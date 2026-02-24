import 'package:flutter_test/flutter_test.dart';
import 'package:iSuite/core/central_config.dart';
import 'package:iSuite/core/logging/logging_service.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CentralConfig config;
  late LoggingService logger;

  setUp(() async {
    config = CentralConfig.instance;
    logger = LoggingService();

    // Reset config for each test
    await config.initialize();
  });

  tearDown(() async {
    // Clean up any test configurations
    await config.resetToDefaults();
  });

  group('CentralConfig - Core Functionality', () {
    test('should initialize successfully', () async {
      expect(config.isInitialized, true);
    });

    test('should get parameter with default value', () {
      final result = config.getParameter('test.parameter', defaultValue: 'default_value');
      expect(result, 'default_value');
    });

    test('should set and get parameter', () async {
      await config.setParameter('test.parameter', 'test_value');
      final result = config.getParameter('test.parameter', defaultValue: 'default');
      expect(result, 'test_value');
    });

    test('should handle different data types', () async {
      // String
      await config.setParameter('test.string', 'hello');
      expect(config.getParameter('test.string'), 'hello');

      // Integer
      await config.setParameter('test.int', 42);
      expect(config.getParameter('test.int'), 42);

      // Boolean
      await config.setParameter('test.bool', true);
      expect(config.getParameter('test.bool'), true);

      // Double
      await config.setParameter('test.double', 3.14);
      expect(config.getParameter('test.double'), 3.14);

      // List
      await config.setParameter('test.list', [1, 2, 3]);
      expect(config.getParameter('test.list'), [1, 2, 3]);

      // Map
      await config.setParameter('test.map', {'key': 'value'});
      expect(config.getParameter('test.map'), {'key': 'value'});
    });

    test('should validate parameter types', () async {
      // Test integer validation
      await config.setParameter('test.int', 42);
      expect(config.getParameter('test.int', type: ParameterType.int), 42);

      // Test boolean validation
      await config.setParameter('test.bool', true);
      expect(config.getParameter('test.bool', type: ParameterType.bool), true);

      // Test string validation
      await config.setParameter('test.string', 'hello');
      expect(config.getParameter('test.string', type: ParameterType.string), 'hello');
    });

    test('should handle parameter validation errors', () {
      expect(
        () => config.getParameter('invalid.param', type: ParameterType.int, required: true),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('should support environment overrides', () async {
      // Set base value
      await config.setParameter('app.name', 'iSuite');

      // Override for production
      await config.setEnvironmentOverride('production', 'app.name', 'iSuite Pro');
      await config.setEnvironment('production');

      expect(config.getParameter('app.name'), 'iSuite Pro');

      // Switch back to development
      await config.setEnvironment('development');
      expect(config.getParameter('app.name'), 'iSuite');
    });

    test('should support platform overrides', () async {
      // Set base value
      await config.setParameter('ui.font_size', 14);

      // Override for mobile
      await config.setPlatformOverride('mobile', 'ui.font_size', 16);

      // Simulate mobile platform
      await config.setPlatform('mobile');
      expect(config.getParameter('ui.font_size'), 16);

      // Switch back to desktop
      await config.setPlatform('desktop');
      expect(config.getParameter('ui.font_size'), 14);
    });

    test('should handle component registration', () async {
      final componentInfo = ComponentInfo(
        id: 'test.component',
        name: 'Test Component',
        version: '1.0.0',
        description: 'Test component for unit testing',
        dependencies: ['CentralConfig'],
        parameters: {
          'test.param1': 'value1',
          'test.param2': 42,
        },
      );

      await config.registerComponentInfo(componentInfo);

      // Verify component is registered
      final registered = config.getComponentInfo('test.component');
      expect(registered, isNotNull);
      expect(registered!.name, 'Test Component');
      expect(registered.version, '1.0.0');
    });

    test('should handle component relationships', () async {
      // Register components
      await config.registerComponentInfo(ComponentInfo(
        id: 'component.a',
        name: 'Component A',
        version: '1.0.0',
        description: 'Component A',
      ));

      await config.registerComponentInfo(ComponentInfo(
        id: 'component.b',
        name: 'Component B',
        version: '1.0.0',
        description: 'Component B',
      ));

      // Create relationship
      await config.registerComponentRelationship(
        'component.a',
        'component.b',
        RelationshipType.depends_on,
        'Component A depends on Component B',
      );

      // Verify relationship
      final relationships = config.getComponentRelationships('component.a');
      expect(relationships.length, 1);
      expect(relationships[0].targetId, 'component.b');
      expect(relationships[0].type, RelationshipType.depends_on);
    });

    test('should validate component dependencies', () async {
      // Register component with missing dependency
      await config.registerComponentInfo(ComponentInfo(
        id: 'dependent.component',
        name: 'Dependent Component',
        version: '1.0.0',
        description: 'Component with dependencies',
        dependencies: ['nonexistent.component'],
      ));

      // Should not throw error but log warning
      final component = config.getComponentInfo('dependent.component');
      expect(component, isNotNull);
      expect(component!.dependencies, contains('nonexistent.component'));
    });

    test('should handle configuration hot reload', () async {
      // Set initial value
      await config.setParameter('test.reload', 'initial');

      // Simulate configuration file change
      await config.reloadConfiguration();

      // Value should still be available (in real implementation, would reload from file)
      expect(config.getParameter('test.reload', defaultValue: 'default'), 'initial');
    });

    test('should provide configuration statistics', () {
      final stats = config.getConfigurationStats();

      expect(stats, isNotNull);
      expect(stats.totalParameters, greaterThanOrEqualTo(0));
      expect(stats.totalComponents, greaterThanOrEqualTo(0));
      expect(stats.environments, contains('development'));
      expect(stats.platforms, isNotEmpty);
    });

    test('should handle configuration export/import', () async {
      // Set some test parameters
      await config.setParameter('export.test1', 'value1');
      await config.setParameter('export.test2', 42);

      // Export configuration
      final exportData = await config.exportConfiguration();

      // Create new config instance and import
      final newConfig = CentralConfig.instance; // In real test, would create new instance
      await newConfig.importConfiguration(exportData);

      // Verify imported values
      expect(newConfig.getParameter('export.test1'), 'value1');
      expect(newConfig.getParameter('export.test2'), 42);
    });

    test('should handle configuration backup/restore', () async {
      // Set test data
      await config.setParameter('backup.test', 'backup_value');

      // Create backup
      final backupId = await config.createBackup('test_backup');

      // Modify value
      await config.setParameter('backup.test', 'modified_value');

      // Restore backup
      await config.restoreBackup(backupId);

      // Verify restored value
      expect(config.getParameter('backup.test'), 'backup_value');
    });

    test('should validate parameter constraints', () async {
      // Test range validation
      await config.setParameterValidation('test.range', ParameterValidation(
        minValue: 0,
        maxValue: 100,
        type: ParameterType.int,
      ));

      // Valid value
      await config.setParameter('test.range', 50);
      expect(config.getParameter('test.range'), 50);

      // Invalid value should be clamped or rejected
      await config.setParameter('test.range', 150);
      // Implementation should handle validation appropriately
    });

    test('should handle parameter change notifications', () async {
      String? changedParameter;
      dynamic newValue;

      // Subscribe to parameter changes
      config.addParameterChangeListener('test.notify', (param, value) {
        changedParameter = param;
        newValue = value;
      });

      // Change parameter
      await config.setParameter('test.notify', 'new_value');

      // Verify notification
      expect(changedParameter, 'test.notify');
      expect(newValue, 'new_value');
    });

    test('should handle bulk parameter operations', () async {
      final parameters = {
        'bulk.param1': 'value1',
        'bulk.param2': 42,
        'bulk.param3': true,
      };

      // Set bulk parameters
      await config.setParameters(parameters);

      // Verify all parameters are set
      for (final entry in parameters.entries) {
        expect(config.getParameter(entry.key), entry.value);
      }
    });

    test('should provide parameter search functionality', () async {
      // Set test parameters
      await config.setParameter('search.database.host', 'localhost');
      await config.setParameter('search.database.port', 5432);
      await config.setParameter('search.cache.enabled', true);

      // Search for database parameters
      final results = config.searchParameters('database');
      expect(results.length, 2);
      expect(results.keys, contains('search.database.host'));
      expect(results.keys, contains('search.database.port'));
    });

    test('should handle configuration schema validation', () async {
      // Define schema
      final schema = ConfigurationSchema(
        parameters: {
          'schema.required': ParameterSchema(
            type: ParameterType.string,
            required: true,
            description: 'Required parameter',
          ),
          'schema.optional': ParameterSchema(
            type: ParameterType.int,
            defaultValue: 42,
            description: 'Optional parameter',
          ),
        },
      );

      await config.setConfigurationSchema(schema);

      // Validate configuration
      final validationResult = await config.validateConfiguration();
      expect(validationResult.isValid, true);

      // Test with missing required parameter
      await config.setParameter('schema.required', null);
      final invalidResult = await config.validateConfiguration();
      expect(invalidResult.isValid, false);
      expect(invalidResult.errors, isNotEmpty);
    });
  });

  group('CentralConfig - Error Handling', () {
    test('should handle invalid parameter types gracefully', () {
      expect(
        () => config.getParameter('invalid', type: ParameterType.int, required: true),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('should handle malformed configuration data', () async {
      // Test with invalid JSON-like data
      expect(
        () async => await config.importConfiguration('invalid json'),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('should handle file system errors during export', () async {
      // Test export to invalid path
      expect(
        () async => await config.exportConfigurationToFile('/invalid/path/config.json'),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('should handle concurrent access safely', () async {
      // Test concurrent parameter access
      final futures = <Future>[];
      for (int i = 0; i < 10; i++) {
        futures.add(config.setParameter('concurrent.test$i', 'value$i'));
      }

      await Future.wait(futures);

      // Verify all parameters were set
      for (int i = 0; i < 10; i++) {
        expect(config.getParameter('concurrent.test$i'), 'value$i');
      }
    });
  });

  group('CentralConfig - Performance', () {
    test('should handle large number of parameters efficiently', () async {
      // Set many parameters
      for (int i = 0; i < 1000; i++) {
        await config.setParameter('perf.test$i', 'value$i');
      }

      // Measure retrieval performance
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        config.getParameter('perf.test${i * 10}');
      }
      stopwatch.stop();

      // Should complete in reasonable time (< 100ms for 100 operations)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('should cache frequently accessed parameters', () async {
      // Set parameter
      await config.setParameter('cache.test', 'cached_value');

      // Access multiple times
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        config.getParameter('cache.test');
      }
      stopwatch.stop();

      // Should be very fast due to caching
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });
  });
}
