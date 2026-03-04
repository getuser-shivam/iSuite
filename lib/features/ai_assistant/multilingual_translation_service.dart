import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/logging/logging_service.dart';
import '../../core/config/central_config.dart';

/// Multilingual Translation Service using AI/LLM
///
/// Provides comprehensive translation capabilities to overcome language barriers:
/// - Real-time document translation between multiple languages
/// - Intelligent language detection and content analysis
/// - Context-aware translation preserving technical terminology
/// - Batch translation for multiple documents
/// - Translation quality assessment and improvement
/// - Cultural adaptation and localization support
/// - Integration with voice translation for accessibility
class MultilingualTranslationService {
  static final MultilingualTranslationService _instance =
      MultilingualTranslationService._internal();
  factory MultilingualTranslationService() => _instance;
  MultilingualTranslationService._internal();

  final LoggingService _logger = LoggingService();
  final CentralConfig _config = CentralConfig.instance;

  GenerativeModel? _model;
  bool _isInitialized = false;

  // Translation cache and history
  final Map<String, TranslationResult> _translationCache = {};
  final List<TranslationRequest> _translationHistory = [];
  final Map<String, LanguageProfile> _languageProfiles = {};

  // Supported languages (ISO 639-1 codes)
  final Map<String, String> _supportedLanguages = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ko': 'Korean',
    'ar': 'Arabic',
    'hi': 'Hindi',
    'bn': 'Bengali',
    'nl': 'Dutch',
    'sv': 'Swedish',
    'no': 'Norwegian',
    'da': 'Danish',
    'fi': 'Finnish',
    'pl': 'Polish',
    'tr': 'Turkish',
    'cs': 'Czech',
    'hu': 'Hungarian',
    'ro': 'Romanian',
    'el': 'Greek',
    'he': 'Hebrew',
    'th': 'Thai',
    'vi': 'Vietnamese',
    'id': 'Indonesian',
    'ms': 'Malay',
    'ta': 'Tamil',
    'te': 'Telugu',
    'ur': 'Urdu',
    'fa': 'Persian',
  };

  /// Initialize the translation service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Multilingual Translation Service',
          'TranslationService');

      // Check if translation features are enabled
      final translationEnabled =
          _config.getParameter('ai.nlp.enabled', defaultValue: true);
      if (!translationEnabled) {
        _logger.info('Translation features disabled', 'TranslationService');
        _isInitialized = true;
        return;
      }

      // Initialize AI model for translation
      await _initializeAIModel();

      // Load language profiles
      await _initializeLanguageProfiles();

      _isInitialized = true;
      _logger.info('Multilingual Translation Service initialized successfully',
          'TranslationService');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Multilingual Translation Service',
          'TranslationService',
          error: e, stackTrace: stackTrace);
      // Continue with limited functionality
      _isInitialized = true;
    }
  }

  Future<void> _initializeAIModel() async {
    try {
      final provider =
          _config.getParameter('ai.llm_provider', defaultValue: 'google');
      final apiKey = _config.getParameter('ai.api_key', defaultValue: '');
      final modelName = _config.getParameter('ai.model_name',
          defaultValue: 'gemini-1.5-flash');

      if (provider == 'google' && apiKey.isNotEmpty) {
        _model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.1, // Low temperature for accurate translations
            maxOutputTokens:
                _config.getParameter('ai.max_tokens', defaultValue: 4096),
          ),
        );
        _logger.info(
            'AI model initialized for translation', 'TranslationService');
      }
    } catch (e) {
      _logger.error(
          'Failed to initialize AI model for translation', 'TranslationService',
          error: e);
    }
  }

  Future<void> _initializeLanguageProfiles() async {
    // Initialize language-specific profiles for better translation quality
    for (final entry in _supportedLanguages.entries) {
      final languageCode = entry.key;
      _languageProfiles[languageCode] = LanguageProfile(
        languageCode: languageCode,
        languageName: entry.value,
        translationCount: 0,
        averageQuality: 0.0,
        commonPhrases: [],
        technicalTerms: [],
      );
    }

    _logger.info(
        'Language profiles initialized for ${languageCode.length} languages',
        'TranslationService');
  }

  /// Translate text from one language to another
  Future<TranslationResult> translateText({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
    String? context,
    TranslationOptions? options,
  }) async {
    if (!_isInitialized) await initialize();

    final cacheKey =
        _generateCacheKey(text, targetLanguage, sourceLanguage, context);
    if (_config.getParameter('ai.cache.enabled', defaultValue: true)) {
      final cached = _translationCache[cacheKey];
      if (cached != null && !_isCacheExpired(cached)) {
        _logger.info('Returning cached translation', 'TranslationService');
        return cached;
      }
    }

    try {
      _logger.info('Translating text to $targetLanguage (${text.length} chars)',
          'TranslationService');

      final result = TranslationResult(
        originalText: text,
        translatedText: '',
        sourceLanguage: sourceLanguage ?? await _detectLanguage(text),
        targetLanguage: targetLanguage,
        confidence: 0.0,
        translationTime: DateTime.now(),
      );

      // Perform translation
      result.translatedText = await _performTranslation(
          text, result.sourceLanguage, targetLanguage, context, options);
      result.confidence = await _assessTranslationQuality(
          text, result.translatedText, targetLanguage);

      // Post-process translation
      result.translatedText =
          await _postProcessTranslation(result.translatedText, targetLanguage);

      // Update language profiles
      await _updateLanguageProfile(
          result.sourceLanguage, result.targetLanguage, result.confidence);

      // Record translation history
      final request = TranslationRequest(
        id: 'translation_${DateTime.now().millisecondsSinceEpoch}',
        originalText: text,
        sourceLanguage: result.sourceLanguage,
        targetLanguage: targetLanguage,
        context: context,
        options: options,
        timestamp: DateTime.now(),
      );
      _translationHistory.add(request);

      // Cache result
      if (_config.getParameter('ai.cache.enabled', defaultValue: true)) {
        _translationCache[cacheKey] = result;
        _cleanupTranslationCache();
      }

      _logger.info(
          'Translation completed with confidence: ${(result.confidence * 100).round()}%',
          'TranslationService');
      return result;
    } catch (e, stackTrace) {
      _logger.error('Translation failed for text to $targetLanguage',
          'TranslationService',
          error: e, stackTrace: stackTrace);

      return TranslationResult(
        originalText: text,
        translatedText: text, // Return original on failure
        sourceLanguage: sourceLanguage ?? 'unknown',
        targetLanguage: targetLanguage,
        confidence: 0.0,
        error: e.toString(),
        translationTime: DateTime.now(),
      );
    }
  }

  /// Translate an entire document
  Future<DocumentTranslationResult> translateDocument({
    required String documentPath,
    required String content,
    required String targetLanguage,
    String? sourceLanguage,
    DocumentTranslationOptions? options,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      _logger.info('Translating document to $targetLanguage: $documentPath',
          'TranslationService');

      final result = DocumentTranslationResult(
        documentPath: documentPath,
        originalContent: content,
        translatedContent: '',
        sourceLanguage: sourceLanguage ?? await _detectLanguage(content),
        targetLanguage: targetLanguage,
        sections: [],
        metadata: {},
        translationTime: DateTime.now(),
      );

      // Split document into sections for better translation
      final sections = _splitDocumentIntoSections(content);
      final translatedSections = <DocumentSection>[];

      for (final section in sections) {
        final sectionTranslation = await translateText(
          text: section.content,
          targetLanguage: targetLanguage,
          sourceLanguage: result.sourceLanguage,
          context: 'Document section: ${section.type}',
          options: TranslationOptions(
            preserveFormatting: true,
            technicalTerms: options?.preserveTechnicalTerms ?? true,
          ),
        );

        translatedSections.add(DocumentSection(
          type: section.type,
          originalContent: section.content,
          translatedContent: sectionTranslation.translatedText,
          confidence: sectionTranslation.confidence,
        ));
      }

      // Combine translated sections
      result.translatedContent =
          translatedSections.map((s) => s.translatedContent).join('\n\n');
      result.sections = translatedSections;

      // Extract and translate metadata
      result.metadata = await _translateDocumentMetadata(
          documentPath, content, targetLanguage);

      // Calculate overall confidence
      result.confidence = translatedSections.isEmpty
          ? 0.0
          : translatedSections
                  .map((s) => s.confidence)
                  .reduce((a, b) => a + b) /
              translatedSections.length;

      _logger.info(
          'Document translation completed: ${result.sections.length} sections',
          'TranslationService');
      return result;
    } catch (e, stackTrace) {
      _logger.error(
          'Document translation failed: $documentPath', 'TranslationService',
          error: e, stackTrace: stackTrace);

      return DocumentTranslationResult(
        documentPath: documentPath,
        originalContent: content,
        translatedContent: content, // Return original on failure
        sourceLanguage: sourceLanguage ?? 'unknown',
        targetLanguage: targetLanguage,
        sections: [],
        metadata: {},
        error: e.toString(),
        translationTime: DateTime.now(),
      );
    }
  }

  /// Detect the language of given text
  Future<String> detectLanguage(String text) async {
    return await _detectLanguage(text);
  }

  /// Get supported languages
  Map<String, String> getSupportedLanguages() {
    return Map.from(_supportedLanguages);
  }

  /// Get translation statistics
  TranslationStatistics getTranslationStatistics() {
    final totalTranslations = _translationHistory.length;
    final languagePairs = <String, int>{};
    final averageConfidence = _translationHistory.isEmpty
        ? 0.0
        : _translationHistory
                .map((t) => t.confidence ?? 0.0)
                .reduce((a, b) => a + b) /
            totalTranslations;

    for (final request in _translationHistory) {
      final pair = '${request.sourceLanguage}->${request.targetLanguage}';
      languagePairs[pair] = (languagePairs[pair] ?? 0) + 1;
    }

    return TranslationStatistics(
      totalTranslations: totalTranslations,
      uniqueLanguagePairs: languagePairs.length,
      averageConfidence: averageConfidence,
      mostUsedPairs: languagePairs.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(5).map((e) => e.key).toList(),
      languageUsage: _getLanguageUsageStats(),
    );
  }

  /// Batch translate multiple texts
  Future<List<TranslationResult>> batchTranslate({
    required List<String> texts,
    required String targetLanguage,
    String? sourceLanguage,
    int maxConcurrent = 3,
  }) async {
    if (!_isInitialized) await initialize();

    final results = <TranslationResult>[];
    final semaphore = _Semaphore(maxConcurrent);

    try {
      _logger.info(
          'Starting batch translation of ${texts.length} texts to $targetLanguage',
          'TranslationService');

      final futures = texts.map((text) async {
        await semaphore.acquire();
        try {
          final result = await translateText(
            text: text,
            targetLanguage: targetLanguage,
            sourceLanguage: sourceLanguage,
          );
          results.add(result);
        } finally {
          semaphore.release();
        }
      });

      await Future.wait(futures);
      _logger.info('Batch translation completed: ${results.length} texts',
          'TranslationService');
    } catch (e, stackTrace) {
      _logger.error('Batch translation failed', 'TranslationService',
          error: e, stackTrace: stackTrace);
    }

    return results;
  }

  // Private implementation methods

  Future<String> _detectLanguage(String text) async {
    if (_model == null) return 'en'; // Default fallback

    try {
      // Use AI to detect language
      final prompt = '''
Detect the primary language of this text. Return only the ISO 639-1 language code (e.g., 'en', 'es', 'fr').

Text: "${text.substring(0, min(200, text.length))}"
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final detected = response.text?.trim().toLowerCase() ?? 'en';

      // Validate detected language
      return _supportedLanguages.containsKey(detected) ? detected : 'en';
    } catch (e) {
      _logger.warning('Language detection failed, using English as default',
          'TranslationService',
          error: e);
      return 'en';
    }
  }

  Future<String> _performTranslation(
    String text,
    String sourceLanguage,
    String targetLanguage,
    String? context,
    TranslationOptions? options,
  ) async {
    if (_model == null) return text; // Return original if no AI available

    try {
      final prompt = _buildTranslationPrompt(
          text, sourceLanguage, targetLanguage, context, options);

      final response = await _model!.generateContent([Content.text(prompt)]);
      final translation = response.text?.trim() ?? text;

      // Clean up the response
      return _cleanTranslationResponse(translation);
    } catch (e) {
      _logger.warning('AI translation failed, returning original text',
          'TranslationService',
          error: e);
      return text;
    }
  }

  String _buildTranslationPrompt(
    String text,
    String sourceLanguage,
    String targetLanguage,
    String? context,
    TranslationOptions? options,
  ) {
    final sourceName = _supportedLanguages[sourceLanguage] ?? 'Unknown';
    final targetName = _supportedLanguages[targetLanguage] ?? 'Unknown';

    var prompt = '''
Translate this text from $sourceName ($sourceLanguage) to $targetName ($targetLanguage).

IMPORTANT: Provide ONLY the translated text, no explanations or additional content.

''';

    if (context != null) {
      prompt += 'Context: $context\n\n';
    }

    if (options?.preserveFormatting == true) {
      prompt += 'Preserve formatting, line breaks, and structure.\n';
    }

    if (options?.technicalTerms == true) {
      prompt +=
          'Preserve technical terms, proper nouns, and specialized vocabulary.\n';
    }

    if (options?.formalTone == true) {
      prompt += 'Use formal, professional tone.\n';
    }

    prompt += '\nText to translate:\n$text\n\nTranslation:';

    return prompt;
  }

  String _cleanTranslationResponse(String response) {
    // Remove any extra content that might have been added
    final translationMarker = 'Translation:';
    if (response.contains(translationMarker)) {
      return response.split(translationMarker).last.trim();
    }

    // Remove markdown formatting if present
    return response.replaceAll(RegExp(r'```.*?\n?'), '').trim();
  }

  Future<double> _assessTranslationQuality(
      String original, String translated, String targetLanguage) async {
    if (_model == null) return 0.7; // Default confidence

    try {
      final prompt = '''
Rate the quality of this translation on a scale of 0.0 to 1.0, where:
- 1.0 = Perfect translation, natural and accurate
- 0.8 = Good translation with minor issues
- 0.6 = Acceptable but could be improved
- 0.4 = Poor translation with significant errors
- 0.2 = Very poor, barely understandable
- 0.0 = Complete failure

Consider: accuracy, naturalness, grammar, terminology, and cultural appropriateness.

Original: "$original"
Translation to ${_supportedLanguages[targetLanguage] ?? targetLanguage}: "$translated"

Return only the numerical rating.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final rating = double.tryParse(response.text?.trim() ?? '0.7') ?? 0.7;

      return rating.clamp(0.0, 1.0);
    } catch (e) {
      _logger.warning(
          'Translation quality assessment failed', 'TranslationService',
          error: e);
      return 0.7; // Default confidence
    }
  }

  Future<String> _postProcessTranslation(
      String translation, String targetLanguage) async {
    // Apply language-specific post-processing
    switch (targetLanguage) {
      case 'zh':
      case 'ja':
      case 'ko':
        // Ensure proper spacing for CJK languages
        return translation.replaceAll(RegExp(r'\s+'), ' ').trim();
      case 'ar':
      case 'he':
      case 'fa':
        // RTL languages might need special handling
        return translation.trim();
      default:
        return translation.trim();
    }
  }

  List<DocumentSection> _splitDocumentIntoSections(String content) {
    final sections = <DocumentSection>[];

    // Simple section splitting - can be enhanced with more sophisticated parsing
    final lines = content.split('\n');
    final currentSection = StringBuffer();
    var currentType = 'body';

    for (final line in lines) {
      if (line.trim().isEmpty) {
        if (currentSection.isNotEmpty) {
          sections.add(DocumentSection(
            type: currentType,
            content: currentSection.toString().trim(),
          ));
          currentSection.clear();
        }
        continue;
      }

      // Detect section types based on content patterns
      if (line.startsWith('#') || line.toUpperCase() == line) {
        if (currentSection.isNotEmpty) {
          sections.add(DocumentSection(
            type: currentType,
            content: currentSection.toString().trim(),
          ));
          currentSection.clear();
        }
        currentType = 'header';
      } else if (line.contains(RegExp(r'^\d+\.')) ||
          line.startsWith('-') ||
          line.startsWith('*')) {
        if (currentType != 'list') {
          if (currentSection.isNotEmpty) {
            sections.add(DocumentSection(
              type: currentType,
              content: currentSection.toString().trim(),
            ));
            currentSection.clear();
          }
          currentType = 'list';
        }
      } else {
        if (currentType != 'body') {
          if (currentSection.isNotEmpty) {
            sections.add(DocumentSection(
              type: currentType,
              content: currentSection.toString().trim(),
            ));
            currentSection.clear();
          }
          currentType = 'body';
        }
      }

      currentSection.writeln(line);
    }

    // Add final section
    if (currentSection.isNotEmpty) {
      sections.add(DocumentSection(
        type: currentType,
        content: currentSection.toString().trim(),
      ));
    }

    return sections.isEmpty
        ? [DocumentSection(type: 'body', content: content)]
        : sections;
  }

  Future<Map<String, dynamic>> _translateDocumentMetadata(
    String documentPath,
    String content,
    String targetLanguage,
  ) async {
    final metadata = <String, dynamic>{};

    // Extract basic metadata
    final fileName = documentPath.split('/').last;
    final extension = fileName.split('.').last;

    // Translate filename if it contains meaningful text
    if (fileName.contains(RegExp(r'[a-zA-Z]'))) {
      try {
        final nameTranslation = await translateText(
          text: fileName,
          targetLanguage: targetLanguage,
          options: TranslationOptions(preserveFormatting: true),
        );
        metadata['translated_filename'] = nameTranslation.translatedText;
      } catch (e) {
        metadata['translated_filename'] = fileName;
      }
    }

    metadata['original_filename'] = fileName;
    metadata['file_extension'] = extension;
    metadata['content_length'] = content.length;
    metadata['estimated_reading_time'] = _estimateReadingTime(content);

    return metadata;
  }

  int _estimateReadingTime(String content) {
    // Rough estimate: 200 words per minute
    final wordCount = content.split(RegExp(r'\s+')).length;
    return (wordCount / 200).ceil();
  }

  Future<void> _updateLanguageProfile(
      String sourceLang, String targetLang, double confidence) async {
    final profile = _languageProfiles[targetLang];
    if (profile != null) {
      profile.translationCount++;
      profile.averageQuality =
          ((profile.averageQuality * (profile.translationCount - 1)) +
                  confidence) /
              profile.translationCount;
    }
  }

  Map<String, int> _getLanguageUsageStats() {
    final stats = <String, int>{};
    for (final request in _translationHistory) {
      stats[request.sourceLanguage] = (stats[request.sourceLanguage] ?? 0) + 1;
      stats[request.targetLanguage] = (stats[request.targetLanguage] ?? 0) + 1;
    }
    return stats;
  }

  String _generateCacheKey(String text, String targetLanguage,
      String? sourceLanguage, String? context) {
    final textHash = text.hashCode;
    final contextHash = context?.hashCode ?? 0;
    final sourceHash = sourceLanguage?.hashCode ?? 0;
    return '${textHash}_${targetLanguage.hashCode}_${sourceHash}_${contextHash}';
  }

  bool _isCacheExpired(TranslationResult result) {
    final cacheTTL = Duration(
        seconds: _config.getParameter('ai.cache.ttl', defaultValue: 3600));
    return DateTime.now().difference(result.translationTime) > cacheTTL;
  }

  void _cleanupTranslationCache() {
    final maxSize =
        _config.getParameter('ai.cache.max_size', defaultValue: 100);
    if (_translationCache.length > maxSize) {
      // Remove oldest entries
      final entries = _translationCache.entries.toList()
        ..sort((a, b) =>
            a.value.translationTime.compareTo(b.value.translationTime));

      final toRemove = entries.take(_translationCache.length - maxSize);
      for (final entry in toRemove) {
        _translationCache.remove(entry.key);
      }
    }

    // Keep translation history manageable
    if (_translationHistory.length > 1000) {
      _translationHistory.removeRange(0, _translationHistory.length - 1000);
    }
  }

  // Getters
  bool get isInitialized => _isInitialized;
  Map<String, LanguageProfile> get languageProfiles =>
      Map.from(_languageProfiles);
  List<TranslationRequest> get translationHistory =>
      List.from(_translationHistory);
}

/// Supporting data classes

class TranslationResult {
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final double confidence;
  final DateTime translationTime;
  final String? error;

  TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.confidence,
    required this.translationTime,
    this.error,
  });
}

class TranslationRequest {
  final String id;
  final String originalText;
  final String sourceLanguage;
  final String targetLanguage;
  final String? context;
  final TranslationOptions? options;
  final DateTime timestamp;
  double? confidence;

  TranslationRequest({
    required this.id,
    required this.originalText,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.context,
    this.options,
    required this.timestamp,
    this.confidence,
  });
}

class TranslationOptions {
  final bool preserveFormatting;
  final bool technicalTerms;
  final bool formalTone;
  final String? domain; // e.g., 'technical', 'medical', 'legal'

  TranslationOptions({
    this.preserveFormatting = true,
    this.technicalTerms = true,
    this.formalTone = false,
    this.domain,
  });
}

class DocumentTranslationResult {
  final String documentPath;
  final String originalContent;
  final String translatedContent;
  final String sourceLanguage;
  final String targetLanguage;
  final List<DocumentSection> sections;
  final Map<String, dynamic> metadata;
  final DateTime translationTime;
  double confidence = 0.0;
  final String? error;

  DocumentTranslationResult({
    required this.documentPath,
    required this.originalContent,
    required this.translatedContent,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.sections,
    required this.metadata,
    required this.translationTime,
    this.error,
  });
}

class DocumentTranslationOptions {
  final bool preserveTechnicalTerms;
  final bool preserveFormatting;
  final String? documentType;
  final List<String>? prioritySections;

  DocumentTranslationOptions({
    this.preserveTechnicalTerms = true,
    this.preserveFormatting = true,
    this.documentType,
    this.prioritySections,
  });
}

class DocumentSection {
  final String type; // header, body, list, etc.
  final String originalContent;
  final String translatedContent;
  final double confidence;

  DocumentSection({
    required this.type,
    required this.originalContent,
    required this.translatedContent,
    required this.confidence,
  });
}

class LanguageProfile {
  final String languageCode;
  final String languageName;
  int translationCount;
  double averageQuality;
  final List<String> commonPhrases;
  final List<String> technicalTerms;

  LanguageProfile({
    required this.languageCode,
    required this.languageName,
    required this.translationCount,
    required this.averageQuality,
    required this.commonPhrases,
    required this.technicalTerms,
  });
}

class TranslationStatistics {
  final int totalTranslations;
  final int uniqueLanguagePairs;
  final double averageConfidence;
  final List<String> mostUsedPairs;
  final Map<String, int> languageUsage;

  TranslationStatistics({
    required this.totalTranslations,
    required this.uniqueLanguagePairs,
    required this.averageConfidence,
    required this.mostUsedPairs,
    required this.languageUsage,
  });
}

/// Simple semaphore implementation for concurrency control
class _Semaphore {
  final int maxCount;
  int _currentCount = 0;
  final List<Completer<void>> _waitQueue = [];

  _Semaphore(this.maxCount);

  Future<void> acquire() async {
    if (_currentCount < maxCount) {
      _currentCount++;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    _currentCount--;
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeAt(0);
      _currentCount++;
      completer.complete();
    }
  }
}
