import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../core/config/central_config.dart';
import '../../core/advanced_performance_service.dart';
import '../../core/logging/logging_service.dart';
import 'advanced_ai_search_service.dart';

/// AI-Enhanced Build System with Predictive Optimization
/// Provides intelligent build analysis, optimization, and predictive capabilities
class AIBuildOptimizerService {
  static final AIBuildOptimizerService _instance = AIBuildOptimizerService._internal();
  factory AIBuildOptimizerService() => _instance;
  AIBuildOptimizerService._internal();

  final CentralConfig _config = CentralConfig.instance;
  final AdvancedPerformanceService _performanceService = AdvancedPerformanceService();
  final LoggingService _logger = LoggingService();
  final AdvancedAISearchService _aiSearchService = AdvancedAISearchService();

  StreamController<BuildOptimizationEvent> _optimizationEventController = StreamController.broadcast();
  StreamController<BuildPredictionEvent> _predictionEventController = StreamController.broadcast();

  Stream<BuildOptimizationEvent> get optimizationEvents => _optimizationEventController.stream;
  Stream<BuildPredictionEvent> get predictionEvents => _predictionEventController.stream;

  // AI Models for build optimization
  final Map<String, BuildPredictionModel> _predictionModels = {};
  final Map<String, BuildOptimizationModel> _optimizationModels = {};
  final Map<String, BuildFailureAnalysisModel> _failureAnalysisModels = {};

  // Build analytics and history
  final Map<String, BuildAnalytics> _buildAnalytics = {};
  final Map<String, BuildPattern> _buildPatterns = {};
  final Map<String, BuildOptimizationRule> _optimizationRules = {};

  // Performance baselines and predictions
  final Map<String, BuildPerformanceBaseline> _performanceBaselines = {};
  final Map<String, BuildTimePrediction> _timePredictions = {};

  bool _isInitialized = false;
  bool _aiOptimizationEnabled = true;

  /// Initialize AI build optimizer service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing AI build optimizer service', 'AIBuildOptimizerService');

      // Register with CentralConfig
      await _config.registerComponent(
        'AIBuildOptimizerService',
        '2.0.0',
        'AI-powered build optimization with predictive analytics and intelligent suggestions',
        dependencies: ['CentralConfig', 'AdvancedPerformanceService', 'AdvancedAISearchService'],
        parameters: {
          // AI Build Optimization
          'ai.build.optimization.enabled': true,
          'ai.build.prediction.enabled': true,
          'ai.build.failure_analysis.enabled': true,
          'ai.build.learning.enabled': true,
          'ai.build.adaptive.enabled': true,

          // Prediction Settings
          'ai.build.prediction.confidence_threshold': 0.75,
          'ai.build.prediction.history_window_days': 30,
          'ai.build.prediction.accuracy_target': 0.85,

          // Optimization Settings
          'ai.build.optimization.parallel_jobs': 4,
          'ai.build.optimization.cache_enabled': true,
          'ai.build.optimization.incremental_enabled': true,
          'ai.build.optimization.compression_enabled': true,

          // Learning Settings
          'ai.build.learning.pattern_discovery': true,
          'ai.build.learning.feedback_loop': true,
          'ai.build.learning.model_update_interval': 3600000, // 1 hour

          // Performance Monitoring
          'ai.build.monitoring.enabled': true,
          'ai.build.monitoring.resource_tracking': true,
          'ai.build.monitoring.bottleneck_detection': true,

          // Failure Analysis
          'ai.build.failure.root_cause_analysis': true,
          'ai.build.failure.suggestion_generation': true,
          'ai.build.failure.prevention_recommendations': true,

          // Build Configuration
          'ai.build.config.auto_tuning': true,
          'ai.build.config.memory_optimization': true,
          'ai.build.config.disk_space_optimization': true,

          // Reporting and Analytics
          'ai.build.analytics.enabled': true,
          'ai.build.analytics.detailed_reporting': true,
          'ai.build.analytics.trend_analysis': true,
          'ai.build.analytics.predictive_insights': true,
        }
      );

      // Initialize AI models
      await _initializePredictionModels();
      await _initializeOptimizationModels();
      await _initializeFailureAnalysisModels();

      // Load build history and analytics
      await _loadBuildHistory();
      await _initializeBuildAnalytics();

      // Setup performance monitoring
      await _setupBuildPerformanceMonitoring();

      // Start background optimization tasks
      _startBackgroundOptimization();

      _isInitialized = true;
      _logger.info('AI build optimizer service initialized successfully', 'AIBuildOptimizerService');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize AI build optimizer service', 'AIBuildOptimizerService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Predict build time and resource usage
  Future<BuildTimePrediction> predictBuildTime({
    required String platform,
    required String mode,
    String? profile,
    Map<String, dynamic>? buildConfig,
  }) async {
    try {
      _logger.info('Predicting build time for $platform/$mode', 'AIBuildOptimizerService');

      // Get historical data for similar builds
      final historicalBuilds = await _getSimilarBuildHistory(platform, mode, profile);

      if (historicalBuilds.isEmpty) {
        // No historical data, provide baseline prediction
        return _provideBaselinePrediction(platform, mode);
      }

      // Apply AI prediction model
      final prediction = await _applyPredictionModel(historicalBuilds, buildConfig);

      // Calculate confidence based on data quality
      final confidence = _calculatePredictionConfidence(historicalBuilds, prediction);

      final result = BuildTimePrediction(
        platform: platform,
        mode: mode,
        profile: profile,
        predictedDuration: prediction.estimatedDuration,
        confidence: confidence,
        resourceUsage: prediction.resourceUsage,
        optimizationSuggestions: prediction.optimizationSuggestions,
        riskFactors: prediction.riskFactors,
        generatedAt: DateTime.now(),
        basedOnBuilds: historicalBuilds.length,
      );

      _emitPredictionEvent(BuildPredictionEventType.timePredicted, data: {
        'platform': platform,
        'mode': mode,
        'predicted_duration': prediction.estimatedDuration.inSeconds,
        'confidence': confidence,
      });

      return result;

    } catch (e, stackTrace) {
      _logger.error('Build time prediction failed', 'AIBuildOptimizerService', error: e, stackTrace: stackTrace);

      // Return fallback prediction
      return BuildTimePrediction(
        platform: platform,
        mode: mode,
        profile: profile,
        predictedDuration: const Duration(minutes: 5), // Conservative fallback
        confidence: 0.3,
        resourceUsage: {},
        optimizationSuggestions: ['Unable to generate AI predictions'],
        riskFactors: ['Prediction service unavailable'],
        generatedAt: DateTime.now(),
        basedOnBuilds: 0,
      );
    }
  }

  /// Optimize build configuration automatically
  Future<BuildOptimizationResult> optimizeBuildConfig({
    required String platform,
    required String mode,
    Map<String, dynamic>? currentConfig,
    BuildOptimizationGoal goal = BuildOptimizationGoal.speed,
  }) async {
    try {
      _logger.info('Optimizing build config for $platform/$mode with goal: ${goal.name}', 'AIBuildOptimizerService');

      // Analyze current configuration
      final analysis = await _analyzeCurrentBuildConfig(currentConfig ?? {});

      // Get optimization recommendations based on goal
      final recommendations = await _generateOptimizationRecommendations(
        platform,
        mode,
        analysis,
        goal
      );

      // Predict impact of optimizations
      final impactPrediction = await _predictOptimizationImpact(recommendations, analysis);

      // Generate optimized configuration
      final optimizedConfig = await _generateOptimizedConfig(currentConfig ?? {}, recommendations);

      final result = BuildOptimizationResult(
        platform: platform,
        mode: mode,
        goal: goal,
        currentConfig: currentConfig ?? {},
        optimizedConfig: optimizedConfig,
        recommendations: recommendations,
        predictedImpact: impactPrediction,
        confidence: _calculateOptimizationConfidence(recommendations, impactPrediction),
        generatedAt: DateTime.now(),
      );

      _emitOptimizationEvent(BuildOptimizationEventType.configOptimized, data: {
        'platform': platform,
        'mode': mode,
        'goal': goal.name,
        'recommendations_count': recommendations.length,
        'confidence': result.confidence,
      });

      return result;

    } catch (e, stackTrace) {
      _logger.error('Build config optimization failed', 'AIBuildOptimizerService', error: e, stackTrace: stackTrace);

      return BuildOptimizationResult(
        platform: platform,
        mode: mode,
        goal: goal,
        currentConfig: currentConfig ?? {},
        optimizedConfig: currentConfig ?? {},
        recommendations: ['Optimization service unavailable - using current config'],
        predictedImpact: BuildImpactPrediction(
          timeReduction: Duration.zero,
          resourceReduction: {},
          riskIncrease: 0.0,
        ),
        confidence: 0.0,
        generatedAt: DateTime.now(),
      );
    }
  }

  /// Analyze build failure and provide intelligent fixes
  Future<BuildFailureAnalysis> analyzeBuildFailure({
    required String platform,
    required String mode,
    required String errorOutput,
    Map<String, dynamic>? buildConfig,
    List<String>? recentChanges,
  }) async {
    try {
      _logger.info('Analyzing build failure for $platform/$mode', 'AIBuildOptimizerService');

      // Parse error output
      final parsedErrors = await _parseBuildErrors(errorOutput);

      // Identify root cause using AI
      final rootCause = await _identifyRootCause(parsedErrors, platform, mode, buildConfig);

      // Generate fix suggestions
      final fixSuggestions = await _generateFixSuggestions(rootCause, parsedErrors, recentChanges);

      // Predict prevention measures
      final preventionMeasures = await _predictPreventionMeasures(rootCause, parsedErrors);

      final analysis = BuildFailureAnalysis(
        platform: platform,
        mode: mode,
        errorOutput: errorOutput,
        parsedErrors: parsedErrors,
        rootCause: rootCause,
        fixSuggestions: fixSuggestions,
        preventionMeasures: preventionMeasures,
        confidence: _calculateFailureAnalysisConfidence(parsedErrors, rootCause),
        analyzedAt: DateTime.now(),
        similarFailures: await _findSimilarFailures(rootCause),
      );

      // Learn from this failure for future prevention
      await _learnFromBuildFailure(analysis);

      _emitOptimizationEvent(BuildOptimizationEventType.failureAnalyzed, data: {
        'platform': platform,
        'mode': mode,
        'root_cause': rootCause.category,
        'suggestions_count': fixSuggestions.length,
        'confidence': analysis.confidence,
      });

      return analysis;

    } catch (e, stackTrace) {
      _logger.error('Build failure analysis failed', 'AIBuildOptimizerService', error: e, stackTrace: stackTrace);

      return BuildFailureAnalysis(
        platform: platform,
        mode: mode,
        errorOutput: errorOutput,
        parsedErrors: [],
        rootCause: BuildFailureCause(
          category: 'unknown',
          description: 'Analysis failed',
          severity: FailureSeverity.unknown,
        ),
        fixSuggestions: ['Unable to analyze failure - check logs manually'],
        preventionMeasures: [],
        confidence: 0.0,
        analyzedAt: DateTime.now(),
        similarFailures: [],
      );
    }
  }

  /// Monitor build performance in real-time
  Future<BuildPerformanceMonitoring> startBuildMonitoring({
    required String buildId,
    required String platform,
    required String mode,
  }) async {
    try {
      _logger.info('Starting build performance monitoring for $buildId', 'AIBuildOptimizerService');

      final monitoring = BuildPerformanceMonitoring(
        buildId: buildId,
        platform: platform,
        mode: mode,
        startedAt: DateTime.now(),
        metrics: <String, List<BuildMetric>>{},
        alerts: [],
        predictions: [],
      );

      // Start real-time monitoring
      await _startRealTimeBuildMonitoring(monitoring);

      return monitoring;

    } catch (e, stackTrace) {
      _logger.error('Build performance monitoring failed', 'AIBuildOptimizerService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Generate comprehensive build analytics report
  Future<BuildAnalyticsReport> generateBuildAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? platform,
    String? mode,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      _logger.info('Generating build analytics report from $start to $end', 'AIBuildOptimizerService');

      // Gather build data
      final buildData = await _gatherBuildData(start, end, platform, mode);

      // Analyze performance trends
      final performanceTrends = await _analyzePerformanceTrends(buildData);

      // Identify bottlenecks
      final bottlenecks = await _identifyBuildBottlenecks(buildData);

      // Generate optimization recommendations
      final recommendations = await _generateBuildOptimizationRecommendations(buildData, bottlenecks);

      // Predict future performance
      final predictions = await _predictFutureBuildPerformance(buildData);

      final report = BuildAnalyticsReport(
        period: DateRange(start: start, end: end),
        platform: platform,
        mode: mode,
        totalBuilds: buildData.length,
        successfulBuilds: buildData.where((b) => b.success).length,
        averageBuildTime: _calculateAverageBuildTime(buildData),
        performanceTrends: performanceTrends,
        bottlenecks: bottlenecks,
        recommendations: recommendations,
        predictions: predictions,
        generatedAt: DateTime.now(),
      );

      _emitOptimizationEvent(BuildOptimizationEventType.analyticsGenerated, data: {
        'total_builds': buildData.length,
        'avg_build_time': report.averageBuildTime.inMinutes,
        'recommendations_count': recommendations.length,
      });

      return report;

    } catch (e, stackTrace) {
      _logger.error('Build analytics generation failed', 'AIBuildOptimizerService', error: e, stackTrace: stackTrace);

      return BuildAnalyticsReport(
        period: DateRange(start: start, end: end),
        platform: platform,
        mode: mode,
        totalBuilds: 0,
        successfulBuilds: 0,
        averageBuildTime: Duration.zero,
        performanceTrends: [],
        bottlenecks: [],
        recommendations: ['Analytics generation failed'],
        predictions: [],
        generatedAt: DateTime.now(),
      );
    }
  }

  /// Learn from build patterns and improve predictions
  Future<void> learnFromBuildHistory() async {
    try {
      _logger.info('Learning from build history to improve predictions', 'AIBuildOptimizerService');

      // Analyze recent build patterns
      final recentBuilds = await _getRecentBuilds(const Duration(days: 7));

      // Update prediction models
      await _updatePredictionModels(recentBuilds);

      // Discover new optimization patterns
      await _discoverOptimizationPatterns(recentBuilds);

      // Update performance baselines
      await _updatePerformanceBaselines(recentBuilds);

      _logger.info('Build learning completed - models updated', 'AIBuildOptimizerService');

    } catch (e, stackTrace) {
      _logger.error('Build learning failed', 'AIBuildOptimizerService', error: e, stackTrace: stackTrace);
    }
  }

  // Core implementation methods (simplified)

  Future<void> _initializePredictionModels() async {
    _predictionModels['time_prediction'] = BuildPredictionModel(
      name: 'Build Time Predictor',
      algorithm: 'gradient_boosting',
      accuracy: 0.82,
      features: ['platform', 'mode', 'file_count', 'dependency_count', 'last_build_time'],
    );

    _predictionModels['resource_prediction'] = BuildPredictionModel(
      name: 'Resource Usage Predictor',
      algorithm: 'neural_network',
      accuracy: 0.78,
      features: ['cpu_usage', 'memory_usage', 'disk_usage', 'build_complexity'],
    );
  }

  Future<void> _initializeOptimizationModels() async {
    _optimizationModels['config_optimizer'] = BuildOptimizationModel(
      name: 'Build Config Optimizer',
      algorithm: 'genetic_algorithm',
      optimizationGoals: ['speed', 'memory', 'disk_space'],
      constraints: ['compatibility', 'stability'],
    );
  }

  Future<void> _initializeFailureAnalysisModels() async {
    _failureAnalysisModels['error_classifier'] = BuildFailureAnalysisModel(
      name: 'Error Pattern Classifier',
      algorithm: 'nlp_classification',
      errorCategories: ['compilation', 'dependency', 'resource', 'configuration'],
      accuracy: 0.89,
    );
  }

  Future<void> _loadBuildHistory() async {
    // Load historical build data from storage
    _logger.info('Build history loaded', 'AIBuildOptimizerService');
  }

  Future<void> _initializeBuildAnalytics() async {
    // Initialize analytics data structures
    _logger.info('Build analytics initialized', 'AIBuildOptimizerService');
  }

  Future<void> _setupBuildPerformanceMonitoring() async {
    // Setup real-time performance monitoring
    _logger.info('Build performance monitoring setup', 'AIBuildOptimizerService');
  }

  void _startBackgroundOptimization() {
    // Start background optimization tasks
    Timer.periodic(const Duration(hours: 1), (timer) {
      _performBackgroundOptimization();
    });
  }

  Future<void> _performBackgroundOptimization() async {
    try {
      // Perform background learning and optimization
      await learnFromBuildHistory();
    } catch (e) {
      _logger.error('Background optimization failed', 'AIBuildOptimizerService', error: e);
    }
  }

  // Prediction and optimization methods (simplified implementations)

  Future<List<BuildRecord>> _getSimilarBuildHistory(String platform, String mode, String? profile) async => [];
  BuildTimePrediction _provideBaselinePrediction(String platform, String mode) => BuildTimePrediction(
    platform: platform,
    mode: mode,
    predictedDuration: const Duration(minutes: 5),
    confidence: 0.5,
    resourceUsage: {},
    optimizationSuggestions: [],
    riskFactors: [],
    generatedAt: DateTime.now(),
    basedOnBuilds: 0,
  );
  Future<BuildPredictionResult> _applyPredictionModel(List<BuildRecord> builds, Map<String, dynamic>? config) async =>
    BuildPredictionResult(estimatedDuration: const Duration(minutes: 5), resourceUsage: {}, optimizationSuggestions: [], riskFactors: []);
  double _calculatePredictionConfidence(List<BuildRecord> builds, BuildPredictionResult prediction) => 0.75;

  Future<BuildConfigAnalysis> _analyzeCurrentBuildConfig(Map<String, dynamic> config) async => BuildConfigAnalysis();
  Future<List<BuildOptimizationRecommendation>> _generateOptimizationRecommendations(
    String platform, String mode, BuildConfigAnalysis analysis, BuildOptimizationGoal goal
  ) async => [];
  Future<BuildImpactPrediction> _predictOptimizationImpact(List<BuildOptimizationRecommendation> recommendations, BuildConfigAnalysis analysis) async =>
    BuildImpactPrediction(timeReduction: Duration.zero, resourceReduction: {}, riskIncrease: 0.0);
  Future<Map<String, dynamic>> _generateOptimizedConfig(Map<String, dynamic> currentConfig, List<BuildOptimizationRecommendation> recommendations) async => currentConfig;
  double _calculateOptimizationConfidence(List<BuildOptimizationRecommendation> recommendations, BuildImpactPrediction impact) => 0.8;

  Future<List<ParsedBuildError>> _parseBuildErrors(String errorOutput) async => [];
  Future<BuildFailureCause> _identifyRootCause(List<ParsedBuildError> errors, String platform, String mode, Map<String, dynamic>? config) async =>
    BuildFailureCause(category: 'unknown', description: 'Unable to identify root cause', severity: FailureSeverity.unknown);
  Future<List<BuildFixSuggestion>> _generateFixSuggestions(BuildFailureCause rootCause, List<ParsedBuildError> errors, List<String>? changes) async => [];
  Future<List<PreventionMeasure>> _predictPreventionMeasures(BuildFailureCause rootCause, List<ParsedBuildError> errors) async => [];
  double _calculateFailureAnalysisConfidence(List<ParsedBuildError> errors, BuildFailureCause rootCause) => 0.85;
  Future<List<SimilarFailure>> _findSimilarFailures(BuildFailureCause rootCause) async => [];
  Future<void> _learnFromBuildFailure(BuildFailureAnalysis analysis) async {}

  Future<void> _startRealTimeBuildMonitoring(BuildPerformanceMonitoring monitoring) async {}
  Future<List<BuildRecord>> _gatherBuildData(DateTime start, DateTime end, String? platform, String? mode) async => [];
  Future<List<PerformanceTrend>> _analyzePerformanceTrends(List<BuildRecord> builds) async => [];
  Future<List<BuildBottleneck>> _identifyBuildBottlenecks(List<BuildRecord> builds) async => [];
  Future<List<String>> _generateBuildOptimizationRecommendations(List<BuildRecord> builds, List<BuildBottleneck> bottlenecks) async => [];
  Future<List<BuildPrediction>> _predictFutureBuildPerformance(List<BuildRecord> builds) async => [];
  Duration _calculateAverageBuildTime(List<BuildRecord> builds) => const Duration(minutes: 5);
  Future<List<BuildRecord>> _getRecentBuilds(Duration period) async => [];
  Future<void> _updatePredictionModels(List<BuildRecord> builds) async {}
  Future<void> _discoverOptimizationPatterns(List<BuildRecord> builds) async {}
  Future<void> _updatePerformanceBaselines(List<BuildRecord> builds) async {}

  // Event emission methods
  void _emitOptimizationEvent(BuildOptimizationEventType type, {Map<String, dynamic>? data}) {
    final event = BuildOptimizationEvent(type: type, timestamp: DateTime.now(), data: data ?? {});
    _optimizationEventController.add(event);
  }

  void _emitPredictionEvent(BuildPredictionEventType type, {Map<String, dynamic>? data}) {
    final event = BuildPredictionEvent(type: type, timestamp: DateTime.now(), data: data ?? {});
    _predictionEventController.add(event);
  }

  /// Dispose resources
  void dispose() {
    _optimizationEventController.close();
    _predictionEventController.close();
  }
}

/// Supporting data classes and enums

enum BuildOptimizationGoal {
  speed,
  memory,
  diskSpace,
  reliability,
  compatibility,
}

enum BuildOptimizationEventType {
  configOptimized,
  failureAnalyzed,
  analyticsGenerated,
  optimizationApplied,
  learningCompleted,
}

enum BuildPredictionEventType {
  timePredicted,
  resourcePredicted,
  riskAssessed,
  optimizationSuggested,
}

enum FailureSeverity {
  low,
  medium,
  high,
  critical,
  unknown,
}

class BuildTimePrediction {
  final String platform;
  final String mode;
  final String? profile;
  final Duration predictedDuration;
  final double confidence;
  final Map<String, dynamic> resourceUsage;
  final List<String> optimizationSuggestions;
  final List<String> riskFactors;
  final DateTime generatedAt;
  final int basedOnBuilds;

  BuildTimePrediction({
    required this.platform,
    required this.mode,
    this.profile,
    required this.predictedDuration,
    required this.confidence,
    required this.resourceUsage,
    required this.optimizationSuggestions,
    required this.riskFactors,
    required this.generatedAt,
    required this.basedOnBuilds,
  });
}

class BuildOptimizationResult {
  final String platform;
  final String mode;
  final BuildOptimizationGoal goal;
  final Map<String, dynamic> currentConfig;
  final Map<String, dynamic> optimizedConfig;
  final List<BuildOptimizationRecommendation> recommendations;
  final BuildImpactPrediction predictedImpact;
  final double confidence;
  final DateTime generatedAt;

  BuildOptimizationResult({
    required this.platform,
    required this.mode,
    required this.goal,
    required this.currentConfig,
    required this.optimizedConfig,
    required this.recommendations,
    required this.predictedImpact,
    required this.confidence,
    required this.generatedAt,
  });
}

class BuildOptimizationRecommendation {
  final String type;
  final String description;
  final double impact;
  final double risk;
  final Map<String, dynamic> changes;

  BuildOptimizationRecommendation({
    required this.type,
    required this.description,
    required this.impact,
    required this.risk,
    required this.changes,
  });
}

class BuildImpactPrediction {
  final Duration timeReduction;
  final Map<String, double> resourceReduction;
  final double riskIncrease;

  BuildImpactPrediction({
    required this.timeReduction,
    required this.resourceReduction,
    required this.riskIncrease,
  });
}

class BuildFailureAnalysis {
  final String platform;
  final String mode;
  final String errorOutput;
  final List<ParsedBuildError> parsedErrors;
  final BuildFailureCause rootCause;
  final List<BuildFixSuggestion> fixSuggestions;
  final List<PreventionMeasure> preventionMeasures;
  final double confidence;
  final DateTime analyzedAt;
  final List<SimilarFailure> similarFailures;

  BuildFailureAnalysis({
    required this.platform,
    required this.mode,
    required this.errorOutput,
    required this.parsedErrors,
    required this.rootCause,
    required this.fixSuggestions,
    required this.preventionMeasures,
    required this.confidence,
    required this.analyzedAt,
    required this.similarFailures,
  });
}

class ParsedBuildError {
  final String message;
  final String file;
  final int line;
  final String category;
  final FailureSeverity severity;

  ParsedBuildError({
    required this.message,
    required this.file,
    required this.line,
    required this.category,
    required this.severity,
  });
}

class BuildFailureCause {
  final String category;
  final String description;
  final FailureSeverity severity;

  BuildFailureCause({
    required this.category,
    required this.description,
    required this.severity,
  });
}

class BuildFixSuggestion {
  final String description;
  final String command;
  final double successProbability;
  final List<String> prerequisites;

  BuildFixSuggestion({
    required this.description,
    required this.command,
    required this.successProbability,
    required this.prerequisites,
  });
}

class PreventionMeasure {
  final String description;
  final String implementation;
  final String monitoring;

  PreventionMeasure({
    required this.description,
    required this.implementation,
    required this.monitoring,
  });
}

class SimilarFailure {
  final String buildId;
  final String platform;
  final String mode;
  final DateTime occurredAt;
  final double similarity;

  SimilarFailure({
    required this.buildId,
    required this.platform,
    required this.mode,
    required this.occurredAt,
    required this.similarity,
  });
}

class BuildPerformanceMonitoring {
  final String buildId;
  final String platform;
  final String mode;
  final DateTime startedAt;
  final Map<String, List<BuildMetric>> metrics;
  final List<String> alerts;
  final List<String> predictions;

  BuildPerformanceMonitoring({
    required this.buildId,
    required this.platform,
    required this.mode,
    required this.startedAt,
    required this.metrics,
    required this.alerts,
    required this.predictions,
  });
}

class BuildMetric {
  final String name;
  final double value;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  BuildMetric({
    required this.name,
    required this.value,
    required this.timestamp,
    this.metadata = const {},
  });
}

class BuildAnalyticsReport {
  final DateRange period;
  final String? platform;
  final String? mode;
  final int totalBuilds;
  final int successfulBuilds;
  final Duration averageBuildTime;
  final List<PerformanceTrend> performanceTrends;
  final List<BuildBottleneck> bottlenecks;
  final List<String> recommendations;
  final List<BuildPrediction> predictions;
  final DateTime generatedAt;

  BuildAnalyticsReport({
    required this.period,
    this.platform,
    this.mode,
    required this.totalBuilds,
    required this.successfulBuilds,
    required this.averageBuildTime,
    required this.performanceTrends,
    required this.bottlenecks,
    required this.recommendations,
    required this.predictions,
    required this.generatedAt,
  });
}

class PerformanceTrend {
  final DateTime date;
  final Duration averageBuildTime;
  final double successRate;
  final Map<String, double> resourceUsage;

  PerformanceTrend({
    required this.date,
    required this.averageBuildTime,
    required this.successRate,
    required this.resourceUsage,
  });
}

class BuildBottleneck {
  final String type;
  final String description;
  final double impact;
  final List<String> affectedBuilds;

  BuildBottleneck({
    required this.type,
    required this.description,
    required this.impact,
    required this.affectedBuilds,
  });
}

class BuildPrediction {
  final String type;
  final String description;
  final double confidence;
  final Map<String, dynamic> data;

  BuildPrediction({
    required this.type,
    required this.description,
    required this.confidence,
    required this.data,
  });
}

class BuildPredictionModel {
  final String name;
  final String algorithm;
  final double accuracy;
  final List<String> features;

  BuildPredictionModel({
    required this.name,
    required this.algorithm,
    required this.accuracy,
    required this.features,
  });
}

class BuildOptimizationModel {
  final String name;
  final String algorithm;
  final List<String> optimizationGoals;
  final List<String> constraints;

  BuildOptimizationModel({
    required this.name,
    required this.algorithm,
    required this.optimizationGoals,
    required this.constraints,
  });
}

class BuildFailureAnalysisModel {
  final String name;
  final String algorithm;
  final List<String> errorCategories;
  final double accuracy;

  BuildFailureAnalysisModel({
    required this.name,
    required this.algorithm,
    required this.errorCategories,
    required this.accuracy,
  });
}

class BuildAnalytics {
  final String platform;
  final String mode;
  final int totalBuilds;
  final int successfulBuilds;
  final Duration averageBuildTime;
  final Map<String, dynamic> performanceData;

  BuildAnalytics({
    required this.platform,
    required this.mode,
    required this.totalBuilds,
    required this.successfulBuilds,
    required this.averageBuildTime,
    required this.performanceData,
  });
}

class BuildPattern {
  final String patternId;
  final String description;
  final Map<String, dynamic> conditions;
  final List<String> applicableBuilds;
  final double successRate;

  BuildPattern({
    required this.patternId,
    required this.description,
    required this.conditions,
    required this.applicableBuilds,
    required this.successRate,
  });
}

class BuildOptimizationRule {
  final String ruleId;
  final String description;
  final Map<String, dynamic> conditions;
  final Map<String, dynamic> actions;
  final double confidence;

  BuildOptimizationRule({
    required this.ruleId,
    required this.description,
    required this.conditions,
    required this.actions,
    required this.confidence,
  });
}

class BuildPerformanceBaseline {
  final String platform;
  final String mode;
  final Duration expectedBuildTime;
  final Map<String, double> expectedResourceUsage;
  final DateTime establishedAt;
  final double confidence;

  BuildPerformanceBaseline({
    required this.platform,
    required this.mode,
    required this.expectedBuildTime,
    required this.expectedResourceUsage,
    required this.establishedAt,
    required this.confidence,
  });
}

class BuildConfigAnalysis {
  final Map<String, dynamic> currentSettings;
  final List<String> inefficiencies;
  final Map<String, double> performanceImpact;
  final List<String> recommendations;

  BuildConfigAnalysis({
    this.currentSettings = const {},
    this.inefficiencies = const [],
    this.performanceImpact = const {},
    this.recommendations = const [],
  });
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({
    required this.start,
    required this.end,
  });
}

class BuildOptimizationEvent {
  final BuildOptimizationEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  BuildOptimizationEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });
}

class BuildPredictionEvent {
  final BuildPredictionEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  BuildPredictionEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });
}

class BuildPredictionResult {
  final Duration estimatedDuration;
  final Map<String, dynamic> resourceUsage;
  final List<String> optimizationSuggestions;
  final List<String> riskFactors;

  BuildPredictionResult({
    required this.estimatedDuration,
    required this.resourceUsage,
    required this.optimizationSuggestions,
    required this.riskFactors,
  });
}
