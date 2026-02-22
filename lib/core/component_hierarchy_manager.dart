import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'central_config.dart';
import 'logging/logging_service.dart';
import 'advanced_security_manager.dart';
import 'advanced_performance_monitor.dart';
import 'project_finalizer.dart';
import 'robustness_manager.dart';
import 'resilience_manager.dart';
import 'health_monitor.dart';
import 'plugin_manager.dart';
import 'notification_service.dart';
import 'accessibility_manager.dart';
import 'component_registry.dart';
import 'component_factory.dart';
import 'owlfiles_inspired_network_manager.dart';
import 'universal_protocol_manager.dart';

/// Component Hierarchy Manager - Organizes components in logical hierarchy
/// 
/// Provides well-organized component structure with clear relationships,
/// dependencies, and hierarchical organization for maintainability and scalability.
class ComponentHierarchyManager {
  static final ComponentHierarchyManager _instance = ComponentHierarchyManager._internal();
  factory ComponentHierarchyManager() => _instance;
  ComponentHierarchyManager._internal();

  // Core services
  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();
  final AdvancedSecurityManager _security = AdvancedSecurityManager();
  final AdvancedPerformanceMonitor _performance = AdvancedPerformanceMonitor();

  // Hierarchy structure
  final Map<String, HierarchyNode> _hierarchyNodes = {};
  final Map<String, List<String>> _parentToChildren = {};
  final Map<String, String> _childToParent = {};
  final Map<String, ComponentLevel> _componentLevels = {};

  // Component categories
  final Map<ComponentCategory, List<String>> _categoryComponents = {};
  final Map<String, ComponentCategory> _componentCategories = {};

  // Dependency tracking
  final Map<String, Set<String>> _componentDependencies = {};
  final Map<String, Set<String>> _reverseDependencies = {};

  // Event streams
  final StreamController<HierarchyEvent> _hierarchyEventController = StreamController.broadcast();
  final StreamController<ComponentLifecycleEvent> _lifecycleEventController = StreamController.broadcast();

  Stream<HierarchyEvent> get hierarchyEvents => _hierarchyEventController.stream;
  Stream<ComponentLifecycleEvent> get lifecycleEvents => _lifecycleEventController.stream;

  // State
  bool _isInitialized = false;
  final Map<String, DateTime> _componentRegistrationTimes = {};

  /// Initialize component hierarchy with sensible organization
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Component Hierarchy Manager', 'ComponentHierarchyManager');

      // Register component hierarchy with CentralConfig
      await _registerHierarchyWithCentralConfig();

      // Build component hierarchy
      await _buildComponentHierarchy();

      // Organize components by category
      await _organizeComponentsByCategory();

      // Setup dependency tracking
      await _setupDependencyTracking();

      // Start hierarchy monitoring
      await _startHierarchyMonitoring();

      _isInitialized = true;
      _emitHierarchyEvent(HierarchyEventType.initialized);

      _logger.info('Component Hierarchy Manager initialized successfully', 'ComponentHierarchyManager');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Component Hierarchy Manager', 'ComponentHierarchyManager',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Register component in hierarchy
  Future<void> registerComponent({
    required String componentName,
    required ComponentCategory category,
    required ComponentLevel level,
    String? parentComponent,
    List<String>? dependencies,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _logger.info('Registering component: $componentName', 'ComponentHierarchyManager');

      // Create hierarchy node
      final node = HierarchyNode(
        name: componentName,
        category: category,
        level: level,
        parent: parentComponent,
        dependencies: dependencies ?? [],
        metadata: metadata ?? {},
        registeredAt: DateTime.now(),
        isActive: true,
      );

      // Add to hierarchy
      _hierarchyNodes[componentName] = node;

      // Update parent-child relationships
      if (parentComponent != null) {
        _parentToChildren[parentComponent] ??= [];
        _parentToChildren[parentComponent]!.add(componentName);
        _childToParent[componentName] = parentComponent;
      }

      // Update category mapping
      _categoryComponents[category] ??= [];
      _categoryComponents[category]!.add(componentName);
      _componentCategories[componentName] = category;

      // Update level mapping
      _componentLevels[componentName] = level;

      // Update dependencies
      if (dependencies != null) {
        _componentDependencies[componentName] = Set.from(dependencies);
        for (final dep in dependencies) {
          _reverseDependencies[dep] ??= {};
          _reverseDependencies[dep]!.add(componentName);
        }
      }

      // Register with CentralConfig
      await _config.registerComponent(
        componentName,
        metadata?['version'] ?? '1.0.0',
        metadata?['description'] ?? 'Component in $category',
      );

      // Register relationships
      await _registerComponentRelationships(componentName, node);

      // Track registration time
      _componentRegistrationTimes[componentName] = DateTime.now();

      _emitLifecycleEvent(ComponentLifecycleEventType.registered, componentName);
      _emitHierarchyEvent(HierarchyEventType.componentAdded, componentName: componentName);

      _logger.info('Component registered successfully: $componentName', 'ComponentHierarchyManager');

    } catch (e) {
      _logger.error('Failed to register component: $componentName', 'ComponentHierarchyManager', error: e);
      rethrow;
    }
  }

  /// Get component hierarchy tree
  HierarchyTree getHierarchyTree() {
    // Find root components (no parent)
    final roots = _hierarchyNodes.values
        .where((node) => node.parent == null)
        .toList();

    // Build tree recursively
    final treeNodes = roots.map((root) => _buildTreeNode(root)).toList();

    return HierarchyTree(
      roots: treeNodes,
      totalComponents: _hierarchyNodes.length,
      totalLevels: ComponentLevel.values.length,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get components by category
  List<String> getComponentsByCategory(ComponentCategory category) {
    return _categoryComponents[category] ?? [];
  }

  /// Get components by level
  List<String> getComponentsByLevel(ComponentLevel level) {
    return _componentLevels.entries
        .where((entry) => entry.value == level)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get component dependencies
  Set<String> getComponentDependencies(String componentName) {
    return _componentDependencies[componentName] ?? {};
  }

  /// Get components that depend on this component
  Set<String> getComponentDependents(String componentName) {
    return _reverseDependencies[componentName] ?? {};
  }

  /// Get component path in hierarchy
  List<String> getComponentPath(String componentName) {
    final path = <String>[];
    var current = componentName;

    while (current != null) {
      path.insert(0, current);
      current = _childToParent[current];
    }

    return path;
  }

  /// Validate component hierarchy
  Future<HierarchyValidationResult> validateHierarchy() async {
    final issues = <HierarchyIssue>[];
    final warnings = <HierarchyIssue>[];

    try {
      // Check for circular dependencies
      final circularDeps = await _detectCircularDependencies();
      for (final cycle in circularDeps) {
        issues.add(HierarchyIssue(
          type: HierarchyIssueType.circularDependency,
          severity: IssueSeverity.critical,
          description: 'Circular dependency detected: ${cycle.join(' -> ')}',
          components: cycle,
        ));
      }

      // Check for orphaned components
      final orphans = _findOrphanedComponents();
      for (final orphan in orphans) {
        warnings.add(HierarchyIssue(
          type: HierarchyIssueType.orphanedComponent,
          severity: IssueSeverity.warning,
          description: 'Orphaned component: $orphan',
          components: [orphan],
        ));
      }

      // Check for missing dependencies
      final missingDeps = await _checkMissingDependencies();
      for (final entry in missingDeps.entries) {
        final component = entry.key;
        final deps = entry.value;
        for (final dep in deps) {
          issues.add(HierarchyIssue(
            type: HierarchyIssueType.missingDependency,
            severity: IssueSeverity.error,
            description: 'Component $component depends on missing component $dep',
            components: [component, dep],
          ));
        }
      }

      // Check hierarchy depth
      final maxDepth = _calculateMaxDepth();
      if (maxDepth > 10) {
        warnings.add(HierarchyIssue(
          type: HierarchyIssueType.deepHierarchy,
          severity: IssueSeverity.warning,
          description: 'Hierarchy depth ($maxDepth) exceeds recommended limit',
          components: [],
        ));
      }

      return HierarchyValidationResult(
        isValid: issues.isEmpty,
        issues: issues,
        warnings: warnings,
        totalComponents: _hierarchyNodes.length,
        maxDepth: maxDepth,
        validatedAt: DateTime.now(),
      );

    } catch (e) {
      _logger.error('Hierarchy validation failed', 'ComponentHierarchyManager', error: e);
      return HierarchyValidationResult(
        isValid: false,
        issues: [
          HierarchyIssue(
            type: HierarchyIssueType.validationError,
            severity: IssueSeverity.critical,
            description: 'Validation failed: ${e.toString()}',
            components: [],
          )
        ],
        warnings: warnings,
        totalComponents: _hierarchyNodes.length,
        maxDepth: 0,
        validatedAt: DateTime.now(),
      );
    }
  }

  /// Get component statistics
  ComponentStatistics getComponentStatistics() {
    final categoryStats = <ComponentCategory, int>{};
    final levelStats = <ComponentLevel, int>{};

    for (final node in _hierarchyNodes.values) {
      categoryStats[node.category] = (categoryStats[node.category] ?? 0) + 1;
      levelStats[node.level] = (levelStats[node.level] ?? 0) + 1;
    }

    return ComponentStatistics(
      totalComponents: _hierarchyNodes.length,
      categoryDistribution: categoryStats,
      levelDistribution: levelStats,
      averageDependencies: _calculateAverageDependencies(),
      maxDependencies: _calculateMaxDependencies(),
      orphanedComponents: _findOrphanedComponents().length,
      circularDependencies: _detectCircularDependencies().length,
      lastUpdated: DateTime.now(),
    );
  }

  /// Private helper methods

  Future<void> _registerHierarchyWithCentralConfig() async {
    await _config.registerComponent(
      'ComponentHierarchyManager',
      '1.0.0',
      'Manages component hierarchy and organization',
    );

    await _config.registerComponentRelationship(
      'ComponentHierarchyManager',
      'CentralConfig',
      RelationshipType.depends_on,
      'Uses CentralConfig for component registration and relationships',
    );

    await _config.registerComponentRelationship(
      'ComponentHierarchyManager',
      'AdvancedPerformanceMonitor',
      RelationshipType.monitors,
      'Monitored by AdvancedPerformanceMonitor for hierarchy metrics',
    );
  }

  Future<void> _buildComponentHierarchy() async {
    // Register core components in logical hierarchy

    // Level 1: Core Infrastructure
    await registerComponent(
      componentName: 'CentralConfig',
      category: ComponentCategory.core,
      level: ComponentLevel.infrastructure,
      metadata: {
        'version': '2.0.0',
        'description': 'Central configuration and parameter management',
        'critical': true,
      },
    );

    await registerComponent(
      componentName: 'LoggingService',
      category: ComponentCategory.core,
      level: ComponentLevel.infrastructure,
      parentComponent: 'CentralConfig',
      metadata: {
        'version': '1.0.0',
        'description': 'Centralized logging service',
        'critical': true,
      },
    );

    // Level 2: Security & Performance
    await registerComponent(
      componentName: 'AdvancedSecurityManager',
      category: ComponentCategory.security,
      level: ComponentLevel.service,
      parentComponent: 'CentralConfig',
      dependencies: ['LoggingService'],
      metadata: {
        'version': '1.0.0',
        'description': 'Advanced security and encryption management',
        'critical': true,
      },
    );

    await registerComponent(
      componentName: 'AdvancedPerformanceMonitor',
      category: ComponentCategory.performance,
      level: ComponentLevel.service,
      parentComponent: 'CentralConfig',
      dependencies: ['LoggingService'],
      metadata: {
        'version': '1.0.0',
        'description': 'Performance monitoring and optimization',
        'critical': false,
      },
    );

    // Level 3: Network & File Management
    await registerComponent(
      componentName: 'UniversalProtocolManager',
      category: ComponentCategory.network,
      level: ComponentLevel.manager,
      parentComponent: 'AdvancedSecurityManager',
      dependencies: ['CentralConfig', 'AdvancedSecurityManager', 'AdvancedPerformanceMonitor'],
      metadata: {
        'version': '1.0.0',
        'description': 'Universal protocol management for network connections',
        'critical': true,
      },
    );

    await registerComponent(
      componentName: 'OwlfilesInspiredNetworkManager',
      category: ComponentCategory.network,
      level: ComponentLevel.manager,
      parentComponent: 'UniversalProtocolManager',
      dependencies: ['UniversalProtocolManager', 'AdvancedSecurityManager'],
      metadata: {
        'version': '1.0.0',
        'description': 'Owlfiles-inspired network and file sharing',
        'critical': true,
      },
    );

    // Level 4: Application Features
    await registerComponent(
      componentName: 'RobustnessManager',
      category: ComponentCategory.robustness,
      level: ComponentLevel.feature,
      parentComponent: 'CentralConfig',
      dependencies: ['LoggingService', 'AdvancedSecurityManager'],
      metadata: {
        'version': '1.0.0',
        'description': 'System robustness and error handling',
        'critical': true,
      },
    );

    await registerComponent(
      componentName: 'HealthMonitor',
      category: ComponentCategory.monitoring,
      level: ComponentLevel.feature,
      parentComponent: 'AdvancedPerformanceMonitor',
      dependencies: ['AdvancedPerformanceMonitor', 'LoggingService'],
      metadata: {
        'version': '1.0.0',
        'description': 'System health monitoring',
        'critical': false,
      },
    );

    // Level 5: UI & User Services
    await registerComponent(
      componentName: 'NotificationService',
      category: ComponentCategory.ui,
      level: ComponentLevel.service,
      parentComponent: 'CentralConfig',
      dependencies: ['LoggingService'],
      metadata: {
        'version': '1.0.0',
        'description': 'User notification service',
        'critical': false,
      },
    );

    await registerComponent(
      componentName: 'AccessibilityManager',
      category: ComponentCategory.ui,
      level: ComponentLevel.service,
      parentComponent: 'NotificationService',
      dependencies: ['NotificationService'],
      metadata: {
        'version': '1.0.0',
        'description': 'Accessibility and user experience management',
        'critical': false,
      },
    );
  }

  Future<void> _organizeComponentsByCategory() async {
    // Categories are already organized during registration
    _logger.info('Components organized by category', 'ComponentHierarchyManager');
  }

  Future<void> _setupDependencyTracking() async {
    // Dependencies are already tracked during registration
    _logger.info('Dependency tracking setup completed', 'ComponentHierarchyManager');
  }

  Future<void> _startHierarchyMonitoring() async {
    // Start periodic hierarchy validation
    Timer.periodic(Duration(minutes: 5), (timer) async {
      final validation = await validateHierarchy();
      if (!validation.isValid) {
        _logger.warning('Hierarchy validation failed', 'ComponentHierarchyManager');
        _emitHierarchyEvent(HierarchyEventType.validationFailed, details: validation.toString());
      }
    });
  }

  Future<void> _registerComponentRelationships(String componentName, HierarchyNode node) async {
    // Register parent relationship
    if (node.parent != null) {
      await _config.registerComponentRelationship(
        componentName,
        node.parent!,
        RelationshipType.depends_on,
        'Child component depends on parent',
      );
    }

    // Register dependency relationships
    for (final dependency in node.dependencies) {
      await _config.registerComponentRelationship(
        componentName,
        dependency,
        RelationshipType.depends_on,
        'Component dependency',
      );
    }
  }

  TreeNode _buildTreeNode(HierarchyNode node) {
    final children = _parentToChildren[node.name] ?? [];
    final childNodes = children.map((childName) {
      final childNode = _hierarchyNodes[childName]!;
      return _buildTreeNode(childNode);
    }).toList();

    return TreeNode(
      node: node,
      children: childNodes,
      depth: _calculateNodeDepth(node.name),
    );
  }

  int _calculateNodeDepth(String componentName) {
    return getComponentPath(componentName).length - 1;
  }

  Future<List<List<String>>> _detectCircularDependencies() async {
    final cycles = <List<String>>[];
    final visited = <String>{};
    final recursionStack = <String>{};
    final path = <String>[];

    for (final component in _hierarchyNodes.keys) {
      if (!visited.contains(component)) {
        final cycle = await _detectCycleDFS(
          component,
          visited,
          recursionStack,
          path,
        );
        if (cycle.isNotEmpty) {
          cycles.add(cycle);
        }
      }
    }

    return cycles;
  }

  Future<List<String>> _detectCycleDFS(
    String component,
    Set<String> visited,
    Set<String> recursionStack,
    List<String> path,
  ) async {
    visited.add(component);
    recursionStack.add(component);
    path.add(component);

    final dependencies = _componentDependencies[component] ?? {};
    for (final dep in dependencies) {
      if (!visited.contains(dep)) {
        final cycle = await _detectCycleDFS(dep, visited, recursionStack, path);
        if (cycle.isNotEmpty) {
          return cycle;
        }
      } else if (recursionStack.contains(dep)) {
        // Found a cycle
        final cycleStart = path.indexOf(dep);
        return path.sublist(cycleStart);
      }
    }

    recursionStack.remove(component);
    path.removeLast();
    return [];
  }

  List<String> _findOrphanedComponents() {
    final orphans = <String>[];
    
    for (final component in _hierarchyNodes.keys) {
      final hasParent = _childToParent.containsKey(component);
      final isInfrastructure = _componentLevels[component] == ComponentLevel.infrastructure;
      
      if (!hasParent && !isInfrastructure) {
        orphans.add(component);
      }
    }

    return orphans;
  }

  Future<Map<String, Set<String>>> _checkMissingDependencies() async {
    final missing = <String, Set<String>>{};

    for (final entry in _componentDependencies.entries) {
      final component = entry.key;
      final dependencies = entry.value;
      final missingDeps = <String>{};

      for (final dep in dependencies) {
        if (!_hierarchyNodes.containsKey(dep)) {
          missingDeps.add(dep);
        }
      }

      if (missingDeps.isNotEmpty) {
        missing[component] = missingDeps;
      }
    }

    return missing;
  }

  int _calculateMaxDepth() {
    int maxDepth = 0;
    for (final component in _hierarchyNodes.keys) {
      final depth = _calculateNodeDepth(component);
      maxDepth = Math.max(maxDepth, depth);
    }
    return maxDepth;
  }

  double _calculateAverageDependencies() {
    if (_componentDependencies.isEmpty) return 0.0;
    
    final totalDeps = _componentDependencies.values
        .map((deps) => deps.length)
        .reduce((a, b) => a + b);
    
    return totalDeps / _componentDependencies.length;
  }

  int _calculateMaxDependencies() {
    if (_componentDependencies.isEmpty) return 0;
    
    return _componentDependencies.values
        .map((deps) => deps.length)
        .reduce(Math.max);
  }

  void _emitHierarchyEvent(HierarchyEventType type, {String? componentName, String? details}) {
    final event = HierarchyEvent(
      type: type,
      timestamp: DateTime.now(),
      componentName: componentName,
      details: details,
    );
    _hierarchyEventController.add(event);
  }

  void _emitLifecycleEvent(ComponentLifecycleEventType type, String componentName) {
    final event = ComponentLifecycleEvent(
      type: type,
      timestamp: DateTime.now(),
      componentName: componentName,
    );
    _lifecycleEventController.add(event);
  }

  // Getters
  bool get isInitialized => _isInitialized;
  Map<String, HierarchyNode> get hierarchyNodes => Map.from(_hierarchyNodes);
  Map<ComponentCategory, List<String>> get categoryComponents => Map.from(_categoryComponents);
}

// Supporting enums and classes

enum ComponentCategory {
  core,
  security,
  performance,
  network,
  robustness,
  monitoring,
  ui,
  data,
  ai,
  collaboration,
}

enum ComponentLevel {
  infrastructure,    // Level 1: Core infrastructure
  service,         // Level 2: Core services
  manager,         // Level 3: Feature managers
  feature,         // Level 4: Application features
  utility,         // Level 5: Utilities and helpers
}

enum HierarchyEventType {
  initialized,
  componentAdded,
  componentRemoved,
  componentUpdated,
  validationFailed,
  hierarchyRebuilt,
}

enum ComponentLifecycleEventType {
  registered,
  activated,
  deactivated,
  unregistered,
  error,
}

enum HierarchyIssueType {
  circularDependency,
  orphanedComponent,
  missingDependency,
  deepHierarchy,
  validationError,
}

enum IssueSeverity {
  info,
  warning,
  error,
  critical,
}

class HierarchyNode {
  final String name;
  final ComponentCategory category;
  final ComponentLevel level;
  final String? parent;
  final List<String> dependencies;
  final Map<String, dynamic> metadata;
  final DateTime registeredAt;
  final bool isActive;

  HierarchyNode({
    required this.name,
    required this.category,
    required this.level,
    this.parent,
    required this.dependencies,
    required this.metadata,
    required this.registeredAt,
    required this.isActive,
  });
}

class TreeNode {
  final HierarchyNode node;
  final List<TreeNode> children;
  final int depth;

  TreeNode({
    required this.node,
    required this.children,
    required this.depth,
  });
}

class HierarchyTree {
  final List<TreeNode> roots;
  final int totalComponents;
  final int totalLevels;
  final DateTime lastUpdated;

  HierarchyTree({
    required this.roots,
    required this.totalComponents,
    required this.totalLevels,
    required this.lastUpdated,
  });
}

class HierarchyEvent {
  final HierarchyEventType type;
  final DateTime timestamp;
  final String? componentName;
  final String? details;

  HierarchyEvent({
    required this.type,
    required this.timestamp,
    this.componentName,
    this.details,
  });
}

class ComponentLifecycleEvent {
  final ComponentLifecycleEventType type;
  final DateTime timestamp;
  final String componentName;

  ComponentLifecycleEvent({
    required this.type,
    required this.timestamp,
    required this.componentName,
  });
}

class HierarchyIssue {
  final HierarchyIssueType type;
  final IssueSeverity severity;
  final String description;
  final List<String> components;

  HierarchyIssue({
    required this.type,
    required this.severity,
    required this.description,
    required this.components,
  });
}

class HierarchyValidationResult {
  final bool isValid;
  final List<HierarchyIssue> issues;
  final List<HierarchyIssue> warnings;
  final int totalComponents;
  final int maxDepth;
  final DateTime validatedAt;

  HierarchyValidationResult({
    required this.isValid,
    required this.issues,
    required this.warnings,
    required this.totalComponents,
    required this.maxDepth,
    required this.validatedAt,
  });
}

class ComponentStatistics {
  final int totalComponents;
  final Map<ComponentCategory, int> categoryDistribution;
  final Map<ComponentLevel, int> levelDistribution;
  final double averageDependencies;
  final int maxDependencies;
  final int orphanedComponents;
  final int circularDependencies;
  final DateTime lastUpdated;

  ComponentStatistics({
    required this.totalComponents,
    required this.categoryDistribution,
    required this.levelDistribution,
    required this.averageDependencies,
    required this.maxDependencies,
    required this.orphanedComponents,
    required this.circularDependencies,
    required this.lastUpdated,
  });
}
