import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/logging/logging_service.dart';
import '../../../core/security/security_manager.dart';
import '../../../core/config/central_config.dart';

/// Enhanced Input Validation System
/// Provides comprehensive input validation with security checks and sanitization
class EnhancedInputValidator {
  static final EnhancedInputValidator _instance = EnhancedInputValidator._internal();
  factory EnhancedInputValidator() => _instance;
  EnhancedInputValidator._internal();

  final LoggingService _logger = LoggingService();
  final SecurityManager _security = SecurityManager();
  final CentralConfig _config = CentralConfig.instance;

  // Validation rules cache
  final Map<String, ValidationRule> _rules = {};

  // Validation statistics
  int _totalValidations = 0;
  int _failedValidations = 0;
  final Map<String, int> _validationErrors = {};

  // Performance optimization: Validation cache
  final Map<String, _CachedValidationResult> _validationCache = {};

  // Performance metrics
  final List<ValidationMetric> _validationMetrics = [];

  /// Initialize validator with default rules
  void initialize() {
    _setupDefaultRules();
    _logger.info('Enhanced Input Validator initialized', 'EnhancedInputValidator');
  }

  void _setupDefaultRules() {
    // Email validation
    _rules['email'] = ValidationRule(
      name: 'email',
      pattern: _config.getParameter('validation.email.pattern', defaultValue: r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'),
      maxLength: _config.getParameter('validation.email.max_length', defaultValue: 254),
      required: false,
      securityCheck: true,
    );

    // Phone number validation
    _rules['phone'] = ValidationRule(
      name: 'phone',
      pattern: _config.getParameter('validation.phone.pattern', defaultValue: r'^\+?[\d\s\-\(\)]{10,15}$'),
      maxLength: _config.getParameter('validation.phone.max_length', defaultValue: 20),
      required: false,
      securityCheck: false,
    );

    // URL validation
    _rules['url'] = ValidationRule(
      name: 'url',
      pattern: _config.getParameter('validation.url.pattern', defaultValue: r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$'),
      maxLength: _config.getParameter('validation.url.max_length', defaultValue: 2048),
      required: false,
      securityCheck: true,
    );

    // Username validation
    _rules['username'] = ValidationRule(
      name: 'username',
      pattern: _config.getParameter('validation.username.pattern', defaultValue: r'^[a-zA-Z0-9_]{3,20}$'),
      minLength: _config.getParameter('validation.username.min_length', defaultValue: 3),
      maxLength: _config.getParameter('validation.username.max_length', defaultValue: 20),
      required: false,
      securityCheck: true,
    );

    // Password validation
    _rules['password'] = ValidationRule(
      name: 'password',
      minLength: _config.getParameter('validation.password.min_length', defaultValue: 8),
      maxLength: _config.getParameter('validation.password.max_length', defaultValue: 128),
      required: false,
      securityCheck: true,
      customValidator: _validatePasswordStrength,
    );

    // File path validation
    _rules['file_path'] = ValidationRule(
      name: 'file_path',
      maxLength: _config.getParameter('validation.file_path.max_length', defaultValue: 260), // Windows MAX_PATH
      required: false,
      securityCheck: true,
      sanitizer: _security.sanitizeFilePath,
    );

    // Text input validation
    _rules['text'] = ValidationRule(
      name: 'text',
      maxLength: _config.getParameter('validation.text.max_length', defaultValue: 10000),
      required: false,
      securityCheck: true,
    );

    // Number validation
    _rules['number'] = ValidationRule(
      name: 'number',
      pattern: r'^-?\d+(\.\d+)?$',
      required: false,
      securityCheck: false,
    );

    // IP address validation
    _rules['ip_address'] = ValidationRule(
      name: 'ip_address',
      pattern: r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
      required: false,
      securityCheck: false,
    );
  }

  /// Validate input against a rule with enhanced features
  ValidationResult validate(String? input, String ruleName, {
    bool required = false,
    Map<String, dynamic>? customParams,
    bool enableCache = true,
    bool enableMetrics = true,
  }) {
    final startTime = enableMetrics ? DateTime.now() : null;
    _totalValidations++;

    // Check cache if enabled
    if (enableCache && input != null) {
      final cacheKey = '${ruleName}_${input.hashCode}';
      final cachedResult = _validationCache[cacheKey];
      if (cachedResult != null && 
          DateTime.now().difference(cachedResult.timestamp).inMinutes < 5) {
        return cachedResult.result;
      }
    }

    final rule = _rules[ruleName];
    if (rule == null) {
      _recordValidationError(ruleName, 'Unknown validation rule');
      final result = ValidationResult(
        isValid: false,
        error: 'Unknown validation rule: $ruleName',
      );
      _cacheResult(ruleName, input, result, enableCache);
      return result;
    }

    // Enhanced required field check with context
    if ((rule.required || required) && (input == null || input.trim().isEmpty)) {
      final contextMessage = _getContextualErrorMessage(ruleName, 'required');
      _recordValidationError(ruleName, contextMessage);
      final result = ValidationResult(
        isValid: false,
        error: contextMessage,
        errorCode: 'VALIDATION_REQUIRED',
      );
      _cacheResult(ruleName, input, result, enableCache);
      return result;
    }

    // Skip further validation for empty optional fields
    if (input == null || input.trim().isEmpty) {
      final result = ValidationResult(isValid: true, sanitizedValue: input);
      _cacheResult(ruleName, input, result, enableCache);
      return result;
    }

    final trimmedInput = input.trim();

    // Enhanced length validation with detailed feedback
    if (rule.minLength != null && trimmedInput.length < rule.minLength!) {
      final contextMessage = _getContextualErrorMessage(ruleName, 'min_length', {
        'required': rule.minLength,
        'actual': trimmedInput.length,
      });
      _recordValidationError(ruleName, contextMessage);
      final result = ValidationResult(
        isValid: false,
        error: contextMessage,
        errorCode: 'VALIDATION_TOO_SHORT',
        metadata: {'minLength': rule.minLength, 'actualLength': trimmedInput.length},
      );
      _cacheResult(ruleName, input, result, enableCache);
      return result;
    }

    if (rule.maxLength != null && trimmedInput.length > rule.maxLength!) {
      final contextMessage = _getContextualErrorMessage(ruleName, 'max_length', {
        'allowed': rule.maxLength,
        'actual': trimmedInput.length,
      });
      _recordValidationError(ruleName, contextMessage);
      final result = ValidationResult(
        isValid: false,
        error: contextMessage,
        errorCode: 'VALIDATION_TOO_LONG',
        metadata: {'maxLength': rule.maxLength, 'actualLength': trimmedInput.length},
      );
      _cacheResult(ruleName, input, result, enableCache);
      return result;
    }

    // Pattern validation
    if (rule.pattern != null) {
      final regex = RegExp(rule.pattern!);
      if (!regex.hasMatch(trimmedInput)) {
        _recordValidationError(ruleName, 'Pattern mismatch');
        return ValidationResult(
          isValid: false,
          error: 'Invalid format',
        );
      }
    }

    // Custom validation
    if (rule.customValidator != null) {
      final customResult = rule.customValidator!(trimmedInput, customParams);
      if (!customResult.isValid) {
        _recordValidationError(ruleName, 'Custom validation failed');
        return customResult;
      }
    }

    // Security check
    if (rule.securityCheck) {
      if (_security.containsSensitiveData(trimmedInput)) {
        _recordValidationError(ruleName, 'Contains sensitive data');
        return ValidationResult(
          isValid: false,
          error: 'Input contains sensitive information',
        );
      }
    }

    // Sanitization
    String sanitizedValue = trimmedInput;
    if (rule.sanitizer != null) {
      sanitizedValue = rule.sanitizer!(trimmedInput);
    }

    return ValidationResult(
      isValid: true,
      sanitizedValue: sanitizedValue,
    );
  }

  /// Batch validate multiple inputs
  Map<String, ValidationResult> validateBatch(Map<String, dynamic> inputs, Map<String, String> rules) {
    final results = <String, ValidationResult>{};

    for (final entry in rules.entries) {
      final fieldName = entry.key;
      final ruleName = entry.value;
      final value = inputs[fieldName]?.toString();

      results[fieldName] = validate(value, ruleName);
    }

    return results;
  }

  /// Add custom validation rule
  void addRule(String name, ValidationRule rule) {
    _rules[name] = rule;
    _logger.info('Added custom validation rule: $name', 'EnhancedInputValidator');
  }

  /// Remove validation rule
  void removeRule(String name) {
    _rules.remove(name);
    _logger.info('Removed validation rule: $name', 'EnhancedInputValidator');
  }

  /// Get validation statistics with enhanced metrics
  Map<String, dynamic> getValidationStats() {
    final errorRate = _totalValidations > 0 ? (_failedValidations / _totalValidations) * 100 : 0.0;
    final cacheHitRate = _validationCache.isNotEmpty ? 
        (_validationCache.values.where((c) => DateTime.now().difference(c.timestamp).inMinutes < 5).length / _validationCache.length) * 100 : 0.0;

    // Calculate average validation time
    final avgValidationTime = _validationMetrics.isNotEmpty ?
        _validationMetrics.map((m) => m.duration.inMilliseconds).reduce((a, b) => a + b) / _validationMetrics.length : 0.0;

    return {
      'totalValidations': _totalValidations,
      'failedValidations': _failedValidations,
      'errorRate': '${errorRate.toStringAsFixed(2)}%',
      'commonErrors': _validationErrors,
      'activeRules': _rules.length,
      'cacheSize': _validationCache.length,
      'cacheHitRate': '${cacheHitRate.toStringAsFixed(2)}%',
      'averageValidationTime': '${avgValidationTime.toStringAsFixed(2)}ms',
      'metricsCollected': _validationMetrics.length,
    };
  }

  /// Cache validation result for performance optimization
  void _cacheResult(String ruleName, String? input, ValidationResult result, bool enableCache) {
    if (!enableCache || input == null) return;

    final cacheKey = '${ruleName}_${input.hashCode}';
    _validationCache[cacheKey] = _CachedValidationResult(result);

    // Limit cache size to prevent memory issues
    if (_validationCache.length > 1000) {
      _cleanupCache();
    }
  }

  /// Clean up old cache entries
  void _cleanupCache() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 10));
    _validationCache.removeWhere((key, value) => value.timestamp.isBefore(cutoff));
  }

  /// Get contextual error message based on validation rule and error type
  String _getContextualErrorMessage(String ruleName, String errorType, [Map<String, dynamic>? params]) {
    final contextMessages = _config.getMap('validation.context_messages', defaultValue: {
      'email': {
        'required': 'Email address is required for account creation',
        'min_length': 'Email address must be at least ${params?['required']} characters',
        'max_length': 'Email address cannot exceed ${params?['allowed']} characters',
        'pattern': 'Please enter a valid email address (e.g., user@example.com)',
      },
      'password': {
        'required': 'Password is required for security',
        'min_length': 'Password must be at least ${params?['required']} characters long',
        'max_length': 'Password cannot exceed ${params?['allowed']} characters',
        'pattern': 'Password must contain uppercase, lowercase, numbers, and special characters',
      },
      'username': {
        'required': 'Username is required for identification',
        'min_length': 'Username must be at least ${params?['required']} characters',
        'max_length': 'Username cannot exceed ${params?['allowed']} characters',
        'pattern': 'Username can only contain letters, numbers, and underscores',
      },
    });

    final ruleMessages = contextMessages[ruleName]?[errorType] ?? 
        'Invalid ${ruleName.replaceAll('_', ' ')}: ${errorType.replaceAll('_', ' ')}';

    return ruleMessages;
  }

  /// Record validation performance metrics
  void _recordValidationMetric(String ruleName, Duration duration, bool isValid) {
    _validationMetrics.add(ValidationMetric(
      ruleName: ruleName,
      duration: duration,
      isValid: isValid,
      timestamp: DateTime.now(),
    ));

    // Limit metrics collection to prevent memory issues
    if (_validationMetrics.length > 10000) {
      _validationMetrics.removeRange(0, 5000);
    }
  }

  /// Get performance analytics
  Map<String, dynamic> getPerformanceAnalytics() {
    if (_validationMetrics.isEmpty) return {'status': 'no_data'};

    final ruleMetrics = <String, List<ValidationMetric>>{};
    for (final metric in _validationMetrics) {
      ruleMetrics.putIfAbsent(metric.ruleName, () => []).add(metric);
    }

    final analytics = <String, dynamic>{};
    for (final entry in ruleMetrics.entries) {
      final metrics = entry.value;
      final totalTime = metrics.map((m) => m.duration.inMicroseconds).reduce((a, b) => a + b);
      final avgTime = totalTime / metrics.length;
      final successRate = metrics.where((m) => m.isValid).length / metrics.length * 100;

      analytics[entry.key] = {
        'totalValidations': metrics.length,
        'averageTime': '${(avgTime / 1000).toStringAsFixed(2)}ms',
        'successRate': '${successRate.toStringAsFixed(2)}%',
        'lastValidation': metrics.last.timestamp.toIso8601String(),
      };
    }

    return {
      'overall': {
        'totalMetrics': _validationMetrics.length,
        'timeRange': {
          'start': _validationMetrics.first.timestamp.toIso8601String(),
          'end': _validationMetrics.last.timestamp.toIso8601String(),
        },
      },
      'byRule': analytics,
    };
  }

  /// Password strength validation
  ValidationResult _validatePasswordStrength(String password, Map<String, dynamic>? params) {
    if (password.length < 8) {
      return ValidationResult(
        isValid: false,
        error: 'Password must be at least 8 characters long',
      );
    }

    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasNumbers = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!hasUppercase || !hasLowercase || !hasNumbers) {
      return ValidationResult(
        isValid: false,
        error: 'Password must contain uppercase, lowercase, and numeric characters',
      );
    }

    // Optional: Check for special characters
    if (params?['requireSpecialChars'] == true && !hasSpecialChars) {
      return ValidationResult(
        isValid: false,
        error: 'Password must contain special characters',
      );
    }

    return ValidationResult(isValid: true, sanitizedValue: password);
  }

  void _recordValidationError(String ruleName, String errorType) {
    _failedValidations++;
    _validationErrors[errorType] = (_validationErrors[errorType] ?? 0) + 1;

    _logger.warning('Validation failed: $ruleName - $errorType', 'EnhancedInputValidator');
  }

  /// Sanitize HTML input
  String sanitizeHtml(String input) {
    // Remove script tags and other dangerous elements
    return input
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]+>', caseSensitive: false), '')
        .trim();
  }

  /// Validate file upload
  ValidationResult validateFileUpload(File file, {
    List<String>? allowedExtensions,
    int? maxSizeBytes,
    bool checkForMalware = true,
  }) {
    // Check file size
    if (maxSizeBytes != null) {
      final stat = file.statSync();
      if (stat.size > maxSizeBytes) {
        return ValidationResult(
          isValid: false,
          error: 'File size exceeds maximum allowed size',
        );
      }
    }

    // Check file extension
    if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
      final extension = file.path.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(extension)) {
        return ValidationResult(
          isValid: false,
          error: 'File type not allowed',
        );
      }
    }

    // Basic malware check (check for suspicious patterns)
    if (checkForMalware) {
      try {
        final content = file.readAsStringSync();
        if (_security.containsSensitiveData(content) ||
            content.contains('\x00') && content.length > 100) {
          return ValidationResult(
            isValid: false,
            error: 'File contains suspicious content',
          );
        }
      } catch (e) {
        // If we can't read the file as text, assume it's binary and okay
      }
    }

    return ValidationResult(isValid: true, sanitizedValue: file.path);
  }
}

/// Validation rule definition
class ValidationRule {
  final String name;
  final String? pattern;
  final int? minLength;
  final int? maxLength;
  final bool required;
  final bool securityCheck;
  final ValidationResult Function(String, Map<String, dynamic>?)? customValidator;
  final String Function(String)? sanitizer;

  ValidationRule({
    required this.name,
    this.pattern,
    this.minLength,
    this.maxLength,
    this.required = false,
    this.securityCheck = false,
    this.customValidator,
    this.sanitizer,
  });
}

/// State Persistence Manager
/// Provides robust state persistence and recovery mechanisms
class StatePersistenceManager {
  static final StatePersistenceManager _instance = StatePersistenceManager._internal();
  factory StatePersistenceManager() => _instance;
  StatePersistenceManager._internal();

  final LoggingService _logger = LoggingService();

  final Map<String, StateSnapshot> _stateSnapshots = {};
  final Map<String, StateRecoveryStrategy> _recoveryStrategies = {};
  Timer? _autoSaveTimer;

  bool _isInitialized = false;
  Directory? _persistenceDirectory;

  /// Initialize state persistence
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Create persistence directory
      final appDir = await getApplicationDocumentsDirectory();
      _persistenceDirectory = Directory('${appDir.path}/state_persistence');

      if (!await _persistenceDirectory!.exists()) {
        await _persistenceDirectory!.create(recursive: true);
      }

      // Load existing state snapshots
      await _loadPersistedStates();

      // Start auto-save timer
      _autoSaveTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        _autoSaveStates();
      });

      _isInitialized = true;
      _logger.info('State Persistence Manager initialized', 'StatePersistenceManager');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize State Persistence Manager', 'StatePersistenceManager',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Save state snapshot
  Future<void> saveState(String stateId, Map<String, dynamic> state, {
    String? description,
    bool isCritical = false,
  }) async {
    try {
      final snapshot = StateSnapshot(
        id: stateId,
        data: state,
        timestamp: DateTime.now(),
        description: description,
        isCritical: isCritical,
        checksum: _calculateChecksum(state),
      );

      _stateSnapshots[stateId] = snapshot;

      // Persist to disk
      await _persistState(snapshot);

      _logger.debug('State saved: $stateId', 'StatePersistenceManager');

    } catch (e, stackTrace) {
      _logger.error('Failed to save state: $stateId', 'StatePersistenceManager',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Load state snapshot
  Future<Map<String, dynamic>?> loadState(String stateId) async {
    try {
      final snapshot = _stateSnapshots[stateId];
      if (snapshot != null) {
        // Verify checksum
        if (_calculateChecksum(snapshot.data) == snapshot.checksum) {
          _logger.debug('State loaded: $stateId', 'StatePersistenceManager');
          return snapshot.data;
        } else {
          _logger.warning('State checksum mismatch for: $stateId', 'StatePersistenceManager');
          // Try recovery
          return await _attemptRecovery(stateId, snapshot);
        }
      }
      return null;

    } catch (e, stackTrace) {
      _logger.error('Failed to load state: $stateId', 'StatePersistenceManager',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Delete state snapshot
  Future<void> deleteState(String stateId) async {
    try {
      _stateSnapshots.remove(stateId);

      // Remove from disk
      final stateFile = File('${_persistenceDirectory!.path}/$stateId.json');
      if (await stateFile.exists()) {
        await stateFile.delete();
      }

      _logger.debug('State deleted: $stateId', 'StatePersistenceManager');

    } catch (e, stackTrace) {
      _logger.error('Failed to delete state: $stateId', 'StatePersistenceManager',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Register recovery strategy
  void registerRecoveryStrategy(String stateId, StateRecoveryStrategy strategy) {
    _recoveryStrategies[stateId] = strategy;
    _logger.info('Recovery strategy registered for: $stateId', 'StatePersistenceManager');
  }

  /// Get all saved states
  Map<String, StateSnapshot> getSavedStates() {
    return Map.unmodifiable(_stateSnapshots);
  }

  /// Clear old states
  Future<void> cleanupOldStates({Duration maxAge = const Duration(days: 7)}) async {
    try {
      final cutoff = DateTime.now().subtract(maxAge);
      final toRemove = <String>[];

      for (final entry in _stateSnapshots.entries) {
        if (!entry.value.isCritical && entry.value.timestamp.isBefore(cutoff)) {
          toRemove.add(entry.key);
        }
      }

      for (final stateId in toRemove) {
        await deleteState(stateId);
      }

      if (toRemove.isNotEmpty) {
        _logger.info('Cleaned up ${toRemove.length} old state snapshots', 'StatePersistenceManager');
      }

    } catch (e, stackTrace) {
      _logger.error('Failed to cleanup old states', 'StatePersistenceManager',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Export state for backup
  Future<String> exportStates() async {
    try {
      final exportData = {
        'exportTime': DateTime.now().toIso8601String(),
        'version': '1.0',
        'states': _stateSnapshots.map((key, value) => MapEntry(key, value.toJson())),
      };

      return jsonEncode(exportData);

    } catch (e, stackTrace) {
      _logger.error('Failed to export states', 'StatePersistenceManager',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Import states from backup
  Future<void> importStates(String exportData) async {
    try {
      final data = jsonDecode(exportData);
      final states = data['states'] as Map<String, dynamic>;

      for (final entry in states.entries) {
        final snapshot = StateSnapshot.fromJson(entry.value);
        _stateSnapshots[entry.key] = snapshot;
        await _persistState(snapshot);
      }

      _logger.info('Imported ${states.length} state snapshots', 'StatePersistenceManager');

    } catch (e, stackTrace) {
      _logger.error('Failed to import states', 'StatePersistenceManager',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _loadPersistedStates() async {
    if (_persistenceDirectory == null) return;

    try {
      final files = await _persistenceDirectory!.list().toList();

      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final content = await entity.readAsString();
            final data = jsonDecode(content);
            final snapshot = StateSnapshot.fromJson(data);

            _stateSnapshots[snapshot.id] = snapshot;
          } catch (e) {
            _logger.warning('Failed to load state file: ${entity.path}', 'StatePersistenceManager');
          }
        }
      }

      _logger.info('Loaded ${_stateSnapshots.length} persisted states', 'StatePersistenceManager');

    } catch (e, stackTrace) {
      _logger.error('Failed to load persisted states', 'StatePersistenceManager',
          error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _persistState(StateSnapshot snapshot) async {
    if (_persistenceDirectory == null) return;

    try {
      final stateFile = File('${_persistenceDirectory!.path}/${snapshot.id}.json');
      await stateFile.writeAsString(jsonEncode(snapshot.toJson()));

    } catch (e, stackTrace) {
      _logger.error('Failed to persist state: ${snapshot.id}', 'StatePersistenceManager',
          error: e, stackTrace: stackTrace);
    }
  }

  Future<Map<String, dynamic>?> _attemptRecovery(String stateId, StateSnapshot snapshot) async {
    final strategy = _recoveryStrategies[stateId];
    if (strategy != null) {
      try {
        _logger.info('Attempting state recovery for: $stateId', 'StatePersistenceManager');
        return await strategy.recover(snapshot);
      } catch (e) {
        _logger.error('State recovery failed for: $stateId', 'StatePersistenceManager', error: e);
      }
    }
    return null;
  }

  void _autoSaveStates() {
    // Implementation for auto-saving critical states
    _logger.debug('Auto-saving states', 'StatePersistenceManager');
  }

  String _calculateChecksum(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    return jsonString.hashCode.toString(); // Simple checksum for demo
  }

  void dispose() {
    _autoSaveTimer?.cancel();
    _stateSnapshots.clear();
    _recoveryStrategies.clear();
  }
}

/// State snapshot for persistence
class StateSnapshot {
  final String id;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? description;
  final bool isCritical;
  final String checksum;

  StateSnapshot({
    required this.id,
    required this.data,
    required this.timestamp,
    this.description,
    this.isCritical = false,
    required this.checksum,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'description': description,
    'isCritical': isCritical,
    'checksum': checksum,
  };

  factory StateSnapshot.fromJson(Map<String, dynamic> json) {
    return StateSnapshot(
      id: json['id'],
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      description: json['description'],
      isCritical: json['isCritical'] ?? false,
      checksum: json['checksum'],
    );
  }
}

/// State recovery strategy
abstract class StateRecoveryStrategy {
  Future<Map<String, dynamic>> recover(StateSnapshot snapshot);
}

/// Default recovery strategy
class DefaultRecoveryStrategy implements StateRecoveryStrategy {
  @override
  Future<Map<String, dynamic>> recover(StateSnapshot snapshot) async {
    // Return default state or attempt to reconstruct from partial data
    return snapshot.data; // For now, return original data
  }
}

/// Enhanced validation result with additional metadata
class _CachedValidationResult {
  final ValidationResult result;
  final DateTime timestamp;

  _CachedValidationResult(this.result) : timestamp = DateTime.now();
}

/// Validation performance metrics
class ValidationMetric {
  final String ruleName;
  final Duration duration;
  final bool isValid;
  final DateTime timestamp;

  ValidationMetric({
    required this.ruleName,
    required this.duration,
    required this.isValid,
    required this.timestamp,
  });
}

/// Enhanced validation result with detailed information
class EnhancedValidationResult extends ValidationResult {
  final String? errorCode;
  final Map<String, dynamic>? metadata;
  final List<String> suggestions;
  final ValidationSeverity severity;

  EnhancedValidationResult({
    required bool isValid,
    String? error,
    String? sanitizedValue,
    this.errorCode,
    this.metadata,
    this.suggestions = const [],
    this.severity = ValidationSeverity.info,
  }) : super(isValid: isValid, error: error, sanitizedValue: sanitizedValue);
}

/// Validation severity levels
enum ValidationSeverity {
  info,
  warning,
  error,
  critical,
}

/// Main Robustness Manager
/// Coordinates all robustness features and provides unified interface
class RobustnessManager {
  static final RobustnessManager _instance = RobustnessManager._internal();
  factory RobustnessManager() => _instance;
  RobustnessManager._internal();

  final EnhancedInputValidator _validator = EnhancedInputValidator();
  final StatePersistenceManager _persistenceManager = StatePersistenceManager();
  final LoggingService _logger = LoggingService();
  final CentralConfig _config = CentralConfig.instance;

  bool _isInitialized = false;

  /// Initialize all robustness components
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Robustness Manager', 'RobustnessManager');

      // Initialize validator
      _validator.initialize();

      // Initialize persistence manager
      await _persistenceManager.initialize();

      _isInitialized = true;
      _logger.info('Robustness Manager initialized successfully', 'RobustnessManager');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Robustness Manager', 'RobustnessManager',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get input validator instance
  EnhancedInputValidator get validator => _validator;

  /// Get persistence manager instance
  StatePersistenceManager get persistence => _persistenceManager;

  /// Validate input with enhanced security
  ValidationResult validateInput(String? input, String ruleName, {bool required = false}) {
    return _validator.validate(input, ruleName, required: required);
  }

  /// Save application state
  Future<void> saveAppState(String stateId, Map<String, dynamic> state, {
    String? description,
    bool isCritical = false,
  }) async {
    await _persistenceManager.saveState(stateId, state, 
        description: description, isCritical: isCritical);
  }

  /// Load application state
  Future<Map<String, dynamic>?> loadAppState(String stateId) async {
    return await _persistenceManager.loadState(stateId);
  }

  /// Get robustness statistics
  Map<String, dynamic> getStatistics() {
    return {
      'validation': _validator.getValidationStats(),
      'persistence': _persistenceManager.getStatistics(),
      'isInitialized': _isInitialized,
    };
  }

  /// Perform health check on all robustness components
  Future<bool> performHealthCheck() async {
    try {
      // Check validator
      final validationStats = _validator.getValidationStats();
      final errorRate = double.tryParse(validationStats['errorRate'].toString().replaceAll('%', '')) ?? 0.0;
      
      if (errorRate > 10.0) {
        _logger.warning('High validation error rate detected', 'RobustnessManager');
      }

      // Check persistence
      final persistenceStats = _persistenceManager.getStatistics();
      final totalStates = persistenceStats['totalStates'] as int;
      
      if (totalStates > 100) {
        _logger.warning('High number of persisted states detected', 'RobustnessManager');
      }

      return true;
    } catch (e) {
      _logger.error('Health check failed', 'RobustnessManager', error: e);
      return false;
    }
  }
}
