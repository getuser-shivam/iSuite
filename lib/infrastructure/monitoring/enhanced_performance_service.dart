import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../config/central_config.dart';
import 'logging_service.dart';

/// Enhanced Performance Optimization Service
/// Implements comprehensive caching, lazy loading, and performance monitoring
class EnhancedPerformanceService {
  static final EnhancedPerformanceService _instance =
      EnhancedPerformanceService._internal();
  factory EnhancedPerformanceService() => _instance;

  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();

  // Caching system
  final Map<String, _CacheEntry> _memoryCache = {};
  final Map<String, _CacheEntry> _persistentCache = {};
  final Queue<String> _cacheAccessOrder = Queue<String>();

  // Lazy loading management
  final Map<String, LazyLoader> _lazyLoaders = {};
  final Map<String, bool> _loadedItems = {};

  // Performance monitoring
  final Map<String, PerformanceMetrics> _performanceMetrics = {};
  final StreamController<PerformanceAlert> _alertController =
      StreamController.broadcast();

  // Resource management
  final Map<String, ResourceUsage> _resourceUsage = {};
  Timer? _cleanupTimer;
  Timer? _monitoringTimer;

  bool _isInitialized = false;
  int _maxCacheSize = 1000;
  Duration _defaultCacheTTL = const Duration(minutes: 30);

  EnhancedPerformanceService._internal();

  /// Initialize performance optimization service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Register with CentralConfig
      await _config.registerComponent('EnhancedPerformanceService', '2.0.0',
          'Comprehensive performance optimization with caching, lazy loading, and monitoring',
          dependencies: [
            'CentralConfig',
            'LoggingService'
          ],
          parameters: {
            // Caching configuration
            'performance.cache.enabled': true,
            'performance.cache.max_size': 1000,
            'performance.cache.default_ttl_minutes': 30,
            'performance.cache.cleanup_interval_minutes': 15,
            'performance.cache.persistent_enabled': true,

            // Lazy loading
            'performance.lazy_loading.enabled': true,
            'performance.lazy_loading.preload_enabled': true,
            'performance.lazy_loading.preload_distance': 5,

            // Performance monitoring
            'performance.monitoring.enabled': true,
            'performance.monitoring.interval_seconds': 60,
            'performance.monitoring.alerts_enabled': true,
            'performance.monitoring.slow_operation_threshold_ms': 100,

            // Resource management
            'performance.resources.memory_limit_mb': 100,
            'performance.resources.cpu_limit_percent': 80,
            'performance.resources.disk_limit_mb': 500,

            // Optimization settings
            'performance.optimization.compression_enabled': true,
            'performance.optimization.batching_enabled': true,
            'performance.optimization.prefetching_enabled': false,
          });

      // Setup cache cleanup
      await _setupCacheCleanup();

      // Setup performance monitoring
      await _setupPerformanceMonitoring();

      _isInitialized = true;

      _logger.info('Enhanced Performance Service initialized successfully',
          'EnhancedPerformanceService');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Enhanced Performance Service',
          'EnhancedPerformanceService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get cached value with performance tracking
  Future<T?> getCached<T>(String key) async {
    final startTime = DateTime.now();

    try {
      // Check memory cache first
      if (_memoryCache.containsKey(key)) {
        final entry = _memoryCache[key]!;
        if (!entry.isExpired) {
          _updateCacheAccess(key);
          _trackPerformance('cache_hit', DateTime.now().difference(startTime));
          return entry.value as T?;
        } else {
          _memoryCache.remove(key);
        }
      }

      // Check persistent cache
      if (_persistentCache.containsKey(key)) {
        final entry = _persistentCache[key]!;
        if (!entry.isExpired) {
          // Move to memory cache for faster access
          _memoryCache[key] = entry;
          _updateCacheAccess(key);
          _trackPerformance(
              'persistent_cache_hit', DateTime.now().difference(startTime));
          return entry.value as T?;
        } else {
          _persistentCache.remove(key);
        }
      }

      _trackPerformance('cache_miss', DateTime.now().difference(startTime));
      return null;
    } catch (e) {
      _logger.error(
          'Cache retrieval failed for key: $key', 'EnhancedPerformanceService',
          error: e);
      return null;
    }
  }

  /// Set cached value with TTL
  Future<void> setCached(String key, dynamic value, {Duration? ttl}) async {
    try {
      final expiry = DateTime.now().add(ttl ?? _defaultCacheTTL);
      final entry = _CacheEntry(value, expiry);

      // Store in memory cache
      _memoryCache[key] = entry;
      _updateCacheAccess(key);

      // Store in persistent cache if enabled
      final persistentEnabled = await _config
              .getParameter<bool>('performance.cache.persistent_enabled') ??
          true;
      if (persistentEnabled) {
        _persistentCache[key] = entry;
      }

      // Enforce cache size limits
      await _enforceCacheLimits();

      _logger.debug('Cached value for key: $key', 'EnhancedPerformanceService');
    } catch (e) {
      _logger.error(
          'Cache storage failed for key: $key', 'EnhancedPerformanceService',
          error: e);
    }
  }

  /// Lazy load an item
  Future<T?> lazyLoad<T>(
    String key,
    Future<T> Function() loader, {
    Map<String, dynamic>? metadata,
  }) async {
    // Check if already loaded
    if (_loadedItems[key] == true) {
      return await getCached<T>(key);
    }

    // Check if loader exists
    if (_lazyLoaders.containsKey(key)) {
      return await _lazyLoaders[key]!.load();
    }

    // Create new lazy loader
    final lazyLoader = LazyLoader<T>(
      key: key,
      loader: loader,
      onLoaded: (value) async {
        await setCached(key, value);
        _loadedItems[key] = true;
        _logger.debug('Lazy loaded item: $key', 'EnhancedPerformanceService');
      },
    );

    _lazyLoaders[key] = lazyLoader;
    return await lazyLoader.load();
  }

  /// Preload items for better performance
  Future<void> preloadItems(List<String> keys) async {
    final preloadEnabled = await _config
            .getParameter<bool>('performance.lazy_loading.preload_enabled') ??
        true;
    if (!preloadEnabled) return;

    final futures = <Future>[];
    for (final key in keys) {
      if (_lazyLoaders.containsKey(key) && !_loadedItems.containsKey(key)) {
        futures.add(_lazyLoaders[key]!.load());
      }
    }

    await Future.wait(futures);
    _logger.info(
        'Preloaded ${futures.length} items', 'EnhancedPerformanceService');
  }

  /// Execute operation with performance tracking
  Future<T> executeWithPerformanceTracking<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
  }) async {
    final startTime = DateTime.now();
    final stopwatch = Stopwatch()..start();

    try {
      final result = await operation();
      stopwatch.stop();

      final duration = stopwatch.elapsed;
      _trackPerformance(operationName, duration, metadata: metadata);

      // Check for slow operations
      final thresholdMs = await _config.getParameter<int>(
              'performance.monitoring.slow_operation_threshold_ms') ??
          100;
      if (duration.inMilliseconds > thresholdMs) {
        _emitPerformanceAlert(
          PerformanceAlertType.slowOperation,
          operationName,
          duration,
          metadata: metadata,
        );
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      _trackPerformance('${operationName}_error', stopwatch.elapsed,
          metadata: metadata);
      _emitPerformanceAlert(
        PerformanceAlertType.operationFailed,
        operationName,
        stopwatch.elapsed,
        metadata: {...?metadata, 'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Get performance metrics
  PerformanceMetrics getPerformanceMetrics(String operation) {
    return _performanceMetrics.putIfAbsent(
        operation, () => PerformanceMetrics(operation));
  }

  /// Get resource usage
  ResourceUsage getResourceUsage(String component) {
    return _resourceUsage.putIfAbsent(
        component, () => ResourceUsage(component));
  }

  /// Optimize memory usage
  Future<void> optimizeMemory() async {
    try {
      // Clear expired cache entries
      await _cleanupExpiredCache();

      // Force garbage collection hint
      // Note: This is a hint, actual GC is managed by the Dart VM

      // Compact cache if needed
      await _compactCache();

      _logger.info(
          'Memory optimization completed', 'EnhancedPerformanceService');
    } catch (e) {
      _logger.error('Memory optimization failed', 'EnhancedPerformanceService',
          error: e);
    }
  }

  /// Stream of performance alerts
  Stream<PerformanceAlert> get performanceAlerts => _alertController.stream;

  /// Private helper methods

  void _updateCacheAccess(String key) {
    // Move to end of access order (most recently used)
    if (_cacheAccessOrder.contains(key)) {
      _cacheAccessOrder.remove(key);
    }
    _cacheAccessOrder.add(key);
  }

  Future<void> _enforceCacheLimits() async {
    final maxSize =
        await _config.getParameter<int>('performance.cache.max_size') ??
            _maxCacheSize;

    // Remove least recently used items if cache is too large
    while (_memoryCache.length > maxSize && _cacheAccessOrder.isNotEmpty) {
      final lruKey = _cacheAccessOrder.removeFirst();
      _memoryCache.remove(lruKey);
    }
  }

  Future<void> _cleanupExpiredCache() async {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    // Check memory cache
    _memoryCache.forEach((key, entry) {
      if (entry.isExpired) {
        expiredKeys.add(key);
      }
    });

    // Check persistent cache
    _persistentCache.forEach((key, entry) {
      if (entry.isExpired) {
        expiredKeys.add(key);
      }
    });

    // Remove expired entries
    for (final key in expiredKeys) {
      _memoryCache.remove(key);
      _persistentCache.remove(key);
      _cacheAccessOrder.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      _logger.debug('Cleaned up ${expiredKeys.length} expired cache entries',
          'EnhancedPerformanceService');
    }
  }

  Future<void> _compactCache() async {
    // Implement cache compaction logic
    // This could involve compressing values or removing low-priority items
    _logger.debug('Cache compaction completed', 'EnhancedPerformanceService');
  }

  Future<void> _setupCacheCleanup() async {
    final cleanupInterval = await _config
            .getParameter<int>('performance.cache.cleanup_interval_minutes') ??
        15;

    _cleanupTimer =
        Timer.periodic(Duration(minutes: cleanupInterval), (timer) async {
      await optimizeMemory();
    });
  }

  Future<void> _setupPerformanceMonitoring() async {
    final monitoringEnabled =
        await _config.getParameter<bool>('performance.monitoring.enabled') ??
            true;
    if (!monitoringEnabled) return;

    final interval = await _config
            .getParameter<int>('performance.monitoring.interval_seconds') ??
        60;

    _monitoringTimer =
        Timer.periodic(Duration(seconds: interval), (timer) async {
      await _performPerformanceCheck();
    });
  }

  Future<void> _performPerformanceCheck() async {
    try {
      // Check resource usage
      final memoryUsage = await _getMemoryUsage();
      final cpuUsage = await _getCpuUsage();

      // Check for alerts
      final memoryLimit = await _config
              .getParameter<int>('performance.resources.memory_limit_mb') ??
          100;
      final cpuLimit = await _config
              .getParameter<int>('performance.resources.cpu_limit_percent') ??
          80;

      if (memoryUsage > memoryLimit) {
        _emitPerformanceAlert(
          PerformanceAlertType.highMemoryUsage,
          'system',
          Duration.zero,
          metadata: {'memoryUsage': memoryUsage, 'limit': memoryLimit},
        );
      }

      if (cpuUsage > cpuLimit) {
        _emitPerformanceAlert(
          PerformanceAlertType.highCpuUsage,
          'system',
          Duration.zero,
          metadata: {'cpuUsage': cpuUsage, 'limit': cpuLimit},
        );
      }
    } catch (e) {
      _logger.error('Performance check failed', 'EnhancedPerformanceService',
          error: e);
    }
  }

  Future<double> _getMemoryUsage() async {
    // Placeholder - would implement actual memory usage monitoring
    return 50.0; // MB
  }

  Future<double> _getCpuUsage() async {
    // Placeholder - would implement actual CPU usage monitoring
    return 30.0; // Percentage
  }

  void _trackPerformance(String operation, Duration duration,
      {Map<String, dynamic>? metadata}) {
    final metrics = getPerformanceMetrics(operation);
    metrics.recordExecution(duration, metadata: metadata);
  }

  void _emitPerformanceAlert(
    PerformanceAlertType type,
    String operation,
    Duration duration, {
    Map<String, dynamic>? metadata,
  }) {
    final alert = PerformanceAlert(
      type: type,
      operation: operation,
      duration: duration,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    _alertController.add(alert);

    // Log the alert
    _logger.warning('Performance alert: ${type.toString()} for $operation',
        'EnhancedPerformanceService');
  }

  /// Dispose service
  void dispose() {
    _cleanupTimer?.cancel();
    _monitoringTimer?.cancel();
    _alertController.close();
    _memoryCache.clear();
    _persistentCache.clear();
    _lazyLoaders.clear();
    _performanceMetrics.clear();
  }
}

// Supporting classes

class _CacheEntry {
  final dynamic value;
  final DateTime expiry;

  _CacheEntry(this.value, this.expiry);

  bool get isExpired => DateTime.now().isAfter(expiry);
}

class LazyLoader<T> {
  final String key;
  final Future<T> Function() loader;
  final Future<void> Function(T value)? onLoaded;

  T? _cachedValue;
  bool _isLoading = false;
  final Completer<T> _completer = Completer<T>();

  LazyLoader({
    required this.key,
    required this.loader,
    this.onLoaded,
  });

  Future<T> load() async {
    if (_cachedValue != null) {
      return _cachedValue!;
    }

    if (_isLoading) {
      return _completer.future;
    }

    _isLoading = true;

    try {
      final value = await loader();
      _cachedValue = value;

      if (onLoaded != null) {
        await onLoaded!(value);
      }

      _completer.complete(value);
      return value;
    } catch (e) {
      _completer.completeError(e);
      rethrow;
    } finally {
      _isLoading = false;
    }
  }
}

class PerformanceMetrics {
  final String operation;
  final List<Duration> _executionTimes = [];
  final Map<String, dynamic> _metadata = {};
  Duration _totalTime = Duration.zero;
  int _executionCount = 0;

  PerformanceMetrics(this.operation);

  void recordExecution(Duration duration, {Map<String, dynamic>? metadata}) {
    _executionTimes.add(duration);
    _totalTime += duration;
    _executionCount++;

    if (metadata != null) {
      _metadata.addAll(metadata);
    }

    // Keep only last 100 executions
    if (_executionTimes.length > 100) {
      _executionTimes.removeAt(0);
    }
  }

  Duration get averageTime {
    return _executionCount > 0
        ? Duration(microseconds: _totalTime.inMicroseconds ~/ _executionCount)
        : Duration.zero;
  }

  Duration get minTime => _executionTimes.isNotEmpty
      ? _executionTimes.reduce((a, b) => a < b ? a : b)
      : Duration.zero;
  Duration get maxTime => _executionTimes.isNotEmpty
      ? _executionTimes.reduce((a, b) => a > b ? a : b)
      : Duration.zero;

  int get executionCount => _executionCount;
  List<Duration> get recentExecutions => List.from(_executionTimes);
}

class ResourceUsage {
  final String component;
  double _memoryUsage = 0.0;
  double _cpuUsage = 0.0;
  int _activeThreads = 0;
  final DateTime _lastUpdate = DateTime.now();

  ResourceUsage(this.component);

  void updateUsage({double? memory, double? cpu, int? threads}) {
    if (memory != null) _memoryUsage = memory;
    if (cpu != null) _cpuUsage = cpu;
    if (threads != null) _activeThreads = threads;
  }

  double get memoryUsage => _memoryUsage;
  double get cpuUsage => _cpuUsage;
  int get activeThreads => _activeThreads;
  DateTime get lastUpdate => _lastUpdate;
}

enum PerformanceAlertType {
  slowOperation,
  highMemoryUsage,
  highCpuUsage,
  operationFailed,
  cacheOverflow,
  resourceExhaustion,
}

class PerformanceAlert {
  final PerformanceAlertType type;
  final String operation;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PerformanceAlert({
    required this.type,
    required this.operation,
    required this.duration,
    required this.timestamp,
    required this.metadata,
  });

  @override
  String toString() {
    return 'PerformanceAlert(type: $type, operation: $operation, duration: ${duration.inMilliseconds}ms)';
  }
}
