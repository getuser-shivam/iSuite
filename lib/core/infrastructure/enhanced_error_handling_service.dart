import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/central_config.dart';
import 'logging_service.dart';

/// Enhanced Error Handling Service for iSuite
/// Provides comprehensive error management, validation, and recovery mechanisms
class EnhancedErrorHandlingService {
  static final EnhancedErrorHandlingService _instance =
      EnhancedErrorHandlingService._internal();
  factory EnhancedErrorHandlingService() => _instance;

  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();

  // Error tracking and analytics
  final Map<String, ErrorAnalytics> _errorAnalytics = {};
  final Map<String, ErrorRecoveryStrategy> _recoveryStrategies = {};
  final Map<String, ErrorBoundary> _errorBoundaries = {};

  // Validation rules
  final Map<String, ValidationRule> _validationRules = {};
  final Map<String, InputValidator> _inputValidators = {};

  // Recovery mechanisms
  final Map<String, RecoveryHandler> _recoveryHandlers = {};

  bool _isInitialized = false;

  EnhancedErrorHandlingService._internal();

  /// Initialize enhanced error handling service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Register with CentralConfig
      await _config.registerComponent('EnhancedErrorHandlingService', '2.0.0',
          'Comprehensive error handling with validation, recovery, and analytics',
          dependencies: [
            'CentralConfig',
            'LoggingService'
          ],
          parameters: {
            // Error tracking
            'error.tracking.enabled': true,
            'error.tracking.max_errors_per_component': 1000,
            'error.tracking.retention_days': 30,

            // Validation
            'error.validation.enabled': true,
            'error.validation.strict_mode': false,
            'error.validation.custom_rules_enabled': true,

            // Recovery
            'error.recovery.enabled': true,
            'error.recovery.auto_retry_enabled': true,
            'error.recovery.max_retry_attempts': 3,
            'error.recovery.retry_delay_ms': 1000,

            // Error boundaries
            'error.boundaries.enabled': true,
            'error.boundaries.fallback_ui_enabled': true,
            'error.boundaries.error_reporting_enabled': false,

            // Analytics
            'error.analytics.enabled': true,
            'error.analytics.pattern_detection_enabled': true,
            'error.analytics.predictive_alerts_enabled': false,
          });

      // Setup default recovery strategies
      await _setupDefaultRecoveryStrategies();

      // Setup default validation rules
      await _setupDefaultValidationRules();

      _isInitialized = true;

      _logger.info('Enhanced Error Handling Service initialized successfully',
          'EnhancedErrorHandlingService');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Enhanced Error Handling Service',
          'EnhancedErrorHandlingService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Handle error with comprehensive analysis and recovery
  Future<ErrorResult> handleError(
    dynamic error,
    StackTrace? stackTrace, {
    String? component,
    String? operation,
    Map<String, dynamic>? context,
    ErrorSeverity severity = ErrorSeverity.medium,
  }) async {
    final errorInfo = ErrorInfo(
      error: error,
      stackTrace: stackTrace,
      component: component ?? 'Unknown',
      operation: operation,
      context: context ?? {},
      severity: severity,
      timestamp: DateTime.now(),
    );

    // Log the error
    await _logError(errorInfo);

    // Analyze the error
    final analysis = await _analyzeError(errorInfo);

    // Attempt recovery
    final recoveryResult = await _attemptRecovery(errorInfo, analysis);

    // Track analytics
    await _trackErrorAnalytics(errorInfo, analysis, recoveryResult);

    return ErrorResult(
      handled: recoveryResult.success,
      recovered: recoveryResult.success,
      analysis: analysis,
      recoveryResult: recoveryResult,
    );
  }

  /// Validate input with comprehensive validation rules
  Future<ValidationResult> validateInput(
    dynamic input, {
    String? validatorName,
    Map<String, dynamic>? context,
  }) async {
    final validator = validatorName != null
        ? _inputValidators[validatorName]
        : _getDefaultValidator(input.runtimeType);

    if (validator == null) {
      return ValidationResult(
        isValid: true,
        errors: [],
        warnings: ['No validator found for type: ${input.runtimeType}'],
      );
    }

    return await validator.validate(input, context: context);
  }

  /// Register custom error recovery strategy
  void registerRecoveryStrategy(
      String errorType, ErrorRecoveryStrategy strategy) {
    _recoveryStrategies[errorType] = strategy;
    _logger.info('Recovery strategy registered for error type: $errorType',
        'EnhancedErrorHandlingService');
  }

  /// Register custom validation rule
  void registerValidationRule(String ruleName, ValidationRule rule) {
    _validationRules[ruleName] = rule;
    _logger.info('Validation rule registered: $ruleName',
        'EnhancedErrorHandlingService');
  }

  /// Register input validator
  void registerInputValidator(String name, InputValidator validator) {
    _inputValidators[name] = validator;
    _logger.info(
        'Input validator registered: $name', 'EnhancedErrorHandlingService');
  }

  /// Register error boundary
  void registerErrorBoundary(String component, ErrorBoundary boundary) {
    _errorBoundaries[component] = boundary;
    _logger.info('Error boundary registered for component: $component',
        'EnhancedErrorHandlingService');
  }

  /// Get error analytics
  ErrorAnalytics getErrorAnalytics(String component) {
    return _errorAnalytics.putIfAbsent(
        component, () => ErrorAnalytics(component));
  }

  /// Execute operation with error handling and recovery
  Future<T> executeWithErrorHandling<T>(
    Future<T> Function() operation, {
    String? component,
    String? operationName,
    Map<String, dynamic>? context,
    int maxRetries = 3,
  }) async {
    int attempts = 0;

    while (attempts <= maxRetries) {
      try {
        return await operation();
      } catch (e, stackTrace) {
        attempts++;

        final result = await handleError(
          e,
          stackTrace,
          component: component,
          operation: operationName,
          context: {...?context, 'attempt': attempts, 'maxRetries': maxRetries},
        );

        if (!result.recovered && attempts > maxRetries) {
          rethrow;
        }

        // Wait before retry if not the last attempt
        if (attempts <= maxRetries) {
          final delay = await _config
                  .getParameter<int>('error.recovery.retry_delay_ms') ??
              1000;
          await Future.delayed(Duration(milliseconds: delay));
        }
      }
    }

    throw Exception('Operation failed after $maxRetries retries');
  }

  /// Private helper methods

  Future<void> _logError(ErrorInfo errorInfo) async {
    final level = _getLogLevel(errorInfo.severity);
    final message = _formatErrorMessage(errorInfo);

    _logger.log(level, message, errorInfo.component,
        error: errorInfo.error, stackTrace: errorInfo.stackTrace);
  }

  Level _getLogLevel(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Level.debug;
      case ErrorSeverity.medium:
        return Level.warning;
      case ErrorSeverity.high:
        return Level.error;
      case ErrorSeverity.critical:
        return Level.fatal;
    }
  }

  String _formatErrorMessage(ErrorInfo errorInfo) {
    final buffer = StringBuffer();

    buffer.write('Error in ${errorInfo.component}');
    if (errorInfo.operation != null) {
      buffer.write(' during ${errorInfo.operation}');
    }
    buffer.write(': ${errorInfo.error}');

    if (errorInfo.context.isNotEmpty) {
      buffer.write(' (Context: ${jsonEncode(errorInfo.context)})');
    }

    return buffer.toString();
  }

  Future<ErrorAnalysis> _analyzeError(ErrorInfo errorInfo) async {
    final analysis = ErrorAnalysis(
      errorType: _classifyError(errorInfo.error),
      rootCause: await _identifyRootCause(errorInfo),
      impact: _assessImpact(errorInfo),
      suggestions: await _generateSuggestions(errorInfo),
      confidence: 0.8,
    );

    return analysis;
  }

  String _classifyError(dynamic error) {
    if (error is Exception) {
      return error.runtimeType.toString();
    } else if (error is Error) {
      return error.runtimeType.toString();
    } else {
      return 'Unknown';
    }
  }

  Future<String> _identifyRootCause(ErrorInfo errorInfo) async {
    // Simple root cause analysis - can be enhanced with ML
    final error = errorInfo.error;

    if (error.toString().contains('Network')) {
      return 'Network connectivity issue';
    } else if (error.toString().contains('Permission')) {
      return 'Insufficient permissions';
    } else if (error.toString().contains('Validation')) {
      return 'Input validation failure';
    } else if (error.toString().contains('Timeout')) {
      return 'Operation timeout';
    } else {
      return 'Unknown root cause';
    }
  }

  ErrorImpact _assessImpact(ErrorInfo errorInfo) {
    switch (errorInfo.severity) {
      case ErrorSeverity.low:
        return ErrorImpact.low;
      case ErrorSeverity.medium:
        return ErrorImpact.medium;
      case ErrorSeverity.high:
        return ErrorImpact.high;
      case ErrorSeverity.critical:
        return ErrorImpact.critical;
    }
  }

  Future<List<String>> _generateSuggestions(ErrorInfo errorInfo) async {
    final suggestions = <String>[];

    final errorString = errorInfo.error.toString().toLowerCase();

    if (errorString.contains('network')) {
      suggestions.add('Check internet connectivity');
      suggestions.add('Verify network permissions');
    } else if (errorString.contains('permission')) {
      suggestions.add('Request necessary permissions');
      suggestions.add('Check app permissions in device settings');
    } else if (errorString.contains('validation')) {
      suggestions.add('Validate input data');
      suggestions.add('Check data format and constraints');
    } else if (errorString.contains('timeout')) {
      suggestions.add('Increase timeout duration');
      suggestions.add('Check server responsiveness');
    }

    suggestions.add('Enable detailed logging for more information');
    suggestions.add('Contact support if issue persists');

    return suggestions;
  }

  Future<RecoveryResult> _attemptRecovery(
      ErrorInfo errorInfo, ErrorAnalysis analysis) async {
    final strategy = _recoveryStrategies[analysis.errorType];

    if (strategy != null) {
      try {
        final success = await strategy.recover(errorInfo, analysis);
        return RecoveryResult(
          success: success,
          strategy: strategy.name,
          details: success ? 'Recovery successful' : 'Recovery failed',
        );
      } catch (e) {
        return RecoveryResult(
          success: false,
          strategy: strategy.name,
          details: 'Recovery exception: $e',
        );
      }
    }

    return RecoveryResult(
      success: false,
      strategy: 'none',
      details: 'No recovery strategy available',
    );
  }

  Future<void> _trackErrorAnalytics(
    ErrorInfo errorInfo,
    ErrorAnalysis analysis,
    RecoveryResult recovery,
  ) async {
    final analytics = getErrorAnalytics(errorInfo.component);
    analytics.recordError(errorInfo, analysis, recovery);
  }

  Future<void> _setupDefaultRecoveryStrategies() async {
    // Network error recovery
    registerRecoveryStrategy(
        'NetworkException',
        ErrorRecoveryStrategy(
          name: 'Network Retry',
          recover: (errorInfo, analysis) async {
            // Implement network retry logic
            await Future.delayed(const Duration(seconds: 1));
            return false; // Placeholder - would implement actual retry
          },
        ));

    // Permission error recovery
    registerRecoveryStrategy(
        'PermissionException',
        ErrorRecoveryStrategy(
          name: 'Permission Request',
          recover: (errorInfo, analysis) async {
            // Implement permission request logic
            return false; // Placeholder - would implement actual permission request
          },
        ));

    // Validation error recovery
    registerRecoveryStrategy(
        'ValidationException',
        ErrorRecoveryStrategy(
          name: 'Input Sanitization',
          recover: (errorInfo, analysis) async {
            // Implement input sanitization
            return false; // Placeholder - would implement actual sanitization
          },
        ));
  }

  Future<void> _setupDefaultValidationRules() async {
    // Email validation
    registerValidationRule(
        'email',
        ValidationRule(
          name: 'Email Validation',
          validate: (value) {
            if (value == null) return ValidationResult.valid();
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            return emailRegex.hasMatch(value.toString())
                ? ValidationResult.valid()
                : ValidationResult.invalid(['Invalid email format']);
          },
        ));

    // Required field validation
    registerValidationRule(
        'required',
        ValidationRule(
          name: 'Required Field',
          validate: (value) {
            return (value != null && value.toString().trim().isNotEmpty)
                ? ValidationResult.valid()
                : ValidationResult.invalid(['Field is required']);
          },
        ));

    // Length validation
    registerValidationRule(
        'length',
        ValidationRule(
          name: 'Length Validation',
          validate: (value) {
            if (value == null) return ValidationResult.valid();
            final str = value.toString();
            return (str.length >= 1 && str.length <= 1000)
                ? ValidationResult.valid()
                : ValidationResult.invalid(
                    ['Length must be between 1 and 1000 characters']);
          },
        ));
  }

  InputValidator _getDefaultValidator(Type type) {
    return InputValidator(
      name: 'Default ${type.toString()} Validator',
      validate: (input, {context}) async {
        // Basic validation - can be enhanced
        if (input == null) {
          return ValidationResult.invalid(['Input cannot be null']);
        }
        return ValidationResult.valid();
      },
    );
  }
}

// Supporting classes

enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

enum ErrorImpact {
  low,
  medium,
  high,
  critical,
}

class ErrorInfo {
  final dynamic error;
  final StackTrace? stackTrace;
  final String component;
  final String? operation;
  final Map<String, dynamic> context;
  final ErrorSeverity severity;
  final DateTime timestamp;

  ErrorInfo({
    required this.error,
    this.stackTrace,
    required this.component,
    this.operation,
    required this.context,
    required this.severity,
    required this.timestamp,
  });
}

class ErrorAnalysis {
  final String errorType;
  final String rootCause;
  final ErrorImpact impact;
  final List<String> suggestions;
  final double confidence;

  ErrorAnalysis({
    required this.errorType,
    required this.rootCause,
    required this.impact,
    required this.suggestions,
    required this.confidence,
  });
}

class RecoveryResult {
  final bool success;
  final String strategy;
  final String details;

  RecoveryResult({
    required this.success,
    required this.strategy,
    required this.details,
  });
}

class ErrorResult {
  final bool handled;
  final bool recovered;
  final ErrorAnalysis? analysis;
  final RecoveryResult? recoveryResult;

  ErrorResult({
    required this.handled,
    required this.recovered,
    this.analysis,
    this.recoveryResult,
  });
}

class ErrorRecoveryStrategy {
  final String name;
  final Future<bool> Function(ErrorInfo errorInfo, ErrorAnalysis analysis)
      recover;

  ErrorRecoveryStrategy({
    required this.name,
    required this.recover,
  });
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  factory ValidationResult.valid() =>
      ValidationResult(isValid: true, errors: [], warnings: []);
  factory ValidationResult.invalid(List<String> errors) =>
      ValidationResult(isValid: false, errors: errors, warnings: []);
}

class ValidationRule {
  final String name;
  final ValidationResult Function(dynamic value) validate;

  ValidationRule({
    required this.name,
    required this.validate,
  });
}

class InputValidator {
  final String name;
  final Future<ValidationResult> Function(dynamic input,
      {Map<String, dynamic>? context}) validate;

  InputValidator({
    required this.name,
    required this.validate,
  });
}

class ErrorBoundary {
  final Widget Function(
      BuildContext context, dynamic error, StackTrace? stackTrace) builder;

  ErrorBoundary({required this.builder});
}

class ErrorAnalytics {
  final String component;
  final List<ErrorInfo> _errors = [];
  final Map<String, int> _errorCounts = {};

  ErrorAnalytics(this.component);

  void recordError(
      ErrorInfo errorInfo, ErrorAnalysis analysis, RecoveryResult recovery) {
    _errors.add(errorInfo);
    _errorCounts[analysis.errorType] =
        (_errorCounts[analysis.errorType] ?? 0) + 1;

    // Keep only last 1000 errors
    if (_errors.length > 1000) {
      _errors.removeRange(0, _errors.length - 1000);
    }
  }

  List<ErrorInfo> get recentErrors => List.from(_errors);
  Map<String, int> get errorCounts => Map.from(_errorCounts);
}
