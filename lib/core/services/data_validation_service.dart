import '../logging_service.dart';

/// Data Validation Service for iSuite
/// Provides comprehensive input validation and sanitization
class DataValidationService {
  static final DataValidationService _instance = DataValidationService._internal();
  factory DataValidationService() => _instance;
  DataValidationService._internal();

  final LoggingService _logger = LoggingService();

  /// Validate email address
  ValidationResult validateEmail(String email) {
    if (email.isEmpty) {
      return ValidationResult.invalid('Email is required');
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    if (!emailRegex.hasMatch(email)) {
      return ValidationResult.invalid('Invalid email format');
    }

    if (email.length > 254) {
      return ValidationResult.invalid('Email too long');
    }

    return ValidationResult.valid();
  }

  /// Validate password strength
  ValidationResult validatePassword(String password) {
    if (password.isEmpty) {
      return ValidationResult.invalid('Password is required');
    }

    if (password.length < 8) {
      return ValidationResult.invalid('Password must be at least 8 characters');
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return ValidationResult.invalid('Password must contain uppercase letter');
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return ValidationResult.invalid('Password must contain lowercase letter');
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return ValidationResult.invalid('Password must contain number');
    }

    return ValidationResult.valid();
  }

  /// Validate file name
  ValidationResult validateFileName(String fileName) {
    if (fileName.isEmpty) {
      return ValidationResult.invalid('File name is required');
    }

    if (fileName.length > 255) {
      return ValidationResult.invalid('File name too long');
    }

    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(fileName)) {
      return ValidationResult.invalid('File name contains invalid characters');
    }

    return ValidationResult.valid();
  }

  /// Validate URL
  ValidationResult validateUrl(String url) {
    if (url.isEmpty) {
      return ValidationResult.invalid('URL is required');
    }

    final urlRegex = RegExp(r'^(https?|ftp)://[^\s/$.?#].[^\s]*$');
    if (!urlRegex.hasMatch(url)) {
      return ValidationResult.invalid('Invalid URL format');
    }

    return ValidationResult.valid();
  }

  /// Sanitize text input
  String sanitizeText(String text) {
    // Remove potentially harmful characters
    return text.replaceAll(RegExp(r'[<>]'), '');
  }

  /// Validate file size
  ValidationResult validateFileSize(int sizeInBytes, {int maxSizeInMB = 100}) {
    final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
    if (sizeInBytes > maxSizeInBytes) {
      return ValidationResult.invalid('File size exceeds ${maxSizeInMB}MB limit');
    }

    return ValidationResult.valid();
  }
}

/// Validation Result class
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult._(this.isValid, this.errorMessage);

  factory ValidationResult.valid() => ValidationResult._(true, null);
  factory ValidationResult.invalid(String message) => ValidationResult._(false, message);
}
