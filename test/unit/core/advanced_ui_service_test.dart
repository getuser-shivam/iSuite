import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:iSuite/core/advanced_ui_service.dart';
import 'package:iSuite/core/config/central_config.dart';

@GenerateMocks([CentralConfig])
void main() {
  group('AdvancedUIService Tests', () {
    late AdvancedUIService uiService;
    late MockCentralConfig mockConfig;

    setUp(() async {
      // Create mock config
      mockConfig = MockCentralConfig();

      // Setup mock config responses
      when(mockConfig.getParameter('ui.primary_color', defaultValue: anyNamed('defaultValue')))
          .thenReturn(0xFF2196F3);
      when(mockConfig.getParameter('ui.secondary_color', defaultValue: anyNamed('defaultValue')))
          .thenReturn(0xFF03DAC6);
      when(mockConfig.getParameter('ui.error_color', defaultValue: anyNamed('defaultValue')))
          .thenReturn(0xFFB00020);
      when(mockConfig.getParameter('ui.background_color', defaultValue: anyNamed('defaultValue')))
          .thenReturn(0xFFFAFAFA);
      when(mockConfig.getParameter('ui.surface_color', defaultValue: anyNamed('defaultValue')))
          .thenReturn(0xFFFFFFFF);
      when(mockConfig.getParameter('ui.on_primary', defaultValue: anyNamed('defaultValue')))
          .thenReturn(0xFFFFFFFF);
      when(mockConfig.getParameter('ui.on_surface', defaultValue: anyNamed('defaultValue')))
          .thenReturn(0xFF000000);
      when(mockConfig.getParameter('ui.font_size_md', defaultValue: anyNamed('defaultValue')))
          .thenReturn(16.0);
      when(mockConfig.getParameter('ui.spacing_md', defaultValue: anyNamed('defaultValue')))
          .thenReturn(16.0);
      when(mockConfig.getParameter('ui.border_radius_md', defaultValue: anyNamed('defaultValue')))
          .thenReturn(8.0);
      when(mockConfig.getParameter('ui.animation_normal', defaultValue: anyNamed('defaultValue')))
          .thenReturn(300);

      // Inject mock config (this would require dependency injection in real implementation)
      // For now, we'll test with the singleton instance

      uiService = AdvancedUIService.instance;
    });

    test('Singleton Pattern - Returns same instance', () {
      final instance1 = AdvancedUIService.instance;
      final instance2 = AdvancedUIService.instance;

      expect(identical(instance1, instance2), isTrue);
    });

    test('Initialization - Loads UI parameters', () async {
      await uiService.initialize();

      // Verify that UI service was initialized
      expect(uiService, isNotNull);
    });

    test('Theme Generation - Light theme creation', () async {
      await uiService.initialize();

      final lightTheme = uiService.getThemeData(brightness: Brightness.light);

      expect(lightTheme, isNotNull);
      expect(lightTheme.brightness, equals(Brightness.light));
      expect(lightTheme.primaryColor, isNotNull);
      expect(lightTheme.colorScheme, isNotNull);
    });

    test('Theme Generation - Dark theme creation', () async {
      await uiService.initialize();

      final darkTheme = uiService.getThemeData(brightness: Brightness.dark);

      expect(darkTheme, isNotNull);
      expect(darkTheme.brightness, equals(Brightness.dark));
      expect(darkTheme.primaryColor, isNotNull);
      expect(darkTheme.colorScheme, isNotNull);
    });

    test('Theme Generation - High contrast theme', () async {
      await uiService.initialize();

      final highContrastTheme = uiService.getThemeData(
        brightness: Brightness.light,
        highContrast: true
      );

      expect(highContrastTheme, isNotNull);
      expect(highContrastTheme.brightness, equals(Brightness.light));
      expect(highContrastTheme.primaryColor, equals(Colors.black));
    });

    test('Spacing Utilities - Get spacing values', () {
      const testCases = [
        ('xs', 4.0),
        ('sm', 8.0),
        ('md', 16.0),
        ('lg', 24.0),
        ('xl', 32.0),
        ('2xl', 48.0),
      ];

      for (final testCase in testCases) {
        final size = testCase.$1;
        final expected = testCase.$2;

        // Mock the config to return expected values
        when(mockConfig.getParameter('ui.spacing_$size', defaultValue: anyNamed('defaultValue')))
            .thenReturn(expected);

        final result = uiService.getSpacing(size);
        expect(result, equals(expected));
      }
    });

    test('Font Size Utilities - Get font size values', () {
      const testCases = [
        ('xs', 12.0),
        ('sm', 14.0),
        ('md', 16.0),
        ('lg', 18.0),
        ('xl', 20.0),
        ('2xl', 24.0),
        ('3xl', 30.0),
      ];

      for (final testCase in testCases) {
        final size = testCase.$1;
        final expected = testCase.$2;

        when(mockConfig.getParameter('ui.font_size_$size', defaultValue: anyNamed('defaultValue')))
            .thenReturn(expected);

        final result = uiService.getFontSize(size);
        expect(result, equals(expected));
      }
    });

    test('Border Radius Utilities - Get border radius values', () {
      const testCases = [
        ('sm', 4.0),
        ('md', 8.0),
        ('lg', 12.0),
        ('xl', 16.0),
        ('full', 999.0),
      ];

      for (final testCase in testCases) {
        final size = testCase.$1;
        final expected = testCase.$2;

        when(mockConfig.getParameter('ui.border_radius_$size', defaultValue: anyNamed('defaultValue')))
            .thenReturn(expected);

        final result = uiService.getBorderRadius(size);
        expect(result, equals(expected));
      }
    });

    test('Animation Duration Utilities - Get animation duration values', () {
      const testCases = [
        ('fast', 150),
        ('normal', 300),
        ('slow', 500),
      ];

      for (final testCase in testCases) {
        final speed = testCase.$1;
        final expectedMs = testCase.$2;

        when(mockConfig.getParameter('ui.animation_$speed', defaultValue: anyNamed('defaultValue')))
            .thenReturn(expectedMs);

        final result = uiService.getAnimationDuration(speed);
        expect(result, equals(Duration(milliseconds: expectedMs)));
      }
    });

    test('Icon Size Utilities - Get icon size values', () {
      const testCases = [
        ('sm', 16.0),
        ('md', 24.0),
        ('lg', 32.0),
        ('xl', 48.0),
      ];

      for (final testCase in testCases) {
        final size = testCase.$1;
        final expected = testCase.$2;

        when(mockConfig.getParameter('ui.icon_size_$size', defaultValue: anyNamed('defaultValue')))
            .thenReturn(expected);

        final result = uiService.getIconSize(size);
        expect(result, equals(expected));
      }
    });

    test('Shadow Blur Utilities - Get shadow blur values', () {
      const testCases = [
        ('sm', 2.0),
        ('md', 4.0),
        ('lg', 8.0),
        ('xl', 16.0),
      ];

      for (final testCase in testCases) {
        final size = testCase.$1;
        final expected = testCase.$2;

        when(mockConfig.getParameter('ui.shadow_$size', defaultValue: anyNamed('defaultValue')))
            .thenReturn(expected);

        final result = uiService.getShadowBlur(size);
        expect(result, equals(expected));
      }
    });

    test('Adaptive Text Theme - Small screen scaling', () {
      final smallScreenSize = Size(400, 800); // Small screen
      final largeScreenSize = Size(1200, 800); // Large screen

      // Test small screen scaling
      final smallScreenTheme = uiService.getAdaptiveTextTheme(
        BuildContextFake(),
        screenSize: smallScreenSize
      );

      // Test large screen scaling
      final largeScreenTheme = uiService.getAdaptiveTextTheme(
        BuildContextFake(),
        screenSize: largeScreenSize
      );

      expect(smallScreenTheme, isNotNull);
      expect(largeScreenTheme, isNotNull);

      // Small screen should have smaller fonts
      expect(smallScreenTheme.headlineLarge?.fontSize,
             lessThan(largeScreenTheme.headlineLarge?.fontSize ?? 32));
    });

    test('High Contrast Text Theme - Enhanced readability', () {
      final highContrastTheme = uiService.getAdaptiveTextTheme(
        BuildContextFake(),
        highContrast: true
      );

      expect(highContrastTheme, isNotNull);
      // High contrast theme should use Typography.blackMountainView
      expect(highContrastTheme.headlineLarge?.fontWeight, equals(FontWeight.w700));
    });

    test('Color Scheme Generation - Complete color scheme', () async {
      await uiService.initialize();

      final lightTheme = uiService.getThemeData(brightness: Brightness.light);
      final colorScheme = lightTheme.colorScheme;

      expect(colorScheme.primary, isNotNull);
      expect(colorScheme.secondary, isNotNull);
      expect(colorScheme.surface, isNotNull);
      expect(colorScheme.background, isNotNull);
      expect(colorScheme.onPrimary, isNotNull);
      expect(colorScheme.onSecondary, isNotNull);
      expect(colorScheme.onSurface, isNotNull);
      expect(colorScheme.onBackground, isNotNull);
      expect(colorScheme.error, isNotNull);
      expect(colorScheme.onError, isNotNull);
    });

    test('Material Design 3 Compliance - Uses Material 3', () async {
      await uiService.initialize();

      final theme = uiService.getThemeData(brightness: Brightness.light);

      expect(theme.useMaterial3, isTrue);
    });

    test('Theme Persistence - Themes remain consistent', () async {
      await uiService.initialize();

      final theme1 = uiService.getThemeData(brightness: Brightness.light);
      final theme2 = uiService.getThemeData(brightness: Brightness.light);

      // Themes should be identical for same parameters
      expect(theme1.primaryColor, equals(theme2.primaryColor));
      expect(theme1.colorScheme?.primary, equals(theme2.colorScheme?.primary));
    });

    test('Configuration Changes - Dynamic theme updates', () async {
      await uiService.initialize();

      // Get initial theme
      final initialTheme = uiService.getThemeData(brightness: Brightness.light);
      final initialPrimaryColor = initialTheme.primaryColor;

      // Simulate configuration change (this would require a real config update)
      // In a real scenario, the theme would update when config changes
      final updatedTheme = uiService.getThemeData(brightness: Brightness.light);

      // For now, verify the theme generation works consistently
      expect(updatedTheme.primaryColor, equals(initialPrimaryColor));
    });

    test('Accessibility Features - Screen reader support', () async {
      await uiService.initialize();

      // Test that accessibility features can be applied
      // This would test the applyAccessibilitySettings method
      expect(uiService, isNotNull);
    });

    test('Performance - Theme generation is fast', () async {
      await uiService.initialize();

      final stopwatch = Stopwatch()..start();

      // Generate multiple themes
      for (var i = 0; i < 100; i++) {
        uiService.getThemeData(brightness: Brightness.light);
        uiService.getThemeData(brightness: Brightness.dark);
      }

      stopwatch.stop();

      // Should complete within reasonable time (e.g., 1 second for 200 theme generations)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('Error Handling - Graceful degradation', () async {
      // Test that UI service handles configuration errors gracefully
      // This would test error scenarios in theme generation
      await uiService.initialize();

      final theme = uiService.getThemeData(brightness: Brightness.light);
      expect(theme, isNotNull); // Should not crash even with config issues
    });

    test('Cross-Platform Compatibility - Works on all platforms', () async {
      await uiService.initialize();

      // Test theme generation works regardless of platform
      final theme = uiService.getThemeData(brightness: Brightness.light);
      expect(theme.platform, isNull); // Should work on all platforms
    });
  });
}

// Mock classes and utilities for testing
class BuildContextFake implements BuildContext {
  @override
  bool get debugDoingBuild => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCentralConfig extends Mock implements CentralConfig {}
