import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../core/config/central_parameterized_config.dart';
import '../core/config/component_relationship_manager.dart';
import '../core/config/unified_service_orchestrator.dart';
import '../core/orchestrator/application_orchestrator.dart';
import '../core/registry/service_registry.dart';

/// Configuration Provider
/// 
/// Manages UI state and provides access to central configuration
/// Features: Configuration binding, state management, real-time updates
/// Performance: Optimized state updates, efficient configuration access
/// Architecture: Provider pattern, observer pattern, state management
class ConfigurationProvider extends ChangeNotifier {
  final CentralParameterizedConfig _config;
  final ComponentRelationshipManager _componentManager;
  final UnifiedServiceOrchestrator _serviceOrchestrator;
  final ApplicationOrchestrator _appOrchestrator;
  final ServiceRegistry _serviceRegistry;
  
  // Configuration state
  Map<String, dynamic> _configStats = {};
  Map<String, dynamic> _componentStats = {};
  Map<String, dynamic> _orchestratorStats = {};
  Map<String, dynamic> _appStats = {};
  
  // UI state
  bool _isLoading = false;
  String? _error;
  
  ConfigurationProvider({
    required CentralParameterizedConfig config,
    required ComponentRelationshipManager componentManager,
    required UnifiedServiceOrchestrator serviceOrchestrator,
    required ApplicationOrchestrator appOrchestrator,
    required ServiceRegistry serviceRegistry,
  }) : _config = config,
       _componentManager = componentManager,
       _serviceOrchestrator = serviceOrchestrator,
       _appOrchestrator = appOrchestrator,
       _serviceRegistry = serviceRegistry {
    
    // Setup configuration listeners
    _setupConfigurationListeners();
    
    // Load initial statistics
    _loadStatistics();
  }
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get configStats => Map.unmodifiable(_configStats);
  Map<String, dynamic> get componentStats => Map.unmodifiable(_componentStats);
  Map<String, dynamic> get orchestratorStats => Map.unmodifiable(_orchestratorStats);
  Map<String, dynamic> get appStats => Map.unmodifiable(_appStats);
  
  // Configuration getters
  String get appName => _config.getParameter('app.name', defaultValue: 'iSuite') ?? 'iSuite';
  String get appVersion => _config.getParameter('app.version', defaultValue: '2.0.0') ?? '2.0.0';
  String get appEnvironment => _config.getParameter('app.environment', defaultValue: 'production') ?? 'production';
  bool get isDebugMode => _config.getParameter('app.debug', defaultValue: false) ?? false;
  
  // AI Services configuration
  bool get aiFileOrganizerEnabled => _config.getParameter('ai_services.enable_file_organizer', defaultValue: true) ?? true;
  bool get aiAdvancedSearchEnabled => _config.getParameter('ai_services.enable_advanced_search', defaultValue: true) ?? true;
  bool get aiSmartCategorizerEnabled => _config.getParameter('ai_services.enable_smart_categorizer', defaultValue: true) ?? true;
  bool get aiDuplicateDetectorEnabled => _config.getParameter('ai_services.enable_duplicate_detector', defaultValue: true) ?? true;
  bool get aiRecommendationsEnabled => _config.getParameter('ai_services.enable_recommendations', defaultValue: true) ?? true;
  bool get aiIntegrationEnabled => _config.getParameter('ai_services.enable_integration', defaultValue: true) ?? true;
  int get aiMaxConcurrentTasks => _config.getParameter('ai_services.max_concurrent_tasks', defaultValue: 5) ?? 5;
  int get aiWorkflowTimeout => _config.getParameter('ai_services.workflow_timeout_seconds', defaultValue: 300) ?? 300;
  
  // Network Services configuration
  bool get networkFileSharingEnabled => _config.getParameter('network_services.enable_file_sharing', defaultValue: true) ?? true;
  bool get ftpClientEnabled => _config.getParameter('network_services.enable_ftp_client', defaultValue: true) ?? true;
  bool get wifiDirectEnabled => _config.getParameter('network_services.enable_wifi_direct', defaultValue: true) ?? true;
  bool get p2pEnabled => _config.getParameter('network_services.enable_p2p', defaultValue: true) ?? true;
  bool get webdavEnabled => _config.getParameter('network_services.enable_webdav', defaultValue: true) ?? true;
  bool get discoveryEnabled => _config.getParameter('network_services.enable_discovery', defaultValue: true) ?? true;
  bool get securityEnabled => _config.getParameter('network_services.enable_security', defaultValue: true) ?? true;
  int get networkMaxConcurrentOperations => _config.getParameter('network_services.max_concurrent_operations', defaultValue: 10) ?? 10;
  int get networkConnectionTimeout => _config.getParameter('network_services.connection_timeout_seconds', defaultValue: 30) ?? 30;
  
  // Performance configuration
  bool get cachingEnabled => _config.getParameter('performance.enable_caching', defaultValue: true) ?? true;
  int get cacheSize => _config.getParameter('performance.cache_size_mb', defaultValue: 100) ?? 100;
  bool get parallelProcessingEnabled => _config.getParameter('performance.enable_parallel_processing', defaultValue: true) ?? true;
  int get maxWorkers => _config.getParameter('performance.max_workers', defaultValue: 4) ?? 4;
  int get memoryLimit => _config.getParameter('performance.memory_limit_mb', defaultValue: 512) ?? 512;
  
  // Security configuration
  bool get encryptionEnabled => _config.getParameter('security.enable_encryption', defaultValue: true) ?? true;
  bool get authenticationEnabled => _config.getParameter('security.enable_authentication', defaultValue: true) ?? true;
  bool get accessControlEnabled => _config.getParameter('security.enable_access_control', defaultValue: true) ?? true;
  bool get auditLoggingEnabled => _config.getParameter('security.enable_audit_logging', defaultValue: true) ?? true;
  String get encryptionAlgorithm => _config.getParameter('security.encryption_algorithm', defaultValue: 'AES-256') ?? 'AES-256';
  int get keySize => _config.getParameter('security.key_size', defaultValue: 256) ?? 256;
  int get sessionTimeout => _config.getParameter('security.session_timeout_hours', defaultValue: 8) ?? 8;
  
  // UI configuration
  String get themeMode => _config.getParameter('ui.theme_mode', defaultValue: 'system') ?? 'system';
  bool get darkModeEnabled => _config.getParameter('ui.enable_dark_mode', defaultValue: true) ?? true;
  bool get animationsEnabled => _config.getParameter('ui.enable_animations', defaultValue: true) ?? true;
  String get fontSize => _config.getParameter('ui.font_size', defaultValue: 'medium') ?? 'medium';
  String get language => _config.getParameter('ui.language', defaultValue: 'en') ?? 'en';
  
  // Backend configuration
  String get backendType => _config.getParameter('backend.type', defaultValue: 'pocketbase') ?? 'pocketbase';
  String get backendHost => _config.getParameter('backend.host', defaultValue: 'localhost') ?? 'localhost';
  int get backendPort => _config.getParameter('backend.port', defaultValue: 8090) ?? 8090;
  bool get backendAutoStart => _config.getParameter('backend.auto_start', defaultValue: true) ?? true;
  bool get offlineEnabled => _config.getParameter('backend.enable_offline', defaultValue: true) ?? true;
  
  // Logging configuration
  String get logLevel => _config.getParameter('logging.level', defaultValue: 'info') ?? 'info';
  bool get fileLoggingEnabled => _config.getParameter('logging.enable_file_logging', defaultValue: true) ?? true;
  bool get consoleLoggingEnabled => _config.getParameter('logging.enable_console_logging', defaultValue: true) ?? true;
  int get maxFileSize => _config.getParameter('logging.max_file_size_mb', defaultValue: 10) ?? 10;
  int get retentionDays => _config.getParameter('logging.retention_days', defaultValue: 30) ?? 30;
  
  /// Setup configuration listeners
  void _setupConfigurationListeners() {
    // Listen to configuration changes
    _config.configurationEvents.listen((event) {
      if (event.type == ConfigurationEventType.parameterChanged) {
        _loadStatistics();
        notifyListeners();
      }
    });
    
    // Listen to component events
    _componentManager.componentEvents.listen((event) {
      _loadStatistics();
      notifyListeners();
    });
    
    // Listen to orchestrator events
    _serviceOrchestrator.orchestratorEvents.listen((event) {
      _loadStatistics();
      notifyListeners();
    });
    
    // Listen to application events
    _appOrchestrator.applicationEvents.listen((event) {
      _loadStatistics();
      notifyListeners();
    });
  }
  
  /// Load statistics from all systems
  void _loadStatistics() {
    try {
      _configStats = _config.getConfigurationStatistics();
      _componentStats = _componentManager.getComponentStatistics();
      _orchestratorStats = _serviceOrchestrator.getOrchestratorStatistics();
      _appStats = _appOrchestrator.getApplicationStatistics();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
  }
  
  /// Update configuration value
  Future<bool> updateConfiguration<T>(String key, T value) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final success = await _config.setParameter<T>(key, value);
      
      if (success) {
        _loadStatistics();
      } else {
        _error = 'Failed to update configuration';
      }
      
      _isLoading = false;
      notifyListeners();
      
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Reload configuration
  Future<void> reloadConfiguration() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _config.reloadConfiguration();
      _loadStatistics();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Export configuration
  Future<String> exportConfiguration() async {
    try {
      return await _config.exportConfiguration();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  /// Import configuration
  Future<bool> importConfiguration(String yamlData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final success = await _config.importConfiguration(yamlData);
      
      if (success) {
        _loadStatistics();
      } else {
        _error = 'Failed to import configuration';
      }
      
      _isLoading = false;
      notifyListeners();
      
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Reset to defaults
  Future<void> resetToDefaults() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // This would implement resetting to default values
      // For now, just reload current configuration
      await _config.reloadConfiguration();
      _loadStatistics();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}

/// Configuration Provider instance
final configurationProvider = ChangeNotifierProvider<ConfigurationProvider>((ref) {
  final config = CentralParameterizedConfig.instance;
  final componentManager = ComponentRelationshipManager.instance;
  final serviceOrchestrator = UnifiedServiceOrchestrator.instance;
  final appOrchestrator = ApplicationOrchestrator.instance;
  final serviceRegistry = ServiceRegistry.instance;
  
  return ConfigurationProvider(
    config: config,
    componentManager: componentManager,
    serviceOrchestrator: serviceOrchestrator,
    appOrchestrator: appOrchestrator,
    serviceRegistry: serviceRegistry,
  );
});
