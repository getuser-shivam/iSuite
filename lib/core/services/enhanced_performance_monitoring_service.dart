import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/enhanced_config_provider.dart';
import '../widgets/common/parameterized_app_bar.dart';

/// Enhanced Performance Monitoring Service
/// 
/// Comprehensive performance monitoring with advanced analytics
/// Features: Real-time metrics, performance profiling, optimization suggestions
/// Performance: Efficient monitoring, minimal overhead, optimized data collection
/// Architecture: Service layer, async operations, event-driven monitoring
class EnhancedPerformanceMonitoringService {
  static EnhancedPerformanceMonitoringService? _instance;
  static EnhancedPerformanceMonitoringService get instance => _instance ??= EnhancedPerformanceMonitoringService._internal();
  
  EnhancedPerformanceMonitoringService._internal();
  
  final Map<String, PerformanceMetric> _metrics = {};
  final Map<String, PerformanceProfile> _profiles = {};
  final StreamController<PerformanceEvent> _eventController = StreamController.broadcast();
  final Map<String, PerformanceAlert> _alerts = {};
  final Map<String, OptimizationSuggestion> _suggestions = {};
  
  Stream<PerformanceEvent> get performanceEvents => _eventController.stream;
  
  /// Initialize performance monitoring
  Future<void> initialize() async {
    await _initializeMetrics();
    await _initializeProfiling();
    await _initializeAlerts();
    await _startMonitoring();
  }
  
  /// Record performance metric
  void recordMetric(String name, double value, Map<String, dynamic> metadata) {
    final metric = PerformanceMetric(
      id: _generateMetricId(),
      name: name,
      value: value,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    
    _metrics[metric.id] = metric;
    
    _emitEvent(PerformanceEvent(type: PerformanceEventType.metricRecorded, data: metric));
    
    // Check for performance alerts
    _checkPerformanceAlerts(metric);
  }
  
  /// Start performance profile
  Future<String> startProfile(String operation) async {
    final profileId = _generateProfileId();
    final profile = PerformanceProfile(
      id: profileId,
      operation: operation,
      startTime: DateTime.now(),
      status: ProfileStatus.running,
    );
    
    _profiles[profileId] = profile;
    
    _emitEvent(PerformanceEvent(type: PerformanceEventType.profileStarted, data: profile));
    
    return profileId;
  }
  
  /// End performance profile
  Future<void> endProfile(String profileId) async {
    final profile = _profiles[profileId];
    if (profile == null) {
      throw ArgumentError('Profile not found: $profileId');
    }
    
    profile.endTime = DateTime.now();
    profile.duration = profile.endTime!.difference(profile.startTime);
    profile.status = ProfileStatus.completed;
    
    _emitEvent(PerformanceEvent(type: PerformanceEventType.profileCompleted, data: profile));
    
    // Analyze performance
    await _analyzePerformance(profile);
  }
  
  /// Get performance metrics
  List<PerformanceMetric> getMetrics({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    var metrics = _metrics.values.toList();
    
    // Filter by name
    if (name != null) {
      metrics = metrics.where((m) => m.name == name).toList();
    }
    
    // Filter by date range
    if (startDate != null) {
      metrics = metrics.where((m) => m.timestamp.isAfter(startDate)).toList();
    }
    
    if (endDate != null) {
      metrics = metrics.where((m) => m.timestamp.isBefore(endDate)).toList();
    }
    
    // Sort by timestamp (newest first)
    metrics.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Apply limit
    if (limit != null) {
      metrics = metrics.take(limit).toList();
    }
    
    return metrics;
  }
  
  /// Get performance profiles
  List<PerformanceProfile> getProfiles({
    String? operation,
    ProfileStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    var profiles = _profiles.values.toList();
    
    // Filter by operation
    if (operation != null) {
      profiles = profiles.where((p) => p.operation == operation).toList();
    }
    
    // Filter by status
    if (status != null) {
      profiles = profiles.where((p) => p.status == status).toList();
    }
    
    // Filter by date range
    if (startDate != null) {
      profiles = profiles.where((p) => p.startTime.isAfter(startDate)).toList();
    }
    
    if (endDate != null) {
      profiles = profiles.where((p) => p.startTime.isBefore(endDate)).toList();
    }
    
    // Sort by start time (newest first)
    profiles.sort((a, b) => b.startTime.compareTo(a.startTime));
    
    // Apply limit
    if (limit != null) {
      profiles = profiles.take(limit).toList();
    }
    
    return profiles;
  }
  
  /// Get performance statistics
  PerformanceStatistics getPerformanceStatistics() {
    final totalMetrics = _metrics.length;
    final totalProfiles = _profiles.length;
    final activeProfiles = _profiles.values.where((p) => p.status == ProfileStatus.running).length;
    final totalAlerts = _alerts.length;
    final activeAlerts = _alerts.values.where((a) => a.isActive).length;
    
    // Calculate average performance
    final recentMetrics = getMetrics(limit: 100);
    final averageResponseTime = recentMetrics.isEmpty ? 0.0 : 
        recentMetrics.where((m) => m.name == 'response_time').map((m) => m.value).reduce((a, b) => a + b) / 
        recentMetrics.where((m) => m.name == 'response_time').length;
    
    final averageMemoryUsage = recentMetrics.isEmpty ? 0.0 :
        recentMetrics.where((m) => m.name == 'memory_usage').map((m) => m.value).reduce((a, b) => a + b) /
        recentMetrics.where((m) => m.name == 'memory_usage').length;
    
    return PerformanceStatistics(
      totalMetrics: totalMetrics,
      totalProfiles: totalProfiles,
      activeProfiles: activeProfiles,
      totalAlerts: totalAlerts,
      activeAlerts: activeAlerts,
      averageResponseTime: averageResponseTime,
      averageMemoryUsage: averageMemoryUsage,
    );
  }
  
  /// Generate performance report
  Future<PerformanceReport> generatePerformanceReport() async {
    final statistics = getPerformanceStatistics();
    final recentMetrics = getMetrics(limit: 100);
    final recentProfiles = getProfiles(limit: 50);
    final activeAlerts = _alerts.values.where((a) => a.isActive).toList();
    
    return PerformanceReport(
      generatedAt: DateTime.now(),
      statistics: statistics,
      recentMetrics: recentMetrics,
      recentProfiles: recentProfiles,
      activeAlerts: activeAlerts,
      recommendations: await _generatePerformanceRecommendations(statistics),
    );
  }
  
  /// Get optimization suggestions
  List<OptimizationSuggestion> getOptimizationSuggestions() {
    return _suggestions.values.toList();
  }
  
  /// Create performance alert
  void createAlert(String name, String description, AlertSeverity severity, AlertCondition condition) {
    final alertId = _generateAlertId();
    final alert = PerformanceAlert(
      id: alertId,
      name: name,
      description: description,
      severity: severity,
      condition: condition,
      isActive: true,
      createdAt: DateTime.now(),
    );
    
    _alerts[alertId] = alert;
    
    _emitEvent(PerformanceEvent(type: PerformanceEventType.alertCreated, data: alert));
  }
  
  /// Clear performance data
  void clearPerformanceData() {
    _metrics.clear();
    _profiles.clear();
    _alerts.clear();
    _suggestions.clear();
    
    _emitEvent(PerformanceEvent(type: PerformanceEventType.dataCleared));
  }
  
  // Private methods
  
  Future<void> _initializeMetrics() async {
    // Initialize default metrics
    recordMetric('cpu_usage', 0.0, {'source': 'system'});
    recordMetric('memory_usage', 0.0, {'source': 'system'});
    recordMetric('response_time', 0.0, {'source': 'application'});
    recordMetric('throughput', 0.0, {'source': 'application'});
  }
  
  Future<void> _initializeProfiling() async {
    // Initialize profiling system
  }
  
  Future<void> _initializeAlerts() async {
    // Initialize default alerts
    createAlert(
      'High CPU Usage',
      'CPU usage exceeds 80%',
      AlertSeverity.warning,
      AlertCondition.metricAbove('cpu_usage', 80.0),
    );
    
    createAlert(
      'High Memory Usage',
      'Memory usage exceeds 90%',
      AlertSeverity.critical,
      AlertCondition.metricAbove('memory_usage', 90.0),
    );
    
    createAlert(
      'Slow Response Time',
      'Response time exceeds 5 seconds',
      AlertSeverity.warning,
      AlertCondition.metricAbove('response_time', 5.0),
    );
  }
  
  Future<void> _startMonitoring() async {
    // Start periodic monitoring
    Timer.periodic(const Duration(seconds: 5), (timer) {
      _collectSystemMetrics();
    });
    
    Timer.periodic(const Duration(minutes: 1), (timer) {
      _analyzePerformanceTrends();
    });
  }
  
  Future<void> _collectSystemMetrics() async {
    // Collect system metrics
    final cpuUsage = await _getCpuUsage();
    final memoryUsage = await _getMemoryUsage();
    
    recordMetric('cpu_usage', cpuUsage, {'source': 'system'});
    recordMetric('memory_usage', memoryUsage, {'source': 'system'});
  }
  
  Future<void> _analyzePerformanceTrends() async {
    // Analyze performance trends and generate suggestions
    final recentMetrics = getMetrics(limit: 60); // Last minute of metrics
    
    // CPU usage trend
    final cpuMetrics = recentMetrics.where((m) => m.name == 'cpu_usage').toList();
    if (cpuMetrics.isNotEmpty) {
      final avgCpuUsage = cpuMetrics.map((m) => m.value).reduce((a, b) => a + b) / cpuMetrics.length;
      if (avgCpuUsage > 70.0) {
        _createOptimizationSuggestion(
          'High CPU Usage',
          'Consider optimizing CPU-intensive operations',
          OptimizationType.cpu,
        );
      }
    }
    
    // Memory usage trend
    final memoryMetrics = recentMetrics.where((m) => m.name == 'memory_usage').toList();
    if (memoryMetrics.isNotEmpty) {
      final avgMemoryUsage = memoryMetrics.map((m) => m.value).reduce((a, b) => a + b) / memoryMetrics.length;
      if (avgMemoryUsage > 80.0) {
        _createOptimizationSuggestion(
          'High Memory Usage',
          'Consider implementing memory optimization',
          OptimizationType.memory,
        );
      }
    }
  }
  
  Future<void> _analyzePerformance(PerformanceProfile profile) async {
    // Analyze performance profile and generate insights
    if (profile.duration != null) {
      if (profile.duration!.inSeconds > 10) {
        _createOptimizationSuggestion(
          'Slow Operation',
          'Operation "${profile.operation}" took ${profile.duration!.inSeconds} seconds',
          OptimizationType.operation,
        );
      }
    }
  }
  
  void _checkPerformanceAlerts(PerformanceMetric metric) {
    for (final alert in _alerts.values) {
      if (!alert.isActive) continue;
      
      switch (alert.condition.type) {
        case AlertConditionType.metricAbove:
          if (metric.name == alert.condition.parameter && metric.value > alert.condition.threshold) {
            _triggerAlert(alert, metric);
          }
          break;
        case AlertConditionType.metricBelow:
          if (metric.name == alert.condition.parameter && metric.value < alert.condition.threshold) {
            _triggerAlert(alert, metric);
          }
          break;
        case AlertConditionType.durationExceeds:
          // Handle duration-based alerts
          break;
      }
    }
  }
  
  void _triggerAlert(PerformanceAlert alert, PerformanceMetric metric) {
    alert.lastTriggered = DateTime.now();
    alert.triggerCount++;
    
    _emitEvent(PerformanceEvent(
      type: PerformanceEventType.alertTriggered,
      data: alert,
    ));
  }
  
  void _createOptimizationSuggestion(String title, String description, OptimizationType type) {
    final suggestionId = _generateSuggestionId();
    final suggestion = OptimizationSuggestion(
      id: suggestionId,
      title: title,
      description: description,
      type: type,
      createdAt: DateTime.now(),
      priority: _calculateSuggestionPriority(type),
    );
    
    _suggestions[suggestionId] = suggestion;
    
    _emitEvent(PerformanceEvent(type: PerformanceEventType.suggestionCreated, data: suggestion));
  }
  
  Future<List<String>> _generatePerformanceRecommendations(PerformanceStatistics statistics) async {
    final recommendations = <String>[];
    
    if (statistics.averageResponseTime > 2.0) {
      recommendations.add('Optimize response time by implementing caching and reducing database queries');
    }
    
    if (statistics.averageMemoryUsage > 80.0) {
      recommendations.add('Implement memory optimization techniques to reduce memory usage');
    }
    
    if (statistics.activeAlerts > 5) {
      recommendations.add('Review and optimize system performance to reduce alert frequency');
    }
    
    return recommendations;
  }
  
  double _calculateSuggestionPriority(OptimizationType type) {
    switch (type) {
      case OptimizationType.cpu:
        return 0.8;
      case OptimizationType.memory:
        return 0.9;
      case OptimizationType.operation:
        return 0.7;
      case OptimizationType.network:
        return 0.6;
      case OptimizationType.database:
        return 0.8;
    }
  }
  
  Future<double> _getCpuUsage() async {
    // Implementation for getting CPU usage
    // This would use system monitoring libraries
    return 30.0; // Placeholder
  }
  
  Future<double> _getMemoryUsage() async {
    // Implementation for getting memory usage
    // This would use system monitoring libraries
    return 45.0; // Placeholder
  }
  
  String _generateMetricId() {
    return 'metric_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  String _generateProfileId() {
    return 'profile_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  String _generateAlertId() {
    return 'alert_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  String _generateSuggestionId() {
    return 'suggestion_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  void _emitEvent(PerformanceEvent event) {
    _eventController.add(event);
  }
  
  void dispose() {
    _eventController.close();
  }
}

// Model classes

class PerformanceMetric {
  final String id;
  final String name;
  final double value;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  
  PerformanceMetric({
    required this.id,
    required this.name,
    required this.value,
    required this.timestamp,
    required this.metadata,
  });
}

class PerformanceProfile {
  final String id;
  final String operation;
  final DateTime startTime;
  DateTime? endTime;
  Duration? duration;
  ProfileStatus status;
  final Map<String, dynamic> metadata;
  
  PerformanceProfile({
    required this.id,
    required this.operation,
    required this.startTime,
    this.endTime,
    this.duration,
    required this.status,
    this.metadata = const {},
  });
}

class PerformanceAlert {
  final String id;
  final String name;
  final String description;
  final AlertSeverity severity;
  final AlertCondition condition;
  bool isActive;
  final DateTime createdAt;
  DateTime? lastTriggered;
  int triggerCount;
  
  PerformanceAlert({
    required this.id,
    required this.name,
    required this.description,
    required this.severity,
    required this.condition,
    required this.isActive,
    required this.createdAt,
    this.lastTriggered,
    this.triggerCount = 0,
  });
}

class OptimizationSuggestion {
  final String id;
  final String title;
  final String description;
  final OptimizationType type;
  final DateTime createdAt;
  final double priority;
  bool isImplemented;
  
  OptimizationSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.createdAt,
    required this.priority,
    this.isImplemented = false,
  });
}

class PerformanceStatistics {
  final int totalMetrics;
  final int totalProfiles;
  final int activeProfiles;
  final int totalAlerts;
  final int activeAlerts;
  final double averageResponseTime;
  final double averageMemoryUsage;
  
  PerformanceStatistics({
    required this.totalMetrics,
    required this.totalProfiles,
    required this.activeProfiles,
    required this.totalAlerts,
    required this.activeAlerts,
    required this.averageResponseTime,
    required this.averageMemoryUsage,
  });
}

class PerformanceReport {
  final DateTime generatedAt;
  final PerformanceStatistics statistics;
  final List<PerformanceMetric> recentMetrics;
  final List<PerformanceProfile> recentProfiles;
  final List<PerformanceAlert> activeAlerts;
  final List<String> recommendations;
  
  PerformanceReport({
    required this.generatedAt,
    required this.statistics,
    required this.recentMetrics,
    required this.recentProfiles,
    required this.activeAlerts,
    required this.recommendations,
  });
}

class PerformanceEvent {
  final PerformanceEventType type;
  final dynamic data;
  
  PerformanceEvent({
    required this.type,
    this.data,
  });
}

class AlertCondition {
  final AlertConditionType type;
  final String parameter;
  final double threshold;
  
  AlertCondition({
    required this.type,
    required this.parameter,
    required this.threshold,
  });
  
  static AlertCondition metricAbove(String parameter, double threshold) {
    return AlertCondition(type: AlertConditionType.metricAbove, parameter: parameter, threshold: threshold);
  }
  
  static AlertCondition metricBelow(String parameter, double threshold) {
    return AlertCondition(type: AlertConditionType.metricBelow, parameter: parameter, threshold: threshold);
  }
  
  static AlertCondition durationExceeds(Duration threshold) {
    return AlertCondition(
      type: AlertConditionType.durationExceeds,
      parameter: 'duration',
      threshold: threshold.inMilliseconds.toDouble(),
    );
  }
}

enum ProfileStatus {
  running,
  completed,
  failed,
  cancelled,
}

enum AlertSeverity {
  info,
  warning,
  critical,
}

enum AlertConditionType {
  metricAbove,
  metricBelow,
  durationExceeds,
}

enum OptimizationType {
  cpu,
  memory,
  operation,
  network,
  database,
}

enum PerformanceEventType {
  metricRecorded,
  profileStarted,
  profileCompleted,
  alertCreated,
  alertTriggered,
  suggestionCreated,
  dataCleared,
}
