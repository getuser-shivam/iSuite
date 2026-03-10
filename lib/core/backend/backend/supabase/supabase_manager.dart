import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'config/central_config.dart';
import 'logging_service.dart';
import 'supabase/supabase_auth_service.dart';
import 'supabase/supabase_database_service.dart';
import 'supabase/supabase_storage_service.dart';
import 'supabase/supabase_realtime_service.dart';
import 'supabase/supabase_offline_service.dart';

/// Enhanced Supabase Integration for iSuite
/// Organized into modular services with offline-first capabilities
/// Inspired by open source projects and best practices

/// Core Supabase Manager - Central coordinator for all Supabase services
class SupabaseManager {
  static final SupabaseManager _instance = SupabaseManager._internal();
  factory SupabaseManager() => _instance;

  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();

  // Service instances
  late SupabaseAuthService _authService;
  late SupabaseDatabaseService _databaseService;
  late SupabaseStorageService _storageService;
  late SupabaseRealtimeService _realtimeService;
  late SupabaseOfflineService _offlineService;

  bool _isInitialized = false;
  SupabaseConnectionState _connectionState =
      SupabaseConnectionState.disconnected;

  SupabaseManager._internal() {
    _initializeServices();
  }

  void _initializeServices() {
    _authService = SupabaseAuthService(_config, _logger);
    _databaseService = SupabaseDatabaseService(_config, _logger);
    _storageService = SupabaseStorageService(_config, _logger);
    _realtimeService = SupabaseRealtimeService(_config, _logger);
    _offlineService = SupabaseOfflineService(_config, _logger);
  }

  // Service getters
  SupabaseAuthService get auth => _authService;
  SupabaseDatabaseService get database => _databaseService;
  SupabaseStorageService get storage => _storageService;
  SupabaseRealtimeService get realtime => _realtimeService;
  SupabaseOfflineService get offline => _offlineService;

  /// Initialize all Supabase services with proper organization
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing enhanced Supabase Manager', 'SupabaseManager');

      // Initialize core Supabase client
      await _initializeSupabaseClient();

      // Initialize all services
      await Future.wait([
        _authService.initialize(),
        _databaseService.initialize(),
        _storageService.initialize(),
        _realtimeService.initialize(),
        _offlineService.initialize(),
      ]);

      // Setup cross-service integrations
      await _setupServiceIntegrations();

      // Start monitoring and health checks
      await _startHealthMonitoring();

      _isInitialized = true;
      _connectionState = SupabaseConnectionState.connected;

      _logger.info(
          'Supabase Manager initialized successfully with all services',
          'SupabaseManager');
    } catch (e, stackTrace) {
      _connectionState = SupabaseConnectionState.error;
      _logger.error('Failed to initialize Supabase Manager', 'SupabaseManager',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _initializeSupabaseClient() async {
    // Get configuration from CentralConfig
    final supabaseUrl = await _config.getParameter<String>('supabase.url');
    final supabaseAnonKey =
        await _config.getParameter<String>('supabase.anon_key');

    if (supabaseUrl == null ||
        supabaseUrl.isEmpty ||
        supabaseAnonKey == null ||
        supabaseAnonKey.isEmpty) {
      throw SupabaseException('Supabase URL and Anon Key must be configured');
    }

    // Initialize with enhanced configuration
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      headers: await _buildEnhancedHeaders(),
      httpClient: await _buildEnhancedHttpClient(),
    );
  }

  Future<Map<String, String>> _buildEnhancedHeaders() async {
    final anonKey =
        await _config.getParameter<String>('supabase.anon_key') ?? '';
    final clientVersion =
        await _config.getParameter<String>('app.version') ?? '1.0.0';
    final clientPlatform = Platform.isAndroid
        ? 'android'
        : Platform.isIOS
            ? 'ios'
            : Platform.isWindows
                ? 'windows'
                : 'unknown';

    return {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
      'Content-Type': 'application/json',
      'X-Client-Info': 'iSuite/$clientVersion',
      'X-Client-Platform': clientPlatform,
      'X-Client-Environment': kDebugMode ? 'development' : 'production',
      'X-Client-Timezone': DateTime.now().timeZoneName,
    };
  }

  Future<HttpClient> _buildEnhancedHttpClient() async {
    final client = HttpClient();

    // Connection settings
    final connectionTimeout =
        await _config.getParameter<int>('supabase.connection_timeout') ?? 30;
    client.connectionTimeout = Duration(seconds: connectionTimeout);

    // SSL verification
    final sslVerification =
        await _config.getParameter<bool>('supabase.ssl_verification') ?? true;
    if (!sslVerification) {
      client.badCertificateCallback = (cert, host, port) => true;
    }

    return client;
  }

  Future<void> _setupServiceIntegrations() async {
    // Auth service integration
    _authService.onAuthStateChanged = (user) {
      _databaseService.setCurrentUser(user);
      _storageService.setCurrentUser(user);
      _realtimeService.setCurrentUser(user);
    };

    // Offline service integration
    _offlineService.onConnectivityChanged = (isOnline) {
      if (isOnline) {
        _syncOfflineData();
      }
    };
  }

  Future<void> _startHealthMonitoring() async {
    // Periodic health checks
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _performHealthCheck();
    });

    // Connection monitoring
    final connectivity = Connectivity();
    connectivity.onConnectivityChanged.listen((result) {
      final isOnline = result != ConnectivityResult.none;
      _offlineService.updateConnectivityStatus(isOnline);
    });
  }

  Future<void> _performHealthCheck() async {
    try {
      final healthStatus = await _databaseService.healthCheck();
      if (!healthStatus) {
        _connectionState = SupabaseConnectionState.error;
        _logger.warning('Supabase health check failed', 'SupabaseManager');
      } else {
        _connectionState = SupabaseConnectionState.connected;
      }
    } catch (e) {
      _connectionState = SupabaseConnectionState.error;
      _logger.error('Health check error', 'SupabaseManager', error: e);
    }
  }

  Future<void> _syncOfflineData() async {
    try {
      await _offlineService.syncPendingOperations();
      _logger.info('Offline data sync completed', 'SupabaseManager');
    } catch (e) {
      _logger.error('Offline data sync failed', 'SupabaseManager', error: e);
    }
  }

  /// Get overall system health
  Future<Map<String, dynamic>> getSystemHealth() async {
    final services = await Future.wait([
      _authService.getHealthStatus(),
      _databaseService.getHealthStatus(),
      _storageService.getHealthStatus(),
      _realtimeService.getHealthStatus(),
      _offlineService.getHealthStatus(),
    ]);

    return {
      'overall_status': _connectionState.toString(),
      'services': services,
      'last_check': DateTime.now().toIso8601String(),
    };
  }

  /// Dispose all services
  void dispose() {
    _authService.dispose();
    _databaseService.dispose();
    _storageService.dispose();
    _realtimeService.dispose();
    _offlineService.dispose();
    _logger.info('Supabase Manager disposed', 'SupabaseManager');
  }
}

/// Authentication Service - Handles user authentication and sessions
class SupabaseAuthService {
  final CentralConfig _config;
  final LoggingService _logger;

  SupabaseClient? _client;
  StreamSubscription<AuthState>? _authSubscription;
  Function(User?)? onAuthStateChanged;

  User? _currentUser;
  bool _isInitialized = false;

  SupabaseAuthService(this._config, this._logger);

  Future<void> initialize() async {
    _client = Supabase.instance.client;

    // Setup auth state monitoring
    _authSubscription = _client!.auth.onAuthStateChange.listen((event) {
      _currentUser = event.session?.user;
      onAuthStateChanged?.call(_currentUser);
      _logger.info(
          'Auth state changed: ${_currentUser?.id}', 'SupabaseAuthService');
    });

    _isInitialized = true;
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      final response = await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _createUserProfile(response.user!);
        return AuthResponse.success(response.user!);
      }

      return AuthResponse.error(response.error?.message ?? 'Sign in failed');
    } catch (e) {
      return AuthResponse.error(e.toString());
    }
  }

  Future<AuthResponse> signUpWithEmail(String email, String password,
      {String? name}) async {
    try {
      final response = await _client!.auth.signUp(
        email: email,
        password: password,
        data: name != null ? {'name': name} : null,
      );

      if (response.user != null) {
        await _createUserProfile(response.user!, name: name);
        return AuthResponse.success(response.user!);
      }

      return AuthResponse.error(response.error?.message ?? 'Sign up failed');
    } catch (e) {
      return AuthResponse.error(e.toString());
    }
  }

  Future<void> signOut() async {
    await _client!.auth.signOut();
  }

  Future<Map<String, dynamic>> getHealthStatus() async {
    return {
      'service': 'auth',
      'initialized': _isInitialized,
      'user': _currentUser?.id,
      'session_valid': _client?.auth.currentSession != null,
    };
  }

  Future<void> _createUserProfile(User user, {String? name}) async {
    try {
      final profile = {
        'id': user.id,
        'email': user.email,
        'name': name ?? user.userMetadata?['name'] ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client!.from('user_profiles').upsert(profile);
    } catch (e) {
      _logger.error('Failed to create user profile', 'SupabaseAuthService',
          error: e);
    }
  }

  void dispose() {
    _authSubscription?.cancel();
  }
}

/// Database Service - Handles data operations with caching and offline support
class SupabaseDatabaseService {
  final CentralConfig _config;
  final LoggingService _logger;

  SupabaseClient? _client;
  User? _currentUser;
  final Map<String, List<Map<String, dynamic>>> _cache = {};
  bool _isInitialized = false;

  SupabaseDatabaseService(this._config, this._logger);

  Future<void> initialize() async {
    _client = Supabase.instance.client;
    _isInitialized = true;
  }

  void setCurrentUser(User? user) {
    _currentUser = user;
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool? ascending,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = _client!.from(table);

      if (select != null) query = query.select(select);
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending ?? true);
      }
      if (limit != null) query = query.limit(limit);
      if (offset != null) query = query.offset(offset);

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.error('Database query failed', 'SupabaseDatabaseService',
          error: e);
      return [];
    }
  }

  Future<Map<String, dynamic>?> insert(
      String table, Map<String, dynamic> data) async {
    try {
      final response =
          await _client!.from(table).insert(data).select().single();
      return response;
    } catch (e) {
      _logger.error('Database insert failed', 'SupabaseDatabaseService',
          error: e);
      return null;
    }
  }

  Future<bool> update(String table, Map<String, dynamic> data,
      Map<String, dynamic> filters) async {
    try {
      var query = _client!.from(table);
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      await query.update(data);
      return true;
    } catch (e) {
      _logger.error('Database update failed', 'SupabaseDatabaseService',
          error: e);
      return false;
    }
  }

  Future<bool> delete(String table, Map<String, dynamic> filters) async {
    try {
      var query = _client!.from(table);
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      await query.delete();
      return true;
    } catch (e) {
      _logger.error('Database delete failed', 'SupabaseDatabaseService',
          error: e);
      return false;
    }
  }

  Future<bool> healthCheck() async {
    try {
      await _client!.from('user_profiles').select('count').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getHealthStatus() async {
    final isHealthy = await healthCheck();
    return {
      'service': 'database',
      'initialized': _isInitialized,
      'healthy': isHealthy,
      'user': _currentUser?.id,
      'cache_size': _cache.length,
    };
  }
}

/// Storage Service - Handles file uploads, downloads, and management
class SupabaseStorageService {
  final CentralConfig _config;
  final LoggingService _logger;

  SupabaseClient? _client;
  User? _currentUser;
  bool _isInitialized = false;

  SupabaseStorageService(this._config, this._logger);

  Future<void> initialize() async {
    _client = Supabase.instance.client;
    _isInitialized = true;
  }

  void setCurrentUser(User? user) {
    _currentUser = user;
  }

  Future<String?> uploadFile(
    String bucket,
    String filePath,
    List<int> fileBytes, {
    String? contentType,
    Map<String, String>? metadata,
  }) async {
    try {
      final fileOptions = FileOptions(
        contentType: contentType,
        upsert: true,
      );

      final response = await _client!.storage
          .from(bucket)
          .uploadBinary(filePath, fileBytes, fileOptions: fileOptions);

      if (response.isNotEmpty) {
        final publicUrl = _client!.storage.from(bucket).getPublicUrl(filePath);
        return publicUrl;
      }
      return null;
    } catch (e) {
      _logger.error('File upload failed', 'SupabaseStorageService', error: e);
      return null;
    }
  }

  Future<List<int>?> downloadFile(String bucket, String filePath) async {
    try {
      final response = await _client!.storage.from(bucket).download(filePath);
      return response;
    } catch (e) {
      _logger.error('File download failed', 'SupabaseStorageService', error: e);
      return null;
    }
  }

  Future<bool> deleteFile(String bucket, String filePath) async {
    try {
      await _client!.storage.from(bucket).remove([filePath]);
      return true;
    } catch (e) {
      _logger.error('File deletion failed', 'SupabaseStorageService', error: e);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> listFiles(String bucket,
      {String? path}) async {
    try {
      final response = await _client!.storage.from(bucket).list(path: path);
      return response.map((file) => file.toJson()).toList();
    } catch (e) {
      _logger.error('File listing failed', 'SupabaseStorageService', error: e);
      return [];
    }
  }

  Future<Map<String, dynamic>> getHealthStatus() async {
    return {
      'service': 'storage',
      'initialized': _isInitialized,
      'user': _currentUser?.id,
    };
  }
}

/// Real-time Service - Handles real-time subscriptions and live updates
class SupabaseRealtimeService {
  final CentralConfig _config;
  final LoggingService _logger;

  SupabaseClient? _client;
  User? _currentUser;
  final Map<String, RealtimeChannel> _channels = {};
  bool _isInitialized = false;

  SupabaseRealtimeService(this._config, this._logger);

  Future<void> initialize() async {
    _client = Supabase.instance.client;
    _isInitialized = true;
  }

  void setCurrentUser(User? user) {
    _currentUser = user;
  }

  Future<RealtimeChannel> subscribeToTable(
    String table,
    Function(Map<String, dynamic>) onUpdate, {
    String? filter,
  }) async {
    final channelName = 'table_$table${filter != null ? '_$filter' : ''}';

    if (_channels.containsKey(channelName)) {
      return _channels[channelName]!;
    }

    final channel = _client!
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: filter != null
              ? PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'user_id',
                  value: _currentUser?.id)
              : null,
          callback: (payload) {
            onUpdate(payload.newRecord ?? {});
          },
        )
        .subscribe();

    _channels[channelName] = channel;
    return channel;
  }

  Future<void> unsubscribeFromTable(String table, {String? filter}) async {
    final channelName = 'table_$table${filter != null ? '_$filter' : ''}';

    if (_channels.containsKey(channelName)) {
      await _channels[channelName]!.unsubscribe();
      _channels.remove(channelName);
    }
  }

  Future<Map<String, dynamic>> getHealthStatus() async {
    return {
      'service': 'realtime',
      'initialized': _isInitialized,
      'active_channels': _channels.length,
      'user': _currentUser?.id,
    };
  }
}

/// Offline Service - Handles offline data storage and synchronization
class SupabaseOfflineService {
  final CentralConfig _config;
  final LoggingService _logger;

  bool _isOnline = true;
  final List<Map<String, dynamic>> _pendingOperations = [];
  Function(bool)? onConnectivityChanged;
  bool _isInitialized = false;

  SupabaseOfflineService(this._config, this._logger);

  Future<void> initialize() async {
    _isInitialized = true;
    // Initialize local storage for offline data
  }

  void updateConnectivityStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      onConnectivityChanged?.call(isOnline);

      if (isOnline) {
        syncPendingOperations();
      }
    }
  }

  Future<void> queueOperation(Map<String, dynamic> operation) async {
    _pendingOperations.add({
      ...operation,
      'timestamp': DateTime.now().toIso8601String(),
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    // Store locally for offline support
    await _storeOperationLocally(operation);
  }

  Future<void> syncPendingOperations() async {
    if (_pendingOperations.isEmpty) return;

    final operations = List.from(_pendingOperations);
    _pendingOperations.clear();

    for (final operation in operations) {
      try {
        await _executeOperation(operation);
      } catch (e) {
        // Re-queue failed operations
        _pendingOperations.add(operation);
        _logger.error('Failed to sync operation', 'SupabaseOfflineService',
            error: e);
      }
    }
  }

  Future<void> _executeOperation(Map<String, dynamic> operation) async {
    // Execute the operation based on its type
    // This would integrate with the database service
  }

  Future<void> _storeOperationLocally(Map<String, dynamic> operation) async {
    // Store operation in local storage for offline support
    // Implementation would use shared_preferences or sqflite
  }

  Future<Map<String, dynamic>> getHealthStatus() async {
    return {
      'service': 'offline',
      'initialized': _isInitialized,
      'is_online': _isOnline,
      'pending_operations': _pendingOperations.length,
    };
  }
}

/// Supporting classes and enums
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
  final User? user;
  final String? error;

  AuthResponse.success(this.user)
      : success = true,
        error = null;
  AuthResponse.error(this.error)
      : success = false,
        user = null;
}

class SupabaseEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  SupabaseEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });
}

/// Supabase Tables constants
class SupabaseTables {
  static const String users = 'users';
  static const String userProfiles = 'user_profiles';
  static const String files = 'files';
  static const String fileMetadata = 'file_metadata';
  static const String networkDevices = 'network_devices';
  static const String settings = 'settings';
}
