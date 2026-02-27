import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config/central_config.dart';
import '../logging/logging_service.dart';
import '../enhanced_error_handling_service.dart';

/// Retry Service with Exponential Backoff
///
/// Provides intelligent retry mechanisms for failed operations:
/// - Exponential backoff with jitter
/// - Configurable retry policies
/// - Circuit breaker integration
/// - Success rate tracking
/// - Automatic failure classification
class RetryService {
  static const String _configPrefix = 'retry';
  static const String _defaultMaxAttempts = 'retry.max_attempts';
  static const String _defaultBaseDelay = 'retry.base_delay_ms';
  static const String _defaultMaxDelay = 'retry.max_delay_ms';
  static const String _defaultBackoffMultiplier = 'retry.backoff_multiplier';
  static const String _defaultJitterEnabled = 'retry.jitter_enabled';
  static const String _defaultJitterPercent = 'retry.jitter_percent';
  static const String _defaultEnabled = 'retry.enabled';

  final LoggingService _loggingService;
  final CentralConfig _centralConfig;
  final EnhancedErrorHandlingService _errorHandlingService;

  final Map<String, RetryPolicy> _policies = {};
  final Map<String, RetryStatistics> _statistics = {};
  final StreamController<RetryEvent> _eventController = StreamController.broadcast();

  bool _isInitialized = false;

  RetryService({
    LoggingService? loggingService,
    CentralConfig? centralConfig,
    EnhancedErrorHandlingService? errorHandlingService,
  }) : _loggingService = loggingService ?? LoggingService(),
       _centralConfig = centralConfig ?? CentralConfig.instance,
       _errorHandlingService = errorHandlingService ?? EnhancedErrorHandlingService();

  /// Initialize the retry service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _loggingService.info('Initializing Retry Service', 'RetryService');

      // Register with CentralConfig
      await _centralConfig.registerComponent(
        'RetryService',
        '1.0.0',
        'Intelligent retry service with exponential backoff and circuit breaker integration',
        dependencies: ['CentralConfig', 'LoggingService', 'EnhancedErrorHandlingService'],
        parameters: {
          _defaultEnabled: true,
          _defaultMaxAttempts: 3,
          _defaultBaseDelay: 1000, // 1 second
          _defaultMaxDelay: 30000, // 30 seconds
          _defaultBackoffMultiplier: 2.0,
          _defaultJitterEnabled: true,
          _defaultJitterPercent: 0.1, // 10%
          'retry.network_retry_enabled': true,
          'retry.timeout_retry_enabled': true,
          'retry.server_error_retry_enabled': true,
          'retry.auth_error_retry_enabled': false, // Don't retry auth errors
          'retry.client_error_retry_enabled': false, // Don't retry 4xx errors
        }
      );

      // Create default retry policies
      _createDefaultPolicies();

      _isInitialized = true;
      _loggingService.info('Retry Service initialized successfully', 'RetryService');

    } catch (e, stackTrace) {
      _loggingService.error('Failed to initialize Retry Service', 'RetryService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Configuration getters
  bool get enabled => _centralConfig.getParameter(_defaultEnabled, defaultValue: true);
  int get maxAttempts => _centralConfig.getParameter(_defaultMaxAttempts, defaultValue: 3);
  int get baseDelayMs => _centralConfig.getParameter(_defaultBaseDelay, defaultValue: 1000);
  int get maxDelayMs => _centralConfig.getParameter(_defaultMaxDelay, defaultValue: 30000);
  double get backoffMultiplier => _centralConfig.getParameter(_defaultBackoffMultiplier, defaultValue: 2.0);
  bool get jitterEnabled => _centralConfig.getParameter(_defaultJitterEnabled, defaultValue: true);
  double get jitterPercent => _centralConfig.getParameter(_defaultJitterPercent, defaultValue: 0.1);

  bool get networkRetryEnabled => _centralConfig.getParameter('retry.network_retry_enabled', defaultValue: true);
  bool get timeoutRetryEnabled => _centralConfig.getParameter('retry.timeout_retry_enabled', defaultValue: true);
  bool get serverErrorRetryEnabled => _centralConfig.getParameter('retry.server_error_retry_enabled', defaultValue: true);
  bool get authErrorRetryEnabled => _centralConfig.getParameter('retry.auth_error_retry_enabled', defaultValue: false);
  bool get clientErrorRetryEnabled => _centralConfig.getParameter('retry.client_error_retry_enabled', defaultValue: false);

  /// Execute operation with retry logic
  Future<T> execute<T>({
    required String operationName,
    required Future<T> Function() operation,
    RetryPolicy? policy,
    bool Function(dynamic error)? shouldRetry,
    void Function(RetryAttempt attempt)? onRetry,
  }) async {
    if (!enabled) {
      return await operation();
    }

    final effectivePolicy = policy ?? _policies['default'] ?? _createDefaultPolicy();
    final stats = _getOrCreateStatistics(operationName);

    Exception? lastException;
    final attempts = <RetryAttempt>[];

    for (int attempt = 0; attempt <= effectivePolicy.maxAttempts; attempt++) {
      try {
        final startTime = DateTime.now();
        final result = await operation().timeout(effectivePolicy.timeout ?? const Duration(seconds: 30));
        final duration = DateTime.now().difference(startTime);

        // Success
        stats.recordSuccess(duration);
        _emitEvent(RetryEvent(
          operationName: operationName,
          type: RetryEventType.success,
          attempt: attempt,
          totalAttempts: attempt,
          duration: duration,
        ));

        if (attempt > 0) {
          _loggingService.info('Operation $operationName succeeded on attempt ${attempt + 1}', 'RetryService');
        }

        return result;

      } catch (e, stackTrace) {
        lastException = e is Exception ? e : Exception(e.toString());

        final attemptRecord = RetryAttempt(
          number: attempt,
          error: lastException,
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        );
        attempts.add(attemptRecord);

        stats.recordFailure(attemptRecord);

        _loggingService.warning(
          'Operation $operationName failed on attempt ${attempt + 1}: ${e.toString()}',
          'RetryService'
        );

        // Check if we should retry
        final canRetry = attempt < effectivePolicy.maxAttempts &&
                        _isRetryableError(e, effectivePolicy) &&
                        (shouldRetry == null || shouldRetry(e));

        if (!canRetry) {
          break;
        }

        // Calculate delay
        final delay = _calculateDelay(effectivePolicy, attempt);
        onRetry?.call(attemptRecord);

        _emitEvent(RetryEvent(
          operationName: operationName,
          type: RetryEventType.retry,
          attempt: attempt,
          totalAttempts: effectivePolicy.maxAttempts,
          delay: delay,
          error: e.toString(),
        ));

        _loggingService.info(
          'Retrying operation $operationName in ${delay.inMilliseconds}ms (attempt ${attempt + 2}/${effectivePolicy.maxAttempts + 1})',
          'RetryService'
        );

        await Future.delayed(delay);
      }
    }

    // All attempts failed
    _emitEvent(RetryEvent(
      operationName: operationName,
      type: RetryEventType.exhausted,
      attempt: attempts.length - 1,
      totalAttempts: effectivePolicy.maxAttempts,
      attempts: attempts,
    ));

    _loggingService.error(
      'Operation $operationName failed after ${attempts.length} attempts',
      'RetryService',
      error: lastException
    );

    throw lastException ?? Exception('Operation failed after all retry attempts');
  }

  /// Execute with custom retry policy
  Future<T> executeWithPolicy<T>(
    String policyName,
    Future<T> Function() operation, {
    String? operationName,
    bool Function(dynamic error)? shouldRetry,
    void Function(RetryAttempt attempt)? onRetry,
  }) async {
    final policy = _policies[policyName];
    if (policy == null) {
      throw ArgumentError('Retry policy "$policyName" not found');
    }

    return execute(
      operationName: operationName ?? 'custom_operation',
      operation: operation,
      policy: policy,
      shouldRetry: shouldRetry,
      onRetry: onRetry,
    );
  }

  /// Create a custom retry policy
  RetryPolicy createPolicy({
    required String name,
    int? maxAttempts,
    Duration? baseDelay,
    Duration? maxDelay,
    double? backoffMultiplier,
    bool? jitterEnabled,
    double? jitterPercent,
    Duration? timeout,
    Set<RetryableErrorType>? retryableErrors,
    bool Function(dynamic error)? customRetryCondition,
  }) {
    final policy = RetryPolicy(
      name: name,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      baseDelay: baseDelay ?? Duration(milliseconds: baseDelayMs),
      maxDelay: maxDelay ?? Duration(milliseconds: maxDelayMs),
      backoffMultiplier: backoffMultiplier ?? this.backoffMultiplier,
      jitterEnabled: jitterEnabled ?? this.jitterEnabled,
      jitterPercent: jitterPercent ?? this.jitterPercent,
      timeout: timeout,
      retryableErrors: retryableErrors ?? {RetryableErrorType.network, RetryableErrorType.timeout, RetryableErrorType.serverError},
      customRetryCondition: customRetryCondition,
    );

    _policies[name] = policy;
    _loggingService.info('Created retry policy: $name', 'RetryService');

    return policy;
  }

  /// Get retry policy by name
  RetryPolicy? getPolicy(String name) {
    return _policies[name];
  }

  /// Get all retry policies
  Map<String, RetryPolicy> getAllPolicies() {
    return Map.from(_policies);
  }

  /// Get retry statistics for operation
  RetryStatistics? getStatistics(String operationName) {
    return _statistics[operationName];
  }

  /// Get all retry statistics
  Map<String, RetryStatistics> getAllStatistics() {
    return Map.from(_statistics);
  }

  /// Reset statistics for operation
  void resetStatistics(String operationName) {
    _statistics.remove(operationName);
    _loggingService.info('Reset statistics for operation: $operationName', 'RetryService');
  }

  /// Reset all statistics
  void resetAllStatistics() {
    _statistics.clear();
    _loggingService.info('Reset all retry statistics', 'RetryService');
  }

  /// Create default retry policies
  void _createDefaultPolicies() {
    // Default policy for general operations
    _policies['default'] = _createDefaultPolicy();

    // Aggressive policy for critical operations
    _policies['aggressive'] = createPolicy(
      name: 'aggressive',
      maxAttempts: 5,
      baseDelay: const Duration(milliseconds: 500),
      backoffMultiplier: 1.5,
    );

    // Conservative policy for non-critical operations
    _policies['conservative'] = createPolicy(
      name: 'conservative',
      maxAttempts: 2,
      baseDelay: const Duration(milliseconds: 2000),
      backoffMultiplier: 3.0,
    );

    // Fast policy for quick operations
    _policies['fast'] = createPolicy(
      name: 'fast',
      maxAttempts: 3,
      baseDelay: const Duration(milliseconds: 100),
      maxDelay: const Duration(milliseconds: 1000),
      backoffMultiplier: 2.0,
    );

    // Network-specific policy
    _policies['network'] = createPolicy(
      name: 'network',
      maxAttempts: 4,
      baseDelay: const Duration(milliseconds: 1000),
      retryableErrors: {RetryableErrorType.network, RetryableErrorType.timeout},
    );

    _loggingService.info('Created ${policies.length} default retry policies', 'RetryService');
  }

  /// Create default retry policy
  RetryPolicy _createDefaultPolicy() {
    return RetryPolicy(
      name: 'default',
      maxAttempts: maxAttempts,
      baseDelay: Duration(milliseconds: baseDelayMs),
      maxDelay: Duration(milliseconds: maxDelayMs),
      backoffMultiplier: backoffMultiplier,
      jitterEnabled: jitterEnabled,
      jitterPercent: jitterPercent,
      retryableErrors: {RetryableErrorType.network, RetryableErrorType.timeout, RetryableErrorType.serverError},
    );
  }

  /// Get or create statistics for operation
  RetryStatistics _getOrCreateStatistics(String operationName) {
    return _statistics.putIfAbsent(operationName, () => RetryStatistics(operationName));
  }

  /// Calculate delay for retry attempt
  Duration _calculateDelay(RetryPolicy policy, int attempt) {
    // Exponential backoff: baseDelay * (multiplier ^ attempt)
    double delay = policy.baseDelay.inMilliseconds * pow(policy.backoffMultiplier, attempt).toDouble();

    // Cap at max delay
    delay = min(delay, policy.maxDelay.inMilliseconds.toDouble());

    // Add jitter to prevent thundering herd
    if (policy.jitterEnabled) {
      final jitterRange = delay * policy.jitterPercent;
      final jitter = (Random().nextDouble() - 0.5) * 2 * jitterRange; // ±jitterRange
      delay += jitter;
      delay = max(delay, 0); // Ensure non-negative
    }

    return Duration(milliseconds: delay.toInt());
  }

  /// Check if error is retryable
  bool _isRetryableError(dynamic error, RetryPolicy policy) {
    // Check custom retry condition first
    if (policy.customRetryCondition != null) {
      return policy.customRetryCondition!(error);
    }

    // Classify error type
    final errorType = _classifyError(error);

    // Check if error type is retryable
    if (!policy.retryableErrors.contains(errorType)) {
      return false;
    }

    // Apply specific configuration rules
    switch (errorType) {
      case RetryableErrorType.network:
        return networkRetryEnabled;
      case RetryableErrorType.timeout:
        return timeoutRetryEnabled;
      case RetryableErrorType.serverError:
        return serverErrorRetryEnabled;
      case RetryableErrorType.authError:
        return authErrorRetryEnabled;
      case RetryableErrorType.clientError:
        return clientErrorRetryEnabled;
      case RetryableErrorType.unknown:
        return false; // Don't retry unknown errors
    }

    return false;
  }

  /// Classify error type
  RetryableErrorType _classifyError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('dns') ||
        errorString.contains('host')) {
      return RetryableErrorType.network;
    }

    // Timeout errors
    if (errorString.contains('timeout') ||
        errorString.contains('timed out')) {
      return RetryableErrorType.timeout;
    }

    // HTTP status codes (if available)
    if (error is Exception && errorString.contains('http')) {
      if (errorString.contains('401') || errorString.contains('403')) {
        return RetryableErrorType.authError;
      }
      if (errorString.contains('4')) {
        return RetryableErrorType.clientError;
      }
      if (errorString.contains('5')) {
        return RetryableErrorType.serverError;
      }
    }

    // Authentication errors
    if (errorString.contains('unauthorized') ||
        errorString.contains('authentication') ||
        errorString.contains('auth')) {
      return RetryableErrorType.authError;
    }

    return RetryableErrorType.unknown;
  }

  /// Emit retry event
  void _emitEvent(RetryEvent event) {
    _eventController.add(event);
  }

  /// Get event stream
  Stream<RetryEvent> get events => _eventController.stream;

  /// Dispose resources
  void dispose() {
    _eventController.close();
    _loggingService.info('Retry service disposed', 'RetryService');
  }
}

/// Retry Policy Configuration
class RetryPolicy {
  final String name;
  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final bool jitterEnabled;
  final double jitterPercent;
  final Duration? timeout;
  final Set<RetryableErrorType> retryableErrors;
  final bool Function(dynamic error)? customRetryCondition;

  RetryPolicy({
    required this.name,
    required this.maxAttempts,
    required this.baseDelay,
    required this.maxDelay,
    required this.backoffMultiplier,
    required this.jitterEnabled,
    required this.jitterPercent,
    this.timeout,
    required this.retryableErrors,
    this.customRetryCondition,
  });

  @override
  String toString() {
    return 'RetryPolicy(name: $name, maxAttempts: $maxAttempts, baseDelay: $baseDelay, maxDelay: $maxDelay)';
  }
}

/// Retryable Error Types
enum RetryableErrorType {
  network,
  timeout,
  serverError,
  authError,
  clientError,
  unknown,
}

/// Retry Attempt Record
class RetryAttempt {
  final int number;
  final Exception error;
  final DateTime timestamp;
  final StackTrace stackTrace;

  RetryAttempt({
    required this.number,
    required this.error,
    required this.timestamp,
    required this.stackTrace,
  });

  @override
  String toString() {
    return 'RetryAttempt(number: $number, error: ${error.toString()}, timestamp: $timestamp)';
  }
}

/// Retry Statistics
class RetryStatistics {
  final String operationName;
  int totalAttempts = 0;
  int successfulAttempts = 0;
  int failedAttempts = 0;
  Duration totalDuration = Duration.zero;
  final List<RetryAttempt> failureHistory = [];
  DateTime? lastSuccessTime;
  DateTime? lastFailureTime;

  RetryStatistics(this.operationName);

  void recordSuccess(Duration duration) {
    totalAttempts++;
    successfulAttempts++;
    totalDuration += duration;
    lastSuccessTime = DateTime.now();
  }

  void recordFailure(RetryAttempt attempt) {
    totalAttempts++;
    failedAttempts++;
    failureHistory.add(attempt);
    lastFailureTime = DateTime.now();

    // Keep only last 10 failures
    if (failureHistory.length > 10) {
      failureHistory.removeAt(0);
    }
  }

  double get successRate => totalAttempts > 0 ? successfulAttempts / totalAttempts : 1.0;
  double get failureRate => totalAttempts > 0 ? failedAttempts / totalAttempts : 0.0;
  Duration get averageDuration => totalAttempts > 0 ? totalDuration ~/ totalAttempts : Duration.zero;

  @override
  String toString() {
    return 'RetryStatistics(operation: $operationName, attempts: $totalAttempts, '
           'successRate: ${(successRate * 100).toStringAsFixed(1)}%, '
           'avgDuration: ${averageDuration.inMilliseconds}ms)';
  }
}

/// Retry Event Types
enum RetryEventType {
  success,
  retry,
  exhausted,
}

/// Retry Event
class RetryEvent {
  final String operationName;
  final RetryEventType type;
  final int attempt;
  final int totalAttempts;
  final Duration? delay;
  final String? error;
  final List<RetryAttempt>? attempts;
  final Duration? duration;
  final DateTime timestamp;

  RetryEvent({
    required this.operationName,
    required this.type,
    required this.attempt,
    required this.totalAttempts,
    this.delay,
    this.error,
    this.attempts,
    this.duration,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'RetryEvent(operation: $operationName, type: $type, attempt: $attempt/$totalAttempts)';
  }
}
