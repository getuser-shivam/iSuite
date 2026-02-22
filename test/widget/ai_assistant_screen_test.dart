import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/core/central_config.dart';
import '../../../lib/features/ai_assistant/ai_assistant_screen.dart';

void main() {
  setUp(() async {
    await CentralConfig.instance.initialize();
  });

  group('AiAssistantScreen', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AiAssistantScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('AI Assistant'), findsOneWidget);
      expect(find.text('Hello! I\'m your AI file management assistant. How can I help you today?'), findsOneWidget);
      expect(find.text('Ask me about file management, organization, search...'), findsOneWidget);
    });

    testWidgets('can send message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AiAssistantScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'organize files');
      await tester.tap(find.text('Send'));
      await tester.pump();

      expect(find.text('organize files'), findsOneWidget);
      expect(find.textContaining('AI File Organization'), findsOneWidget);
    });

    testWidgets('shows different responses for different queries', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AiAssistantScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Test search query
      await tester.enterText(find.byType(TextField), 'search files');
      await tester.tap(find.text('Send'));
      await tester.pump();

      expect(find.textContaining('AI-Powered Search'), findsOneWidget);

      // Test network query
      await tester.enterText(find.byType(TextField), 'network tools');
      await tester.tap(find.text('Send'));
      await tester.pump();

      expect(find.textContaining('Network Diagnostics'), findsOneWidget);

      // Test FTP query
      await tester.enterText(find.byType(TextField), 'ftp upload');
      await tester.tap(find.text('Send'));
      await tester.pump();

      expect(find.textContaining('FTP File Transfer'), findsOneWidget);
    });

    testWidgets('handles empty message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AiAssistantScreen(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Send'));
      await tester.pump();

      // Should not add empty message
      expect(find.text('Hello! I\'m your AI file management assistant. How can I help you today?'), findsOneWidget);
    });

    testWidgets('scrolls to bottom on new messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AiAssistantScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Add several messages to test scrolling
      for (int i = 0; i < 5; i++) {
        await tester.enterText(find.byType(TextField), 'test message $i');
        await tester.tap(find.text('Send'));
        await tester.pump();
      }

      // Should have multiple messages
      expect(find.textContaining('test message'), findsWidgets);
    });

    testWidgets('timestamps are displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AiAssistantScreen(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test');
      await tester.tap(find.text('Send'));
      await tester.pump();

      // Should show timestamps (format like HH:MM)
      expect(find.textContaining(':'), findsWidgets);
    });

    testWidgets('default response for unknown queries', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AiAssistantScreen(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'unknown query xyz');
      await tester.tap(find.text('Send'));
      await tester.pump();

      expect(find.textContaining('I understand you\'re asking about'), findsOneWidget);
      expect(find.textContaining('unknown query xyz'), findsOneWidget);
    });
  });
}
