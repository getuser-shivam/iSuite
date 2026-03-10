import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/central_config.dart';
import '../logging/logging_service.dart';
import '../enhanced_error_handling_service.dart';
import '../enhanced_performance_service.dart';
import '../enhanced_security_service.dart';
import '../circuit_breaker_service.dart';
import '../health_check_service.dart';
import '../retry_service.dart';
import '../graceful_shutdown_service.dart';
import '../database_integrity_service.dart';
import '../backup_restore_service.dart';
import '../memory_leak_detection_service.dart';

/// Monitoring Dashboard Service
///
/// Provides real-time monitoring and visualization of all iSuite services:
/// - Live metrics dashboard
/// - Service health status
/// - Performance monitoring
/// - Error tracking and analytics
/// - System resource usage
/// - Alert management
/// - Historical data and trends
/// - Custom dashboards and widgets
class MonitoringDashboardService {
  static const String _configPrefix = 'monitoring_dashboard';
  static const String _defaultEnabled = 'monitoring_dashboard.enabled';
  static const String _defaultUpdateInterval =
      'monitoring_dashboard.update_interval_seconds';
  static const String _defaultMetricsHistory =
      'monitoring_dashboard.metrics_history_hours';
  static const String _defaultAlertThresholds =
      'monitoring_dashboard.alert_thresholds';

  final LoggingService _loggingService;
  final CentralConfig _centralConfig;
  final EnhancedErrorHandlingService _errorHandlingService;
  final EnhancedPerformanceService _performanceService;
  final EnhancedSecurityService _securityService;

  // Service references
  CircuitBreakerService? _circuitBreakerService;
  HealthCheckService? _healthCheckService;
  RetryService? _retryService;
  GracefulShutdownService? _gracefulShutdownService;
  DatabaseIntegrityService? _databaseIntegrityService;
  BackupRestoreService? _backupRestoreService;
  MemoryLeakDetectionService? _memoryLeakDetectionService;

  Timer? _updateTimer;
  final StreamController<DashboardUpdate> _dashboardController =
      StreamController.broadcast();
  final Map<String, MetricSeries> _metricsHistory = {};
  final List<Alert> _activeAlerts = [];
  final Map<String, DashboardWidget> _widgets = {};

  bool _isInitialized = false;
  DateTime? _lastUpdate;

  MonitoringDashboardService({
    LoggingService? loggingService,
    CentralConfig? centralConfig,
    EnhancedErrorHandlingService? errorHandlingService,
    EnhancedPerformanceService? performanceService,
    EnhancedSecurityService? securityService,
  })  : _loggingService = loggingService ?? LoggingService(),
        _centralConfig = centralConfig ?? CentralConfig.instance,
        _errorHandlingService =
            errorHandlingService ?? EnhancedErrorHandlingService(),
        _performanceService =
            performanceService ?? EnhancedPerformanceService(),
        _securityService = securityService ?? EnhancedSecurityService();

  /// Initialize the monitoring dashboard service
  Future<void> initialize({
    CircuitBreakerService? circuitBreakerService,
    HealthCheckService? healthCheckService,
    RetryService? retryService,
    GracefulShutdownService? gracefulShutdownService,
    DatabaseIntegrityService? databaseIntegrityService,
    BackupRestoreService? backupRestoreService,
    MemoryLeakDetectionService? memoryLeakDetectionService,
  }) async {
    if (_isInitialized) return;

    try {
      _loggingService.info('Initializing Monitoring Dashboard Service',
          'MonitoringDashboardService');

      // Store service references
      _circuitBreakerService = circuitBreakerService;
      _healthCheckService = healthCheckService;
      _retryService = retryService;
      _gracefulShutdownService = gracefulShutdownService;
      _databaseIntegrityService = databaseIntegrityService;
      _backupRestoreService = backupRestoreService;
      _memoryLeakDetectionService = memoryLeakDetectionService;

      // Register with CentralConfig
      await _centralConfig.registerComponent(
          'MonitoringDashboardService',
          '1.0.0',
          'Real-time monitoring dashboard with comprehensive metrics and analytics',
          dependencies: [
            'CentralConfig',
            'LoggingService',
            'EnhancedErrorHandlingService'
          ],
          parameters: {
            _defaultEnabled: true,
            _defaultUpdateInterval: 5, // seconds
            _defaultMetricsHistory: 24, // hours
            'monitoring_dashboard.auto_refresh_enabled': true,
            'monitoring_dashboard.alerts_enabled': true,
            'monitoring_dashboard.performance_monitoring': true,
            'monitoring_dashboard.error_tracking': true,
            'monitoring_dashboard.custom_widgets_enabled': true,
            'monitoring_dashboard.export_enabled': true,
            'monitoring_dashboard.max_history_points': 1000,
          });

      // Initialize default widgets
      _initializeDefaultWidgets();

      // Start monitoring
      if (enabled) {
        _startMonitoring();
      }

      _isInitialized = true;
      _loggingService.info(
          'Monitoring Dashboard Service initialized successfully',
          'MonitoringDashboardService');
    } catch (e, stackTrace) {
      _loggingService.error('Failed to initialize Monitoring Dashboard Service',
          'MonitoringDashboardService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Configuration getters
  bool get enabled =>
      _centralConfig.getParameter(_defaultEnabled, defaultValue: true);
  Duration get updateInterval => Duration(
      seconds:
          _centralConfig.getParameter(_defaultUpdateInterval, defaultValue: 5));
  int get metricsHistoryHours =>
      _centralConfig.getParameter(_defaultMetricsHistory, defaultValue: 24);
  bool get autoRefreshEnabled =>
      _centralConfig.getParameter('monitoring_dashboard.auto_refresh_enabled',
          defaultValue: true);
  bool get alertsEnabled => _centralConfig
      .getParameter('monitoring_dashboard.alerts_enabled', defaultValue: true);
  bool get performanceMonitoring =>
      _centralConfig.getParameter('monitoring_dashboard.performance_monitoring',
          defaultValue: true);
  bool get errorTracking => _centralConfig
      .getParameter('monitoring_dashboard.error_tracking', defaultValue: true);
  bool get customWidgetsEnabled =>
      _centralConfig.getParameter('monitoring_dashboard.custom_widgets_enabled',
          defaultValue: true);
  bool get exportEnabled => _centralConfig
      .getParameter('monitoring_dashboard.export_enabled', defaultValue: true);
  int get maxHistoryPoints =>
      _centralConfig.getParameter('monitoring_dashboard.max_history_points',
          defaultValue: 1000);

  /// Get current dashboard data
  Future<DashboardData> getDashboardData() async {
    final metrics = await _collectAllMetrics();
    final alerts = List<Alert>.from(_activeAlerts);
    final widgets = await _getActiveWidgets();

    return DashboardData(
      timestamp: DateTime.now(),
      metrics: metrics,
      alerts: alerts,
      widgets: widgets,
      lastUpdate: _lastUpdate,
      systemHealth: await _calculateSystemHealth(metrics),
    );
  }

  /// Get metric history
  Map<String, MetricSeries> getMetricHistory() {
    return Map.from(_metricsHistory);
  }

  /// Get active alerts
  List<Alert> getActiveAlerts() {
    return List.from(_activeAlerts);
  }

  /// Create custom widget
  DashboardWidget createWidget({
    required String id,
    required String title,
    required WidgetType type,
    required Map<String, dynamic> config,
    String? description,
  }) {
    if (!customWidgetsEnabled) {
      throw UnsupportedError('Custom widgets are disabled');
    }

    final widget = DashboardWidget(
      id: id,
      title: title,
      type: type,
      config: config,
      description: description,
      createdAt: DateTime.now(),
      isActive: true,
    );

    _widgets[id] = widget;
    _loggingService.info(
        'Created custom widget: $id', 'MonitoringDashboardService');

    return widget;
  }

  /// Remove widget
  void removeWidget(String widgetId) {
    _widgets.remove(widgetId);
    _loggingService.info(
        'Removed widget: $widgetId', 'MonitoringDashboardService');
  }

  /// Export dashboard data
  Future<String> exportDashboardData(
      {DashboardExportFormat format = DashboardExportFormat.json}) async {
    if (!exportEnabled) {
      throw UnsupportedError('Dashboard export is disabled');
    }

    final data = await getDashboardData();
    final history = getMetricHistory();

    final exportData = {
      'exported_at': DateTime.now().toIso8601String(),
      'dashboard_data': data.toJson(),
      'metrics_history':
          history.map((key, value) => MapEntry(key, value.toJson())),
      'active_alerts': _activeAlerts.map((a) => a.toJson()).toList(),
    };

    switch (format) {
      case DashboardExportFormat.json:
        return JsonEncoder.withIndent('  ').convert(exportData);
      case DashboardExportFormat.csv:
        return _convertToCsv(exportData);
      default:
        throw UnsupportedError('Unsupported export format: $format');
    }
  }

  /// Acknowledge alert
  void acknowledgeAlert(String alertId) {
    final alert = _activeAlerts.firstWhere((a) => a.id == alertId);
    alert.acknowledgedAt = DateTime.now();
    alert.acknowledgedBy = 'system'; // In real app, this would be user ID

    _emitUpdate(DashboardUpdate(
      type: DashboardUpdateType.alertAcknowledged,
      alert: alert,
    ));

    _loggingService.info(
        'Alert acknowledged: $alertId', 'MonitoringDashboardService');
  }

  /// Clear resolved alerts
  void clearResolvedAlerts() {
    _activeAlerts.removeWhere((alert) => alert.status == AlertStatus.resolved);
    _loggingService.info(
        'Cleared resolved alerts', 'MonitoringDashboardService');
  }

  /// Get system recommendations
  List<String> getSystemRecommendations() {
    final recommendations = <String>[];
    final data = getDashboardData();

    // This would be implemented with complex logic based on metrics
    // For now, return basic recommendations
    recommendations.add('Monitor system performance regularly');
    recommendations.add('Review error logs for potential issues');
    recommendations.add('Ensure adequate system resources');

    return recommendations;
  }

  /// Private methods

  void _initializeDefaultWidgets() {
    // System Health Widget
    createWidget(
      id: 'system_health',
      title: 'System Health',
      type: WidgetType.gauge,
      config: {
        'metric': 'system.health_score',
        'min': 0,
        'max': 100,
        'thresholds': {'warning': 70, 'critical': 50},
      },
      description: 'Overall system health score',
    );

    // Memory Usage Widget
    createWidget(
      id: 'memory_usage',
      title: 'Memory Usage',
      type: WidgetType.lineChart,
      config: {
        'metrics': ['memory.heap_used', 'memory.heap_capacity'],
        'timeRange': '1h',
        'colors': ['blue', 'red'],
      },
      description: 'Heap memory usage over time',
    );

    // Error Rate Widget
    createWidget(
      id: 'error_rate',
      title: 'Error Rate',
      type: WidgetType.barChart,
      config: {
        'metric': 'errors.rate_per_minute',
        'timeRange': '1h',
      },
      description: 'Application error rate',
    );

    // Service Status Widget
    createWidget(
      id: 'service_status',
      title: 'Service Status',
      type: WidgetType.statusList,
      config: {
        'services': ['circuit_breaker', 'health_check', 'database', 'network'],
      },
      description: 'Status of core services',
    );

    _loggingService.info(
        'Initialized default dashboard widgets', 'MonitoringDashboardService');
  }

  Future<Map<String, Metric>> _collectAllMetrics() async {
    final metrics = <String, Metric>{};

    try {
      // System metrics
      metrics.addAll(await _collectSystemMetrics());

      // Performance metrics
      if (performanceMonitoring) {
        metrics.addAll(await _collectPerformanceMetrics());
      }

      // Error metrics
      if (errorTracking) {
        metrics.addAll(await _collectErrorMetrics());
      }

      // Service-specific metrics
      metrics.addAll(await _collectServiceMetrics());
    } catch (e) {
      _loggingService.error(
          'Failed to collect metrics', 'MonitoringDashboardService',
          error: e);
    }

    return metrics;
  }

  Future<Map<String, Metric>> _collectSystemMetrics() async {
    final metrics = <String, Metric>{};

    // Basic system info
    metrics['system.uptime'] = Metric(
      name: 'system.uptime',
      value: _gracefulShutdownService?.getUptime()?.inSeconds ?? 0,
      unit: 'seconds',
      timestamp: DateTime.now(),
    );

    metrics['system.memory_pressure'] = Metric(
      name: 'system.memory_pressure',
      value: _memoryLeakDetectionService
              ?.getMemoryStatistics()
              .averageMemoryUsage ??
          0,
      unit: 'MB',
      timestamp: DateTime.now(),
    );

    return metrics;
  }

  Future<Map<String, Metric>> _collectPerformanceMetrics() async {
    final metrics = <String, Metric>{};

    try {
      final perfMetrics = await _performanceService.getPerformanceMetrics();

      metrics['performance.frame_rate'] = Metric(
        name: 'performance.frame_rate',
        value: perfMetrics['frame_rate_fps'] ?? 60.0,
        unit: 'fps',
        timestamp: DateTime.now(),
      );

      metrics['performance.memory_usage'] = Metric(
        name: 'performance.memory_usage',
        value: perfMetrics['memory_usage_mb'] ?? 0,
        unit: 'MB',
        timestamp: DateTime.now(),
      );

      metrics['performance.cpu_usage'] = Metric(
        name: 'performance.cpu_usage',
        value: perfMetrics['cpu_usage_percent'] ?? 0,
        unit: '%',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      _loggingService.warning(
          'Failed to collect performance metrics: ${e.toString()}',
          'MonitoringDashboardService');
    }

    return metrics;
  }

  Future<Map<String, Metric>> _collectErrorMetrics() async {
    final metrics = <String, Metric>{};

    try {
      final errorStats = _errorHandlingService.getErrorStatistics();

      metrics['errors.total_count'] = Metric(
        name: 'errors.total_count',
        value: errorStats.totalErrors.toDouble(),
        unit: 'count',
        timestamp: DateTime.now(),
      );

      metrics['errors.rate_per_minute'] = Metric(
        name: 'errors.rate_per_minute',
        value: errorStats.errorRatePerMinute,
        unit: 'errors/min',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      _loggingService.warning(
          'Failed to collect error metrics: ${e.toString()}',
          'MonitoringDashboardService');
    }

    return metrics;
  }

  Future<Map<String, Metric>> _collectServiceMetrics() async {
    final metrics = <String, Metric>{};

    // Circuit breaker metrics
    if (_circuitBreakerService != null) {
      final cbStats = _circuitBreakerService!.getAllStatistics();
      metrics['circuit_breaker.total_operations'] = Metric(
        name: 'circuit_breaker.total_operations',
        value: cbStats.values
            .fold(0, (sum, stat) => sum + stat.totalAttempts)
            .toDouble(),
        unit: 'operations',
        timestamp: DateTime.now(),
      );
    }

    // Health check metrics
    if (_healthCheckService != null) {
      final healthStats = _healthCheckService!.getLastResults();
      final healthyCount = healthStats.values
          .where((r) => r.status == HealthStatus.healthy)
          .length;
      final totalCount = healthStats.length;

      metrics['health.services_healthy'] = Metric(
        name: 'health.services_healthy',
        value: healthyCount.toDouble(),
        unit: 'services',
        timestamp: DateTime.now(),
      );

      metrics['health.services_total'] = Metric(
        name: 'health.services_total',
        value: totalCount.toDouble(),
        unit: 'services',
        timestamp: DateTime.now(),
      );
    }

    // Database integrity metrics
    if (_databaseIntegrityService != null) {
      final integrityStats = _databaseIntegrityService!.getIntegrityStatuses();
      final healthyDbs = integrityStats.values
          .where((s) => s.status == IntegrityStatus.healthy)
          .length;

      metrics['database.integrity_score'] = Metric(
        name: 'database.integrity_score',
        value: integrityStats.isNotEmpty
            ? (healthyDbs / integrityStats.length) * 100
            : 100.0,
        unit: '%',
        timestamp: DateTime.now(),
      );
    }

    return metrics;
  }

  Future<Map<String, DashboardWidget>> _getActiveWidgets() async {
    return Map.fromEntries(
        _widgets.entries.where((entry) => entry.value.isActive));
  }

  Future<SystemHealth> _calculateSystemHealth(
      Map<String, Metric> metrics) async {
    double healthScore = 100.0;
    final issues = <String>[];

    // Check memory usage
    final memoryUsage = metrics['performance.memory_usage']?.value ?? 0;
    if (memoryUsage > 500) {
      // High memory usage
      healthScore -= 20;
      issues.add('High memory usage: ${memoryUsage}MB');
    }

    // Check error rate
    final errorRate = metrics['errors.rate_per_minute']?.value ?? 0;
    if (errorRate > 5) {
      // High error rate
      healthScore -= 15;
      issues.add('High error rate: ${errorRate} errors/min');
    }

    // Check service health
    final healthyServices = metrics['health.services_healthy']?.value ?? 0;
    final totalServices = metrics['health.services_total']?.value ?? 1;
    final serviceHealthPercent = (healthyServices / totalServices) * 100;

    if (serviceHealthPercent < 80) {
      healthScore -= 25;
      issues.add(
          'Service health degraded: ${serviceHealthPercent.toStringAsFixed(1)}%');
    }

    // Determine overall status
    HealthStatus status;
    if (healthScore >= 90) {
      status = HealthStatus.healthy;
    } else if (healthScore >= 70) {
      status = HealthStatus.warning;
    } else {
      status = HealthStatus.unhealthy;
    }

    return SystemHealth(
      score: healthScore.clamp(0, 100),
      status: status,
      issues: issues,
      lastChecked: DateTime.now(),
    );
  }

  void _updateMetricsHistory(Map<String, Metric> metrics) {
    final now = DateTime.now();

    for (final metric in metrics.values) {
      final series = _metricsHistory.putIfAbsent(
          metric.name, () => MetricSeries(metric.name));
      series.addPoint(MetricPoint(
        timestamp: now,
        value: metric.value,
      ));

      // Limit history size
      if (series.points.length > maxHistoryPoints) {
        series.points.removeAt(0);
      }
    }
  }

  void _checkForAlerts(Map<String, Metric> metrics) {
    if (!alertsEnabled) return;

    // Memory usage alert
    final memoryUsage = metrics['performance.memory_usage']?.value ?? 0;
    if (memoryUsage > 800) {
      // Critical memory usage
      _createAlert(
        id: 'high_memory_usage',
        title: 'High Memory Usage',
        message: 'Memory usage is critically high: ${memoryUsage}MB',
        severity: AlertSeverity.critical,
        type: AlertType.resource,
      );
    }

    // Error rate alert
    final errorRate = metrics['errors.rate_per_minute']?.value ?? 0;
    if (errorRate > 10) {
      // High error rate
      _createAlert(
        id: 'high_error_rate',
        title: 'High Error Rate',
        message: 'Error rate is critically high: ${errorRate} errors/min',
        severity: AlertSeverity.critical,
        type: AlertType.error,
      );
    }

    // Service health alert
    final healthyServices = metrics['health.services_healthy']?.value ?? 0;
    final totalServices = metrics['health.services_total']?.value ?? 1;
    if (totalServices > 0 && (healthyServices / totalServices) < 0.5) {
      // Less than 50% services healthy
      _createAlert(
        id: 'service_health_degraded',
        title: 'Service Health Degraded',
        message: 'Less than 50% of services are healthy',
        severity: AlertSeverity.warning,
        type: AlertType.service,
      );
    }

    // Clean up resolved alerts
    _cleanupResolvedAlerts(metrics);
  }

  void _createAlert({
    required String id,
    required String title,
    required String message,
    required AlertSeverity severity,
    required AlertType type,
  }) {
    // Check if alert already exists
    final existingAlert =
        _activeAlerts.firstWhere((a) => a.id == id, orElse: () => null);
    if (existingAlert != null) {
      return; // Alert already active
    }

    final alert = Alert(
      id: id,
      title: title,
      message: message,
      severity: severity,
      type: type,
      status: AlertStatus.active,
      createdAt: DateTime.now(),
    );

    _activeAlerts.add(alert);

    _emitUpdate(DashboardUpdate(
      type: DashboardUpdateType.alertCreated,
      alert: alert,
    ));

    _loggingService.warning(
        'Alert created: $title', 'MonitoringDashboardService');
  }

  void _cleanupResolvedAlerts(Map<String, Metric> metrics) {
    final alertsToRemove = <String>[];

    for (final alert in _activeAlerts) {
      bool resolved = false;

      switch (alert.id) {
        case 'high_memory_usage':
          final memoryUsage = metrics['performance.memory_usage']?.value ?? 0;
          resolved = memoryUsage < 600; // Resolved if memory drops below 600MB
          break;
        case 'high_error_rate':
          final errorRate = metrics['errors.rate_per_minute']?.value ?? 0;
          resolved = errorRate < 5; // Resolved if error rate drops below 5/min
          break;
        case 'service_health_degraded':
          final healthyServices =
              metrics['health.services_healthy']?.value ?? 0;
          final totalServices = metrics['health.services_total']?.value ?? 1;
          resolved = totalServices > 0 &&
              (healthyServices / totalServices) >=
                  0.8; // Resolved if >= 80% healthy
          break;
      }

      if (resolved) {
        alert.status = AlertStatus.resolved;
        alert.resolvedAt = DateTime.now();
        alertsToRemove.add(alert.id);

        _emitUpdate(DashboardUpdate(
          type: DashboardUpdateType.alertResolved,
          alert: alert,
        ));

        _loggingService.info(
            'Alert resolved: ${alert.title}', 'MonitoringDashboardService');
      }
    }

    // Remove old resolved alerts (keep for 1 hour)
    final cutoffTime = DateTime.now().subtract(const Duration(hours: 1));
    _activeAlerts.removeWhere((alert) =>
        alert.status == AlertStatus.resolved &&
        alert.resolvedAt != null &&
        alert.resolvedAt!.isBefore(cutoffTime));
  }

  String _convertToCsv(Map<String, dynamic> data) {
    final buffer = StringBuffer();

    // Simple CSV conversion (in real app, use a proper CSV library)
    buffer.writeln('Key,Value');

    void addToCsv(String prefix, dynamic value) {
      if (value is Map<String, dynamic>) {
        value.forEach((key, val) {
          addToCsv('$prefix.$key', val);
        });
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          addToCsv('$prefix[$i]', value[i]);
        }
      } else {
        buffer.writeln('"$prefix","${value.toString().replaceAll('"', '""')}"');
      }
    }

    data.forEach((key, value) {
      addToCsv(key, value);
    });

    return buffer.toString();
  }

  void _startMonitoring() {
    _updateTimer = Timer.periodic(updateInterval, (_) async {
      try {
        await _performUpdate();
      } catch (e) {
        _loggingService.error(
            'Dashboard update failed', 'MonitoringDashboardService',
            error: e);
      }
    });

    _loggingService.info(
        'Dashboard monitoring started', 'MonitoringDashboardService');
  }

  Future<void> _performUpdate() async {
    final metrics = await _collectAllMetrics();
    _updateMetricsHistory(metrics);
    _checkForAlerts(metrics);

    _lastUpdate = DateTime.now();

    _emitUpdate(DashboardUpdate(
      type: DashboardUpdateType.metricsUpdated,
      metrics: metrics,
    ));
  }

  void _emitUpdate(DashboardUpdate update) {
    _dashboardController.add(update);
  }

  /// Get dashboard update stream
  Stream<DashboardUpdate> get dashboardUpdates => _dashboardController.stream;

  /// Get all widgets
  Map<String, DashboardWidget> getAllWidgets() {
    return Map.from(_widgets);
  }

  /// Dispose resources
  void dispose() {
    _updateTimer?.cancel();
    _dashboardController.close();
    _loggingService.info(
        'Monitoring dashboard service disposed', 'MonitoringDashboardService');
  }
}

/// Dashboard Data
class DashboardData {
  final DateTime timestamp;
  final Map<String, Metric> metrics;
  final List<Alert> alerts;
  final Map<String, DashboardWidget> widgets;
  final DateTime? lastUpdate;
  final SystemHealth systemHealth;

  DashboardData({
    required this.timestamp,
    required this.metrics,
    required this.alerts,
    required this.widgets,
    this.lastUpdate,
    required this.systemHealth,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'metrics': metrics.map((key, value) => MapEntry(key, value.toJson())),
      'alerts': alerts.map((a) => a.toJson()).toList(),
      'widgets': widgets.map((key, value) => MapEntry(key, value.toJson())),
      'last_update': lastUpdate?.toIso8601String(),
      'system_health': systemHealth.toJson(),
    };
  }
}

/// Metric
class Metric {
  final String name;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  Metric({
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'Metric($name: ${value.toStringAsFixed(2)} $unit)';
  }
}

/// Metric Series for historical data
class MetricSeries {
  final String metricName;
  final List<MetricPoint> points = [];

  MetricSeries(this.metricName);

  void addPoint(MetricPoint point) {
    points.add(point);
  }

  List<MetricPoint> getPointsInRange(DateTime start, DateTime end) {
    return points
        .where((point) =>
            point.timestamp.isAfter(start) && point.timestamp.isBefore(end))
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'metric_name': metricName,
      'points': points.map((p) => p.toJson()).toList(),
    };
  }
}

/// Metric Point
class MetricPoint {
  final DateTime timestamp;
  final double value;

  MetricPoint({
    required this.timestamp,
    required this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'value': value,
    };
  }
}

/// Alert
class Alert {
  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final AlertType type;
  AlertStatus status;
  final DateTime createdAt;
  DateTime? acknowledgedAt;
  String? acknowledgedBy;
  DateTime? resolvedAt;

  Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.type,
    required this.status,
    required this.createdAt,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.resolvedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'severity': severity.toString(),
      'type': type.toString(),
      'status': status.toString(),
      'created_at': createdAt.toIso8601String(),
      'acknowledged_at': acknowledgedAt?.toIso8601String(),
      'acknowledged_by': acknowledgedBy,
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }
}

/// Alert Severity
enum AlertSeverity {
  info,
  warning,
  critical,
}

/// Alert Type
enum AlertType {
  error,
  resource,
  service,
  security,
}

/// Alert Status
enum AlertStatus {
  active,
  acknowledged,
  resolved,
}

/// Dashboard Widget
class DashboardWidget {
  final String id;
  final String title;
  final WidgetType type;
  final Map<String, dynamic> config;
  final String? description;
  final DateTime createdAt;
  bool isActive;

  DashboardWidget({
    required this.id,
    required this.title,
    required this.type,
    required this.config,
    this.description,
    required this.createdAt,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.toString(),
      'config': config,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}

/// Widget Types
enum WidgetType {
  gauge,
  lineChart,
  barChart,
  pieChart,
  statusList,
  text,
  table,
}

/// System Health
class SystemHealth {
  final double score;
  final HealthStatus status;
  final List<String> issues;
  final DateTime lastChecked;

  SystemHealth({
    required this.score,
    required this.status,
    required this.issues,
    required this.lastChecked,
  });

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'status': status.toString(),
      'issues': issues,
      'last_checked': lastChecked.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'SystemHealth(score: ${score.toStringAsFixed(1)}, status: $status, issues: ${issues.length})';
  }
}

/// Dashboard Export Formats
enum DashboardExportFormat {
  json,
  csv,
}

/// Dashboard Update Types
enum DashboardUpdateType {
  metricsUpdated,
  alertCreated,
  alertAcknowledged,
  alertResolved,
  widgetAdded,
  widgetRemoved,
}

/// Dashboard Update
class DashboardUpdate {
  final DashboardUpdateType type;
  final DateTime timestamp;
  final Map<String, Metric>? metrics;
  final Alert? alert;
  final DashboardWidget? widget;

  DashboardUpdate({
    required this.type,
    this.metrics,
    this.alert,
    this.widget,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'DashboardUpdate(type: $type, timestamp: $timestamp)';
  }
}
