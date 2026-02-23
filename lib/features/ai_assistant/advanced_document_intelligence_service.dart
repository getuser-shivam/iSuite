import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mime/mime.dart';
import 'logging_service.dart';
import 'central_config.dart';

/// Advanced Document Intelligence Service using AI/LLM
///
/// Provides comprehensive document analysis, categorization, and intelligence features:
/// - Automated document classification and organization
/// - Metadata extraction and generation
/// - Intelligent summarization
/// - Content analysis and insights
/// - Semantic search enhancement
/// - PII detection and security analysis
class AdvancedDocumentIntelligenceService {
  static final AdvancedDocumentIntelligenceService _instance =
      AdvancedDocumentIntelligenceService._internal();
  factory AdvancedDocumentIntelligenceService() => _instance;
  AdvancedDocumentIntelligenceService._internal();

  final LoggingService _logger = LoggingService();
  final CentralConfig _config = CentralConfig.instance;

  GenerativeModel? _model;
  bool _isInitialized = false;
  final Map<String, DocumentAnalysis> _analysisCache = {};

  /// Initialize the document intelligence service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Advanced Document Intelligence Service', 'DocumentIntelligence');

      // Check if AI features are enabled
      final aiEnabled = _config.getParameter('ai.enabled', defaultValue: true);
      if (!aiEnabled) {
        _logger.info('AI features disabled, Document Intelligence Service will operate in limited mode', 'DocumentIntelligence');
        _isInitialized = true;
        return;
      }

      // Initialize AI model based on configuration
      await _initializeAIModel();

      _isInitialized = true;
      _logger.info('Document Intelligence Service initialized successfully', 'DocumentIntelligence');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Document Intelligence Service', 'DocumentIntelligence',
          error: e, stackTrace: stackTrace);
      // Continue with limited functionality
      _isInitialized = true;
    }
  }

  Future<void> _initializeAIModel() async {
    try {
      final provider = _config.getParameter('ai.llm_provider', defaultValue: 'google');
      final apiKey = _config.getParameter('ai.api_key', defaultValue: '');
      final modelName = _config.getParameter('ai.model_name', defaultValue: 'gemini-1.5-flash');

      if (provider == 'google' && apiKey.isNotEmpty) {
        _model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: _config.getParameter('ai.temperature', defaultValue: 0.7),
            maxOutputTokens: _config.getParameter('ai.max_tokens', defaultValue: 2048),
          ),
        );
        _logger.info('Google Gemini AI model initialized', 'DocumentIntelligence');
      } else {
        _logger.warning('AI provider not configured or API key missing', 'DocumentIntelligence');
      }
    } catch (e) {
      _logger.error('Failed to initialize AI model', 'DocumentIntelligence', error: e);
    }
  }

  /// Analyze document content and extract intelligence
  Future<DocumentAnalysis> analyzeDocument({
    required String filePath,
    required String content,
    String? mimeType,
    Map<String, dynamic>? existingMetadata,
  }) async {
    if (!_isInitialized) await initialize();

    // Check cache first
    final cacheKey = _generateCacheKey(filePath, content.hashCode);
    if (_analysisCache.containsKey(cacheKey)) {
      return _analysisCache[cacheKey]!;
    }

    try {
      _logger.info('Analyzing document: $filePath', 'DocumentIntelligence');

      final analysis = DocumentAnalysis(
        filePath: filePath,
        fileName: _extractFileName(filePath),
        mimeType: mimeType ?? lookupMimeType(filePath) ?? 'application/octet-stream',
        fileSize: content.length,
        analyzedAt: DateTime.now(),
      );

      // Extract basic metadata
      analysis.metadata = await _extractBasicMetadata(filePath, content, existingMetadata);

      // Perform AI-powered analysis if available
      if (_model != null && _config.getParameter('ai.document_analysis.enabled', defaultValue: true)) {
        await _performAIAnalysis(analysis, content);
      }

      // Cache the analysis
      if (_config.getParameter('ai.cache.enabled', defaultValue: true)) {
        _analysisCache[cacheKey] = analysis;
        _cleanupAnalysisCache();
      }

      _logger.info('Document analysis completed for: $filePath', 'DocumentIntelligence');
      return analysis;

    } catch (e, stackTrace) {
      _logger.error('Document analysis failed for: $filePath', 'DocumentIntelligence',
          error: e, stackTrace: stackTrace);

      // Return basic analysis on failure
      return DocumentAnalysis(
        filePath: filePath,
        fileName: _extractFileName(filePath),
        mimeType: mimeType ?? 'application/octet-stream',
        fileSize: content.length,
        analyzedAt: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> _extractBasicMetadata(
    String filePath,
    String content,
    Map<String, dynamic>? existingMetadata,
  ) async {
    final metadata = <String, dynamic>{};

    // Extract from existing metadata
    if (existingMetadata != null) {
      metadata.addAll(existingMetadata);
    }

    // Extract file system metadata
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        metadata['file_size'] = stat.size;
        metadata['created'] = stat.changed.toIso8601String();
        metadata['modified'] = stat.modified.toIso8601String();
        metadata['accessed'] = stat.accessed.toIso8601String();
      }
    } catch (e) {
      _logger.warning('Failed to extract file system metadata', 'DocumentIntelligence', error: e);
    }

    // Extract content-based metadata
    metadata['content_length'] = content.length;
    metadata['line_count'] = content.split('\n').length;
    metadata['word_count'] = _countWords(content);

    // Detect encoding
    metadata['encoding'] = _detectEncoding(content);

    return metadata;
  }

  Future<void> _performAIAnalysis(DocumentAnalysis analysis, String content) async {
    if (_model == null) return;

    try {
      final prompt = _buildAnalysisPrompt(analysis, content);
      final response = await _model!.generateContent([Content.text(prompt)]);
      final analysisResult = response.text;

      if (analysisResult != null) {
        final aiInsights = _parseAIResponse(analysisResult);
        analysis.aiInsights = aiInsights;
        analysis.confidence = aiInsights['confidence'] ?? 0.5;
      }
    } catch (e) {
      _logger.warning('AI analysis failed, continuing with basic analysis', 'DocumentIntelligence', error: e);
    }
  }

  String _buildAnalysisPrompt(DocumentAnalysis analysis, String content) {
    final mimeType = analysis.mimeType;
    final fileName = analysis.fileName;
    final sampleContent = content.length > 2000 ? content.substring(0, 2000) + '...' : content;

    return '''
Analyze this document and provide comprehensive intelligence:

FILE INFORMATION:
- Name: $fileName
- Type: $mimeType
- Size: ${analysis.fileSize} characters

CONTENT SAMPLE:
$sampleContent

Please provide:
1. DOCUMENT_TYPE: Classify the document type (e.g., invoice, report, code, document, image, etc.)
2. CATEGORY: Suggest appropriate categories/tags for organization
3. SUMMARY: Brief summary of the document content (2-3 sentences)
4. KEY_TOPICS: Main topics or subjects covered
5. SENTIMENT: Overall sentiment (positive, negative, neutral)
6. LANGUAGE: Primary language used
7. SENSITIVE_CONTENT: Any sensitive information detected (PII, financial data, etc.)
8. SEARCH_KEYWORDS: Important keywords for search indexing
9. PRIORITY_LEVEL: Suggested priority (high, medium, low)
10. ACTION_ITEMS: Any action items or tasks mentioned
11. CONFIDENCE: Your confidence in this analysis (0.0-1.0)

Format your response as JSON with these keys.
''';
  }

  Map<String, dynamic> _parseAIResponse(String response) {
    try {
      // Extract JSON from response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd);
        return json.decode(jsonStr);
      }
    } catch (e) {
      _logger.warning('Failed to parse AI response as JSON', 'DocumentIntelligence', error: e);
    }

    // Fallback: extract information manually
    return _extractInsightsManually(response);
  }

  Map<String, dynamic> _extractInsightsManually(String response) {
    final insights = <String, dynamic>{};

    // Simple pattern matching for key information
    final lines = response.split('\n');
    for (final line in lines) {
      if (line.contains('DOCUMENT_TYPE:')) {
        insights['document_type'] = line.split(':').last.trim();
      } else if (line.contains('CATEGORY:')) {
        insights['categories'] = line.split(':').last.trim().split(',').map((s) => s.trim()).toList();
      } else if (line.contains('SUMMARY:')) {
        insights['summary'] = line.split(':').last.trim();
      } else if (line.contains('LANGUAGE:')) {
        insights['language'] = line.split(':').last.trim();
      } else if (line.contains('CONFIDENCE:')) {
        final confidenceStr = line.split(':').last.trim();
        insights['confidence'] = double.tryParse(confidenceStr) ?? 0.5;
      }
    }

    // Set defaults for missing information
    insights.putIfAbsent('document_type', () => 'unknown');
    insights.putIfAbsent('categories', () => ['uncategorized']);
    insights.putIfAbsent('summary', () => 'No summary available');
    insights.putIfAbsent('language', () => 'unknown');
    insights.putIfAbsent('confidence', () => 0.5);

    return insights;
  }

  /// Generate smart search suggestions
  Future<List<String>> generateSearchSuggestions(String query, List<DocumentAnalysis> availableDocuments) async {
    if (!_isInitialized || _model == null) {
      return _generateBasicSuggestions(query, availableDocuments);
    }

    try {
      final context = availableDocuments.take(10).map((doc) =>
        '${doc.fileName}: ${doc.aiInsights?['summary'] ?? 'No summary'}'
      ).join('\n');

      final prompt = '''
Based on the user's search query: "$query"

And considering these available documents:
$context

Generate 5-10 smart search suggestions that would help the user find relevant information.
Consider semantic meaning, related concepts, and different ways to phrase the search.

Return only the suggestions as a numbered list, one per line.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final suggestions = response.text?.split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.replaceAll(RegExp(r'^\d+\.\s*'), '').trim())
          .where((line) => line.isNotEmpty)
          .take(10)
          .toList() ?? [];

      return suggestions.isNotEmpty ? suggestions : _generateBasicSuggestions(query, availableDocuments);

    } catch (e) {
      _logger.warning('AI search suggestions failed, using basic suggestions', 'DocumentIntelligence', error: e);
      return _generateBasicSuggestions(query, availableDocuments);
    }
  }

  List<String> _generateBasicSuggestions(String query, List<DocumentAnalysis> availableDocuments) {
    // Basic suggestions based on file names and types
    final suggestions = <String>[];

    final queryLower = query.toLowerCase();

    for (final doc in availableDocuments) {
      final fileName = doc.fileName.toLowerCase();
      if (fileName.contains(queryLower)) {
        suggestions.add(doc.fileName);
      }
    }

    // Add common variations
    if (queryLower.contains('report')) {
      suggestions.addAll(['monthly report', 'annual report', 'weekly report']);
    } else if (queryLower.contains('invoice')) {
      suggestions.addAll(['pending invoice', 'paid invoice', 'overdue invoice']);
    }

    return suggestions.take(5).toList();
  }

  /// Detect sensitive content and PII
  Future<SensitivityAnalysis> analyzeSensitivity(String content) async {
    if (!_isInitialized) await initialize();

    final analysis = SensitivityAnalysis(
      contentLength: content.length,
      analyzedAt: DateTime.now(),
    );

    // Basic pattern-based detection
    analysis.containsPII = _containsPII(content);
    analysis.containsFinancial = _containsFinancialData(content);
    analysis.containsHealth = _containsHealthData(content);
    analysis.sensitivityLevel = _calculateSensitivityLevel(analysis);

    // AI-powered analysis if available
    if (_model != null && _config.getParameter('ai.security.pii_detection', defaultValue: true)) {
      await _performAISensitivityAnalysis(analysis, content);
    }

    return analysis;
  }

  bool _containsPII(String content) {
    // Basic PII detection patterns
    final piiPatterns = [
      RegExp(r'\b\d{3}-\d{2}-\d{4}\b'), // SSN
      RegExp(r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b'), // Credit card
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'), // Email
      RegExp(r'\b\d{3}[-\s]?\d{3}[-\s]?\d{4}\b'), // Phone
    ];

    return piiPatterns.any((pattern) => pattern.hasMatch(content));
  }

  bool _containsFinancialData(String content) {
    final financialPatterns = [
      RegExp(r'\$\d+(?:\.\d{2})?'), // Dollar amounts
      RegExp(r'\b\d+(?:\.\d{2})?\s*(?:USD|EUR|GBP)\b'), // Currency amounts
      RegExp(r'\baccount\s+number\b', caseSensitive: false),
      RegExp(r'\bbank\s+account\b', caseSensitive: false),
    ];

    return financialPatterns.any((pattern) => pattern.hasMatch(content));
  }

  bool _containsHealthData(String content) {
    final healthPatterns = [
      RegExp(r'\b(?:diagnosis|treatment|medication|prescription)\b', caseSensitive: false),
      RegExp(r'\b(?:patient|medical|health|clinical)\b', caseSensitive: false),
    ];

    return healthPatterns.any((pattern) => pattern.hasMatch(content));
  }

  String _calculateSensitivityLevel(SensitivityAnalysis analysis) {
    if (analysis.containsPII || analysis.containsFinancial) {
      return 'high';
    } else if (analysis.containsHealth) {
      return 'medium';
    }
    return 'low';
  }

  Future<void> _performAISensitivityAnalysis(SensitivityAnalysis analysis, String content) async {
    if (_model == null) return;

    try {
      final sampleContent = content.length > 1000 ? content.substring(0, 1000) + '...' : content;

      final prompt = '''
Analyze this content for sensitive information and provide a detailed security assessment:

CONTENT:
$sampleContent

Please identify:
1. SENSITIVE_DATA_TYPES: Types of sensitive data found (PII, financial, health, etc.)
2. RISK_LEVEL: Overall risk level (low, medium, high, critical)
3. RECOMMENDATIONS: Security recommendations for handling this content
4. COMPLIANCE_CONCERNS: Any compliance issues (GDPR, HIPAA, etc.)

Format as JSON with these keys.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final result = response.text;

      if (result != null) {
        analysis.aiSecurityInsights = _parseAIResponse(result);
      }
    } catch (e) {
      _logger.warning('AI sensitivity analysis failed', 'DocumentIntelligence', error: e);
    }
  }

  /// Generate document organization suggestions
  Future<OrganizationSuggestions> generateOrganizationSuggestions(List<DocumentAnalysis> documents) async {
    if (!_isInitialized) await initialize();

    final suggestions = OrganizationSuggestions(
      generatedAt: DateTime.now(),
      totalDocuments: documents.length,
    );

    // Basic organization logic
    suggestions.folderStructure = _generateBasicFolderStructure(documents);
    suggestions.tagSuggestions = _generateTagSuggestions(documents);

    // AI-powered suggestions if available
    if (_model != null && _config.getParameter('ai.organization.enabled', defaultValue: true)) {
      await _generateAIOrganizationSuggestions(suggestions, documents);
    }

    return suggestions;
  }

  Map<String, List<String>> _generateBasicFolderStructure(List<DocumentAnalysis> documents) {
    final structure = <String, List<String>>{};

    for (final doc in documents) {
      final type = doc.aiInsights?['document_type'] ?? 'unknown';
      final category = (doc.aiInsights?['categories'] as List?)?.first ?? 'uncategorized';

      if (!structure.containsKey(category)) {
        structure[category] = [];
      }
      structure[category]!.add(doc.fileName);
    }

    return structure;
  }

  List<String> _generateTagSuggestions(List<DocumentAnalysis> documents) {
    final tags = <String>{};

    for (final doc in documents) {
      final docTags = doc.aiInsights?['categories'] as List?;
      if (docTags != null) {
        tags.addAll(docTags.map((tag) => tag.toString()));
      }
    }

    return tags.toList();
  }

  Future<void> _generateAIOrganizationSuggestions(OrganizationSuggestions suggestions, List<DocumentAnalysis> documents) async {
    if (_model == null) return;

    try {
      final documentSummary = documents.take(20).map((doc) =>
        '${doc.fileName}: ${doc.aiInsights?['document_type'] ?? 'unknown'} - ${doc.aiInsights?['summary'] ?? 'No summary'}'
      ).join('\n');

      final prompt = '''
Based on these documents, suggest an optimal folder structure and organization strategy:

DOCUMENTS:
$documentSummary

Please provide:
1. FOLDER_STRUCTURE: Suggest a hierarchical folder structure
2. NAMING_CONVENTIONS: Recommended file naming conventions
3. TAGGING_STRATEGY: How to tag and categorize documents
4. ARCHIVAL_POLICY: When and how to archive old documents
5. COLLABORATION_SETUP: How to organize for team collaboration

Format as JSON with these keys.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final result = response.text;

      if (result != null) {
        suggestions.aiOrganizationInsights = _parseAIResponse(result);
      }
    } catch (e) {
      _logger.warning('AI organization suggestions failed', 'DocumentIntelligence', error: e);
    }
  }

  // Utility methods
  String _extractFileName(String filePath) {
    return filePath.split(Platform.pathSeparator).last;
  }

  int _countWords(String content) {
    return content.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  String _detectEncoding(String content) {
    // Simple encoding detection - in a real implementation, use a proper library
    return 'utf-8';
  }

  String _generateCacheKey(String filePath, int contentHash) {
    return '${filePath.hashCode}_${contentHash}';
  }

  void _cleanupAnalysisCache() {
    final maxSize = _config.getParameter('ai.cache.max_size', defaultValue: 100);
    if (_analysisCache.length > maxSize) {
      // Remove oldest entries (simple implementation)
      final entriesToRemove = _analysisCache.length - maxSize;
      final keysToRemove = _analysisCache.keys.take(entriesToRemove).toList();
      for (final key in keysToRemove) {
        _analysisCache.remove(key);
      }
    }
  }

  bool get isInitialized => _isInitialized;
  bool get aiEnabled => _model != null;
}

/// Document Analysis Result
class DocumentAnalysis {
  final String filePath;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final DateTime analyzedAt;
  Map<String, dynamic> metadata = {};
  Map<String, dynamic>? aiInsights;
  double confidence = 0.0;
  String? error;

  DocumentAnalysis({
    required this.filePath,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.analyzedAt,
    this.aiInsights,
    this.confidence = 0.0,
    this.error,
  });
}

/// Sensitivity Analysis Result
class SensitivityAnalysis {
  final int contentLength;
  final DateTime analyzedAt;
  bool containsPII = false;
  bool containsFinancial = false;
  bool containsHealth = false;
  String sensitivityLevel = 'low';
  Map<String, dynamic>? aiSecurityInsights;

  SensitivityAnalysis({
    required this.contentLength,
    required this.analyzedAt,
  });
}

/// Organization Suggestions
class OrganizationSuggestions {
  final DateTime generatedAt;
  final int totalDocuments;
  Map<String, List<String>> folderStructure = {};
  List<String> tagSuggestions = [];
  Map<String, dynamic>? aiOrganizationInsights;

  OrganizationSuggestions({
    required this.generatedAt,
    required this.totalDocuments,
  });
}
