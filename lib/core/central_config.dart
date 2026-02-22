import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'logging_service.dart';
import 'central_config.dart';

/// Enhanced Central Configuration System
/// Provides comprehensive configuration management with caching, validation, and hot-reload
class CentralConfig {
  static CentralConfig? _instance;
  static CentralConfig get instance => _instance ??= CentralConfig._internal();
  CentralConfig._internal();

  // Enhanced caching system with relationship tracking
  final Map<String, _CachedValue> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _defaultCacheTTL = Duration(minutes: 5);
  final int _maxCacheSize = 1000;

  // Supabase Configuration
  Future<void> setupSupabaseConfig() async {
    await setParameter('supabase.url', '', 
        description: 'Supabase project URL');
    await setParameter('supabase.anon_key', '',
        description: 'Supabase anonymous key');
    await setParameter('supabase.service_key', '',
        description: 'Supabase service key (if needed)');
    await setParameter('supabase.database_url', '',
        description: 'Supabase database URL (if different from project URL)');
    await setParameter('supabase.enable_realtime', true,
        description: 'Enable Supabase realtime subscriptions');
    await setParameter('supabase.auto_retry', true,
        description: 'Enable automatic retry for failed requests');
    await setParameter('supabase.cache_ttl', 300,
        description: 'Cache TTL in seconds for Supabase requests');
    await setParameter('supabase.max_connections', 10,
        description: 'Maximum concurrent Supabase connections');
    await setParameter('supabase.enable_file_upload', true,
        description: 'Enable file upload to Supabase storage');
    await setParameter('supabase.max_file_size', 100 * 1024 * 1024, // 100MB
        description: 'Maximum file size in bytes for uploads');
    await setParameter('supabase.enable_realtime_sync', true,
        description: 'Enable realtime synchronization');
    await setParameter('supabase.sync_interval', 30,
        description: 'Sync interval in seconds');
    await setParameter('supabase.backup_enabled', true,
        description: 'Enable automatic backups');
    await setParameter('supabase.backup_interval', 3600, // 1 hour
        description: 'Backup interval in seconds');
  }

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
  final StreamController _configStreamController = StreamController.broadcast();
  final Map<String, List<Function()>> _dependencyWatchers = {};

  // Environment-based configuration with component overrides
  final Map<String, String> _envOverrides = {};
  final Map<String, String> _platformOverrides = {};
  final Map<String, Map<String, dynamic>> _componentOverrides = {};

  // Memory optimization with component-aware cleanup
  final Map<String, WeakReference> _weakReferences = {};
  final Map<String, ComponentMemoryInfo> _componentMemoryInfo = {};

  // Thread safety with component-level locking
  final _lock = ReadWriteLock();
  final Map<String, ReadWriteLock> _componentLocks = {};
  bool _isInitialized = false;

  // Event streaming
  final StreamController<ConfigEvent> _eventController = StreamController.broadcast();

  Stream<ConfigEvent> get events => _eventController.stream;

  /// Initialize CentralConfig with enhanced features
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Setup default parameters
      await _setupDefaultParameters();
      
      // Setup Supabase configuration
      await setupSupabaseConfig();

      // Setup environment overrides
      await _setupEnvironmentOverrides();

      // Setup platform-specific overrides
      await _setupPlatformOverrides();

      // Start automatic cleanup
      _startAutomaticCleanup();

      _isInitialized = true;
      _emitEvent(ConfigEventType.initialized);

    } catch (e) {
      rethrow;
    }
  }

  /// Get parameter with caching and validation
  T getParameter<T>(String key, {T? defaultValue}) {
    return _lock.read<T>(() {
      // Check cache first
      final cached = _cache[key];
      if (cached != null && !cached.isExpired) {
        _updateAccessMetrics(key);
        return cached.value as T;
      }

      // Get from environment overrides
      final envValue = _envOverrides[key];
      if (envValue != null) {
        final value = _parseValue<T>(envValue);
        _cache[key] = _CachedValue(value, DateTime.now().add(_defaultCacheTTL));
        _updateAccessMetrics(key);
        return value;
      }

      // Get from platform overrides
      final platformValue = _platformOverrides[key];
      if (platformValue != null) {
        final value = _parseValue<T>(platformValue);
        _cache[key] = _CachedValue(value, DateTime.now().add(_defaultCacheTTL));
        _updateAccessMetrics(key);
        return value;
      }

      // Return default value
      if (defaultValue != null) {
        _cache[key] = _CachedValue(defaultValue, DateTime.now().add(_defaultCacheTTL));
        _updateAccessMetrics(key);
        return defaultValue;
      }

      throw ArgumentError('Parameter $key not found and no default value provided');
    });
  }

  /// Set parameter with validation and dependency propagation
  Future<void> setParameter<T>(String key, T value, {String? description}) async {
    await _lock.write(() async {
      final oldValue = _cache[key]?.value;
      
      // Validate parameter
      await _validateParameter(key, value);

      // Update cache
      _cache[key] = _CachedValue(value, DateTime.now().add(_defaultCacheTTL));
      _cacheTimestamps[key] = DateTime.now();

      // Update access metrics
      _updateAccessMetrics(key);

      // Propagate to dependencies
      await _propagateToDependencies(key, value);

      // Notify watchers
      await _notifyWatchers(key, value, oldValue);

      // Emit event
      _emitEvent(ConfigEventType.parameterChanged, parameterKey: key, oldValue: oldValue, newValue: value);

      // Perform cache cleanup if needed
      if (_cache.length > _maxCacheSize) {
        await _performCacheCleanup();
      }
    });
  }

  /// Register component with relationship tracking
  Future<void> registerComponent(
    String componentName,
    String version,
    String description, {
    List<String>? dependencies,
    Map<String, dynamic>? parameters,
  }) async {
    await _lock.write(() async {
      // Store component info
      _componentOverrides[componentName] = {
        'version': version,
        'description': description,
        'dependencies': dependencies ?? [],
        'parameters': parameters ?? {},
        'registeredAt': DateTime.now().toIso8601String(),
      };

      // Setup dependencies
      if (dependencies != null) {
        _componentDependencies[componentName] = Set.from(dependencies);
        for (final dep in dependencies) {
          _componentDependencies[dep] ??= <String>{};
          _componentDependencies[dep]!.add(componentName);
        }
      }

      // Setup component lock
      _componentLocks[componentName] = ReadWriteLock();

      // Initialize component metrics
      _componentMetrics[componentName] = ComponentMetrics(
        componentName: componentName,
        accessCount: 0,
        averageResponseTime: Duration.zero,
        memoryUsage: 0,
        lastAccess: DateTime.now(),
        activeParameters: parameters?.keys.toList() ?? [],
        performanceData: {},
      );

      _emitEvent(ConfigEventType.componentRegistered, componentName: componentName);
    });
  }

  /// Register component relationship
  Future<void> registerComponentRelationship(
    String sourceComponent,
    String targetComponent,
    RelationshipType type,
    String description,
  ) async {
    await _lock.write(() async {
      final relationship = ComponentRelationship(
        sourceComponent: sourceComponent,
        targetComponent: targetComponent,
        type: type,
        description: description,
        createdAt: DateTime.now(),
      );

      _componentRelationships['${sourceComponent}_${targetComponent}'] = relationship;

      // Update dependency tracking
      _updateDependencyTracking(sourceComponent, targetComponent, type);
    });
  }

  /// Watch parameter changes
  void watchParameter(String parameterKey, Function(dynamic) callback) {
    _configWatchers[parameterKey] = callback;
  }

  /// Get component relationships
  List<ComponentRelationship> getComponentRelationships(String componentName) {
    return _componentRelationships.values
        .where((rel) => rel.sourceComponent == componentName || rel.targetComponent == componentName)
        .toList();
  }

  /// Get component metrics
  ComponentMetrics? getComponentMetrics(String componentName) {
    return _componentMetrics[componentName];
  }

  /// Update component metrics
  Future<void> updateComponentMetrics(String componentName, ComponentMetrics metrics) async {
    await _lock.write(() async {
      _componentMetrics[componentName] = metrics;
      _emitEvent(ConfigEventType.componentParametersUpdated, componentName: componentName);
    });
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

  /// Setup Supabase configuration
  Future<void> _setupSupabaseConfig() async {
    await setParameter('supabase.url', '', 
        description: 'Supabase project URL');
    await setParameter('supabase.anon_key', '',
        description: 'Supabase anonymous key');
    await setParameter('supabase.service_key', '',
        description: 'Supabase service key (if needed)');
    await setParameter('supabase.database_url', '',
        description: 'Supabase database URL (if different from project URL)');
    await setParameter('supabase.enable_realtime', true,
        description: 'Enable Supabase realtime subscriptions');
    await setParameter('supabase.auto_retry', true,
        description: 'Enable automatic retry for failed requests');
    await setParameter('supabase.cache_ttl', 300,
        description: 'Cache TTL in seconds for Supabase requests');
    await setParameter('supabase.max_connections', 10,
        description: 'Maximum concurrent Supabase connections');
    await setParameter('supabase.enable_file_upload', true,
        description: 'Enable file upload to Supabase storage');
    await setParameter('supabase.max_file_size', 100 * 1024 * 1024, // 100MB
        description: 'Maximum file size in bytes for uploads');
    await setParameter('supabase.enable_realtime_sync', true,
        description: 'Enable realtime synchronization');
  T _parseValue<T>(String value) {
    if (T == String) return value as T;
    if (T == int) return int.parse(value) as T;
    if (T == double) return double.parse(value) as T;
    if (T == bool) return (value.toLowerCase() == 'true') as T;
    if (T == Duration) return Duration(seconds: int.parse(value)) as T;
    
    throw ArgumentError('Unsupported type: $T');
  }

  Future<void> _validateParameter(String key, dynamic value) async {
    // Basic validation
    if (key.isEmpty) {
      throw ArgumentError('Parameter key cannot be empty');
    }

    // Type-specific validation
    if (key.contains('port') && value is int) {
      if (value < 1 || value > 65535) {
        throw ArgumentError('Port must be between 1 and 65535');
      }
    }

    if (key.contains('timeout') && value is Duration) {
      if (value.inSeconds < 1 || value.inSeconds > 300) {
        throw ArgumentError('Timeout must be between 1 and 300 seconds');
      }
    }

    if (key.contains('color') && value is int) {
      if (value < 0 || value > 0xFFFFFFFF) {
        throw ArgumentError('Color must be a valid 32-bit integer');
      }
    }
  }

  void _updateAccessMetrics(String key) {
    _accessTimestamps[key] = DateTime.now();
    _accessCounts[key] = (_accessCounts[key] ?? 0) + 1;
  }

  Future<void> _propagateToDependencies(String key, dynamic value) async {
    final dependencies = _parameterDependencies[key];
    if (dependencies != null) {
      for (final dep in dependencies) {
        final watchers = _dependencyWatchers[dep];
        if (watchers != null) {
          for (final watcher in watchers) {
            try {
              watcher();
            } catch (e) {
              // Log error but don't fail
            }
          }
        }
      }
    }
  }

  Future<void> _notifyWatchers(String key, dynamic newValue, dynamic oldValue) async {
    final watcher = _configWatchers[key];
    if (watcher != null) {
      try {
        watcher(newValue);
      } catch (e) {
        // Log error but don't fail
      }
    }
  }

  Future<void> _performCacheCleanup() async {
    if (_cache.length <= _maxCacheSize) return;

    // Sort by last access time and remove oldest entries
    final sortedEntries = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final entriesToRemove = sortedEntries.take(_cache.length - _maxCacheSize);
    for (final entry in entriesToRemove) {
      _cache.remove(entry.key);
      _cacheTimestamps.remove(entry.key);
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
      final timestamp = entry.value;
      final key = entry.key;
      
      if (now.difference(timestamp) > _defaultCacheTTL) {
        expiredKeys.add(key);
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
      final key = entry.key;
      final reference = entry.value;
      
      if (reference.target == null) {
        deadReferences.add(key);
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
      
      if (now.difference(metrics.lastAccess) > inactiveThreshold) {
        // Mark component as inactive
        final memoryInfo = _componentMemoryInfo[componentName];
        if (memoryInfo != null) {
          _componentMemoryInfo[componentName] = ComponentMemoryInfo(
            componentName: memoryInfo.componentName,
            memoryUsage: memoryInfo.memoryUsage,
            cacheSize: memoryInfo.cacheSize,
            objectCount: memoryInfo.objectCount,
            lastCleanup: memoryInfo.lastCleanup,
            needsCleanup: true,
          );
        }
      }
    }
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
    _eventController.add(event);
  }

  /// Dispose
  void dispose() {
    _eventController.close();
    _isInitialized = false;
  }
}

// Supporting classes

class _CachedValue {
  final dynamic value;
  final DateTime expiry;

  _CachedValue(this.value, this.expiry);

  bool get isExpired => DateTime.now().isAfter(expiry);
}

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
}

enum RelationshipType {
  depends_on,
  provides_to,
  configures,
  monitors,
  extends,
  implements,
  uses,
  contains,
}

class ComponentRelationship {
  final String sourceComponent;
  final String targetComponent;
  final RelationshipType type;
  final String description;
  final DateTime createdAt;

  ComponentRelationship({
    required this.sourceComponent,
    required this.targetComponent,
    required this.type,
    required this.description,
    required this.createdAt,
  });
}

class ComponentMetrics {
  final String componentName;
  final int accessCount;
  final Duration averageResponseTime;
  final int memoryUsage;
  final DateTime lastAccess;
  final List<String> activeParameters;
  final Map<String, dynamic> performanceData;

  ComponentMetrics({
    required this.componentName,
    required this.accessCount,
    required this.averageResponseTime,
    required this.memoryUsage,
    required this.lastAccess,
    required this.activeParameters,
    required this.performanceData,
  });
}

class ComponentMemoryInfo {
  final String componentName;
  final int memoryUsage;
  final int cacheSize;
  final int objectCount;
  final DateTime lastCleanup;
  final bool needsCleanup;

  ComponentMemoryInfo({
    required this.componentName,
    required this.memoryUsage,
    required this.cacheSize,
    required this.objectCount,
    required this.lastCleanup,
    required this.needsCleanup,
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

// Simple ReadWriteLock implementation
class ReadWriteLock {
  int _readers = 0;
  bool _writer = false;
  final Queue<Completer<void>> _writerQueue = Queue<Completer<void>>();
  final Queue<Completer<void>> _readerQueue = Queue<Completer<void>>();

  T read<T>(T Function() operation) {
    if (_writer) {
      // Wait for writer to finish
      final completer = Completer<void>();
      _readerQueue.add(completer);
      completer.future.then((_) => operation());
    } else {
      _readers++;
      try {
        return operation();
      } finally {
        _readers--;
        if (_readers == 0 && _writerQueue.isNotEmpty) {
          _writerQueue.removeFirst().complete();
        }
      }
    }
    return operation();
  }

  Future<T> write<T>(Future<T> Function() operation) async {
    if (_writer || _readers > 0) {
      final completer = Completer<void>();
      _writerQueue.add(completer);
      await completer.future;
    }

    _writer = true;
    try {
      return await operation();
    } finally {
      _writer = false;
      if (_writerQueue.isNotEmpty) {
        _writerQueue.removeFirst().complete();
      } else if (_readerQueue.isNotEmpty) {
        for (final completer in _readerQueue) {
          completer.complete();
        }
        _readerQueue.clear();
      }
    }
  }
}
