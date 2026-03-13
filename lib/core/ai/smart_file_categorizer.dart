import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import '../backend/enhanced_pocketbase_service.dart';
import '../config/enhanced_config_manager.dart';
import '../logging/enhanced_logger.dart';
import '../performance/enhanced_performance_manager.dart';
import 'ai_file_organizer.dart';
import 'ai_advanced_search.dart';

/// Smart File Categorization Service
/// Features: AI-powered categorization, custom categories, automatic organization
/// Performance: Batch processing, caching, machine learning models
/// Security: Privacy-first, local processing, secure categorization
class SmartFileCategorizer {
  static SmartFileCategorizer? _instance;
  static SmartFileCategorizer get instance => _instance ??= SmartFileCategorizer._internal();
  SmartFileCategorizer._internal();

  // Configuration
  late final bool _enableAICategorization;
  late final bool _enableCustomCategories;
  late final bool _enableAutoOrganization;
  late final bool _enableLearning;
  late final double _categorizationThreshold;
  late final int _maxCustomCategories;
  
  // Category models and rules
  final Map<String, CategoryModel> _categoryModels = {};
  final Map<String, CategorizationRule> _categorizationRules = {};
  final Map<String, List<FilePattern>> _filePatterns = {};
  
  // Machine learning data
  final Map<String, List<String>> _trainingData = {};
  final Map<String, double> _categoryWeights = {};
  final Map<String, Map<String, double>> _featureWeights = {};
  
  // Custom categories
  final Map<String, CustomCategory> _customCategories = {};
  final Map<String, List<String>> _userPreferences = {};
  
  // Organization templates
  final Map<String, OrganizationTemplate> _organizationTemplates = {};
  
  // Event streams
  final StreamController<CategorizationEvent> _eventController = 
      StreamController<CategorizationEvent>.broadcast();
  final StreamController<OrganizationProgress> _progressController = 
      StreamController<OrganizationProgress>.broadcast();
  
  Stream<CategorizationEvent> get categorizationEvents => _eventController.stream;
  Stream<OrganizationProgress> get progressEvents => _progressController.stream;

  /// Initialize Smart File Categorizer
  Future<void> initialize() async {
    try {
      // Load configuration
      await _loadConfiguration();
      
      // Initialize category models
      await _initializeCategoryModels();
      
      // Setup categorization rules
      _setupCategorizationRules();
      
      // Setup file patterns
      _setupFilePatterns();
      
      // Setup organization templates
      _setupOrganizationTemplates();
      
      // Load custom categories
      await _loadCustomCategories();
      
      EnhancedLogger.instance.info('Smart File Categorizer initialized');
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to initialize Smart File Categorizer', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Load configuration
  Future<void> _loadConfiguration() async {
    final config = EnhancedConfigManager.instance;
    
    _enableAICategorization = config.getParameter('smart_categorizer.enable_ai') ?? true;
    _enableCustomCategories = config.getParameter('smart_categorizer.enable_custom') ?? true;
    _enableAutoOrganization = config.getParameter('smart_categorizer.enable_auto_organization') ?? true;
    _enableLearning = config.getParameter('smart_categorizer.enable_learning') ?? true;
    _categorizationThreshold = config.getParameter('smart_categorizer.threshold') ?? 0.7;
    _maxCustomCategories = config.getParameter('smart_categorizer.max_custom_categories') ?? 20;
  }

  /// Initialize category models
  Future<void> _initializeCategoryModels() async {
    // Documents model
    _categoryModels['documents'] = CategoryModel(
      name: 'documents',
      displayName: 'Documents',
      description: 'Text documents and PDFs',
      features: {
        'extension': 0.9,
        'content_type': 0.8,
        'file_size': 0.3,
        'path_depth': 0.2,
      },
      patterns: [
        FilePattern(type: PatternType.extension, value: r'\.(pdf|doc|docx|txt|rtf|odt)$'),
        FilePattern(type: PatternType.content, value: r'\b(document|report|letter|invoice|contract)\b'),
        FilePattern(type: PatternType.path, value: r'.*[/\\](documents|docs|papers)[/\\].*'),
      ],
      confidence: 0.85,
    );
    
    // Images model
    _categoryModels['images'] = CategoryModel(
      name: 'images',
      displayName: 'Images',
      description: 'Photos and graphics',
      features: {
        'extension': 0.9,
        'content_type': 0.7,
        'file_size': 0.4,
        'resolution': 0.6,
      },
      patterns: [
        FilePattern(type: PatternType.extension, value: r'\.(jpg|jpeg|png|gif|bmp|svg|webp|tiff)$'),
        FilePattern(type: PatternType.content, value: r'\b(photo|image|picture|graphic|screenshot)\b'),
        FilePattern(type: PatternType.path, value: r'.*[/\\](pictures|photos|images)[/\\].*'),
      ],
      confidence: 0.9,
    );
    
    // Videos model
    _categoryModels['videos'] = CategoryModel(
      name: 'videos',
      displayName: 'Videos',
      description: 'Video files',
      features: {
        'extension': 0.9,
        'content_type': 0.8,
        'file_size': 0.6,
        'duration': 0.7,
      },
      patterns: [
        FilePattern(type: PatternType.extension, value: r'\.(mp4|avi|mov|wmv|flv|webm|mkv|m4v)$'),
        FilePattern(type: PatternType.content, value: r'\b(video|movie|clip|recording)\b'),
        FilePattern(type: PatternType.path, value: r'.*[/\\](videos|movies|recordings)[/\\].*'),
      ],
      confidence: 0.9,
    );
    
    // Audio model
    _categoryModels['audio'] = CategoryModel(
      name: 'audio',
      displayName: 'Audio',
      description: 'Music and audio files',
      features: {
        'extension': 0.9,
        'content_type': 0.7,
        'file_size': 0.3,
        'duration': 0.6,
      },
      patterns: [
        FilePattern(type: PatternType.extension, value: r'\.(mp3|wav|flac|aac|ogg|m4a|wma)$'),
        FilePattern(type: PatternType.content, value: r'\b(music|song|audio|recording|podcast)\b'),
        FilePattern(type: PatternType.path, value: r'.*[/\\](music|audio|songs)[/\\].*'),
      ],
      confidence: 0.85,
    );
    
    // Code model
    _categoryModels['code'] = CategoryModel(
      name: 'code',
      displayName: 'Code',
      description: 'Source code files',
      features: {
        'extension': 0.9,
        'content_type': 0.8,
        'syntax': 0.7,
        'structure': 0.6,
      },
      patterns: [
        FilePattern(type: PatternType.extension, value: r'\.(dart|js|ts|py|java|cpp|c|h|html|css|php|rb|go|rs|swift)$'),
        FilePattern(type: PatternType.content, value: r'\b(function|class|import|def|public|private|var|let|const)\b'),
        FilePattern(type: PatternType.path, value: r'.*[/\\](src|code|projects)[/\\].*'),
      ],
      confidence: 0.9,
    );
    
    // Archives model
    _categoryModels['archives'] = CategoryModel(
      name: 'archives',
      displayName: 'Archives',
      description: 'Compressed files',
      features: {
        'extension': 0.9,
        'content_type': 0.8,
        'compression': 0.7,
        'file_size': 0.5,
      },
      patterns: [
        FilePattern(type: PatternType.extension, value: r'\.(zip|rar|7z|tar|gz|bz2|xz|arj)$'),
        FilePattern(type: PatternType.content, value: r'\b(archive|compressed|backup|package)\b'),
        FilePattern(type: PatternType.path, value: r'.*[/\\](archives|backups|packages)[/\\].*'),
      ],
      confidence: 0.95,
    );
    
    // Spreadsheets model
    _categoryModels['spreadsheets'] = CategoryModel(
      name: 'spreadsheets',
      displayName: 'Spreadsheets',
      description: 'Excel and spreadsheet files',
      features: {
        'extension': 0.9,
        'content_type': 0.8,
        'structure': 0.7,
        'data_type': 0.6,
      },
      patterns: [
        FilePattern(type: PatternType.extension, value: r'\.(xls|xlsx|csv|ods|numbers)$'),
        FilePattern(type: PatternType.content, value: r'\b(spreadsheet|excel|sheet|table|data)\b'),
        FilePattern(type: PatternType.path, value: r'.*[/\\](spreadsheets|excel|data)[/\\].*'),
      ],
      confidence: 0.85,
    );
    
    // Presentations model
    _categoryModels['presentations'] = CategoryModel(
      name: 'presentations',
      displayName: 'Presentations',
      description: 'PowerPoint and presentation files',
      features: {
        'extension': 0.9,
        'content_type': 0.8,
        'structure': 0.7,
        'slides': 0.6,
      },
      patterns: [
        FilePattern(type: PatternType.extension, value: r'\.(ppt|pptx|odp|key)$'),
        FilePattern(type: PatternType.content, value: r'\b(presentation|slide|powerpoint|keynote)\b'),
        FilePattern(type: PatternType.path, value: r'.*[/\\](presentations|slides)[/\\].*'),
      ],
      confidence: 0.85,
    );
    
    // Downloads model
    _categoryModels['downloads'] = CategoryModel(
      name: 'downloads',
      displayName: 'Downloads',
      description: 'Downloaded files',
      features: {
        'path': 0.9,
        'recency': 0.7,
        'source': 0.5,
      },
      patterns: [
        FilePattern(type: PatternType.path, value: r'.*[/\\]downloads[/\\].*'),
        FilePattern(type: PatternType.path, value: r'.*[/\\]downloads$'),
      ],
      confidence: 0.8,
    );
    
    // Temporary model
    _categoryModels['temporary'] = CategoryModel(
      name: 'temporary',
      displayName: 'Temporary',
      description: 'Temporary files',
      features: {
        'path': 0.9,
        'recency': 0.8,
        'name': 0.6,
      },
      patterns: [
        FilePattern(type: PatternType.path, value: r'.*[/\\]temp[/\\].*'),
        FilePattern(type: PatternType.path, value: r'.*[/\\]tmp[/\\].*'),
        FilePattern(type: PatternType.name, value: r'^temp|tmp|~\$'),
      ],
      confidence: 0.9,
    );
    
    EnhancedLogger.instance.info('Category models initialized');
  }

  /// Setup categorization rules
  void _setupCategorizationRules() {
    // Size-based rules
    _categorizationRules['large_files'] = CategorizationRule(
      name: 'large_files',
      condition: 'file_size > 100MB',
      action: 'add_tag',
      value: 'large',
      priority: 1,
    );
    
    _categorizationRules['small_files'] = CategorizationRule(
      name: 'small_files',
      condition: 'file_size < 1KB',
      action: 'add_tag',
      value: 'small',
      priority: 1,
    );
    
    // Date-based rules
    _categorizationRules['recent_files'] = CategorizationRule(
      name: 'recent_files',
      condition: 'file_age < 7 days',
      action: 'add_tag',
      value: 'recent',
      priority: 2,
    );
    
    _categorizationRules['old_files'] = CategorizationRule(
      name: 'old_files',
      condition: 'file_age > 365 days',
      action: 'add_tag',
      value: 'old',
      priority: 2,
    );
    
    // Path-based rules
    _categorizationRules['system_files'] = CategorizationRule(
      name: 'system_files',
      condition: 'path_contains_system',
      action: 'add_tag',
      value: 'system',
      priority: 3,
    );
  }

  /// Setup file patterns
  void _setupFilePatterns() {
    // Work-related patterns
    _filePatterns['work'] = [
      FilePattern(type: PatternType.name, value: r'.*\b(work|project|report|meeting|invoice)\b.*'),
      FilePattern(type: PatternType.path, value: r'.*[/\\](work|projects|office)[/\\].*'),
      FilePattern(type: PatternType.extension, value: r'\.(doc|docx|xls|xlsx|ppt|pptx)$'),
    ];
    
    // Personal patterns
    _filePatterns['personal'] = [
      FilePattern(type: PatternType.name, value: r'.*\b(personal|family|home|private)\b.*'),
      FilePattern(type: PatternType.path, value: r'.*[/\\](personal|family|home)[/\\].*'),
      FilePattern(type: PatternType.content, value: r'\b(personal|family|home|private)\b'),
    ];
    
    // Educational patterns
    _filePatterns['education'] = [
      FilePattern(type: PatternType.name, value: r'.*\b(course|lesson|tutorial|study|exam)\b.*'),
      FilePattern(type: PatternType.path, value: r'.*[/\\](courses|education|study)[/\\].*'),
      FilePattern(type: PatternType.content, value: r'\b(course|lesson|tutorial|study|exam)\b'),
    ];
    
    // Media patterns
    _filePatterns['media'] = [
      FilePattern(type: PatternType.extension, value: r'\.(jpg|jpeg|png|gif|mp4|avi|mp3|wav)$'),
      FilePattern(type: PatternType.path, value: r'.*[/\\](media|photos|videos|music)[/\\].*'),
      FilePattern(type: PatternType.name, value: r'.*\b(media|photo|video|music)\b.*'),
    ];
  }

  /// Setup organization templates
  void _setupOrganizationTemplates() {
    // Professional template
    _organizationTemplates['professional'] = OrganizationTemplate(
      name: 'professional',
      displayName: 'Professional',
      description: 'Professional file organization',
      structure: {
        'Documents': ['Reports', 'Contracts', 'Invoices', 'Presentations'],
        'Projects': ['Active', 'Completed', 'Archived'],
        'Media': ['Images', 'Videos', 'Audio'],
        'Resources': ['Templates', 'References', 'Tools'],
      },
      rules: [
        'Sort by date modified',
        'Group by project',
        'Archive old files',
      ],
    );
    
    // Personal template
    _organizationTemplates['personal'] = OrganizationTemplate(
      name: 'personal',
      displayName: 'Personal',
      description: 'Personal file organization',
      structure: {
        'Documents': ['Personal', 'Family', 'Finance', 'Health'],
        'Media': ['Photos', 'Videos', 'Music'],
        'Projects': ['Hobbies', 'DIY', 'Learning'],
        'Archives': ['Old Files', 'Backups'],
      },
      rules: [
        'Sort by year',
        'Group by category',
        'Keep recent files accessible',
      ],
    );
    
    // Creative template
    _organizationTemplates['creative'] = OrganizationTemplate(
      name: 'creative',
      displayName: 'Creative',
      description: 'Creative work organization',
      structure: {
        'Projects': ['Active', 'Completed', 'Ideas'],
        'Assets': ['Images', 'Videos', 'Audio', 'Fonts'],
        'Resources': ['Inspiration', 'Tools', 'Tutorials'],
        'Exports': ['Final', 'Drafts', 'Archived'],
      },
      rules: [
        'Sort by project status',
        'Group by media type',
        'Version control exports',
      ],
    );
  }

  /// Load custom categories
  Future<void> _loadCustomCategories() async {
    // Load from PocketBase or local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final customCategoriesJson = prefs.getString('custom_categories');
      
      if (customCategoriesJson != null) {
        final categoriesData = jsonDecode(customCategoriesJson) as Map<String, dynamic>;
        
        for (final entry in categoriesData.entries) {
          final categoryData = entry.value as Map<String, dynamic>;
          _customCategories[entry.key] = CustomCategory.fromJson(categoryData);
        }
      }
    } catch (e) {
      EnhancedLogger.instance.warning('Failed to load custom categories: $e');
    }
  }

  /// Categorize file with AI
  Future<CategorizationResult> categorizeFile(String filePath) async {
    final timer = EnhancedPerformanceManager.instance.startTimer('file_categorization');
    
    try {
      // Get file analysis
      final analysis = await AIFileOrganizer.instance.analyzeFile(filePath);
      
      // Extract features
      final features = await _extractFeatures(analysis);
      
      // Calculate category scores
      final categoryScores = <String, double>{};
      
      for (final categoryModel in _categoryModels.values) {
        final score = await _calculateCategoryScore(features, categoryModel);
        categoryScores[categoryModel.name] = score;
      }
      
      // Find best category
      final bestCategory = categoryScores.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      
      // Apply categorization rules
      final tags = await _applyCategorizationRules(analysis);
      
      // Check custom categories
      final customCategory = await _checkCustomCategories(features);
      
      // Create result
      final result = CategorizationResult(
        filePath: filePath,
        primaryCategory: bestCategory.key,
        confidence: bestCategory.value,
        alternativeCategories: categoryScores.entries
            .where((entry) => entry.key != bestCategory.key && entry.value > 0.5)
            .map((entry) => CategoryScore(category: entry.key, score: entry.value))
            .toList()
            ..sort((a, b) => b.score.compareTo(a.score)),
        tags: tags,
        customCategory: customCategory,
        features: features,
        timestamp: DateTime.now(),
      );
      
      // Learn from categorization
      if (_enableLearning) {
        _learnFromCategorization(result);
      }
      
      timer.stop();
      
      // Emit event
      _eventController.add(CategorizationEvent(
        type: CategorizationEventType.fileCategorized,
        filePath: filePath,
        result: result,
      ));
      
      return result;
    } catch (e, stackTrace) {
      timer.stop();
      EnhancedLogger.instance.error('Failed to categorize file: $filePath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Extract features from file analysis
  Future<Map<String, dynamic>> _extractFeatures(FileAnalysisResult analysis) async {
    final features = <String, dynamic>{};
    
    // Extension feature
    features['extension'] = path.extension(analysis.filePath).toLowerCase();
    
    // File size feature
    features['file_size'] = analysis.size;
    features['file_size_category'] = _categorizeFileSize(analysis.size);
    
    // Content type feature
    features['content_type'] = _determineContentType(analysis);
    
    // Path depth feature
    final pathParts = analysis.filePath.split(RegExp(r'[\/\\]'));
    features['path_depth'] = pathParts.length;
    features['path_contains_system'] = _containsSystemPath(analysis.filePath);
    
    // Name features
    final fileName = path.basename(analysis.filePath);
    features['name_length'] = fileName.length;
    features['name_contains_date'] = _containsDate(fileName);
    features['name_contains_keywords'] = _containsKeywords(fileName);
    
    // Content features
    features['text_content'] = analysis.contentAnalysis['text_content'] ?? '';
    features['language'] = analysis.contentAnalysis['language'] ?? 'unknown';
    features['has_code'] = analysis.contentAnalysis['has_code'] ?? false;
    
    // Metadata features
    features['created_at'] = analysis.createdAt;
    features['modified_at'] = analysis.modifiedAt;
    features['file_age_days'] = DateTime.now().difference(analysis.modifiedAt).inDays;
    
    // Tags features
    features['tags'] = analysis.tags;
    features['tag_count'] = analysis.tags.length;
    
    return features;
  }

  /// Calculate category score
  Future<double> _calculateCategoryScore(
    Map<String, dynamic> features,
    CategoryModel categoryModel,
  ) async {
    double score = 0.0;
    
    // Check patterns
    for (final pattern in categoryModel.patterns) {
      final patternScore = await _matchPattern(features, pattern);
      score += patternScore;
    }
    
    // Apply feature weights
    for (final feature in categoryModel.features.entries) {
      final weight = feature.value;
      final featureValue = features[feature.key];
      
      if (featureValue != null) {
        switch (feature.key) {
          case 'extension':
            if (_matchesExtension(features['extension'], categoryModel)) {
              score += weight;
            }
            break;
          case 'content_type':
            if (_matchesContentType(featureValue, categoryModel)) {
              score += weight;
            }
            break;
          case 'file_size':
            final size = featureValue as int;
            if (_matchesFileSize(size, categoryModel)) {
              score += weight;
            }
            break;
          case 'path_depth':
            final depth = featureValue as int;
            if (_matchesPathDepth(depth, categoryModel)) {
              score += weight;
            }
            break;
        }
      }
    }
    
    // Normalize score
    score = score / categoryModel.patterns.length;
    
    // Apply confidence
    score *= categoryModel.confidence;
    
    return math.min(1.0, score);
  }

  /// Match pattern
  Future<double> _matchPattern(Map<String, dynamic> features, FilePattern pattern) async {
    switch (pattern.type) {
      case PatternType.extension:
        final extension = features['extension'] as String;
        return RegExp(pattern.value).hasMatch(extension) ? 1.0 : 0.0;
        
      case PatternType.name:
        final fileName = path.basename(features['file_path'] as String);
        return RegExp(pattern.value, caseSensitive: false).hasMatch(fileName) ? 1.0 : 0.0;
        
      case PatternType.path:
        final filePath = features['file_path'] as String;
        return RegExp(pattern.value, caseSensitive: false).hasMatch(filePath) ? 1.0 : 0.0;
        
      case PatternType.content:
        final content = features['text_content'] as String;
        return RegExp(pattern.value, caseSensitive: false).hasMatch(content) ? 1.0 : 0.0;
        
      default:
        return 0.0;
    }
  }

  /// Apply categorization rules
  Future<List<String>> _applyCategorizationRules(FileAnalysisResult analysis) async {
    final tags = <String>[];
    
    for (final rule in _categorizationRules.values) {
      if (_evaluateRule(rule, analysis)) {
        tags.add(rule.value);
      }
    }
    
    return tags;
  }

  /// Evaluate categorization rule
  bool _evaluateRule(CategorizationRule rule, FileAnalysisResult analysis) {
    switch (rule.name) {
      case 'large_files':
        return analysis.size > 100 * 1024 * 1024; // 100MB
      case 'small_files':
        return analysis.size < 1024; // 1KB
      case 'recent_files':
        return DateTime.now().difference(analysis.modifiedAt).inDays < 7;
      case 'old_files':
        return DateTime.now().difference(analysis.modifiedAt).inDays > 365;
      case 'system_files':
        return _containsSystemPath(analysis.filePath);
      default:
        return false;
    }
  }

  /// Check custom categories
  Future<CustomCategory?> _checkCustomCategories(Map<String, dynamic> features) async {
    for (final customCategory in _customCategories.values) {
      if (_matchesCustomCategory(features, customCategory)) {
        return customCategory;
      }
    }
    return null;
  }

  /// Matches custom category
  bool _matchesCustomCategory(Map<String, dynamic> features, CustomCategory category) {
    // Check patterns
    for (final pattern in category.patterns) {
      if (_matchesPattern(features, pattern) > 0.5) {
        return true;
      }
    }
    
    // Check conditions
    for (final condition in category.conditions) {
      if (_evaluateCondition(condition, features)) {
        return true;
      }
    }
    
    return false;
  }

  /// Evaluate condition
  bool _evaluateCondition(String condition, Map<String, dynamic> features) {
    // Simple condition evaluation (can be enhanced)
    final parts = condition.split(' ');
    if (parts.length != 3) return false;
    
    final field = parts[0];
    final operator = parts[1];
    final value = parts[2];
    
    final featureValue = features[field];
    if (featureValue == null) return false;
    
    switch (operator) {
      case '>':
        return featureValue > _parseValue(value);
      case '<':
        return featureValue < _parseValue(value);
      case '>=':
        return featureValue >= _parseValue(value);
      case '<=':
        return featureValue <= _parseValue(value);
      case '==':
        return featureValue == _parseValue(value);
      case '!=':
        return featureValue != _parseValue(value);
      default:
        return false;
    }
  }

  /// Parse value
  dynamic _parseValue(String value) {
    if (value.startsWith('"') && value.endsWith('"')) {
      return value.substring(1, value.length - 1);
    }
    
    if (value.contains('MB')) {
      final number = double.tryParse(value.replaceAll('MB', ''));
      return number != null ? number * 1024 * 1024 : value;
    }
    
    if (value.contains('KB')) {
      final number = double.tryParse(value.replaceAll('KB', ''));
      return number != null ? number * 1024 : value;
    }
    
    if (value.contains('GB')) {
      final number = double.tryParse(value.replaceAll('GB', ''));
      return number != null ? number * 1024 * 1024 * 1024 : value;
    }
    
    return double.tryParse(value) ?? value;
  }

  /// Learn from categorization
  void _learnFromCategorization(CategorizationResult result) {
    // Update category weights
    final currentWeight = _categoryWeights[result.primaryCategory] ?? 0.5;
    _categoryWeights[result.primaryCategory] = (currentWeight + result.confidence) / 2;
    
    // Update feature weights
    for (final feature in result.features.entries) {
      if (!_featureWeights.containsKey(result.primaryCategory)) {
        _featureWeights[result.primaryCategory] = {};
      }
      
      final currentFeatureWeight = _featureWeights[result.primaryCategory][feature.key] ?? 0.5;
      _featureWeights[result.primaryCategory][feature.key] = (currentFeatureWeight + result.confidence) / 2;
    }
  }

  /// Create custom category
  Future<void> createCustomCategory(CustomCategory category) async {
    if (_customCategories.length >= _maxCustomCategories) {
      throw Exception('Maximum number of custom categories reached');
    }
    
    _customCategories[category.name] = category;
    
    // Save to storage
    await _saveCustomCategories();
    
    // Emit event
    _eventController.add(CategorizationEvent(
      type: CategorizationEventType.customCategoryCreated,
      result: category,
    ));
    
    EnhancedLogger.instance.info('Custom category created: ${category.name}');
  }

  /// Delete custom category
  Future<void> deleteCustomCategory(String categoryName) async {
    _customCategories.remove(categoryName);
    
    // Save to storage
    await _saveCustomCategories();
    
    // Emit event
    _eventController.add(CategorizationEvent(
      type: CategorizationEventType.customCategoryDeleted,
      result: categoryName,
    ));
    
    EnhancedLogger.instance.info('Custom category deleted: $categoryName');
  }

  /// Save custom categories
  Future<void> _saveCustomCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = _customCategories.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
      
      await prefs.setString('custom_categories', jsonEncode(categoriesJson));
    } catch (e) {
      EnhancedLogger.instance.error('Failed to save custom categories: $e');
    }
  }

  /// Organize directory
  Future<OrganizationResult> organizeDirectory(
    String dirPath, {
    String? templateName,
    bool dryRun = false,
  }) async {
    final timer = EnhancedPerformanceManager.instance.startTimer('directory_organization');
    
    try {
      final directory = Directory(dirPath);
      if (!await directory.exists()) {
        throw Exception('Directory does not exist: $dirPath');
      }
      
      // Get template
      final template = templateName != null 
          ? _organizationTemplates[templateName]
          : _organizationTemplates['professional'];
      
      if (template == null) {
        throw Exception('Template not found: $templateName');
      }
      
      final result = OrganizationResult(
        directoryPath: dirPath,
        template: template.name,
        dryRun: dryRun,
        organizedFiles: [],
        createdDirectories: [],
        errors: [],
        timestamp: DateTime.now(),
      );
      
      // Create directory structure
      for (final category in template.structure.entries) {
        final categoryPath = path.join(dirPath, category.key);
        
        if (!dryRun) {
          await Directory(categoryPath).create(recursive: true);
        }
        
        result.createdDirectories.add(categoryPath);
        
        // Create subcategories
        for (final subcategory in category.value) {
          final subcategoryPath = path.join(categoryPath, subcategory);
          
          if (!dryRun) {
            await Directory(subcategoryPath).create(recursive: true);
          }
          
          result.createdDirectories.add(subcategoryPath);
        }
      }
      
      // Get all files
      final files = await directory
          .list(recursive: true)
          .where((entity) => entity is File)
          .cast<File>()
          .toList();
      
      // Organize files
      for (final file in files) {
        try {
          final categorization = await categorizeFile(file.path);
          
          // Find target directory
          final targetPath = _findTargetDirectory(categorization, template, dirPath);
          
          if (targetPath != null) {
            if (!dryRun) {
              await file.rename(targetPath);
            }
            
            result.organizedFiles.add(OrganizedFile(
              originalPath: file.path,
              targetPath: targetPath,
              category: categorization.primaryCategory,
              confidence: categorization.confidence,
            ));
          }
        } catch (e) {
          result.errors.add(OrganizationError(
            filePath: file.path,
            error: e.toString(),
          ));
        }
      }
      
      timer.stop();
      
      // Emit event
      _eventController.add(CategorizationEvent(
        type: CategorizationEventType.directoryOrganized,
        result: result,
      ));
      
      return result;
    } catch (e, stackTrace) {
      timer.stop();
      EnhancedLogger.instance.error('Failed to organize directory: $dirPath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Find target directory for file
  String? _findTargetDirectory(
    CategorizationResult categorization,
    OrganizationTemplate template,
    String baseDir,
  ) {
    final category = categorization.primaryCategory;
    
    // Check if category exists in template structure
    if (template.structure.containsKey(category)) {
      // Find best subcategory
      final subcategories = template.structure[category]!;
      
      for (final subcategory in subcategories) {
        final subcategoryPath = path.join(baseDir, category, subcategory);
        return subcategoryPath;
      }
      
      // Return main category directory
      return path.join(baseDir, category);
    }
    
    // Check custom categories
    if (categorization.customCategory != null) {
      return path.join(baseDir, 'custom', categorization.customCategory!.name);
    }
    
    // Default to uncategorized
    return path.join(baseDir, 'uncategorized');
  }

  /// Get categorization statistics
  Map<String, dynamic> getCategorizationStatistics() {
    return {
      'category_models': _categoryModels.length,
      'custom_categories': _customCategories.length,
      'categorization_rules': _categorizationRules.length,
      'file_patterns': _filePatterns.length,
      'organization_templates': _organizationTemplates.length,
      'category_weights': _categoryWeights,
      'feature_weights': _featureWeights,
    };
  }

  /// Helper methods
  bool _matchesExtension(String extension, CategoryModel categoryModel) {
    return categoryModel.patterns.any((pattern) =>
        pattern.type == PatternType.extension &&
        RegExp(pattern.value).hasMatch(extension));
  }

  bool _matchesContentType(dynamic contentType, CategoryModel categoryModel) {
    // Simplified content type matching
    switch (categoryModel.name) {
      case 'documents':
        return contentType == 'text' || contentType == 'document';
      case 'images':
        return contentType == 'image';
      case 'videos':
        return contentType == 'video';
      case 'audio':
        return contentType == 'audio';
      case 'code':
        return contentType == 'code';
      default:
        return false;
    }
  }

  bool _matchesFileSize(int size, CategoryModel categoryModel) {
    switch (categoryModel.name) {
      case 'videos':
      case 'archives':
        return size > 10 * 1024 * 1024; // > 10MB
      case 'images':
        return size > 100 * 1024; // > 100KB
      case 'documents':
        return size < 50 * 1024 * 1024; // < 50MB
      default:
        return true;
    }
  }

  bool _matchesPathDepth(int depth, CategoryModel categoryModel) {
    switch (categoryModel.name) {
      case 'downloads':
      case 'temporary':
        return depth >= 2;
      default:
        return true;
    }
  }

  String _categorizeFileSize(int size) {
    if (size < 1024) return 'tiny';
    if (size < 10 * 1024) return 'small';
    if (size < 1024 * 1024) return 'medium';
    if (size < 100 * 1024 * 1024) return 'large';
    return 'huge';
  }

  String _determineContentType(FileAnalysisResult analysis) {
    final extension = path.extension(analysis.filePath).toLowerCase();
    
    if (_isImageExtension(extension)) return 'image';
    if (_isVideoExtension(extension)) return 'video';
    if (_isAudioExtension(extension)) return 'audio';
    if (_isDocumentExtension(extension)) return 'document';
    if (_isArchiveExtension(extension)) return 'archive';
    if (_isCodeExtension(extension)) return 'code';
    
    return 'unknown';
  }

  bool _containsSystemPath(String filePath) {
    final systemPaths = [
      '/windows/', '/system/', '/library/', '/usr/', '/bin/', '/sbin/',
      'C:\\Windows\\', 'C:\\Program Files\\', 'C:\\System32\\',
    ];
    
    return systemPaths.any((systemPath) => filePath.contains(systemPath));
  }

  bool _containsDate(String fileName) {
    final datePattern = RegExp(r'\d{4}[-_]\d{2}[-_]\d{2}');
    return datePattern.hasMatch(fileName);
  }

  bool _containsKeywords(String fileName) {
    final keywords = ['report', 'project', 'invoice', 'contract', 'meeting', 'photo', 'video', 'music'];
    return keywords.any((keyword) => fileName.toLowerCase().contains(keyword));
  }

  bool _isImageExtension(String extension) {
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg', '.webp', '.tiff'].contains(extension);
  }

  bool _isVideoExtension(String extension) {
    return ['.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm', '.mkv', '.m4v'].contains(extension);
  }

  bool _isAudioExtension(String extension) {
    return ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a', '.wma'].contains(extension);
  }

  bool _isDocumentExtension(String extension) {
    return ['.pdf', '.doc', '.docx', '.txt', '.rtf', '.odt', '.xls', '.xlsx', '.csv', '.ods', '.ppt', '.pptx', '.odp'].contains(extension);
  }

  bool _isArchiveExtension(String extension) {
    return ['.zip', '.rar', '.7z', '.tar', '.gz', '.bz2', '.xz', '.arj'].contains(extension);
  }

  bool _isCodeExtension(String extension) {
    return ['.dart', '.js', '.ts', '.py', '.java', '.cpp', '.c', '.h', '.html', '.css', '.php', '.rb', '.go', '.rs', '.swift'].contains(extension);
  }

  /// Dispose
  void dispose() {
    _eventController.close();
    _progressController.close();
    
    _categoryModels.clear();
    _categorizationRules.clear();
    _filePatterns.clear();
    _trainingData.clear();
    _categoryWeights.clear();
    _featureWeights.clear();
    _customCategories.clear();
    _userPreferences.clear();
    _organizationTemplates.clear();
    
    EnhancedLogger.instance.info('Smart File Categorizer disposed');
  }
}

/// Category model
class CategoryModel {
  final String name;
  final String displayName;
  final String description;
  final Map<String, double> features;
  final List<FilePattern> patterns;
  final double confidence;

  CategoryModel({
    required this.name,
    required this.displayName,
    required this.description,
    required this.features,
    required this.patterns,
    required this.confidence,
  });
}

/// File pattern
class FilePattern {
  final PatternType type;
  final String value;

  FilePattern({
    required this.type,
    required this.value,
  });
}

/// Categorization rule
class CategorizationRule {
  final String name;
  final String condition;
  final String action;
  final String value;
  final int priority;

  CategorizationRule({
    required this.name,
    required this.condition,
    required this.action,
    required this.value,
    required this.priority,
  });
}

/// Custom category
class CustomCategory {
  final String name;
  final String displayName;
  final String description;
  final List<FilePattern> patterns;
  final List<String> conditions;
  final DateTime createdAt;

  CustomCategory({
    required this.name,
    required this.displayName,
    required this.description,
    required this.patterns,
    required this.conditions,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'display_name': displayName,
      'description': description,
      'patterns': patterns.map((p) => {
        'type': p.type.toString(),
        'value': p.value,
      }).toList(),
      'conditions': conditions,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CustomCategory.fromJson(Map<String, dynamic> json) {
    return CustomCategory(
      name: json['name'],
      displayName: json['display_name'],
      description: json['description'],
      patterns: (json['patterns'] as List)
          .map((p) => FilePattern(
            type: PatternType.values.firstWhere((type) => type.toString() == p['type']),
            value: p['value'],
          ))
          .toList(),
      conditions: (json['conditions'] as List).cast<String>(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Organization template
class OrganizationTemplate {
  final String name;
  final String displayName;
  final String description;
  final Map<String, List<String>> structure;
  final List<String> rules;

  OrganizationTemplate({
    required this.name,
    required this.displayName,
    required this.description,
    required this.structure,
    required this.rules,
  });
}

/// Categorization result
class CategorizationResult {
  final String filePath;
  final String primaryCategory;
  final double confidence;
  final List<CategoryScore> alternativeCategories;
  final List<String> tags;
  final CustomCategory? customCategory;
  final Map<String, dynamic> features;
  final DateTime timestamp;

  CategorizationResult({
    required this.filePath,
    required this.primaryCategory,
    required this.confidence,
    required this.alternativeCategories,
    required this.tags,
    this.customCategory,
    required this.features,
    required this.timestamp,
  });
}

/// Category score
class CategoryScore {
  final String category;
  final double score;

  CategoryScore({
    required this.category,
    required this.score,
  });
}

/// Organization result
class OrganizationResult {
  final String directoryPath;
  final String template;
  final bool dryRun;
  final List<OrganizedFile> organizedFiles;
  final List<String> createdDirectories;
  final List<OrganizationError> errors;
  final DateTime timestamp;

  OrganizationResult({
    required this.directoryPath,
    required this.template,
    required this.dryRun,
    required this.organizedFiles,
    required this.createdDirectories,
    required this.errors,
    required this.timestamp,
  });
}

/// Organized file
class OrganizedFile {
  final String originalPath;
  final String targetPath;
  final String category;
  final double confidence;

  OrganizedFile({
    required this.originalPath,
    required this.targetPath,
    required this.category,
    required this.confidence,
  });
}

/// Organization error
class OrganizationError {
  final String filePath;
  final String error;

  OrganizationError({
    required this.filePath,
    required this.error,
  });
}

/// Categorization event
class CategorizationEvent {
  final CategorizationEventType type;
  final String? filePath;
  final dynamic result;
  final DateTime timestamp;

  CategorizationEvent({
    required this.type,
    this.filePath,
    this.result,
  }) : timestamp = DateTime.now();
}

/// Organization progress
class OrganizationProgress {
  final String stage;
  final int totalFiles;
  final int processedFiles;
  final String? currentFile;
  final DateTime timestamp;

  OrganizationProgress({
    required this.stage,
    required this.totalFiles,
    required this.processedFiles,
    this.currentFile,
  }) : timestamp = DateTime.now();

  double get progress => totalFiles > 0 ? processedFiles / totalFiles : 0.0;
}

/// Enums
enum PatternType { extension, name, path, content }
enum CategorizationEventType { fileCategorized, directoryOrganized, customCategoryCreated, customCategoryDeleted }
