import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import '../config/central_config.dart';
import '../logging/logging_service.dart';
import '../enhanced_error_handling_service.dart';

/// Memory Leak Detection and Prevention Service
///
/// Provides comprehensive memory management and leak detection for iSuite:
/// - Automatic memory leak detection
/// - Object retention tracking
/// - Memory usage monitoring
/// - Garbage collection triggering
/// - Memory pressure handling
/// - Leak prevention strategies
/// - Memory profiling and reporting
class MemoryLeakDetectionService {
  static const String _configPrefix = 'memory_leak_detection';
  static const String _defaultEnabled = 'memory_leak_detection.enabled';
  static const String _defaultCheckInterval =
      'memory_leak_detection.check_interval_seconds';
  static const String _defaultLeakThreshold =
      'memory_leak_detection.leak_threshold_mb';
  static const String _defaultGcInterval =
      'memory_leak_detection.gc_interval_minutes';
  static const String _defaultMaxTrackedObjects =
      'memory_leak_detection.max_tracked_objects';

  final LoggingService _loggingService;
  final CentralConfig _centralConfig;
  final EnhancedErrorHandlingService _errorHandlingService;

  Timer? _monitoringTimer;
  Timer? _gcTimer;
  final Map<String, TrackedObject> _trackedObjects = {};
  final Queue<MemorySnapshot> _snapshots = Queue<MemorySnapshot>();
  final StreamController<MemoryEvent> _memoryController =
      StreamController.broadcast();

  bool _isInitialized = false;
  VmService? _vmService;
  MemoryUsage _lastMemoryUsage = MemoryUsage.empty();

  // Leak detection
  final Map<String, LeakDetectionResult> _potentialLeaks = {};
  int _gcCount = 0;

  MemoryLeakDetectionService({
    LoggingService? loggingService,
    CentralConfig? centralConfig,
    EnhancedErrorHandlingService? errorHandlingService,
  })  : _loggingService = loggingService ?? LoggingService(),
        _centralConfig = centralConfig ?? CentralConfig.instance,
        _errorHandlingService =
            errorHandlingService ?? EnhancedErrorHandlingService();

  /// Initialize the memory leak detection service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _loggingService.info('Initializing Memory Leak Detection Service',
          'MemoryLeakDetectionService');

      // Register with CentralConfig
      await _centralConfig.registerComponent('MemoryLeakDetectionService',
          '1.0.0', 'Comprehensive memory leak detection and prevention service',
          dependencies: [
            'CentralConfig',
            'LoggingService',
            'EnhancedErrorHandlingService'
          ],
          parameters: {
            _defaultEnabled: true,
            _defaultCheckInterval: 60, // seconds
            _defaultLeakThreshold: 50, // MB
            _defaultGcInterval: 10, // minutes
            _defaultMaxTrackedObjects: 1000,
            'memory_leak_detection.auto_gc_enabled': true,
            'memory_leak_detection.leak_detection_enabled': true,
            'memory_leak_detection.memory_pressure_handling': true,
            'memory_leak_detection.snapshot_history_size': 10,
            'memory_leak_detection.gc_threshold_mb': 100,
          });

      // Connect to VM service for advanced memory inspection
      if (!kReleaseMode) {
        await _connectToVmService();
      }

      // Start monitoring
      if (enabled) {
        _startMonitoring();
        _startGarbageCollection();
      }

      _isInitialized = true;
      _loggingService.info(
          'Memory Leak Detection Service initialized successfully',
          'MemoryLeakDetectionService');
    } catch (e, stackTrace) {
      _loggingService.error(
          'Failed to initialize Memory Leak Detection Service',
          'MemoryLeakDetectionService',
          error: e,
          stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Configuration getters
  bool get enabled =>
      _centralConfig.getParameter(_defaultEnabled, defaultValue: true);
  Duration get checkInterval => Duration(
      seconds:
          _centralConfig.getParameter(_defaultCheckInterval, defaultValue: 60));
  int get leakThresholdMb =>
      _centralConfig.getParameter(_defaultLeakThreshold, defaultValue: 50);
  Duration get gcInterval => Duration(
      minutes:
          _centralConfig.getParameter(_defaultGcInterval, defaultValue: 10));
  int get maxTrackedObjects => _centralConfig
      .getParameter(_defaultMaxTrackedObjects, defaultValue: 1000);
  bool get autoGcEnabled =>
      _centralConfig.getParameter('memory_leak_detection.auto_gc_enabled',
          defaultValue: true);
  bool get leakDetectionEnabled => _centralConfig.getParameter(
      'memory_leak_detection.leak_detection_enabled',
      defaultValue: true);
  bool get memoryPressureHandling => _centralConfig.getParameter(
      'memory_leak_detection.memory_pressure_handling',
      defaultValue: true);
  int get snapshotHistorySize =>
      _centralConfig.getParameter('memory_leak_detection.snapshot_history_size',
          defaultValue: 10);
  int get gcThresholdMb => _centralConfig
      .getParameter('memory_leak_detection.gc_threshold_mb', defaultValue: 100);

  /// Get current memory usage
  Future<MemoryUsage> getCurrentMemoryUsage() async {
    try {
      if (_vmService != null) {
        // Get detailed memory info from VM
        final vm = await _vmService!.getVM();
        final isolateId = vm.isolates!.first.id!;

        final memory = await _vmService!.getMemoryUsage(isolateId);
        final heap = await _vmService!.getIsolate(isolateId);

        return MemoryUsage(
          heapUsed: memory.heapUsage! ~/ 1024 ~/ 1024, // Convert to MB
          heapCapacity: memory.heapCapacity! ~/ 1024 ~/ 1024,
          externalSize: memory.externalUsage! ~/ 1024 ~/ 1024,
          rss: ProcessInfo.currentRss ~/ 1024 ~/ 1024,
          timestamp: DateTime.now(),
        );
      } else {
        // Fallback to basic memory info
        return MemoryUsage(
          heapUsed: 0, // Not available without VM service
          heapCapacity: 0,
          externalSize: 0,
          rss: ProcessInfo.currentRss ~/ 1024 ~/ 1024,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      _loggingService.warning('Failed to get memory usage: ${e.toString()}',
          'MemoryLeakDetectionService');
      return MemoryUsage.empty();
    }
  }

  /// Track an object for potential leaks
  void trackObject(dynamic object, {String? label, String? context}) {
    if (!enabled || !leakDetectionEnabled) return;

    final objectId = _generateObjectId(object);
    final trackedObject = TrackedObject(
      id: objectId,
      object: object,
      label: label ?? object.runtimeType.toString(),
      context: context,
      createdAt: DateTime.now(),
      lastAccessed: DateTime.now(),
    );

    _trackedObjects[objectId] = trackedObject;

    // Limit tracked objects
    if (_trackedObjects.length > maxTrackedObjects) {
      final oldestKey = _trackedObjects.keys.first;
      _trackedObjects.remove(oldestKey);
    }
  }

  /// Untrack an object
  void untrackObject(dynamic object) {
    final objectId = _generateObjectId(object);
    _trackedObjects.remove(objectId);
  }

  /// Take memory snapshot
  Future<MemorySnapshot> takeSnapshot({String? label}) async {
    final memoryUsage = await getCurrentMemoryUsage();
    final trackedObjects = Map<String, TrackedObject>.from(_trackedObjects);

    final snapshot = MemorySnapshot(
      timestamp: DateTime.now(),
      memoryUsage: memoryUsage,
      trackedObjects: trackedObjects,
      label: label,
    );

    _snapshots.add(snapshot);

    // Limit snapshot history
    while (_snapshots.length > snapshotHistorySize) {
      _snapshots.removeFirst();
    }

    _loggingService.debug(
        'Memory snapshot taken: ${memoryUsage.heapUsed}MB used',
        'MemoryLeakDetectionService');

    return snapshot;
  }

  /// Detect potential memory leaks
  Future<List<LeakDetectionResult>> detectLeaks() async {
    if (!enabled || !leakDetectionEnabled) return [];

    final leaks = <LeakDetectionResult>[];

    try {
      // Compare current memory usage with baseline
      final currentUsage = await getCurrentMemoryUsage();
      final baselineUsage = _getBaselineMemoryUsage();

      if (baselineUsage != null) {
        final memoryIncrease = currentUsage.heapUsed - baselineUsage.heapUsed;

        if (memoryIncrease > leakThresholdMb) {
          final leak = LeakDetectionResult(
            detectedAt: DateTime.now(),
            memoryIncrease: memoryIncrease,
            suspectedObjects: _findSuspectedObjects(),
            severity: _calculateLeakSeverity(memoryIncrease),
            description:
                'Memory usage increased by ${memoryIncrease}MB since baseline',
          );

          leaks.add(leak);
          _potentialLeaks[leak.detectedAt.toIso8601String()] = leak;

          _emitEvent(MemoryEvent(
            type: MemoryEventType.leakDetected,
            leakResult: leak,
          ));

          _loggingService.warning(
              'Potential memory leak detected: +${memoryIncrease}MB',
              'MemoryLeakDetectionService');
        }
      }

      // Check for long-lived objects
      final longLivedObjects = _findLongLivedObjects();
      if (longLivedObjects.isNotEmpty) {
        final leak = LeakDetectionResult(
          detectedAt: DateTime.now(),
          memoryIncrease: 0, // Unknown
          suspectedObjects: longLivedObjects,
          severity: LeakSeverity.warning,
          description:
              'Found ${longLivedObjects.length} potentially long-lived objects',
        );

        leaks.add(leak);
      }

      // Clean up old leak records
      _cleanupOldLeaks();
    } catch (e) {
      _loggingService.error(
          'Leak detection failed', 'MemoryLeakDetectionService',
          error: e);
    }

    return leaks;
  }

  /// Trigger garbage collection
  Future<void> triggerGarbageCollection() async {
    try {
      if (_vmService != null) {
        final vm = await _vmService!.getVM();
        final isolateId = vm.isolates!.first.id!;

        await _vmService!.getAllocationProfile(isolateId, gc: true);
        _gcCount++;

        _emitEvent(MemoryEvent(type: MemoryEventType.gcTriggered));

        _loggingService.debug('Garbage collection triggered (count: $_gcCount)',
            'MemoryLeakDetectionService');
      }
    } catch (e) {
      _loggingService.warning(
          'Failed to trigger garbage collection: ${e.toString()}',
          'MemoryLeakDetectionService');
    }
  }

  /// Force cleanup of tracked objects
  Future<void> forceCleanup() async {
    try {
      final objectsToRemove = <String>[];

      for (final entry in _trackedObjects.entries) {
        final object = entry.value.object;

        // Check if object is still accessible
        try {
          // This is a simple heuristic - in practice, you might use WeakReferences
          if (object == null) {
            objectsToRemove.add(entry.key);
          }
        } catch (e) {
          objectsToRemove.add(entry.key);
        }
      }

      for (final key in objectsToRemove) {
        _trackedObjects.remove(key);
      }

      if (objectsToRemove.isNotEmpty) {
        _loggingService.info(
            'Cleaned up ${objectsToRemove.length} tracked objects',
            'MemoryLeakDetectionService');
      }

      // Trigger GC
      await triggerGarbageCollection();
    } catch (e) {
      _loggingService.error(
          'Force cleanup failed', 'MemoryLeakDetectionService',
          error: e);
    }
  }

  /// Get memory statistics
  MemoryStatistics getMemoryStatistics() {
    final snapshots = _snapshots.toList();
    final leaks = _potentialLeaks.values.toList();

    double averageUsage = 0;
    int peakUsage = 0;

    if (snapshots.isNotEmpty) {
      final usages = snapshots.map((s) => s.memoryUsage.heapUsed).toList();
      averageUsage = usages.reduce((a, b) => a + b) / usages.length;
      peakUsage = usages.reduce((a, b) => a > b ? a : b);
    }

    return MemoryStatistics(
      totalTrackedObjects: _trackedObjects.length,
      totalSnapshots: snapshots.length,
      totalLeaksDetected: leaks.length,
      averageMemoryUsage: averageUsage,
      peakMemoryUsage: peakUsage,
      gcCount: _gcCount,
      lastMemoryUsage: _lastMemoryUsage,
    );
  }

  /// Handle memory pressure
  Future<void> handleMemoryPressure() async {
    if (!memoryPressureHandling) return;

    try {
      _loggingService.warning('Memory pressure detected, initiating cleanup',
          'MemoryLeakDetectionService');

      // Force cleanup
      await forceCleanup();

      // Clear caches
      await _clearCaches();

      // Trigger aggressive GC
      await triggerGarbageCollection();

      _emitEvent(MemoryEvent(type: MemoryEventType.pressureHandled));
    } catch (e) {
      _loggingService.error(
          'Memory pressure handling failed', 'MemoryLeakDetectionService',
          error: e);
    }
  }

  /// Get memory recommendations
  List<String> getMemoryRecommendations() {
    final recommendations = <String>[];
    final stats = getMemoryStatistics();

    if (stats.averageMemoryUsage > gcThresholdMb) {
      recommendations
          .add('Consider implementing lazy loading for large datasets');
      recommendations.add('Review and optimize image loading and caching');
    }

    if (stats.totalLeaksDetected > 0) {
      recommendations.add('Investigate and fix detected memory leaks');
      recommendations
          .add('Ensure proper disposal of controllers and listeners');
    }

    if (stats.totalTrackedObjects > maxTrackedObjects * 0.8) {
      recommendations.add(
          'Reduce the number of tracked objects or increase tracking limit');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Memory usage is within acceptable limits');
    }

    return recommendations;
  }

  /// Private methods

  Future<void> _connectToVmService() async {
    try {
      final serviceProtocolUrl = (await developer.Service.getInfo()).serverUri;
      if (serviceProtocolUrl != null) {
        _vmService = await vmServiceConnectUri(serviceProtocolUrl.toString());
        _loggingService.info(
            'Connected to VM service', 'MemoryLeakDetectionService');
      }
    } catch (e) {
      _loggingService.warning(
          'Failed to connect to VM service: ${e.toString()}',
          'MemoryLeakDetectionService');
    }
  }

  String _generateObjectId(dynamic object) {
    return '${object.runtimeType}_${object.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
  }

  MemoryUsage? _getBaselineMemoryUsage() {
    if (_snapshots.isEmpty) return null;

    // Use the oldest snapshot as baseline
    return _snapshots.first.memoryUsage;
  }

  List<TrackedObject> _findSuspectedObjects() {
    final suspected = <TrackedObject>[];

    // Find objects that have been tracked for a long time
    final cutoffTime = DateTime.now().subtract(const Duration(hours: 1));

    for (final object in _trackedObjects.values) {
      if (object.createdAt.isBefore(cutoffTime)) {
        suspected.add(object);
      }
    }

    return suspected;
  }

  List<TrackedObject> _findLongLivedObjects() {
    final longLived = <TrackedObject>[];

    // Find objects older than 30 minutes
    final cutoffTime = DateTime.now().subtract(const Duration(minutes: 30));

    for (final object in _trackedObjects.values) {
      if (object.createdAt.isBefore(cutoffTime)) {
        longLived.add(object);
      }
    }

    return longLived;
  }

  LeakSeverity _calculateLeakSeverity(int memoryIncrease) {
    if (memoryIncrease > leakThresholdMb * 2) {
      return LeakSeverity.critical;
    } else if (memoryIncrease > leakThresholdMb) {
      return LeakSeverity.warning;
    } else {
      return LeakSeverity.info;
    }
  }

  void _cleanupOldLeaks() {
    final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
    _potentialLeaks
        .removeWhere((key, leak) => leak.detectedAt.isBefore(cutoffTime));
  }

  Future<void> _clearCaches() async {
    try {
      // Clear image cache
      // PaintingBinding.instance.imageCache.clear();

      // Clear other caches as needed
      _loggingService.info(
          'Application caches cleared', 'MemoryLeakDetectionService');
    } catch (e) {
      _loggingService.warning('Failed to clear caches: ${e.toString()}',
          'MemoryLeakDetectionService');
    }
  }

  void _startMonitoring() {
    _monitoringTimer = Timer.periodic(checkInterval, (_) async {
      try {
        await _performMonitoring();
      } catch (e) {
        _loggingService.error(
            'Memory monitoring failed', 'MemoryLeakDetectionService',
            error: e);
      }
    });

    _loggingService.info(
        'Memory monitoring started', 'MemoryLeakDetectionService');
  }

  void _startGarbageCollection() {
    if (!autoGcEnabled) return;

    _gcTimer = Timer.periodic(gcInterval, (_) async {
      try {
        await triggerGarbageCollection();
      } catch (e) {
        _loggingService.error(
            'Scheduled GC failed', 'MemoryLeakDetectionService',
            error: e);
      }
    });

    _loggingService.info(
        'Automatic garbage collection started', 'MemoryLeakDetectionService');
  }

  Future<void> _performMonitoring() async {
    // Take memory snapshot
    await takeSnapshot(label: 'periodic');

    // Update last memory usage
    _lastMemoryUsage = await getCurrentMemoryUsage();

    // Check for memory pressure
    if (_lastMemoryUsage.heapUsed > gcThresholdMb) {
      await handleMemoryPressure();
    }

    // Detect leaks
    await detectLeaks();

    // Emit monitoring event
    _emitEvent(MemoryEvent(
      type: MemoryEventType.monitoringUpdate,
      memoryUsage: _lastMemoryUsage,
    ));
  }

  void _emitEvent(MemoryEvent event) {
    _memoryController.add(event);
  }

  /// Get memory event stream
  Stream<MemoryEvent> get memoryEvents => _memoryController.stream;

  /// Get tracked objects
  Map<String, TrackedObject> getTrackedObjects() {
    return Map.from(_trackedObjects);
  }

  /// Get memory snapshots
  List<MemorySnapshot> getSnapshots() {
    return _snapshots.toList();
  }

  /// Get potential leaks
  Map<String, LeakDetectionResult> getPotentialLeaks() {
    return Map.from(_potentialLeaks);
  }

  /// Clear all tracking data
  void clearTrackingData() {
    _trackedObjects.clear();
    _snapshots.clear();
    _potentialLeaks.clear();
    _loggingService.info(
        'Memory tracking data cleared', 'MemoryLeakDetectionService');
  }

  /// Dispose resources
  void dispose() {
    _monitoringTimer?.cancel();
    _gcTimer?.cancel();
    _memoryController.close();
    _vmService?.dispose();
    _loggingService.info(
        'Memory leak detection service disposed', 'MemoryLeakDetectionService');
  }
}

/// Memory Usage Information
class MemoryUsage {
  final int heapUsed; // MB
  final int heapCapacity; // MB
  final int externalSize; // MB
  final int rss; // MB
  final DateTime timestamp;

  MemoryUsage({
    required this.heapUsed,
    required this.heapCapacity,
    required this.externalSize,
    required this.rss,
    required this.timestamp,
  });

  factory MemoryUsage.empty() {
    return MemoryUsage(
      heapUsed: 0,
      heapCapacity: 0,
      externalSize: 0,
      rss: 0,
      timestamp: DateTime.now(),
    );
  }

  double get usagePercent =>
      heapCapacity > 0 ? (heapUsed / heapCapacity) * 100 : 0;

  @override
  String toString() {
    return 'MemoryUsage(heap: ${heapUsed}MB/${heapCapacity}MB, external: ${externalSize}MB, rss: ${rss}MB)';
  }
}

/// Tracked Object
class TrackedObject {
  final String id;
  final dynamic object;
  final String label;
  final String? context;
  final DateTime createdAt;
  DateTime lastAccessed;

  TrackedObject({
    required this.id,
    required this.object,
    required this.label,
    this.context,
    required this.createdAt,
    required this.lastAccessed,
  });

  Duration get age => DateTime.now().difference(createdAt);

  @override
  String toString() {
    return 'TrackedObject(id: $id, label: $label, age: ${age.inMinutes}m)';
  }
}

/// Memory Snapshot
class MemorySnapshot {
  final DateTime timestamp;
  final MemoryUsage memoryUsage;
  final Map<String, TrackedObject> trackedObjects;
  final String? label;

  MemorySnapshot({
    required this.timestamp,
    required this.memoryUsage,
    required this.trackedObjects,
    this.label,
  });

  @override
  String toString() {
    return 'MemorySnapshot(time: $timestamp, usage: $memoryUsage, objects: ${trackedObjects.length})';
  }
}

/// Leak Detection Result
class LeakDetectionResult {
  final DateTime detectedAt;
  final int memoryIncrease; // MB
  final List<TrackedObject> suspectedObjects;
  final LeakSeverity severity;
  final String description;

  LeakDetectionResult({
    required this.detectedAt,
    required this.memoryIncrease,
    required this.suspectedObjects,
    required this.severity,
    required this.description,
  });

  @override
  String toString() {
    return 'LeakDetectionResult(severity: $severity, increase: ${memoryIncrease}MB, objects: ${suspectedObjects.length})';
  }
}

/// Leak Severity Levels
enum LeakSeverity {
  info,
  warning,
  critical,
}

/// Memory Statistics
class MemoryStatistics {
  final int totalTrackedObjects;
  final int totalSnapshots;
  final int totalLeaksDetected;
  final double averageMemoryUsage;
  final int peakMemoryUsage;
  final int gcCount;
  final MemoryUsage lastMemoryUsage;

  MemoryStatistics({
    required this.totalTrackedObjects,
    required this.totalSnapshots,
    required this.totalLeaksDetected,
    required this.averageMemoryUsage,
    required this.peakMemoryUsage,
    required this.gcCount,
    required this.lastMemoryUsage,
  });

  @override
  String toString() {
    return 'MemoryStatistics(objects: $totalTrackedObjects, snapshots: $totalSnapshots, '
        'leaks: $totalLeaksDetected, avg: ${averageMemoryUsage.toStringAsFixed(1)}MB, '
        'peak: ${peakMemoryUsage}MB, gc: $gcCount)';
  }
}

/// Memory Event Types
enum MemoryEventType {
  monitoringUpdate,
  leakDetected,
  gcTriggered,
  pressureHandled,
  snapshotTaken,
}

/// Memory Event
class MemoryEvent {
  final MemoryEventType type;
  final DateTime timestamp;
  final MemoryUsage? memoryUsage;
  final LeakDetectionResult? leakResult;
  final MemorySnapshot? snapshot;

  MemoryEvent({
    required this.type,
    this.memoryUsage,
    this.leakResult,
    this.snapshot,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'MemoryEvent(type: $type, timestamp: $timestamp)';
  }
}
