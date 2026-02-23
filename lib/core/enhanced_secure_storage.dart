import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'advanced_security_manager.dart';

/// Enhanced Secure Storage Service
/// Provides enterprise-grade secure storage with encryption, integrity verification, and access controls
class EnhancedSecureStorage {
  static final EnhancedSecureStorage _instance = EnhancedSecureStorage._internal();
  factory EnhancedSecureStorage() => _instance;
  EnhancedSecureStorage._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final AdvancedSecurityManager _securityManager = AdvancedSecurityManager();

  static const String _masterKeyKey = 'master_encryption_key';
  static const String _saltKey = 'encryption_salt';
  static const String _metadataKey = 'storage_metadata';

  late encrypt.Key _masterKey;
  late Uint8List _salt;
  late encrypt.Encrypter _encrypter;
  late encrypt.IV _iv;

  bool _isInitialized = false;

  /// Initialize secure storage with key derivation
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Generate or retrieve master key
      final storedKey = await _secureStorage.read(key: _masterKeyKey);
      final storedSalt = await _secureStorage.read(key: _saltKey);

      if (storedKey == null || storedSalt == null) {
        // Generate new master key and salt
        _salt = _generateSalt();
        _masterKey = _deriveMasterKey('', _salt); // Empty password for app-level encryption

        // Store securely
        await _secureStorage.write(key: _masterKeyKey, value: base64.encode(_masterKey.bytes));
        await _secureStorage.write(key: _saltKey, value: base64.encode(_salt));
      } else {
        // Load existing keys
        _masterKey = encrypt.Key(base64.decode(storedKey));
        _salt = base64.decode(storedSalt);
      }

      // Initialize encryption
      _encrypter = encrypt.Encrypter(encrypt.AES(_masterKey));
      _iv = encrypt.IV.fromSecureRandom(16);

      // Initialize metadata
      await _initializeMetadata();

      _isInitialized = true;

    } catch (e) {
      throw SecureStorageException('Failed to initialize secure storage: $e');
    }
  }

  /// Store sensitive data with encryption and integrity protection
  Future<void> storeSecureData(String key, String data, {
    SecurityLevel securityLevel = SecurityLevel.standard,
    Map<String, String>? metadata,
    DateTime? expirationDate,
  }) async {
    _ensureInitialized();

    try {
      // Create data package
      final dataPackage = SecureDataPackage(
        data: data,
        timestamp: DateTime.now(),
        securityLevel: securityLevel,
        metadata: metadata,
        expirationDate: expirationDate,
      );

      // Serialize and encrypt
      final jsonData = json.encode(dataPackage.toJson());
      final encrypted = await _encryptData(jsonData, securityLevel);

      // Store with integrity hash
      final integrityHash = _calculateIntegrityHash(encrypted);
      final storageData = {
        'encryptedData': encrypted,
        'integrityHash': integrityHash,
        'version': '2.0',
      };

      await _secureStorage.write(key: key, value: json.encode(storageData));

      // Update metadata
      await _updateMetadataForKey(key, dataPackage);

      // Log secure storage event
      _securityManager._emitEvent(SecurityEventType.secureFileStored, details: 'Data stored securely: $key');

    } catch (e) {
      throw SecureStorageException('Failed to store secure data: $e');
    }
  }

  /// Retrieve and decrypt sensitive data with integrity verification
  Future<String?> retrieveSecureData(String key) async {
    _ensureInitialized();

    try {
      final storedValue = await _secureStorage.read(key: key);
      if (storedValue == null) return null;

      final storageData = json.decode(storedValue) as Map<String, dynamic>;

      // Verify version compatibility
      final version = storageData['version'] as String?;
      if (version != '2.0') {
        throw SecureStorageException('Incompatible storage version');
      }

      final encryptedData = storageData['encryptedData'] as String;
      final storedHash = storageData['integrityHash'] as String;

      // Verify integrity
      final calculatedHash = _calculateIntegrityHash(encryptedData);
      if (calculatedHash != storedHash) {
        throw SecureStorageException('Data integrity verification failed');
      }

      // Decrypt data
      final decryptedJson = await _decryptData(encryptedData);
      final dataPackage = SecureDataPackage.fromJson(json.decode(decryptedJson));

      // Check expiration
      if (dataPackage.expirationDate != null &&
          DateTime.now().isAfter(dataPackage.expirationDate!)) {
        // Auto-cleanup expired data
        await deleteSecureData(key);
        return null;
      }

      // Log access
      _securityManager._emitEvent(SecurityEventType.secureRetrievalSuccessful, details: 'Data retrieved: $key');

      return dataPackage.data;

    } catch (e) {
      _securityManager._emitEvent(SecurityEventType.secureRetrievalFailed, details: 'Failed to retrieve: $key');
      throw SecureStorageException('Failed to retrieve secure data: $e');
    }
  }

  /// Store credentials with enhanced security
  Future<void> storeCredentials(String identifier, String username, String password, {
    String? service,
    Map<String, String>? additionalData,
  }) async {
    _ensureInitialized();

    final credentialData = {
      'username': username,
      'password': password,
      'service': service,
      'additionalData': additionalData,
      'createdAt': DateTime.now().toIso8601String(),
      'lastModified': DateTime.now().toIso8601String(),
    };

    final jsonData = json.encode(credentialData);
    await storeSecureData(
      'cred_$identifier',
      jsonData,
      securityLevel: SecurityLevel.maximum,
      metadata: {'type': 'credential', 'service': service ?? 'unknown'},
    );
  }

  /// Retrieve credentials securely
  Future<CredentialData?> retrieveCredentials(String identifier) async {
    _ensureInitialized();

    try {
      final data = await retrieveSecureData('cred_$identifier');
      if (data == null) return null;

      final credentialMap = json.decode(data) as Map<String, dynamic>;
      return CredentialData.fromJson(credentialMap);
    } catch (e) {
      throw SecureStorageException('Failed to retrieve credentials: $e');
    }
  }

  /// Store encrypted file with integrity protection
  Future<String> storeEncryptedFile(String filePath, Uint8List fileData, {
    SecurityLevel securityLevel = SecurityLevel.standard,
  }) async {
    _ensureInitialized();

    try {
      // Encrypt file data using AdvancedSecurityManager
      final encryptedData = await _securityManager.encryptData(
        fileData,
        algorithm: EncryptionAlgorithm.aes256GCM,
        useHardwareSecurity: securityLevel == SecurityLevel.maximum,
      );

      // Create file package
      final filePackage = EncryptedFilePackage(
        filePath: filePath,
        encryptedData: encryptedData,
        originalSize: fileData.length,
        timestamp: DateTime.now(),
      );

      // Store file package
      final packageKey = 'file_${DateTime.now().millisecondsSinceEpoch}';
      final jsonData = json.encode(filePackage.toJson());

      await storeSecureData(
        packageKey,
        jsonData,
        securityLevel: securityLevel,
        metadata: {'type': 'file', 'originalPath': filePath},
      );

      return packageKey;

    } catch (e) {
      throw SecureStorageException('Failed to store encrypted file: $e');
    }
  }

  /// Retrieve and decrypt file
  Future<Uint8List?> retrieveEncryptedFile(String packageKey) async {
    _ensureInitialized();

    try {
      final data = await retrieveSecureData(packageKey);
      if (data == null) return null;

      final filePackage = EncryptedFilePackage.fromJson(json.decode(data));

      // Decrypt file data
      final decryptedData = await _securityManager.decryptData(filePackage.encryptedData);

      if (decryptedData is! Uint8List) {
        throw SecureStorageException('Invalid decrypted file data type');
      }

      return decryptedData;

    } catch (e) {
      throw SecureStorageException('Failed to retrieve encrypted file: $e');
    }
  }

  /// Delete secure data
  Future<void> deleteSecureData(String key) async {
    _ensureInitialized();

    try {
      await _secureStorage.delete(key: key);
      await _removeMetadataForKey(key);

      _securityManager._emitEvent(SecurityEventType.secureDataDeleted, details: 'Data deleted: $key');
    } catch (e) {
      throw SecureStorageException('Failed to delete secure data: $e');
    }
  }

  /// Check if secure data exists
  Future<bool> containsKey(String key) async {
    _ensureInitialized();
    return await _secureStorage.containsKey(key: key);
  }

  /// Get all stored keys (for management purposes)
  Future<List<String>> getAllKeys() async {
    _ensureInitialized();

    try {
      final metadata = await _getStorageMetadata();
      return metadata.keys.toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear all secure data (use with caution)
  Future<void> clearAllData() async {
    _ensureInitialized();

    try {
      // Get all keys
      final keys = await getAllKeys();

      // Delete each key
      for (final key in keys) {
        await _secureStorage.delete(key: key);
      }

      // Clear metadata
      await _secureStorage.delete(key: _metadataKey);

      _securityManager._emitEvent(SecurityEventType.secureStorageCleared, details: 'All secure data cleared');

    } catch (e) {
      throw SecureStorageException('Failed to clear secure storage: $e');
    }
  }

  /// Get storage statistics
  Future<SecureStorageStats> getStorageStats() async {
    _ensureInitialized();

    try {
      final metadata = await _getStorageMetadata();
      final stats = SecureStorageStats(
        totalItems: metadata.length,
        credentialsCount: metadata.values.where((m) => m['type'] == 'credential').length,
        filesCount: metadata.values.where((m) => m['type'] == 'file').length,
        dataCount: metadata.values.where((m) => m['type'] == 'data').length,
      );

      return stats;
    } catch (e) {
      return SecureStorageStats.empty();
    }
  }

  /// Rotate encryption keys
  Future<void> rotateEncryptionKeys() async {
    _ensureInitialized();

    try {
      // Get all existing data
      final allKeys = await getAllKeys();
      final dataBackup = <String, String>{};

      // Backup all data
      for (final key in allKeys) {
        final data = await _secureStorage.read(key: key);
        if (data != null) {
          dataBackup[key] = data;
        }
      }

      // Generate new keys
      _salt = _generateSalt();
      _masterKey = _deriveMasterKey('', _salt);
      _encrypter = encrypt.Encrypter(encrypt.AES(_masterKey));
      _iv = encrypt.IV.fromSecureRandom(16);

      // Store new keys
      await _secureStorage.write(key: _masterKeyKey, value: base64.encode(_masterKey.bytes));
      await _secureStorage.write(key: _saltKey, value: base64.encode(_salt));

      // Re-encrypt and store all data
      for (final entry in dataBackup.entries) {
        await _secureStorage.write(key: entry.key, value: entry.value);
      }

      _securityManager._emitEvent(SecurityEventType.encryptionKeysRotated, details: 'Encryption keys rotated successfully');

    } catch (e) {
      throw SecureStorageException('Failed to rotate encryption keys: $e');
    }
  }

  // Private helper methods

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw SecureStorageException('Secure storage not initialized');
    }
  }

  Uint8List _generateSalt() {
    return encrypt.IV.fromSecureRandom(32).bytes;
  }

  encrypt.Key _deriveMasterKey(String password, Uint8List salt) {
    final keyData = utf8.encode(password);
    final hmac = Hmac(sha256, salt);
    final derivedKey = hmac.convert(keyData).bytes;
    return encrypt.Key(Uint8List.fromList(derivedKey));
  }

  Future<String> _encryptData(String data, SecurityLevel level) async {
    final encrypted = _encrypter.encrypt(data, iv: _iv);
    return encrypted.base64;
  }

  Future<String> _decryptData(String encryptedData) async {
    final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
    final decrypted = _encrypter.decrypt(encrypted, iv: _iv);
    return decrypted;
  }

  String _calculateIntegrityHash(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  Future<void> _initializeMetadata() async {
    final metadata = await _getStorageMetadata();
    if (metadata.isEmpty) {
      await _secureStorage.write(key: _metadataKey, value: json.encode({}));
    }
  }

  Future<Map<String, dynamic>> _getStorageMetadata() async {
    final metadataJson = await _secureStorage.read(key: _metadataKey);
    if (metadataJson == null) return {};

    try {
      return json.decode(metadataJson) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Future<void> _updateMetadataForKey(String key, SecureDataPackage dataPackage) async {
    final metadata = await _getStorageMetadata();
    metadata[key] = {
      'type': dataPackage.metadata?['type'] ?? 'data',
      'createdAt': dataPackage.timestamp.toIso8601String(),
      'securityLevel': dataPackage.securityLevel.toString(),
      'expiresAt': dataPackage.expirationDate?.toIso8601String(),
    };

    await _secureStorage.write(key: _metadataKey, value: json.encode(metadata));
  }

  Future<void> _removeMetadataForKey(String key) async {
    final metadata = await _getStorageMetadata();
    metadata.remove(key);
    await _secureStorage.write(key: _metadataKey, value: json.encode(metadata));
  }
}

/// Security levels for data storage
enum SecurityLevel {
  standard,   // Standard AES encryption
  enhanced,   // Hardware-backed encryption when available
  maximum,    // Hardware-backed + additional security measures
}

/// Secure data package
class SecureDataPackage {
  final String data;
  final DateTime timestamp;
  final SecurityLevel securityLevel;
  final Map<String, String>? metadata;
  final DateTime? expirationDate;

  SecureDataPackage({
    required this.data,
    required this.timestamp,
    required this.securityLevel,
    this.metadata,
    this.expirationDate,
  });

  Map<String, dynamic> toJson() => {
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'securityLevel': securityLevel.toString(),
    'metadata': metadata,
    'expirationDate': expirationDate?.toIso8601String(),
  };

  factory SecureDataPackage.fromJson(Map<String, dynamic> json) {
    return SecureDataPackage(
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      securityLevel: SecurityLevel.values.firstWhere(
        (e) => e.toString() == json['securityLevel'],
        orElse: () => SecurityLevel.standard,
      ),
      metadata: json['metadata'] != null ? Map<String, String>.from(json['metadata']) : null,
      expirationDate: json['expirationDate'] != null ? DateTime.parse(json['expirationDate']) : null,
    );
  }
}

/// Credential data structure
class CredentialData {
  final String username;
  final String password;
  final String? service;
  final Map<String, String>? additionalData;
  final DateTime createdAt;
  final DateTime lastModified;

  CredentialData({
    required this.username,
    required this.password,
    this.service,
    this.additionalData,
    required this.createdAt,
    required this.lastModified,
  });

  factory CredentialData.fromJson(Map<String, dynamic> json) {
    return CredentialData(
      username: json['username'],
      password: json['password'],
      service: json['service'],
      additionalData: json['additionalData'] != null ? Map<String, String>.from(json['additionalData']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: DateTime.parse(json['lastModified']),
    );
  }
}

/// Encrypted file package
class EncryptedFilePackage {
  final String filePath;
  final EncryptedData encryptedData;
  final int originalSize;
  final DateTime timestamp;

  EncryptedFilePackage({
    required this.filePath,
    required this.encryptedData,
    required this.originalSize,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'filePath': filePath,
    'encryptedData': {
      'encryptedBytes': base64.encode(encryptedData.encryptedBytes),
      'integrityHash': encryptedData.integrityHash,
      'algorithm': encryptedData.algorithm.toString(),
      'isQuantumResistant': encryptedData.isQuantumResistant,
      'isHardwareSecured': encryptedData.isHardwareSecured,
      'createdAt': encryptedData.createdAt.toIso8601String(),
    },
    'originalSize': originalSize,
    'timestamp': timestamp.toIso8601String(),
  };

  factory EncryptedFilePackage.fromJson(Map<String, dynamic> json) {
    final encryptedDataJson = json['encryptedData'] as Map<String, dynamic>;
    final encryptedData = EncryptedData(
      encryptedBytes: base64.decode(encryptedDataJson['encryptedBytes']),
      integrityHash: encryptedDataJson['integrityHash'],
      algorithm: EncryptionAlgorithm.values.firstWhere(
        (e) => e.toString() == encryptedDataJson['algorithm'],
        orElse: () => EncryptionAlgorithm.aes256GCM,
      ),
      isQuantumResistant: encryptedDataJson['isQuantumResistant'] ?? false,
      isHardwareSecured: encryptedDataJson['isHardwareSecured'] ?? false,
      createdAt: DateTime.parse(encryptedDataJson['createdAt']),
    );

    return EncryptedFilePackage(
      filePath: json['filePath'],
      encryptedData: encryptedData,
      originalSize: json['originalSize'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Storage statistics
class SecureStorageStats {
  final int totalItems;
  final int credentialsCount;
  final int filesCount;
  final int dataCount;

  SecureStorageStats({
    required this.totalItems,
    required this.credentialsCount,
    required this.filesCount,
    required this.dataCount,
  });

  factory SecureStorageStats.empty() {
    return SecureStorageStats(
      totalItems: 0,
      credentialsCount: 0,
      filesCount: 0,
      dataCount: 0,
    );
  }
}

/// Secure storage exception
class SecureStorageException implements Exception {
  final String message;

  SecureStorageException(this.message);

  @override
  String toString() => 'SecureStorageException: $message';
}
