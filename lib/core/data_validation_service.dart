import 'dart:convert';
import 'logging_service.dart';
import 'central_config.dart';

/// Comprehensive Data Validation and Sanitization Service
///
/// Provides enterprise-grade data validation, sanitization, and security:
/// - Input validation with configurable rules
/// - Data sanitization and cleansing
/// - SQL injection prevention
/// - XSS protection
/// - Schema validation for structured data
/// - Type coercion and normalization
/// - Custom validation rules and constraints
class DataValidationService {
  static final DataValidationService _instance = DataValidationService._internal();
  factory DataValidationService() => _instance;
  DataValidationService._internal();

  final LoggingService _logger = LoggingService();
  final CentralConfig _config = CentralConfig.instance;

  final Map<String, ValidationRule> _validationRules = {};
  final Map<String, SanitizationRule> _sanitizationRules = {};
  final Map<String, DataSchema> _dataSchemas = {};

  bool _isInitialized = false;

  /// Initialize the data validation service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Data Validation Service', 'DataValidation');

      // Register with CentralConfig
      await _config.registerComponent(
        'DataValidationService',
        '1.0.0',
        'Enterprise data validation and sanitization service with security hardening',
        dependencies: ['CentralConfig', 'LoggingService'],
        parameters: {
          // Validation settings
          'validation.enabled': true,
          'validation.strict_mode': false,
          'validation.fail_fast': true,
          'validation.max_string_length': 10000,
          'validation.max_array_size': 1000,

          // Sanitization settings
          'sanitization.enabled': true,
          'sanitization.html_encoding': true,
          'sanitization.sql_escaping': true,
          'sanitization.remove_null_bytes': true,

          // Security settings
          'security.xss_protection': true,
          'security.sql_injection_protection': true,
          'security.command_injection_protection': true,
          'security.path_traversal_protection': true,

          // Schema validation
          'schema.enabled': true,
          'schema.strict_validation': false,
          'schema.coerce_types': true,
        }
      );

      // Register default validation rules
      _registerDefaultValidationRules();

      // Register default sanitization rules
      _registerDefaultSanitizationRules();

      _isInitialized = true;
      _logger.info('Data Validation Service initialized successfully', 'DataValidation');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Data Validation Service', 'DataValidation',
          error: e, stackTrace: stackTrace);
      // Continue with limited functionality
      _isInitialized = true;
    }
  }

  void _registerDefaultValidationRules() {
    // Email validation
    registerValidationRule(ValidationRule(
      name: 'email',
      description: 'Validates email address format',
      validator: _validateEmail,
      errorMessage: 'Invalid email address format',
    ));

    // URL validation
    registerValidationRule(ValidationRule(
      name: 'url',
      description: 'Validates URL format',
      validator: _validateUrl,
      errorMessage: 'Invalid URL format',
    ));

    // Phone number validation
    registerValidationRule(ValidationRule(
      name: 'phone',
      description: 'Validates phone number format',
      validator: _validatePhone,
      errorMessage: 'Invalid phone number format',
    ));

    // SQL injection detection
    registerValidationRule(ValidationRule(
      name: 'no_sql_injection',
      description: 'Detects potential SQL injection attempts',
      validator: _validateNoSqlInjection,
      errorMessage: 'Potential SQL injection detected',
    ));

    // XSS detection
    registerValidationRule(ValidationRule(
      name: 'no_xss',
      description: 'Detects potential XSS attacks',
      validator: _validateNoXss,
      errorMessage: 'Potential XSS attack detected',
    ));

    // File path validation
    registerValidationRule(ValidationRule(
      name: 'safe_path',
      description: 'Validates file paths for security',
      validator: _validateSafePath,
      errorMessage: 'Unsafe file path detected',
    ));

    _logger.info('Default validation rules registered', 'DataValidation');
  }

  void _registerDefaultSanitizationRules() {
    // HTML sanitization
    registerSanitizationRule(SanitizationRule(
      name: 'html_encode',
      description: 'Encodes HTML special characters',
      sanitizer: _sanitizeHtml,
    ));

    // SQL escaping
    registerSanitizationRule(SanitizationRule(
      name: 'sql_escape',
      description: 'Escapes SQL special characters',
      sanitizer: _sanitizeSql,
    ));

    // Null byte removal
    registerSanitizationRule(SanitizationRule(
      name: 'remove_null_bytes',
      description: 'Removes null bytes from strings',
      sanitizer: _removeNullBytes,
    ));

    // Trim whitespace
    registerSanitizationRule(SanitizationRule(
      name: 'trim_whitespace',
      description: 'Trims leading and trailing whitespace',
      sanitizer: _trimWhitespace,
    ));

    _logger.info('Default sanitization rules registered', 'DataValidation');
  }

  /// Register a custom validation rule
  void registerValidationRule(ValidationRule rule) {
    _validationRules[rule.name] = rule;
    _logger.info('Registered validation rule: ${rule.name}', 'DataValidation');
  }

  /// Register a custom sanitization rule
  void registerSanitizationRule(SanitizationRule rule) {
    _sanitizationRules[rule.name] = rule;
    _logger.info('Registered sanitization rule: ${rule.name}', 'DataValidation');
  }

  /// Register a data schema for validation
  void registerDataSchema(String name, DataSchema schema) {
    _dataSchemas[name] = schema;
    _logger.info('Registered data schema: $name', 'DataValidation');
  }

  /// Validate data against a single rule
  ValidationResult validate(dynamic data, String ruleName) {
    if (!_isInitialized) {
      return ValidationResult(
        isValid: true,
        errors: [],
        warnings: ['Validation service not initialized'],
      );
    }

    final rule = _validationRules[ruleName];
    if (rule == null) {
      return ValidationResult(
        isValid: false,
        errors: ['Unknown validation rule: $ruleName'],
        warnings: [],
      );
    }

    try {
      final errors = rule.validator(data);
      return ValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        warnings: [],
      );
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errors: ['Validation failed: ${e.toString()}'],
        warnings: [],
      );
    }
  }

  /// Validate data against multiple rules
  ValidationResult validateMultiple(dynamic data, List<String> ruleNames) {
    final allErrors = <String>[];
    final allWarnings = <String>[];

    for (final ruleName in ruleNames) {
      final result = validate(data, ruleName);
      allErrors.addAll(result.errors);
      allWarnings.addAll(result.warnings);
    }

    return ValidationResult(
      isValid: allErrors.isEmpty,
      errors: allErrors,
      warnings: allWarnings,
    );
  }

  /// Validate data against a schema
  ValidationResult validateAgainstSchema(dynamic data, String schemaName) {
    final schema = _dataSchemas[schemaName];
    if (schema == null) {
      return ValidationResult(
        isValid: false,
        errors: ['Unknown schema: $schemaName'],
        warnings: [],
      );
    }

    return schema.validate(data);
  }

  /// Sanitize data using a single rule
  dynamic sanitize(dynamic data, String ruleName) {
    if (!_isInitialized) return data;

    final rule = _sanitizationRules[ruleName];
    if (rule == null) {
      _logger.warning('Unknown sanitization rule: $ruleName', 'DataValidation');
      return data;
    }

    try {
      return rule.sanitizer(data);
    } catch (e) {
      _logger.error('Sanitization failed for rule $ruleName', 'DataValidation', error: e);
      return data;
    }
  }

  /// Sanitize data using multiple rules
  dynamic sanitizeMultiple(dynamic data, List<String> ruleNames) {
    dynamic sanitized = data;

    for (final ruleName in ruleNames) {
      sanitized = sanitize(sanitized, ruleName);
    }

    return sanitized;
  }

  /// Comprehensive data cleaning pipeline
  DataCleaningResult cleanData(dynamic data, {
    List<String> validationRules = const [],
    List<String> sanitizationRules = const ['trim_whitespace', 'remove_null_bytes'],
    String? schemaName,
    bool strictMode = false,
  }) {
    final result = DataCleaningResult(
      originalData: data,
      cleanedData: data,
      isValid: true,
      validationErrors: [],
      sanitizationApplied: [],
    );

    // Apply sanitization first
    result.cleanedData = sanitizeMultiple(data, sanitizationRules);
    result.sanitizationApplied = sanitizationRules;

    // Apply validation
    if (validationRules.isNotEmpty) {
      final validationResult = validateMultiple(result.cleanedData, validationRules);
      result.isValid = validationResult.isValid;
      result.validationErrors = validationResult.errors;
    }

    // Apply schema validation if specified
    if (schemaName != null) {
      final schemaResult = validateAgainstSchema(result.cleanedData, schemaName);
      if (!schemaResult.isValid) {
        result.isValid = false;
        result.validationErrors.addAll(schemaResult.errors);
      }
    }

    // In strict mode, return null if validation fails
    if (strictMode && !result.isValid) {
      result.cleanedData = null;
    }

    return result;
  }

  /// Validate and sanitize user input comprehensively
  InputValidationResult validateUserInput(String input, {
    List<String> securityRules = const ['no_xss', 'no_sql_injection', 'safe_path'],
    List<String> sanitizationRules = const ['html_encode', 'trim_whitespace'],
    int? maxLength,
  }) {
    final result = InputValidationResult(
      originalInput: input,
      sanitizedInput: input,
      isValid: true,
      securityViolations: [],
      validationErrors: [],
    );

    // Check length limits
    if (maxLength != null && input.length > maxLength) {
      result.isValid = false;
      result.validationErrors.add('Input exceeds maximum length of $maxLength characters');
      return result;
    }

    // Apply security validation
    for (final rule in securityRules) {
      final validationResult = validate(input, rule);
      if (!validationResult.isValid) {
        result.isValid = false;
        result.securityViolations.addAll(validationResult.errors);
      }
    }

    // Apply sanitization
    result.sanitizedInput = sanitizeMultiple(input, sanitizationRules);

    return result;
  }

  /// Validate API request data
  ApiValidationResult validateApiRequest(Map<String, dynamic> requestData, {
    Map<String, List<String>> fieldValidations = const {},
    List<String> globalValidations = const [],
    bool strictValidation = false,
  }) {
    final result = ApiValidationResult(
      isValid: true,
      fieldErrors: {},
      globalErrors: [],
      sanitizedData: Map.from(requestData),
    );

    // Validate individual fields
    for (final entry in fieldValidations.entries) {
      final fieldName = entry.key;
      final rules = entry.value;

      if (requestData.containsKey(fieldName)) {
        final fieldValue = requestData[fieldName];
        final validationResult = validateMultiple(fieldValue, rules);

        if (!validationResult.isValid) {
          result.isValid = false;
          result.fieldErrors[fieldName] = validationResult.errors;

          // Sanitize if validation failed but we're not in strict mode
          if (!strictValidation) {
            result.sanitizedData[fieldName] = sanitizeMultiple(fieldValue, ['html_encode', 'trim_whitespace']);
          }
        }
      }
    }

    // Apply global validations
    if (globalValidations.isNotEmpty) {
      final globalResult = validateMultiple(requestData, globalValidations);
      if (!globalResult.isValid) {
        result.isValid = false;
        result.globalErrors = globalResult.errors;
      }
    }

    return result;
  }

  // Private validation implementations

  List<String> _validateEmail(dynamic value) {
    final errors = <String>[];

    if (value == null) {
      errors.add('Email is required');
      return errors;
    }

    if (value is! String) {
      errors.add('Email must be a string');
      return errors;
    }

    final email = value.trim();
    if (email.isEmpty) {
      errors.add('Email cannot be empty');
      return errors;
    }

    // Basic email regex
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      errors.add('Invalid email format');
    }

    // Check for suspicious patterns
    if (email.contains('..') || email.startsWith('.') || email.endsWith('.')) {
      errors.add('Invalid email structure');
    }

    return errors;
  }

  List<String> _validateUrl(dynamic value) {
    final errors = <String>[];

    if (value == null) {
      errors.add('URL is required');
      return errors;
    }

    if (value is! String) {
      errors.add('URL must be a string');
      return errors;
    }

    final url = value.trim();
    if (url.isEmpty) {
      errors.add('URL cannot be empty');
      return errors;
    }

    // Basic URL regex
    final urlRegex = RegExp(r'^https?://[^\s/$.?#].[^\s]*$');
    if (!urlRegex.hasMatch(url)) {
      errors.add('Invalid URL format');
    }

    return errors;
  }

  List<String> _validatePhone(dynamic value) {
    final errors = <String>[];

    if (value == null) {
      errors.add('Phone number is required');
      return errors;
    }

    if (value is! String) {
      errors.add('Phone number must be a string');
      return errors;
    }

    final phone = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.length < 10 || phone.length > 15) {
      errors.add('Phone number must be between 10-15 digits');
    }

    return errors;
  }

  List<String> _validateNoSqlInjection(dynamic value) {
    final errors = <String>[];

    if (value == null) return errors;

    final stringValue = value.toString().toLowerCase();

    // Common SQL injection patterns
    final sqlPatterns = [
      RegExp(r';\s*(drop|delete|update|insert|alter|create|truncate)\s+', caseSensitive: false),
      RegExp(r'union\s+select', caseSensitive: false),
      RegExp(r'--\s*$', multiLine: true),
      RegExp(r'/\*.*\*/', dotAll: true),
      RegExp(r';\s*$'),
    ];

    for (final pattern in sqlPatterns) {
      if (pattern.hasMatch(stringValue)) {
        errors.add('Potential SQL injection pattern detected');
        break;
      }
    }

    return errors;
  }

  List<String> _validateNoXss(dynamic value) {
    final errors = <String>[];

    if (value == null) return errors;

    final stringValue = value.toString().toLowerCase();

    // Common XSS patterns
    final xssPatterns = [
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'<iframe[^>]*>', caseSensitive: false),
      RegExp(r'<object[^>]*>', caseSensitive: false),
      RegExp(r'<embed[^>]*>', caseSensitive: false),
    ];

    for (final pattern in xssPatterns) {
      if (pattern.hasMatch(stringValue)) {
        errors.add('Potential XSS attack pattern detected');
        break;
      }
    }

    return errors;
  }

  List<String> _validateSafePath(dynamic value) {
    final errors = <String>[];

    if (value == null) return errors;

    final stringValue = value.toString();

    // Path traversal patterns
    final traversalPatterns = [
      RegExp(r'\.\./'),
      RegExp(r'\.\.\\'),
      RegExp(r'%2e%2e%2f', caseSensitive: false),
      RegExp(r'%2e%2e%5c', caseSensitive: false),
    ];

    for (final pattern in traversalPatterns) {
      if (pattern.hasMatch(stringValue)) {
        errors.add('Potential path traversal attack detected');
        break;
      }
    }

    // Check for absolute paths that might be dangerous
    if (stringValue.startsWith('/') || stringValue.contains(':\\') || stringValue.contains(':/')) {
      // Allow some safe absolute paths but flag suspicious ones
      if (stringValue.contains('..') || stringValue.contains('~')) {
        errors.add('Suspicious absolute path detected');
      }
    }

    return errors;
  }

  // Private sanitization implementations

  dynamic _sanitizeHtml(dynamic value) {
    if (value == null) return value;

    final stringValue = value.toString();

    // Simple HTML encoding - replace common dangerous characters
    return stringValue
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  dynamic _sanitizeSql(dynamic value) {
    if (value == null) return value;

    final stringValue = value.toString();

    // Basic SQL escaping
    return stringValue
        .replaceAll("'", "''")
        .replaceAll('\\', '\\\\')
        .replaceAll('\x00', '') // Remove null bytes
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .replaceAll('\t', ' ');
  }

  dynamic _removeNullBytes(dynamic value) {
    if (value == null) return value;

    final stringValue = value.toString();
    return stringValue.replaceAll('\x00', '');
  }

  dynamic _trimWhitespace(dynamic value) {
    if (value == null) return value;

    if (value is String) {
      return value.trim();
    }

    return value;
  }

  // Getters
  bool get isInitialized => _isInitialized;
  Map<String, ValidationRule> get validationRules => Map.from(_validationRules);
  Map<String, SanitizationRule> get sanitizationRules => Map.from(_sanitizationRules);
  Map<String, DataSchema> get dataSchemas => Map.from(_dataSchemas);
}

/// Supporting classes and data structures

class ValidationRule {
  final String name;
  final String description;
  final List<String> Function(dynamic) validator;
  final String errorMessage;

  ValidationRule({
    required this.name,
    required this.description,
    required this.validator,
    required this.errorMessage,
  });
}

class SanitizationRule {
  final String name;
  final String description;
  final dynamic Function(dynamic) sanitizer;

  SanitizationRule({
    required this.name,
    required this.description,
    required this.sanitizer,
  });
}

class DataSchema {
  final String name;
  final Map<String, dynamic> schema;
  final bool strictValidation;
  final bool coerceTypes;

  DataSchema({
    required this.name,
    required this.schema,
    this.strictValidation = false,
    this.coerceTypes = true,
  });

  ValidationResult validate(dynamic data) {
    final errors = <String>[];
    final warnings = <String>[];

    if (data is! Map<String, dynamic>) {
      return ValidationResult(
        isValid: false,
        errors: ['Data must be a Map'],
        warnings: warnings,
      );
    }

    final mapData = data as Map<String, dynamic>;

    // Check required fields
    final requiredFields = schema['required'] as List<String>? ?? [];
    for (final field in requiredFields) {
      if (!mapData.containsKey(field) || mapData[field] == null) {
        errors.add('Missing required field: $field');
      }
    }

    // Validate field types and constraints
    final properties = schema['properties'] as Map<String, dynamic>? ?? {};
    for (final entry in properties.entries) {
      final fieldName = entry.key;
      final fieldSchema = entry.value as Map<String, dynamic>;

      if (mapData.containsKey(fieldName)) {
        final fieldValue = mapData[fieldName];
        final expectedType = fieldSchema['type'];

        // Type validation
        if (expectedType == 'string' && fieldValue is! String) {
          if (coerceTypes && fieldValue != null) {
            mapData[fieldName] = fieldValue.toString();
          } else {
            errors.add('Field "$fieldName" must be a string');
          }
        } else if (expectedType == 'number' && fieldValue is! num) {
          if (coerceTypes && fieldValue != null) {
            final numValue = num.tryParse(fieldValue.toString());
            if (numValue != null) {
              mapData[fieldName] = numValue;
            } else {
              errors.add('Field "$fieldName" must be a number');
            }
          } else {
            errors.add('Field "$fieldName" must be a number');
          }
        } else if (expectedType == 'boolean' && fieldValue is! bool) {
          if (coerceTypes && fieldValue != null) {
            if (fieldValue.toString().toLowerCase() == 'true') {
              mapData[fieldName] = true;
            } else if (fieldValue.toString().toLowerCase() == 'false') {
              mapData[fieldName] = false;
            } else {
              errors.add('Field "$fieldName" must be a boolean');
            }
          } else {
            errors.add('Field "$fieldName" must be a boolean');
          }
        }

        // Length constraints for strings
        if (expectedType == 'string' && fieldValue is String) {
          final maxLength = fieldSchema['maxLength'] as int?;
          if (maxLength != null && fieldValue.length > maxLength) {
            errors.add('Field "$fieldName" exceeds maximum length of $maxLength');
          }

          final minLength = fieldSchema['minLength'] as int?;
          if (minLength != null && fieldValue.length < minLength) {
            errors.add('Field "$fieldName" is below minimum length of $minLength');
          }
        }

        // Range constraints for numbers
        if (expectedType == 'number' && fieldValue is num) {
          final minimum = fieldSchema['minimum'] as num?;
          if (minimum != null && fieldValue < minimum) {
            errors.add('Field "$fieldName" must be at least $minimum');
          }

          final maximum = fieldSchema['maximum'] as num?;
          if (maximum != null && fieldValue > maximum) {
            errors.add('Field "$fieldName" must be at most $maximum');
          }
        }
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
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
}

class DataCleaningResult {
  final dynamic originalData;
  dynamic cleanedData;
  bool isValid;
  final List<String> validationErrors;
  final List<String> sanitizationApplied;

  DataCleaningResult({
    required this.originalData,
    required this.cleanedData,
    required this.isValid,
    required this.validationErrors,
    required this.sanitizationApplied,
  });
}

class InputValidationResult {
  final String originalInput;
  String sanitizedInput;
  bool isValid;
  final List<String> securityViolations;
  final List<String> validationErrors;

  InputValidationResult({
    required this.originalInput,
    required this.sanitizedInput,
    required this.isValid,
    required this.securityViolations,
    required this.validationErrors,
  });
}

class ApiValidationResult {
  bool isValid;
  final Map<String, List<String>> fieldErrors;
  final List<String> globalErrors;
  final Map<String, dynamic> sanitizedData;

  ApiValidationResult({
    required this.isValid,
    required this.fieldErrors,
    required this.globalErrors,
    required this.sanitizedData,
  });
}
