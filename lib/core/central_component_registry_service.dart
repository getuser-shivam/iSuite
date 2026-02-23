import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'central_config.dart';

/// Central Component Registry Service
/// Ensures all components are properly registered, parameterized, and connected through CentralConfig
/// Provides centralized management of component relationships and dependencies
class CentralComponentRegistryService {
  static final CentralComponentRegistryService _instance = CentralComponentRegistryService._internal();
  factory CentralComponentRegistryService() => _instance;
  CentralComponentRegistryService._internal();

  final CentralConfig _config = CentralConfig.instance;

  // Component registry tracking
  final Map<String, ComponentRegistration> _registeredComponents = {};
  final Map<String, ComponentRelationship> _componentRelationships = {};
  final StreamController<ComponentRegistryEvent> _eventController = StreamController.broadcast();

  Stream<ComponentRegistryEvent> get events => _eventController.stream;

  bool _isInitialized = false;

  /// Initialize the central component registry
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Register self with CentralConfig
      await _config.registerComponent(
        'CentralComponentRegistryService',
        '1.0.0',
        'Central registry for managing component parameterization and relationships',
        dependencies: ['CentralConfig'],
        parameters: {
          'registry.enabled': true,
          'registry.auto_discovery': true,
          'registry.relationship_validation': true,
          'registry.parameter_validation': true,
          'registry.health_monitoring': true,
          'registry.dependency_resolution': true,
        }
      );

      _isInitialized = true;
      _emitEvent(ComponentRegistryEventType.serviceInitialized);

    } catch (e) {
      _emitEvent(ComponentRegistryEventType.initializationFailed, error: e.toString());
      rethrow;
    }
  }

  /// Register a component with comprehensive parameterization
  Future<void> registerComponent({
    required String componentName,
    required String version,
    required String description,
    List<String> dependencies = const [],
    Map<String, dynamic> parameters = const {},
    List<ComponentRelationship> relationships = const [],
  }) async {
    if (!_isInitialized) await initialize();

    // Check if component already registered
    if (_registeredComponents.containsKey(componentName)) {
      throw ComponentRegistryException('Component $componentName already registered');
    }

    // Validate dependencies
    await _validateDependencies(dependencies);

    // Register with CentralConfig
    await _config.registerComponent(
      componentName,
      version,
      description,
      dependencies: dependencies,
      parameters: parameters,
    );

    // Register relationships
    for (final relationship in relationships) {
      await registerRelationship(componentName, relationship);
    }

    // Track registration
    final registration = ComponentRegistration(
      name: componentName,
      version: version,
      description: description,
      dependencies: dependencies,
      parameters: parameters,
      registeredAt: DateTime.now(),
    );

    _registeredComponents[componentName] = registration;

    _emitEvent(ComponentRegistryEventType.componentRegistered, componentName: componentName);
  }

  /// Register a relationship between components
  Future<void> registerRelationship(String componentName, ComponentRelationship relationship) async {
    if (!_isInitialized) await initialize();

    // Validate component exists
    if (!_registeredComponents.containsKey(componentName)) {
      throw ComponentRegistryException('Component $componentName not registered');
    }

    if (!_registeredComponents.containsKey(relationship.targetComponent)) {
      throw ComponentRegistryException('Target component ${relationship.targetComponent} not registered');
    }

    // Register with CentralConfig
    await _config.registerComponentRelationship(
      componentName,
      relationship.targetComponent,
      relationship.type,
      relationship.description,
    );

    // Track relationship
    final relationshipKey = '${componentName}_${relationship.targetComponent}_${relationship.type}';
    _componentRelationships[relationshipKey] = relationship;

    _emitEvent(ComponentRegistryEventType.relationshipRegistered,
      componentName: componentName,
      targetComponent: relationship.targetComponent,
      relationshipType: relationship.type.toString(),
    );
  }

  /// Audit all components for parameterization and relationships
  Future<ComponentAuditReport> auditAllComponents() async {
    if (!_isInitialized) await initialize();

    final report = ComponentAuditReport();
    final allServices = await _discoverAllServices();

    for (final service in allServices) {
      final serviceAudit = await _auditService(service);
      report.serviceAudits[service] = serviceAudit;
    }

    // Cross-component analysis
    report.relationshipAnalysis = await _analyzeRelationships(report.serviceAudits);
    report.parameterizationAnalysis = await _analyzeParameterization(report.serviceAudits);
    report.dependencyAnalysis = await _analyzeDependencies(report.serviceAudits);

    _emitEvent(ComponentRegistryEventType.auditCompleted, data: {
      'total_services': allServices.length,
      'issues_found': report.getTotalIssues(),
    });

    return report;
  }

  /// Discover all services in the project
  Future<List<String>> _discoverAllServices() async {
    // This would typically scan the codebase, but for now return known services
    return [
      'CentralConfig',
      'LoggingService',
      'SecurityHardeningService',
      'AdvancedErrorHandlingService',
      'AdvancedCachingService',
      'ComprehensiveTestingStrategyService',
      'SupabaseService',
      'FTPClientService',
      'AdvancedFileManagerService',
      'CloudStorageService',
      'AdvancedFileOperationsService',
      // Add more services as discovered
    ];
  }

  /// Audit a specific service
  Future<ServiceAudit> _auditService(String serviceName) async {
    final audit = ServiceAudit(serviceName: serviceName);

    try {
      // Check if registered with CentralConfig
      final registeredComponents = _config.getRegisteredComponents();
      audit.isRegistered = registeredComponents.contains(serviceName);

      if (audit.isRegistered) {
        audit.registrationInfo = _registeredComponents[serviceName];
        audit.parameters = _config.getAllParametersForComponent(serviceName);
        audit.relationships = getComponentRelationships(serviceName);
      }

      // Check parameterization completeness
      audit.parameterizationScore = _calculateParameterizationScore(audit);

      // Check relationship completeness
      audit.relationshipScore = _calculateRelationshipScore(audit);

      // Check for common issues
      audit.issues = await _identifyServiceIssues(audit);

    } catch (e) {
      audit.issues.add('Audit failed: $e');
    }

    audit.auditCompleted = true;
    return audit;
  }

  /// Calculate parameterization score (0-100)
  double _calculateParameterizationScore(ServiceAudit audit) {
    if (!audit.isRegistered || audit.parameters.isEmpty) return 0.0;

    double score = 0.0;
    final params = audit.parameters;

    // Core configuration parameters
    if (params.containsKey('${audit.serviceName.toLowerCase()}.enabled')) score += 10;
    if (params.containsKey('${audit.serviceName.toLowerCase()}.timeout_seconds') ||
        params.containsKey('${audit.serviceName.toLowerCase()}.timeout')) score += 10;
    if (params.containsKey('${audit.serviceName.toLowerCase()}.max_connections') ||
        params.containsKey('${audit.serviceName.toLowerCase()}.pool_size')) score += 10;

    // Security parameters
    if (params.containsKey('${audit.serviceName.toLowerCase()}.security.enabled')) score += 15;
    if (params.containsKey('${audit.serviceName.toLowerCase()}.encryption.enabled')) score += 10;

    // Monitoring parameters
    if (params.containsKey('${audit.serviceName.toLowerCase()}.monitoring.enabled')) score += 10;
    if (params.containsKey('${audit.serviceName.toLowerCase()}.analytics.enabled')) score += 10;

    // Performance parameters
    if (params.containsKey('${audit.serviceName.toLowerCase()}.performance.enabled')) score += 10;

    // Integration parameters
    if (params.containsKey('${audit.serviceName.toLowerCase()}.integration.enabled') ||
        params.containsKey('${audit.serviceName.toLowerCase()}.api.enabled')) score += 10;

    // Advanced features
    if (params.length > 20) score += 15; // Bonus for comprehensive parameterization

    return score.clamp(0.0, 100.0);
  }

  /// Calculate relationship score (0-100)
  double _calculateRelationshipScore(ServiceAudit audit) {
    if (!audit.isRegistered || audit.relationships.isEmpty) return 0.0;

    double score = 0.0;
    final relationships = audit.relationships;

    // Core dependencies
    if (relationships.any((r) => r.targetComponent == 'CentralConfig')) score += 20;
    if (relationships.any((r) => r.targetComponent == 'LoggingService')) score += 15;
    if (relationships.any((r) => r.targetComponent == 'SecurityHardeningService')) score += 15;

    // Functional relationships
    if (relationships.any((r) => r.targetComponent.contains('Error'))) score += 10;
    if (relationships.any((r) => r.targetComponent.contains('Cache'))) score += 10;
    if (relationships.any((r) => r.targetComponent.contains('Performance'))) score += 10;

    // Quality relationships
    if (relationships.length >= 3) score += 15; // Good connectivity
    if (relationships.any((r) => r.type == RelationshipType.depends_on)) score += 5;
    if (relationships.any((r) => r.type == RelationshipType.uses)) score += 5;

    return score.clamp(0.0, 100.0);
  }

  /// Identify issues with a service
  Future<List<String>> _identifyServiceIssues(ServiceAudit audit) async {
    final issues = <String>[];

    if (!audit.isRegistered) {
      issues.add('Service not registered with CentralConfig');
      return issues;
    }

    // Parameterization issues
    if (audit.parameters.isEmpty) {
      issues.add('No parameters configured');
    } else {
      // Check for essential parameters
      final essentialParams = [
        '${audit.serviceName.toLowerCase()}.enabled',
        'timeout',
        'max_connections',
      ];

      for (final param in essentialParams) {
        if (!audit.parameters.containsKey(param) &&
            !audit.parameters.keys.any((key) => key.contains(param))) {
          issues.add('Missing essential parameter: $param');
        }
      }
    }

    // Relationship issues
    if (audit.relationships.isEmpty) {
      issues.add('No component relationships defined');
    } else {
      // Check for critical relationships
      final criticalDeps = ['CentralConfig', 'LoggingService'];
      for (final dep in criticalDeps) {
        if (!audit.relationships.any((r) => r.targetComponent == dep)) {
          issues.add('Missing critical relationship to $dep');
        }
      }
    }

    // Configuration issues
    if (audit.parameterizationScore < 50) {
      issues.add('Low parameterization score (${audit.parameterizationScore.toStringAsFixed(1)}/100)');
    }

    if (audit.relationshipScore < 50) {
      issues.add('Low relationship score (${audit.relationshipScore.toStringAsFixed(1)}/100)');
    }

    return issues;
  }

  /// Analyze cross-component relationships
  Future<RelationshipAnalysis> _analyzeRelationships(Map<String, ServiceAudit> audits) async {
    final analysis = RelationshipAnalysis();

    // Build dependency graph
    for (final audit in audits.values) {
      if (audit.isRegistered) {
        for (final relationship in audit.relationships) {
          analysis.dependencyGraph.putIfAbsent(audit.serviceName, () => []).add(relationship.targetComponent);
        }
      }
    }

    // Detect cycles
    analysis.cycles = _detectCycles(analysis.dependencyGraph);

    // Analyze connectivity
    analysis.isolatedComponents = _findIsolatedComponents(analysis.dependencyGraph, audits.keys.toList());
    analysis.highlyConnectedComponents = _findHighlyConnectedComponents(analysis.dependencyGraph);

    // Calculate centrality
    analysis.centralityScores = _calculateCentralityScores(analysis.dependencyGraph);

    return analysis;
  }

  /// Analyze parameterization patterns
  Future<ParameterizationAnalysis> _analyzeParameterization(Map<String, ServiceAudit> audits) async {
    final analysis = ParameterizationAnalysis();

    for (final audit in audits.values) {
      if (audit.isRegistered) {
        analysis.totalParameters += audit.parameters.length;
        analysis.parameterizationScores[audit.serviceName] = audit.parameterizationScore;
      }
    }

    // Calculate averages
    if (analysis.parameterizationScores.isNotEmpty) {
      analysis.averageScore = analysis.parameterizationScores.values.reduce((a, b) => a + b) / analysis.parameterizationScores.length;
    }

    // Identify patterns
    analysis.commonParameterPatterns = _identifyParameterPatterns(audits);
    analysis.missingParameters = _identifyMissingParameters(audits);

    return analysis;
  }

  /// Analyze dependency health
  Future<DependencyAnalysis> _analyzeDependencies(Map<String, ServiceAudit> audits) async {
    final analysis = DependencyAnalysis();

    // Check for missing dependencies
    for (final audit in audits.values) {
      if (audit.isRegistered) {
        for (final dep in audit.registrationInfo?.dependencies ?? []) {
          if (!audits.containsKey(dep) || !audits[dep]!.isRegistered) {
            analysis.missingDependencies.add('${audit.serviceName} -> $dep');
          }
        }
      }
    }

    // Check for circular dependencies
    analysis.circularDependencies = _detectCircularDependencies(audits);

    // Check dependency depth
    analysis.dependencyDepths = _calculateDependencyDepths(audits);

    return analysis;
  }

  /// Detect cycles in dependency graph
  List<List<String>> _detectCycles(Map<String, List<String>> graph) {
    final cycles = <List<String>>[];
    final visiting = <String>{};
    final visited = <String>{};

    void dfs(String node, List<String> path) {
      if (visiting.contains(node)) {
        final cycleStart = path.indexOf(node);
        cycles.add(path.sublist(cycleStart));
        return;
      }

      if (visited.contains(node)) return;

      visiting.add(node);
      path.add(node);

      for (final neighbor in graph[node] ?? []) {
        dfs(neighbor, List.from(path));
      }

      visiting.remove(node);
      path.removeLast();
      visited.add(node);
    }

    for (final node in graph.keys) {
      if (!visited.contains(node)) {
        dfs(node, []);
      }
    }

    return cycles;
  }

  /// Find isolated components
  List<String> _findIsolatedComponents(Map<String, List<String>> graph, List<String> allComponents) {
    final connected = <String>{};

    for (final component in graph.keys) {
      connected.add(component);
      connected.addAll(graph[component] ?? []);
    }

    return allComponents.where((component) => !connected.contains(component)).toList();
  }

  /// Find highly connected components
  List<String> _findHighlyConnectedComponents(Map<String, List<String>> graph) {
    return graph.entries
        .where((entry) => (entry.value.length) > 5)
        .map((entry) => entry.key)
        .toList();
  }

  /// Calculate centrality scores
  Map<String, double> _calculateCentralityScores(Map<String, List<String>> graph) {
    final scores = <String, double>{};

    for (final component in graph.keys) {
      final outgoing = graph[component]?.length ?? 0;
      final incoming = graph.values
          .where((deps) => deps.contains(component))
          .length;

      scores[component] = (outgoing + incoming) / 2.0;
    }

    return scores;
  }

  /// Identify common parameter patterns
  Map<String, int> _identifyParameterPatterns(Map<String, ServiceAudit> audits) {
    final patterns = <String, int>{};

    for (final audit in audits.values) {
      if (audit.isRegistered) {
        for (final param in audit.parameters.keys) {
          // Extract pattern (e.g., "*.enabled" -> "enabled")
          final parts = param.split('.');
          if (parts.length > 1) {
            final pattern = parts.last;
            patterns[pattern] = (patterns[pattern] ?? 0) + 1;
          }
        }
      }
    }

    return patterns;
  }

  /// Identify missing essential parameters
  List<String> _identifyMissingParameters(Map<String, ServiceAudit> audits) {
    final missing = <String>[];
    final essentialParams = ['enabled', 'timeout', 'max_connections'];

    for (final audit in audits.values) {
      if (audit.isRegistered) {
        for (final essential in essentialParams) {
          final hasParam = audit.parameters.keys.any((param) =>
              param.contains(essential) ||
              param.endsWith(essential));

          if (!hasParam) {
            missing.add('${audit.serviceName}: missing $essential');
          }
        }
      }
    }

    return missing;
  }

  /// Detect circular dependencies
  List<String> _detectCircularDependencies(Map<String, ServiceAudit> audits) {
    final circular = <String>[];

    for (final audit in audits.values) {
      if (audit.isRegistered) {
        for (final dep in audit.registrationInfo?.dependencies ?? []) {
          if (audits.containsKey(dep) && audits[dep]!.isRegistered) {
            final depAudit = audits[dep]!;
            if (depAudit.registrationInfo?.dependencies.contains(audit.serviceName) ?? false) {
              circular.add('${audit.serviceName} <-> $dep');
            }
          }
        }
      }
    }

    return circular;
  }

  /// Calculate dependency depths
  Map<String, int> _calculateDependencyDepths(Map<String, ServiceAudit> audits) {
    final depths = <String, int>{};

    int calculateDepth(String component, Set<String> visited) {
      if (visited.contains(component)) return 0;
      if (!audits.containsKey(component) || !audits[component]!.isRegistered) return 0;

      visited.add(component);
      final deps = audits[component]!.registrationInfo?.dependencies ?? [];
      int maxDepth = 0;

      for (final dep in deps) {
        maxDepth = max(maxDepth, calculateDepth(dep, Set.from(visited)) + 1);
      }

      visited.remove(component);
      return maxDepth;
    }

    for (final component in audits.keys) {
      depths[component] = calculateDepth(component, {});
    }

    return depths;
  }

  /// Validate all registered components
  Future<Map<String, ComponentValidationResult>> validateAllComponents() async {
    if (!_isInitialized) await initialize();

    final results = <String, ComponentValidationResult>{};

    for (final componentName in _registeredComponents.keys) {
      results[componentName] = await validateComponent(componentName);
    }

    return results;
  }

  /// Get component registration info
  ComponentRegistration? getComponentRegistration(String componentName) {
    return _registeredComponents[componentName];
  }

  /// Get all registered components
  List<ComponentRegistration> getAllComponentRegistrations() {
    return _registeredComponents.values.toList();
  }

  /// Get relationships for component
  List<ComponentRelationship> getComponentRelationships(String componentName) {
    return _componentRelationships.entries
        .where((entry) => entry.key.startsWith('${componentName}_'))
        .map((entry) => entry.value)
        .toList();
  }

  /// Get dependency graph for component
  Map<String, List<String>> getDependencyGraph(String componentName) {
    final graph = <String, List<String>>{};
    final visited = <String>{};

    void buildGraph(String component) {
      if (visited.contains(component)) return;
      visited.add(component);

      final registration = _registeredComponents[component];
      if (registration != null) {
        graph[component] = registration.dependencies;
        for (final dep in registration.dependencies) {
          buildGraph(dep);
        }
      }
    }

    buildGraph(componentName);
    return graph;
  }

  /// Validate dependencies exist
  Future<void> _validateDependencies(List<String> dependencies) async {
    for (final dependency in dependencies) {
      if (!_registeredComponents.containsKey(dependency) &&
          !_config.getRegisteredComponents().contains(dependency)) {
        throw ComponentRegistryException('Dependency not available: $dependency');
      }
    }
  }

  /// Emit event
  void _emitEvent(ComponentRegistryEventType type, {
    String? componentName,
    String? targetComponent,
    String? relationshipType,
    String? error,
  }) {
    final event = ComponentRegistryEvent(
      type: type,
      timestamp: DateTime.now(),
      componentName: componentName,
      targetComponent: targetComponent,
      relationshipType: relationshipType,
      error: error,
    );

    _eventController.add(event);
  }
}

// === DATA MODELS ===

/// Component Registration
class ComponentRegistration {
  final String name;
  final String version;
  final String description;
  final List<String> dependencies;
  final Map<String, dynamic> parameters;
  final DateTime registeredAt;

  ComponentRegistration({
    required this.name,
    required this.version,
    required this.description,
    required this.dependencies,
    required this.parameters,
    required this.registeredAt,
  });
}

/// Component Relationship
class ComponentRelationship {
  final String targetComponent;
  final RelationshipType type;
  final String description;

  ComponentRelationship({
    required this.targetComponent,
    required this.type,
    required this.description,
  });
}

/// Component Validation Result
class ComponentValidationResult {
  final String componentName;
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ComponentValidationResult({
    required this.componentName,
    required this.isValid,
    required this.errors,
    this.warnings = const [],
  });
}

/// Component Registry Event
class ComponentRegistryEvent {
  final ComponentRegistryEventType type;
  final DateTime timestamp;
  final String? componentName;
  final String? targetComponent;
  final String? relationshipType;
  final String? error;

  ComponentRegistryEvent({
    required this.type,
    required this.timestamp,
    this.componentName,
    this.targetComponent,
    this.relationshipType,
    this.error,
  });
}

/// Component Registry Event Types
enum ComponentRegistryEventType {
  serviceInitialized,
  initializationFailed,
  componentRegistered,
  relationshipRegistered,
  componentValidated,
  validationFailed,
  auditCompleted,
}

/// Component Audit Report
class ComponentAuditReport {
  final Map<String, ServiceAudit> serviceAudits = {};
  late final RelationshipAnalysis relationshipAnalysis;
  late final ParameterizationAnalysis parameterizationAnalysis;
  late final DependencyAnalysis dependencyAnalysis;

  int getTotalIssues() {
    int total = 0;
    for (final audit in serviceAudits.values) {
      total += audit.issues.length;
    }
    return total;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalServices': serviceAudits.length,
      'totalIssues': getTotalIssues(),
      'serviceAudits': serviceAudits.map((key, value) => MapEntry(key, value.toJson())),
      'relationshipAnalysis': relationshipAnalysis.toJson(),
      'parameterizationAnalysis': parameterizationAnalysis.toJson(),
      'dependencyAnalysis': dependencyAnalysis.toJson(),
    };
  }
}

/// Service Audit
class ServiceAudit {
  final String serviceName;
  bool isRegistered = false;
  ComponentRegistration? registrationInfo;
  Map<String, dynamic> parameters = {};
  List<ComponentRelationship> relationships = [];
  double parameterizationScore = 0.0;
  double relationshipScore = 0.0;
  List<String> issues = [];
  bool auditCompleted = false;

  ServiceAudit({required this.serviceName});

  Map<String, dynamic> toJson() {
    return {
      'serviceName': serviceName,
      'isRegistered': isRegistered,
      'parameterizationScore': parameterizationScore,
      'relationshipScore': relationshipScore,
      'issues': issues,
      'auditCompleted': auditCompleted,
    };
  }
}

/// Relationship Analysis
class RelationshipAnalysis {
  final Map<String, List<String>> dependencyGraph = {};
  List<List<String>> cycles = [];
  List<String> isolatedComponents = [];
  List<String> highlyConnectedComponents = [];
  Map<String, double> centralityScores = {};

  Map<String, dynamic> toJson() {
    return {
      'cycles': cycles,
      'isolatedComponents': isolatedComponents,
      'highlyConnectedComponents': highlyConnectedComponents,
      'centralityScores': centralityScores,
    };
  }
}

/// Parameterization Analysis
class ParameterizationAnalysis {
  int totalParameters = 0;
  Map<String, double> parameterizationScores = {};
  double averageScore = 0.0;
  Map<String, int> commonParameterPatterns = {};
  List<String> missingParameters = [];

  Map<String, dynamic> toJson() {
    return {
      'totalParameters': totalParameters,
      'averageScore': averageScore,
      'commonParameterPatterns': commonParameterPatterns,
      'missingParameters': missingParameters,
    };
  }
}

/// Dependency Analysis
class DependencyAnalysis {
  List<String> missingDependencies = [];
  List<String> circularDependencies = [];
  Map<String, int> dependencyDepths = {};

  Map<String, dynamic> toJson() {
    return {
      'missingDependencies': missingDependencies,
      'circularDependencies': circularDependencies,
      'dependencyDepths': dependencyDepths,
    };
  }
}

/// Component Registry Exception
class ComponentRegistryException implements Exception {
  final String message;
  ComponentRegistryException(this.message);

  @override
  String toString() => 'ComponentRegistryException: $message';
}
