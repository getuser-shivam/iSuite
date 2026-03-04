import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../core/logging/logging_service.dart';
import '../../core/config/central_config.dart';

/// Circuit Breaker Service for fault tolerance and resilience
///
/// Implements circuit breaker pattern to prevent cascade failures and provide graceful degradation:
/// - Automatic failure detection and recovery
/// - Configurable failure thresholds and timeouts
/// - Exponential backoff for recovery attempts
/// - Service health monitoring and reporting
/// - Graceful degradation strategies
class CircuitBreakerService {
  static final CircuitBreakerService _instance =
      CircuitBreakerService._internal();
  factory CircuitBreakerService() => _instance;
  CircuitBreakerService._internal();

  final LoggingService _logger = LoggingService();
  final CentralConfig _config = CentralConfig.instance;

  final Map<String, CircuitBreaker> _circuitBreakers = {};
  final Map<String, ServiceHealthMonitor> _healthMonitors = {};
  final StreamController<CircuitBreakerEvent> _eventController =
      StreamController.broadcast();

  bool _isInitialized = false;
  Timer? _monitoringTimer;

  /// Initialize the circuit breaker service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Circuit Breaker Service', 'CircuitBreaker');

      // Register with CentralConfig
      await _config.registerComponent('CircuitBreakerService', '1.0.0',
          'Enterprise circuit breaker service for fault tolerance and resilience',
          dependencies: [
            'CentralConfig',
            'LoggingService'
          ],
          parameters: {
            // Circuit breaker settings
            'circuit_breaker.enabled': true,
            'circuit_breaker.failure_threshold': 5,
            'circuit_breaker.recovery_timeout_seconds': 60,
            'circuit_breaker.monitoring_interval_seconds': 30,
            'circuit_breaker.success_threshold': 3,
            'circuit_breaker.timeout_seconds': 30,

            // Health monitoring settings
            'health_monitoring.enabled': true,
            'health_monitoring.check_interval_seconds': 60,
            'health_monitoring.failure_threshold': 3,
            'health_monitoring.recovery_threshold': 2,

            // Resilience settings
            'resilience.retry_enabled': true,
            'resilience.max_retry_attempts': 3,
            'resilience.retry_delay_base_ms': 1000,
            'resilience.exponential_backoff': true,
            'resilience.jitter_enabled': true,
          });

      // Start monitoring
      _startMonitoring();

      _isInitialized = true;
      _logger.info(
          'Circuit Breaker Service initialized successfully', 'CircuitBreaker');
    } catch (e, stackTrace) {
      _logger.error(
          'Failed to initialize Circuit Breaker Service', 'CircuitBreaker',
          error: e, stackTrace: stackTrace);
      // Continue with limited functionality
      _isInitialized = true;
    }
  }

  /// Execute operation with circuit breaker protection
  Future<T> execute<T>({
    required String serviceName,
    required Future<T> Function() operation,
    Duration? timeout,
    int? maxRetries,
    bool enableCircuitBreaker = true,
  }) async {
    if (!_isInitialized) await initialize();

    final breaker =
        enableCircuitBreaker ? _getOrCreateBreaker(serviceName) : null;

    // Check circuit breaker state
    if (breaker?.state == CircuitBreakerState.open) {
      if (!breaker!.canAttemptReset()) {
        _logger.warning(
            'Circuit breaker OPEN for $serviceName, rejecting request',
            'CircuitBreaker');
        throw CircuitBreakerException(
            'Service $serviceName is currently unavailable (circuit breaker open)');
      }
    }

    final effectiveTimeout = timeout ??
        Duration(
            seconds: _config.getParameter('circuit_breaker.timeout_seconds',
                defaultValue: 30));
    final effectiveMaxRetries = maxRetries ??
        _config.getParameter('resilience.max_retry_attempts', defaultValue: 3);

    Exception? lastException;

    for (int attempt = 0; attempt <= effectiveMaxRetries; attempt++) {
      try {
        // Execute with timeout
        final result = await operation().timeout(effectiveTimeout);

        // Success - record and return
        breaker?.recordSuccess();
        _updateHealthMonitor(serviceName, true);

        if (attempt > 0) {
          _logger.info(
              'Operation succeeded on attempt ${attempt + 1} for $serviceName',
              'CircuitBreaker');
        }

        return result;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        _logger.warning(
            'Operation failed on attempt ${attempt + 1} for $serviceName: ${e.toString()}',
            'CircuitBreaker');

        // Record failure
        breaker?.recordFailure();
        _updateHealthMonitor(serviceName, false);

        // Check if we should retry
        if (attempt >= effectiveMaxRetries || !_isRetryableError(e)) {
          break;
        }

        // Wait before retry with exponential backoff
        if (attempt < effectiveMaxRetries) {
          final delay = _calculateRetryDelay(attempt);
          await Future.delayed(delay);
        }
      }
    }

    // All attempts failed
    _emitEvent(CircuitBreakerEventType.operationFailed,
        serviceName: serviceName, error: lastException.toString());
    throw lastException ??
        Exception('Operation failed after all retry attempts');
  }

  /// Create a circuit breaker for a service
  CircuitBreaker createBreaker(
    String serviceName, {
    int? failureThreshold,
    Duration? recoveryTimeout,
    int? successThreshold,
  }) {
    final breaker = CircuitBreaker(
      serviceName: serviceName,
      failureThreshold: failureThreshold ??
          _config.getParameter('circuit_breaker.failure_threshold',
              defaultValue: 5),
      recoveryTimeout: recoveryTimeout ??
          Duration(
              seconds: _config.getParameter(
                  'circuit_breaker.recovery_timeout_seconds',
                  defaultValue: 60)),
      successThreshold: successThreshold ??
          _config.getParameter('circuit_breaker.success_threshold',
              defaultValue: 3),
    );

    _circuitBreakers[serviceName] = breaker;
    _logger.info('Created circuit breaker for $serviceName', 'CircuitBreaker');

    return breaker;
  }

  /// Get circuit breaker for a service (creates if doesn't exist)
  CircuitBreaker _getOrCreateBreaker(String serviceName) {
    return _circuitBreakers.putIfAbsent(
        serviceName, () => createBreaker(serviceName));
  }

  /// Get circuit breaker state
  CircuitBreakerState? getBreakerState(String serviceName) {
    return _circuitBreakers[serviceName]?.state;
  }

  /// Force reset a circuit breaker
  void resetBreaker(String serviceName) {
    final breaker = _circuitBreakers[serviceName];
    if (breaker != null) {
      breaker.reset();
      _emitEvent(CircuitBreakerEventType.breakerReset,
          serviceName: serviceName);
      _logger.info('Circuit breaker reset for $serviceName', 'CircuitBreaker');
    }
  }

  /// Get health status for all services
  Map<String, ServiceHealthStatus> getHealthStatus() {
    final status = <String, ServiceHealthStatus>{};

    for (final entry in _circuitBreakers.entries) {
      final serviceName = entry.key;
      final breaker = entry.value;
      final monitor = _healthMonitors[serviceName];

      status[serviceName] = ServiceHealthStatus(
        serviceName: serviceName,
        circuitBreakerState: breaker.state,
        consecutiveFailures: breaker.consecutiveFailures,
        lastFailureTime: breaker.lastFailureTime,
        lastSuccessTime: breaker.lastSuccessTime,
        healthScore: monitor?.healthScore ?? 1.0,
        isHealthy: _isServiceHealthy(serviceName),
      );
    }

    return status;
  }

  /// Check if a service is healthy
  bool isServiceHealthy(String serviceName) {
    return _isServiceHealthy(serviceName);
  }

  bool _isServiceHealthy(String serviceName) {
    final breaker = _circuitBreakers[serviceName];
    final monitor = _healthMonitors[serviceName];

    if (breaker?.state == CircuitBreakerState.open) {
      return false;
    }

    if (monitor != null && monitor.healthScore < 0.5) {
      return false;
    }

    return true;
  }

  /// Enable graceful degradation for a service
  void enableGracefulDegradation(
      String serviceName, Function() fallbackOperation) {
    final breaker = _getOrCreateBreaker(serviceName);
    breaker.gracefulDegradationEnabled = true;
    breaker.fallbackOperation = fallbackOperation;
    _logger.info(
        'Enabled graceful degradation for $serviceName', 'CircuitBreaker');
  }

  /// Bulk health check for all monitored services
  Future<Map<String, bool>> performBulkHealthCheck() async {
    final results = <String, bool>{};

    for (final serviceName in _circuitBreakers.keys) {
      try {
        // Perform a simple health check (this would be service-specific in real implementation)
        results[serviceName] = _isServiceHealthy(serviceName);
      } catch (e) {
        results[serviceName] = false;
        _logger.warning('Health check failed for $serviceName: ${e.toString()}',
            'CircuitBreaker');
      }
    }

    _logger.info('Bulk health check completed for ${results.length} services',
        'CircuitBreaker');
    return results;
  }

  // Private methods

  void _startMonitoring() {
    final monitoringEnabled =
        _config.getParameter('circuit_breaker.enabled', defaultValue: true);
    if (!monitoringEnabled) return;

    final interval = Duration(
        seconds: _config.getParameter(
            'circuit_breaker.monitoring_interval_seconds',
            defaultValue: 30));

    _monitoringTimer = Timer.periodic(interval, (timer) {
      _performMonitoring();
    });

    _logger.info('Circuit breaker monitoring started', 'CircuitBreaker');
  }

  void _performMonitoring() {
    try {
      // Check for breakers that can attempt reset
      for (final entry in _circuitBreakers.entries) {
        final breaker = entry.value;
        if (breaker.state == CircuitBreakerState.open &&
            breaker.canAttemptReset()) {
          _emitEvent(CircuitBreakerEventType.attemptingReset,
              serviceName: entry.key);
        }
      }

      // Update health monitors
      for (final monitor in _healthMonitors.values) {
        monitor.updateHealthScore();
      }
    } catch (e) {
      _logger.error('Monitoring cycle failed', 'CircuitBreaker', error: e);
    }
  }

  void _updateHealthMonitor(String serviceName, bool success) {
    final monitor = _healthMonitors.putIfAbsent(
        serviceName, () => ServiceHealthMonitor(serviceName));
    monitor.recordResult(success);
  }

  Duration _calculateRetryDelay(int attempt) {
    final baseDelay = _config.getParameter('resilience.retry_delay_base_ms',
        defaultValue: 1000);
    final exponentialBackoff = _config
        .getParameter('resilience.exponential_backoff', defaultValue: true);
    final jitterEnabled =
        _config.getParameter('resilience.jitter_enabled', defaultValue: true);

    double delay = baseDelay.toDouble();

    if (exponentialBackoff) {
      delay = baseDelay * pow(2, attempt).toDouble();
    }

    // Add jitter to prevent thundering herd
    if (jitterEnabled) {
      final jitter = Random().nextDouble() * 0.1 * delay; // ±10% jitter
      delay += jitter - (delay * 0.05); // Center the jitter
    }

    // Cap at reasonable maximum
    delay = min(delay, 30000); // Max 30 seconds

    return Duration(milliseconds: delay.toInt());
  }

  bool _isRetryableError(dynamic error) {
    if (error is CircuitBreakerException) return false;

    final errorString = error.toString().toLowerCase();

    // Network and temporary errors are retryable
    if (errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('temporary') ||
        errorString.contains('server error')) {
      return true;
    }

    // Authentication and permission errors are not retryable
    if (errorString.contains('unauthorized') ||
        errorString.contains('forbidden') ||
        errorString.contains('authentication') ||
        errorString.contains('permission')) {
      return false;
    }

    // Default to retryable for unknown errors
    return true;
  }

  void _emitEvent(
    CircuitBreakerEventType type, {
    String? serviceName,
    String? error,
  }) {
    final event = CircuitBreakerEvent(
      type: type,
      timestamp: DateTime.now(),
      serviceName: serviceName,
      error: error,
    );
    _eventController.add(event);
  }

  // Getters
  bool get isInitialized => _isInitialized;
  Stream<CircuitBreakerEvent> get events => _eventController.stream;
  Map<String, CircuitBreaker> get circuitBreakers => Map.from(_circuitBreakers);
}

/// Circuit Breaker implementation
class CircuitBreaker {
  final String serviceName;
  final int failureThreshold;
  final Duration recoveryTimeout;
  final int successThreshold;

  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _consecutiveFailures = 0;
  int _consecutiveSuccesses = 0;
  DateTime? _lastFailureTime;
  DateTime? _lastSuccessTime;
  DateTime? _stateChangedTime;

  bool gracefulDegradationEnabled = false;
  Function()? fallbackOperation;

  CircuitBreaker({
    required this.serviceName,
    required this.failureThreshold,
    required this.recoveryTimeout,
    required this.successThreshold,
  });

  CircuitBreakerState get state => _state;
  int get consecutiveFailures => _consecutiveFailures;
  DateTime? get lastFailureTime => _lastFailureTime;
  DateTime? get lastSuccessTime => _lastSuccessTime;

  void recordSuccess() {
    _consecutiveFailures = 0;
    _consecutiveSuccesses++;
    _lastSuccessTime = DateTime.now();

    if (_state == CircuitBreakerState.halfOpen &&
        _consecutiveSuccesses >= successThreshold) {
      _setState(CircuitBreakerState.closed);
    }
  }

  void recordFailure() {
    _consecutiveFailures++;
    _consecutiveSuccesses = 0;
    _lastFailureTime = DateTime.now();

    if (_state == CircuitBreakerState.closed &&
        _consecutiveFailures >= failureThreshold) {
      _setState(CircuitBreakerState.open);
    }
  }

  bool canAttemptReset() {
    if (_state != CircuitBreakerState.open) return false;

    final timeSinceOpened =
        DateTime.now().difference(_stateChangedTime ?? DateTime.now());
    return timeSinceOpened >= recoveryTimeout;
  }

  void attemptReset() {
    if (canAttemptReset()) {
      _setState(CircuitBreakerState.halfOpen);
      _consecutiveSuccesses = 0;
    }
  }

  void reset() {
    _consecutiveFailures = 0;
    _consecutiveSuccesses = 0;
    _setState(CircuitBreakerState.closed);
  }

  void _setState(CircuitBreakerState newState) {
    _state = newState;
    _stateChangedTime = DateTime.now();
  }
}

/// Service Health Monitor
class ServiceHealthMonitor {
  final String serviceName;
  final List<bool> _recentResults = [];
  final int _maxHistorySize = 10;

  double _healthScore = 1.0;

  ServiceHealthMonitor(this.serviceName);

  double get healthScore => _healthScore;

  void recordResult(bool success) {
    _recentResults.add(success);
    if (_recentResults.length > _maxHistorySize) {
      _recentResults.removeAt(0);
    }
    _updateHealthScore();
  }

  void _updateHealthScore() {
    if (_recentResults.isEmpty) return;

    final successCount = _recentResults.where((r) => r).length;
    _healthScore = successCount / _recentResults.length;
  }

  void updateHealthScore() {
    _updateHealthScore();
  }
}

/// Supporting classes and enums

enum CircuitBreakerState { closed, open, halfOpen }

enum CircuitBreakerEventType {
  breakerOpened,
  breakerClosed,
  breakerHalfOpen,
  attemptingReset,
  breakerReset,
  operationFailed,
  operationSucceeded,
}

class CircuitBreakerEvent {
  final CircuitBreakerEventType type;
  final DateTime timestamp;
  final String? serviceName;
  final String? error;

  CircuitBreakerEvent({
    required this.type,
    required this.timestamp,
    this.serviceName,
    this.error,
  });
}

class CircuitBreakerException implements Exception {
  final String message;
  CircuitBreakerException(this.message);

  @override
  String toString() => 'CircuitBreakerException: $message';
}

class ServiceHealthStatus {
  final String serviceName;
  final CircuitBreakerState circuitBreakerState;
  final int consecutiveFailures;
  final DateTime? lastFailureTime;
  final DateTime? lastSuccessTime;
  final double healthScore;
  final bool isHealthy;

  ServiceHealthStatus({
    required this.serviceName,
    required this.circuitBreakerState,
    required this.consecutiveFailures,
    required this.lastFailureTime,
    required this.lastSuccessTime,
    required this.healthScore,
    required this.isHealthy,
  });
}
