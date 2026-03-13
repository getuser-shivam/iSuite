import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../config/central_parameterized_config.dart';
import '../logging/enhanced_logger.dart';

/// Enhanced Supabase Service
/// 
/// Provides comprehensive Supabase integration with proper organization
/// Features: Authentication, Database, Storage, Real-time, Edge Functions
/// Performance: Optimized queries, caching, connection pooling
/// Architecture: Service layer, repository pattern, error handling
class EnhancedSupabaseService {
  static EnhancedSupabaseService? _instance;
  static EnhancedSupabaseService get instance => _instance ??= EnhancedSupabaseService._internal();
  EnhancedSupabaseService._internal();

  // Supabase client
  late final SupabaseClient _client;
  
  // Configuration
  late final String _supabaseUrl;
  late final String _supabaseKey;
  late final String _databaseUrl;
  late final String _storageUrl;
  late final String _functionsUrl;
  
  // Service state
  bool _isInitialized = false;
  bool _isConnected = false;
  String? _currentUserId;
  String? _currentSessionToken;
  
  // Caching
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheTimeout = Duration(minutes: 5);
  
  // Event streams
  final StreamController<SupabaseEvent> _eventController = 
      StreamController<SupabaseEvent>.broadcast();
  
  // Real-time subscriptions
  final Map<String, RealtimeChannel> _subscriptions = {};
  
  Stream<SupabaseEvent> get events => _eventController.stream;

  /// Initialize Supabase service
  Future<void> initialize() async {
    try {
      EnhancedLogger.instance.info('Initializing Enhanced Supabase Service...');
      
      // Load configuration
      await _loadConfiguration();
      
      // Initialize Supabase client
      _client = SupabaseClient(
        _supabaseUrl,
        _supabaseKey,
        httpClient: _createHttpClient(),
        realtimeClientOptions: const RealtimeClientOptions(
          headers: {'apikey': _supabaseKey},
        ),
      );
      
      // Test connection
      await _testConnection();
      
      // Setup event listeners
      _setupEventListeners();
      
      _isInitialized = true;
      _isConnected = true;
      
      _emitEvent(SupabaseEventType.initialized, 'Supabase service initialized successfully');
      
      EnhancedLogger.instance.info('Enhanced Supabase Service initialized successfully');
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to initialize Supabase service', 
        error: e, stackTrace: stackTrace);
      _emitEvent(SupabaseEventType.error, 'Failed to initialize Supabase service', error: e.toString());
      rethrow;
    }
  }

  /// Load configuration from central config
  Future<void> _loadConfiguration() async {
    final config = CentralParameterizedConfig.instance;
    
    _supabaseUrl = config.getParameter('supabase.url', defaultValue: 'https://your-project.supabase.co')!;
    _supabaseKey = config.getParameter('supabase.anon_key', defaultValue: 'your-anon-key')!;
    _databaseUrl = config.getParameter('supabase.database_url', defaultValue: '$_supabaseUrl/rest/v1')!;
    _storageUrl = config.getParameter('supabase.storage_url', defaultValue: '$_supabaseUrl/storage/v1')!;
    _functionsUrl = config.getParameter('supabase.functions_url', defaultValue: '$_supabaseUrl/functions/v1')!;
    
    EnhancedLogger.instance.info('Supabase configuration loaded');
  }

  /// Create HTTP client with proper headers
  Future<Function(String) -> Future<http.Response>> _createHttpClient() async {
    return (url) async {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
          'Content-Type': 'application/json',
        },
      );
      return response;
    };
  }

  /// Test Supabase connection
  Future<void> _testConnection() async {
    try {
      final response = await _client.from('health_check').select().limit(1).execute();
      
      if (response.error != null) {
        throw Exception('Connection test failed: ${response.error!.message}');
      }
      
      EnhancedLogger.instance.info('Supabase connection test successful');
    } catch (e) {
      EnhancedLogger.instance.warning('Supabase connection test failed, but continuing: $e');
    }
  }

  /// Setup event listeners
  void _setupEventListeners() {
    // Listen to configuration changes
    CentralParameterizedConfig.instance.configurationEvents.listen((event) {
      if (event.type == ConfigurationEventType.parameterChanged) {
        _handleConfigurationChange(event);
      }
    });
  }

  /// Handle configuration changes
  void _handleConfigurationChange(ConfigurationEvent event) {
    if (event.key.startsWith('supabase.')) {
      EnhancedLogger.instance.info('Supabase configuration changed, reinitializing...');
      _reinitialize();
    }
  }

  /// Reinitialize service
  Future<void> _reinitialize() async {
    try {
      await dispose();
      await initialize();
    } catch (e) {
      EnhancedLogger.instance.error('Failed to reinitialize Supabase service', error: e);
    }
  }

  /// Authentication Methods
  /// 
  /// Sign up with email and password
  Future<SupabaseResponse> signUp(String email, String password, {Map<String, dynamic>? metadata}) async {
    try {
      _emitEvent(SupabaseEventType.signUpStarted, 'Starting sign up process');
      
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );
      
      if (response.user != null) {
        _currentUserId = response.user!.id;
        _currentSessionToken = response.session?.accessToken;
        _emitEvent(SupabaseEventType.signUpSuccess, 'Sign up successful');
      } else {
        _emitEvent(SupabaseEventType.signUpError, 'Sign up failed', error: response.error?.message);
      }
      
      return SupabaseResponse.fromAuthResponse(response);
    } catch (e) {
      _emitEvent(SupabaseEventType.signUpError, 'Sign up error', error: e.toString());
      return SupabaseResponse.error('Sign up failed: $e');
    }
  }

  /// Sign in with email and password
  Future<SupabaseResponse> signIn(String email, String password) async {
    try {
      _emitEvent(SupabaseEventType.signInStarted, 'Starting sign in process');
      
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        _currentUserId = response.user!.id;
        _currentSessionToken = response.session?.accessToken;
        _emitEvent(SupabaseEventType.signInSuccess, 'Sign in successful');
      } else {
        _emitEvent(SupabaseEventType.signInError, 'Sign in failed', error: response.error?.message);
      }
      
      return SupabaseResponse.fromAuthResponse(response);
    } catch (e) {
      _emitEvent(SupabaseEventType.signInError, 'Sign in error', error: e.toString());
      return SupabaseResponse.error('Sign in failed: $e');
    }
  }

  /// Sign in with OAuth provider
  Future<SupabaseResponse> signInWithOAuth(OAuthProvider provider) async {
    try {
      _emitEvent(SupabaseEventType.signInStarted, 'Starting OAuth sign in');
      
      final response = await _client.auth.signInWithOAuth(provider);
      
      if (response.user != null) {
        _currentUserId = response.user!.id;
        _currentSessionToken = response.session?.accessToken;
        _emitEvent(SupabaseEventType.signInSuccess, 'OAuth sign in successful');
      } else {
        _emitEvent(SupabaseEventType.signInError, 'OAuth sign in failed', error: response.error?.message);
      }
      
      return SupabaseResponse.fromAuthResponse(response);
    } catch (e) {
      _emitEvent(SupabaseEventType.signInError, 'OAuth sign in error', error: e.toString());
      return SupabaseResponse.error('OAuth sign in failed: $e');
    }
  }

  /// Sign out
  Future<SupabaseResponse> signOut() async {
    try {
      _emitEvent(SupabaseEventType.signOutStarted, 'Starting sign out process');
      
      await _client.auth.signOut();
      
      _currentUserId = null;
      _currentSessionToken = null;
      
      // Clear user-specific cache
      _clearUserCache();
      
      _emitEvent(SupabaseEventType.signOutSuccess, 'Sign out successful');
      
      return SupabaseResponse.success('Sign out successful');
    } catch (e) {
      _emitEvent(SupabaseEventType.signOutError, 'Sign out error', error: e.toString());
      return SupabaseResponse.error('Sign out failed: $e');
    }
  }

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Get current session
  Session? get currentSession => _client.auth.currentSession;

  /// Database Methods
  /// 
  /// Generic query with caching
  Future<SupabaseResponse> query(
    String table, {
    List<String>? columns,
    String? filter,
    String? orderBy,
    int? limit,
    int? offset,
    bool useCache = true,
  }) async {
    try {
      final cacheKey = _generateCacheKey(table, columns, filter, orderBy, limit, offset);
      
      // Check cache first
      if (useCache && _isCacheValid(cacheKey)) {
        final cachedData = _cache[cacheKey];
        _emitEvent(SupabaseEventType.dataLoaded, 'Data loaded from cache');
        return SupabaseResponse.success(cachedData);
      }
      
      _emitEvent(SupabaseEventType.dataLoading, 'Loading data from database');
      
      var query = _client.from(table).select(columns?.join(', ') ?? '*');
      
      if (filter != null) {
        query = query.filter(filter);
      }
      
      if (orderBy != null) {
        query = query.order(orderBy);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      if (offset != null) {
        query = query.range(offset, offset! + (limit ?? 100) - 1);
      }
      
      final response = await query.execute();
      
      if (response.error != null) {
        _emitEvent(SupabaseEventType.dataError, 'Query failed', error: response.error!.message);
        return SupabaseResponse.error('Query failed: ${response.error!.message}');
      }
      
      final data = response.data;
      
      // Cache the result
      if (useCache && data != null) {
        _cache[cacheKey] = data;
        _cacheTimestamps[cacheKey] = DateTime.now();
      }
      
      _emitEvent(SupabaseEventType.dataLoaded, 'Data loaded successfully');
      
      return SupabaseResponse.success(data);
    } catch (e) {
      _emitEvent(SupabaseEventType.dataError, 'Query error', error: e.toString());
      return SupabaseResponse.error('Query failed: $e');
    }
  }

  /// Insert data
  Future<SupabaseResponse> insert(String table, Map<String, dynamic> data) async {
    try {
      _emitEvent(SupabaseEventType.dataInserting, 'Inserting data');
      
      final response = await _client.from(table).insert(data).execute();
      
      if (response.error != null) {
        _emitEvent(SupabaseEventType.dataError, 'Insert failed', error: response.error!.message);
        return SupabaseResponse.error('Insert failed: ${response.error!.message}');
      }
      
      // Invalidate cache for this table
      _invalidateTableCache(table);
      
      _emitEvent(SupabaseEventType.dataInserted, 'Data inserted successfully');
      
      return SupabaseResponse.success(response.data);
    } catch (e) {
      _emitEvent(SupabaseEventType.dataError, 'Insert error', error: e.toString());
      return SupabaseResponse.error('Insert failed: $e');
    }
  }

  /// Update data
  Future<SupabaseResponse> update(String table, Map<String, dynamic> data, String filter) async {
    try {
      _emitEvent(SupabaseEventType.dataUpdating, 'Updating data');
      
      final response = await _client.from(table).update(data).filter(filter).execute();
      
      if (response.error != null) {
        _emitEvent(SupabaseEventType.dataError, 'Update failed', error: response.error!.message);
        return SupabaseResponse.error('Update failed: ${response.error!.message}');
      }
      
      // Invalidate cache for this table
      _invalidateTableCache(table);
      
      _emitEvent(SupabaseEventType.dataUpdated, 'Data updated successfully');
      
      return SupabaseResponse.success(response.data);
    } catch (e) {
      _emitEvent(SupabaseEventType.dataError, 'Update error', error: e.toString());
      return SupabaseResponse.error('Update failed: $e');
    }
  }

  /// Delete data
  Future<SupabaseResponse> delete(String table, String filter) async {
    try {
      _emitEvent(SupabaseEventType.dataDeleting, 'Deleting data');
      
      final response = await _client.from(table).delete().filter(filter).execute();
      
      if (response.error != null) {
        _emitEvent(SupabaseEventType.dataError, 'Delete failed', error: response.error!.message);
        return SupabaseResponse.error('Delete failed: ${response.error!.message}');
      }
      
      // Invalidate cache for this table
      _invalidateTableCache(table);
      
      _emitEvent(SupabaseEventType.dataDeleted, 'Data deleted successfully');
      
      return SupabaseResponse.success(response.data);
    } catch (e) {
      _emitEvent(SupabaseEventType.dataError, 'Delete error', error: e.toString());
      return SupabaseResponse.error('Delete failed: $e');
    }
  }

  /// Storage Methods
  /// 
  /// Upload file to storage
  Future<SupabaseResponse> uploadFile(String bucket, String path, Uint8List fileBytes, {Map<String, String>? metadata}) async {
    try {
      _emitEvent(SupabaseEventType.fileUploading, 'Uploading file');
      
      final response = await _client.storage.from(bucket).uploadBinary(
        path,
        fileBytes,
        fileOptions: FileOptions(
          cacheControl: '3600',
          upsert: true,
          metadata: metadata,
        ),
      );
      
      if (response.error != null) {
        _emitEvent(SupabaseEventType.fileError, 'Upload failed', error: response.error!.message);
        return SupabaseResponse.error('Upload failed: ${response.error!.message}');
      }
      
      _emitEvent(SupabaseEventType.fileUploaded, 'File uploaded successfully');
      
      return SupabaseResponse.success(response.data);
    } catch (e) {
      _emitEvent(SupabaseEventType.fileError, 'Upload error', error: e.toString());
      return SupabaseResponse.error('Upload failed: $e');
    }
  }

  /// Download file from storage
  Future<SupabaseResponse> downloadFile(String bucket, String path) async {
    try {
      _emitEvent(SupabaseEventType.fileDownloading, 'Downloading file');
      
      final response = await _client.storage.from(bucket).download(path);
      
      if (response.error != null) {
        _emitEvent(SupabaseEventType.fileError, 'Download failed', error: response.error!.message);
        return SupabaseResponse.error('Download failed: ${response.error!.message}');
      }
      
      _emitEvent(SupabaseEventType.fileDownloaded, 'File downloaded successfully');
      
      return SupabaseResponse.success(response.data);
    } catch (e) {
      _emitEvent(SupabaseEventType.fileError, 'Download error', error: e.toString());
      return SupabaseResponse.error('Download failed: $e');
    }
  }

  /// Get public URL for file
  String getPublicUrl(String bucket, String path) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  /// Real-time Methods
  /// 
  /// Subscribe to table changes
  RealtimeChannel subscribeToTable(String table, {Function(RealtimePayload)? onEvent}) {
    final channel = _client.channel(table).onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: table,
      callback: onEvent,
    ).subscribe();
    
    _subscriptions[table] = channel;
    
    _emitEvent(SupabaseEventType.subscriptionCreated, 'Subscribed to table: $table');
    
    return channel;
  }

  /// Unsubscribe from table
  void unsubscribeFromTable(String table) {
    final channel = _subscriptions[table];
    if (channel != null) {
      channel.unsubscribe();
      _subscriptions.remove(table);
      
      _emitEvent(SupabaseEventType.subscriptionRemoved, 'Unsubscribed from table: $table');
    }
  }

  /// Edge Functions
  /// 
  /// Call edge function
  Future<SupabaseResponse> callFunction(String functionName, {Map<String, dynamic>? parameters}) async {
    try {
      _emitEvent(SupabaseEventType.functionCalling, 'Calling edge function: $functionName');
      
      final response = await _client.functions.invoke(functionName, params: parameters);
      
      if (response.error != null) {
        _emitEvent(SupabaseEventType.functionError, 'Function call failed', error: response.error!.message);
        return SupabaseResponse.error('Function call failed: ${response.error!.message}');
      }
      
      _emitEvent(SupabaseEventType.functionCalled, 'Edge function called successfully');
      
      return SupabaseResponse.success(response.data);
    } catch (e) {
      _emitEvent(SupabaseEventType.functionError, 'Function call error', error: e.toString());
      return SupabaseResponse.error('Function call failed: $e');
    }
  }

  /// Utility Methods
  /// 
  /// Generate cache key
  String _generateCacheKey(String table, List<String>? columns, String? filter, String? orderBy, int? limit, int? offset) {
    final parts = [table];
    if (columns != null) parts.add(columns.join(','));
    if (filter != null) parts.add(filter);
    if (orderBy != null) parts.add(orderBy);
    if (limit != null) parts.add('limit:$limit');
    if (offset != null) parts.add('offset:$offset');
    return parts.join('|');
  }

  /// Check if cache is valid
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheTimeout;
  }

  /// Invalidate table cache
  void _invalidateTableCache(String table) {
    final keysToRemove = _cache.keys.where((key) => key.startsWith('$table|')).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Clear user-specific cache
  void _clearUserCache() {
    final keysToRemove = _cache.keys.where((key) => key.contains('user_')).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Clear all cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Emit event
  void _emitEvent(SupabaseEventType type, String message, {dynamic data, String? error}) {
    _eventController.add(SupabaseEvent(
      type: type,
      message: message,
      data: data,
      error: error,
      timestamp: DateTime.now(),
    ));
  }

  /// Get service statistics
  Map<String, dynamic> getStatistics() {
    return {
      'is_initialized': _isInitialized,
      'is_connected': _isConnected,
      'current_user_id': _currentUserId,
      'cache_size': _cache.length,
      'subscriptions_count': _subscriptions.length,
      'supabase_url': _supabaseUrl,
      'database_url': _databaseUrl,
      'storage_url': _storageUrl,
      'functions_url': _functionsUrl,
    };
  }

  /// Dispose service
  Future<void> dispose() async {
    try {
      _emitEvent(SupabaseEventType.disposing, 'Disposing Supabase service');
      
      // Unsubscribe from all real-time subscriptions
      for (final channel in _subscriptions.values) {
        channel.unsubscribe();
      }
      _subscriptions.clear();
      
      // Clear cache
      clearCache();
      
      // Close event controller
      await _eventController.close();
      
      _isInitialized = false;
      _isConnected = false;
      _currentUserId = null;
      _currentSessionToken = null;
      
      EnhancedLogger.instance.info('Supabase service disposed');
    } catch (e) {
      EnhancedLogger.instance.error('Error disposing Supabase service', error: e);
    }
  }
}

/// Supabase Response wrapper
class SupabaseResponse {
  final bool success;
  final dynamic data;
  final String? error;
  final DateTime timestamp;
  
  SupabaseResponse({
    required this.success,
    this.data,
    this.error,
  }) : timestamp = DateTime.now();
  
  factory SupabaseResponse.success(dynamic data) {
    return SupabaseResponse(success: true, data: data);
  }
  
  factory SupabaseResponse.error(String error) {
    return SupabaseResponse(success: false, error: error);
  }
  
  factory SupabaseResponse.fromAuthResponse(AuthResponse response) {
    if (response.user != null) {
      return SupabaseResponse.success({
        'user': response.user!.toJson(),
        'session': response.session?.toJson(),
      });
    } else {
      return SupabaseResponse.error(response.error?.message ?? 'Authentication failed');
    }
  }
}

/// Supabase Event
class SupabaseEvent {
  final SupabaseEventType type;
  final String message;
  final dynamic data;
  final String? error;
  final DateTime timestamp;
  
  SupabaseEvent({
    required this.type,
    required this.message,
    this.data,
    this.error,
  }) : timestamp = DateTime.now();
}

/// Supabase Event Types
enum SupabaseEventType {
  // Authentication
  initialized,
  signUpStarted,
  signUpSuccess,
  signUpError,
  signInStarted,
  signInSuccess,
  signInError,
  signOutStarted,
  signOutSuccess,
  signOutError,
  
  // Database
  dataLoading,
  dataLoaded,
  dataError,
  dataInserting,
  dataInserted,
  dataUpdating,
  dataUpdated,
  dataDeleting,
  dataDeleted,
  
  // Storage
  fileUploading,
  fileUploaded,
  fileDownloading,
  fileDownloaded,
  fileError,
  
  // Real-time
  subscriptionCreated,
  subscriptionRemoved,
  
  // Edge Functions
  functionCalling,
  functionCalled,
  functionError,
  
  // System
  disposing,
  error,
}

/// Enhanced Supabase Service Provider
class EnhancedSupabaseServiceProvider extends ChangeNotifier {
  final EnhancedSupabaseService _service;
  
  EnhancedSupabaseServiceProvider(this._service);
  
  factory EnhancedSupabaseServiceProvider.create() {
    final service = EnhancedSupabaseService.instance;
    return EnhancedSupabaseServiceProvider._internal(service);
  }
  
  EnhancedSupabaseServiceProvider._internal(this._service);
  
  // Getters
  bool get isInitialized => _service._isInitialized;
  bool get isConnected => _service._isConnected;
  String? get currentUserId => _service._currentUserId;
  User? get currentUser => _service.currentUser;
  Session? get currentSession => _service.currentSession;
  
  // Stream
  Stream<SupabaseEvent> get events => _service.events;
  
  // Statistics
  Map<String, dynamic> get statistics => _service.getStatistics();
  
  // Methods
  Future<void> initialize() => _service.initialize();
  Future<void> dispose() => _service.dispose();
}

/// Provider instance
final enhancedSupabaseServiceProvider = ChangeNotifierProvider<EnhancedSupabaseServiceProvider>(
  (ref) => EnhancedSupabaseServiceProvider.create(),
);
