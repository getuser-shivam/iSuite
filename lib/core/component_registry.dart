import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../presentation/providers/theme_provider.dart';
import '../presentation/providers/user_provider.dart';
import '../presentation/providers/task_provider.dart';
import '../presentation/providers/calendar_provider.dart';
import '../presentation/providers/note_provider.dart';
import '../presentation/providers/file_provider.dart';
import '../presentation/providers/analytics_provider.dart';
import '../presentation/providers/backup_provider.dart';
import '../presentation/providers/search_provider.dart';
import '../presentation/providers/reminder_provider.dart';
import '../presentation/providers/task_suggestion_provider.dart';
import '../presentation/providers/task_automation_provider.dart';
import '../presentation/providers/network_provider.dart';
import '../presentation/providers/file_sharing_provider.dart';
import '../presentation/providers/cloud_sync_provider.dart';

/// Central component registry for managing all app components
class ComponentRegistry {
  static ComponentRegistry? _instance;
  static ComponentRegistry get instance => _instance ??= ComponentRegistry._internal();
  ComponentRegistry._internal();

  final Map<Type, dynamic> _components = {};
  final Map<String, dynamic> _parameters = {};
  final Map<Type, List<Type>> _dependencies = {};
  bool _isInitialized = false;

  /// Initialize all components with proper dependency injection
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize core parameters
      await _initializeParameters();
      
      // Register dependencies
      _registerDependencies();
      
      // Initialize components in dependency order
      await _initializeComponents();
      
      _isInitialized = true;
      debugPrint('ComponentRegistry: All components initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('ComponentRegistry initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Initialize global parameters
  Future<void> _initializeParameters() async {
    _parameters['app_version'] = '1.0.0';
    _parameters['debug_mode'] = true;
    _parameters['enable_analytics'] = true;
    _parameters['enable_cloud_sync'] = true;
    _parameters['max_file_size'] = 100 * 1024 * 1024; // 100MB
    _parameters['supported_languages'] = ['en', 'es', 'fr', 'de', 'zh', 'ja'];
    _parameters['default_language'] = 'en';
    _parameters['theme_transition_duration'] = Duration(milliseconds: 300);
    _parameters['animation_duration'] = Duration(milliseconds: 200);
    _parameters['network_timeout'] = Duration(seconds: 30);
    _parameters['retry_attempts'] = 3;
    _parameters['cache_size'] = 50 * 1024 * 1024; // 50MB
    _parameters['enable_notifications'] = true;
    _parameters['enable_location'] = false;
    _parameters['enable_camera'] = true;
    _parameters['enable_microphone'] = false;
  }

  /// Register component dependencies
  void _registerDependencies() {
    // Theme provider has no dependencies
    _dependencies[ThemeProvider] = [];
    
    // User provider depends on theme provider
    _dependencies[UserProvider] = [ThemeProvider];
    
    // Task providers depend on user and theme providers
    _dependencies[TaskProvider] = [UserProvider, ThemeProvider];
    _dependencies[TaskSuggestionProvider] = [TaskProvider, AnalyticsProvider];
    _dependencies[TaskAutomationProvider] = [TaskProvider, ReminderProvider];
    
    // Other providers depend on user provider
    _dependencies[CalendarProvider] = [UserProvider];
    _dependencies[NoteProvider] = [UserProvider];
    _dependencies[FileProvider] = [UserProvider];
    _dependencies[AnalyticsProvider] = [UserProvider];
    _dependencies[BackupProvider] = [UserProvider];
    _dependencies[SearchProvider] = [UserProvider];
    _dependencies[ReminderProvider] = [UserProvider];
    _dependencies[NetworkProvider] = [UserProvider];
    _dependencies[FileSharingProvider] = [NetworkProvider, UserProvider];
    _dependencies[CloudSyncProvider] = [UserProvider, FileProvider, TaskProvider];
  }

  /// Initialize components in dependency order
  Future<void> _initializeComponents() async {
    final initialized = <Type>{};
    
    // Initialize components respecting dependencies
    for (final componentType in _dependencies.keys) {
      await _initializeComponent(componentType, initialized);
    }
  }

  /// Initialize a single component and its dependencies
  Future<void> _initializeComponent(Type componentType, Set<Type> initialized) async {
    if (initialized.contains(componentType)) return;

    // Initialize dependencies first
    final dependencies = _dependencies[componentType] ?? [];
    for (final dependency in dependencies) {
      await _initializeComponent(dependency, initialized);
    }

    // Create component instance
    final component = await _createComponent(componentType);
    _components[componentType] = component;
    initialized.add(componentType);
    
    debugPrint('ComponentRegistry: Initialized $componentType');
  }

  /// Create component instance with proper parameters
  Future<dynamic> _createComponent(Type componentType) async {
    switch (componentType) {
      case ThemeProvider:
        return ThemeProvider();
        
      case UserProvider:
        return UserProvider();
        
      case TaskProvider:
        return TaskProvider();
        
      case CalendarProvider:
        return CalendarProvider();
        
      case NoteProvider:
        return NoteProvider();
        
      case FileProvider:
        return FileProvider();
        
      case AnalyticsProvider:
        return AnalyticsProvider();
        
      case BackupProvider:
        return BackupProvider();
        
      case SearchProvider:
        return SearchProvider();
        
      case ReminderProvider:
        return ReminderProvider();
        
      case TaskSuggestionProvider:
        return TaskSuggestionProvider();
        
      case TaskAutomationProvider:
        return TaskAutomationProvider();
        
      case NetworkProvider:
        return NetworkProvider();
        
      case FileSharingProvider:
        return FileSharingProvider();
        
      case CloudSyncProvider:
        return CloudSyncProvider();
        
      default:
        throw ArgumentError('Unknown component type: $componentType');
    }
  }

  /// Get component instance
  T getComponent<T>() {
    final component = _components[T];
    if (component == null) {
      throw StateError('Component $T not found. Make sure initialize() was called.');
    }
    return component as T;
  }

  /// Get parameter value
  T getParameter<T>(String key) {
    final value = _parameters[key];
    if (value == null) {
      throw StateError('Parameter $key not found');
    }
    return value as T;
  }

  /// Set parameter value
  void setParameter(String key, dynamic value) {
    _parameters[key] = value;
    debugPrint('ComponentRegistry: Set parameter $key = $value');
  }

  /// Get all providers for MultiProvider
  List<ChangeNotifierProvider> getAllProviders() {
    return _components.entries
        .where((entry) => entry.value is ChangeNotifier)
        .map((entry) => ChangeNotifierProvider(create: (_) => entry.value))
        .toList();
  }

  /// Check if component is initialized
  bool isInitialized<T>() {
    return _components.containsKey(T);
  }

  /// Get component dependencies
  List<Type> getDependencies<T>() {
    return _dependencies[T] ?? [];
  }

  /// Update component parameters
  void updateComponentParameters<T>(Map<String, dynamic> parameters) {
    final component = getComponent<T>();
    if (component is ParameterizedComponent) {
      component.updateParameters(parameters);
    }
  }

  /// Get component status
  Map<String, dynamic> getComponentStatus() {
    return {
      'initialized': _isInitialized,
      'component_count': _components.length,
      'parameter_count': _parameters.length,
      'components': _components.keys.map((type) => type.toString()).toList(),
      'parameters': _parameters.keys.toList(),
    };
  }

  /// Reset registry (for testing)
  void reset() {
    _components.clear();
    _parameters.clear();
    _dependencies.clear();
    _isInitialized = false;
  }
}

/// Abstract class for components that can be parameterized
abstract class ParameterizedComponent {
  void updateParameters(Map<String, dynamic> parameters);
}

/// Extension for easy access to registry
extension ComponentRegistryExtension on BuildContext {
  T getRegistryComponent<T>() => ComponentRegistry.instance.getComponent<T>();
  T getRegistryParameter<T>(String key) => ComponentRegistry.instance.getParameter<T>(key);
}
