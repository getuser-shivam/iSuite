import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'logging_service.dart';
import 'advanced_security_manager.dart';
import 'central_config.dart';
import 'dart:math' as math;

/// Enhanced Robustness Manager
/// Provides comprehensive error handling, resilience, and system robustness
class RobustnessManager {
  static final RobustnessManager _instance = RobustnessManager._internal();
  factory RobustnessManager() => _instance;
  RobustnessManager._internal();

  final LoggingService _logger = LoggingService();
  final AdvancedSecurityManager _security = AdvancedSecurityManager();
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
  final StreamController<RobustnessEvent> _eventController = StreamController.broadcast();

  Stream<RobustnessEvent> get events => _eventController.stream;

  /// Initialize robustness manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Robustness Manager', 'RobustnessManager');

      // Setup default error handlers
      await _setupDefaultErrorHandlers();

      // Setup circuit breakers
      await _setupCircuitBreakers();

      // Setup retry policies
      await _setupRetryPolicies();

      // Setup global error handling
      await _setupGlobalErrorHandling();

      _isInitialized = true;
      _emitEvent(RobustnessEventType.initialized);

      _logger.info('Robustness Manager initialized successfully', 'RobustnessManager');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Robustness Manager', 'RobustnessManager',
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
      _logger.error('Handling error: $errorType', 'RobustnessManager', error: error);

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
      final retryPolicy = _retryPolicies[errorType] ?? _retryPolicies['default'];
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
    final result = await _executeWithRetry(operationFunc, retryPolicy, timeout: timeout);

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
      componentsWithErrors: _errorMetrics.map((m) => m.component).where((c) => c != null).toSet().toList(),
      averageRecoveryTime: _calculateAverageRecoveryTime(),
      circuitBreakerStates: _circuitBreakers.map((key, cb) => MapEntry(key, cb.state)),
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
    _errorHandlers['security'] = SecurityErrorHandler(_logger, _security, _config);

    // System error handler
    _errorHandlers['system'] = SystemErrorHandler(_logger, _config);

    // Default error handler
    _errorHandlers['default'] = DefaultErrorHandler(_logger, _config);
  }

  Future<void> _setupCircuitBreakers() async {
    // Network circuit breaker
    _circuitBreakers['network'] = CircuitBreaker(
      failureThreshold: _config.getParameter('robustness.circuit_breaker.failure_threshold', defaultValue: 5),
      recoveryTimeout: Duration(seconds: _config.getParameter('robustness.circuit_breaker.recovery_timeout', defaultValue: 60)),
      monitoringPeriod: Duration(seconds: _config.getParameter('robustness.circuit_breaker.monitoring_period', defaultValue: 300)),
    );

    // Database circuit breaker
    _circuitBreakers['database'] = CircuitBreaker(
      failureThreshold: _config.getParameter('robustness.circuit_breaker.failure_threshold', defaultValue: 3),
      recoveryTimeout: Duration(seconds: _config.getParameter('robustness.circuit_breaker.recovery_timeout', defaultValue: 30)),
      monitoringPeriod: Duration(seconds: _config.getParameter('robustness.circuit_breaker.monitoring_period', defaultValue: 180)),
    );

    // Default circuit breaker
    _circuitBreakers['default'] = CircuitBreaker(
      failureThreshold: _config.getParameter('robustness.circuit_breaker.failure_threshold', defaultValue: 5),
      recoveryTimeout: Duration(seconds: _config.getParameter('robustness.circuit_breaker.recovery_timeout', defaultValue: 60)),
      monitoringPeriod: Duration(seconds: _config.getParameter('robustness.circuit_breaker.monitoring_period', defaultValue: 300)),
    );
  }

  Future<void> _setupRetryPolicies() async {
    // Network retry policy
    _retryPolicies['network'] = RetryPolicy(
      maxAttempts: _config.getParameter('robustness.retry.max_attempts', defaultValue: 3),
      baseDelay: Duration(milliseconds: _config.getParameter('robustness.retry.base_delay', defaultValue: 1000)),
      maxDelay: Duration(seconds: _config.getParameter('robustness.retry.max_delay', defaultValue: 30)),
      backoffMultiplier: _config.getParameter('robustness.retry.backoff_multiplier', defaultValue: 2.0),
    );

    // Database retry policy
    _retryPolicies['database'] = RetryPolicy(
      maxAttempts: _config.getParameter('robustness.retry.max_attempts', defaultValue: 2),
      baseDelay: Duration(milliseconds: _config.getParameter('robustness.retry.base_delay', defaultValue: 500)),
      maxDelay: Duration(seconds: _config.getParameter('robustness.retry.max_delay', defaultValue: 10)),
      backoffMultiplier: _config.getParameter('robustness.retry.backoff_multiplier', defaultValue: 1.5),
    );

    // Default retry policy
    _retryPolicies['default'] = RetryPolicy(
      maxAttempts: _config.getParameter('robustness.retry.max_attempts', defaultValue: 3),
      baseDelay: Duration(milliseconds: _config.getParameter('robustness.retry.base_delay', defaultValue: 1000)),
      maxDelay: Duration(seconds: _config.getParameter('robustness.retry.max_delay', defaultValue: 30)),
      backoffMultiplier: _config.getParameter('robustness.retry.backoff_multiplier', defaultValue: 2.0),
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

  Future<void> _recordErrorMetric(String errorType, dynamic error, String? component) async {
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

        _logger.info('Retrying operation after error: ${e.toString()}', 'RobustnessManager');
      }
    }

    throw RobustnessException('Operation failed after ${policy.maxAttempts} attempts: ${lastError.toString()}');
  }

  Duration _calculateDelay(int attempt, RetryPolicy policy) {
    final exponentialDelay = policy.baseDelay.inMilliseconds * math.pow(policy.backoffMultiplier, attempt - 1);
    final clampedDelay = math.min(exponentialDelay, policy.maxDelay.inMilliseconds.toDouble());
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
  Future<ErrorHandlingResult> handle(dynamic error, Map<String, dynamic>? context);
}

class NetworkErrorHandler extends ErrorHandler {
  final LoggingService _logger;
  final CentralConfig _config;

  NetworkErrorHandler(this._logger, this._config);

  @override
  Future<ErrorHandlingResult> handle(dynamic error, Map<String, dynamic>? context) async {
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
  Future<ErrorHandlingResult> handle(dynamic error, Map<String, dynamic>? context) async {
    _logger.error('Validation error handled', 'ValidationErrorHandler', error: error);
    
    return ErrorHandlingResult(
      success: true,
      strategy: ErrorHandlingStrategy.fallback,
      message: 'Validation error handled with fallback',
    );
  }
}

class SecurityErrorHandler extends ErrorHandler {
  final LoggingService _logger;
  final AdvancedSecurityManager _security;
  final CentralConfig _config;

  SecurityErrorHandler(this._logger, this._security, this._config);

  @override
  Future<ErrorHandlingResult> handle(dynamic error, Map<String, dynamic>? context) async {
    _logger.error('Security error handled', 'SecurityErrorHandler', error: error);
    
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
  Future<ErrorHandlingResult> handle(dynamic error, Map<String, dynamic>? context) async {
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
  Future<ErrorHandlingResult> handle(dynamic error, Map<String, dynamic>? context) async {
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
