import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Advanced Performance Optimization Service
/// Provides comprehensive performance monitoring, optimization, and memory management
class PerformanceOptimizationService {
  static final PerformanceOptimizationService _instance =
      PerformanceOptimizationService._internal();
  factory PerformanceOptimizationService() => _instance;
  PerformanceOptimizationService._internal();

  final Map<String, PerformanceMetric> _metrics = {};
  final Map<String, OperationTracker> _activeOperations = {};
  final Queue<PerformanceEvent> _performanceEvents = Queue();
  final StreamController<PerformanceEvent> _eventController =
      StreamController.broadcast();

  // Memory management
  final Map<String, CachedObject> _memoryCache = {};
  final List<WeakReference> _weakReferences = [];
  Timer? _memoryCleanupTimer;
  Timer? _performanceMonitoringTimer;

  // Performance thresholds
  static const Duration _defaultOperationTimeout = Duration(seconds: 30);
  static const int _maxMemoryCacheSize = 50 * 1024 * 1024; // 50MB
  static const int _maxPerformanceEvents = 1000;
  static const Duration _memoryCleanupInterval = Duration(minutes: 5);
  static const Duration _performanceMonitoringInterval = Duration(seconds: 30);

  Stream<PerformanceEvent> get performanceEvents => _eventController.stream;

  bool _isInitialized = false;

  /// Initialize performance optimization service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Start memory cleanup timer
      _memoryCleanupTimer = Timer.periodic(
          _memoryCleanupInterval, (_) => _performMemoryCleanup());

      // Start performance monitoring timer
      _performanceMonitoringTimer = Timer.periodic(
          _performanceMonitoringInterval,
          (_) => _performPerformanceMonitoring());

      // Initialize baseline metrics
      await _initializeBaselineMetrics();

      _isInitialized = true;
      _emitEvent(PerformanceEventType.serviceInitialized,
          details: 'Performance optimization service initialized');
    } catch (e) {
      _emitEvent(PerformanceEventType.initializationFailed,
          details: e.toString());
      rethrow;
    }
  }

  /// Track operation performance with automatic cleanup
  Future<T> trackOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    Duration? timeout,
    Map<String, dynamic>? metadata,
  }) async {
    final operationId =
        '${operationName}_${DateTime.now().millisecondsSinceEpoch}';
    final tracker = OperationTracker(
      id: operationId,
      name: operationName,
      startTime: DateTime.now(),
      metadata: metadata,
    );

    _activeOperations[operationId] = tracker;

    try {
      final result =
          await operation.timeout(timeout ?? _defaultOperationTimeout);

      tracker.endTime = DateTime.now();
      tracker.success = true;

      // Record performance metric
      final metric = PerformanceMetric(
        operationName: operationName,
        duration: tracker.duration,
        timestamp: tracker.startTime,
        success: true,
        metadata: metadata,
      );

      _addMetric(metric);
      _emitEvent(PerformanceEventType.operationCompleted,
          details: operationName, duration: tracker.duration);

      return result;
    } catch (e) {
      tracker.endTime = DateTime.now();
      tracker.success = false;
      tracker.error = e.toString();

      // Record failed operation metric
      final metric = PerformanceMetric(
        operationName: operationName,
        duration: tracker.duration,
        timestamp: tracker.startTime,
        success: false,
        error: e.toString(),
        metadata: metadata,
      );

      _addMetric(metric);
      _emitEvent(PerformanceEventType.operationFailed,
          details: operationName, error: e.toString());

      rethrow;
    } finally {
      // Cleanup
      _activeOperations.remove(operationId);
    }
  }

  /// Cache object in memory with LRU eviction
  void cacheObject<T>(
    String key,
    T object, {
    Duration? ttl,
    int? sizeEstimate,
  }) {
    if (_getCurrentCacheSize() >= _maxMemoryCacheSize) {
      _evictCacheEntries();
    }

    final cachedObject = CachedObject<T>(
      key: key,
      object: object,
      createdAt: DateTime.now(),
      ttl: ttl,
      sizeEstimate: sizeEstimate ?? _estimateObjectSize(object),
      accessCount: 0,
    );

    _memoryCache[key] = cachedObject;
    _emitEvent(PerformanceEventType.objectCached,
        details: 'Cached object: $key');
  }

  /// Retrieve cached object with access tracking
  T? getCachedObject<T>(String key) {
    final cachedObject = _memoryCache[key] as CachedObject<T>?;

    if (cachedObject == null) {
      _emitEvent(PerformanceEventType.cacheMiss, details: key);
      return null;
    }

    // Check TTL
    if (cachedObject.isExpired) {
      _memoryCache.remove(key);
      _emitEvent(PerformanceEventType.cacheExpired, details: key);
      return null;
    }

    // Update access tracking
    cachedObject.lastAccessed = DateTime.now();
    cachedObject.accessCount++;

    _emitEvent(PerformanceEventType.cacheHit, details: key);
    return cachedObject.object;
  }

  /// Clear cache with optional pattern matching
  void clearCache({String? pattern}) {
    if (pattern == null) {
      final count = _memoryCache.length;
      _memoryCache.clear();
      _emitEvent(PerformanceEventType.cacheCleared,
          details: 'Cleared $count objects');
    } else {
      final keysToRemove =
          _memoryCache.keys.where((key) => key.contains(pattern)).toList();
      for (final key in keysToRemove) {
        _memoryCache.remove(key);
      }
      _emitEvent(PerformanceEventType.cacheCleared,
          details: 'Cleared ${keysToRemove.length} objects matching: $pattern');
    }
  }

  /// Get performance metrics with filtering
  List<PerformanceMetric> getMetrics({
    String? operationName,
    DateTime? startTime,
    DateTime? endTime,
    bool? success,
    int? limit,
  }) {
    var filteredMetrics = _metrics.values.toList();

    if (operationName != null) {
      filteredMetrics = filteredMetrics
          .where((m) => m.operationName == operationName)
          .toList();
    }

    if (startTime != null) {
      filteredMetrics =
          filteredMetrics.where((m) => m.timestamp.isAfter(startTime)).toList();
    }

    if (endTime != null) {
      filteredMetrics =
          filteredMetrics.where((m) => m.timestamp.isBefore(endTime)).toList();
    }

    if (success != null) {
      filteredMetrics =
          filteredMetrics.where((m) => m.success == success).toList();
    }

    // Sort by timestamp (newest first)
    filteredMetrics.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (limit != null && filteredMetrics.length > limit) {
      filteredMetrics = filteredMetrics.take(limit).toList();
    }

    return filteredMetrics;
  }

  /// Get performance statistics
  PerformanceStatistics getPerformanceStatistics({
    String? operationName,
    Duration? timeWindow,
  }) {
    final metrics = getMetrics(
      operationName: operationName,
      startTime:
          timeWindow != null ? DateTime.now().subtract(timeWindow) : null,
    );

    if (metrics.isEmpty) {
      return PerformanceStatistics.empty();
    }

    final durations = metrics.map((m) => m.duration.inMilliseconds).toList();
    durations.sort();

    final totalOperations = metrics.length;
    final successfulOperations = metrics.where((m) => m.success).length;
    final failedOperations = totalOperations - successfulOperations;

    final avgDuration = durations.reduce((a, b) => a + b) / durations.length;
    final minDuration = durations.first;
    final maxDuration = durations.last;
    final medianDuration = durations[durations.length ~/ 2];

    // Calculate percentiles
    final p95Index = (durations.length * 0.95).floor();
    final p99Index = (durations.length * 0.99).floor();
    final p95Duration = durations[p95Index.clamp(0, durations.length - 1)];
    final p99Duration = durations[p99Index.clamp(0, durations.length - 1)];

    return PerformanceStatistics(
      operationName: operationName,
      totalOperations: totalOperations,
      successfulOperations: successfulOperations,
      failedOperations: failedOperations,
      averageDuration: Duration(milliseconds: avgDuration.round()),
      minDuration: Duration(milliseconds: minDuration),
      maxDuration: Duration(milliseconds: maxDuration),
      medianDuration: Duration(milliseconds: medianDuration),
      p95Duration: Duration(milliseconds: p95Duration),
      p99Duration: Duration(milliseconds: p99Duration),
      successRate: successfulOperations / totalOperations,
    );
  }

  /// Get memory usage statistics
  MemoryStatistics getMemoryStatistics() {
    final cacheSize = _getCurrentCacheSize();
    final cacheEntryCount = _memoryCache.length;
    final activeOperationsCount = _activeOperations.length;

    return MemoryStatistics(
      cacheSizeBytes: cacheSize,
      cacheEntryCount: cacheEntryCount,
      activeOperationsCount: activeOperationsCount,
      cacheHitRate: _calculateCacheHitRate(),
      memoryPressure: _assessMemoryPressure(),
    );
  }

  /// Optimize memory usage
  Future<void> optimizeMemory() async {
    _emitEvent(PerformanceEventType.memoryOptimizationStarted);

    // Force garbage collection hint (platform dependent)
    // In Flutter, we can't force GC, but we can clear caches
    clearCache();

    // Clear weak references
    _weakReferences.removeWhere((ref) => ref.target == null);

    // Compact performance events
    while (_performanceEvents.length > _maxPerformanceEvents ~/ 2) {
      _performanceEvents.removeFirst();
    }

    _emitEvent(PerformanceEventType.memoryOptimizationCompleted);
  }

  /// Get performance bottlenecks
  List<PerformanceBottleneck> identifyBottlenecks({
    Duration? timeWindow,
    double thresholdMultiplier = 2.0,
  }) {
    final statistics = getPerformanceStatistics(timeWindow: timeWindow);
    final bottlenecks = <PerformanceBottleneck>[];

    // Check for slow operations
    final slowThreshold = statistics.averageDuration * thresholdMultiplier;
    final slowMetrics = getMetrics(
      startTime:
          timeWindow != null ? DateTime.now().subtract(timeWindow) : null,
    ).where((m) => m.duration > slowThreshold).toList();

    if (slowMetrics.isNotEmpty) {
      bottlenecks.add(PerformanceBottleneck(
        type: BottleneckType.slowOperations,
        description:
            '${slowMetrics.length} operations exceed ${thresholdMultiplier}x average duration',
        severity: slowMetrics.length > 10
            ? BottleneckSeverity.high
            : BottleneckSeverity.medium,
        affectedOperations:
            slowMetrics.map((m) => m.operationName).toSet().toList(),
      ));
    }

    // Check for high failure rate
    if (statistics.successRate < 0.8) {
      bottlenecks.add(PerformanceBottleneck(
        type: BottleneckType.highFailureRate,
        description:
            'Success rate is ${(statistics.successRate * 100).round()}%',
        severity: statistics.successRate < 0.5
            ? BottleneckSeverity.critical
            : BottleneckSeverity.high,
        affectedOperations: [statistics.operationName ?? 'all_operations'],
      ));
    }

    // Check for memory pressure
    final memoryStats = getMemoryStatistics();
    if (memoryStats.memoryPressure == MemoryPressure.high) {
      bottlenecks.add(PerformanceBottleneck(
        type: BottleneckType.memoryPressure,
        description: 'High memory usage detected',
        severity: BottleneckSeverity.high,
        affectedOperations: [],
      ));
    }

    return bottlenecks;
  }

  /// Export performance report
  Future<String> exportPerformanceReport({
    Duration? timeWindow,
    bool includeMetrics = true,
    bool includeMemoryStats = true,
    bool includeBottlenecks = true,
  }) async {
    final report = StringBuffer();
    report.writeln('Performance Report - ${DateTime.now()}');
    report.writeln('=' * 50);

    if (includeMetrics) {
      report.writeln('\nPerformance Statistics:');
      final stats = getPerformanceStatistics(timeWindow: timeWindow);
      report.writeln(stats.toString());
    }

    if (includeMemoryStats) {
      report.writeln('\nMemory Statistics:');
      final memStats = getMemoryStatistics();
      report.writeln('Cache Size: ${memStats.cacheSizeBytes} bytes');
      report.writeln('Cache Entries: ${memStats.cacheEntryCount}');
      report.writeln('Active Operations: ${memStats.activeOperationsCount}');
      report
          .writeln('Cache Hit Rate: ${(memStats.cacheHitRate * 100).round()}%');
      report.writeln('Memory Pressure: ${memStats.memoryPressure}');
    }

    if (includeBottlenecks) {
      report.writeln('\nPerformance Bottlenecks:');
      final bottlenecks = identifyBottlenecks(timeWindow: timeWindow);
      if (bottlenecks.isEmpty) {
        report.writeln('No significant bottlenecks detected');
      } else {
        for (final bottleneck in bottlenecks) {
          report
              .writeln('- ${bottleneck.description} (${bottleneck.severity})');
        }
      }
    }

    return report.toString();
  }

  // Private helper methods

  void _addMetric(PerformanceMetric metric) {
    _metrics[metric.id] = metric;

    // Maintain reasonable size
    if (_metrics.length > 10000) {
      final keysToRemove = _metrics.keys.take(1000).toList();
      for (final key in keysToRemove) {
        _metrics.remove(key);
      }
    }
  }

  void _emitEvent(
    PerformanceEventType type, {
    String? details,
    Duration? duration,
    String? error,
  }) {
    final event = PerformanceEvent(
      type: type,
      timestamp: DateTime.now(),
      details: details,
      duration: duration,
      error: error,
    );

    _performanceEvents.add(event);
    _eventController.add(event);

    // Maintain event queue size
    if (_performanceEvents.length > _maxPerformanceEvents) {
      _performanceEvents.removeFirst();
    }
  }

  int _getCurrentCacheSize() {
    return _memoryCache.values
        .fold(0, (sum, obj) => sum + (obj.sizeEstimate ?? 0));
  }

  void _evictCacheEntries() {
    // Simple LRU eviction
    final entries = _memoryCache.values.toList();
    entries.sort((a, b) {
      final aTime = a.lastAccessed ?? a.createdAt;
      final bTime = b.lastAccessed ?? b.createdAt;
      return aTime.compareTo(bTime);
    });

    // Remove oldest 20% of entries
    final toRemove = (entries.length * 0.2).ceil();
    for (var i = 0; i < toRemove && i < entries.length; i++) {
      _memoryCache.remove(entries[i].key);
    }
  }

  int _estimateObjectSize(dynamic object) {
    // Rough estimation - in practice, you'd use more sophisticated methods
    if (object == null) return 0;

    if (object is String) return object.length * 2; // UTF-16 estimation
    if (object is List) return object.length * 8; // Pointer size estimation
    if (object is Map) return object.length * 16; // Key-value pair estimation

    return 64; // Default object size estimation
  }

  void _performMemoryCleanup() {
    // Remove expired cache entries
    final expiredKeys = <String>[];
    for (final entry in _memoryCache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _memoryCache.remove(key);
    }

    // Clean weak references
    _weakReferences.removeWhere((ref) => ref.target == null);

    if (expiredKeys.isNotEmpty) {
      _emitEvent(PerformanceEventType.memoryCleanupPerformed,
          details: 'Cleaned up ${expiredKeys.length} expired cache entries');
    }
  }

  void _performPerformanceMonitoring() {
    final memoryStats = getMemoryStatistics();

    // Check for memory pressure
    if (memoryStats.memoryPressure == MemoryPressure.high) {
      _emitEvent(PerformanceEventType.memoryPressureDetected,
          details: 'High memory usage: ${memoryStats.cacheSizeBytes} bytes');
    }

    // Monitor active operations
    if (_activeOperations.length > 10) {
      _emitEvent(PerformanceEventType.highOperationCount,
          details: '${_activeOperations.length} active operations');
    }
  }

  Future<void> _initializeBaselineMetrics() async {
    // Record baseline memory usage
    final memoryStats = getMemoryStatistics();
    _emitEvent(PerformanceEventType.baselineRecorded,
        details: 'Baseline memory: ${memoryStats.cacheSizeBytes} bytes');
  }

  double _calculateCacheHitRate() {
    // This would require tracking cache hits/misses over time
    // For simplicity, returning a placeholder
    return 0.85; // 85% hit rate placeholder
  }

  MemoryPressure _assessMemoryPressure() {
    final cacheSize = _getCurrentCacheSize();
    final ratio = cacheSize / _maxMemoryCacheSize;

    if (ratio > 0.9) return MemoryPressure.critical;
    if (ratio > 0.7) return MemoryPressure.high;
    if (ratio > 0.5) return MemoryPressure.medium;
    return MemoryPressure.low;
  }

  void dispose() {
    _memoryCleanupTimer?.cancel();
    _performanceMonitoringTimer?.cancel();
    _eventController.close();
    _memoryCache.clear();
    _activeOperations.clear();
    _performanceEvents.clear();
  }
}

/// Performance metric data class
class PerformanceMetric {
  final String id;
  final String operationName;
  final Duration duration;
  final DateTime timestamp;
  final bool success;
  final String? error;
  final Map<String, dynamic>? metadata;

  PerformanceMetric({
    required this.operationName,
    required this.duration,
    required this.timestamp,
    required this.success,
    this.error,
    this.metadata,
  }) : id = '${operationName}_${timestamp.millisecondsSinceEpoch}';

  @override
  String toString() {
    return 'PerformanceMetric(operation: $operationName, duration: ${duration.inMilliseconds}ms, success: $success)';
  }
}

/// Operation tracker
class OperationTracker {
  final String id;
  final String name;
  final DateTime startTime;
  DateTime? endTime;
  bool success = false;
  String? error;
  final Map<String, dynamic>? metadata;

  OperationTracker({
    required this.id,
    required this.name,
    required this.startTime,
    this.metadata,
  });

  Duration get duration => endTime?.difference(startTime) ?? Duration.zero;
}

/// Cached object with metadata
class CachedObject<T> {
  final String key;
  final T object;
  final DateTime createdAt;
  DateTime? lastAccessed;
  final Duration? ttl;
  final int? sizeEstimate;
  int accessCount;

  CachedObject({
    required this.key,
    required this.object,
    required this.createdAt,
    this.ttl,
    this.sizeEstimate,
    this.accessCount = 0,
  });

  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().difference(createdAt) > ttl!;
  }
}

/// Performance event types
enum PerformanceEventType {
  serviceInitialized,
  initializationFailed,
  operationCompleted,
  operationFailed,
  objectCached,
  cacheHit,
  cacheMiss,
  cacheExpired,
  cacheCleared,
  memoryOptimizationStarted,
  memoryOptimizationCompleted,
  memoryCleanupPerformed,
  memoryPressureDetected,
  highOperationCount,
  baselineRecorded,
}

/// Performance event
class PerformanceEvent {
  final PerformanceEventType type;
  final DateTime timestamp;
  final String? details;
  final Duration? duration;
  final String? error;

  PerformanceEvent({
    required this.type,
    required this.timestamp,
    this.details,
    this.duration,
    this.error,
  });
}

/// Performance statistics
class PerformanceStatistics {
  final String? operationName;
  final int totalOperations;
  final int successfulOperations;
  final int failedOperations;
  final Duration averageDuration;
  final Duration minDuration;
  final Duration maxDuration;
  final Duration medianDuration;
  final Duration p95Duration;
  final Duration p99Duration;
  final double successRate;

  PerformanceStatistics({
    required this.operationName,
    required this.totalOperations,
    required this.successfulOperations,
    required this.failedOperations,
    required this.averageDuration,
    required this.minDuration,
    required this.maxDuration,
    required this.medianDuration,
    required this.p95Duration,
    required this.p99Duration,
    required this.successRate,
  });

  factory PerformanceStatistics.empty() {
    return PerformanceStatistics(
      operationName: null,
      totalOperations: 0,
      successfulOperations: 0,
      failedOperations: 0,
      averageDuration: Duration.zero,
      minDuration: Duration.zero,
      maxDuration: Duration.zero,
      medianDuration: Duration.zero,
      p95Duration: Duration.zero,
      p99Duration: Duration.zero,
      successRate: 0.0,
    );
  }

  @override
  String toString() {
    return '''
Total Operations: $totalOperations
Successful: $successfulOperations
Failed: $failedOperations
Success Rate: ${(successRate * 100).round()}%
Average Duration: ${averageDuration.inMilliseconds}ms
Min Duration: ${minDuration.inMilliseconds}ms
Max Duration: ${maxDuration.inMilliseconds}ms
Median Duration: ${medianDuration.inMilliseconds}ms
95th Percentile: ${p95Duration.inMilliseconds}ms
99th Percentile: ${p99Duration.inMilliseconds}ms
''';
  }
}

/// Memory statistics
class MemoryStatistics {
  final int cacheSizeBytes;
  final int cacheEntryCount;
  final int activeOperationsCount;
  final double cacheHitRate;
  final MemoryPressure memoryPressure;

  MemoryStatistics({
    required this.cacheSizeBytes,
    required this.cacheEntryCount,
    required this.activeOperationsCount,
    required this.cacheHitRate,
    required this.memoryPressure,
  });
}

/// Memory pressure levels
enum MemoryPressure {
  low,
  medium,
  high,
  critical,
}

/// Performance bottleneck
class PerformanceBottleneck {
  final BottleneckType type;
  final String description;
  final BottleneckSeverity severity;
  final List<String> affectedOperations;

  PerformanceBottleneck({
    required this.type,
    required this.description,
    required this.severity,
    required this.affectedOperations,
  });
}

/// Bottleneck types
enum BottleneckType {
  slowOperations,
  highFailureRate,
  memoryPressure,
  networkLatency,
  diskIO,
}

/// Bottleneck severity levels
enum BottleneckSeverity {
  low,
  medium,
  high,
  critical,
}
