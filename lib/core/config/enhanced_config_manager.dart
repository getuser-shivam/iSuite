import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:yaml/yaml.dart';
import 'package:http/http.dart' as http;

/// Enhanced Configuration Manager with Advanced Parameterization
/// Features: Environment detection, validation, hot-reload, caching
/// Supports: YAML, JSON, environment variables, runtime overrides
class EnhancedConfigManager {
  static EnhancedConfigManager? _instance;
  static EnhancedConfigManager get instance => _instance ??= EnhancedConfigManager._internal();
  EnhancedConfigManager._internal();

  // Configuration storage with validation
  final Map<String, dynamic> _config = {};
  final Map<String, ConfigSchema> _schemas = {};
  final Map<String, DateTime> _lastModified = {};
  final Map<String, String> _configSources = {};
  
  // Environment and platform detection
  late final String _environment;
  late final String _platform;
  late final bool _isDebugMode;
  late final bool _isProduction;
  late final bool _isDevelopment;
  
  // Hot-reload and caching
  final Map<String, Timer> _watchers = {};
  final Map<String, StreamController<void>> _reloadStreams = {};
  final Map<String, dynamic> _cache = {};
  final Duration _cacheTimeout = Duration(minutes: 5);
  
  // Validation and defaults
  final Map<String, dynamic> _defaults = {};
  final Map<String, List<String>> _required = {};
  final Map<String, dynamic> _validators = {};
  
  // Event streams
  final StreamController<ConfigEvent> _eventController = 
      StreamController<ConfigEvent>.broadcast();
  
  Stream<ConfigEvent> get events => _eventController.stream;

  /// Initialize enhanced configuration manager
  Future<void> initialize() async {
    try {
      // Detect environment and platform
      _detectEnvironment();
      
      // Load configuration files
      await _loadConfigurationFiles();
      
      // Load environment variables
      await _loadEnvironmentVariables();
      
      // Apply defaults
      _applyDefaults();
      
      // Validate configuration
      await _validateConfiguration();
      
      // Setup hot-reload if in development
      if (_isDevelopment) {
        _setupHotReload();
      }
      
      debugPrint('Enhanced configuration initialized for $_environment on $_platform');
    } catch (e) {
      debugPrint('Failed to initialize configuration: $e');
      rethrow;
    }
  }

  /// Detect environment and platform
  void _detectEnvironment() {
    // Environment detection
    const env = String.fromEnvironment('FLUTTER_ENV', defaultValue: 'development');
    _environment = env;
    _isDebugMode = kDebugMode;
    _isProduction = env == 'production';
    _isDevelopment = env == 'development';
    
    // Platform detection
    if (Platform.isWindows) {
      _platform = 'windows';
    } else if (Platform.isLinux) {
      _platform = 'linux';
    } else if (Platform.isMacOS) {
      _platform = 'macos';
    } else if (Platform.isAndroid) {
      _platform = 'android';
    } else if (Platform.isIOS) {
      _platform = 'ios';
    } else {
      _platform = 'web';
    }
    
    debugPrint('Environment: $_environment, Platform: $_platform');
  }

  /// Load configuration files with precedence
  Future<void> _loadConfigurationFiles() async {
    final configFiles = [
      'config/app.yaml',
      'config/pocketbase/pocketbase_config.yaml',
      'config/platform/platform_config.yaml',
      'config/environments/$_environment.yaml',
      'config/platforms/$_platform.yaml',
      'config/local/local_config.yaml',
    ];
    
    for (final filePath in configFiles) {
      try {
        await _loadConfigFile(filePath);
      } catch (e) {
        debugPrint('Failed to load config file $filePath: $e');
        // Continue with other files
      }
    }
  }

  /// Load individual configuration file
  Future<void> _loadConfigFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return;
    
    final content = await file.readAsString();
    final yaml = loadYaml(content);
    
    if (yaml is Map) {
      final configMap = _yamlToMap(yaml);
      _mergeConfig(configMap, filePath);
      _configSources[filePath] = 'file';
      _lastModified[filePath] = await file.lastModified();
      
      debugPrint('Loaded configuration from $filePath');
    }
  }

  /// Convert YAML to Map with proper type handling
  Map<String, dynamic> _yamlToMap(YamlMap yaml) {
    final result = <String, dynamic>{};
    
    for (final entry in yaml.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      
      if (value is YamlMap) {
        result[key] = _yamlToMap(value);
      } else if (value is YamlList) {
        result[key] = value.map((e) => e is YamlMap ? _yamlToMap(e) : e).toList();
      } else {
        result[key] = value;
      }
    }
    
    return result;
  }

  /// Merge configuration with existing
  void _mergeConfig(Map<String, dynamic> newConfig, String source) {
    _deepMerge(_config, newConfig);
    
    // Emit merge event
    _eventController.add(ConfigEvent(
      type: ConfigEventType.configLoaded,
      key: source,
      oldValue: null,
      newValue: newConfig,
    ));
  }

  /// Deep merge maps
  void _deepMerge(Map<String, dynamic> target, Map<String, dynamic> source) {
    for (final entry in source.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is Map && target[key] is Map) {
        _deepMerge(target[key] as Map<String, dynamic>, value as Map<String, dynamic>);
      } else {
        target[key] = value;
      }
    }
  }

  /// Load environment variables with prefix support
  Future<void> _loadEnvironmentVariables() async {
    final envVars = Platform.environment;
    
    // Load all environment variables with ISUITE_ prefix
    for (final entry in envVars.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (key.startsWith('ISUITE_')) {
        final configKey = key.substring(7).toLowerCase();
        _setNestedValue(configKey, value);
        _configSources[configKey] = 'environment';
      }
    }
    
    // Load PocketBase specific variables
    final pbVars = {
      'pocketbase_url': 'POCKETBASE_URL',
      'pocketbase_host': 'POCKETBASE_HOST',
      'pocketbase_port': 'POCKETBASE_PORT',
      'pocketbase_email': 'POCKETBASE_EMAIL',
      'pocketbase_password': 'POCKETBASE_PASSWORD',
    };
    
    for (final entry in pbVars.entries) {
      final value = envVars[entry.value];
      if (value != null) {
        _setNestedValue(entry.key, value);
        _configSources[entry.key] = 'environment';
      }
    }
  }

  /// Set nested value using dot notation
  void _setNestedValue(String key, dynamic value) {
    final parts = key.split('.');
    var current = _config;
    
    for (int i = 0; i < parts.length - 1; i++) {
      final part = parts[i];
      if (!current.containsKey(part) || current[part] is! Map) {
        current[part] = {};
      }
      current = current[part] as Map<String, dynamic>;
    }
    
    current[parts.last] = value;
  }

  /// Apply default values
  void _applyDefaults() {
    final defaults = {
      'pocketbase': {
        'server': {
          'local': {
            'host': 'localhost',
            'port': 8090,
            'url': 'http://localhost:8090',
          },
        },
        'performance': {
          'enable_offline': true,
          'enable_caching': true,
          'cache_timeout_seconds': 300,
          'max_retries': 3,
          'timeout_duration': 30,
          'enable_compression': false,
          'enable_encryption': false,
          'enable_metrics': true,
          'max_cache_size_mb': 100,
          'connection_pool_size': 5,
          'enable_auto_sync': true,
          'sync_interval_seconds': 60,
        },
        'auth': {
          'session_timeout_minutes': 30,
          'jwt_secret': 'default-secret-change-in-production',
          'enable_auto_lock': false,
          'auto_lock_timeout_minutes': 5,
        },
        'api': {
          'rate_limiting': {
            'enabled': true,
            'requests_per_minute': 60,
            'requests_per_hour': 1000,
            'requests_per_day': 10000,
          },
          'cors': {
            'enabled': true,
            'allowed_origins': ['http://localhost:3000', 'http://localhost:8080'],
            'allowed_methods': ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
            'allowed_headers': ['Content-Type', 'Authorization', 'X-Requested-With'],
          },
        },
      },
      'ui': {
        'primary_color': 0xFF2196F3,
        'secondary_color': 0xFF03DAC6,
        'theme_mode': 'system',
        'enable_animations': true,
        'enable_haptic_feedback': true,
      },
      'network': {
        'discovery_timeout_ms': 30000,
        'connection_timeout_ms': 15000,
        'buffer_size': 8192,
        'enable_encryption': true,
        'max_file_size_bytes': 104857600,
        'auto_accept_transfers': false,
        'transfer_retry_attempts': 3,
      },
      'analytics': {
        'enable_analytics': false,
        'enable_crash_reporting': false,
        'enable_performance_monitoring': true,
        'sampling_rate': 1.0,
        'enable_user_tracking': false,
        'anonymize_ip': true,
      },
      'logging': {
        'level': 'info',
        'enable_file_logging': true,
        'enable_console_logging': true,
        'log_file_path': 'logs/app.log',
        'log_max_size_mb': 10,
        'log_retention_days': 7,
      },
    };
    
    _deepMerge(_config, defaults);
    _configSources['defaults'] = 'built-in';
  }

  /// Validate configuration against schemas
  Future<void> _validateConfiguration() async {
    final validationErrors = <String>[];
    
    // Validate required fields
    for (final requiredPath in _required.entries) {
      final value = getParameter(requiredPath.key);
      if (value == null) {
        validationErrors.add('Required field missing: ${requiredPath.key}');
      }
    }
    
    // Validate data types and ranges
    for (final validator in _validators.entries) {
      final value = getParameter(validator.key);
      if (value != null && !_validateValue(value, validator.value)) {
        validationErrors.add('Invalid value for ${validator.key}: $value');
      }
    }
    
    // Validate PocketBase configuration
    final pocketbaseUrl = getParameter('pocketbase.server.local.url');
    if (pocketbaseUrl != null && !_isValidUrl(pocketbaseUrl)) {
      validationErrors.add('Invalid PocketBase URL: $pocketbaseUrl');
    }
    
    if (validationErrors.isNotEmpty) {
      throw ConfigValidationException(validationErrors);
    }
    
    debugPrint('Configuration validation passed');
  }

  /// Validate individual value
  bool _validateValue(dynamic value, dynamic validator) {
    if (validator is String) {
      return _validateByType(value, validator);
    } else if (validator is Map) {
      return _validateByRules(value, validator);
    }
    return true;
  }

  /// Validate by type
  bool _validateByType(dynamic value, String type) {
    switch (type) {
      case 'string':
        return value is String;
      case 'int':
        return value is int;
      case 'double':
        return value is double;
      case 'bool':
        return value is bool;
      case 'url':
        return _isValidUrl(value);
      case 'email':
        return _isValidEmail(value);
      default:
        return true;
    }
  }

  /// Validate by rules
  bool _validateByRules(dynamic value, Map<String, dynamic> rules) {
    if (rules.containsKey('type') && !_validateByType(value, rules['type'])) {
      return false;
    }
    
    if (rules.containsKey('min') && value is num && value < rules['min']) {
      return false;
    }
    
    if (rules.containsKey('max') && value is num && value > rules['max']) {
      return false;
    }
    
    if (rules.containsKey('pattern') && value is String) {
      final pattern = RegExp(rules['pattern']);
      return pattern.hasMatch(value);
    }
    
    return true;
  }

  /// Check if URL is valid
  bool _isValidUrl(dynamic url) {
    if (url is! String) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Check if email is valid
  bool _isValidEmail(dynamic email) {
    if (email is! String) return false;
    final pattern = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return pattern.hasMatch(email);
  }

  /// Setup hot-reload for configuration files
  void _setupHotReload() {
    final configFiles = [
      'config/app.yaml',
      'config/pocketbase/pocketbase_config.yaml',
      'config/platform/platform_config.yaml',
      'config/environments/$_environment.yaml',
    ];
    
    for (final filePath in configFiles) {
      _setupFileWatcher(filePath);
    }
  }

  /// Setup file watcher for hot-reload
  void _setupFileWatcher(String filePath) {
    final file = File(filePath);
    DateTime? lastModified;
    
    _watchers[filePath] = Timer.periodic(Duration(seconds: 1), (timer) async {
      try {
        if (!await file.exists()) return;
        
        final currentModified = await file.lastModified();
        if (lastModified == null || currentModified.isAfter(lastModified!)) {
          lastModified = currentModified;
          
          // Reload configuration
          await _loadConfigFile(filePath);
          
          // Validate
          await _validateConfiguration();
          
          // Notify listeners
          _eventController.add(ConfigEvent(
            type: ConfigEventType.configReloaded,
            key: filePath,
            oldValue: null,
            newValue: _config,
          ));
          
          debugPrint('Configuration reloaded: $filePath');
        }
      } catch (e) {
        debugPrint('Failed to reload config $filePath: $e');
      }
    });
  }

  /// Get parameter with caching and validation
  T? getParameter<T>(String key) {
    // Check cache first
    final cacheKey = '$key:${_environment}:${_platform}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey] as T?;
    }
    
    // Get value from config
    final value = _getNestedValue(key);
    
    // Cache the value
    if (value != null) {
      _cache[cacheKey] = value;
      
      // Clear cache after timeout
      Timer(_cacheTimeout, () {
        _cache.remove(cacheKey);
      });
    }
    
    return value as T?;
  }

  /// Get nested value using dot notation
  dynamic _getNestedValue(String key) {
    final parts = key.split('.');
    var current = _config;
    
    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    
    return current;
  }

  /// Set parameter with validation and events
  Future<void> setParameter<T>(String key, T value, {String? source}) async {
    final oldValue = getParameter<T>(key);
    
    // Validate value
    if (_validators.containsKey(key) && !_validateValue(value, _validators[key])) {
      throw ConfigValidationException(['Invalid value for $key: $value']);
    }
    
    // Set value
    _setNestedValue(key, value);
    _configSources[key] = source ?? 'runtime';
    
    // Clear cache
    _clearCacheForKey(key);
    
    // Emit event
    _eventController.add(ConfigEvent(
      type: ConfigEventType.parameterChanged,
      key: key,
      oldValue: oldValue,
      newValue: value,
    ));
    
    debugPrint('Parameter set: $key = $value');
  }

  /// Clear cache for specific key
  void _clearCacheForKey(String key) {
    _cache.removeWhere((cacheKey, value) => cacheKey.startsWith('$key:'));
  }

  /// Get configuration by environment
  Map<String, dynamic> getEnvironmentConfig(String environment) {
    return _config[environment] ?? {};
  }

  /// Get platform-specific configuration
  Map<String, dynamic> getPlatformConfig(String platform) {
    return _config[platform] ?? {};
  }

  /// Get all configuration with metadata
  Map<String, dynamic> getFullConfig() {
    return {
      'config': _config,
      'environment': _environment,
      'platform': _platform,
      'sources': _configSources,
      'last_modified': _lastModified,
      'cache_size': _cache.length,
      'watchers_count': _watchers.length,
    };
  }

  /// Export configuration to file
  Future<void> exportConfig(String filePath) async {
    final file = File(filePath);
    final content = const JsonEncoder.withIndent('  ').convert(_config);
    await file.writeAsString(content);
    debugPrint('Configuration exported to $filePath');
  }

  /// Import configuration from file
  Future<void> importConfig(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Config file not found: $filePath');
    }
    
    final content = await file.readAsString();
    final config = jsonDecode(content) as Map<String, dynamic>;
    
    _mergeConfig(config, filePath);
    await _validateConfiguration();
    
    debugPrint('Configuration imported from $filePath');
  }

  /// Reset configuration to defaults
  Future<void> resetToDefaults() async {
    _config.clear();
    _cache.clear();
    _configSources.clear();
    _lastModified.clear();
    
    await _loadConfigurationFiles();
    _applyDefaults();
    await _validateConfiguration();
    
    _eventController.add(ConfigEvent(
      type: ConfigEventType.resetToDefaults,
      key: 'all',
      oldValue: null,
      newValue: _config,
    ));
    
    debugPrint('Configuration reset to defaults');
  }

  /// Get configuration schema
  ConfigSchema? getSchema(String key) {
    return _schemas[key];
  }

  /// Add configuration schema
  void addSchema(String key, ConfigSchema schema) {
    _schemas[key] = schema;
  }

  /// Validate configuration against schema
  Future<List<String>> validateAgainstSchema() async {
    final errors = <String>[];
    
    for (final schemaEntry in _schemas.entries) {
      final key = schemaEntry.key;
      final schema = schemaEntry.value;
      final value = getParameter(key);
      
      if (schema.required && value == null) {
        errors.add('Required field missing: $key');
        continue;
      }
      
      if (value != null && !schema.validate(value)) {
        errors.add('Schema validation failed for $key');
      }
    }
    
    return errors;
  }

  /// Dispose resources
  Future<void> dispose() async {
    // Cancel watchers
    for (final watcher in _watchers.values) {
      watcher.cancel();
    }
    _watchers.clear();
    
    // Close streams
    for (final stream in _reloadStreams.values) {
      stream.close();
    }
    _reloadStreams.clear();
    
    await _eventController.close();
    
    debugPrint('Enhanced configuration manager disposed');
  }

  // Getters
  String get environment => _environment;
  String get platform => _platform;
  bool get isDebugMode => _isDebugMode;
  bool get isProduction => _isProduction;
  bool get isDevelopment => _isDevelopment;
  int get cacheSize => _cache.length;
  int get watchersCount => _watchers.length;
}

/// Configuration schema for validation
class ConfigSchema {
  final String type;
  final bool required;
  final dynamic defaultValue;
  final dynamic min;
  final dynamic max;
  final String? pattern;
  final List<String>? allowedValues;
  final String? description;

  ConfigSchema({
    required this.type,
    this.required = false,
    this.defaultValue,
    this.min,
    this.max,
    this.pattern,
    this.allowedValues,
    this.description,
  });

  bool validate(dynamic value) {
    // Type validation
    switch (type) {
      case 'string':
        if (value is! String) return false;
        break;
      case 'int':
        if (value is! int) return false;
        break;
      case 'double':
        if (value is! double) return false;
        break;
      case 'bool':
        if (value is! bool) return false;
        break;
      case 'url':
        if (value is! String || !Uri.tryParse(value)!.hasScheme) return false;
        break;
      case 'email':
        if (value is! String || !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) return false;
        break;
    }

    // Range validation
    if (value is num) {
      if (min != null && value < min) return false;
      if (max != null && value > max) return false;
    }

    // Pattern validation
    if (pattern != null && value is String) {
      if (!RegExp(pattern!).hasMatch(value)) return false;
    }

    // Allowed values validation
    if (allowedValues != null && !allowedValues!.contains(value)) {
      return false;
    }

    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'required': required,
      'default_value': defaultValue,
      'min': min,
      'max': max,
      'pattern': pattern,
      'allowed_values': allowedValues,
      'description': description,
    };
  }
}

/// Configuration event types
enum ConfigEventType {
  configLoaded,
  configReloaded,
  parameterChanged,
  resetToDefaults,
  validationFailed,
}

/// Configuration event
class ConfigEvent {
  final ConfigEventType type;
  final String key;
  final dynamic oldValue;
  final dynamic newValue;
  final DateTime timestamp;

  ConfigEvent({
    required this.type,
    required this.key,
    this.oldValue,
    this.newValue,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'key': key,
      'old_value': oldValue,
      'new_value': newValue,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Configuration validation exception
class ConfigValidationException implements Exception {
  final List<String> errors;

  ConfigValidationException(this.errors);

  @override
  String toString() {
    return 'Configuration validation failed:\n${errors.join('\n')}';
  }
}
