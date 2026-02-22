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
    // TODO: Start data synchronization
  }

  /// Handle when device goes offline
  void _handleDisconnection() {
    _logger.info('Device disconnected, switching to offline mode', 'OfflineManager');
    // TODO: Notify UI components about offline mode
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
          // TODO: Execute the operation
          // This would be implemented based on the specific operation type

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
        }
      }

    } catch (e, stackTrace) {
      _logger.error('Failed to process queued operations', 'OfflineManager',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Initialize SQLite database
  Future<void> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'offline_data.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // Create offline data table
        await db.execute('''
          CREATE TABLE offline_data (
            key TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            synced INTEGER DEFAULT 0
          )
        ''');

        // Create operation queue table
        await db.execute('''
          CREATE TABLE operation_queue (
            operation_id TEXT PRIMARY KEY,
            operation TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            executed INTEGER DEFAULT 0,
            executed_at TEXT,
            retry_count INTEGER DEFAULT 0
          )
        ''');

        _logger.info('Database tables created', 'OfflineManager');
      },
    );
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
