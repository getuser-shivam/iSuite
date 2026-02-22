import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../types/supabase.dart';
import '../component_registry.dart';
import '../utils.dart';

/// Enhanced Supabase Service with Enterprise Features
/// Provides comprehensive database operations, real-time sync, and offline support
class EnhancedSupabaseService {
  static EnhancedSupabaseService? _instance;
  static EnhancedSupabaseService get instance => _instance ??= EnhancedSupabaseService._internal();
  EnhancedSupabaseService._internal();

  // Supabase Client
  late final SupabaseClient _client;
  late final SupabaseRealtimeClient _realtime;
  
  // Configuration
  SupabaseConfig _config = SupabaseConfig.defaultConfig();
  
  // State Management
  bool _isInitialized = false;
  bool _isConnected = false;
  String? _currentUserId;
  String? _currentSessionId;
  
  // Caching
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheTimeout = Duration(minutes: 5);
  
  // Offline Queue
  final List<OfflineOperation> _offlineQueue = [];
  Timer? _syncTimer;
  
  // Real-time Subscriptions
  final Map<String, RealtimeChannel> _subscriptions = {};
  
  // Event Streams
  final StreamController<SupabaseEvent> _eventController = 
      StreamController<SupabaseEvent>.broadcast();
  
  // Performance Monitoring
  final Map<String, dynamic> _performanceMetrics = {};
  final List<OperationMetric> _operationHistory = [];

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;
  String? get currentSessionId => _currentSessionId;
  SupabaseConfig get config => _config;
  Stream<SupabaseEvent> get events => _eventController.stream;
  Map<String, dynamic> get performanceMetrics => Map.from(_performanceMetrics);
  List<OperationMetric> get operationHistory => List.from(_operationHistory);

  /// Initialize the enhanced Supabase service
  Future<bool> initialize({SupabaseConfig? config}) async {
    if (_isInitialized) return true;

    try {
      // Set configuration from central registry if not provided
      _config = config ?? ComponentRegistry.instance.getParameter('supabase_config') ?? SupabaseConfig.defaultConfig();
      
      // Initialize Supabase
      await Supabase.initialize(
        url: _config.url,
        anonKey: _config.anonKey,
        authOptions: AuthOptions(
          localStorage: SharedPreferencesAsync(),
          autoRefreshToRefresh: true,
          debug: _config.debug,
        ),
        realtimeOptions: RealtimeOptions(
          logLevel: _config.debug ? RealtimeLogLevel.debug : RealtimeLogLevel.info,
        ),
      );
      
      _client = Supabase.instance.client;
      _realtime = _client.realtime;
      
      // Listen to auth state changes
      _client.auth.onAuthStateChange.listen((data) {
        _handleAuthStateChange(data);
      });
      
      // Start sync timer
      _startSyncTimer();
      
      // Start performance monitoring
      _startPerformanceMonitoring();
      
      _isInitialized = true;
      await _emitEvent(SupabaseEvent.initialized);
      
      return true;
    } catch (e) {
      await _emitEvent(SupabaseEvent.error('Initialization failed: $e'));
      return false;
    }
  }

  /// Authenticate user with email and password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _executeOperation(
      'signInWithEmail',
      () async {
        final response = await _client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        
        if (response.user != null) {
          _currentUserId = response.user!.id;
          await _emitEvent(SupabaseEvent.signInSuccess(response.user!.id));
        }
        
        return response;
      },
    );
  }

  /// Register new user
  Future<AuthResponse> signUpWithEmail(String email, String password, {
    String? displayName,
    Map<String, dynamic>? metadata,
  }) async {
    return await _executeOperation(
      'signUpWithEmail',
      () async {
        final response = await _client.auth.signUp(
          email: email,
          password: password,
          data: {
            if (displayName != null) 'display_name': displayName,
            if (metadata != null) ...metadata,
          },
        );
        
        if (response.user != null) {
          _currentUserId = response.user!.id;
          await _emitEvent(SupabaseEvent.signUpSuccess(response.user!.id));
        }
        
        return response;
      },
    );
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _executeOperation(
      'signOut',
      () async {
        await _client.auth.signOut();
        _currentUserId = null;
        _currentSessionId = null;
        await _emitEvent(SupabaseEvent.signOut);
      },
    );
  }

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _executeOperation(
      'resetPassword',
      () async {
        await _client.auth.resetPasswordForEmail(email);
        await _emitEvent(SupabaseEvent.passwordReset);
      },
    );
  }

  /// Generic database operation with caching and offline support
  Future<List<Map<String, dynamic>>> fetchData(
    String table, {
    String? select,
    List<String>? columns,
    Map<String, dynamic>? filters,
    String? orderBy,
    int? limit,
    int? offset,
    bool useCache = true,
  }) async {
    final cacheKey = _generateCacheKey(table, filters, orderBy, limit, offset);
    
    // Check cache first
    if (useCache && _isCacheValid(cacheKey)) {
      return _cache[cacheKey] as List<Map<String, dynamic>>;
    }
    
    return await _executeOperation(
      'fetchData_$table',
      () async {
        PostgrestBuilder query = _client.from(table);
        
        if (select != null) {
          query = query.select(select);
        } else if (columns != null) {
          query = query.select(columns.join(', '));
        }
        
        if (filters != null) {
          for (final entry in filters.entries) {
            if (entry.value is List) {
              query = query.in_(entry.key, entry.value);
            } else {
              query = query.eq(entry.key, entry.value);
            }
          }
        }
        
        if (orderBy != null) {
          query = query.order(orderBy);
        }
        
        if (limit != null) {
          query = query.limit(limit);
        }
        
        if (offset != null) {
          query = query.range(offset, offset + (limit ?? 100) - 1);
        }
        
        final response = await query;
        final data = List<Map<String, dynamic>>.from(response);
        
        // Cache the result
        if (useCache) {
          _cache[cacheKey] = data;
          _cacheTimestamps[cacheKey] = DateTime.now();
        }
        
        return data;
      },
    );
  }

  /// Insert data into database
  Future<Map<String, dynamic>> insertData(
    String table,
    Map<String, dynamic> data, {
    bool returnData = true,
  }) async {
    return await _executeOperation(
      'insertData_$table',
      () async {
        PostgrestBuilder query = _client.from(table).insert(data);
        
        if (returnData) {
          query = query.select();
        }
        
        final response = await query;
        final result = List<Map<String, dynamic>>.from(response);
        
        // Invalidate cache
        _invalidateCacheForTable(table);
        
        if (result.isNotEmpty) {
          await _emitEvent(SupabaseEvent.dataInserted(table, result.first));
          return result.first;
        }
        
        return {};
      },
    );
  }

  /// Update data in database
  Future<Map<String, dynamic>> updateData(
    String table,
    Map<String, dynamic> data,
    String column,
    dynamic value, {
    bool returnData = true,
  }) async {
    return await _executeOperation(
      'updateData_$table',
      () async {
        PostgrestBuilder query = _client.from(table).update(data).eq(column, value);
        
        if (returnData) {
          query = query.select();
        }
        
        final response = await query;
        final result = List<Map<String, dynamic>>.from(response);
        
        // Invalidate cache
        _invalidateCacheForTable(table);
        
        if (result.isNotEmpty) {
          await _emitEvent(SupabaseEvent.dataUpdated(table, result.first));
          return result.first;
        }
        
        return {};
      },
    );
  }

  /// Delete data from database
  Future<void> deleteData(String table, String column, dynamic value) async {
    await _executeOperation(
      'deleteData_$table',
      () async {
        await _client.from(table).delete().eq(column, value);
        
        // Invalidate cache
        _invalidateCacheForTable(table);
        
        await _emitEvent(SupabaseEvent.dataDeleted(table));
      },
    );
  }

  /// Subscribe to real-time changes
  Future<RealtimeChannel> subscribeToTable(
    String table, {
    String? event,
    Map<String, dynamic>? filters,
    Function(Map<String, dynamic>)? onInsert,
    Function(Map<String, dynamic>)? onUpdate,
    Function(Map<String, dynamic>)? onDelete,
  }) async {
    final subscriptionKey = '${table}_${event ?? '*'}';
    
    if (_subscriptions.containsKey(subscriptionKey)) {
      return _subscriptions[subscriptionKey]!;
    }
    
    try {
      RealtimeChannel channel = _realtime.channel(subscriptionKey);
      
      // Build the event filter
      String eventFilter = event ?? '*';
      String filterString = '';
      
      if (filters != null) {
        final filterList = filters.entries.map((e) => '${e.key}=eq.${e.value}').join('&');
        filterString = '?filter=$filterList';
      }
      
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (payload, [ref]) {
          switch (payload.eventType) {
            case PostgresChangeEvent.insert:
              onInsert?.call(payload.newRecord);
              _emitEvent(SupabaseEvent.realtimeInsert(table, payload.newRecord));
              break;
            case PostgresChangeEvent.update:
              onUpdate?.call(payload.newRecord);
              _emitEvent(SupabaseEvent.realtimeUpdate(table, payload.newRecord));
              break;
            case PostgresChangeEvent.delete:
              onDelete?.call(payload.oldRecord);
              _emitEvent(SupabaseEvent.realtimeDelete(table, payload.oldRecord));
              break;
          }
        },
      );
      
      await channel.subscribe();
      _subscriptions[subscriptionKey] = channel;
      
      await _emitEvent(SupabaseEvent.subscriptionCreated(table));
      return channel;
    } catch (e) {
      await _emitEvent(SupabaseEvent.error('Subscription failed: $e'));
      rethrow;
    }
  }

  /// Unsubscribe from real-time changes
  Future<void> unsubscribeFromTable(String table, {String? event}) async {
    final subscriptionKey = '${table}_${event ?? '*'}';
    
    if (_subscriptions.containsKey(subscriptionKey)) {
      await _subscriptions[subscriptionKey]!.unsubscribe();
      _subscriptions.remove(subscriptionKey);
      
      await _emitEvent(SupabaseEvent.subscriptionRemoved(table));
    }
  }

  /// Upload file to Supabase Storage
  Future<String> uploadFile(
    String bucket,
    String path,
    File file, {
    Map<String, String>? metadata,
    String? contentType,
  }) async {
    return await _executeOperation(
      'uploadFile_$bucket',
      () async {
        final fileBytes = await file.readAsBytes();
        
        final response = await _client.storage.from(bucket).uploadBinary(
          fileBytes,
          path,
          fileOptions: FileOptions(
            contentType: contentType ?? _getContentType(file.path),
            metadata: metadata ?? {},
          ),
        );
        
        final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
        
        await _emitEvent(SupabaseEvent.fileUploaded(bucket, path));
        return publicUrl;
      },
    );
  }

  /// Download file from Supabase Storage
  Future<Uint8List> downloadFile(String bucket, String path) async {
    return await _executeOperation(
      'downloadFile_$bucket',
      () async {
        final data = await _client.storage.from(bucket).download(path);
        await _emitEvent(SupabaseEvent.fileDownloaded(bucket, path));
        return data;
      },
    );
  }

  /// Delete file from Supabase Storage
  Future<void> deleteFile(String bucket, String path) async {
    await _executeOperation(
      'deleteFile_$bucket',
      () async {
        await _client.storage.from(bucket).remove([path]);
        await _emitEvent(SupabaseEvent.fileDeleted(bucket, path));
      },
    );
  }

  /// Execute RPC function
  Future<Map<String, dynamic>> executeRpc(
    String functionName,
    Map<String, dynamic> parameters,
  ) async {
    return await _executeOperation(
      'rpc_$functionName',
      () async {
        final response = await _client.rpc(functionName, params: parameters);
        final result = Map<String, dynamic>.from(response);
        
        await _emitEvent(SupabaseEvent.rpcExecuted(functionName));
        return result;
      },
    );
  }

  /// Get service statistics
  Map<String, dynamic> getStatistics() {
    return {
      'config': _config.toMap(),
      'isInitialized': _isInitialized,
      'isConnected': _isConnected,
      'currentUserId': _currentUserId,
      'currentSessionId': _currentSessionId,
      'cacheSize': _cache.length,
      'offlineQueueSize': _offlineQueue.length,
      'activeSubscriptions': _subscriptions.length,
      'performanceMetrics': _performanceMetrics,
      'operationHistory': _operationHistory.take(100).toList(),
    };
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    _emitEvent(SupabaseEvent.cacheCleared);
  }

  /// Sync offline operations
  Future<void> syncOfflineOperations() async {
    if (_offlineQueue.isEmpty || !_isConnected) return;

    try {
      final operations = List<OfflineOperation>.from(_offlineQueue);
      _offlineQueue.clear();

      for (final operation in operations) {
        try {
          await _executeOfflineOperation(operation);
        } catch (e) {
          // Re-add failed operation to queue
          _offlineQueue.add(operation);
        }
      }

      await _emitEvent(SupabaseEvent.offlineSyncCompleted);
    } catch (e) {
      await _emitEvent(SupabaseEvent.error('Offline sync failed: $e'));
    }
  }

  /// Private methods
  Future<T> _executeOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      
      stopwatch.stop();
      
      // Record performance metric
      _recordOperationMetric(operationName, stopwatch.elapsedMilliseconds, true);
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      // Record performance metric
      _recordOperationMetric(operationName, stopwatch.elapsedMilliseconds, false);
      
      // Add to offline queue if not connected
      if (!_isConnected && _config.enableOfflineSupport) {
        _addToOfflineQueue(operationName, e);
      }
      
      await _emitEvent(SupabaseEvent.error('Operation failed: $operationName - $e'));
      rethrow;
    }
  }

  void _handleAuthStateChange(AuthState data) {
    switch (data.event) {
      case AuthChangeEvent.signedIn:
        _isConnected = true;
        _currentUserId = data.session?.user.id;
        _currentSessionId = data.session?.accessToken;
        _emitEvent(SupabaseEvent.authStateChanged('signed_in'));
        break;
      case AuthChangeEvent.signedOut:
        _isConnected = false;
        _currentUserId = null;
        _currentSessionId = null;
        _emitEvent(SupabaseEvent.authStateChanged('signed_out'));
        break;
      case AuthChangeEvent.tokenRefreshed:
        _currentSessionId = data.session?.accessToken;
        _emitEvent(SupabaseEvent.authStateChanged('token_refreshed'));
        break;
    }
  }

  String _generateCacheKey(
    String table,
    Map<String, dynamic>? filters,
    String? orderBy,
    int? limit,
    int? offset,
  ) {
    final parts = [table];
    
    if (filters != null && filters.isNotEmpty) {
      parts.add(filters.toString());
    }
    
    if (orderBy != null) {
      parts.add(orderBy);
    }
    
    if (limit != null) {
      parts.add('limit:$limit');
    }
    
    if (offset != null) {
      parts.add('offset:$offset');
    }
    
    return parts.join('_');
  }

  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheTimeout;
  }

  void _invalidateCacheForTable(String table) {
    final keysToRemove = _cache.keys.where((key) => key.startsWith(table)).toList();
    
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  String _getContentType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    
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
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }

  void _startSyncTimer() {
    if (!_config.enableOfflineSync) return;
    
    _syncTimer = Timer.periodic(Duration(seconds: 30), (_) {
      syncOfflineOperations();
    });
  }

  void _startPerformanceMonitoring() {
    Timer.periodic(Duration(seconds: 10), (_) {
      _updatePerformanceMetrics();
    });
  }

  void _updatePerformanceMetrics() {
    _performanceMetrics = {
      'lastUpdate': DateTime.now().toIso8601String(),
      'cacheSize': _cache.length,
      'offlineQueueSize': _offlineQueue.length,
      'activeSubscriptions': _subscriptions.length,
      'isConnected': _isConnected,
      'currentUserId': _currentUserId,
      'averageOperationTime': _getAverageOperationTime(),
      'successRate': _getSuccessRate(),
    };
  }

  double _getAverageOperationTime() {
    if (_operationHistory.isEmpty) return 0.0;
    
    final totalTime = _operationHistory.fold<int>(0, (sum, metric) => sum + metric.durationMs);
    return totalTime / _operationHistory.length;
  }

  double _getSuccessRate() {
    if (_operationHistory.isEmpty) return 1.0;
    
    final successfulOperations = _operationHistory.where((m) => m.success).length;
    return successfulOperations / _operationHistory.length;
  }

  void _recordOperationMetric(String operationName, int durationMs, bool success) {
    final metric = OperationMetric(
      operationName: operationName,
      durationMs: durationMs,
      success: success,
      timestamp: DateTime.now(),
    );
    
    _operationHistory.add(metric);
    
    // Keep only last 1000 operations
    if (_operationHistory.length > 1000) {
      _operationHistory.removeRange(0, _operationHistory.length - 1000);
    }
  }

  void _addToOfflineQueue(String operationName, dynamic error) {
    final operation = OfflineOperation(
      id: AppUtils.generateRandomId(),
      operationName: operationName,
      timestamp: DateTime.now(),
      error: error.toString(),
      retryCount: 0,
    );
    
    _offlineQueue.add(operation);
  }

  Future<void> _executeOfflineOperation(OfflineOperation operation) async {
    // In a real implementation, this would reconstruct and retry the operation
    // For now, we'll just log it
    await _emitEvent(SupabaseEvent.offlineOperationExecuted(operation.id));
  }

  Future<void> _emitEvent(SupabaseEvent event) async {
    _eventController.add(event);
  }

  /// Dispose the service
  Future<void> dispose() async {
    _syncTimer?.cancel();
    _eventController.close();
    
    // Unsubscribe from all channels
    for (final channel in _subscriptions.values) {
      await channel.unsubscribe();
    }
    _subscriptions.clear();
    
    _isInitialized = false;
  }
}

// Supporting Classes
class SupabaseConfig {
  final String url;
  final String anonKey;
  final bool debug;
  final bool enableOfflineSupport;
  final bool enableOfflineSync;
  final Duration cacheTimeout;
  final int maxCacheSize;
  final int maxOfflineQueueSize;

  const SupabaseConfig({
    required this.url,
    required this.anonKey,
    this.debug = false,
    this.enableOfflineSupport = true,
    this.enableOfflineSync = true,
    this.cacheTimeout = const Duration(minutes: 5),
    this.maxCacheSize = 1000,
    this.maxOfflineQueueSize = 100,
  });

  static const SupabaseConfig defaultConfig = SupabaseConfig(
    url: 'https://your-project.supabase.co',
    anonKey: 'your-anon-key',
  );

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'anonKey': anonKey,
      'debug': debug,
      'enableOfflineSupport': enableOfflineSupport,
      'enableOfflineSync': enableOfflineSync,
      'cacheTimeout': cacheTimeout.inMilliseconds,
      'maxCacheSize': maxCacheSize,
      'maxOfflineQueueSize': maxOfflineQueueSize,
    };
  }
}

class OfflineOperation {
  final String id;
  final String operationName;
  final DateTime timestamp;
  final String error;
  final int retryCount;
  final Map<String, dynamic>? data;

  const OfflineOperation({
    required this.id,
    required this.operationName,
    required this.timestamp,
    required this.error,
    this.retryCount = 0,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operationName': operationName,
      'timestamp': timestamp.toIso8601String(),
      'error': error,
      'retryCount': retryCount,
      'data': data,
    };
  }
}

class OperationMetric {
  final String operationName;
  final int durationMs;
  final bool success;
  final DateTime timestamp;

  const OperationMetric({
    required this.operationName,
    required this.durationMs,
    required this.success,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'operationName': operationName,
      'durationMs': durationMs,
      'success': success,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

enum SupabaseEventType {
  initialized,
  signInSuccess,
  signUpSuccess,
  signOut,
  passwordReset,
  authStateChanged,
  dataInserted,
  dataUpdated,
  dataDeleted,
  realtimeInsert,
  realtimeUpdate,
  realtimeDelete,
  subscriptionCreated,
  subscriptionRemoved,
  fileUploaded,
  fileDownloaded,
  fileDeleted,
  rpcExecuted,
  cacheCleared,
  offlineSyncCompleted,
  offlineOperationExecuted,
  error,
}

class SupabaseEvent {
  final SupabaseEventType type;
  final String? message;
  final dynamic data;
  final DateTime timestamp;

  const SupabaseEvent({
    required this.type,
    this.message,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  const SupabaseEvent.initialized()
      : type = SupabaseEventType.initialized;

  const SupabaseEvent.signInSuccess(String userId)
      : type = SupabaseEventType.signInSuccess,
        data = userId;

  const SupabaseEvent.signUpSuccess(String userId)
      : type = SupabaseEventType.signUpSuccess,
        data = userId;

  const SupabaseEvent.signOut()
      : type = SupabaseEventType.signOut;

  const SupabaseEvent.passwordReset()
      : type = SupabaseEventType.passwordReset;

  const SupabaseEvent.authStateChanged(String state)
      : type = SupabaseEventType.authStateChanged,
        data = state;

  const SupabaseEvent.dataInserted(String table, Map<String, dynamic> data)
      : type = SupabaseEventType.dataInserted,
        data = {'table': table, 'data': data};

  const SupabaseEvent.dataUpdated(String table, Map<String, dynamic> data)
      : type = SupabaseEventType.dataUpdated,
        data = {'table': table, 'data': data};

  const SupabaseEvent.dataDeleted(String table)
      : type = SupabaseEventType.dataDeleted,
        data = table;

  const SupabaseEvent.realtimeInsert(String table, Map<String, dynamic> data)
      : type = SupabaseEventType.realtimeInsert,
        data = {'table': table, 'data': data};

  const SupabaseEvent.realtimeUpdate(String table, Map<String, dynamic> data)
      : type = SupabaseEventType.realtimeUpdate,
        data = {'table': table, 'data': data};

  const SupabaseEvent.realtimeDelete(String table, Map<String, dynamic> data)
      : type = SupabaseEventType.realtimeDelete,
        data = {'table': table, 'data': data};

  const SupabaseEvent.subscriptionCreated(String table)
      : type = SupabaseEventType.subscriptionCreated,
        data = table;

  const SupabaseEvent.subscriptionRemoved(String table)
      : type = SupabaseEventType.subscriptionRemoved,
        data = table;

  const SupabaseEvent.fileUploaded(String bucket, String path)
      : type = SupabaseEventType.fileUploaded,
        data = {'bucket': bucket, 'path': path};

  const SupabaseEvent.fileDownloaded(String bucket, String path)
      : type = SupabaseEventType.fileDownloaded,
        data = {'bucket': bucket, 'path': path};

  const SupabaseEvent.fileDeleted(String bucket, String path)
      : type = SupabaseEventType.fileDeleted,
        data = {'bucket': bucket, 'path': path};

  const SupabaseEvent.rpcExecuted(String functionName)
      : type = SupabaseEventType.rpcExecuted,
        data = functionName;

  const SupabaseEvent.cacheCleared()
      : type = SupabaseEventType.cacheCleared;

  const SupabaseEvent.offlineSyncCompleted()
      : type = SupabaseEventType.offlineSyncCompleted;

  const SupabaseEvent.offlineOperationExecuted(String operationId)
      : type = SupabaseEventType.offlineOperationExecuted,
        data = operationId;

  const SupabaseEvent.error(String message)
      : type = SupabaseEventType.error,
        message = message;
}
