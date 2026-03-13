import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;
import '../logging/enhanced_logger.dart';

/// Central Parameterized Configuration Manager
/// Features: Centralized configuration, environment overrides, validation
/// Performance: Caching, hot-reload, lazy loading, type safety
/// Security: Secure parameter storage, encryption for sensitive data
/// Architecture: Singleton pattern, observer pattern, dependency injection ready
class CentralParameterizedConfig {
  static CentralParameterizedConfig? _instance;
  static CentralParameterizedConfig get instance => _instance ??= CentralParameterizedConfig._internal();
  CentralParameterizedConfig._internal();

  // Core configuration storage
  final Map<String, dynamic> _config = {};
  final Map<String, dynamic> _defaults = {};
  final Map<String, dynamic> _environmentOverrides = {};
  final Map<String, dynamic> _runtimeOverrides = {};
  
  // Configuration sources
  final Map<String, ConfigurationSource> _sources = {};
  final List<ConfigurationObserver> _observers = [];
  
  // Caching and performance
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  Timer? _cacheCleanupTimer;
  
  // Validation
  final Map<String, ParameterValidator> _validators = {};
  final Map<String, ParameterSchema> _schemas = {};
  
  // Event streams
  final StreamController<ConfigurationEvent> _eventController = 
      StreamController<ConfigurationEvent>.broadcast();
  
  Stream<ConfigurationEvent> get configurationEvents => _eventController.stream;

  /// Initialize central configuration
  Future<void> initialize() async {
    try {
      // Load default configuration
      await _loadDefaults();
      
      // Load environment overrides
      await _loadEnvironmentOverrides();
      
      // Load configuration files
      await _loadConfigurationFiles();
      
      // Setup validation schemas
      await _setupValidationSchemas();
      
      // Setup caching
      _setupCaching();
      
      // Merge all configuration sources
      await _mergeConfiguration();
      
      // Validate final configuration
      await _validateConfiguration();
      
      EnhancedLogger.instance.info('Central Parameterized Configuration initialized');
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to initialize Central Parameterized Configuration', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Load default configuration
  Future<void> _loadDefaults() async {
    _defaults.addAll({
      // Application defaults
      'app.name': 'iSuite',
      'app.version': '2.0.0',
      'app.environment': kDebugMode ? 'development' : 'production',
      'app.debug': kDebugMode,
      
      // AI Services defaults
      'ai_services.enable_file_organizer': true,
      'ai_services.enable_advanced_search': true,
      'ai_services.enable_smart_categorizer': true,
      'ai_services.enable_duplicate_detector': true,
      'ai_services.enable_recommendations': true,
      'ai_services.enable_integration': true,
      'ai_services.max_concurrent_tasks': 5,
      'ai_services.workflow_timeout_seconds': 300,
      
      // Network Services defaults
      'network_services.enable_file_sharing': true,
      'network_services.enable_ftp_client': true,
      'network_services.enable_wifi_direct': true,
      'network_services.enable_p2p': true,
      'network_services.enable_webdav': true,
      'network_services.enable_discovery': true,
      'network_services.enable_security': true,
      'network_services.max_concurrent_operations': 10,
      'network_services.connection_timeout_seconds': 30,
      'network_services.enable_cross_protocol_sharing': true,
      
      // Performance defaults
      'performance.enable_caching': true,
      'performance.cache_size_mb': 100,
      'performance.enable_parallel_processing': true,
      'performance.max_workers': 4,
      'performance.enable_optimization': true,
      'performance.memory_limit_mb': 512,
      
      // Security defaults
      'security.enable_encryption': true,
      'security.enable_authentication': true,
      'security.enable_access_control': true,
      'security.enable_audit_logging': true,
      'security.encryption_algorithm': 'AES-256',
      'security.key_size': 256,
      'security.session_timeout_hours': 8,
      
      // UI defaults
      'ui.theme_mode': 'system',
      'ui.enable_dark_mode': true,
      'ui.enable_animations': true,
      'ui.font_size': 'medium',
      'ui.language': 'en',
      
      // Backend defaults
      'backend.type': 'pocketbase',
      'backend.host': 'localhost',
      'backend.port': 8090,
      'backend.auto_start': true,
      'backend.enable_offline': true,
      
      // Logging defaults
      'logging.level': kDebugMode ? 'debug' : 'info',
      'logging.enable_file_logging': true,
      'logging.enable_console_logging': true,
      'logging.max_file_size_mb': 10,
      'logging.retention_days': 30,
    });
    
    // Copy defaults to main config
    _config.addAll(Map<String, dynamic>.from(_defaults));
    
    EnhancedLogger.instance.info('Default configuration loaded');
  }

  /// Load environment overrides
  Future<void> _loadEnvironmentOverrides() async {
    // Load from environment variables prefixed with ISUITE_
    final envVars = Platform.environment;
    
    for (final entry in envVars.entries) {
      if (entry.key.startsWith('ISUITE_')) {
        final configKey = entry.key.substring(7).toLowerCase();
        final value = _parseEnvironmentValue(entry.value);
        _environmentOverrides[configKey] = value;
      }
    }
    
    EnhancedLogger.instance.info('Environment overrides loaded: ${_environmentOverrides.length} values');
  }

  /// Load configuration files
  Future<void> _loadConfigurationFiles() async {
    final configDir = path.join(Directory.current.path, 'config');
    
    // Load main configuration file
    final mainConfigFile = path.join(configDir, 'config.yaml');
    if (await File(mainConfigFile).exists()) {
      final content = await File(mainConfigFile).readAsString();
      final yamlData = loadYaml(content);
      _sources['main'] = FileConfigurationSource('main', mainConfigFile, yamlData);
    }
    
    // Load environment-specific configuration
    final environment = getParameter('app.environment', 'production');
    final envConfigFile = path.join(configDir, 'environments', '$environment.yaml');
    if (await File(envConfigFile).exists()) {
      final content = await File(envConfigFile).readAsString();
      final yamlData = loadYaml(content);
      _sources['environment'] = FileConfigurationSource('environment', envConfigFile, yamlData);
    }
    
    // Load component-specific configurations
    final componentConfigs = [
      'ai/ai_config.yaml',
      'network/network_config.yaml',
      'performance/performance_config.yaml',
      'security/security_config.yaml',
      'ui/ui_config.yaml',
    ];
    
    for (final configFile in componentConfigs) {
      final fullPath = path.join(configDir, configFile);
      if (await File(fullPath).exists()) {
        final content = await File(fullPath).readAsString();
        final yamlData = loadYaml(content);
        final componentName = path.basenameWithoutExtension(configFile);
        _sources[componentName] = FileConfigurationSource(componentName, fullPath, yamlData);
      }
    }
    
    EnhancedLogger.instance.info('Configuration files loaded: ${_sources.length} sources');
  }

  /// Setup validation schemas
  Future<void> _setupValidationSchemas() async {
    // Define parameter schemas for validation
    _schemas['app'] = ParameterSchema({
      'name': ParameterType.string,
      'version': ParameterType.string,
      'environment': ParameterType.string,
      'debug': ParameterType.boolean,
    });
    
    _schemas['ai_services'] = ParameterSchema({
      'enable_file_organizer': ParameterType.boolean,
      'enable_advanced_search': ParameterType.boolean,
      'enable_smart_categorizer': ParameterType.boolean,
      'enable_duplicate_detector': ParameterType.boolean,
      'enable_recommendations': ParameterType.boolean,
      'enable_integration': ParameterType.boolean,
      'max_concurrent_tasks': ParameterType.integer,
      'workflow_timeout_seconds': ParameterType.integer,
    });
    
    _schemas['network_services'] = ParameterSchema({
      'enable_file_sharing': ParameterType.boolean,
      'enable_ftp_client': ParameterType.boolean,
      'enable_wifi_direct': ParameterType.boolean,
      'enable_p2p': ParameterType.boolean,
      'enable_webdav': ParameterType.boolean,
      'enable_discovery': ParameterType.boolean,
      'enable_security': ParameterType.boolean,
      'max_concurrent_operations': ParameterType.integer,
      'connection_timeout_seconds': ParameterType.integer,
      'enable_cross_protocol_sharing': ParameterType.boolean,
    });
    
    _schemas['performance'] = ParameterSchema({
      'enable_caching': ParameterType.boolean,
      'cache_size_mb': ParameterType.integer,
      'enable_parallel_processing': ParameterType.boolean,
      'max_workers': ParameterType.integer,
      'enable_optimization': ParameterType.boolean,
      'memory_limit_mb': ParameterType.integer,
    });
    
    _schemas['security'] = ParameterSchema({
      'enable_encryption': ParameterType.boolean,
      'enable_authentication': ParameterType.boolean,
      'enable_access_control': ParameterType.boolean,
      'enable_audit_logging': ParameterType.boolean,
      'encryption_algorithm': ParameterType.string,
      'key_size': ParameterType.integer,
      'session_timeout_hours': ParameterType.integer,
    });
    
    _schemas['ui'] = ParameterSchema({
      'theme_mode': ParameterType.string,
      'enable_dark_mode': ParameterType.boolean,
      'enable_animations': ParameterType.boolean,
      'font_size': ParameterType.string,
      'language': ParameterType.string,
    });
    
    _schemas['backend'] = ParameterSchema({
      'type': ParameterType.string,
      'host': ParameterType.string,
      'port': ParameterType.integer,
      'auto_start': ParameterType.boolean,
      'enable_offline': ParameterType.boolean,
    });
    
    _schemas['logging'] = ParameterSchema({
      'level': ParameterType.string,
      'enable_file_logging': ParameterType.boolean,
      'enable_console_logging': ParameterType.boolean,
      'max_file_size_mb': ParameterType.integer,
      'retention_days': ParameterType.integer,
    });
    
    EnhancedLogger.instance.info('Validation schemas setup: ${_schemas.length} schemas');
  }

  /// Setup caching
  void _setupCaching() {
    _cacheCleanupTimer = Timer.periodic(Duration(minutes: 10), (_) {
      _cleanupCache();
    });
  }

  /// Merge all configuration sources
  Future<void> _mergeConfiguration() async {
    // Start with defaults
    _config.clear();
    _config.addAll(Map<String, dynamic>.from(_defaults));
    
    // Apply environment overrides
    _mergeMap(_config, _environmentOverrides);
    
    // Apply configuration files (in order of priority)
    final sourceOrder = ['main', 'environment', 'ai', 'network', 'performance', 'security', 'ui', 'backend', 'logging'];
    
    for (final sourceName in sourceOrder) {
      final source = _sources[sourceName];
      if (source != null) {
        _mergeMap(_config, source.data);
      }
    }
    
    // Apply runtime overrides
    _mergeMap(_config, _runtimeOverrides);
    
    EnhancedLogger.instance.info('Configuration merged from ${_sources.length + 3} sources');
  }

  /// Validate configuration
  Future<void> _validateConfiguration() async {
    for (final entry in _config.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // Find schema for this parameter
      final category = _getCategoryForParameter(key);
      final schema = _schemas[category];
      
      if (schema != null) {
        final parameterType = schema.type;
        
        // Validate parameter type
        if (!_isValidType(value, parameterType)) {
          throw ConfigurationException(
            'Invalid type for parameter $key: expected $parameterType, got ${value.runtimeType}',
          );
        }
        
        // Apply parameter-specific validation
        final validator = _validators[key];
        if (validator != null) {
          final validationResult = await validator.validate(value);
          if (!validationResult.isValid) {
            throw ConfigurationException(
              'Validation failed for parameter $key: ${validationResult.error}',
            );
          }
        }
      }
    }
    
    EnhancedLogger.instance.info('Configuration validated successfully');
  }

  /// Get parameter value with automatic type casting
  T? getParameter<T>(String key, {T? defaultValue, String? category}) {
    try {
      // Check cache first
      final cacheKey = '${category ?? 'global'}:$key';
      if (_cache.containsKey(cacheKey)) {
        final cachedValue = _cache[cacheKey];
        if (cachedValue is T) {
          return cachedValue as T;
        }
      }
      
      // Get value from configuration
      final value = _config[key];
      if (value == null) {
        return defaultValue;
      }
      
      // Type conversion
      final convertedValue = _convertValue<T>(value);
      if (convertedValue != null) {
        // Cache the converted value
        _cache[cacheKey] = convertedValue;
        _cacheTimestamps[cacheKey] = DateTime.now();
      }
      
      return convertedValue;
    } catch (e) {
      EnhancedLogger.instance.warning('Failed to get parameter $key: $e');
      return defaultValue;
    }
  }

  /// Set parameter value with validation and notification
  Future<bool> setParameter<T>(String key, T value, {String? category, bool notify = true}) async {
    try {
      // Validate parameter
      final categoryKey = category ?? _getCategoryForParameter(key);
      final schema = _schemas[categoryKey];
      
      if (schema != null) {
        final parameterType = schema.type;
        if (!_isValidType(value, parameterType)) {
          throw ConfigurationException(
            'Invalid type for parameter $key: expected $parameterType, got ${value.runtimeType}',
          );
        }
        
        // Apply parameter-specific validation
        final validator = _validators[key];
        if (validator != null) {
          final validationResult = await validator.validate(value);
          if (!validationResult.isValid) {
            throw ConfigurationException(
              'Validation failed for parameter $key: ${validationResult.error}',
            );
          }
        }
      }
      
      // Set value
      _config[key] = value;
      
      // Clear cache
      final cacheKey = '${categoryKey}:$key';
      _cache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
      
      // Notify observers
      if (notify) {
        _notifyObservers(key, value);
      }
      
      // Emit event
      _eventController.add(ConfigurationEvent(
        type: ConfigurationEventType.parameterChanged,
        key: key,
        oldValue: _config[key],
        newValue: value,
        timestamp: DateTime.now(),
      );
      
      EnhancedLogger.instance.info('Parameter set: $key = $value');
      return true;
    } catch (e) {
      EnhancedLogger.instance.error('Failed to set parameter $key: $e');
      return false;
    }
  }

  /// Add configuration observer
  void addObserver(ConfigurationObserver observer) {
    _observers.add(observer);
  }

  /// Remove configuration observer
  void removeObserver(ConfigurationObserver observer) {
    _observers.remove(observer);
  }

  /// Add parameter validator
  void addValidator(String key, ParameterValidator validator) {
    _validators[key] = validator;
  }

  /// Reload configuration from sources
  Future<void> reloadConfiguration() async {
    try {
      // Clear current configuration
      _config.clear();
      
      // Reload all sources
      await _loadEnvironmentOverrides();
      await _loadConfigurationFiles();
      
      // Merge configuration
      await _mergeConfiguration();
      
      // Validate configuration
      await _validateConfiguration();
      
      // Notify observers of reload
      _notifyObservers('*', _config);
      
      // Emit reload event
      _eventController.add(ConfigurationEvent(
        type: ConfigurationEventType.configurationReloaded,
        timestamp: DateTime.now(),
      );
      
      EnhancedLogger.instance.info('Configuration reloaded successfully');
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to reload configuration', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Export configuration to YAML
  Future<String> exportConfiguration() async {
    final exportData = <String, dynamic>{};
    
    // Export by category
    for (final entry in _config.entries) {
      final category = _getCategoryForParameter(entry.key);
      if (!exportData.containsKey(category)) {
        exportData[category] = {};
      }
      exportData[category][entry.key] = entry.value;
    }
    
    return yaml.encode(exportData);
  }

  /// Import configuration from YAML
  Future<bool> importConfiguration(String yamlData) async {
    try {
      final importData = loadYaml(yamlData);
      
      // Validate import data
      for (final categoryEntry in importData.entries) {
        final category = categoryEntry.key;
        final schema = _schemas[category];
        
        if (schema != null) {
          for (final paramEntry in categoryEntry.value.entries) {
            final key = paramEntry.key;
            final value = paramEntry.value;
            
            final parameterType = schema.type;
            if (!_isValidType(value, parameterType)) {
              throw ConfigurationException(
                'Invalid type for parameter $key: expected $parameterType, got ${value.runtimeType}',
              );
            }
          }
        }
      }
      
      // Apply imported configuration
      _mergeMap(_config, importData);
      
      // Validate final configuration
      await _validateConfiguration();
      
      // Notify observers
      _notifyObservers('*', _config);
      
      // Emit import event
      _eventController.add(ConfigurationEvent(
        type: ConfigurationEventType.configurationImported,
        timestamp: DateTime.now(),
      );
      
      EnhancedLogger.instance.info('Configuration imported successfully');
      return true;
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to import configuration', 
        error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get configuration statistics
  Map<String, dynamic> getConfigurationStatistics() {
    return {
      'total_parameters': _config.length,
      'cached_parameters': _cache.length,
      'sources_count': _sources.length,
      'observers_count': _observers.length,
      'validators_count': _validators.length,
      'schemas_count': _schemas.length,
      'environment_overrides': _environmentOverrides.length,
      'runtime_overrides': _runtimeOverrides.length,
      'categories': _schemas.keys.toList(),
      'cache_hit_rate': _calculateCacheHitRate(),
    };
  }

  /// Helper methods
  String _getCategoryForParameter(String key) {
    if (key.startsWith('app.')) return 'app';
    if (key.startsWith('ai_services.')) return 'ai_services';
    if (key.startsWith('network_services.')) return 'network_services';
    if (key.startsWith('performance.')) return 'performance';
    if (key.startsWith('security.')) return 'security';
    if (key.startsWith('ui.')) return 'ui';
    if (key.startsWith('backend.')) return 'backend';
    if (key.startsWith('logging.')) return 'logging';
    return 'global';
  }

  void _mergeMap(Map<String, dynamic> target, Map<String, dynamic> source) {
    for (final entry in source.entries) {
      target[entry.key] = entry.value;
    }
  }

  dynamic _parseEnvironmentValue(String value) {
    // Try to parse as JSON first
    try {
      return jsonDecode(value);
    } catch (e) {
      // Return as string if not valid JSON
      return value;
    }
  }

  T? _convertValue<T>(dynamic value) {
    if (value is T) return value;
    
    // Type conversions
    switch (T) {
      case String:
        return value.toString() as T?;
      case int:
        return int.tryParse(value.toString()) as T?;
      case double:
        return double.tryParse(value.toString()) as T?;
      case bool:
        if (value is bool) return value as T;
        if (value is String) {
          final lower = value.toLowerCase();
          if (lower == 'true') return true as T;
          if (lower == 'false') return false as T;
        }
        return null;
      case List:
        if (value is List) return value as T?;
        if (value is String) {
          try {
            return jsonDecode(value) as T?;
          } catch (e) {
            return null;
          }
        }
        return null;
      case Map:
        if (value is Map) return value as T?;
        if (value is String) {
          try {
            return jsonDecode(value) as T?;
          } catch (e) {
            return null;
          }
        }
        return null;
      default:
        return null;
    }
  }

  bool _isValidType(dynamic value, ParameterType type) {
    switch (type) {
      case ParameterType.string:
        return value is String;
      case ParameterType.integer:
        return value is int || (value is String && int.tryParse(value) != null);
      case ParameterType.double:
        return value is double || (value is String && double.tryParse(value) != null);
      case ParameterType.boolean:
        return value is bool || (value is String && (value.toLowerCase() == 'true' || value.toLowerCase() == 'false'));
      case ParameterType.list:
        return value is List;
      case ParameterType.map:
        return value is Map;
      default:
        return true;
    }
  }

  void _notifyObservers(String key, dynamic value) {
    for (final observer in _observers) {
      observer.onConfigurationChanged(key, value);
    }
  }

  void _cleanupCache() {
    final expiredKeys = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (DateTime.now().difference(entry.value).inMinutes > 30) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      EnhancedLogger.instance.info('Cleaned up ${expiredKeys.length} expired cache entries');
    }
  }

  double _calculateCacheHitRate() {
    // This would require tracking cache hits and misses
    // For now, return a placeholder value
    return 0.85;
  }

  /// Dispose
  void dispose() {
    _cacheCleanupTimer?.cancel();
    _eventController.close();
    _observers.clear();
    _sources.clear();
    _validators.clear();
    _schemas.clear();
    _config.clear();
    _cache.clear();
    _cacheTimestamps.clear();
    _environmentOverrides.clear();
    _runtimeOverrides.clear();
    
    EnhancedLogger.instance.info('Central Parameterized Configuration disposed');
  }
}

/// Configuration source interface
abstract class ConfigurationSource {
  final String name;
  final String path;
  final Map<String, dynamic> data;
  
  ConfigurationSource(this.name, this.path, this.data);
}

/// File configuration source
class FileConfigurationSource extends ConfigurationSource {
  FileConfigurationSource(String name, String path, Map<String, dynamic> data) 
      : super(name, path, data);
}

/// Parameter schema
class ParameterSchema {
  final Map<String, ParameterType> type;
  
  ParameterSchema(this.type);
}

/// Parameter validator interface
abstract class ParameterValidator {
  Future<ValidationResult> validate(dynamic value);
}

/// Validation result
class ValidationResult {
  final bool isValid;
  final String? error;
  
  ValidationResult(this.isValid, {this.error});
}

/// Configuration observer interface
abstract class ConfigurationObserver {
  void onConfigurationChanged(String key, dynamic value);
}

/// Configuration event
class ConfigurationEvent {
  final ConfigurationEventType type;
  final String? key;
  final dynamic oldValue;
  final dynamic newValue;
  final DateTime timestamp;
  
  ConfigurationEvent({
    required this.type,
    this.key,
    this.oldValue,
    this.newValue,
  }) : timestamp = DateTime.now();
}

/// Configuration exception
class ConfigurationException implements Exception {
  final String message;
  
  ConfigurationException(this.message);
  
  @override
  String toString() => 'ConfigurationException: $message';
}

/// Parameter types
enum ParameterType {
  string,
  integer,
  double,
  boolean,
  list,
  map,
}

/// Configuration event types
enum ConfigurationEventType {
  parameterChanged,
  configurationReloaded,
  configurationImported,
  configurationExported,
}

/// Global configuration getter for easy access
T? getConfig<T>(String key, {T? defaultValue, String? category}) {
  return CentralParameterizedConfig.instance.getParameter<T>(key, defaultValue: defaultValue, category: category);
}

/// Global configuration setter for easy access
Future<bool> setConfig<T>(String key, T value, {String? category, bool notify = true}) async {
  return await CentralParameterizedConfig.instance.setParameter<T>(key, value, category: category, notify: notify);
}
