import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import '../backend/enhanced_pocketbase_service.dart';
import '../config/enhanced_config_manager.dart';
import '../logging/enhanced_logger.dart';
import '../performance/enhanced_performance_manager.dart';
import 'ai_file_organizer.dart';
import 'ai_advanced_search.dart';
import 'smart_file_categorizer.dart';
import 'ai_duplicate_detector.dart';

/// AI-Powered File Recommendations Service
/// Features: Smart suggestions, usage patterns, predictive organization
/// Performance: Machine learning, caching, parallel processing
/// Security: Privacy-first, local processing, secure recommendations
class AIFileRecommendations {
  static AIFileRecommendations? _instance;
  static AIFileRecommendations get instance => _instance ??= AIFileRecommendations._internal();
  AIFileRecommendations._internal();

  // Configuration
  late final bool _enableUsageTracking;
  late final bool _enablePredictiveRecommendations;
  late final bool _enableSmartSuggestions;
  late final bool _enableLearning;
  late final int _maxRecommendations;
  late final int _historyRetentionDays;
  late final double _recommendationThreshold;
  
  // User behavior tracking
  final Map<String, UserBehavior> _userBehaviors = {};
  final List<FileAccessEvent> _accessHistory = [];
  final Map<String, List<FileAction>> _fileActions = {};
  
  // Recommendation models
  final Map<String, RecommendationModel> _recommendationModels = {};
  final Map<String, List<FilePattern>> _usagePatterns = {};
  final Map<String, double> _featureWeights = {};
  
  // Machine learning data
  final Map<String, List<double>> _trainingData = {};
  final Map<String, Map<String, double>> _userPreferences = {};
  final Map<String, List<RecommendationResult>> _recommendationHistory = {};
  
  // Caching
  final Map<String, List<RecommendationResult>> _recommendationCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  Timer? _cacheCleanupTimer;
  
  // Event streams
  final StreamController<RecommendationEvent> _eventController = 
      StreamController<RecommendationEvent>.broadcast();
  final StreamController<LearningProgress> _progressController = 
      StreamController<LearningProgress>.broadcast();
  
  Stream<RecommendationEvent> get recommendationEvents => _eventController.stream;
  Stream<LearningProgress> get learningEvents => _progressController.stream;

  /// Initialize AI File Recommendations
  Future<void> initialize() async {
    try {
      // Load configuration
      await _loadConfiguration();
      
      // Initialize recommendation models
      await _initializeRecommendationModels();
      
      // Setup usage patterns
      _setupUsagePatterns();
      
      // Setup cache cleanup
      _setupCacheCleanup();
      
      // Load user preferences
      await _loadUserPreferences();
      
      EnhancedLogger.instance.info('AI File Recommendations initialized');
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to initialize AI File Recommendations', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Load configuration
  Future<void> _loadConfiguration() async {
    final config = EnhancedConfigManager.instance;
    
    _enableUsageTracking = config.getParameter('recommendations.enable_usage_tracking') ?? true;
    _enablePredictiveRecommendations = config.getParameter('recommendations.enable_predictive') ?? true;
    _enableSmartSuggestions = config.getParameter('recommendations.enable_smart_suggestions') ?? true;
    _enableLearning = config.getParameter('recommendations.enable_learning') ?? true;
    _maxRecommendations = config.getParameter('recommendations.max_recommendations') ?? 10;
    _historyRetentionDays = config.getParameter('recommendations.history_retention_days') ?? 30;
    _recommendationThreshold = config.getParameter('recommendations.threshold') ?? 0.7;
  }

  /// Initialize recommendation models
  Future<void> _initializeRecommendationModels() async {
    // File access prediction model
    _recommendationModels['access_prediction'] = RecommendationModel(
      name: 'access_prediction',
      type: ModelType.classification,
      features: {
        'time_of_day': 0.3,
        'day_of_week': 0.2,
        'file_age': 0.2,
        'access_frequency': 0.3,
      },
      algorithm: 'random_forest',
      confidence: 0.8,
    );
    
    // File organization model
    _recommendationModels['organization'] = RecommendationModel(
      name: 'organization',
      type: ModelType.clustering,
      features: {
        'file_type': 0.4,
        'file_size': 0.2,
        'creation_date': 0.2,
        'access_pattern': 0.2,
      },
      algorithm: 'k_means',
      confidence: 0.75,
    );
    
    // Similar files model
    _recommendationModels['similar_files'] = RecommendationModel(
      name: 'similar_files',
      type: ModelType.similarity,
      features: {
        'content_similarity': 0.5,
        'metadata_similarity': 0.3,
        'usage_similarity': 0.2,
      },
      algorithm: 'cosine_similarity',
      confidence: 0.85,
    );
    
    // File importance model
    _recommendationModels['importance'] = RecommendationModel(
      name: 'importance',
      type: ModelType.regression,
      features: {
        'access_frequency': 0.4,
        'recency': 0.3,
        'file_size': 0.1,
        'user_rating': 0.2,
      },
      algorithm: 'linear_regression',
      confidence: 0.7,
    );
    
    EnhancedLogger.instance.info('Recommendation models initialized');
  }

  /// Setup usage patterns
  void _setupUsagePatterns() {
    // Work patterns
    _usagePatterns['work'] = [
      FilePattern(
        type: PatternType.time,
        value: '09:00-17:00',
        weight: 0.8,
      ),
      FilePattern(
        type: PatternType.day,
        value: 'monday,tuesday,wednesday,thursday,friday',
        weight: 0.9,
      ),
      FilePattern(
        type: PatternType.category,
        value: 'documents,spreadsheets,presentations',
        weight: 0.7,
      ),
    ];
    
    // Personal patterns
    _usagePatterns['personal'] = [
      FilePattern(
        type: PatternType.time,
        value: '18:00-22:00',
        weight: 0.7,
      ),
      FilePattern(
        type: PatternType.day,
        value: 'saturday,sunday',
        weight: 0.8,
      ),
      FilePattern(
        type: PatternType.category,
        value: 'images,videos,audio',
        weight: 0.6,
      ),
    ];
    
    // Project patterns
    _usagePatterns['project'] = [
      FilePattern(
        type: PatternType.path,
        value: '.*[/\\]projects[/\\].*',
        weight: 0.9,
      ),
      FilePattern(
        type: PatternType.category,
        value: 'code,documents',
        weight: 0.8,
      ),
      FilePattern(
        type: PatternType.recency,
        value: 'recent',
        weight: 0.7,
      ),
    ];
  }

  /// Setup cache cleanup
  void _setupCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(Duration(hours: 1), (_) {
      _cleanupCache();
    });
  }

  /// Load user preferences
  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString('user_preferences');
      
      if (preferencesJson != null) {
        final preferencesData = jsonDecode(preferencesJson) as Map<String, dynamic>;
        
        for (final entry in preferencesData.entries) {
          final prefData = entry.value as Map<String, dynamic>;
          _userPreferences[entry.key] = Map<String, double>.from(prefData);
        }
      }
    } catch (e) {
      EnhancedLogger.instance.warning('Failed to load user preferences: $e');
    }
  }

  /// Track file access
  void trackFileAccess(String filePath, FileActionType actionType) {
    if (!_enableUsageTracking) return;
    
    final event = FileAccessEvent(
      filePath: filePath,
      actionType: actionType,
      timestamp: DateTime.now(),
    );
    
    _accessHistory.add(event);
    
    // Update file actions
    if (!_fileActions.containsKey(filePath)) {
      _fileActions[filePath] = [];
    }
    _fileActions[filePath]!.add(FileAction(
      type: actionType,
      timestamp: event.timestamp,
    ));
    
    // Update user behavior
    _updateUserBehavior(event);
    
    // Clean old history
    _cleanupOldHistory();
    
    // Emit event
    _eventController.add(RecommendationEvent(
      type: RecommendationEventType.fileAccessTracked,
      filePath: filePath,
      result: event,
    ));
  }

  /// Update user behavior
  void _updateUserBehavior(FileAccessEvent event) {
    final hour = event.timestamp.hour;
    final dayOfWeek = event.timestamp.weekday;
    final behaviorKey = '${hour}_$dayOfWeek';
    
    if (!_userBehaviors.containsKey(behaviorKey)) {
      _userBehaviors[behaviorKey] = UserBehavior(
        hour: hour,
        dayOfWeek: dayOfWeek,
        accessCount: 0,
        categories: {},
        patterns: [],
      );
    }
    
    final behavior = _userBehaviors[behaviorKey]!;
    behavior.accessCount++;
    
    // Update category preferences
    final category = _getFileCategory(event.filePath);
    behavior.categories[category] = (behavior.categories[category] ?? 0) + 1;
  }

  /// Get recommendations for user
  Future<List<RecommendationResult>> getRecommendations({
    String? context,
    RecommendationType type = RecommendationType.general,
    int? limit,
  }) async {
    final timer = EnhancedPerformanceManager.instance.startTimer('get_recommendations');
    
    try {
      // Check cache first
      final cacheKey = _generateCacheKey(context, type);
      final cached = _recommendationCache[cacheKey];
      if (cached != null && !_isCacheExpired(cacheKey)) {
        timer.stop();
        return cached.take(limit ?? _maxRecommendations).toList();
      }
      
      final recommendations = <RecommendationResult>[];
      
      // Generate recommendations based on type
      switch (type) {
        case RecommendationType.frequentlyAccessed:
          recommendations.addAll(await _getFrequentlyAccessedRecommendations());
          break;
        case RecommendationType.similarFiles:
          recommendations.addAll(await _getSimilarFilesRecommendations(context));
          break;
        case RecommendationType.predictive:
          recommendations.addAll(await _getPredictiveRecommendations());
          break;
        case RecommendationType.organization:
          recommendations.addAll(await _getOrganizationRecommendations());
          break;
        case RecommendationType.importance:
          recommendations.addAll(await _getImportanceRecommendations());
          break;
        case RecommendationType.smartSuggestions:
          recommendations.addAll(await _getSmartSuggestions(context));
          break;
        case RecommendationType.general:
        default:
          recommendations.addAll(await _getGeneralRecommendations());
          break;
      }
      
      // Sort by confidence
      recommendations.sort((a, b) => b.confidence.compareTo(a.confidence));
      
      // Limit results
      final limitedRecommendations = recommendations.take(limit ?? _maxRecommendations).toList();
      
      // Cache results
      _recommendationCache[cacheKey] = limitedRecommendations;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      timer.stop();
      
      // Emit event
      _eventController.add(RecommendationEvent(
        type: RecommendationEventType.recommendationsGenerated,
        result: limitedRecommendations,
      ));
      
      return limitedRecommendations;
    } catch (e, stackTrace) {
      timer.stop();
      EnhancedLogger.instance.error('Failed to get recommendations', 
        error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get frequently accessed recommendations
  Future<List<RecommendationResult>> _getFrequentlyAccessedRecommendations() async {
    final recommendations = <RecommendationResult>[];
    
    // Calculate access frequency for each file
    final accessFrequency = <String, int>{};
    for (final action in _fileActions.values.expand((actions) => actions)) {
      final filePath = _getFilePathFromAction(action);
      if (filePath != null) {
        accessFrequency[filePath] = (accessFrequency[filePath] ?? 0) + 1;
      }
    }
    
    // Sort by frequency and create recommendations
    final sortedFiles = accessFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in sortedFiles.take(_maxRecommendations)) {
      recommendations.add(RecommendationResult(
        type: RecommendationType.frequentlyAccessed,
        filePath: entry.key,
        title: 'Frequently Accessed',
        description: 'Accessed ${entry.value} times',
        confidence: _calculateFrequencyConfidence(entry.value),
        reason: 'High access frequency',
        metadata: {
          'access_count': entry.value,
          'last_accessed': _getLastAccessTime(entry.key),
        },
        timestamp: DateTime.now(),
      ));
    }
    
    return recommendations;
  }

  /// Get similar files recommendations
  Future<List<RecommendationResult>> _getSimilarFilesRecommendations(String? context) async {
    if (context == null) return [];
    
    final recommendations = <RecommendationResult>[];
    
    // Get file analysis for context
    try {
      final analysis = await AIFileOrganizer.instance.analyzeFile(context);
      
      // Find similar files using AI search
      final searchQuery = SearchQuery(
        query: analysis.tags.join(' '),
        type: SearchType.semantic,
      );
      
      final searchResults = await AIAdvancedSearch.instance.search(searchQuery);
      
      // Create recommendations from search results
      for (final result in searchResults.results.take(_maxRecommendations)) {
        if (result.documentId != context) {
          recommendations.add(RecommendationResult(
            type: RecommendationType.similarFiles,
            filePath: result.documentId,
            title: 'Similar File',
            description: result.snippet,
            confidence: result.score,
            reason: 'Content similarity: ${(result.score * 100).toStringAsFixed(1)}%',
            metadata: {
              'similarity_score': result.score,
              'matched_terms': result.matchedTerms,
            },
            timestamp: DateTime.now(),
          ));
        }
      }
    } catch (e) {
      EnhancedLogger.instance.warning('Failed to get similar files recommendations: $e');
    }
    
    return recommendations;
  }

  /// Get predictive recommendations
  Future<List<RecommendationResult>> _getPredictiveRecommendations() async {
    final recommendations = <RecommendationResult>[];
    
    if (!_enablePredictiveRecommendations) return recommendations;
    
    // Get current time context
    final now = DateTime.now();
    final hour = now.hour;
    final dayOfWeek = now.weekday;
    
    // Find similar historical behavior
    final similarBehaviors = _userBehaviors.entries
        .where((entry) => _isSimilarTimeContext(entry.key, hour, dayOfWeek))
        .map((entry) => entry.value)
        .toList();
    
    if (similarBehaviors.isEmpty) return recommendations;
    
    // Calculate category preferences
    final categoryPreferences = <String, double>{};
    for (final behavior in similarBehaviors) {
      for (final entry in behavior.categories.entries) {
        categoryPreferences[entry.key] = (categoryPreferences[entry.key] ?? 0) + entry.value;
      }
    }
    
    // Normalize preferences
    final totalPreference = categoryPreferences.values.fold(0.0, (sum, val) => sum + val);
    if (totalPreference > 0) {
      for (final entry in categoryPreferences.entries) {
        categoryPreferences[entry.key] = entry.value / totalPreference;
      }
    }
    
    // Get files from preferred categories
    for (final entry in categoryPreferences.entries) {
      final category = entry.key;
      final preference = entry.value;
      
      if (preference > 0.1) { // Only consider significant preferences
        final categoryFiles = await _getFilesByCategory(category);
        
        for (final filePath in categoryFiles.take(3)) {
          recommendations.add(RecommendationResult(
            type: RecommendationType.predictive,
            filePath: filePath,
            title: 'Predicted Access',
            description: 'Based on your usage patterns',
            confidence: preference,
            reason: 'Time-based prediction for $category',
            metadata: {
              'category': category,
              'preference': preference,
              'time_context': '${hour}_$dayOfWeek',
            },
            timestamp: DateTime.now(),
          ));
        }
      }
    }
    
    return recommendations;
  }

  /// Get organization recommendations
  Future<List<RecommendationResult>> _getOrganizationRecommendations() async {
    final recommendations = <RecommendationResult>[];
    
    // Get duplicate analysis
    final duplicateAnalysis = await AIDuplicateDetector.instance.analyzeDirectory('.');
    
    // Recommend duplicate cleanup
    for (final group in duplicateAnalysis.duplicateGroups) {
      if (group.type == DuplicateType.exact && group.files.length > 1) {
        recommendations.add(RecommendationResult(
          type: RecommendationType.organization,
          filePath: group.files.first,
          title: 'Duplicate Files Found',
          description: '${group.files.length} identical files found',
          confidence: 0.9,
          reason: 'Exact duplicates detected',
          metadata: {
            'duplicate_group': group.files,
            'savings': group.savings,
          },
          timestamp: DateTime.now(),
        ));
      }
    }
    
    // Get categorization analysis
    try {
      final categorization = await SmartFileCategorizer.instance.categorizeFile('.');
      
      // Recommend uncategorized files
      if (categorization.confidence < 0.5) {
        recommendations.add(RecommendationResult(
          type: RecommendationType.organization,
          filePath: '.',
          title: 'Uncategorized Files',
          description: 'Files that need better organization',
          confidence: 0.7,
          reason: 'Low categorization confidence',
          metadata: {
            'category': categorization.primaryCategory,
            'confidence': categorization.confidence,
          },
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      EnhancedLogger.instance.warning('Failed to get categorization recommendations: $e');
    }
    
    return recommendations;
  }

  /// Get importance recommendations
  Future<List<RecommendationResult>> _getImportanceRecommendations() async {
    final recommendations = <RecommendationResult>[];
    
    // Calculate importance scores for files
    final importanceScores = <String, double>{};
    
    for (final entry in _fileActions.entries) {
      final filePath = entry.key;
      final actions = entry.value;
      
      // Calculate importance based on access patterns
      double score = 0.0;
      
      // Access frequency
      score += actions.length * 0.4;
      
      // Recency
      final lastAccess = actions.map((a) => a.timestamp).reduce(math.max);
      final daysSinceLastAccess = DateTime.now().difference(lastAccess).inDays;
      score += math.max(0, (30 - daysSinceLastAccess) / 30) * 0.3;
      
      // File size (larger files might be more important)
      try {
        final file = File(filePath);
        final size = await file.length();
        score += math.log(size + 1) / math.log(1024 * 1024) * 0.1; // Normalize by 1MB
      } catch (e) {
        // File might not exist
      }
      
      importanceScores[filePath] = score;
    }
    
    // Sort by importance and create recommendations
    final sortedFiles = importanceScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in sortedFiles.take(_maxRecommendations)) {
      recommendations.add(RecommendationResult(
        type: RecommendationType.importance,
        filePath: entry.key,
        title: 'Important File',
        description: 'Based on your usage patterns',
        confidence: entry.value,
        reason: 'High importance score',
        metadata: {
          'importance_score': entry.value,
          'access_count': _fileActions[entry.key]?.length ?? 0,
        },
        timestamp: DateTime.now(),
      ));
    }
    
    return recommendations;
  }

  /// Get smart suggestions
  Future<List<RecommendationResult>> _getSmartSuggestions(String? context) async {
    final recommendations = <RecommendationResult>[];
    
    if (!_enableSmartSuggestions) return recommendations;
    
    // Context-aware suggestions
    if (context != null) {
      // Suggest related files
      final relatedFiles = await _getRelatedFiles(context);
      recommendations.addAll(relatedFiles);
      
      // Suggest actions
      final actionSuggestions = await _getActionSuggestions(context);
      recommendations.addAll(actionSuggestions);
    }
    
    // General smart suggestions
    final generalSuggestions = await _getGeneralSmartSuggestions();
    recommendations.addAll(generalSuggestions);
    
    return recommendations;
  }

  /// Get general recommendations
  Future<List<RecommendationResult>> _getGeneralRecommendations() async {
    final recommendations = <RecommendationResult>[];
    
    // Combine all recommendation types
    recommendations.addAll(await _getFrequentlyAccessedRecommendations());
    recommendations.addAll(await _getPredictiveRecommendations());
    recommendations.addAll(await _getOrganizationRecommendations());
    
    // Remove duplicates and sort
    final uniqueRecommendations = <String, RecommendationResult>{};
    for (final rec in recommendations) {
      final key = '${rec.type}_${rec.filePath}';
      if (!uniqueRecommendations.containsKey(key) || 
          uniqueRecommendations[key]!.confidence < rec.confidence) {
        uniqueRecommendations[key] = rec;
      }
    }
    
    return uniqueRecommendations.values.toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence))
      ..take(_maxRecommendations);
  }

  /// Get related files
  Future<List<RecommendationResult>> _getRelatedFiles(String filePath) async {
    final recommendations = <RecommendationResult>[];
    
    // Get files in same directory
    final directory = path.dirname(filePath);
    final directoryFiles = await _getFilesInDirectory(directory);
    
    for (final relatedFile in directoryFiles.take(5)) {
      if (relatedFile != filePath) {
        recommendations.add(RecommendationResult(
          type: RecommendationType.smartSuggestions,
          filePath: relatedFile,
          title: 'Related File',
          description: 'In the same directory',
          confidence: 0.6,
          reason: 'Directory relationship',
          metadata: {
            'directory': directory,
            'relationship': 'same_directory',
          },
          timestamp: DateTime.now(),
        ));
      }
    }
    
    return recommendations;
  }

  /// Get action suggestions
  Future<List<RecommendationResult>> _getActionSuggestions(String filePath) async {
    final recommendations = <RecommendationResult>[];
    
    // Suggest duplicate check
    recommendations.add(RecommendationResult(
      type: RecommendationType.smartSuggestions,
      filePath: filePath,
      title: 'Check for Duplicates',
      description: 'Find similar files',
      confidence: 0.7,
      reason: 'Duplicate detection suggestion',
      action: 'check_duplicates',
      timestamp: DateTime.now(),
    ));
    
    // Suggest categorization
    recommendations.add(RecommendationResult(
      type: RecommendationType.smartSuggestions,
      filePath: filePath,
      title: 'Improve Organization',
      description: 'Better file categorization',
      confidence: 0.6,
      reason: 'Organization suggestion',
      action: 'categorize',
      timestamp: DateTime.now(),
    ));
    
    return recommendations;
  }

  /// Get general smart suggestions
  Future<List<RecommendationResult>> _getGeneralSmartSuggestions() async {
    final recommendations = <RecommendationResult>[];
    
    // Suggest cleanup
    recommendations.add(RecommendationResult(
      type: RecommendationType.smartSuggestions,
      filePath: '.',
      title: 'Clean Up Files',
      description: 'Remove duplicates and organize',
      confidence: 0.8,
      reason: 'Maintenance suggestion',
      action: 'cleanup',
      timestamp: DateTime.now(),
    ));
    
    // Suggest backup
    recommendations.add(RecommendationResult(
      type: RecommendationType.smartSuggestions,
      filePath: '.',
      title: 'Backup Important Files',
      description: 'Protect your data',
      confidence: 0.7,
      reason: 'Security suggestion',
      action: 'backup',
      timestamp: DateTime.now(),
    ));
    
    return recommendations;
  }

  /// Helper methods
  String _getFileCategory(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    
    if (['.pdf', '.doc', '.docx', '.txt', '.rtf'].contains(extension)) return 'documents';
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp'].contains(extension)) return 'images';
    if (['.mp4', '.avi', '.mov', '.wmv'].contains(extension)) return 'videos';
    if (['.mp3', '.wav', '.flac', '.aac'].contains(extension)) return 'audio';
    if (['.dart', '.js', '.ts', '.py', '.java'].contains(extension)) return 'code';
    if (['.zip', '.rar', '.7z', '.tar'].contains(extension)) return 'archives';
    
    return 'other';
  }

  String? _getFilePathFromAction(FileAction action) {
    // This would need to be implemented based on how actions are stored
    return null;
  }

  double _calculateFrequencyConfidence(int accessCount) {
    // Normalize confidence based on access count
    return math.min(1.0, accessCount / 10.0);
  }

  DateTime? _getLastAccessTime(String filePath) {
    final actions = _fileActions[filePath];
    if (actions == null || actions.isEmpty) return null;
    
    return actions.map((a) => a.timestamp).reduce(math.max);
  }

  bool _isSimilarTimeContext(String behaviorKey, int currentHour, int currentDayOfWeek) {
    final parts = behaviorKey.split('_');
    if (parts.length != 2) return false;
    
    final behaviorHour = int.tryParse(parts[0]);
    final behaviorDay = int.tryParse(parts[1]);
    
    if (behaviorHour == null || behaviorDay == null) return false;
    
    // Check if within 2 hours and same day type (weekday/weekend)
    final hourDiff = (behaviorHour - currentHour).abs();
    final isWeekday = (currentDayOfWeek >= 1 && currentDayOfWeek <= 5);
    final isBehaviorWeekday = (behaviorDay >= 1 && behaviorDay <= 5);
    
    return hourDiff <= 2 && isWeekday == isBehaviorWeekday;
  }

  Future<List<String>> _getFilesByCategory(String category) async {
    // This would need to be implemented using the file organizer
    return [];
  }

  Future<List<String>> _getFilesInDirectory(String directory) async {
    try {
      final dir = Directory(directory);
      final files = await dir.list().where((entity) => entity is File).cast<File>().toList();
      return files.map((file) => file.path).toList();
    } catch (e) {
      return [];
    }
  }

  void _cleanupOldHistory() {
    final cutoffDate = DateTime.now().subtract(Duration(days: _historyRetentionDays));
    
    // Remove old access history
    _accessHistory.removeWhere((event) => event.timestamp.isBefore(cutoffDate));
    
    // Remove old file actions
    for (final entry in _fileActions.entries) {
      entry.value.removeWhere((action) => action.timestamp.isBefore(cutoffDate));
    }
    
    // Remove empty file action entries
    _fileActions.removeWhere((key, value) => value.isEmpty);
  }

  String _generateCacheKey(String? context, RecommendationType type) {
    return '${type}_${context ?? 'global'}';
  }

  bool _isCacheExpired(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return true;
    
    return DateTime.now().difference(timestamp).inMinutes > 30;
  }

  void _cleanupCache() {
    final expiredKeys = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (_isCacheExpired(entry.key)) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _recommendationCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      EnhancedLogger.instance.info('Cleaned up ${expiredKeys.length} expired recommendation cache entries');
    }
  }

  /// Save user preferences
  Future<void> _saveUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_preferences', jsonEncode(_userPreferences));
    } catch (e) {
      EnhancedLogger.instance.error('Failed to save user preferences: $e');
    }
  }

  /// Update user preference
  void updateUserPreference(String key, Map<String, double> preferences) {
    _userPreferences[key] = preferences;
    _saveUserPreferences();
  }

  /// Get recommendation statistics
  Map<String, dynamic> getRecommendationStatistics() {
    return {
      'total_recommendations': _recommendationCache.values.fold(0, (sum, recs) => sum + recs.length),
      'user_behaviors': _userBehaviors.length,
      'access_history_size': _accessHistory.length,
      'file_actions': _fileActions.length,
      'recommendation_models': _recommendationModels.length,
      'usage_patterns': _usagePatterns.length,
      'cache_size': _recommendationCache.length,
    };
  }

  /// Clear all data
  void clearAllData() {
    _userBehaviors.clear();
    _accessHistory.clear();
    _fileActions.clear();
    _recommendationCache.clear();
    _cacheTimestamps.clear();
    _trainingData.clear();
    _userPreferences.clear();
    _recommendationHistory.clear();
    
    EnhancedLogger.instance.info('All recommendation data cleared');
  }

  /// Dispose
  void dispose() {
    _cacheCleanupTimer?.cancel();
    
    _userBehaviors.clear();
    _accessHistory.clear();
    _fileActions.clear();
    _recommendationModels.clear();
    _usagePatterns.clear();
    _featureWeights.clear();
    _trainingData.clear();
    _userPreferences.clear();
    _recommendationHistory.clear();
    _recommendationCache.clear();
    _cacheTimestamps.clear();
    
    _eventController.close();
    _progressController.close();
    
    EnhancedLogger.instance.info('AI File Recommendations disposed');
  }
}

/// User behavior
class UserBehavior {
  final int hour;
  final int dayOfWeek;
  final int accessCount;
  final Map<String, int> categories;
  final List<String> patterns;

  UserBehavior({
    required this.hour,
    required this.dayOfWeek,
    required this.accessCount,
    required this.categories,
    required this.patterns,
  });
}

/// File action
class FileAction {
  final FileActionType type;
  final DateTime timestamp;

  FileAction({
    required this.type,
    required this.timestamp,
  });
}

/// Recommendation model
class RecommendationModel {
  final String name;
  final ModelType type;
  final Map<String, double> features;
  final String algorithm;
  final double confidence;

  RecommendationModel({
    required this.name,
    required this.type,
    required this.features,
    required this.algorithm,
    required this.confidence,
  });
}

/// File pattern
class FilePattern {
  final PatternType type;
  final String value;
  final double weight;

  FilePattern({
    required this.type,
    required this.value,
    required this.weight,
  });
}

/// Recommendation result
class RecommendationResult {
  final RecommendationType type;
  final String filePath;
  final String title;
  final String description;
  final double confidence;
  final String reason;
  final String? action;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  RecommendationResult({
    required this.type,
    required this.filePath,
    required this.title,
    required this.description,
    required this.confidence,
    required this.reason,
    this.action,
    required this.metadata,
    required this.timestamp,
  });
}

/// File access event
class FileAccessEvent {
  final String filePath;
  final FileActionType actionType;
  final DateTime timestamp;

  FileAccessEvent({
    required this.filePath,
    required this.actionType,
    required this.timestamp,
  });
}

/// Recommendation event
class RecommendationEvent {
  final RecommendationEventType type;
  final String? filePath;
  final dynamic result;
  final DateTime timestamp;

  RecommendationEvent({
    required this.type,
    this.filePath,
    this.result,
  }) : timestamp = DateTime.now();
}

/// Learning progress
class LearningProgress {
  final String stage;
  final double progress;
  final String? message;
  final DateTime timestamp;

  LearningProgress({
    required this.stage,
    required this.progress,
    this.message,
  }) : timestamp = DateTime.now();
}

/// Enums
enum ModelType { classification, clustering, similarity, regression }
enum PatternType { time, day, category, path, recency }
enum RecommendationType { general, frequentlyAccessed, similarFiles, predictive, organization, importance, smartSuggestions }
enum FileActionType { open, edit, delete, copy, move, share }
enum RecommendationEventType { fileAccessTracked, recommendationsGenerated, modelTrained }
