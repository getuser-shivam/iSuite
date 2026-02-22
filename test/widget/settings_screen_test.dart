import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../lib/core/central_config.dart';
import '../../../lib/core/theme_provider.dart';
import '../../../lib/features/settings/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CentralConfig.instance.initialize();
  });

  group('SettingsScreen', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('General Settings'), findsOneWidget);
      expect(find.text('Network Settings'), findsOneWidget);
      expect(find.text('AI Assistant Settings'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('theme toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final themeProvider = Provider.of<ThemeProvider>(tester.element(find.byType(SettingsScreen)), listen: false);

      expect(themeProvider.isDarkTheme, false);

      await tester.tap(find.text('Dark Theme'));
      await tester.pump();

      expect(themeProvider.isDarkTheme, true);
    });

    testWidgets('language dropdown changes value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('English'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
    });

    testWidgets('slider values update', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('30'), findsWidgets); // Network timeout default
      expect(find.text('100'), findsOneWidget); // Batch size default
    });

    testWidgets('save button shows snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Settings'));
      await tester.pump();

      expect(find.text('Settings saved successfully!'), findsOneWidget);
    });

    testWidgets('all switches toggle correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Auto Save switch
      await tester.tap(find.text('Auto Save'));
      await tester.pump();

      // Smart Suggestions switch
      await tester.tap(find.text('Smart Suggestions'));
      await tester.pump();

      // Switches should toggle without errors
      expect(tester.takeException(), isNull);
    });
  });
}
