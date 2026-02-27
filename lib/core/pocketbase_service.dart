import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:pocketbase_server_flutter/pocketbase_server_flutter.dart';
import 'logging_service.dart';
import 'central_config.dart';

/// Enhanced PocketBase Service for iSuite
/// Completely FREE backend alternative to Supabase with built-in database, auth, and file storage
class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;
  PocketBaseService._internal();

  final LoggingService _logger = LoggingService();
  final CentralConfig _config = CentralConfig.instance;

  // PocketBase client and server
  PocketBase? _client;
  PocketBaseServer? _server;
  bool _isInitialized = false;
  bool _isServerRunning = false;

  // Connection state
  bool _isConnected = false;
  String? _connectionError;
  final StreamController<PocketBaseConnectionState> _connectionStateController =
      StreamController.broadcast();

  Stream<PocketBaseConnectionState> get connectionState => _connectionStateController.stream;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;
  String? get connectionError => _connectionError;
  PocketBase? get client => _client;

  /// Initialize PocketBase service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing PocketBase service', 'PocketBaseService');

      // Get PocketBase configuration
      final pocketbaseUrl = _config.getParameter('pocketbase.url', defaultValue: 'http://127.0.0.1:8090');

      // Initialize PocketBase client
      _client = PocketBase(pocketbaseUrl);

      _isInitialized = true;
      _isConnected = true;

      _emitConnectionState(PocketBaseConnectionState.connected);
      _logger.info('PocketBase service initialized successfully', 'PocketBaseService');

      // Test connection
      await _testConnection();

    } catch (e, stackTrace) {
      _connectionError = e.toString();
      _isConnected = false;
      _emitConnectionState(PocketBaseConnectionState.error, error: e.toString());
      
      _logger.error('Failed to initialize PocketBase service', 'PocketBaseService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Test PocketBase connection
  Future<bool> testConnection() async {
    if (!_isInitialized || _client == null) {
      return false;
    }

    try {
      _logger.info('Testing PocketBase connection', 'PocketBaseService');

      // Test by getting collections (simple health check)
      await _client!.collections.getFullList();

      _isConnected = true;
      _connectionError = null;
      _emitConnectionState(PocketBaseConnectionState.connected);

      _logger.info('PocketBase connection test successful', 'PocketBaseService');
      return true;

    } catch (e) {
      _isConnected = false;
      _connectionError = e.toString();
      _emitConnectionState(PocketBaseConnectionState.error, error: e.toString());

      _logger.error('PocketBase connection test failed', 'PocketBaseService', error: e);
      return false;
    }
  }

  /// Get current user
  Future<RecordModel?> getCurrentUser() async {
    if (!_isInitialized || _client == null) {
      _logger.warning('PocketBase not initialized', 'PocketBaseService');
      return null;
    }

    try {
      final user = _client!.authStore.model;
      _logger.info('Retrieved current user: ${user?.id}', 'PocketBaseService');
      return user;
    } catch (e) {
      _logger.error('Failed to get current user', 'PocketBaseService', error: e);
      return null;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    if (!_isInitialized || _client == null) {
      return AuthResponse.error('PocketBase not initialized');
    }

    try {
      _logger.info('Signing in with email: $email', 'PocketBaseService');

      final record = await _client!.collection('users').authWithPassword(email, password);

      if (record != null) {
        _logger.info('Sign in successful: ${record.id}', 'PocketBaseService');
        return AuthResponse.success(record);
      } else {
        final error = 'Unknown error';
        _logger.error('Sign in failed: $error', 'PocketBaseService');
        return AuthResponse.error(error);
      }
    } catch (e) {
      _logger.error('Sign in exception', 'PocketBaseService', error: e);
      return AuthResponse.error(e.toString());
    }
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail(String email, String password, {String? name}) async {
    if (!_isInitialized || _client == null) {
      return AuthResponse.error('PocketBase not initialized');
    }

    try {
      _logger.info('Signing up with email: $email', 'PocketBaseService');

      final body = {
        'email': email,
        'password': password,
        'passwordConfirm': password,
        if (name != null) 'name': name,
      };

      final record = await _client!.collection('users').create(body: body);

      if (record != null) {
        _logger.info('Sign up successful: ${record.id}', 'PocketBaseService');

        // Automatically sign in after signup
        final authRecord = await _client!.collection('users').authWithPassword(email, password);
        return AuthResponse.success(authRecord);
      } else {
        final error = 'Unknown error';
        _logger.error('Sign up failed: $error', 'PocketBaseService');
        return AuthResponse.error(error);
      }
    } catch (e) {
      _logger.error('Sign up exception', 'PocketBaseService', error: e);
      return AuthResponse.error(e.toString());
    }
  }

  /// Sign out
  Future<void> signOut() async {
    if (!_isInitialized || _client == null) {
      _logger.warning('PocketBase not initialized', 'PocketBaseService');
      return;
    }

    try {
      _logger.info('Signing out', 'PocketBaseService');
      _client!.authStore.clear();
      _logger.info('Sign out successful', 'PocketBaseService');
    } catch (e) {
      _logger.error('Sign out failed', 'PocketBaseService', error: e);
    }
  }

  /// Reset password
  Future<AuthResponse> resetPassword(String email) async {
    if (!_isInitialized || _client == null) {
      return AuthResponse.error('PocketBase not initialized');
    }

    try {
      _logger.info('Resetting password for: $email', 'PocketBaseService');

      await _client!.collection('users').requestPasswordReset(email);

      _logger.info('Password reset email sent', 'PocketBaseService');
      return AuthResponse.success(null);
    } catch (e) {
      _logger.error('Password reset exception', 'PocketBaseService', error: e);
      return AuthResponse.error(e.toString());
    }
  }

  /// Create user profile
  Future<void> _createUserProfile(String userId, {String? name}) async {
    try {
      _logger.info('Creating user profile for: $userId', 'PocketBaseService');

      final profileData = {
        'id': userId,
        'name': name ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'preferences': {},
        'metadata': {},
      };

      await _client!.collection('profiles').create(body: profileData);
      _logger.info('User profile created successfully', 'PocketBaseService');
    } catch (e) {
      _logger.error('Failed to create user profile', 'PocketBaseService', error: e);
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    if (!_isInitialized || _client == null) {
      return null;
    }

    try {
      _logger.info('Getting user profile for: $userId', 'PocketBaseService');

      final record = await _client!.collection('profiles').getFirstListItem('id="$userId"');

      return record.data;
    } catch (e) {
      _logger.error('Failed to get user profile', 'PocketBaseService', error: e);
      return null;
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> data) async {
    if (!_isInitialized || _client == null) {
      return false;
    }

    try {
      _logger.info('Updating user profile for: $userId', 'PocketBaseService');

      final updateData = {
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final record = await _client!.collection('profiles').getFirstListItem('id="$userId"');
      await _client!.collection('profiles').update(record.id, body: updateData);

      _logger.info('User profile updated successfully', 'PocketBaseService');
      return true;
    } catch (e) {
      _logger.error('Failed to update user profile', 'PocketBaseService', error: e);
      return false;
    }
  }

  /// Upload file to storage
  Future<String?> uploadFile(String bucket, String filePath, Uint8List fileBytes) async {
    if (!_isInitialized || _client == null) {
      return null;
    }

    try {
      _logger.info('Uploading file to bucket: $bucket', 'PocketBaseService');

      final result = await _client!.files.upload(fileBytes, filename: filePath);

      _logger.info('File uploaded successfully: $filePath', 'PocketBaseService');
      return result.url;
    } catch (e) {
      _logger.error('File upload exception', 'PocketBaseService', error: e);
      return null;
    }
  }

  /// Delete file from storage
  Future<bool> deleteFile(String bucket, String filePath) async {
    if (!_isInitialized || _client == null) {
      return false;
    }

    try {
      _logger.info('Deleting file from bucket: $bucket', 'PocketBaseService');

      await _client!.files.delete(filePath);

      _logger.info('File deleted successfully: $filePath', 'PocketBaseService');
      return true;
    } catch (e) {
      _logger.error('File deletion exception', 'PocketBaseService', error: e);
      return false;
    }
  }

  /// Execute database query
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? select,
    String? where,
    List<String>? orderBy,
    int? limit,
    int? offset,
  }) async {
    if (!_isInitialized || _client == null) {
      return [];
    }

    try {
      _logger.info('Querying table: $table', 'PocketBaseService');

      final result = await _client!.collection(table).getFullList(
        filter: where,
        sort: orderBy?.join(','),
        fields: select,
        limit: limit,
        offset: offset,
      );

      return result.items.map((e) => e.data).toList();
    } catch (e) {
      _logger.error('Query failed for table: $table', 'PocketBaseService', error: e);
      return [];
    }
  }

  /// Insert data into table
  Future<Map<String, dynamic>?> insert(String table, Map<String, dynamic> data) async {
    if (!_isInitialized || _client == null) {
      return null;
    }

    try {
      _logger.info('Inserting into table: $table', 'PocketBaseService');

      final record = await _client!.collection(table).create(body: data);
      return record.data;
    } catch (e) {
      _logger.error('Insert failed for table: $table', 'PocketBaseService', error: e);
      return null;
    }
  }

  /// Update data in table
  Future<bool> update(String table, Map<String, dynamic> data, String where) async {
    if (!_isInitialized || _client == null) {
      return false;
    }

    try {
      _logger.info('Updating table: $table', 'PocketBaseService');

      final records = await _client!.collection(table).getFullList(filter: where);
      for (final record in records.items) {
        await _client!.collection(table).update(record.id, body: data);
      }
      return true;
    } catch (e) {
      _logger.error('Update failed for table: $table', 'PocketBaseService', error: e);
      return false;
    }
  }

  /// Delete data from table
  Future<bool> delete(String table, String where) async {
    if (!_isInitialized || _client == null) {
      return false;
    }

    try {
      _logger.info('Deleting from table: $table', 'PocketBaseService');

      final records = await _client!.collection(table).getFullList(filter: where);
      for (final record in records.items) {
        await _client!.collection(table).delete(record.id);
      }
      return true;
    } catch (e) {
      _logger.error('Delete failed for table: $table', 'PocketBaseService', error: e);
      return false;
    }
  }

  /// Private helper methods

  Future<void> _testConnection() async {
    try {
      await _client!.collections.getFullList();
      _logger.info('Connection test passed', 'PocketBaseService');
    } catch (e) {
      _logger.error('Connection test failed', 'PocketBaseService', error: e);
      _isConnected = false;
      _connectionError = e.toString();
      _emitConnectionState(PocketBaseConnectionState.error, error: e.toString());
    }
  }

  void _emitConnectionState(PocketBaseConnectionState state, {String? error}) {
    final event = PocketBaseConnectionEvent(
      state: state,
      timestamp: DateTime.now(),
      error: error,
    );
    _connectionStateController.add(event);
  }

  /// Dispose service
  void dispose() {
    _connectionStateController.close();
  }
}

// Supporting classes

enum PocketBaseConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

class PocketBaseConnectionEvent {
  final PocketBaseConnectionState state;
  final DateTime timestamp;
  final String? error;

  PocketBaseConnectionEvent({
    required this.state,
    required this.timestamp,
    this.error,
  });
}

class AuthResponse {
  final bool success;
  final RecordModel? user;
  final String? error;

  AuthResponse.success(this.user) : success = true, error = null;
  AuthResponse.error(this.error) : success = false, user = null;
}
