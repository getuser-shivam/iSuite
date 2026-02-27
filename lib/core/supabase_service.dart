import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'logging_service.dart';
import 'central_config.dart';

/// Organized Supabase Service for iSuite
/// Consolidated and properly organized Supabase integration
/// Provides clean, modular access to all Supabase features with proper error handling
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final LoggingService _logger = LoggingService();
  final CentralConfig _config = CentralConfig.instance;

  // Core Supabase client
  SupabaseClient? _client;
  bool _isInitialized = false;
  bool _isConnected = false;
  String? _connectionError;

  // Connection monitoring
  final StreamController<SupabaseConnectionState> _connectionStateController =
      StreamController<SupabaseConnectionState>.broadcast();
  Timer? _connectionCheckTimer;

  // Event streams
  final StreamController<SupabaseEvent> _eventController =
      StreamController<SupabaseEvent>.broadcast();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;
  String? get connectionError => _connectionError;
  SupabaseClient? get client => _client;
  Stream<SupabaseConnectionState> get connectionState => _connectionStateController.stream;
  Stream<SupabaseEvent> get events => _eventController.stream;

  /// Initialize organized Supabase service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing organized Supabase service', 'SupabaseService');

      // Get configuration from CentralConfig
      final url = _config.getParameter('supabase.url', defaultValue: '');
      final anonKey = _config.getParameter('supabase.anon_key', defaultValue: '');

      if (url.isEmpty || anonKey.isEmpty) {
        throw Exception('Supabase URL and Anon Key must be configured in CentralConfig');
      }

      // Initialize Supabase with proper configuration
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        authOptions: FlutterAuthClientOptions(
          autoRefreshToken: _config.getParameter('supabase.auth.auto_refresh_token', defaultValue: true),
          pkceAsyncStorage: _config.getParameter('supabase.auth.persist_session', defaultValue: true),
        ),
        realtimeClientOptions: RealtimeClientOptions(
          params: {
            'eventsPerSecond': _config.getParameter('supabase.realtime.events_per_second', defaultValue: 10),
          },
        ),
      );

      _client = Supabase.instance.client;

      // Register with CentralConfig
      await _config.registerComponent(
        'SupabaseService',
        '2.0.0',
        'Consolidated and organized Supabase integration with proper error handling and monitoring',
        dependencies: ['CentralConfig', 'LoggingService'],
        parameters: {
          // Connection settings
          'supabase.url': url,
          'supabase.anon_key': anonKey,
          'supabase.connection_timeout': _config.getParameter('supabase.connection_timeout', defaultValue: 30),

          // Authentication
          'supabase.auth.auto_refresh_token': true,
          'supabase.auth.persist_session': true,

          // Database
          'supabase.db.max_rows_per_page': _config.getParameter('supabase.db.max_rows_per_page', defaultValue: 1000),
          'supabase.db.query_timeout_seconds': _config.getParameter('supabase.db.query_timeout_seconds', defaultValue: 60),

          // File storage
          'supabase.storage.bucket_name': _config.getParameter('supabase.storage.bucket_name', defaultValue: 'user-files'),
          'supabase.storage.upload_timeout_minutes': _config.getParameter('supabase.storage.upload_timeout_minutes', defaultValue: 10),

          // Real-time
          'supabase.realtime.enabled': _config.getParameter('supabase.realtime.enabled', defaultValue: true),
          'supabase.realtime.events_per_second': 10,

          // Monitoring
          'supabase.monitoring.enabled': _config.getParameter('supabase.monitoring.enabled', defaultValue: true),
          'supabase.monitoring.connection_check_interval_seconds': _config.getParameter('supabase.monitoring.connection_check_interval_seconds', defaultValue: 60),
        }
      );

      _isInitialized = true;

      // Test connection and setup monitoring
      await _testConnection();
      _setupConnectionMonitoring();

      _emitConnectionState(SupabaseConnectionState.connected);
      _logger.info('Supabase service initialized and organized successfully', 'SupabaseService');

    } catch (e, stackTrace) {
      _connectionError = e.toString();
      _isConnected = false;
      _emitConnectionState(SupabaseConnectionState.error, error: e.toString());

      _logger.error('Failed to initialize organized Supabase service', 'SupabaseService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Test connection
  Future<bool> testConnection() async {
    try {
      return await _testConnection();
    } catch (e) {
      _isConnected = false;
      _connectionError = e.toString();
      _emitConnectionState(SupabaseConnectionState.error, error: e.toString());
      _logger.error('Supabase connection test failed', 'SupabaseService', error: e);
      return false;
    }
  }

  /// Get current user
  Future<SupabaseUser?> getCurrentUser() async {
    if (!_isInitialized) {
      _logger.warning('Supabase not initialized', 'SupabaseService');
      return null;
    }

    try {
      final user = _client?.auth.currentUser;
      _logger.info('Retrieved current user: ${user?.id}', 'SupabaseService');
      return user;
    } catch (e) {
      _logger.error('Failed to get current user', 'SupabaseService', error: e);
      return null;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    if (!_isInitialized) {
      return AuthResponse.error('Supabase not initialized');
    }

    try {
      _logger.info('Signing in with email: $email', 'SupabaseService');
      final response = await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _emitEvent(SupabaseEvent.authSuccess, data: {'user': response.user?.id});
      return AuthResponse.success(response.user);
    } catch (e) {
      _logger.error('Sign in failed for: $email', 'SupabaseService', error: e);
      _emitEvent(SupabaseEvent.authFailed, data: {'error': e.toString()});
      return AuthResponse.error(e.toString());
    }
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail(String email, String password, {String? name}) async {
    if (!_isInitialized) {
      return AuthResponse.error('Supabase not initialized');
    }

    try {
      _logger.info('Signing up with email: $email', 'SupabaseService');
      final response = await _client!.auth.signUp(
        email: email,
        password: password,
        data: name != null ? {'name': name} : null,
      );

      _emitEvent(SupabaseEvent.authSuccess, data: {'user': response.user?.id});
      return AuthResponse.success(response.user);
    } catch (e) {
      _logger.error('Sign up failed for: $email', 'SupabaseService', error: e);
      _emitEvent(SupabaseEvent.authFailed, data: {'error': e.toString()});
      return AuthResponse.error(e.toString());
    }
  }

  /// Sign out
  Future<void> signOut() async {
    if (!_isInitialized) {
      _logger.warning('Supabase not initialized', 'SupabaseService');
      return;
    }

    try {
      _logger.info('Signing out', 'SupabaseService');
      await _client!.auth.signOut();
      _emitEvent(SupabaseEvent.authSignOut);
      _logger.info('Sign out successful', 'SupabaseService');
    } catch (e) {
      _logger.error('Sign out failed', 'SupabaseService', error: e);
      rethrow;
    }
  }

  /// Reset password
  Future<AuthResponse> resetPassword(String email) async {
    if (!_isInitialized) {
      return AuthResponse.error('Supabase not initialized');
    }

    try {
      _logger.info('Resetting password for: $email', 'SupabaseService');
      await _client!.auth.resetPasswordForEmail(email);
      return AuthResponse.success(null);
    } catch (e) {
      _logger.error('Password reset failed for: $email', 'SupabaseService', error: e);
      return AuthResponse.error(e.toString());
    }
  }

  /// Create user profile
  Future<void> _createUserProfile(String userId, {String? name}) async {
    try {
      _logger.info('Creating user profile for: $userId', 'SupabaseService');

      final profileData = {
        'id': userId,
        'name': name ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'preferences': {},
        'metadata': {},
      };

      await _client!.from('user_profiles').insert(profileData);
      _logger.info('User profile created successfully', 'SupabaseService');
    } catch (e) {
      _logger.error('Failed to create user profile', 'SupabaseService', error: e);
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    if (!_isInitialized) {
      return null;
    }

    try {
      _logger.info('Getting user profile for: $userId', 'SupabaseService');

      final response = await _client!.from('user_profiles').select().eq('id', userId).single();
      return response;
    } catch (e) {
      _logger.error('Failed to get user profile', 'SupabaseService', error: e);
      return null;
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> data) async {
    if (!_isInitialized) {
      return false;
    }

    try {
      _logger.info('Updating user profile for: $userId', 'SupabaseService');

      final updateData = {
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client!.from('user_profiles').update(updateData).eq('id', userId);
      return true;
    } catch (e) {
      _logger.error('Failed to update user profile', 'SupabaseService', error: e);
      return false;
    }
  }

  /// Upload file
  Future<String?> uploadFile(String bucket, String filePath, Uint8List fileBytes) async {
    if (!_isInitialized) {
      return null;
    }

    try {
      _logger.info('Uploading file to bucket: $bucket', 'SupabaseService');

      final fileName = filePath.split('/').last;
      final storageResponse = await _client!.storage.from(bucket).uploadBinary(
        fileName,
        fileBytes,
        fileOptions: FileOptions(
          contentType: _getContentType(fileName),
        ),
      );

      final publicUrl = _client!.storage.from(bucket).getPublicUrl(fileName);
      _emitEvent(SupabaseEvent.storageUploadSuccess, data: {'bucket': bucket, 'file': fileName});

      return publicUrl;
    } catch (e) {
      _logger.error('File upload failed', 'SupabaseService', error: e);
      _emitEvent(SupabaseEvent.storageUploadFailed, data: {'error': e.toString()});
      return null;
    }
  }

  /// Delete file
  Future<bool> deleteFile(String bucket, String filePath) async {
    if (!_isInitialized) {
      return false;
    }

    try {
      _logger.info('Deleting file from bucket: $bucket', 'SupabaseService');

      await _client!.storage.from(bucket).remove([filePath]);
      _emitEvent(SupabaseEvent.storageDeleteSuccess, data: {'bucket': bucket, 'file': filePath});

      return true;
    } catch (e) {
      _logger.error('File deletion failed', 'SupabaseService', error: e);
      _emitEvent(SupabaseEvent.storageDeleteFailed, data: {'error': e.toString()});
      return false;
    }
  }

  /// Query database
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
  }) async {
    if (!_isInitialized) {
      return [];
    }

    try {
      _logger.info('Querying table: $table', 'SupabaseService');

      var query = _client!.from(table).select(select ?? '*');

      // Apply filters
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      // Apply limits
      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 1000) - 1);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.error('Query failed for table: $table', 'SupabaseService', error: e);
      return [];
    }
  }

  /// Insert data
  Future<Map<String, dynamic>?> insert(String table, Map<String, dynamic> data) async {
    if (!_isInitialized) {
      return null;
    }

    try {
      _logger.info('Inserting into table: $table', 'SupabaseService');

      final response = await _client!.from(table).insert(data).select().single();
      _emitEvent(SupabaseEvent.databaseInsertSuccess, data: {'table': table});

      return response;
    } catch (e) {
      _logger.error('Insert failed for table: $table', 'SupabaseService', error: e);
      _emitEvent(SupabaseEvent.databaseInsertFailed, data: {'table': table, 'error': e.toString()});
      return null;
    }
  }

  /// Update data
  Future<bool> update(String table, Map<String, dynamic> data, Map<String, dynamic> filters) async {
    if (!_isInitialized) {
      return false;
    }

    try {
      _logger.info('Updating table: $table', 'SupabaseService');

      var query = _client!.from(table).update(data);

      // Apply filters
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      await query;
      _emitEvent(SupabaseEvent.databaseUpdateSuccess, data: {'table': table});

      return true;
    } catch (e) {
      _logger.error('Update failed for table: $table', 'SupabaseService', error: e);
      _emitEvent(SupabaseEvent.databaseUpdateFailed, data: {'table': table, 'error': e.toString()});
      return false;
    }
  }

  /// Delete data
  Future<bool> delete(String table, Map<String, dynamic> filters) async {
    if (!_isInitialized) {
      return false;
    }

    try {
      _logger.info('Deleting from table: $table', 'SupabaseService');

      var query = _client!.from(table).delete();

      // Apply filters
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      await query;
      _emitEvent(SupabaseEvent.databaseDeleteSuccess, data: {'table': table});

      return true;
    } catch (e) {
      _logger.error('Delete failed for table: $table', 'SupabaseService', error: e);
      _emitEvent(SupabaseEvent.databaseDeleteFailed, data: {'table': table, 'error': e.toString()});
      return false;
    }
  }

  /// Private helper methods

  Future<void> _testConnection() async {
    try {
      // Simple connection test
      await _client!.from('user_profiles').select('count').limit(1);
      _isConnected = true;
      _logger.info('Connection test passed', 'SupabaseService');
    } catch (e) {
      _isConnected = false;
      _logger.error('Connection test failed', 'SupabaseService', error: e);
      _connectionError = e.toString();
      _emitConnectionState(SupabaseConnectionState.error, error: e.toString());
    }
  }

  void _setupConnectionMonitoring() {
    final interval = _config.getParameter('supabase.monitoring.connection_check_interval_seconds', defaultValue: 60);

    _connectionCheckTimer = Timer.periodic(Duration(seconds: interval), (_) async {
      await _testConnection();
    });

    _logger.info('Connection monitoring started', 'SupabaseService');
  }

  void _emitConnectionState(SupabaseConnectionState state, {String? error}) {
    final event = SupabaseConnectionEvent(
      state: state,
      timestamp: DateTime.now(),
      error: error,
    );
    _connectionStateController.add(event);
  }

  void _emitEvent(SupabaseEvent event, {Map<String, dynamic>? data}) {
    final fullEvent = SupabaseEventData(
      type: event,
      timestamp: DateTime.now(),
      data: data,
    );
    _eventController.add(fullEvent);
  }

  String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'json':
        return 'application/json';
      default:
        return 'application/octet-stream';
    }
  }

  /// Dispose resources
  void dispose() {
    _connectionStateController.close();
    _eventController.close();
    _connectionCheckTimer?.cancel();
    _logger.info('Supabase service disposed', 'SupabaseService');
  }
}

// Supporting classes

enum SupabaseConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

class SupabaseConnectionEvent {
  final SupabaseConnectionState state;
  final DateTime timestamp;
  final String? error;

  SupabaseConnectionEvent({
    required this.state,
    required this.timestamp,
    this.error,
  });
}

enum SupabaseEvent {
  authSuccess,
  authFailed,
  authSignOut,
  databaseInsertSuccess,
  databaseInsertFailed,
  databaseUpdateSuccess,
  databaseUpdateFailed,
  databaseDeleteSuccess,
  databaseDeleteFailed,
  storageUploadSuccess,
  storageUploadFailed,
  storageDeleteSuccess,
  storageDeleteFailed,
}

class SupabaseEventData {
  final SupabaseEvent type;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  SupabaseEventData({
    required this.type,
    required this.timestamp,
    this.data,
  });
}

class AuthResponse {
  final bool success;
  final SupabaseUser? user;
  final String? error;

  AuthResponse.success(this.user) : success = true, error = null;
  AuthResponse.error(this.error) : success = false, user = null;
}
