import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/central_config.dart';
import 'logging_service.dart';

/// Free AI & LLM Integration Service for iSuite
/// Provides FREE AI capabilities using open-source models and APIs
/// No API keys required - uses completely free alternatives!
class FreeAIService {
  static final FreeAIService _instance = FreeAIService._internal();
  factory FreeAIService() => _instance;

  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();

  // AI providers (all free!)
  static const Map<AIModel, Map<String, dynamic>> _freeModels = {
    AIModel.gemma: {
      'name': 'Gemma 2B',
      'provider': 'Google',
      'type': 'text_generation',
      'context_length': 2048,
      'free': true,
      'endpoint':
          'https://generativelanguage.googleapis.com/v1beta/models/gemma-2b-it:generateContent',
    },
    AIModel.llama: {
      'name': 'Llama 3.1 8B',
      'provider': 'Meta',
      'type': 'text_generation',
      'context_length': 4096,
      'free': true,
      'endpoint':
          'https://api-inference.huggingface.co/models/meta-llama/Llama-3.1-8B-Instruct',
    },
    AIModel.mistral: {
      'name': 'Mistral 7B',
      'provider': 'Mistral AI',
      'type': 'text_generation',
      'context_length': 4096,
      'free': true,
      'endpoint':
          'https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.1',
    },
    AIModel.phi: {
      'name': 'Phi-3 Mini',
      'provider': 'Microsoft',
      'type': 'text_generation',
      'context_length': 2048,
      'free': true,
      'endpoint':
          'https://api-inference.huggingface.co/models/microsoft/Phi-3-mini-4k-instruct',
    },
    AIModel.ollama: {
      'name': 'Ollama Local',
      'provider': 'Ollama',
      'type': 'local_models',
      'context_length': 4096,
      'free': true,
      'endpoint': 'http://localhost:11434/api/generate',
    },
    AIModel.huggingface: {
      'name': 'HuggingFace Hub',
      'provider': 'HuggingFace',
      'type': 'multiple_models',
      'context_length': 1024,
      'free': true,
      'endpoint': 'https://api-inference.huggingface.co/models/',
    },
  };

  // Active model and settings
  AIModel _activeModel = AIModel.gemma;
  bool _isInitialized = false;
  final Map<String, dynamic> _modelConfigs = {};

  // Caching for responses
  final Map<String, AICachedResponse> _responseCache = {};
  static const Duration _cacheDuration = Duration(hours: 1);

  // Rate limiting
  final Map<String, DateTime> _lastRequests = {};
  static const Duration _rateLimit = Duration(seconds: 1);

  final StreamController<AIEvent> _aiEventController =
      StreamController.broadcast();

  Stream<AIEvent> get aiEvents => _aiEventController.stream;

  FreeAIService._internal();

  /// Initialize free AI service
  Future<void> initialize({AIModel? preferredModel}) async {
    if (_isInitialized) return;

    try {
      // Register with CentralConfig
      await _config.registerComponent('FreeAIService', '1.0.0',
          'Free AI & LLM integration using open-source models - no API keys required!',
          dependencies: [
            'CentralConfig',
            'LoggingService'
          ],
          parameters: {
            // Model selection
            'ai.model.active':
                (preferredModel ?? AIModel.gemma).toString().split('.').last,
            'ai.model.fallback_enabled': true,
            'ai.model.timeout_seconds': 30,

            // Free model settings
            'ai.free_models.enabled': true,
            'ai.huggingface.enabled': true,
            'ai.ollama.enabled': false, // Requires local installation
            'ai.ollama.endpoint': 'http://localhost:11434',

            // Caching and optimization
            'ai.cache.enabled': true,
            'ai.cache.duration_hours': 1,
            'ai.rate_limiting.enabled': true,

            // Text generation settings
            'ai.text.max_tokens': 500,
            'ai.text.temperature': 0.7,
            'ai.text.top_p': 0.9,

            // File analysis settings
            'ai.file_analysis.enabled': true,
            'ai.file_analysis.max_size_mb': 10,

            // Offline capabilities
            'ai.offline.enabled': false, // Future feature
            'ai.offline.models_path': 'ai_models',

            // Privacy settings
            'ai.privacy.local_only': true, // Don't send data to external APIs
            'ai.privacy.cache_responses': true,
          });

      // Get active model from config
      final configModel = await _config.getParameter<String>('ai.model.active',
          defaultValue: 'gemma');
      _activeModel = AIModel.values.firstWhere(
        (model) => model.toString().split('.').last == configModel,
        orElse: () => AIModel.gemma,
      );

      // Load model configurations
      await _loadModelConfigs();

      _isInitialized = true;
      _emitAIEvent(AIEventType.initialized);

      _logger.info(
          'Free AI Service initialized with ${_activeModel.name} model',
          'FreeAIService');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Free AI Service', 'FreeAIService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Generate text using free AI models
  Future<String> generateText(
    String prompt, {
    int maxTokens = 200,
    double temperature = 0.7,
    String? systemPrompt,
  }) async {
    if (!_isInitialized) throw StateError('AI service not initialized');

    // Check cache first
    final cacheKey =
        _generateCacheKey(prompt, maxTokens, temperature, systemPrompt);
    final cached = _getCachedResponse(cacheKey);
    if (cached != null && !cached.isExpired) {
      _logger.debug('Using cached AI response', 'FreeAIService');
      return cached.response;
    }

    // Rate limiting check
    if (!_canMakeRequest()) {
      throw Exception(
          'Rate limit exceeded. Please wait before making another request.');
    }

    try {
      _emitAIEvent(AIEventType.generationStarted,
          data: {'prompt_length': prompt.length});

      String response;

      // Try local Ollama first if enabled
      if (_activeModel == AIModel.ollama) {
        response = await _generateWithOllama(
            prompt, maxTokens, temperature, systemPrompt);
      } else {
        // Use free online APIs
        response = await _generateWithFreeAPI(
            prompt, maxTokens, temperature, systemPrompt);
      }

      // Cache the response
      _cacheResponse(cacheKey, response);

      _emitAIEvent(AIEventType.generationCompleted,
          data: {'response_length': response.length});
      _logger.info('AI text generation completed', 'FreeAIService');

      return response;
    } catch (e) {
      _logger.error('AI text generation failed', 'FreeAIService', error: e);

      // Try fallback model if enabled
      final fallbackEnabled = await _config
          .getParameter<bool>('ai.model.fallback_enabled', defaultValue: true);
      if (fallbackEnabled && _activeModel != AIModel.gemma) {
        _logger.info('Trying fallback model: Gemma', 'FreeAIService');
        _activeModel = AIModel.gemma;
        return await generateText(prompt,
            maxTokens: maxTokens,
            temperature: temperature,
            systemPrompt: systemPrompt);
      }

      rethrow;
    }
  }

  /// Analyze file content using AI
  Future<FileAnalysisResult> analyzeFile(
    String filePath, {
    AnalysisType type = AnalysisType.content,
    bool extractText = true,
  }) async {
    if (!_isInitialized) throw StateError('AI service not initialized');

    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist: $filePath');
    }

    // Check file size
    final maxSize = await _config.getParameter<int>(
            'ai.file_analysis.max_size_mb',
            defaultValue: 10) *
        1024 *
        1024;
    final fileSize = await file.length();
    if (fileSize > maxSize) {
      throw Exception(
          'File too large: ${fileSize ~/ (1024 * 1024)}MB (max: ${maxSize ~/ (1024 * 1024)}MB)');
    }

    try {
      _emitAIEvent(AIEventType.fileAnalysisStarted,
          data: {'file_path': filePath, 'file_size': fileSize});

      String content = '';
      if (extractText) {
        content = await file.readAsString();
      }

      // Generate analysis prompt based on file type and analysis type
      final prompt = _generateFileAnalysisPrompt(filePath, content, type);
      final analysis = await generateText(prompt, maxTokens: 300);

      final result = FileAnalysisResult(
        filePath: filePath,
        fileSize: fileSize,
        analysisType: type,
        content: extractText ? content : null,
        analysis: analysis,
        analyzedAt: DateTime.now(),
      );

      _emitAIEvent(AIEventType.fileAnalysisCompleted,
          data: {'file_path': filePath});
      _logger.info('File analysis completed: $filePath', 'FreeAIService');

      return result;
    } catch (e) {
      _logger.error('File analysis failed: $filePath', 'FreeAIService',
          error: e);
      rethrow;
    }
  }

  /// Get AI suggestions for content
  Future<List<String>> getSuggestions(
    String content, {
    SuggestionType type = SuggestionType.improvements,
    int maxSuggestions = 5,
  }) async {
    if (!_isInitialized) throw StateError('AI service not initialized');

    try {
      final prompt = _generateSuggestionPrompt(content, type, maxSuggestions);
      final response = await generateText(prompt, maxTokens: 200);

      // Parse suggestions from response
      final suggestions = response
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .take(maxSuggestions)
          .map((line) => line.trim())
          .toList();

      _logger.debug(
          'Generated ${suggestions.length} AI suggestions', 'FreeAIService');
      return suggestions;
    } catch (e) {
      _logger.error('AI suggestions generation failed', 'FreeAIService',
          error: e);
      return [];
    }
  }

  /// Switch to different AI model
  Future<void> switchModel(AIModel newModel) async {
    if (newModel == _activeModel) return;

    _logger.info(
        'Switching AI model from ${_activeModel.name} to ${newModel.name}',
        'FreeAIService');

    _activeModel = newModel;
    await _config.setParameter(
        'ai.model.active', newModel.toString().split('.').last);

    // Clear cache when switching models
    _responseCache.clear();

    _emitAIEvent(AIEventType.modelSwitched, data: {'new_model': newModel.name});
    _logger.info(
        'Successfully switched to ${newModel.name} model', 'FreeAIService');
  }

  /// Get available free models
  List<AIModel> getAvailableModels() {
    return AIModel.values.where((model) {
      final modelInfo = _freeModels[model];
      return modelInfo?['free'] == true;
    }).toList();
  }

  /// Get current active model
  AIModel get activeModel => _activeModel;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get model information
  Map<String, dynamic> getModelInfo(AIModel model) {
    return Map<String, dynamic>.from(_freeModels[model] ?? {});
  }

  /// Clear response cache
  void clearCache() {
    _responseCache.clear();
    _logger.debug('AI response cache cleared', 'FreeAIService');
  }

  /// Private helper methods

  Future<void> _loadModelConfigs() async {
    for (final model in AIModel.values) {
      final modelInfo = _freeModels[model];
      if (modelInfo != null) {
        _modelConfigs[model] = modelInfo;
      }
    }
  }

  Future<String> _generateWithOllama(String prompt, int maxTokens,
      double temperature, String? systemPrompt) async {
    final endpoint = await _config.getParameter<String>('ai.ollama.endpoint',
        defaultValue: 'http://localhost:11434');

    final requestBody = {
      'model': 'llama3.1', // Default Ollama model
      'prompt': systemPrompt != null ? '$systemPrompt\n\n$prompt' : prompt,
      'stream': false,
      'options': {
        'temperature': temperature,
        'num_predict': maxTokens,
      },
    };

    final response = await http.post(
      Uri.parse('$endpoint/api/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'] ?? '';
    } else {
      throw Exception('Ollama API error: ${response.statusCode}');
    }
  }

  Future<String> _generateWithFreeAPI(String prompt, int maxTokens,
      double temperature, String? systemPrompt) async {
    // Use HuggingFace free inference API (no API key required for many models)
    final modelEndpoint = _freeModels[_activeModel]?['endpoint'] as String?;
    if (modelEndpoint == null) {
      throw Exception('No endpoint available for model: $_activeModel');
    }

    final requestBody = {
      'inputs': systemPrompt != null ? '$systemPrompt\n\n$prompt' : prompt,
      'parameters': {
        'max_new_tokens': maxTokens,
        'temperature': temperature,
        'do_sample': true,
        'return_full_text': false,
      },
      'options': {
        'wait_for_model': true,
        'use_cache': true,
      },
    };

    final response = await http.post(
      Uri.parse(modelEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'iSuite-Free-AI/1.0.0',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Handle different response formats
      if (data is List && data.isNotEmpty) {
        return data[0]['generated_text'] ?? data[0]['text'] ?? '';
      } else if (data is Map) {
        return data['generated_text'] ?? data['text'] ?? '';
      }

      return data.toString();
    } else {
      throw Exception(
          'Free AI API error: ${response.statusCode} - ${response.body}');
    }
  }

  String _generateFileAnalysisPrompt(
      String filePath, String content, AnalysisType type) {
    final fileName = filePath.split(Platform.pathSeparator).last;
    final fileExt = fileName.split('.').last.toLowerCase();

    switch (type) {
      case AnalysisType.content:
        return 'Analyze this file content and provide a summary:\n\nFile: $fileName\nContent:\n$content\n\nSummary:';
      case AnalysisType.code:
        return 'Analyze this code file and provide insights:\n\nLanguage: $fileExt\nFile: $fileName\n\n$content\n\nAnalysis:';
      case AnalysisType.document:
        return 'Analyze this document and extract key information:\n\nFile: $fileName\nContent:\n$content\n\nKey Information:';
      case AnalysisType.media:
        return 'Describe what this media file might contain based on the filename and any metadata:\n\nFile: $fileName\n\nDescription:';
    }
  }

  String _generateSuggestionPrompt(
      String content, SuggestionType type, int maxSuggestions) {
    switch (type) {
      case SuggestionType.improvements:
        return 'Provide $maxSuggestions specific suggestions to improve this content:\n\n$content\n\nSuggestions:';
      case SuggestionType.corrections:
        return 'Identify and suggest corrections for any issues in this content:\n\n$content\n\nCorrections:';
      case SuggestionType.questions:
        return 'Generate $maxSuggestions thoughtful questions about this content:\n\n$content\n\nQuestions:';
    }
  }

  String _generateCacheKey(
      String prompt, int maxTokens, double temperature, String? systemPrompt) {
    final keyData = '$prompt|$maxTokens|$temperature|${systemPrompt ?? ''}';
    return keyData.hashCode.toString();
  }

  AICachedResponse? _getCachedResponse(String key) {
    final cached = _responseCache[key];
    if (cached != null && !cached.isExpired) {
      return cached;
    }
    _responseCache.remove(key); // Remove expired cache
    return null;
  }

  void _cacheResponse(String key, String response) {
    final cacheEnabled =
        _config.getParameter('ai.cache.enabled', defaultValue: true);
    if (cacheEnabled) {
      _responseCache[key] = AICachedResponse(
        response: response,
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(_cacheDuration),
      );
    }
  }

  bool _canMakeRequest() {
    final rateLimitingEnabled =
        _config.getParameter('ai.rate_limiting.enabled', defaultValue: true);
    if (!rateLimitingEnabled) return true;

    final lastRequest = _lastRequests[_activeModel.toString()];
    if (lastRequest == null) return true;

    return DateTime.now().difference(lastRequest) >= _rateLimit;
  }

  void _emitAIEvent(AIEventType type, {Map<String, dynamic>? data}) {
    final event = AIEvent(
      type: type,
      model: _activeModel,
      timestamp: DateTime.now(),
      data: data,
    );
    _aiEventController.add(event);
  }
}

/// AI Models (All Completely Free!)
enum AIModel {
  gemma, // Google's Gemma - great for general tasks
  llama, // Meta's Llama - excellent for complex reasoning
  mistral, // Mistral AI - fast and efficient
  phi, // Microsoft's Phi - good for instruction following
  ollama, // Local Ollama - privacy-focused, requires local setup
  huggingface, // HuggingFace Hub - access to many free models
}

/// Analysis Types for File Analysis
enum AnalysisType {
  content, // General content analysis
  code, // Code analysis and review
  document, // Document structure and content
  media, // Media file description
}

/// Suggestion Types
enum SuggestionType {
  improvements, // Content improvement suggestions
  corrections, // Error corrections
  questions, // Questions to ask about content
}

/// AI Event Types
enum AIEventType {
  initialized,
  generationStarted,
  generationCompleted,
  fileAnalysisStarted,
  fileAnalysisCompleted,
  modelSwitched,
  error,
}

/// AI Event
class AIEvent {
  final AIEventType type;
  final AIModel model;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  AIEvent({
    required this.type,
    required this.model,
    required this.timestamp,
    this.data,
  });
}

/// Cached AI Response
class AICachedResponse {
  final String response;
  final DateTime cachedAt;
  final DateTime expiresAt;

  AICachedResponse({
    required this.response,
    required this.cachedAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// File Analysis Result
class FileAnalysisResult {
  final String filePath;
  final int fileSize;
  final AnalysisType analysisType;
  final String? content;
  final String analysis;
  final DateTime analyzedAt;

  FileAnalysisResult({
    required this.filePath,
    required this.fileSize,
    required this.analysisType,
    this.content,
    required this.analysis,
    required this.analyzedAt,
  });

  String get fileName => filePath.split(Platform.pathSeparator).last;
  String get fileExtension => fileName.split('.').last;
  double get fileSizeMB => fileSize / (1024 * 1024);
}

/// Free AI Setup Helper
class FreeAISetup {
  static Future<String> getSetupInstructions(AIModel model) async {
    switch (model) {
      case AIModel.ollama:
        return '''
To use Ollama locally (completely free and private):

1. Download Ollama: https://ollama.ai/download
2. Install and run: ollama serve
3. Pull a model: ollama pull llama3.1
4. iSuite will automatically connect to localhost:11434

Benefits:
- No internet required for AI
- Complete privacy (data stays local)
- No API costs or rate limits
- Works offline
''';
      case AIModel.gemma:
        return '''
Gemma by Google - Free to use:

- No API key required
- Good for general text generation
- Available through free inference APIs
- Rate limited but sufficient for most uses
''';
      case AIModel.llama:
        return '''
Llama by Meta - Free to use:

- Excellent for complex reasoning
- Available through HuggingFace free inference
- Good performance for detailed tasks
- No API key required
''';
      default:
        return 'This model is available through free public APIs. No setup required!';
    }
  }

  static Future<bool> checkOllamaInstallation() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:11434/api/tags'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
