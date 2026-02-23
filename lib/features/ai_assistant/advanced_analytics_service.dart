import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'ai_file_analysis_service.dart';
import 'performance_optimization_service.dart';
import '../../core/config/central_config.dart';

/// Advanced Analytics and Business Intelligence Service
/// Provides comprehensive analytics, reporting, and business intelligence features
class AdvancedAnalyticsService {
  static final AdvancedAnalyticsService _instance = AdvancedAnalyticsService._internal();
  factory AdvancedAnalyticsService() => _instance;
  AdvancedAnalyticsService._internal();

  final AIFileAnalysisService _fileAnalysisService = AIFileAnalysisService.instance;
  final PerformanceOptimizationService _performanceService = PerformanceOptimizationService();
  final CentralConfig _config = CentralConfig.instance;
  final StreamController<AnalyticsEvent> _analyticsEventController = StreamController.broadcast();

  Stream<AnalyticsEvent> get analyticsEvents => _analyticsEventController.stream;

  // Analytics data structures
  final Map<String, AnalyticsDashboard> _dashboards = {};
  final Map<String, AnalyticsMetric> _metrics = {};
  final Map<String, AnalyticsReport> _reports = {};
  final Map<String, UserBehaviorProfile> _userProfiles = {};
  final Map<String, PredictiveModel> _predictiveModels = {};

  // Data collection
  final Map<String, DataCollector> _dataCollectors = {};
  final Queue<AnalyticsEventData> _eventQueue = Queue();
  final Map<String, DataAggregation> _aggregations = {};

  bool _isInitialized = false;

  // Configuration
  static const Duration _collectionInterval = Duration(minutes: 5);
  static const Duration _aggregationInterval = Duration(hours: 1);
  static const int _maxEventQueueSize = 10000;
  static const int _maxHistoricalDataDays = 90;

  Timer? _collectionTimer;
  Timer? _aggregationTimer;

  /// Initialize advanced analytics service
  Future<void> initialize({
    List<AnalyticsMetric>? customMetrics,
    List<AnalyticsDashboard>? dashboards,
    Map<String, PredictiveModel>? models,
  }) async {
    if (_isInitialized) return;

    try {
      // Register with CentralConfig
      await _config.registerComponent(
        'AdvancedAnalyticsService',
        '1.0.0',
        'Advanced analytics and business intelligence with predictive modeling',
        dependencies: ['AIFileAnalysisService', 'PerformanceOptimizationService'],
        parameters: {
          'collection_interval': 300000, // 5 minutes in ms
          'aggregation_interval': 3600000, // 1 hour in ms
          'max_event_queue_size': 10000,
          'max_historical_data_days': 90,
          'confidence_threshold': 0.7,
          'dashboard_refresh_interval': 30000, // 30 seconds
          'report_generation_timeout': 300000, // 5 minutes
          'predictive_model_update_interval': 86400000, // 24 hours
          'analytics_cache_size': 1000,
        }
      );

      // Register component relationships
      await _config.registerComponentRelationship(
        'AdvancedAnalyticsService',
        'AIFileAnalysisService',
        RelationshipType.depends_on,
        'Uses AI analysis for intelligent analytics and predictions',
      );

      await _config.registerComponentRelationship(
        'AdvancedAnalyticsService',
        'PerformanceOptimizationService',
        RelationshipType.depends_on,
        'Uses performance optimization for analytics processing',
      );

      await _config.registerComponentRelationship(
        'AdvancedAnalyticsService',
        'MonitoringObservabilityService',
        RelationshipType.uses,
        'Integrates with monitoring for comprehensive analytics data',
      );

      // Initialize core metrics
      await _initializeCoreMetrics();

      // Add custom metrics
      if (customMetrics != null) {
        for (final metric in customMetrics) {
          _metrics[metric.metricId] = metric;
        }
      }

      // Initialize dashboards
      if (dashboards != null) {
        for (final dashboard in dashboards) {
          _dashboards[dashboard.dashboardId] = dashboard;
        }
      } else {
        await _initializeDefaultDashboards();
      }

      // Load predictive models
      if (models != null) {
        _predictiveModels.addAll(models);
      } else {
        await _initializeDefaultModels();
      }

      // Start data collection
      _startDataCollection();

      // Start periodic aggregation
      _startDataAggregation();

      _isInitialized = true;
      _emitAnalyticsEvent(AnalyticsEventType.serviceInitialized);

    } catch (e) {
      _emitAnalyticsEvent(AnalyticsEventType.initializationFailed, error: e.toString());
      rethrow;
    }
  }

  /// Track user interaction event
  Future<void> trackEvent({
    required String eventName,
    required String userId,
    Map<String, dynamic>? properties,
    String? sessionId,
    String? screenName,
    DateTime? timestamp,
  }) async {
    final event = AnalyticsEventData(
      eventId: _generateEventId(),
      eventName: eventName,
      userId: userId,
      properties: properties ?? {},
      sessionId: sessionId,
      screenName: screenName,
      timestamp: timestamp ?? DateTime.now(),
    );

    // Add to queue
    _eventQueue.add(event);

    // Maintain queue size
    while (_eventQueue.length > _maxEventQueueSize) {
      _eventQueue.removeFirst();
    }

    // Update user profile
    await _updateUserProfile(event);

    _emitAnalyticsEvent(AnalyticsEventType.eventTracked,
      details: 'Event: $eventName, User: $userId');
  }

  /// Get analytics dashboard data
  Future<DashboardData> getDashboardData({
    required String dashboardId,
    DateTimeRange? dateRange,
    List<String>? filters,
    int? limit,
  }) async {
    final dashboard = _dashboards[dashboardId];
    if (dashboard == null) {
      throw AnalyticsException('Dashboard not found: $dashboardId');
    }

    final range = dateRange ?? DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );

    _emitAnalyticsEvent(AnalyticsEventType.dashboardDataRequested,
      details: 'Dashboard: $dashboardId');

    try {
      final data = <String, MetricData>{};

      for (final widget in dashboard.widgets) {
        final metricData = await _getMetricData(
          widget.metricId,
          range,
          filters,
          limit,
        );
        data[widget.widgetId] = metricData;
      }

      final dashboardData = DashboardData(
        dashboardId: dashboardId,
        data: data,
        dateRange: range,
        generatedAt: DateTime.now(),
      );

      _emitAnalyticsEvent(AnalyticsEventType.dashboardDataGenerated,
        details: 'Dashboard: $dashboardId, Widgets: ${data.length}');

      return dashboardData;

    } catch (e) {
      _emitAnalyticsEvent(AnalyticsEventType.dashboardDataFailed, error: e.toString());
      rethrow;
    }
  }

  /// Generate custom analytics report
  Future<AnalyticsReport> generateReport({
    required String reportId,
    required String title,
    required List<String> metricIds,
    required DateTimeRange dateRange,
    List<String>? filters,
    ReportFormat format = ReportFormat.json,
    String? description,
  }) async {
    _emitAnalyticsEvent(AnalyticsEventType.reportGenerationStarted,
      details: 'Report: $reportId');

    try {
      final reportData = <String, MetricData>{};

      for (final metricId in metricIds) {
        final data = await _getMetricData(metricId, dateRange, filters);
        reportData[metricId] = data;
      }

      final insights = await _generateReportInsights(reportData);
      final trends = await _analyzeTrends(reportData, dateRange);

      final report = AnalyticsReport(
        reportId: reportId,
        title: title,
        description: description,
        data: reportData,
        insights: insights,
        trends: trends,
        dateRange: dateRange,
        generatedAt: DateTime.now(),
        format: format,
      );

      _reports[reportId] = report;

      _emitAnalyticsEvent(AnalyticsEventType.reportGenerationCompleted,
        details: 'Report: $reportId, Metrics: ${metricIds.length}');

      return report;

    } catch (e) {
      _emitAnalyticsEvent(AnalyticsEventType.reportGenerationFailed, error: e.toString());
      rethrow;
    }
  }

  /// Get user behavior analytics
  Future<UserBehaviorAnalytics> getUserBehaviorAnalytics({
    required String userId,
    DateTimeRange? dateRange,
    int? maxEvents,
  }) async {
    final profile = _userProfiles[userId];
    if (profile == null) {
      return UserBehaviorAnalytics.empty(userId);
    }

    final range = dateRange ?? DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );

    final events = profile.events
        .where((event) => event.timestamp.isAfter(range.start) &&
                         event.timestamp.isBefore(range.end))
        .take(maxEvents ?? 1000)
        .toList();

    final patterns = await _analyzeBehaviorPatterns(events);
    final preferences = await _extractUserPreferences(events);
    final engagement = await _calculateEngagementScore(events);

    return UserBehaviorAnalytics(
      userId: userId,
      totalEvents: events.length,
      patterns: patterns,
      preferences: preferences,
      engagementScore: engagement,
      dateRange: range,
      analyzedAt: DateTime.now(),
    );
  }

  /// Run predictive analytics
  Future<PredictiveAnalyticsResult> runPredictiveAnalytics({
    required String modelId,
    required Map<String, dynamic> inputData,
    int? predictionHorizon,
  }) async {
    final model = _predictiveModels[modelId];
    if (model == null) {
      throw AnalyticsException('Predictive model not found: $modelId');
    }

    _emitAnalyticsEvent(AnalyticsEventType.predictiveAnalysisStarted,
      details: 'Model: $modelId');

    try {
      final prediction = await model.predict(inputData);
      final confidence = await _calculatePredictionConfidence(model, inputData);

      final result = PredictiveAnalyticsResult(
        modelId: modelId,
        prediction: prediction,
        confidence: confidence,
        inputData: inputData,
        predictionHorizon: predictionHorizon,
        generatedAt: DateTime.now(),
      );

      _emitAnalyticsEvent(AnalyticsEventType.predictiveAnalysisCompleted,
        details: 'Model: $modelId, Confidence: ${(confidence * 100).round()}%');

      return result;

    } catch (e) {
      _emitAnalyticsEvent(AnalyticsEventType.predictiveAnalysisFailed, error: e.toString());
      rethrow;
    }
  }

  /// Create custom analytics dashboard
  Future<AnalyticsDashboard> createDashboard({
    required String dashboardId,
    required String title,
    required List<DashboardWidget> widgets,
    String? description,
    List<String>? tags,
  }) async {
    final dashboard = AnalyticsDashboard(
      dashboardId: dashboardId,
      title: title,
      description: description,
      widgets: widgets,
      tags: tags ?? [],
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );

    _dashboards[dashboardId] = dashboard;

    _emitAnalyticsEvent(AnalyticsEventType.dashboardCreated,
      details: 'Dashboard: $dashboardId, Widgets: ${widgets.length}');

    return dashboard;
  }

  /// Get business intelligence insights
  Future<BusinessIntelligenceInsights> getBusinessIntelligenceInsights({
    DateTimeRange? dateRange,
    List<String>? focusAreas,
  }) async {
    final range = dateRange ?? DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );

    _emitAnalyticsEvent(AnalyticsEventType.biInsightsRequested);

    try {
      final userInsights = await _analyzeUserInsights(range);
      final performanceInsights = await _analyzePerformanceInsights(range);
      final featureInsights = await _analyzeFeatureInsights(range, focusAreas);
      final predictiveInsights = await _generatePredictiveInsights(range);

      final insights = BusinessIntelligenceInsights(
        userInsights: userInsights,
        performanceInsights: performanceInsights,
        featureInsights: featureInsights,
        predictiveInsights: predictiveInsights,
        dateRange: range,
        generatedAt: DateTime.now(),
      );

      _emitAnalyticsEvent(AnalyticsEventType.biInsightsGenerated,
        details: 'Insights generated for ${range.duration.inDays} days');

      return insights;

    } catch (e) {
      _emitAnalyticsEvent(AnalyticsEventType.biInsightsFailed, error: e.toString());
      rethrow;
    }
  }

  /// Export analytics data
  Future<String> exportAnalyticsData({
    DateTimeRange? dateRange,
    bool includeEvents = true,
    bool includeMetrics = true,
    bool includeReports = false,
    ExportFormat format = ExportFormat.json,
  }) async {
    final range = dateRange ?? DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );

    final data = <String, dynamic>{};

    if (includeEvents) {
      final events = _eventQueue.where((event) =>
        event.timestamp.isAfter(range.start) &&
        event.timestamp.isBefore(range.end)
      ).toList();
      data['events'] = events.map((e) => e.toJson()).toList();
    }

    if (includeMetrics) {
      final metrics = <String, dynamic>{};
      for (final metric in _metrics.values) {
        final metricData = await _getMetricData(metric.metricId, range);
        metrics[metric.metricId] = metricData.toJson();
      }
      data['metrics'] = metrics;
    }

    if (includeReports) {
      data['reports'] = _reports.map((key, value) => MapEntry(key, value.toJson()));
    }

    data['exportRange'] = {
      'start': range.start.toIso8601String(),
      'end': range.end.toIso8601String(),
    };
    data['exportedAt'] = DateTime.now().toIso8601String();

    switch (format) {
      case ExportFormat.json:
        return json.encode(data);
      case ExportFormat.csv:
        return _convertToCSV(data);
      default:
        return json.encode(data);
    }
  }

  // Private methods

  Future<void> _initializeCoreMetrics() async {
    _metrics['user_sessions'] = AnalyticsMetric(
      metricId: 'user_sessions',
      name: 'User Sessions',
      description: 'Number of user sessions',
      type: MetricType.counter,
      unit: 'sessions',
    );

    _metrics['file_operations'] = AnalyticsMetric(
      metricId: 'file_operations',
      name: 'File Operations',
      description: 'Number of file operations performed',
      type: MetricType.counter,
      unit: 'operations',
    );

    _metrics['app_performance'] = AnalyticsMetric(
      metricId: 'app_performance',
      name: 'App Performance',
      description: 'Application performance metrics',
      type: MetricType.gauge,
      unit: 'ms',
    );

    _metrics['user_engagement'] = AnalyticsMetric(
      metricId: 'user_engagement',
      name: 'User Engagement',
      description: 'User engagement score',
      type: MetricType.gauge,
      unit: 'score',
    );

    _metrics['feature_usage'] = AnalyticsMetric(
      metricId: 'feature_usage',
      name: 'Feature Usage',
      description: 'Usage statistics for app features',
      type: MetricType.histogram,
      unit: 'uses',
    );
  }

  Future<void> _initializeDefaultDashboards() async {
    _dashboards['overview'] = AnalyticsDashboard(
      dashboardId: 'overview',
      title: 'Analytics Overview',
      description: 'General application analytics overview',
      widgets: [
        DashboardWidget(
          widgetId: 'user_sessions_chart',
          title: 'User Sessions',
          type: WidgetType.lineChart,
          metricId: 'user_sessions',
          size: WidgetSize.medium,
        ),
        DashboardWidget(
          widgetId: 'performance_gauge',
          title: 'Performance',
          type: WidgetType.gauge,
          metricId: 'app_performance',
          size: WidgetSize.small,
        ),
        DashboardWidget(
          widgetId: 'engagement_score',
          title: 'User Engagement',
          type: WidgetType.number,
          metricId: 'user_engagement',
          size: WidgetSize.small,
        ),
      ],
      tags: ['overview', 'general'],
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );

    _dashboards['performance'] = AnalyticsDashboard(
      dashboardId: 'performance',
      title: 'Performance Analytics',
      description: 'Detailed performance metrics and trends',
      widgets: [
        DashboardWidget(
          widgetId: 'response_times',
          title: 'Response Times',
          type: WidgetType.histogram,
          metricId: 'app_performance',
          size: WidgetSize.large,
        ),
        DashboardWidget(
          widgetId: 'error_rate',
          title: 'Error Rate',
          type: WidgetType.lineChart,
          metricId: 'error_rate',
          size: WidgetSize.medium,
        ),
      ],
      tags: ['performance', 'technical'],
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );
  }

  Future<void> _initializeDefaultModels() async {
    _predictiveModels['user_churn'] = PredictiveModel(
      modelId: 'user_churn',
      name: 'User Churn Prediction',
      type: ModelType.classification,
      features: ['session_frequency', 'feature_usage', 'error_rate'],
      target: 'will_churn',
      accuracy: 0.85,
    );

    _predictiveModels['usage_prediction'] = PredictiveModel(
      modelId: 'usage_prediction',
      name: 'Usage Prediction',
      type: ModelType.regression,
      features: ['past_usage', 'time_of_day', 'day_of_week'],
      target: 'predicted_usage',
      accuracy: 0.78,
    );
  }

  void _startDataCollection() {
    _collectionTimer = Timer.periodic(_collectionInterval, (timer) async {
      await _collectMetrics();
    });
  }

  void _startDataAggregation() {
    _aggregationTimer = Timer.periodic(_aggregationInterval, (timer) async {
      await _aggregateData();
    });
  }

  Future<void> _collectMetrics() async {
    // Collect metrics from various sources
    for (final collector in _dataCollectors.values) {
      try {
        await collector.collect();
      } catch (e) {
        // Log collection error
      }
    }
  }

  Future<void> _aggregateData() async {
    // Aggregate event data
    final aggregatedData = <String, dynamic>{};

    // Group events by type and time periods
    final eventsByType = <String, List<AnalyticsEventData>>{};
    for (final event in _eventQueue) {
      eventsByType.putIfAbsent(event.eventName, () => []).add(event);
    }

    for (final entry in eventsByType.entries) {
      final count = entry.value.length;
      final timeSpan = entry.value.last.timestamp.difference(entry.value.first.timestamp);
      final rate = timeSpan.inMinutes > 0 ? count / timeSpan.inMinutes : 0;

      aggregatedData['${entry.key}_count'] = count;
      aggregatedData['${entry.key}_rate'] = rate;
    }

    // Store aggregated data
    _aggregations[DateTime.now().toIso8601String().split('T')[0]] = DataAggregation(
      date: DateTime.now(),
      data: aggregatedData,
    );
  }

  Future<void> _updateUserProfile(AnalyticsEventData event) async {
    final profile = _userProfiles.putIfAbsent(event.userId, () => UserBehaviorProfile(event.userId));
    profile.events.add(event);

    // Maintain event history size
    if (profile.events.length > 1000) {
      profile.events.removeAt(0);
    }

    // Update behavior patterns
    await _updateBehaviorPatterns(profile, event);
  }

  Future<void> _updateBehaviorPatterns(UserBehaviorProfile profile, AnalyticsEventData event) async {
    // Update session patterns
    if (event.properties.containsKey('session_start')) {
      profile.sessionCount++;
    }

    // Update feature usage patterns
    final feature = event.properties['feature'] as String?;
    if (feature != null) {
      profile.featureUsage[feature] = (profile.featureUsage[feature] ?? 0) + 1;
    }

    // Update time patterns
    final hour = event.timestamp.hour;
    profile.hourlyActivity[hour] = (profile.hourlyActivity[hour] ?? 0) + 1;
  }

  Future<MetricData> _getMetricData(
    String metricId,
    DateTimeRange range,
    List<String>? filters,
    int? limit,
  ) async {
    // Retrieve metric data from storage/aggregation
    // This is a simplified implementation
    return MetricData(
      metricId: metricId,
      values: [
        MetricValue(
          timestamp: DateTime.now(),
          value: Random().nextDouble() * 100,
          labels: {},
        ),
      ],
      timeRange: range,
    );
  }

  Future<List<ReportInsight>> _generateReportInsights(Map<String, MetricData> data) async {
    final insights = <ReportInsight>[];

    for (final entry in data.entries) {
      final metricData = entry.value;
      final trend = _calculateTrend(metricData.values.map((v) => v.value).toList());

      if (trend == TrendDirection.increasing) {
        insights.add(ReportInsight(
          type: InsightType.trend,
          title: '${entry.key} is increasing',
          description: 'The ${entry.key} metric shows an upward trend',
          confidence: 0.8,
          data: {'trend': 'increasing'},
        ));
      }
    }

    return insights;
  }

  Future<List<TrendAnalysis>> _analyzeTrends(Map<String, MetricData> data, DateTimeRange range) async {
    final trends = <TrendAnalysis>[];

    for (final entry in data.entries) {
      final trend = _calculateTrend(entry.value.values.map((v) => v.value).toList());
      final changePercent = _calculateChangePercent(entry.value.values.map((v) => v.value).toList());

      trends.add(TrendAnalysis(
        metricId: entry.key,
        direction: trend,
        changePercent: changePercent,
        timeRange: range,
        confidence: 0.85,
      ));
    }

    return trends;
  }

  Future<UserInsights> _analyzeUserInsights(DateTimeRange range) async {
    final totalUsers = _userProfiles.length;
    final activeUsers = _userProfiles.values
        .where((profile) => profile.events.any((event) =>
          event.timestamp.isAfter(range.start) && event.timestamp.isBefore(range.end)))
        .length;

    final avgSessionDuration = _calculateAverageSessionDuration(range);
    final userRetentionRate = _calculateRetentionRate(range);

    return UserInsights(
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      newUsers: 0, // Would calculate from user registration data
      returningUsers: activeUsers,
      avgSessionDuration: avgSessionDuration,
      userRetentionRate: userRetentionRate,
      topFeatures: _getTopFeatures(range),
    );
  }

  Future<PerformanceInsights> _analyzePerformanceInsights(DateTimeRange range) async {
    // Analyze performance data
    return PerformanceInsights(
      avgResponseTime: const Duration(milliseconds: 150),
      errorRate: 0.02,
      throughput: 1000,
      availability: 0.99,
      performanceTrends: [],
      bottlenecks: [],
    );
  }

  Future<FeatureInsights> _analyzeFeatureInsights(DateTimeRange range, List<String>? focusAreas) async {
    final featureUsage = <String, int>{};

    // Aggregate feature usage across all users
    for (final profile in _userProfiles.values) {
      for (final entry in profile.featureUsage.entries) {
        if (focusAreas == null || focusAreas.contains(entry.key)) {
          featureUsage[entry.key] = (featureUsage[entry.key] ?? 0) + entry.value;
        }
      }
    }

    final sortedFeatures = featureUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return FeatureInsights(
      mostUsedFeatures: sortedFeatures.take(5).map((e) => e.key).toList(),
      leastUsedFeatures: sortedFeatures.reversed.take(3).map((e) => e.key).toList(),
      featureAdoptionRates: {},
      featureUsageTrends: [],
    );
  }

  Future<List<PredictiveInsight>> _generatePredictiveInsights(DateTimeRange range) async {
    final insights = <PredictiveInsight>[];

    // Generate insights based on predictive models
    for (final model in _predictiveModels.values) {
      if (model.type == ModelType.classification) {
        insights.add(PredictiveInsight(
          type: PredictiveInsightType.userBehavior,
          title: 'Potential user churn detected',
          description: 'Based on usage patterns, some users may be at risk of churning',
          confidence: 0.75,
          timeHorizon: const Duration(days: 30),
          recommendedActions: ['Send engagement email', 'Offer feature tutorial'],
        ));
      }
    }

    return insights;
  }

  Future<BehaviorPatterns> _analyzeBehaviorPatterns(List<AnalyticsEventData> events) async {
    final patterns = BehaviorPatterns(
      commonSequences: [], // Would analyze event sequences
      peakUsageHours: _calculatePeakHours(events),
      preferredFeatures: _calculatePreferredFeatures(events),
      usageFrequency: _calculateUsageFrequency(events),
    );

    return patterns;
  }

  Future<UserPreferences> _extractUserPreferences(List<AnalyticsEventData> events) async {
    final preferences = <String, dynamic>{};

    // Analyze user preferences from events
    final themeEvents = events.where((e) => e.properties['theme'] != null);
    if (themeEvents.isNotEmpty) {
      preferences['preferred_theme'] = themeEvents.last.properties['theme'];
    }

    return UserPreferences(
      preferredTheme: preferences['preferred_theme'] as String?,
      preferredFeatures: [],
      accessibilitySettings: {},
      customSettings: preferences,
    );
  }

  Future<double> _calculateEngagementScore(List<AnalyticsEventData> events) async {
    if (events.isEmpty) return 0.0;

    // Calculate engagement based on event frequency, diversity, and recency
    final eventCount = events.length;
    final timeSpan = events.last.timestamp.difference(events.first.timestamp);
    final frequency = timeSpan.inDays > 0 ? eventCount / timeSpan.inDays : eventCount;

    final eventTypes = events.map((e) => e.eventName).toSet().length;
    final diversity = eventTypes / 10; // Assume 10 possible event types

    final recency = DateTime.now().difference(events.last.timestamp).inDays;
    final recencyScore = recency < 7 ? 1.0 : (recency < 30 ? 0.5 : 0.1);

    return min((frequency * 0.4 + diversity * 0.3 + recencyScore * 0.3), 1.0);
  }

  Future<double> _calculatePredictionConfidence(PredictiveModel model, Map<String, dynamic> input) async {
    // Simplified confidence calculation
    return 0.85;
  }

  TrendDirection _calculateTrend(List<double> values) {
    if (values.length < 2) return TrendDirection.stable;

    final recent = values.sublist(values.length ~/ 2);
    final older = values.sublist(0, values.length ~/ 2);

    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;

    const threshold = 0.05;
    final change = (recentAvg - olderAvg) / olderAvg.abs();

    if (change > threshold) return TrendDirection.increasing;
    if (change < -threshold) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  double _calculateChangePercent(List<double> values) {
    if (values.length < 2) return 0.0;

    final first = values.first;
    final last = values.last;

    return first != 0 ? ((last - first) / first) * 100 : 0.0;
  }

  Duration _calculateAverageSessionDuration(DateTimeRange range) {
    // Simplified calculation
    return const Duration(minutes: 25);
  }

  double _calculateRetentionRate(DateTimeRange range) {
    // Simplified calculation
    return 0.75;
  }

  List<String> _getTopFeatures(DateTimeRange range) {
    final featureUsage = <String, int>{};

    for (final profile in _userProfiles.values) {
      for (final entry in profile.featureUsage.entries) {
        featureUsage[entry.key] = (featureUsage[entry.key] ?? 0) + entry.value;
      }
    }

    return featureUsage.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(5)
        .map((e) => e.key)
        .toList();
  }

  List<int> _calculatePeakHours(List<AnalyticsEventData> events) {
    final hourlyCount = List<int>.filled(24, 0);

    for (final event in events) {
      final hour = event.timestamp.hour;
      hourlyCount[hour]++;
    }

    final maxCount = hourlyCount.reduce(max);
    return hourlyCount.asMap().entries
        .where((entry) => entry.value == maxCount)
        .map((entry) => entry.key)
        .toList();
  }

  List<String> _calculatePreferredFeatures(List<AnalyticsEventData> events) {
    final featureCount = <String, int>{};

    for (final event in events) {
      final feature = event.properties['feature'] as String?;
      if (feature != null) {
        featureCount[feature] = (featureCount[feature] ?? 0) + 1;
      }
    }

    return featureCount.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(5)
        .map((e) => e.key)
        .toList();
  }

  UsageFrequency _calculateUsageFrequency(List<AnalyticsEventData> events) {
    if (events.isEmpty) return UsageFrequency.daily;

    final timeSpan = events.last.timestamp.difference(events.first.timestamp);
    final eventCount = events.length;
    final avgEventsPerDay = timeSpan.inDays > 0 ? eventCount / timeSpan.inDays : eventCount;

    if (avgEventsPerDay > 10) return UsageFrequency.daily;
    if (avgEventsPerDay > 3) return UsageFrequency.weekly;
    return UsageFrequency.monthly;
  }

  String _convertToCSV(Map<String, dynamic> data) {
    // Simplified CSV conversion
    final buffer = StringBuffer();
    buffer.writeln('Key,Value');

    void addToCSV(dynamic value, String prefix) {
      if (value is Map<String, dynamic>) {
        for (final entry in value.entries) {
          addToCSV(entry.value, '$prefix.${entry.key}');
        }
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          addToCSV(value[i], '$prefix[$i]');
        }
      } else {
        buffer.writeln('$prefix,$value');
      }
    }

    for (final entry in data.entries) {
      addToCSV(entry.value, entry.key);
    }

    return buffer.toString();
  }

  String _generateEventId() {
    return 'evt_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  void _emitAnalyticsEvent(AnalyticsEventType type, {
    String? details,
    String? error,
  }) {
    final event = AnalyticsEvent(
      type: type,
      timestamp: DateTime.now(),
      details: details,
      error: error,
    );

    _analyticsEventController.add(event);
  }

  void dispose() {
    _collectionTimer?.cancel();
    _aggregationTimer?.cancel();
    _analyticsEventController.close();
  }
}

/// Supporting data classes and enums

enum AnalyticsEventType {
  serviceInitialized,
  initializationFailed,
  eventTracked,
  dashboardDataRequested,
  dashboardDataGenerated,
  dashboardDataFailed,
  reportGenerationStarted,
  reportGenerationCompleted,
  reportGenerationFailed,
  predictiveAnalysisStarted,
  predictiveAnalysisCompleted,
  predictiveAnalysisFailed,
  dashboardCreated,
  biInsightsRequested,
  biInsightsGenerated,
  biInsightsFailed,
}

enum MetricType {
  counter,
  gauge,
  histogram,
}

enum ReportFormat {
  json,
  csv,
  pdf,
  excel,
}

enum WidgetType {
  lineChart,
  barChart,
  pieChart,
  gauge,
  number,
  table,
}

enum WidgetSize {
  small,
  medium,
  large,
}

enum ModelType {
  classification,
  regression,
  clustering,
}

enum ExportFormat {
  json,
  csv,
  xml,
}

enum TrendDirection {
  increasing,
  decreasing,
  stable,
}

enum InsightType {
  trend,
  anomaly,
  correlation,
  prediction,
}

enum PredictiveInsightType {
  userBehavior,
  performance,
  featureUsage,
  business,
}

enum UsageFrequency {
  daily,
  weekly,
  monthly,
  rarely,
}

/// Data classes

class AnalyticsEventData {
  final String eventId;
  final String eventName;
  final String userId;
  final Map<String, dynamic> properties;
  final String? sessionId;
  final String? screenName;
  final DateTime timestamp;

  AnalyticsEventData({
    required this.eventId,
    required this.eventName,
    required this.userId,
    required this.properties,
    this.sessionId,
    this.screenName,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'eventName': eventName,
    'userId': userId,
    'properties': properties,
    'sessionId': sessionId,
    'screenName': screenName,
    'timestamp': timestamp.toIso8601String(),
  };
}

class AnalyticsMetric {
  final String metricId;
  final String name;
  final String description;
  final MetricType type;
  final String unit;

  AnalyticsMetric({
    required this.metricId,
    required this.name,
    required this.description,
    required this.type,
    required this.unit,
  });
}

class AnalyticsDashboard {
  final String dashboardId;
  final String title;
  final String? description;
  final List<DashboardWidget> widgets;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime lastModified;

  AnalyticsDashboard({
    required this.dashboardId,
    required this.title,
    this.description,
    required this.widgets,
    required this.tags,
    required this.createdAt,
    required this.lastModified,
  });
}

class DashboardWidget {
  final String widgetId;
  final String title;
  final WidgetType type;
  final String metricId;
  final WidgetSize size;

  DashboardWidget({
    required this.widgetId,
    required this.title,
    required this.type,
    required this.metricId,
    required this.size,
  });
}

class DashboardData {
  final String dashboardId;
  final Map<String, MetricData> data;
  final DateTimeRange dateRange;
  final DateTime generatedAt;

  DashboardData({
    required this.dashboardId,
    required this.data,
    required this.dateRange,
    required this.generatedAt,
  });
}

class MetricData {
  final String metricId;
  final List<MetricValue> values;
  final DateTimeRange? timeRange;

  MetricData({
    required this.metricId,
    required this.values,
    this.timeRange,
  });

  Map<String, dynamic> toJson() => {
    'metricId': metricId,
    'values': values.map((v) => v.toJson()).toList(),
    'timeRange': timeRange != null ? {
      'start': timeRange!.start.toIso8601String(),
      'end': timeRange!.end.toIso8601String(),
    } : null,
  };
}

class MetricValue {
  final DateTime timestamp;
  final double value;
  final Map<String, String> labels;

  MetricValue({
    required this.timestamp,
    required this.value,
    required this.labels,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'value': value,
    'labels': labels,
  };
}

class AnalyticsReport {
  final String reportId;
  final String title;
  final String? description;
  final Map<String, MetricData> data;
  final List<ReportInsight> insights;
  final List<TrendAnalysis> trends;
  final DateTimeRange dateRange;
  final DateTime generatedAt;
  final ReportFormat format;

  AnalyticsReport({
    required this.reportId,
    required this.title,
    this.description,
    required this.data,
    required this.insights,
    required this.trends,
    required this.dateRange,
    required this.generatedAt,
    required this.format,
  });

  Map<String, dynamic> toJson() => {
    'reportId': reportId,
    'title': title,
    'description': description,
    'data': data.map((key, value) => MapEntry(key, value.toJson())),
    'insights': insights.map((i) => i.toJson()).toList(),
    'trends': trends.map((t) => t.toJson()).toList(),
    'dateRange': {
      'start': dateRange.start.toIso8601String(),
      'end': dateRange.end.toIso8601String(),
    },
    'generatedAt': generatedAt.toIso8601String(),
    'format': format.toString(),
  };
}

class ReportInsight {
  final InsightType type;
  final String title;
  final String description;
  final double confidence;
  final Map<String, dynamic> data;

  ReportInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.confidence,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'title': title,
    'description': description,
    'confidence': confidence,
    'data': data,
  };
}

class TrendAnalysis {
  final String metricId;
  final TrendDirection direction;
  final double changePercent;
  final DateTimeRange timeRange;
  final double confidence;

  TrendAnalysis({
    required this.metricId,
    required this.direction,
    required this.changePercent,
    required this.timeRange,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'metricId': metricId,
    'direction': direction.toString(),
    'changePercent': changePercent,
    'timeRange': {
      'start': timeRange.start.toIso8601String(),
      'end': timeRange.end.toIso8601String(),
    },
    'confidence': confidence,
  };
}

class UserBehaviorProfile {
  final String userId;
  final List<AnalyticsEventData> events;
  final Map<String, int> featureUsage;
  final List<int> hourlyActivity;
  int sessionCount;

  UserBehaviorProfile(this.userId, {
    List<AnalyticsEventData>? events,
    Map<String, int>? featureUsage,
    List<int>? hourlyActivity,
    this.sessionCount = 0,
  }) :
    events = events ?? [],
    featureUsage = featureUsage ?? {},
    hourlyActivity = hourlyActivity ?? List.filled(24, 0);

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'events': events.map((e) => e.toJson()).toList(),
    'featureUsage': featureUsage,
    'hourlyActivity': hourlyActivity,
    'sessionCount': sessionCount,
  };
}

class UserBehaviorAnalytics {
  final String userId;
  final int totalEvents;
  final BehaviorPatterns patterns;
  final UserPreferences preferences;
  final double engagementScore;
  final DateTimeRange dateRange;
  final DateTime analyzedAt;

  UserBehaviorAnalytics({
    required this.userId,
    required this.totalEvents,
    required this.patterns,
    required this.preferences,
    required this.engagementScore,
    required this.dateRange,
    required this.analyzedAt,
  });

  static UserBehaviorAnalytics empty(String userId) {
    return UserBehaviorAnalytics(
      userId: userId,
      totalEvents: 0,
      patterns: BehaviorPatterns(
        commonSequences: [],
        peakUsageHours: [],
        preferredFeatures: [],
        usageFrequency: UsageFrequency.monthly,
      ),
      preferences: UserPreferences(),
      engagementScore: 0.0,
      dateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
      analyzedAt: DateTime.now(),
    );
  }
}

class BehaviorPatterns {
  final List<List<String>> commonSequences;
  final List<int> peakUsageHours;
  final List<String> preferredFeatures;
  final UsageFrequency usageFrequency;

  BehaviorPatterns({
    required this.commonSequences,
    required this.peakUsageHours,
    required this.preferredFeatures,
    required this.usageFrequency,
  });
}

class UserPreferences {
  final String? preferredTheme;
  final List<String> preferredFeatures;
  final Map<String, dynamic> accessibilitySettings;
  final Map<String, dynamic> customSettings;

  UserPreferences({
    this.preferredTheme,
    List<String>? preferredFeatures,
    Map<String, dynamic>? accessibilitySettings,
    Map<String, dynamic>? customSettings,
  }) :
    preferredFeatures = preferredFeatures ?? [],
    accessibilitySettings = accessibilitySettings ?? {},
    customSettings = customSettings ?? {};
}

class PredictiveModel {
  final String modelId;
  final String name;
  final ModelType type;
  final List<String> features;
  final String target;
  final double accuracy;

  PredictiveModel({
    required this.modelId,
    required this.name,
    required this.type,
    required this.features,
    required this.target,
    required this.accuracy,
  });

  Future<Map<String, dynamic>> predict(Map<String, dynamic> input) async {
    // Simplified prediction implementation
    return {'prediction': 'predicted_value', 'confidence': accuracy};
  }
}

class PredictiveAnalyticsResult {
  final String modelId;
  final Map<String, dynamic> prediction;
  final double confidence;
  final Map<String, dynamic> inputData;
  final int? predictionHorizon;
  final DateTime generatedAt;

  PredictiveAnalyticsResult({
    required this.modelId,
    required this.prediction,
    required this.confidence,
    required this.inputData,
    this.predictionHorizon,
    required this.generatedAt,
  });
}

class BusinessIntelligenceInsights {
  final UserInsights userInsights;
  final PerformanceInsights performanceInsights;
  final FeatureInsights featureInsights;
  final List<PredictiveInsight> predictiveInsights;
  final DateTimeRange dateRange;
  final DateTime generatedAt;

  BusinessIntelligenceInsights({
    required this.userInsights,
    required this.performanceInsights,
    required this.featureInsights,
    required this.predictiveInsights,
    required this.dateRange,
    required this.generatedAt,
  });
}

class UserInsights {
  final int totalUsers;
  final int activeUsers;
  final int newUsers;
  final int returningUsers;
  final Duration avgSessionDuration;
  final double userRetentionRate;
  final List<String> topFeatures;

  UserInsights({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsers,
    required this.returningUsers,
    required this.avgSessionDuration,
    required this.userRetentionRate,
    required this.topFeatures,
  });
}

class PerformanceInsights {
  final Duration avgResponseTime;
  final double errorRate;
  final int throughput;
  final double availability;
  final List<TrendAnalysis> performanceTrends;
  final List<String> bottlenecks;

  PerformanceInsights({
    required this.avgResponseTime,
    required this.errorRate,
    required this.throughput,
    required this.availability,
    required this.performanceTrends,
    required this.bottlenecks,
  });
}

class FeatureInsights {
  final List<String> mostUsedFeatures;
  final List<String> leastUsedFeatures;
  final Map<String, double> featureAdoptionRates;
  final List<TrendAnalysis> featureUsageTrends;

  FeatureInsights({
    required this.mostUsedFeatures,
    required this.leastUsedFeatures,
    required this.featureAdoptionRates,
    required this.featureUsageTrends,
  });
}

class PredictiveInsight {
  final PredictiveInsightType type;
  final String title;
  final String description;
  final double confidence;
  final Duration timeHorizon;
  final List<String> recommendedActions;

  PredictiveInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.confidence,
    required this.timeHorizon,
    required this.recommendedActions,
  });
}

class DataCollector {
  final String collectorId;
  final String name;
  final Future<void> Function() collect;

  DataCollector({
    required this.collectorId,
    required this.name,
    required this.collect,
  });
}

class DataAggregation {
  final DateTime date;
  final Map<String, dynamic> data;

  DataAggregation({
    required this.date,
    required this.data,
  });
}

/// Event classes

class AnalyticsEvent {
  final AnalyticsEventType type;
  final DateTime timestamp;
  final String? details;
  final String? error;

  AnalyticsEvent({
    required this.type,
    required this.timestamp,
    this.details,
    this.error,
  });
}

/// Exception class

class AnalyticsException implements Exception {
  final String message;

  AnalyticsException(this.message);

  @override
  String toString() => 'AnalyticsException: $message';
}
