import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CachingEngine {
  static CachingEngine? _instance;
  static CachingEngine get instance => _instance ??= CachingEngine._internal();
  CachingEngine._internal();

  // Cache Storage
  late Box<CacheItem> _memoryCache;
  late Box<CacheItem> _diskCache;
  SharedPreferences? _prefs;

  // Cache Configuration
  bool _isInitialized = false;
  int _maxMemoryItems = 1000;
  int _maxDiskItems = 10000;
  int _maxMemorySize = 100 * 1024 * 1024; // 100MB
  int _maxDiskSize = 500 * 1024 * 1024; // 500MB
  Duration _defaultTTL = Duration(hours: 1);
  CachePolicy _defaultPolicy = CachePolicy.lru;

  // Cache Layers
  final Map<String, CacheItem> _memoryLayer = {};
  final Map<String, CacheItem> _diskLayer = {};
  final Map<String, CacheItem> _networkLayer = {};

  // Cache Statistics
  final Map<String, CacheStats> _cacheStats = {};
  final List<CacheEvent> _eventLog = [];

  // Cache Strategies
  bool _enableCompression = true;
  bool _enableEncryption = false;
  bool _enablePersistence = true;
  bool _enableMetrics = true;
  bool _enableNetworkCache = false;

  // Eviction Policies
  Timer? _cleanupTimer;
  Duration _cleanupInterval = Duration(minutes: 5);

  // Network Monitoring
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;

  // Getters
  bool get isInitialized => _isInitialized;
  int get maxMemoryItems => _maxMemoryItems;
  int get maxDiskItems => _maxDiskItems;
  int get maxMemorySize => _maxMemorySize;
  int get maxDiskSize => _maxDiskSize;
  CachePolicy get defaultPolicy => _defaultPolicy;
  bool get enableCompression => _enableCompression;
  bool get enableEncryption => _enableEncryption;
  bool get enablePersistence => _enablePersistence;
  bool get enableMetrics => _enableMetrics;
  bool get enableNetworkCache => _enableNetworkCache;
  Map<String, CacheStats> get cacheStats => Map.from(_cacheStats);
  List<CacheEvent> get eventLog => List.from(_eventLog);

  /// Initialize Caching Engine
  Future<bool> initialize({
    int? maxMemoryItems,
    int? maxDiskItems,
    int? maxMemorySize,
    int? maxDiskSize,
    Duration? defaultTTL,
    CachePolicy? defaultPolicy,
    bool enableCompression = true,
    bool enableEncryption = false,
    bool enablePersistence = true,
    bool enableMetrics = true,
    bool enableNetworkCache = false,
    Duration? cleanupInterval,
  }) async {
    if (_isInitialized) return true;

    try {
      // Set configuration
      _maxMemoryItems = maxMemoryItems ?? _maxMemoryItems;
      _maxDiskItems = maxDiskItems ?? _maxDiskItems;
      _maxMemorySize = maxMemorySize ?? _maxMemorySize;
      _maxDiskSize = maxDiskSize ?? _maxDiskSize;
      _defaultTTL = defaultTTL ?? _defaultTTL;
      _defaultPolicy = defaultPolicy ?? _defaultPolicy;
      _enableCompression = enableCompression;
      _enableEncryption = enableEncryption;
      _enablePersistence = enablePersistence;
      _enableMetrics = enableMetrics;
      _enableNetworkCache = enableNetworkCache;
      _cleanupInterval = cleanupInterval ?? _cleanupInterval;

      // Initialize storage
      await _initializeStorage();

      // Initialize network monitoring
      await _initializeNetworkMonitoring();

      // Start cleanup timer
      _startCleanupTimer();

      // Initialize statistics
      await _initializeStats();

      _isInitialized = true;
      await _logCacheEvent(CacheEventType.initialized, {
        'maxMemoryItems': _maxMemoryItems,
        'maxDiskItems': _maxDiskItems,
        'defaultPolicy': _defaultPolicy.name,
      });

      return true;
    } catch (e) {
      await _logCacheEvent(
          CacheEventType.initializationFailed, {'error': e.toString()});
      return false;
    }
  }

  Future<void> _initializeStorage() async {
    // Initialize Hive
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(CacheItemAdapter());
    Hive.registerAdapter(CacheStatsAdapter());
    Hive.registerAdapter(CacheEventAdapter());

    // Open boxes
    _memoryCache = await Hive.openBox<CacheItem>('memory_cache');
    _diskCache = await Hive.openBox<CacheItem>('disk_cache');

    // Initialize SharedPreferences
    if (_enablePersistence) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  Future<void> _initializeNetworkMonitoring() async {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (!wasOnline && _isOnline) {
        // Came back online - sync caches
        _syncCaches();
      } else if (wasOnline && !_isOnline) {
        // Went offline - disable network cache
        _disableNetworkCache();
      }
    });
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _cleanupExpiredItems();
    });
  }

  Future<void> _initializeStats() async {
    // Initialize cache statistics
    _cacheStats['memory'] = CacheStats(
      layer: 'memory',
      hitCount: 0,
      missCount: 0,
      itemCount: 0,
      totalSize: 0,
      evictionCount: 0,
    );

    _cacheStats['disk'] = CacheStats(
      layer: 'disk',
      hitCount: 0,
      missCount: 0,
      itemCount: 0,
      totalSize: 0,
      evictionCount: 0,
    );

    if (_enableNetworkCache) {
      _cacheStats['network'] = CacheStats(
        layer: 'network',
        hitCount: 0,
        missCount: 0,
        itemCount: 0,
        totalSize: 0,
        evictionCount: 0,
      );
    }
  }

  /// Store data in cache
  Future<bool> put({
    required String key,
    required dynamic value,
    Duration? ttl,
    CacheLayer layer = CacheLayer.memory,
    CachePolicy? policy,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) return false;

    try {
      final cacheItem = CacheItem(
        key: key,
        value: value,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(ttl ?? _defaultTTL),
        size: _calculateSize(value),
        policy: policy ?? _defaultPolicy,
        metadata: metadata ?? {},
        compressed: _enableCompression,
        encrypted: _enableEncryption,
      );

      // Process value
      dynamic processedValue = value;
      if (_enableCompression) {
        processedValue = await _compressData(value);
      }
      if (_enableEncryption) {
        processedValue = await _encryptData(processedValue);
      }

      final finalItem = cacheItem.copyWith(
        value: processedValue,
        size: _calculateSize(processedValue),
      );

      // Store in appropriate layer
      bool success = false;
      switch (layer) {
        case CacheLayer.memory:
          success = await _putInMemory(finalItem);
          break;
        case CacheLayer.disk:
          success = await _putInDisk(finalItem);
          break;
        case CacheLayer.network:
          success =
              _enableNetworkCache ? await _putInNetwork(finalItem) : false;
          break;
      }

      if (success) {
        await _updateStats(layer, CacheOperation.put, finalItem.size);
        await _logCacheEvent(CacheEventType.itemStored, {
          'key': key,
          'layer': layer.name,
          'size': finalItem.size,
          'ttl': ttl?.inSeconds ?? _defaultTTL.inSeconds,
        });
      }

      return success;
    } catch (e) {
      await _logCacheEvent(CacheEventType.storageFailed, {
        'key': key,
        'layer': layer.name,
        'error': e.toString(),
      });
      return false;
    }
  }

  /// Retrieve data from cache
  Future<T?> get<T>({
    required String key,
    CacheLayer? preferredLayer,
    bool fallback = true,
  }) async {
    if (!_isInitialized) return null;

    try {
      // Try preferred layer first
      if (preferredLayer != null) {
        final item = await _getFromLayer<T>(key, preferredLayer!);
        if (item != null) {
          await _updateStats(preferredLayer!, CacheOperation.hit, 0);
          return item;
        }
      }

      // Try other layers if fallback is enabled
      if (fallback) {
        // Try memory
        final memoryItem = await _getFromLayer<T>(key, CacheLayer.memory);
        if (memoryItem != null) {
          await _updateStats(CacheLayer.memory, CacheOperation.hit, 0);
          return memoryItem;
        }

        // Try disk
        final diskItem = await _getFromLayer<T>(key, CacheLayer.disk);
        if (diskItem != null) {
          await _updateStats(CacheLayer.disk, CacheOperation.hit, 0);
          // Promote to memory if space allows
          await _promoteToMemory(key, diskItem);
          return diskItem;
        }

        // Try network if enabled
        if (_enableNetworkCache && _isOnline) {
          final networkItem = await _getFromLayer<T>(key, CacheLayer.network);
          if (networkItem != null) {
            await _updateStats(CacheLayer.network, CacheOperation.hit, 0);
            return networkItem;
          }
        }
      }

      // Record miss
      await _updateStats(CacheLayer.memory, CacheOperation.miss, 0);
      await _logCacheEvent(CacheEventType.itemMissed, {'key': key});

      return null;
    } catch (e) {
      await _logCacheEvent(CacheEventType.retrievalFailed, {
        'key': key,
        'error': e.toString(),
      });
      return null;
    }
  }

  Future<T?> _getFromLayer<T>(String key, CacheLayer layer) async {
    CacheItem? item;

    switch (layer) {
      case CacheLayer.memory:
        item = _memoryLayer[key];
        break;
      case CacheLayer.disk:
        item = _diskCache.get(key);
        break;
      case CacheLayer.network:
        item = _networkLayer[key];
        break;
    }

    if (item == null) return null;

    // Check if expired
    if (DateTime.now().isAfter(item.expiresAt)) {
      await _removeFromLayer(key, layer);
      return null;
    }

    // Process value
    dynamic processedValue = item.value;
    if (item.encrypted) {
      processedValue = await _decryptData(processedValue);
    }
    if (item.compressed) {
      processedValue = await _decompressData(processedValue);
    }

    return processedValue as T?;
  }

  Future<bool> _putInMemory(CacheItem item) async {
    // Check memory limits
    if (_memoryLayer.length >= _maxMemoryItems) {
      await _evictFromMemory();
    }

    if (_getMemorySize() + item.size > _maxMemorySize) {
      await _evictFromMemoryUntilSize(_maxMemorySize - item.size);
    }

    _memoryLayer[item.key] = item;
    return true;
  }

  Future<bool> _putInDisk(CacheItem item) async {
    // Check disk limits
    if (_diskCache.length >= _maxDiskItems) {
      await _evictFromDisk();
    }

    if (_getDiskSize() + item.size > _maxDiskSize) {
      await _evictFromDiskUntilSize(_maxDiskSize - item.size);
    }

    await _diskCache.put(item.key, item);
    return true;
  }

  Future<bool> _putInNetwork(CacheItem item) async {
    // Network cache is in-memory only
    if (_networkLayer.length >= _maxMemoryItems) {
      await _evictFromNetwork();
    }

    _networkLayer[item.key] = item;
    return true;
  }

  /// Remove item from cache
  Future<bool> remove(String key, {CacheLayer? layer}) async {
    if (!_isInitialized) return false;

    try {
      bool success = false;

      if (layer != null) {
        success = await _removeFromLayer(key, layer!);
      } else {
        // Remove from all layers
        success = await _removeFromLayer(key, CacheLayer.memory) |
            await _removeFromLayer(key, CacheLayer.disk) |
            await _removeFromLayer(key, CacheLayer.network);
      }

      if (success) {
        await _logCacheEvent(CacheEventType.itemRemoved, {'key': key});
      }

      return success;
    } catch (e) {
      await _logCacheEvent(CacheEventType.removalFailed, {
        'key': key,
        'error': e.toString(),
      });
      return false;
    }
  }

  Future<bool> _removeFromLayer(String key, CacheLayer layer) async {
    switch (layer) {
      case CacheLayer.memory:
        _memoryLayer.remove(key);
        return true;
      case CacheLayer.disk:
        await _diskCache.delete(key);
        return true;
      case CacheLayer.network:
        _networkLayer.remove(key);
        return true;
    }
  }

  /// Clear cache
  Future<bool> clear({CacheLayer? layer}) async {
    if (!_isInitialized) return false;

    try {
      if (layer != null) {
        switch (layer) {
          case CacheLayer.memory:
            _memoryLayer.clear();
            break;
          case CacheLayer.disk:
            await _diskCache.clear();
            break;
          case CacheLayer.network:
            _networkLayer.clear();
            break;
        }
      } else {
        _memoryLayer.clear();
        await _diskCache.clear();
        _networkLayer.clear();
      }

      await _logCacheEvent(CacheEventType.cacheCleared, {'layer': layer?.name});
      return true;
    } catch (e) {
      await _logCacheEvent(CacheEventType.clearanceFailed, {
        'layer': layer?.name,
        'error': e.toString(),
      });
      return false;
    }
  }

  /// Cache warming
  Future<void> warmCache(List<CacheItem> items) async {
    if (!_isInitialized) return;

    for (final item in items) {
      await put(
        key: item.key,
        value: item.value,
        ttl: item.expiresAt.difference(item.createdAt),
        layer: CacheLayer.memory,
        policy: item.policy,
        metadata: item.metadata,
      );
    }

    await _logCacheEvent(
        CacheEventType.cacheWarmed, {'itemsCount': items.length});
  }

  /// Cache statistics
  Map<String, dynamic> getCacheStatistics() {
    return {
      'isInitialized': _isInitialized,
      'memoryStats': _cacheStats['memory']?.toMap(),
      'diskStats': _cacheStats['disk']?.toMap(),
      'networkStats': _cacheStats['network']?.toMap(),
      'memoryLayerSize': _memoryLayer.length,
      'diskLayerSize': _diskCache.length,
      'networkLayerSize': _networkLayer.length,
      'memorySize': _getMemorySize(),
      'diskSize': _getDiskSize(),
      'configuration': {
        'maxMemoryItems': _maxMemoryItems,
        'maxDiskItems': _maxDiskItems,
        'maxMemorySize': _maxMemorySize,
        'maxDiskSize': _maxDiskSize,
        'defaultTTL': _defaultTTL.inSeconds,
        'defaultPolicy': _defaultPolicy.name,
        'enableCompression': _enableCompression,
        'enableEncryption': _enableEncryption,
        'enablePersistence': _enablePersistence,
        'enableMetrics': _enableMetrics,
        'enableNetworkCache': _enableNetworkCache,
      },
    };
  }

  /// Utility Methods
  int _calculateSize(dynamic value) {
    try {
      final jsonString = jsonEncode(value);
      return jsonString.length;
    } catch (e) {
      return 0;
    }
  }

  int _getMemorySize() {
    return _memoryLayer.values.fold(0, (sum, item) => sum + item.size);
  }

  int _getDiskSize() {
    return _diskCache.values.fold(0, (sum, item) => sum + item.size);
  }

  Future<dynamic> _compressData(dynamic data) async {
    // Implement compression logic
    // For now, return original data
    return data;
  }

  Future<dynamic> _decompressData(dynamic data) async {
    // Implement decompression logic
    // For now, return original data
    return data;
  }

  Future<dynamic> _encryptData(dynamic data) async {
    // Implement encryption logic
    // For now, return original data
    return data;
  }

  Future<dynamic> _decryptData(dynamic data) async {
    // Implement decryption logic
    // For now, return original data
    return data;
  }

  /// Eviction Methods
  Future<void> _evictFromMemory() async {
    final items = _memoryLayer.values.toList();
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    switch (_defaultPolicy) {
      case CachePolicy.lru:
        items.sort((a, b) => a.accessedAt.compareTo(b.accessedAt));
        break;
      case CachePolicy.lfu:
        items.sort((a, b) => a.accessCount.compareTo(b.accessCount));
        break;
      case CachePolicy.fifo:
        // Already sorted by creation time
        break;
      case CachePolicy.random:
        items.shuffle();
        break;
    }

    final toRemove = items.take(items.length ~/ 4);
    for (final item in toRemove) {
      _memoryLayer.remove(item.key);
    }
  }

  Future<void> _evictFromDisk() async {
    final items = _diskCache.values.toList();
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    switch (_defaultPolicy) {
      case CachePolicy.lru:
        items.sort((a, b) => a.accessedAt.compareTo(b.accessedAt));
        break;
      case CachePolicy.lfu:
        items.sort((a, b) => a.accessCount.compareTo(b.accessCount));
        break;
      case CachePolicy.fifo:
        // Already sorted by creation time
        break;
      case CachePolicy.random:
        items.shuffle();
        break;
    }

    final toRemove = items.take(items.length ~/ 4);
    for (final item in toRemove) {
      await _diskCache.delete(item.key);
    }
  }

  Future<void> _evictFromNetwork() async {
    final items = _networkLayer.values.toList();
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    switch (_defaultPolicy) {
      case CachePolicy.lru:
        items.sort((a, b) => a.accessedAt.compareTo(b.accessedAt));
        break;
      case CachePolicy.lfu:
        items.sort((a, b) => a.accessCount.compareTo(b.accessCount));
        break;
      case CachePolicy.fifo:
        // Already sorted by creation time
        break;
      case CachePolicy.random:
        items.shuffle();
        break;
    }

    final toRemove = items.take(items.length ~/ 4);
    for (final item in toRemove) {
      _networkLayer.remove(item.key);
    }
  }

  Future<void> _evictFromMemoryUntilSize(int targetSize) async {
    while (_getMemorySize() > targetSize && _memoryLayer.isNotEmpty) {
      await _evictFromMemory();
    }
  }

  Future<void> _evictFromDiskUntilSize(int targetSize) async {
    while (_getDiskSize() > targetSize && _diskCache.isNotEmpty) {
      await _evictFromDisk();
    }
  }

  /// Cleanup expired items
  Future<void> _cleanupExpiredItems() async {
    final now = DateTime.now();

    // Clean memory cache
    final expiredMemoryKeys = _memoryLayer.entries
        .where((entry) => now.isAfter(entry.value.expiresAt))
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredMemoryKeys) {
      _memoryLayer.remove(key);
    }

    // Clean disk cache
    final expiredDiskKeys = _diskCache.values
        .where((item) => now.isAfter(item.expiresAt))
        .map((item) => item.key)
        .toList();

    for (final key in expiredDiskKeys) {
      await _diskCache.delete(key);
    }

    // Clean network cache
    final expiredNetworkKeys = _networkLayer.entries
        .where((entry) => now.isAfter(entry.value.expiresAt))
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredNetworkKeys) {
      _networkLayer.remove(key);
    }

    if (expiredMemoryKeys.isNotEmpty ||
        expiredDiskKeys.isNotEmpty ||
        expiredNetworkKeys.isNotEmpty) {
      await _logCacheEvent(CacheEventType.expiredItemsCleaned, {
        'memoryCount': expiredMemoryKeys.length,
        'diskCount': expiredDiskKeys.length,
        'networkCount': expiredNetworkKeys.length,
      });
    }
  }

  /// Promote item to memory cache
  Future<void> _promoteToMemory(String key, dynamic value) async {
    if (_memoryLayer.length >= _maxMemoryItems) {
      await _evictFromMemory();
    }

    final item = CacheItem(
      key: key,
      value: value,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(_defaultTTL),
      size: _calculateSize(value),
      policy: _defaultPolicy,
      metadata: {},
      compressed: _enableCompression,
      encrypted: _enableEncryption,
    );

    _memoryLayer[key] = item;
  }

  /// Sync caches when coming back online
  Future<void> _syncCaches() async {
    // Implement cache synchronization logic
    // This would sync with remote cache servers
    await _logCacheEvent(CacheEventType.cacheSynced, {});
  }

  /// Disable network cache when offline
  void _disableNetworkCache() {
    _networkLayer.clear();
    _enableNetworkCache = false;
  }

  /// Update statistics
  Future<void> _updateStats(
      CacheLayer layer, CacheOperation operation, int size) async {
    if (!_enableMetrics) return;

    final stats = _cacheStats[layer.name];
    if (stats == null) return;

    switch (operation) {
      case CacheOperation.put:
        stats.itemCount++;
        stats.totalSize += size;
        break;
      case CacheOperation.hit:
        stats.hitCount++;
        break;
      case CacheOperation.miss:
        stats.missCount++;
        break;
      case CacheOperation.evict:
        stats.evictionCount++;
        stats.itemCount--;
        stats.totalSize -= size;
        break;
    }
  }

  /// Log cache event
  Future<void> _logCacheEvent(
      CacheEventType type, Map<String, dynamic> data) async {
    final event = CacheEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      timestamp: DateTime.now(),
      data: data,
    );

    _eventLog.add(event);

    // Limit event log size
    if (_eventLog.length > 1000) {
      _eventLog.removeRange(0, _eventLog.length - 1000);
    }
  }

  /// Dispose caching engine
  Future<void> dispose() async {
    _cleanupTimer?.cancel();
    await _connectivitySubscription?.cancel();

    _memoryLayer.clear();
    _networkLayer.clear();
    _cacheStats.clear();
    _eventLog.clear();

    await _memoryCache.close();
    await _diskCache.close();

    _isInitialized = false;
  }
}

// Cache Models
@HiveType(typeId: 0)
class CacheItem extends HiveObject {
  @HiveField(0)
  final String key;

  @HiveField(1)
  final dynamic value;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final DateTime expiresAt;

  @HiveField(4)
  final int size;

  @HiveField(5)
  final CachePolicy policy;

  @HiveField(6)
  final Map<String, dynamic> metadata;

  @HiveField(7)
  final bool compressed;

  @HiveField(8)
  final bool encrypted;

  @HiveField(9)
  DateTime accessedAt;

  @HiveField(10)
  int accessCount;

  CacheItem({
    required this.key,
    required this.value,
    required this.createdAt,
    required this.expiresAt,
    required this.size,
    required this.policy,
    required this.metadata,
    required this.compressed,
    required this.encrypted,
    required this.accessedAt,
    required this.accessCount,
  });

  CacheItem copyWith({
    String? key,
    dynamic value,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? size,
    CachePolicy? policy,
    Map<String, dynamic>? metadata,
    bool? compressed,
    bool? encrypted,
    DateTime? accessedAt,
    int? accessCount,
  }) {
    return CacheItem(
      key: key ?? this.key,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      size: size ?? this.size,
      policy: policy ?? this.policy,
      metadata: metadata ?? this.metadata,
      compressed: compressed ?? this.compressed,
      encrypted: encrypted ?? this.encrypted,
      accessedAt: accessedAt ?? this.accessedAt,
      accessCount: accessCount ?? this.accessCount,
    );
  }
}

@HiveType(typeId: 1)
class CacheStats extends HiveObject {
  @HiveField(0)
  final String layer;

  @HiveField(1)
  int hitCount;

  @HiveField(2)
  int missCount;

  @HiveField(3)
  int itemCount;

  @HiveField(4)
  int totalSize;

  @HiveField(5)
  int evictionCount;

  CacheStats({
    required this.layer,
    this.hitCount = 0,
    this.missCount = 0,
    this.itemCount = 0,
    this.totalSize = 0,
    this.evictionCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'layer': layer,
      'hitCount': hitCount,
      'missCount': missCount,
      'itemCount': itemCount,
      'totalSize': totalSize,
      'evictionCount': evictionCount,
      'hitRate':
          hitCount + missCount > 0 ? (hitCount / (hitCount + missCount)) : 0.0,
    };
  }
}

@HiveType(typeId: 2)
class CacheEvent extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final CacheEventType type;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final Map<String, dynamic> data;

  CacheEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.data,
  });
}

// Enums
enum CacheLayer {
  memory,
  disk,
  network,
}

enum CachePolicy {
  lru,
  lfu,
  fifo,
  random,
}

enum CacheOperation {
  put,
  hit,
  miss,
  evict,
}

enum CacheEventType {
  initialized,
  initializationFailed,
  itemStored,
  storageFailed,
  itemRetrieved,
  retrievalFailed,
  itemRemoved,
  removalFailed,
  itemMissed,
  cacheCleared,
  clearanceFailed,
  cacheWarmed,
  expiredItemsCleaned,
  cacheSynced,
  unknown,
}

// Hive Adapters
class CacheItemAdapter extends TypeAdapter<CacheItem> {
  @override
  final typeId = 0;

  @override
  CacheItem read(BinaryReader reader) {
    return CacheItem(
      key: reader.read(),
      value: reader.read(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.read()),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(reader.read()),
      size: reader.read(),
      policy: CachePolicy.values[reader.read()],
      metadata: Map<String, dynamic>.from(reader.read()),
      compressed: reader.read(),
      encrypted: reader.read(),
      accessedAt: DateTime.fromMillisecondsSinceEpoch(reader.read()),
      accessCount: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, CacheItem obj) {
    writer.write(obj.key);
    writer.write(obj.value);
    writer.write(obj.createdAt.millisecondsSinceEpoch);
    writer.write(obj.expiresAt.millisecondsSinceEpoch);
    writer.write(obj.size);
    writer.write(obj.policy.index);
    writer.write(obj.metadata);
    writer.write(obj.compressed);
    writer.write(obj.encrypted);
    writer.write(obj.accessedAt.millisecondsSinceEpoch);
    writer.write(obj.accessCount);
  }
}

class CacheStatsAdapter extends TypeAdapter<CacheStats> {
  @override
  final typeId = 1;

  @override
  CacheStats read(BinaryReader reader) {
    return CacheStats(
      layer: reader.read(),
      hitCount: reader.read(),
      missCount: reader.read(),
      itemCount: reader.read(),
      totalSize: reader.read(),
      evictionCount: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, CacheStats obj) {
    writer.write(obj.layer);
    writer.write(obj.hitCount);
    writer.write(obj.missCount);
    writer.write(obj.itemCount);
    writer.write(obj.totalSize);
    writer.write(obj.evictionCount);
  }
}

class CacheEventAdapter extends TypeAdapter<CacheEvent> {
  @override
  final typeId = 2;

  @override
  CacheEvent read(BinaryReader reader) {
    return CacheEvent(
      id: reader.read(),
      type: CacheEventType.values[reader.read()],
      timestamp: DateTime.fromMillisecondsSinceEpoch(reader.read()),
      data: Map<String, dynamic>.from(reader.read()),
    );
  }

  @override
  void write(BinaryWriter writer, CacheEvent obj) {
    writer.write(obj.id);
    writer.write(obj.type.index);
    writer.write(obj.timestamp.millisecondsSinceEpoch);
    writer.write(obj.data);
  }
}
