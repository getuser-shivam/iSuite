import 'dart:async';
import 'package:flutter/foundation.dart';
import 'central_config.dart';

/// Enhanced Parameterization System
/// Ensures all components are well-connected and centrally configured
class EnhancedParameterization {
  final CentralConfig _config;
  final Map<String, dynamic> _componentRegistry = {};
  final Map<String, List<String>> _componentDependencies = {};
  final Map<String, Map<String, dynamic>> _parameterMappings = {};
  final StreamController<Map<String, dynamic>> _parameterChangeController =
      StreamController.broadcast();

  EnhancedParameterization(this._config) {
    _initializeParameterization();
    _setupParameterChangeMonitoring();
  }

  /// Initialize comprehensive parameterization
  void _initializeParameterization() {
    // Register all core parameters
    _config.setParameter('app_name', 'iSuite Enhanced');
    _config.setParameter('app_version', '2.0.0');
    _config.setParameter('build_number', 1);
    _config.setParameter('environment', 'development');

    // Network parameters
    _config.setParameter('network_timeout', Duration(seconds: 30));
    _config.setParameter('max_file_size', 100 * 1024 * 1024); // 100MB
    _config.setParameter(
        'supported_protocols', ['http', 'ftp', 'websocket', 'qr_code']);
    _config.setParameter('encryption_enabled', true);
    _config.setParameter('compression_algorithms', ['gzip', 'zip', 'lz4']);

    // AI parameters
    _config.setParameter('ai_enabled', true);
    _config.setParameter('ai_optimization_level', 'aggressive');
    _config.setParameter('ai_learning_enabled', true);
    _config.setParameter('ai_prediction_accuracy', 0.85);

    // UI parameters
    _config.setParameter('theme_mode', 'system');
    _config.setParameter('animation_duration', Duration(milliseconds: 300));
    _config.setParameter('cache_size', 50 * 1024 * 1024); // 50MB

    debugPrint(
        'EnhancedParameterization: Initialized with ${_config.getAllParameters().length} parameters');
  }

  /// Setup parameter change monitoring
  void _setupParameterChangeMonitoring() {
    _parameterChangeController.stream.listen((changes) {
      _handleParameterChanges(changes);
    });
  }

  /// Handle parameter changes
  void _handleParameterChanges(Map<String, dynamic> changes) {
    for (final entry in changes.entries) {
      final parameterName = entry.key;
      final oldValue = entry.value['old'];
      final newValue = entry.value['new'];

      // Update parameter mappings
      _updateParameterMappings(parameterName, newValue);

      // Notify dependent components
      _notifyParameterChange(parameterName, oldValue, newValue);

      debugPrint('Parameter changed: $parameterName = $newValue');
    }
  }

  /// Update parameter mappings
  void _updateParameterMappings(String parameterName, dynamic newValue) {
    // Update component-specific parameters
    switch (parameterName) {
      case 'network_timeout':
        _updateNetworkComponents(newValue as Duration);
        break;
      case 'max_file_size':
        _updateFileManagementComponents(newValue as int);
        break;
      case 'encryption_enabled':
        _updateSecurityComponents(newValue as bool);
        break;
      case 'ai_optimization_level':
        _updateAIComponents(newValue as String);
        break;
      case 'theme_mode':
        _updateUIComponents(newValue as String);
        break;
    }
  }

  /// Update network components
  void _updateNetworkComponents(Duration timeout) {
    _config.setParameter('http_timeout', timeout.inSeconds);
    _config.setParameter('ftp_timeout', timeout.inSeconds);
    _config.setParameter('websocket_timeout', timeout.inSeconds);
  }

  /// Update file management components
  void _updateFileManagementComponents(int maxSize) {
    _config.setParameter('max_upload_size', maxSize);
    _config.setParameter('max_download_size', maxSize);
    _config.setParameter('chunk_size', 64 * 1024); // 64KB chunks
  }

  /// Update security components
  void _updateSecurityComponents(bool encryptionEnabled) {
    _config.setParameter('aes_encryption_enabled', encryptionEnabled);
    _config.setParameter('file_integrity_check', encryptionEnabled);
    _config.setParameter('secure_transfer', encryptionEnabled);
  }

  /// Update AI components
  void _updateAIComponents(String optimizationLevel) {
    _config.setParameter('ai_optimization_mode', optimizationLevel);
    _config.setParameter('ml_model_path', 'assets/models/ai_model.tflite');
    _config.setParameter('prediction_confidence', 0.85);
    _config.setParameter('auto_optimization', true);
  }

  /// Update UI components
  void _updateUIComponents(String themeMode) {
    _config.setParameter('primary_color', _getThemeColor(themeMode));
    _config.setParameter('font_size', _getThemeFontSize(themeMode));
    _config.setParameter('border_radius', _getThemeBorderRadius(themeMode));
    _config.setParameter('animation_curve', _getThemeAnimationCurve(themeMode));
  }

  /// Get theme color based on mode
  String _getThemeColor(String mode) {
    switch (mode) {
      case 'light':
        return '#2196F3';
      case 'dark':
        return '#121212';
      case 'system':
        return '#37474F';
      default:
        return '#1976D2';
    }
  }

  /// Get theme font size based on mode
  double _getThemeFontSize(String mode) {
    switch (mode) {
      case 'light':
        return 14.0;
      case 'dark':
        return 16.0;
      case 'system':
        return 15.0;
      default:
        return 14.0;
    }
  }

  /// Get theme border radius based on mode
  double _getThemeBorderRadius(String mode) {
    switch (mode) {
      case 'light':
        return 8.0;
      case 'dark':
        return 12.0;
      case 'system':
        return 10.0;
      default:
        return 8.0;
    }
  }

  /// Get theme animation curve based on mode
  String _getThemeAnimationCurve(String mode) {
    switch (mode) {
      case 'light':
        return 'Curves.easeInOut';
      case 'dark':
        return 'Curves.easeInOut';
      case 'system':
        return 'Curves.easeInOut';
      default:
        return 'Curves.easeInOut';
    }
  }

  /// Register component with dependencies
  void registerComponent(String componentId, String componentType,
      Map<String, dynamic> parameters, List<String> dependencies) {
    _componentRegistry[componentId] = {
      'type': componentType,
      'parameters': parameters,
      'dependencies': dependencies,
      'registered_at': DateTime.now().toIso8601String(),
    };

    _componentDependencies[componentId] = dependencies;

    debugPrint('Component registered: $componentId ($componentType)');
  }

  /// Establish relationship between components
  void establishRelationship(String parentId, String childId) {
    if (!_componentDependencies.containsKey(parentId)) {
      _componentDependencies[parentId] = <String>[];
    }
    _componentDependencies[parentId].add(childId);

    debugPrint('Relationship established: $parentId -> $childId');
  }

  /// Get component registry
  Map<String, dynamic> getComponentRegistry() {
    return Map.from(_componentRegistry);
  }

  /// Get component dependencies
  Map<String, List<String>> getComponentDependencies() {
    return Map.from(_componentDependencies);
  }

  /// Get parameter value
  T getParameter<T>(String parameterName, [T defaultValue]) {
    return _config.getParameter(parameterName, defaultValue: defaultValue);
  }

  /// Set parameter value
  void setParameter<T>(String parameterName, T value) {
    _config.setParameter(parameterName, value);
    _parameterChangeController.add({
      'parameter': parameterName,
      'old': _config.getParameter(parameterName),
      'new': value,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Get all parameters
  Map<String, dynamic> getAllParameters() {
    return _config.getAllParameters();
  }

  /// Get parameter change stream
  Stream<Map<String, dynamic>> get parameterChangeStream =>
      _parameterChangeController.stream;

  /// Validate component connections
  bool validateConnections() {
    bool isValid = true;
    final issues = <String>[];

    // Check for circular dependencies
    for (final entry in _componentDependencies.entries) {
      if (_hasCircularDependency(entry.key, entry.value)) {
        issues.add('Circular dependency detected: ${entry.key}');
        isValid = false;
      }
    }

    // Check for missing dependencies
    for (final entry in _componentDependencies.entries) {
      for (final dependency in entry.value) {
        if (!_componentRegistry.containsKey(dependency)) {
          issues.add(
              'Missing dependency: $dependency for component ${entry.key}');
          isValid = false;
        }
      }
    }

    if (issues.isNotEmpty) {
      debugPrint('Component validation issues: ${issues.join(', ')}');
    }

    return isValid;
  }

  /// Check for circular dependencies
  bool _hasCircularDependency(String componentId, List<String> dependencies) {
    final visited = <String>{};

    bool hasCircularDependency(String currentId, List<String> currentDeps) {
      if (visited.contains(currentId)) return true;
      visited.add(currentId);

      for (final dep in currentDeps) {
        if (_hasCircularDependency(dep, currentDeps)) {
          return true;
        }
      }

      visited.remove(currentId);
      return false;
    }

    return _hasCircularDependency(componentId, dependencies);
  }

  /// Generate component health report
  Map<String, dynamic> generateHealthReport() {
    final report = <String, dynamic>{};

    int totalComponents = _componentRegistry.length;
    int healthyComponents = 0;
    int componentsWithIssues = 0;

    for (final entry in _componentRegistry.entries) {
      final isHealthy = _validateComponent(entry.key);
      if (isHealthy) {
        healthyComponents++;
      } else {
        componentsWithIssues++;
      }

      report[entry.key] = {
        'health': isHealthy ? 'healthy' : 'unhealthy',
        'dependencies': entry.value['dependencies'],
        'last_validated': entry.value['registered_at'],
        'issues': isHealthy ? [] : ['validation_failed'],
      };
    }

    report['summary'] = {
      'total_components': totalComponents,
      'healthy_components': healthyComponents,
      'components_with_issues': componentsWithIssues,
      'health_score': totalComponents > 0
          ? (healthyComponents / totalComponents) * 100
          : 100,
      'generated_at': DateTime.now().toIso8601String(),
    };

    return report;
  }

  /// Validate single component
  bool _validateComponent(String componentId) {
    final component = _componentRegistry[componentId];
    if (component == null) return false;

    // Check if component has required parameters
    final requiredParams = _getRequiredParameters(component['type']);
    for (final param in requiredParams) {
      if (!component['parameters'].containsKey(param)) {
        return false;
      }
    }

    return true;
  }

  /// Get required parameters for component type
  List<String> _getRequiredParameters(String componentType) {
    switch (componentType) {
      case 'network':
        return ['network_timeout', 'max_file_size'];
      case 'file_management':
        return ['max_upload_size', 'chunk_size'];
      case 'security':
        return ['encryption_enabled', 'file_integrity_check'];
      case 'ui':
        return ['theme_mode', 'font_size', 'animation_curve'];
      case 'ai':
        return ['ai_enabled', 'optimization_level', 'ml_model_path'];
      default:
        return [];
    }
  }

  /// Notify parameter change
  void _notifyParameterChange(
      String parameterName, dynamic oldValue, dynamic newValue) {
    // Find dependent components
    final dependentComponents = _findDependentComponents(parameterName);

    // Update dependent components
    for (final componentId in dependentComponents) {
      if (_componentRegistry.containsKey(componentId)) {
        final component = _componentRegistry[componentId];
        final updatedParams =
            Map<String, dynamic>.from(component['parameters']);
        updatedParams[parameterName] = newValue;

        _componentRegistry[componentId] = {
          ...component,
          'parameters': updatedParams,
          'last_updated': DateTime.now().toIso8601String(),
        };

        debugPrint(
            'Updated component $componentId with parameter $parameterName = $newValue');
      }
    }
  }

  /// Find components that depend on a parameter
  List<String> _findDependentComponents(String parameterName) {
    final dependentComponents = <String>[];

    for (final entry in _componentRegistry.entries) {
      final component = entry.value;
      if (component['parameters']
          .values
          .any((param) => _parameterDependsOn(parameter, param))) {
        dependentComponents.add(entry.key);
      }
    }

    return dependentComponents;
  }

  /// Check if a parameter depends on another
  bool _parameterDependsOn(String parameter, String dependentParameter) {
    final dependencies = {
      'network_timeout': ['file_management'],
      'max_file_size': ['file_management'],
      'encryption_enabled': ['security'],
      'theme_mode': ['ui'],
      'ai_enabled': ['ai'],
    };

    return dependencies[parameter]?.contains(dependentParameter) ?? false;
  }

  /// Optimize all components based on current configuration
  Future<void> optimizeAll() async {
    debugPrint('EnhancedParameterization: Starting optimization...');

    final healthReport = generateHealthReport();

    // Apply optimizations based on health report
    for (final entry in healthReport.entries) {
      if (entry.key != 'summary' && entry.value['health'] == 'unhealthy') {
        await _optimizeComponent(entry.key);
      }
    }

    debugPrint('EnhancedParameterization: Optimization completed');
  }

  /// Optimize individual component
  Future<void> _optimizeComponent(String componentId) async {
    debugPrint(
        'EnhancedParameterization: Optimizing component $componentId...');

    // Component-specific optimization logic would go here
    await Future.delayed(Duration(milliseconds: 500));

    debugPrint('EnhancedParameterization: Component $componentId optimized');
  }

  /// Generate configuration summary
  Map<String, dynamic> generateConfigurationSummary() {
    return {
      'total_parameters': _config.getAllParameters().length,
      'total_components': _componentRegistry.length,
      'total_relationships': _componentDependencies.values
          .fold(0, (sum, deps) => sum + deps.length),
      'health_score': _generateHealthReport()['summary']['health_score'],
      'parameter_mappings': _parameterMappings,
      'last_optimization': _config.getParameter('last_optimization'),
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Dispose resources
  void dispose() {
    _parameterChangeController.close();
    debugPrint('EnhancedParameterization: Disposed');
  }
}
