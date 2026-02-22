import 'dart:async';
import 'dart:math';
import '../../../core/logging/logging_service.dart';

/// Circuit Breaker Pattern Implementation
/// Provides resilience against cascading failures and prevents system overload
class CircuitBreaker {
  final LoggingService _logger = LoggingService();

  final String name;
  final int failureThreshold;
  final Duration timeout;
  final Duration retryTimeout;
  final double failureRateThreshold;

  int _failureCount = 0;
  int _successCount = 0;
  int _totalRequests = 0;
  CircuitBreakerState _state = CircuitBreakerState.closed;
  DateTime? _lastFailureTime;
  Timer? _retryTimer;

  CircuitBreaker({
    required this.name,
    this.failureThreshold = 5,
    this.timeout = const Duration(seconds: 10),
    this.retryTimeout = const Duration(seconds: 30),
    this.failureRateThreshold = 0.5,
  });

  /// Execute a function with circuit breaker protection
  Future<T> execute<T>(Future<T> Function() operation) async {
    _totalRequests++;

    if (_state == CircuitBreakerState.open) {
      if (_canAttemptReset()) {
        _transitionToHalfOpen();
      } else {
        throw CircuitBreakerException('Circuit breaker is OPEN for $name');
      }
    }

    try {
      final result = await operation().timeout(timeout);
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }

  void _onSuccess() {
    _successCount++;
    _failureCount = 0;

    if (_state == CircuitBreakerState.halfOpen) {
      _transitionToClosed();
    }

    _logger.debug('Circuit breaker $name: Success recorded', 'CircuitBreaker');
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    final failureRate = _failureCount / _totalRequests;
    if (failureRate >= failureRateThreshold || _failureCount >= failureThreshold) {
      _transitionToOpen();
    }

    _logger.warning('Circuit breaker $name: Failure recorded (count: $_failureCount, rate: ${(failureRate * 100).toFixed(1)}%)', 'CircuitBreaker');
  }

  bool _canAttemptReset() {
    if (_lastFailureTime == null) return false;
    return DateTime.now().difference(_lastFailureTime!) >= retryTimeout;
  }

  void _transitionToOpen() {
    _state = CircuitBreakerState.open;
    _startRetryTimer();
    _logger.warning('Circuit breaker $name: OPEN - Stopping requests', 'CircuitBreaker');
  }

  void _transitionToHalfOpen() {
    _state = CircuitBreakerState.halfOpen;
    _logger.info('Circuit breaker $name: HALF-OPEN - Testing service', 'CircuitBreaker');
  }

  void _transitionToClosed() {
    _state = CircuitBreakerState.closed;
    _retryTimer?.cancel();
    _failureCount = 0;
    _logger.info('Circuit breaker $name: CLOSED - Service restored', 'CircuitBreaker');
  }

  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer(retryTimeout, () {
      if (_state == CircuitBreakerState.open) {
        _transitionToHalfOpen();
      }
    });
  }

  /// Get current circuit breaker status
  CircuitBreakerStatus getStatus() {
    return CircuitBreakerStatus(
      name: name,
      state: _state,
      failureCount: _failureCount,
      successCount: _successCount,
      totalRequests: _totalRequests,
      failureRate: _totalRequests > 0 ? _failureCount / _totalRequests : 0.0,
      lastFailureTime: _lastFailureTime,
    );
  }

  /// Reset circuit breaker manually
  void reset() {
    _failureCount = 0;
    _successCount = 0;
    _totalRequests = 0;
    _lastFailureTime = null;
    _transitionToClosed();
    _logger.info('Circuit breaker $name: Manually reset', 'CircuitBreaker');
  }

  void dispose() {
    _retryTimer?.cancel();
  }
}

/// Circuit breaker states
enum CircuitBreakerState {
  closed,    // Normal operation
  open,      // Failing, requests blocked
  halfOpen,  // Testing if service recovered
}

/// Circuit breaker status information
class CircuitBreakerStatus {
  final String name;
  final CircuitBreakerState state;
  final int failureCount;
  final int successCount;
  final int totalRequests;
  final double failureRate;
  final DateTime? lastFailureTime;

  CircuitBreakerStatus({
    required this.name,
    required this.state,
    required this.failureCount,
    required this.successCount,
    required this.totalRequests,
    required this.failureRate,
    required this.lastFailureTime,
  });

  bool get isHealthy => state == CircuitBreakerState.closed && failureRate < 0.1;
}

/// Circuit breaker exception
class CircuitBreakerException implements Exception {
  final String message;
  CircuitBreakerException(this.message);

  @override
  String toString() => 'CircuitBreakerException: $message';
}

/// Retry mechanism with exponential backoff
class RetryMechanism {
  final LoggingService _logger = LoggingService();

  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final bool Function(Object error)? shouldRetry;

  RetryMechanism({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.shouldRetry,
  });

  /// Execute operation with retry logic
  Future<T> execute<T>(Future<T> Function() operation) async {
    Object? lastError;
    Duration delay = initialDelay;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final result = await operation();
        if (attempt > 1) {
          _logger.info('Operation succeeded on attempt $attempt', 'RetryMechanism');
        }
        return result;
      } catch (e) {
        lastError = e;

        if (attempt == maxAttempts) {
          _logger.error('Operation failed after $maxAttempts attempts', 'RetryMechanism', error: e);
          break;
        }

        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry!(e)) {
          _logger.info('Not retrying error: $e', 'RetryMechanism');
          rethrow;
        }

        _logger.warning('Operation failed (attempt $attempt/$maxAttempts): $e. Retrying in ${delay.inSeconds}s...', 'RetryMechanism');

        await Future.delayed(delay);
        delay = Duration(milliseconds: min((delay.inMilliseconds * backoffMultiplier).round(), maxDelay.inMilliseconds));
      }
    }

    throw lastError ?? Exception('Unknown error after $maxAttempts attempts');
  }
}

/// Resilience manager coordinating multiple robustness mechanisms
class ResilienceManager {
  static final ResilienceManager _instance = ResilienceManager._internal();
  factory ResilienceManager() => _instance;
  ResilienceManager._internal();

  final LoggingService _logger = LoggingService();
  final Map<String, CircuitBreaker> _circuitBreakers = {};
  final Map<String, RetryMechanism> _retryMechanisms = {};

  bool _isInitialized = false;

  /// Initialize resilience manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize default circuit breakers
    _initializeDefaultCircuitBreakers();

    // Initialize default retry mechanisms
    _initializeDefaultRetryMechanisms();

    _isInitialized = true;
    _logger.info('Resilience Manager initialized', 'ResilienceManager');
  }

  void _initializeDefaultCircuitBreakers() {
    // Network circuit breaker
    _circuitBreakers['network'] = CircuitBreaker(
      name: 'network',
      failureThreshold: 5,
      timeout: const Duration(seconds: 10),
      retryTimeout: const Duration(seconds: 30),
      failureRateThreshold: 0.5,
    );

    // API circuit breaker
    _circuitBreakers['api'] = CircuitBreaker(
      name: 'api',
      failureThreshold: 3,
      timeout: const Duration(seconds: 15),
      retryTimeout: const Duration(seconds: 60),
      failureRateThreshold: 0.3,
    );

    // Database circuit breaker
    _circuitBreakers['database'] = CircuitBreaker(
      name: 'database',
      failureThreshold: 2,
      timeout: const Duration(seconds: 5),
      retryTimeout: const Duration(seconds: 10),
      failureRateThreshold: 0.2,
    );
  }

  void _initializeDefaultRetryMechanisms() {
    // Network retry mechanism
    _retryMechanisms['network'] = RetryMechanism(
      maxAttempts: 3,
      initialDelay: const Duration(seconds: 1),
      backoffMultiplier: 2.0,
      maxDelay: const Duration(seconds: 10),
      shouldRetry: (error) => _isRetryableNetworkError(error),
    );

    // API retry mechanism
    _retryMechanisms['api'] = RetryMechanism(
      maxAttempts: 3,
      initialDelay: const Duration(milliseconds: 500),
      backoffMultiplier: 1.5,
      maxDelay: const Duration(seconds: 5),
      shouldRetry: (error) => _isRetryableApiError(error),
    );

    // File operation retry mechanism
    _retryMechanisms['file'] = RetryMechanism(
      maxAttempts: 2,
      initialDelay: const Duration(milliseconds: 100),
      backoffMultiplier: 2.0,
      maxDelay: const Duration(seconds: 1),
      shouldRetry: (error) => _isRetryableFileError(error),
    );
  }

  /// Execute operation with resilience (circuit breaker + retry)
  Future<T> executeResilient<T>({
    required String operationName,
    required Future<T> Function() operation,
    String circuitBreakerName = 'default',
    String retryMechanismName = 'default',
  }) async {
    final circuitBreaker = _circuitBreakers[circuitBreakerName] ?? _circuitBreakers['network']!;
    final retryMechanism = _retryMechanisms[retryMechanismName] ?? _retryMechanisms['network']!;

    return await circuitBreaker.execute(() async {
      return await retryMechanism.execute(operation);
    });
  }

  /// Add custom circuit breaker
  void addCircuitBreaker(String name, CircuitBreaker circuitBreaker) {
    _circuitBreakers[name] = circuitBreaker;
    _logger.info('Added custom circuit breaker: $name', 'ResilienceManager');
  }

  /// Add custom retry mechanism
  void addRetryMechanism(String name, RetryMechanism retryMechanism) {
    _retryMechanisms[name] = retryMechanism;
    _logger.info('Added custom retry mechanism: $name', 'ResilienceManager');
  }

  /// Get circuit breaker status
  CircuitBreakerStatus? getCircuitBreakerStatus(String name) {
    return _circuitBreakers[name]?.getStatus();
  }

  /// Get all circuit breaker statuses
  Map<String, CircuitBreakerStatus> getAllCircuitBreakerStatuses() {
    return _circuitBreakers.map((key, value) => MapEntry(key, value.getStatus()));
  }

  /// Reset circuit breaker
  void resetCircuitBreaker(String name) {
    _circuitBreakers[name]?.reset();
    _logger.info('Reset circuit breaker: $name', 'ResilienceManager');
  }

  /// Check if error is retryable for network operations
  bool _isRetryableNetworkError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') ||
           errorString.contains('connection') ||
           errorString.contains('network') ||
           errorString.contains('socket');
  }

  /// Check if error is retryable for API operations
  bool _isRetryableApiError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') ||
           errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('500') ||
           errorString.contains('502') ||
           errorString.contains('503') ||
           errorString.contains('504');
  }

  /// Check if error is retryable for file operations
  bool _isRetryableFileError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('permission') ||
           errorString.contains('busy') ||
           errorString.contains('locked');
  }

  /// Get resilience health status
  Map<String, dynamic> getHealthStatus() {
    final circuitBreakerHealth = _circuitBreakers.map((key, value) {
      final status = value.getStatus();
      return MapEntry(key, {
        'healthy': status.isHealthy,
        'state': status.state.name,
        'failureRate': status.failureRate,
      });
    });

    final overallHealth = circuitBreakerHealth.values.every((status) => status['healthy'] as bool);

    return {
      'overallHealthy': overallHealth,
      'circuitBreakers': circuitBreakerHealth,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  void dispose() {
    for (final circuitBreaker in _circuitBreakers.values) {
      circuitBreaker.dispose();
    }
    _circuitBreakers.clear();
    _retryMechanisms.clear();
  }
}
