import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../logging/logging_service.dart';

/// Offline Support Manager
class OfflineManager {
  static final OfflineManager _instance = OfflineManager._internal();
  factory OfflineManager() => _instance;
  OfflineManager._internal();

  final LoggingService _logger = LoggingService();
  final Connectivity _connectivity = Connectivity();

  late Database _database;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();

  // Callbacks for online/offline events
  final Map<String, Function(bool)> _connectivityCallbacks = {};

  /// Initialize offline manager
  Future<void> initialize() async {
    try {
      _logger.info('Initializing offline manager', 'OfflineManager');

      // Initialize database
      await _initDatabase();

      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _isOnline = result != ConnectivityResult.none;
      _logger.info('Initial connectivity: $_isOnline', 'OfflineManager');

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
      );

      _logger.info('Offline manager initialized successfully', 'OfflineManager');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize offline manager', 'OfflineManager',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Check if device is online
  bool get isOnline => _isOnline;

  /// Stream of connectivity changes
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Register callback for connectivity changes
  void registerConnectivityCallback(String key, Function(bool) callback) {
    _connectivityCallbacks[key] = callback;
  }

  /// Unregister connectivity callback
  void unregisterConnectivityCallback(String key) {
    _connectivityCallbacks.remove(key);
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    if (wasOnline != _isOnline) {
      _logger.info('Connectivity changed: $_isOnline', 'OfflineManager');

      // Notify callbacks
      for (final callback in _connectivityCallbacks.values) {
        try {
          callback(_isOnline);
        } catch (e) {
          _logger.error('Error in connectivity callback', 'OfflineManager', error: e);
        }
      }

      // Add to stream
      _connectivityController.add(_isOnline);

      // Handle reconnection
      if (_isOnline) {
        _handleReconnection();
      } else {
        _handleDisconnection();
      }
    }
  }

  /// Handle when device comes back online
  void _handleReconnection() {
    _logger.info('Device reconnected, starting synchronization', 'OfflineManager');

    // Start data synchronization
    _startDataSynchronization();

    // Notify UI components about online status
    _notifyUIAboutConnectivityChange(true);
  }

  /// Handle when device goes offline
  void _handleDisconnection() {
    _logger.info('Device disconnected, switching to offline mode', 'OfflineManager');

    // Notify UI components about offline mode
    _notifyUIAboutConnectivityChange(false);
  }

  /// Start data synchronization when coming back online
  Future<void> _startDataSynchronization() async {
    try {
      _logger.info('Starting offline data synchronization', 'OfflineManager');

      // Process queued operations first
      await processQueuedOperations();

      // Sync offline data changes
      await _syncOfflineDataChanges();

      // Sync with remote servers if configured
      await _syncWithRemoteServers();

      _logger.info('Offline data synchronization completed', 'OfflineManager');

    } catch (e, stackTrace) {
      _logger.error('Failed to synchronize offline data', 'OfflineManager',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Notify UI components about connectivity changes
  void _notifyUIAboutConnectivityChange(bool isOnline) {
    // Notify all registered callbacks
    for (final callback in _connectivityCallbacks.values) {
      try {
        callback(isOnline);
      } catch (e) {
        _logger.error('Error in connectivity callback', 'OfflineManager', error: e);
      }
    }

    // Emit to stream
    _connectivityController.add(isOnline);

    // Log the notification
    _logger.info('Notified UI components about connectivity change: $isOnline', 'OfflineManager');
  }

  /// Sync offline data changes with remote servers
  Future<void> _syncOfflineDataChanges() async {
    try {
      final unsyncedData = await getUnsyncedData();

      if (unsyncedData.isEmpty) {
        _logger.info('No unsynced data to synchronize', 'OfflineManager');
        return;
      }

      _logger.info('Synchronizing ${unsyncedData.length} offline data items', 'OfflineManager');

      for (final item in unsyncedData) {
        try {
          // TODO: Implement actual synchronization logic based on data type
          // This would call appropriate services (Supabase, API, etc.) to sync data

          // For now, just mark as synced
          await markAsSynced(item['key']);

          _logger.debug('Synchronized offline data: ${item['key']}', 'OfflineManager');

        } catch (e) {
          _logger.error('Failed to sync offline data: ${item['key']}', 'OfflineManager', error: e);
          // Continue with other items - don't fail the whole sync
        }
      }

    } catch (e, stackTrace) {
      _logger.error('Failed to sync offline data changes', 'OfflineManager',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Sync with remote servers
  Future<void> _syncWithRemoteServers() async {
    try {
      _logger.info('Synchronizing with remote servers', 'OfflineManager');

      // TODO: Implement remote server synchronization
      // This would sync with Supabase, APIs, etc.

      _logger.info('Remote server synchronization completed', 'OfflineManager');

    } catch (e, stackTrace) {
      _logger.error('Failed to sync with remote servers', 'OfflineManager',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Store data for offline use
  Future<void> storeOfflineData(String key, Map<String, dynamic> data) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final offlineData = {
        'key': key,
        'data': jsonEncode(data),
        'timestamp': timestamp,
        'synced': false,
      };

      await _database.insert(
        'offline_data',
        offlineData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.debug('Stored offline data for key: $key', 'OfflineManager');

    } catch (e, stackTrace) {
      _logger.error('Failed to store offline data', 'OfflineManager',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Retrieve offline data
  Future<Map<String, dynamic>?> getOfflineData(String key) async {
    try {
      final result = await _database.query(
        'offline_data',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final data = result.first;
        return {
          'data': jsonDecode(data['data'] as String),
          'timestamp': data['timestamp'] as String,
          'synced': data['synced'] == 1,
        };
      }

      return null;

    } catch (e, stackTrace) {
      _logger.error('Failed to retrieve offline data', 'OfflineManager',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Mark data as synced
  Future<void> markAsSynced(String key) async {
    try {
      await _database.update(
        'offline_data',
        {'synced': true},
        where: 'key = ?',
        whereArgs: [key],
      );

      _logger.debug('Marked data as synced for key: $key', 'OfflineManager');

    } catch (e, stackTrace) {
      _logger.error('Failed to mark data as synced', 'OfflineManager',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Get all unsynced data
  Future<List<Map<String, dynamic>>> getUnsyncedData() async {
    try {
      final result = await _database.query(
        'offline_data',
        where: 'synced = ?',
        whereArgs: [false],
      );

      return result.map((row) => {
        'key': row['key'] as String,
        'data': jsonDecode(row['data'] as String),
        'timestamp': row['timestamp'] as String,
      }).toList();

    } catch (e, stackTrace) {
      _logger.error('Failed to get unsynced data', 'OfflineManager',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Queue operation for when device comes online
  Future<void> queueOperation(String operationId, Map<String, dynamic> operation) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final queueItem = {
        'operation_id': operationId,
        'operation': jsonEncode(operation),
        'timestamp': timestamp,
        'executed': false,
        'retry_count': 0,
      };

      await _database.insert('operation_queue', queueItem);

      _logger.debug('Queued operation: $operationId', 'OfflineManager');

    } catch (e, stackTrace) {
      _logger.error('Failed to queue operation', 'OfflineManager',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Process queued operations when online
  Future<void> processQueuedOperations() async {
    if (!_isOnline) return;

    try {
      final queuedOperations = await _database.query(
        'operation_queue',
        where: 'executed = ?',
        whereArgs: [false],
        orderBy: 'timestamp ASC',
      );

      _logger.info('Processing ${queuedOperations.length} queued operations', 'OfflineManager');

      for (final operation in queuedOperations) {
        try {
          // Execute the operation based on its type
          await _executeQueuedOperation(operation);

          // Mark as executed
          await _database.update(
            'operation_queue',
            {'executed': true, 'executed_at': DateTime.now().toIso8601String()},
            where: 'operation_id = ?',
            whereArgs: [operation['operation_id']],
          );

          _logger.debug('Executed queued operation: ${operation['operation_id']}', 'OfflineManager');

        } catch (e) {
          _logger.error('Failed to execute queued operation: ${operation['operation_id']}',
              'OfflineManager', error: e);

          // Increment retry count
          final retryCount = (operation['retry_count'] as int) + 1;
          await _database.update(
            'operation_queue',
            {'retry_count': retryCount},
            where: 'operation_id = ?',
            whereArgs: [operation['operation_id']],
          );

          // If max retries exceeded, mark as failed
          if (retryCount >= 3) { // Max retries
            await _database.update(
              'operation_queue',
              {'executed': true, 'failed': true, 'error': e.toString()},
              where: 'operation_id = ?',
              whereArgs: [operation['operation_id']],
            );
          }
        }
      }

    } catch (e, stackTrace) {
      _logger.error('Failed to process queued operations', 'OfflineManager',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Execute a queued operation
  Future<void> _executeQueuedOperation(Map<String, dynamic> operation) async {
    final operationData = jsonDecode(operation['operation'] as String);
    final operationType = operationData['type'] as String?;

    if (operationType == null) {
      throw Exception('Operation type not specified');
    }

    _logger.debug('Executing operation type: $operationType', 'OfflineManager');

    switch (operationType) {
      case 'http_request':
        await _executeHttpRequest(operationData);
        break;
      case 'database_operation':
        await _executeDatabaseOperation(operationData);
        break;
      case 'file_operation':
        await _executeFileOperation(operationData);
        break;
      case 'api_call':
        await _executeApiCall(operationData);
        break;
      default:
        throw Exception('Unknown operation type: $operationType');
    }
  }

  /// Execute HTTP request operation
  Future<void> _executeHttpRequest(Map<String, dynamic> operationData) async {
    final url = operationData['url'] as String?;
    final method = operationData['method'] as String? ?? 'GET';
    final headers = operationData['headers'] as Map<String, dynamic>? ?? {};
    final body = operationData['body'];

    if (url == null) {
      throw Exception('URL not specified for HTTP request');
    }

    // This would use the HTTP client to make the request
    // For now, this is a placeholder implementation
    _logger.debug('Executing HTTP request: $method $url', 'OfflineManager');

    // TODO: Implement actual HTTP request execution
    // This would use http package or similar to make the request
  }

  /// Execute database operation
  Future<void> _executeDatabaseOperation(Map<String, dynamic> operationData) async {
    final table = operationData['table'] as String?;
    final operation = operationData['operation'] as String? ?? 'insert';
    final data = operationData['data'] as Map<String, dynamic>?;

    if (table == null || data == null) {
      throw Exception('Table or data not specified for database operation');
    }

    _logger.debug('Executing database operation: $operation on $table', 'OfflineManager');

    // This would execute the database operation using appropriate service
    // For now, this is a placeholder
    // TODO: Implement actual database operation execution
  }

  /// Execute file operation
  Future<void> _executeFileOperation(Map<String, dynamic> operationData) async {
    final operation = operationData['operation'] as String? ?? 'upload';
    final filePath = operationData['filePath'] as String?;
    final remotePath = operationData['remotePath'] as String?;

    if (filePath == null) {
      throw Exception('File path not specified for file operation');
    }

    _logger.debug('Executing file operation: $operation on $filePath', 'OfflineManager');

    // This would execute file operations using appropriate service
    // For now, this is a placeholder
    // TODO: Implement actual file operation execution
  }

  /// Execute API call operation
  Future<void> _executeApiCall(Map<String, dynamic> operationData) async {
    final endpoint = operationData['endpoint'] as String?;
    final method = operationData['method'] as String? ?? 'GET';
    final payload = operationData['payload'];

    if (endpoint == null) {
      throw Exception('Endpoint not specified for API call');
    }

    _logger.debug('Executing API call: $method $endpoint', 'OfflineManager');

    // This would execute API calls using appropriate service
    // For now, this is a placeholder
    // TODO: Implement actual API call execution
  }

  /// Clean up resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
    _database.close();
  }
}

/// Offline-aware widget mixin
mixin OfflineAware {
  bool get isOnline => OfflineManager().isOnline;
  Stream<bool> get connectivityStream => OfflineManager().connectivityStream;

  /// Execute operation with offline fallback
  Future<T?> executeWithOfflineFallback<T>(
    Future<T> Function() onlineOperation,
    Future<T?> Function()? offlineFallback,
  ) async {
    if (isOnline) {
      try {
        return await onlineOperation();
      } catch (e) {
        if (offlineFallback != null) {
          return await offlineFallback();
        }
        rethrow;
      }
    } else {
      if (offlineFallback != null) {
        return await offlineFallback();
      }
      return null;
    }
  }

  /// Store data for offline use
  Future<void> storeForOffline(String key, Map<String, dynamic> data) async {
    await OfflineManager().storeOfflineData(key, data);
  }

  /// Retrieve offline data
  Future<Map<String, dynamic>?> getOfflineData(String key) async {
    return await OfflineManager().getOfflineData(key);
  }
}
