import 'package:flutter/material.dart';
import 'component_registry.dart';

/// Base interface for all components that can be parameterized
abstract class BaseComponent {
  /// Component unique identifier
  String get id;
  
  /// Component name
  String get name;
  
  /// Component version
  String get version;
  
  /// Component dependencies
  List<Type> get dependencies;
  
  /// Component parameters
  Map<String, dynamic> get parameters;
  
  /// Update component parameters
  void updateParameters(Map<String, dynamic> newParameters);
  
  /// Get parameter value with type safety
  T getParameter<T>(String key, [T? defaultValue]);
  
  /// Set parameter value
  void setParameter(String key, dynamic value);
  
  /// Check if component is initialized
  bool get isInitialized;
  
  /// Initialize component
  Future<void> initialize();
  
  /// Dispose component resources
  void dispose();
  
  /// Get component status
  Map<String, dynamic> getStatus();
}

/// Abstract base class for components with common functionality
abstract class BaseComponentImpl extends BaseComponent {
  final Map<String, dynamic> _parameters = {};
  bool _isInitialized = false;
  
  @override
  Map<String, dynamic> get parameters => Map.from(_parameters);
  
  @override
  bool get isInitialized => _isInitialized;
  
  @override
  void updateParameters(Map<String, dynamic> newParameters) {
    _parameters.addAll(newParameters);
    onParametersUpdated(newParameters);
  }
  
  @override
  T getParameter<T>(String key, [T? defaultValue]) {
    final value = _parameters[key];
    if (value == null) return defaultValue ?? (throw ArgumentError('Parameter $key not found'));
    return value as T;
  }
  
  @override
  void setParameter(String key, dynamic value) {
    _parameters[key] = value;
    onParameterChanged(key, value);
  }
  
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await onInitialize();
    _isInitialized = true;
    debugPrint('$name: Component initialized');
  }
  
  @override
  void dispose() {
    onDispose();
    _parameters.clear();
    _isInitialized = false;
    debugPrint('$name: Component disposed');
  }
  
  @override
  Map<String, dynamic> getStatus() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'initialized': _isInitialized,
      'parameters': _parameters,
      'dependencies': dependencies.map((d) => d.toString()).toList(),
    };
  }
  
  /// Called when parameters are updated
  void onParametersUpdated(Map<String, dynamic> updatedParameters) {}
  
  /// Called when a single parameter changes
  void onParameterChanged(String key, dynamic value) {}
  
  /// Called during initialization
  Future<void> onInitialize() async {}
  
  /// Called during disposal
  void onDispose() {}
}

/// Base class for providers with enhanced parameterization
abstract class BaseProvider extends ChangeNotifier implements BaseComponent {
  final Map<String, dynamic> _parameters = {};
  bool _isInitialized = false;
  String? _error;
  
  @override
  Map<String, dynamic> get parameters => Map.from(_parameters);
  
  @override
  bool get isInitialized => _isInitialized;
  
  String? get error => _error;
  
  @override
  void updateParameters(Map<String, dynamic> newParameters) {
    _parameters.addAll(newParameters);
    onParametersUpdated(newParameters);
    notifyListeners();
  }
  
  @override
  T getParameter<T>(String key, [T? defaultValue]) {
    final value = _parameters[key];
    if (value == null) return defaultValue ?? (throw ArgumentError('Parameter $key not found'));
    return value as T;
  }
  
  @override
  void setParameter(String key, dynamic value) {
    _parameters[key] = value;
    onParameterChanged(key, value);
    notifyListeners();
  }
  
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await onInitialize();
      _isInitialized = true;
      debugPrint('$name: Provider initialized successfully');
    } catch (e) {
      _error = e.toString();
      debugPrint('$name: Provider initialization failed: $e');
      rethrow;
    }
  }
  
  @override
  void dispose() {
    onDispose();
    _parameters.clear();
    _isInitialized = false;
    super.dispose();
    debugPrint('$name: Provider disposed');
  }
  
  @override
  Map<String, dynamic> getStatus() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'initialized': _isInitialized,
      'parameters': _parameters,
      'dependencies': dependencies.map((d) => d.toString()).toList(),
      'error': _error,
      'has_listeners': hasListeners,
    };
  }
  
  /// Set error state
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Called when parameters are updated
  void onParametersUpdated(Map<String, dynamic> updatedParameters) {}
  
  /// Called when a single parameter changes
  void onParameterChanged(String key, dynamic value) {}
  
  /// Called during initialization
  Future<void> onInitialize() async {}
  
  /// Called during disposal
  void onDispose() {}
}

/// Component lifecycle manager
class ComponentLifecycleManager {
  static ComponentLifecycleManager? _instance;
  static ComponentLifecycleManager get instance => _instance ??= ComponentLifecycleManager._internal();
  ComponentLifecycleManager._internal();

  final Map<String, BaseComponent> _components = {};
  final Map<String, List<VoidCallback>> _listeners = {};

  /// Register component
  void registerComponent(BaseComponent component) {
    _components[component.id] = component;
    debugPrint('LifecycleManager: Registered component ${component.id}');
  }

  /// Unregister component
  void unregisterComponent(String componentId) {
    final component = _components.remove(componentId);
    if (component != null) {
      component.dispose();
      _listeners.remove(componentId);
      debugPrint('LifecycleManager: Unregistered component $componentId');
    }
  }

  /// Get component
  T? getComponent<T extends BaseComponent>(String id) {
    return _components[id] as T?;
  }

  /// Initialize all components
  Future<void> initializeAll() async {
    for (final component in _components.values) {
      if (!component.isInitialized) {
        try {
          await component.initialize();
        } catch (e) {
          debugPrint('Failed to initialize component ${component.id}: $e');
        }
      }
    }
  }

  /// Dispose all components
  void disposeAll() {
    for (final component in _components.values) {
      component.dispose();
    }
    _components.clear();
    _listeners.clear();
  }

  /// Add lifecycle listener
  void addListener(String componentId, VoidCallback listener) {
    _listeners.putIfAbsent(componentId, () => []).add(listener);
  }

  /// Remove lifecycle listener
  void removeListener(String componentId, VoidCallback listener) {
    _listeners[componentId]?.remove(listener);
  }

  /// Notify listeners
  void notifyListeners(String componentId) {
    final listeners = _listeners[componentId];
    if (listeners != null) {
      for (final listener in listeners) {
        listener();
      }
    }
  }

  /// Get all component statuses
  Map<String, Map<String, dynamic>> getAllStatuses() {
    return _components.map((key, component) => MapEntry(key, component.getStatus()));
  }
}

/// Component communication system
class ComponentCommunication {
  static ComponentCommunication? _instance;
  static ComponentCommunication get instance => _instance ??= ComponentCommunication._internal();
  ComponentCommunication._internal();

  final Map<String, List<Function(dynamic)>> _subscribers = {};

  /// Subscribe to component events
  void subscribe(String event, Function(dynamic) callback) {
    _subscribers.putIfAbsent(event, () => []).add(callback);
  }

  /// Unsubscribe from component events
  void unsubscribe(String event, Function(dynamic) callback) {
    _subscribers[event]?.remove(callback);
  }

  /// Publish event
  void publish(String event, dynamic data) {
    final subscribers = _subscribers[event];
    if (subscribers != null) {
      for (final subscriber in subscribers) {
        try {
          subscriber(data);
        } catch (e) {
          debugPrint('Error in subscriber for event $event: $e');
        }
      }
    }
  }

  /// Clear all subscribers
  void clear() {
    _subscribers.clear();
  }
}

/// Extension for easy access to component systems
extension ComponentExtensions on BuildContext {
  T? getComponent<T extends BaseComponent>(String id) {
    return ComponentLifecycleManager.instance.getComponent<T>(id);
  }
  
  void subscribeToEvent(String event, Function(dynamic) callback) {
    ComponentCommunication.instance.subscribe(event, callback);
  }
  
  void publishEvent(String event, dynamic data) {
    ComponentCommunication.instance.publish(event, data);
  }
}
