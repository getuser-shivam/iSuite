import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

class SyncEngine {
  static SyncEngine? _instance;
  static SyncEngine get instance => _instance ??= SyncEngine._internal();
  SyncEngine._internal();

  // WebSocket Connections
  final Map<String, WebSocketChannel> _connections = {};
  final Map<String, SyncSession> _sessions = {};
  
  // Sync State
  bool _isInitialized = false;
  bool _isOnline = false;
  bool _isSyncing = false;
  String? _serverUrl;
  String? _userId;
  String? _deviceId;
  
  // Sync Configuration
  Duration _syncInterval = Duration(seconds: 5);
  int _maxRetries = 3;
  Duration _retryDelay = Duration(seconds: 2);
  int _maxBatchSize = 100;
  bool _autoSync = true;
  bool _enableRealTime = true;
  
  // Sync Queue
  final List<SyncOperation> _syncQueue = [];
  final Map<String, List<SyncOperation>> _pendingOperations = {};
  final Map<String, DateTime> _lastSyncTime = {};
  
  // Conflict Resolution
  final Map<String, SyncConflict> _conflicts = {};
  ConflictResolutionStrategy _conflictStrategy = ConflictResolution.timestamp;
  
  // Event System
  final Map<String, List<Function(SyncEvent)>> _listeners = {};
  final List<SyncEvent> _eventLog = [];
  
  // Performance Monitoring
  final Map<String, SyncMetrics> _metrics = {};
  Timer? _syncTimer;
  Timer? _metricsTimer;
  
  // Network Monitoring
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  String? get serverUrl => _serverUrl;
  String? get userId => _userId;
  String? get deviceId => _deviceId;
  bool get autoSync => _autoSync;
  bool get enableRealTime => _enableRealTime;
  List<SyncOperation> get syncQueue => List.from(_syncQueue);
  Map<String, SyncConflict> get conflicts => Map.from(_conflicts);
  Map<String, SyncMetrics> get metrics => Map.from(_metrics);
  List<SyncEvent> get eventLog => List.from(_eventLog);

  /// Initialize Sync Engine
  Future<bool> initialize({
    required String serverUrl,
    required String userId,
    String? deviceId,
    Duration? syncInterval,
    int? maxRetries,
    Duration? retryDelay,
    int? maxBatchSize,
    bool autoSync = true,
    bool enableRealTime = true,
    ConflictResolutionStrategy? conflictStrategy,
  }) async {
    if (_isInitialized) return true;

    try {
      _serverUrl = serverUrl;
      _userId = userId;
      _deviceId = deviceId ?? const Uuid().v4();
      _syncInterval = syncInterval ?? _syncInterval;
      _maxRetries = maxRetries ?? _maxRetries;
      _retryDelay = retryDelay ?? _retryDelay;
      _maxBatchSize = maxBatchSize ?? _maxBatchSize;
      _autoSync = autoSync;
      _enableRealTime = enableRealTime;
      _conflictStrategy = conflictStrategy ?? _conflictStrategy;

      // Initialize metrics
      await _initializeMetrics();

      // Connect to server
      await _connectToServer();

      // Start network monitoring
      await _startNetworkMonitoring();

      // Start auto-sync if enabled
      if (_autoSync) {
        _startAutoSync();
      }

      // Start metrics collection
      _startMetricsCollection();

      _isInitialized = true;
      await _logSyncEvent(SyncEventType.initialized, {
        'serverUrl': _serverUrl,
        'userId': _userId,
        'deviceId': _deviceId,
        'autoSync': _autoSync,
        'enableRealTime': _enableRealTime,
      });

      return true;
    } catch (e) {
      await _logSyncEvent(SyncEventType.initializationFailed, {'error': e.toString()});
      return false;
    }
  }

  Future<void> _initializeMetrics() async {
    _metrics['sync'] = SyncMetrics(
      type: 'sync',
      operationsCount: 0,
      successCount: 0,
      errorCount: 0,
      averageLatency: 0.0,
      throughput: 0.0,
      lastSyncTime: DateTime.now(),
    );

    _metrics['realtime'] = SyncMetrics(
      type: 'realtime',
      operationsCount: 0,
      successCount: 0,
      errorCount: 0,
      averageLatency: 0.0,
      throughput: 0.0,
      lastSyncTime: DateTime.now(),
    );

    _metrics['conflict'] = SyncMetrics(
      type: 'conflict',
      operationsCount: 0,
      successCount: 0,
      errorCount: 0,
      averageLatency: 0.0,
      throughput: 0.0,
      lastSyncTime: DateTime.now(),
    );
  }

  Future<void> _connectToServer() async {
    try {
      final uri = Uri.parse('$_serverUrl/sync');
      final channel = WebSocketChannel.connect(uri);
      
      _connections['main'] = channel;
      
      channel.stream.listen(
        _handleServerMessage,
        onError: (error) {
          _isOnline = false;
          _logSyncEvent(SyncEventType.connectionError, {'error': error.toString()});
        },
        onDone: () {
          _isOnline = false;
          _logSyncEvent(SyncEventType.disconnected, {});
        },
      );

      // Send authentication
      await _sendAuthentication();
      
      _isOnline = true;
      _logSyncEvent(SyncEventType.connected, {});
    } catch (e) {
      _isOnline = false;
      _logSyncEvent(SyncEventType.connectionFailed, {'error': e.toString()});
    }
  }

  Future<void> _sendAuthentication() async {
    final channel = _connections['main'];
    if (channel == null) return;

    final authMessage = {
      'type': 'auth',
      'userId': _userId,
      'deviceId': _deviceId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    channel.sink.add(jsonEncode(authMessage));
  }

  void _handleServerMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final event = SyncEvent.fromMap(data);
      
      _processSyncEvent(event);
    } catch (e) {
      _logSyncEvent(SyncEventType.messageProcessingFailed, {'error': e.toString()});
    }
  }

  void _processSyncEvent(SyncEvent event) {
    switch (event.type) {
      case SyncEventType.authSuccess:
        _handleAuthSuccess(event);
        break;
      case SyncEventType.dataChanged:
        _handleDataChanged(event);
        break;
      case SyncEventType.conflictDetected:
        _handleConflictDetected(event);
        break;
      case SyncEventType.syncCompleted:
        _handleSyncCompleted(event);
        break;
      case SyncEventType.syncFailed:
        _handleSyncFailed(event);
        break;
      case SyncEventType.broadcast:
        _handleBroadcast(event);
        break;
      default:
        _logSyncEvent(SyncEventType.unknownEvent, {'type': event.type.name});
    }
  }

  void _handleAuthSuccess(SyncEvent event) {
    final sessionId = event.data['sessionId'];
    if (sessionId != null) {
      _sessions[sessionId] = SyncSession(
        id: sessionId,
        userId: _userId!,
        deviceId: _deviceId!,
        connectedAt: DateTime.now(),
        lastActivity: DateTime.now(),
      );
    }
  }

  void _handleDataChanged(SyncEvent event) {
    final dataId = event.data['dataId'];
    final changeType = event.data['changeType'];
    final data = event.data['data'];
    
    // Broadcast to all connected clients
    _broadcastEvent(SyncEventType.broadcast, {
      'dataId': dataId,
      'changeType': changeType,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void _handleConflictDetected(SyncEvent event) {
    final conflictId = event.data['conflictId'];
    final conflict = SyncConflict.fromMap(event.data);
    
    _conflicts[conflictId] = conflict;
    
    // Resolve conflict based on strategy
    _resolveConflict(conflict);
  }

  void _handleSyncCompleted(SyncEvent event) {
    final operationId = event.data['operationId'];
    _removeFromQueue(operationId);
    
    // Update metrics
    _updateMetrics('sync', SyncOperationType.success, 0);
  }

  void _handleSyncFailed(SyncEvent event) {
    final operationId = event.data['operationId'];
    final operation = _getOperationFromQueue(operationId);
    
    if (operation != null) {
      operation.retryCount++;
      
      if (operation.retryCount < _maxRetries) {
        // Retry after delay
        Future.delayed(_retryDelay * operation.retryCount, () {
          _addToQueue(operation);
        });
      } else {
        // Max retries reached
        _removeFromQueue(operationId);
        _updateMetrics('sync', SyncOperationType.error, 0);
      }
    }
  }

  void _handleBroadcast(SyncEvent event) {
    // Broadcast to all connected clients
    for (final channel in _connections.values) {
      channel.sink.add(jsonEncode(event.toMap()));
    }
  }

  /// Add sync operation
  Future<String> addOperation({
    required String type,
    required String dataId,
    required Map<String, dynamic> data,
    String? parentId,
    SyncPriority priority = SyncPriority.normal,
    SyncOperationType operationType = SyncOperationType.create,
  }) async {
    final operation = SyncOperation(
      id: const Uuid().v4(),
      type: type,
      dataId: dataId,
      data: data,
      parentId: parentId,
      priority: priority,
      operationType: operationType,
      timestamp: DateTime.now(),
      retryCount: 0,
    );

    await _addToQueue(operation);
    return operation.id;
  }

  Future<void> _addToQueue(SyncOperation operation) async {
    _syncQueue.add(operation);
    
    // Sort by priority
    _syncQueue.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    
    // Limit queue size
    if (_syncQueue.length > 1000) {
      _syncQueue.removeRange(0, _syncQueue.length - 1000);
    }

    // Process queue if online
    if (_isOnline && !_isSyncing) {
      _processQueue();
    }
  }

  Future<void> _removeFromQueue(String operationId) async {
    _syncQueue.removeWhere((op) => op.id == operationId);
  }

  SyncOperation? _getOperationFromQueue(String operationId) {
    try {
      return _syncQueue.firstWhere((op) => op.id == operationId);
    } catch (e) {
      return null;
    }
  }

  /// Process sync queue
  Future<void> _processQueue() async {
    if (_isSyncing || !_isOnline || _syncQueue.isEmpty) return;

    _isSyncing = true;

    try {
      final batch = _syncQueue.take(_maxBatchSize).toList();
      
      for (final operation in batch) {
        if (!_isOnline) break;
        
        final success = await _executeOperation(operation);
        
        if (success) {
          _removeFromQueue(operation.id);
        } else {
          // Operation failed, will be retried
          break;
        }
      }

      await _logSyncEvent(SyncEventType.batchProcessed, {
        'batchSize': batch.length,
        'remaining': _syncQueue.length,
      });
    } catch (e) {
      await _logSyncEvent(SyncEventType.queueProcessingFailed, {'error': e.toString()});
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _executeOperation(SyncOperation operation) async {
    final startTime = DateTime.now();
    
    try {
      final channel = _connections['main'];
      if (channel == null) return false;

      final message = {
        'type': 'operation',
        'operationId': operation.id,
        'operationType': operation.operationType.name,
        'data': operation.toMap(),
      };

      channel.sink.add(jsonEncode(message));
      
      // Wait for response (in a real implementation, this would be handled via callbacks)
      await Future.delayed(Duration(milliseconds: 100));
      
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      _updateMetrics('sync', SyncOperationType.success, latency);
      
      return true;
    } catch (e) {
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      _updateMetrics('sync', SyncOperationType.error, latency);
      return false;
    }
  }

  /// Real-time data synchronization
  Future<void> syncData({
    required String type,
    required String dataId,
    required Map<String, dynamic> data,
    String? parentId,
    bool immediate = false,
  }) async {
    if (!_enableRealTime && !immediate) {
      // Add to queue for batch processing
      await addOperation(
        type: type,
        dataId: dataId,
        data: data,
        parentId: parentId,
        priority: immediate ? SyncPriority.high : SyncPriority.normal,
      );
      return;
    }

    try {
      final channel = _connections['main'];
      if (channel == null || !_isOnline) return;

      final message = {
        'type': 'realtime_sync',
        'dataId': dataId,
        'type': type,
        'data': data,
        'parentId': parentId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      channel.sink.add(jsonEncode(message));
      
      _updateMetrics('realtime', SyncOperationType.success, 0);
      
      await _logSyncEvent(SyncEventType.realtimeSync, {
        'dataId': dataId,
        'type': type,
        'immediate': immediate,
      });
    } catch (e) {
      _updateMetrics('realtime', SyncOperationType.error, 0);
      await _logSyncEvent(SyncEventType.realtimeSyncFailed, {
        'dataId': dataId,
        'type': type,
        'error': e.toString(),
      });
    }
  }

  /// Conflict resolution
  Future<void> _resolveConflict(SyncConflict conflict) async {
    switch (_conflictStrategy) {
      case ConflictResolution.timestamp:
        await _resolveByTimestamp(conflict);
        break;
      case ConflictResolution.userChoice:
        await _resolveByUserChoice(conflict);
        break;
      case ConflictResolution.merge:
        await _resolveByMerge(conflict);
        break;
      case ConflictResolution.serverWins:
        await _resolveByServer(conflict);
        break;
      case ConflictResolution.clientWins:
        await _resolveByClient(conflict);
        break;
    }
  }

  Future<void> _resolveByTimestamp(SyncConflict conflict) async {
    // Use the most recent version
    final winner = conflict.localTimestamp.isAfter(conflict.remoteTimestamp) 
        ? conflict.localData 
        : conflict.remoteData;
    
    await _applyConflictResolution(conflict.id, winner);
  }

  Future<void> _resolveByUserChoice(SyncConflict conflict) async {
    // In a real implementation, this would show UI to user
    // For now, use timestamp as fallback
    await _resolveByTimestamp(conflict);
  }

  Future<void> _resolveByMerge(SyncConflict conflict) async {
    // Implement merge logic based on data type
    final merged = _mergeData(conflict.localData, conflict.remoteData);
    await _applyConflictResolution(conflict.id, merged);
  }

  Future<void> _resolveByServer(SyncConflict conflict) async {
    await _applyConflictResolution(conflict.id, conflict.remoteData);
  }

  Future<void> _resolveByClient(SyncConflict conflict) async {
    await _applyConflictResolution(conflict.id, conflict.localData);
  }

  Future<void> _applyConflictResolution(String conflictId, dynamic resolvedData) async {
    // Apply the resolved data to local storage
    // This would integrate with the appropriate data provider
    
    _conflicts.remove(conflictId);
    
    await _logSyncEvent(SyncEventType.conflictResolved, {
      'conflictId': conflictId,
      'strategy': _conflictStrategy.name,
    });
  }

  dynamic _mergeData(dynamic localData, dynamic remoteData) {
    // Implement merge logic based on data type
    // This is a simplified implementation
    if (localData is Map && remoteData is Map) {
      final local = localData as Map<String, dynamic>;
      final remote = remoteData as Map<String, dynamic>;
      
      // Merge maps, remote takes precedence
      final merged = Map<String, dynamic>.from(local);
      merged.addAll(remote);
      return merged;
    }
    
    // For other types, return remote data
    return remoteData;
  }

  /// Broadcast event to all connected clients
  void _broadcastEvent(SyncEventType type, Map<String, dynamic> data) {
    final event = SyncEvent(
      id: const Uuid().v4(),
      type: type,
      timestamp: DateTime.now(),
      data: data,
    );

    for (final channel in _connections.values) {
      try {
        channel.sink.add(jsonEncode(event.toMap()));
      } catch (e) {
        // Remove broken connection
        _connections.removeWhere((key, value) => value == channel);
      }
    }
  }

  /// Start network monitoring
  Future<void> _startNetworkMonitoring() async {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (!wasOnline && _isOnline) {
        // Came back online
        _logSyncEvent(SyncEventType.connected, {});
        if (_autoSync) {
          _processQueue();
        }
      } else if (wasOnline && !_isOnline) {
        // Went offline
        _logSyncEvent(SyncEventType.disconnected, {});
      }
    });
  }

  /// Start auto-sync
  void _startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (_isOnline && !_isSyncing) {
        _processQueue();
      }
    });
  }

  /// Start metrics collection
  void _startMetricsCollection() {
    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _collectMetrics();
    });
  }

  void _collectMetrics() {
    for (final metrics in _metrics.values) {
      // Calculate throughput
      final timeSinceLastSync = DateTime.now().difference(metrics.lastSyncTime).inSeconds;
      if (timeSinceLastSync > 0) {
        metrics.throughput = metrics.operationsCount / timeSinceLastSync;
      }
    }
  }

  /// Update metrics
  void _updateMetrics(String metricsType, SyncOperationType operationType, double latency) {
    final metrics = _metrics[metricsType];
    if (metrics == null) return;

    metrics.operationsCount++;
    
    switch (operationType) {
      case SyncOperationType.success:
        metrics.successCount++;
        break;
      case SyncOperationType.error:
        metrics.errorCount++;
        break;
    }
    
    // Update average latency
    final totalOperations = metrics.successCount + metrics.errorCount;
    if (totalOperations > 0) {
      metrics.averageLatency = (metrics.averageLatency * (totalOperations - 1) + latency) / totalOperations;
    }
    
    metrics.lastSyncTime = DateTime.now();
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStatistics() {
    return {
      'isInitialized': _isInitialized,
      'isOnline': _isOnline,
      'isSyncing': _isSyncing,
      'serverUrl': _serverUrl,
      'userId': _userId,
      'deviceId': _deviceId,
      'autoSync': _autoSync,
      'enableRealTime': _enableRealTime,
      'queueSize': _syncQueue.length,
      'conflictCount': _conflicts.length,
      'activeConnections': _connections.length,
      'activeSessions': _sessions.length,
      'metrics': _metrics.map((k, v) => MapEntry(k, v.toMap())),
      'configuration': {
        'syncInterval': _syncInterval.inSeconds,
        'maxRetries': _maxRetries,
        'retryDelay': _retryDelay.inSeconds,
        'maxBatchSize': _maxBatchSize,
        'conflictStrategy': _conflictStrategy.name,
      },
    };
  }

  /// Get sync status for specific data
  SyncStatus getSyncStatus(String dataId) {
    final isInQueue = _syncQueue.any((op) => op.dataId == dataId);
    final hasConflict = _conflicts.containsKey(dataId);
    final lastSync = _lastSyncTime[dataId];
    
    return SyncStatus(
      dataId: dataId,
      isInQueue: isInQueue,
      hasConflict: hasConflict,
      lastSyncTime: lastSync,
      status: hasConflict 
          ? SyncStatus.conflicted 
          : isInQueue 
              ? SyncStatus.pending 
              : SyncStatus.synced,
    );
  }

  /// Force sync
  Future<void> forceSync() async {
    if (!_isOnline) {
      _logSyncEvent(SyncEventType.forceSyncFailed, {'reason': 'Offline'});
      return;
    }

    await _processQueue();
  }

  /// Clear sync queue
  Future<void> clearQueue() async {
    _syncQueue.clear();
    await _logSyncEvent(SyncEventType.queueCleared, {});
  }

  /// Clear conflicts
  Future<void> clearConflicts() async {
    _conflicts.clear();
    await _logSyncEvent(SyncEventType.conflictsCleared, {});
  }

  /// Add event listener
  void addEventListener(SyncEventType type, Function(SyncEvent) listener) {
    _listeners.putIfAbsent(type.name, []).add(listener);
  }

  /// Remove event listener
  void removeEventListener(SyncEventType type, Function(SyncEvent) listener) {
    _listeners[type.name]?.remove(listener);
  }

  /// Log sync event
  Future<void> _logSyncEvent(SyncEventType type, Map<String, dynamic> data) async {
    final event = SyncEvent(
      id: const Uuid().v4(),
      type: type,
      timestamp: DateTime.now(),
      data: data,
    );

    _eventLog.add(event);
    
    // Limit event log size
    if (_eventLog.length > 1000) {
      _eventLog.removeRange(0, _eventLog.length - 1000);
    }

    // Notify listeners
    final listeners = _listeners[type.name] ?? [];
    for (final listener in listeners) {
      try {
        listener(event);
      } catch (e) {
        debugPrint('Error in sync event listener: $e');
      }
    }
  }

  /// Dispose sync engine
  Future<void> dispose() async {
    _syncTimer?.cancel();
    _metricsTimer?.cancel();
    await _connectivitySubscription?.cancel();
    
    // Close all connections
    for (final channel in _connections.values) {
      channel.sink.close();
    }
    _connections.clear();
    
    _sessions.clear();
    _syncQueue.clear();
    _conflicts.clear();
    _metrics.clear();
    _eventLog.clear();
    
    _isInitialized = false;
    _isOnline = false;
    _isSyncing = false;
  }
}

// Sync Models
class SyncOperation {
  final String id;
  final String type;
  final String dataId;
  final Map<String, dynamic> data;
  final String? parentId;
  final SyncPriority priority;
  final SyncOperationType operationType;
  final DateTime timestamp;
  int retryCount;

  const SyncOperation({
    required this.id,
    required this.type,
    required this.dataId,
    required this.data,
    this.parentId,
    required this.priority,
    required this.operationType,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'dataId': dataId,
      'data': data,
      'parentId': parentId,
      'priority': priority.name,
      'operationType': operationType.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'retryCount': retryCount,
    };
  }

  factory SyncOperation.fromMap(Map<String, dynamic> map) {
    return SyncOperation(
      id: map['id'],
      type: map['type'],
      dataId: map['dataId'],
      data: Map<String, dynamic>.from(map['data']),
      parentId: map['parentId'],
      priority: SyncPriority.values.firstWhere((p) => p.name == map['priority']),
      operationType: SyncOperationType.values.firstWhere((t) => t.name == map['operationType']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      retryCount: map['retryCount'] ?? 0,
    );
  }
}

class SyncSession {
  final String id;
  final String userId;
  final String deviceId;
  final DateTime connectedAt;
  DateTime lastActivity;

  const SyncSession({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.connectedAt,
    required this.lastActivity,
  });
}

class SyncConflict {
  final String id;
  final String dataId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime localTimestamp;
  final DateTime remoteTimestamp;
  final String conflictReason;

  const SyncConflict({
    required this.id,
    required this.dataId,
    required this.localData,
    required this.remoteData,
    required this.localTimestamp,
    required this.remoteTimestamp,
    required this.conflictReason,
  });

  factory SyncConflict.fromMap(Map<String, dynamic> map) {
    return SyncConflict(
      id: map['id'],
      dataId: map['dataId'],
      localData: Map<String, dynamic>.from(map['localData']),
      remoteData: Map<String, dynamic>.from(map['remoteData']),
      localTimestamp: DateTime.fromMillisecondsSinceEpoch(map['localTimestamp']),
      remoteTimestamp: DateTime.fromMillisecondsSinceEpoch(map['remoteTimestamp']),
      conflictReason: map['conflictReason'],
    );
  }
}

class SyncEvent {
  final String id;
  final SyncEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const SyncEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'data': data,
    };
  }

  factory SyncEvent.fromMap(Map<String, dynamic> map) {
    return SyncEvent(
      id: map['id'],
      type: SyncEventType.values.firstWhere((t) => t.name == map['type']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      data: Map<String, dynamic>.from(map['data']),
    );
  }
}

class SyncMetrics {
  final String type;
  int operationsCount;
  int successCount;
  int errorCount;
  double averageLatency;
  double throughput;
  DateTime lastSyncTime;

  SyncMetrics({
    required this.type,
    this.operationsCount = 0,
    this.successCount = 0,
    this.errorCount = 0,
    this.averageLatency = 0.0,
    this.throughput = 0.0,
    required this.lastSyncTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'operationsCount': operationsCount,
      'successCount': successCount,
      'errorCount': errorCount,
      'averageLatency': averageLatency,
      'throughput': throughput,
      'lastSyncTime': lastSyncTime.toIso8601String(),
      'successRate': operationsCount > 0 ? successCount / operationsCount : 0.0,
    };
  }
}

class SyncStatus {
  final String dataId;
  final bool isInQueue;
  final bool hasConflict;
  final DateTime? lastSyncTime;
  final SyncStatusType status;

  const SyncStatus({
    required this.dataId,
    required this.isInQueue,
    required this.hasConflict,
    this.lastSyncTime,
    required this.status,
  });
}

// Enums
enum SyncPriority {
  low,
  normal,
  high,
  critical,
}

enum SyncOperationType {
  create,
  update,
  delete,
  sync,
}

enum ConflictResolution {
  timestamp,
  userChoice,
  merge,
  serverWins,
  clientWins,
}

enum SyncEventType {
  initialized,
  initializationFailed,
  connected,
  disconnected,
  connectionError,
  connectionFailed,
  authSuccess,
  authFailed,
  dataChanged,
  conflictDetected,
  conflictResolved,
  syncCompleted,
  syncFailed,
  queueProcessed,
  queueProcessingFailed,
  batchProcessed,
  realtimeSync,
  realtimeSyncFailed,
  itemStored,
  itemRetrieved,
  itemRemoved,
  itemUpdated,
  queueCleared,
  conflictsCleared,
  forceSyncFailed,
  broadcast,
  unknownEvent,
  messageProcessingFailed,
}

enum SyncStatusType {
  synced,
  pending,
  conflicted,
  error,
}
