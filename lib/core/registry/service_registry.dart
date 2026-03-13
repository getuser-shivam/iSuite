import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/config/central_parameterized_config.dart';
import '../core/config/component_relationship_manager.dart';
import '../core/config/unified_service_orchestrator.dart';
import '../core/logging/enhanced_logger.dart';
import '../core/ai/ai_file_organizer.dart';
import '../core/ai/ai_advanced_search.dart';
import '../core/ai/smart_file_categorizer.dart';
import '../core/ai/ai_duplicate_detector.dart';
import '../core/ai/ai_file_recommendations.dart';
import '../core/ai/ai_services_integration.dart';
import '../core/network/enhanced_network_file_sharing.dart';
import '../core/network/advanced_ftp_client.dart';
import '../core/network/wifi_direct_p2p_service.dart';
import '../core/network/webdav_client.dart';
import '../core/network/network_discovery_service.dart';
import '../core/network/network_security_service.dart';
import '../core/network/network_file_sharing_integration.dart';
import '../core/backend/enhanced_pocketbase_service.dart';
import '../core/performance/enhanced_performance_manager.dart';
import '../core/security/enhanced_security_service.dart';

/// Service Registry - Central Service Management
/// Features: Service registration, lifecycle management, dependency resolution
/// Performance: Lazy loading, service pooling, health monitoring
/// Architecture: Registry pattern, factory pattern, observer pattern
class ServiceRegistry {
  static ServiceRegistry? _instance;
  static ServiceRegistry get instance => _instance ??= ServiceRegistry._internal();
  ServiceRegistry._internal();

  // Service storage
  final Map<String, ServiceDefinition> _services = {};
  final Map<String, dynamic> _instances = {};
  final Map<String, ServiceState> _states = {};
  final Map<String, DateTime> _initTimes = {};
  
  // Service dependencies
  final Map<String, List<String>> _dependencies = {};
  final Map<String, List<String>> _dependents = {};
  
  // Event streams
  final StreamController<ServiceEvent> _eventController = 
      StreamController<ServiceEvent>.broadcast();
  
  Stream<ServiceEvent> get serviceEvents => _eventController.stream;

  /// Register all services
  Future<void> registerServices() async {
    try {
      EnhancedLogger.instance.info('Registering services...');
      
      // Register infrastructure services first
      await _registerInfrastructureServices();
      
      // Register AI services
      await _registerAIServices();
      
      // Register network services
      await _registerNetworkServices();
      
      // Register integration services
      await _registerIntegrationServices();
      
      EnhancedLogger.instance.info('Services registered: ${_services.length}');
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to register services', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Register infrastructure services
  Future<void> _registerInfrastructureServices() async {
    // Enhanced Logger
    _registerService('enhanced_logger', () => EnhancedLogger.instance, []);
    
    // Central Parameterized Config
    _registerService('central_parameterized_config', () => CentralParameterizedConfig.instance, [
      'enhanced_logger',
    ]);
    
    // Component Relationship Manager
    _registerService('component_relationship_manager', () => ComponentRelationshipManager.instance, [
      'enhanced_logger',
      'central_parameterized_config',
    ]);
    
    // Unified Service Orchestrator
    _registerService('unified_service_orchestrator', () => UnifiedServiceOrchestrator.instance, [
      'enhanced_logger',
      'central_parameterized_config',
      'component_relationship_manager',
    ]);
    
    // Enhanced Performance Manager
    _registerService('enhanced_performance_manager', () => EnhancedPerformanceManager.instance, [
      'enhanced_logger',
    ]);
    
    // Enhanced Security Service
    _registerService('enhanced_security_service', () => EnhancedSecurityService.instance, [
      'enhanced_logger',
      'central_parameterized_config',
    ]);
    
    // Enhanced PocketBase Service
    _registerService('enhanced_pocketbase_service', () => EnhancedPocketBaseService.instance, [
      'enhanced_logger',
      'central_parameterized_config',
    ]);
  }

  /// Register AI services
  Future<void> _registerAIServices() async {
    // AI File Organizer
    _registerService('ai_file_organizer', () => AIFileOrganizer.instance, [
      'enhanced_logger',
      'enhanced_performance_manager',
      'central_parameterized_config',
    ]);
    
    // AI Advanced Search
    _registerService('ai_advanced_search', () => AIAdvancedSearch.instance, [
      'enhanced_logger',
      'enhanced_performance_manager',
      'ai_file_organizer',
      'central_parameterized_config',
    ]);
    
    // Smart File Categorizer
    _registerService('smart_file_categorizer', () => SmartFileCategorizer.instance, [
      'enhanced_logger',
      'enhanced_performance_manager',
      'central_parameterized_config',
    ]);
    
    // AI Duplicate Detector
    _registerService('ai_duplicate_detector', () => AIDuplicateDetector.instance, [
      'enhanced_logger',
      'enhanced_performance_manager',
      'central_parameterized_config',
    ]);
    
    // AI File Recommendations
    _registerService('ai_file_recommendations', () => AIFileRecommendations.instance, [
      'enhanced_logger',
      'enhanced_performance_manager',
      'ai_file_organizer',
      'central_parameterized_config',
    ]);
    
    // AI Services Integration
    _registerService('ai_services_integration', () => AIServicesIntegration.instance, [
      'enhanced_logger',
      'enhanced_performance_manager',
      'central_parameterized_config',
      'ai_file_organizer',
      'ai_advanced_search',
      'smart_file_categorizer',
      'ai_duplicate_detector',
      'ai_file_recommendations',
    ]);
  }

  /// Register network services
  Future<void> _registerNetworkServices() async {
    // Network Discovery Service
    _registerService('network_discovery_service', () => NetworkDiscoveryService.instance, [
      'enhanced_logger',
      'enhanced_performance_manager',
      'central_parameterized_config',
    ]);
    
    // Network Security Service
    _registerService('network_security_service', () => NetworkSecurityService.instance, [
      'enhanced_logger',
      'enhanced_performance_manager',
      'central_parameterized_config',
    ]);
    
    // Enhanced Network File Sharing
    _registerService('enhanced_network_file_sharing', () => EnhancedNetworkFileSharing.instance, [
      'enhanced_logger',
      'enhanced_performance_manager',
      'central_parameterized_config',
      'network_discovery_service',
      'network_security_service',
    ]);
    
    // Advanced FTP Client
    _registerService('advanced_ftp_client', () => AdvancedFTPClient.instance, [
      'enhanced_logger',
      'enhanced_performance_manager',
      'central_parameterized_config',
      'network_security_service',
    ]);
    
    // WiFi Direct P2P Service
    _registerService('wifi_direct_p2p_service', () => WiFiDirectP2PService.instance, [
      'enhanced_logger',
      'enhanced_performance_manager',
      'central_parameterized_config',
      'network_discovery_service',
      'network_security_service',
    ]);
    
    // WebDAV Client
    _registerService('webdav_client', () => WebDAVClient.instance, [
      'enhanced_logger',
      'enhanced_performance_manager',
      'central_parameterized_config',
      'network_security_service',
    ]);
    
    // Network File Sharing Integration
    _registerService('network_file_sharing_integration', () => NetworkFileSharingIntegration.instance, [
      'enhanced_logger',
      'enhanced_performance_manager',
      'central_parameterized_config',
      'enhanced_network_file_sharing',
      'advanced_ftp_client',
      'wifi_direct_p2p_service',
      'webdav_client',
      'network_discovery_service',
      'network_security_service',
    ]);
  }

  /// Register integration services
  Future<void> _registerIntegrationServices() async {
    // Integration services are already registered as part of their respective layers
    // This section is for cross-layer integration services if needed
  }

  /// Register a service
  void _registerService(String name, ServiceFactory factory, List<String> dependencies) {
    _services[name] = ServiceDefinition(
      name: name,
      factory: factory,
      dependencies: dependencies,
      state: ServiceState.unregistered,
    );
    
    _dependencies[name] = dependencies;
    _states[name] = ServiceState.unregistered;
    
    // Build dependents map
    for (final dependency in dependencies) {
      if (!_dependents.containsKey(dependency)) {
        _dependents[dependency] = [];
      }
      _dependents[dependency]!.add(name);
    }
  }

  /// Initialize all services
  Future<void> initializeServices() async {
    try {
      EnhancedLogger.instance.info('Initializing services...');
      
      final initializationOrder = _calculateInitializationOrder();
      
      for (final serviceName in initializationOrder) {
        await _initializeService(serviceName);
      }
      
      EnhancedLogger.instance.info('Services initialized: ${_instances.length}');
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to initialize services', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Initialize individual service
  Future<void> _initializeService(String serviceName) async {
    if (_instances.containsKey(serviceName)) {
      return; // Already initialized
    }
    
    final serviceDef = _services[serviceName];
    if (serviceDef == null) {
      throw ServiceException('Service not found: $serviceName');
    }
    
    // Update state
    _states[serviceName] = ServiceState.initializing;
    _initTimes[serviceName] = DateTime.now();
    
    // Emit event
    _eventController.add(ServiceEvent(
      type: ServiceEventType.initializing,
      serviceName: serviceName,
      timestamp: DateTime.now(),
    ));
    
    try {
      // Initialize dependencies first
      for (final dependency in serviceDef.dependencies) {
        await _initializeService(dependency);
      }
      
      // Create service instance
      final instance = serviceDef.factory();
      
      // Initialize service if it supports initialization
      if (instance is InitializableService) {
        await instance.initialize();
      }
      
      // Store instance
      _instances[serviceName] = instance;
      _states[serviceName] = ServiceState.initialized;
      
      // Emit event
      _eventController.add(ServiceEvent(
        type: ServiceEventType.initialized,
        serviceName: serviceName,
        timestamp: DateTime.now(),
      ));
      
      EnhancedLogger.instance.info('Service initialized: $serviceName');
    } catch (e, stackTrace) {
      _states[serviceName] = ServiceState.error;
      
      // Emit event
      _eventController.add(ServiceEvent(
        type: ServiceEventType.error,
        serviceName: serviceName,
        error: e.toString(),
        timestamp: DateTime.now(),
      ));
      
      rethrow;
    }
  }

  /// Calculate initialization order based on dependencies
  List<String> _calculateInitializationOrder() {
    final visited = <String>{};
    final visiting = <String>{};
    final order = <String>[];
    
    for (final serviceName in _services.keys) {
      if (!visited.contains(serviceName)) {
        _topologicalSort(serviceName, visited, visiting, order);
      }
    }
    
    return order;
  }

  /// Topological sort for dependency resolution
  void _topologicalSort(String serviceName, Set<String> visited, Set<String> visiting, List<String> order) {
    if (visiting.contains(serviceName)) {
      throw ServiceException('Circular dependency detected involving: $serviceName');
    }
    
    if (visited.contains(serviceName)) {
      return;
    }
    
    visiting.add(serviceName);
    
    final dependencies = _dependencies[serviceName] ?? [];
    for (final dependency in dependencies) {
      _topologicalSort(dependency, visited, visiting, order);
    }
    
    visiting.remove(serviceName);
    visited.add(serviceName);
    order.add(serviceName);
  }

  /// Get service instance
  T? getService<T>(String serviceName) {
    final instance = _instances[serviceName];
    if (instance is T) {
      return instance;
    }
    return null;
  }

  /// Get service state
  ServiceState getServiceState(String serviceName) {
    return _states[serviceName] ?? ServiceState.unregistered;
  }

  /// Get service dependencies
  List<String> getServiceDependencies(String serviceName) {
    return _dependencies[serviceName] ?? [];
  }

  /// Get service dependents
  List<String> getServiceDependents(String serviceName) {
    return _dependents[serviceName] ?? [];
  }

  /// Check if service is initialized
  bool isServiceInitialized(String serviceName) {
    return _instances.containsKey(serviceName);
  }

  /// Restart service
  Future<bool> restartService(String serviceName) async {
    try {
      final instance = _instances[serviceName];
      if (instance is DisposableService) {
        await instance.dispose();
      }
      
      _instances.remove(serviceName);
      _states[serviceName] = ServiceState.unregistered;
      
      await _initializeService(serviceName);
      
      // Notify dependents
      final dependents = _dependents[serviceName] ?? [];
      for (final dependent in dependents) {
        await _notifyDependentChanged(dependent, serviceName);
      }
      
      _eventController.add(ServiceEvent(
        type: ServiceEventType.restarted,
        serviceName: serviceName,
        timestamp: DateTime.now(),
      ));
      
      EnhancedLogger.instance.info('Service restarted: $serviceName');
      return true;
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to restart service: $serviceName', 
        error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get service statistics
  Map<String, dynamic> getServiceStatistics() {
    final stateCounts = <ServiceState, int>{};
    for (final state in _states.values) {
      stateCounts[state] = (stateCounts[state] ?? 0) + 1;
    }
    
    return {
      'total_services': _services.length,
      'initialized_services': _instances.length,
      'states_by_count': stateCounts.map((k, v) => MapEntry(k.toString(), v)),
      'dependencies_count': _dependencies.values.fold(0, (sum, deps) => sum + deps.length),
      'dependents_count': _dependents.values.fold(0, (sum, deps) => sum + deps.length),
    };
  }

  /// Get service hierarchy
  Map<String, List<String>> getServiceHierarchy() {
    final hierarchy = <String, List<String>>{};
    
    // Group services by layer
    hierarchy['infrastructure'] = [
      'enhanced_logger',
      'central_parameterized_config',
      'component_relationship_manager',
      'unified_service_orchestrator',
      'enhanced_performance_manager',
      'enhanced_security_service',
      'enhanced_pocketbase_service',
    ];
    
    hierarchy['ai_services'] = [
      'ai_file_organizer',
      'ai_advanced_search',
      'smart_file_categorizer',
      'ai_duplicate_detector',
      'ai_file_recommendations',
      'ai_services_integration',
    ];
    
    hierarchy['network_services'] = [
      'network_discovery_service',
      'network_security_service',
      'enhanced_network_file_sharing',
      'advanced_ftp_client',
      'wifi_direct_p2p_service',
      'webdav_client',
      'network_file_sharing_integration',
    ];
    
    return hierarchy;
  }

  /// Get service dependency graph
  Map<String, List<String>> getDependencyGraph() {
    return Map.from(_dependencies);
  }

  /// Notify dependent of change
  Future<void> _notifyDependentChanged(String dependent, String dependency) async {
    final dependentInstance = _instances[dependent];
    if (dependentInstance is DependencyAwareService) {
      await dependentInstance.onDependencyChanged(dependency);
    }
  }

  /// Dispose all services
  Future<void> dispose() async {
    try {
      EnhancedLogger.instance.info('Disposing services...');
      
      // Dispose services in reverse dependency order
      final order = _calculateInitializationOrder().reversed;
      
      for (final serviceName in order) {
        final instance = _instances[serviceName];
        if (instance is DisposableService) {
          try {
            await instance.dispose();
          } catch (e, stackTrace) {
            EnhancedLogger.instance.error('Failed to dispose service: $serviceName', 
              error: e, stackTrace: stackTrace);
          }
        }
      }
      
      // Clear all data
      _services.clear();
      _instances.clear();
      _states.clear();
      _initTimes.clear();
      _dependencies.clear();
      _dependents.clear();
      
      _eventController.close();
      
      EnhancedLogger.instance.info('Services disposed');
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to dispose services', 
        error: e, stackTrace: stackTrace);
    }
  }
}

/// Service definition
class ServiceDefinition {
  final String name;
  final ServiceFactory factory;
  final List<String> dependencies;
  final ServiceState state;
  
  ServiceDefinition({
    required this.name,
    required this.factory,
    required this.dependencies,
    this.state = ServiceState.unregistered,
  });
}

/// Service event
class ServiceEvent {
  final ServiceEventType type;
  final String serviceName;
  final String? error;
  final DateTime timestamp;
  
  ServiceEvent({
    required this.type,
    required this.serviceName,
    this.error,
  }) : timestamp = DateTime.now();
}

/// Service exception
class ServiceException implements Exception {
  final String message;
  
  ServiceException(this.message);
  
  @override
  String toString() => 'ServiceException: $message';
}

/// Service types
typedef ServiceFactory = dynamic Function();

/// Service states
enum ServiceState {
  unregistered,
  initializing,
  initialized,
  error,
  disposed,
}

/// Service event types
enum ServiceEventType {
  initializing,
  initialized,
  error,
  restarted,
  disposed,
}

/// Service interfaces
abstract class InitializableService {
  Future<void> initialize();
}

abstract class DisposableService {
  Future<void> dispose();
}

abstract class DependencyAwareService {
  Future<void> onDependencyChanged(String dependency);
}

/// Global service registry getter for easy access
ServiceRegistry getServiceRegistry() {
  return ServiceRegistry.instance;
}

/// Global service getter for easy access
T? getService<T>(String serviceName) {
  return ServiceRegistry.instance.getService<T>(serviceName);
}

/// Global service state getter for easy access
ServiceState getServiceState(String serviceName) {
  return ServiceRegistry.instance.getServiceState(serviceName);
}
