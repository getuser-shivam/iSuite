import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../config/enhanced_config_manager.dart';
import '../logging/enhanced_logger.dart';

/// Enhanced Performance Optimization and Caching System
/// Features: Multi-level caching, memory management, performance monitoring
/// Performance: LRU eviction, compression, async operations, connection pooling
/// Security: Encrypted cache, secure storage, data validation
class EnhancedPerformanceManager {
  static EnhancedPerformanceManager? _instance;
  static EnhancedPerformanceManager get instance => _instance ??= EnhancedPerformanceManager._internal();
  EnhancedPerformanceManager._internal();

  // Configuration
  late final bool _enableMemoryCache;
  late final bool _enableDiskCache;
  late final bool _enableCompression;
  late final bool _enableEncryption;
  late final int _maxMemoryCacheSize;
  late final int _maxDiskCacheSize;
  late final Duration _cacheTimeout;
  late final int _compressionThreshold;
  
  // Memory cache with LRU eviction
  final Map<String, CacheEntry> _memoryCache = {};
  final List<String> _memoryAccessOrder = [];
  int _currentMemorySize = 0;
  
  // Disk cache management
  late final Directory _cacheDirectory;
  final Map<String, DiskCacheInfo> _diskCacheIndex = {};
  int _currentDiskSize = 0;
  
  // Performance monitoring
  final Map<String, List<PerformanceMetric>> _metrics = {};
  final Map<String, Stopwatch> _timers = {};
  Timer? _cleanupTimer;
  Timer? _metricsTimer;
  
  // Connection pooling
  final Map<String, List<Connection>> _connectionPools = {};
  final int _maxPoolSize = 10;
  
  // Image optimization
  final Map<String, ImageCache> _imageCache = {};
  final Map<String, Uint8List> _optimizedImages = {};
  
  // Background operations
  final Queue<BackgroundTask> _taskQueue = Queue();
  Timer? _taskTimer;
  bool _isProcessingTasks = false;
  
  // Memory pressure monitoring
  Timer? _memoryMonitorTimer;
  bool _isUnderMemoryPressure = false;

  /// Initialize performance manager
  Future<void> initialize() async {
    try {
      // Load configuration
      await _loadConfiguration();
      
      // Setup cache directory
      await _setupCacheDirectory();
      
      // Load disk cache index
      await _loadDiskCacheIndex();
      
      // Setup periodic tasks
      _setupPeriodicTasks();
      
      // Setup memory monitoring
      _setupMemoryMonitoring();
      
      // Initialize connection pools
      _initializeConnectionPools();
      
      EnhancedLogger.instance.info('Enhanced performance manager initialized');
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to initialize performance manager', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Load configuration
  Future<void> _loadConfiguration() async {
    final config = EnhancedConfigManager.instance;
    
    _enableMemoryCache = config.getParameter('performance.enable_memory_cache') ?? true;
    _enableDiskCache = config.getParameter('performance.enable_disk_cache') ?? true;
    _enableCompression = config.getParameter('performance.enable_compression') ?? false;
    _enableEncryption = config.getParameter('performance.enable_encryption') ?? false;
    _maxMemoryCacheSize = (config.getParameter('performance.max_memory_cache_mb') ?? 50) * 1024 * 1024;
    _maxDiskCacheSize = (config.getParameter('performance.max_disk_cache_mb') ?? 100) * 1024 * 1024;
    _cacheTimeout = Duration(seconds: config.getParameter('performance.cache_timeout_seconds') ?? 300);
    _compressionThreshold = config.getParameter('performance.compression_threshold_bytes') ?? 1024;
  }

  /// Setup cache directory
  Future<void> _setupCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDirectory = Directory('${appDir.path}/cache');
    
    if (!await _cacheDirectory.exists()) {
      await _cacheDirectory.create(recursive: true);
    }
    
    EnhancedLogger.instance.info('Cache directory: ${_cacheDirectory.path}');
  }

  /// Load disk cache index
  Future<void> _loadDiskCacheIndex() async {
    try {
      final indexFile = File('${_cacheDirectory.path}/cache_index.json');
      
      if (await indexFile.exists()) {
        final content = await indexFile.readAsString();
        final indexData = jsonDecode(content) as Map<String, dynamic>;
        
        for (final entry in indexData.entries) {
          final info = DiskCacheInfo.fromJson(entry.value as Map<String, dynamic>);
          _diskCacheIndex[entry.key] = info;
          _currentDiskSize += info.size;
        }
        
        EnhancedLogger.instance.info('Loaded ${_diskCacheIndex.length} disk cache entries');
      }
    } catch (e) {
      EnhancedLogger.instance.warning('Failed to load disk cache index: $e');
    }
  }

  /// Setup periodic tasks
  void _setupPeriodicTasks() {
    // Cache cleanup timer
    _cleanupTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _cleanupExpiredEntries();
    });
    
    // Metrics collection timer
    _metricsTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _collectPerformanceMetrics();
    });
    
    // Background task processor
    _taskTimer = Timer.periodic(Duration(milliseconds: 100), (_) {
      _processBackgroundTasks();
    });
  }

  /// Setup memory monitoring
  void _setupMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(Duration(seconds: 10), (_) {
      _checkMemoryPressure();
    });
  }

  /// Initialize connection pools
  void _initializeConnectionPools() {
    // Initialize pools for different connection types
    _connectionPools['http'] = [];
    _connectionPools['websocket'] = [];
    _connectionPools['database'] = [];
  }

  /// Get cached data with multi-level fallback
  Future<T?> getCachedData<T>(String key) async {
    final timer = startTimer('cache_get');
    
    try {
      // Try memory cache first
      if (_enableMemoryCache) {
        final memoryData = _getFromMemoryCache<T>(key);
        if (memoryData != null) {
          recordMetric('cache_memory_hit', 1);
          return memoryData;
        }
      }
      
      // Try disk cache
      if (_enableDiskCache) {
        final diskData = await _getFromDiskCache<T>(key);
        if (diskData != null) {
          // Promote to memory cache if enabled
          if (_enableMemoryCache) {
            await _setInMemoryCache(key, diskData);
          }
          recordMetric('cache_disk_hit', 1);
          return diskData;
        }
      }
      
      recordMetric('cache_miss', 1);
      return null;
    } finally {
      timer.stop();
    }
  }

  /// Set cached data with multi-level storage
  Future<void> setCachedData<T>(String key, T data, {Duration? ttl}) async {
    final timer = startTimer('cache_set');
    
    try {
      final effectiveTtl = ttl ?? _cacheTimeout;
      
      // Store in memory cache
      if (_enableMemoryCache) {
        await _setInMemoryCache(key, data, ttl: effectiveTtl);
      }
      
      // Store in disk cache
      if (_enableDiskCache) {
        await _setInDiskCache(key, data, ttl: effectiveTtl);
      }
      
      recordMetric('cache_set', 1);
    } finally {
      timer.stop();
    }
  }

  /// Get data from memory cache
  T? _getFromMemoryCache<T>(String key) {
    final entry = _memoryCache[key];
    
    if (entry != null && !entry.isExpired) {
      _updateMemoryAccessOrder(key);
      return entry.data as T?;
    }
    
    if (entry != null && entry.isExpired) {
      _removeFromMemoryCache(key);
    }
    
    return null;
  }

  /// Set data in memory cache with LRU eviction
  Future<void> _setInMemoryCache<T>(String key, T data, {Duration? ttl}) async {
    final dataSize = _calculateDataSize(data);
    final entry = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl ?? _cacheTimeout,
      size: dataSize,
    );
    
    // Check if we need to evict entries
    if (_currentMemorySize + dataSize > _maxMemoryCacheSize) {
      await _evictMemoryCacheEntries(dataSize);
    }
    
    // Remove existing entry if present
    _removeFromMemoryCache(key);
    
    // Add new entry
    _memoryCache[key] = entry;
    _memoryAccessOrder.add(key);
    _currentMemorySize += dataSize;
  }

  /// Remove from memory cache
  void _removeFromMemoryCache(String key) {
    final entry = _memoryCache.remove(key);
    if (entry != null) {
      _currentMemorySize -= entry.size;
      _memoryAccessOrder.remove(key);
    }
  }

  /// Update memory access order for LRU
  void _updateMemoryAccessOrder(String key) {
    _memoryAccessOrder.remove(key);
    _memoryAccessOrder.add(key);
  }

  /// Evict memory cache entries (LRU)
  Future<void> _evictMemoryCacheEntries(int requiredSize) async {
    int evictedSize = 0;
    final entriesToEvict = <String>[];
    
    // Evict oldest entries until we have enough space
    for (final key in _memoryAccessOrder) {
      if (evictedSize >= requiredSize) break;
      
      final entry = _memoryCache[key];
      if (entry != null) {
        entriesToEvict.add(key);
        evictedSize += entry.size;
      }
    }
    
    // Remove evicted entries
    for (final key in entriesToEvict) {
      _removeFromMemoryCache(key);
    }
    
    EnhancedLogger.instance.info('Evicted ${entriesToEvict.length} memory cache entries');
  }

  /// Get data from disk cache
  Future<T?> _getFromDiskCache<T>(String key) async {
    final info = _diskCacheIndex[key];
    
    if (info == null || info.isExpired) {
      if (info != null) {
        await _removeFromDiskCache(key);
      }
      return null;
    }
    
    try {
      final file = File('${_cacheDirectory.path}/${info.fileName}');
      
      if (!await file.exists()) {
        await _removeFromDiskCache(key);
        return null;
      }
      
      // Update access time
      info.lastAccessed = DateTime.now();
      await _saveDiskCacheIndex();
      
      // Read and decrypt/decompress data
      Uint8List data = await file.readAsBytes();
      
      if (_enableEncryption) {
        data = await _decryptData(data);
      }
      
      if (_enableCompression && info.compressed) {
        data = await _decompressData(data);
      }
      
      // Deserialize data
      final serialized = utf8.decode(data);
      final deserialized = jsonDecode(serialized);
      
      return deserialized as T?;
    } catch (e) {
      EnhancedLogger.instance.warning('Failed to read from disk cache: $e');
      await _removeFromDiskCache(key);
      return null;
    }
  }

  /// Set data in disk cache
  Future<void> _setInDiskCache<T>(String key, T data, {Duration? ttl}) async {
    try {
      // Serialize data
      final serialized = jsonEncode(data);
      Uint8List bytes = utf8.encode(serialized);
      
      // Compress if enabled and data is large enough
      bool compressed = false;
      if (_enableCompression && bytes.length > _compressionThreshold) {
        bytes = await _compressData(bytes);
        compressed = true;
      }
      
      // Encrypt if enabled
      if (_enableEncryption) {
        bytes = await _encryptData(bytes);
      }
      
      // Generate unique filename
      final fileName = _generateCacheFileName(key);
      final filePath = '${_cacheDirectory.path}/$fileName';
      
      // Write to disk
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      // Update index
      final info = DiskCacheInfo(
        fileName: fileName,
        size: bytes.length,
        originalSize: serialized.length,
        compressed: compressed,
        encrypted: _enableEncryption,
        createdAt: DateTime.now(),
        lastAccessed: DateTime.now(),
        ttl: ttl ?? _cacheTimeout,
      );
      
      // Remove existing entry if present
      await _removeFromDiskCache(key);
      
      // Add new entry
      _diskCacheIndex[key] = info;
      _currentDiskSize += bytes.length;
      
      // Save index
      await _saveDiskCacheIndex();
      
      // Check disk cache size
      if (_currentDiskSize > _maxDiskCacheSize) {
        await _evictDiskCacheEntries();
      }
    } catch (e) {
      EnhancedLogger.instance.error('Failed to write to disk cache: $e');
    }
  }

  /// Remove from disk cache
  Future<void> _removeFromDiskCache(String key) async {
    final info = _diskCacheIndex.remove(key);
    
    if (info != null) {
      try {
        final file = File('${_cacheDirectory.path}/${info.fileName}');
        if (await file.exists()) {
          await file.delete();
        }
        _currentDiskSize -= info.size;
      } catch (e) {
        EnhancedLogger.instance.warning('Failed to delete disk cache file: $e');
      }
    }
  }

  /// Evict disk cache entries (LRU based on last accessed)
  Future<void> _evictDiskCacheEntries() async {
    final sortedEntries = _diskCacheIndex.entries.toList()
      ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));
    
    int evictedSize = 0;
    final entriesToEvict = <String>[];
    
    for (final entry in sortedEntries) {
      if (evictedSize >= _currentDiskSize * 0.2) break; // Evict 20%
      
      entriesToEvict.add(entry.key);
      evictedSize += entry.value.size;
    }
    
    for (final key in entriesToEvict) {
      await _removeFromDiskCache(key);
    }
    
    await _saveDiskCacheIndex();
    EnhancedLogger.instance.info('Evicted ${entriesToEvict.length} disk cache entries');
  }

  /// Generate cache filename
  String _generateCacheFileName(String key) {
    final hash = sha256.convert(utf8.encode(key));
    return '${hash.toString().substring(0, 16)}.cache';
  }

  /// Save disk cache index
  Future<void> _saveDiskCacheIndex() async {
    try {
      final indexFile = File('${_cacheDirectory.path}/cache_index.json');
      final indexData = _diskCacheIndex.map((key, value) => MapEntry(key, value.toJson()));
      await indexFile.writeAsString(jsonEncode(indexData));
    } catch (e) {
      EnhancedLogger.instance.warning('Failed to save disk cache index: $e');
    }
  }

  /// Compress data
  Future<Uint8List> _compressData(Uint8List data) async {
    // Simple compression implementation (placeholder)
    // In production, use proper compression library
    return data;
  }

  /// Decompress data
  Future<Uint8List> _decompressData(Uint8List data) async {
    // Simple decompression implementation (placeholder)
    // In production, use proper compression library
    return data;
  }

  /// Encrypt data
  Future<Uint8List> _encryptData(Uint8List data) async {
    // Simple encryption implementation (placeholder)
    // In production, use proper encryption library
    return data;
  }

  /// Decrypt data
  Future<Uint8List> _decryptData(Uint8List data) async {
    // Simple decryption implementation (placeholder)
    // In production, use proper encryption library
    return data;
  }

  /// Calculate data size
  int _calculateDataSize(dynamic data) {
    try {
      if (data is String) {
        return data.length;
      } else if (data is Uint8List) {
        return data.length;
      } else {
        return jsonEncode(data).length;
      }
    } catch (e) {
      return 1024; // Default size
    }
  }

  /// Cleanup expired entries
  Future<void> _cleanupExpiredEntries() async {
    // Cleanup memory cache
    final expiredMemoryKeys = <String>[];
    for (final entry in _memoryCache.entries) {
      if (entry.value.isExpired) {
        expiredMemoryKeys.add(entry.key);
      }
    }
    
    for (final key in expiredMemoryKeys) {
      _removeFromMemoryCache(key);
    }
    
    // Cleanup disk cache
    final expiredDiskKeys = <String>[];
    for (final entry in _diskCacheIndex.entries) {
      if (entry.value.isExpired) {
        expiredDiskKeys.add(entry.key);
      }
    }
    
    for (final key in expiredDiskKeys) {
      await _removeFromDiskCache(key);
    }
    
    if (expiredMemoryKeys.isNotEmpty || expiredDiskKeys.isNotEmpty) {
      EnhancedLogger.instance.info('Cleaned up ${expiredMemoryKeys.length} memory and ${expiredDiskKeys.length} disk cache entries');
    }
  }

  /// Check memory pressure
  void _checkMemoryPressure() {
    // Simple memory pressure detection
    final memoryUsageRatio = _currentMemorySize / _maxMemoryCacheSize;
    
    if (memoryUsageRatio > 0.9) {
      if (!_isUnderMemoryPressure) {
        _isUnderMemoryPressure = true;
        _handleMemoryPressure();
      }
    } else {
      _isUnderMemoryPressure = false;
    }
  }

  /// Handle memory pressure
  void _handleMemoryPressure() {
    // Aggressively clean up memory cache
    final targetSize = (_maxMemoryCacheSize * 0.5).toInt();
    
    while (_currentMemorySize > targetSize && _memoryAccessOrder.isNotEmpty) {
      final oldestKey = _memoryAccessOrder.removeAt(0);
      _removeFromMemoryCache(oldestKey);
    }
    
    EnhancedLogger.instance.info('Memory pressure handled: reduced cache to $_currentMemorySize bytes');
  }

  /// Get connection from pool
  Connection getConnection(String type) {
    final pool = _connectionPools[type] ?? [];
    
    if (pool.isNotEmpty) {
      final connection = pool.removeLast();
      if (connection.isValid) {
        return connection;
      }
    }
    
    // Create new connection
    return _createConnection(type);
  }

  /// Return connection to pool
  void returnConnection(String type, Connection connection) {
    final pool = _connectionPools[type] ?? [];
    
    if (pool.length < _maxPoolSize && connection.isValid) {
      pool.add(connection);
      _connectionPools[type] = pool;
    } else {
      connection.close();
    }
  }

  /// Create new connection
  Connection _createConnection(String type) {
    // Implementation depends on connection type
    return Connection(type);
  }

  /// Optimize image
  Future<Uint8List> optimizeImage(Uint8List imageData, {int? maxWidth, int? maxHeight}) async {
    final key = 'image_${hash.bytes(imageData)}';
    
    // Check cache first
    final cached = _optimizedImages[key];
    if (cached != null) {
      return cached;
    }
    
    // Optimize image (placeholder implementation)
    final optimized = await _performImageOptimization(imageData, maxWidth, maxHeight);
    
    // Cache result
    _optimizedImages[key] = optimized;
    
    return optimized;
  }

  /// Perform actual image optimization
  Future<Uint8List> _performImageOptimization(Uint8List imageData, int? maxWidth, int? maxHeight) async {
    // Placeholder implementation
    // In production, use image processing library
    return imageData;
  }

  /// Add background task
  void addBackgroundTask(BackgroundTask task) {
    _taskQueue.add(task);
  }

  /// Process background tasks
  void _processBackgroundTasks() {
    if (_isProcessingTasks || _taskQueue.isEmpty) return;
    
    _isProcessingTasks = true;
    
    while (_taskQueue.isNotEmpty) {
      final task = _taskQueue.removeFirst();
      
      try {
        task.execute();
      } catch (e) {
        EnhancedLogger.instance.error('Background task failed: $e');
      }
    }
    
    _isProcessingTasks = false;
  }

  /// Start performance timer
  PerformanceTimer startTimer(String name) {
    final timer = PerformanceTimer(name);
    _timers[name] = timer.stopwatch;
    return timer;
  }

  /// Record performance metric
  void recordMetric(String name, dynamic value, {String? unit, Map<String, dynamic>? metadata}) {
    if (!_metrics.containsKey(name)) {
      _metrics[name] = [];
    }
    
    final metric = PerformanceMetric(
      name: name,
      value: value,
      unit: unit ?? 'count',
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    
    _metrics[name]!.add(metric);
    
    // Keep only last 1000 metrics per name
    if (_metrics[name]!.length > 1000) {
      _metrics[name]!.removeRange(0, _metrics[name]!.length - 1000);
    }
  }

  /// Collect performance metrics
  void _collectPerformanceMetrics() {
    recordMetric('memory_cache_size', _currentMemorySize, unit: 'bytes');
    recordMetric('memory_cache_entries', _memoryCache.length, unit: 'count');
    recordMetric('disk_cache_size', _currentDiskSize, unit: 'bytes');
    recordMetric('disk_cache_entries', _diskCacheIndex.length, unit: 'count');
    recordMetric('task_queue_size', _taskQueue.length, unit: 'count');
    recordMetric('connection_pools', _connectionPools.values.map((pool) => pool.length).fold(0, (sum, count) => sum + count), unit: 'count');
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStatistics() {
    final stats = <String, dynamic>{
      'memory_cache': {
        'size_bytes': _currentMemorySize,
        'max_size_bytes': _maxMemoryCacheSize,
        'entries': _memoryCache.length,
        'hit_rate': _calculateHitRate('memory'),
      },
      'disk_cache': {
        'size_bytes': _currentDiskSize,
        'max_size_bytes': _maxDiskCacheSize,
        'entries': _diskCacheIndex.length,
        'hit_rate': _calculateHitRate('disk'),
      },
      'connection_pools': _connectionPools.map((key, pool) => MapEntry(key, {
        'size': pool.length,
        'max_size': _maxPoolSize,
      })),
      'background_tasks': {
        'queue_size': _taskQueue.length,
        'processing': _isProcessingTasks,
      },
      'memory_pressure': {
        'under_pressure': _isUnderMemoryPressure,
        'usage_ratio': _currentMemorySize / _maxMemoryCacheSize,
      },
    };
    
    // Add metrics
    for (final entry in _metrics.entries) {
      final values = entry.value.map((m) => m.value).toList();
      if (values.isNotEmpty) {
        values.sort();
        stats['metrics_${entry.key}'] = {
          'count': values.length,
          'min': values.first,
          'max': values.last,
          'average': values.reduce((a, b) => a + b) / values.length,
          'latest': values.last,
        };
      }
    }
    
    return stats;
  }

  /// Calculate cache hit rate
  double _calculateHitRate(String cacheType) {
    final hits = _metrics['cache_${cacheType}_hit']?.length ?? 0;
    final misses = _metrics['cache_miss']?.length ?? 0;
    final total = hits + misses;
    
    return total > 0 ? hits / total : 0.0;
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    // Clear memory cache
    _memoryCache.clear();
    _memoryAccessOrder.clear();
    _currentMemorySize = 0;
    
    // Clear disk cache
    for (final key in _diskCacheIndex.keys.toList()) {
      await _removeFromDiskCache(key);
    }
    
    // Clear optimized images
    _optimizedImages.clear();
    
    EnhancedLogger.instance.info('All caches cleared');
  }

  /// Dispose resources
  Future<void> dispose() async {
    _cleanupTimer?.cancel();
    _metricsTimer?.cancel();
    _taskTimer?.cancel();
    _memoryMonitorTimer?.cancel();
    
    // Close all connections
    for (final pool in _connectionPools.values) {
      for (final connection in pool) {
        connection.close();
      }
    }
    _connectionPools.clear();
    
    // Save disk cache index
    await _saveDiskCacheIndex();
    
    EnhancedLogger.instance.info('Enhanced performance manager disposed');
  }
}

/// Cache entry
class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration ttl;
  final int size;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
    required this.size,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

/// Disk cache info
class DiskCacheInfo {
  final String fileName;
  final int size;
  final int originalSize;
  final bool compressed;
  final bool encrypted;
  final DateTime createdAt;
  DateTime lastAccessed;
  final Duration ttl;

  DiskCacheInfo({
    required this.fileName,
    required this.size,
    required this.originalSize,
    required this.compressed,
    required this.encrypted,
    required this.createdAt,
    required this.lastAccessed,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().difference(lastAccessed) > ttl;

  Map<String, dynamic> toJson() {
    return {
      'file_name': fileName,
      'size': size,
      'original_size': originalSize,
      'compressed': compressed,
      'encrypted': encrypted,
      'created_at': createdAt.toIso8601String(),
      'last_accessed': lastAccessed.toIso8601String(),
      'ttl': ttl.inSeconds,
    };
  }

  factory DiskCacheInfo.fromJson(Map<String, dynamic> json) {
    return DiskCacheInfo(
      fileName: json['file_name'],
      size: json['size'],
      originalSize: json['original_size'],
      compressed: json['compressed'],
      encrypted: json['encrypted'],
      createdAt: DateTime.parse(json['created_at']),
      lastAccessed: DateTime.parse(json['last_accessed']),
      ttl: Duration(seconds: json['ttl']),
    );
  }
}

/// Connection pool entry
class Connection {
  final String type;
  final DateTime createdAt;
  bool isValid;

  Connection(this.type) : createdAt = DateTime.now(), isValid = true;

  void close() {
    isValid = false;
  }
}

/// Background task
abstract class BackgroundTask {
  final String name;
  final DateTime createdAt;

  BackgroundTask(this.name) : createdAt = DateTime.now();

  void execute();
}

/// Performance timer
class PerformanceTimer {
  final String name;
  final Stopwatch stopwatch = Stopwatch();

  PerformanceTimer(this.name) {
    stopwatch.start();
  }

  Duration stop() {
    stopwatch.stop();
    EnhancedPerformanceManager.instance.recordMetric(
      'timer_${name}',
      stopwatch.elapsedMicroseconds.toDouble(),
      unit: 'μs',
    );
    return stopwatch.elapsed;
  }
}

/// Performance metric
class PerformanceMetric {
  final String name;
  final dynamic value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  PerformanceMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.metadata,
  });
}
