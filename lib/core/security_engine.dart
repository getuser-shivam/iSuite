import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/export.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecurityEngine {
  static SecurityEngine? _instance;
  static SecurityEngine get instance => _instance ??= SecurityEngine._internal();
  SecurityEngine._internal();

  // Security Configuration
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Encryption Keys
  Encrypter? _aesEncrypter;
  RSAKeyPair? _rsaKeyPair;
  String? _masterKey;
  String? _sessionKey;
  
  // Security State
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  bool _biometricEnabled = false;
  bool _twoFactorEnabled = false;
  int _failedAttempts = 0;
  DateTime? _lastFailedAttempt;
  
  // Security Policies
  SecurityLevel _currentSecurityLevel = SecurityLevel.standard;
  Duration _sessionTimeout = Duration(minutes: 30);
  int _maxFailedAttempts = 5;
  Duration _lockoutDuration = Duration(minutes: 5);
  
  // Audit Trail
  final List<SecurityEvent> _auditTrail = [];
  final Map<String, SecuritySession> _activeSessions = {};
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _isAuthenticated;
  bool get biometricEnabled => _biometricEnabled;
  bool get twoFactorEnabled => _twoFactorEnabled;
  SecurityLevel get currentSecurityLevel => _currentSecurityLevel;
  int get failedAttempts => _failedAttempts;
  List<SecurityEvent> get auditTrail => List.from(_auditTrail);
  Map<String, SecuritySession> get activeSessions => Map.from(_activeSessions);

  /// Initialize Security Engine
  Future<bool> initialize({
    SecurityLevel securityLevel = SecurityLevel.standard,
    bool enableBiometrics = false,
    bool enableTwoFactor = false,
  }) async {
    if (_isInitialized) return true;

    try {
      _currentSecurityLevel = securityLevel;
      _biometricEnabled = enableBiometrics;
      _twoFactorEnabled = enableTwoFactor;

      // Generate or load master key
      await _initializeMasterKey();
      
      // Initialize encryption
      await _initializeEncryption();
      
      // Check biometric availability
      if (_biometricEnabled) {
        _biometricEnabled = await _checkBiometricAvailability();
      }
      
      // Load security policies
      await _loadSecurityPolicies();
      
      // Initialize audit trail
      await _initializeAuditTrail();
      
      _isInitialized = true;
      await _logSecurityEvent(SecurityEventType.systemInitialized, {
        'securityLevel': securityLevel.name,
        'biometricEnabled': _biometricEnabled,
        'twoFactorEnabled': _twoFactorEnabled,
      });
      
      return true;
    } catch (e) {
      await _logSecurityEvent(SecurityEventType.initializationFailed, {'error': e.toString()});
      return false;
    }
  }

  Future<void> _initializeMasterKey() async {
    // Try to load existing master key
    _masterKey = await _secureStorage.read(key: 'master_key');
    
    if (_masterKey == null) {
      // Generate new master key
      _masterKey = _generateSecureKey(32);
      await _secureStorage.write(key: 'master_key', value: _masterKey!);
    }
  }

  Future<void> _initializeEncryption() async {
    // Initialize AES encryption
    final aesKey = Key.fromBase64(_masterKey!);
    _aesEncrypter = Encrypter(AES(aesKey));
    
    // Generate RSA key pair
    await _generateRSAKeyPair();
    
    // Generate session key
    _sessionKey = _generateSecureKey(32);
  }

  Future<void> _generateRSAKeyPair() async {
    final keyGen = RSAKeyGenerator();
    keyGen.init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048),
      SecureRandom('Fortuna'),
    ));
    
    final pair = keyGen.generateKeyPair();
    _rsaKeyPair = RSAKeyPair(
      privateKey: pair.privateKey as RSAPrivateKey,
      publicKey: pair.publicKey as RSAPublicKey,
    );
  }

  Future<bool> _checkBiometricAvailability() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return canCheckBiometrics && availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadSecurityPolicies() async {
    // Load security policies from secure storage
    final policies = await _secureStorage.read(key: 'security_policies');
    if (policies != null) {
      final data = jsonDecode(policies);
      _sessionTimeout = Duration(minutes: data['sessionTimeout'] ?? 30);
      _maxFailedAttempts = data['maxFailedAttempts'] ?? 5;
      _lockoutDuration = Duration(minutes: data['lockoutDuration'] ?? 5);
    }
  }

  Future<void> _initializeAuditTrail() async {
    // Load existing audit trail
    final trail = await _secureStorage.read(key: 'audit_trail');
    if (trail != null) {
      final data = jsonDecode(trail);
      _auditTrail.addAll((data as List).map((e) => SecurityEvent.fromMap(e)));
    }
  }

  /// Authenticate user
  Future<AuthenticationResult> authenticate({
    String? password,
    bool useBiometrics = false,
    String? twoFactorCode,
  }) async {
    if (!_isInitialized) {
      return AuthenticationResult(success: false, error: 'Security engine not initialized');
    }

    // Check if account is locked
    if (_isAccountLocked()) {
      return AuthenticationResult(
        success: false,
        error: 'Account locked. Try again later.',
        lockoutRemaining: _getLockoutRemaining(),
      );
    }

    try {
      bool authenticated = false;
      String? error;

      if (useBiometrics && _biometricEnabled) {
        authenticated = await _authenticateWithBiometrics();
        if (!authenticated) {
          error = 'Biometric authentication failed';
        }
      } else if (password != null) {
        authenticated = await _authenticateWithPassword(password);
        if (!authenticated) {
          error = 'Invalid password';
        }
      } else {
        return AuthenticationResult(success: false, error: 'No authentication method provided');
      }

      // Check two-factor authentication
      if (authenticated && _twoFactorEnabled && twoFactorCode == null) {
        return AuthenticationResult(
          success: false,
          requiresTwoFactor: true,
          error: 'Two-factor authentication required',
        );
      } else if (authenticated && _twoFactorEnabled && twoFactorCode != null) {
        authenticated = await _verifyTwoFactorCode(twoFactorCode);
        if (!authenticated) {
          error = 'Invalid two-factor code';
        }
      }

      if (authenticated) {
        _isAuthenticated = true;
        _failedAttempts = 0;
        _lastFailedAttempt = null;
        
        // Create session
        final sessionId = _generateSessionId();
        _activeSessions[sessionId] = SecuritySession(
          id: sessionId,
          userId: 'current_user',
          startTime: DateTime.now(),
          expiresAt: DateTime.now().add(_sessionTimeout),
          securityLevel: _currentSecurityLevel,
        );
        
        await _logSecurityEvent(SecurityEventType.authenticationSuccess, {
          'method': useBiometrics ? 'biometrics' : 'password',
          'sessionId': sessionId,
        });
        
        return AuthenticationResult(success: true, sessionId: sessionId);
      } else {
        _failedAttempts++;
        _lastFailedAttempt = DateTime.now();
        
        await _logSecurityEvent(SecurityEventType.authenticationFailed, {
          'method': useBiometrics ? 'biometrics' : 'password',
          'failedAttempts': _failedAttempts,
        });
        
        return AuthenticationResult(success: false, error: error);
      }
    } catch (e) {
      await _logSecurityEvent(SecurityEventType.authenticationError, {'error': e.toString()});
      return AuthenticationResult(success: false, error: 'Authentication error: $e');
    }
  }

  Future<bool> _authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access iSuite',
        options: AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  Future<bool> _authenticateWithPassword(String password) async {
    // Hash the provided password
    final hashedPassword = _hashPassword(password);
    
    // Compare with stored password hash
    final storedHash = await _secureStorage.read(key: 'password_hash');
    
    return storedHash != null && storedHash == hashedPassword;
  }

  Future<bool> _verifyTwoFactorCode(String code) async {
    // Implement 2FA verification (TOTP, SMS, etc.)
    // For now, accept any 6-digit code
    return code.length == 6 && RegExp(r'^\d{6}$').hasMatch(code);
  }

  /// Encrypt data
  EncryptedData encrypt(String data, {String? key}) async {
    if (!_isInitialized) {
      throw StateError('Security engine not initialized');
    }

    try {
      final encrypter = key != null 
          ? Encrypter(AES(Key.fromBase64(key)))
          : _aesEncrypter!;
      
      final encrypted = encrypter.encrypt(data);
      final iv = encrypter.iv.base64;
      
      return EncryptedData(
        data: encrypted.base64,
        iv: iv,
        algorithm: 'AES-256',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      await _logSecurityEvent(SecurityEventType.encryptionFailed, {'error': e.toString()});
      rethrow;
    }
  }

  /// Decrypt data
  Future<String> decrypt(EncryptedData encryptedData, {String? key}) async {
    if (!_isInitialized) {
      throw StateError('Security engine not initialized');
    }

    try {
      final encrypter = key != null 
          ? Encrypter(AES(Key.fromBase64(key)))
          : _aesEncrypter!;
      
      final encrypted = Encrypted.fromBase64(encryptedData.data);
      final decrypted = encrypter.decrypt(encrypted);
      
      return decrypted;
    } catch (e) {
      await _logSecurityEvent(SecurityEventType.decryptionFailed, {'error': e.toString()});
      rethrow;
    }
  }

  /// Encrypt file
  Future<EncryptedFile> encryptFile(Uint8List fileData, String fileName) async {
    if (!_isInitialized) {
      throw StateError('Security engine not initialized');
    }

    try {
      // Generate file-specific key
      final fileKey = _generateSecureKey(32);
      final encrypter = Encrypter(AES(Key.fromBase64(fileKey)));
      
      // Encrypt file data
      final encrypted = encrypter.encryptBytes(fileData);
      
      // Encrypt file key with RSA
      final encryptedKey = _encryptWithRSA(fileKey);
      
      return EncryptedFile(
        fileName: fileName,
        encryptedData: encrypted.base64,
        encryptedKey: encryptedKey,
        iv: encrypter.iv.base64,
        algorithm: 'AES-256',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      await _logSecurityEvent(SecurityEventType.fileEncryptionFailed, {
        'fileName': fileName,
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Decrypt file
  Future<Uint8List> decryptFile(EncryptedFile encryptedFile) async {
    if (!_isInitialized) {
      throw StateError('Security engine not initialized');
    }

    try {
      // Decrypt file key with RSA
      final fileKey = _decryptWithRSA(encryptedFile.encryptedKey);
      
      // Decrypt file data
      final encrypter = Encrypter(AES(Key.fromBase64(fileKey)));
      final encrypted = Encrypted.fromBase64(encryptedFile.encryptedData);
      final decrypted = encrypter.decryptBytes(encrypted);
      
      return decrypted;
    } catch (e) {
      await _logSecurityEvent(SecurityEventType.fileDecryptionFailed, {
        'fileName': encryptedFile.fileName,
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Sign data
  DigitalSignature signData(String data) async {
    if (!_isInitialized || _rsaKeyPair == null) {
      throw StateError('Security engine not initialized');
    }

    try {
      final signer = Signer(RSASigner(SHA256(), 'private'));
      final signature = signer.sign(
        Uint8List.fromList(data.codeUnits),
        _rsaKeyPair!.privateKey,
      );
      
      return DigitalSignature(
        signature: base64Encode(signature),
        algorithm: 'RSA-SHA256',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      await _logSecurityEvent(SecurityEventType.signingFailed, {'error': e.toString()});
      rethrow;
    }
  }

  /// Verify signature
  Future<bool> verifySignature(String data, DigitalSignature signature) async {
    if (!_isInitialized || _rsaKeyPair == null) {
      throw StateError('Security engine not initialized');
    }

    try {
      final verifier = Signer(RSASigner(SHA256(), 'public'));
      final sigBytes = base64Decode(signature.signature);
      
      return verifier.verify(
        Uint8List.fromList(data.codeUnits),
        sigBytes,
        _rsaKeyPair!.publicKey,
      );
    } catch (e) {
      await _logSecurityEvent(SecurityEventType.verificationFailed, {'error': e.toString()});
      return false;
    }
  }

  /// Hash password
  String _hashPassword(String password) {
    final salt = 'iSuite_Salt_2024';
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate secure key
  String _generateSecureKey(int length) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Generate session ID
  String _generateSessionId() {
    return _generateSecureKey(32);
  }

  /// Encrypt with RSA
  String _encryptWithRSA(String data) {
    if (_rsaKeyPair == null) {
      throw StateError('RSA key pair not initialized');
    }

    final encrypter = Encrypter(RSA(publicKey: _rsaKeyPair!.publicKey));
    final encrypted = encrypter.encrypt(data);
    return encrypted.base64;
  }

  /// Decrypt with RSA
  String _decryptWithRSA(String encryptedData) {
    if (_rsaKeyPair == null) {
      throw StateError('RSA key pair not initialized');
    }

    final encrypter = Encrypter(RSA(privateKey: _rsaKeyPair!.privateKey));
    final encrypted = Encrypted.fromBase64(encryptedData);
    return encrypter.decrypt(encrypted);
  }

  /// Check if account is locked
  bool _isAccountLocked() {
    if (_failedAttempts < _maxFailedAttempts) return false;
    if (_lastFailedAttempt == null) return false;
    
    final timeSinceLastAttempt = DateTime.now().difference(_lastFailedAttempt!);
    return timeSinceLastAttempt < _lockoutDuration;
  }

  /// Get remaining lockout time
  Duration _getLockoutRemaining() {
    if (_lastFailedAttempt == null) return Duration.zero;
    
    final timeSinceLastAttempt = DateTime.now().difference(_lastFailedAttempt!);
    final remaining = _lockoutDuration - timeSinceLastAttempt;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Logout
  Future<void> logout(String sessionId) async {
    _activeSessions.remove(sessionId);
    _isAuthenticated = false;
    
    await _logSecurityEvent(SecurityEventType.logout, {'sessionId': sessionId});
  }

  /// Change password
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (!_isInitialized) return false;

    try {
      // Verify old password
      if (!await _authenticateWithPassword(oldPassword)) {
        return false;
      }

      // Hash new password
      final hashedPassword = _hashPassword(newPassword);
      
      // Store new password hash
      await _secureStorage.write(key: 'password_hash', value: hashedPassword);
      
      await _logSecurityEvent(SecurityEventType.passwordChanged, {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      return true;
    } catch (e) {
      await _logSecurityEvent(SecurityEventType.passwordChangeFailed, {'error': e.toString()});
      return false;
    }
  }

  /// Enable/disable biometrics
  Future<bool> setBiometricEnabled(bool enabled) async {
    if (enabled && !await _checkBiometricAvailability()) {
      return false;
    }

    _biometricEnabled = enabled;
    await _secureStorage.write(key: 'biometric_enabled', value: enabled.toString());
    
    await _logSecurityEvent(SecurityEventType.biometricSettingsChanged, {
      'enabled': enabled,
    });
    
    return true;
  }

  /// Enable/disable two-factor authentication
  Future<void> setTwoFactorEnabled(bool enabled) async {
    _twoFactorEnabled = enabled;
    await _secureStorage.write(key: 'two_factor_enabled', value: enabled.toString());
    
    await _logSecurityEvent(SecurityEventType.twoFactorSettingsChanged, {
      'enabled': enabled,
    });
  }

  /// Update security level
  Future<void> setSecurityLevel(SecurityLevel level) async {
    _currentSecurityLevel = level;
    await _secureStorage.write(key: 'security_level', value: level.name);
    
    await _logSecurityEvent(SecurityEventType.securityLevelChanged, {
      'level': level.name,
    });
  }

  /// Get security status
  Map<String, dynamic> getSecurityStatus() {
    return {
      'isInitialized': _isInitialized,
      'isAuthenticated': _isAuthenticated,
      'currentSecurityLevel': _currentSecurityLevel.name,
      'biometricEnabled': _biometricEnabled,
      'twoFactorEnabled': _twoFactorEnabled,
      'failedAttempts': _failedAttempts,
      'activeSessions': _activeSessions.length,
      'isAccountLocked': _isAccountLocked(),
      'lockoutRemaining': _getLockoutRemaining().inSeconds,
    };
  }

  /// Log security event
  Future<void> _logSecurityEvent(SecurityEventType type, Map<String, dynamic> data) async {
    final event = SecurityEvent(
      id: _generateSessionId(),
      type: type,
      timestamp: DateTime.now(),
      data: data,
    );
    
    _auditTrail.add(event);
    
    // Limit audit trail size
    if (_auditTrail.length > 1000) {
      _auditTrail.removeRange(0, _auditTrail.length - 1000);
    }
    
    // Save to secure storage
    await _secureStorage.write(
      key: 'audit_trail',
      value: jsonEncode(_auditTrail.map((e) => e.toMap()).toList()),
    );
  }

  /// Generate security report
  Map<String, dynamic> generateSecurityReport() {
    final now = DateTime.now();
    final last24Hours = now.subtract(Duration(hours: 24));
    final last7Days = now.subtract(Duration(days: 7));
    
    final recentEvents = _auditTrail.where((e) => e.timestamp.isAfter(last24Hours)).toList();
    final weeklyEvents = _auditTrail.where((e) => e.timestamp.isAfter(last7Days)).toList();
    
    return {
      'generatedAt': now.toIso8601String(),
      'securityLevel': _currentSecurityLevel.name,
      'biometricEnabled': _biometricEnabled,
      'twoFactorEnabled': _twoFactorEnabled,
      'activeSessions': _activeSessions.length,
      'failedAttempts': _failedAttempts,
      'isAccountLocked': _isAccountLocked(),
      'statistics': {
        'last24Hours': {
          'totalEvents': recentEvents.length,
          'authenticationSuccess': recentEvents.where((e) => e.type == SecurityEventType.authenticationSuccess).length,
          'authenticationFailed': recentEvents.where((e) => e.type == SecurityEventType.authenticationFailed).length,
          'encryptionOperations': recentEvents.where((e) => e.type == SecurityEventType.encryptionFailed || e.type == SecurityEventType.decryptionFailed).length,
        },
        'last7Days': {
          'totalEvents': weeklyEvents.length,
          'authenticationSuccess': weeklyEvents.where((e) => e.type == SecurityEventType.authenticationSuccess).length,
          'authenticationFailed': weeklyEvents.where((e) => e.type == SecurityEventType.authenticationFailed).length,
          'securityEvents': weeklyEvents.where((e) => e.type.index >= SecurityEventType.securityLevelChanged.index).length,
        },
      },
      'recommendations': _generateSecurityRecommendations(),
    };
  }

  List<String> _generateSecurityRecommendations() {
    final recommendations = <String>[];
    
    if (!_biometricEnabled) {
      recommendations.add('Enable biometric authentication for enhanced security');
    }
    
    if (!_twoFactorEnabled) {
      recommendations.add('Enable two-factor authentication for additional protection');
    }
    
    if (_currentSecurityLevel.index < SecurityLevel.high.index) {
      recommendations.add('Consider upgrading to a higher security level');
    }
    
    if (_failedAttempts > 0) {
      recommendations.add('Review recent failed authentication attempts');
    }
    
    if (_activeSessions.length > 1) {
      recommendations.add('Review active sessions and terminate any unauthorized ones');
    }
    
    return recommendations;
  }

  /// Dispose security engine
  Future<void> dispose() async {
    _isInitialized = false;
    _isAuthenticated = false;
    _activeSessions.clear();
    _auditTrail.clear();
    
    // Clear sensitive data
    _masterKey = null;
    _sessionKey = null;
    _aesEncrypter = null;
    _rsaKeyPair = null;
  }
}

// Security Models
class AuthenticationResult {
  final bool success;
  final String? error;
  final String? sessionId;
  final bool requiresTwoFactor;
  final Duration? lockoutRemaining;

  const AuthenticationResult({
    required this.success,
    this.error,
    this.sessionId,
    this.requiresTwoFactor = false,
    this.lockoutRemaining,
  });
}

class EncryptedData {
  final String data;
  final String iv;
  final String algorithm;
  final DateTime timestamp;

  const EncryptedData({
    required this.data,
    required this.iv,
    required this.algorithm,
    required this.timestamp,
  });
}

class EncryptedFile {
  final String fileName;
  final String encryptedData;
  final String encryptedKey;
  final String iv;
  final String algorithm;
  final DateTime timestamp;

  const EncryptedFile({
    required this.fileName,
    required this.encryptedData,
    required this.encryptedKey,
    required this.iv,
    required this.algorithm,
    required this.timestamp,
  });
}

class DigitalSignature {
  final String signature;
  final String algorithm;
  final DateTime timestamp;

  const DigitalSignature({
    required this.signature,
    required this.algorithm,
    required this.timestamp,
  });
}

class SecurityEvent {
  final String id;
  final SecurityEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const SecurityEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'data': data,
    };
  }

  factory SecurityEvent.fromMap(Map<String, dynamic> map) {
    return SecurityEvent(
      id: map['id'],
      type: SecurityEventType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SecurityEventType.unknown,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
    );
  }
}

class SecuritySession {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime expiresAt;
  final SecurityLevel securityLevel;

  const SecuritySession({
    required this.id,
    required this.userId,
    required this.startTime,
    required this.expiresAt,
    required this.securityLevel,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Duration get remaining => expiresAt.difference(DateTime.now());
}

class RSAKeyPair {
  final RSAPrivateKey privateKey;
  final RSAPublicKey publicKey;

  const RSAKeyPair({
    required this.privateKey,
    required this.publicKey,
  });
}

// Enums
enum SecurityLevel {
  basic,
  standard,
  high,
  maximum,
}

enum SecurityEventType {
  systemInitialized,
  initializationFailed,
  authenticationSuccess,
  authenticationFailed,
  authenticationError,
  logout,
  passwordChanged,
  passwordChangeFailed,
  biometricSettingsChanged,
  twoFactorSettingsChanged,
  securityLevelChanged,
  encryptionFailed,
  decryptionFailed,
  fileEncryptionFailed,
  fileDecryptionFailed,
  signingFailed,
  verificationFailed,
  unknown,
}
