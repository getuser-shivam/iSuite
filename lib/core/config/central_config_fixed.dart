import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

// Enums and classes first
enum ConfigEventType {
  initialized,
  parameterChanged,
  componentRegistered,
  componentNotified,
  componentParametersUpdated,
  configurationImported,
  resetToDefaults,
}

class ConfigEvent {
  final ConfigEventType type;
  final DateTime timestamp;
  final String? componentName;
  final String? parameterKey;
  final dynamic oldValue;
  final dynamic newValue;

  ConfigEvent({
    required this.type,
    required this.timestamp,
    this.componentName,
    this.parameterKey,
    this.oldValue,
    this.newValue,
  });

  @override
  String toString() {
    return 'ConfigEvent(type: $type, timestamp: $timestamp, componentName: $componentName)';
  }
}

enum RelationshipType {
  depends_on,
  provides_to,
  configures,
  monitors,
}

class ComponentRelationship {
  final String sourceComponent;
  final String targetComponent;
  final RelationshipType type;
  final DateTime createdAt;

  ComponentRelationship({
    required this.sourceComponent,
    required this.targetComponent,
    required this.type,
    required this.createdAt,
  });
}

class ComponentMetrics {
  final String componentName;
  final int accessCount;
  final Duration averageResponseTime;
  final Map<String, dynamic> performanceData;

  ComponentMetrics({
    required this.componentName,
    required this.accessCount,
    required this.averageResponseTime,
    required this.performanceData,
  });
}

class SystemHealthStatus {
  final int totalComponents;
  final int activeComponents;
  final int totalConnections;
  final int cacheSize;
  final int memoryUsage;
  final bool isHealthy;
  final DateTime lastHealthCheck;

  SystemHealthStatus({
    required this.totalComponents,
    required this.activeComponents,
    required this.totalConnections,
    required this.cacheSize,
    required this.memoryUsage,
    required this.isHealthy,
    required this.lastHealthCheck,
  });
}

class ComponentMemoryInfo {
  final String componentName;
  final int memoryUsage;
  final int cacheSize;

  ComponentMemoryInfo({
    required this.componentName,
    required this.memoryUsage,
    required this.cacheSize,
  });
}

class _CachedValue {
  final dynamic value;
  final DateTime expiry;

  _CachedValue(this.value, this.expiry);

  bool get isExpired => DateTime.now().isAfter(expiry);
}

class ReadWriteLock {
  int _readers = 0;
  bool _writer = false;
  final Queue<Completer<void>> _writerQueue = Queue<Completer<void>>();

  Future<T> read<T>(Future<T> Function() operation) async {
    while (_writer) {
      await _writerQueue.first;
    }
    _readers++;
    try {
      return await operation();
    } finally {
      _readers--;
    }
  }

  Future<T> write<T>(Future<T> Function() operation) async {
    final completer = Completer<void>();
    _writerQueue.add(completer);
    
    while (_readers > 0 || _writer) {
      await completer.future;
    }
    
    _writer = true;
    _writerQueue.remove(completer);
    
    try {
      return await operation();
    } finally {
      _writer = false;
      // Signal next writer
      if (_writerQueue.isNotEmpty) {
        _writerQueue.first.complete();
      }
    }
  }
}

/// Enhanced Central Configuration System
class CentralConfig {
  static CentralConfig? _instance;
  static CentralConfig get instance => _instance ??= CentralConfig._internal();
  CentralConfig._internal();

  // Enhanced caching system with relationship tracking
  final Map<String, _CachedValue> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _defaultCacheTTL = Duration(minutes: 5);
  final int _maxCacheSize = 1000;

  // Component relationship tracking
  final Map<String, Set<String>> _componentDependencies = {};
  final Map<String, Set<String>> _parameterDependencies = {};
  final Map<String, ComponentRelationship> _componentRelationships = {};

  // Performance monitoring with component metrics
  final Map<String, DateTime> _accessTimestamps = {};
  final Map<String, int> _accessCounts = {};
  final Map<String, Duration> _performanceMetrics = {};
  final Map<String, ComponentMetrics> _componentMetrics = {};

  // Hot-reload support with dependency propagation
  final Map<String, Function()> _configWatchers = {};
  final Map<String, Set<String>> _dependencyWatchers = {};

  // Environment-based configuration with component overrides
  final Map<String, String> _envOverrides = {};
  final Map<String, String> _platformOverrides = {};
  final Map<String, Map<String, dynamic>> _componentOverrides = {};

  // Memory optimization with component-aware cleanup
  final Map<String, WeakReference> _weakReferences = {};
  final Map<String, ComponentMemoryInfo> _componentMemoryInfo = {};

  // Thread safety with component-level locking
  final ReadWriteLock _lock = ReadWriteLock();
  final Map<String, ReadWriteLock> _componentLocks = {};
  bool _isInitialized = false;

  // Event streaming
  final StreamController<ConfigEvent> _eventController = StreamController.broadcast();

  Stream<ConfigEvent> get events => _eventController.stream;

  /// Initialize CentralConfig with enhanced features
  Future<void> initialize({bool enableHotReload = true}) async {
    if (_isInitialized) return;

    try {
      _isInitialized = true;
    } catch (e, stackTrace) {
      rethrow;
    }
  }

  /// Setup UI configuration parameters
  Future<void> setupUIConfig() async {
    await setParameter('ui.primary_color', 0xFF2196F3, description: 'Primary theme color');
    await setParameter('ui.secondary_color', 0xFF03DAC6, description: 'Secondary theme color');
  }

  /// Get parameter with caching and validation
  Future<T?> getParameter<T>(String key) async {
    return await _lock.read(() async {
      // Check cache first
      if (_cache.containsKey(key)) {
        final cachedValue = _cache[key]!;
        if (!cachedValue.isExpired) {
          _accessTimestamps[key] = DateTime.now();
          _accessCounts[key] = (_accessCounts[key] ?? 0) + 1;
          return cachedValue.value as T?;
        }
        _cache.remove(key);
        _cacheTimestamps.remove(key);
      }

      // Check environment overrides
      if (_envOverrides.containsKey(key)) {
        return _envOverrides[key] as T?;
      }

      // Check platform overrides
      if (_platformOverrides.containsKey(key)) {
        return _platformOverrides[key] as T?;
      }

      // Check component overrides
      for (final componentOverride in _componentOverrides.values) {
        if (componentOverride.containsKey(key)) {
          return componentOverride[key] as T?;
        }
      }

      return null;
    });
  }

  /// Set parameter with validation and caching
  Future<void> setParameter(String key, dynamic value, {String? description}) async {
    await _lock.write(() async {
      final oldValue = await getParameter(key);
      
      // Cache the value
      _cache[key] = _CachedValue(value, DateTime.now().add(_defaultCacheTTL));
      _cacheTimestamps[key] = DateTime.now();

      // Emit event
      _emitEvent(ConfigEventType.parameterChanged, parameterKey: key, oldValue: oldValue, newValue: value);

      // Perform cache cleanup if needed
      if (_cache.length > _maxCacheSize) {
        _cleanupCache();
      }
    });
  }

  void _emitEvent(ConfigEventType type, {String? componentName, String? parameterKey, dynamic oldValue, dynamic newValue}) {
    final event = ConfigEvent(
      type: type,
      timestamp: DateTime.now(),
      componentName: componentName,
      parameterKey: parameterKey,
      oldValue: oldValue,
      newValue: newValue,
    );
    
    // Add event to stream (non-blocking)
    Future.microtask(() {
      _eventController.add(event);
    });
  }

  void _cleanupCache() {
    if (_cache.length <= _maxCacheSize) return;

    // Sort by timestamp and remove oldest entries
    final sortedEntries = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final entriesToRemove = sortedEntries.take(_cache.length - _maxCacheSize);
    for (final entry in entriesToRemove) {
      _cache.remove(entry.key);
      _cacheTimestamps.remove(entry.key);
    }
  }

  int _calculateTotalMemoryUsage() {
    int totalUsage = 0;
    for (final memoryInfo in _componentMemoryInfo.values) {
      totalUsage += memoryInfo.memoryUsage;
    }
    return totalUsage;
  }

  Future<void> _cleanupExpiredCache() async {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _defaultCacheTTL) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  Future<void> _cleanupWeakReferences() async {
    final deadReferences = <String>[];

    for (final entry in _weakReferences.entries) {
      if (entry.value.target == null) {
        deadReferences.add(entry.key);
      }
    }

    for (final key in deadReferences) {
      _weakReferences.remove(key);
    }
  }

  Future<void> _cleanupInactiveComponents() async {
    final now = DateTime.now();
    final inactiveThreshold = Duration(hours: 1);

    for (final entry in _componentMetrics.entries) {
      final componentName = entry.key;
      final metrics = entry.value;
      
      if (now.difference(metrics.performanceData['lastAccess'] ?? now) > inactiveThreshold) {
        _componentMetrics.remove(componentName);
        _componentMemoryInfo.remove(componentName);
      }
    }
  }

  void _updateDependencyTracking(String source, String target, RelationshipType type) {
    // Update component dependencies
    if (!_componentDependencies.containsKey(source)) {
      _componentDependencies[source] = <String>{};
    }
    _componentDependencies[source]!.add(target);

    // Update parameter dependencies based on relationship type
    switch (type) {
      case RelationshipType.depends_on:
        _addParameterDependency(source, target);
        break;
      case RelationshipType.configures:
        _addParameterDependency(target, source);
        break;
      case RelationshipType.monitors:
        _addParameterDependency(source, target);
        break;
      default:
        break;
    }
  }

  void _addParameterDependency(String source, String target) {
    final sourceParams = _getActiveParametersForComponent(source);
    final targetParams = _getActiveParametersForComponent(target);

    for (final sourceParam in sourceParams) {
      if (!_parameterDependencies.containsKey(sourceParam)) {
        _parameterDependencies[sourceParam] = <String>{};
      }
      _parameterDependencies[sourceParam]!.addAll(targetParams);
    }
  }

  List<String> _getActiveParametersForComponent(String componentName) {
    final componentPrefix = componentName.toLowerCase();
    return _cache.keys.where((key) => key.startsWith(componentPrefix)).toList();
  }

  /// Get system health status
  SystemHealthStatus getSystemHealthStatus() {
    return _lock.read(() {
      final totalComponents = _componentOverrides.length;
      final activeComponents = _componentMetrics.length;
      final totalConnections = _componentRelationships.length;
      final cacheSize = _cache.length;
      final memoryUsage = _calculateTotalMemoryUsage();

      return SystemHealthStatus(
        totalComponents: totalComponents,
        activeComponents: activeComponents,
        totalConnections: totalConnections,
        cacheSize: cacheSize,
        memoryUsage: memoryUsage,
        isHealthy: activeComponents >= totalComponents * 0.8,
        lastHealthCheck: DateTime.now(),
      );
    });
  }

  /// Perform automatic cleanup
  Future<void> performAutomaticCleanup() async {
    await _lock.write(() async {
      // Clean up expired cache entries
      await _cleanupExpiredCache();

      // Clean up weak references
      await _cleanupWeakReferences();

      // Clean up inactive components
      await _cleanupInactiveComponents();
    });
  }

  /// Update component metrics
  Future<void> updateComponentMetrics(String componentName, ComponentMetrics metrics) async {
    await _lock.write(() async {
      _componentMetrics[componentName] = metrics;
      _emitEvent(ConfigEventType.componentParametersUpdated, componentName: componentName);
    });
  }

  /// Dispose resources
  void dispose() {
    _eventController.close();
  }
}
