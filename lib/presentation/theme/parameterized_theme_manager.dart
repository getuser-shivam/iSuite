import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/config_provider.dart';

/// Parameterized Theme Manager
/// 
/// Manages theme configuration based on central parameters
/// Features: Dynamic theme switching, font size adjustment, localization
/// Performance: Optimized theme updates, efficient configuration access
/// Architecture: Provider pattern, observer pattern, theme management
class ParameterizedThemeManager {
  static ParameterizedThemeManager? _instance;
  static ParameterizedThemeManager get instance => _instance ??= ParameterizedThemeManager._internal();
  ParameterizedThemeManager._internal();

  /// Build light theme based on configuration
  ThemeData buildLightTheme(BuildContext context, ConfigurationProvider configProvider) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _getPrimaryColor(configProvider),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      fontFamily: _getFontFamily(configProvider),
      textTheme: _buildTextTheme(colorScheme.brightness, configProvider),
      appBarTheme: _buildAppBarTheme(colorScheme, configProvider),
      cardTheme: _buildCardTheme(colorScheme, configProvider),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme, configProvider),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme, configProvider),
      inputDecorationTheme: _buildInputDecorationTheme(colorScheme, configProvider),
    );
  }

  /// Build dark theme based on configuration
  ThemeData buildDarkTheme(BuildContext context, ConfigurationProvider configProvider) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _getPrimaryColor(configProvider),
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      fontFamily: _getFontFamily(configProvider),
      textTheme: _buildTextTheme(colorScheme.brightness, configProvider),
      appBarTheme: _buildAppBarTheme(colorScheme, configProvider),
      cardTheme: _buildCardTheme(colorScheme, configProvider),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme, configProvider),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme, configProvider),
      inputDecorationTheme: _buildInputDecorationTheme(colorScheme, configProvider),
    );
  }

  /// Get primary color from configuration
  Color _getPrimaryColor(ConfigurationProvider configProvider) {
    final primaryColor = configProvider._config.getParameter('ui.primary_color', defaultValue: 'blue');
    
    switch (primaryColor) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'teal':
        return Colors.teal;
      case 'indigo':
        return Colors.indigo;
      case 'pink':
        return Colors.pink;
      default:
        return Colors.blue;
    }
  }

  /// Get font family from configuration
  String _getFontFamily(ConfigurationProvider configProvider) {
    final language = configProvider.language;
    
    switch (language) {
      case 'ar':
        return 'Cairo';
      case 'zh':
        return 'Noto Sans SC';
      case 'ja':
        return 'Noto Sans JP';
      case 'ko':
        return 'Noto Sans KR';
      case 'th':
        return 'Noto Sans Thai';
      case 'hi':
        return 'Noto Sans Devanagari';
      default:
        return 'Roboto';
    }
  }

  /// Build text theme based on configuration
  TextTheme _buildTextTheme(Brightness brightness, ConfigurationProvider configProvider) {
    final fontSize = _getFontSize(configProvider.fontSize);
    final textColor = brightness == Brightness.dark ? Colors.white : Colors.black;
    
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: fontSize * 2.5,
        color: textColor,
        fontWeight: FontWeight.w300,
      ),
      displayMedium: TextStyle(
        fontSize: fontSize * 2.0,
        color: textColor,
        fontWeight: FontWeight.w300,
      ),
      displaySmall: TextStyle(
        fontSize: fontSize * 1.75,
        color: textColor,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: TextStyle(
        fontSize: fontSize * 1.5,
        color: textColor,
        fontWeight: FontWeight.w400,
      ),
      headlineMedium: TextStyle(
        fontSize: fontSize * 1.25,
        color: textColor,
        fontWeight: FontWeight.w400,
      ),
      headlineSmall: TextStyle(
        fontSize: fontSize * 1.125,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: TextStyle(
        fontSize: fontSize * 1.0,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      titleMedium: TextStyle(
        fontSize: fontSize * 0.875,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        fontSize: fontSize * 0.75,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(
        fontSize: fontSize * 0.875,
        color: textColor,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontSize: fontSize * 0.75,
        color: textColor,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        fontSize: fontSize * 0.625,
        color: textColor,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        fontSize: fontSize * 0.875,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        fontSize: fontSize * 0.75,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        fontSize: fontSize * 0.625,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Build app bar theme
  AppBarTheme _buildAppBarTheme(ColorScheme colorScheme, ConfigurationProvider configProvider) {
    return AppBarTheme(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: configProvider.animationsEnabled ? 4.0 : 0.0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: _getFontSize(configProvider.fontSize) * 1.125,
        fontWeight: FontWeight.w500,
        color: colorScheme.onPrimary,
      ),
    );
  }

  /// Build card theme
  CardTheme _buildCardTheme(ColorScheme colorScheme, ConfigurationProvider configProvider) {
    return CardTheme(
      color: colorScheme.surface,
      elevation: configProvider.animationsEnabled ? 2.0 : 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    );
  }

  /// Build elevated button theme
  ElevatedButtonThemeData _buildElevatedButtonTheme(ColorScheme colorScheme, ConfigurationProvider configProvider) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: configProvider.animationsEnabled ? 2.0 : 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        textStyle: TextStyle(
          fontSize: _getFontSize(configProvider.fontSize) * 0.875,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Build outlined button theme
  OutlinedButtonThemeData _buildOutlinedButtonTheme(ColorScheme colorScheme, ConfigurationProvider configProvider) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary, width: 1.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        textStyle: TextStyle(
          fontSize: _getFontSize(configProvider.fontSize) * 0.875,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Build input decoration theme
  InputDecorationTheme _buildInputDecorationTheme(ColorScheme colorScheme, ConfigurationProvider configProvider) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: colorScheme.error, width: 2.0),
      ),
      labelStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: _getFontSize(configProvider.fontSize) * 0.75,
      ),
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withOpacity(0.6),
        fontSize: _getFontSize(configProvider.fontSize) * 0.75,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    );
  }

  /// Get font size based on configuration
  double _getFontSize(String fontSize) {
    switch (fontSize) {
      case 'small':
        return 12.0;
      case 'medium':
        return 14.0;
      case 'large':
        return 16.0;
      case 'extra_large':
        return 18.0;
      default:
        return 14.0;
    }
  }

  /// Get theme mode from configuration
  ThemeMode getThemeMode(ConfigurationProvider configProvider) {
    final themeMode = configProvider.themeMode;
    final enableDarkMode = configProvider.darkModeEnabled;
    
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return enableDarkMode ? ThemeMode.dark : ThemeMode.light;
    }
  }

  /// Get supported locales from configuration
  List<Locale> getSupportedLocales(ConfigurationProvider configProvider) {
    final supportedLanguages = configProvider._config.getParameter('ui.supported_languages', defaultValue: ['en', 'es', 'fr']);
    
    return supportedLanguages.map<Locale>((lang) => Locale(lang)).toList();
  }

  /// Get locale from configuration
  Locale getLocale(ConfigurationProvider configProvider) {
    final language = configProvider.language;
    final country = configProvider._config.getParameter('ui.country_code', defaultValue: '');
    
    return country.isNotEmpty ? Locale(language, country) : Locale(language);
  }
}

/// Parameterized Theme Provider
/// 
/// Provides theme management with central configuration
class ParameterizedThemeProvider extends ChangeNotifier {
  final ParameterizedThemeManager _themeManager;
  final ConfigurationProvider _configProvider;
  
  ThemeData? _lightTheme;
  ThemeData? _darkTheme;
  ThemeMode? _themeMode;
  
  ParameterizedThemeProvider({
    required ParameterizedThemeManager themeManager,
    required ConfigurationProvider configProvider,
  }) : _themeManager = themeManager,
       _configProvider = configProvider {
    
    // Initialize themes
    _updateThemes();
    
    // Listen to configuration changes
    _configProvider.addListener(_onConfigurationChanged);
  }
  
  // Getters
  ThemeData get lightTheme => _lightTheme!;
  ThemeData get darkTheme => _darkTheme!;
  ThemeMode get themeMode => _themeMode!;
  
  /// Update themes when configuration changes
  void _updateThemes() {
    // Note: In a real implementation, we'd need a BuildContext here
    // For now, we'll create themes without context
    _lightTheme = _themeManager.buildLightTheme(null, _configProvider);
    _darkTheme = _themeManager.buildDarkTheme(null, _configProvider);
    _themeMode = _themeManager.getThemeMode(_configProvider);
    
    notifyListeners();
  }
  
  /// Handle configuration changes
  void _onConfigurationChanged() {
    _updateThemes();
  }
  
  @override
  void dispose() {
    _configProvider.removeListener(_onConfigurationChanged);
    super.dispose();
  }
}

/// Parameterized theme provider instance
final parameterizedThemeProvider = ChangeNotifierProvider<ParameterizedThemeProvider>((ref) {
  final themeManager = ParameterizedThemeManager.instance;
  final configProvider = ref.watch(configurationProvider);
  
  return ParameterizedThemeProvider(
    themeManager: themeManager,
    configProvider: configProvider,
  );
});
