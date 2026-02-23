import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'logging_service.dart';
import 'central_config.dart';

/// Enhanced Supabase Service for iSuite
/// Provides comprehensive Supabase integration with proper organization, error handling, and CentralConfig integration
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final LoggingService _logger = LoggingService();
  final CentralConfig _config = CentralConfig.instance;

  // Supabase client and state
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

  Stream<SupabaseConnectionState> get connectionState => _connectionStateController.stream;
  Stream<SupabaseEvent> get events => _eventController.stream;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;
  String? get connectionError => _connectionError;
  SupabaseClient? get client => _client;

  /// Initialize Supabase service with proper organization
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing organized Supabase service', 'SupabaseService');

      // Register with CentralConfig with comprehensive parameters
      await _config.registerComponent(
        'SupabaseService',
        '2.0.0',
        'Enterprise Supabase integration with advanced configuration and monitoring',
        dependencies: ['CentralConfig', 'LoggingService', 'EnhancedSecurityService'],
        parameters: {
          // Connection settings
          'supabase.url': '',
          'supabase.anon_key': '',
          'supabase.service_key': '',
          'supabase.database_url': '',
          'supabase.enable_realtime': true,
          'supabase.connection_timeout': 30000,
          'supabase.request_timeout': 60000,
          'supabase.max_connections': 10,
          'supabase.connection_pool_size': 5,

          // Authentication settings
          'supabase.auth.auto_refresh': true,
          'supabase.auth.refresh_threshold': 300,
          'supabase.auth.persist_session': true,
          'supabase.auth.detect_session_in_url': true,
          'supabase.auth.flow_type': 'pkce',

          // Database settings
          'supabase.db.user_profiles_table': SupabaseTables.userProfiles,
          'supabase.db.users_table': SupabaseTables.users,
          'supabase.db.schema': 'public',
          'supabase.db.max_rows': 1000,
          'supabase.db.default_page_size': 100,
          'supabase.db.enable_pagination': true,

          // File storage settings
          'supabase.storage.enable_upload': true,
          'supabase.storage.max_file_size': 100 * 1024 * 1024, // 100MB
          'supabase.storage.allowed_types': ['image/*', 'application/pdf', 'text/*'],
          'supabase.storage.bucket_name': 'user-files',
          'supabase.storage.cache_enabled': true,
          'supabase.storage.cache_ttl': 3600,

          // Real-time settings
          'supabase.realtime.enabled': true,
          'supabase.realtime.auto_reconnect': true,
          'supabase.realtime.max_reconnect_attempts': 5,
          'supabase.realtime.reconnect_delay': 1000,

          // Security settings
          'supabase.security.enable_rls': true,
          'supabase.security.enable_ssl': true,
          'supabase.security.validate_certificates': true,

          // Monitoring and logging
          'supabase.monitoring.enabled': true,
          'supabase.monitoring.log_queries': false,
          'supabase.monitoring.log_errors': true,
          'supabase.monitoring.performance_tracking': true,

          // Caching settings
          'supabase.cache.enabled': true,
          'supabase.cache.ttl': 300,
          'supabase.cache.max_size': 50,

          // Retry and error handling
          'supabase.retry.enabled': true,
          'supabase.retry.max_attempts': 3,
          'supabase.retry.delay': 1000,
          'supabase.retry.backoff_multiplier': 2.0,

          // Feature toggles
          'supabase.features.auth': true,
          'supabase.features.database': true,
          'supabase.features.storage': true,
          'supabase.features.realtime': true,
          'supabase.features.functions': true,
        }
      );

      // Register component relationships
      await _config.registerComponentRelationship(
        'SupabaseService',
        'CentralConfig',
        RelationshipType.depends_on,
        'Uses CentralConfig for parameter management',
      );

      // Get Supabase configuration from CentralConfig
      final supabaseUrl = _config.getParameter('supabase.url', defaultValue: '');
      final supabaseAnonKey = _config.getParameter('supabase.anon_key', defaultValue: '');
      final connectionTimeout = _config.getParameter('supabase.connection_timeout', defaultValue: 30000);

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw SupabaseException('Supabase URL and Anon Key must be configured in CentralConfig');
      }

      // Initialize Supabase with organized configuration
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        headers: _buildOrganizedHeaders(),
        httpClient: _buildConfiguredHttpClient(),
      );

      _client = Supabase.instance.client;
      _isInitialized = true;

      // Test connection and setup monitoring
      await _testConnection();
      _setupConnectionMonitoring();
      _setupRealtimeSubscriptions();

      _emitConnectionState(SupabaseConnectionState.connected);
      _logger.info('Supabase service initialized successfully with proper organization', 'SupabaseService');

    } catch (e, stackTrace) {
      _connectionError = e.toString();
      _isConnected = false;
      _emitConnectionState(SupabaseConnectionState.error, error: e.toString());

      _logger.error('Failed to initialize organized Supabase service', 'SupabaseService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Test Supabase connection with proper error handling
  Future<bool> testConnection() async {
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
    if (!_isInitialized || _client == null) {
      _logger.warning('Supabase not initialized', 'SupabaseService');
      return null;
    }

    try {
      final user = _client.auth.currentUser;
      _logger.info('Retrieved current user: ${user?.id}', 'SupabaseService');
      return user;
    } catch (e) {
      _logger.error('Failed to get current user', 'SupabaseService', error: e);
      return null;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    if (!_isInitialized || _client == null) {
      return AuthResponse.error('Supabase not initialized');
    }

    try {
      _logger.info('Signing in with email: $email', 'SupabaseService');

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _logger.info('Sign in successful: ${response.user!.id}', 'SupabaseService');
        return AuthResponse.success(response.user!);
      } else {
        final error = response.error?.message ?? 'Unknown error';
        _logger.error('Sign in failed: $error', 'SupabaseService');
        return AuthResponse.error(error);
      }
    } catch (e) {
      _logger.error('Sign in exception', 'SupabaseService', error: e);
      return AuthResponse.error(e.toString());
    }
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail(String email, String password, {String? name}) async {
    if (!_isInitialized || _client == null) {
      return AuthResponse.error('Supabase not initialized');
    }

    try {
      _logger.info('Signing up with email: $email', 'SupabaseService');

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: name != null ? {'name': name} : null,
      );

      if (response.user != null) {
        _logger.info('Sign up successful: ${response.user!.id}', 'SupabaseService');
        
        // Create user profile
        await _createUserProfile(response.user!.id, name: name);
        
        return AuthResponse.success(response.user!);
      } else {
        final error = response.error?.message ?? 'Unknown error';
        _logger.error('Sign up failed: $error', 'SupabaseService');
        return AuthResponse.error(error);
      }
    } catch (e) {
      _logger.error('Sign up exception', 'SupabaseService', error: e);
      return AuthResponse.error(e.toString());
    }
  }

  /// Sign out
  Future<void> signOut() async {
    if (!_isInitialized || _client == null) {
      _logger.warning('Supabase not initialized', 'SupabaseService');
      return;
    }

    try {
      _logger.info('Signing out', 'SupabaseService');
      await _client.auth.signOut();
      _logger.info('Sign out successful', 'SupabaseService');
    } catch (e) {
      _logger.error('Sign out failed', 'SupabaseService', error: e);
    }
  }

  /// Reset password
  Future<AuthResponse> resetPassword(String email) async {
    if (!_isInitialized || _client == null) {
      return AuthResponse.error('Supabase not initialized');
    }

    try {
      _logger.info('Resetting password for: $email', 'SupabaseService');

      final response = await _client.auth.resetPasswordForEmail(
        email: email,
      );

      if (response.error == null) {
        _logger.info('Password reset email sent', 'SupabaseService');
        return AuthResponse.success(null);
      } else {
        final error = response.error?.message ?? 'Unknown error';
        _logger.error('Password reset failed: $error', 'SupabaseService');
        return AuthResponse.error(error);
      }
    } catch (e) {
      _logger.error('Password reset exception', 'SupabaseService', error: e);
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

      await _client.from(_config.getParameter('supabase.db.user_profiles_table', defaultValue: SupabaseTables.userProfiles)).insert(profileData);
      _logger.info('User profile created successfully', 'SupabaseService');
    } catch (e) {
      _logger.error('Failed to create user profile', 'SupabaseService', error: e);
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    if (!_isInitialized || _client == null) {
      return null;
    }

    try {
      _logger.info('Getting user profile for: $userId', 'SupabaseService');

      final response = await _client
          .from(_config.getParameter('supabase.db.user_profiles_table', defaultValue: SupabaseTables.userProfiles))
          .select()
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      _logger.error('Failed to get user profile', 'SupabaseService', error: e);
      return null;
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> data) async {
    if (!_isInitialized || _client == null) {
      return false;
    }

    try {
      _logger.info('Updating user profile for: $userId', 'SupabaseService');

      final updateData = {
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from(_config.getParameter('supabase.db.user_profiles_table', defaultValue: SupabaseTables.userProfiles))
          .update(updateData)
          .eq('id', userId);

      _logger.info('User profile updated successfully', 'SupabaseService');
      return true;
    } catch (e) {
      _logger.error('Failed to update user profile', 'SupabaseService', error: e);
      return false;
    }
  }

  /// Upload file to storage
  Future<String?> uploadFile(String bucket, String filePath, Uint8List fileBytes) async {
    if (!_isInitialized || _client == null) {
      return null;
    }

    try {
      _logger.info('Uploading file to bucket: $bucket', 'SupabaseService');

      final response = await _client.storage
          .from(bucket)
          .upload(filePath, fileBytes);

      if (response.error == null) {
        final publicUrl = _client.storage
            .from(bucket)
            .getPublicUrl(filePath);
        
        _logger.info('File uploaded successfully: $filePath', 'SupabaseService');
        return publicUrl;
      } else {
        _logger.error('File upload failed: ${response.error?.message}', 'SupabaseService');
        return null;
      }
    } catch (e) {
      _logger.error('File upload exception', 'SupabaseService', error: e);
      return null;
    }
  }

  /// Delete file from storage
  Future<bool> deleteFile(String bucket, String filePath) async {
    if (!_isInitialized || _client == null) {
      return false;
    }

    try {
      _logger.info('Deleting file from bucket: $bucket', 'SupabaseService');

      final response = await _client.storage
          .from(bucket)
          .remove([filePath]);

      if (response.error == null) {
        _logger.info('File deleted successfully: $filePath', 'SupabaseService');
        return true;
      } else {
        _logger.error('File deletion failed: ${response.error?.message}', 'SupabaseService');
        return false;
      }
    } catch (e) {
      _logger.error('File deletion exception', 'SupabaseService', error: e);
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
      _logger.info('Querying table: $table', 'SupabaseService');

      var query = _client.from(table);

      if (select != null) {
        query = query.select(select);
      }

      if (where != null) {
        query = query.filter(where);
      }

      if (orderBy != null) {
        for (final order in orderBy!) {
          query = query.order(order);
        }
      }

      if (limit != null) {
        query = query.limit(limit!);
      }

      if (offset != null) {
        query = query.offset(offset!);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.error('Query failed for table: $table', 'SupabaseService', error: e);
      return [];
    }
  }

  /// Insert data into table
  Future<Map<String, dynamic>?> insert(String table, Map<String, dynamic> data) async {
    if (!_isInitialized || _client == null) {
      return null;
    }

    try {
      _logger.info('Inserting into table: $table', 'SupabaseService');

      final response = await _client.from(table).insert(data);
      return response;
    } catch (e) {
      _logger.error('Insert failed for table: $table', 'SupabaseService', error: e);
      return null;
    }
  }

  /// Update data in table
  Future<bool> update(String table, Map<String, dynamic> data, String where) async {
    if (!_isInitialized || _client == null) {
      return false;
    }

    try {
      _logger.info('Updating table: $table', 'SupabaseService');

      await _client.from(table).update(data).filter(where);
      return true;
    } catch (e) {
      _logger.error('Update failed for table: $table', 'SupabaseService', error: e);
      return false;
    }
  }

  /// Delete data from table
  Future<bool> delete(String table, String where) async {
    if (!_isInitialized || _client == null) {
      return false;
    }

    try {
      _logger.info('Deleting from table: $table', 'SupabaseService');

      await _client.from(table).delete().filter(where);
      return true;
    } catch (e) {
      _logger.error('Delete failed for table: $table', 'SupabaseService', error: e);
      return false;
    }
  }

  /// Private helper methods

  Future<void> _testConnection() async {
    try {
      await _client!.from(_config.getParameter('supabase.db.users_table', defaultValue: SupabaseTables.users)).select('count').limit(1);
      _logger.info('Connection test passed', 'SupabaseService');
    } catch (e) {
      _logger.error('Connection test failed', 'SupabaseService', error: e);
      _isConnected = false;
      _connectionError = e.toString();
      _emitConnectionState(SupabaseConnectionState.error, error: e.toString());
    }
  }

  Map<String, String> _buildHeaders() {
    return {
      'apikey': _config.getParameter('supabase.anon_key', defaultValue: ''),
      'Authorization': 'Bearer ${_config.getParameter('supabase.anon_key', defaultValue: '')}',
      'Content-Type': 'application/json',
      'X-Client-Info': 'isuite-app',
      'X-Client-Version': '2.0.0',
      'X-Client-Name': 'iSuite',
      'X-Client-Platform': 'flutter',
      'X-Client-Environment': kDebugMode ? 'development' : 'production',
      'X-Client-User-Agent': 'isuite-app/2.0.0',
    };
  }

  void _emitConnectionState(SupabaseConnectionState state, {String? error}) {
    final event = SupabaseConnectionEvent(
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

class AuthResponse {
  final bool success;
  final SupabaseUser? user;
  final String? error;

  AuthResponse.success(this.user) : success = true, error = null;
  AuthResponse.error(this.error) : success = false, user = null;
}
