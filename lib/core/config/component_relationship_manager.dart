import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'central_parameterized_config.dart';
import '../logging/enhanced_logger.dart';

/// Component Relationship Manager
/// Features: Component dependency management, service coordination, lifecycle management
/// Performance: Dependency injection, lazy loading, component pooling
/// Architecture: Observer pattern, factory pattern, dependency injection pattern
class ComponentRelationshipManager {
  static ComponentRelationshipManager? _instance;
  static ComponentRelationshipManager get instance => _instance ??= ComponentRelationshipManager._internal();
  ComponentRelationshipManager._internal();

  // Component registry
  final Map<String, ComponentDefinition> _components = {};
  final Map<String, dynamic> _instances = {};
  final Map<String, List<String>> _dependencies = {};
  final Map<String, List<String>> _dependents = {};
  
  // Lifecycle management
  final Map<String, ComponentState> _states = {};
  final Map<String, DateTime> _initTimes = {};
  final List<ComponentObserver> _observers = [];
  
  // Dependency injection
  final Map<String, dynamic> _services = {};
  final Map<String, ServiceFactory> _factories = {};
  
  // Event streams
  final StreamController<ComponentEvent> _eventController = 
      StreamController<ComponentEvent>.broadcast();
  
  Stream<ComponentEvent> get componentEvents => _eventController.stream;

  /// Initialize component relationship manager
  Future<void> initialize() async {
    try {
      // Register core components
      await _registerCoreComponents();
      
      // Setup dependency relationships
      await _setupDependencyRelationships();
      
      // Initialize components in dependency order
      await _initializeComponents();
      
      EnhancedLogger.instance.info('Component Relationship Manager initialized');
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to initialize Component Relationship Manager', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Register core components
  Future<void> _registerCoreComponents() async {
    // AI Services Components
    _registerComponent('ai_file_organizer', () => AIFileOrganizerComponent(), [
      'enhanced_logger',
      'enhanced_performance_manager',
      'central_parameterized_config',
    ]);
    
    _registerComponent('ai_advanced_search', () => AIAdvancedSearchComponent(), [
      'ai_file_organizer',
      'enhanced_logger',
      'enhanced_performance_manager',
    ]);
    
    _registerComponent('smart_file_categorizer', () => SmartFileCategorizerComponent(), [
      'enhanced_logger',
      'enhanced_performance_manager',
      'central_parameterized_config',
    ]);
    
    _registerComponent('ai_duplicate_detector', () => AIDuplicateDetectorComponent(), [
      'enhanced_logger',
      'enhanced_performance_manager',
    ]);
    
    _registerComponent('ai_file_recommendations', () => AIFileRecommendationsComponent(), [
      'ai_file_organizer',
      'enhanced_logger',
      'enhanced_performance_manager',
    ]);
    
    _registerComponent('ai_services_integration', () => AIServicesIntegrationComponent(), [
      'ai_file_organizer',
      'ai_advanced_search',
      'smart_file_categorizer',
      'ai_duplicate_detector',
      'ai_file_recommendations',
      'enhanced_logger',
      'enhanced_performance_manager',
    ]);
    
    // Network Services Components
    _registerComponent('enhanced_network_file_sharing', () => EnhancedNetworkFileSharingComponent(), [
      'network_discovery_service',
      'network_security_service',
      'enhanced_logger',
      'enhanced_performance_manager',
      'central_parameterized_config',
    ]);
    
    _registerComponent('advanced_ftp_client', () => AdvancedFTPClientComponent(), [
      'network_security_service',
      'enhanced_logger',
      'enhanced_performance_manager',
      'central_parameterized_config',
    ]);
    
    _registerComponent('wifi_direct_p2p_service', () => WiFiDirectP2PServiceComponent(), [
      'network_discovery_service',
      'network_security_service',
      'enhanced_logger',
      'enhanced_performance_manager',
    ]);
    
    _registerComponent('webdav_client', () => WebDAVClientComponent(), [
      'network_security_service',
      'enhanced_logger',
      'enhanced_performance_manager',
      'central_parameterized_config',
    ]);
    
    _registerComponent('network_discovery_service', () => NetworkDiscoveryServiceComponent(), [
      'enhanced_logger',
      'enhanced_performance_manager',
      'central_parameterized_config',
    ]);
    
    _registerComponent('network_security_service', () => NetworkSecurityServiceComponent(), [
      'enhanced_logger',
      'enhanced_performance_manager',
      'central_parameterized_config',
    ]);
    
    _registerComponent('network_file_sharing_integration', () => NetworkFileSharingIntegrationComponent(), [
      'enhanced_network_file_sharing',
      'advanced_ftp_client',
      'wifi_direct_p2p_service',
      'webdav_client',
      'network_discovery_service',
      'network_security_service',
      'enhanced_logger',
      'enhanced_performance_manager',
    ]);
    
    // Core Infrastructure Components
    _registerComponent('enhanced_logger', () => EnhancedLoggerComponent(), []);
    _registerComponent('enhanced_performance_manager', () => EnhancedPerformanceManagerComponent(), [
      'enhanced_logger',
    ]);
    _registerComponent('central_parameterized_config', () => CentralParameterizedConfigComponent(), [
      'enhanced_logger',
    ]);
    
    EnhancedLogger.instance.info('Core components registered: ${_components.length}');
  }

  /// Setup dependency relationships
  Future<void> _setupDependencyRelationships() async {
    // Build dependency and dependent maps
    for (final entry in _components.entries) {
      final componentName = entry.key;
      final component = entry.value;
      
      _dependencies[componentName] = component.dependencies;
      
      // Build dependents map (reverse dependencies)
      for (final dependency in component.dependencies) {
        if (!_dependents.containsKey(dependency)) {
          _dependents[dependency] = [];
        }
        _dependents[dependency]!.add(componentName);
      }
    }
    
    EnhancedLogger.instance.info('Dependency relationships setup completed');
  }

  /// Initialize components in dependency order
  Future<void> _initializeComponents() async {
    final initializationOrder = _calculateInitializationOrder();
    
    for (final componentName in initializationOrder) {
      try {
        await _initializeComponent(componentName);
      } catch (e, stackTrace) {
        EnhancedLogger.instance.error('Failed to initialize component: $componentName', 
          error: e, stackTrace: stackTrace);
        // Continue with other components
      }
    }
    
    EnhancedLogger.instance.info('Components initialized: ${_instances.length}');
  }

  /// Register component
  void _registerComponent(String name, ComponentFactory factory, List<String> dependencies) {
    _components[name] = ComponentDefinition(
      name: name,
      factory: factory,
      dependencies: dependencies,
      state: ComponentState.uninitialized,
    );
    
    _states[name] = ComponentState.uninitialized;
  }

  /// Initialize individual component
  Future<void> _initializeComponent(String componentName) async {
    if (_instances.containsKey(componentName)) {
      return; // Already initialized
    }
    
    final component = _components[componentName];
    if (component == null) {
      throw ComponentException('Component not found: $componentName');
    }
    
    // Update state
    _states[componentName] = ComponentState.initializing;
    _initTimes[componentName] = DateTime.now();
    
    // Notify observers
    _notifyObservers(componentName, ComponentState.initializing);
    
    // Emit event
    _eventController.add(ComponentEvent(
      type: ComponentEventType.componentInitializing,
      componentName: componentName,
      timestamp: DateTime.now(),
    ));
    
    try {
      // Check dependencies
      for (final dependency in component.dependencies) {
        if (!_instances.containsKey(dependency)) {
          await _initializeComponent(dependency);
        }
      }
      
      // Create instance
      final instance = component.factory();
      
      // Initialize component if it supports initialization
      if (instance is InitializableComponent) {
        await instance.initialize();
      }
      
      // Store instance
      _instances[componentName] = instance;
      
      // Update state
      _states[componentName] = ComponentState.initialized;
      
      // Notify observers
      _notifyObservers(componentName, ComponentState.initialized);
      
      // Emit event
      _eventController.add(ComponentEvent(
        type: ComponentEventType.componentInitialized,
        componentName: componentName,
        timestamp: DateTime.now(),
      ));
      
      EnhancedLogger.instance.info('Component initialized: $componentName');
    } catch (e, stackTrace) {
      _states[componentName] = ComponentState.error;
      
      // Notify observers
      _notifyObservers(componentName, ComponentState.error);
      
      // Emit event
      _eventController.add(ComponentEvent(
        type: ComponentEventType.componentError,
        componentName: componentName,
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
    
    for (final componentName in _components.keys) {
      if (!visited.contains(componentName)) {
        _topologicalSort(componentName, visited, visiting, order);
      }
    }
    
    return order;
  }

  /// Topological sort for dependency resolution
  void _topologicalSort(String componentName, Set<String> visited, Set<String> visiting, List<String> order) {
    if (visiting.contains(componentName)) {
      throw ComponentException('Circular dependency detected involving: $componentName');
    }
    
    if (visited.contains(componentName)) {
      return;
    }
    
    visiting.add(componentName);
    
    final component = _components[componentName];
    if (component != null) {
      for (final dependency in component.dependencies) {
        _topologicalSort(dependency, visited, visiting, order);
      }
    }
    
    visiting.remove(componentName);
    visited.add(componentName);
    order.add(componentName);
  }

  /// Get component instance
  T? getComponent<T>(String componentName) {
    final instance = _instances[componentName];
    if (instance is T) {
      return instance;
    }
    return null;
  }

  /// Get component state
  ComponentState getComponentState(String componentName) {
    return _states[componentName] ?? ComponentState.uninitialized;
  }

  /// Get component dependencies
  List<String> getComponentDependencies(String componentName) {
    return _dependencies[componentName] ?? [];
  }

  /// Get component dependents
  List<String> getComponentDependents(String componentName) {
    return _dependents[componentName] ?? [];
  }

  /// Check if component is initialized
  bool isComponentInitialized(String componentName) {
    return _instances.containsKey(componentName);
  }

  /// Restart component
  Future<bool> restartComponent(String componentName) async {
    try {
      // Dispose component if it supports disposal
      final instance = _instances[componentName];
      if (instance is DisposableComponent) {
        await instance.dispose();
      }
      
      // Remove instance
      _instances.remove(componentName);
      _states[componentName] = ComponentState.uninitialized;
      
      // Re-initialize
      await _initializeComponent(componentName);
      
      // Notify dependents
      final dependents = _dependents[componentName] ?? [];
      for (final dependent in dependents) {
        await _notifyDependencyChanged(dependent, componentName);
      }
      
      _eventController.add(ComponentEvent(
        type: ComponentEventType.componentRestarted,
        componentName: componentName,
        timestamp: DateTime.now(),
      ));
      
      EnhancedLogger.instance.info('Component restarted: $componentName');
      return true;
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to restart component: $componentName', 
        error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Add component observer
  void addObserver(ComponentObserver observer) {
    _observers.add(observer);
  }

  /// Remove component observer
  void removeObserver(ComponentObserver observer) {
    _observers.remove(observer);
  }

  /// Get component statistics
  Map<String, dynamic> getComponentStatistics() {
    final stateCounts = <ComponentState, int>{};
    for (final state in _states.values) {
      stateCounts[state] = (stateCounts[state] ?? 0) + 1;
    }
    
    return {
      'total_components': _components.length,
      'initialized_components': _instances.length,
      'states_by_count': stateCounts.map((k, v) => MapEntry(k.toString(), v)),
      'dependencies_count': _dependencies.values.fold(0, (sum, deps) => sum + deps.length),
      'dependents_count': _dependents.values.fold(0, (sum, deps) => sum + deps.length),
      'observers_count': _observers.length,
    };
  }

  /// Helper methods
  void _notifyObservers(String componentName, ComponentState state) {
    for (final observer in _observers) {
      observer.onComponentStateChanged(componentName, state);
    }
  }

  Future<void> _notifyDependencyChanged(String dependent, String dependency) async {
    final dependentInstance = _instances[dependent];
    if (dependentInstance is DependencyAwareComponent) {
      await dependentInstance.onDependencyChanged(dependency);
    }
  }

  /// Dispose
  Future<void> dispose() async {
    // Dispose components in reverse dependency order
    final order = _calculateInitializationOrder().reversed;
    
    for (final componentName in order) {
      final instance = _instances[componentName];
      if (instance is DisposableComponent) {
        try {
          await instance.dispose();
        } catch (e, stackTrace) {
          EnhancedLogger.instance.error('Failed to dispose component: $componentName', 
            error: e, stackTrace: stackTrace);
        }
      }
    }
    
    // Clear all data
    _components.clear();
    _instances.clear();
    _dependencies.clear();
    _dependents.clear();
    _states.clear();
    _initTimes.clear();
    _observers.clear();
    _services.clear();
    _factories.clear();
    
    _eventController.close();
    
    EnhancedLogger.instance.info('Component Relationship Manager disposed');
  }
}

/// Component definition
class ComponentDefinition {
  final String name;
  final ComponentFactory factory;
  final List<String> dependencies;
  ComponentState state;
  
  ComponentDefinition({
    required this.name,
    required this.factory,
    required this.dependencies,
    this.state = ComponentState.uninitialized,
  });
}

/// Component event
class ComponentEvent {
  final ComponentEventType type;
  final String componentName;
  final String? error;
  final DateTime timestamp;
  
  ComponentEvent({
    required this.type,
    required this.componentName,
    this.error,
  }) : timestamp = DateTime.now();
}

/// Component exception
class ComponentException implements Exception {
  final String message;
  
  ComponentException(this.message);
  
  @override
  String toString() => 'ComponentException: $message';
}

/// Component types
typedef ComponentFactory = dynamic Function();

/// Service factory
typedef ServiceFactory = dynamic Function(Map<String, dynamic>);

/// Component states
enum ComponentState {
  uninitialized,
  initializing,
  initialized,
  error,
  disposed,
}

/// Component event types
enum ComponentEventType {
  componentInitializing,
  componentInitialized,
  componentError,
  componentRestarted,
  componentDisposed,
}

/// Component interfaces
abstract class InitializableComponent {
  Future<void> initialize();
}

abstract class DisposableComponent {
  Future<void> dispose();
}

abstract class DependencyAwareComponent {
  Future<void> onDependencyChanged(String dependency);
}

abstract class ComponentObserver {
  void onComponentStateChanged(String componentName, ComponentState state);
}

/// Component base classes
abstract class BaseComponent implements InitializableComponent, DisposableComponent {
  final String name;
  ComponentState _state = ComponentState.uninitialized;
  
  BaseComponent(this.name);
  
  ComponentState get state => _state;
  
  @override
  Future<void> initialize() async {
    _state = ComponentState.initializing;
    await onInitialize();
    _state = ComponentState.initialized;
  }
  
  @override
  Future<void> dispose() async {
    await onDispose();
    _state = ComponentState.disposed;
  }
  
  Future<void> onInitialize() async {
    // Override in subclasses
  }
  
  Future<void> onDispose() async {
    // Override in subclasses
  }
}

/// Mock component implementations for demonstration
class AIFileOrganizerComponent extends BaseComponent {
  AIFileOrganizerComponent() : super('ai_file_organizer');
}

class AIAdvancedSearchComponent extends BaseComponent {
  AIAdvancedSearchComponent() : super('ai_advanced_search');
}

class SmartFileCategorizerComponent extends BaseComponent {
  SmartFileCategorizerComponent() : super('smart_file_categorizer');
}

class AIDuplicateDetectorComponent extends BaseComponent {
  AIDuplicateDetectorComponent() : super('ai_duplicate_detector');
}

class AIFileRecommendationsComponent extends BaseComponent {
  AIFileRecommendationsComponent() : super('ai_file_recommendations');
}

class AIServicesIntegrationComponent extends BaseComponent {
  AIServicesIntegrationComponent() : super('ai_services_integration');
}

class EnhancedNetworkFileSharingComponent extends BaseComponent {
  EnhancedNetworkFileSharingComponent() : super('enhanced_network_file_sharing');
}

class AdvancedFTPClientComponent extends BaseComponent {
  AdvancedFTPClientComponent() : super('advanced_ftp_client');
}

class WiFiDirectP2PServiceComponent extends BaseComponent {
  WiFiDirectP2PServiceComponent() : super('wifi_direct_p2p_service');
}

class WebDAVClientComponent extends BaseComponent {
  WebDAVClientComponent() : super('webdav_client');
}

class NetworkDiscoveryServiceComponent extends BaseComponent {
  NetworkDiscoveryServiceComponent() : super('network_discovery_service');
}

class NetworkSecurityServiceComponent extends BaseComponent {
  NetworkSecurityServiceComponent() : super('network_security_service');
}

class NetworkFileSharingIntegrationComponent extends BaseComponent {
  NetworkFileSharingIntegrationComponent() : super('network_file_sharing_integration');
}

class EnhancedLoggerComponent extends BaseComponent {
  EnhancedLoggerComponent() : super('enhanced_logger');
}

class EnhancedPerformanceManagerComponent extends BaseComponent {
  EnhancedPerformanceManagerComponent() : super('enhanced_performance_manager');
}

class CentralParameterizedConfigComponent extends BaseComponent {
  CentralParameterizedConfigComponent() : super('central_parameterized_config');
}

/// Global component getter for easy access
T? getComponent<T>(String componentName) {
  return ComponentRelationshipManager.instance.getComponent<T>(componentName);
}

/// Global component state getter for easy access
ComponentState getComponentState(String componentName) {
  return ComponentRelationshipManager.instance.getComponentState(componentName);
}
