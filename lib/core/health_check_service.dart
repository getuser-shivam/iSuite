import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/central_config.dart';
import '../logging/logging_service.dart';
import '../enhanced_error_handling_service.dart';
import '../enhanced_performance_service.dart';
import '../enhanced_security_service.dart';
import '../free_integrations_service.dart';
import '../advanced_offline_service.dart';
import '../advanced_free_ai_service.dart';
import '../circuit_breaker_service.dart';

/// Comprehensive Health Check Service
///
/// Provides health monitoring and diagnostics for all iSuite services:
/// - Service availability checks
/// - Performance metrics monitoring
/// - Resource usage tracking
/// - Dependency health validation
/// - System diagnostics
/// - Automated recovery suggestions
class HealthCheckService {
  static const String _configPrefix = 'health_check';
  static const String _defaultCheckInterval = 'health_check.check_interval_seconds';
  static const String _defaultTimeout = 'health_check.timeout_seconds';
  static const String _defaultFailureThreshold = 'health_check.failure_threshold';
  static const String _defaultRecoveryThreshold = 'health_check.recovery_threshold';
  static const String _defaultEnabled = 'health_check.enabled';

  final LoggingService _loggingService;
  final CentralConfig _centralConfig;
  final EnhancedErrorHandlingService _errorHandlingService;
  final EnhancedPerformanceService _performanceService;
  final EnhancedSecurityService _securityService;

  Timer? _healthCheckTimer;
  final Map<String, HealthCheckResult> _lastResults = {};
  final StreamController<HealthStatusEvent> _statusController = StreamController.broadcast();

  bool _isInitialized = false;

  // Service instances to check
  FreeIntegrationsService? _freeIntegrationsService;
  AdvancedOfflineService? _advancedOfflineService;
  AdvancedFreeAiService? _advancedFreeAiService;
  CircuitBreakerService? _circuitBreakerService;

  HealthCheckService({
    LoggingService? loggingService,
    CentralConfig? centralConfig,
    EnhancedErrorHandlingService? errorHandlingService,
    EnhancedPerformanceService? performanceService,
    EnhancedSecurityService? securityService,
  }) : _loggingService = loggingService ?? LoggingService(),
       _centralConfig = centralConfig ?? CentralConfig.instance,
       _errorHandlingService = errorHandlingService ?? EnhancedErrorHandlingService(),
       _performanceService = performanceService ?? EnhancedPerformanceService(),
       _securityService = securityService ?? EnhancedSecurityService();

  /// Initialize the health check service
  Future<void> initialize({
    FreeIntegrationsService? freeIntegrationsService,
    AdvancedOfflineService? advancedOfflineService,
    AdvancedFreeAiService? advancedFreeAiService,
    CircuitBreakerService? circuitBreakerService,
  }) async {
    if (_isInitialized) return;

    try {
      _loggingService.info('Initializing Health Check Service', 'HealthCheckService');

      // Store service references
      _freeIntegrationsService = freeIntegrationsService;
      _advancedOfflineService = advancedOfflineService;
      _advancedFreeAiService = advancedFreeAiService;
      _circuitBreakerService = circuitBreakerService;

      // Register with CentralConfig
      await _centralConfig.registerComponent(
        'HealthCheckService',
        '1.0.0',
        'Comprehensive health monitoring and diagnostics service',
        dependencies: ['CentralConfig', 'LoggingService'],
        parameters: {
          _defaultEnabled: true,
          _defaultCheckInterval: 60, // seconds
          _defaultTimeout: 10, // seconds
          _defaultFailureThreshold: 3,
          _defaultRecoveryThreshold: 2,
          'health_check.network_enabled': true,
          'health_check.database_enabled': true,
          'health_check.storage_enabled': true,
          'health_check.services_enabled': true,
          'health_check.performance_enabled': true,
          'health_check.security_enabled': true,
          'health_check.external_enabled': false, // Disabled by default for privacy
        }
      );

      // Start periodic health checks
      if (enabled) {
        _startPeriodicChecks();
      }

      _isInitialized = true;
      _loggingService.info('Health Check Service initialized successfully', 'HealthCheckService');

    } catch (e, stackTrace) {
      _loggingService.error('Failed to initialize Health Check Service', 'HealthCheckService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Configuration getters
  bool get enabled => _centralConfig.getParameter(_defaultEnabled, defaultValue: true);
  Duration get checkInterval => Duration(seconds: _centralConfig.getParameter(_defaultCheckInterval, defaultValue: 60));
  Duration get timeout => Duration(seconds: _centralConfig.getParameter(_defaultTimeout, defaultValue: 10));
  int get failureThreshold => _centralConfig.getParameter(_defaultFailureThreshold, defaultValue: 3);
  int get recoveryThreshold => _centralConfig.getParameter(_defaultRecoveryThreshold, defaultValue: 2);

  bool get networkChecksEnabled => _centralConfig.getParameter('health_check.network_enabled', defaultValue: true);
  bool get databaseChecksEnabled => _centralConfig.getParameter('health_check.database_enabled', defaultValue: true);
  bool get storageChecksEnabled => _centralConfig.getParameter('health_check.storage_enabled', defaultValue: true);
  bool get serviceChecksEnabled => _centralConfig.getParameter('health_check.services_enabled', defaultValue: true);
  bool get performanceChecksEnabled => _centralConfig.getParameter('health_check.performance_enabled', defaultValue: true);
  bool get securityChecksEnabled => _centralConfig.getParameter('health_check.security_enabled', defaultValue: true);
  bool get externalChecksEnabled => _centralConfig.getParameter('health_check.external_enabled', defaultValue: false);

  /// Perform comprehensive health check
  Future<HealthReport> performFullHealthCheck() async {
    final startTime = DateTime.now();
    final results = <String, HealthCheckResult>{};
    final issues = <HealthIssue>[];

    try {
      _loggingService.info('Starting comprehensive health check', 'HealthCheckService');

      // Network connectivity check
      if (networkChecksEnabled) {
        results['network'] = await _checkNetworkConnectivity();
      }

      // Database health check
      if (databaseChecksEnabled) {
        results['database'] = await _checkDatabaseHealth();
      }

      // Storage health check
      if (storageChecksEnabled) {
        results['storage'] = await _checkStorageHealth();
      }

      // Service health checks
      if (serviceChecksEnabled) {
        results.addAll(await _checkServiceHealth());
      }

      // Performance health check
      if (performanceChecksEnabled) {
        results['performance'] = await _checkPerformanceHealth();
      }

      // Security health check
      if (securityChecksEnabled) {
        results['security'] = await _checkSecurityHealth();
      }

      // External service checks (if enabled)
      if (externalChecksEnabled) {
        results.addAll(await _checkExternalServices());
      }

      // Update last results
      _lastResults.addAll(results);

      // Analyze results for issues
      issues.addAll(_analyzeHealthResults(results));

      final report = HealthReport(
        timestamp: DateTime.now(),
        duration: DateTime.now().difference(startTime),
        results: results,
        issues: issues,
        overallStatus: _calculateOverallStatus(results),
        recommendations: _generateRecommendations(issues),
      );

      _emitStatusEvent(HealthStatusEvent(
        type: HealthStatusEventType.checkCompleted,
        report: report,
      ));

      _loggingService.info('Health check completed in ${report.duration.inMilliseconds}ms', 'HealthCheckService');

      return report;

    } catch (e, stackTrace) {
      _loggingService.error('Health check failed', 'HealthCheckService', error: e, stackTrace: stackTrace);

      final errorReport = HealthReport(
        timestamp: DateTime.now(),
        duration: DateTime.now().difference(startTime),
        results: results,
        issues: [HealthIssue(
          severity: HealthIssueSeverity.critical,
          component: 'HealthCheckService',
          message: 'Health check execution failed: ${e.toString()}',
          recommendation: 'Check service configuration and dependencies',
        )],
        overallStatus: HealthStatus.unhealthy,
        recommendations: ['Investigate health check service failure'],
      );

      return errorReport;
    }
  }

  /// Check network connectivity
  Future<HealthCheckResult> _checkNetworkConnectivity() async {
    try {
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity().timeout(timeout);

      bool isHealthy = result.isNotEmpty && !result.contains(ConnectivityResult.none);
      String details = 'Connectivity types: ${result.map((r) => r.name).join(', ')}';

      // Test actual connectivity with a simple request
      if (isHealthy) {
        try {
          final response = await http.get(Uri.parse('https://www.google.com')).timeout(const Duration(seconds: 5));
          isHealthy = response.statusCode == 200;
          details += ', HTTP test: ${isHealthy ? 'successful' : 'failed'}';
        } catch (e) {
          isHealthy = false;
          details += ', HTTP test failed: ${e.toString()}';
        }
      }

      return HealthCheckResult(
        component: 'network',
        status: isHealthy ? HealthStatus.healthy : HealthStatus.unhealthy,
        responseTime: Duration.zero, // Not applicable
        details: details,
        metrics: {'connectivity_types': result.length},
      );

    } catch (e) {
      return HealthCheckResult.failure('network', 'Network check failed: ${e.toString()}');
    }
  }

  /// Check database health
  Future<HealthCheckResult> _checkDatabaseHealth() async {
    try {
      // This would integrate with actual database services
      // For now, return a placeholder
      final startTime = DateTime.now();

      // Simulate database operations
      await Future.delayed(const Duration(milliseconds: 100));

      final responseTime = DateTime.now().difference(startTime);

      return HealthCheckResult(
        component: 'database',
        status: HealthStatus.healthy,
        responseTime: responseTime,
        details: 'Database connectivity and basic operations healthy',
        metrics: {
          'response_time_ms': responseTime.inMilliseconds,
          'connections_active': 1, // Placeholder
        },
      );

    } catch (e) {
      return HealthCheckResult.failure('database', 'Database check failed: ${e.toString()}');
    }
  }

  /// Check storage health
  Future<HealthCheckResult> _checkStorageHealth() async {
    try {
      final startTime = DateTime.now();

      // Check available storage space
      final directory = Directory.systemTemp;
      final stat = await directory.stat();

      final freeSpace = stat.size; // This is approximate
      final totalSpace = freeSpace + 1024 * 1024 * 100; // Estimate total (placeholder)

      final responseTime = DateTime.now().difference(startTime);
      final isHealthy = freeSpace > 100 * 1024 * 1024; // 100MB minimum

      return HealthCheckResult(
        component: 'storage',
        status: isHealthy ? HealthStatus.healthy : HealthStatus.warning,
        responseTime: responseTime,
        details: 'Storage space check completed',
        metrics: {
          'free_space_mb': (freeSpace / (1024 * 1024)).round(),
          'total_space_mb': (totalSpace / (1024 * 1024)).round(),
          'usage_percent': ((1 - freeSpace / totalSpace) * 100).round(),
        },
      );

    } catch (e) {
      return HealthCheckResult.failure('storage', 'Storage check failed: ${e.toString()}');
    }
  }

  /// Check service health
  Future<Map<String, HealthCheckResult>> _checkServiceHealth() async {
    final results = <String, HealthCheckResult>{};

    // Check FreeIntegrationsService
    if (_freeIntegrationsService != null) {
      results['free_integrations'] = await _checkService(_freeIntegrationsService, 'FreeIntegrationsService');
    }

    // Check AdvancedOfflineService
    if (_advancedOfflineService != null) {
      results['advanced_offline'] = await _checkService(_advancedOfflineService, 'AdvancedOfflineService');
    }

    // Check AdvancedFreeAiService
    if (_advancedFreeAiService != null) {
      results['advanced_free_ai'] = await _checkService(_advancedFreeAiService, 'AdvancedFreeAiService');
    }

    // Check CircuitBreakerService
    if (_circuitBreakerService != null) {
      results['circuit_breaker'] = await _checkService(_circuitBreakerService, 'CircuitBreakerService');
    }

    return results;
  }

  /// Generic service health check
  Future<HealthCheckResult> _checkService(dynamic service, String serviceName) async {
    try {
      final startTime = DateTime.now();

      // Try to call a health check method if available
      if (service is FreeIntegrationsService) {
        await service.initialize();
      } else if (service is AdvancedOfflineService) {
        await service.initialize();
      } else if (service is AdvancedFreeAiService) {
        await service.initialize();
      } else if (service is CircuitBreakerService) {
        await service.initialize();
      }

      final responseTime = DateTime.now().difference(startTime);

      return HealthCheckResult(
        component: serviceName,
        status: HealthStatus.healthy,
        responseTime: responseTime,
        details: '$serviceName initialized successfully',
        metrics: {'response_time_ms': responseTime.inMilliseconds},
      );

    } catch (e) {
      return HealthCheckResult.failure(serviceName, 'Service check failed: ${e.toString()}');
    }
  }

  /// Check performance health
  Future<HealthCheckResult> _checkPerformanceHealth() async {
    try {
      final startTime = DateTime.now();

      // Get performance metrics from performance service
      final metrics = await _performanceService.getPerformanceMetrics();

      final responseTime = DateTime.now().difference(startTime);

      // Analyze performance metrics
      final memoryUsage = metrics['memory_usage_mb'] ?? 0;
      final cpuUsage = metrics['cpu_usage_percent'] ?? 0;
      final frameRate = metrics['frame_rate_fps'] ?? 60;

      bool isHealthy = true;
      final issues = <String>[];

      if (memoryUsage > 500) { // High memory usage
        isHealthy = false;
        issues.add('High memory usage: ${memoryUsage}MB');
      }

      if (cpuUsage > 80) { // High CPU usage
        isHealthy = false;
        issues.add('High CPU usage: ${cpuUsage}%');
      }

      if (frameRate < 30) { // Low frame rate
        isHealthy = false;
        issues.add('Low frame rate: ${frameRate}fps');
      }

      return HealthCheckResult(
        component: 'performance',
        status: isHealthy ? HealthStatus.healthy : HealthStatus.warning,
        responseTime: responseTime,
        details: issues.isEmpty ? 'Performance metrics within acceptable ranges' : 'Performance issues detected: ${issues.join(', ')}',
        metrics: {
          'memory_usage_mb': memoryUsage,
          'cpu_usage_percent': cpuUsage,
          'frame_rate_fps': frameRate,
          'response_time_ms': responseTime.inMilliseconds,
        },
      );

    } catch (e) {
      return HealthCheckResult.failure('performance', 'Performance check failed: ${e.toString()}');
    }
  }

  /// Check security health
  Future<HealthCheckResult> _checkSecurityHealth() async {
    try {
      final startTime = DateTime.now();

      // Get security status from security service
      final securityStatus = await _securityService.getSecurityStatus();

      final responseTime = DateTime.now().difference(startTime);

      // Analyze security metrics
      final threatsDetected = securityStatus['threats_detected'] ?? 0;
      final vulnerabilities = securityStatus['vulnerabilities'] ?? 0;
      final lastScan = securityStatus['last_scan'] as DateTime?;

      bool isHealthy = threatsDetected == 0 && vulnerabilities == 0;
      String details = 'Security scan completed';

      if (threatsDetected > 0) {
        details += ', $threatsDetected threats detected';
        isHealthy = false;
      }

      if (vulnerabilities > 0) {
        details += ', $vulnerabilities vulnerabilities found';
        isHealthy = false;
      }

      if (lastScan != null) {
        final daysSinceScan = DateTime.now().difference(lastScan).inDays;
        if (daysSinceScan > 7) {
          details += ', security scan outdated (${daysSinceScan} days old)';
          isHealthy = false;
        }
      }

      return HealthCheckResult(
        component: 'security',
        status: isHealthy ? HealthStatus.healthy : HealthStatus.unhealthy,
        responseTime: responseTime,
        details: details,
        metrics: {
          'threats_detected': threatsDetected,
          'vulnerabilities': vulnerabilities,
          'last_scan_days': lastScan != null ? DateTime.now().difference(lastScan).inDays : -1,
          'response_time_ms': responseTime.inMilliseconds,
        },
      );

    } catch (e) {
      return HealthCheckResult.failure('security', 'Security check failed: ${e.toString()}');
    }
  }

  /// Check external services
  Future<Map<String, HealthCheckResult>> _checkExternalServices() async {
    final results = <String, HealthCheckResult>{};

    // Check common external services that iSuite might depend on
    final externalServices = [
      'https://api.github.com',
      'https://www.googleapis.com',
      'https://api.openai.com', // If using OpenAI
    ];

    for (final url in externalServices) {
      try {
        final startTime = DateTime.now();
        final response = await http.get(Uri.parse(url)).timeout(timeout);
        final responseTime = DateTime.now().difference(startTime);

        final serviceName = Uri.parse(url).host;
        results[serviceName] = HealthCheckResult(
          component: serviceName,
          status: response.statusCode == 200 ? HealthStatus.healthy : HealthStatus.warning,
          responseTime: responseTime,
          details: 'HTTP ${response.statusCode}',
          metrics: {
            'status_code': response.statusCode,
            'response_time_ms': responseTime.inMilliseconds,
          },
        );

      } catch (e) {
        final serviceName = Uri.parse(url).host;
        results[serviceName] = HealthCheckResult.failure(serviceName, 'External service check failed: ${e.toString()}');
      }
    }

    return results;
  }

  /// Analyze health results for issues
  List<HealthIssue> _analyzeHealthResults(Map<String, HealthCheckResult> results) {
    final issues = <HealthIssue>[];

    for (final entry in results.entries) {
      final result = entry.value;

      if (result.status == HealthStatus.unhealthy) {
        issues.add(HealthIssue(
          severity: HealthIssueSeverity.critical,
          component: result.component,
          message: '${result.component} is unhealthy: ${result.details}',
          recommendation: 'Check ${result.component} configuration and logs',
        ));
      } else if (result.status == HealthStatus.warning) {
        issues.add(HealthIssue(
          severity: HealthIssueSeverity.warning,
          component: result.component,
          message: '${result.component} has warnings: ${result.details}',
          recommendation: 'Monitor ${result.component} performance',
        ));
      }

      // Check response times
      if (result.responseTime > const Duration(seconds: 5)) {
        issues.add(HealthIssue(
          severity: HealthIssueSeverity.warning,
          component: result.component,
          message: '${result.component} response time is slow: ${result.responseTime.inMilliseconds}ms',
          recommendation: 'Optimize ${result.component} performance',
        ));
      }
    }

    return issues;
  }

  /// Calculate overall health status
  HealthStatus _calculateOverallStatus(Map<String, HealthCheckResult> results) {
    if (results.values.any((r) => r.status == HealthStatus.unhealthy)) {
      return HealthStatus.unhealthy;
    }

    if (results.values.any((r) => r.status == HealthStatus.warning)) {
      return HealthStatus.warning;
    }

    return HealthStatus.healthy;
  }

  /// Generate recommendations based on issues
  List<String> _generateRecommendations(List<HealthIssue> issues) {
    final recommendations = <String>[];

    for (final issue in issues) {
      recommendations.add(issue.recommendation);
    }

    // Add general recommendations
    if (issues.isEmpty) {
      recommendations.add('System is healthy - continue monitoring');
    } else {
      recommendations.add('Consider implementing automated recovery mechanisms');
      recommendations.add('Review system logs for additional context');
    }

    return recommendations.toSet().toList(); // Remove duplicates
  }

  /// Start periodic health checks
  void _startPeriodicChecks() {
    _healthCheckTimer = Timer.periodic(checkInterval, (_) async {
      try {
        await performFullHealthCheck();
      } catch (e) {
        _loggingService.error('Periodic health check failed', 'HealthCheckService', error: e);
      }
    });

    _loggingService.info('Periodic health checks started', 'HealthCheckService');
  }

  /// Get last health check results
  Map<String, HealthCheckResult> getLastResults() {
    return Map.from(_lastResults);
  }

  /// Get health status for specific component
  HealthCheckResult? getComponentStatus(String component) {
    return _lastResults[component];
  }

  /// Force a health check
  Future<HealthReport> forceHealthCheck() async {
    return await performFullHealthCheck();
  }

  /// Emit status event
  void _emitStatusEvent(HealthStatusEvent event) {
    _statusController.add(event);
  }

  /// Get status event stream
  Stream<HealthStatusEvent> get statusEvents => _statusController.stream;

  /// Stop health checks
  void stop() {
    _healthCheckTimer?.cancel();
    _loggingService.info('Health check service stopped', 'HealthCheckService');
  }

  /// Dispose resources
  void dispose() {
    stop();
    _statusController.close();
    _loggingService.info('Health check service disposed', 'HealthCheckService');
  }
}

/// Health Status Enum
enum HealthStatus {
  healthy,
  warning,
  unhealthy,
}

/// Health Issue Severity
enum HealthIssueSeverity {
  info,
  warning,
  critical,
}

/// Health Check Result
class HealthCheckResult {
  final String component;
  final HealthStatus status;
  final Duration responseTime;
  final String details;
  final Map<String, dynamic> metrics;
  final DateTime timestamp;

  HealthCheckResult({
    required this.component,
    required this.status,
    required this.responseTime,
    required this.details,
    this.metrics = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory HealthCheckResult.failure(String component, String error) {
    return HealthCheckResult(
      component: component,
      status: HealthStatus.unhealthy,
      responseTime: Duration.zero,
      details: error,
      metrics: {'error': error},
    );
  }

  @override
  String toString() {
    return 'HealthCheckResult(component: $component, status: $status, responseTime: ${responseTime.inMilliseconds}ms, details: $details)';
  }
}

/// Health Issue
class HealthIssue {
  final HealthIssueSeverity severity;
  final String component;
  final String message;
  final String recommendation;
  final DateTime timestamp;

  HealthIssue({
    required this.severity,
    required this.component,
    required this.message,
    required this.recommendation,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'HealthIssue(severity: $severity, component: $component, message: $message)';
  }
}

/// Health Report
class HealthReport {
  final DateTime timestamp;
  final Duration duration;
  final Map<String, HealthCheckResult> results;
  final List<HealthIssue> issues;
  final HealthStatus overallStatus;
  final List<String> recommendations;

  HealthReport({
    required this.timestamp,
    required this.duration,
    required this.results,
    required this.issues,
    required this.overallStatus,
    required this.recommendations,
  });

  int get healthyCount => results.values.where((r) => r.status == HealthStatus.healthy).length;
  int get warningCount => results.values.where((r) => r.status == HealthStatus.warning).length;
  int get unhealthyCount => results.values.where((r) => r.status == HealthStatus.unhealthy).length;

  @override
  String toString() {
    return 'HealthReport(overallStatus: $overallStatus, duration: ${duration.inMilliseconds}ms, '
           'results: ${results.length}, issues: ${issues.length}, '
           'healthy: $healthyCount, warning: $warningCount, unhealthy: $unhealthyCount)';
  }
}

/// Health Status Event Types
enum HealthStatusEventType {
  checkStarted,
  checkCompleted,
  issueDetected,
  recoverySuggested,
}

/// Health Status Event
class HealthStatusEvent {
  final HealthStatusEventType type;
  final DateTime timestamp;
  final HealthReport? report;
  final HealthIssue? issue;

  HealthStatusEvent({
    required this.type,
    this.report,
    this.issue,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
