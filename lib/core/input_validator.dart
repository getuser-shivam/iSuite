import 'dart:convert';

/// Utility class for input validation and sanitization
class InputValidator {
  static const int maxFileNameLength = 255;
  static const int maxPathLength = 4096;
  static const int maxTextLength = 10000;

  /// Validate file name
  static ValidationResult validateFileName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return ValidationResult.invalid('File name cannot be empty');
    }

    final trimmed = name.trim();

    if (trimmed.length > maxFileNameLength) {
      return ValidationResult.invalid('File name too long (max $maxFileNameLength characters)');
    }

    // Check for invalid characters
    final invalidChars = RegExp(r'[<>:"/\\|?*\x00-\x1f]');
    if (invalidChars.hasMatch(trimmed)) {
      return ValidationResult.invalid('File name contains invalid characters');
    }

    // Check for reserved names (Windows)
    final reservedNames = [
      'CON', 'PRN', 'AUX', 'NUL',
      'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
      'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9'
    ];

    if (reservedNames.contains(trimmed.toUpperCase())) {
      return ValidationResult.invalid('File name is reserved by system');
    }

    return ValidationResult.valid(trimmed);
  }

  /// Validate directory path
  static ValidationResult validatePath(String? path) {
    if (path == null || path.trim().isEmpty) {
      return ValidationResult.invalid('Path cannot be empty');
    }

    final trimmed = path.trim();

    if (trimmed.length > maxPathLength) {
      return ValidationResult.invalid('Path too long (max $maxPathLength characters)');
    }

    // Basic path validation
    if (trimmed.contains('\x00')) {
      return ValidationResult.invalid('Path contains invalid characters');
    }

    return ValidationResult.valid(trimmed);
  }

  /// Validate URL
  static ValidationResult validateUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return ValidationResult.invalid('URL cannot be empty');
    }

    final trimmed = url.trim();

    try {
      final uri = Uri.parse(trimmed);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return ValidationResult.invalid('Invalid URL format');
      }

      if (uri.scheme != 'http' && uri.scheme != 'https') {
        return ValidationResult.invalid('URL must use HTTP or HTTPS');
      }

      return ValidationResult.valid(trimmed);
    } catch (e) {
      return ValidationResult.invalid('Invalid URL format');
    }
  }

  /// Validate email
  static ValidationResult validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return ValidationResult.invalid('Email cannot be empty');
    }

    final trimmed = email.trim();

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(trimmed)) {
      return ValidationResult.invalid('Invalid email format');
    }

    if (trimmed.length > 254) {
      return ValidationResult.invalid('Email too long');
    }

    return ValidationResult.valid(trimmed);
  }

  /// Validate port number
  static ValidationResult validatePort(String? port) {
    if (port == null || port.trim().isEmpty) {
      return ValidationResult.invalid('Port cannot be empty');
    }

    final trimmed = port.trim();

    final portNumber = int.tryParse(trimmed);
    if (portNumber == null) {
      return ValidationResult.invalid('Port must be a number');
    }

    if (portNumber < 1 || portNumber > 65535) {
      return ValidationResult.invalid('Port must be between 1 and 65535');
    }

    return ValidationResult.valid(portNumber.toString());
  }

  /// Validate text input
  static ValidationResult validateText(String? text, {int maxLength = maxTextLength}) {
    if (text == null) {
      return ValidationResult.invalid('Text cannot be null');
    }

    if (text.length > maxLength) {
      return ValidationResult.invalid('Text too long (max $maxLength characters)');
    }

    // Basic sanitization - remove potential script tags
    final sanitized = text.replaceAll(RegExp(r'<[^>]*>'), '').trim();

    return ValidationResult.valid(sanitized);
  }

  /// Sanitize HTML input (remove dangerous tags)
  static String sanitizeHtml(String input) {
    // Remove script tags and other dangerous elements
    var sanitized = input.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '');
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]+>', caseSensitive: false), '');
    return sanitized.trim();
  }

  /// Validate JSON input
  static ValidationResult validateJson(String? jsonString) {
    if (jsonString == null || jsonString.trim().isEmpty) {
      return ValidationResult.invalid('JSON cannot be empty');
    }

    try {
      jsonDecode(jsonString);
      return ValidationResult.valid(jsonString);
    } catch (e) {
      return ValidationResult.invalid('Invalid JSON format: ${e.toString()}');
    }
  }

  /// Validate file size
  static ValidationResult validateFileSize(int? size, {int maxSize = 100 * 1024 * 1024}) {
    if (size == null || size < 0) {
      return ValidationResult.invalid('Invalid file size');
    }

    if (size > maxSize) {
      final maxSizeMB = (maxSize / (1024 * 1024)).round();
      return ValidationResult.invalid('File too large (max ${maxSizeMB}MB)');
    }

    return ValidationResult.valid(size.toString());
  }
}

/// Result class for validation operations
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? sanitizedValue;

  ValidationResult._(this.isValid, this.errorMessage, this.sanitizedValue);

  factory ValidationResult.valid(String value) {
    return ValidationResult._(true, null, value);
  }

  factory ValidationResult.invalid(String message) {
    return ValidationResult._(false, message, null);
  }

  String get value => sanitizedValue ?? '';
}
