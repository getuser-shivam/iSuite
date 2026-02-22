import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ErrorHandlingEngine {
  static ErrorHandlingEngine? _instance;
  static ErrorHandlingEngine get instance => _instance ??= ErrorHandlingEngine._internal();
  ErrorHandlingEngine._internal();

  // Error Registry
  final Map<String, ErrorCategory> _errorCategories = {};
  final Map<String, ErrorSeverity> _errorSeverities = {};
  final Map<String, ErrorRecoveryStrategy> _recoveryStrategies = {};
  
  // Error Tracking
  final List<ErrorReport> _errorLog = [];
  final Map<String, ErrorStatistics> _errorStats = {};
  final Map<String, List<ErrorReport>> _errorHistory = {};
  
  // Circuit Breaker
  final Map<String, CircuitBreaker> _circuitBreakers = {};
  int _defaultFailureThreshold = 5;
  Duration _defaultRecoveryTimeout = Duration(seconds: 30);
  
  // Retry Policy
  RetryPolicy _defaultRetryPolicy = RetryPolicy.exponential;
  int _maxRetries = 3;
  Duration _baseRetryDelay = Duration(seconds: 1);
  double _retryMultiplier = 2.0;
  
  // Fallback Handlers
  final Map<String, FallbackHandler> _fallbackHandlers = {};
  
  // Monitoring
  final Map<String, ErrorMetrics> _metrics = {};
  Timer? _metricsTimer;
  Duration _metricsInterval = Duration(minutes: 1);
  
  // Configuration
  bool _isInitialized = false;
  bool _enableLogging = true;
  bool _enableMetrics = true;
  bool _enableRecovery = true;
  bool _enableCircuitBreaker = true;
  String? _logFilePath;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get enableLogging => _enableLogging;
  bool get enableMetrics => _enableMetrics;
  bool get enableRecovery => _enableRecovery;
  bool get enableCircuitBreaker => _enableCircuitBreaker;
  List<ErrorReport> get errorLog => List.from(_errorLog);
  Map<String, ErrorStatistics> get errorStats => Map.from(_errorStats);
  Map<String, List<ErrorReport>> get errorHistory => Map.from(_errorHistory);

  /// Initialize Error Handling Engine
  Future<bool> initialize({
    String? logFilePath,
    bool enableLogging = true,
    bool enableMetrics = true,
    bool enableRecovery = true,
    bool enableCircuitBreaker = true,
    int? failureThreshold,
    Duration? recoveryTimeout,
    RetryPolicy? retryPolicy,
    int? maxRetries,
    Duration? baseRetryDelay,
    double? retryMultiplier,
  }) async {
    if (_isInitialized) return true;

    try {
      _enableLogging = enableLogging;
      _enableMetrics = enableMetrics;
      _enableRecovery = enableRecovery;
      _enableCircuitBreaker = enableCircuitBreaker;
      _logFilePath = logFilePath;
      _defaultFailureThreshold = failureThreshold ?? _defaultFailureThreshold;
      _defaultRecoveryTimeout = recoveryTimeout ?? _defaultRecoveryTimeout;
      _defaultRetryPolicy = retryPolicy ?? _defaultRetryPolicy;
      _maxRetries = maxRetries ?? _maxRetries;
      _baseRetryDelay = baseRetryDelay ?? _baseRetryDelay;
      _retryMultiplier = retryMultiplier ?? _retryMultiplier;

      // Initialize error categories
      await _initializeErrorCategories();
      
      // Initialize error severities
      await _initializeErrorSeverities();
      
      // Initialize recovery strategies
      await _initializeRecoveryStrategies();
      
      // Initialize circuit breakers
      if (_enableCircuitBreaker) {
        await _initializeCircuitBreakers();
      }

      // Initialize metrics
      if (_enableMetrics) {
        await _initializeMetrics();
      }

      // Start metrics collection
      if (_enableMetrics) {
        _startMetricsCollection();
      }

      // Initialize logging
      if (_enableLogging) {
        await _initializeLogging();
      }

      _isInitialized = true;
      await _logError(ErrorType.initialization, 'Error handling engine initialized successfully');
      
      return true;
    } catch (e) {
      print('Failed to initialize error handling engine: $e');
      return false;
    }
  }

  Future<void> _initializeErrorCategories() async {
    _errorCategories['network'] = ErrorCategory(
      name: 'Network',
      description: 'Network-related errors',
      icon: Icons.wifi_off,
      color: Colors.red,
    );
    
    _errorCategories['database'] = ErrorCategory(
      name: 'Database',
      description: 'Database operation errors',
      icon: Icons.storage,
      color: Colors.orange,
    );
    
    _errorCategories['authentication'] = ErrorCategory(
      name: 'Authentication',
      description: 'Authentication and authorization errors',
      icon: Icons.lock,
      color: Colors.purple,
    );
    
    _errorCategories['validation'] = ErrorCategory(
      name: 'Validation',
      description: 'Data validation errors',
      icon: Icons.error_outline,
      color: Colors.yellow,
    );
    
    _errorCategories['business'] = ErrorCategory(
      name: 'Business Logic',
      description: 'Business logic errors',
      icon: Icons.business_center,
      color: Colors.blue,
    );
    
    _errorCategories['system'] = ErrorCategory(
      name: 'System',
      description: 'System-level errors',
      icon: Icons.settings,
      color: Colors.grey,
    );
    
    _errorCategories['ui'] = ErrorCategory(
      name: 'UI',
      description: 'User interface errors',
      icon: Icons.desktop_windows,
      color: Colors.teal,
    );
  }

  Future<void> _initializeErrorSeverities() async {
    _errorSeverities['critical'] = ErrorSeverity(
      name: 'Critical',
      description: 'Critical errors that require immediate attention',
      level: 5,
      color: Colors.red,
      requiresNotification: true,
      requiresIntervention: true,
    );
    
    _errorSeverities['high'] = ErrorSeverity(
      name: 'High',
      description: 'High severity errors',
      level: 4,
      color: Colors.orange,
      requiresNotification: true,
      requiresIntervention: true,
    );
    
    _errorSeverities['medium'] = ErrorSeverity(
      name: 'Medium',
      description: 'Medium severity errors',
      level: 3,
      color: Colors.yellow,
      requiresNotification: false,
      requiresIntervention: false,
    );
    
    _errorSeverities['low'] = ErrorSeverity(
      name: 'Low',
      description: 'Low severity errors',
      level: 2,
      color: Colors.blue,
      requiresNotification: false,
      requiresIntervention: false,
    );
    
    _errorSeverities['info'] = ErrorSeverity(
      name: 'Info',
      description: 'Informational messages',
      level: 1,
      color: Colors.grey,
      requiresNotification: false,
      requiresIntervention: false,
    );
  }

  Future<void> _initializeRecoveryStrategies() async {
    _recoveryStrategies['retry'] = ErrorRecoveryStrategy(
      name: 'Retry',
      description: 'Retry the operation with exponential backoff',
      canRetry: true,
      maxRetries: _maxRetries,
      baseDelay: _baseRetryDelay,
      multiplier: _retryMultiplier,
    );
    
    _recoveryStrategies['fallback'] = ErrorRecoveryStrategy(
      name: 'Fallback',
      description: 'Use fallback implementation',
      canRetry: false,
      maxRetries: 0,
      baseDelay: Duration.zero,
      multiplier: 1.0,
    );
    
    _recoveryStrategies['ignore'] = ErrorRecoveryStrategy(
      name: 'Ignore',
      description: 'Ignore the error and continue',
      canRetry: false,
      maxRetries: 0,
      baseDelay: Duration.zero,
      multiplier: 1.0,
    );
    
    _recoveryStrategies['restart'] = ErrorRecoveryStrategy(
      name: 'Restart',
      description: 'Restart the component',
      canRetry: false,
      maxRetries: 1,
      baseDelay: Duration(seconds: 5),
      multiplier: 1.0,
    );
    
    _recoveryStrategies['escalate'] = ErrorRecoveryStrategy(
      name: 'Escalate',
      description: 'Escalate to higher level',
      canRetry: false,
      maxRetries: 0,
      baseDelay: Duration.zero,
      multiplier: 1.0,
    );
  }

  Future<void> _initializeCircuitBreakers() async {
    // Initialize circuit breakers for common components
    _circuitBreakers['network'] = CircuitBreaker(
    failureThreshold: _defaultFailureThreshold,
    recoveryTimeout: _defaultRecoveryTimeout,
  );
    
    _circuitBreakers['database'] = CircuitBreaker(
      failureThreshold: _defaultFailureThreshold,
      recoveryTimeout: _defaultRecoveryTimeout,
    );
    
    _circuitBreakers['api'] = CircuitBreaker(
      failureThreshold: _defaultFailureThreshold,
      recoveryTimeout: _defaultRecoveryTimeout,
    );
  }

  Future<void> _initializeMetrics() async {
    _metrics['global'] = ErrorMetrics(
      type: 'global',
      totalErrors: 0,
      criticalErrors: 0,
      highErrors: 0,
      mediumErrors: 0,
      lowErrors: 0,
      infoMessages: 0,
      averageRecoveryTime: 0.0,
      successRate: 1.0,
      lastErrorTime: null,
    );

    // Initialize metrics for each category
    for (final category in _errorCategories.keys) {
      _metrics[category] = ErrorMetrics(
        type: category,
        totalErrors: 0,
        criticalErrors: 0,
        highErrors: 0,
        mediumErrors: 0,
        lowErrors: 0,
        infoMessages: 0,
        averageRecoveryTime: 0.0,
        successRate: 1.0,
        lastErrorTime: null,
      );
    }
  }

  Future<void> _initializeLogging() async {
    if (_logFilePath != null) {
      final logFile = File(_logFilePath!);
      if (!await logFile.exists()) {
        await logFile.create(recursive: true);
      }
    }
  }

  void _startMetricsCollection() {
    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(_metricsInterval, (_) {
      _collectMetrics();
    });
  }

  void _collectMetrics() {
    for (final metrics in _metrics.values) {
      // Calculate success rate
      final totalOperations = metrics.totalErrors + metrics.successCount;
      if (totalOperations > 0) {
        metrics.successRate = metrics.successCount / totalOperations;
      }
      
      // Calculate average recovery time
      if (metrics.recoveryTimes.isNotEmpty) {
        final totalRecoveryTime = metrics.recoveryTimes.reduce((a, b) => a + b);
        metrics.averageRecoveryTime = totalRecoveryTime / metrics.recoveryTimes.length;
      }
    }
  }

  /// Handle error
  Future<ErrorResult> handleError({
    required dynamic error,
    String? context,
    String? component,
    ErrorType? type,
    Map<String, dynamic>? metadata,
    StackTrace? stackTrace,
    ErrorSeverity? severity,
    ErrorRecoveryStrategy? recoveryStrategy,
    int? maxRetries,
  }) async {
    if (!_isInitialized) {
      return ErrorResult(
        success: false,
        error: 'Error handling engine not initialized',
      );
    }

    final errorReport = ErrorReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type ?? _determineErrorType(error),
      message: error.toString(),
      context: context,
      component: component,
      severity: severity ?? _determineErrorSeverity(error),
      timestamp: DateTime.now(),
      stackTrace: stackTrace?.toString(),
      metadata: metadata ?? {},
      retryCount: 0,
      resolved: false,
    );

    // Log error
    await _logError(errorReport);

    // Update statistics
    await _updateStatistics(errorReport);

    // Check circuit breaker
    final circuitBreaker = _getCircuitBreaker(component);
    if (circuitBreaker != null && !circuitBreaker.canExecute()) {
      return ErrorResult(
        success: false,
        error: 'Circuit breaker is open for component: $component',
        circuitBreakerOpen: true,
      );
    }

    // Attempt recovery
    final success = await _attemptRecovery(errorReport, recoveryStrategy, maxRetries);
    
    if (success) {
      errorReport.resolved = true;
      await _logError(ErrorType.recoverySuccess, {
        'originalErrorId': errorReport.id,
        'strategy': recoveryStrategy?.name ?? 'none',
      });
    }

    return ErrorResult(
      success: success,
      error: success ? null : errorReport.message,
      errorReport: success ? null : errorReport,
      circuitBreakerOpen: !success && circuitBreaker?.isOpen ?? false,
    );
  }

  /// Attempt error recovery
  Future<bool> _attemptRecovery(
    ErrorReport errorReport,
    ErrorRecoveryStrategy? strategy,
    int? maxRetries,
  ) async {
    final strategyToUse = strategy ?? _getRecoveryStrategy(errorReport);
    
    if (!strategyToUse.canRetry) {
      return false;
    }

    final maxRetriesToUse = maxRetries ?? strategyToUse.maxRetries;
    
    for (int attempt = 0; attempt < maxRetriesToUse; attempt++) {
      try {
        final delay = strategyToUse.baseDelay * 
            pow(strategyToUse.multiplier, attempt);
        
        if (delay > Duration.zero) {
          await Future.delayed(delay);
        }

        final success = await _executeRecovery(errorReport, strategyToUse);
        
        if (success) {
          errorReport.retryCount = attempt + 1;
          errorReport.resolved = true;
          errorReport.recoveredAt = DateTime.now();
          
          // Record recovery time
          final metrics = _metrics[errorReport.type.name];
          if (metrics != null) {
            metrics.recoveryTimes.add(DateTime.now().difference(errorReport.timestamp).inMilliseconds);
          }
          
          return true;
        }
      } catch (e) {
        errorReport.retryCount++;
        errorReport.lastError = e.toString();
        
        if (attempt == maxRetriesToUse - 1) {
          // Last attempt failed
          return false;
        }
      }
    }

    return false;
  }

  Future<bool> _executeRecovery(ErrorReport errorReport, ErrorRecoveryStrategy strategy) async {
    switch (strategy.name) {
      case 'retry':
        return await _executeRetryRecovery(errorReport);
      case 'fallback':
        return await _executeFallbackRecovery(errorReport);
      case 'ignore':
        return await _executeIgnoreRecovery(errorReport);
      case 'restart':
        return await _executeRestartRecovery(errorReport);
      case 'escalate':
        return await _executeEscalateRecovery(errorReport);
      default:
        return false;
    }
  }

  Future<bool> _executeRetryRecovery(ErrorReport errorReport) async {
    // In a real implementation, this would retry the original operation
    // For now, we'll simulate success
    await Future.delayed(Duration(milliseconds: 100));
    return true;
  }

  Future<bool> _executeFallbackRecovery(ErrorReport errorReport) async {
    // Execute fallback handler if available
    final fallbackHandler = _fallbackHandlers[errorReport.component];
    if (fallbackHandler != null) {
      return await fallbackHandler(errorReport);
    }
    return false;
  }

  Future<bool> _executeIgnoreRecovery(ErrorReport errorReport) async {
    // Simply ignore the error
    return true;
  }

  Future<bool> _executeRestartRecovery(ErrorReport errorReport) async {
    // Restart the component
    // In a real implementation, this would restart the specific component
    return true;
  }

  CircuitBreaker? _getCircuitBreaker(String? component) {
    if (component == null) return null;
    return _circuitBreakers[component];
  }

  ErrorType _determineErrorType(dynamic error) {
    if (error is SocketException) {
      return ErrorType.network;
    } else if (error is DatabaseException) {
      return ErrorType.database;
    } else if (error is FormatException) {
      return ErrorType.validation;
    } else if (error is StateError) {
      return ErrorType.system;
    } else if (error is RangeError) {
      return ErrorType.validation;
    } else {
      return ErrorType.unknown;
    }
  }

  ErrorSeverity _determineErrorSeverity(dynamic error) {
    // Determine severity based on error type and context
    final errorType = _determineErrorType(error);
    
    switch (errorType) {
      case ErrorType.network:
        return ErrorSeverity.high;
      case ErrorType.database:
        return ErrorSeverity.critical;
      case ErrorType.authentication:
        return ErrorSeverity.critical;
      case ErrorType.validation:
        return ErrorSeverity.medium;
      case ErrorType.business:
        return ErrorSeverity.medium;
      case ErrorType.system:
        return ErrorSeverity.high;
      case ErrorType.ui:
        return ErrorSeverity.low;
      case ErrorType.unknown:
      default:
        return ErrorSeverity.medium;
    }
  }

  ErrorRecoveryStrategy _getRecoveryStrategy(ErrorReport errorReport) {
    // Determine recovery strategy based on error type and severity
    final errorType = errorReport.type;
    final severity = errorReport.severity;
    
    // Critical errors require escalation
    if (severity.level >= 4) {
      return _recoveryStrategies['escalate']!;
    }
    
    // Network errors typically use retry
    if (errorType == ErrorType.network) {
      return _recoveryStrategies['retry']!;
    }
    
    // Database errors may need fallback or restart
    if (errorType == ErrorType.database) {
      return _recoveryStrategies['fallback']!;
    }
    
    // Validation errors can be ignored
    if (errorType == ErrorType.validation) {
      return _recoveryStrategies['ignore']!;
    }
    
    // Default to retry
    return _recoveryStrategies['retry']!;
  }

  /// Log error
  Future<void> _logError(ErrorType type, String message, {Map<String, dynamic>? metadata}) async {
    if (!_enableLogging) return;

    try {
      final logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'type': type.name,
        'message': message,
        'metadata': metadata ?? {},
      };

      if (_logFilePath != null) {
        final logFile = File(_logFilePath!);
        await logFile.writeAsString('${jsonEncode(logEntry)}\n', mode: FileMode.append);
      }

      print('[${type.name.toUpperCase()}] $message');
    } catch (e) {
      print('Failed to log error: $e');
    }
  }

  /// Update error statistics
  Future<void> _updateStatistics(ErrorReport errorReport) async {
    // Update global stats
    final globalStats = _metrics['global']!;
    globalStats.totalErrors++;
    
    switch (errorReport.severity.level) {
      case 5:
        globalStats.criticalErrors++;
        break;
      case 4:
        globalStats.highErrors++;
        break;
      case 3:
        globalStats.mediumErrors++;
        break;
      case 2:
        globalStats.lowErrors++;
        break;
      case 1:
        globalStats.infoMessages++;
        break;
    }

    // Update category stats
    final categoryStats = _metrics[errorReport.type.name];
    if (categoryStats != null) {
      switch (errorReport.severity.level) {
        case 5:
          categoryStats.criticalErrors++;
          break;
        case 4:
          categoryStats.highErrors++;
          break;
        case 3:
          categoryStats.mediumErrors++;
          break;
        case 2:
          categoryStats.lowErrors++;
          break;
        case 1:
          categoryStats.infoMessages++;
          break;
      }
    }

    // Update component stats
    if (errorReport.component != null) {
      final componentStats = _metrics[errorReport.component!];
      if (componentStats == null) {
        _metrics[errorReport.component!] = ErrorMetrics(
          type: errorReport.component!,
          totalErrors: 1,
          criticalErrors: errorReport.severity.level >= 5 ? 1 : 0,
          highErrors: errorReport.severity.level >= 4 ? 1 : 0,
          mediumErrors: errorReport.severity.level >= 3 ? 1 : 0,
          lowErrors: errorReport.severity.level >= 2 ? 1 : 0,
          infoMessages: errorReport.severity.level <= 1 ? 1 : 0,
          averageRecoveryTime: 0.0,
          successRate: 0.0,
          lastErrorTime: DateTime.now(),
        );
      }
    }

    // Add to error log
    _errorLog.add(errorReport);
    
    // Add to error history
    final history = _errorHistory[errorReport.type.name] ?? [];
    history.add(errorReport);
    
    // Limit history size
    if (history.length > 100) {
      history.removeRange(0, history.length - 100);
    }

    // Limit error log size
    if (_errorLog.length > 1000) {
      _errorLog.removeRange(0, _errorLog.length - 1000);
    }
  }

  /// Get error statistics
  Map<String, dynamic> getErrorStatistics() {
    return {
      'isInitialized': _isInitialized,
      'enableLogging': _enableLogging,
      'enableMetrics': _enableMetrics,
      'enableRecovery': _enableRecovery,
      'enableCircuitBreaker': _enableCircuitBreaker,
      'totalErrors': _metrics['global']?.totalErrors ?? 0,
      'criticalErrors': _metrics['global']?.criticalErrors ?? 0,
      'highErrors': _metrics['global']?.highErrors ?? 0,
      'mediumErrors': _metrics['global']?.mediumErrors ?? 0,
      'lowErrors': _errorLog.where((e) => e.severity.level == 2).length,
      'infoMessages': _errorLog.where((e) => e.severity.level == 1).length,
      'successRate': _metrics['global']?.successRate ?? 1.0,
      'averageRecoveryTime': _metrics['global']?.averageRecoveryTime ?? 0.0,
      'lastErrorTime': _metrics['global']?.lastErrorTime?.toIso8601String(),
      'categoryStats': _metrics.map((k, v) => MapEntry(k, v.toMap())),
      'componentStats': _metrics.where((k, v) => k != 'global').map((k, v) => MapEntry(k, v.toMap())),
      'circuitBreakers': _circuitBreakers.map((k, v) => MapEntry(k, v.toMap())),
      'configuration': {
        'defaultFailureThreshold': _defaultFailureThreshold,
        'defaultRecoveryTimeout': _defaultRecoveryTimeout.inSeconds,
        'defaultRetryPolicy': _defaultRetryPolicy.name,
        'maxRetries': _maxRetries,
        'baseRetryDelay': _baseRetryDelay.inSeconds,
        'retryMultiplier': _retryMultiplier,
      },
    };
  }

  /// Register fallback handler
  void registerFallbackHandler(String component, FallbackHandler handler) {
    _fallbackHandlers[component] = handler;
  }

  /// Unregister fallback handler
  void unregisterFallbackHandler(String component) {
    _fallbackHandlers.remove(component);
  }

  /// Create circuit breaker
  CircuitBreaker createCircuitBreaker({
    String? component,
    int? failureThreshold,
    Duration? recoveryTimeout,
  }) {
    final id = component ?? 'default';
    final circuitBreaker = CircuitBreaker(
      failureThreshold: failureThreshold ?? _defaultFailureThreshold,
      recoveryTimeout: recoveryTimeout ?? _defaultRecoveryTimeout,
    );
    
    _circuitBreakers[id] = circuitBreaker;
    return circuitBreaker;
  }

  /// Dispose error handling engine
  Future<void> dispose() async {
    _metricsTimer?.cancel();
    _connectivitySubscription?.cancel();
    
    _errorCategories.clear();
    _errorSeverities.clear();
    _recoveryStrategies.clear();
    _circuitBreakers.clear();
    _metrics.clear();
    _errorLog.clear();
    _errorHistory.clear();
    _fallbackHandlers.clear();
    
    _isInitialized = false;
  }
}

// Error Models
class ErrorResult {
  final bool success;
  final String? error;
  final ErrorReport? errorReport;
  final bool circuitBreakerOpen;

  const ErrorResult({
    required this.success,
    this.error,
    this.errorReport,
    this.circuitBreakerOpen = false,
  });
}

class ErrorReport {
  final String id;
  final ErrorType type;
  final String message;
  final String? context;
  final String? component;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final String? stackTrace;
  final Map<String, dynamic> metadata;
  int retryCount;
  bool resolved;
  DateTime? recoveredAt;

  const ErrorReport({
    required this.id,
    required this.type,
    required this.message,
    this.context,
    this.component,
    required this.severity,
    required this.timestamp,
    this.stackTrace,
    this.metadata = const {},
    this.retryCount = 0,
    this.resolved = false,
    this.recoveredAt,
  });
}

class ErrorCategory {
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const ErrorCategory({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class ErrorSeverity {
  final String name;
  final String description;
  final int level;
  final Color color;
  final bool requiresNotification;
  final bool requiresIntervention;

  const ErrorSeverity({
    required this.name,
    required this.description,
    required this.level,
    required this.color,
    this.requiresNotification = false,
    this.requiresIntervention = false,
  });
}

class ErrorRecoveryStrategy {
  final String name;
  final String description;
  final bool canRetry;
  final int maxRetries;
  final Duration baseDelay;
  final double multiplier;

  const ErrorRecoveryStrategy({
    required this.name,
    required this.description,
    required this.canRetry,
    required this.maxRetries,
    required this.baseDelay,
    required this.multiplier,
  });
}

class CircuitBreaker {
  final int failureThreshold;
  final Duration recoveryTimeout;
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  bool _isOpen = false;

  CircuitBreaker({
    required this.failureThreshold,
    required this.recoveryTimeout,
  });

  bool get canExecute => !_isOpen;

  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    
    if (_failureCount >= failureThreshold) {
      _isOpen = true;
    }
  }

  void recordSuccess() {
    _failureCount = 0;
    _isOpen = false;
    _lastFailureTime = null;
  }

  void reset() {
    _failureCount = 0;
    _isOpen = false;
    _lastFailureTime = null;
  }

  Map<String, dynamic> toMap() {
    return {
      'failureThreshold': failureThreshold,
      'recoveryTimeout': recoveryTimeout.inSeconds,
      'failureCount': _failureCount,
      'lastFailureTime': _lastFailureTime?.toIso8601String(),
      'isOpen': _isOpen,
    };
  }
}

class ErrorMetrics {
  final String type;
  int totalErrors;
  int criticalErrors;
  int highErrors;
  int mediumErrors;
  int lowErrors;
  int infoMessages;
  double averageRecoveryTime;
  double successRate;
  DateTime? lastErrorTime;
  final List<int> recoveryTimes = [];

  ErrorMetrics({
    required this.type,
    this.totalErrors = 0,
    this.criticalErrors = 0,
    this.highErrors = 0,
    this.mediumErrors = 0,
    this.lowErrors = 0,
    this.infoMessages = 0,
    this.averageRecoveryTime = 0.0,
    this.successRate = 1.0,
    this.lastErrorTime,
    this.recoveryTimes = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'totalErrors': totalErrors,
      'criticalErrors': criticalErrors,
      'highErrors: highErrors,
      'mediumErrors: mediumErrors,
      'lowErrors': lowErrors,
      'infoMessages': infoMessages,
      'averageRecoveryTime': averageRecoveryTime,
      'successRate': successRate,
      'lastErrorTime': lastErrorTime?.toIso8601String(),
      'recoveryTimes': recoveryTimes,
    };
  }
}

class FallbackHandler {
  final Future<bool> Function(ErrorReport) handler;

  const FallbackHandler({required this.handler});
}

// Enums
enum ErrorType {
  network,
  database,
  authentication,
  validation,
  business,
  system,
  ui,
  unknown,
  recoverySuccess,
  initializationFailed,
  connectionFailed,
  connectionError,
  queueProcessingFailed,
  realtimeSyncFailed,
  messageProcessingFailed,
  unknownEvent,
}

enum RetryPolicy {
  constant,
  linear,
  exponential,
  fibonacci,
}

enum SyncStatusType {
  synced,
  pending,
  conflicted,
  error,
}

// Extensions
extension double pow(double base, int exponent) {
  return math.pow(base, exponent);
}
