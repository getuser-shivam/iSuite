import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'central_config.dart';
import 'logging_service.dart';

/// Generative AI Service for iSuite
/// Provides AI-powered content generation, summarization, and analysis
class GenerativeAIService {
  static final GenerativeAIService _instance = GenerativeAIService._internal();
  factory GenerativeAIService() => _instance;
  GenerativeAIService._internal();

  final LoggingService _logger = LoggingService();
  final CentralConfig _config = CentralConfig.instance;

  GenerativeModel? _model;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize the Generative AI service
  Future<void> initialize() async {
    if (_isInitialized) return;

    final apiKey = _config.getParameter('ai.api_key', defaultValue: '');
    if (apiKey.isEmpty) {
      _logger.warning('AI API key not configured', 'GenerativeAIService');
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );

    _isInitialized = true;
    _logger.info('Generative AI service initialized', 'GenerativeAIService');
  }

  /// Generate a summary of the given content
  Future<String> generateSummary(String content) async {
    if (!_isInitialized || _model == null) {
      return 'AI service not initialized';
    }

    try {
      final prompt = 'Please provide a concise summary of the following content:\n\n$content';
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'No summary generated';
    } catch (e) {
      _logger.error('Error generating summary: $e', 'GenerativeAIService');
      return 'Error generating summary: $e';
    }
  }

  /// Analyze file content and provide insights
  Future<String> analyzeFileContent(String fileName, String content) async {
    if (!_isInitialized || _model == null) {
      return 'AI service not initialized';
    }

    try {
      final prompt = '''
Analyze this file: $fileName

Content:
$content

Please provide:
1. A brief description of what this file contains
2. Key insights or important information
3. Suggested category or tags
4. Any recommendations for organization

Keep the response concise and actionable.
''';
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'No analysis generated';
    } catch (e) {
      _logger.error('Error analyzing file: $e', 'GenerativeAIService');
      return 'Error analyzing file: $e';
    }
  }

  /// Generate smart file naming suggestions
  Future<List<String>> suggestFileNames(String content, {String? fileType}) async {
    if (!_isInitialized || _model == null) {
      return ['AI service not initialized'];
    }

    try {
      final typeInfo = fileType != null ? ' (file type: $fileType)' : '';
      final prompt = '''
Based on this content$typeInfo, suggest 3-5 appropriate file names that would be descriptive and organized:

Content:
$content

Provide only the file names, one per line, without extensions.
''';
      final response = await _model!.generateContent([Content.text(prompt)]);
      final suggestions = response.text?.split('\n')
          .where((line) => line.trim().isNotEmpty)
          .take(5)
          .map((line) => line.trim().replaceAll(RegExp(r'^[-\d\.\s]*'), ''))
          .toList() ?? [];
      return suggestions.isEmpty ? ['No suggestions generated'] : suggestions;
    } catch (e) {
      _logger.error('Error suggesting names: $e', 'GenerativeAIService');
      return ['Error generating suggestions'];
    }
  }
}
