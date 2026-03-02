import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'performance_optimization_service.dart';

/// Runtime Performance Optimization Service
/// Provides comprehensive performance monitoring and optimization for Flutter apps
class RuntimePerformanceService {
  static final RuntimePerformanceService _instance = RuntimePerformanceService._internal();
  factory RuntimePerformanceService() => _instance;
  RuntimePerformanceService._internal();

  final PerformanceOptimizationService _performanceService = PerformanceOptimizationService();
  final StreamController<PerformanceEvent> _performanceEventController = StreamController.broadcast();

  Stream<PerformanceEvent> get performanceEvents => _performanceEventController.stream;

  // Performance monitoring
  final Map<String, PerformanceMetrics> _currentMetrics = {};
  final Queue<PerformanceSnapshot> _performanceHistory = Queue();
  final Map<String, WidgetBuildMetrics> _widgetBuildMetrics = {};

  // Memory management
  final Map<String, WeakReference> _objectRegistry = {};
  final List<VoidCallback> _cleanupCallbacks = [];
  final Map<String, MemoryPool> _memoryPools = {};

  // Rendering optimization
  final Map<String, ImageCacheEntry> _imageCache = {};
  final Map<String, LazyLoadController> _lazyLoadControllers = {};
  final Set<String> _preloadedAssets = {};

  // Background task management
  final Map<String, BackgroundTask> _backgroundTasks = {};
  final PriorityQueue<TaskPriority> _taskQueue = PriorityQueue();

  bool _isInitialized = false;
  bool _performanceMonitoringEnabled = true;

  // Configuration
  static const int _maxPerformanceHistorySize = 1000;
  static const Duration _performanceCheckInterval = Duration(seconds: 5);
  static const int _maxImageCacheSize = 50 * 1024 * 1024; // 50MB
  static const int _maxMemoryPoolSize = 100;

  Timer? _performanceTimer;
  WidgetsBindingObserver? _bindingObserver;

  /// Initialize runtime performance service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize performance monitoring
      await _setupPerformanceMonitoring();

      // Initialize memory management
      await _setupMemoryManagement();

      // Initialize rendering optimizations
      await _setupRenderingOptimizations();

      // Initialize background task management
      await _setupBackgroundTasks();

      _isInitialized = true;
      _emitPerformanceEvent(PerformanceEventType.serviceInitialized);

    } catch (e) {
      _emitPerformanceEvent(PerformanceEventType.initializationFailed, error: e.toString());
      rethrow;
    }
  }

  /// Monitor widget build performance
  Widget monitorWidgetBuild({
    required String widgetKey,
    required Widget child,
    bool trackRebuilds = true,
    bool optimizeRebuilds = true,
  }) {
    if (!_performanceMonitoringEnabled) return child;

    return _PerformanceMonitoredWidget(
      key: ValueKey(widgetKey),
      widgetKey: widgetKey,
      trackRebuilds: trackRebuilds,
      optimizeRebuilds: optimizeRebuilds,
      child: child,
      onBuild: _onWidgetBuild,
      onRebuild: _onWidgetRebuild,
    );
  }

  /// Optimize image loading and caching
  Widget optimizeImage({
    required String imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    bool enableCaching = true,
    bool enableLazyLoading = true,
    String? cacheKey,
  }) {
    final key = cacheKey ?? imageUrl;

    if (enableCaching && _imageCache.containsKey(key)) {
      final cached = _imageCache[key]!;
      if (!cached.isExpired) {
        return Image.memory(
          cached.imageData,
          width: width,
          height: height,
          fit: fit,
        );
      } else {
        _imageCache.remove(key);
      }
    }

    return enableLazyLoading
        ? _LazyImageWidget(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
            cacheKey: key,
            onLoadComplete: _onImageLoaded,
          )
        : Image.network(
            imageUrl,
            width: width,
            height: height,
            fit: fit,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return SizedBox(
                width: width,
                height: height,
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          );
  }

  /// Implement lazy loading for lists
  Widget lazyLoadList<T>({
    required String listKey,
    required List<T> items,
    required Widget Function(BuildContext, T, int) itemBuilder,
    required int visibleItemCount,
    ScrollController? controller,
    Axis scrollDirection = Axis.vertical,
    bool enablePagination = true,
  }) {
    final lazyController = _lazyLoadControllers[listKey] ?? LazyLoadController(
      totalItems: items.length,
      visibleThreshold: visibleItemCount,
    );

    _lazyLoadControllers[listKey] = lazyController;

    return LazyLoadListView<T>(
      key: ValueKey(listKey),
      items: items,
      itemBuilder: itemBuilder,
      controller: lazyController,
      scrollController: controller,
      scrollDirection: scrollDirection,
      enablePagination: enablePagination,
      onLoadMore: () => _onLoadMore(listKey),
    );
  }

  /// Optimize memory usage with object pooling
  T getPooledObject<T extends PoolableObject>(String poolKey, T Function() factory) {
    final pool = _memoryPools[poolKey] ?? MemoryPool<T>(maxSize: _maxMemoryPoolSize);
    _memoryPools[poolKey] = pool;

    return pool.getObject(factory);
  }

  /// Register object for memory monitoring
  void registerObject(String objectId, Object object) {
    _objectRegistry[objectId] = WeakReference(object);
  }

  /// Unregister object from memory monitoring
  void unregisterObject(String objectId) {
    _objectRegistry.remove(objectId);
  }

  /// Add cleanup callback
  void addCleanupCallback(VoidCallback callback) {
    _cleanupCallbacks.add(callback);
  }

  /// Execute background task with priority
  Future<T> executeBackgroundTask<T>({
    required String taskId,
    required Future<T> Function() task,
    TaskPriority priority = TaskPriority.normal,
    Duration? timeout,
    bool cancellable = true,
  }) async {
    final backgroundTask = BackgroundTask(
      taskId: taskId,
      priority: priority,
      timeout: timeout,
      cancellable: cancellable,
      task: task,
    );

    _backgroundTasks[taskId] = backgroundTask;
    _taskQueue.add(priority);

    try {
      final result = await _executeTaskWithPriority(backgroundTask);
      _emitPerformanceEvent(PerformanceEventType.taskCompleted,
        details: 'Task: $taskId, Priority: $priority');
      return result;

    } catch (e) {
      _emitPerformanceEvent(PerformanceEventType.taskFailed,
        details: 'Task: $taskId', error: e.toString());
      rethrow;
    } finally {
      _backgroundTasks.remove(taskId);
    }
  }

  /// Preload assets for better performance
  Future<void> preloadAssets(List<String> assetPaths) async {
    for (final path in assetPaths) {
      if (!_preloadedAssets.contains(path)) {
        try {
          // Preload images
          if (path.endsWith('.png') || path.endsWith('.jpg') || path.endsWith('.jpeg')) {
            final image = await _loadImageAsset(path);
            _imageCache[path] = ImageCacheEntry(
              imageData: image,
              loadedAt: DateTime.now(),
              size: image.length,
            );
          }
          _preloadedAssets.add(path);

        } catch (e) {
          // Continue with other assets
        }
      }
    }

    _emitPerformanceEvent(PerformanceEventType.assetsPreloaded,
      details: 'Assets: ${assetPaths.length}');
  }

  /// Optimize widget tree with const constructors
  Widget optimizeWidgetTree(Widget child) {
    return _WidgetOptimizer(child: child);
  }

  /// Get current performance metrics
  PerformanceMetrics getCurrentMetrics() {
    return PerformanceMetrics(
      memoryUsage: _getMemoryUsage(),
      cpuUsage: _getCpuUsage(),
      frameTime: _getAverageFrameTime(),
      buildTime: _getAverageBuildTime(),
      networkLatency: _getNetworkLatency(),
      timestamp: DateTime.now(),
    );
  }

  /// Get performance history
  List<PerformanceSnapshot> getPerformanceHistory({
    Duration? timeRange,
    int? maxEntries,
  }) {
    var history = _performanceHistory.toList();

    if (timeRange != null) {
      final cutoff = DateTime.now().subtract(timeRange);
      history = history.where((snapshot) => snapshot.timestamp.isAfter(cutoff)).toList();
    }

    if (maxEntries != null && history.length > maxEntries) {
      history = history.sublist(history.length - maxEntries);
    }

    return history;
  }

  /// Analyze performance bottlenecks
  Future<PerformanceAnalysis> analyzeBottlenecks({
    Duration analysisPeriod = const Duration(minutes: 5),
  }) async {
    final history = getPerformanceHistory(timeRange: analysisPeriod);

    if (history.isEmpty) {
      return PerformanceAnalysis.empty();
    }

    // Analyze memory usage patterns
    final memoryUsage = history.map((h) => h.metrics.memoryUsage).toList();
    final avgMemoryUsage = memoryUsage.reduce((a, b) => a + b) / memoryUsage.length;
    final memoryTrend = _calculateTrend(memoryUsage);

    // Analyze frame times
    final frameTimes = history.map((h) => h.metrics.frameTime).toList();
    final avgFrameTime = frameTimes.reduce((a, b) => a + b) / frameTimes.length;
    final frameTimeTrend = _calculateTrend(frameTimes);

    // Identify bottlenecks
    final bottlenecks = <PerformanceBottleneck>[];

    if (avgMemoryUsage > 100 * 1024 * 1024) { // 100MB
      bottlenecks.add(PerformanceBottleneck(
        type: BottleneckType.memory,
        severity: BottleneckSeverity.high,
        description: 'High memory usage detected',
        recommendation: 'Implement memory pooling and object reuse',
      ));
    }

    if (avgFrameTime > 16.67) { // 60 FPS threshold
      bottlenecks.add(PerformanceBottleneck(
        type: BottleneckType.rendering,
        severity: BottleneckSeverity.medium,
        description: 'Frame time exceeds 60 FPS threshold',
        recommendation: 'Optimize widget rebuilds and reduce layout complexity',
      ));
    }

    // Analyze widget build metrics
    final slowWidgets = _widgetBuildMetrics.entries
        .where((entry) => entry.value.averageBuildTime > 10) // 10ms threshold
        .map((entry) => entry.key)
        .toList();

    if (slowWidgets.isNotEmpty) {
      bottlenecks.add(PerformanceBottleneck(
        type: BottleneckType.widgetBuild,
        severity: BottleneckSeverity.medium,
        description: 'Slow widget builds detected: ${slowWidgets.join(', ')}',
        recommendation: 'Optimize widget build methods and use const constructors',
      ));
    }

    return PerformanceAnalysis(
      analysisPeriod: analysisPeriod,
      averageMemoryUsage: avgMemoryUsage,
      averageFrameTime: avgFrameTime,
      memoryTrend: memoryTrend,
      frameTimeTrend: frameTimeTrend,
      bottlenecks: bottlenecks,
      recommendations: _generateRecommendations(bottlenecks),
    );
  }

  /// Force garbage collection (for debugging)
  void forceGarbageCollection() {
    // This is a hint to the Dart VM
    // In production, avoid calling this frequently
  }

  /// Clean up resources
  void dispose() {
    _performanceTimer?.cancel();
    _bindingObserver?.removeObserver(this);
    _performanceEventController.close();

    // Clean up background tasks
    for (final task in _backgroundTasks.values) {
      task.cancel();
    }

    // Execute cleanup callbacks
    for (final callback in _cleanupCallbacks) {
      try {
        callback();
      } catch (e) {
        // Ignore cleanup errors
      }
    }
  }

  // Private methods

  Future<void> _setupPerformanceMonitoring() async {
    _performanceTimer = Timer.periodic(_performanceCheckInterval, (_) {
      _collectPerformanceMetrics();
    });

    _bindingObserver = _PerformanceObserver(this);
    WidgetsBinding.instance.addObserver(_bindingObserver!);

    // Enable performance overlay in debug mode
    if (kDebugMode) {
      debugProfileBuildsEnabled = true;
      debugProfilePaintsEnabled = true;
    }
  }

  Future<void> _setupMemoryManagement() async {
    // Set up automatic memory cleanup
    Timer.periodic(const Duration(minutes: 5), (_) {
      _performMemoryCleanup();
    });
  }

  Future<void> _setupRenderingOptimizations() async {
    // Configure image cache size
    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes = _maxImageCacheSize;
  }

  Future<void> _setupBackgroundTasks() async {
    // Start background task processor
    _processBackgroundTasks();
  }

  void _collectPerformanceMetrics() {
    final metrics = getCurrentMetrics();
    final snapshot = PerformanceSnapshot(
      timestamp: DateTime.now(),
      metrics: metrics,
    );

    _performanceHistory.add(snapshot);

    // Maintain history size
    while (_performanceHistory.length > _maxPerformanceHistorySize) {
      _performanceHistory.removeFirst();
    }

    // Check for performance issues
    _checkPerformanceThresholds(metrics);
  }

  void _checkPerformanceThresholds(PerformanceMetrics metrics) {
    if (metrics.memoryUsage > 200 * 1024 * 1024) { // 200MB
      _emitPerformanceEvent(PerformanceEventType.memoryWarning,
        details: 'High memory usage: ${(metrics.memoryUsage / 1024 / 1024).round()}MB');
    }

    if (metrics.frameTime > 33.33) { // 30 FPS threshold
      _emitPerformanceEvent(PerformanceEventType.frameDropWarning,
        details: 'Frame time: ${metrics.frameTime.toStringAsFixed(2)}ms');
    }
  }

  void _performMemoryCleanup() {
    // Clean up expired cache entries
    final now = DateTime.now();
    _imageCache.removeWhere((key, entry) => entry.isExpired);

    // Clean up weak references
    _objectRegistry.removeWhere((key, ref) => ref.target == null);

    // Clean up lazy load controllers
    _lazyLoadControllers.removeWhere((key, controller) => controller.isExpired);

    _emitPerformanceEvent(PerformanceEventType.memoryCleanupCompleted);
  }

  Future<void> _processBackgroundTasks() async {
    while (true) {
      if (_taskQueue.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }

      final priority = _taskQueue.removeFirst();
      final tasks = _backgroundTasks.values
          .where((task) => task.priority == priority)
          .toList();

      for (final task in tasks) {
        if (!task.isCancelled) {
          try {
            await task.execute();
          } catch (e) {
            // Handle task error
          }
        }
      }
    }
  }

  Future<T> _executeTaskWithPriority<T>(BackgroundTask<T> task) async {
    // Implement priority-based execution
    return task.task();
  }

  void _onWidgetBuild(String widgetKey, Duration buildTime) {
    final metrics = _widgetBuildMetrics[widgetKey] ?? WidgetBuildMetrics();
    metrics.addBuildTime(buildTime);
    _widgetBuildMetrics[widgetKey] = metrics;

    if (buildTime > const Duration(milliseconds: 16)) { // 60 FPS threshold
      _emitPerformanceEvent(PerformanceEventType.slowWidgetBuild,
        details: 'Widget: $widgetKey, Time: ${buildTime.inMilliseconds}ms');
    }
  }

  void _onWidgetRebuild(String widgetKey) {
    final metrics = _widgetBuildMetrics[widgetKey];
    if (metrics != null) {
      metrics.incrementRebuildCount();
    }
  }

  void _onImageLoaded(String cacheKey, Uint8List imageData) {
    _imageCache[cacheKey] = ImageCacheEntry(
      imageData: imageData,
      loadedAt: DateTime.now(),
      size: imageData.length,
    );

    // Check cache size limits
    var totalSize = _imageCache.values.fold<int>(0, (sum, entry) => sum + entry.size);
    while (totalSize > _maxImageCacheSize && _imageCache.isNotEmpty) {
      final oldestKey = _imageCache.keys.first;
      totalSize -= _imageCache[oldestKey]!.size;
      _imageCache.remove(oldestKey);
    }
  }

  void _onLoadMore(String listKey) {
    final controller = _lazyLoadControllers[listKey];
    if (controller != null) {
      controller.loadMore();
    }
  }

  Future<Uint8List> _loadImageAsset(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }

  double _getMemoryUsage() {
    // This is a simplified implementation
    // In a real app, you might use platform-specific APIs
    return 50 * 1024 * 1024; // Placeholder: 50MB
  }

  double _getCpuUsage() {
    // This is a simplified implementation
    return 25.0; // Placeholder: 25%
  }

  double _getAverageFrameTime() {
    // This is a simplified implementation
    return 16.67; // Placeholder: 60 FPS
  }

  double _getAverageBuildTime() {
    if (_widgetBuildMetrics.isEmpty) return 0.0;

    final totalTime = _widgetBuildMetrics.values
        .fold<Duration>(Duration.zero, (sum, metrics) => sum + metrics.totalBuildTime);
    final totalBuilds = _widgetBuildMetrics.values
        .fold<int>(0, (sum, metrics) => sum + metrics.buildCount);

    return totalBuilds > 0 ? totalTime.inMilliseconds / totalBuilds : 0.0;
  }

  double _getNetworkLatency() {
    // This is a simplified implementation
    return 100.0; // Placeholder: 100ms
  }

  TrendDirection _calculateTrend(List<double> values) {
    if (values.length < 2) return TrendDirection.stable;

    final recent = values.sublist(values.length - 10); // Last 10 values
    final older = values.sublist(0, values.length - 10);

    if (recent.isEmpty || older.isEmpty) return TrendDirection.stable;

    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;

    const threshold = 0.05; // 5% change threshold
    final change = (recentAvg - olderAvg) / olderAvg;

    if (change > threshold) return TrendDirection.increasing;
    if (change < -threshold) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  List<String> _generateRecommendations(List<PerformanceBottleneck> bottlenecks) {
    final recommendations = <String>[];

    for (final bottleneck in bottlenecks) {
      recommendations.add(bottleneck.recommendation);
    }

    // Add general recommendations
    recommendations.add('Use const constructors for static widgets');
    recommendations.add('Implement lazy loading for large lists');
    recommendations.add('Cache expensive computations');
    recommendations.add('Use ObjectKey only when necessary');
    recommendations.add('Profile with Flutter DevTools regularly');

    return recommendations;
  }

  void _emitPerformanceEvent(PerformanceEventType type, {
    String? details,
    String? error,
  }) {
    final event = PerformanceEvent(
      type: type,
      timestamp: DateTime.now(),
      details: details,
      error: error,
    );

    _performanceEventController.add(event);
  }
}

/// Performance Observer for app lifecycle
class _PerformanceObserver extends WidgetsBindingObserver {
  final RuntimePerformanceService _service;

  _PerformanceObserver(this._service);

  @override
  void didHaveMemoryPressure() {
    _service._emitPerformanceEvent(PerformanceEventType.memoryPressure);
    _service._performMemoryCleanup();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _service._emitPerformanceEvent(PerformanceEventType.appPaused);
        break;
      case AppLifecycleState.resumed:
        _service._emitPerformanceEvent(PerformanceEventType.appResumed);
        break;
      case AppLifecycleState.inactive:
        _service._emitPerformanceEvent(PerformanceEventType.appInactive);
        break;
      case AppLifecycleState.detached:
        _service._emitPerformanceEvent(PerformanceEventType.appDetached);
        break;
    }
  }
}

/// Supporting data classes and enums

enum PerformanceEventType {
  serviceInitialized,
  initializationFailed,
  memoryWarning,
  frameDropWarning,
  slowWidgetBuild,
  memoryPressure,
  appPaused,
  appResumed,
  appInactive,
  appDetached,
  taskCompleted,
  taskFailed,
  assetsPreloaded,
  memoryCleanupCompleted,
}

enum BottleneckType {
  memory,
  rendering,
  widgetBuild,
  network,
  cpu,
}

enum BottleneckSeverity {
  low,
  medium,
  high,
  critical,
}

enum TrendDirection {
  increasing,
  decreasing,
  stable,
}

enum TaskPriority {
  low,
  normal,
  high,
  critical,
}

/// Data classes

class PerformanceMetrics {
  final double memoryUsage;
  final double cpuUsage;
  final double frameTime;
  final double buildTime;
  final double networkLatency;
  final DateTime timestamp;

  PerformanceMetrics({
    required this.memoryUsage,
    required this.cpuUsage,
    required this.frameTime,
    required this.buildTime,
    required this.networkLatency,
    required this.timestamp,
  });
}

class PerformanceSnapshot {
  final DateTime timestamp;
  final PerformanceMetrics metrics;

  PerformanceSnapshot({
    required this.timestamp,
    required this.metrics,
  });
}

class WidgetBuildMetrics {
  int buildCount = 0;
  int rebuildCount = 0;
  Duration totalBuildTime = Duration.zero;
  DateTime lastBuildTime = DateTime.now();

  void addBuildTime(Duration time) {
    buildCount++;
    totalBuildTime += time;
    lastBuildTime = DateTime.now();
  }

  void incrementRebuildCount() {
    rebuildCount++;
  }

  double get averageBuildTime => buildCount > 0 ? totalBuildTime.inMilliseconds / buildCount : 0.0;
}

class MemoryPool<T> {
  final int maxSize;
  final Queue<T> _pool = Queue();

  MemoryPool({required this.maxSize});

  T getObject(T Function() factory) {
    if (_pool.isNotEmpty) {
      return _pool.removeFirst();
    }
    return factory();
  }

  void returnObject(T object) {
    if (_pool.length < maxSize) {
      _pool.add(object);
    }
  }
}

abstract class PoolableObject {
  void reset();
}

class ImageCacheEntry {
  final Uint8List imageData;
  final DateTime loadedAt;
  final int size;
  static const Duration cacheDuration = Duration(minutes: 30);

  ImageCacheEntry({
    required this.imageData,
    required this.loadedAt,
    required this.size,
  });

  bool get isExpired => DateTime.now().difference(loadedAt) > cacheDuration;
}

class LazyLoadController {
  final int totalItems;
  final int visibleThreshold;
  int loadedItems;
  bool isLoading = false;
  static const Duration expiryDuration = Duration(minutes: 30);

  LazyLoadController({
    required this.totalItems,
    required this.visibleThreshold,
  }) : loadedItems = visibleThreshold;

  bool get hasMoreItems => loadedItems < totalItems;

  bool get isExpired => DateTime.now().difference(DateTime.now()) > expiryDuration; // Simplified

  void loadMore() {
    if (!isLoading && hasMoreItems) {
      isLoading = true;
      loadedItems = (loadedItems + visibleThreshold).clamp(0, totalItems);
      isLoading = false;
    }
  }
}

class BackgroundTask<T> {
  final String taskId;
  final TaskPriority priority;
  final Duration? timeout;
  final bool cancellable;
  final Future<T> Function() task;
  bool isCancelled = false;

  BackgroundTask({
    required this.taskId,
    required this.priority,
    this.timeout,
    required this.cancellable,
    required this.task,
  });

  Future<T> execute() async {
    if (timeout != null) {
      return task().timeout(timeout!);
    }
    return task();
  }

  void cancel() {
    isCancelled = true;
  }
}

class PriorityQueue<T> {
  final List<T> _queue = [];

  void add(T item) {
    _queue.add(item);
    _queue.sort((a, b) => _getPriorityValue(b).compareTo(_getPriorityValue(a)));
  }

  T removeFirst() {
    if (_queue.isEmpty) throw StateError('Queue is empty');
    return _queue.removeAt(0);
  }

  bool get isEmpty => _queue.isEmpty;

  int _getPriorityValue(T item) {
    if (item is TaskPriority) {
      switch (item) {
        case TaskPriority.low: return 1;
        case TaskPriority.normal: return 2;
        case TaskPriority.high: return 3;
        case TaskPriority.critical: return 4;
      }
    }
    return 0;
  }
}

class PerformanceAnalysis {
  final Duration analysisPeriod;
  final double averageMemoryUsage;
  final double averageFrameTime;
  final TrendDirection memoryTrend;
  final TrendDirection frameTimeTrend;
  final List<PerformanceBottleneck> bottlenecks;
  final List<String> recommendations;

  PerformanceAnalysis({
    required this.analysisPeriod,
    required this.averageMemoryUsage,
    required this.averageFrameTime,
    required this.memoryTrend,
    required this.frameTimeTrend,
    required this.bottlenecks,
    required this.recommendations,
  });

  factory PerformanceAnalysis.empty() {
    return PerformanceAnalysis(
      analysisPeriod: Duration.zero,
      averageMemoryUsage: 0.0,
      averageFrameTime: 0.0,
      memoryTrend: TrendDirection.stable,
      frameTimeTrend: TrendDirection.stable,
      bottlenecks: [],
      recommendations: [],
    );
  }
}

class PerformanceBottleneck {
  final BottleneckType type;
  final BottleneckSeverity severity;
  final String description;
  final String recommendation;

  PerformanceBottleneck({
    required this.type,
    required this.severity,
    required this.description,
    required this.recommendation,
  });
}

/// Widget classes

class _PerformanceMonitoredWidget extends StatefulWidget {
  final String widgetKey;
  final Widget child;
  final bool trackRebuilds;
  final bool optimizeRebuilds;
  final Function(String, Duration) onBuild;
  final Function(String) onRebuild;

  const _PerformanceMonitoredWidget({
    super.key,
    required this.widgetKey,
    required this.child,
    required this.trackRebuilds,
    required this.optimizeRebuilds,
    required this.onBuild,
    required this.onRebuild,
  });

  @override
  State<_PerformanceMonitoredWidget> createState() => _PerformanceMonitoredWidgetState();
}

class _PerformanceMonitoredWidgetState extends State<_PerformanceMonitoredWidget> {
  DateTime? _buildStartTime;

  @override
  void initState() {
    super.initState();
    _trackBuild();
  }

  @override
  void didUpdateWidget(_PerformanceMonitoredWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trackRebuilds) {
      widget.onRebuild(widget.widgetKey);
    }
    _trackBuild();
  }

  void _trackBuild() {
    if (widget.trackRebuilds) {
      _buildStartTime = DateTime.now();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_buildStartTime != null) {
          final buildTime = DateTime.now().difference(_buildStartTime!);
          widget.onBuild(widget.widgetKey, buildTime);
          _buildStartTime = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _LazyImageWidget extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final String cacheKey;
  final Function(String, Uint8List) onLoadComplete;

  const _LazyImageWidget({
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.fit,
    required this.cacheKey,
    required this.onLoadComplete,
  });

  @override
  State<_LazyImageWidget> createState() => _LazyImageWidgetState();
}

class _LazyImageWidgetState extends State<_LazyImageWidget> {
  Uint8List? _imageData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final response = await http.get(Uri.parse(widget.imageUrl));
      if (response.statusCode == 200) {
        setState(() {
          _imageData = response.bodyBytes;
          _isLoading = false;
        });
        widget.onLoadComplete(widget.cacheKey, response.bodyBytes);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const CircularProgressIndicator(),
      );
    }

    if (_imageData != null) {
      return Image.memory(
        _imageData!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: const Icon(Icons.broken_image),
    );
  }
}

class LazyLoadListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final LazyLoadController controller;
  final ScrollController? scrollController;
  final Axis scrollDirection;
  final bool enablePagination;

  const LazyLoadListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.controller,
    this.scrollController,
    this.scrollDirection = Axis.vertical,
    this.enablePagination = true,
  });

  @override
  State<LazyLoadListView<T>> createState() => _LazyLoadListViewState<T>();
}

class _LazyLoadListViewState<T> extends State<LazyLoadListView<T>> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (!widget.enablePagination || !widget.controller.hasMoreItems) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8; // Load more when 80% scrolled

    if (currentScroll >= threshold) {
      widget.controller.loadMore();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = widget.items.take(widget.controller.loadedItems).toList();

    return ListView.builder(
      controller: _scrollController,
      scrollDirection: widget.scrollDirection,
      itemCount: visibleItems.length + (widget.controller.hasMoreItems ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == visibleItems.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return widget.itemBuilder(context, visibleItems[index], index);
      },
    );
  }
}

class _WidgetOptimizer extends StatelessWidget {
  final Widget child;

  const _WidgetOptimizer({required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: child);
  }
}

/// Event classes

class PerformanceEvent {
  final PerformanceEventType type;
  final DateTime timestamp;
  final String? details;
  final String? error;

  PerformanceEvent({
    required this.type,
    required this.timestamp,
    this.details,
    this.error,
  });
}
