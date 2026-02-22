import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/logging/logging_service.dart';
import '../../../core/security/security_manager.dart';

/// Enhanced Input Validation System
/// Provides comprehensive input validation with security checks and sanitization
class EnhancedInputValidator {
  static final EnhancedInputValidator _instance = EnhancedInputValidator._internal();
  factory EnhancedInputValidator() => _instance;
  EnhancedInputValidator._internal();

  final LoggingService _logger = LoggingService();
  final SecurityManager _security = SecurityManager();

  // Validation rules cache
  final Map<String, ValidationRule> _rules = {};

  // Validation statistics
  int _totalValidations = 0;
  int _failedValidations = 0;
  final Map<String, int> _validationErrors = {};

  /// Initialize validator with default rules
  void initialize() {
    _setupDefaultRules();
    _logger.info('Enhanced Input Validator initialized', 'EnhancedInputValidator');
  }

  void _setupDefaultRules() {
    // Email validation
    _rules['email'] = ValidationRule(
      name: 'email',
      pattern: r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      maxLength: 254,
      required: false,
      securityCheck: true,
    );

    // Phone number validation
    _rules['phone'] = ValidationRule(
      name: 'phone',
      pattern: r'^\+?[\d\s\-\(\)]{10,15}$',
      maxLength: 20,
      required: false,
      securityCheck: false,
    );

    // URL validation
    _rules['url'] = ValidationRule(
      name: 'url',
      pattern: r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
      maxLength: 2048,
      required: false,
      securityCheck: true,
    );

    // Username validation
    _rules['username'] = ValidationRule(
      name: 'username',
      pattern: r'^[a-zA-Z0-9_-]{3,20}$',
      minLength: 3,
      maxLength: 20,
      required: true,
      securityCheck: true,
    );

    // Password validation
    _rules['password'] = ValidationRule(
      name: 'password',
      minLength: 8,
      maxLength: 128,
      required: true,
      securityCheck: true,
      customValidator: _validatePasswordStrength,
    );

    // File path validation
    _rules['file_path'] = ValidationRule(
      name: 'file_path',
      maxLength: 260, // Windows MAX_PATH
      required: false,
      securityCheck: true,
      sanitizer: _security.sanitizeFilePath,
    );

    // Text input validation
    _rules['text'] = ValidationRule(
      name: 'text',
      maxLength: 10000,
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

  /// Validate input against a rule
  ValidationResult validate(String? input, String ruleName, {
    bool required = false,
    Map<String, dynamic>? customParams,
  }) {
    _totalValidations++;

    final rule = _rules[ruleName];
    if (rule == null) {
      _recordValidationError(ruleName, 'Unknown validation rule');
      return ValidationResult(
        isValid: false,
        error: 'Unknown validation rule: $ruleName',
      );
    }

    // Check if required
    if ((rule.required || required) && (input == null || input.trim().isEmpty)) {
      _recordValidationError(ruleName, 'Field is required');
      return ValidationResult(
        isValid: false,
        error: 'This field is required',
      );
    }

    // Skip further validation for empty optional fields
    if (input == null || input.trim().isEmpty) {
      return ValidationResult(isValid: true, sanitizedValue: input);
    }

    final trimmedInput = input.trim();

    // Length validation
    if (rule.minLength != null && trimmedInput.length < rule.minLength!) {
      _recordValidationError(ruleName, 'Too short');
      return ValidationResult(
        isValid: false,
        error: 'Minimum length is ${rule.minLength} characters',
      );
    }

    if (rule.maxLength != null && trimmedInput.length > rule.maxLength!) {
      _recordValidationError(ruleName, 'Too long');
      return ValidationResult(
        isValid: false,
        error: 'Maximum length is ${rule.maxLength} characters',
      );
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

  /// Get validation statistics
  Map<String, dynamic> getValidationStats() {
    final errorRate = _totalValidations > 0 ? (_failedValidations / _totalValidations) * 100 : 0.0;

    return {
      'totalValidations': _totalValidations,
      'failedValidations': _failedValidations,
      'errorRate': '${errorRate.toStringAsFixed(2)}%',
      'commonErrors': _validationErrors,
      'activeRules': _rules.length,
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
