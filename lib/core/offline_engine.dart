import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:workmanager/workmanager.dart';

class OfflineEngine {
  static OfflineEngine? _instance;
  static OfflineEngine get instance => _instance ??= OfflineEngine._internal();
  OfflineEngine._internal();

  // Offline Storage
  late Box<OfflineData> _dataBox;
  late Box<SyncQueue> _syncQueueBox;
  late Box<ConflictRecord> _conflictBox;
  
  // Sync State
  bool _isInitialized = false;
  bool _isOnline = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _lastSyncError;
  
  // Configuration
  Duration _syncInterval = Duration(minutes: 5);
  int _maxRetryAttempts = 3;
  Duration _retryDelay = Duration(seconds: 10);
  int _maxOfflineData = 10000;
  bool _autoSync = true;
  
  // Listeners
  final Map<String, List<Function(OfflineEvent)>> _listeners = {};
  Timer? _syncTimer;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastSyncError => _lastSyncError;
  bool get autoSync => _autoSync;
  int get pendingSyncCount => _syncQueueBox.length;
  int get conflictCount => _conflictBox.length;

  /// Initialize Offline Engine
  Future<bool> initialize({
    Duration? syncInterval,
    int? maxRetryAttempts,
    Duration? retryDelay,
    bool autoSync = true,
  }) async {
    if (_isInitialized) return true;

    try {
      // Initialize Hive
      await Hive.initFlutter();
      
      // Register adapters
      Hive.registerAdapter(OfflineDataAdapter());
      Hive.registerAdapter(SyncQueueAdapter());
      Hive.registerAdapter(ConflictRecordAdapter());
      
      // Open boxes
      _dataBox = await Hive.openBox<OfflineData>('offline_data');
      _syncQueueBox = await Hive.openBox<SyncQueue>('sync_queue');
      _conflictBox = await Hive.openBox<ConflictRecord>('conflicts');
      
      // Set configuration
      _syncInterval = syncInterval ?? _syncInterval;
      _maxRetryAttempts = maxRetryAttempts ?? _maxRetryAttempts;
      _retryDelay = retryDelay ?? _retryDelay;
      _autoSync = autoSync;
      
      // Check connectivity
      await _checkConnectivity();
      
      // Start connectivity monitoring
      _startConnectivityMonitoring();
      
      // Start auto-sync if enabled
      if (_autoSync && _isOnline) {
        _startAutoSync();
      }
      
      // Initialize background sync
      await _initializeBackgroundSync();
      
      _isInitialized = true;
      await _logOfflineEvent(OfflineEventType.initialized, {
        'autoSync': _autoSync,
        'syncInterval': _syncInterval.inSeconds,
      });
      
      return true;
    } catch (e) {
      await _logOfflineEvent(OfflineEventType.initializationFailed, {'error': e.toString()});
      return false;
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _isOnline = results != ConnectivityResult.none;
      
      if (_isOnline && !_isSyncing) {
        await _startSync();
      }
    } catch (e) {
      _isOnline = false;
    }
  }

  void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (!wasOnline && _isOnline) {
        // Came back online
        _logOfflineEvent(OfflineEventType.connected, {'result': result.name});
        if (_autoSync) {
          _startSync();
        }
      } else if (wasOnline && !_isOnline) {
        // Went offline
        _logOfflineEvent(OfflineEventType.disconnected, {'result': result.name});
      }
    });
  }

  void _startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (_isOnline && !_isSyncing) {
        _startSync();
      }
    });
  }

  Future<void> _initializeBackgroundSync() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher: _backgroundSyncDispatcher,
      );
      
      // Schedule periodic background sync
      await Workmanager().registerPeriodicTask(
        'offline_sync_task',
        'offlineSyncTask',
        frequency: Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    } catch (e) {
      await _logOfflineEvent(OfflineEventType.backgroundSyncFailed, {'error': e.toString()});
    }
  }

  /// Store data offline
  Future<void> storeOfflineData({
    required String type,
    required String id,
    required Map<String, dynamic> data,
    String? parentId,
    DateTime? timestamp,
    bool requiresSync = true,
  }) async {
    if (!_isInitialized) return;

    try {
      final offlineData = OfflineData(
        id: id,
        type: type,
        data: data,
        parentId: parentId,
        timestamp: timestamp ?? DateTime.now(),
        requiresSync: requiresSync,
        synced: !requiresSync,
        version: 1,
      );

      await _dataBox.put(id, offlineData);
      
      // Add to sync queue if requires sync
      if (requiresSync && _isOnline) {
        await _addToSyncQueue(offlineData);
      }
      
      // Limit offline data size
      await _limitOfflineData();
      
      await _logOfflineEvent(OfflineEventType.dataStored, {
        'type': type,
        'id': id,
        'requiresSync': requiresSync,
      });
    } catch (e) {
      await _logOfflineEvent(OfflineEventType.dataStorageFailed, {
        'type': type,
        'id': id,
        'error': e.toString(),
      });
    }
  }

  /// Get offline data
  Future<OfflineData?> getOfflineData(String id) async {
    if (!_isInitialized) return null;
    
    try {
      return _dataBox.get(id);
    } catch (e) {
      await _logOfflineEvent(OfflineEventType.dataRetrievalFailed, {
        'id': id,
        'error': e.toString(),
      });
      return null;
    }
  }

  /// Get all offline data by type
  Future<List<OfflineData>> getOfflineDataByType(String type) async {
    if (!_isInitialized) return [];
    
    try {
      return _dataBox.values.where((data) => data.type == type).toList();
    } catch (e) {
      await _logOfflineEvent(OfflineEventType.dataRetrievalFailed, {
        'type': type,
        'error': e.toString(),
      });
      return [];
    }
  }

  /// Update offline data
  Future<void> updateOfflineData({
    required String id,
    required Map<String, dynamic> data,
    bool requiresSync = true,
  }) async {
    if (!_isInitialized) return;

    try {
      final existing = _dataBox.get(id);
      if (existing == null) return;

      final updated = existing.copyWith(
        data: data,
        timestamp: DateTime.now(),
        requiresSync: requiresSync,
        synced: !requiresSync,
        version: existing.version + 1,
      );

      await _dataBox.put(id, updated);
      
      if (requiresSync && _isOnline) {
        await _addToSyncQueue(updated);
      }
      
      await _logOfflineEvent(OfflineEventType.dataUpdated, {
        'id': id,
        'requiresSync': requiresSync,
      });
    } catch (e) {
      await _logOfflineEvent(OfflineEventType.dataUpdateFailed, {
        'id': id,
        'error': e.toString(),
      });
    }
  }

  /// Delete offline data
  Future<void> deleteOfflineData(String id) async {
    if (!_isInitialized) return;

    try {
      final existing = _dataBox.get(id);
      if (existing == null) return;

      await _dataBox.delete(id);
      
      // Add to sync queue for deletion
      if (existing.requiresSync && _isOnline) {
        await _addToSyncQueue(existing.copyWith(action: SyncAction.delete));
      }
      
      await _logOfflineEvent(OfflineEventType.dataDeleted, {'id': id});
    } catch (e) {
      await _logOfflineEvent(OfflineEventType.dataDeletionFailed, {
        'id': id,
        'error': e.toString(),
      });
    }
  }

  /// Add to sync queue
  Future<void> _addToSyncQueue(OfflineData data) async {
    try {
      final syncItem = SyncQueue(
        id: _generateId(),
        dataId: data.id,
        type: data.type,
        action: data.action ?? SyncAction.create,
        data: data.data,
        timestamp: DateTime.now(),
        attempts: 0,
        lastAttempt: DateTime.now(),
      );

      await _syncQueueBox.put(syncItem.id, syncItem);
      
      await _logOfflineEvent(OfflineEventType.addedToSyncQueue, {
        'dataId': data.id,
        'action': data.action?.name,
      });
    } catch (e) {
      await _logOfflineEvent(OfflineEventType.syncQueueFailed, {
        'dataId': data.id,
        'error': e.toString(),
      });
    }
  }

  /// Start sync process
  Future<void> _startSync() async {
    if (_isSyncing || !_isOnline) return;

    _isSyncing = true;
    
    try {
      final queueItems = _syncQueueBox.values.toList();
      
      for (final item in queueItems) {
        if (!_isOnline) break;
        
        final success = await _syncItem(item);
        
        if (success) {
          await _syncQueueBox.delete(item.id);
        } else if (item.attempts >= _maxRetryAttempts) {
          // Move to conflicts
          await _moveToConflicts(item);
          await _syncQueueBox.delete(item.id);
        } else {
          // Update retry info
          final updated = item.copyWith(
            attempts: item.attempts + 1,
            lastAttempt: DateTime.now(),
          );
          await _syncQueueBox.put(item.id, updated);
          
          // Wait before retry
          await Future.delayed(_retryDelay);
        }
      }
      
      _lastSyncTime = DateTime.now();
      _lastSyncError = null;
      
      await _logOfflineEvent(OfflineEventType.syncCompleted, {
        'itemsProcessed': queueItems.length,
        'timestamp': _lastSyncTime!.toIso8601String(),
      });
    } catch (e) {
      _lastSyncError = e.toString();
      await _logOfflineEvent(OfflineEventType.syncFailed, {'error': e.toString()});
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync individual item
  Future<bool> _syncItem(SyncQueue item) async {
    try {
      // Simulate sync with server
      // In a real implementation, this would make HTTP requests
      
      switch (item.action) {
        case SyncAction.create:
          return await _syncCreate(item);
        case SyncAction.update:
          return await _syncUpdate(item);
        case SyncAction.delete:
          return await _syncDelete(item);
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> _syncCreate(SyncQueue item) async {
    // Simulate server creation
    await Future.delayed(Duration(milliseconds: 100));
    
    // Mark data as synced
    final data = _dataBox.get(item.dataId);
    if (data != null) {
      final synced = data.copyWith(synced: true);
      await _dataBox.put(item.dataId, synced);
    }
    
    return true;
  }

  Future<bool> _syncUpdate(SyncQueue item) async {
    // Simulate server update
    await Future.delayed(Duration(milliseconds: 100));
    
    // Mark data as synced
    final data = _dataBox.get(item.dataId);
    if (data != null) {
      final synced = data.copyWith(synced: true);
      await _dataBox.put(item.dataId, synced);
    }
    
    return true;
  }

  Future<bool> _syncDelete(SyncQueue item) async {
    // Simulate server deletion
    await Future.delayed(Duration(milliseconds: 100));
    
    return true;
  }

  /// Move item to conflicts
  Future<void> _moveToConflicts(SyncQueue item) async {
    try {
      final conflict = ConflictRecord(
        id: _generateId(),
        dataId: item.dataId,
        type: item.type,
        action: item.action,
        data: item.data,
        conflictReason: 'Max retry attempts exceeded',
        timestamp: DateTime.now(),
        resolved: false,
      );

      await _conflictBox.put(conflict.id, conflict);
      
      await _logOfflineEvent(OfflineEventType.conflictDetected, {
        'dataId': item.dataId,
        'reason': conflict.conflictReason,
      });
    } catch (e) {
      await _logOfflineEvent(OfflineEventType.conflictHandlingFailed, {
        'dataId': item.dataId,
        'error': e.toString(),
      });
    }
  }

  /// Resolve conflict
  Future<bool> resolveConflict(String conflictId, ConflictResolution resolution) async {
    try {
      final conflict = _conflictBox.get(conflictId);
      if (conflict == null) return false;

      switch (resolution) {
        case ConflictResolution.useLocal:
          // Keep local version, mark as synced
          final data = _dataBox.get(conflict.dataId);
          if (data != null) {
            final synced = data.copyWith(synced: true);
            await _dataBox.put(conflict.dataId, synced);
          }
          break;
          
        case ConflictResolution.useRemote:
          // Discard local version
          await _dataBox.delete(conflict.dataId);
          break;
          
        case ConflictResolution.merge:
          // Merge versions (implementation depends on data type)
          await _mergeConflictData(conflict);
          break;
      }

      // Remove conflict record
      await _conflictBox.delete(conflictId);
      
      await _logOfflineEvent(OfflineEventType.conflictResolved, {
        'conflictId': conflictId,
        'resolution': resolution.name,
      });
      
      return true;
    } catch (e) {
      await _logOfflineEvent(OfflineEventType.conflictResolutionFailed, {
        'conflictId': conflictId,
        'error': e.toString(),
      });
      return false;
    }
  }

  Future<void> _mergeConflictData(ConflictRecord conflict) async {
    // Implement merge logic based on data type
    // This is a placeholder implementation
    final data = _dataBox.get(conflict.dataId);
    if (data != null) {
      final merged = data.copyWith(
        timestamp: DateTime.now(),
        version: data.version + 1,
        synced: true,
      );
      await _dataBox.put(conflict.dataId, merged);
    }
  }

  /// Limit offline data size
  Future<void> _limitOfflineData() async {
    try {
      final count = _dataBox.length;
      if (count <= _maxOfflineData) return;

      // Remove oldest data
      final allData = _dataBox.values.toList();
      allData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      final toRemove = allData.take(count - _maxOfflineData);
      for (final data in toRemove) {
        await _dataBox.delete(data.id);
      }
      
      await _logOfflineEvent(OfflineEventType.dataCleanup, {
        'removedCount': toRemove.length,
        'remainingCount': _dataBox.length,
      });
    } catch (e) {
      await _logOfflineEvent(OfflineEventType.cleanupFailed, {'error': e.toString()});
    }
  }

  /// Force sync
  Future<void> forceSync() async {
    if (!_isOnline) {
      await _logOfflineEvent(OfflineEventType.forceSyncFailed, {'reason': 'Offline'});
      return;
    }

    await _startSync();
  }

  /// Clear all offline data
  Future<void> clearAllData() async {
    try {
      await _dataBox.clear();
      await _syncQueueBox.clear();
      await _conflictBox.clear();
      
      await _logOfflineEvent(OfflineEventType.dataCleared, {});
    } catch (e) {
      await _logOfflineEvent(OfflineEventType.dataCleanupFailed, {'error': e.toString()});
    }
  }

  /// Get offline statistics
  Map<String, dynamic> getOfflineStats() {
    return {
      'isInitialized': _isInitialized,
      'isOnline': _isOnline,
      'isSyncing': _isSyncing,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'lastSyncError': _lastSyncError,
      'dataCount': _dataBox.length,
      'pendingSyncCount': _syncQueueBox.length,
      'conflictCount': _conflictBox.length,
      'autoSync': _autoSync,
      'syncInterval': _syncInterval.inSeconds,
    };
  }

  /// Add event listener
  void addEventListener(OfflineEventType type, Function(OfflineEvent) listener) {
    _listeners.putIfAbsent(type.name, () => []).add(listener);
  }

  /// Remove event listener
  void removeEventListener(OfflineEventType type, Function(OfflineEvent) listener) {
    _listeners[type.name]?.remove(listener);
  }

  /// Broadcast event
  void _broadcastEvent(OfflineEvent event) {
    final listeners = _listeners[event.type.name] ?? [];
    for (final listener in listeners) {
      try {
        listener(event);
      } catch (e) {
        debugPrint('Error in offline event listener: $e');
      }
    }
  }

  /// Log offline event
  Future<void> _logOfflineEvent(OfflineEventType type, Map<String, dynamic> data) async {
    final event = OfflineEvent(
      id: _generateId(),
      type: type,
      timestamp: DateTime.now(),
      data: data,
    );
    
    _broadcastEvent(event);
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(10000).toString();
  }

  /// Background sync dispatcher
  static void _backgroundSyncDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      // This would be called in background
      // Implement background sync logic here
      return Future.value(true);
    });
  }

  /// Dispose offline engine
  Future<void> dispose() async {
    _syncTimer?.cancel();
    await _connectivitySubscription?.cancel();
    
    await _dataBox.close();
    await _syncQueueBox.close();
    await _conflictBox.close();
    
    _listeners.clear();
    _isInitialized = false;
  }
}

// Offline Models
@HiveType(typeId: 0)
class OfflineData extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String type;
  
  @HiveField(2)
  final Map<String, dynamic> data;
  
  @HiveField(3)
  final String? parentId;
  
  @HiveField(4)
  final DateTime timestamp;
  
  @HiveField(5)
  final bool requiresSync;
  
  @HiveField(6)
  final bool synced;
  
  @HiveField(7)
  final int version;
  
  @HiveField(8)
  final SyncAction? action;

  OfflineData({
    required this.id,
    required this.type,
    required this.data,
    this.parentId,
    required this.timestamp,
    required this.requiresSync,
    required this.synced,
    required this.version,
    this.action,
  });

  OfflineData copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? data,
    String? parentId,
    DateTime? timestamp,
    bool? requiresSync,
    bool? synced,
    int? version,
    SyncAction? action,
  }) {
    return OfflineData(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      parentId: parentId ?? this.parentId,
      timestamp: timestamp ?? this.timestamp,
      requiresSync: requiresSync ?? this.requiresSync,
      synced: synced ?? this.synced,
      version: version ?? this.version,
      action: action ?? this.action,
    );
  }
}

@HiveType(typeId: 1)
class SyncQueue extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String dataId;
  
  @HiveField(2)
  final String type;
  
  @HiveField(3)
  final SyncAction action;
  
  @HiveField(4)
  final Map<String, dynamic> data;
  
  @HiveField(5)
  final DateTime timestamp;
  
  @HiveField(6)
  final int attempts;
  
  @HiveField(7)
  final DateTime lastAttempt;

  SyncQueue({
    required this.id,
    required this.dataId,
    required this.type,
    required this.action,
    required this.data,
    required this.timestamp,
    required this.attempts,
    required this.lastAttempt,
  });

  SyncQueue copyWith({
    String? id,
    String? dataId,
    String? type,
    SyncAction? action,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    int? attempts,
    DateTime? lastAttempt,
  }) {
    return SyncQueue(
      id: id ?? this.id,
      dataId: dataId ?? this.dataId,
      type: type ?? this.type,
      action: action ?? this.action,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      attempts: attempts ?? this.attempts,
      lastAttempt: lastAttempt ?? this.lastAttempt,
    );
  }
}

@HiveType(typeId: 2)
class ConflictRecord extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String dataId;
  
  @HiveField(2)
  final String type;
  
  @HiveField(3)
  final SyncAction action;
  
  @HiveField(4)
  final Map<String, dynamic> data;
  
  @HiveField(5)
  final String conflictReason;
  
  @HiveField(6)
  final DateTime timestamp;
  
  @HiveField(7)
  final bool resolved;

  ConflictRecord({
    required this.id,
    required this.dataId,
    required this.type,
    required this.action,
    required this.data,
    required this.conflictReason,
    required this.timestamp,
    required this.resolved,
  });
}

class OfflineEvent {
  final String id;
  final OfflineEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  OfflineEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.data,
  });
}

// Enums
enum SyncAction {
  create,
  update,
  delete,
}

enum OfflineEventType {
  initialized,
  initializationFailed,
  connected,
  disconnected,
  dataStored,
  dataStorageFailed,
  dataRetrieved,
  dataRetrievalFailed,
  dataUpdated,
  dataUpdateFailed,
  dataDeleted,
  dataDeletionFailed,
  addedToSyncQueue,
  syncQueueFailed,
  syncStarted,
  syncCompleted,
  syncFailed,
  conflictDetected,
  conflictResolved,
  conflictHandlingFailed,
  conflictResolutionFailed,
  dataCleanup,
  cleanupFailed,
  dataCleared,
  forceSyncFailed,
  backgroundSyncFailed,
}

enum ConflictResolution {
  useLocal,
  useRemote,
  merge,
}

// Hive Adapters
class OfflineDataAdapter extends TypeAdapter<OfflineData> {
  @override
  final typeId = 0;

  @override
  OfflineData read(BinaryReader reader) {
    return OfflineData(
      id: reader.read(),
      type: reader.read(),
      data: Map<String, dynamic>.from(reader.read()),
      parentId: reader.read(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(reader.read()),
      requiresSync: reader.read(),
      synced: reader.read(),
      version: reader.read(),
      action: SyncAction.values[reader.read()],
    );
  }

  @override
  void write(BinaryWriter writer, OfflineData obj) {
    writer.write(obj.id);
    writer.write(obj.type);
    writer.write(obj.data);
    writer.write(obj.parentId);
    writer.write(obj.timestamp.millisecondsSinceEpoch);
    writer.write(obj.requiresSync);
    writer.write(obj.synced);
    writer.write(obj.version);
    writer.write(obj.action?.index ?? 0);
  }
}

class SyncQueueAdapter extends TypeAdapter<SyncQueue> {
  @override
  final typeId = 1;

  @override
  SyncQueue read(BinaryReader reader) {
    return SyncQueue(
      id: reader.read(),
      dataId: reader.read(),
      type: reader.read(),
      action: SyncAction.values[reader.read()],
      data: Map<String, dynamic>.from(reader.read()),
      timestamp: DateTime.fromMillisecondsSinceEpoch(reader.read()),
      attempts: reader.read(),
      lastAttempt: DateTime.fromMillisecondsSinceEpoch(reader.read()),
    );
  }

  @override
  void write(BinaryWriter writer, SyncQueue obj) {
    writer.write(obj.id);
    writer.write(obj.dataId);
    writer.write(obj.type);
    writer.write(obj.action.index);
    writer.write(obj.data);
    writer.write(obj.timestamp.millisecondsSinceEpoch);
    writer.write(obj.attempts);
    writer.write(obj.lastAttempt.millisecondsSinceEpoch);
  }
}

class ConflictRecordAdapter extends TypeAdapter<ConflictRecord> {
  @override
  final typeId = 2;

  @override
  ConflictRecord read(BinaryReader reader) {
    return ConflictRecord(
      id: reader.read(),
      dataId: reader.read(),
      type: reader.read(),
      action: SyncAction.values[reader.read()],
      data: Map<String, dynamic>.from(reader.read()),
      conflictReason: reader.read(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(reader.read()),
      resolved: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, ConflictRecord obj) {
    writer.write(obj.id);
    writer.write(obj.dataId);
    writer.write(obj.type);
    writer.write(obj.action.index);
    writer.write(obj.data);
    writer.write(obj.conflictReason);
    writer.write(obj.timestamp.millisecondsSinceEpoch);
    writer.write(obj.resolved);
  }
}
