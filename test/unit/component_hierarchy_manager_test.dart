import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:isuite/core/component_hierarchy_manager.dart';
import 'package:isuite/core/central_config.dart';

// Generate mocks
@GenerateMocks([CentralConfig])
import 'component_hierarchy_manager_test.mocks.dart';

void main() {
  late ComponentHierarchyManager hierarchyManager;
  late MockCentralConfig mockConfig;

  setUp(() {
    mockConfig = MockCentralConfig();
    hierarchyManager = ComponentHierarchyManager._internal();
  });

  tearDown(() {
    hierarchyManager.dispose();
  });

  group('ComponentHierarchyManager - Initialization', () {
    test('should be a singleton', () {
      final instance1 = ComponentHierarchyManager();
      final instance2 = ComponentHierarchyManager();
      expect(instance1, equals(instance2));
    });

    test('should initialize with correct structure', () {
      expect(hierarchyManager.level1Components, isA<List<String>>());
      expect(hierarchyManager.level2Components, isA<List<String>>());
      expect(hierarchyManager.level3Components, isA<List<String>>());
      expect(hierarchyManager.level4Components, isA<List<String>>());
      expect(hierarchyManager.level5Components, isA<List<String>>());
    });
  });

  group('ComponentHierarchyManager - Component Registration', () {
    test('should register component successfully', () {
      const componentName = 'TestComponent';
      const level = 3;

      final result = hierarchyManager.registerComponent(
        componentName,
        level,
        'Test component description'
      );

      expect(result, isTrue);
      expect(hierarchyManager.level3Components.contains(componentName), isTrue);
    });

    test('should reject invalid component levels', () {
      const componentName = 'InvalidComponent';

      final result = hierarchyManager.registerComponent(
        componentName,
        6, // Invalid level
        'Test component description'
      );

      expect(result, isFalse);
      expect(hierarchyManager.level1Components.contains(componentName), isFalse);
      expect(hierarchyManager.level2Components.contains(componentName), isFalse);
      expect(hierarchyManager.level3Components.contains(componentName), isFalse);
      expect(hierarchyManager.level4Components.contains(componentName), isFalse);
      expect(hierarchyManager.level5Components.contains(componentName), isFalse);
    });

    test('should prevent duplicate component registration', () {
      const componentName = 'DuplicateComponent';

      // First registration should succeed
      final firstResult = hierarchyManager.registerComponent(
        componentName,
        2,
        'Test component description'
      );
      expect(firstResult, isTrue);

      // Second registration should fail
      final secondResult = hierarchyManager.registerComponent(
        componentName,
        2,
        'Test component description'
      );
      expect(secondResult, isFalse);
    });

    test('should validate component names', () {
      // Valid name
      expect(hierarchyManager._isValidComponentName('ValidComponent'), isTrue);

      // Invalid names
      expect(hierarchyManager._isValidComponentName(''), isFalse);
      expect(hierarchyManager._isValidComponentName('Component With Spaces'), isFalse);
      expect(hierarchyManager._isValidComponentName('Component-With-Dashes'), isFalse);
      expect(hierarchyManager._isValidComponentName('Component.With.Dots'), isFalse);
      expect(hierarchyManager._isValidComponentName('component_lowercase'), isFalse);
    });
  });

  group('ComponentHierarchyManager - Component Relationships', () {
    test('should establish parent-child relationships', () {
      const parentComponent = 'ParentComponent';
      const childComponent = 'ChildComponent';

      hierarchyManager.registerComponent(parentComponent, 2, 'Parent component');
      hierarchyManager.registerComponent(childComponent, 3, 'Child component');

      hierarchyManager.setParentChildRelationship(parentComponent, childComponent);

      final children = hierarchyManager.getChildComponents(parentComponent);
      expect(children.contains(childComponent), isTrue);

      final parent = hierarchyManager.getParentComponent(childComponent);
      expect(parent, equals(parentComponent));
    });

    test('should prevent circular relationships', () {
      const componentA = 'ComponentA';
      const componentB = 'ComponentB';
      const componentC = 'ComponentC';

      hierarchyManager.registerComponent(componentA, 2, 'Component A');
      hierarchyManager.registerComponent(componentB, 3, 'Component B');
      hierarchyManager.registerComponent(componentC, 4, 'Component C');

      // Create relationships: A -> B -> C
      hierarchyManager.setParentChildRelationship(componentA, componentB);
      hierarchyManager.setParentChildRelationship(componentB, componentC);

      // Try to create circular relationship: C -> A (should fail)
      final result = hierarchyManager.setParentChildRelationship(componentC, componentA);
      expect(result, isFalse);

      // Verify no circular relationship was created
      final childrenOfC = hierarchyManager.getChildComponents(componentC);
      expect(childrenOfC.contains(componentA), isFalse);
    });

    test('should handle component dependencies', () {
      const dependentComponent = 'DependentComponent';
      const dependencyComponent = 'DependencyComponent';

      hierarchyManager.registerComponent(dependentComponent, 3, 'Dependent component');
      hierarchyManager.registerComponent(dependencyComponent, 2, 'Dependency component');

      hierarchyManager.addComponentDependency(dependentComponent, dependencyComponent);

      final dependencies = hierarchyManager.getComponentDependencies(dependentComponent);
      expect(dependencies.contains(dependencyComponent), isTrue);

      final dependents = hierarchyManager.getComponentDependents(dependencyComponent);
      expect(dependents.contains(dependentComponent), isTrue);
    });

    test('should validate relationship constraints', () {
      const level2Component = 'Level2Component';
      const level4Component = 'Level4Component';

      hierarchyManager.registerComponent(level2Component, 2, 'Level 2 component');
      hierarchyManager.registerComponent(level4Component, 4, 'Level 4 component');

      // Level 2 cannot be child of Level 4 (higher level numbers are lower in hierarchy)
      final result = hierarchyManager.setParentChildRelationship(level4Component, level2Component);
      expect(result, isFalse);
    });
  });

  group('ComponentHierarchyManager - Hierarchy Validation', () {
    test('should validate complete hierarchy', () {
      // Register components at all levels
      hierarchyManager.registerComponent('Level1Comp', 1, 'Level 1');
      hierarchyManager.registerComponent('Level2Comp', 2, 'Level 2');
      hierarchyManager.registerComponent('Level3Comp', 3, 'Level 3');
      hierarchyManager.registerComponent('Level4Comp', 4, 'Level 4');
      hierarchyManager.registerComponent('Level5Comp', 5, 'Level 5');

      // Establish relationships
      hierarchyManager.setParentChildRelationship('Level1Comp', 'Level2Comp');
      hierarchyManager.setParentChildRelationship('Level2Comp', 'Level3Comp');
      hierarchyManager.setParentChildRelationship('Level3Comp', 'Level4Comp');
      hierarchyManager.setParentChildRelationship('Level4Comp', 'Level5Comp');

      final validationResult = hierarchyManager.validateHierarchy();

      expect(validationResult.isValid, isTrue);
      expect(validationResult.errors.isEmpty, isTrue);
    });

    test('should detect orphaned components', () {
      hierarchyManager.registerComponent('OrphanedComp', 3, 'Orphaned component');
      hierarchyManager.registerComponent('ConnectedComp', 2, 'Connected component');

      // Don't connect the orphaned component

      final validationResult = hierarchyManager.validateHierarchy();

      expect(validationResult.isValid, isFalse);
      expect(validationResult.errors.contains('Orphaned components found'), isTrue);
    });

    test('should detect circular dependencies', () {
      const componentA = 'ComponentA';
      const componentB = 'ComponentB';

      hierarchyManager.registerComponent(componentA, 2, 'Component A');
      hierarchyManager.registerComponent(componentB, 3, 'Component B');

      // Create dependency cycle
      hierarchyManager.addComponentDependency(componentA, componentB);
      hierarchyManager.addComponentDependency(componentB, componentA);

      final validationResult = hierarchyManager.validateHierarchy();

      expect(validationResult.isValid, isFalse);
      expect(validationResult.errors.contains('Circular dependencies detected'), isTrue);
    });

    test('should validate component metadata', () {
      hierarchyManager.registerComponent('TestComp', 2, 'Test component');

      final metadata = hierarchyManager.getComponentMetadata('TestComp');

      expect(metadata, isNotNull);
      expect(metadata!['name'], equals('TestComp'));
      expect(metadata!['level'], equals(2));
      expect(metadata!['description'], equals('Test component'));
    });
  });

  group('ComponentHierarchyManager - Component Queries', () {
    test('should find components by level', () {
      hierarchyManager.registerComponent('Level2A', 2, 'Level 2 A');
      hierarchyManager.registerComponent('Level2B', 2, 'Level 2 B');
      hierarchyManager.registerComponent('Level3A', 3, 'Level 3 A');

      final level2Components = hierarchyManager.getComponentsByLevel(2);
      expect(level2Components.length, equals(2));
      expect(level2Components.contains('Level2A'), isTrue);
      expect(level2Components.contains('Level2B'), isTrue);

      final level3Components = hierarchyManager.getComponentsByLevel(3);
      expect(level3Components.length, equals(1));
      expect(level3Components.contains('Level3A'), isTrue);
    });

    test('should get component hierarchy path', () {
      const level1 = 'Level1Comp';
      const level2 = 'Level2Comp';
      const level3 = 'Level3Comp';

      hierarchyManager.registerComponent(level1, 1, 'Level 1');
      hierarchyManager.registerComponent(level2, 2, 'Level 2');
      hierarchyManager.registerComponent(level3, 3, 'Level 3');

      hierarchyManager.setParentChildRelationship(level1, level2);
      hierarchyManager.setParentChildRelationship(level2, level3);

      final path = hierarchyManager.getComponentHierarchyPath(level3);

      expect(path.length, equals(3));
      expect(path[0], equals(level1));
      expect(path[1], equals(level2));
      expect(path[2], equals(level3));
    });

    test('should detect components with issues', () {
      const healthyComponent = 'HealthyComp';
      const problematicComponent = 'ProblemComp';

      hierarchyManager.registerComponent(healthyComponent, 2, 'Healthy component');
      hierarchyManager.registerComponent(problematicComponent, 3, 'Problem component');

      // Don't connect problematic component (making it orphaned)

      final componentsWithIssues = hierarchyManager.getComponentsWithIssues();

      expect(componentsWithIssues.contains(problematicComponent), isTrue);
      expect(componentsWithIssues.contains(healthyComponent), isFalse);
    });
  });

  group('ComponentHierarchyManager - Performance and Memory', () {
    test('should handle large number of components efficiently', () {
      // Register many components
      for (int i = 0; i < 100; i++) {
        hierarchyManager.registerComponent('Component$i', 3, 'Test component $i');
      }

      final level3Components = hierarchyManager.getComponentsByLevel(3);
      expect(level3Components.length, equals(100));
    });

    test('should clean up resources on dispose', () {
      hierarchyManager.registerComponent('TestComp', 2, 'Test component');

      hierarchyManager.dispose();

      // Verify cleanup (this would require checking internal state)
      expect(hierarchyManager.getComponentsByLevel(2).isEmpty, isTrue);
    });
  });

  group('ComponentHierarchyManager - Integration Scenarios', () {
    test('should handle complex hierarchy with multiple branches', () {
      // Create a complex hierarchy
      const root = 'RootComp';
      const branch1Level2 = 'Branch1Level2';
      const branch1Level3 = 'Branch1Level3';
      const branch2Level2 = 'Branch2Level2';
      const branch2Level3 = 'Branch2Level3';

      hierarchyManager.registerComponent(root, 1, 'Root component');
      hierarchyManager.registerComponent(branch1Level2, 2, 'Branch 1 Level 2');
      hierarchyManager.registerComponent(branch1Level3, 3, 'Branch 1 Level 3');
      hierarchyManager.registerComponent(branch2Level2, 2, 'Branch 2 Level 2');
      hierarchyManager.registerComponent(branch2Level3, 3, 'Branch 2 Level 3');

      hierarchyManager.setParentChildRelationship(root, branch1Level2);
      hierarchyManager.setParentChildRelationship(branch1Level2, branch1Level3);
      hierarchyManager.setParentChildRelationship(root, branch2Level2);
      hierarchyManager.setParentChildRelationship(branch2Level2, branch2Level3);

      final validationResult = hierarchyManager.validateHierarchy();

      expect(validationResult.isValid, isTrue);

      // Verify branch isolation
      final branch1Children = hierarchyManager.getChildComponents(branch1Level2);
      expect(branch1Children.contains(branch1Level3), isTrue);
      expect(branch1Children.contains(branch2Level3), isFalse);
    });

    test('should handle component removal and cleanup', () {
      const parentComp = 'ParentComp';
      const childComp = 'ChildComp';

      hierarchyManager.registerComponent(parentComp, 2, 'Parent component');
      hierarchyManager.registerComponent(childComp, 3, 'Child component');

      hierarchyManager.setParentChildRelationship(parentComp, childComp);
      hierarchyManager.addComponentDependency(childComp, parentComp);

      // Remove component
      final removalResult = hierarchyManager.removeComponent(childComp);
      expect(removalResult, isTrue);

      // Verify cleanup
      final children = hierarchyManager.getChildComponents(parentComp);
      expect(children.contains(childComp), isFalse);

      final dependencies = hierarchyManager.getComponentDependencies(childComp);
      expect(dependencies.isEmpty, isTrue);
    });

    test('should export and import hierarchy configuration', () {
      // Register some components and relationships
      hierarchyManager.registerComponent('ExportComp1', 1, 'Export component 1');
      hierarchyManager.registerComponent('ExportComp2', 2, 'Export component 2');
      hierarchyManager.setParentChildRelationship('ExportComp1', 'ExportComp2');

      final exportedConfig = hierarchyManager.exportHierarchyConfiguration();

      expect(exportedConfig, isA<Map<String, dynamic>>());
      expect(exportedConfig.containsKey('components'), isTrue);
      expect(exportedConfig.containsKey('relationships'), isTrue);

      // Create new instance and import
      final newHierarchyManager = ComponentHierarchyManager._internal();
      newHierarchyManager.importHierarchyConfiguration(exportedConfig);

      // Verify import
      final importedComponents = newHierarchyManager.getComponentsByLevel(1);
      expect(importedComponents.contains('ExportComp1'), isTrue);
    });
  });

  group('ComponentHierarchyManager - Error Handling', () {
    test('should handle invalid component operations gracefully', () {
      // Try to get children of non-existent component
      final children = hierarchyManager.getChildComponents('NonExistentComponent');
      expect(children.isEmpty, isTrue);

      // Try to get parent of non-existent component
      final parent = hierarchyManager.getParentComponent('NonExistentComponent');
      expect(parent, isNull);

      // Try to get metadata of non-existent component
      final metadata = hierarchyManager.getComponentMetadata('NonExistentComponent');
      expect(metadata, isNull);
    });

    test('should validate relationship operations', () {
      // Try to create relationship with non-existent components
      final result = hierarchyManager.setParentChildRelationship('NonExistent1', 'NonExistent2');
      expect(result, isFalse);

      final dependencyResult = hierarchyManager.addComponentDependency('NonExistent1', 'NonExistent2');
      expect(dependencyResult, isFalse);
    });

    test('should handle concurrent operations', () async {
      final futures = <Future>[];

      for (int i = 0; i < 10; i++) {
        futures.add(Future(() {
          hierarchyManager.registerComponent('ConcurrentComp$i', 3, 'Concurrent component $i');
        }));
      }

      await Future.wait(futures);

      final level3Components = hierarchyManager.getComponentsByLevel(3);
      expect(level3Components.length, equals(10));
    });
  });
}
