import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'component_registry.dart';
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

/// Factory for creating and managing components with centralized configuration
class ComponentFactory {
  static ComponentFactory? _instance;
  static ComponentFactory get instance =>
      _instance ??= ComponentFactory._internal();
  ComponentFactory._internal();

  final ComponentRegistry _registry = ComponentRegistry.instance;
  final Map<String, ComponentConfig> _configurations = {};

  /// Initialize factory with default configurations
  Future<void> initialize() async {
    await _setupDefaultConfigurations();
    await _registry.initialize();
    debugPrint(
        'ComponentFactory: Initialized with ${_configurations.length} configurations');
  }

  /// Setup default component configurations
  void _setupDefaultConfigurations() {
    // Theme provider configuration
    _configurations['theme_provider'] = ComponentConfig(
      type: ThemeProvider,
      parameters: {
        'default_theme': 'system',
        'enable_custom_themes': true,
        'theme_cache_size': 10,
        'auto_switch_theme': true,
      },
      dependencies: [],
    );

    // User provider configuration
    _configurations['user_provider'] = ComponentConfig(
      type: UserProvider,
      parameters: {
        'session_timeout': Duration(hours: 24),
        'enable_biometric': true,
        'max_login_attempts': 3,
        'cache_user_data': true,
      },
      dependencies: [ThemeProvider],
    );

    // Task provider configuration
    _configurations['task_provider'] = ComponentConfig(
      type: TaskProvider,
      parameters: {
        'max_tasks_per_page': 50,
        'enable_task_suggestions': true,
        'auto_save_interval': Duration(minutes: 5),
        'task_history_limit': 1000,
        'enable_task_recurrence': true,
      },
      dependencies: [UserProvider, ThemeProvider],
    );

    // Calendar provider configuration
    _configurations['calendar_provider'] = ComponentConfig(
      type: CalendarProvider,
      parameters: {
        'default_view': 'month',
        'enable_reminders': true,
        'sync_with_google': false,
        'event_duration_default': Duration(hours: 1),
        'max_events_per_day': 100,
      },
      dependencies: [UserProvider],
    );

    // Note provider configuration
    _configurations['note_provider'] = ComponentConfig(
      type: NoteProvider,
      parameters: {
        'max_note_size': 1024 * 1024, // 1MB
        'enable_rich_text': true,
        'auto_save_interval': Duration(seconds: 30),
        'enable_note_encryption': true,
        'max_notes_per_user': 10000,
      },
      dependencies: [UserProvider],
    );

    // File provider configuration
    _configurations['file_provider'] = ComponentConfig(
      type: FileProvider,
      parameters: {
        'max_file_size': 100 * 1024 * 1024, // 100MB
        'allowed_extensions': [
          '.pdf',
          '.doc',
          '.docx',
          '.txt',
          '.jpg',
          '.png',
          '.mp4',
          '.mp3'
        ],
        'enable_file_encryption': true,
        'auto_backup': true,
        'cache_thumbnails': true,
      },
      dependencies: [UserProvider],
    );

    // Analytics provider configuration
    _configurations['analytics_provider'] = ComponentConfig(
      type: AnalyticsProvider,
      parameters: {
        'enable_tracking': true,
        'data_retention_days': 365,
        'enable_ml_predictions': true,
        'batch_size': 100,
        'update_interval': Duration(hours: 1),
      },
      dependencies: [UserProvider],
    );

    // Backup provider configuration
    _configurations['backup_provider'] = ComponentConfig(
      type: BackupProvider,
      parameters: {
        'auto_backup_interval': Duration(days: 1),
        'max_backup_count': 10,
        'enable_encryption': true,
        'backup_location': 'local',
        'compress_backups': true,
      },
      dependencies: [UserProvider],
    );

    // Search provider configuration
    _configurations['search_provider'] = ComponentConfig(
      type: SearchProvider,
      parameters: {
        'max_results': 50,
        'enable_fuzzy_search': true,
        'search_history_size': 100,
        'index_content': true,
        'search_timeout': Duration(seconds: 5),
      },
      dependencies: [UserProvider],
    );

    // Reminder provider configuration
    _configurations['reminder_provider'] = ComponentConfig(
      type: ReminderProvider,
      parameters: {
        'max_reminders': 1000,
        'default_snooze_duration': Duration(minutes: 5),
        'enable_smart_scheduling': true,
        'notification_sound': 'default',
        'enable_vibration': true,
      },
      dependencies: [UserProvider],
    );

    // Task suggestion provider configuration
    _configurations['task_suggestion_provider'] = ComponentConfig(
      type: TaskSuggestionProvider,
      parameters: {
        'enable_ai_suggestions': true,
        'suggestion_count': 5,
        'learning_enabled': true,
        'update_interval': Duration(hours: 6),
        'confidence_threshold': 0.7,
      },
      dependencies: [TaskProvider, AnalyticsProvider],
    );

    // Task automation provider configuration
    _configurations['task_automation_provider'] = ComponentConfig(
      type: TaskAutomationProvider,
      parameters: {
        'enable_automation': true,
        'max_automations': 50,
        'execution_interval': Duration(minutes: 15),
        'enable_smart_rules': true,
        'log_actions': true,
      },
      dependencies: [TaskProvider, ReminderProvider],
    );

    // Network provider configuration
    _configurations['network_provider'] = ComponentConfig(
      type: NetworkProvider,
      parameters: {
        'scan_interval': Duration(seconds: 30),
        'max_networks': 50,
        'enable_hotspot': true,
        'auto_connect_saved': false,
        'security_check_enabled': true,
      },
      dependencies: [UserProvider],
    );

    // File sharing provider configuration
    _configurations['file_sharing_provider'] = ComponentConfig(
      type: FileSharingProvider,
      parameters: {
        'server_port': 8080,
        'max_concurrent_transfers': 5,
        'enable_encryption': true,
        'chunk_size': 1024 * 1024, // 1MB
        'timeout_duration': Duration(minutes: 10),
      },
      dependencies: [NetworkProvider, UserProvider],
    );

    // Cloud sync provider configuration
    _configurations['cloud_sync_provider'] = ComponentConfig(
      type: CloudSyncProvider,
      parameters: {
        'sync_interval': Duration(minutes: 15),
        'enable_background_sync': true,
        'conflict_resolution': 'manual',
        'max_sync_retries': 3,
        'enable_compression': true,
      },
      dependencies: [UserProvider, FileProvider, TaskProvider],
    );
  }

  /// Create component with configuration
  T createComponent<T>(String configKey) {
    final config = _configurations[configKey];
    if (config == null) {
      throw ArgumentError('Configuration not found for key: $configKey');
    }

    return _createComponentFromConfig<T>(config);
  }

  /// Create component from configuration
  T _createComponentFromConfig<T>(ComponentConfig config) {
    // Check if component is already created
    if (_registry.isInitialized<T>()) {
      return _registry.getComponent<T>();
    }

    // Create component with parameters
    final component = _instantiateComponent<T>(config.type);

    // Apply configuration parameters
    if (component is ParameterizedComponent) {
      component.updateParameters(config.parameters);
    }

    return component;
  }

  /// Instantiate component by type
  T _instantiateComponent<T>(Type type) {
    switch (type) {
      case ThemeProvider:
        return ThemeProvider() as T;
      case UserProvider:
        return UserProvider() as T;
      case TaskProvider:
        return TaskProvider() as T;
      case CalendarProvider:
        return CalendarProvider() as T;
      case NoteProvider:
        return NoteProvider() as T;
      case FileProvider:
        return FileProvider() as T;
      case AnalyticsProvider:
        return AnalyticsProvider() as T;
      case BackupProvider:
        return BackupProvider() as T;
      case SearchProvider:
        return SearchProvider() as T;
      case ReminderProvider:
        return ReminderProvider() as T;
      case TaskSuggestionProvider:
        return TaskSuggestionProvider() as T;
      case TaskAutomationProvider:
        return TaskAutomationProvider() as T;
      case NetworkProvider:
        return NetworkProvider() as T;
      case FileSharingProvider:
        return FileSharingProvider() as T;
      case CloudSyncProvider:
        return CloudSyncProvider() as T;
      default:
        throw ArgumentError('Cannot instantiate component of type: $type');
    }
  }

  /// Update component configuration
  void updateConfiguration(String configKey, Map<String, dynamic> parameters) {
    final config = _configurations[configKey];
    if (config != null) {
      config.parameters.addAll(parameters);

      // Update existing component if already created
      if (_registry.isInitialized(config.type)) {
        _registry.updateComponentParameters(config.type, parameters);
      }
    }
  }

  /// Get component configuration
  ComponentConfig? getConfiguration(String configKey) {
    return _configurations[configKey];
  }

  /// Get all configurations
  Map<String, ComponentConfig> getAllConfigurations() {
    return Map.from(_configurations);
  }

  /// Validate component dependencies
  bool validateDependencies() {
    for (final config in _configurations.values) {
      for (final dependency in config.dependencies) {
        if (!_configurations.values.any((c) => c.type == dependency)) {
          debugPrint(
              'Missing dependency $dependency for component ${config.type}');
          return false;
        }
      }
    }
    return true;
  }

  /// Get dependency graph
  Map<Type, List<Type>> getDependencyGraph() {
    final graph = <Type, List<Type>>{};
    for (final config in _configurations.values) {
      graph[config.type] = config.dependencies;
    }
    return graph;
  }

  /// Create all providers for MultiProvider
  List<ChangeNotifierProvider> createAllProviders() {
    return _configurations.values
        .where((config) => _isChangeNotifier(config.type))
        .map((config) => ChangeNotifierProvider(
            create: (_) => _createComponentFromConfig(config.type)))
        .toList();
  }

  /// Get all providers for MultiProvider (alias for createAllProviders)
  List<ChangeNotifierProvider> getAllProviders() {
    return createAllProviders();
  }

  /// Check if type is ChangeNotifier
  bool _isChangeNotifier(Type type) {
    return [
      ThemeProvider,
      UserProvider,
      TaskProvider,
      CalendarProvider,
      NoteProvider,
      FileProvider,
      AnalyticsProvider,
      BackupProvider,
      SearchProvider,
      ReminderProvider,
      TaskSuggestionProvider,
      TaskAutomationProvider,
      NetworkProvider,
      FileSharingProvider,
      CloudSyncProvider,
    ].contains(type);
  }
}

/// Component configuration class
class ComponentConfig {
  final Type type;
  final Map<String, dynamic> parameters;
  final List<Type> dependencies;
  final String? description;
  final bool isSingleton;
  final bool isLazy;

  ComponentConfig({
    required this.type,
    this.parameters = const {},
    this.dependencies = const [],
    this.description,
    this.isSingleton = true,
    this.isLazy = true,
  });

  ComponentConfig copyWith({
    Type? type,
    Map<String, dynamic>? parameters,
    List<Type>? dependencies,
    String? description,
    bool? isSingleton,
    bool? isLazy,
  }) {
    return ComponentConfig(
      type: type ?? this.type,
      parameters: parameters ?? this.parameters,
      dependencies: dependencies ?? this.dependencies,
      description: description ?? this.description,
      isSingleton: isSingleton ?? this.isSingleton,
      isLazy: isLazy ?? this.isLazy,
    );
  }

  @override
  String toString() {
    return 'ComponentConfig(type: $type, dependencies: $dependencies, parameters: $parameters)';
  }
}

/// Extension for easy factory access
extension ComponentFactoryExtension on BuildContext {
  T createComponent<T>(String configKey) =>
      ComponentFactory.instance.createComponent<T>(configKey);
  ComponentConfig? getComponentConfig(String configKey) =>
      ComponentFactory.instance.getConfiguration(configKey);
}
