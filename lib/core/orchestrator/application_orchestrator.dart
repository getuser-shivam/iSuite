import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/registry/service_registry.dart';
import '../core/logging/enhanced_logger.dart';
import '../core/config/central_parameterized_config.dart';
import '../core/config/component_relationship_manager.dart';
import '../core/config/unified_service_orchestrator.dart';

/// Application Orchestrator - Top-level Application Management
/// Features: Application lifecycle, service coordination, error handling
/// Performance: Optimized startup, resource management, health monitoring
/// Architecture: Orchestrator pattern, observer pattern, state management
class ApplicationOrchestrator {
  static ApplicationOrchestrator? _instance;
  static ApplicationOrchestrator get instance => _instance ??= ApplicationOrchestrator._internal();
  ApplicationOrchestrator._internal();

  // Application state
  ApplicationState _state = ApplicationState.uninitialized;
  String? _startupError;
  final List<String> _startupSteps = [];
  final List<String> _completedSteps = [];
  DateTime? _startTime;
  DateTime? _initializedTime;
  
  // Core managers
  late final ServiceRegistry _serviceRegistry;
  late final CentralParameterizedConfig _config;
  late final ComponentRelationshipManager _componentManager;
  late final UnifiedServiceOrchestrator _serviceOrchestrator;
  
  // Event streams
  final StreamController<ApplicationEvent> _eventController = 
      StreamController<ApplicationEvent>.broadcast();
  
  Stream<ApplicationEvent> get applicationEvents => _eventController.stream;

  /// Initialize the application
  Future<void> initialize() async {
    try {
      _startTime = DateTime.now();
      _state = ApplicationState.initializing;
      
      _emitEvent(ApplicationEventType.initializing, 'Application initialization started');
      
      // Step 1: Initialize core infrastructure
      await _initializeInfrastructure();
      
      // Step 2: Register and initialize services
      await _initializeServices();
      
      // Step 3: Setup event coordination
      await _setupEventCoordination();
      
      // Step 4: Setup health monitoring
      await _setupHealthMonitoring();
      
      // Step 5: Finalize application
      await _finalizeApplication();
      
      _initializedTime = DateTime.now();
      _state = ApplicationState.initialized;
      
      _emitEvent(ApplicationEventType.initialized, 'Application initialized successfully');
      
      EnhancedLogger.instance.info('Application initialized in ${_getInitializationDuration().inMilliseconds}ms');
    } catch (e, stackTrace) {
      _startupError = e.toString();
      _state = ApplicationState.error;
      
      _emitEvent(ApplicationEventType.error, 'Application initialization failed', error: e.toString());
      
      EnhancedLogger.instance.error('Failed to initialize application', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Initialize core infrastructure
  Future<void> _initializeInfrastructure() async {
    _addStartupStep('Initializing core infrastructure...');
    
    // Initialize Enhanced Logger first
    await EnhancedLogger.instance.initialize();
    _addCompletedStep('Enhanced Logger initialized');
    
    // Initialize Central Parameterized Config
    _config = CentralParameterizedConfig.instance;
    await _config.initialize();
    _addCompletedStep('Central Parameterized Config initialized');
    
    // Initialize Component Relationship Manager
    _componentManager = ComponentRelationshipManager.instance;
    await _componentManager.initialize();
    _addCompletedStep('Component Relationship Manager initialized');
    
    // Initialize Unified Service Orchestrator
    _serviceOrchestrator = UnifiedServiceOrchestrator.instance;
    await _serviceOrchestrator.initialize();
    _addCompletedStep('Unified Service Orchestrator initialized');
    
    // Initialize Service Registry
    _serviceRegistry = ServiceRegistry.instance;
    await _serviceRegistry.registerServices();
    _addCompletedStep('Service Registry initialized');
  }

  /// Initialize services
  Future<void> _initializeServices() async {
    _addStartupStep('Initializing services...');
    
    await _serviceRegistry.initializeServices();
    
    _addCompletedStep('All services initialized');
  }

  /// Setup event coordination
  Future<void> _setupEventCoordination() async {
    _addStartupStep('Setting up event coordination...');
    
    // Listen to configuration events
    _config.configurationEvents.listen((event) {
      _handleConfigurationEvent(event);
    });
    
    // Listen to component events
    _componentManager.componentEvents.listen((event) {
      _handleComponentEvent(event);
    });
    
    // Listen to service events
    _serviceRegistry.serviceEvents.listen((event) {
      _handleServiceEvent(event);
    });
    
    // Listen to orchestrator events
    _serviceOrchestrator.orchestratorEvents.listen((event) {
      _handleOrchestratorEvent(event);
    });
    
    _addCompletedStep('Event coordination setup completed');
  }

  /// Setup health monitoring
  Future<void> _setupHealthMonitoring() async {
    _addStartupStep('Setting up health monitoring...');
    
    // Setup periodic health checks
    Timer.periodic(Duration(minutes: 5), (_) {
      _performHealthCheck();
    });
    
    _addCompletedStep('Health monitoring setup completed');
  }

  /// Finalize application
  Future<void> _finalizeApplication() async {
    _addStartupStep('Finalizing application...');
    
    // Apply initial configuration
    await _applyInitialConfiguration();
    
    // Setup performance monitoring
    await _setupPerformanceMonitoring();
    
    // Validate system integrity
    await _validateSystemIntegrity();
    
    _addCompletedStep('Application finalized');
  }

  /// Handle configuration events
  void _handleConfigurationEvent(dynamic event) {
    if (kDebugMode) {
      print('Configuration Event: ${event.type}');
    }
    
    _emitEvent(ApplicationEventType.configurationChanged, 'Configuration changed', data: event);
  }

  /// Handle component events
  void _handleComponentEvent(dynamic event) {
    if (kDebugMode) {
      print('Component Event: ${event.type} - ${event.componentName}');
    }
    
    _emitEvent(ApplicationEventType.componentStateChanged, 'Component state changed', data: event);
  }

  /// Handle service events
  void _handleServiceEvent(ServiceEvent event) {
    if (kDebugMode) {
      print('Service Event: ${event.type} - ${event.serviceName}');
    }
    
    _emitEvent(ApplicationEventType.serviceStateChanged, 'Service state changed', data: event);
  }

  /// Handle orchestrator events
  void _handleOrchestratorEvent(dynamic event) {
    if (kDebugMode) {
      print('Orchestrator Event: ${event.type} - ${event.serviceName}');
    }
    
    _emitEvent(ApplicationEventType.orchestratorEvent, 'Orchestrator event', data: event);
  }

  /// Apply initial configuration
  Future<void> _applyInitialConfiguration() async {
    // Apply UI configuration
    final themeMode = _config.getParameter('ui.theme_mode', defaultValue: 'system');
    final enableDarkMode = _config.getParameter('ui.enable_dark_mode', defaultValue: true);
    
    // Apply performance configuration
    final enableCaching = _config.getParameter('performance.enable_caching', defaultValue: true);
    final enableParallelProcessing = _config.getParameter('performance.enable_parallel_processing', defaultValue: true);
    
    // Apply security configuration
    final enableEncryption = _config.getParameter('security.enable_encryption', defaultValue: true);
    final enableAuthentication = _config.getParameter('security.enable_authentication', defaultValue: true);
    
    _emitEvent(ApplicationEventType.configurationApplied, 'Initial configuration applied');
  }

  /// Setup performance monitoring
  Future<void> _setupPerformanceMonitoring() async {
    // Setup performance metrics collection
    Timer.periodic(Duration(seconds: 10), (_) {
      _collectPerformanceMetrics();
    });
    
    _emitEvent(ApplicationEventType.performanceMonitoringSetup, 'Performance monitoring setup');
  }

  /// Validate system integrity
  Future<void> _validateSystemIntegrity() async {
    // Validate all services are healthy
    final serviceStats = _serviceRegistry.getServiceStatistics();
    final initializedServices = serviceStats['initialized_services'] as int;
    final totalServices = serviceStats['total_services'] as int;
    
    if (initializedServices != totalServices) {
      throw Exception('System integrity validation failed: Not all services initialized');
    }
    
    // Validate component relationships
    final componentStats = _componentManager.getComponentStatistics();
    final initializedComponents = componentStats['initialized_components'] as int;
    final totalComponents = componentStats['total_components'] as int;
    
    if (initializedComponents != totalComponents) {
      throw Exception('System integrity validation failed: Not all components initialized');
    }
    
    _emitEvent(ApplicationEventType.systemIntegrityValidated, 'System integrity validated');
  }

  /// Perform health check
  void _performHealthCheck() {
    try {
      final serviceStats = _serviceRegistry.getServiceStatistics();
      final componentStats = _componentManager.getComponentStatistics();
      final orchestratorStats = _serviceOrchestrator.getOrchestratorStatistics();
      
      final isHealthy = _isSystemHealthy(serviceStats, componentStats, orchestratorStats);
      
      _emitEvent(
        isHealthy ? ApplicationEventType.healthCheckPassed : ApplicationEventType.healthCheckFailed,
        'Health check completed',
        data: {
          'services': serviceStats,
          'components': componentStats,
          'orchestrator': orchestratorStats,
        },
      );
    } catch (e) {
      _emitEvent(ApplicationEventType.healthCheckFailed, 'Health check failed', error: e.toString());
    }
  }

  /// Collect performance metrics
  void _collectPerformanceMetrics() {
    try {
      final metrics = {
        'timestamp': DateTime.now().toIso8601String(),
        'uptime': _getUptime().inMilliseconds,
        'memory_usage': _getMemoryUsage(),
        'service_stats': _serviceRegistry.getServiceStatistics(),
        'component_stats': _componentManager.getComponentStatistics(),
        'orchestrator_stats': _serviceOrchestrator.getOrchestratorStatistics(),
      };
      
      _emitEvent(ApplicationEventType.performanceMetricsCollected, 'Performance metrics collected', data: metrics);
    } catch (e) {
      EnhancedLogger.instance.error('Failed to collect performance metrics', error: e);
    }
  }

  /// Check if system is healthy
  bool _isSystemHealthy(Map<String, dynamic> serviceStats, Map<String, dynamic> componentStats, Map<String, dynamic> orchestratorStats) {
    // Check service health
    final initializedServices = serviceStats['initialized_services'] as int;
    final totalServices = serviceStats['total_services'] as int;
    
    if (initializedServices < totalServices * 0.9) { // Allow 10% tolerance
      return false;
    }
    
    // Check component health
    final initializedComponents = componentStats['initialized_components'] as int;
    final totalComponents = componentStats['total_components'] as int;
    
    if (initializedComponents < totalComponents * 0.9) { // Allow 10% tolerance
      return false;
    }
    
    // Check orchestrator health
    final initializedOrchestratorServices = orchestratorStats['initialized_services'] as int;
    final totalOrchestratorServices = orchestratorStats['total_services'] as int;
    
    if (initializedOrchestratorServices < totalOrchestratorServices * 0.9) { // Allow 10% tolerance
      return false;
    }
    
    return true;
  }

  /// Get application state
  ApplicationState get state => _state;

  /// Get startup error
  String? get startupError => _startupError;

  /// Get startup steps
  List<String> get startupSteps => List.unmodifiable(_startupSteps);

  /// Get completed steps
  List<String> get completedSteps => List.unmodifiable(_completedSteps);

  /// Get initialization duration
  Duration getInitializationDuration() {
    return _getInitializationDuration();
  }

  /// Get uptime
  Duration getUptime() {
    return _getUptime();
  }

  /// Get application statistics
  Map<String, dynamic> getApplicationStatistics() {
    return {
      'state': _state.toString(),
      'startup_error': _startupError,
      'initialization_duration': _getInitializationDuration().inMilliseconds,
      'uptime': _getUptime().inMilliseconds,
      'startup_steps': _startupSteps.length,
      'completed_steps': _completedSteps.length,
      'service_registry_stats': _serviceRegistry.getServiceStatistics(),
      'component_manager_stats': _componentManager.getComponentStatistics(),
      'service_orchestrator_stats': _serviceOrchestrator.getOrchestratorStatistics(),
      'config_stats': _config.getConfigurationStatistics(),
    };
  }

  /// Restart application
  Future<bool> restart() async {
    try {
      _emitEvent(ApplicationEventType.restarting, 'Application restarting');
      
      // Dispose current state
      await dispose();
      
      // Reset state
      _state = ApplicationState.uninitialized;
      _startupError = null;
      _startupSteps.clear();
      _completedSteps.clear();
      _startTime = null;
      _initializedTime = null;
      
      // Reinitialize
      await initialize();
      
      _emitEvent(ApplicationEventType.restarted, 'Application restarted successfully');
      
      return true;
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to restart application', 
        error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Dispose application
  Future<void> dispose() async {
    try {
      _emitEvent(ApplicationEventType.disposing, 'Application disposing');
      
      // Dispose services
      await _serviceRegistry.dispose();
      
      // Dispose orchestrator
      await _serviceOrchestrator.dispose();
      
      // Dispose component manager
      await _componentManager.dispose();
      
      // Close event controller
      _eventController.close();
      
      _state = ApplicationState.disposed;
      
      EnhancedLogger.instance.info('Application disposed');
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to dispose application', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// Helper methods
  void _addStartupStep(String step) {
    _startupSteps.add(step);
    _emitEvent(ApplicationEventType.startupStepAdded, step);
  }

  void _addCompletedStep(String step) {
    _completedSteps.add(step);
    _emitEvent(ApplicationEventType.startupStepCompleted, step);
  }

  void _emitEvent(ApplicationEventType type, String message, {dynamic data, String? error}) {
    _eventController.add(ApplicationEvent(
      type: type,
      message: message,
      data: data,
      error: error,
    ));
  }

  Duration _getInitializationDuration() {
    if (_startTime != null && _initializedTime != null) {
      return _initializedTime!.difference(_startTime!);
    }
    return Duration.zero;
  }

  Duration _getUptime() {
    if (_startTime != null) {
      return DateTime.now().difference(_startTime!);
    }
    return Duration.zero;
  }

  double _getMemoryUsage() {
    // This would implement actual memory usage calculation
    // For now, return a placeholder value
    return 0.0;
  }
}

/// Application event
class ApplicationEvent {
  final ApplicationEventType type;
  final String message;
  final dynamic data;
  final String? error;
  final DateTime timestamp;
  
  ApplicationEvent({
    required this.type,
    required this.message,
    this.data,
    this.error,
  }) : timestamp = DateTime.now();
}

/// Application states
enum ApplicationState {
  uninitialized,
  initializing,
  initialized,
  error,
  restarting,
  disposed,
}

/// Application event types
enum ApplicationEventType {
  initializing,
  initialized,
  error,
  restarting,
  restarted,
  disposing,
  disposed,
  startupStepAdded,
  startupStepCompleted,
  configurationChanged,
  componentStateChanged,
  serviceStateChanged,
  orchestratorEvent,
  configurationApplied,
  performanceMonitoringSetup,
  systemIntegrityValidated,
  healthCheckPassed,
  healthCheckFailed,
  performanceMetricsCollected,
}

/// Global application orchestrator getter for easy access
ApplicationOrchestrator getApplicationOrchestrator() {
  return ApplicationOrchestrator.instance;
}

/// Global application state getter for easy access
ApplicationState getApplicationState() {
  return ApplicationOrchestrator.instance.state;
}

/// Global application statistics getter for easy access
Map<String, dynamic> getApplicationStatistics() {
  return ApplicationOrchestrator.instance.getApplicationStatistics();
}
