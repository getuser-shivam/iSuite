import 'package:flutter_test/flutter_test.dart';
import 'package:isuite/core/component_registry.dart';
import 'package:isuite/core/component_factory.dart';

void main() {
  group('ComponentRegistry Tests', () {
    late ComponentRegistry registry;

    setUp(() {
      registry = ComponentRegistry.instance;
      registry.reset();
    });

    test('should be singleton', () {
      final instance1 = ComponentRegistry.instance;
      final instance2 = ComponentRegistry.instance;
      expect(instance1, equals(instance2));
    });

    test('should initialize successfully', () async {
      await registry.initialize();
      expect(registry.isInitialized, isTrue);
    });

    test('should store and retrieve parameters', () async {
      await registry.initialize();
      
      registry.setParameter('test_param', 'test_value');
      final value = registry.getParameter<String>('test_param');
      expect(value, equals('test_value'));
    });

    test('should throw error for missing parameter', () async {
      await registry.initialize();
      
      expect(() => registry.getParameter<String>('missing_param'), 
             throwsA(isA<StateError>()));
    });

    test('should return default value for parameter', () async {
      await registry.initialize();
      
      final value = registry.getParameter('missing_param', defaultValue: 'default');
      expect(value, equals('default'));
    });

    test('should update parameters', () async {
      await registry.initialize();
      
      registry.setParameter('test_param', 'initial_value');
      registry.setParameters({'test_param': 'updated_value'});
      
      final value = registry.getParameter<String>('test_param');
      expect(value, equals('updated_value'));
    });

    test('should provide component status', () async {
      await registry.initialize();
      
      final status = registry.getComponentStatus();
      expect(status['initialized'], isTrue);
      expect(status['component_count'], greaterThan(0));
      expect(status['parameter_count'], greaterThan(0));
    });
  });

  group('ComponentFactory Tests', () {
    late ComponentFactory factory;

    setUp(() {
      factory = ComponentFactory.instance;
    });

    test('should be singleton', () {
      final instance1 = ComponentFactory.instance;
      final instance2 = ComponentFactory.instance;
      expect(instance1, equals(instance2));
    });

    test('should initialize successfully', () async {
      await factory.initialize();
      expect(factory.getProviders().isNotEmpty, isTrue);
    });

    test('should validate dependencies', () {
      final isValid = factory.validateDependencies();
      expect(isValid, isTrue);
    });

    test('should provide dependency graph', () {
      final graph = factory.getDependencyGraph();
      expect(graph.isNotEmpty, isTrue);
    });

    test('should get configuration by key', () {
      final config = factory.getConfiguration('theme_provider');
      expect(config, isNotNull);
      expect(config!.type.toString(), contains('ThemeProvider'));
    });

    test('should update configuration', () {
      factory.updateConfiguration('theme_provider', {'new_param': 'new_value'});
      final config = factory.getConfiguration('theme_provider');
      expect(config!.parameters['new_param'], equals('new_value'));
    });

    test('should get all configurations', () {
      final configs = factory.getAllConfigurations();
      expect(configs.isNotEmpty, isTrue);
      expect(configs.containsKey('theme_provider'), isTrue);
    });
  });

  group('Component Integration Tests', () {
    test('should initialize factory and registry together', () async {
      await ComponentFactory.instance.initialize();
      
      final registry = ComponentRegistry.instance;
      expect(registry.isInitialized, isTrue);
      
      final factory = ComponentFactory.instance;
      expect(factory.getAllProviders().isNotEmpty, isTrue);
    });

    test('should create all providers without errors', () async {
      await ComponentFactory.instance.initialize();
      
      final providers = ComponentFactory.instance.createAllProviders();
      expect(providers.isNotEmpty, isTrue);
      
      // Verify all providers are valid instances
      for (final provider in providers) {
        expect(provider.runtimeType.toString(), contains('Provider'));
      }
    });
  });
}
