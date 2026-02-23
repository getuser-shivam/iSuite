import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'advanced_document_intelligence_service.dart';
import '../../core/logging/logging_service.dart';
import '../../core/config/central_config.dart';

/// Predictive Analytics Service for Document Lifecycle Management
///
/// Uses AI and machine learning to predict document lifecycle events and optimize productivity:
/// - Predict when documents need updates or reviews
/// - Determine optimal archiving and deletion schedules
/// - Analyze usage patterns for lifecycle optimization
/// - Provide proactive maintenance recommendations
/// - Optimize storage and organization based on predictive insights
class PredictiveAnalyticsService {
  static final PredictiveAnalyticsService _instance = PredictiveAnalyticsService._internal();
  factory PredictiveAnalyticsService() => _instance;
  PredictiveAnalyticsService._internal();

  final LoggingService _logger = LoggingService();
  final CentralConfig _config = CentralConfig.instance;
  final AdvancedDocumentIntelligenceService _documentIntelligence = AdvancedDocumentIntelligenceService();

  GenerativeModel? _model;
  bool _isInitialized = false;

  // Analytics data
  final Map<String, DocumentLifecycleData> _documentLifecycles = {};
  final Map<String, UsagePattern> _usagePatterns = {};
  final List<PredictiveInsight> _insights = [];
  final StreamController<PredictiveInsight> _insightsController = StreamController.broadcast();

  // Prediction models
  final Map<String, PredictiveModel> _predictionModels = {};
  Timer? _analysisTimer;

  /// Initialize the predictive analytics service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Predictive Analytics Service', 'PredictiveAnalytics');

      // Check if predictive analytics is enabled
      final predictiveEnabled = _config.getParameter('ai.workflow.enabled', defaultValue: true);
      if (!predictiveEnabled) {
        _logger.info('Predictive analytics disabled', 'PredictiveAnalytics');
        _isInitialized = true;
        return;
      }

      // Initialize AI model for predictions
      await _initializeAIModel();

      // Start background analysis
      _startBackgroundAnalysis();

      _isInitialized = true;
      _logger.info('Predictive Analytics Service initialized successfully', 'PredictiveAnalytics');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Predictive Analytics Service', 'PredictiveAnalytics',
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
            temperature: _config.getParameter('ai.temperature', defaultValue: 0.2), // Lower temperature for predictions
            maxOutputTokens: _config.getParameter('ai.max_tokens', defaultValue: 1024),
          ),
        );
        _logger.info('AI model initialized for predictive analytics', 'PredictiveAnalytics');
      }
    } catch (e) {
      _logger.error('Failed to initialize AI model for predictions', 'PredictiveAnalytics', error: e);
    }
  }

  void _startBackgroundAnalysis() {
    // Run analysis every 6 hours
    _analysisTimer = Timer.periodic(Duration(hours: 6), (timer) {
      _performBackgroundAnalysis();
    });

    // Initial analysis
    _performBackgroundAnalysis();
  }

  Future<void> _performBackgroundAnalysis() async {
    try {
      _logger.info('Performing background predictive analysis', 'PredictiveAnalytics');

      // Analyze document lifecycles
      await _analyzeDocumentLifecycles();

      // Update usage patterns
      await _updateUsagePatterns();

      // Generate predictions
      await _generatePredictions();

      // Clean up old data
      _cleanupOldData();

      _logger.info('Background predictive analysis completed', 'PredictiveAnalytics');

    } catch (e, stackTrace) {
      _logger.error('Background predictive analysis failed', 'PredictiveAnalytics',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Record document access for pattern analysis
  void recordDocumentAccess(String filePath, String userId, String accessType) {
    final lifecycle = _documentLifecycles.putIfAbsent(filePath, () => DocumentLifecycleData(filePath));
    final access = DocumentAccess(
      timestamp: DateTime.now(),
      userId: userId,
      accessType: accessType,
    );

    lifecycle.accessHistory.add(access);

    // Keep only last 1000 accesses per document
    if (lifecycle.accessHistory.length > 1000) {
      lifecycle.accessHistory.removeRange(0, lifecycle.accessHistory.length - 1000);
    }

    // Update usage patterns
    _updateUsagePatternForAccess(filePath, access);
  }

  /// Get lifecycle predictions for a document
  Future<DocumentLifecyclePrediction> getLifecyclePrediction(String filePath) async {
    final lifecycle = _documentLifecycles[filePath];
    if (lifecycle == null) {
      return DocumentLifecyclePrediction(
        filePath: filePath,
        predictedActions: [],
        confidence: 0.0,
      );
    }

    return await _predictLifecycle(lifecycle);
  }

  /// Get predictive insights
  List<PredictiveInsight> getPredictiveInsights({int limit = 20}) {
    return _insights.take(limit).toList();
  }

  /// Get usage analytics for a document
  UsageAnalytics getUsageAnalytics(String filePath) {
    final lifecycle = _documentLifecycles[filePath];
    if (lifecycle == null) {
      return UsageAnalytics(
        filePath: filePath,
        totalAccesses: 0,
        uniqueUsers: 0,
        averageAccessFrequency: 0.0,
        lastAccessed: null,
        accessPatterns: {},
      );
    }

    return _calculateUsageAnalytics(lifecycle);
  }

  /// Generate storage optimization recommendations
  Future<List<StorageRecommendation>> generateStorageRecommendations() async {
    final recommendations = <StorageRecommendation>[];

    // Analyze all documents
    for (final entry in _documentLifecycles.entries) {
      final lifecycle = entry.value;
      final analytics = _calculateUsageAnalytics(lifecycle);

      // Check for archiving candidates
      if (_shouldArchiveDocument(analytics)) {
        recommendations.add(StorageRecommendation(
          type: 'archive',
          filePath: lifecycle.filePath,
          reason: 'Low usage frequency and old last access',
          priority: _calculateArchivePriority(analytics),
          estimatedSavings: _estimateStorageSavings(lifecycle),
        ));
      }

      // Check for deletion candidates
      if (_shouldDeleteDocument(analytics)) {
        recommendations.add(StorageRecommendation(
          type: 'delete',
          filePath: lifecycle.filePath,
          reason: 'No recent access and low relevance',
          priority: _calculateDeletionPriority(analytics),
          estimatedSavings: _estimateStorageSavings(lifecycle),
        ));
      }
    }

    // Sort by priority
    recommendations.sort((a, b) => b.priority.compareTo(a.priority));

    return recommendations.take(50).toList(); // Top 50 recommendations
  }

  Future<void> _analyzeDocumentLifecycles() async {
    for (final entry in _documentLifecycles.entries) {
      final lifecycle = entry.value;

      // Calculate lifecycle metrics
      lifecycle.daysSinceLastAccess = _calculateDaysSinceLastAccess(lifecycle);
      lifecycle.accessFrequency = _calculateAccessFrequency(lifecycle);
      lifecycle.relevanceScore = await _calculateRelevanceScore(lifecycle);

      // Generate AI-powered insights if available
      if (_model != null) {
        await _generateAIInsights(lifecycle);
      }
    }
  }

  Future<void> _updateUsagePatterns() async {
    // Analyze access patterns across all documents
    final allAccesses = <DocumentAccess>[];
    for (final lifecycle in _documentLifecycles.values) {
      allAccesses.addAll(lifecycle.accessHistory);
    }

    // Group by time patterns
    final hourlyPatterns = <int, int>{};
    final dailyPatterns = <int, int>{};
    final weeklyPatterns = <int, int>{};

    for (final access in allAccesses) {
      hourlyPatterns[access.timestamp.hour] = (hourlyPatterns[access.timestamp.hour] ?? 0) + 1;
      dailyPatterns[access.timestamp.weekday] = (dailyPatterns[access.timestamp.weekday] ?? 0) + 1;
      weeklyPatterns[access.timestamp.month] = (weeklyPatterns[access.timestamp.month] ?? 0) + 1;
    }

    _usagePatterns['global'] = UsagePattern(
      patternType: 'global',
      hourlyDistribution: hourlyPatterns,
      dailyDistribution: dailyPatterns,
      weeklyDistribution: weeklyPatterns,
      peakHours: _findPeakPeriods(hourlyPatterns),
      lowActivityPeriods: _findLowActivityPeriods(hourlyPatterns),
    );
  }

  Future<void> _generatePredictions() async {
    final newInsights = <PredictiveInsight>[];

    for (final entry in _documentLifecycles.entries) {
      final lifecycle = entry.value;

      // Predict update needs
      if (_predictsNeedsUpdate(lifecycle)) {
        newInsights.add(PredictiveInsight(
          type: 'update_needed',
          filePath: lifecycle.filePath,
          message: 'Document may need updates based on usage patterns',
          confidence: 0.75,
          suggestedActions: ['Review content', 'Update metadata', 'Check for newer versions'],
          timestamp: DateTime.now(),
        ));
      }

      // Predict archiving needs
      if (_predictsShouldArchive(lifecycle)) {
        newInsights.add(PredictiveInsight(
          type: 'archive_candidate',
          filePath: lifecycle.filePath,
          message: 'Document is a candidate for archiving',
          confidence: 0.8,
          suggestedActions: ['Move to archive storage', 'Update access permissions'],
          timestamp: DateTime.now(),
        ));
      }

      // Predict collaboration opportunities
      final collaborationPrediction = await _predictCollaborationOpportunities(lifecycle);
      if (collaborationPrediction != null) {
        newInsights.add(collaborationPrediction);
      }
    }

    // Add new insights
    _insights.addAll(newInsights);

    // Keep only recent insights (last 1000)
    if (_insights.length > 1000) {
      _insights.removeRange(0, _insights.length - 1000);
    }

    // Emit new insights
    for (final insight in newInsights) {
      _insightsController.add(insight);
    }
  }

  Future<DocumentLifecyclePrediction> _predictLifecycle(DocumentLifecycleData lifecycle) async {
    final prediction = DocumentLifecyclePrediction(
      filePath: lifecycle.filePath,
      predictedActions: [],
      confidence: 0.0,
    );

    // Basic predictions based on access patterns
    if (lifecycle.daysSinceLastAccess > 90) {
      prediction.predictedActions.add(PredictedAction(
        action: 'archive',
        probability: 0.8,
        timeframe: Duration(days: 30),
        reasoning: 'No access for ${lifecycle.daysSinceLastAccess} days',
      ));
    }

    if (lifecycle.accessFrequency < 0.1) { // Less than once per 10 days
      prediction.predictedActions.add(PredictedAction(
        action: 'review',
        probability: 0.6,
        timeframe: Duration(days: 60),
        reasoning: 'Low access frequency suggests review needed',
      ));
    }

    // AI-powered predictions
    if (_model != null) {
      final aiPredictions = await _generateAIPredictions(lifecycle);
      prediction.predictedActions.addAll(aiPredictions);
    }

    // Calculate overall confidence
    prediction.confidence = prediction.predictedActions.isNotEmpty ?
      prediction.predictedActions.map((a) => a.probability).reduce(max) : 0.0;

    return prediction;
  }

  Future<List<PredictedAction>> _generateAIPredictions(DocumentLifecycleData lifecycle) async {
    if (_model == null) return [];

    try {
      final accessPattern = lifecycle.accessHistory.take(20).map((access) =>
        '${access.timestamp.toIso8601String()}: ${access.accessType} by ${access.userId}'
      ).join('\n');

      final prompt = '''
Analyze this document's access pattern and predict future lifecycle actions:

ACCESS HISTORY (last 20 accesses):
$accessPattern

CURRENT METRICS:
- Days since last access: ${lifecycle.daysSinceLastAccess}
- Access frequency: ${lifecycle.accessFrequency} accesses/day
- Relevance score: ${lifecycle.relevanceScore}

Predict the most likely actions needed for this document in the next 30-90 days.
For each prediction, provide:
1. ACTION: (archive, review, update, delete, collaborate)
2. PROBABILITY: (0.0-1.0)
3. TIMEFRAME_DAYS: (number of days)
4. REASONING: (brief explanation)

Format as JSON array of predictions.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final result = response.text;

      if (result != null) {
        final predictions = _parseAIPredictions(result);
        return predictions;
      }
    } catch (e) {
      _logger.warning('AI lifecycle prediction failed', 'PredictiveAnalytics', error: e);
    }

    return [];
  }

  List<PredictedAction> _parseAIPredictions(String response) {
    final predictions = <PredictedAction>[];

    try {
      // Extract JSON array from response
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd);
        final jsonList = json.decode(jsonStr) as List;

        for (final item in jsonList) {
          if (item is Map) {
            predictions.add(PredictedAction(
              action: item['ACTION']?.toString() ?? 'unknown',
              probability: (item['PROBABILITY'] as num?)?.toDouble() ?? 0.5,
              timeframe: Duration(days: (item['TIMEFRAME_DAYS'] as num?)?.toInt() ?? 30),
              reasoning: item['REASONING']?.toString() ?? 'AI prediction',
            ));
          }
        }
      }
    } catch (e) {
      _logger.warning('Failed to parse AI predictions', 'PredictiveAnalytics', error: e);
    }

    return predictions;
  }

  Future<void> _generateAIInsights(DocumentLifecycleData lifecycle) async {
    if (_model == null) return;

    try {
      final prompt = '''
Analyze this document's lifecycle and provide insights:

METRICS:
- Days since last access: ${lifecycle.daysSinceLastAccess}
- Access frequency: ${lifecycle.accessFrequency}
- Relevance score: ${lifecycle.relevanceScore}
- Total accesses: ${lifecycle.accessHistory.length}

Provide insights about:
1. Current status and health
2. Predicted future usage
3. Recommended actions
4. Potential risks or opportunities

Keep response concise but informative.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      lifecycle.aiInsights = response.text;
    } catch (e) {
      _logger.warning('AI insights generation failed', 'PredictiveAnalytics', error: e);
    }
  }

  // Utility methods
  int _calculateDaysSinceLastAccess(DocumentLifecycleData lifecycle) {
    if (lifecycle.accessHistory.isEmpty) return 999;
    final lastAccess = lifecycle.accessHistory.map((a) => a.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);
    return DateTime.now().difference(lastAccess).inDays;
  }

  double _calculateAccessFrequency(DocumentLifecycleData lifecycle) {
    if (lifecycle.accessHistory.length < 2) return 0.0;

    final sortedAccesses = lifecycle.accessHistory.map((a) => a.timestamp).toList()
      ..sort();

    final totalSpan = sortedAccesses.last.difference(sortedAccesses.first).inDays;
    if (totalSpan == 0) return lifecycle.accessHistory.length.toDouble();

    return lifecycle.accessHistory.length / totalSpan;
  }

  Future<double> _calculateRelevanceScore(DocumentLifecycleData lifecycle) async {
    double score = 0.5; // Base score

    // Recency factor
    final daysSinceLastAccess = _calculateDaysSinceLastAccess(lifecycle);
    if (daysSinceLastAccess < 7) score += 0.3;
    else if (daysSinceLastAccess < 30) score += 0.1;
    else if (daysSinceLastAccess > 365) score -= 0.2;

    // Frequency factor
    final frequency = _calculateAccessFrequency(lifecycle);
    if (frequency > 1.0) score += 0.2; // Daily access
    else if (frequency > 0.1) score += 0.1; // Weekly access

    // AI-powered relevance if available
    if (_model != null && lifecycle.aiInsights != null) {
      final aiRelevance = await _extractAIRelevance(lifecycle.aiInsights!);
      score = (score + aiRelevance) / 2; // Average with AI insight
    }

    return score.clamp(0.0, 1.0);
  }

  Future<double> _extractAIRelevance(String aiInsights) async {
    // Simple keyword-based relevance extraction
    final lowerInsights = aiInsights.toLowerCase();
    if (lowerInsights.contains('high') || lowerInsights.contains('important')) return 0.8;
    if (lowerInsights.contains('medium') || lowerInsights.contains('moderate')) return 0.6;
    if (lowerInsights.contains('low') || lowerInsights.contains('obsolete')) return 0.3;
    return 0.5; // Default
  }

  void _updateUsagePatternForAccess(String filePath, DocumentAccess access) {
    final pattern = _usagePatterns.putIfAbsent(filePath, () => UsagePattern(
      patternType: 'document',
      hourlyDistribution: {},
      dailyDistribution: {},
      weeklyDistribution: {},
      peakHours: [],
      lowActivityPeriods: [],
    ));

    pattern.hourlyDistribution[access.timestamp.hour] =
      (pattern.hourlyDistribution[access.timestamp.hour] ?? 0) + 1;

    pattern.dailyDistribution[access.timestamp.weekday] =
      (pattern.dailyDistribution[access.timestamp.weekday] ?? 0) + 1;

    pattern.weeklyDistribution[access.timestamp.month] =
      (pattern.weeklyDistribution[access.timestamp.month] ?? 0) + 1;
  }

  UsageAnalytics _calculateUsageAnalytics(DocumentLifecycleData lifecycle) {
    final accesses = lifecycle.accessHistory;
    final uniqueUsers = accesses.map((a) => a.userId).toSet().length;

    final lastAccessed = accesses.isEmpty ? null :
      accesses.map((a) => a.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);

    final accessPatterns = <String, int>{};
    for (final access in accesses) {
      accessPatterns[access.accessType] = (accessPatterns[access.accessType] ?? 0) + 1;
    }

    return UsageAnalytics(
      filePath: lifecycle.filePath,
      totalAccesses: accesses.length,
      uniqueUsers: uniqueUsers,
      averageAccessFrequency: _calculateAccessFrequency(lifecycle),
      lastAccessed: lastAccessed,
      accessPatterns: accessPatterns,
    );
  }

  bool _shouldArchiveDocument(UsageAnalytics analytics) {
    return analytics.daysSinceLastAccess > 180 && // 6 months
           analytics.averageAccessFrequency < 0.03; // Less than once per month
  }

  bool _shouldDeleteDocument(UsageAnalytics analytics) {
    return analytics.daysSinceLastAccess > 365 && // 1 year
           analytics.averageAccessFrequency < 0.01 && // Less than once per 3 months
           analytics.totalAccesses < 5; // Very few accesses
  }

  double _calculateArchivePriority(UsageAnalytics analytics) {
    double priority = 0.5;

    if (analytics.daysSinceLastAccess > 365) priority += 0.3;
    if (analytics.averageAccessFrequency < 0.01) priority += 0.2;

    return priority.clamp(0.0, 1.0);
  }

  double _calculateDeletionPriority(UsageAnalytics analytics) {
    double priority = 0.3;

    if (analytics.daysSinceLastAccess > 730) priority += 0.4; // 2 years
    if (analytics.averageAccessFrequency < 0.005) priority += 0.3; // Less than once per 6 months

    return priority.clamp(0.0, 1.0);
  }

  int _estimateStorageSavings(DocumentLifecycleData lifecycle) {
    // Estimate based on file size and access patterns
    // This is a simplified estimation
    return (lifecycle.fileSize ?? 0) * 0.8 ~/ 1; // Assume 80% savings for compressed archival
  }

  bool _predictsNeedsUpdate(DocumentLifecycleData lifecycle) {
    return lifecycle.daysSinceLastAccess < 30 &&
           lifecycle.accessFrequency > 0.5 && // Frequent access
           lifecycle.relevanceScore > 0.7; // High relevance
  }

  bool _predictsShouldArchive(DocumentLifecycleData lifecycle) {
    return lifecycle.daysSinceLastAccess > 120 &&
           lifecycle.accessFrequency < 0.05;
  }

  Future<PredictiveInsight?> _predictCollaborationOpportunities(DocumentLifecycleData lifecycle) async {
    // Check for collaboration patterns
    final recentAccesses = lifecycle.accessHistory
      .where((a) => a.timestamp.isAfter(DateTime.now().subtract(Duration(days: 30))))
      .toList();

    if (recentAccesses.length >= 3) {
      final uniqueUsers = recentAccesses.map((a) => a.userId).toSet().length;
      if (uniqueUsers >= 3) {
        return PredictiveInsight(
          type: 'collaboration_opportunity',
          filePath: lifecycle.filePath,
          message: 'Document shows collaborative usage pattern',
          confidence: 0.7,
          suggestedActions: ['Share with team', 'Set up collaborative editing', 'Create version control'],
          timestamp: DateTime.now(),
        );
      }
    }

    return null;
  }

  List<int> _findPeakPeriods(Map<int, int> distribution) {
    if (distribution.isEmpty) return [];

    final maxValue = distribution.values.reduce(max);
    return distribution.entries
      .where((e) => e.value >= maxValue * 0.8) // At least 80% of peak
      .map((e) => e.key)
      .toList();
  }

  List<int> _findLowActivityPeriods(Map<int, int> distribution) {
    if (distribution.isEmpty) return [];

    final avgValue = distribution.values.reduce((a, b) => a + b) / distribution.length;
    return distribution.entries
      .where((e) => e.value <= avgValue * 0.3) // At most 30% of average
      .map((e) => e.key)
      .toList();
  }

  void _cleanupOldData() {
    final cutoffDate = DateTime.now().subtract(Duration(days: 365)); // Keep 1 year of data

    for (final lifecycle in _documentLifecycles.values) {
      lifecycle.accessHistory.removeWhere((access) => access.timestamp.isBefore(cutoffDate));
    }

    // Remove insights older than 90 days
    _insights.removeWhere((insight) => insight.timestamp.isBefore(
      DateTime.now().subtract(Duration(days: 90))
    ));
  }

  // Getters
  bool get isInitialized => _isInitialized;
  Stream<PredictiveInsight> get insights => _insightsController.stream;
  Map<String, DocumentLifecycleData> get documentLifecycles => Map.from(_documentLifecycles);
  Map<String, UsagePattern> get usagePatterns => Map.from(_usagePatterns);
}

/// Supporting data classes

class DocumentLifecycleData {
  final String filePath;
  final List<DocumentAccess> accessHistory = [];
  int? fileSize;
  double relevanceScore = 0.5;
  int daysSinceLastAccess = 0;
  double accessFrequency = 0.0;
  String? aiInsights;

  DocumentLifecycleData(this.filePath);
}

class DocumentAccess {
  final DateTime timestamp;
  final String userId;
  final String accessType; // read, write, modify, delete

  DocumentAccess({
    required this.timestamp,
    required this.userId,
    required this.accessType,
  });
}

class DocumentLifecyclePrediction {
  final String filePath;
  final List<PredictedAction> predictedActions;
  double confidence;

  DocumentLifecyclePrediction({
    required this.filePath,
    required this.predictedActions,
    required this.confidence,
  });
}

class PredictedAction {
  final String action; // archive, review, update, delete, collaborate
  final double probability;
  final Duration timeframe;
  final String reasoning;

  PredictedAction({
    required this.action,
    required this.probability,
    required this.timeframe,
    required this.reasoning,
  });
}

class UsageAnalytics {
  final String filePath;
  final int totalAccesses;
  final int uniqueUsers;
  final double averageAccessFrequency;
  final DateTime? lastAccessed;
  final Map<String, int> accessPatterns;

  int get daysSinceLastAccess =>
    lastAccessed != null ? DateTime.now().difference(lastAccessed!).inDays : 999;

  UsageAnalytics({
    required this.filePath,
    required this.totalAccesses,
    required this.uniqueUsers,
    required this.averageAccessFrequency,
    required this.lastAccessed,
    required this.accessPatterns,
  });
}

class UsagePattern {
  final String patternType;
  final Map<int, int> hourlyDistribution;
  final Map<int, int> dailyDistribution;
  final Map<int, int> weeklyDistribution;
  final List<int> peakHours;
  final List<int> lowActivityPeriods;

  UsagePattern({
    required this.patternType,
    required this.hourlyDistribution,
    required this.dailyDistribution,
    required this.weeklyDistribution,
    required this.peakHours,
    required this.lowActivityPeriods,
  });
}

class PredictiveInsight {
  final String type;
  final String filePath;
  final String message;
  final double confidence;
  final List<String> suggestedActions;
  final DateTime timestamp;

  PredictiveInsight({
    required this.type,
    required this.filePath,
    required this.message,
    required this.confidence,
    required this.suggestedActions,
    required this.timestamp,
  });
}

class StorageRecommendation {
  final String type; // archive, delete, optimize
  final String filePath;
  final String reason;
  final double priority;
  final int estimatedSavings;

  StorageRecommendation({
    required this.type,
    required this.filePath,
    required this.reason,
    required this.priority,
    required this.estimatedSavings,
  });
}

class PredictiveModel {
  final String modelType;
  final Map<String, dynamic> parameters;
  final DateTime trainedAt;
  double accuracy = 0.0;

  PredictiveModel({
    required this.modelType,
    required this.parameters,
    required this.trainedAt,
  });
}
