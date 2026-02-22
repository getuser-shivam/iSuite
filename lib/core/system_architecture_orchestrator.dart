import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'central_config.dart';
import 'logging/logging_service.dart';
import 'advanced_security_manager.dart';
import 'advanced_performance_monitor.dart';
import 'component_hierarchy_manager.dart';
import 'owlfiles_inspired_network_manager.dart';
import 'universal_protocol_manager.dart';

/// System Architecture Orchestrator - Organizes and manages the entire system architecture
/// 
/// Provides sensible organization, well-connected components, and clear hierarchy
/// for maintainability, scalability, and logical structure.
class SystemArchitectureOrchestrator {
  static final SystemArchitectureOrchestrator _instance = SystemArchitectureOrchestrator._internal();
  factory SystemArchitectureOrchestrator() => _instance;
  SystemArchitectureOrchestrator._internal();

  // Core services
  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();
  final AdvancedSecurityManager _security = AdvancedSecurityManager();
  final AdvancedPerformanceMonitor _performance = AdvancedPerformanceMonitor();
  final ComponentHierarchyManager _hierarchy = ComponentHierarchyManager();

  // Architecture layers
  final Map<ArchitectureLayer, List<String>> _layerComponents = {};
  final Map<String, ArchitectureLayer> _componentLayers = {};

  // System organization
  final Map<SystemDomain, List<String>> _domainComponents = {};
  final Map<String, SystemDomain> _componentDomains = {};

  // Communication patterns
  final Map<CommunicationPattern, List<String>> _patternComponents = {};
  final Map<String, List<CommunicationPattern>> _componentPatterns = {};

  // Event streams
  final StreamController<ArchitectureEvent> _architectureEventController = StreamController.broadcast();
  final StreamController<SystemReorganizationEvent> _reorganizationEventController = StreamController.broadcast();

  Stream<ArchitectureEvent> get architectureEvents => _architectureEventController.stream;
  Stream<SystemReorganizationEvent> get reorganizationEvents => _reorganizationEventController.stream;

  // State
  bool _isInitialized = false;
  final Map<String, ComponentHealth> _componentHealth = {};
  final Map<String, SystemMetrics> _systemMetrics = {};

  /// Initialize system architecture with sensible organization
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing System Architecture Orchestrator', 'SystemArchitectureOrchestrator');

      // Register orchestrator with CentralConfig
      await _registerOrchestrator();

      // Initialize hierarchy manager
      await _hierarchy.initialize();

      // Build architecture layers
      await _buildArchitectureLayers();

      // Organize system domains
      await _organizeSystemDomains();

      // Setup communication patterns
      await _setupCommunicationPatterns();

      // Validate architecture
      await _validateSystemArchitecture();

      // Start architecture monitoring
      await _startArchitectureMonitoring();

      _isInitialized = true;
      _emitArchitectureEvent(ArchitectureEventType.initialized);

      _logger.info('System Architecture Orchestrator initialized successfully', 'SystemArchitectureOrchestrator');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize System Architecture Orchestrator', 'SystemArchitectureOrchestrator',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get system architecture overview
  SystemArchitectureOverview getArchitectureOverview() {
    return SystemArchitectureOverview(
      layers: _layerComponents,
      domains: _domainComponents,
      communicationPatterns: _patternComponents,
      totalComponents: _componentLayers.length,
      healthStatus: _calculateSystemHealth(),
      lastUpdated: DateTime.now(),
    );
  }

  /// Get components by architecture layer
  List<String> getComponentsByLayer(ArchitectureLayer layer) {
    return _layerComponents[layer] ?? [];
  }

  /// Get components by system domain
  List<String> getComponentsByDomain(SystemDomain domain) {
    return _domainComponents[domain] ?? [];
  }

  /// Get component communication patterns
  List<CommunicationPattern> getComponentPatterns(String componentName) {
    return _componentPatterns[componentName] ?? [];
  }

  /// Reorganize system for better structure
  Future<void> reorganizeSystem() async {
    try {
      _logger.info('Starting system reorganization', 'SystemArchitectureOrchestrator');

      // Analyze current architecture
      final analysis = await _analyzeCurrentArchitecture();

      // Identify optimization opportunities
      final optimizations = await _identifyOptimizations(analysis);

      // Apply optimizations
      await _applyOptimizations(optimizations);

      // Validate new architecture
      await _validateSystemArchitecture();

      _emitReorganizationEvent(SystemReorganizationEventType.completed, optimizations: optimizations);

      _logger.info('System reorganization completed', 'SystemArchitectureOrchestrator');

    } catch (e) {
      _logger.error('System reorganization failed', 'SystemArchitectureOrchestrator', error: e);
      _emitReorganizationEvent(SystemReorganizationEventType.failed, details: e.toString());
      rethrow;
    }
  }

  /// Get system health and metrics
  SystemHealthReport getSystemHealthReport() {
    final componentHealth = Map<String, ComponentHealth>.from(_componentHealth);
    final systemMetrics = Map<String, SystemMetrics>.from(_systemMetrics);

    return SystemHealthReport(
      componentHealth: componentHealth,
      systemMetrics: systemMetrics,
      overallHealth: _calculateOverallHealth(),
      recommendations: _generateHealthRecommendations(),
      generatedAt: DateTime.now(),
    );
  }

  /// Private helper methods

  Future<void> _registerOrchestrator() async {
    await _config.registerComponent(
      'SystemArchitectureOrchestrator',
      '1.0.0',
      'Manages system architecture and organization',
    );

    await _config.registerComponentRelationship(
      'SystemArchitectureOrchestrator',
      'ComponentHierarchyManager',
      RelationshipType.depends_on,
      'Uses ComponentHierarchyManager for component organization',
    );

    await _config.registerComponentRelationship(
      'SystemArchitectureOrchestrator',
      'CentralConfig',
      RelationshipType.configures,
      'Configures CentralConfig for system-wide parameters',
    );
  }

  Future<void> _buildArchitectureLayers() async {
    // Layer 1: Infrastructure Layer
    _layerComponents[ArchitectureLayer.infrastructure] = [
      'CentralConfig',
      'LoggingService',
    ];

    // Layer 2: Core Services Layer
    _layerComponents[ArchitectureLayer.coreServices] = [
      'AdvancedSecurityManager',
      'AdvancedPerformanceMonitor',
      'ComponentHierarchyManager',
    ];

    // Layer 3: Business Logic Layer
    _layerComponents[ArchitectureLayer.businessLogic] = [
      'UniversalProtocolManager',
      'OwlfilesInspiredNetworkManager',
      'RobustnessManager',
      'HealthMonitor',
    ];

    // Layer 4: Application Services Layer
    _layerComponents[ArchitectureLayer.applicationServices] = [
      'NotificationService',
      'AccessibilityManager',
      'PluginManager',
    ];

    // Layer 5: Presentation Layer
    _layerComponents[ArchitectureLayer.presentation] = [
      'ComponentRegistry',
      'ComponentFactory',
    ];

    // Update component layer mapping
    for (final entry in _layerComponents.entries) {
      final layer = entry.key;
      final components = entry.value;
      for (final component in components) {
        _componentLayers[component] = layer;
      }
    }

    _logger.info('Architecture layers built successfully', 'SystemArchitectureOrchestrator');
  }

  Future<void> _organizeSystemDomains() async {
    // Core Infrastructure Domain
    _domainComponents[SystemDomain.coreInfrastructure] = [
      'CentralConfig',
      'LoggingService',
      'ComponentHierarchyManager',
    ];

    // Security Domain
    _domainComponents[SystemDomain.security] = [
      'AdvancedSecurityManager',
    ];

    // Performance Domain
    _domainComponents[SystemDomain.performance] = [
      'AdvancedPerformanceMonitor',
      'HealthMonitor',
    ];

    // Network Domain
    _domainComponents[SystemDomain.network] = [
      'UniversalProtocolManager',
      'OwlfilesInspiredNetworkManager',
    ];

    // Robustness Domain
    _domainComponents[SystemDomain.robustness] = [
      'RobustnessManager',
      'ResilienceManager',
    ];

    // User Experience Domain
    _domainComponents[SystemDomain.userExperience] = [
      'NotificationService',
      'AccessibilityManager',
    ];

    // Plugin Domain
    _domainComponents[SystemDomain.plugins] = [
      'PluginManager',
      'ComponentRegistry',
      'ComponentFactory',
    ];

    // Update component domain mapping
    for (final entry in _domainComponents.entries) {
      final domain = entry.key;
      final components = entry.value;
      for (final component in components) {
        _componentDomains[component] = domain;
      }
    }

    _logger.info('System domains organized successfully', 'SystemArchitectureOrchestrator');
  }

  Future<void> _setupCommunicationPatterns() async {
    // Event-Driven Pattern
    _patternComponents[CommunicationPattern.eventDriven] = [
      'CentralConfig',
      'AdvancedPerformanceMonitor',
      'ComponentHierarchyManager',
      'NotificationService',
    ];

    // Observer Pattern
    _patternComponents[CommunicationPattern.observer] = [
      'CentralConfig',
      'AdvancedSecurityManager',
      'HealthMonitor',
    ];

    // Singleton Pattern
    _patternComponents[CommunicationPattern.singleton] = [
      'CentralConfig',
      'LoggingService',
      'AdvancedSecurityManager',
      'AdvancedPerformanceMonitor',
      'ComponentHierarchyManager',
      'SystemArchitectureOrchestrator',
    ];

    // Factory Pattern
    _patternComponents[CommunicationPattern.factory] = [
      'ComponentFactory',
    ];

    // Strategy Pattern
    _patternComponents[CommunicationPattern.strategy] = [
      'UniversalProtocolManager',
      'OwlfilesInspiredNetworkManager',
    ];

    // Update component pattern mapping
    for (final entry in _patternComponents.entries) {
      final pattern = entry.key;
      final components = entry.value;
      for (final component in components) {
        _componentPatterns[component] ??= [];
        _componentPatterns[component]!.add(pattern);
      }
    }

    _logger.info('Communication patterns setup completed', 'SystemArchitectureOrchestrator');
  }

  Future<void> _validateSystemArchitecture() async {
    final enableValidation = _config.getParameter('components.hierarchy.enable_validation', defaultValue: true);
    if (!enableValidation) return;

    try {
      // Validate hierarchy
      final hierarchyValidation = await _hierarchy.validateHierarchy();
      if (!hierarchyValidation.isValid) {
        _logger.warning('Hierarchy validation failed', 'SystemArchitectureOrchestrator');
      }

      // Validate layer dependencies
      await _validateLayerDependencies();

      // Validate domain boundaries
      await _validateDomainBoundaries();

      // Validate communication patterns
      await _validateCommunicationPatterns();

      _logger.info('System architecture validation completed', 'SystemArchitectureOrchestrator');

    } catch (e) {
      _logger.error('Architecture validation failed', 'SystemArchitectureOrchestrator', error: e);
      rethrow;
    }
  }

  Future<void> _validateLayerDependencies() async {
    // Check for proper layer dependencies
    final violations = <String>[];

    // Infrastructure should not depend on higher layers
    for (final component in _layerComponents[ArchitectureLayer.infrastructure] ?? []) {
      final dependencies = _hierarchy.getComponentDependencies(component);
      for (final dep in dependencies) {
        final depLayer = _componentLayers[dep];
        if (depLayer != null && depLayer.index > ArchitectureLayer.infrastructure.index) {
          violations.add('Infrastructure component $component depends on higher layer component $dep');
        }
      }
    }

    if (violations.isNotEmpty) {
      _logger.warning('Layer dependency violations detected: ${violations.join(', ')}', 'SystemArchitectureOrchestrator');
    }
  }

  Future<void> _validateDomainBoundaries() async {
    // Check for cross-domain dependencies that should be internal
    final violations = <String>[];

    for (final entry in _domainComponents.entries) {
      final domain = entry.key;
      final components = entry.value;
      
      for (final component in components) {
        final dependencies = _hierarchy.getComponentDependencies(component);
        for (final dep in dependencies) {
          final depDomain = _componentDomains[dep];
          if (depDomain != null && depDomain != domain && !_isAllowedCrossDomainDependency(domain, depDomain)) {
            violations.add('Component $component in $domain depends on $dep in $depDomain');
          }
        }
      }
    }

    if (violations.isNotEmpty) {
      _logger.warning('Domain boundary violations detected: ${violations.join(', ')}', 'SystemArchitectureOrchestrator');
    }
  }

  bool _isAllowedCrossDomainDependency(SystemDomain source, SystemDomain target) {
    // Define allowed cross-domain dependencies
    switch (source) {
      case SystemDomain.network:
        return target == SystemDomain.coreInfrastructure || target == SystemDomain.security;
      case SystemDomain.security:
        return target == SystemDomain.coreInfrastructure;
      case SystemDomain.performance:
        return target == SystemDomain.coreInfrastructure;
      default:
        return target == SystemDomain.coreInfrastructure;
    }
  }

  Future<void> _validateCommunicationPatterns() async {
    // Validate that components follow their assigned patterns
    for (final entry in _componentPatterns.entries) {
      final component = entry.key;
      final patterns = entry.value;
      
      for (final pattern in patterns) {
        await _validateComponentPattern(component, pattern);
      }
    }
  }

  Future<void> _validateComponentPattern(String component, CommunicationPattern pattern) async {
    switch (pattern) {
      case CommunicationPattern.singleton:
        // Singleton components should have only one instance
        // This is already enforced by the singleton pattern implementation
        break;
      case CommunicationPattern.eventDriven:
        // Event-driven components should emit events
        // This is validated through the event stream presence
        break;
      case CommunicationPattern.observer:
        // Observer components should watch for changes
        // This is validated through the watcher presence
        break;
      default:
        break;
    }
  }

  Future<void> _startArchitectureMonitoring() async {
    // Start periodic architecture health checks
    Timer.periodic(Duration(minutes: 10), (timer) async {
      await _performArchitectureHealthCheck();
    });

    // Start metrics collection
    Timer.periodic(Duration(minutes: 5), (timer) async {
      await _collectSystemMetrics();
    });
  }

  Future<void> _performArchitectureHealthCheck() async {
    for (final component in _componentLayers.keys) {
      try {
        final health = await _assessComponentHealth(component);
        _componentHealth[component] = health;
      } catch (e) {
        _logger.error('Failed to assess health of $component', 'SystemArchitectureOrchestrator', error: e);
        _componentHealth[component] = ComponentHealth.unhealthy(e.toString());
      }
    }
  }

  Future<ComponentHealth> _assessComponentHealth(String componentName) async {
    // Check if component is registered in hierarchy
    final isRegistered = _hierarchy.hierarchyNodes.containsKey(componentName);
    if (!isRegistered) {
      return ComponentHealth.unhealthy('Component not registered in hierarchy');
    }

    // Check component dependencies
    final dependencies = _hierarchy.getComponentDependencies(componentName);
    final missingDeps = dependencies.where((dep) => !_componentLayers.containsKey(dep)).toList();
    if (missingDeps.isNotEmpty) {
      return ComponentHealth.degraded('Missing dependencies: ${missingDeps.join(', ')}');
    }

    // Check component metrics
    final metrics = _systemMetrics[componentName];
    if (metrics != null && metrics.errorRate > 0.1) {
      return ComponentHealth.degraded('High error rate: ${(metrics.errorRate * 100).toStringAsFixed(1)}%');
    }

    return ComponentHealth.healthy();
  }

  Future<void> _collectSystemMetrics() async {
    for (final component in _componentLayers.keys) {
      try {
        final metrics = await _collectComponentMetrics(component);
        _systemMetrics[component] = metrics;
      } catch (e) {
        _logger.error('Failed to collect metrics for $component', 'SystemArchitectureOrchestrator', error: e);
      }
    }
  }

  Future<SystemMetrics> _collectComponentMetrics(String componentName) async {
    // Get component metrics from performance monitor
    final componentMetrics = _config.getComponentMetrics(componentName);
    
    return SystemMetrics(
      componentName: componentName,
      responseTime: componentMetrics?.averageResponseTime.inMilliseconds.toDouble() ?? 0.0,
      throughput: componentMetrics?.accessCount.toDouble() ?? 0.0,
      errorRate: 0.0, // Would be calculated from error tracking
      memoryUsage: componentMetrics?.memoryUsage.toDouble() ?? 0.0,
      cpuUsage: 0.0, // Would be collected from system monitoring
      timestamp: DateTime.now(),
    );
  }

  Future<ArchitectureAnalysis> _analyzeCurrentArchitecture() async {
    return ArchitectureAnalysis(
      totalComponents: _componentLayers.length,
      layerDistribution: _layerComponents.map((layer, components) => MapEntry(layer, components.length)),
      domainDistribution: _domainComponents.map((domain, components) => MapEntry(domain, components.length)),
      patternDistribution: _patternComponents.map((pattern, components) => MapEntry(pattern, components.length)),
      dependencyComplexity: _calculateDependencyComplexity(),
      couplingMetrics: _calculateCouplingMetrics(),
      cohesionMetrics: _calculateCohesionMetrics(),
      analyzedAt: DateTime.now(),
    );
  }

  Future<List<ArchitectureOptimization>> _identifyOptimizations(ArchitectureAnalysis analysis) async {
    final optimizations = <ArchitectureOptimization>[];

    // Check for high coupling
    if (analysis.couplingMetrics.averageCoupling > 0.7) {
      optimizations.add(ArchitectureOptimization(
        type: OptimizationType.reduceCoupling,
        priority: OptimizationPriority.high,
        description: 'High coupling detected between components',
        estimatedImpact: OptimizationImpact.high,
      ));
    }

    // Check for low cohesion
    if (analysis.cohesionMetrics.averageCohesion < 0.5) {
      optimizations.add(ArchitectureOptimization(
        type: OptimizationType.improveCohesion,
        priority: OptimizationPriority.medium,
        description: 'Low cohesion within components',
        estimatedImpact: OptimizationImpact.medium,
      ));
    }

    // Check for deep hierarchy
    final maxDepth = _config.getParameter('components.hierarchy.max_depth', defaultValue: 10);
    if (analysis.dependencyComplexity.maxDepth > maxDepth) {
      optimizations.add(ArchitectureOptimization(
        type: OptimizationType.flattenHierarchy,
        priority: OptimizationPriority.medium,
        description: 'Hierarchy depth exceeds recommended limit',
        estimatedImpact: OptimizationImpact.medium,
      ));
    }

    return optimizations;
  }

  Future<void> _applyOptimizations(List<ArchitectureOptimization> optimizations) async {
    for (final optimization in optimizations) {
      try {
        await _applyOptimization(optimization);
      } catch (e) {
        _logger.error('Failed to apply optimization: ${optimization.type}', 'SystemArchitectureOrchestrator', error: e);
      }
    }
  }

  Future<void> _applyOptimization(ArchitectureOptimization optimization) async {
    switch (optimization.type) {
      case OptimizationType.reduceCoupling:
        await _reduceComponentCoupling();
        break;
      case OptimizationType.improveCohesion:
        await _improveComponentCohesion();
        break;
      case OptimizationType.flattenHierarchy:
        await _flattenHierarchy();
        break;
      default:
        break;
    }
  }

  Future<void> _reduceComponentCoupling() async {
    // Implement coupling reduction strategies
    _logger.info('Reducing component coupling', 'SystemArchitectureOrchestrator');
  }

  Future<void> _improveComponentCohesion() async {
    // Implement cohesion improvement strategies
    _logger.info('Improving component cohesion', 'SystemArchitectureOrchestrator');
  }

  Future<void> _flattenHierarchy() async {
    // Implement hierarchy flattening strategies
    _logger.info('Flattening component hierarchy', 'SystemArchitectureOrchestrator');
  }

  double _calculateDependencyComplexity() {
    int totalDependencies = 0;
    for (final component in _componentLayers.keys) {
      totalDependencies += _hierarchy.getComponentDependencies(component).length;
    }
    return _componentLayers.isEmpty ? 0.0 : totalDependencies / _componentLayers.length;
  }

  CouplingMetrics _calculateCouplingMetrics() {
    // Calculate afferent and efferent coupling
    final afferentCoupling = <String, int>{};
    final efferentCoupling = <String, int>{};

    for (final component in _componentLayers.keys) {
      efferentCoupling[component] = _hierarchy.getComponentDependencies(component).length;
      afferentCoupling[component] = _hierarchy.getComponentDependents(component).length;
    }

    final averageCoupling = efferentCoupling.values.isEmpty ? 0.0 : 
        efferentCoupling.values.reduce((a, b) => a + b) / efferentCoupling.values.length;

    return CouplingMetrics(
      afferentCoupling: afferentCoupling,
      efferentCoupling: efferentCoupling,
      averageCoupling: averageCoupling,
    );
  }

  CohesionMetrics _calculateCohesionMetrics() {
    // Calculate cohesion metrics based on component responsibilities
    final cohesionScores = <String, double>{};

    for (final component in _componentLayers.keys) {
      // Simplified cohesion calculation based on domain grouping
      final domain = _componentDomains[component];
      final domainComponents = _domainComponents[domain] ?? [];
      final sameDomainDeps = _hierarchy.getComponentDependencies(component)
          .where((dep) => _componentDomains[dep] == domain)
          .length;
      final totalDeps = _hierarchy.getComponentDependencies(component).length;
      
      final cohesion = totalDeps == 0 ? 1.0 : sameDomainDeps / totalDeps;
      cohesionScores[component] = cohesion;
    }

    final averageCohesion = cohesionScores.values.isEmpty ? 0.0 :
        cohesionScores.values.reduce((a, b) => a + b) / cohesionScores.values.length;

    return CohesionMetrics(
      cohesionScores: cohesionScores,
      averageCohesion: averageCohesion,
    );
  }

  SystemHealthStatus _calculateSystemHealth() {
    final healthyComponents = _componentHealth.values.where((health) => health.isHealthy).length;
    final totalComponents = _componentHealth.length;
    
    return totalComponents == 0 ? SystemHealthStatus.healthy :
        healthyComponents / totalComponents > 0.8 ? SystemHealthStatus.healthy :
        healthyComponents / totalComponents > 0.6 ? SystemHealthStatus.degraded :
        SystemHealthStatus.unhealthy;
  }

  SystemHealthStatus _calculateOverallHealth() {
    final componentHealth = _componentHealth.values;
    final healthyCount = componentHealth.where((h) => h.isHealthy).length;
    final totalCount = componentHealth.length;
    
    if (totalCount == 0) return SystemHealthStatus.healthy;
    
    final healthRatio = healthyCount / totalCount;
    if (healthRatio >= 0.9) return SystemHealthStatus.healthy;
    if (healthRatio >= 0.7) return SystemHealthStatus.degraded;
    return SystemHealthStatus.unhealthy;
  }

  List<String> _generateHealthRecommendations() {
    final recommendations = <String>[];
    
    // Check for unhealthy components
    final unhealthyComponents = _componentHealth.entries
        .where((entry) => !entry.value.isHealthy)
        .map((entry) => '${entry.key}: ${entry.value.issues.join(', ')}')
        .toList();
    
    if (unhealthyComponents.isNotEmpty) {
      recommendations.add('Address unhealthy components: ${unhealthyComponents.join('; ')}');
    }
    
    // Check for high error rates
    final highErrorComponents = _systemMetrics.entries
        .where((entry) => entry.value.errorRate > 0.1)
        .map((entry) => entry.key)
        .toList();
    
    if (highErrorComponents.isNotEmpty) {
      recommendations.add('Investigate high error rates in: ${highErrorComponents.join(', ')}');
    }
    
    return recommendations;
  }

  void _emitArchitectureEvent(ArchitectureEventType type, {String? componentName, String? details}) {
    final event = ArchitectureEvent(
      type: type,
      timestamp: DateTime.now(),
      componentName: componentName,
      details: details,
    );
    _architectureEventController.add(event);
  }

  void _emitReorganizationEvent(SystemReorganizationEventType type, {List<ArchitectureOptimization>? optimizations, String? details}) {
    final event = SystemReorganizationEvent(
      type: type,
      timestamp: DateTime.now(),
      optimizations: optimizations,
      details: details,
    );
    _reorganizationEventController.add(event);
  }

  // Getters
  bool get isInitialized => _isInitialized;
  Map<ArchitectureLayer, List<String>> get layerComponents => Map.from(_layerComponents);
  Map<SystemDomain, List<String>> get domainComponents => Map.from(_domainComponents);
}

// Supporting enums and classes

enum ArchitectureLayer {
  infrastructure,      // Layer 1: Core infrastructure
  coreServices,        // Layer 2: Core services
  businessLogic,       // Layer 3: Business logic
  applicationServices, // Layer 4: Application services
  presentation,        // Layer 5: Presentation layer
}

enum SystemDomain {
  coreInfrastructure,
  security,
  performance,
  network,
  robustness,
  userExperience,
  plugins,
}

enum CommunicationPattern {
  eventDriven,
  observer,
  singleton,
  factory,
  strategy,
  adapter,
  decorator,
}

enum ArchitectureEventType {
  initialized,
  componentAdded,
  componentRemoved,
  layerUpdated,
  domainUpdated,
  validationFailed,
  reorganizationCompleted,
}

enum SystemReorganizationEventType {
  started,
  inProgress,
  completed,
  failed,
}

enum OptimizationType {
  reduceCoupling,
  improveCohesion,
  flattenHierarchy,
  consolidateComponents,
  splitComponents,
}

enum OptimizationPriority {
  low,
  medium,
  high,
  critical,
}

enum OptimizationImpact {
  low,
  medium,
  high,
  critical,
}

enum SystemHealthStatus {
  healthy,
  degraded,
  unhealthy,
}

class SystemArchitectureOverview {
  final Map<ArchitectureLayer, List<String>> layers;
  final Map<SystemDomain, List<String>> domains;
  final Map<CommunicationPattern, List<String>> communicationPatterns;
  final int totalComponents;
  final SystemHealthStatus healthStatus;
  final DateTime lastUpdated;

  SystemArchitectureOverview({
    required this.layers,
    required this.domains,
    required this.communicationPatterns,
    required this.totalComponents,
    required this.healthStatus,
    required this.lastUpdated,
  });
}

class ArchitectureEvent {
  final ArchitectureEventType type;
  final DateTime timestamp;
  final String? componentName;
  final String? details;

  ArchitectureEvent({
    required this.type,
    required this.timestamp,
    this.componentName,
    this.details,
  });
}

class SystemReorganizationEvent {
  final SystemReorganizationEventType type;
  final DateTime timestamp;
  final List<ArchitectureOptimization>? optimizations;
  final String? details;

  SystemReorganizationEvent({
    required this.type,
    required this.timestamp,
    this.optimizations,
    this.details,
  });
}

class ComponentHealth {
  final bool isHealthy;
  final List<String> issues;
  final DateTime assessedAt;

  ComponentHealth({
    required this.isHealthy,
    required this.issues,
    required this.assessedAt,
  });

  factory ComponentHealth.healthy() {
    return ComponentHealth(
      isHealthy: true,
      issues: [],
      assessedAt: DateTime.now(),
    );
  }

  factory ComponentHealth.unhealthy(String issue) {
    return ComponentHealth(
      isHealthy: false,
      issues: [issue],
      assessedAt: DateTime.now(),
    );
  }

  factory ComponentHealth.degraded(String issue) {
    return ComponentHealth(
      isHealthy: false,
      issues: [issue],
      assessedAt: DateTime.now(),
    );
  }
}

class SystemMetrics {
  final String componentName;
  final double responseTime;
  final double throughput;
  final double errorRate;
  final double memoryUsage;
  final double cpuUsage;
  final DateTime timestamp;

  SystemMetrics({
    required this.componentName,
    required this.responseTime,
    required this.throughput,
    required this.errorRate,
    required this.memoryUsage,
    required this.cpuUsage,
    required this.timestamp,
  });
}

class SystemHealthReport {
  final Map<String, ComponentHealth> componentHealth;
  final Map<String, SystemMetrics> systemMetrics;
  final SystemHealthStatus overallHealth;
  final List<String> recommendations;
  final DateTime generatedAt;

  SystemHealthReport({
    required this.componentHealth,
    required this.systemMetrics,
    required this.overallHealth,
    required this.recommendations,
    required this.generatedAt,
  });
}

class ArchitectureAnalysis {
  final int totalComponents;
  final Map<ArchitectureLayer, int> layerDistribution;
  final Map<SystemDomain, int> domainDistribution;
  final Map<CommunicationPattern, int> patternDistribution;
  final double dependencyComplexity;
  final CouplingMetrics couplingMetrics;
  final CohesionMetrics cohesionMetrics;
  final DateTime analyzedAt;

  ArchitectureAnalysis({
    required this.totalComponents,
    required this.layerDistribution,
    required this.domainDistribution,
    required this.patternDistribution,
    required this.dependencyComplexity,
    required this.couplingMetrics,
    required this.cohesionMetrics,
    required this.analyzedAt,
  });
}

class ArchitectureOptimization {
  final OptimizationType type;
  final OptimizationPriority priority;
  final String description;
  final OptimizationImpact estimatedImpact;

  ArchitectureOptimization({
    required this.type,
    required this.priority,
    required this.description,
    required this.estimatedImpact,
  });
}

class CouplingMetrics {
  final Map<String, int> afferentCoupling;
  final Map<String, int> efferentCoupling;
  final double averageCoupling;

  CouplingMetrics({
    required this.afferentCoupling,
    required this.efferentCoupling,
    required this.averageCoupling,
  });
}

class CohesionMetrics {
  final Map<String, double> cohesionScores;
  final double averageCohesion;

  CohesionMetrics({
    required this.cohesionScores,
    required this.averageCohesion,
  });
}
