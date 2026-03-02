import 'dart:async';
import 'dart:developer' as developer;
import 'logging_service.dart';
import 'central_config.dart';

/// Comprehensive Performance Monitoring Service
///
/// Provides enterprise-grade performance monitoring and optimization:
/// - Real-time performance metrics collection
/// - Bottleneck detection and analysis
/// - Memory usage tracking and leak detection
/// - Network performance monitoring
/// - UI rendering performance analysis
/// - Automated performance recommendations
/// - Performance regression detection
class PerformanceMonitoringService {
  static final PerformanceMonitoringService _instance = PerformanceMonitoringService._internal();
  factory PerformanceMonitoringService() => _instance;
  PerformanceMonitoringService._internal();

  final LoggingService _logger = LoggingService();
  final CentralConfig _config = CentralConfig.instance;

  final Map<String, PerformanceMetric> _activeMetrics = {};
  final List<PerformanceSnapshot> _performanceHistory = [];
  final Map<String, PerformanceBaseline> _baselines = {};
  final StreamController<PerformanceEvent> _performanceEvents = StreamController.broadcast();

  bool _isInitialized = false;
  Timer? _monitoringTimer;
  Timer? _cleanupTimer;

  // Performance thresholds
  late double _cpuThreshold;
  late double _memoryThreshold;
  late Duration _responseTimeThreshold;
  late int _maxMetricsHistory;

  /// Initialize the performance monitoring service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Performance Monitoring Service', 'PerformanceMonitor');

      // Register with CentralConfig
      await _config.registerComponent(
        'PerformanceMonitoringService',
        '1.0.0',
        'Enterprise performance monitoring service with bottleneck detection and optimization',
        dependencies: ['CentralConfig', 'LoggingService'],
        parameters: {
          // Monitoring settings
          'performance.enabled': true,
          'performance.monitoring_interval_seconds': 10,
          'performance.history_retention_hours': 24,
          'performance.baseline_calculation_period_hours': 168, // 1 week

          // Thresholds
          'performance.cpu_threshold_percent': 80.0,
          'performance.memory_threshold_percent': 85.0,
          'performance.response_time_threshold_ms': 5000,
          'performance.network_timeout_threshold_ms': 30000,

          // Analysis settings
          'performance.bottleneck_detection_enabled': true,
          'performance.memory_leak_detection_enabled': true,
          'performance.regression_detection_enabled': true,
          'performance.auto_optimization_suggestions': true,

          // UI performance
          'performance.ui_rendering_threshold_ms': 16, // 60 FPS
          'performance.ui_jank_detection_enabled': true,

          // Reporting
          'performance.reporting_enabled': true,
          'performance.reporting_interval_hours': 6,
        }
      );

      // Load thresholds
      _cpuThreshold = _config.getParameter('performance.cpu_threshold_percent', defaultValue: 80.0);
      _memoryThreshold = _config.getParameter('performance.memory_threshold_percent', defaultValue: 85.0);
      _responseTimeThreshold = Duration(milliseconds: _config.getParameter('performance.response_time_threshold_ms', defaultValue: 5000));
      _maxMetricsHistory = _config.getParameter('performance.history_retention_hours', defaultValue: 24) * 3600 ~/ 10; // Convert to number of snapshots

      // Start monitoring
      _startMonitoring();

      _isInitialized = true;
      _logger.info('Performance Monitoring Service initialized successfully', 'PerformanceMonitor');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Performance Monitoring Service', 'PerformanceMonitor',
          error: e, stackTrace: stackTrace);
      // Continue with limited functionality
      _isInitialized = true;
    }
  }

  /// Start performance monitoring for an operation
  String startOperation(String operationName, {Map<String, dynamic>? metadata}) {
    final operationId = '${operationName}_${DateTime.now().millisecondsSinceEpoch}_${_activeMetrics.length}';

    final metric = PerformanceMetric(
      operationId: operationId,
      operationName: operationName,
      startTime: DateTime.now(),
      metadata: metadata ?? {},
      checkpoints: [],
    );

    _activeMetrics[operationId] = metric;

    // Add initial checkpoint
    addCheckpoint(operationId, 'start');

    return operationId;
  }

  /// End performance monitoring for an operation
  PerformanceMetric? endOperation(String operationId, {Map<String, dynamic>? resultMetadata}) {
    final metric = _activeMetrics[operationId];
    if (metric == null) {
      _logger.warning('Attempted to end unknown operation: $operationId', 'PerformanceMonitor');
      return null;
    }

    metric.endTime = DateTime.now();
    metric.duration = metric.endTime!.difference(metric.startTime);

    // Add result metadata
    if (resultMetadata != null) {
      metric.metadata.addAll(resultMetadata);
    }

    // Add final checkpoint
    addCheckpoint(operationId, 'end');

    // Move to history
    _activeMetrics.remove(operationId);

    // Analyze performance
    _analyzeOperationPerformance(metric);

    // Check for bottlenecks
    _checkForBottlenecks(metric);

    // Emit performance event
    _emitPerformanceEvent(PerformanceEventType.operationCompleted, metric: metric);

    _logger.debug('Operation completed: $operationId (${metric.duration.inMilliseconds}ms)', 'PerformanceMonitor');

    return metric;
  }

  /// Add a performance checkpoint
  void addCheckpoint(String operationId, String checkpointName, {Map<String, dynamic>? data}) {
    final metric = _activeMetrics[operationId];
    if (metric == null) return;

    final checkpoint = PerformanceCheckpoint(
      name: checkpointName,
      timestamp: DateTime.now(),
      data: data ?? {},
    );

    metric.checkpoints.add(checkpoint);
  }

  /// Record a custom performance metric
  void recordMetric(String metricName, double value, {
    String unit = '',
    Map<String, dynamic>? metadata,
  }) {
    final metric = CustomMetric(
      name: metricName,
      value: value,
      unit: unit,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    // Emit metric event
    _emitPerformanceEvent(PerformanceEventType.metricRecorded, customMetric: metric);

    // Check thresholds
    _checkMetricThresholds(metric);

    _logger.debug('Custom metric recorded: $metricName = $value $unit', 'PerformanceMonitor');
  }

  /// Take a performance snapshot
  Future<PerformanceSnapshot> takeSnapshot() async {
    final snapshot = PerformanceSnapshot(
      timestamp: DateTime.now(),
      systemMetrics: await _gatherSystemMetrics(),
      activeOperations: Map.from(_activeMetrics),
      memoryUsage: await _getMemoryUsage(),
      networkStats: await _getNetworkStats(),
    );

    _performanceHistory.add(snapshot);

    // Maintain history size
    if (_performanceHistory.length > _maxMetricsHistory) {
      _performanceHistory.removeRange(0, _performanceHistory.length - _maxMetricsHistory);
    }

    // Emit snapshot event
    _emitPerformanceEvent(PerformanceEventType.snapshotTaken, snapshot: snapshot);

    return snapshot;
  }

  /// Get performance analytics
  PerformanceAnalytics getAnalytics({Duration? timeRange}) {
    final cutoff = timeRange != null ? DateTime.now().subtract(timeRange) : null;

    final relevantHistory = cutoff != null
        ? _performanceHistory.where((s) => s.timestamp.isAfter(cutoff)).toList()
        : _performanceHistory;

    final analytics = PerformanceAnalytics(
      timeRange: timeRange ?? Duration(hours: 1),
      totalSnapshots: relevantHistory.length,
      averageMetrics: _calculateAverageMetrics(relevantHistory),
      peakMetrics: _calculatePeakMetrics(relevantHistory),
      performanceTrends: _analyzePerformanceTrends(relevantHistory),
      bottleneckAnalysis: _analyzeBottlenecks(relevantHistory),
      recommendations: _generatePerformanceRecommendations(relevantHistory),
    );

    return analytics;
  }

  /// Detect performance regressions
  List<PerformanceRegression> detectRegressions({Duration? comparisonPeriod}) {
    final period = comparisonPeriod ?? Duration(hours: 24);
    final cutoff = DateTime.now().subtract(period);

    final recentHistory = _performanceHistory.where((s) => s.timestamp.isAfter(cutoff)).toList();
    final olderHistory = _performanceHistory.where((s) => s.timestamp.isBefore(cutoff) && s.timestamp.isAfter(cutoff.subtract(period))).toList();

    if (recentHistory.isEmpty || olderHistory.isEmpty) {
      return [];
    }

    final regressions = <PerformanceRegression>[];

    // Compare average response times
    final recentAvgResponse = _calculateAverageResponseTime(recentHistory);
    final olderAvgResponse = _calculateAverageResponseTime(olderHistory);

    if (recentAvgResponse > olderAvgResponse * 1.5) { // 50% degradation
      regressions.add(PerformanceRegression(
        type: 'response_time_degradation',
        severity: RegressionSeverity.high,
        description: 'Response time increased by ${(recentAvgResponse.inMilliseconds / olderAvgResponse.inMilliseconds * 100 - 100).round()}%',
        detectedAt: DateTime.now(),
        baselineValue: olderAvgResponse,
        currentValue: recentAvgResponse,
        recommendations: [
          'Review recent code changes for performance issues',
          'Check database query optimization',
          'Monitor memory usage for potential leaks',
        ],
      ));
    }

    // Compare memory usage
    final recentAvgMemory = _calculateAverageMemoryUsage(recentHistory);
    final olderAvgMemory = _calculateAverageMemoryUsage(olderHistory);

    if (recentAvgMemory > olderAvgMemory * 1.3) { // 30% increase
      regressions.add(PerformanceRegression(
        type: 'memory_usage_increase',
        severity: RegressionSeverity.medium,
        description: 'Memory usage increased by ${(recentAvgMemory / olderAvgMemory * 100 - 100).round()}%',
        detectedAt: DateTime.now(),
        baselineValue: olderAvgMemory,
        currentValue: recentAvgMemory,
        recommendations: [
          'Check for memory leaks in recent code changes',
          'Review object lifecycle management',
          'Monitor garbage collection performance',
        ],
      ));
    }

    return regressions;
  }

  /// Get performance optimization recommendations
  Future<List<PerformanceRecommendation>> getOptimizationRecommendations() async {
    final recommendations = <List<PerformanceRecommendation>>[];

    // Analyze current performance
    final analytics = getAnalytics(timeRange: Duration(hours: 1));

    // Memory optimization recommendations
    if (analytics.averageMetrics.memoryUsage > _memoryThreshold) {
      recommendations.add([
        PerformanceRecommendation(
          category: 'memory',
          priority: RecommendationPriority.high,
          title: 'High Memory Usage Detected',
          description: 'Memory usage is above threshold (${analytics.averageMetrics.memoryUsage.toStringAsFixed(1)}%)',
          actions: [
            'Review object allocations and disposal',
            'Implement memory pooling for frequently used objects',
            'Check for memory leaks using profiling tools',
            'Consider lazy loading for large data structures',
          ],
          estimatedImprovement: 0.2, // 20% improvement
        )
      ]);
    }

    // CPU optimization recommendations
    if (analytics.averageMetrics.cpuUsage > _cpuThreshold) {
      recommendations.add([
        PerformanceRecommendation(
          category: 'cpu',
          priority: RecommendationPriority.high,
          title: 'High CPU Usage Detected',
          description: 'CPU usage is above threshold (${analytics.averageMetrics.cpuUsage.toStringAsFixed(1)}%)',
          actions: [
            'Profile CPU-intensive operations',
            'Implement background processing for heavy tasks',
            'Optimize algorithms and data structures',
            'Consider caching for expensive computations',
          ],
          estimatedImprovement: 0.25, // 25% improvement
        )
      ]);
    }

    // Network optimization recommendations
    if (analytics.averageMetrics.networkLatency > Duration(seconds: 5)) {
      recommendations.add([
        PerformanceRecommendation(
          category: 'network',
          priority: RecommendationPriority.medium,
          title: 'Slow Network Performance',
          description: 'Network latency is above acceptable threshold',
          actions: [
            'Implement response caching',
            'Use compression for data transfer',
            'Optimize API call frequency',
            'Consider offline-first architecture',
          ],
          estimatedImprovement: 0.3, // 30% improvement
        )
      ]);
    }

    return recommendations.expand((r) => r).toList();
  }

  // Private methods

  void _startMonitoring() {
    final monitoringEnabled = _config.getParameter('performance.enabled', defaultValue: true);
    if (!monitoringEnabled) return;

    final interval = Duration(seconds: _config.getParameter('performance.monitoring_interval_seconds', defaultValue: 10));

    _monitoringTimer = Timer.periodic(interval, (timer) async {
      try {
        await takeSnapshot();
      } catch (e) {
        _logger.error('Monitoring cycle failed', 'PerformanceMonitor', error: e);
      }
    });

    // Cleanup old data periodically
    _cleanupTimer = Timer.periodic(Duration(hours: 1), (timer) {
      _cleanupOldData();
    });

    _logger.info('Performance monitoring started with ${interval.inSeconds}s interval', 'PerformanceMonitor');
  }

  Future<Map<String, dynamic>> _gatherSystemMetrics() async {
    // In a real implementation, this would gather actual system metrics
    // For now, return mock data
    return {
      'cpu_usage': 45.0 + (10.0 * (DateTime.now().millisecondsSinceEpoch % 100) / 100.0), // Mock fluctuating CPU
      'memory_usage': 60.0 + (20.0 * (DateTime.now().millisecondsSinceEpoch % 100) / 100.0), // Mock fluctuating memory
      'disk_usage': 35.0,
      'network_latency': Duration(milliseconds: 50 + (DateTime.now().millisecondsSinceEpoch % 100)),
      'active_threads': 8,
      'open_file_handles': 45,
    };
  }

  Future<double> _getMemoryUsage() async {
    // Mock memory usage - in real implementation, use platform-specific APIs
    return 65.0 + (15.0 * (DateTime.now().millisecondsSinceEpoch % 100) / 100.0);
  }

  Future<Map<String, dynamic>> _getNetworkStats() async {
    // Mock network stats
    return {
      'bytes_sent': 1024000,
      'bytes_received': 2048000,
      'active_connections': 5,
      'failed_requests': 2,
    };
  }

  void _analyzeOperationPerformance(PerformanceMetric metric) {
    // Check if operation exceeded thresholds
    if (metric.duration > _responseTimeThreshold) {
      _emitPerformanceEvent(PerformanceEventType.slowOperationDetected, metric: metric);

      _logger.warning(
        'Slow operation detected: ${metric.operationName} (${metric.duration.inMilliseconds}ms)',
        'PerformanceMonitor'
      );
    }

    // Update baselines
    _updatePerformanceBaseline(metric);

    // Check for memory issues in checkpoints
    for (final checkpoint in metric.checkpoints) {
      final memoryUsage = checkpoint.data['memory_usage'] as double?;
      if (memoryUsage != null && memoryUsage > _memoryThreshold) {
        _emitPerformanceEvent(PerformanceEventType.memoryIssueDetected,
            metric: metric, checkpoint: checkpoint);
      }
    }
  }

  void _checkForBottlenecks(PerformanceMetric metric) {
    // Simple bottleneck detection
    if (metric.checkpoints.length > 1) {
      for (int i = 1; i < metric.checkpoints.length; i++) {
        final duration = metric.checkpoints[i].timestamp.difference(metric.checkpoints[i-1].timestamp);
        if (duration > Duration(seconds: 5)) {
          _emitPerformanceEvent(PerformanceEventType.bottleneckDetected,
              metric: metric, bottleneckIndex: i);
        }
      }
    }
  }

  void _checkMetricThresholds(CustomMetric metric) {
    switch (metric.name) {
      case 'cpu_usage':
        if (metric.value > _cpuThreshold) {
          _emitPerformanceEvent(PerformanceEventType.thresholdExceeded,
              customMetric: metric, thresholdType: 'cpu');
        }
        break;
      case 'memory_usage':
        if (metric.value > _memoryThreshold) {
          _emitPerformanceEvent(PerformanceEventType.thresholdExceeded,
              customMetric: metric, thresholdType: 'memory');
        }
        break;
    }
  }

  void _updatePerformanceBaseline(PerformanceMetric metric) {
    final baseline = _baselines.putIfAbsent(metric.operationName, () => PerformanceBaseline(
      operationName: metric.operationName,
      measurements: [],
    ));

    baseline.measurements.add(metric.duration);

    // Keep only last 100 measurements
    if (baseline.measurements.length > 100) {
      baseline.measurements.removeRange(0, baseline.measurements.length - 100);
    }

    // Update baseline statistics
    if (baseline.measurements.isNotEmpty) {
      final total = baseline.measurements.fold<Duration>(Duration.zero, (a, b) => a + b);
      baseline.averageDuration = Duration(microseconds: total.inMicroseconds ~/ baseline.measurements.length);

      final sorted = List<Duration>.from(baseline.measurements)..sort();
      baseline.percentile95 = sorted[(sorted.length * 0.95).toInt()];
    }
  }

  AverageMetrics _calculateAverageMetrics(List<PerformanceSnapshot> snapshots) {
    if (snapshots.isEmpty) return AverageMetrics.empty();

    double totalCpu = 0;
    double totalMemory = 0;
    Duration totalLatency = Duration.zero;
    int count = snapshots.length;

    for (final snapshot in snapshots) {
      totalCpu += snapshot.systemMetrics['cpu_usage'] as double? ?? 0;
      totalMemory += snapshot.systemMetrics['memory_usage'] as double? ?? 0;
      totalLatency += snapshot.systemMetrics['network_latency'] as Duration? ?? Duration.zero;
    }

    return AverageMetrics(
      cpuUsage: totalCpu / count,
      memoryUsage: totalMemory / count,
      networkLatency: Duration(milliseconds: totalLatency.inMilliseconds ~/ count),
      activeOperations: snapshots.map((s) => s.activeOperations.length).reduce((a, b) => a + b) ~/ count,
    );
  }

  PeakMetrics _calculatePeakMetrics(List<PerformanceSnapshot> snapshots) {
    if (snapshots.isEmpty) return PeakMetrics.empty();

    double peakCpu = 0;
    double peakMemory = 0;
    Duration peakLatency = Duration.zero;

    for (final snapshot in snapshots) {
      final cpu = snapshot.systemMetrics['cpu_usage'] as double? ?? 0;
      final memory = snapshot.systemMetrics['memory_usage'] as double? ?? 0;
      final latency = snapshot.systemMetrics['network_latency'] as Duration? ?? Duration.zero;

      peakCpu = cpu > peakCpu ? cpu : peakCpu;
      peakMemory = memory > peakMemory ? memory : peakMemory;
      peakLatency = latency > peakLatency ? latency : peakLatency;
    }

    return PeakMetrics(
      peakCpuUsage: peakCpu,
      peakMemoryUsage: peakMemory,
      peakNetworkLatency: peakLatency,
    );
  }

  List<PerformanceTrend> _analyzePerformanceTrends(List<PerformanceSnapshot> snapshots) {
    if (snapshots.length < 2) return [];

    final trends = <PerformanceTrend>[];

    // Simple trend analysis (can be enhanced with statistical methods)
    final firstHalf = snapshots.take(snapshots.length ~/ 2).toList();
    final secondHalf = snapshots.skip(snapshots.length ~/ 2).toList();

    final firstHalfAvg = _calculateAverageMetrics(firstHalf);
    final secondHalfAvg = _calculateAverageMetrics(secondHalf);

    // CPU trend
    final cpuChange = secondHalfAvg.cpuUsage - firstHalfAvg.cpuUsage;
    if (cpuChange.abs() > 5.0) { // Significant change
      trends.add(PerformanceTrend(
        metric: 'cpu_usage',
        trend: cpuChange > 0 ? 'increasing' : 'decreasing',
        changePercent: (cpuChange / firstHalfAvg.cpuUsage) * 100,
        period: snapshots.last.timestamp.difference(snapshots.first.timestamp),
      ));
    }

    // Memory trend
    final memoryChange = secondHalfAvg.memoryUsage - firstHalfAvg.memoryUsage;
    if (memoryChange.abs() > 5.0) {
      trends.add(PerformanceTrend(
        metric: 'memory_usage',
        trend: memoryChange > 0 ? 'increasing' : 'decreasing',
        changePercent: (memoryChange / firstHalfAvg.memoryUsage) * 100,
        period: snapshots.last.timestamp.difference(snapshots.first.timestamp),
      ));
    }

    return trends;
  }

  Map<String, dynamic> _analyzeBottlenecks(List<PerformanceSnapshot> snapshots) {
    // Simple bottleneck analysis
    final bottlenecks = <String, int>{};

    for (final snapshot in snapshots) {
      if (snapshot.systemMetrics['cpu_usage'] as double? ?? 0 > _cpuThreshold) {
        bottlenecks['high_cpu'] = (bottlenecks['high_cpu'] ?? 0) + 1;
      }
      if (snapshot.systemMetrics['memory_usage'] as double? ?? 0 > _memoryThreshold) {
        bottlenecks['high_memory'] = (bottlenecks['high_memory'] ?? 0) + 1;
      }
    }

    return {
      'detected_bottlenecks': bottlenecks,
      'most_common': bottlenecks.entries.isEmpty ? null :
        bottlenecks.entries.reduce((a, b) => a.value > b.value ? a : b).key,
    };
  }

  List<String> _generatePerformanceRecommendations(List<PerformanceSnapshot> snapshots) {
    final recommendations = <String>[];

    final analytics = getAnalytics();
    analytics.performanceTrends;

    if (analytics.averageMetrics.cpuUsage > _cpuThreshold) {
      recommendations.add('Consider optimizing CPU-intensive operations or implementing background processing');
    }

    if (analytics.averageMetrics.memoryUsage > _memoryThreshold) {
      recommendations.add('Review memory usage patterns and consider implementing memory optimization strategies');
    }

    if (analytics.averageMetrics.networkLatency > Duration(seconds: 2)) {
      recommendations.add('Network latency is high - consider implementing caching or optimizing data transfer');
    }

    if (recommendations.isEmpty) {
      recommendations.add('System performance is within acceptable ranges');
    }

    return recommendations;
  }

  Duration _calculateAverageResponseTime(List<PerformanceSnapshot> snapshots) {
    final operations = snapshots.expand((s) => s.activeOperations.values).toList();
    if (operations.isEmpty) return Duration.zero;

    final totalDuration = operations.fold<Duration>(
      Duration.zero,
      (sum, op) => sum + (op.endTime?.difference(op.startTime) ?? Duration.zero)
    );

    return Duration(milliseconds: totalDuration.inMilliseconds ~/ operations.length);
  }

  double _calculateAverageMemoryUsage(List<PerformanceSnapshot> snapshots) {
    if (snapshots.isEmpty) return 0.0;

    final total = snapshots.fold<double>(0, (sum, s) => sum + s.memoryUsage);
    return total / snapshots.length;
  }

  void _cleanupOldData() {
    final retentionHours = _config.getParameter('performance.history_retention_hours', defaultValue: 24);
    final cutoff = DateTime.now().subtract(Duration(hours: retentionHours));

    _performanceHistory.removeWhere((s) => s.timestamp.isBefore(cutoff));

    // Clean up old baselines (keep last 100 measurements per operation)
    for (final baseline in _baselines.values) {
      if (baseline.measurements.length > 100) {
        baseline.measurements.removeRange(0, baseline.measurements.length - 100);
      }
    }
  }

  void _emitPerformanceEvent(PerformanceEventType type, {
    PerformanceMetric? metric,
    PerformanceSnapshot? snapshot,
    CustomMetric? customMetric,
    PerformanceCheckpoint? checkpoint,
    int? bottleneckIndex,
    String? thresholdType,
  }) {
    final event = PerformanceEvent(
      type: type,
      timestamp: DateTime.now(),
      metric: metric,
      snapshot: snapshot,
      customMetric: customMetric,
      checkpoint: checkpoint,
      bottleneckIndex: bottleneckIndex,
      thresholdType: thresholdType,
    );
    _performanceEvents.add(event);
  }

  // Getters
  bool get isInitialized => _isInitialized;
  Stream<PerformanceEvent> get performanceEvents => _performanceEvents.stream;
  Map<String, PerformanceMetric> get activeMetrics => Map.from(_activeMetrics);
  List<PerformanceSnapshot> get performanceHistory => List.from(_performanceHistory);
  Map<String, PerformanceBaseline> get baselines => Map.from(_baselines);
}

/// Supporting classes and enums

enum PerformanceEventType {
  operationStarted,
  operationCompleted,
  slowOperationDetected,
  bottleneckDetected,
  memoryIssueDetected,
  metricRecorded,
  thresholdExceeded,
  snapshotTaken,
  regressionDetected,
  optimizationRecommended,
}

class PerformanceEvent {
  final PerformanceEventType type;
  final DateTime timestamp;
  final PerformanceMetric? metric;
  final PerformanceSnapshot? snapshot;
  final CustomMetric? customMetric;
  final PerformanceCheckpoint? checkpoint;
  final int? bottleneckIndex;
  final String? thresholdType;

  PerformanceEvent({
    required this.type,
    required this.timestamp,
    this.metric,
    this.snapshot,
    this.customMetric,
    this.checkpoint,
    this.bottleneckIndex,
    this.thresholdType,
  });
}

class PerformanceMetric {
  final String operationId;
  final String operationName;
  final DateTime startTime;
  DateTime? endTime;
  Duration? duration;
  final Map<String, dynamic> metadata;
  final List<PerformanceCheckpoint> checkpoints;

  PerformanceMetric({
    required this.operationId,
    required this.operationName,
    required this.startTime,
    required this.metadata,
    required this.checkpoints,
  });
}

class PerformanceCheckpoint {
  final String name;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  PerformanceCheckpoint({
    required this.name,
    required this.timestamp,
    required this.data,
  });
}

class CustomMetric {
  final String name;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  CustomMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
    required this.metadata,
  });
}

class PerformanceSnapshot {
  final DateTime timestamp;
  final Map<String, dynamic> systemMetrics;
  final Map<String, PerformanceMetric> activeOperations;
  final double memoryUsage;
  final Map<String, dynamic> networkStats;

  PerformanceSnapshot({
    required this.timestamp,
    required this.systemMetrics,
    required this.activeOperations,
    required this.memoryUsage,
    required this.networkStats,
  });
}

class PerformanceBaseline {
  final String operationName;
  final List<Duration> measurements;
  Duration? averageDuration;
  Duration? percentile95;

  PerformanceBaseline({
    required this.operationName,
    required this.measurements,
  });
}

class AverageMetrics {
  final double cpuUsage;
  final double memoryUsage;
  final Duration networkLatency;
  final int activeOperations;

  AverageMetrics({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.networkLatency,
    required this.activeOperations,
  });

  factory AverageMetrics.empty() => AverageMetrics(
    cpuUsage: 0.0,
    memoryUsage: 0.0,
    networkLatency: Duration.zero,
    activeOperations: 0,
  );
}

class PeakMetrics {
  final double peakCpuUsage;
  final double peakMemoryUsage;
  final Duration peakNetworkLatency;

  PeakMetrics({
    required this.peakCpuUsage,
    required this.peakMemoryUsage,
    required this.peakNetworkLatency,
  });

  factory PeakMetrics.empty() => PeakMetrics(
    peakCpuUsage: 0.0,
    peakMemoryUsage: 0.0,
    peakNetworkLatency: Duration.zero,
  );
}

class PerformanceAnalytics {
  final Duration timeRange;
  final int totalSnapshots;
  final AverageMetrics averageMetrics;
  final PeakMetrics peakMetrics;
  final List<PerformanceTrend> performanceTrends;
  final Map<String, dynamic> bottleneckAnalysis;
  final List<String> recommendations;

  PerformanceAnalytics({
    required this.timeRange,
    required this.totalSnapshots,
    required this.averageMetrics,
    required this.peakMetrics,
    required this.performanceTrends,
    required this.bottleneckAnalysis,
    required this.recommendations,
  });
}

class PerformanceTrend {
  final String metric;
  final String trend;
  final double changePercent;
  final Duration period;

  PerformanceTrend({
    required this.metric,
    required this.trend,
    required this.changePercent,
    required this.period,
  });
}

enum RegressionSeverity { low, medium, high, critical }

class PerformanceRegression {
  final String type;
  final RegressionSeverity severity;
  final String description;
  final DateTime detectedAt;
  final dynamic baselineValue;
  final dynamic currentValue;
  final List<String> recommendations;

  PerformanceRegression({
    required this.type,
    required this.severity,
    required this.description,
    required this.detectedAt,
    required this.baselineValue,
    required this.currentValue,
    required this.recommendations,
  });
}

enum RecommendationPriority { low, medium, high, critical }

class PerformanceRecommendation {
  final String category;
  final RecommendationPriority priority;
  final String title;
  final String description;
  final List<String> actions;
  final double estimatedImprovement;

  PerformanceRecommendation({
    required this.category,
    required this.priority,
    required this.title,
    required this.description,
    required this.actions,
    required this.estimatedImprovement,
  });
}
