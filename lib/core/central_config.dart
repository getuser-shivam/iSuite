import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central Configuration System for iSuite
/// Provides unified parameter management across all components
/// Ensures proper centralization and well-connected relationships
class CentralConfig {
  static CentralConfig? _instance;
  static CentralConfig get instance => _instance ??= CentralConfig._internal();
  CentralConfig._internal();

  // App Configuration
  static const String _appName = 'iSuite';
  static const String _appVersion = '1.0.0';
  static const String _buildNumber = '1';
  
  // Free Framework Preferences (User Requirements)
  static const String _primaryFramework = 'Flutter'; // Free, cross-platform
  static const String _backendFramework = 'Supabase'; // Free tier available
  static const String _localDatabase = 'SQLite'; // Free, embedded
  
  // Network & File Sharing Configuration
  static const int _defaultPort = 8080;
  static const String _defaultWifiSSID = 'iSuite_Share';
  static const String _defaultWifiPassword = 'isuite123';
  static const Duration _defaultTimeout = Duration(seconds: 30);
  
  // Cross-Platform Support
  static const List<String> _supportedPlatforms = [
    'android', 'ios', 'windows', 'linux', 'macos', 'web'
  ];
  
  // Central Parameter Store
  final Map<String, dynamic> _parameters = {};
  final Map<String, ParameterType> _parameterTypes = {};
  final Map<String, String> _parameterDescriptions = {};
  
  // Component Registry
  final Map<String, ComponentConfig> _components = {};
  final Map<String, List<String>> _componentDependencies = {};
  
  // Event System
  final StreamController<ConfigEvent> _eventController = 
      StreamController<ConfigEvent>.broadcast();
  
  // State
  bool _isInitialized = false;
  SharedPreferences? _prefs;

  // Getters
  String get appName => _appName;
  String get appVersion => _appVersion;
  String get buildNumber => _buildNumber;
  String get primaryFramework => _primaryFramework;
  String get backendFramework => _backendFramework;
  String get localDatabase => _localDatabase;
  int get defaultPort => _defaultPort;
  String get defaultWifiSSID => _defaultWifiSSID;
  String get defaultWifiPassword => _defaultWifiPassword;
  Duration get defaultTimeout => _defaultTimeout;
  List<String> get supportedPlatforms => List.from(_supportedPlatforms);
  bool get isInitialized => _isInitialized;
  Stream<ConfigEvent> get events => _eventController.stream;

  /// Initialize central configuration
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Load saved parameters
      await _loadParameters();
      
      // Register default parameters
      await _registerDefaultParameters();
      
      // Register components
      await _registerComponents();
      
      // Establish component relationships
      await _establishRelationships();
      
      _isInitialized = true;
      await _emitEvent(ConfigEvent.initialized);
      
      debugPrint('CentralConfig initialized successfully');
    } catch (e) {
      debugPrint('CentralConfig initialization failed: $e');
      rethrow;
    }
  }

  /// Get a parameter value with type safety
  T? getParameter<T>(String key, {T? defaultValue}) {
    if (!_isInitialized) {
      debugPrint('CentralConfig not initialized');
      return defaultValue;
    }

    final value = _parameters[key];
    if (value == null) return defaultValue;

    // Type checking and conversion
    if (T == String) {
      return value.toString() as T;
    } else if (T == int) {
      if (value is int) return value as T;
      if (value is String) {
        final intValue = int.tryParse(value);
        return intValue as T?;
      }
    } else if (T == double) {
      if (value is double) return value as T;
      if (value is String) {
        final doubleValue = double.tryParse(value);
        return doubleValue as T?;
      }
    } else if (T == bool) {
      if (value is bool) return value as T;
      if (value is String) {
        final boolValue = value.toLowerCase() == 'true';
        return boolValue as T;
      }
    } else if (T == List<String>) {
      if (value is List) {
        return value.map((e) => e.toString()).toList() as T;
      }
      if (value is String) {
        try {
          final listValue = jsonDecode(value);
          if (listValue is List) {
            return listValue.map((e) => e.toString()).toList() as T;
          }
        } catch (e) {
          debugPrint('Failed to parse list parameter: $e');
        }
      }
    }

    debugPrint('Parameter type mismatch for key: $key, expected: $T, got: ${value.runtimeType}');
    return defaultValue;
  }

  /// Set a parameter value with type safety and validation
  Future<bool> setParameter<T>(String key, T value, {
    String? description,
    bool persist = true,
    bool notifyComponents = true,
  }) async {
    if (!_isInitialized) {
      debugPrint('CentralConfig not initialized');
      return false;
    }

    try {
      // Validate parameter
      if (!_validateParameter(key, value)) {
        debugPrint('Parameter validation failed for key: $key');
        return false;
      }

      final oldValue = _parameters[key];
      _parameters[key] = value;
      _parameterTypes[key] = _getParameterType<T>();
      
      if (description != null) {
        _parameterDescriptions[key] = description;
      }

      // Persist if required
      if (persist && _prefs != null) {
        await _persistParameter(key, value);
      }

      // Notify dependent components
      if (notifyComponents) {
        await _notifyComponents(key, oldValue, value);
      }

      await _emitEvent(ConfigEvent.parameterChanged(key, oldValue, value));
      
      debugPrint('Parameter set: $key = $value');
      return true;
    } catch (e) {
      debugPrint('Failed to set parameter: $key, error: $e');
      return false;
    }
  }

  /// Register a component with its configuration
  Future<void> registerComponent(String componentName, ComponentConfig config) async {
    _components[componentName] = config;
    
    // Register component parameters
    for (final param in config.parameters) {
      _parameterTypes[param.key] = param.type;
      _parameterDescriptions[param.key] = param.description;
      
      if (!_parameters.containsKey(param.key)) {
        _parameters[param.key] = param.defaultValue;
      }
    }

    await _emitEvent(ConfigEvent.componentRegistered(componentName));
    debugPrint('Component registered: $componentName');
  }

  /// Get component configuration
  ComponentConfig? getComponentConfig(String componentName) {
    return _components[componentName];
  }

  /// Get all registered components
  Map<String, ComponentConfig> getAllComponents() {
    return Map.from(_components);
  }

  /// Establish relationship between components
  void setComponentRelationship(String parent, String child) {
    _componentDependencies.putIfAbsent(parent, () => []).add(child);
    debugPrint('Component relationship set: $parent -> $child');
  }

  /// Get component dependencies
  List<String> getComponentDependencies(String componentName) {
    return List.from(_componentDependencies[componentName] ?? []);
  }

  /// Get all parameters for a component
  Map<String, dynamic> getComponentParameters(String componentName) {
    final config = _components[componentName];
    if (config == null) return {};

    final componentParams = <String, dynamic>{};
    for (final param in config.parameters) {
      componentParams[param.key] = _parameters[param.key] ?? param.defaultValue;
    }

    return componentParams;
  }

  /// Update component parameters
  Future<bool> updateComponentParameters(String componentName, Map<String, dynamic> params) async {
    final config = _components[componentName];
    if (config == null) return false;

    try {
      for (final entry in params.entries) {
        if (config.parameters.any((p) => p.key == entry.key)) {
          await setParameter(entry.key, entry.value);
        }
      }

      await _emitEvent(ConfigEvent.componentParametersUpdated(componentName));
      return true;
    } catch (e) {
      debugPrint('Failed to update component parameters: $e');
      return false;
    }
  }

  /// Get configuration summary
  Map<String, dynamic> getConfigurationSummary() {
    return {
      'app': {
        'name': _appName,
        'version': _appVersion,
        'build': _buildNumber,
        'framework': _primaryFramework,
        'backend': _backendFramework,
        'database': _localDatabase,
        'platforms': _supportedPlatforms,
      },
      'network': {
        'defaultPort': _defaultPort,
        'defaultWifiSSID': _defaultWifiSSID,
        'defaultTimeout': _defaultTimeout.inMilliseconds,
      },
      'components': _components.keys.toList(),
      'parameters': _parameters.length,
      'relationships': _componentDependencies,
      'isInitialized': _isInitialized,
    };
  }

  /// Export configuration
  String exportConfiguration() {
    final config = {
      'version': _appVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'parameters': _parameters,
      'components': _components.map((k, v) => MapEntry(k, v.toMap())),
      'relationships': _componentDependencies,
    };
    
    return jsonEncode(config);
  }

  /// Import configuration
  Future<bool> importConfiguration(String configJson) async {
    try {
      final config = jsonDecode(configJson);
      
      if (config['parameters'] is Map) {
        for (final entry in config['parameters'].entries) {
          await setParameter(entry.key, entry.value, persist: false);
        }
      }

      if (config['components'] is Map) {
        for (final entry in config['components'].entries) {
          final componentConfig = ComponentConfig.fromMap(entry.value);
          await registerComponent(entry.key, componentConfig);
        }
      }

      if (config['relationships'] is Map) {
        for (final entry in config['relationships'].entries) {
          for (final child in entry.value) {
            setComponentRelationship(entry.key, child);
          }
        }
      }

      await _emitEvent(ConfigEvent.configurationImported);
      return true;
    } catch (e) {
      debugPrint('Failed to import configuration: $e');
      return false;
    }
  }

  /// Reset to defaults
  Future<void> resetToDefaults() async {
    _parameters.clear();
    _parameterTypes.clear();
    _parameterDescriptions.clear();
    _components.clear();
    _componentDependencies.clear();
    
    await _prefs?.clear();
    await _registerDefaultParameters();
    await _registerComponents();
    await _establishRelationships();
    
    await _emitEvent(ConfigEvent.resetToDefaults);
  }

  /// Private methods
  Future<void> _loadParameters() async {
    if (_prefs == null) return;

    final keys = _prefs!.getKeys();
    for (final key in keys) {
      if (key.startsWith('config_')) {
        final paramKey = key.substring(7); // Remove 'config_' prefix
        final value = _prefs!.get(key);
        if (value != null) {
          _parameters[paramKey] = value;
        }
      }
    }
  }

  Future<void> _persistParameter(String key, dynamic value) async {
    if (_prefs == null) return;

    final prefKey = 'config_$key';
    
    if (value is String) {
      await _prefs!.setString(prefKey, value);
    } else if (value is int) {
      await _prefs!.setInt(prefKey, value);
    } else if (value is double) {
      await _prefs!.setDouble(prefKey, value);
    } else if (value is bool) {
      await _prefs!.setBool(prefKey, value);
    } else if (value is List) {
      await _prefs!.setString(prefKey, jsonEncode(value));
    } else {
      await _prefs!.setString(prefKey, jsonEncode(value));
    }
  }

  Future<void> _registerDefaultParameters() async {
    // App parameters
    await setParameter('app_theme', 'system', description: 'App theme preference');
    await setParameter('app_language', 'en', description: 'App language');
    await setParameter('enable_notifications', true, description: 'Enable notifications');
    await setParameter('auto_sync', true, description: 'Enable automatic sync');
    
    // Network parameters
    await setParameter('network_auto_discovery', true, description: 'Enable network auto-discovery');
    await setParameter('network_share_timeout', _defaultTimeout.inSeconds, description: 'Network share timeout');
    await setParameter('ftp_port', 21, description: 'FTP port');
    await setParameter('http_port', _defaultPort, description: 'HTTP port');
    
    // File sharing parameters
    await setParameter('max_file_size', 100 * 1024 * 1024, description: 'Maximum file size in bytes');
    await setParameter('allowed_file_types', ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png'], description: 'Allowed file types');
    await setParameter('enable_encryption', false, description: 'Enable file encryption');
    
    // UI parameters
    await setParameter('ui_density', 'comfortable', description: 'UI density');
    await setParameter('enable_animations', true, description: 'Enable animations');
    await setParameter('primary_color', '#1976D2', description: 'Primary color');
    
    // Performance parameters
    await setParameter('cache_size', 50 * 1024 * 1024, description: 'Cache size in bytes');
    await setParameter('max_concurrent_uploads', 3, description: 'Maximum concurrent uploads');
    await setParameter('max_concurrent_downloads', 3, description: 'Maximum concurrent downloads');
  }

  Future<void> _registerComponents() async {
    // Network Sharing Component
    await registerComponent('network_sharing', ComponentConfig(
      name: 'Network Sharing',
      version: '1.0.0',
      description: 'WiFi and file sharing capabilities',
      parameters: [
        ParameterConfig('network_auto_discovery', ParameterType.bool, true, 'Enable network auto-discovery'),
        ParameterConfig('network_share_timeout', ParameterType.int, _defaultTimeout.inSeconds, 'Network share timeout'),
        ParameterConfig('default_wifi_ssid', ParameterType.string, _defaultWifiSSID, 'Default WiFi SSID'),
        ParameterConfig('default_wifi_password', ParameterType.string, _defaultWifiPassword, 'Default WiFi password'),
        ParameterConfig('max_concurrent_transfers', ParameterType.int, 5, 'Maximum concurrent transfers'),
      ],
    ));

    // File Management Component
    await registerComponent('file_management', ComponentConfig(
      name: 'File Management',
      version: '1.0.0',
      description: 'File operations and storage management',
      parameters: [
        ParameterConfig('max_file_size', ParameterType.int, 100 * 1024 * 1024, 'Maximum file size'),
        ParameterConfig('allowed_file_types', ParameterType.list, ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png'], 'Allowed file types'),
        ParameterConfig('enable_encryption', ParameterType.bool, false, 'Enable file encryption'),
        ParameterConfig('auto_backup', ParameterType.bool, true, 'Enable automatic backup'),
      ],
    ));

    // Supabase Component
    await registerComponent('supabase', ComponentConfig(
      name: 'Supabase Backend',
      version: '1.0.0',
      description: 'Cloud backend integration',
      parameters: [
        ParameterConfig('supabase_url', ParameterType.string, '', 'Supabase URL'),
        ParameterConfig('supabase_anon_key', ParameterType.string, '', 'Supabase anonymous key'),
        ParameterConfig('enable_offline_sync', ParameterType.bool, true, 'Enable offline sync'),
        ParameterConfig('sync_interval', ParameterType.int, 300, 'Sync interval in seconds'),
      ],
    ));

    // UI Component
    await registerComponent('ui', ComponentConfig(
      name: 'User Interface',
      version: '1.0.0',
      description: 'User interface settings',
      parameters: [
        ParameterConfig('app_theme', ParameterType.string, 'system', 'App theme'),
        ParameterConfig('app_language', ParameterType.string, 'en', 'App language'),
        ParameterConfig('ui_density', ParameterType.string, 'comfortable', 'UI density'),
        ParameterConfig('enable_animations', ParameterType.bool, true, 'Enable animations'),
        ParameterConfig('primary_color', ParameterType.string, '#1976D2', 'Primary color'),
      ],
    ));

    // Performance Component
    await registerComponent('performance', ComponentConfig(
      name: 'Performance',
      version: '1.0.0',
      description: 'Performance optimization settings',
      parameters: [
        ParameterConfig('cache_size', ParameterType.int, 50 * 1024 * 1024, 'Cache size'),
        ParameterConfig('max_concurrent_uploads', ParameterType.int, 3, 'Maximum concurrent uploads'),
        ParameterConfig('max_concurrent_downloads', ParameterType.int, 3, 'Maximum concurrent downloads'),
        ParameterConfig('enable_performance_monitoring', ParameterType.bool, true, 'Enable performance monitoring'),
      ],
    ));
  }

  Future<void> _establishRelationships() async {
    // UI depends on Performance
    setComponentRelationship('ui', 'performance');
    
    // Network Sharing depends on Performance and File Management
    setComponentRelationship('network_sharing', 'performance');
    setComponentRelationship('network_sharing', 'file_management');
    
    // File Management depends on Performance and Supabase
    setComponentRelationship('file_management', 'performance');
    setComponentRelationship('file_management', 'supabase');
    
    // Supabase depends on Performance
    setComponentRelationship('supabase', 'performance');
  }

  bool _validateParameter(String key, dynamic value) {
    // Add validation logic here
    if (key.isEmpty) return false;
    if (value == null) return false;
    
    // Type-specific validation
    final type = _parameterTypes[key];
    if (type != null) {
      switch (type) {
        case ParameterType.string:
          return value is String;
        case ParameterType.int:
          return value is int || (value is String && int.tryParse(value) != null);
        case ParameterType.double:
          return value is double || (value is String && double.tryParse(value) != null);
        case ParameterType.bool:
          return value is bool || (value is String && ['true', 'false'].contains(value.toLowerCase()));
        case ParameterType.list:
          return value is List || (value is String && _isValidJsonList(value));
      }
    }
    
    return true;
  }

  ParameterType _getParameterType<T>() {
    if (T == String) return ParameterType.string;
    if (T == int) return ParameterType.int;
    if (T == double) return ParameterType.double;
    if (T == bool) return ParameterType.bool;
    if (T == List) return ParameterType.list;
    return ParameterType.string;
  }

  bool _isValidJsonList(String value) {
    try {
      final parsed = jsonDecode(value);
      return parsed is List;
    } catch (e) {
      return false;
    }
  }

  Future<void> _notifyComponents(String key, dynamic oldValue, dynamic newValue) async {
    // Find components that use this parameter
    for (final component in _components.entries) {
      if (component.value.parameters.any((p) => p.key == key)) {
        await _emitEvent(ConfigEvent.componentNotified(component.key, key, newValue));
      }
    }
  }

  Future<void> _emitEvent(ConfigEvent event) async {
    _eventController.add(event);
  }

  /// Dispose
  void dispose() {
    _eventController.close();
    _isInitialized = false;
  }
}

// Supporting Classes
enum ParameterType {
  string,
  int,
  double,
  bool,
  list,
}

class ParameterConfig {
  final String key;
  final ParameterType type;
  final dynamic defaultValue;
  final String description;

  const ParameterConfig(
    this.key,
    this.type,
    this.defaultValue,
    this.description,
  );

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'type': type.name,
      'defaultValue': defaultValue,
      'description': description,
    };
  }

  factory ParameterConfig.fromMap(Map<String, dynamic> map) {
    return ParameterConfig(
      map['key'] as String,
      ParameterType.values.firstWhere((e) => e.name == map['type']),
      map['defaultValue'],
      map['description'] as String,
    );
  }
}

class ComponentConfig {
  final String name;
  final String version;
  final String description;
  final List<ParameterConfig> parameters;

  const ComponentConfig({
    required this.name,
    required this.version,
    required this.description,
    required this.parameters,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'version': version,
      'description': description,
      'parameters': parameters.map((p) => p.toMap()).toList(),
    };
  }

  factory ComponentConfig.fromMap(Map<String, dynamic> map) {
    return ComponentConfig(
      map['name'] as String,
      map['version'] as String,
      map['description'] as String,
      (map['parameters'] as List)
          .map((p) => ParameterConfig.fromMap(p as Map<String, dynamic>))
          .toList(),
    );
  }
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
  final String? componentName;
  final String? parameterKey;
  final dynamic oldValue;
  final dynamic newValue;
  final DateTime timestamp;

  const ConfigEvent({
    required this.type,
    this.componentName,
    this.parameterKey,
    this.oldValue,
    this.newValue,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  const ConfigEvent.initialized()
      : type = ConfigEventType.initialized,
        componentName = null,
        parameterKey = null,
        oldValue = null,
        newValue = null,
        timestamp = DateTime.now();

  const ConfigEvent.parameterChanged(String key, dynamic oldValue, dynamic newValue)
      : type = ConfigEventType.parameterChanged,
        componentName = null,
        parameterKey = key,
        oldValue = oldValue,
        newValue = newValue,
        timestamp = DateTime.now();

  const ConfigEvent.componentRegistered(String componentName)
      : type = ConfigEventType.componentRegistered,
        componentName = componentName,
        parameterKey = null,
        oldValue = null,
        newValue = null,
        timestamp = DateTime.now();

  const ConfigEvent.componentNotified(String componentName, String key, dynamic value)
      : type = ConfigEventType.componentNotified,
        componentName = componentName,
        parameterKey = key,
        oldValue = null,
        newValue = value,
        timestamp = DateTime.now();

  const ConfigEvent.componentParametersUpdated(String componentName)
      : type = ConfigEventType.componentParametersUpdated,
        componentName = componentName,
        parameterKey = null,
        oldValue = null,
        newValue = null,
        timestamp = DateTime.now();

  const ConfigEvent.configurationImported()
      : type = ConfigEventType.configurationImported,
        componentName = null,
        parameterKey = null,
        oldValue = null,
        newValue = null,
        timestamp = DateTime.now();

  const ConfigEvent.resetToDefaults()
      : type = ConfigEventType.resetToDefaults,
        componentName = null,
        parameterKey = null,
        oldValue = null,
        newValue = null,
        timestamp = DateTime.now();
}
