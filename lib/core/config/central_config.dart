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

  /// Setup UI configuration parameters
  Future<void> setupUIConfig() async {
    // Theme colors
    await setParameter('ui.primary_color', 0xFF2196F3, description: 'Primary theme color');
    await setParameter('ui.secondary_color', 0xFF03DAC6, description: 'Secondary theme color');
    await setParameter('ui.accent_color', 0xFFFF4081, description: 'Accent color');
    await setParameter('ui.error_color', 0xFFB00020, description: 'Error color');
    await setParameter('ui.warning_color', 0xFFFF9800, description: 'Warning color');
    await setParameter('ui.success_color', 0xFF4CAF50, description: 'Success color');
    await setParameter('ui.info_color', 0xFF2196F3, description: 'Info color');

    // Surface colors
    await setParameter('ui.surface_color', 0xFFFFFFFF, description: 'Surface background color');
    await setParameter('ui.background_color', 0xFFFAFAFA, description: 'Background color');
    await setParameter('ui.card_color', 0xFFFFFFFF, description: 'Card background color');
    await setParameter('ui.dialog_color', 0xFFFFFFFF, description: 'Dialog background color');

    // Text colors
    await setParameter('ui.on_primary', 0xFFFFFFFF, description: 'Text color on primary');
    await setParameter('ui.on_secondary', 0xFF000000, description: 'Text color on secondary');
    await setParameter('ui.on_surface', 0xFF000000, description: 'Text color on surface');
    await setParameter('ui.on_background', 0xFF000000, description: 'Text color on background');
    await setParameter('ui.on_error', 0xFFFFFFFF, description: 'Text color on error');

    // Font sizes
    await setParameter('ui.font_size_xs', 12.0, description: 'Extra small font size');
    await setParameter('ui.font_size_sm', 14.0, description: 'Small font size');
    await setParameter('ui.font_size_md', 16.0, description: 'Medium font size');
    await setParameter('ui.font_size_lg', 18.0, description: 'Large font size');
    await setParameter('ui.font_size_xl', 20.0, description: 'Extra large font size');
    await setParameter('ui.font_size_2xl', 24.0, description: '2X large font size');
    await setParameter('ui.font_size_3xl', 30.0, description: '3X large font size');

    // Spacing
    await setParameter('ui.spacing_xs', 4.0, description: 'Extra small spacing');
    await setParameter('ui.spacing_sm', 8.0, description: 'Small spacing');
    await setParameter('ui.spacing_md', 16.0, description: 'Medium spacing');
    await setParameter('ui.spacing_lg', 24.0, description: 'Large spacing');
    await setParameter('ui.spacing_xl', 32.0, description: 'Extra large spacing');
    await setParameter('ui.spacing_2xl', 48.0, description: '2X large spacing');

    // Border radius
    await setParameter('ui.border_radius_sm', 4.0, description: 'Small border radius');
    await setParameter('ui.border_radius_md', 8.0, description: 'Medium border radius');
    await setParameter('ui.border_radius_lg', 12.0, description: 'Large border radius');
    await setParameter('ui.border_radius_xl', 16.0, description: 'Extra large border radius');
    await setParameter('ui.border_radius_full', 999.0, description: 'Full border radius');

    // Shadows and elevation
    await setParameter('ui.shadow_sm', 2.0, description: 'Small shadow blur');
    await setParameter('ui.shadow_md', 4.0, description: 'Medium shadow blur');
    await setParameter('ui.shadow_lg', 8.0, description: 'Large shadow blur');
    await setParameter('ui.shadow_xl', 16.0, description: 'Extra large shadow blur');

    // Animation durations
    await setParameter('ui.animation_fast', 150, description: 'Fast animation duration (ms)');
    await setParameter('ui.animation_normal', 300, description: 'Normal animation duration (ms)');
    await setParameter('ui.animation_slow', 500, description: 'Slow animation duration (ms)');

    // Component dimensions
    await setParameter('ui.button_height', 48.0, description: 'Standard button height');
    await setParameter('ui.input_height', 48.0, description: 'Input field height');
    await setParameter('ui.card_padding', 16.0, description: 'Card padding');
    await setParameter('ui.screen_padding', 16.0, description: 'Screen padding');

    // Icon sizes
    await setParameter('ui.icon_size_sm', 16.0, description: 'Small icon size');
    await setParameter('ui.icon_size_md', 24.0, description: 'Medium icon size');
    await setParameter('ui.icon_size_lg', 32.0, description: 'Large icon size');
    await setParameter('ui.icon_size_xl', 48.0, description: 'Extra large icon size');

    _logger.info('UI configuration parameters loaded', 'CentralConfig');
  }

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
  Future<void> initialize({bool enableHotReload = true}) async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing CentralConfig', 'CentralConfig');

      // Load default configurations
      await _loadDefaultConfigurations();

      // Load environment and platform-specific configs
      await _loadEnvironmentConfigurations();

      // Load default accessibility configurations
      await _loadDefaultAccessibilityConfigurations();

      // Validate all configurations
      await _validateConfigurations();

      // Register hot-reload if enabled
      if (enableHotReload && !_isTestEnvironment) {
        await _setupHotReload();
      }

      _isInitialized = true;
      _logger.info('CentralConfig initialized successfully', 'CentralConfig');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize CentralConfig', 'CentralConfig', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Validate all configurations against schemas
  Future<void> _validateConfigurations() async {
    final validationErrors = <String>[];

    // Validate each component's configuration
    for (final componentName in _componentParameters.keys) {
      final parameters = _componentParameters[componentName]!;
      final errors = await _validateComponentConfiguration(componentName, parameters);
      validationErrors.addAll(errors);
    }

    // Validate global parameters
    final globalErrors = _validateGlobalConfiguration();
    validationErrors.addAll(globalErrors);

    // Validate accessibility settings
    final accessibilityErrors = _validateAccessibilityConfiguration();
    validationErrors.addAll(accessibilityErrors);

    if (validationErrors.isNotEmpty) {
      _logger.warning('Configuration validation errors found:', 'CentralConfig');
      for (final error in validationErrors) {
        _logger.warning('  - $error', 'CentralConfig');
      }

      // In strict mode, throw exception; otherwise just log warnings
      if (_strictValidation) {
        throw ConfigurationException('Configuration validation failed: ${validationErrors.join(', ')}');
      }
    }
  }

  /// Validate component configuration
  Future<List<String>> _validateComponentConfiguration(String componentName, Map<String, dynamic> parameters) async {
    final errors = <String>[];

    // Get component schema if available
    final schema = _componentSchemas[componentName];
    if (schema != null) {
      final schemaErrors = _validateAgainstSchema(componentName, parameters, schema);
      errors.addAll(schemaErrors);
    }

    // Component-specific validations
    switch (componentName) {
      case 'FTPClientService':
        errors.addAll(_validateFTPConfiguration(parameters));
        break;
      case 'NetworkDeviceScanner':
        errors.addAll(_validateNetworkConfiguration(parameters));
        break;
      case 'AIEnhancedService':
        errors.addAll(_validateAIConfiguration(parameters));
        break;
    }

    return errors;
  }

  /// Validate FTP configuration
  List<String> _validateFTPConfiguration(Map<String, dynamic> params) {
    final errors = <String>[];

    final timeout = params['ftp_timeout'];
    if (timeout != null && (timeout < 5 || timeout > 300)) {
      errors.add('FTP timeout must be between 5-300 seconds');
    }

    final maxConnections = params['max_connections'];
    if (maxConnections != null && (maxConnections < 1 || maxConnections > 10)) {
      errors.add('FTP max connections must be between 1-10');
    }

    return errors;
  }

  /// Validate network configuration
  List<String> _validateNetworkConfiguration(Map<String, dynamic> params) {
    final errors = <String>[];

    final maxConcurrent = params['max_concurrent'];
    if (maxConcurrent != null && (maxConcurrent < 1 || maxConcurrent > 20)) {
      errors.add('Network max concurrent must be between 1-20');
    }

    final timeout = params['timeout'];
    if (timeout != null && (timeout < 100 || timeout > 30000)) {
      errors.add('Network timeout must be between 100-30000ms');
    }

    return errors;
  }

  /// Validate AI configuration
  List<String> _validateAIConfiguration(Map<String, dynamic> params) {
    final errors = <String>[];

    final maxRetries = params['max_retries'];
    if (maxRetries != null && (maxRetries < 0 || maxRetries > 5)) {
      errors.add('AI max retries must be between 0-5');
    }

    final timeout = params['timeout'];
    if (timeout != null && (timeout < 5000 || timeout > 120000)) {
      errors.add('AI timeout must be between 5000-120000ms');
    }

    return errors;
  }

  /// Validate accessibility configuration
  List<String> _validateAccessibilityConfiguration() {
    final errors = <String>[];

    // Validate screen reader settings
    final screenReader = getParameter('accessibility.screen_reader_enabled', defaultValue: false);
    if (screenReader is! bool) {
      errors.add('accessibility.screen_reader_enabled must be a boolean');
    }

    // Validate high contrast settings
    final highContrast = getParameter('accessibility.high_contrast_enabled', defaultValue: false);
    if (highContrast is! bool) {
      errors.add('accessibility.high_contrast_enabled must be a boolean');
    }

    // Validate font scale
    final fontScale = getParameter('accessibility.font_scale', defaultValue: 1.0);
    if (fontScale is num && (fontScale < 0.5 || fontScale > 3.0)) {
      errors.add('accessibility.font_scale must be between 0.5 and 3.0');
    }

    // Validate keyboard navigation
    final keyboardNav = getParameter('accessibility.keyboard_navigation_enabled', defaultValue: true);
    if (keyboardNav is! bool) {
      errors.add('accessibility.keyboard_navigation_enabled must be a boolean');
    }

    return errors;
  }

  /// Load default accessibility configurations
  Future<void> _loadDefaultAccessibilityConfigurations() async {
    // Default accessibility settings
    _parameters['accessibility.screen_reader_enabled'] = false;
    _parameters['accessibility.high_contrast_enabled'] = false;
    _parameters['accessibility.font_scale'] = 1.0;
    _parameters['accessibility.keyboard_navigation_enabled'] = true;
    _parameters['accessibility.animation_duration'] = 300; // milliseconds
    _parameters['accessibility.focus_highlight_color'] = '#FF6B35';
    _parameters['accessibility.minimum_touch_target'] = 44; // pixels
    _parameters['accessibility.screen_reader_delay'] = 1000; // milliseconds

    _logger.info('Default accessibility configurations loaded', 'CentralConfig');
  }

  /// Load default FTP configurations
  Future<void> _loadDefaultFTPConfigurations() async {
    // FTP Connection Parameters
    _parameters['ftp.timeout'] = 30;  // Connection timeout in seconds
    _parameters['ftp.max_retries'] = 3;  // Maximum retry attempts
    _parameters['ftp.data_timeout'] = 30;  // Data transfer timeout in seconds
    _parameters['ftp.upload_timeout'] = 300;  // Upload timeout in seconds (5 minutes)
    _parameters['ftp.download_timeout'] = 300;  // Download timeout in seconds (5 minutes)
    _parameters['ftp.retry_delay_base'] = 2;  // Base delay for exponential backoff
    _parameters['ftp.upload_retry_delay_base'] = 3;  // Base delay for upload retries

    // FTP Data Transfer Parameters
    _parameters['ftp.chunk_size'] = 1048576;  // 1MB chunks for resumable uploads
    _parameters['ftp.buffer_size'] = 8192;  // Buffer size for data transfers
    _parameters['ftp.max_connections'] = 10;  // Maximum concurrent connections
    _parameters['ftp.connection_pool_size'] = 5;  // Connection pool size
    _parameters['ftp.keep_alive_interval'] = 60;  // Keep alive ping interval
    _parameters['ftp.socket_timeout'] = 10;  // Socket operation timeout

    // FTP Protocol Parameters
    _parameters['ftp.passive_mode'] = true;  // Use passive mode by default
    _parameters['ftp.auto_reconnect'] = true;  // Auto reconnect on failure
    _parameters['ftp.error_retry_exponential_backoff'] = true;  // Use exponential backoff
    _parameters['ftp.adapter_connection_pooling'] = true;  // Enable connection pooling
    _parameters['ftp.logging_connection_events'] = true;  // Log connection events
    _parameters['ftp.validate_ssl_certificates'] = true;  // SSL certificate validation
    _parameters['ftp.max_file_size'] = 1073741824;  // 1GB max file size limit

    // FTP Advanced Features
    _parameters['ftp.workspace_max_tabs'] = 10;  // Maximum tabs per workspace
    _parameters['ftp.wireless_discovery_port'] = 5353;  // mDNS discovery port
    _parameters['ftp.streaming_buffer_size'] = 65536;  // 64KB streaming buffer
    // AI/LLM Integration Parameters
    _parameters['ai.enabled'] = true;  // Enable AI features
    _parameters['ai.llm_provider'] = 'google';  // google, openai, vertex, or local
    _parameters['ai.api_key'] = '';  // API key for cloud providers
    _parameters['ai.model_name'] = 'gemini-1.5-flash';  // Default model
    _parameters['ai.temperature'] = 0.7;  // Creativity level (0.0-1.0)
    _parameters['ai.max_tokens'] = 2048;  // Maximum response length
    _parameters['ai.timeout'] = 30000;  // API timeout in milliseconds

    // Document Intelligence Parameters
    _parameters['ai.document_analysis.enabled'] = true;  // Enable document analysis
    _parameters['ai.document_analysis.auto_categorize'] = true;  // Auto-categorize files
    _parameters['ai.document_analysis.extract_metadata'] = true;  // Extract metadata
    _parameters['ai.document_analysis.generate_summaries'] = true;  // Generate summaries
    _parameters['ai.document_analysis.confidence_threshold'] = 0.8;  // Minimum confidence

    // Search Enhancement Parameters
    _parameters['ai.search.enabled'] = true;  // Enable AI-enhanced search
    _parameters['ai.search.semantic_search'] = true;  // Use semantic search
    _parameters['ai.search.context_understanding'] = true;  // Understand search context
    _parameters['ai.search.personalization'] = true;  // Personalize search results
    _parameters['ai.search.max_results'] = 50;  // Maximum search results

    // Organization Intelligence Parameters
    _parameters['ai.organization.enabled'] = true;  // Enable smart organization
    _parameters['ai.organization.auto_suggestions'] = true;  // Suggest organization
    _parameters['ai.organization.batch_processing'] = true;  // Process files in batches
    _parameters['ai.organization.learning_enabled'] = true;  // Learn from user preferences

    // Security AI Parameters
    _parameters['ai.security.enabled'] = true;  // Enable AI security features
    _parameters['ai.security.pii_detection'] = true;  // Detect PII in documents
    _parameters['ai.security.anomaly_detection'] = true;  // Detect unusual access
    _parameters['ai.security.content_filtering'] = true;  // Filter inappropriate content

    // Workflow Automation Parameters
    _parameters['ai.workflow.enabled'] = true;  // Enable workflow automation
    _parameters['ai.workflow.task_routing'] = true;  // AI-powered task assignment
    _parameters['ai.workflow.deadline_prediction'] = true;  // Predict task deadlines
    _parameters['ai.workflow.priority_suggestions'] = true;  // Suggest task priorities

    // Natural Language Interface Parameters
    _parameters['ai.nlp.enabled'] = true;  // Enable NLP features
    _parameters['ai.nlp.voice_commands'] = true;  // Voice command processing
    _parameters['ai.nlp.intent_recognition'] = true;  // Understand user intent
    _parameters['ai.nlp.conversation_memory'] = true;  // Remember conversation context

    // Performance and Caching Parameters
    _parameters['ai.cache.enabled'] = true;  // Enable AI result caching
    _parameters['ai.cache.ttl'] = 3600;  // Cache TTL in seconds
    _parameters['ai.cache.max_size'] = 100;  // Maximum cached results
    _parameters['ai.offline_mode'] = true;  // Enable offline AI capabilities

    _logger.info('Advanced AI/LLM configuration parameters loaded', 'CentralConfig');
  }

  /// Validate against schema
  List<String> _validateAgainstSchema(String componentName, Map<String, dynamic> params, Map<String, dynamic> schema) {
    final errors = <String>[];

    // Basic schema validation (can be expanded)
    final requiredFields = schema['required'] as List<String>? ?? [];
    for (final field in requiredFields) {
      if (!params.containsKey(field) || params[field] == null) {
        errors.add('$componentName: Missing required field "$field"');
      }
    }

    // Type validation
    final properties = schema['properties'] as Map<String, dynamic>? ?? {};
    for (final entry in properties.entries) {
      final fieldName = entry.key;
      final fieldSchema = entry.value as Map<String, dynamic>;

      if (params.containsKey(fieldName)) {
        final value = params[fieldName];
        final expectedType = fieldSchema['type'];

        if (expectedType == 'number' && value is! num) {
          errors.add('$componentName: Field "$fieldName" must be a number');
        } else if (expectedType == 'string' && value is! String) {
          errors.add('$componentName: Field "$fieldName" must be a string');
        } else if (expectedType == 'boolean' && value is! bool) {
          errors.add('$componentName: Field "$fieldName" must be a boolean');
        }
      }
    }

    return errors;
  }

  /// Setup hot-reload for configuration changes
  Future<void> _setupHotReload() async {
    // In a real implementation, this would watch configuration files
    // and reload when they change. For now, this is a placeholder.
    _logger.info('Hot-reload setup completed (placeholder)', 'CentralConfig');
  }

  /// Reload configuration from sources
  Future<void> reloadConfiguration() async {
    try {
      _logger.info('Reloading configuration', 'CentralConfig');

      // Clear existing parameters
      _parameters.clear();
      _componentParameters.clear();

      // Reinitialize
      await initialize(enableHotReload: false);

      // Notify listeners of configuration change
      _notifyConfigurationChanged();

      _logger.info('Configuration reloaded successfully', 'CentralConfig');

    } catch (e, stackTrace) {
      _logger.error('Failed to reload configuration', 'CentralConfig', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Notify listeners of configuration changes
  void _notifyConfigurationChanged() {
    // In a real implementation, this would notify all registered components
    // For now, this is a placeholder
    _logger.info('Configuration change notification sent', 'CentralConfig');
  }

  /// Get configuration schema for a component
  Map<String, dynamic>? getComponentSchema(String componentName) {
    return _componentSchemas[componentName];
  }

  /// Register component schema for validation
  void registerComponentSchema(String componentName, Map<String, dynamic> schema) {
    _componentSchemas[componentName] = schema;
    _logger.info('Registered schema for component: $componentName', 'CentralConfig');
  }

  /// Export current configuration (for debugging/backup)
  Map<String, dynamic> exportConfiguration() {
    return {
      'global_parameters': Map.from(_parameters),
      'component_parameters': Map.from(_componentParameters),
      'schemas': Map.from(_componentSchemas),
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  /// Import configuration (for restore)
  Future<void> importConfiguration(Map<String, dynamic> config) async {
    try {
      _parameters.clear();
      _parameters.addAll(config['global_parameters'] as Map<String, dynamic>? ?? {});

      _componentParameters.clear();
      final componentParams = config['component_parameters'] as Map<String, dynamic>? ?? {};
      for (final entry in componentParams.entries) {
        _componentParameters[entry.key] = Map.from(entry.value as Map);
      }

      _componentSchemas.clear();
      final schemas = config['schemas'] as Map<String, dynamic>? ?? {};
      for (final entry in schemas.entries) {
        _componentSchemas[entry.key] = Map.from(entry.value as Map);
      }

      await _validateConfigurations();
      _notifyConfigurationChanged();

      _logger.info('Configuration imported successfully', 'CentralConfig');

    } catch (e, stackTrace) {
      _logger.error('Failed to import configuration', 'CentralConfig', error: e, stackTrace: stackTrace);
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
