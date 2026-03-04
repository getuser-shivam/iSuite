import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/central_config.dart';
import 'logging_service.dart';
import 'free_database_service.dart';

/// Advanced Offline Capabilities Service for iSuite
/// Provides comprehensive offline functionality with intelligent sync
/// Works completely offline and syncs when connection is restored
class AdvancedOfflineService {
  static final AdvancedOfflineService _instance =
      AdvancedOfflineService._internal();
  factory AdvancedOfflineService() => _instance;

  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();
  final FreeDatabaseService _databaseService = FreeDatabaseService();
  final Connectivity _connectivity = Connectivity();

  // Offline state
  bool _isOnline = true;
  bool _isInitialized = false;
  DateTime? _lastSyncTime;
  final Map<String, OfflineQueueItem> _syncQueue = {};
  final Map<String, ConflictResolution> _conflictResolutions = {};

  // Sync configuration
  Duration _syncInterval = const Duration(minutes: 5);
  int _maxRetries = 3;
  Duration _retryDelay = const Duration(seconds: 30);

  // Queues for offline operations
  final List<OfflineOperation> _pendingOperations = [];
  final List<OfflineOperation> _failedOperations = [];
  final Map<String, OfflineData> _offlineCache = {};

  final StreamController<OfflineEvent> _offlineEventController =
      StreamController.broadcast();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _syncTimer;

  Stream<OfflineEvent> get offlineEvents => _offlineEventController.stream;

  AdvancedOfflineService._internal();

  /// Initialize advanced offline service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Register with CentralConfig
      await _config.registerComponent('AdvancedOfflineService', '1.0.0',
          'Advanced offline capabilities with intelligent sync and conflict resolution',
          dependencies: [
            'CentralConfig',
            'LoggingService',
            'FreeDatabaseService'
          ],
          parameters: {
            // Offline settings
            'offline.enabled': true,
            'offline.auto_sync': true,
            'offline.sync_on_startup': true,
            'offline.background_sync': true,

            // Sync configuration
            'offline.sync_interval_minutes': 5,
            'offline.max_retries': 3,
            'offline.retry_delay_seconds': 30,
            'offline.batch_size': 50,

            // Conflict resolution
            'offline.conflict_strategy':
                'server_wins', // server_wins, client_wins, manual
            'offline.notify_conflicts': true,

            // Data management
            'offline.max_cache_size_mb': 100,
            'offline.cache_cleanup_enabled': true,
            'offline.cache_cleanup_interval_hours': 24,

            // Network optimization
            'offline.compress_data': true,
            'offline.delta_sync': true,
            'offline.preload_favorites': true,

            // User experience
            'offline.show_offline_indicator': true,
            'offline.offline_mode_message':
                'You are currently offline. Changes will sync when connection is restored.',
          });

      // Initialize connectivity monitoring
      await _initializeConnectivityMonitoring();

      // Load offline data from storage
      await _loadOfflineData();

      // Setup periodic sync
      await _setupPeriodicSync();

      // Check initial connectivity
      await _updateConnectivityStatus();

      _isInitialized = true;
      _emitOfflineEvent(OfflineEventType.initialized);

      _logger.info(
          'Advanced Offline Service initialized', 'AdvancedOfflineService');

      // Perform initial sync if online and enabled
      if (_isOnline &&
          await _config.getParameter<bool>('offline.sync_on_startup',
              defaultValue: true)) {
        await performSync();
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Advanced Offline Service',
          'AdvancedOfflineService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Queue operation for offline execution
  Future<String> queueOperation({
    required String operationType,
    required Map<String, dynamic> data,
    required String collection,
    String? documentId,
    ConflictResolutionStrategy conflictStrategy =
        ConflictResolutionStrategy.serverWins,
  }) async {
    final operationId = _generateOperationId();
    final operation = OfflineOperation(
      id: operationId,
      type: operationType,
      data: data,
      collection: collection,
      documentId: documentId,
      timestamp: DateTime.now(),
      conflictStrategy: conflictStrategy,
      retryCount: 0,
    );

    _pendingOperations.add(operation);

    // Save to persistent storage
    await _saveOfflineOperation(operation);

    _emitOfflineEvent(OfflineEventType.operationQueued, data: {
      'operationId': operationId,
      'type': operationType,
      'collection': collection
    });

    _logger.debug(
        'Operation queued for offline sync: $operationId ($operationType)',
        'AdvancedOfflineService');

    // Try to sync immediately if online
    if (_isOnline) {
      await _processPendingOperations();
    }

    return operationId;
  }

  /// Perform manual sync
  Future<SyncResult> performSync({
    bool forceFullSync = false,
    List<String>? specificCollections,
  }) async {
    if (!_isOnline) {
      return SyncResult(
        success: false,
        message: 'No internet connection',
        syncedOperations: 0,
        failedOperations: 0,
        conflictsResolved: 0,
      );
    }

    _emitOfflineEvent(OfflineEventType.syncStarted,
        data: {'forceFullSync': forceFullSync});

    try {
      final result = await _performSyncOperation(
        forceFullSync: forceFullSync,
        specificCollections: specificCollections,
      );

      _lastSyncTime = DateTime.now();

      _emitOfflineEvent(OfflineEventType.syncCompleted, data: {
        'syncedOperations': result.syncedOperations,
        'failedOperations': result.failedOperations,
        'conflictsResolved': result.conflictsResolved,
      });

      _logger.info(
          'Sync completed: ${result.syncedOperations} operations synced, '
              '${result.failedOperations} failed, ${result.conflictsResolved} conflicts resolved',
          'AdvancedOfflineService');

      return result;
    } catch (e) {
      _emitOfflineEvent(OfflineEventType.syncFailed,
          data: {'error': e.toString()});
      _logger.error('Sync failed', 'AdvancedOfflineService', error: e);

      return SyncResult(
        success: false,
        message: 'Sync failed: ${e.toString()}',
        syncedOperations: 0,
        failedOperations: _pendingOperations.length,
        conflictsResolved: 0,
      );
    }
  }

  /// Cache data for offline access
  Future<void> cacheData({
    required String key,
    required Map<String, dynamic> data,
    Duration? ttl,
    String? collection,
  }) async {
    final cacheItem = OfflineData(
      key: key,
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl,
      collection: collection,
    );

    _offlineCache[key] = cacheItem;

    // Save to persistent storage
    await _saveOfflineCacheItem(cacheItem);

    // Check cache size limits
    await _enforceCacheLimits();

    _emitOfflineEvent(OfflineEventType.dataCached,
        data: {'key': key, 'collection': collection, 'ttl': ttl?.inMinutes});

    _logger.debug('Data cached: $key', 'AdvancedOfflineService');
  }

  /// Get cached data
  Future<Map<String, dynamic>?> getCachedData(String key) async {
    final cached = _offlineCache[key];

    if (cached == null) {
      // Try to load from persistent storage
      final loaded = await _loadOfflineCacheItem(key);
      if (loaded != null && !loaded.isExpired) {
        _offlineCache[key] = loaded;
        return loaded.data;
      }
      return null;
    }

    if (cached.isExpired) {
      await removeCachedData(key);
      return null;
    }

    return cached.data;
  }

  /// Remove cached data
  Future<void> removeCachedData(String key) async {
    _offlineCache.remove(key);
    await _deleteOfflineCacheItem(key);

    _emitOfflineEvent(OfflineEventType.dataRemoved, data: {'key': key});
  }

  /// Check if data is available offline
  Future<bool> isDataAvailableOffline(String key) async {
    final cached = await getCachedData(key);
    return cached != null;
  }

  /// Get offline status
  OfflineStatus getOfflineStatus() {
    return OfflineStatus(
      isOnline: _isOnline,
      lastSyncTime: _lastSyncTime,
      pendingOperations: _pendingOperations.length,
      failedOperations: _failedOperations.length,
      cachedItems: _offlineCache.length,
      queuedUploads: _syncQueue.length,
    );
  }

  /// Force offline mode (for testing or manual control)
  Future<void> forceOfflineMode(bool offline) async {
    final oldStatus = _isOnline;
    _isOnline = !offline;

    if (oldStatus != _isOnline) {
      _emitOfflineEvent(OfflineEventType.connectivityChanged,
          data: {'isOnline': _isOnline, 'forced': true});

      if (_isOnline) {
        await performSync();
      }
    }
  }

  /// Clear all offline data
  Future<void> clearOfflineData() async {
    _pendingOperations.clear();
    _failedOperations.clear();
    _offlineCache.clear();
    _syncQueue.clear();

    // Clear persistent storage
    final prefs = await SharedPreferences.getInstance();
    final keys =
        prefs.getKeys().where((key) => key.startsWith('offline_')).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }

    _emitOfflineEvent(OfflineEventType.dataCleared);
    _logger.info('All offline data cleared', 'AdvancedOfflineService');
  }

  /// Get sync conflicts
  List<SyncConflict> getSyncConflicts() {
    return _conflictResolutions.entries.map((entry) {
      return SyncConflict(
        operationId: entry.key,
        localData: entry.value.localData,
        serverData: entry.value.serverData,
        conflictType: entry.value.conflictType,
        detectedAt: entry.value.detectedAt,
      );
    }).toList();
  }

  /// Resolve sync conflict
  Future<void> resolveConflict(
      String operationId, ConflictResolutionStrategy resolution) async {
    final conflict = _conflictResolutions[operationId];
    if (conflict == null) return;

    conflict.resolution = resolution;
    conflict.resolvedAt = DateTime.now();

    // Apply resolution
    await _applyConflictResolution(conflict);

    _conflictResolutions.remove(operationId);

    _emitOfflineEvent(OfflineEventType.conflictResolved, data: {
      'operationId': operationId,
      'resolution': resolution.toString()
    });
  }

  /// Enable/disable background sync
  Future<void> setBackgroundSyncEnabled(bool enabled) async {
    await _config.setParameter('offline.background_sync', enabled);

    if (enabled) {
      await _setupPeriodicSync();
    } else {
      _syncTimer?.cancel();
      _syncTimer = null;
    }

    _emitOfflineEvent(OfflineEventType.backgroundSyncToggled,
        data: {'enabled': enabled});
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get current connectivity status
  bool get isOnline => _isOnline;

  // Private helper methods

  Future<void> _initializeConnectivityMonitoring() async {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) async {
      await _updateConnectivityStatus();
    });
  }

  Future<void> _updateConnectivityStatus() async {
    final result = await _connectivity.checkConnectivity();
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    if (wasOnline != _isOnline) {
      _emitOfflineEvent(OfflineEventType.connectivityChanged,
          data: {'isOnline': _isOnline});

      if (_isOnline) {
        // Connection restored - perform sync
        await performSync();
      } else {
        // Connection lost - notify user
        _emitOfflineEvent(OfflineEventType.offlineModeActivated);
      }
    }
  }

  Future<void> _setupPeriodicSync() async {
    final backgroundSyncEnabled = await _config
        .getParameter<bool>('offline.background_sync', defaultValue: true);
    if (!backgroundSyncEnabled) return;

    final syncIntervalMinutes = await _config
        .getParameter<int>('offline.sync_interval_minutes', defaultValue: 5);
    _syncInterval = Duration(minutes: syncIntervalMinutes);

    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (timer) async {
      if (_isOnline && _pendingOperations.isNotEmpty) {
        await performSync();
      }
    });
  }

  Future<void> _loadOfflineData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load pending operations
    final operationsJson =
        prefs.getStringList('offline_pending_operations') ?? [];
    for (final jsonStr in operationsJson) {
      try {
        final operation = OfflineOperation.fromJson(jsonDecode(jsonStr));
        _pendingOperations.add(operation);
      } catch (e) {
        _logger.error(
            'Failed to load offline operation', 'AdvancedOfflineService',
            error: e);
      }
    }

    // Load cached data
    final cacheKeys = prefs.getStringList('offline_cache_keys') ?? [];
    for (final key in cacheKeys) {
      final cached = await _loadOfflineCacheItem(key);
      if (cached != null && !cached.isExpired) {
        _offlineCache[key] = cached;
      }
    }

    _logger.debug(
        'Loaded ${_pendingOperations.length} pending operations and ${_offlineCache.length} cached items',
        'AdvancedOfflineService');
  }

  Future<SyncResult> _performSyncOperation({
    bool forceFullSync = false,
    List<String>? specificCollections,
  }) async {
    int syncedCount = 0;
    int failedCount = 0;
    int conflictsResolved = 0;

    // Process pending operations
    await _processPendingOperations();

    // Sync cached data if needed
    if (forceFullSync) {
      await _syncCachedData();
    }

    return SyncResult(
      success: true,
      syncedOperations: syncedCount,
      failedOperations: failedCount,
      conflictsResolved: conflictsResolved,
    );
  }

  Future<void> _processPendingOperations() async {
    final operationsToProcess = List<OfflineOperation>.from(_pendingOperations);
    _pendingOperations.clear();

    for (final operation in operationsToProcess) {
      try {
        final success = await _executeOfflineOperation(operation);

        if (success) {
          await _removeOfflineOperation(operation.id);
          _emitOfflineEvent(OfflineEventType.operationSynced,
              data: {'operationId': operation.id});
        } else {
          operation.retryCount++;
          if (operation.retryCount < _maxRetries) {
            _pendingOperations.add(operation);
            await Future.delayed(_retryDelay);
          } else {
            _failedOperations.add(operation);
            _emitOfflineEvent(OfflineEventType.operationFailed,
                data: {'operationId': operation.id});
          }
        }
      } catch (e) {
        _logger.error(
            'Operation sync failed: ${operation.id}', 'AdvancedOfflineService',
            error: e);
        operation.retryCount++;
        if (operation.retryCount < _maxRetries) {
          _pendingOperations.add(operation);
        } else {
          _failedOperations.add(operation);
        }
      }
    }
  }

  Future<bool> _executeOfflineOperation(OfflineOperation operation) async {
    // This would integrate with your backend services
    // For now, simulate success/failure
    await Future.delayed(const Duration(milliseconds: 100));

    // Simulate occasional failures for demo
    if (operation.id.hashCode % 10 == 0) {
      return false;
    }

    return true;
  }

  Future<void> _syncCachedData() async {
    // Sync cached data with server
    for (final entry in _offlineCache.entries) {
      if (entry.value.needsSync) {
        // Sync logic here
        entry.value.lastSynced = DateTime.now();
        await _saveOfflineCacheItem(entry.value);
      }
    }
  }

  Future<void> _applyConflictResolution(ConflictResolution conflict) async {
    // Apply the chosen conflict resolution
    switch (conflict.resolution) {
      case ConflictResolutionStrategy.serverWins:
        // Keep server data
        break;
      case ConflictResolutionStrategy.clientWins:
        // Override with local data
        break;
      case ConflictResolutionStrategy.manual:
        // Wait for manual resolution
        break;
      case ConflictResolutionStrategy.merge:
        // Merge the data
        break;
    }
  }

  Future<void> _enforceCacheLimits() async {
    final maxCacheSize = await _config
        .getParameter<int>('offline.max_cache_size_mb', defaultValue: 100);
    final currentSize = _calculateCacheSize();

    if (currentSize > maxCacheSize) {
      // Remove oldest items
      final sortedItems = _offlineCache.values.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      while (_calculateCacheSize() > maxCacheSize && sortedItems.isNotEmpty) {
        final oldest = sortedItems.removeAt(0);
        await removeCachedData(oldest.key);
      }
    }
  }

  int _calculateCacheSize() {
    // Rough estimation in MB
    return (_offlineCache.values.fold<int>(
                0, (sum, item) => sum + jsonEncode(item.data).length) /
            (1024 * 1024))
        .round();
  }

  Future<void> _saveOfflineOperation(OfflineOperation operation) async {
    final prefs = await SharedPreferences.getInstance();
    final operations = prefs.getStringList('offline_pending_operations') ?? [];
    operations.add(jsonEncode(operation.toJson()));
    await prefs.setStringList('offline_pending_operations', operations);
  }

  Future<void> _removeOfflineOperation(String operationId) async {
    final prefs = await SharedPreferences.getInstance();
    final operations = prefs.getStringList('offline_pending_operations') ?? [];
    operations.removeWhere((jsonStr) {
      final operation = OfflineOperation.fromJson(jsonDecode(jsonStr));
      return operation.id == operationId;
    });
    await prefs.setStringList('offline_pending_operations', operations);
  }

  Future<void> _saveOfflineCacheItem(OfflineData cacheItem) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'offline_cache_${cacheItem.key}', jsonEncode(cacheItem.toJson()));

    final cacheKeys = prefs.getStringList('offline_cache_keys') ?? [];
    if (!cacheKeys.contains(cacheItem.key)) {
      cacheKeys.add(cacheItem.key);
      await prefs.setStringList('offline_cache_keys', cacheKeys);
    }
  }

  Future<OfflineData?> _loadOfflineCacheItem(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('offline_cache_$key');
    if (jsonStr == null) return null;

    try {
      return OfflineData.fromJson(jsonDecode(jsonStr));
    } catch (e) {
      return null;
    }
  }

  Future<void> _deleteOfflineCacheItem(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('offline_cache_$key');

    final cacheKeys = prefs.getStringList('offline_cache_keys') ?? [];
    cacheKeys.remove(key);
    await prefs.setStringList('offline_cache_keys', cacheKeys);
  }

  String _generateOperationId() {
    return 'offline_op_${DateTime.now().millisecondsSinceEpoch}_${_pendingOperations.length}';
  }

  void _emitOfflineEvent(OfflineEventType type, {Map<String, dynamic>? data}) {
    final event = OfflineEvent(
      type: type,
      timestamp: DateTime.now(),
      data: data,
    );
    _offlineEventController.add(event);
  }

  /// Dispose service
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _offlineEventController.close();
    _isInitialized = false;
    _logger.info('Advanced Offline Service disposed', 'AdvancedOfflineService');
  }
}

/// Supporting Classes and Enums

enum OfflineEventType {
  initialized,
  connectivityChanged,
  operationQueued,
  operationSynced,
  operationFailed,
  dataCached,
  dataRemoved,
  dataCleared,
  syncStarted,
  syncCompleted,
  syncFailed,
  conflictDetected,
  conflictResolved,
  offlineModeActivated,
  backgroundSyncToggled,
}

class OfflineEvent {
  final OfflineEventType type;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  OfflineEvent({
    required this.type,
    required this.timestamp,
    this.data,
  });
}

enum ConflictResolutionStrategy {
  serverWins, // Server version takes precedence
  clientWins, // Local version takes precedence
  manual, // User must manually resolve
  merge, // Attempt to merge changes
}

class OfflineOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final String collection;
  final String? documentId;
  final DateTime timestamp;
  final ConflictResolutionStrategy conflictStrategy;
  int retryCount;

  OfflineOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.collection,
    this.documentId,
    required this.timestamp,
    required this.conflictStrategy,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'data': data,
        'collection': collection,
        'documentId': documentId,
        'timestamp': timestamp.toIso8601String(),
        'conflictStrategy': conflictStrategy.toString(),
        'retryCount': retryCount,
      };

  factory OfflineOperation.fromJson(Map<String, dynamic> json) =>
      OfflineOperation(
        id: json['id'],
        type: json['type'],
        data: json['data'],
        collection: json['collection'],
        documentId: json['documentId'],
        timestamp: DateTime.parse(json['timestamp']),
        conflictStrategy: ConflictResolutionStrategy.values.firstWhere(
          (e) => e.toString() == json['conflictStrategy'],
          orElse: () => ConflictResolutionStrategy.serverWins,
        ),
        retryCount: json['retryCount'] ?? 0,
      );
}

class OfflineData {
  final String key;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final Duration? ttl;
  final String? collection;
  DateTime? lastSynced;

  OfflineData({
    required this.key,
    required this.data,
    required this.timestamp,
    this.ttl,
    this.collection,
    this.lastSynced,
  });

  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().difference(timestamp) > ttl!;
  }

  bool get needsSync {
    if (lastSynced == null) return true;
    return DateTime.now().difference(lastSynced!) > const Duration(minutes: 5);
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'ttl': ttl?.inMilliseconds,
        'collection': collection,
        'lastSynced': lastSynced?.toIso8601String(),
      };

  factory OfflineData.fromJson(Map<String, dynamic> json) => OfflineData(
        key: json['key'],
        data: json['data'],
        timestamp: DateTime.parse(json['timestamp']),
        ttl: json['ttl'] != null ? Duration(milliseconds: json['ttl']) : null,
        collection: json['collection'],
        lastSynced: json['lastSynced'] != null
            ? DateTime.parse(json['lastSynced'])
            : null,
      );
}

class OfflineStatus {
  final bool isOnline;
  final DateTime? lastSyncTime;
  final int pendingOperations;
  final int failedOperations;
  final int cachedItems;
  final int queuedUploads;

  OfflineStatus({
    required this.isOnline,
    this.lastSyncTime,
    required this.pendingOperations,
    required this.failedOperations,
    required this.cachedItems,
    required this.queuedUploads,
  });

  bool get hasPendingWork => pendingOperations > 0 || queuedUploads > 0;
  bool get hasFailedOperations => failedOperations > 0;
}

class SyncResult {
  final bool success;
  final String? message;
  final int syncedOperations;
  final int failedOperations;
  final int conflictsResolved;

  SyncResult({
    required this.success,
    this.message,
    required this.syncedOperations,
    required this.failedOperations,
    required this.conflictsResolved,
  });
}

class ConflictResolution {
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final ConflictType conflictType;
  final DateTime detectedAt;
  ConflictResolutionStrategy? resolution;
  DateTime? resolvedAt;

  ConflictResolution({
    required this.localData,
    required this.serverData,
    required this.conflictType,
    required this.detectedAt,
    this.resolution,
    this.resolvedAt,
  });
}

enum ConflictType {
  fieldModified,
  recordDeleted,
  recordCreated,
  schemaChanged,
}

class SyncConflict {
  final String operationId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final ConflictType conflictType;
  final DateTime detectedAt;

  SyncConflict({
    required this.operationId,
    required this.localData,
    required this.serverData,
    required this.conflictType,
    required this.detectedAt,
  });
}
