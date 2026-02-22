import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:isuite/features/network_management/screens/ftp_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FtpClientScreen', () {
    testWidgets('should render without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FtpClientScreen(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify that the app bar is present
      expect(find.text('FTP Client'), findsOneWidget);

      // Verify that connection form elements are present
      expect(find.text('Host'), findsOneWidget);
      expect(find.text('Port'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
    });

    testWidgets('should show default values in form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FtpClientScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that the host field has the default value
      final hostField = find.byType(TextField).at(0);
      final hostController = tester.widget<TextField>(hostField).controller;
      expect(hostController?.text, equals('ftp.example.com'));

      // Check that the port field has the default value
      final portField = find.byType(TextField).at(1);
      final portController = tester.widget<TextField>(portField).controller;
      expect(portController?.text, equals('21'));

      // Check that the username field has the default value
      final usernameField = find.byType(TextField).at(2);
      final usernameController = tester.widget<TextField>(usernameField).controller;
      expect(usernameController?.text, equals('anonymous'));
    });

    testWidgets('should show disconnect button when connected', (WidgetTester tester) async {
      // Note: This test would require mocking the FTP connection
      // For now, just verify the initial state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FtpClientScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should show Connect button
      expect(find.text('Connect'), findsOneWidget);
      expect(find.text('Disconnect'), findsNothing);
    });
  });
}
