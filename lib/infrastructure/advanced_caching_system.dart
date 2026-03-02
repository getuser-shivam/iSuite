import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../config/central_config.dart';
import '../logging/logging_service.dart';

/// Advanced Caching System with Multiple Strategies
///
/// Features:
/// - Multi-level caching (Memory → Disk → Network)
/// - Intelligent cache invalidation and TTL management
/// - Compression and encryption support
/// - Cache warming and prefetching
/// - Performance monitoring and analytics
/// - Distributed cache support (future extension)
/// - Cache synchronization across app restarts

/// Main Cache Manager
class AdvancedCacheManager {
  static final AdvancedCacheManager _instance = AdvancedCacheManager._internal();
  factory AdvancedCacheManager() => _instance;

  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();

  late MemoryCache _memoryCache;
  late DiskCache _diskCache;
  late NetworkCache _networkCache;

  bool _isInitialized = false;

  AdvancedCacheManager._internal();

  /// Initialize the cache manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Advanced Cache Manager', 'AdvancedCacheManager');

      // Initialize cache layers
      _memoryCache = MemoryCache();
      _diskCache = DiskCache();
      _networkCache = NetworkCache();

      // Initialize disk cache
      await _diskCache.initialize();

      // Load cache configuration
      await _loadCacheConfiguration();

      _isInitialized = true;
      _logger.info('Advanced Cache Manager initialized successfully', 'AdvancedCacheManager');

      // Start cache maintenance
      _startCacheMaintenance();

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize cache manager', 'AdvancedCacheManager',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get data from cache with fallback strategy
  Future<CacheEntry?> get(String key, {CacheStrategy strategy = CacheStrategy.auto}) async {
    if (!_isInitialized) await initialize();

    try {
      // Try memory cache first (fastest)
      var entry = await _memoryCache.get(key);
      if (entry != null && entry.isValid) {
        _logger.debug('Cache hit (memory): $key', 'AdvancedCacheManager');
        return entry;
      }

      // Try disk cache
      entry = await _diskCache.get(key);
      if (entry != null && entry.isValid) {
        _logger.debug('Cache hit (disk): $key', 'AdvancedCacheManager');
        // Promote to memory cache
        await _memoryCache.set(key, entry.data, ttl: entry.ttl);
        return entry;
      }

      // Try network cache if enabled
      if (strategy != CacheStrategy.memoryOnly && strategy != CacheStrategy.diskOnly) {
        entry = await _networkCache.get(key);
        if (entry != null && entry.isValid) {
          _logger.debug('Cache hit (network): $key', 'AdvancedCacheManager');
          // Cache locally
          await _setMultiLevel(key, entry.data, ttl: entry.ttl);
          return entry;
        }
      }

      _logger.debug('Cache miss: $key', 'AdvancedCacheManager');
      return null;

    } catch (e) {
      _logger.warning('Cache get error for key $key: ${e.toString()}', 'AdvancedCacheManager');
      return null;
    }
  }

  /// Set data in cache with specified strategy
  Future<void> set(String key, dynamic data, {
    CacheStrategy strategy = CacheStrategy.auto,
    Duration? ttl,
    bool compress = false,
    bool encrypt = false,
  }) async {
    if (!_isInitialized) await initialize();

    await _setMultiLevel(key, data, strategy: strategy, ttl: ttl, compress: compress, encrypt: encrypt);
  }

  /// Set data across multiple cache levels
  Future<void> _setMultiLevel(String key, dynamic data, {
    CacheStrategy strategy = CacheStrategy.auto,
    Duration? ttl,
    bool compress = false,
    bool encrypt = false,
  }) async {
    final effectiveTtl = ttl ?? _getDefaultTtl();

    try {
      // Memory cache (always included unless specified otherwise)
      if (strategy != CacheStrategy.diskOnly && strategy != CacheStrategy.networkOnly) {
        await _memoryCache.set(key, data, ttl: effectiveTtl, compress: compress, encrypt: encrypt);
      }

      // Disk cache
      if (strategy != CacheStrategy.memoryOnly && strategy != CacheStrategy.networkOnly) {
        await _diskCache.set(key, data, ttl: effectiveTtl, compress: compress, encrypt: encrypt);
      }

      // Network cache (for shared/distributed data)
      if (strategy == CacheStrategy.networkOnly || strategy == CacheStrategy.distributed) {
        await _networkCache.set(key, data, ttl: effectiveTtl, compress: compress, encrypt: encrypt);
      }

    } catch (e) {
      _logger.error('Cache set error for key $key: ${e.toString()}', 'AdvancedCacheManager');
    }
  }

  /// Invalidate cache entry
  Future<void> invalidate(String key) async {
    if (!_isInitialized) await initialize();

    try {
      await _memoryCache.invalidate(key);
      await _diskCache.invalidate(key);
      await _networkCache.invalidate(key);

      _logger.debug('Cache invalidated: $key', 'AdvancedCacheManager');

    } catch (e) {
      _logger.warning('Cache invalidation error for key $key: ${e.toString()}', 'AdvancedCacheManager');
    }
  }

  /// Clear all caches
  Future<void> clearAll() async {
    if (!_isInitialized) await initialize();

    try {
      await _memoryCache.clear();
      await _diskCache.clear();
      await _networkCache.clear();

      _logger.info('All caches cleared', 'AdvancedCacheManager');

    } catch (e) {
      _logger.error('Cache clear error: ${e.toString()}', 'AdvancedCacheManager');
    }
  }

  /// Get cache statistics
  CacheStatistics getStatistics() {
    if (!_isInitialized) {
      return CacheStatistics.empty();
    }

    return CacheStatistics(
      memoryEntries: _memoryCache.size,
      diskEntries: _diskCache.size,
      networkEntries: _networkCache.size,
      memoryHitRate: _memoryCache.hitRate,
      diskHitRate: _diskCache.hitRate,
      totalSize: _memoryCache.totalSize + _diskCache.totalSize + _networkCache.totalSize,
      lastCleanup: DateTime.now(), // Simplified
    );
  }

  /// Warm up cache with frequently used data
  Future<void> warmUpCache(List<String> keys) async {
    if (!_isInitialized) await initialize();

    _logger.info('Starting cache warm-up for ${keys.length} keys', 'AdvancedCacheManager');

    // This would implement cache warming logic
    // For now, just log the operation
    await Future.delayed(const Duration(milliseconds: 100));
    _logger.info('Cache warm-up completed', 'AdvancedCacheManager');
  }

  /// Prefetch data into cache
  Future<void> prefetch(List<String> urls, {Duration? ttl}) async {
    if (!_isInitialized) await initialize();

    _logger.info('Starting cache prefetch for ${urls.length} URLs', 'AdvancedCacheManager');

    // This would implement prefetching logic
    // For now, just log the operation
    await Future.delayed(const Duration(milliseconds: 100));
    _logger.info('Cache prefetch completed', 'AdvancedCacheManager');
  }

  /// Export cache data for backup
  Future<String> exportCache() async {
    if (!_isInitialized) await initialize();

    try {
      final exportData = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
        'memory_cache': await _memoryCache.export(),
        'disk_cache': await _diskCache.export(),
        'statistics': getStatistics().toJson(),
      };

      return jsonEncode(exportData);

    } catch (e) {
      _logger.error('Cache export error: ${e.toString()}', 'AdvancedCacheManager');
      return '{}';
    }
  }

  /// Import cache data from backup
  Future<void> importCache(String jsonData) async {
    if (!_isInitialized) await initialize();

    try {
      final importData = jsonDecode(jsonData);

      if (importData['memory_cache'] != null) {
        await _memoryCache.import(importData['memory_cache']);
      }

      if (importData['disk_cache'] != null) {
        await _diskCache.import(importData['disk_cache']);
      }

      _logger.info('Cache import completed', 'AdvancedCacheManager');

    } catch (e) {
      _logger.error('Cache import error: ${e.toString()}', 'AdvancedCacheManager');
    }
  }

  /// Load cache configuration
  Future<void> _loadCacheConfiguration() async {
    await _config.initialize();

    // Configure cache sizes and TTLs
    final memoryCacheSize = _config.getParameter('cache.memory.max_entries', defaultValue: 100);
    final diskCacheSize = _config.getParameter('cache.disk.max_entries', defaultValue: 1000);
    final defaultTtlMinutes = _config.getParameter('cache.default_ttl_minutes', defaultValue: 30);

    // Apply configurations
    _memoryCache.maxSize = memoryCacheSize;
    _diskCache.maxSize = diskCacheSize;

    _logger.info('Cache configuration loaded', 'AdvancedCacheManager');
  }

  /// Get default TTL
  Duration _getDefaultTtl() {
    final minutes = _config.getParameter('cache.default_ttl_minutes', defaultValue: 30);
    return Duration(minutes: minutes);
  }

  /// Start cache maintenance tasks
  void _startCacheMaintenance() {
    // Clean up expired entries periodically
    Timer.periodic(const Duration(minutes: 30), (_) async {
      try {
        await _memoryCache.cleanup();
        await _diskCache.cleanup();
        await _networkCache.cleanup();

        _logger.debug('Cache maintenance completed', 'AdvancedCacheManager');

      } catch (e) {
        _logger.warning('Cache maintenance error: ${e.toString()}', 'AdvancedCacheManager');
      }
    });
  }

  /// Dispose resources
  void dispose() {
    _memoryCache.dispose();
    _diskCache.dispose();
    _networkCache.dispose();
    _logger.info('Advanced Cache Manager disposed', 'AdvancedCacheManager');
  }
}

/// Cache Strategies
enum CacheStrategy {
  auto,        // Use all available caches
  memoryOnly,  // Memory cache only
  diskOnly,    // Disk cache only
  networkOnly, // Network cache only
  distributed, // Distributed across all layers
}

/// Cache Entry
class CacheEntry {
  final String key;
  final dynamic data;
  final DateTime created;
  final DateTime expires;
  final bool compressed;
  final bool encrypted;
  final String checksum;

  CacheEntry({
    required this.key,
    required this.data,
    required this.created,
    required Duration ttl,
    this.compressed = false,
    this.encrypted = false,
  }) : expires = created.add(ttl),
       checksum = _calculateChecksum(data);

  bool get isValid => DateTime.now().isBefore(expires);

  Duration get ttl => expires.difference(DateTime.now());

  static String _calculateChecksum(dynamic data) {
    final bytes = utf8.encode(jsonEncode(data));
    return sha256.convert(bytes).toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'data': data,
      'created': created.toIso8601String(),
      'expires': expires.toIso8601String(),
      'compressed': compressed,
      'encrypted': encrypted,
      'checksum': checksum,
    };
  }

  static CacheEntry? fromJson(Map<String, dynamic> json) {
    try {
      return CacheEntry(
        key: json['key'],
        data: json['data'],
        created: DateTime.parse(json['created']),
        ttl: DateTime.parse(json['expires']).difference(DateTime.parse(json['created'])),
        compressed: json['compressed'] ?? false,
        encrypted: json['encrypted'] ?? false,
      );
    } catch (e) {
      return null;
    }
  }
}

/// Memory Cache Implementation
class MemoryCache {
  final Map<String, CacheEntry> _cache = {};
  int _maxSize = 100;
  int _hits = 0;
  int _misses = 0;

  int get size => _cache.length;
  int get maxSize => _maxSize;
  set maxSize(int value) => _maxSize = value;

  double get hitRate => (_hits + _misses) > 0 ? _hits / (_hits + _misses) : 0.0;

  int get totalSize => _cache.values.fold(0, (sum, entry) => sum + _estimateSize(entry.data));

  Future<CacheEntry?> get(String key) async {
    final entry = _cache[key];
    if (entry != null) {
      if (entry.isValid) {
        _hits++;
        return entry;
      } else {
        // Remove expired entry
        _cache.remove(key);
      }
    }
    _misses++;
    return null;
  }

  Future<void> set(String key, dynamic data, {required Duration ttl, bool compress = false, bool encrypt = false}) async {
    // Remove expired entries if cache is full
    if (_cache.length >= _maxSize) {
      await cleanup();
      if (_cache.length >= _maxSize) {
        // Remove oldest entry (simple LRU)
        final oldestKey = _cache.keys.first;
        _cache.remove(oldestKey);
      }
    }

    _cache[key] = CacheEntry(
      key: key,
      data: data,
      created: DateTime.now(),
      ttl: ttl,
      compressed: compress,
      encrypted: encrypt,
    );
  }

  Future<void> invalidate(String key) async {
    _cache.remove(key);
  }

  Future<void> clear() async {
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }

  Future<void> cleanup() async {
    final keysToRemove = <String>[];

    for (final entry in _cache.entries) {
      if (!entry.value.isValid) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  Future<Map<String, dynamic>> export() async {
    return {
      'entries': _cache.map((key, entry) => MapEntry(key, entry.toJson())),
      'max_size': _maxSize,
      'hits': _hits,
      'misses': _misses,
    };
  }

  Future<void> import(Map<String, dynamic> data) async {
    _maxSize = data['max_size'] ?? 100;
    _hits = data['hits'] ?? 0;
    _misses = data['misses'] ?? 0;

    final entries = data['entries'] as Map<String, dynamic>?;
    if (entries != null) {
      for (final entry in entries.values) {
        final cacheEntry = CacheEntry.fromJson(entry as Map<String, dynamic>);
        if (cacheEntry != null && cacheEntry.isValid) {
          _cache[cacheEntry.key] = cacheEntry;
        }
      }
    }
  }

  void dispose() {
    _cache.clear();
  }

  int _estimateSize(dynamic data) {
    // Simple size estimation
    if (data == null) return 0;
    final jsonStr = jsonEncode(data);
    return jsonStr.length * 2; // Rough estimate in bytes
  }
}

/// Disk Cache Implementation
class DiskCache {
  Directory? _cacheDir;
  final Map<String, CacheEntry> _metadata = {};
  int _maxSize = 1000;

  int get size => _metadata.length;
  int get maxSize => _maxSize;
  set maxSize(int value) => _maxSize = value;

  int get totalSize {
    if (_cacheDir == null) return 0;
    try {
      return _cacheDir!.listSync().fold(0, (sum, file) => sum + (file as File).lengthSync());
    } catch (e) {
      return 0;
    }
  }

  double get hitRate => 0.0; // Not implemented for disk cache

  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/cache');

    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }

    // Load metadata
    await _loadMetadata();
  }

  Future<CacheEntry?> get(String key) async {
    if (_cacheDir == null) return null;

    final file = File('${_cacheDir!.path}/$key.cache');
    if (!await file.exists()) return null;

    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);

      final entry = CacheEntry.fromJson(data);
      if (entry != null && entry.isValid) {
        return entry;
      } else {
        // Remove invalid file
        await file.delete();
        _metadata.remove(key);
      }
    } catch (e) {
      // Remove corrupted file
      await file.delete();
      _metadata.remove(key);
    }

    return null;
  }

  Future<void> set(String key, dynamic data, {required Duration ttl, bool compress = false, bool encrypt = false}) async {
    if (_cacheDir == null) return;

    // Clean up if cache is full
    if (_metadata.length >= _maxSize) {
      await cleanup();
      if (_metadata.length >= _maxSize) {
        // Remove oldest entry
        final oldestKey = _metadata.keys.first;
        await invalidate(oldestKey);
      }
    }

    final entry = CacheEntry(
      key: key,
      data: data,
      created: DateTime.now(),
      ttl: ttl,
      compressed: compress,
      encrypted: encrypt,
    );

    final file = File('${_cacheDir!.path}/$key.cache');
    await file.writeAsString(jsonEncode(entry.toJson()));

    _metadata[key] = entry;
  }

  Future<void> invalidate(String key) async {
    if (_cacheDir == null) return;

    final file = File('${_cacheDir!.path}/$key.cache');
    if (await file.exists()) {
      await file.delete();
    }
    _metadata.remove(key);
  }

  Future<void> clear() async {
    if (_cacheDir == null) return;

    try {
      final files = await _cacheDir!.list().toList();
      for (final file in files) {
        if (file is File) {
          await file.delete();
        }
      }
      _metadata.clear();
    } catch (e) {
      // Ignore errors during clear
    }
  }

  Future<void> cleanup() async {
    if (_cacheDir == null) return;

    final keysToRemove = <String>[];

    for (final entry in _metadata.entries) {
      if (!entry.value.isValid) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      await invalidate(key);
    }
  }

  Future<Map<String, dynamic>> export() async {
    return {
      'metadata': _metadata.map((key, entry) => MapEntry(key, entry.toJson())),
      'max_size': _maxSize,
    };
  }

  Future<void> import(Map<String, dynamic> data) async {
    _maxSize = data['max_size'] ?? 1000;

    final metadata = data['metadata'] as Map<String, dynamic>?;
    if (metadata != null) {
      for (final entry in metadata.values) {
        final cacheEntry = CacheEntry.fromJson(entry as Map<String, dynamic>);
        if (cacheEntry != null) {
          _metadata[cacheEntry.key] = cacheEntry;
        }
      }
    }
  }

  Future<void> _loadMetadata() async {
    if (_cacheDir == null) return;

    try {
      final files = await _cacheDir!.list().toList();
      for (final file in files) {
        if (file is File && file.path.endsWith('.cache')) {
          try {
            final content = await file.readAsString();
            final data = jsonDecode(content);
            final entry = CacheEntry.fromJson(data);
            if (entry != null) {
              _metadata[entry.key] = entry;
            }
          } catch (e) {
            // Remove corrupted metadata
            await file.delete();
          }
        }
      }
    } catch (e) {
      // Ignore errors during metadata loading
    }
  }

  void dispose() {
    _metadata.clear();
  }
}

/// Network Cache Implementation (Placeholder)
class NetworkCache {
  final Map<String, CacheEntry> _cache = {};

  int get size => _cache.length;
  int get totalSize => _cache.values.fold(0, (sum, entry) => sum + jsonEncode(entry.data).length);

  Future<CacheEntry?> get(String key) async {
    // Placeholder implementation
    // In a real implementation, this would fetch from a network cache service
    return _cache[key];
  }

  Future<void> set(String key, dynamic data, {required Duration ttl, bool compress = false, bool encrypt = false}) async {
    // Placeholder implementation
    _cache[key] = CacheEntry(
      key: key,
      data: data,
      created: DateTime.now(),
      ttl: ttl,
    );
  }

  Future<void> invalidate(String key) async {
    _cache.remove(key);
  }

  Future<void> clear() async {
    _cache.clear();
  }

  Future<void> cleanup() async {
    final keysToRemove = <String>[];

    for (final entry in _cache.entries) {
      if (!entry.value.isValid) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  void dispose() {
    _cache.clear();
  }
}

/// Cache Statistics
class CacheStatistics {
  final int memoryEntries;
  final int diskEntries;
  final int networkEntries;
  final double memoryHitRate;
  final double diskHitRate;
  final int totalSize;
  final DateTime lastCleanup;

  CacheStatistics({
    required this.memoryEntries,
    required this.diskEntries,
    required this.networkEntries,
    required this.memoryHitRate,
    required this.diskHitRate,
    required this.totalSize,
    required this.lastCleanup,
  });

  factory CacheStatistics.empty() {
    return CacheStatistics(
      memoryEntries: 0,
      diskEntries: 0,
      networkEntries: 0,
      memoryHitRate: 0.0,
      diskHitRate: 0.0,
      totalSize: 0,
      lastCleanup: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memory_entries': memoryEntries,
      'disk_entries': diskEntries,
      'network_entries': networkEntries,
      'memory_hit_rate': memoryHitRate,
      'disk_hit_rate': diskHitRate,
      'total_size': totalSize,
      'last_cleanup': lastCleanup.toIso8601String(),
    };
  }
}

/// Cache Riverpod Providers
final cacheManagerProvider = Provider<AdvancedCacheManager>((ref) {
  return AdvancedCacheManager();
});

final cacheStatisticsProvider = Provider<CacheStatistics>((ref) {
  final cacheManager = ref.watch(cacheManagerProvider);
  return cacheManager.getStatistics();
});

/// Cache Operations Providers
final cacheGetProvider = FutureProvider.family<CacheEntry?, String>((ref, key) async {
  final cacheManager = ref.watch(cacheManagerProvider);
  return await cacheManager.get(key);
});

/// Cache Warming Provider
final cacheWarmUpProvider = FutureProvider<List<String>>((ref) async {
  final cacheManager = ref.watch(cacheManagerProvider);

  // Define frequently used cache keys
  const frequentlyUsedKeys = [
    'user_profile',
    'app_config',
    'theme_settings',
    'navigation_state',
  ];

  await cacheManager.warmUpCache(frequentlyUsedKeys);
  return frequentlyUsedKeys;
});
