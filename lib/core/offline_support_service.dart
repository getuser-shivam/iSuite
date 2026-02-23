import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'advanced_security_manager.dart';
import 'performance_optimization_service.dart';

/// Enhanced Offline Support Service
/// Provides comprehensive offline functionality across all app features
class OfflineSupportService {
  static final OfflineSupportService _instance = OfflineSupportService._internal();
  factory OfflineSupportService() => _instance;
  OfflineSupportService._internal();

  final Connectivity _connectivity = Connectivity();
  final AdvancedSecurityManager _securityManager = AdvancedSecurityManager();
  final PerformanceOptimizationService _performanceService = PerformanceOptimizationService();

  Database? _offlineDatabase;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  final StreamController<OfflineEvent> _eventController = StreamController.broadcast();
  final Map<String, OfflineOperation> _pendingOperations = {};
  final Map<String, CachedData> _offlineCache = {};

  Stream<OfflineEvent> get offlineEvents => _eventController.stream;

  bool _isInitialized = false;
  bool _isOnline = true;
  DateTime? _lastOnlineTime;

  // Configuration
  static const String _databaseName = 'offline_data.db';
  static const Duration _syncRetryInterval = Duration(minutes: 5);
  static const Duration _cacheExpiration = Duration(hours: 24);
  static const int _maxPendingOperations = 1000;
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB

  Timer? _syncTimer;
  Timer? _cacheCleanupTimer;

  /// Initialize offline support service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize database
      await _initializeDatabase();

      // Start connectivity monitoring
      await _startConnectivityMonitoring();

      // Load pending operations
      await _loadPendingOperations();

      // Load offline cache
      await _loadOfflineCache();

      // Start background sync
      _startBackgroundSync();

      // Start cache cleanup
      _startCacheCleanup();

      _isInitialized = true;
      _emitEvent(OfflineEventType.serviceInitialized);

    } catch (e) {
      _emitEvent(OfflineEventType.initializationFailed, error: e.toString());
      rethrow;
    }
  }

  /// Check if device is online
  bool get isOnline => _isOnline;

  /// Get last online time
  DateTime? get lastOnlineTime => _lastOnlineTime;

  /// Queue operation for offline execution
  Future<String> queueOperation(
    String operationType,
    Map<String, dynamic> data, {
    String? id,
    Priority priority = Priority.normal,
    Duration? ttl,
  }) async {
    final operationId = id ?? '${operationType}_${DateTime.now().millisecondsSinceEpoch}';

    final operation = OfflineOperation(
      id: operationId,
      type: operationType,
      data: data,
      priority: priority,
      createdAt: DateTime.now(),
      ttl: ttl,
      retryCount: 0,
    );

    _pendingOperations[operationId] = operation;
    await _saveOperationToDatabase(operation);

    _emitEvent(OfflineEventType.operationQueued, operationId: operationId);

    // Try to execute immediately if online
    if (_isOnline) {
      await _executeOperation(operationId);
    }

    return operationId;
  }

  /// Execute pending operations when coming back online
  Future<void> syncPendingOperations() async {
    if (!_isOnline || _pendingOperations.isEmpty) return;

    _emitEvent(OfflineEventType.syncStarted, details: '${_pendingOperations.length} operations');

    final operations = _pendingOperations.values.toList()
      ..sort((a, b) => b.priority.index.compareTo(a.priority.index)); // High priority first

    int successCount = 0;
    int failureCount = 0;

    for (final operation in operations) {
      try {
        await _executeOperation(operation.id);
        successCount++;
      } catch (e) {
        operation.retryCount++;
        operation.lastError = e.toString();

        if (operation.retryCount >= 3) {
          _emitEvent(OfflineEventType.operationFailed, operationId: operation.id, error: e.toString());
          failureCount++;
        } else {
          await _saveOperationToDatabase(operation);
        }
      }
    }

    _emitEvent(OfflineEventType.syncCompleted,
      details: 'Success: $successCount, Failed: $failureCount');
  }

  /// Cache data for offline access
  Future<void> cacheData(
    String key,
    dynamic data, {
    Duration? ttl,
    Map<String, String>? metadata,
  }) async {
    final cacheEntry = CachedData(
      key: key,
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl ?? _cacheExpiration,
      metadata: metadata,
    );

    _offlineCache[key] = cacheEntry;
    await _saveCacheToDatabase(cacheEntry);

    // Check cache size limit
    if (_getCacheSize() > _maxCacheSize) {
      await _cleanupCache();
    }

    _emitEvent(OfflineEventType.dataCached, details: key);
  }

  /// Retrieve cached data
  dynamic getCachedData(String key) {
    final cached = _offlineCache[key];

    if (cached == null || cached.isExpired) {
      if (cached?.isExpired ?? false) {
        _offlineCache.remove(key);
      }
      return null;
    }

    cached.lastAccessed = DateTime.now();
    cached.accessCount++;
    _updateCacheAccess(key);

    return cached.data;
  }

  /// Store data offline with conflict resolution
  Future<void> storeOfflineData(
    String collection,
    String id,
    Map<String, dynamic> data, {
    ConflictResolutionStrategy conflictStrategy = ConflictResolutionStrategy.lastWriteWins,
  }) async {
    final key = '${collection}_$id';

    // Check for existing data
    final existingData = getCachedData(key) as Map<String, dynamic>?;

    if (existingData != null) {
      // Resolve conflicts
      final resolvedData = await _resolveConflict(
        existingData,
        data,
        conflictStrategy
      );
      data = resolvedData;
    }

    // Add metadata
    data['_offline'] = true;
    data['_lastModified'] = DateTime.now().toIso8601String();
    data['_version'] = (existingData?['_version'] as int? ?? 0) + 1;

    await cacheData(key, data, metadata: {'collection': collection, 'id': id});
    await queueOperation('sync_data', {
      'collection': collection,
      'id': id,
      'data': data,
    });
  }

  /// Retrieve offline data
  Map<String, dynamic>? getOfflineData(String collection, String id) {
    final key = '${collection}_$id';
    return getCachedData(key) as Map<String, dynamic>?;
  }

  /// Get all offline data for a collection
  List<Map<String, dynamic>> getOfflineCollection(String collection) {
    return _offlineCache.values
        .where((cache) => cache.metadata?['collection'] == collection)
        .where((cache) => !cache.isExpired)
        .map((cache) => cache.data as Map<String, dynamic>)
        .toList();
  }

  /// Enable offline mode manually
  Future<void> enableOfflineMode() async {
    _isOnline = false;
    _emitEvent(OfflineEventType.offlineModeEnabled);
  }

  /// Disable offline mode manually
  Future<void> disableOfflineMode() async {
    _isOnline = true;
    _lastOnlineTime = DateTime.now();
    _emitEvent(OfflineEventType.offlineModeDisabled);

    // Start sync when coming back online
    await syncPendingOperations();
  }

  /// Get offline statistics
  OfflineStatistics getOfflineStatistics() {
    final pendingOperations = _pendingOperations.length;
    final cachedItems = _offlineCache.length;
    final cacheSize = _getCacheSize();

    final operationsByType = <String, int>{};
    for (final op in _pendingOperations.values) {
      operationsByType[op.type] = (operationsByType[op.type] ?? 0) + 1;
    }

    final collections = <String>{};
    for (final cache in _offlineCache.values) {
      if (cache.metadata?['collection'] != null) {
        collections.add(cache.metadata!['collection']!);
      }
    }

    return OfflineStatistics(
      isOnline: _isOnline,
      pendingOperations: pendingOperations,
      cachedItems: cachedItems,
      cacheSizeBytes: cacheSize,
      lastOnlineTime: _lastOnlineTime,
      operationsByType: operationsByType,
      offlineCollections: collections.toList(),
    );
  }

  /// Clear all offline data (use with caution)
  Future<void> clearOfflineData() async {
    _pendingOperations.clear();
    _offlineCache.clear();

    await _clearDatabase();

    _emitEvent(OfflineEventType.offlineDataCleared);
  }

  /// Export offline data for backup
  Future<String> exportOfflineData() async {
    final exportData = {
      'pendingOperations': _pendingOperations.values.map((op) => op.toJson()).toList(),
      'cachedData': _offlineCache.values.map((cache) => cache.toJson()).toList(),
      'metadata': {
        'exportedAt': DateTime.now().toIso8601String(),
        'isOnline': _isOnline,
        'lastOnlineTime': _lastOnlineTime?.toIso8601String(),
      },
    };

    return json.encode(exportData);
  }

  /// Import offline data from backup
  Future<void> importOfflineData(String jsonData) async {
    try {
      final importData = json.decode(jsonData) as Map<String, dynamic>;

      // Import pending operations
      final operations = importData['pendingOperations'] as List?;
      if (operations != null) {
        for (final opData in operations) {
          final operation = OfflineOperation.fromJson(opData);
          _pendingOperations[operation.id] = operation;
          await _saveOperationToDatabase(operation);
        }
      }

      // Import cached data
      final cachedData = importData['cachedData'] as List?;
      if (cachedData != null) {
        for (final cacheData in cachedData) {
          final cache = CachedData.fromJson(cacheData);
          if (!cache.isExpired) {
            _offlineCache[cache.key] = cache;
            await _saveCacheToDatabase(cache);
          }
        }
      }

      _emitEvent(OfflineEventType.offlineDataImported);

    } catch (e) {
      _emitEvent(OfflineEventType.importFailed, error: e.toString());
      rethrow;
    }
  }

  // Private helper methods

  Future<void> _initializeDatabase() async {
    final dbPath = await _getDatabasePath();
    _offlineDatabase = await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createDatabaseTables,
    );
  }

  Future<String> _getDatabasePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_databaseName';
  }

  Future<void> _createDatabaseTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pending_operations (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        data TEXT NOT NULL,
        priority INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        ttl TEXT,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE offline_cache (
        key TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        ttl TEXT NOT NULL,
        metadata TEXT,
        access_count INTEGER DEFAULT 0,
        last_accessed TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_operations_type ON pending_operations(type)
    ''');

    await db.execute('''
      CREATE INDEX idx_cache_timestamp ON offline_cache(timestamp)
    ''');
  }

  Future<void> _startConnectivityMonitoring() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _updateConnectivityStatus(result);

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectivityStatus,
    );
  }

  void _updateConnectivityStatus(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    if (_isOnline && !wasOnline) {
      // Came back online
      _lastOnlineTime = DateTime.now();
      _emitEvent(OfflineEventType.connectionRestored);
      syncPendingOperations();
    } else if (!_isOnline && wasOnline) {
      // Went offline
      _emitEvent(OfflineEventType.connectionLost);
    }
  }

  Future<void> _startBackgroundSync() async {
    _syncTimer = Timer.periodic(_syncRetryInterval, (timer) async {
      if (_isOnline && _pendingOperations.isNotEmpty) {
        await syncPendingOperations();
      }
    });
  }

  Future<void> _startCacheCleanup() async {
    _cacheCleanupTimer = Timer.periodic(Duration(hours: 1), (timer) async {
      await _cleanupExpiredCache();
    });
  }

  Future<void> _loadPendingOperations() async {
    if (_offlineDatabase == null) return;

    final operations = await _offlineDatabase!.query('pending_operations');
    for (final op in operations) {
      final operation = OfflineOperation.fromJson(op);
      if (!operation.isExpired) {
        _pendingOperations[operation.id] = operation;
      }
    }
  }

  Future<void> _loadOfflineCache() async {
    if (_offlineDatabase == null) return;

    final cacheEntries = await _offlineDatabase!.query('offline_cache');
    for (final entry in cacheEntries) {
      final cache = CachedData.fromJson(entry);
      if (!cache.isExpired) {
        _offlineCache[cache.key] = cache;
      }
    }
  }

  Future<void> _saveOperationToDatabase(OfflineOperation operation) async {
    if (_offlineDatabase == null) return;

    await _offlineDatabase!.insert(
      'pending_operations',
      operation.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _saveCacheToDatabase(CachedData cache) async {
    if (_offlineDatabase == null) return;

    await _offlineDatabase!.insert(
      'offline_cache',
      cache.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _executeOperation(String operationId) async {
    final operation = _pendingOperations[operationId];
    if (operation == null) return;

    // This would be implemented based on operation type
    // For now, just simulate execution
    await Future.delayed(Duration(milliseconds: 100));

    // Remove from pending operations
    _pendingOperations.remove(operationId);
    await _offlineDatabase?.delete(
      'pending_operations',
      where: 'id = ?',
      whereArgs: [operationId],
    );

    _emitEvent(OfflineEventType.operationExecuted, operationId: operationId);
  }

  Future<Map<String, dynamic>> _resolveConflict(
    Map<String, dynamic> existing,
    Map<String, dynamic> incoming,
    ConflictResolutionStrategy strategy,
  ) async {
    switch (strategy) {
      case ConflictResolutionStrategy.lastWriteWins:
        final existingTime = DateTime.parse(existing['_lastModified'] ?? existing['timestamp'] ?? '1970-01-01');
        final incomingTime = DateTime.parse(incoming['_lastModified'] ?? incoming['timestamp'] ?? '1970-01-01');
        return incomingTime.isAfter(existingTime) ? incoming : existing;

      case ConflictResolutionStrategy.merge:
        // Simple merge - incoming overwrites existing
        return {...existing, ...incoming};

      case ConflictResolutionStrategy.manual:
        // For manual resolution, keep both versions
        return {
          ...existing,
          '_conflicts': [incoming],
        };

      default:
        return incoming;
    }
  }

  Future<void> _cleanupCache() async {
    // Remove least recently used items
    final entries = _offlineCache.values.toList()
      ..sort((a, b) {
        final aTime = a.lastAccessed ?? a.timestamp;
        final bTime = b.lastAccessed ?? b.timestamp;
        return aTime.compareTo(bTime);
      });

    final toRemove = entries.take((entries.length * 0.2).ceil()).toList();

    for (final entry in toRemove) {
      _offlineCache.remove(entry.key);
      await _offlineDatabase?.delete(
        'offline_cache',
        where: 'key = ?',
        whereArgs: [entry.key],
      );
    }

    _emitEvent(OfflineEventType.cacheCleaned, details: 'Removed ${toRemove.length} items');
  }

  Future<void> _cleanupExpiredCache() async {
    final expiredKeys = <String>[];

    for (final entry in _offlineCache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _offlineCache.remove(key);
      await _offlineDatabase?.delete(
        'offline_cache',
        where: 'key = ?',
        whereArgs: [key],
      );
    }

    if (expiredKeys.isNotEmpty) {
      _emitEvent(OfflineEventType.expiredCacheCleaned, details: 'Removed ${expiredKeys.length} expired items');
    }
  }

  int _getCacheSize() {
    int totalSize = 0;
    for (final cache in _offlineCache.values) {
      // Rough size estimation
      totalSize += json.encode(cache.data).length * 2; // UTF-16
    }
    return totalSize;
  }

  Future<void> _updateCacheAccess(String key) async {
    if (_offlineDatabase == null) return;

    await _offlineDatabase!.update(
      'offline_cache',
      {
        'access_count': (_offlineCache[key]?.accessCount ?? 0),
        'last_accessed': DateTime.now().toIso8601String(),
      },
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  Future<void> _clearDatabase() async {
    await _offlineDatabase?.delete('pending_operations');
    await _offlineDatabase?.delete('offline_cache');
  }

  void _emitEvent(OfflineEventType type, {
    String? operationId,
    String? details,
    String? error,
  }) {
    final event = OfflineEvent(
      type: type,
      timestamp: DateTime.now(),
      operationId: operationId,
      details: details,
      error: error,
    );

    _eventController.add(event);
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _cacheCleanupTimer?.cancel();
    _eventController.close();
    _offlineDatabase?.close();
  }
}

/// Offline operation data class
class OfflineOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final Priority priority;
  final DateTime createdAt;
  final Duration? ttl;
  int retryCount;
  String? lastError;

  OfflineOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.priority,
    required this.createdAt,
    this.ttl,
    this.retryCount = 0,
    this.lastError,
  });

  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().difference(createdAt) > ttl!;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'data': json.encode(data),
    'priority': priority.index,
    'created_at': createdAt.toIso8601String(),
    'ttl': ttl?.inSeconds,
    'retry_count': retryCount,
    'last_error': lastError,
  };

  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    return OfflineOperation(
      id: json['id'],
      type: json['type'],
      data: json['data'] is String ? json.decode(json['data']) : json['data'],
      priority: Priority.values[json['priority'] ?? 1],
      createdAt: DateTime.parse(json['created_at']),
      ttl: json['ttl'] != null ? Duration(seconds: json['ttl']) : null,
      retryCount: json['retry_count'] ?? 0,
      lastError: json['last_error'],
    );
  }
}

/// Cached data class
class CachedData {
  final String key;
  final dynamic data;
  final DateTime timestamp;
  final Duration ttl;
  final Map<String, String>? metadata;
  int accessCount;
  DateTime? lastAccessed;

  CachedData({
    required this.key,
    required this.data,
    required this.timestamp,
    required this.ttl,
    this.metadata,
    this.accessCount = 0,
    this.lastAccessed,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;

  Map<String, dynamic> toJson() => {
    'key': key,
    'data': json.encode(data),
    'timestamp': timestamp.toIso8601String(),
    'ttl': ttl.inSeconds,
    'metadata': metadata != null ? json.encode(metadata) : null,
    'access_count': accessCount,
    'last_accessed': lastAccessed?.toIso8601String(),
  };

  factory CachedData.fromJson(Map<String, dynamic> json) {
    return CachedData(
      key: json['key'],
      data: json.decode(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      ttl: Duration(seconds: json['ttl']),
      metadata: json['metadata'] != null ? Map<String, String>.from(json.decode(json['metadata'])) : null,
      accessCount: json['access_count'] ?? 0,
      lastAccessed: json['last_accessed'] != null ? DateTime.parse(json['last_accessed']) : null,
    );
  }
}

/// Priority levels for offline operations
enum Priority {
  low,
  normal,
  high,
  critical,
}

/// Conflict resolution strategies
enum ConflictResolutionStrategy {
  lastWriteWins,
  merge,
  manual,
}

/// Offline event types
enum OfflineEventType {
  serviceInitialized,
  initializationFailed,
  connectionLost,
  connectionRestored,
  offlineModeEnabled,
  offlineModeDisabled,
  operationQueued,
  operationExecuted,
  operationFailed,
  syncStarted,
  syncCompleted,
  dataCached,
  cacheCleaned,
  expiredCacheCleaned,
  offlineDataCleared,
  offlineDataImported,
  importFailed,
}

/// Offline event
class OfflineEvent {
  final OfflineEventType type;
  final DateTime timestamp;
  final String? operationId;
  final String? details;
  final String? error;

  OfflineEvent({
    required this.type,
    required this.timestamp,
    this.operationId,
    this.details,
    this.error,
  });
}

/// Offline statistics
class OfflineStatistics {
  final bool isOnline;
  final int pendingOperations;
  final int cachedItems;
  final int cacheSizeBytes;
  final DateTime? lastOnlineTime;
  final Map<String, int> operationsByType;
  final List<String> offlineCollections;

  OfflineStatistics({
    required this.isOnline,
    required this.pendingOperations,
    required this.cachedItems,
    required this.cacheSizeBytes,
    this.lastOnlineTime,
    required this.operationsByType,
    required this.offlineCollections,
  });

  @override
  String toString() {
    return '''
Offline Statistics:
Online: $isOnline
Pending Operations: $pendingOperations
Cached Items: $cachedItems
Cache Size: ${(cacheSizeBytes / 1024 / 1024).toStringAsFixed(2)} MB
Last Online: $lastOnlineTime
Operations by Type: $operationsByType
Offline Collections: $offlineCollections
''';
  }
}
