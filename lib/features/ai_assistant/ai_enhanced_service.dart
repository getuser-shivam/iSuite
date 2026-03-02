import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:vertex_ai/vertex_ai.dart' as vertex;
import 'central_config.dart';
import 'logging/logging_service.dart';

/// Enhanced AI Service for iSuite
/// Provides comprehensive AI/LLM integration with centralized configuration
class AIEnhancedService {
  static final AIEnhancedService _instance = AIEnhancedService._internal();
  factory AIEnhancedService() => _instance;
  AIEnhancedService._internal();

  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();

  // AI Providers
  GenerativeModel? _geminiModel;
  vertex.VertexAI? _vertexAI;
  OpenAIProvider? _openAIProvider;

  bool _isInitialized = false;
  final StreamController<AIMessage> _aiMessageController = StreamController.broadcast();

  Stream<AIMessage> get aiMessages => _aiMessageController.stream;

  /// Initialize AI service with multiple providers
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Enhanced AI Service', 'AIEnhancedService');

      // Initialize Gemini
      await _initializeGemini();

      // Initialize Vertex AI
      await _initializeVertexAI();

      // Initialize OpenAI
      await _initializeOpenAI();

      // Register with CentralConfig
      await _config.registerComponent(
        'AIEnhancedService',
        '1.0.0',
        'Enhanced AI service with multiple LLM providers',
        parameters: {
          'ai_provider': 'gemini',
          'temperature': 0.7,
          'max_tokens': 2048,
          'streaming_enabled': true,
        }
      );

      _isInitialized = true;
      _logger.info('Enhanced AI Service initialized successfully', 'AIEnhancedService');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize AI service', 'AIEnhancedService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _initializeGemini() async {
    final apiKey = _config.getParameter('ai.gemini_api_key', defaultValue: '');
    if (apiKey.isNotEmpty) {
      _geminiModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: _config.getParameter('ai.temperature', defaultValue: 0.7),
          maxOutputTokens: _config.getParameter('ai.max_tokens', defaultValue: 2048),
        ),
      );
    }
  }

  Future<void> _initializeVertexAI() async {
    final projectId = _config.getParameter('ai.vertex_project_id', defaultValue: '');
    if (projectId.isNotEmpty) {
      _vertexAI = vertex.VertexAI(
        projectId: projectId,
        location: _config.getParameter('ai.vertex_location', defaultValue: 'us-central1'),
      );
    }
  }

  Future<void> _initializeOpenAI() async {
    final apiKey = _config.getParameter('ai.openai_api_key', defaultValue: '');
    if (apiKey.isNotEmpty) {
      // Initialize OpenAI provider
      _openAIProvider = OpenAIProvider(
        apiKey: apiKey,
        model: _config.getParameter('ai.openai_model', defaultValue: 'gpt-4'),
      );
    }
  }

  /// Enhanced generate content with provider fallback
  Future<String> generateContent(String prompt, {String? provider, int maxRetries = 2}) async {
    if (!_isInitialized) await initialize();

    final providers = provider != null ? [provider] : ['gemini', 'vertex', 'openai'];
    String lastError = '';

    for (final currentProvider in providers) {
      for (int attempt = 0; attempt <= maxRetries; attempt++) {
        try {
          switch (currentProvider.toLowerCase()) {
            case 'gemini':
              if (_geminiModel != null) {
                final response = await _geminiModel!.generateContent([Content.text(prompt)]);
                return response.text ?? 'No response generated';
              }
              break;
            case 'vertex':
              if (_vertexAI != null) {
                final response = await _vertexAI!.text.generate(prompt);
                return response;
              }
              break;
            case 'openai':
              if (_openAIProvider != null) {
                final response = await _openAIProvider!.complete(prompt);
                return response;
              }
              break;
          }
        } catch (e) {
          lastError = e.toString();
          _logger.warning('AI generation failed for $currentProvider (attempt ${attempt + 1}): $e', 'AIEnhancedService');
          
          if (attempt < maxRetries) {
            // Wait before retry
            await Future.delayed(Duration(seconds: attempt + 1));
          }
        }
      }
    }

    throw Exception('All AI providers failed. Last error: $lastError');
  }

  /// Generate content with streaming and fallback
  Future<String> generateContentWithFallback(String prompt, {
    String? preferredProvider,
    bool enableStreaming = false,
    int maxRetries = 2,
  }) async {
    try {
      if (enableStreaming && preferredProvider != null) {
        // Try streaming first
        return await streamResponse(prompt, provider: preferredProvider).first;
      }
      
      return await generateContent(prompt, provider: preferredProvider, maxRetries: maxRetries);
    } catch (e) {
      _logger.warning('Primary AI generation failed, trying fallback', 'AIEnhancedService');
      
      // Fallback to any available provider
      return await generateContent(prompt, maxRetries: maxRetries);
    }
  }

  /// Batch content generation for multiple prompts
  Future<List<String>> generateBatchContent(List<String> prompts, {
    String? provider,
    int maxConcurrent = 3,
    int maxRetries = 2,
  }) async {
    final results = <String>[];
    final futures = <Future<String>>[];

    for (final prompt in prompts) {
      if (futures.length >= maxConcurrent) {
        // Wait for some to complete
        final completed = await Future.wait(futures.take(maxConcurrent ~/ 2));
        results.addAll(completed);
        futures.removeRange(0, maxConcurrent ~/ 2);
      }

      final future = generateContent(prompt, provider: provider, maxRetries: maxRetries);
      futures.add(future);
    }

    // Wait for remaining
    final remaining = await Future.wait(futures);
    results.addAll(remaining);

    return results;
  }

  /// Analyze text with enhanced error handling
  Future<Map<String, dynamic>> analyzeText(String text, {String? provider}) async {
    if (text.trim().isEmpty) {
      return {
        'sentiment': 'neutral',
        'topics': ['empty'],
        'language': 'unknown',
        'complexity': 'simple',
        'summary': 'Empty text provided',
      };
    }

    const prompt = '''
Analyze the following text and provide insights in JSON format:
- sentiment: positive/negative/neutral
- topics: array of main topics (max 5)
- language: detected language
- complexity: simple/moderate/complex
- summary: brief summary (50 words max)
- keywords: array of key terms (max 10)
- readability_score: 1-10 (1=easy, 10=very complex)

Text: {text}

Return only valid JSON.
''';

    final analysisPrompt = prompt.replaceAll('{text}', text);

    try {
      final response = await generateContent(analysisPrompt, provider: provider);
      final result = json.decode(response) as Map<String, dynamic>;

      // Validate and sanitize results
      return {
        'sentiment': result['sentiment'] ?? 'neutral',
        'topics': List<String>.from(result['topics'] ?? ['general']),
        'language': result['language'] ?? 'unknown',
        'complexity': result['complexity'] ?? 'moderate',
        'summary': result['summary'] ?? text.substring(0, 50),
        'keywords': List<String>.from(result['keywords'] ?? []),
        'readability_score': result['readability_score'] ?? 5,
      };
    } catch (e) {
      // Fallback analysis
      return {
        'sentiment': 'neutral',
        'topics': ['general'],
        'language': 'unknown',
        'complexity': 'moderate',
        'summary': text.length > 50 ? '${text.substring(0, 47)}...' : text,
        'keywords': [],
        'readability_score': 5,
      };
    }
  }

  /// Analyze text with AI
  Future<Map<String, dynamic>> analyzeText(String text) async {
    const prompt = '''
Analyze the following text and provide insights in JSON format:
- sentiment: positive/negative/neutral
- topics: array of main topics
- language: detected language
- complexity: simple/moderate/complex
- summary: brief summary (50 words max)

Text: {text}

Return only valid JSON.
''';

    final analysisPrompt = prompt.replaceAll('{text}', text);
    final response = await generateContent(analysisPrompt);

    try {
      return json.decode(response) as Map<String, dynamic>;
    } catch (e) {
      // Fallback analysis
      return {
        'sentiment': 'neutral',
        'topics': ['general'],
        'language': 'unknown',
        'complexity': 'moderate',
        'summary': text.length > 50 ? '${text.substring(0, 47)}...' : text,
      };
    }
  }

  /// Generate personalized UI suggestions
  Future<List<String>> generateUISuggestions(String userContext) async {
    const prompt = '''
Based on the user context, suggest 3 UI improvements for a productivity app:

Context: {context}

Return suggestions as a numbered list.
''';

    final suggestionPrompt = prompt.replaceAll('{context}', userContext);
    final response = await generateContent(suggestionPrompt);

    // Parse numbered list
    final lines = response.split('\n');
    final suggestions = <String>[];

    for (final line in lines) {
      if (line.trim().isNotEmpty && (line.startsWith('1.') || line.startsWith('2.') || line.startsWith('3.'))) {
        suggestions.add(line.substring(2).trim());
      }
    }

    return suggestions.take(3).toList();
  }

  /// Smart search with semantic understanding
  Future<List<String>> semanticSearch(String query, List<String> items) async {
    const prompt = '''
Given the search query and list of items, return the most relevant items in order of relevance.
Consider semantic meaning, not just keyword matching.

Query: {query}
Items: {items}

Return only the relevant item names, one per line.
''';

    final itemsStr = items.join(', ');
    final searchPrompt = prompt
        .replaceAll('{query}', query)
        .replaceAll('{items}', itemsStr);

    final response = await generateContent(searchPrompt);
    return response.split('\n').where((line) => line.trim().isNotEmpty).toList();
  }

  /// Generate content suggestions
  Future<List<String>> generateContentSuggestions(String context) async {
    const prompt = '''
Based on the current context, suggest 3 pieces of content that would be helpful:

Context: {context}

Return suggestions as a numbered list.
''';

    final suggestionPrompt = prompt.replaceAll('{context}', context);
    final response = await generateContent(suggestionPrompt);

    final lines = response.split('\n');
    final suggestions = <String>[];

    for (final line in lines) {
      if (line.trim().isNotEmpty && RegExp(r'^\d+\.').hasMatch(line)) {
        suggestions.add(line.replaceFirst(RegExp(r'^\d+\.\s*'), ''));
      }
    }

    return suggestions.take(3).toList();
  }

  /// Stream AI responses for real-time interaction
  Stream<String> streamResponse(String prompt, {String provider = 'gemini'}) async* {
    if (!_isInitialized) await initialize();

    try {
      switch (provider.toLowerCase()) {
        case 'gemini':
          if (_geminiModel != null) {
            final response = _geminiModel!.generateContentStream([Content.text(prompt)]);
            await for (final chunk in response) {
              final text = chunk.text;
              if (text != null) {
                yield text;
              }
            }
          }
          break;
        // Add streaming for other providers as needed
        default:
          yield await generateContent(prompt, provider: provider);
      }
    } catch (e) {
      _logger.error('AI streaming failed', 'AIEnhancedService', error: e);
      yield 'Error: $e';
    }
  }

  /// Get AI configuration
  Map<String, dynamic> getAIConfig() {
    return {
      'provider': _config.getParameter('ai.provider', defaultValue: 'gemini'),
      'temperature': _config.getParameter('ai.temperature', defaultValue: 0.7),
      'max_tokens': _config.getParameter('ai.max_tokens', defaultValue: 2048),
      'streaming_enabled': _config.getParameter('ai.streaming_enabled', defaultValue: true),
      'gemini_available': _geminiModel != null,
      'vertex_available': _vertexAI != null,
      'openai_available': _openAIProvider != null,
    };
  }

  /// Update AI configuration
  Future<void> updateAIConfig(Map<String, dynamic> config) async {
    for (final entry in config.entries) {
      await _config.setParameter('ai.${entry.key}', entry.value);
    }

    // Reinitialize if needed
    if (config.containsKey('provider') || config.containsKey('api_keys')) {
      _isInitialized = false;
      await initialize();
    }
  }

  void dispose() {
    _aiMessageController.close();
  }
}

/// AI Message model for streaming
class AIMessage {
  final String content;
  final DateTime timestamp;
  final String provider;
  final bool isError;

  AIMessage({
    required this.content,
    required this.timestamp,
    required this.provider,
    this.isError = false,
  });
}
