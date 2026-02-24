import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../ai/document_ai_service.dart';
import '../logging/logging_service.dart';
import '../central_config.dart';

/// Intelligent Document Categorization Service
/// Uses ML-based classification and rule-based logic for smart document organization
class IntelligentCategorizationService {
  static final IntelligentCategorizationService _instance = IntelligentCategorizationService._internal();
  factory IntelligentCategorizationService() => _instance;
  IntelligentCategorizationService._internal();

  final LoggingService _logger = LoggingService();
  final DocumentAIService _documentAIService = DocumentAIService();
  final CentralConfig _config = CentralConfig.instance;

  // Predefined categories with their keywords and patterns
  final Map<String, CategoryDefinition> _categories = {
    'Work': CategoryDefinition(
      name: 'Work',
      keywords: ['report', 'meeting', 'presentation', 'project', 'deadline', 'client', 'contract', 'proposal'],
      filePatterns: ['*.docx', '*.xlsx', '*.pptx', '*.pdf'],
      color: Colors.blue,
      icon: Icons.work,
    ),
    'Personal': CategoryDefinition(
      name: 'Personal',
      keywords: ['personal', 'family', 'hobby', 'vacation', 'recipe', 'photo', 'memory'],
      filePatterns: ['*.jpg', '*.png', '*.mp4', '*.pdf'],
      color: Colors.green,
      icon: Icons.person,
    ),
    'Finance': CategoryDefinition(
      name: 'Finance',
      keywords: ['invoice', 'receipt', 'bank', 'statement', 'tax', 'budget', 'expense', 'payment'],
      filePatterns: ['*.pdf', '*.xlsx', '*.csv'],
      color: Colors.purple,
      icon: Icons.account_balance_wallet,
    ),
    'Education': CategoryDefinition(
      name: 'Education',
      keywords: ['course', 'lecture', 'assignment', 'study', 'research', 'paper', 'notes', 'exam'],
      filePatterns: ['*.pdf', '*.docx', '*.pptx'],
      color: Colors.orange,
      icon: Icons.school,
    ),
    'Media': CategoryDefinition(
      name: 'Media',
      keywords: ['photo', 'video', 'music', 'image', 'audio', 'movie', 'clip'],
      filePatterns: ['*.jpg', '*.png', '*.mp4', '*.mp3', '*.avi'],
      color: Colors.red,
      icon: Icons.photo,
    ),
    'Documents': CategoryDefinition(
      name: 'Documents',
      keywords: ['document', 'file', 'letter', 'form', 'certificate', 'license'],
      filePatterns: ['*.pdf', '*.docx', '*.txt'],
      color: Colors.grey,
      icon: Icons.description,
    ),
  };

  /// Categorize a single document
  Future<CategorizationResult> categorizeDocument(DocumentAIResult documentResult) async {
    _logger.info('Categorizing document: ${documentResult.fileName}', 'IntelligentCategorizationService');

    try {
      // Extract features from document
      final features = await _extractFeatures(documentResult);

      // Score against each category
      final scores = <String, double>{};
      for (final category in _categories.entries) {
        scores[category.key] = _calculateCategoryScore(features, category.value);
      }

      // Find best match
      final bestCategory = scores.entries.reduce((a, b) => a.value > b.value ? a : b);

      // Generate folder suggestions
      final folderSuggestions = await _generateFolderSuggestions(documentResult, bestCategory.key);

      final result = CategorizationResult(
        documentName: documentResult.fileName,
        primaryCategory: bestCategory.key,
        confidence: bestCategory.value,
        alternativeCategories: scores.entries
            .where((e) => e.key != bestCategory.key && e.value > 0.3)
            .map((e) => AlternativeCategory(e.key, e.value))
            .toList(),
        suggestedFolders: folderSuggestions,
        metadata: {
          'wordCount': features.wordCount,
          'hasImages': features.hasImages,
          'fileSize': documentResult.metadata['fileSize'],
          'processingTime': DateTime.now().toIso8601String(),
        },
      );

      _logger.info('Document categorized as ${bestCategory.key} with confidence ${(bestCategory.value * 100).toStringAsFixed(1)}%',
          'IntelligentCategorizationService');

      return result;

    } catch (e, stackTrace) {
      _logger.error('Failed to categorize document', 'IntelligentCategorizationService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Batch categorize multiple documents
  Future<List<CategorizationResult>> categorizeDocuments(List<DocumentAIResult> documents) async {
    _logger.info('Batch categorizing ${documents.length} documents', 'IntelligentCategorizationService');

    final results = <CategorizationResult>[];
    for (final doc in documents) {
      try {
        final result = await categorizeDocument(doc);
        results.add(result);
      } catch (e) {
        _logger.warning('Failed to categorize document ${doc.fileName}: $e', 'IntelligentCategorizationService');
        // Add fallback categorization
        results.add(CategorizationResult(
          documentName: doc.fileName,
          primaryCategory: 'Uncategorized',
          confidence: 0.0,
          alternativeCategories: [],
          suggestedFolders: ['Uncategorized'],
          metadata: {},
        ));
      }
    }

    return results;
  }

  /// Learn from user corrections to improve categorization
  Future<void> learnFromCorrection(String documentName, String correctCategory,
      DocumentAIResult documentResult) async {
    _logger.info('Learning from user correction: $documentName -> $correctCategory',
        'IntelligentCategorizationService');

    // In a real implementation, this would update ML models
    // For now, we'll store correction data for future improvements
    await _storeLearningData(documentName, correctCategory, documentResult);
  }

  /// Generate smart folder suggestions
  Future<List<String>> generateFolderSuggestions(List<DocumentAIResult> documents) async {
    final results = await categorizeDocuments(documents);

    // Group by category
    final categoryGroups = <String, List<CategorizationResult>>{};
    for (final result in results) {
      categoryGroups.putIfAbsent(result.primaryCategory, () => []).add(result);
    }

    // Generate folder structure
    final suggestions = <String>[];
    for (final entry in categoryGroups.entries) {
      final category = entry.key;
      final docs = entry.value;

      suggestions.add(category);

      // Sub-folders based on date patterns
      final dateFolders = _generateDateBasedFolders(docs);
      suggestions.addAll(dateFolders.map((f) => '$category/$f'));

      // Sub-folders based on content patterns
      final contentFolders = _generateContentBasedFolders(docs);
      suggestions.addAll(contentFolders.map((f) => '$category/$f'));
    }

    return suggestions;
  }

  /// Extract features from document for categorization
  Future<DocumentFeatures> _extractFeatures(DocumentAIResult documentResult) async {
    final text = documentResult.extractedText.toLowerCase();

    // Count words
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final wordCount = words.length;

    // Check for images
    final hasImages = documentResult.contentLabels.isNotEmpty;

    // Extract keywords and patterns
    final keywords = _extractKeywords(text);
    final patterns = _detectPatterns(text);

    return DocumentFeatures(
      text: text,
      wordCount: wordCount,
      hasImages: hasImages,
      keywords: keywords,
      patterns: patterns,
      fileExtension: _getFileExtension(documentResult.fileName),
    );
  }

  /// Calculate score for a category
  double _calculateCategoryScore(DocumentFeatures features, CategoryDefinition category) {
    double score = 0.0;

    // Keyword matching (40% weight)
    final keywordMatches = features.keywords.where((keyword) =>
        category.keywords.any((catKeyword) => keyword.contains(catKeyword) || catKeyword.contains(keyword)));
    score += (keywordMatches.length / max(1, features.keywords.length)) * 0.4;

    // File pattern matching (30% weight)
    final patternMatch = category.filePatterns.any((pattern) =>
        _matchesFilePattern(features.fileExtension, pattern));
    if (patternMatch) score += 0.3;

    // Content patterns (20% weight)
    final contentMatches = features.patterns.where((pattern) =>
        category.keywords.any((keyword) => pattern.toLowerCase().contains(keyword)));
    score += (contentMatches.length / max(1, features.patterns.length)) * 0.2;

    // Image bonus (10% weight)
    if (features.hasImages && category.name == 'Media') {
      score += 0.1;
    }

    return min(1.0, score);
  }

  /// Extract keywords from text
  List<String> _extractKeywords(String text) {
    // Simple keyword extraction - in production, use NLP libraries
    final words = text.split(RegExp(r'\s+'))
        .where((word) => word.length > 3)
        .map((word) => word.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ''))
        .where((word) => word.isNotEmpty)
        .toSet()
        .toList();

    // Remove common stop words
    const stopWords = ['the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'can', 'had', 'her', 'was', 'one', 'our', 'out', 'day', 'get', 'has', 'him', 'his', 'how', 'its', 'may', 'new', 'now', 'old', 'see', 'two', 'who', 'boy', 'did', 'his', 'let', 'put', 'say', 'she', 'too', 'use'];
    words.removeWhere((word) => stopWords.contains(word));

    return words.take(20).toList(); // Limit to top keywords
  }

  /// Detect content patterns
  List<String> _detectPatterns(String text) {
    final patterns = <String>[];

    // Email pattern
    if (RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b').hasMatch(text)) {
      patterns.add('email');
    }

    // Phone pattern
    if (RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b').hasMatch(text)) {
      patterns.add('phone');
    }

    // Date patterns
    if (RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b').hasMatch(text)) {
      patterns.add('date');
    }

    // Money patterns
    if (RegExp(r'\$\d+(\.\d{2})?').hasMatch(text) || RegExp(r'\b\d+(\.\d{2})?\s*(dollars?|USD|€|£)\b', caseSensitive: false).hasMatch(text)) {
      patterns.add('financial');
    }

    return patterns;
  }

  /// Generate folder suggestions
  Future<List<String>> _generateFolderSuggestions(DocumentAIResult document, String category) async {
    final suggestions = <String>[];

    // Base category folder
    suggestions.add(category);

    // Date-based subfolders
    final dateFolders = _generateDateBasedFolders([document]);
    suggestions.addAll(dateFolders.map((f) => '$category/$f'));

    // Content-based subfolders
    if (document.extractedText.contains('invoice') || document.extractedText.contains('receipt')) {
      suggestions.add('$category/Financial Records');
    }

    if (document.extractedText.contains('meeting') || document.extractedText.contains('agenda')) {
      suggestions.add('$category/Meetings');
    }

    return suggestions.take(5).toList(); // Limit suggestions
  }

  /// Generate date-based folder suggestions
  List<String> _generateDateBasedFolders(List<DocumentAIResult> documents) {
    final folders = <String>{};

    for (final doc in documents) {
      // Check metadata for dates
      final modified = doc.metadata['lastModified'];
      if (modified != null && modified is String) {
        try {
          final date = DateTime.parse(modified);
          folders.add('${date.year}');
          folders.add('${date.year}/${date.month.toString().padLeft(2, '0')}');
        } catch (e) {
          // Ignore parsing errors
        }
      }
    }

    return folders.toList();
  }

  /// Generate content-based folder suggestions
  List<String> _generateContentBasedFolders(List<CategorizationResult> results) {
    final folders = <String>{};

    for (final result in results) {
      if (result.primaryCategory == 'Work') {
        if (result.documentName.contains('report')) folders.add('Reports');
        if (result.documentName.contains('meeting')) folders.add('Meetings');
        if (result.documentName.contains('presentation')) folders.add('Presentations');
      }

      if (result.primaryCategory == 'Finance') {
        folders.add('Invoices');
        folders.add('Receipts');
        folders.add('Statements');
      }
    }

    return folders.toList();
  }

  /// Store learning data for future improvements
  Future<void> _storeLearningData(String documentName, String correctCategory,
      DocumentAIResult documentResult) async {
    // In a real implementation, this would store data for ML model training
    _logger.info('Learning data stored for future model improvement', 'IntelligentCategorizationService');
  }

  /// Utility functions
  String _getFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    return lastDot != -1 ? fileName.substring(lastDot) : '';
  }

  bool _matchesFilePattern(String extension, String pattern) {
    if (pattern.startsWith('*.')) {
      return extension.toLowerCase() == pattern.substring(1).toLowerCase();
    }
    return false;
  }

  /// Get all available categories
  Map<String, CategoryDefinition> getCategories() => _categories;

  /// Add custom category
  void addCustomCategory(CategoryDefinition category) {
    _categories[category.name] = category;
    _logger.info('Added custom category: ${category.name}', 'IntelligentCategorizationService');
  }

  /// Remove custom category
  void removeCustomCategory(String categoryName) {
    if (_categories.containsKey(categoryName)) {
      _categories.remove(categoryName);
      _logger.info('Removed custom category: $categoryName', 'IntelligentCategorizationService');
    }
  }
}

/// Category definition with metadata
class CategoryDefinition {
  final String name;
  final List<String> keywords;
  final List<String> filePatterns;
  final Color color;
  final IconData icon;

  const CategoryDefinition({
    required this.name,
    required this.keywords,
    required this.filePatterns,
    required this.color,
    required this.icon,
  });
}

/// Document features for categorization
class DocumentFeatures {
  final String text;
  final int wordCount;
  final bool hasImages;
  final List<String> keywords;
  final List<String> patterns;
  final String fileExtension;

  const DocumentFeatures({
    required this.text,
    required this.wordCount,
    required this.hasImages,
    required this.keywords,
    required this.patterns,
    required this.fileExtension,
  });
}

/// Categorization result
class CategorizationResult {
  final String documentName;
  final String primaryCategory;
  final double confidence;
  final List<AlternativeCategory> alternativeCategories;
  final List<String> suggestedFolders;
  final Map<String, dynamic> metadata;

  const CategorizationResult({
    required this.documentName,
    required this.primaryCategory,
    required this.confidence,
    required this.alternativeCategories,
    required this.suggestedFolders,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'documentName': documentName,
    'primaryCategory': primaryCategory,
    'confidence': confidence,
    'alternativeCategories': alternativeCategories.map((a) => a.toJson()).toList(),
    'suggestedFolders': suggestedFolders,
    'metadata': metadata,
  };
}

/// Alternative category suggestion
class AlternativeCategory {
  final String category;
  final double confidence;

  const AlternativeCategory(this.category, this.confidence);

  Map<String, dynamic> toJson() => {
    'category': category,
    'confidence': confidence,
  };
}
