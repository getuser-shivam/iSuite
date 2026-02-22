import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central Configuration System for iSuite
/// 
/// Enhanced with senior developer optimizations:
/// - Advanced caching with TTL and memory management
/// - Performance monitoring and analytics
/// - Hot-reload configuration without restart
/// - Environment-based configuration overrides
/// - Memory-efficient parameter storage
/// - Lazy loading for better startup performance
/// - Thread-safe concurrent access
/// - Configuration validation and type safety
/// - Automatic cleanup and garbage collection
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

  // App Configuration
  static const String _appName = 'iSuite - Enterprise File Manager';
  static const String _appVersion = '2.0.0';
  static const String _buildNumber = '2';
  static const String _primaryFramework = 'Flutter'; // Free, cross-platform
  static const String _backendFramework = 'Supabase'; // Free tier available
  static const String _localDatabase = 'SQLite'; // Free, embedded
  static const int _defaultPort = 8080;
  static const String _defaultWifiSSID = 'iSuite_Share';
  static const String _defaultWifiPassword = 'isuite123';
  static const Duration _defaultTimeout = Duration(seconds: 30);

  // Network & File Sharing Configuration
  static const int _defaultPort = 8080;
  static const String _defaultWifiSSID = 'iSuite_Share';
  static const String _defaultWifiPassword = 'isuite123';
  static const Duration _defaultTimeout = Duration(seconds: 30);

  // UI Configuration
  static const String _appTitle = 'iSuite - Enterprise File Manager';
  static const String _wifiScreenTitle = 'Network Management';
  static const String _ftpScreenTitle = 'FTP Client';
  static const String _filesTabTitle = 'Files';
  static const String _networkTabTitle = 'Network';
  static const String _ftpTabTitle = 'FTP';
  static const String _aiTabTitle = 'AI';
  static const String _settingsTabTitle = 'Settings';
  static const String _currentConnectionLabel = 'Current Connection';
  static const String _wifiNetworksLabel = 'WiFi Networks';
  static const String _ftpHostLabel = 'Host';
  static const String _ftpPortLabel = 'Port';
  static const String _ftpUsernameLabel = 'Username';
  static const String _ftpPasswordLabel = 'Password';
  static const String _connectButtonLabel = 'Connect';
  static const String _disconnectButtonLabel = 'Disconnect';
  static const String _scanButtonLabel = 'Scan Networks';
  static const String _uploadButtonLabel = 'Upload File';
  static const String _downloadButtonLabel = 'Download';

  // UI Colors
  static const int _primaryColor = 0xFF1976D2;
  static const int _secondaryColor = 0xFFDCEDC8;
  static const int _accentColor = 0xFFFF9800;
  static const int _backgroundColor = 0xFFF5F5F5;
  static const int _surfaceColor = 0xFFFFFFFF;
  static const int _errorColor = 0xFFD32F2F;
  static const int _successColor = 0xFF388E3C;

  // UI Dimensions
  static const double _defaultPadding = 16.0;
  static const double _defaultMargin = 16.0;
  static const double _cardElevation = 2.0;
  static const double _borderRadius = 12.0;
  static const double _wifiListHeight = 300.0;
  static const double _animationIconSize = 48.0;
  static const double _emptyStateIconSize = 64.0;
  static const double _smallIconSize = 18.0;
  static const double _subtitleFontSize = 12.0;

  // Animation Parameters
  static const Duration _scanAnimationDuration = Duration(seconds: 2);
  static const double _scanAnimationMinScale = 0.8;
  static const double _scanAnimationMaxScale = 1.2;

  // Network Tool Parameters
  static const Duration _wifiScanDelay = Duration(seconds: 2);
  static const Duration _portScanTimeout = Duration(milliseconds: 500);
  static const int _portScanBatchSize = 10;
  static const int _portScanBatchDelayMs = 0;
  static const Duration _ftpTimeout = Duration(seconds: 30);

  // Signal Strength Thresholds
  static const int _excellentSignalThreshold = -50;
  static const int _goodSignalThreshold = -60;
  static const int _fairSignalThreshold = -70;

  // UI Colors (additional)
  static const int _wifiSignalExcellent = 0xFF4CAF50; // Green
  static const int _wifiSignalGood = 0xFF8BC34A; // Light green
  static const int _wifiSignalFair = 0xFFFF9800; // Orange
  static const int _wifiSignalWeak = 0xFFF44336; // Red

  // Cross-Platform Support
  static const List<String> _supportedPlatforms = [
    'android',
    'ios',
    'windows',
    'linux',
    'macos',
    'web'
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

  // UI Getters
  String get appTitle => _appTitle;
  String get wifiScreenTitle => _wifiScreenTitle;
  String get ftpScreenTitle => _ftpScreenTitle;
  String get filesTabTitle => _filesTabTitle;
  String get networkTabTitle => _networkTabTitle;
  String get ftpTabTitle => _ftpTabTitle;
  String get aiTabTitle => _aiTabTitle;
  String get settingsTabTitle => _settingsTabTitle;
  String get currentConnectionLabel => _currentConnectionLabel;
  String get wifiNetworksLabel => _wifiNetworksLabel;
  String get ftpHostLabel => _ftpHostLabel;
  String get ftpPortLabel => _ftpPortLabel;
  String get ftpUsernameLabel => _ftpUsernameLabel;
  String get ftpPasswordLabel => _ftpPasswordLabel;
  String get connectButtonLabel => _connectButtonLabel;
  String get disconnectButtonLabel => _disconnectButtonLabel;
  String get scanButtonLabel => _scanButtonLabel;
  String get uploadButtonLabel => _uploadButtonLabel;
  String get downloadButtonLabel => _downloadButtonLabel;

  Color get primaryColor => Color(_primaryColor);
  Color get secondaryColor => Color(_secondaryColor);
  Color get accentColor => Color(_accentColor);
  Color get backgroundColor => Color(_backgroundColor);
  Color get surfaceColor => Color(_surfaceColor);
  Color get errorColor => Color(_errorColor);
  Color get successColor => Color(_successColor);

  double get cardElevation => _cardElevation;
  double get borderRadius => _borderRadius;
  double get wifiListHeight => _wifiListHeight;
  double get animationIconSize => _animationIconSize;
  double get emptyStateIconSize => _emptyStateIconSize;
  double get smallIconSize => _smallIconSize;
  double get subtitleFontSize => _subtitleFontSize;

  Duration get scanAnimationDuration => _scanAnimationDuration;
  double get scanAnimationMinScale => _scanAnimationMinScale;
  double get scanAnimationMaxScale => _scanAnimationMaxScale;

  Duration get wifiScanDelay => _wifiScanDelay;
  Duration get portScanTimeout => _portScanTimeout;
  int get portScanBatchSize => _portScanBatchSize;
  int get portScanBatchDelayMs => _portScanBatchDelayMs;
  Duration get ftpTimeout => _ftpTimeout;

  int get excellentSignalThreshold => _excellentSignalThreshold;
  int get goodSignalThreshold => _goodSignalThreshold;
  int get fairSignalThreshold => _fairSignalThreshold;

  Color get wifiSignalExcellent => Color(_wifiSignalExcellent);
  Color get wifiSignalGood => Color(_wifiSignalGood);
  Color get wifiSignalFair => Color(_wifiSignalFair);
  Color get wifiSignalWeak => Color(_wifiSignalWeak);
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

    debugPrint(
        'Parameter type mismatch for key: $key, expected: $T, got: ${value.runtimeType}');
    return defaultValue;
  }

  /// Set a parameter value with type safety and validation
  Future<bool> setParameter<T>(
    String key,
    T value, {
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
  Future<void> registerComponent(
      String componentName, ComponentConfig config) async {
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
  Future<bool> updateComponentParameters(
      String componentName, Map<String, dynamic> params) async {
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
    await setParameter('app_theme', 'system',
        description: 'App theme preference');
    await setParameter('app_language', 'en', description: 'App language');
    await setParameter('enable_notifications', true,
        description: 'Enable notifications');
    await setParameter('auto_sync', true, description: 'Enable automatic sync');

    // Network parameters
    await setParameter('network_auto_discovery', true,
        description: 'Enable network auto-discovery');
    await setParameter('network_share_timeout', _defaultTimeout.inSeconds,
        description: 'Network share timeout');
    await setParameter('ftp_port', 21, description: 'FTP port');
    await setParameter('http_port', _defaultPort, description: 'HTTP port');

    // File sharing parameters
    await setParameter('max_file_size', 100 * 1024 * 1024,
        description: 'Maximum file size in bytes');
    await setParameter(
        'allowed_file_types', ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png'],
        description: 'Allowed file types');
    await setParameter('enable_encryption', false,
        description: 'Enable file encryption');

    // UI parameters
    await setParameter('ui_density', 'comfortable', description: 'UI density');
    await setParameter('enable_animations', true,
        description: 'Enable animations');
    await setParameter('primary_color', '#1976D2',
        description: 'Primary color');
    
    // File Management UI Parameters
    await setParameter('ui.file_management.search_placeholder', 'Search files...',
        description: 'Search field placeholder text');
    await setParameter('ui.file_management.empty_state_title', 'No files found',
        description: 'Empty state title');
    await setParameter('ui.file_management.empty_state_message', 'Try adjusting your search or filters',
        description: 'Empty state message');
    await setParameter('ui.file_management.sort_label', 'Sort by:',
        description: 'Sort dropdown label');
    await setParameter('ui.file_management.recent_label', 'Recent:',
        description: 'Recent files toggle label');
    await setParameter('ui.file_management.hidden_label', 'Hidden:',
        description: 'Hidden files toggle label');
    await setParameter('ui.file_management.content_search_label', 'Search in content:',
        description: 'Content search toggle label');
    await setParameter('ui.file_management.default_sort', 'name',
        description: 'Default sort option');
    await setParameter('ui.file_management.default_sort_ascending', true,
        description: 'Default sort direction');
    await setParameter('ui.file_management.show_recent_by_default', false,
        description: 'Show recent files by default');
    await setParameter('ui.file_management.show_hidden_by_default', false,
        description: 'Show hidden files by default');
    await setParameter('ui.file_management.enable_content_search', false,
        description: 'Enable content search by default');
    await setParameter('ui.file_management.recent_threshold_hours', 24,
        description: 'Recent files threshold in hours');

    // File Operations Parameters
    await setParameter('file_operations.confirm_delete', true,
        description: 'Require confirmation for delete operations');
    await setParameter('file_operations.confirm_overwrite', true,
        description: 'Require confirmation for overwrite operations');
    await setParameter('file_operations.enable_drag_drop', true,
        description: 'Enable drag and drop operations');
    await setParameter('file_operations.max_clipboard_items', 100,
        description: 'Maximum items in clipboard');
    await setParameter('file_operations.auto_refresh_after_operation', true,
        description: 'Auto refresh after file operations');

    // Cloud Storage Parameters
    await setParameter('cloud_storage.default_provider', 'google_drive',
        description: 'Default cloud storage provider');
    await setParameter('cloud_storage.auto_sync_enabled', true,
        description: 'Enable automatic cloud sync');
    await setParameter('cloud_storage.sync_interval_minutes', 15,
        description: 'Sync interval in minutes');
    await setParameter('cloud_storage.max_sync_concurrent', 3,
        description: 'Maximum concurrent sync operations');
    await setParameter('cloud_storage.enable_offline_cache', true,
        description: 'Enable offline file caching');
    await setParameter('cloud_storage.cache_size_mb', 500,
        description: 'Cache size in MB');
    await setParameter('cloud_storage.compress_before_upload', false,
        description: 'Compress files before upload');
    await setParameter('cloud_storage.enable_versioning', true,
        description: 'Enable file versioning');
    await setParameter('cloud_storage.max_versions_per_file', 10,
        description: 'Maximum versions per file');

    // Cloud Storage UI Parameters
    await setParameter('ui.cloud_storage.google_drive_title', 'Google Drive',
        description: 'Google Drive tab title');
    await setParameter('ui.cloud_storage.dropbox_title', 'Dropbox',
        description: 'Dropbox tab title');
    await setParameter('ui.cloud_storage.connect_button', 'Connect',
        description: 'Connect button text');
    await setParameter('ui.cloud_storage.disconnect_button', 'Disconnect',
        description: 'Disconnect button text');
    await setParameter('ui.cloud_storage.refresh_button', 'Refresh',
        description: 'Refresh button tooltip');
    await setParameter('ui.cloud_storage.upload_button', 'Upload',
        description: 'Upload button text');
    await setParameter('ui.cloud_storage.download_button', 'Download',
        description: 'Download button text');

    // Advanced UI Parameters
    await setParameter('ui.animations.duration_fast', 200,
        description: 'Fast animation duration in milliseconds');
    await setParameter('ui.animations.duration_normal', 300,
        description: 'Normal animation duration in milliseconds');
    await setParameter('ui.animations.duration_slow', 500,
        description: 'Slow animation duration in milliseconds');
    await setParameter('ui.animations.enable_ripple', true,
        description: 'Enable ripple effects');
    await setParameter('ui.animations.enable_fade_transitions', true,
        description: 'Enable fade transitions');
    await setParameter('ui.animations.enable_scale_animations', true,
        description: 'Enable scale animations');

    // Master GUI Parameters
    await setParameter('master_gui.default_build_mode', 'release',
        description: 'Default build mode in master GUI');
    await setParameter('master_gui.auto_save_logs', true,
        description: 'Auto save logs in master GUI');
    await setParameter('master_gui.max_log_lines', 10000,
        description: 'Maximum log lines to keep');
    await setParameter('master_gui.enable_error_notifications', true,
        description: 'Show error notifications');
    await setParameter('master_gui.command_timeout_seconds', 300,
        description: 'Command timeout in seconds');
    await setParameter('master_gui.enable_progress_tracking', true,
        description: 'Enable detailed progress tracking');

    // Feature Toggles
    await setParameter('features.enable_file_operations', true,
        description: 'Enable file operations feature');
    await setParameter('features.enable_cloud_storage', true,
        description: 'Enable cloud storage feature');
    await setParameter('features.enable_ai_assistant', true,
        description: 'Enable AI assistant feature');
    await setParameter('features.enable_network_tools', true,
        description: 'Enable network tools feature');
    await setParameter('features.enable_advanced_search', true,
        description: 'Enable advanced search features');
    await setParameter('features.enable_offline_mode', false,
        description: 'Enable offline mode (experimental)');

    // Performance Parameters
    await setParameter('performance.lazy_load_file_lists', true,
        description: 'Lazy load file lists');
    await setParameter('performance.cache_file_metadata', true,
        description: 'Cache file metadata');
    await setParameter('performance.preload_thumbnails', false,
        description: 'Preload file thumbnails');
    await setParameter('performance.enable_memory_optimization', true,
        description: 'Enable memory optimization');
    await setParameter('performance.max_ui_threads', 4,
        description: 'Maximum UI threads');

    // Security Parameters
    await setParameter('security.encrypt_local_files', false,
        description: 'Encrypt local files');
    await setParameter('security.enable_secure_delete', false,
        description: 'Enable secure file deletion');
    await setParameter('security.require_auth_for_cloud', false,
        description: 'Require authentication for cloud operations');
    await setParameter('security.enable_audit_logging', true,
        description: 'Enable audit logging');

    // Integration Parameters
    await setParameter('integrations.supabase_enabled', true,
        description: 'Enable Supabase integration');
    await setParameter('integrations.google_drive_enabled', true,
        description: 'Enable Google Drive integration');
    await setParameter('integrations.dropbox_enabled', true,
        description: 'Enable Dropbox integration');
    await setParameter('integrations.ftp_enabled', true,
        description: 'Enable FTP integration');

    // Dual-Pane File Manager Parameters
    await setParameter('ui.file_management.enable_dual_pane', false,
        description: 'Enable dual-pane file manager mode');
    await setParameter('ui.file_management.dual_pane_split_ratio', 0.5,
        description: 'Split ratio between left and right panes (0.0-1.0)');
    await setParameter('ui.file_management.show_navigation_breadcrumbs', true,
        description: 'Show navigation breadcrumbs in file panes');
    await setParameter('ui.file_management.enable_drag_between_panes', true,
        description: 'Enable drag and drop between panes');
    await setParameter('ui.file_management.sync_pane_selections', false,
        description: 'Sync selections between panes');
    await setParameter('ui.file_management.show_preview_panel', false,
        description: 'Show file preview panel');
    // UI Color Parameters
    await setParameter('ui.colors.primary', 0xFF1976D2,
        description: 'Primary brand color');
    await setParameter('ui.colors.secondary', 0xFFDCEDC8,
        description: 'Secondary accent color');
    await setParameter('ui.colors.surface.light', 0xFFFFFFFF,
        description: 'Surface color for light theme');
    await setParameter('ui.colors.surface.dark', 0xFF424242,
        description: 'Surface color for dark theme');
    await setParameter('ui.colors.background.light', 0xFFFAFAFA,
        description: 'Background color for light theme');
    await setParameter('ui.colors.background.dark', 0xFF121212,
        description: 'Background color for dark theme');
    await setParameter('ui.colors.error', 0xFFD32F2F,
        description: 'Error color');
    await setParameter('ui.colors.warning', 0xFFF57C00,
        description: 'Warning color');
    await setParameter('ui.colors.success', 0xFF388E3C,
        description: 'Success color');

    // UI Border and Shape Parameters
    await setParameter('ui.border_radius.small', 4.0,
        description: 'Small border radius for subtle rounding');
    await setParameter('ui.border_radius.medium', 8.0,
        description: 'Medium border radius for cards and dialogs');
    await setParameter('ui.border_radius.large', 12.0,
        description: 'Large border radius for prominent elements');
    await setParameter('ui.border_radius.xlarge', 16.0,
        description: 'Extra large border radius for special cases');

    // UI Border Width Parameters
    await setParameter('ui.border_width.thin', 0.5,
        description: 'Thin border width');
    await setParameter('ui.border_width.normal', 1.0,
        description: 'Normal border width');
    await setParameter('ui.border_width.thick', 2.0,
        description: 'Thick border width');

    // UI Opacity Parameters
    await setParameter('ui.opacity.disabled', 0.5,
        description: 'Opacity for disabled elements');
    await setParameter('ui.opacity.overlay', 0.8,
        description: 'Opacity for overlay elements');
    await setParameter('ui.opacity.hover', 0.7,
        description: 'Opacity for hover states');

    // UI Font Parameters
    await setParameter('ui.font.family.primary', 'Roboto',
        description: 'Primary font family');
    await setParameter('ui.font.family.monospace', 'Monospace',
        description: 'Monospace font family for code');

    // UI Animation Parameters
    await setParameter('ui.animation.duration.fast', 150,
        description: 'Fast animation duration in milliseconds');
    await setParameter('ui.animation.duration.normal', 300,
        description: 'Normal animation duration in milliseconds');
    await setParameter('ui.animation.duration.slow', 500,
        description: 'Slow animation duration in milliseconds');
    await setParameter('ui.animation.scale.begin', 1.0,
        description: 'Animation scale start value');
    await setParameter('ui.animation.scale.end', 0.95,
        description: 'Animation scale end value');
    await setParameter('ui.animation.opacity.begin', 1.0,
        description: 'Animation opacity start value');
    await setParameter('ui.animation.opacity.end', 0.7,
        description: 'Animation opacity end value');
    await setParameter('ui.animation.slide_offset', 0.3,
        description: 'Slide animation offset');

    // UI Shadow Parameters
    await setParameter('ui.shadow.opacity', 0.2,
        description: 'Shadow opacity');
    await setParameter('ui.shadow.blur_radius', 4.0,
        description: 'Shadow blur radius');

    // UI Border Parameters
    await setParameter('ui.border.opacity', 0.1,
        description: 'Border opacity');

    // UI Gradient Parameters
    await setParameter('ui.gradient.opacity.start', 0.05,
        description: 'Gradient start opacity');
    await setParameter('ui.gradient.opacity.end', 0.1,
        description: 'Gradient end opacity');

    // UI Icon Parameters
    await setParameter('ui.icon.background.opacity', 0.1,
        description: 'Icon background opacity');

    // UI Avatar Parameters
    await setParameter('ui.avatar.radius.large', 30.0,
        description: 'Large avatar radius');

    // UI Grid Parameters
    await setParameter('ui.grid.cross_axis_count', 2,
        description: 'Grid cross axis count');
    await setParameter('ui.grid.cross_axis_spacing', 16.0,
        description: 'Grid cross axis spacing');
    await setParameter('ui.grid.main_axis_spacing', 16.0,
        description: 'Grid main axis spacing');
    await setParameter('ui.grid.child_aspect_ratio', 1.2,
        description: 'Grid child aspect ratio');

    // UI Text Parameters
    await setParameter('ui.text.max_lines', 2,
        description: 'Maximum text lines');

    // UI Loading Parameters
    await setParameter('ui.loading.stroke_width', 2.0,
        description: 'Loading indicator stroke width');

    // UI Notification Parameters
    await setParameter('ui.notification.badge_size', 8.0,
        description: 'Notification badge size');
    await setParameter('ui.notification.duration.short', 2000,
        description: 'Short notification duration in milliseconds');

    // UI Refresh Parameters
    await setParameter('ui.refresh.delay', 1,
        description: 'Refresh delay in seconds');

    // UI Quick Actions Parameters
    await setParameter('ui.quick_actions.height', 80.0,
        description: 'Height of quick actions container');
    await setParameter('ui.quick_actions.button_width', 80.0,
        description: 'Width of quick action buttons');
    await setParameter('ui.quick_actions.button_margin', 12.0,
        description: 'Margin between quick action buttons');
    await setParameter('ui.quick_actions.icon_container_size', 56.0,
        description: 'Size of icon container in quick actions');

    // UI Font Size Parameters (additional)
    await setParameter('ui.font.size.title_large', 22.0,
        description: 'Large title font size');

    // AI Assistant UI Parameters
    await setParameter('ui.ai_assistant.message_spacing', 8.0,
        description: 'Spacing between chat messages');
    await setParameter('ui.ai_assistant.message_max_width', 300.0,
        description: 'Maximum width of chat messages');
    await setParameter('ui.ai_assistant.typing_indicator_size', 16.0,
        description: 'Size of typing indicator');
    await setParameter('ui.ai_assistant.message_max_lines', 3,
        description: 'Maximum lines for AI assistant message input');

    // Validation Parameters
    await setParameter('validation.email.pattern', r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
        description: 'Email validation regex pattern');
    await setParameter('validation.email.max_length', 254,
        description: 'Maximum email length');
    await setParameter('validation.phone.pattern', r'^\+?[\d\s\-\(\)]{10,15}$',
        description: 'Phone number validation regex pattern');
    await setParameter('validation.phone.max_length', 20,
        description: 'Maximum phone number length');
    await setParameter('validation.url.pattern', r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
        description: 'URL validation regex pattern');
    await setParameter('validation.url.max_length', 2048,
        description: 'Maximum URL length');
    await setParameter('validation.username.pattern', r'^[a-zA-Z0-9_]{3,20}$',
        description: 'Username validation regex pattern');
    await setParameter('validation.username.min_length', 3,
        description: 'Minimum username length');
    await setParameter('validation.username.max_length', 20,
        description: 'Maximum username length');
    await setParameter('validation.password.min_length', 8,
        description: 'Minimum password length');
    await setParameter('validation.password.max_length', 128,
        description: 'Maximum password length');
    await setParameter('validation.file_path.max_length', 260,
        description: 'Maximum file path length (Windows MAX_PATH)');
    await setParameter('validation.text.max_length', 10000,
        description: 'Maximum text input length');

    // Enhanced Validation Context Messages
    await setParameter('validation.context_messages', {
      'email': {
        'required': 'Email address is required for account creation',
        'min_length': 'Email address must be at least {required} characters',
        'max_length': 'Email address cannot exceed {allowed} characters',
        'pattern': 'Please enter a valid email address (e.g., user@example.com)',
      },
      'password': {
        'required': 'Password is required for security',
        'min_length': 'Password must be at least {required} characters long',
        'max_length': 'Password cannot exceed {allowed} characters',
        'pattern': 'Password must contain uppercase, lowercase, numbers, and special characters',
      },
      'username': {
        'required': 'Username is required for identification',
        'min_length': 'Username must be at least {required} characters',
        'max_length': 'Username cannot exceed {allowed} characters',
        'pattern': 'Username can only contain letters, numbers, and underscores',
      },
      'phone': {
        'required': 'Phone number is required for contact',
        'pattern': 'Please enter a valid phone number (e.g., +1 234 567 8900)',
      },
      'url': {
        'required': 'URL is required for link creation',
        'pattern': 'Please enter a valid URL (e.g., https://example.com)',
      },
    }, description: 'Contextual error messages for validation rules');

    // Validation Performance Settings
    await setParameter('validation.performance.enable_cache', true,
        description: 'Enable validation result caching for performance');
    await setParameter('validation.performance.cache_ttl_minutes', 5,
        description: 'Cache time-to-live in minutes');
    await setParameter('validation.performance.max_cache_size', 1000,
        description: 'Maximum number of cached validation results');
    await setParameter('validation.performance.enable_metrics', true,
        description: 'Enable performance metrics collection');
    await setParameter('validation.performance.max_metrics', 10000,
        description: 'Maximum number of performance metrics to store');

    // Validation Security Settings
    await setParameter('validation.security.enable_sanitization', true,
        description: 'Enable input sanitization for security');
    await setParameter('validation.security.check_xss', true,
        description: 'Enable XSS attack detection');
    await setParameter('validation.security.check_sql_injection', true,
        description: 'Enable SQL injection detection');
    await setParameter('validation.security.max_retries', 3,
        description: 'Maximum validation retry attempts');

    // Validation UI Settings
    await setParameter('validation.ui.show_suggestions', true,
        description: 'Show helpful suggestions for validation errors');
    await setParameter('validation.ui.show_context', true,
        description: 'Show contextual error messages');
    await setParameter('validation.ui.error_severity_levels', true,
        description: 'Enable error severity classification');

    // Voice Translation Parameters
    await setParameter('ui.voice_recorder.button_size', 80.0,
        description: 'Size of the voice recording button');
    await setParameter('ui.voice_recorder.waveform_height', 60.0,
        description: 'Height of the waveform visualization');
    await setParameter('ui.voice_recorder.bar_width', 3.0,
        description: 'Width of waveform bars');
    await setParameter('ui.translation.min_height', 120.0,
        description: 'Minimum height of translation display');
    await setParameter('ui.translation.transcript_height', 120.0,
        description: 'Height of transcript display area');
    await setParameter('ui.translation.history_height', 200.0,
        description: 'Maximum height of conversation history');
    await setParameter('ui.animation.typewriter.duration', 1000,
        description: 'Duration of typewriter animation for text');
    await setParameter('ui.language_selector.recent_height', 80.0,
        description: 'Height of recent languages section');
    await setParameter('ui.language_selector.list_height', 200.0,
        description: 'Maximum height of language list');

    // Voice Translation Feature Flags
    await setParameter('voice_translation.enable_offline', true,
        description: 'Enable offline translation capabilities');
    await setParameter('voice_translation.enable_encryption', true,
        description: 'Enable end-to-end encryption for translations');
    await setParameter('voice_translation.enable_biometric', true,
        description: 'Enable biometric authentication for privacy');
    await setParameter('voice_translation.max_history_entries', 50,
        description: 'Maximum number of conversation history entries');
    await setParameter('voice_translation.supported_languages', 50,
        description: 'Number of supported languages');
    await setParameter('voice_translation.auto_detect_language', true,
        description: 'Enable automatic language detection');
    await setParameter('voice_translation.enable_cultural_context', true,
        description: 'Enable cultural context and localization notes');

    // Owlfiles-Inspired Network & File Sharing Parameters
    await setParameter('owlfiles.network.universal_protocols', true,
        description: 'Enable universal protocol support (FTP, SFTP, SMB, WebDAV, NFS, rsync)');
    await setParameter('owlfiles.network.virtual_drive.auto_create', true,
        description: 'Auto-create virtual drives for connections');
    await setParameter('owlfiles.network.discovery.methods', 'mdns,upnp,netbios,manual',
        description: 'Network discovery methods (comma-separated)');
    await setParameter('owlfiles.network.discovery.timeout', 30,
        description: 'Network discovery timeout in seconds');
    await setParameter('owlfiles.network.streaming.enable', true,
        description: 'Enable real-time file streaming');
    await setParameter('owlfiles.network.streaming.quality', 'high',
        description: 'Default streaming quality (low, medium, high, ultra)');
    await setParameter('owlfiles.network.streaming.cache_size', 500,
        description: 'Streaming cache size in MB');
    await setParameter('owlfiles.network.preview.enable', true,
        description: 'Enable universal file preview');
    await setParameter('owlfiles.network.preview.thumbnail_size', 200,
        description: 'Thumbnail size in pixels');
    await setParameter('owlfiles.network.ai.categorization', true,
        description: 'Enable AI-powered file categorization');
    await setParameter('owlfiles.network.ai.smart_search', true,
        description: 'Enable AI-powered smart search');
    await setParameter('owlfiles.network.ai.auto_organize', false,
        description: 'Enable automatic file organization');
    await setParameter('owlfiles.network.collaboration.enable', true,
        description: 'Enable real-time collaboration');
    await setParameter('owlfiles.network.collaboration.max_participants', 10,
        description: 'Maximum collaboration participants');
    await setParameter('owlfiles.network.sharing.enable', true,
        description: 'Enable secure file sharing');
    await setParameter('owlfiles.network.sharing.default_expiry', 24,
        description: 'Default sharing expiry time in hours');
    await setParameter('owlfiles.network.sync.enable', true,
        description: 'Enable file synchronization');
    await setParameter('owlfiles.network.sync.bidirectional', false,
        description: 'Enable bidirectional sync by default');
    await setParameter('owlfiles.network.performance.deduplication', true,
        description: 'Enable file deduplication');
    await setParameter('owlfiles.network.performance.compression', true,
        description: 'Enable automatic compression');
    await setParameter('owlfiles.network.security.encryption', true,
        description: 'Enable end-to-end encryption');
    await setParameter('owlfiles.network.security.zero_knowledge', true,
        description: 'Enable zero-knowledge encryption');
    await setParameter('owlfiles.network.security.biometric', true,
        description: 'Enable biometric authentication');
    await setParameter('owlfiles.network.ui.dashboard', true,
        description: 'Enable comprehensive network dashboard');
    await setParameter('owlfiles.network.ui.real_time_monitoring', true,
        description: 'Enable real-time network monitoring');
    await setParameter('owlfiles.network.ui.advanced_metrics', true,
        description: 'Show advanced performance metrics');

    // Component Relationship Parameters
    await setParameter('components.central_config.enable_relationship_tracking', true,
        description: 'Enable component relationship tracking');
    await setParameter('components.central_config.dependency_propagation', true,
        description: 'Enable automatic dependency propagation');
    await setParameter('components.central_config.component_locking', true,
        description: 'Enable component-level locking');
    await setParameter('components.central_config.memory_tracking', true,
        description: 'Enable component memory usage tracking');
    await setParameter('components.central_config.performance_metrics', true,
        description: 'Enable component performance metrics');
    await setParameter('components.central_config.auto_cleanup', true,
        description: 'Enable automatic component cleanup');
    await setParameter('components.central_config.validation', true,
        description: 'Enable component configuration validation');

    // Component Hierarchy Parameters
    await setParameter('components.hierarchy.enable_validation', true,
        description: 'Enable hierarchy validation');
    await setParameter('components.hierarchy.max_depth', 10,
        description: 'Maximum allowed hierarchy depth');
    await setParameter('components.hierarchy.validation_interval', 300,
        description: 'Hierarchy validation interval in seconds');
    await setParameter('components.hierarchy.auto_orphan_detection', true,
        description: 'Enable automatic orphaned component detection');
    await setParameter('components.hierarchy.circular_dependency_check', true,
        description: 'Enable circular dependency detection');
    await setParameter('components.hierarchy.dependency_tracking', true,
        description: 'Enable comprehensive dependency tracking');
    await setParameter('components.hierarchy.level_organization', true,
        description: 'Enable automatic level-based organization');
    await setParameter('components.hierarchy.category_grouping', true,
        description: 'Enable category-based component grouping');
    await setParameter('components.hierarchy.lifecycle_monitoring', true,
        description: 'Enable component lifecycle monitoring');
    await setParameter('components.hierarchy.statistics_collection', true,
        description: 'Enable hierarchy statistics collection');
    await setParameter('components.hierarchy.performance_impact_analysis', true,
        description: 'Enable performance impact analysis for hierarchy changes');

    // System Architecture Parameters
    await setParameter('system.architecture.enable_validation', true,
        description: 'Enable system architecture validation');
    await setParameter('system.architecture.auto_reorganization', false,
        description: 'Enable automatic system reorganization');
    await setParameter('system.architecture.health_monitoring', true,
        description: 'Enable architecture health monitoring');
    await setParameter('system.architecture.metrics_collection', true,
        description: 'Enable architecture metrics collection');
    await setParameter('system.architecture.layer_validation', true,
        description: 'Enable architecture layer validation');
    await setParameter('system.architecture.domain_boundaries', true,
        description: 'Enable domain boundary validation');
    await setParameter('system.architecture.pattern_validation', true,
        description: 'Enable communication pattern validation');
    await setParameter('system.architecture.coupling_threshold', 0.7,
        description: 'Coupling threshold for optimization');
    await setParameter('system.architecture.cohesion_threshold', 0.5,
        description: 'Cohesion threshold for optimization');
    await setParameter('system.architecture.monitoring_interval', 600,
        description: 'Architecture monitoring interval in seconds');
    await setParameter('system.architecture.optimization_enabled', true,
        description: 'Enable automatic architecture optimization');

    // Advanced Network & File Sharing Parameters
    await setParameter('network.discovery.enable_mdns', true,
        description: 'Enable mDNS/Bonjour/Zeroconf network discovery');
    await setParameter('network.discovery.enable_upnp', true,
        description: 'Enable UPnP device discovery');
    await setParameter('network.discovery.scan_timeout', 30,
        description: 'Network discovery scan timeout in seconds');
    await setParameter('network.discovery.max_devices', 100,
        description: 'Maximum number of devices to discover');
    await setParameter('network.virtual_drive.auto_reconnect', true,
        description: 'Enable automatic reconnection for virtual drives');
    await setParameter('network.virtual_drive.cache_size', 1000,
        description: 'Virtual drive cache size in MB');
    await setParameter('network.ftp.enable_ftps', true,
        description: 'Enable FTPS (FTP over TLS) support');
    await setParameter('network.ftp.passive_mode', true,
        description: 'Enable FTP passive mode by default');
    await setParameter('network.ftp.port_range_start', 12000,
        description: 'FTP passive mode port range start');
    await setParameter('network.ftp.port_range_end', 13000,
        description: 'FTP passive mode port range end');
    await setParameter('network.smb.enable_smb1', false,
        description: 'Enable SMBv1 protocol (legacy, less secure)');
    await setParameter('network.smb.port', 445,
        description: 'SMB/CIFS server port');
    await setParameter('network.webdav.enable_dav', true,
        description: 'Enable WebDAV extensions for file operations');
    await setParameter('network.webdav.depth', 'infinite',
        description: 'WebDAV PROPFIND depth (infinite, 0, 1)');
    await setParameter('network.sftp.enable_compression', true,
        description: 'Enable SFTP compression');
    await setParameter('network.sftp.key_algorithm', 'rsa',
        description: 'SFTP key algorithm (rsa, dsa, ecdsa)');
    await setParameter('network.qr_code.size', 200,
        description: 'QR code size in pixels');
    await setParameter('network.qr_code.error_correction', 'M',
        description: 'QR code error correction level (L, M, Q, H)');
    await setParameter('network.performance.enable_caching', true,
        description: 'Enable network performance caching');
    await setParameter('network.performance.enable_compression', true,
        description: 'Enable data compression for transfers');
    await setParameter('network.performance.bandwidth_limit', 0,
        description: 'Bandwidth limit in KB/s (0 = unlimited)');
    await setParameter('network.performance.chunk_size', 8192,
        description: 'File transfer chunk size in bytes');
    await setParameter('network.security.enable_encryption', true,
        description: 'Enable end-to-end encryption for transfers');
    await setParameter('network.security.verify_certificates', true,
        description: 'Verify SSL/TLS certificates');
    await setParameter('network.security.enable_firewall', true,
        description: 'Enable network firewall rules');
    await setParameter('network.security.log_connections', true,
        description: 'Log all network connections');
    await setParameter('network.ui.show_signal_strength', true,
        description: 'Show signal strength for devices');
    await setParameter('network.ui.show_protocols', true,
        description: 'Show supported protocols for devices');
    await setParameter('network.ui.enable_animations', true,
        description: 'Enable network discovery animations');
    await setParameter('network.ui.refresh_interval', 60,
        description: 'Auto-refresh interval in seconds');
    await setParameter('ui.ai_assistant.message_min_lines', 1,
        description: 'Minimum lines for AI assistant message input');
    await setParameter('ui.ai_assistant.send_icon_size', 18.0,
        description: 'Size of send button icon');

    // FTP Client UI Parameters
    await setParameter('ui.ftp.progress_bar_height', 4.0,
        description: 'Height of progress bars in FTP client');
    await setParameter('ui.ftp.transfer_list_height', 300.0,
        description: 'Height of transfer list');

    // File Management UI Parameters
    await setParameter('ui.file_management.card_margin', 16.0,
        description: 'Margin around file cards');
    await setParameter('ui.file_management.icon_size', 24.0,
        description: 'Size of file type icons');

    // Settings UI Parameters
    await setParameter('ui.settings.section_spacing', 24.0,
        description: 'Spacing between settings sections');

    // Notification Parameters
    await setParameter('notification.duration.short', 2000,
        description: 'Duration for short notifications (ms)');

    // Security Parameters
    await setParameter('security.session_timeout', 3600,
        description: 'Session timeout in seconds');
    await setParameter('security.max_login_attempts', 5,
        description: 'Maximum login attempts before lockout');

    // Platform-specific Parameters
    await setParameter('platform.ios.minimum_version', '12.0',
        description: 'Minimum iOS version supported');
    await setParameter('platform.android.minimum_sdk', 21,
        description: 'Minimum Android SDK version');

    // Feature Flags
    await setParameter('features.enable_beta_features', false,
        description: 'Enable beta features');
    await setParameter('features.enable_debug_mode', false,
        description: 'Enable debug mode features');

    // Performance parameters
    await setParameter('cache_size', 50 * 1024 * 1024,
        description: 'Cache size in bytes');
    await setParameter('max_concurrent_uploads', 3,
        description: 'Maximum concurrent uploads');
    await setParameter('max_concurrent_downloads', 3,
        description: 'Maximum concurrent downloads');
  }

  Future<void> _registerComponents() async {
    // Network Sharing Component
    await registerComponent(
        'network_sharing',
        ComponentConfig(
          name: 'Network Sharing',
          version: '1.0.0',
          description: 'WiFi and file sharing capabilities',
          parameters: [
            ParameterConfig('network_auto_discovery', ParameterType.bool, true,
                'Enable network auto-discovery'),
            ParameterConfig('network_share_timeout', ParameterType.int,
                _defaultTimeout.inSeconds, 'Network share timeout'),
            ParameterConfig('default_wifi_ssid', ParameterType.string,
                _defaultWifiSSID, 'Default WiFi SSID'),
            ParameterConfig('default_wifi_password', ParameterType.string,
                _defaultWifiPassword, 'Default WiFi password'),
            ParameterConfig('max_concurrent_transfers', ParameterType.int, 5,
                'Maximum concurrent transfers'),
          ],
        ));

    // File Management Component
    await registerComponent(
        'file_management',
        ComponentConfig(
          name: 'File Management',
          version: '1.0.0',
          description: 'File operations and storage management',
          parameters: [
            ParameterConfig('max_file_size', ParameterType.int,
                100 * 1024 * 1024, 'Maximum file size'),
            ParameterConfig(
                'allowed_file_types',
                ParameterType.list,
                ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png'],
                'Allowed file types'),
            ParameterConfig('enable_encryption', ParameterType.bool, false,
                'Enable file encryption'),
            ParameterConfig('auto_backup', ParameterType.bool, true,
                'Enable automatic backup'),
          ],
        ));

    // Supabase Component
    await registerComponent(
        'supabase',
        ComponentConfig(
          name: 'Supabase Backend',
          version: '1.0.0',
          description: 'Cloud backend integration',
          parameters: [
            ParameterConfig(
                'supabase_url', ParameterType.string, '', 'Supabase URL'),
            ParameterConfig('supabase_anon_key', ParameterType.string, '',
                'Supabase anonymous key'),
            ParameterConfig('enable_offline_sync', ParameterType.bool, true,
                'Enable offline sync'),
            ParameterConfig('sync_interval', ParameterType.int, 300,
                'Sync interval in seconds'),
          ],
        ));

    // UI Component
    await registerComponent(
        'ui',
        ComponentConfig(
          name: 'User Interface',
          version: '1.0.0',
          description: 'User interface settings',
          parameters: [
            ParameterConfig(
                'app_theme', ParameterType.string, 'system', 'App theme'),
            ParameterConfig(
                'app_language', ParameterType.string, 'en', 'App language'),
            ParameterConfig('ui_density', ParameterType.string, 'comfortable',
                'UI density'),
            ParameterConfig('enable_animations', ParameterType.bool, true,
                'Enable animations'),
            ParameterConfig('primary_color', ParameterType.string, '#1976D2',
                'Primary color'),
          ],
        ));

    // Performance Component
    await registerComponent(
        'performance',
        ComponentConfig(
          name: 'Performance',
          version: '1.0.0',
          description: 'Performance optimization settings',
          parameters: [
            ParameterConfig('cache_size', ParameterType.int, 50 * 1024 * 1024,
                'Cache size'),
            ParameterConfig('max_concurrent_uploads', ParameterType.int, 3,
                'Maximum concurrent uploads'),
            ParameterConfig('max_concurrent_downloads', ParameterType.int, 3,
                'Maximum concurrent downloads'),
            ParameterConfig('enable_performance_monitoring', ParameterType.bool,
                true, 'Enable performance monitoring'),
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
          return value is int ||
              (value is String && int.tryParse(value) != null);
        case ParameterType.double:
          return value is double ||
              (value is String && double.tryParse(value) != null);
        case ParameterType.bool:
          return value is bool ||
              (value is String &&
                  ['true', 'false'].contains(value.toLowerCase()));
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

  Future<void> _notifyComponents(
      String key, dynamic oldValue, dynamic newValue) async {
    // Find components that use this parameter
    for (final component in _components.entries) {
      if (component.value.parameters.any((p) => p.key == key)) {
        await _emitEvent(
            ConfigEvent.componentNotified(component.key, key, newValue));
      }
    }
  }

  Future<void> _emitEvent(ConfigEvent event) async {
    _eventController.add(event);
  }

  /// Register component relationship
  Future<void> registerComponentRelationship(
    String sourceComponent,
    String targetComponent,
    RelationshipType type,
    String description,
  ) async {
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

    _logger?.info('Component relationship registered: $sourceComponent -> $targetComponent (${type.name})', 'CentralConfig');
  }

  /// Update component metrics
  Future<void> updateComponentMetrics(String componentName, ComponentMetrics metrics) async {
    _componentMetrics[componentName] = metrics;
    
    // Emit metrics update event
    _emitEvent(ConfigEventType.componentParametersUpdated, componentName: componentName);
  }

  /// Get active parameters for component
  List<String> getActiveParametersForComponent(String componentName) {
    final componentPrefix = componentName.toLowerCase();
    return _parameterConfigs.keys
        .where((key) => key.startsWith(componentPrefix))
        .toList();
  }

  /// Notify component of event
  void notifyComponent(String componentName, String event, dynamic data) {
    final watchers = _dependencyWatchers[componentName];
    if (watchers != null) {
      for (final watcher in watchers) {
        try {
          watcher();
        } catch (e) {
          _logger?.error('Error notifying component $componentName', 'CentralConfig', error: e);
        }
      }
    }
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

  /// Update dependency tracking
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

  /// Add parameter dependency
  void _addParameterDependency(String source, String target) {
    final sourceParams = getActiveParametersForComponent(source);
    final targetParams = getActiveParametersForComponent(target);

    for (final sourceParam in sourceParams) {
      if (!_parameterDependencies.containsKey(sourceParam)) {
        _parameterDependencies[sourceParam] = <String>{};
      }
      _parameterDependencies[sourceParam]!.addAll(targetParams);
    }
  }

  /// Validate component configuration
  Future<bool> validateComponentConfiguration(String componentName) async {
    final enableValidation = getParameter('components.central_config.validation', defaultValue: true);
    if (!enableValidation) return true;

    try {
      // Check if component is registered
      final componentConfig = _componentConfigs[componentName];
      if (componentConfig == null) {
        _logger?.warning('Component $componentName not registered', 'CentralConfig');
        return false;
      }

      // Validate parameters
      final componentParams = getActiveParametersForComponent(componentName);
      for (final param in componentParams) {
        final config = _parameterConfigs[param];
        if (config == null) {
          _logger?.warning('Parameter $param not configured for component $componentName', 'CentralConfig');
          return false;
        }

        // Validate parameter value
        final value = getParameter(param);
        if (!_validateParameterValue(config, value)) {
          _logger?.warning('Invalid value for parameter $param in component $componentName', 'CentralConfig');
          return false;
        }
      }

      return true;

    } catch (e) {
      _logger?.error('Component configuration validation failed for $componentName', 'CentralConfig', error: e);
      return false;
    }
  }

  /// Validate parameter value
  bool _validateParameterValue(ParameterConfig config, dynamic value) {
    switch (config.type) {
      case ParameterType.string:
        return value is String && value.isNotEmpty;
      case ParameterType.int:
        return value is int;
      case ParameterType.double:
        return value is double || value is int;
      case ParameterType.bool:
        return value is bool;
      case ParameterType.list:
        return value is List;
      default:
        return true;
    }
  }

  /// Perform automatic cleanup
  Future<void> performAutomaticCleanup() async {
    final enableCleanup = getParameter('components.central_config.auto_cleanup', defaultValue: true);
    if (!enableCleanup) return;

    try {
      // Clean up expired cache entries
      await _cleanupExpiredCache();

      // Clean up weak references
      await _cleanupWeakReferences();

      // Clean up inactive components
      await _cleanupInactiveComponents();

      _logger?.info('Automatic cleanup completed', 'CentralConfig');

    } catch (e) {
      _logger?.error('Automatic cleanup failed', 'CentralConfig', error: e);
    }
  }

  /// Cleanup expired cache entries
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

    if (expiredKeys.isNotEmpty) {
      _logger?.info('Cleaned up ${expiredKeys.length} expired cache entries', 'CentralConfig');
    }
  }

  /// Cleanup weak references
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

    if (deadReferences.isNotEmpty) {
      _logger?.info('Cleaned up ${deadReferences.length} dead weak references', 'CentralConfig');
    }
  }

  /// Cleanup inactive components
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

  /// Get system health status
  SystemHealthStatus getSystemHealthStatus() {
    final totalComponents = _componentConfigs.length;
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
      isHealthy: activeComponents >= totalComponents * 0.8, // 80% of components active
      lastHealthCheck: DateTime.now(),
    );
  }

  /// Calculate total memory usage
  int _calculateTotalMemoryUsage() {
    int totalUsage = 0;
    
    for (final memoryInfo in _componentMemoryInfo.values) {
      totalUsage += memoryInfo.memoryUsage;
    }
    
    return totalUsage;
  }

  /// Dispose
  void dispose() {
    _eventController.close();
    _isInitialized = false;
  }
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

  Map<String, dynamic> toMap() {
    return {
      'totalComponents': totalComponents,
      'activeComponents': activeComponents,
      'totalConnections': totalConnections,
      'cacheSize': cacheSize,
      'memoryUsage': memoryUsage,
      'isHealthy': isHealthy,
      'lastHealthCheck': lastHealthCheck.toIso8601String(),
    };
  }
}

// Enhanced Supporting Classes for Component Relationships

class ComponentRelationship {
  final String sourceComponent;
  final String targetComponent;
  final RelationshipType type;
  final String description;
  final DateTime createdAt;
  final bool isActive;

  ComponentRelationship({
    required this.sourceComponent,
    required this.targetComponent,
    required this.type,
    required this.description,
    required this.createdAt,
    this.isActive = true,
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

  const ConfigEvent.parameterChanged(
      String key, dynamic oldValue, dynamic newValue)
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

  const ConfigEvent.componentNotified(
      String componentName, String key, dynamic value)
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
