import 'package:flutter_test/flutter_test.dart';
import 'package:isuite/main.dart';
import 'package:isuite/core/central_config.dart';

void main() {
  group('CentralConfig Tests', () {
    test('Configuration initialization', () async {
      final config = CentralConfig.instance;

      // Test that configuration initializes properly
      expect(config, isNotNull);
      expect(config.primaryColor, isNotNull);
      expect(config.secondaryColor, isNotNull);
    });

    test('Parameter retrieval with defaults', () {
      final config = CentralConfig.instance;

      // Test parameter retrieval with default values
      final defaultValue = config.getParameter('test_key', defaultValue: 'default');
      expect(defaultValue, equals('default'));
    });

    test('UI parameter access', () {
      final config = CentralConfig.instance;

      // Test UI parameter access
      expect(config.appTitle, isNotNull);
      expect(config.primaryColor, isNotNull);
      expect(config.secondaryColor, isNotNull);
      expect(config.surfaceColor, isNotNull);
      expect(config.defaultPadding, isNotNull);
    });
  });

  group('App Initialization Tests', () {
    testWidgets('App initializes without crashing', (WidgetTester tester) async {
      // Test that the app can start without errors
      await tester.pumpWidget(const MyApp());

      // Wait for initialization
      await tester.pumpAndSettle();

      // Verify app is running
      expect(find.byType(MyApp), findsOneWidget);
    });
  });
}
