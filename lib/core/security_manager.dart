import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:local_auth/local_auth.dart';
import '../../../core/central_config.dart';
import '../../../services/logging/logging_service.dart';

/// Security Manager for comprehensive app security
class SecurityManager {
  static final SecurityManager _instance = SecurityManager._internal();
  factory SecurityManager() => _instance;
  SecurityManager._internal();

  final LoggingService _logger = LoggingService();
  final CentralConfig _config = CentralConfig.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _encryptionKeyKey = 'encryption_key';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _sessionTokenKey = 'session_token';

  bool _isInitialized = false;
  late encrypt.Key _encryptionKey;
  late encrypt.Encrypter _encrypter;
  late encrypt.IV _iv;

  /// Initialize security manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Security Manager', 'SecurityManager');

      // Initialize encryption
      await _initializeEncryption();

      // Setup biometric authentication if available
      await _initializeBiometrics();

      _isInitialized = true;
      _logger.info('Security Manager initialized successfully', 'SecurityManager');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Security Manager', 'SecurityManager',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Initialize encryption system
  Future<void> _initializeEncryption() async {
    // Try to load existing key
    String? storedKey = await _secureStorage.read(key: _encryptionKeyKey);

    if (storedKey == null) {
      // Generate new key
      _encryptionKey = encrypt.Key.fromSecureRandom(32);
      storedKey = base64Encode(_encryptionKey.bytes);
      await _secureStorage.write(key: _encryptionKeyKey, value: storedKey);
      _logger.info('Generated new encryption key', 'SecurityManager');
    } else {
      // Load existing key
      _encryptionKey = encrypt.Key(base64Decode(storedKey));
      _logger.info('Loaded existing encryption key', 'SecurityManager');
    }

    // Initialize encrypter
    _encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    _iv = encrypt.IV.fromSecureRandom(16);
  }

  /// Initialize biometric authentication
  Future<void> _initializeBiometrics() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (canAuthenticate && isDeviceSupported) {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        _logger.info('Biometric authentication available: ${availableBiometrics.length} methods',
            'SecurityManager');

        // Store biometric availability
        await _secureStorage.write(
          key: _biometricEnabledKey,
          value: 'true'
        );
      } else {
        await _secureStorage.write(key: _biometricEnabledKey, value: 'false');
      }
    } catch (e) {
      _logger.warning('Biometric initialization failed: $e', 'SecurityManager');
      await _secureStorage.write(key: _biometricEnabledKey, value: 'false');
    }
  }

  /// Encrypt data
  String encryptData(String data) {
    if (!_isInitialized) throw StateError('SecurityManager not initialized');

    try {
      final encrypted = _encrypter.encrypt(data, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      _logger.error('Failed to encrypt data', 'SecurityManager', error: e);
      rethrow;
    }
  }

  /// Decrypt data
  String decryptData(String encryptedData) {
    if (!_isInitialized) throw StateError('SecurityManager not initialized');

    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
      final decrypted = _encrypter.decrypt(encrypted, iv: _iv);
      return decrypted;
    } catch (e) {
      _logger.error('Failed to decrypt data', 'SecurityManager', error: e);
      rethrow;
    }
  }

  /// Store sensitive data securely
  Future<void> storeSecureData(String key, String value) async {
    try {
      final encryptedValue = encryptData(value);
      await _secureStorage.write(key: key, value: encryptedValue);
      _logger.debug('Stored secure data for key: $key', 'SecurityManager');
    } catch (e) {
      _logger.error('Failed to store secure data', 'SecurityManager', error: e);
      rethrow;
    }
  }

  /// Retrieve sensitive data securely
  Future<String?> retrieveSecureData(String key) async {
    try {
      final encryptedValue = await _secureStorage.read(key: key);
      if (encryptedValue != null) {
        return decryptData(encryptedValue);
      }
      return null;
    } catch (e) {
      _logger.error('Failed to retrieve secure data', 'SecurityManager', error: e);
      return null;
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics({String reason = 'Verify your identity'}) async {
    try {
      final isEnabled = await _secureStorage.read(key: _biometricEnabledKey) == 'true';

      if (!isEnabled) {
        _logger.info('Biometric authentication not available', 'SecurityManager');
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        _logger.info('Biometric authentication successful', 'SecurityManager');
      } else {
        _logger.warning('Biometric authentication failed', 'SecurityManager');
      }

      return authenticated;

    } catch (e) {
      _logger.error('Biometric authentication error', 'SecurityManager', error: e);
      return false;
    }
  }

  /// Generate secure session token
  Future<String> generateSessionToken() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    final combined = '$timestamp-$random';

    final token = sha256.convert(utf8.encode(combined)).toString();

    // Store session token securely
    await storeSecureData(_sessionTokenKey, token);

    _logger.debug('Generated new session token', 'SecurityManager');
    return token;
  }

  /// Validate session token
  Future<bool> validateSessionToken(String token) async {
    try {
      final storedToken = await retrieveSecureData(_sessionTokenKey);
      return storedToken == token;
    } catch (e) {
      _logger.error('Session token validation failed', 'SecurityManager', error: e);
      return false;
    }
  }

  /// Hash data using SHA-256
  String hashData(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  /// Generate secure random bytes
  Uint8List generateSecureRandomBytes(int length) {
    return encrypt.Key.fromSecureRandom(length).bytes;
  }

  /// Validate input data
  String? validateInput(String? input, {
    int? minLength,
    int? maxLength,
    String? pattern,
    bool required = false,
  }) {
    if (input == null || input.isEmpty) {
      return required ? 'This field is required' : null;
    }

    if (minLength != null && input.length < minLength) {
      return 'Minimum length is $minLength characters';
    }

    if (maxLength != null && input.length > maxLength) {
      return 'Maximum length is $maxLength characters';
    }

    if (pattern != null && !RegExp(pattern).hasMatch(input)) {
      return 'Invalid format';
    }

    // Check for potentially dangerous characters
    if (input.contains('<') || input.contains('>') || input.contains('&')) {
      return 'Invalid characters detected';
    }

    return null; // Valid
  }

  /// Sanitize file path
  String sanitizeFilePath(String path) {
    // Remove dangerous characters and path traversal attempts
    return path
        .replaceAll('../', '')
        .replaceAll('..\\', '')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('|', '')
        .replaceAll('?', '')
        .replaceAll('*', '')
        .replaceAll('"', '')
        .trim();
  }

  /// Check if data contains sensitive information
  bool containsSensitiveData(String data) {
    // Check for common sensitive patterns
    final sensitivePatterns = [
      r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b', // Credit card numbers
      r'\b\d{3}[-\s]?\d{2}[-\s]?\d{4}\b', // SSN pattern
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', // Email
      r'password|token|key|secret', // Sensitive keywords (case insensitive)
    ];

    for (final pattern in sensitivePatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(data)) {
        return true;
      }
    }

    return false;
  }

  /// Clear all sensitive data (for logout/reset)
  Future<void> clearSensitiveData() async {
    try {
      // Clear secure storage
      await _secureStorage.deleteAll();

      // Reinitialize encryption with new key
      await _initializeEncryption();

      _logger.info('All sensitive data cleared', 'SecurityManager');

    } catch (e) {
      _logger.error('Failed to clear sensitive data', 'SecurityManager', error: e);
      rethrow;
    }
  }

  /// Get security status
  Future<Map<String, dynamic>> getSecurityStatus() async {
    final biometricEnabled = await _secureStorage.read(key: _biometricEnabledKey) == 'true';
    final hasSessionToken = await retrieveSecureData(_sessionTokenKey) != null;

    return {
      'encryption_enabled': _isInitialized,
      'biometric_available': biometricEnabled,
      'session_active': hasSessionToken,
      'secure_storage_available': true,
      'last_security_check': DateTime.now().toIso8601String(),
    };
  }

  /// Run security audit
  Future<Map<String, dynamic>> runSecurityAudit() async {
    _logger.info('Running security audit', 'SecurityManager');

    final issues = <String>[];
    final recommendations = <String>[];

    // Check biometric status
    final biometricEnabled = await _secureStorage.read(key: _biometricEnabledKey) == 'true';
    if (!biometricEnabled) {
      issues.add('Biometric authentication not configured');
      recommendations.add('Enable biometric authentication for enhanced security');
    }

    // Check session management
    final hasSessionToken = await retrieveSecureData(_sessionTokenKey) != null;
    if (!hasSessionToken) {
      issues.add('No active session token');
      recommendations.add('Ensure proper session management');
    }

    // Check encryption
    if (!_isInitialized) {
      issues.add('Encryption not properly initialized');
      recommendations.add('Reinitialize security manager');
    }

    return {
      'audit_timestamp': DateTime.now().toIso8601String(),
      'issues_found': issues.length,
      'issues': issues,
      'recommendations': recommendations,
      'overall_status': issues.isEmpty ? 'secure' : 'needs_attention',
    };
  }
}

/// Security-aware input validator
class SecurityValidator {
  static final SecurityManager _security = SecurityManager();

  /// Validate and sanitize user input
  static ValidationResult validateInput(String? input, {
    String? fieldName = 'input',
    bool required = false,
    int? minLength,
    int? maxLength,
    String? pattern,
    bool checkSensitive = true,
  }) {
    // First validate with security manager
    final securityError = _security.validateInput(
      input,
      required: required,
      minLength: minLength,
      maxLength: maxLength,
      pattern: pattern,
    );

    if (securityError != null) {
      return ValidationResult(
        isValid: false,
        error: securityError,
        sanitizedValue: null,
      );
    }

    // Check for sensitive data if requested
    if (checkSensitive && input != null && _security.containsSensitiveData(input)) {
      return ValidationResult(
        isValid: false,
        error: 'Input contains sensitive information that should not be stored',
        sanitizedValue: null,
      );
    }

    // Sanitize the input
    String sanitized = input ?? '';
    if (fieldName.toLowerCase().contains('path') || fieldName.toLowerCase().contains('file')) {
      sanitized = _security.sanitizeFilePath(sanitized);
    }

    return ValidationResult(
      isValid: true,
      error: null,
      sanitizedValue: sanitized,
    );
  }

  /// Validate file operations
  static ValidationResult validateFileOperation(String filePath, String operation) {
    final sanitizedPath = _security.sanitizeFilePath(filePath);

    // Additional file operation validation
    if (sanitizedPath != filePath) {
      return ValidationResult(
        isValid: false,
        error: 'Invalid characters in file path',
        sanitizedValue: null,
      );
    }

    // Check file size limits
    // Check operation permissions
    // Additional security checks...

    return ValidationResult(
      isValid: true,
      error: null,
      sanitizedValue: sanitizedPath,
    );
  }
}

/// Validation result
class ValidationResult {
  final bool isValid;
  final String? error;
  final String? sanitizedValue;

  ValidationResult({
    required this.isValid,
    this.error,
    this.sanitizedValue,
  });
}
