import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Advanced Input Validation Service
/// Provides comprehensive input validation with security-focused checks
class InputValidationService {
  static final InputValidationService _instance = InputValidationService._internal();
  factory InputValidationService() => _instance;
  InputValidationService._internal();

  final Map<String, ValidationRule> _customRules = {};

  /// Validate email address with advanced checks
  ValidationResult validateEmail(String email, {
    bool allowInternational = true,
    bool checkMX = false,
    List<String>? allowedDomains,
    List<String>? blockedDomains,
  }) {
    if (email.isEmpty) {
      return ValidationResult.invalid('Email cannot be empty');
    }

    if (email.length > 254) {
      return ValidationResult.invalid('Email too long');
    }

    // Basic format check
    final emailRegex = RegExp(r'^[a-zA-Z0-9.!#$%&\'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$');
    if (!emailRegex.hasMatch(email)) {
      return ValidationResult.invalid('Invalid email format');
    }

    // Check for dangerous characters
    final dangerousChars = RegExp(r'[\x00-\x1F\x7F-\x9F]');
    if (dangerousChars.hasMatch(email)) {
      return ValidationResult.invalid('Email contains invalid characters');
    }

    // Domain checks
    final domain = email.split('@').last.toLowerCase();

    if (blockedDomains?.contains(domain) ?? false) {
      return ValidationResult.invalid('Email domain not allowed');
    }

    if (allowedDomains != null && !allowedDomains.contains(domain)) {
      return ValidationResult.invalid('Email domain not in allowed list');
    }

    // International domain check
    if (!allowInternational && domain.contains(RegExp(r'[^a-zA-Z0-9.-]'))) {
      return ValidationResult.invalid('International characters not allowed in domain');
    }

    return ValidationResult.valid();
  }

  /// Validate password with strength requirements
  ValidationResult validatePassword(String password, {
    int minLength = 8,
    int maxLength = 128,
    bool requireUppercase = true,
    bool requireLowercase = true,
    bool requireNumbers = true,
    bool requireSpecialChars = true,
    List<String>? commonPasswords,
  }) {
    if (password.isEmpty) {
      return ValidationResult.invalid('Password cannot be empty');
    }

    if (password.length < minLength) {
      return ValidationResult.invalid('Password must be at least $minLength characters');
    }

    if (password.length > maxLength) {
      return ValidationResult.invalid('Password too long (max $maxLength characters)');
    }

    // Check for common passwords
    if (commonPasswords?.contains(password.toLowerCase()) ?? false) {
      return ValidationResult.invalid('Password is too common');
    }

    // Check for sequential characters
    if (_hasSequentialChars(password)) {
      return ValidationResult.invalid('Password contains sequential characters');
    }

    // Check for repeated characters
    if (_hasRepeatedChars(password)) {
      return ValidationResult.invalid('Password contains too many repeated characters');
    }

    // Character requirements
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumbers = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{};\':"\\|,.<>\/?]'));

    final errors = <String>[];

    if (requireUppercase && !hasUppercase) {
      errors.add('Must contain uppercase letter');
    }
    if (requireLowercase && !hasLowercase) {
      errors.add('Must contain lowercase letter');
    }
    if (requireNumbers && !hasNumbers) {
      errors.add('Must contain number');
    }
    if (requireSpecialChars && !hasSpecialChars) {
      errors.add('Must contain special character');
    }

    if (errors.isNotEmpty) {
      return ValidationResult.invalid(errors.join(', '));
    }

    return ValidationResult.valid(strength: _calculatePasswordStrength(password));
  }

  /// Validate phone number
  ValidationResult validatePhoneNumber(String phone, {
    String? countryCode,
    bool allowInternational = true,
  }) {
    if (phone.isEmpty) {
      return ValidationResult.invalid('Phone number cannot be empty');
    }

    // Remove all non-digit characters for validation
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleanPhone.length < 7) {
      return ValidationResult.invalid('Phone number too short');
    }

    if (cleanPhone.length > 15) {
      return ValidationResult.invalid('Phone number too long');
    }

    // Basic phone number pattern
    final phoneRegex = allowInternational
        ? RegExp(r'^\+?[1-9]\d{6,14}$')
        : RegExp(r'^[2-9]\d{9}$'); // US format

    if (!phoneRegex.hasMatch(cleanPhone)) {
      return ValidationResult.invalid('Invalid phone number format');
    }

    return ValidationResult.valid();
  }

  /// Validate URL with security checks
  ValidationResult validateURL(String url, {
    List<String>? allowedSchemes = const ['http', 'https'],
    List<String>? blockedDomains,
    bool checkReachability = false,
  }) {
    if (url.isEmpty) {
      return ValidationResult.invalid('URL cannot be empty');
    }

    if (url.length > 2048) {
      return ValidationResult.invalid('URL too long');
    }

    try {
      final uri = Uri.parse(url);

      if (uri.scheme.isEmpty) {
        return ValidationResult.invalid('URL must have a scheme');
      }

      if (allowedSchemes != null && !allowedSchemes.contains(uri.scheme.toLowerCase())) {
        return ValidationResult.invalid('URL scheme not allowed');
      }

      if (uri.host.isEmpty) {
        return ValidationResult.invalid('URL must have a host');
      }

      // Check for blocked domains
      if (blockedDomains?.any((domain) => uri.host.contains(domain)) ?? false) {
        return ValidationResult.invalid('URL domain not allowed');
      }

      // Check for suspicious patterns
      if (_isSuspiciousURL(uri)) {
        return ValidationResult.invalid('URL appears suspicious');
      }

    } catch (e) {
      return ValidationResult.invalid('Invalid URL format');
    }

    return ValidationResult.valid();
  }

  /// Validate file path with security checks
  ValidationResult validateFilePath(String path, {
    List<String>? allowedExtensions,
    List<String>? blockedExtensions,
    bool allowAbsolute = true,
    bool allowRelative = true,
    int maxPathLength = 260,
  }) {
    if (path.isEmpty) {
      return ValidationResult.invalid('File path cannot be empty');
    }

    if (path.length > maxPathLength) {
      return ValidationResult.invalid('File path too long');
    }

    // Check for dangerous characters
    final dangerousChars = RegExp(r'[\x00-\x1F\x7F-\x9F]');
    if (dangerousChars.hasMatch(path)) {
      return ValidationResult.invalid('File path contains invalid characters');
    }

    // Check for path traversal attempts
    if (path.contains('..') || path.contains('../') || path.contains('..\\')) {
      return ValidationResult.invalid('Path traversal not allowed');
    }

    // Check absolute vs relative
    final isAbsolute = path.startsWith('/') || path.startsWith('\\') || path.contains(':/') || path.contains(':\\');

    if (isAbsolute && !allowAbsolute) {
      return ValidationResult.invalid('Absolute paths not allowed');
    }

    if (!isAbsolute && !allowRelative) {
      return ValidationResult.invalid('Relative paths not allowed');
    }

    // Check file extension
    final extension = path.split('.').last.toLowerCase();

    if (blockedExtensions?.contains(extension) ?? false) {
      return ValidationResult.invalid('File extension not allowed');
    }

    if (allowedExtensions != null && !allowedExtensions.contains(extension)) {
      return ValidationResult.invalid('File extension not in allowed list');
    }

    return ValidationResult.valid();
  }

  /// Validate JSON data
  ValidationResult validateJSON(String jsonString, {
    Map<String, dynamic>? schema,
    int maxDepth = 10,
    int maxSize = 1024 * 1024, // 1MB
  }) {
    if (jsonString.isEmpty) {
      return ValidationResult.invalid('JSON cannot be empty');
    }

    if (jsonString.length > maxSize) {
      return ValidationResult.invalid('JSON too large');
    }

    try {
      final decoded = json.decode(jsonString);

      // Check depth
      if (_getJSONDepth(decoded) > maxDepth) {
        return ValidationResult.invalid('JSON structure too deep');
      }

      // Schema validation if provided
      if (schema != null && !_validateAgainstSchema(decoded, schema)) {
        return ValidationResult.invalid('JSON does not match required schema');
      }

    } catch (e) {
      return ValidationResult.invalid('Invalid JSON format: ${e.toString()}');
    }

    return ValidationResult.valid();
  }

  /// Validate text input with content checks
  ValidationResult validateText(String text, {
    int minLength = 0,
    int maxLength = 10000,
    bool allowHTML = false,
    bool allowScript = false,
    List<String>? blockedWords,
    String? pattern,
  }) {
    if (text.length < minLength) {
      return ValidationResult.invalid('Text too short (minimum $minLength characters)');
    }

    if (text.length > maxLength) {
      return ValidationResult.invalid('Text too long (maximum $maxLength characters)');
    }

    // Check for HTML if not allowed
    if (!allowHTML && (text.contains('<') && text.contains('>'))) {
      return ValidationResult.invalid('HTML content not allowed');
    }

    // Check for script content
    if (!allowScript && _containsScriptContent(text)) {
      return ValidationResult.invalid('Script content not allowed');
    }

    // Check for blocked words
    if (blockedWords != null) {
      final lowerText = text.toLowerCase();
      for (final word in blockedWords) {
        if (lowerText.contains(word.toLowerCase())) {
          return ValidationResult.invalid('Content contains blocked words');
        }
      }
    }

    // Pattern validation
    if (pattern != null) {
      final regex = RegExp(pattern);
      if (!regex.hasMatch(text)) {
        return ValidationResult.invalid('Text does not match required pattern');
      }
    }

    return ValidationResult.valid();
  }

  /// Sanitize input data
  String sanitizeInput(String input, {
    bool allowHTML = false,
    bool allowScript = false,
    List<String>? allowedTags,
  }) {
    if (input.isEmpty) return input;

    String sanitized = input;

    // Remove null bytes and control characters
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '');

    // HTML sanitization if not allowed
    if (!allowHTML) {
      sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');
    } else if (allowedTags != null) {
      // Keep only allowed tags
      sanitized = sanitized.replaceAllMapped(
        RegExp(r'<(/?)([^>\s]+)([^>]*)>'),
        (match) {
          final tag = match.group(2)!.toLowerCase();
          return allowedTags.contains(tag) ? match.group(0)! : '';
        },
      );
    }

    // Script removal if not allowed
    if (!allowScript) {
      sanitized = sanitized.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '');
      sanitized = sanitized.replaceAll(RegExp(r'on\w+="[^"]*"', caseSensitive: false), '');
    }

    return sanitized.trim();
  }

  /// Add custom validation rule
  void addCustomRule(String name, ValidationRule rule) {
    _customRules[name] = rule;
  }

  /// Validate using custom rule
  ValidationResult validateWithCustomRule(String name, dynamic value) {
    final rule = _customRules[name];
    if (rule == null) {
      return ValidationResult.invalid('Custom validation rule not found');
    }

    return rule.validate(value);
  }

  // Private helper methods

  bool _hasSequentialChars(String str) {
    for (int i = 0; i < str.length - 2; i++) {
      final a = str.codeUnitAt(i);
      final b = str.codeUnitAt(i + 1);
      final c = str.codeUnitAt(i + 2);
      if (b == a + 1 && c == b + 1) return true;
    }
    return false;
  }

  bool _hasRepeatedChars(String str) {
    for (int i = 0; i < str.length - 2; i++) {
      if (str[i] == str[i + 1] && str[i + 1] == str[i + 2]) return true;
    }
    return false;
  }

  double _calculatePasswordStrength(String password) {
    double strength = 0;

    if (password.length >= 8) strength += 0.2;
    if (password.length >= 12) strength += 0.2;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
    if (password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{};\':"\\|,.<>\/?]'))) strength += 0.2;
    if (!_hasSequentialChars(password)) strength += 0.1;
    if (!_hasRepeatedChars(password)) strength += 0.1;

    return strength.clamp(0.0, 1.0);
  }

  bool _isSuspiciousURL(Uri uri) {
    final suspiciousPatterns = [
      RegExp(r'\d+\.\d+\.\d+\.\d+'), // IP addresses (might be suspicious)
      RegExp(r'[0-9]{10,}'), // Long numbers
      RegExp(r'%[0-9a-fA-F]{2}'), // URL encoding
    ];

    final urlString = uri.toString();
    return suspiciousPatterns.any((pattern) => pattern.hasMatch(urlString));
  }

  int _getJSONDepth(dynamic obj) {
    if (obj is Map) {
      int maxDepth = 1;
      for (final value in obj.values) {
        maxDepth = maxDepth.max(1 + _getJSONDepth(value));
      }
      return maxDepth;
    } else if (obj is List) {
      int maxDepth = 1;
      for (final item in obj) {
        maxDepth = maxDepth.max(1 + _getJSONDepth(item));
      }
      return maxDepth;
    }
    return 1;
  }

  bool _validateAgainstSchema(dynamic data, Map<String, dynamic> schema) {
    // Basic schema validation - can be extended
    if (schema.containsKey('type')) {
      final expectedType = schema['type'];
      switch (expectedType) {
        case 'string':
          if (data is! String) return false;
          break;
        case 'number':
          if (data is! num) return false;
          break;
        case 'boolean':
          if (data is! bool) return false;
          break;
        case 'array':
          if (data is! List) return false;
          break;
        case 'object':
          if (data is! Map) return false;
          break;
      }
    }
    return true;
  }

  bool _containsScriptContent(String text) {
    final scriptPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+=', caseSensitive: false),
      RegExp(r'eval\s*\(', caseSensitive: false),
    ];

    return scriptPatterns.any((pattern) => pattern.hasMatch(text));
  }
}

/// Validation result class
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final double? strength; // For password strength

  ValidationResult._(this.isValid, this.errorMessage, this.strength);

  factory ValidationResult.valid({double? strength}) {
    return ValidationResult._(true, null, strength);
  }

  factory ValidationResult.invalid(String message) {
    return ValidationResult._(false, message, null);
  }
}

/// Custom validation rule interface
abstract class ValidationRule {
  ValidationResult validate(dynamic value);
}

/// Predefined validation rules
class EmailValidationRule extends ValidationRule {
  final bool allowInternational;
  final List<String>? allowedDomains;

  EmailValidationRule({this.allowInternational = true, this.allowedDomains});

  @override
  ValidationResult validate(dynamic value) {
    if (value is! String) return ValidationResult.invalid('Value must be a string');
    return InputValidationService().validateEmail(
      value,
      allowInternational: allowInternational,
      allowedDomains: allowedDomains,
    );
  }
}

class PasswordValidationRule extends ValidationRule {
  final int minLength;
  final bool requireSpecialChars;

  PasswordValidationRule({this.minLength = 8, this.requireSpecialChars = true});

  @override
  ValidationResult validate(dynamic value) {
    if (value is! String) return ValidationResult.invalid('Value must be a string');
    return InputValidationService().validatePassword(
      value,
      minLength: minLength,
      requireSpecialChars: requireSpecialChars,
    );
  }
}

class URLValidationRule extends ValidationRule {
  final List<String>? allowedSchemes;

  URLValidationRule({this.allowedSchemes});

  @override
  ValidationResult validate(dynamic value) {
    if (value is! String) return ValidationResult.invalid('Value must be a string');
    return InputValidationService().validateURL(value, allowedSchemes: allowedSchemes);
  }
}
