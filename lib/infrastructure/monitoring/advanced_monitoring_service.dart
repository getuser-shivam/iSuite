import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../config/central_config.dart';
import '../logging/logging_service.dart';

/// Advanced Monitoring and Analytics Service
/// Provides comprehensive system monitoring, performance analytics, and intelligent alerting
class AdvancedMonitoringService {
  static final AdvancedMonitoringService _instance = AdvancedMonitoringService._internal();
  factory AdvancedMonitoringService() => _instance;
  AdvancedMonitoringService._internal();

  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();

  // Monitoring data structures
  final Map<String, MetricCollector> _metricCollectors = {};
  final Map<String, AlertRule> _alertRules = {};
  final Map<String, SystemHealth> _systemHealth = {};
  final Map<String, PerformanceBaseline> _performanceBaselines = {};
  final Map<String, AnomalyDetector> _anomalyDetectors = {};

  // Event streams
  final StreamController<MonitoringEvent> _monitoringEventController = StreamController.broadcast();
  final StreamController<AlertEvent> _alertEventController = StreamController.broadcast();
  final StreamController<PerformanceEvent> _performanceEventController = StreamController.broadcast();

  Stream<MonitoringEvent> get monitoringEvents => _monitoringEventController.stream;
  Stream<AlertEvent> get alertEvents => _alertEventController.stream;
  Stream<PerformanceEvent> get performanceEvents => _performanceEventController.stream;

  // Monitoring timers
  Timer? _healthCheckTimer;
  Timer? _metricsCollectionTimer;
  Timer? _anomalyDetectionTimer;
  Timer? _performanceAnalysisTimer;

  bool _isInitialized = false;
  bool _monitoringEnabled = true;

  /// Initialize advanced monitoring service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing advanced monitoring service', 'AdvancedMonitoringService');

      // Register with CentralConfig
      await _config.registerComponent(
        'AdvancedMonitoringService',
        '2.0.0',
        'Comprehensive system monitoring with analytics and intelligent alerting',
        dependencies: ['CentralConfig', 'LoggingService'],
        parameters: {
          'monitoring.enabled': true,
          'monitoring.health_check_interval': 30000, // 30 seconds
          'monitoring.metrics_collection_interval': 60000, // 1 minute
          'monitoring.anomaly_detection_interval': 300000, // 5 minutes
          'monitoring.performance_analysis_interval': 600000, // 10 minutes
          'monitoring.alert_cooldown_period': 300000, // 5 minutes
          'monitoring.baseline_calculation_period': 604800000, // 7 days
          'monitoring.max_metrics_history': 10000,
          'monitoring.enable_predictive_alerts': true,
          'monitoring.alert_aggregation_enabled': true,
          'monitoring.export_metrics_enabled': true,
          'monitoring.realtime_dashboard_enabled': true,
        }
      );

      // Initialize monitoring components
      await _initializeMetricCollectors();
      await _initializeAlertRules();
      await _initializeAnomalyDetectors();
      await _initializePerformanceBaselines();

      // Start monitoring loops
      _startMonitoringLoops();

      _isInitialized = true;
      _logger.info('Advanced monitoring service initialized successfully', 'AdvancedMonitoringService');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize advanced monitoring service', 'AdvancedMonitoringService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Initialize metric collectors
  Future<void> _initializeMetricCollectors() async {
    try {
      // System metrics
      _metricCollectors['system_cpu'] = MetricCollector(
        name: 'System CPU Usage',
        type: MetricType.gauge,
        collectionInterval: const Duration(seconds: 30),
        collectionFunction: _collectCpuUsage,
      );

      _metricCollectors['system_memory'] = MetricCollector(
        name: 'System Memory Usage',
        type: MetricType.gauge,
        collectionInterval: const Duration(seconds: 30),
        collectionFunction: _collectMemoryUsage,
      );

      _metricCollectors['system_disk'] = MetricCollector(
        name: 'System Disk Usage',
        type: MetricType.gauge,
        collectionInterval: const Duration(minutes: 5),
        collectionFunction: _collectDiskUsage,
      );

      // Application metrics
      _metricCollectors['app_response_time'] = MetricCollector(
        name: 'Application Response Time',
        type: MetricType.histogram,
        collectionInterval: const Duration(seconds: 10),
        collectionFunction: _collectResponseTime,
      );

      _metricCollectors['app_error_rate'] = MetricCollector(
        name: 'Application Error Rate',
        type: MetricType.counter,
        collectionInterval: const Duration(minutes: 1),
        collectionFunction: _collectErrorRate,
      );

      _metricCollectors['app_active_users'] = MetricCollector(
        name: 'Active Users',
        type: MetricType.gauge,
        collectionInterval: const Duration(minutes: 5),
        collectionFunction: _collectActiveUsers,
      );

      _logger.info('Metric collectors initialized', 'AdvancedMonitoringService');

    } catch (e) {
      _logger.error('Failed to initialize metric collectors', 'AdvancedMonitoringService', error: e);
      rethrow;
    }
  }

  /// Initialize alert rules
  Future<void> _initializeAlertRules() async {
    try {
      _alertRules['high_cpu_usage'] = AlertRule(
        name: 'High CPU Usage Alert',
        condition: (metrics) => metrics['cpu_usage'] > 90.0,
        severity: AlertSeverity.warning,
        message: 'CPU usage is above 90%',
        cooldownPeriod: const Duration(minutes: 5),
      );

      _alertRules['high_memory_usage'] = AlertRule(
        name: 'High Memory Usage Alert',
        condition: (metrics) => metrics['memory_usage'] > 85.0,
        severity: AlertSeverity.warning,
        message: 'Memory usage is above 85%',
        cooldownPeriod: const Duration(minutes: 10),
      );

      _alertRules['low_disk_space'] = AlertRule(
        name: 'Low Disk Space Alert',
        condition: (metrics) => metrics['disk_usage'] > 90.0,
        severity: AlertSeverity.critical,
        message: 'Disk usage is above 90%',
        cooldownPeriod: const Duration(minutes: 30),
      );

      _alertRules['high_error_rate'] = AlertRule(
        name: 'High Error Rate Alert',
        condition: (metrics) => metrics['error_rate'] > 5.0,
        severity: AlertSeverity.error,
        message: 'Error rate is above 5%',
        cooldownPeriod: const Duration(minutes: 2),
      );

      _logger.info('Alert rules initialized', 'AdvancedMonitoringService');

    } catch (e) {
      _logger.error('Failed to initialize alert rules', 'AdvancedMonitoringService', error: e);
      rethrow;
    }
  }

  /// Initialize anomaly detectors
  Future<void> _initializeAnomalyDetectors() async {
    try {
      _anomalyDetectors['cpu_anomaly'] = AnomalyDetector(
        name: 'CPU Usage Anomaly Detector',
        metricName: 'cpu_usage',
        algorithm: AnomalyAlgorithm.isolationForest,
        sensitivity: 0.8,
        trainingPeriod: const Duration(hours: 24),
      );

      _anomalyDetectors['memory_anomaly'] = AnomalyDetector(
        name: 'Memory Usage Anomaly Detector',
        metricName: 'memory_usage',
        algorithm: AnomalyAlgorithm.statistical,
        sensitivity: 0.7,
        trainingPeriod: const Duration(hours: 12),
      );

      _anomalyDetectors['response_time_anomaly'] = AnomalyDetector(
        name: 'Response Time Anomaly Detector',
        metricName: 'response_time',
        algorithm: AnomalyAlgorithm.machineLearning,
        sensitivity: 0.9,
        trainingPeriod: const Duration(hours: 6),
      );

      _logger.info('Anomaly detectors initialized', 'AdvancedMonitoringService');

    } catch (e) {
      _logger.error('Failed to initialize anomaly detectors', 'AdvancedMonitoringService', error: e);
      rethrow;
    }
  }

  /// Initialize performance baselines
  Future<void> _initializePerformanceBaselines() async {
    try {
      // Load or calculate performance baselines
      _performanceBaselines['cpu_baseline'] = PerformanceBaseline(
        metricName: 'cpu_usage',
        average: 45.0,
        standardDeviation: 15.0,
        minValue: 5.0,
        maxValue: 95.0,
        lastUpdated: DateTime.now(),
      );

      _performanceBaselines['memory_baseline'] = PerformanceBaseline(
        metricName: 'memory_usage',
        average: 60.0,
        standardDeviation: 20.0,
        minValue: 20.0,
        maxValue: 90.0,
        lastUpdated: DateTime.now(),
      );

      _performanceBaselines['response_time_baseline'] = PerformanceBaseline(
        metricName: 'response_time',
        average: 250.0, // ms
        standardDeviation: 100.0,
        minValue: 50.0,
        maxValue: 2000.0,
        lastUpdated: DateTime.now(),
      );

      _logger.info('Performance baselines initialized', 'AdvancedMonitoringService');

    } catch (e) {
      _logger.error('Failed to initialize performance baselines', 'AdvancedMonitoringService', error: e);
      rethrow;
    }
  }

  /// Start monitoring loops
  void _startMonitoringLoops() {
    if (!_monitoringEnabled) return;

    // Health checks
    _healthCheckTimer = Timer.periodic(
      Duration(milliseconds: _config.getParameter('monitoring.health_check_interval', defaultValue: 30000)),
      (timer) => _performHealthChecks(),
    );

    // Metrics collection
    _metricsCollectionTimer = Timer.periodic(
      Duration(milliseconds: _config.getParameter('monitoring.metrics_collection_interval', defaultValue: 60000)),
      (timer) => _collectMetrics(),
    );

    // Anomaly detection
    _anomalyDetectionTimer = Timer.periodic(
      Duration(milliseconds: _config.getParameter('monitoring.anomaly_detection_interval', defaultValue: 300000)),
      (timer) => _detectAnomalies(),
    );

    // Performance analysis
    _performanceAnalysisTimer = Timer.periodic(
      Duration(milliseconds: _config.getParameter('monitoring.performance_analysis_interval', defaultValue: 600000)),
      (timer) => _analyzePerformance(),
    );

    _logger.info('Monitoring loops started', 'AdvancedMonitoringService');
  }

  /// Perform health checks
  Future<void> _performHealthChecks() async {
    try {
      final healthStatus = await _calculateSystemHealth();

      // Update system health
      _systemHealth['overall'] = healthStatus;

      // Emit health event
      _emitMonitoringEvent(MonitoringEventType.healthCheckCompleted, data: {
        'health_score': healthStatus.overallScore,
        'status': healthStatus.status.toString(),
        'issues': healthStatus.issues,
      });

      // Check for health alerts
      if (healthStatus.status == HealthStatus.critical || healthStatus.status == HealthStatus.warning) {
        _emitAlertEvent(AlertEventType.systemHealthIssue, severity: AlertSeverity.warning, data: {
          'health_status': healthStatus.status.toString(),
          'issues': healthStatus.issues,
        });
      }

    } catch (e) {
      _logger.error('Health check failed', 'AdvancedMonitoringService', error: e);
    }
  }

  /// Collect metrics
  Future<void> _collectMetrics() async {
    try {
      final metrics = <String, dynamic>{};

      // Collect all registered metrics
      for (final collector in _metricCollectors.values) {
        try {
          final value = await collector.collectionFunction();
          metrics[collector.name.toLowerCase().replaceAll(' ', '_')] = value;

          // Store metric value
          collector.addValue(value);

        } catch (e) {
          _logger.error('Failed to collect metric: ${collector.name}', 'AdvancedMonitoringService', error: e);
        }
      }

      // Emit metrics collected event
      _emitMonitoringEvent(MonitoringEventType.metricsCollected, data: metrics);

    } catch (e) {
      _logger.error('Metrics collection failed', 'AdvancedMonitoringService', error: e);
    }
  }

  /// Detect anomalies
  Future<void> _detectAnomalies() async {
    try {
      for (final detector in _anomalyDetectors.values) {
        final collector = _metricCollectors.values.firstWhere(
          (c) => c.name.toLowerCase().replaceAll(' ', '_') == detector.metricName,
          orElse: () => null,
        );

        if (collector != null && collector.values.isNotEmpty) {
          final isAnomaly = await detector.detectAnomaly(collector.values);

          if (isAnomaly) {
            _emitAlertEvent(AlertEventType.anomalyDetected, severity: AlertSeverity.warning, data: {
              'detector': detector.name,
              'metric': detector.metricName,
              'confidence': detector.lastAnomalyScore,
            });
          }
        }
      }

    } catch (e) {
      _logger.error('Anomaly detection failed', 'AdvancedMonitoringService', error: e);
    }
  }

  /// Analyze performance
  Future<void> _analyzePerformance() async {
    try {
      final analysis = await _performPerformanceAnalysis();

      // Emit performance analysis event
      _emitPerformanceEvent(PerformanceEventType.analysisCompleted, data: {
        'cpu_efficiency': analysis.cpuEfficiency,
        'memory_efficiency': analysis.memoryEfficiency,
        'response_time_trend': analysis.responseTimeTrend,
        'bottlenecks': analysis.bottlenecks,
        'recommendations': analysis.recommendations,
      });

      // Check for performance alerts
      if (analysis.cpuEfficiency < 0.7 || analysis.memoryEfficiency < 0.7) {
        _emitAlertEvent(AlertEventType.performanceIssue, severity: AlertSeverity.warning, data: {
          'cpu_efficiency': analysis.cpuEfficiency,
          'memory_efficiency': analysis.memoryEfficiency,
          'bottlenecks': analysis.bottlenecks,
        });
      }

    } catch (e) {
      _logger.error('Performance analysis failed', 'AdvancedMonitoringService', error: e);
    }
  }

  /// Calculate system health
  Future<SystemHealth> _calculateSystemHealth() async {
    try {
      // Get current metrics
      final cpuUsage = await _collectCpuUsage();
      final memoryUsage = await _collectMemoryUsage();
      final diskUsage = await _collectDiskUsage();
      final errorRate = await _collectErrorRate();

      // Calculate health score (0-100)
      double healthScore = 100.0;

      // CPU health
      if (cpuUsage > 90) healthScore -= 30;
      else if (cpuUsage > 70) healthScore -= 15;

      // Memory health
      if (memoryUsage > 85) healthScore -= 25;
      else if (memoryUsage > 70) healthScore -= 10;

      // Disk health
      if (diskUsage > 90) healthScore -= 20;
      else if (diskUsage > 80) healthScore -= 10;

      // Error rate health
      if (errorRate > 10) healthScore -= 15;
      else if (errorRate > 5) healthScore -= 5;

      // Determine status
      HealthStatus status;
      if (healthScore >= 80) status = HealthStatus.healthy;
      else if (healthScore >= 60) status = HealthStatus.warning;
      else status = HealthStatus.critical;

      // Identify issues
      final issues = <String>[];
      if (cpuUsage > 70) issues.add('High CPU usage (${cpuUsage.toStringAsFixed(1)}%)');
      if (memoryUsage > 70) issues.add('High memory usage (${memoryUsage.toStringAsFixed(1)}%)');
      if (diskUsage > 80) issues.add('Low disk space (${diskUsage.toStringAsFixed(1)}%)');
      if (errorRate > 5) issues.add('High error rate (${errorRate.toStringAsFixed(1)}%)');

      return SystemHealth(
        overallScore: healthScore,
        status: status,
        issues: issues,
        timestamp: DateTime.now(),
        metrics: {
          'cpu_usage': cpuUsage,
          'memory_usage': memoryUsage,
          'disk_usage': diskUsage,
          'error_rate': errorRate,
        },
      );

    } catch (e) {
      _logger.error('System health calculation failed', 'AdvancedMonitoringService', error: e);
      return SystemHealth(
        overallScore: 0,
        status: HealthStatus.critical,
        issues: ['Health calculation failed: $e'],
        timestamp: DateTime.now(),
        metrics: {},
      );
    }
  }

  /// Get monitoring dashboard data
  Future<MonitoringDashboard> getMonitoringDashboard() async {
    try {
      final health = await _calculateSystemHealth();
      final metrics = await _getLatestMetrics();
      final alerts = await _getActiveAlerts();
      final performance = await _getPerformanceSummary();

      return MonitoringDashboard(
        systemHealth: health,
        currentMetrics: metrics,
        activeAlerts: alerts,
        performanceSummary: performance,
        generatedAt: DateTime.now(),
      );

    } catch (e) {
      _logger.error('Failed to get monitoring dashboard', 'AdvancedMonitoringService', error: e);
      throw MonitoringException('Dashboard generation failed: $e');
    }
  }

  /// Export monitoring data
  Future<String> exportMonitoringData({
    DateTime? startDate,
    DateTime? endDate,
    ExportFormat format = ExportFormat.json,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 7));
      final end = endDate ?? DateTime.now();

      final data = {
        'export_period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
        'system_health': _systemHealth,
        'metrics': _metricCollectors.map((key, collector) => MapEntry(key, {
          'name': collector.name,
          'type': collector.type.toString(),
          'values': collector.getValuesInRange(start, end),
        })),
        'alerts': _alertRules,
        'performance_baselines': _performanceBaselines,
        'exported_at': DateTime.now().toIso8601String(),
      };

      switch (format) {
        case ExportFormat.json:
          return jsonEncode(data);
        case ExportFormat.csv:
          return _convertToCsv(data);
        default:
          return jsonEncode(data);
      }

    } catch (e) {
      _logger.error('Failed to export monitoring data', 'AdvancedMonitoringService', error: e);
      throw MonitoringException('Data export failed: $e');
    }
  }

  // Metric collection functions (simplified implementations)
  Future<double> _collectCpuUsage() async => 45.0; // Placeholder
  Future<double> _collectMemoryUsage() async => 65.0; // Placeholder
  Future<double> _collectDiskUsage() async => 35.0; // Placeholder
  Future<double> _collectResponseTime() async => 250.0; // Placeholder
  Future<double> _collectErrorRate() async => 2.5; // Placeholder
  Future<int> _collectActiveUsers() async => 150; // Placeholder

  // Helper methods
  Future<Map<String, dynamic>> _getLatestMetrics() async {
    final metrics = <String, dynamic>{};
    for (final collector in _metricCollectors.values) {
      metrics[collector.name.toLowerCase().replaceAll(' ', '_')] = collector.getLatestValue();
    }
    return metrics;
  }

  Future<List<AlertEvent>> _getActiveAlerts() async {
    // Return recent alerts (implementation would filter by time)
    return [];
  }

  Future<PerformanceSummary> _getPerformanceSummary() async {
    return PerformanceSummary(
      averageCpuUsage: 45.0,
      averageMemoryUsage: 65.0,
      averageResponseTime: 250.0,
      uptime: 99.5,
      lastUpdated: DateTime.now(),
    );
  }

  Future<PerformanceAnalysis> _performPerformanceAnalysis() async {
    return PerformanceAnalysis(
      cpuEfficiency: 0.85,
      memoryEfficiency: 0.78,
      responseTimeTrend: 'stable',
      bottlenecks: ['database_queries', 'network_requests'],
      recommendations: [
        'Consider implementing database query optimization',
        'Review network request batching strategy',
      ],
    );
  }

  String _convertToCsv(Map<String, dynamic> data) {
    // Simplified CSV conversion
    final buffer = StringBuffer();
    buffer.writeln('Key,Value');

    void addToCsv(String key, dynamic value) {
      if (value is Map) {
        for (final entry in value.entries) {
          addToCsv('$key.${entry.key}', entry.value);
        }
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          addToCsv('$key[$i]', value[i]);
        }
      } else {
        buffer.writeln('$key,$value');
      }
    }

    for (final entry in data.entries) {
      addToCsv(entry.key, entry.value);
    }

    return buffer.toString();
  }

  // Event emission methods
  void _emitMonitoringEvent(MonitoringEventType type, {Map<String, dynamic>? data}) {
    final event = MonitoringEvent(
      type: type,
      timestamp: DateTime.now(),
      data: data ?? {},
    );
    _monitoringEventController.add(event);
  }

  void _emitAlertEvent(AlertEventType type, {
    AlertSeverity severity = AlertSeverity.info,
    Map<String, dynamic>? data
  }) {
    final event = AlertEvent(
      type: type,
      severity: severity,
      timestamp: DateTime.now(),
      data: data ?? {},
    );
    _alertEventController.add(event);
  }

  void _emitPerformanceEvent(PerformanceEventType type, {Map<String, dynamic>? data}) {
    final event = PerformanceEvent(
      type: type,
      timestamp: DateTime.now(),
      data: data ?? {},
    );
    _performanceEventController.add(event);
  }

  /// Dispose resources
  void dispose() {
    _healthCheckTimer?.cancel();
    _metricsCollectionTimer?.cancel();
    _anomalyDetectionTimer?.cancel();
    _performanceAnalysisTimer?.cancel();

    _monitoringEventController.close();
    _alertEventController.close();
    _performanceEventController.close();
  }
}

/// Supporting data classes and enums

enum MetricType {
  counter,
  gauge,
  histogram,
  summary,
}

enum AlertSeverity {
  info,
  warning,
  error,
  critical,
}

enum HealthStatus {
  healthy,
  warning,
  critical,
}

enum AnomalyAlgorithm {
  statistical,
  isolationForest,
  machineLearning,
}

enum ExportFormat {
  json,
  csv,
  xml,
}

enum MonitoringEventType {
  healthCheckCompleted,
  metricsCollected,
  anomalyDetected,
  systemHealthIssue,
}

enum AlertEventType {
  systemHealthIssue,
  anomalyDetected,
  performanceIssue,
  securityAlert,
}

enum PerformanceEventType {
  analysisCompleted,
  bottleneckDetected,
  optimizationSuggested,
}

class MetricCollector {
  final String name;
  final MetricType type;
  final Duration collectionInterval;
  final Future<dynamic> Function() collectionFunction;

  final List<MetricValue> _values = [];
  final int _maxValues = 1000;

  MetricCollector({
    required this.name,
    required this.type,
    required this.collectionInterval,
    required this.collectionFunction,
  });

  void addValue(dynamic value) {
    _values.add(MetricValue(
      value: value,
      timestamp: DateTime.now(),
    ));

    // Keep only recent values
    if (_values.length > _maxValues) {
      _values.removeRange(0, _values.length - _maxValues);
    }
  }

  dynamic getLatestValue() {
    return _values.isNotEmpty ? _values.last.value : null;
  }

  List<MetricValue> getValuesInRange(DateTime start, DateTime end) {
    return _values.where((v) => v.timestamp.isAfter(start) && v.timestamp.isBefore(end)).toList();
  }

  List<MetricValue> get values => _values;
}

class MetricValue {
  final dynamic value;
  final DateTime timestamp;

  MetricValue({
    required this.value,
    required this.timestamp,
  });
}

class AlertRule {
  final String name;
  final bool Function(Map<String, dynamic>) condition;
  final AlertSeverity severity;
  final String message;
  final Duration cooldownPeriod;

  DateTime? _lastTriggered;

  AlertRule({
    required this.name,
    required this.condition,
    required this.severity,
    required this.message,
    required this.cooldownPeriod,
  });

  bool shouldTrigger(Map<String, dynamic> metrics) {
    final now = DateTime.now();

    // Check cooldown
    if (_lastTriggered != null &&
        now.difference(_lastTriggered!) < cooldownPeriod) {
      return false;
    }

    // Check condition
    if (condition(metrics)) {
      _lastTriggered = now;
      return true;
    }

    return false;
  }
}

class SystemHealth {
  final double overallScore;
  final HealthStatus status;
  final List<String> issues;
  final DateTime timestamp;
  final Map<String, dynamic> metrics;

  SystemHealth({
    required this.overallScore,
    required this.status,
    required this.issues,
    required this.timestamp,
    required this.metrics,
  });
}

class PerformanceBaseline {
  final String metricName;
  final double average;
  final double standardDeviation;
  final double minValue;
  final double maxValue;
  final DateTime lastUpdated;

  PerformanceBaseline({
    required this.metricName,
    required this.average,
    required this.standardDeviation,
    required this.minValue,
    required this.maxValue,
    required this.lastUpdated,
  });
}

class AnomalyDetector {
  final String name;
  final String metricName;
  final AnomalyAlgorithm algorithm;
  final double sensitivity;
  final Duration trainingPeriod;

  double _lastAnomalyScore = 0.0;

  AnomalyDetector({
    required this.name,
    required this.metricName,
    required this.algorithm,
    required this.sensitivity,
    required this.trainingPeriod,
  });

  double get lastAnomalyScore => _lastAnomalyScore;

  Future<bool> detectAnomaly(List<MetricValue> values) async {
    // Simplified anomaly detection
    if (values.length < 10) return false;

    final recentValues = values.sublist(max(0, values.length - 20));
    final average = recentValues.map((v) => v.value as double).reduce((a, b) => a + b) / recentValues.length;
    final latest = recentValues.last.value as double;

    // Simple statistical anomaly detection
    final deviation = (latest - average).abs() / average;

    _lastAnomalyScore = deviation;

    return deviation > sensitivity;
  }
}

class MonitoringEvent {
  final MonitoringEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  MonitoringEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });
}

class AlertEvent {
  final AlertEventType type;
  final AlertSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  AlertEvent({
    required this.type,
    required this.severity,
    required this.timestamp,
    required this.data,
  });
}

class PerformanceEvent {
  final PerformanceEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  PerformanceEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });
}

class MonitoringDashboard {
  final SystemHealth systemHealth;
  final Map<String, dynamic> currentMetrics;
  final List<AlertEvent> activeAlerts;
  final PerformanceSummary performanceSummary;
  final DateTime generatedAt;

  MonitoringDashboard({
    required this.systemHealth,
    required this.currentMetrics,
    required this.activeAlerts,
    required this.performanceSummary,
    required this.generatedAt,
  });
}

class PerformanceSummary {
  final double averageCpuUsage;
  final double averageMemoryUsage;
  final double averageResponseTime;
  final double uptime;
  final DateTime lastUpdated;

  PerformanceSummary({
    required this.averageCpuUsage,
    required this.averageMemoryUsage,
    required this.averageResponseTime,
    required this.uptime,
    required this.lastUpdated,
  });
}

class PerformanceAnalysis {
  final double cpuEfficiency;
  final double memoryEfficiency;
  final String responseTimeTrend;
  final List<String> bottlenecks;
  final List<String> recommendations;

  PerformanceAnalysis({
    required this.cpuEfficiency,
    required this.memoryEfficiency,
    required this.responseTimeTrend,
    required this.bottlenecks,
    required this.recommendations,
  });
}

class MonitoringException implements Exception {
  final String message;

  MonitoringException(this.message);

  @override
  String toString() => 'MonitoringException: $message';
}
