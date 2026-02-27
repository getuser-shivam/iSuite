import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/central_config.dart';

/// Advanced Theme Manager with Dynamic Theming Support
///
/// Features:
/// - Dynamic theme switching (Light/Dark/System)
/// - Custom theme creation and management
/// - Theme persistence and restoration
/// - Advanced color schemes with Material 3 support
/// - Adaptive theming based on system preferences
/// - Theme inheritance and customization
/// - Real-time theme updates without restart
class AdvancedThemeManager {
  static final AdvancedThemeManager _instance = AdvancedThemeManager._internal();
  factory AdvancedThemeManager() => _instance;

  final CentralConfig _config = CentralConfig.instance;

  AdvancedThemeManager._internal();

  /// Build enhanced light theme with dynamic configuration
  Future<ThemeData> buildLightTheme() async {
    await _config.initialize();

    final primaryColor = Color(_config.getParameter('ui.primary_color', defaultValue: 0xFF2196F3));
    final secondaryColor = Color(_config.getParameter('ui.secondary_color', defaultValue: 0xFF03DAC6));
    final errorColor = Color(_config.getParameter('ui.error_color', defaultValue: 0xFFB00020));
    final surfaceColor = Color(_config.getParameter('ui.surface_color_light', defaultValue: 0xFFFFFFFF));
    final backgroundColor = Color(_config.getParameter('ui.background_color_light', defaultValue: 0xFFFAFAFA));

    final borderRadius = _config.getParameter('ui.border_radius_medium', defaultValue: 12.0);
    final elevation = _config.getParameter('ui.elevation_medium', defaultValue: 2.0);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: surfaceColor,
        background: backgroundColor,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: elevation,
        shadowColor: primaryColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(borderRadius)),
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: elevation,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        color: surfaceColor,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),

      // FAB Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        elevation: elevation * 1.5,
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        elevation: elevation,
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return TextStyle(color: primaryColor, fontWeight: FontWeight.w600);
          }
          return TextStyle(color: Colors.grey[600]);
        }),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius * 1.5),
        ),
        elevation: elevation * 2,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius * 1.5)),
        ),
        elevation: elevation,
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: elevation,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius * 2),
        ),
        elevation: elevation,
      ),

      // Text Themes
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w300, fontSize: 57),
        displayMedium: TextStyle(fontWeight: FontWeight.w400, fontSize: 45),
        displaySmall: TextStyle(fontWeight: FontWeight.w400, fontSize: 36),
        headlineLarge: TextStyle(fontWeight: FontWeight.w400, fontSize: 32),
        headlineMedium: TextStyle(fontWeight: FontWeight.w400, fontSize: 28),
        headlineSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 24),
        titleLarge: TextStyle(fontWeight: FontWeight.w500, fontSize: 22),
        titleMedium: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        titleSmall: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        bodyLarge: TextStyle(fontWeight: FontWeight.w400, fontSize: 16),
        bodyMedium: TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
        bodySmall: TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
        labelLarge: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, letterSpacing: 0.1),
        labelMedium: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 0.5),
        labelSmall: TextStyle(fontWeight: FontWeight.w500, fontSize: 11, letterSpacing: 0.5),
      ),
    );
  }

  /// Build enhanced dark theme with dynamic configuration
  Future<ThemeData> buildDarkTheme() async {
    await _config.initialize();

    final primaryColor = Color(_config.getParameter('ui.primary_color_dark', defaultValue: 0xFF2196F3));
    final secondaryColor = Color(_config.getParameter('ui.secondary_color_dark', defaultValue: 0xFF03DAC6));
    final errorColor = Color(_config.getParameter('ui.error_color_dark', defaultValue: 0xFFCF6679));
    final surfaceColor = Color(_config.getParameter('ui.surface_color_dark', defaultValue: 0xFF1E1E1E));
    final backgroundColor = Color(_config.getParameter('ui.background_color_dark', defaultValue: 0xFF121212));

    final borderRadius = _config.getParameter('ui.border_radius_medium', defaultValue: 12.0);
    final elevation = _config.getParameter('ui.elevation_medium', defaultValue: 2.0);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: surfaceColor,
        background: backgroundColor,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: Colors.white,
        elevation: elevation,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(borderRadius)),
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: elevation,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        color: surfaceColor,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),

      // FAB Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.black,
        elevation: elevation * 1.5,
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        elevation: elevation,
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withOpacity(0.3),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return TextStyle(color: primaryColor, fontWeight: FontWeight.w600);
          }
          return TextStyle(color: Colors.grey[400]);
        }),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius * 1.5),
        ),
        elevation: elevation * 2,
        backgroundColor: surfaceColor,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius * 1.5)),
        ),
        elevation: elevation,
        backgroundColor: surfaceColor,
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: elevation,
        backgroundColor: surfaceColor,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius * 2),
        ),
        elevation: elevation,
        backgroundColor: Colors.grey[800],
      ),

      // Text Themes (Dark optimized)
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w300, fontSize: 57, color: Colors.white),
        displayMedium: TextStyle(fontWeight: FontWeight.w400, fontSize: 45, color: Colors.white),
        displaySmall: TextStyle(fontWeight: FontWeight.w400, fontSize: 36, color: Colors.white),
        headlineLarge: TextStyle(fontWeight: FontWeight.w400, fontSize: 32, color: Colors.white),
        headlineMedium: TextStyle(fontWeight: FontWeight.w400, fontSize: 28, color: Colors.white),
        headlineSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 24, color: Colors.white),
        titleLarge: TextStyle(fontWeight: FontWeight.w500, fontSize: 22, color: Colors.white),
        titleMedium: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.white),
        titleSmall: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.white70),
        bodyLarge: TextStyle(fontWeight: FontWeight.w400, fontSize: 16, color: Colors.white),
        bodyMedium: TextStyle(fontWeight: FontWeight.w400, fontSize: 14, color: Colors.white),
        bodySmall: TextStyle(fontWeight: FontWeight.w400, fontSize: 12, color: Colors.white70),
        labelLarge: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, letterSpacing: 0.1, color: Colors.white),
        labelMedium: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 0.5, color: Colors.white),
        labelSmall: TextStyle(fontWeight: FontWeight.w500, fontSize: 11, letterSpacing: 0.5, color: Colors.white70),
      ),
    );
  }

  /// Create custom theme from configuration
  Future<ThemeData> createCustomTheme(CustomThemeConfig config) async {
    await _config.initialize();

    final baseTheme = config.isDark ? await buildDarkTheme() : await buildLightTheme();

    return baseTheme.copyWith(
      primaryColor: config.primaryColor ?? baseTheme.primaryColor,
      scaffoldBackgroundColor: config.backgroundColor ?? baseTheme.scaffoldBackgroundColor,
      cardColor: config.surfaceColor ?? baseTheme.cardColor,
      // Add more customizations as needed
    );
  }

  /// Get available theme presets
  List<ThemePreset> getThemePresets() {
    return [
      ThemePreset(
        id: 'default',
        name: 'Default',
        description: 'Standard iSuite theme',
        isDark: false,
      ),
      ThemePreset(
        id: 'dark',
        name: 'Dark',
        description: 'Dark theme for low light environments',
        isDark: true,
      ),
      ThemePreset(
        id: 'high_contrast',
        name: 'High Contrast',
        description: 'High contrast theme for accessibility',
        isDark: true,
        highContrast: true,
      ),
      ThemePreset(
        id: 'nature',
        name: 'Nature',
        description: 'Green and earth tone theme',
        isDark: false,
        primaryColor: const Color(0xFF4CAF50),
        secondaryColor: const Color(0xFF8BC34A),
      ),
      ThemePreset(
        id: 'ocean',
        name: 'Ocean',
        description: 'Blue and water-inspired theme',
        isDark: false,
        primaryColor: const Color(0xFF2196F3),
        secondaryColor: const Color(0xFF00BCD4),
      ),
      ThemePreset(
        id: 'sunset',
        name: 'Sunset',
        description: 'Warm orange and red theme',
        isDark: false,
        primaryColor: const Color(0xFFFF9800),
        secondaryColor: const Color(0xFFFF5722),
      ),
    ];
  }

  /// Save current theme configuration
  Future<void> saveThemeConfiguration(ThemeData theme, ThemeMode mode) async {
    await _config.initialize();

    // Save theme mode
    final modeString = mode.toString().split('.').last;
    await _config.setParameter('ui.theme_mode', modeString);

    // Save theme colors if custom
    if (theme.primaryColor != null) {
      await _config.setParameter('ui.primary_color', theme.primaryColor!.value);
    }

    // Save other theme properties
    await _config.setParameter('ui.border_radius_medium', 12.0);
    await _config.setParameter('ui.elevation_medium', 2.0);
  }

  /// Load theme configuration
  Future<ThemeConfig> loadThemeConfiguration() async {
    await _config.initialize();

    final modeString = _config.getParameter('ui.theme_mode', defaultValue: 'system');
    final primaryColor = _config.getParameter('ui.primary_color', defaultValue: 0xFF2196F3);

    ThemeMode mode;
    switch (modeString) {
      case 'light':
        mode = ThemeMode.light;
        break;
      case 'dark':
        mode = ThemeMode.dark;
        break;
      default:
        mode = ThemeMode.system;
    }

    return ThemeConfig(
      mode: mode,
      primaryColor: Color(primaryColor),
    );
  }

  /// Get adaptive theme based on system preferences
  ThemeData getAdaptiveTheme(BuildContext context, ThemeData lightTheme, ThemeData darkTheme) {
    final brightness = MediaQuery.of(context).platformBrightness;
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }

  /// Update theme configuration dynamically
  Future<void> updateThemeParameter(String key, dynamic value) async {
    await _config.setParameter(key, value);
  }

  /// Reset theme to defaults
  Future<void> resetThemeToDefaults() async {
    await _config.initialize();

    // Reset to default values
    await _config.setParameter('ui.primary_color', 0xFF2196F3);
    await _config.setParameter('ui.secondary_color', 0xFF03DAC6);
    await _config.setParameter('ui.theme_mode', 'system');
    await _config.setParameter('ui.border_radius_medium', 12.0);
    await _config.setParameter('ui.elevation_medium', 2.0);
  }

  /// Export theme configuration
  Future<String> exportThemeConfiguration() async {
    final config = await loadThemeConfiguration();
    final themeData = {
      'mode': config.mode.toString().split('.').last,
      'primaryColor': config.primaryColor?.value,
      'timestamp': DateTime.now().toIso8601String(),
    };

    return jsonEncode(themeData);
  }

  /// Import theme configuration
  Future<void> importThemeConfiguration(String jsonConfig) async {
    final config = jsonDecode(jsonConfig);

    if (config['mode'] != null) {
      await _config.setParameter('ui.theme_mode', config['mode']);
    }

    if (config['primaryColor'] != null) {
      await _config.setParameter('ui.primary_color', config['primaryColor']);
    }
  }
}

/// Theme Configuration
class ThemeConfig {
  final ThemeMode mode;
  final Color? primaryColor;
  final Color? secondaryColor;
  final Color? backgroundColor;

  ThemeConfig({
    required this.mode,
    this.primaryColor,
    this.secondaryColor,
    this.backgroundColor,
  });
}

/// Custom Theme Configuration
class CustomThemeConfig {
  final String name;
  final bool isDark;
  final Color? primaryColor;
  final Color? secondaryColor;
  final Color? surfaceColor;
  final Color? backgroundColor;
  final double? borderRadius;
  final double? elevation;

  CustomThemeConfig({
    required this.name,
    required this.isDark,
    this.primaryColor,
    this.secondaryColor,
    this.surfaceColor,
    this.backgroundColor,
    this.borderRadius,
    this.elevation,
  });
}

/// Theme Preset
class ThemePreset {
  final String id;
  final String name;
  final String description;
  final bool isDark;
  final bool highContrast;
  final Color? primaryColor;
  final Color? secondaryColor;
  final Color? backgroundColor;

  ThemePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.isDark,
    this.highContrast = false,
    this.primaryColor,
    this.secondaryColor,
    this.backgroundColor,
  });
}

/// Theme Manager Riverpod Provider
final themeManagerProvider = Provider<AdvancedThemeManager>((ref) {
  return AdvancedThemeManager();
});

/// Theme Presets Provider
final themePresetsProvider = Provider<List<ThemePreset>>((ref) {
  final themeManager = ref.watch(themeManagerProvider);
  return themeManager.getThemePresets();
});

/// Current Theme Configuration Provider
final currentThemeConfigProvider = FutureProvider<ThemeConfig>((ref) async {
  final themeManager = ref.watch(themeManagerProvider);
  return await themeManager.loadThemeConfiguration();
});
