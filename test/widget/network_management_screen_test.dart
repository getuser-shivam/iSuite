import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:isuite/features/network_management/screens/network_management.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NetworkManagementScreen', () {
    testWidgets('should render without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NetworkManagementScreen(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify that the app bar is present
      expect(find.text('Network Management'), findsOneWidget);

      // Verify that the current connection section is present
      expect(find.text('Current Connection'), findsOneWidget);

      // Verify that the WiFi networks label is present
      expect(find.text('WiFi Networks'), findsOneWidget);

      // Verify that the network tools section is present
      expect(find.text('Network Tools'), findsOneWidget);
    });

    testWidgets('should show network tools when expanded', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NetworkManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the Network Tools expansion tile
      final expansionTile = find.text('Network Tools');
      expect(expansionTile, findsOneWidget);

      await tester.tap(expansionTile);
      await tester.pumpAndSettle();

      // Verify that ping tool is visible
      expect(find.text('Ping'), findsOneWidget);

      // Verify that traceroute tool is visible
      expect(find.text('Traceroute'), findsOneWidget);

      // Verify that port scan fields are visible
      expect(find.text('Host'), findsOneWidget);
      expect(find.text('Port Range (e.g., 20-100)'), findsOneWidget);
    });

    testWidgets('should have scan button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NetworkManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the scan button is present
      expect(find.text('Scan Networks'), findsOneWidget);
    });
  });
}
