import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enhanced App Theme with Advanced Customization
/// Features: Dynamic colors, adaptive design, accessibility support
/// Performance: Optimized color calculations, cached themes
/// Accessibility: High contrast, large text, color blind friendly
class EnhancedAppTheme {
  // Base color palette
  static const Color _primaryColor = Color(0xFF2196F3);
  static const Color _secondaryColor = Color(0xFF03DAC6);
  static const Color _tertiaryColor = Color(0xFF7C4DFF);
  static const Color _errorColor = Color(0xFFB00020);
  static const Color _warningColor = Color(0xFFFF9800);
  static const Color _successColor = Color(0xFF4CAF50);
  
  // Neutral colors
  static const Color _surfaceColor = Color(0xFFFFFFFF);
  static const Color _backgroundColor = Color(0xFFFAFAFA);
  static const Color _cardColor = Color(0xFFFFFFFF);
  static const Color _dividerColor = Color(0xFFE0E0E0);
  
  // Text colors
  static const Color _onPrimaryColor = Color(0xFFFFFFFF);
  static const Color _onSecondaryColor = Color(0xFF000000);
  static const Color _onSurfaceColor = Color(0xFF000000);
  static const Color _onBackgroundColor = Color(0xFF000000);
  
  // Dark theme colors
  static const Color _darkSurfaceColor = Color(0xFF121212);
  static const Color _darkBackgroundColor = Color(0xFF121212);
  static const Color _darkCardColor = Color(0xFF1E1E1E);
  static const Color _darkDividerColor = Color(0xFF2C2C2C);
  static const Color _darkOnSurfaceColor = Color(0xFFFFFFFF);
  static const Color _darkOnBackgroundColor = Color(0xFFFFFFFF);

  /// Light theme with enhanced customization
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
        primary: _primaryColor,
        secondary: _secondaryColor,
        tertiary: _tertiaryColor,
        error: _errorColor,
        surface: _surfaceColor,
        background: _backgroundColor,
        onPrimary: _onPrimaryColor,
        onSecondary: _onSecondaryColor,
        onSurface: _onSurfaceColor,
        onBackground: _onBackgroundColor,
      ),
      
      // Enhanced typography
      textTheme: _buildTextTheme(Brightness.light),
      
      // Enhanced app bar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: _surfaceColor,
        foregroundColor: _onSurfaceColor,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _onSurfaceColor,
        ),
        iconTheme: const IconThemeData(
          color: _onSurfaceColor,
          size: 24,
        ),
      ),
      
      // Enhanced card theme
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        surfaceTintColor: _primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: _primaryColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: _surfaceColor,
        labelStyle: const TextStyle(color: _onSurfaceColor),
        hintStyle: TextStyle(color: _onSurfaceColor.withOpacity(0.6)),
      ),
      
      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        extendedTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: _surfaceColor,
        selectedItemColor: _primaryColor,
        unselectedItemColor: _onSurfaceColor.withOpacity(0.6),
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceColor,
        selectedColor: _primaryColor.withOpacity(0.2),
        disabledColor: _dividerColor,
        labelStyle: const TextStyle(color: _onSurfaceColor),
        secondaryLabelStyle: const TextStyle(color: _primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      // Dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: _surfaceColor,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _onSurfaceColor,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: _onSurfaceColor,
        ),
      ),
      
      // Divider theme
      dividerTheme: DividerThemeData(
        color: _dividerColor,
        thickness: 1,
        space: 1,
      ),
      
      // List tile theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: _surfaceColor,
        selectedTileColor: _primaryColor.withOpacity(0.1),
        iconColor: _onSurfaceColor,
        textColor: _onSurfaceColor,
      ),
    );
  }

  /// Dark theme with enhanced customization
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.dark,
        primary: _primaryColor,
        secondary: _secondaryColor,
        tertiary: _tertiaryColor,
        error: _errorColor,
        surface: _darkSurfaceColor,
        background: _darkBackgroundColor,
        onPrimary: _onPrimaryColor,
        onSecondary: _onSecondaryColor,
        onSurface: _darkOnSurfaceColor,
        onBackground: _darkOnBackgroundColor,
      ),
      
      // Enhanced typography for dark theme
      textTheme: _buildTextTheme(Brightness.dark),
      
      // Enhanced app bar theme for dark theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: _darkSurfaceColor,
        foregroundColor: _darkOnSurfaceColor,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _darkOnSurfaceColor,
        ),
        iconTheme: const IconThemeData(
          color: _darkOnSurfaceColor,
          size: 24,
        ),
      ),
      
      // Enhanced card theme for dark theme
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        surfaceTintColor: _primaryColor.withOpacity(0.2),
        color: _darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Elevated button theme for dark theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input decoration theme for dark theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _darkDividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _darkDividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: _darkCardColor,
        labelStyle: const TextStyle(color: _darkOnSurfaceColor),
        hintStyle: TextStyle(color: _darkOnSurfaceColor.withOpacity(0.6)),
      ),
      
      // Bottom navigation bar theme for dark theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: _darkSurfaceColor,
        selectedItemColor: _primaryColor,
        unselectedItemColor: _darkOnSurfaceColor.withOpacity(0.6),
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // Dialog theme for dark theme
      dialogTheme: DialogTheme(
        backgroundColor: _darkCardColor,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _darkOnSurfaceColor,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: _darkOnSurfaceColor,
        ),
      ),
      
      // Divider theme for dark theme
      dividerTheme: DividerThemeData(
        color: _darkDividerColor,
        thickness: 1,
        space: 1,
      ),
      
      // List tile theme for dark theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: _darkCardColor,
        selectedTileColor: _primaryColor.withOpacity(0.2),
        iconColor: _darkOnSurfaceColor,
        textColor: _darkOnSurfaceColor,
      ),
    );
  }

  /// Build enhanced text theme
  static TextTheme _buildTextTheme(Brightness brightness) {
    final textColor = brightness == Brightness.light 
        ? _onSurfaceColor 
        : _darkOnSurfaceColor;
    
    return TextTheme(
      // Display styles
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: -0.25,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0,
      ),
      
      // Headline styles
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0,
      ),
      
      // Title styles
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0.1,
      ),
      
      // Body styles
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0.4,
      ),
      
      // Label styles
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Create custom theme with dynamic colors
  static ThemeData createCustomTheme({
    Color? primaryColor,
    Color? secondaryColor,
    Color? surfaceColor,
    Color? backgroundColor,
    Brightness brightness = Brightness.light,
  }) {
    final seedColor = primaryColor ?? _primaryColor;
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
      ),
      textTheme: _buildTextTheme(brightness),
    );
  }

  /// Get color blind friendly palette
  static Map<String, Color> getColorBlindPalette() {
    return {
      'blue': Color(0xFF0066CC),
      'orange': Color(0xFFE69F00),
      'green': Color(0xFF009E73),
      'red': Color(0xFFCC0000),
      'purple': Color(0xFF8B008B),
      'brown': Color(0xFF8B4513),
    };
  }

  /// Get high contrast theme
  static ThemeData getHighContrastTheme({Brightness brightness = Brightness.light}) {
    final isLight = brightness == Brightness.light;
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: isLight 
          ? ColorScheme.highContrast(
              primary: Colors.black,
              secondary: Colors.white,
              surface: Colors.white,
              background: Colors.white,
              onPrimary: Colors.white,
              onSecondary: Colors.black,
              onSurface: Colors.black,
              onBackground: Colors.black,
            )
          : ColorScheme.highContrast(
              primary: Colors.white,
              secondary: Colors.black,
              surface: Colors.black,
              background: Colors.black,
              onPrimary: Colors.black,
              onSecondary: Colors.white,
              onSurface: Colors.white,
              onBackground: Colors.white,
            ),
      textTheme: _buildTextTheme(brightness).copyWith(
        bodyLarge: const TextStyle(fontWeight: FontWeight.bold),
        bodyMedium: const TextStyle(fontWeight: FontWeight.bold),
        bodySmall: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Get accessibility focused theme
  static ThemeData getAccessibilityTheme({
    Brightness brightness = Brightness.light,
    bool largeText = false,
    bool highContrast = false,
  }) {
    ThemeData baseTheme = highContrast 
        ? getHighContrastTheme(brightness: brightness)
        : (brightness == Brightness.light ? lightTheme : darkTheme);
    
    if (largeText) {
      baseTheme = baseTheme.copyWith(
        textTheme: _buildLargeTextTheme(brightness),
      );
    }
    
    return baseTheme;
  }

  /// Build large text theme
  static TextTheme _buildLargeTextTheme(Brightness brightness) {
    final baseTheme = _buildTextTheme(brightness);
    
    return baseTheme.copyWith(
      displayLarge: baseTheme.displayLarge?.copyWith(fontSize: 68.4),
      displayMedium: baseTheme.displayMedium?.copyWith(fontSize: 54.0),
      displaySmall: baseTheme.displaySmall?.copyWith(fontSize: 43.2),
      headlineLarge: baseTheme.headlineLarge?.copyWith(fontSize: 38.4),
      headlineMedium: baseTheme.headlineMedium?.copyWith(fontSize: 33.6),
      headlineSmall: baseTheme.headlineSmall?.copyWith(fontSize: 28.8),
      titleLarge: baseTheme.titleLarge?.copyWith(fontSize: 26.4),
      titleMedium: baseTheme.titleMedium?.copyWith(fontSize: 19.2),
      titleSmall: baseTheme.titleSmall?.copyWith(fontSize: 16.8),
      bodyLarge: baseTheme.bodyLarge?.copyWith(fontSize: 19.2),
      bodyMedium: baseTheme.bodyMedium?.copyWith(fontSize: 16.8),
      bodySmall: baseTheme.bodySmall?.copyWith(fontSize: 14.4),
      labelLarge: baseTheme.labelLarge?.copyWith(fontSize: 16.8),
      labelMedium: baseTheme.labelMedium?.copyWith(fontSize: 14.4),
      labelSmall: baseTheme.labelSmall?.copyWith(fontSize: 13.2),
    );
  }
}
