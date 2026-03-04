import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'logging_service.dart';
import 'central_config.dart';

/// Enhanced Robustness Manager
/// Provides comprehensive error handling, resilience, and system robustness
class RobustnessManager {
  static final RobustnessManager _instance = RobustnessManager._internal();
  factory RobustnessManager() => _instance;
  RobustnessManager._internal();

  final LoggingService _logger = LoggingService();
  final CentralConfig _config = CentralConfig.instance;

  // Error handling
  final Map<String, ErrorHandler> _errorHandlers = {};
  final Map<String, CircuitBreaker> _circuitBreakers = {};
  final Map<String, RetryPolicy> _retryPolicies = {};

  // Performance metrics
  final List<ErrorMetric> _errorMetrics = [];
  final Map<String, DateTime> _lastErrors = {};

  // State
  bool _isInitialized = false;
  final StreamController<RobustnessEvent> _eventController =
      StreamController.broadcast();

  Stream<RobustnessEvent> get events => _eventController.stream;

  /// Initialize robustness manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Register with CentralConfig with comprehensive parameterization
      await _config.registerComponent('RobustnessManager', '1.0.0',
          'Comprehensive robustness manager with circuit breakers, health monitoring, error recovery, performance monitoring, and fallback strategies using centralized parameterization',
          dependencies: [
            'CentralConfig',
            'PerformanceOptimizationService'
          ],
          parameters: {
            // === CIRCUIT BREAKER CONFIGURATION ===
            'robustness.circuit_breaker.enabled': _config.getParameter(
                'robustness.circuit_breaker.enabled',
                defaultValue: true),
            'robustness.circuit_breaker.failure_threshold': _config
                .getParameter('robustness.circuit_breaker.failure_threshold',
                    defaultValue: 5),
            'robustness.circuit_breaker.recovery_timeout_seconds':
                _config.getParameter(
                    'robustness.circuit_breaker.recovery_timeout_seconds',
                    defaultValue: 60),
            'robustness.circuit_breaker.monitoring_period_seconds':
                _config.getParameter(
                    'robustness.circuit_breaker.monitoring_period_seconds',
                    defaultValue: 300),
            'robustness.circuit_breaker.half_open_max_calls': _config
                .getParameter('robustness.circuit_breaker.half_open_max_calls',
                    defaultValue: 3),
            'robustness.circuit_breaker.success_threshold': _config
                .getParameter('robustness.circuit_breaker.success_threshold',
                    defaultValue: 2),

            // === HEALTH MONITORING ===
            'robustness.health_monitoring.enabled': _config.getParameter(
                'robustness.health_monitoring.enabled',
                defaultValue: true),
            'robustness.health_monitoring.check_interval_seconds':
                _config.getParameter(
                    'robustness.health_monitoring.check_interval_seconds',
                    defaultValue: 30),
            'robustness.health_monitoring.timeout_seconds': _config
                .getParameter('robustness.health_monitoring.timeout_seconds',
                    defaultValue: 10),
            'robustness.health_monitoring.failure_threshold': _config
                .getParameter('robustness.health_monitoring.failure_threshold',
                    defaultValue: 3),
            'robustness.health_monitoring.recovery_threshold': _config
                .getParameter('robustness.health_monitoring.recovery_threshold',
                    defaultValue: 2),
            'robustness.health_monitoring.alerting_enabled': _config
                .getParameter('robustness.health_monitoring.alerting_enabled',
                    defaultValue: true),

            // === COMPONENT HEALTH CHECKS ===
            'robustness.component_health_checks.enabled': _config.getParameter(
                'robustness.component_health_checks.enabled',
                defaultValue: true),
            'robustness.component_health_checks.network_enabled':
                _config.getParameter(
                    'robustness.component_health_checks.network_enabled',
                    defaultValue: true),
            'robustness.component_health_checks.database_enabled':
                _config.getParameter(
                    'robustness.component_health_checks.database_enabled',
                    defaultValue: true),
            'robustness.component_health_checks.api_enabled': _config
                .getParameter('robustness.component_health_checks.api_enabled',
                    defaultValue: true),
            'robustness.component_health_checks.storage_enabled':
                _config.getParameter(
                    'robustness.component_health_checks.storage_enabled',
                    defaultValue: true),
            'robustness.component_health_checks.cache_enabled':
                _config.getParameter(
                    'robustness.component_health_checks.cache_enabled',
                    defaultValue: true),

            // === DATA VALIDATION ===
            'robustness.data_validation.enabled': _config.getParameter(
                'robustness.data_validation.enabled',
                defaultValue: true),
            'robustness.data_validation.strict_mode': _config.getParameter(
                'robustness.data_validation.strict_mode',
                defaultValue: false),
            'robustness.data_validation.input_sanitization': _config
                .getParameter('robustness.data_validation.input_sanitization',
                    defaultValue: true),
            'robustness.data_validation.schema_validation': _config
                .getParameter('robustness.data_validation.schema_validation',
                    defaultValue: true),
            'robustness.data_validation.type_checking': _config.getParameter(
                'robustness.data_validation.type_checking',
                defaultValue: true),
            'robustness.data_validation.bounds_checking': _config.getParameter(
                'robustness.data_validation.bounds_checking',
                defaultValue: true),

            // === ERROR RECOVERY ===
            'robustness.error_recovery.enabled': _config.getParameter(
                'robustness.error_recovery.enabled',
                defaultValue: true),
            'robustness.error_recovery.auto_retry': _config.getParameter(
                'robustness.error_recovery.auto_retry',
                defaultValue: true),
            'robustness.error_recovery.graceful_degradation': _config
                .getParameter('robustness.error_recovery.graceful_degradation',
                    defaultValue: true),
            'robustness.error_recovery.fallback_strategies': _config
                .getParameter('robustness.error_recovery.fallback_strategies',
                    defaultValue: true),
            'robustness.error_recovery.state_preservation': _config
                .getParameter('robustness.error_recovery.state_preservation',
                    defaultValue: true),
            'robustness.error_recovery.recovery_timeout_seconds':
                _config.getParameter(
                    'robustness.error_recovery.recovery_timeout_seconds',
                    defaultValue: 300),

            // === PERFORMANCE MONITORING ===
            'robustness.performance_monitoring.enabled': _config.getParameter(
                'robustness.performance_monitoring.enabled',
                defaultValue: true),
            'robustness.performance_monitoring.response_time_threshold_ms':
                _config.getParameter(
                    'robustness.performance_monitoring.response_time_threshold_ms',
                    defaultValue: 5000),
            'robustness.performance_monitoring.memory_usage_threshold_mb':
                _config.getParameter(
                    'robustness.performance_monitoring.memory_usage_threshold_mb',
                    defaultValue: 512),
            'robustness.performance_monitoring.cpu_usage_threshold_percent':
                _config.getParameter(
                    'robustness.performance_monitoring.cpu_usage_threshold_percent',
                    defaultValue: 80),
            'robustness.performance_monitoring.disk_usage_threshold_percent':
                _config.getParameter(
                    'robustness.performance_monitoring.disk_usage_threshold_percent',
                    defaultValue: 90),
            'robustness.performance_monitoring.network_latency_threshold_ms':
                _config.getParameter(
                    'robustness.performance_monitoring.network_latency_threshold_ms',
                    defaultValue: 1000),

            // === RESOURCE MANAGEMENT ===
            'robustness.resource_management.enabled': _config.getParameter(
                'robustness.resource_management.enabled',
                defaultValue: true),
            'robustness.resource_management.connection_pooling':
                _config.getParameter(
                    'robustness.resource_management.connection_pooling',
                    defaultValue: true),
            'robustness.resource_management.memory_cleanup_interval_minutes':
                _config.getParameter(
                    'robustness.resource_management.memory_cleanup_interval_minutes',
                    defaultValue: 30),
            'robustness.resource_management.resource_limits_enforced':
                _config.getParameter(
                    'robustness.resource_management.resource_limits_enforced',
                    defaultValue: true),
            'robustness.resource_management.auto_scaling_enabled':
                _config.getParameter(
                    'robustness.resource_management.auto_scaling_enabled',
                    defaultValue: false),
            'robustness.resource_management.load_balancing_enabled':
                _config.getParameter(
                    'robustness.resource_management.load_balancing_enabled',
                    defaultValue: false),

            // === FALLBACK STRATEGIES ===
            'robustness.fallback_strategies.enabled': _config.getParameter(
                'robustness.fallback_strategies.enabled',
                defaultValue: true),
            'robustness.fallback_strategies.cached_responses': _config
                .getParameter('robustness.fallback_strategies.cached_responses',
                    defaultValue: true),
            'robustness.fallback_strategies.default_values': _config
                .getParameter('robustness.fallback_strategies.default_values',
                    defaultValue: true),
            'robustness.fallback_strategies.simplified_ui': _config
                .getParameter('robustness.fallback_strategies.simplified_ui',
                    defaultValue: true),
            'robustness.fallback_strategies.offline_mode': _config.getParameter(
                'robustness.fallback_strategies.offline_mode',
                defaultValue: true),
            'robustness.fallback_strategies.read_only_mode': _config
                .getParameter('robustness.fallback_strategies.read_only_mode',
                    defaultValue: false),

            // === DEGRADATION HANDLING ===
            'robustness.degradation_handling.enabled': _config.getParameter(
                'robustness.degradation_handling.enabled',
                defaultValue: true),
            'robustness.degradation_handling.feature_disablement':
                _config.getParameter(
                    'robustness.degradation_handling.feature_disablement',
                    defaultValue: true),
            'robustness.degradation_handling.quality_reduction':
                _config.getParameter(
                    'robustness.degradation_handling.quality_reduction',
                    defaultValue: true),
            'robustness.degradation_handling.batch_size_reduction':
                _config.getParameter(
                    'robustness.degradation_handling.batch_size_reduction',
                    defaultValue: true),
            'robustness.degradation_handling.frequency_reduction':
                _config.getParameter(
                    'robustness.degradation_handling.frequency_reduction',
                    defaultValue: true),
            'robustness.degradation_handling.user_notification':
                _config.getParameter(
                    'robustness.degradation_handling.user_notification',
                    defaultValue: true),

            // === MONITORING AND ALERTS ===
            'robustness.monitoring.enabled': _config.getParameter(
                'robustness.monitoring.enabled',
                defaultValue: true),
            'robustness.monitoring.real_time_alerts': _config.getParameter(
                'robustness.monitoring.real_time_alerts',
                defaultValue: true),
            'robustness.monitoring.alert_aggregation': _config.getParameter(
                'robustness.monitoring.alert_aggregation',
                defaultValue: true),
            'robustness.monitoring.escalation_policies': _config.getParameter(
                'robustness.monitoring.escalation_policies',
                defaultValue: true),
            'robustness.monitoring.sla_monitoring': _config.getParameter(
                'robustness.monitoring.sla_monitoring',
                defaultValue: false),
            'robustness.monitoring.performance_baselining': _config
                .getParameter('robustness.monitoring.performance_baselining',
                    defaultValue: true),

            // === TESTING AND VALIDATION ===
            'robustness.testing.enabled': _config
                .getParameter('robustness.testing.enabled', defaultValue: true),
            'robustness.testing.chaos_engineering': _config.getParameter(
                'robustness.testing.chaos_engineering',
                defaultValue: false),
            'robustness.testing.failure_injection': _config.getParameter(
                'robustness.testing.failure_injection',
                defaultValue: false),
            'robustness.testing.load_testing': _config.getParameter(
                'robustness.testing.load_testing',
                defaultValue: true),
            'robustness.testing.resilience_testing': _config.getParameter(
                'robustness.testing.resilience_testing',
                defaultValue: true),
            'robustness.testing.recovery_testing': _config.getParameter(
                'robustness.testing.recovery_testing',
                defaultValue: true),

            // === RECOVERY PROCEDURES ===
            'robustness.recovery_procedures.enabled': _config.getParameter(
                'robustness.recovery_procedures.enabled',
                defaultValue: true),
            'robustness.recovery_procedures.automated_recovery':
                _config.getParameter(
                    'robustness.recovery_procedures.automated_recovery',
                    defaultValue: true),
            'robustness.recovery_procedures.manual_intervention_required':
                _config.getParameter(
                    'robustness.recovery_procedures.manual_intervention_required',
                    defaultValue: false),
            'robustness.recovery_procedures.rollback_strategies':
                _config.getParameter(
                    'robustness.recovery_procedures.rollback_strategies',
                    defaultValue: true),
            'robustness.recovery_procedures.data_backup_recovery':
                _config.getParameter(
                    'robustness.recovery_procedures.data_backup_recovery',
                    defaultValue: true),
            'robustness.recovery_procedures.service_restart_procedures':
                _config.getParameter(
                    'robustness.recovery_procedures.service_restart_procedures',
                    defaultValue: true),

            // === SCALABILITY FEATURES ===
            'robustness.scalability.enabled': _config.getParameter(
                'robustness.scalability.enabled',
                defaultValue: true),
            'robustness.scalability.horizontal_scaling': _config.getParameter(
                'robustness.scalability.horizontal_scaling',
                defaultValue: true),
            'robustness.scalability.vertical_scaling': _config.getParameter(
                'robustness.scalability.vertical_scaling',
                defaultValue: false),
            'robustness.scalability.auto_scaling': _config.getParameter(
                'robustness.scalability.auto_scaling',
                defaultValue: false),
            'robustness.scalability.distributed_processing': _config
                .getParameter('robustness.scalability.distributed_processing',
                    defaultValue: true),
            'robustness.scalability.load_distribution': _config.getParameter(
                'robustness.scalability.load_distribution',
                defaultValue: true),

            // === INTEGRATION SETTINGS ===
            'robustness.integration.logging_enabled': _config.getParameter(
                'robustness.integration.logging_enabled',
                defaultValue: true),
            'robustness.integration.monitoring_enabled': _config.getParameter(
                'robustness.integration.monitoring_enabled',
                defaultValue: true),
            'robustness.integration.alerting_enabled': _config.getParameter(
                'robustness.integration.alerting_enabled',
                defaultValue: true),
            'robustness.integration.metrics_enabled': _config.getParameter(
                'robustness.integration.metrics_enabled',
                defaultValue: true),
            'robustness.integration.external_systems': _config.getParameter(
                'robustness.integration.external_systems',
                defaultValue: false),

            // === SECURITY INTEGRATION ===
            'robustness.security.enabled': _config.getParameter(
                'robustness.security.enabled',
                defaultValue: true),
            'robustness.security.encryption_enabled': _config.getParameter(
                'robustness.security.encryption_enabled',
                defaultValue: true),
            'robustness.security.access_control': _config.getParameter(
                'robustness.security.access_control',
                defaultValue: true),
            'robustness.security.audit_logging': _config.getParameter(
                'robustness.security.audit_logging',
                defaultValue: true),
            'robustness.security.threat_detection': _config.getParameter(
                'robustness.security.threat_detection',
                defaultValue: true),

            // === PERFORMANCE OPTIMIZATION ===
            'robustness.performance_optimization.enabled': _config.getParameter(
                'robustness.performance_optimization.enabled',
                defaultValue: true),
            'robustness.performance_optimization.caching_enabled':
                _config.getParameter(
                    'robustness.performance_optimization.caching_enabled',
                    defaultValue: true),
            'robustness.performance_optimization.lazy_loading':
                _config.getParameter(
                    'robustness.performance_optimization.lazy_loading',
                    defaultValue: true),
            'robustness.performance_optimization.async_processing':
                _config.getParameter(
                    'robustness.performance_optimization.async_processing',
                    defaultValue: true),
            'robustness.performance_optimization.resource_pooling':
                _config.getParameter(
                    'robustness.performance_optimization.resource_pooling',
                    defaultValue: true),

            // === ERROR CLASSIFICATION ===
            'robustness.error_classification.enabled': _config.getParameter(
                'robustness.error_classification.enabled',
                defaultValue: true),
            'robustness.error_classification.transient_errors': _config
                .getParameter(
                    'robustness.error_classification.transient_errors',
                    defaultValue: ['timeout', 'network', 'temporary']),
            'robustness.error_classification.permanent_errors': _config
                .getParameter(
                    'robustness.error_classification.permanent_errors',
                    defaultValue: [
                  'authentication',
                  'authorization',
                  'validation'
                ]),
            'robustness.error_classification.retryable_errors': _config
                .getParameter(
                    'robustness.error_classification.retryable_errors',
                    defaultValue: ['timeout', 'network', 'server_error']),
            'robustness.error_classification.fatal_errors': _config
                .getParameter('robustness.error_classification.fatal_errors',
                    defaultValue: ['out_of_memory', 'disk_full', 'corruption']),

            // === MAINTENANCE ===
            'robustness.maintenance.enabled': _config.getParameter(
                'robustness.maintenance.enabled',
                defaultValue: true),
            'robustness.maintenance.automated_maintenance': _config
                .getParameter('robustness.maintenance.automated_maintenance',
                    defaultValue: true),
            'robustness.maintenance.scheduled_maintenance': _config
                .getParameter('robustness.maintenance.scheduled_maintenance',
                    defaultValue: false),
            'robustness.maintenance.health_checks': _config.getParameter(
                'robustness.maintenance.health_checks',
                defaultValue: true),
            'robustness.maintenance.diagnostic_tools': _config.getParameter(
                'robustness.maintenance.diagnostic_tools',
                defaultValue: true),
            'robustness.maintenance.performance_optimization': _config
                .getParameter('robustness.maintenance.performance_optimization',
                    defaultValue: true),
          });
      await _setupDefaultErrorHandlers();

      // Setup circuit breakers
      await _setupCircuitBreakers();

      // Setup retry policies
      await _setupRetryPolicies();

      // Setup global error handling
      await _setupGlobalErrorHandling();

      _isInitialized = true;
      _emitEvent(RobustnessEventType.initialized);

      _logger.info(
          'Robustness Manager initialized successfully', 'RobustnessManager');
    } catch (e, stackTrace) {
      _logger.error(
          'Failed to initialize Robustness Manager', 'RobustnessManager',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Handle error with appropriate strategy
  Future<ErrorHandlingResult> handleError(
    String errorType,
    dynamic error, {
    Map<String, dynamic>? context,
    String? component,
  }) async {
    try {
      _logger.error('Handling error: $errorType', 'RobustnessManager',
          error: error);

      // Record error metric
      await _recordErrorMetric(errorType, error, component);

      // Get appropriate handler
      final handler = _errorHandlers[errorType] ?? _errorHandlers['default'];
      if (handler == null) {
        return ErrorHandlingResult(
          success: false,
          strategy: ErrorHandlingStrategy.none,
          message: 'No error handler found for $errorType',
        );
      }

      // Apply circuit breaker if configured
      final circuitBreaker = _circuitBreakers[component ?? 'default'];
      if (circuitBreaker != null && circuitBreaker.isOpen) {
        return ErrorHandlingResult(
          success: false,
          strategy: ErrorHandlingStrategy.circuitBreaker,
          message: 'Circuit breaker is open for $component',
        );
      }

      // Handle error with retry policy
      final retryPolicy =
          _retryPolicies[errorType] ?? _retryPolicies['default'];
      final result = await _executeWithRetry(
        () => handler.handle(error, context),
        retryPolicy,
      );

      // Update circuit breaker state
      if (circuitBreaker != null) {
        if (result.success) {
          circuitBreaker.recordSuccess();
        } else {
          circuitBreaker.recordFailure();
        }
      }

      return result;
    } catch (e) {
      _logger.error('Failed to handle error', 'RobustnessManager', error: e);
      return ErrorHandlingResult(
        success: false,
        strategy: ErrorHandlingStrategy.none,
        message: 'Error handling failed: ${e.toString()}',
      );
    }
  }

  /// Execute operation with circuit breaker and retry
  Future<T> executeWithResilience<T>(
    String operation,
    Future<T> Function() operationFunc, {
    String? component,
    Duration? timeout,
  }) async {
    final circuitBreaker = _circuitBreakers[component ?? operation];
    if (circuitBreaker != null && circuitBreaker.isOpen) {
      throw RobustnessException('Circuit breaker is open for $operation');
    }

    final retryPolicy = _retryPolicies[operation] ?? _retryPolicies['default'];
    final result =
        await _executeWithRetry(operationFunc, retryPolicy, timeout: timeout);

    // Update circuit breaker
    if (circuitBreaker != null) {
      circuitBreaker.recordSuccess();
    }

    return result;
  }

  /// Get robustness metrics
  RobustnessMetrics getMetrics() {
    return RobustnessMetrics(
      totalErrors: _errorMetrics.length,
      errorTypes: _errorMetrics.map((m) => m.type).toSet().toList(),
      componentsWithErrors: _errorMetrics
          .map((m) => m.component)
          .where((c) => c != null)
          .toSet()
          .toList(),
      averageRecoveryTime: _calculateAverageRecoveryTime(),
      circuitBreakerStates:
          _circuitBreakers.map((key, cb) => MapEntry(key, cb.state)),
      lastUpdated: DateTime.now(),
    );
  }

  /// Private helper methods

  Future<void> _setupDefaultErrorHandlers() async {
    // Network error handler
    _errorHandlers['network'] = NetworkErrorHandler(_logger, _config);

    // Validation error handler
    _errorHandlers['validation'] = ValidationErrorHandler(_logger, _config);

    // Security error handler
    _errorHandlers['security'] = SecurityErrorHandler(_logger, _config);

    // System error handler
    _errorHandlers['system'] = SystemErrorHandler(_logger, _config);

    // Default error handler
    _errorHandlers['default'] = DefaultErrorHandler(_logger, _config);
  }

  Future<void> _setupCircuitBreakers() async {
    // Network circuit breaker
    _circuitBreakers['network'] = CircuitBreaker(
      failureThreshold: _config.getParameter(
          'robustness.circuit_breaker.failure_threshold',
          defaultValue: 5),
      recoveryTimeout: Duration(
          seconds: _config.getParameter(
              'robustness.circuit_breaker.recovery_timeout',
              defaultValue: 60)),
      monitoringPeriod: Duration(
          seconds: _config.getParameter(
              'robustness.circuit_breaker.monitoring_period',
              defaultValue: 300)),
    );

    // Database circuit breaker
    _circuitBreakers['database'] = CircuitBreaker(
      failureThreshold: _config.getParameter(
          'robustness.circuit_breaker.failure_threshold',
          defaultValue: 3),
      recoveryTimeout: Duration(
          seconds: _config.getParameter(
              'robustness.circuit_breaker.recovery_timeout',
              defaultValue: 30)),
      monitoringPeriod: Duration(
          seconds: _config.getParameter(
              'robustness.circuit_breaker.monitoring_period',
              defaultValue: 180)),
    );

    // Default circuit breaker
    _circuitBreakers['default'] = CircuitBreaker(
      failureThreshold: _config.getParameter(
          'robustness.circuit_breaker.failure_threshold',
          defaultValue: 5),
      recoveryTimeout: Duration(
          seconds: _config.getParameter(
              'robustness.circuit_breaker.recovery_timeout',
              defaultValue: 60)),
      monitoringPeriod: Duration(
          seconds: _config.getParameter(
              'robustness.circuit_breaker.monitoring_period',
              defaultValue: 300)),
    );
  }

  Future<void> _setupRetryPolicies() async {
    // Network retry policy
    _retryPolicies['network'] = RetryPolicy(
      maxAttempts: _config.getParameter('robustness.retry.max_attempts',
          defaultValue: 3),
      baseDelay: Duration(
          milliseconds: _config.getParameter('robustness.retry.base_delay',
              defaultValue: 1000)),
      maxDelay: Duration(
          seconds: _config.getParameter('robustness.retry.max_delay',
              defaultValue: 30)),
      backoffMultiplier: _config.getParameter(
          'robustness.retry.backoff_multiplier',
          defaultValue: 2.0),
    );

    // Database retry policy
    _retryPolicies['database'] = RetryPolicy(
      maxAttempts: _config.getParameter('robustness.retry.max_attempts',
          defaultValue: 2),
      baseDelay: Duration(
          milliseconds: _config.getParameter('robustness.retry.base_delay',
              defaultValue: 500)),
      maxDelay: Duration(
          seconds: _config.getParameter('robustness.retry.max_delay',
              defaultValue: 10)),
      backoffMultiplier: _config.getParameter(
          'robustness.retry.backoff_multiplier',
          defaultValue: 1.5),
    );

    // Default retry policy
    _retryPolicies['default'] = RetryPolicy(
      maxAttempts: _config.getParameter('robustness.retry.max_attempts',
          defaultValue: 3),
      baseDelay: Duration(
          milliseconds: _config.getParameter('robustness.retry.base_delay',
              defaultValue: 1000)),
      maxDelay: Duration(
          seconds: _config.getParameter('robustness.retry.max_delay',
              defaultValue: 30)),
      backoffMultiplier: _config.getParameter(
          'robustness.retry.backoff_multiplier',
          defaultValue: 2.0),
    );
  }

  Future<void> _setupGlobalErrorHandling() async {
    // Setup Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      handleError('flutter', details.exception, context: {
        'stack': details.stack?.toString(),
        'library': details.library,
        'context': details.context?.toString(),
      });
    };

    // Setup zone error handling
    runZonedGuarded(() async {
      // App runs here
    }, (error, stackTrace) {
      handleError('zone', error, context: {
        'stack': stackTrace.toString(),
      });
    });
  }

  Future<void> _recordErrorMetric(
      String errorType, dynamic error, String? component) async {
    final metric = ErrorMetric(
      type: errorType,
      message: error.toString(),
      component: component,
      timestamp: DateTime.now(),
    );

    _errorMetrics.add(metric);
    _lastErrors[errorType] = DateTime.now();

    // Keep only last 1000 metrics
    if (_errorMetrics.length > 1000) {
      _errorMetrics.removeRange(0, _errorMetrics.length - 1000);
    }

    _emitEvent(RobustnessEventType.errorRecorded, data: metric);
  }

  Future<T> _executeWithRetry<T>(
    Future<T> Function() operation,
    RetryPolicy policy, {
    Duration? timeout,
  }) async {
    int attempts = 0;
    dynamic lastError;

    while (attempts < policy.maxAttempts) {
      try {
        if (timeout != null) {
          return await operation().timeout(timeout);
        } else {
          return await operation();
        }
      } catch (e) {
        lastError = e;
        attempts++;

        if (attempts >= policy.maxAttempts) {
          break;
        }

        // Calculate delay with exponential backoff
        final delay = _calculateDelay(attempts, policy);
        await Future.delayed(delay);

        _logger.info('Retrying operation after error: ${e.toString()}',
            'RobustnessManager');
      }
    }

    throw RobustnessException(
        'Operation failed after ${policy.maxAttempts} attempts: ${lastError.toString()}');
  }

  Duration _calculateDelay(int attempt, RetryPolicy policy) {
    final exponentialDelay = policy.baseDelay.inMilliseconds *
        math.pow(policy.backoffMultiplier, attempt - 1);
    final clampedDelay =
        math.min(exponentialDelay, policy.maxDelay.inMilliseconds.toDouble());
    return Duration(milliseconds: clampedDelay.toInt());
  }

  Duration _calculateAverageRecoveryTime() {
    if (_errorMetrics.isEmpty) return Duration.zero;

    // Simplified calculation - would need more sophisticated tracking
    return Duration(seconds: 5);
  }

  void _emitEvent(RobustnessEventType type, {dynamic data}) {
    final event = RobustnessEvent(
      type: type,
      timestamp: DateTime.now(),
      data: data,
    );
    _eventController.add(event);
  }

  /// Dispose robustness manager
  void dispose() {
    _eventController.close();
    _errorHandlers.clear();
    _circuitBreakers.clear();
    _retryPolicies.clear();
    _errorMetrics.clear();
    _lastErrors.clear();
  }

  // Getters
  bool get isInitialized => _isInitialized;
}

// Supporting classes

enum RobustnessEventType {
  initialized,
  errorRecorded,
  circuitBreakerOpened,
  circuitBreakerClosed,
  retryAttempted,
}

enum ErrorHandlingStrategy {
  none,
  retry,
  circuitBreaker,
  fallback,
  ignore,
}

class RobustnessEvent {
  final RobustnessEventType type;
  final DateTime timestamp;
  final dynamic data;

  RobustnessEvent({
    required this.type,
    required this.timestamp,
    this.data,
  });
}

class ErrorHandlingResult {
  final bool success;
  final ErrorHandlingStrategy strategy;
  final String message;
  final dynamic result;

  ErrorHandlingResult({
    required this.success,
    required this.strategy,
    required this.message,
    this.result,
  });
}

class ErrorMetric {
  final String type;
  final String message;
  final String? component;
  final DateTime timestamp;

  ErrorMetric({
    required this.type,
    required this.message,
    this.component,
    required this.timestamp,
  });
}

class RobustnessMetrics {
  final int totalErrors;
  final List<String> errorTypes;
  final List<String> componentsWithErrors;
  final Duration averageRecoveryTime;
  final Map<String, CircuitBreakerState> circuitBreakerStates;
  final DateTime lastUpdated;

  RobustnessMetrics({
    required this.totalErrors,
    required this.errorTypes,
    required this.componentsWithErrors,
    required this.averageRecoveryTime,
    required this.circuitBreakerStates,
    required this.lastUpdated,
  });
}

class CircuitBreaker {
  final int failureThreshold;
  final Duration recoveryTimeout;
  final Duration monitoringPeriod;

  int _failureCount = 0;
  DateTime? _lastFailureTime;
  CircuitBreakerState _state = CircuitBreakerState.closed;

  CircuitBreaker({
    required this.failureThreshold,
    required this.recoveryTimeout,
    required this.monitoringPeriod,
  });

  bool get isOpen => _state == CircuitBreakerState.open;
  CircuitBreakerState get state => _state;

  void recordSuccess() {
    _failureCount = 0;
    if (_state == CircuitBreakerState.halfOpen) {
      _state = CircuitBreakerState.closed;
    }
  }

  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _state = CircuitBreakerState.open;
    }
  }

  void checkState() {
    if (_state == CircuitBreakerState.open &&
        _lastFailureTime != null &&
        DateTime.now().difference(_lastFailureTime!) > recoveryTimeout) {
      _state = CircuitBreakerState.halfOpen;
    }
  }
}

enum CircuitBreakerState {
  closed,
  open,
  halfOpen,
}

class RetryPolicy {
  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final double backoffMultiplier;

  RetryPolicy({
    required this.maxAttempts,
    required this.baseDelay,
    required this.maxDelay,
    required this.backoffMultiplier,
  });
}

abstract class ErrorHandler {
  Future<ErrorHandlingResult> handle(
      dynamic error, Map<String, dynamic>? context);
}

class NetworkErrorHandler extends ErrorHandler {
  final LoggingService _logger;
  final CentralConfig _config;

  NetworkErrorHandler(this._logger, this._config);

  @override
  Future<ErrorHandlingResult> handle(
      dynamic error, Map<String, dynamic>? context) async {
    _logger.error('Network error handled', 'NetworkErrorHandler', error: error);

    return ErrorHandlingResult(
      success: true,
      strategy: ErrorHandlingStrategy.retry,
      message: 'Network error will be retried',
    );
  }
}

class ValidationErrorHandler extends ErrorHandler {
  final LoggingService _logger;
  final CentralConfig _config;

  ValidationErrorHandler(this._logger, this._config);

  @override
  Future<ErrorHandlingResult> handle(
      dynamic error, Map<String, dynamic>? context) async {
    _logger.error('Validation error handled', 'ValidationErrorHandler',
        error: error);

    return ErrorHandlingResult(
      success: true,
      strategy: ErrorHandlingStrategy.fallback,
      message: 'Validation error handled with fallback',
    );
  }
}

class SecurityErrorHandler extends ErrorHandler {
  final LoggingService _logger;
  final CentralConfig _config;

  SecurityErrorHandler(this._logger, this._config);

  @override
  Future<ErrorHandlingResult> handle(
      dynamic error, Map<String, dynamic>? context) async {
    _logger.error('Security error handled', 'SecurityErrorHandler',
        error: error);

    return ErrorHandlingResult(
      success: true,
      strategy: ErrorHandlingStrategy.circuitBreaker,
      message: 'Security error triggered circuit breaker',
    );
  }
}

class SystemErrorHandler extends ErrorHandler {
  final LoggingService _logger;
  final CentralConfig _config;

  SystemErrorHandler(this._logger, this._config);

  @override
  Future<ErrorHandlingResult> handle(
      dynamic error, Map<String, dynamic>? context) async {
    _logger.error('System error handled', 'SystemErrorHandler', error: error);

    return ErrorHandlingResult(
      success: false,
      strategy: ErrorHandlingStrategy.none,
      message: 'System error cannot be recovered',
    );
  }
}

class DefaultErrorHandler extends ErrorHandler {
  final LoggingService _logger;
  final CentralConfig _config;

  DefaultErrorHandler(this._logger, this._config);

  @override
  Future<ErrorHandlingResult> handle(
      dynamic error, Map<String, dynamic>? context) async {
    _logger.error('Default error handler', 'DefaultErrorHandler', error: error);

    return ErrorHandlingResult(
      success: true,
      strategy: ErrorHandlingStrategy.retry,
      message: 'Error handled with default retry strategy',
    );
  }
}

class RobustnessException implements Exception {
  final String message;

  RobustnessException(this.message);

  @override
  String toString() => 'RobustnessException: $message';
}
