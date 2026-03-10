import 'package:flutter/material.dart';

// Infrastructure services
import '../../../core/config/central_config.dart';

/// Build the light theme using CentralConfig parameters
/// No hardcoded values - everything is configurable
ThemeData buildLightTheme(CentralConfig config) {
  // Color scheme using configured colors
  final colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(
        config.getParameter('ui.primary_color', defaultValue: 0xFF1976D2)),
    onPrimary: Color(
        config.getParameter('ui.on_primary_color', defaultValue: 0xFFFFFFFF)),
    primaryContainer: Color(config.getParameter('ui.primary_variant_color',
        defaultValue: 0xFF1565C0)),
    onPrimaryContainer: Color(
        config.getParameter('ui.on_primary_color', defaultValue: 0xFFFFFFFF)),
    secondary: Color(
        config.getParameter('ui.secondary_color', defaultValue: 0xFF03DAC6)),
    onSecondary: Color(
        config.getParameter('ui.on_secondary_color', defaultValue: 0xFF000000)),
    secondaryContainer: Color(
        config.getParameter('ui.secondary_color', defaultValue: 0xFF03DAC6)),
    onSecondaryContainer: Color(
        config.getParameter('ui.on_secondary_color', defaultValue: 0xFF000000)),
    tertiary:
        Color(config.getParameter('ui.accent_color', defaultValue: 0xFFFF4081)),
    onTertiary: Color(
        config.getParameter('ui.on_primary_color', defaultValue: 0xFFFFFFFF)),
    tertiaryContainer:
        Color(config.getParameter('ui.accent_color', defaultValue: 0xFFFF4081)),
    onTertiaryContainer: Color(
        config.getParameter('ui.on_primary_color', defaultValue: 0xFFFFFFFF)),
    error:
        Color(config.getParameter('ui.error_color', defaultValue: 0xFFB00020)),
    onError: Color(
        config.getParameter('ui.on_error_color', defaultValue: 0xFFFFFFFF)),
    errorContainer:
        Color(config.getParameter('ui.error_color', defaultValue: 0xFFB00020)),
    onErrorContainer: Color(
        config.getParameter('ui.on_error_color', defaultValue: 0xFFFFFFFF)),
    background: Color(
        config.getParameter('ui.background_color', defaultValue: 0xFFFAFAFA)),
    onBackground: Color(config.getParameter('ui.on_background_color',
        defaultValue: 0xFF000000)),
    surface: Color(
        config.getParameter('ui.surface_color', defaultValue: 0xFFFFFFFF)),
    onSurface: Color(
        config.getParameter('ui.on_surface_color', defaultValue: 0xFF000000)),
    surfaceVariant:
        Color(config.getParameter('ui.card_color', defaultValue: 0xFFFFFFFF)),
    onSurfaceVariant: Color(
        config.getParameter('ui.on_surface_color', defaultValue: 0xFF000000)),
    outline: Color(config.getParameter('ui.on_surface_color',
            defaultValue: 0xFF000000))
        .withOpacity(0.12),
    outlineVariant: Color(config.getParameter('ui.on_surface_color',
            defaultValue: 0xFF000000))
        .withOpacity(0.08),
    shadow: Color(config.getParameter('ui.on_surface_color',
            defaultValue: 0xFF000000))
        .withOpacity(0.05),
    scrim: Color(config.getParameter('ui.on_surface_color',
            defaultValue: 0xFF000000))
        .withOpacity(0.8),
    inverseSurface: Color(config.getParameter('ui.on_background_color',
        defaultValue: 0xFF000000)),
    onInverseSurface: Color(
        config.getParameter('ui.surface_color', defaultValue: 0xFFFFFFFF)),
    inversePrimary: Color(
        config.getParameter('ui.primary_color', defaultValue: 0xFF1976D2)),
    surfaceTint: Color(
        config.getParameter('ui.primary_color', defaultValue: 0xFF1976D2)),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,

    // App bar theme using configured parameters
    appBarTheme: AppBarTheme(
      elevation: config.getParameter('ui.app_bar_elevation', defaultValue: 0.0),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shadowColor: colorScheme.shadow,
      surfaceTintColor: colorScheme.surfaceTint,
      centerTitle: true,
      toolbarHeight:
          config.getParameter('ui.app_bar_height', defaultValue: 56.0),
      titleTextStyle: TextStyle(
        fontSize: config.getParameter('ui.font_size_xl', defaultValue: 20.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_medium', defaultValue: 500)],
        color: colorScheme.onPrimary,
      ),
    ),

    // Card theme using configured parameters
    cardTheme: CardTheme(
      elevation: config.getParameter('ui.card_elevation', defaultValue: 2.0),
      color: colorScheme.surfaceVariant,
      shadowColor: colorScheme.shadow,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_lg', defaultValue: 12.0),
        ),
      ),
      margin: EdgeInsets.all(
        config.getParameter('ui.card_margin', defaultValue: 8.0),
      ),
    ),

    // Button themes using configured parameters
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: config.getParameter('ui.elevation_md', defaultValue: 2.0),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shadowColor: colorScheme.shadow,
        surfaceTintColor: colorScheme.surfaceTint,
        minimumSize: Size(
          double.infinity,
          config.getParameter('ui.button_height_md', defaultValue: 48.0),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: config.getParameter('ui.spacing_lg', defaultValue: 24.0),
          vertical: config.getParameter('ui.spacing_md', defaultValue: 16.0),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            config.getParameter('ui.border_radius_md', defaultValue: 8.0),
          ),
        ),
        textStyle: TextStyle(
          fontSize: config.getParameter('ui.font_size_md', defaultValue: 16.0),
          fontWeight: FontWeight.values[
              config.getParameter('ui.font_weight_medium', defaultValue: 500)],
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        minimumSize: Size(
          double.infinity,
          config.getParameter('ui.button_height_md', defaultValue: 48.0),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: config.getParameter('ui.spacing_lg', defaultValue: 24.0),
          vertical: config.getParameter('ui.spacing_md', defaultValue: 16.0),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            config.getParameter('ui.border_radius_md', defaultValue: 8.0),
          ),
        ),
        textStyle: TextStyle(
          fontSize: config.getParameter('ui.font_size_md', defaultValue: 16.0),
          fontWeight: FontWeight.values[
              config.getParameter('ui.font_weight_medium', defaultValue: 500)],
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(
          color: colorScheme.outline,
          width: 1.0,
        ),
        minimumSize: Size(
          double.infinity,
          config.getParameter('ui.button_height_md', defaultValue: 48.0),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: config.getParameter('ui.spacing_lg', defaultValue: 24.0),
          vertical: config.getParameter('ui.spacing_md', defaultValue: 16.0),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            config.getParameter('ui.border_radius_md', defaultValue: 8.0),
          ),
        ),
        textStyle: TextStyle(
          fontSize: config.getParameter('ui.font_size_md', defaultValue: 16.0),
          fontWeight: FontWeight.values[
              config.getParameter('ui.font_weight_medium', defaultValue: 500)],
        ),
      ),
    ),

    // Typography using configured font sizes and weights
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: config.getParameter('ui.font_size_xxxl', defaultValue: 32.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_light', defaultValue: 300)],
        color: colorScheme.onSurface,
      ),
      displayMedium: TextStyle(
        fontSize: config.getParameter('ui.font_size_xxl', defaultValue: 24.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_regular', defaultValue: 400)],
        color: colorScheme.onSurface,
      ),
      displaySmall: TextStyle(
        fontSize: config.getParameter('ui.font_size_xl', defaultValue: 20.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_regular', defaultValue: 400)],
        color: colorScheme.onSurface,
      ),
      headlineLarge: TextStyle(
        fontSize: config.getParameter('ui.font_size_xxl', defaultValue: 24.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_bold', defaultValue: 700)],
        color: colorScheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: config.getParameter('ui.font_size_xl', defaultValue: 20.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_bold', defaultValue: 700)],
        color: colorScheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: config.getParameter('ui.font_size_lg', defaultValue: 18.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_bold', defaultValue: 700)],
        color: colorScheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: config.getParameter('ui.font_size_lg', defaultValue: 18.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_medium', defaultValue: 500)],
        color: colorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: config.getParameter('ui.font_size_md', defaultValue: 16.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_medium', defaultValue: 500)],
        color: colorScheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: config.getParameter('ui.font_size_sm', defaultValue: 14.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_medium', defaultValue: 500)],
        color: colorScheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: config.getParameter('ui.font_size_md', defaultValue: 16.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_regular', defaultValue: 400)],
        color: colorScheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: config.getParameter('ui.font_size_sm', defaultValue: 14.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_regular', defaultValue: 400)],
        color: colorScheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: config.getParameter('ui.font_size_xs', defaultValue: 12.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_regular', defaultValue: 400)],
        color: colorScheme.onSurface,
      ),
      labelLarge: TextStyle(
        fontSize: config.getParameter('ui.font_size_sm', defaultValue: 14.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_medium', defaultValue: 500)],
        color: colorScheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: config.getParameter('ui.font_size_xs', defaultValue: 12.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_medium', defaultValue: 500)],
        color: colorScheme.onSurface,
      ),
      labelSmall: TextStyle(
        fontSize: config.getParameter('ui.font_size_xs', defaultValue: 12.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_medium', defaultValue: 500)],
        color: colorScheme.onSurface,
      ),
    ),

    // Dialog theme using configured parameters
    dialogTheme: DialogTheme(
      elevation: config.getParameter('ui.dialog_elevation', defaultValue: 24.0),
      backgroundColor: Color(
          config.getParameter('ui.dialog_color', defaultValue: 0xFFFFFFFF)),
      shadowColor: colorScheme.shadow,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.dialog_border_radius', defaultValue: 12.0),
        ),
      ),
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceVariant,
      contentPadding: EdgeInsets.symmetric(
        horizontal: config.getParameter('ui.spacing_md', defaultValue: 16.0),
        vertical: config.getParameter('ui.spacing_md', defaultValue: 16.0),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_md', defaultValue: 8.0),
        ),
        borderSide: BorderSide(
          color: colorScheme.outline,
          width: 1.0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_md', defaultValue: 8.0),
        ),
        borderSide: BorderSide(
          color: colorScheme.outline,
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_md', defaultValue: 8.0),
        ),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_md', defaultValue: 8.0),
        ),
        borderSide: BorderSide(
          color: colorScheme.error,
          width: 1.0,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_md', defaultValue: 8.0),
        ),
        borderSide: BorderSide(
          color: colorScheme.error,
          width: 2.0,
        ),
      ),
      labelStyle: TextStyle(
        fontSize: config.getParameter('ui.font_size_sm', defaultValue: 14.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_medium', defaultValue: 500)],
        color: colorScheme.onSurface,
      ),
      hintStyle: TextStyle(
        fontSize: config.getParameter('ui.font_size_md', defaultValue: 16.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_regular', defaultValue: 400)],
        color: colorScheme.onSurface.withOpacity(
          config.getParameter('ui.opacity_hint', defaultValue: 0.6),
        ),
      ),
    ),

    // Navigation drawer theme
    drawerTheme: DrawerThemeData(
      width: config.getParameter('ui.navigation_drawer_width',
          defaultValue: 304.0),
      elevation: config.getParameter('ui.elevation_lg', defaultValue: 4.0),
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shadowColor: colorScheme.shadow,
    ),

    // Bottom navigation theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      elevation: config.getParameter('ui.elevation_md', defaultValue: 2.0),
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
      selectedLabelStyle: TextStyle(
        fontSize: config.getParameter('ui.font_size_xs', defaultValue: 12.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_medium', defaultValue: 500)],
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: config.getParameter('ui.font_size_xs', defaultValue: 12.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_regular', defaultValue: 400)],
      ),
    ),

    // Divider theme
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1.0,
    ),

    // Progress indicator theme
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.surfaceVariant,
      circularTrackColor: colorScheme.surfaceVariant,
    ),

    // Snackbar theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(
        fontSize: config.getParameter('ui.font_size_sm', defaultValue: 14.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_regular', defaultValue: 400)],
        color: colorScheme.onInverseSurface,
      ),
      actionTextColor: colorScheme.primary,
      elevation: config.getParameter('ui.elevation_lg', defaultValue: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_md', defaultValue: 8.0),
        ),
      ),
    ),

    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceVariant,
      deleteIconColor: colorScheme.onSurfaceVariant,
      labelStyle: TextStyle(
        fontSize: config.getParameter('ui.font_size_sm', defaultValue: 14.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_regular', defaultValue: 400)],
        color: colorScheme.onSurfaceVariant,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_xl', defaultValue: 16.0),
        ),
      ),
    ),

    // Tab bar theme
    tabBarTheme: TabBarTheme(
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
      labelStyle: TextStyle(
        fontSize: config.getParameter('ui.font_size_md', defaultValue: 16.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_medium', defaultValue: 500)],
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: config.getParameter('ui.font_size_md', defaultValue: 16.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_regular', defaultValue: 400)],
      ),
      indicatorColor: colorScheme.primary,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: colorScheme.outlineVariant,
    ),

    // Floating action button theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      elevation: config.getParameter('ui.elevation_lg', defaultValue: 4.0),
      focusElevation: config.getParameter('ui.elevation_xl', defaultValue: 8.0),
      hoverElevation: config.getParameter('ui.elevation_xl', defaultValue: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_xxl', defaultValue: 24.0),
        ),
      ),
    ),

    // Bottom sheet theme
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Color(config.getParameter('ui.bottom_sheet_color',
          defaultValue: 0xFFFFFFFF)),
      elevation: config.getParameter('ui.elevation_xxl', defaultValue: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            config.getParameter('ui.border_radius_xl', defaultValue: 16.0),
          ),
        ),
      ),
      modalBackgroundColor: Color(config.getParameter('ui.bottom_sheet_color',
          defaultValue: 0xFFFFFFFF)),
      modalElevation:
          config.getParameter('ui.elevation_xxl', defaultValue: 16.0),
    ),

    // Tooltip theme
    tooltipTheme: TooltipThemeData(
      textStyle: TextStyle(
        fontSize: config.getParameter('ui.font_size_xs', defaultValue: 12.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_regular', defaultValue: 400)],
        color: colorScheme.onInverseSurface,
      ),
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_sm', defaultValue: 4.0),
        ),
      ),
    ),

    // List tile theme
    listTileTheme: ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: config.getParameter('ui.spacing_md', defaultValue: 16.0),
        vertical: config.getParameter('ui.spacing_sm', defaultValue: 8.0),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_md', defaultValue: 8.0),
        ),
      ),
      tileColor: colorScheme.surfaceVariant,
      selectedTileColor: colorScheme.primary.withOpacity(0.1),
      selectedColor: colorScheme.primary,
      textColor: colorScheme.onSurface,
      iconColor: colorScheme.onSurface,
      titleTextStyle: TextStyle(
        fontSize: config.getParameter('ui.font_size_md', defaultValue: 16.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_medium', defaultValue: 500)],
        color: colorScheme.onSurface,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: config.getParameter('ui.font_size_sm', defaultValue: 14.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_regular', defaultValue: 400)],
        color: colorScheme.onSurface.withOpacity(0.7),
      ),
    ),

    // Data table theme
    dataTableTheme: DataTableThemeData(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_md', defaultValue: 8.0),
        ),
      ),
      dataRowColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return colorScheme.primary.withOpacity(0.1);
        }
        return null;
      }),
      headingRowColor: MaterialStateProperty.all(colorScheme.surfaceVariant),
      headingTextStyle: TextStyle(
        fontSize: config.getParameter('ui.font_size_sm', defaultValue: 14.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_bold', defaultValue: 700)],
        color: colorScheme.onSurface,
      ),
      dataTextStyle: TextStyle(
        fontSize: config.getParameter('ui.font_size_sm', defaultValue: 14.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_regular', defaultValue: 400)],
        color: colorScheme.onSurface,
      ),
    ),

    // Expansion tile theme
    expansionTileTheme: ExpansionTileThemeData(
      backgroundColor: colorScheme.surfaceVariant,
      collapsedBackgroundColor: colorScheme.surface,
      textColor: colorScheme.onSurface,
      collapsedTextColor: colorScheme.onSurface,
      iconColor: colorScheme.onSurface,
      collapsedIconColor: colorScheme.onSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_md', defaultValue: 8.0),
        ),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_md', defaultValue: 8.0),
        ),
      ),
    ),
  );
}

/// Build the dark theme using CentralConfig parameters
/// No hardcoded values - everything is configurable
ThemeData buildDarkTheme(CentralConfig config) {
  // Dark theme color scheme using configured colors
  final colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(
        config.getParameter('ui.primary_color', defaultValue: 0xFF1976D2)),
    onPrimary: Color(
        config.getParameter('ui.on_primary_color', defaultValue: 0xFFFFFFFF)),
    primaryContainer: Color(config.getParameter('ui.primary_variant_color',
        defaultValue: 0xFF1565C0)),
    onPrimaryContainer: Color(
        config.getParameter('ui.on_primary_color', defaultValue: 0xFFFFFFFF)),
    secondary: Color(
        config.getParameter('ui.secondary_color', defaultValue: 0xFF03DAC6)),
    onSecondary: Color(
        config.getParameter('ui.on_secondary_color', defaultValue: 0xFF000000)),
    secondaryContainer: Color(
        config.getParameter('ui.secondary_color', defaultValue: 0xFF03DAC6)),
    onSecondaryContainer: Color(
        config.getParameter('ui.on_secondary_color', defaultValue: 0xFF000000)),
    tertiary:
        Color(config.getParameter('ui.accent_color', defaultValue: 0xFFFF4081)),
    onTertiary: Color(
        config.getParameter('ui.on_primary_color', defaultValue: 0xFFFFFFFF)),
    tertiaryContainer:
        Color(config.getParameter('ui.accent_color', defaultValue: 0xFFFF4081)),
    onTertiaryContainer: Color(
        config.getParameter('ui.on_primary_color', defaultValue: 0xFFFFFFFF)),
    error:
        Color(config.getParameter('ui.error_color', defaultValue: 0xFFCF6679)),
    onError: Color(
        config.getParameter('ui.on_error_color', defaultValue: 0xFF000000)),
    errorContainer:
        Color(config.getParameter('ui.error_color', defaultValue: 0xFFCF6679)),
    onErrorContainer: Color(
        config.getParameter('ui.on_error_color', defaultValue: 0xFF000000)),
    background: Color(
        config.getParameter('ui.background_color', defaultValue: 0xFF121212)),
    onBackground: Color(config.getParameter('ui.on_background_color',
        defaultValue: 0xFFFFFFFF)),
    surface: Color(
        config.getParameter('ui.surface_color', defaultValue: 0xFF1E1E1E)),
    onSurface: Color(
        config.getParameter('ui.on_surface_color', defaultValue: 0xFFFFFFFF)),
    surfaceVariant:
        Color(config.getParameter('ui.card_color', defaultValue: 0xFF2D2D2D)),
    onSurfaceVariant: Color(
        config.getParameter('ui.on_surface_color', defaultValue: 0xFFFFFFFF)),
    outline: Color(config.getParameter('ui.on_surface_color',
            defaultValue: 0xFFFFFFFF))
        .withOpacity(0.12),
    outlineVariant: Color(config.getParameter('ui.on_surface_color',
            defaultValue: 0xFFFFFFFF))
        .withOpacity(0.08),
    shadow: Color(config.getParameter('ui.on_surface_color',
            defaultValue: 0xFF000000))
        .withOpacity(0.25),
    scrim: Color(config.getParameter('ui.on_surface_color',
            defaultValue: 0xFF000000))
        .withOpacity(0.8),
    inverseSurface: Color(
        config.getParameter('ui.surface_color', defaultValue: 0xFF1E1E1E)),
    onInverseSurface: Color(config.getParameter('ui.on_background_color',
        defaultValue: 0xFF121212)),
    inversePrimary: Color(
        config.getParameter('ui.primary_color', defaultValue: 0xFF1976D2)),
    surfaceTint: Color(
        config.getParameter('ui.primary_color', defaultValue: 0xFF1976D2)),
  );

  // Build dark theme using the same structure as light theme
  return buildLightTheme(config).copyWith(
    colorScheme: colorScheme,

    // Dark-specific overrides
    cardTheme: CardTheme(
      elevation: config.getParameter('ui.card_elevation', defaultValue: 2.0),
      color: colorScheme.surfaceVariant,
      shadowColor: colorScheme.shadow,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_lg', defaultValue: 12.0),
        ),
      ),
      margin: EdgeInsets.all(
        config.getParameter('ui.card_margin', defaultValue: 8.0),
      ),
    ),

    dialogTheme: DialogTheme(
      elevation: config.getParameter('ui.dialog_elevation', defaultValue: 24.0),
      backgroundColor: colorScheme.surface,
      shadowColor: colorScheme.shadow,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.dialog_border_radius', defaultValue: 12.0),
        ),
      ),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      elevation: config.getParameter('ui.elevation_xxl', defaultValue: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            config.getParameter('ui.border_radius_xl', defaultValue: 16.0),
          ),
        ),
      ),
      modalBackgroundColor: colorScheme.surface,
      modalElevation:
          config.getParameter('ui.elevation_xxl', defaultValue: 16.0),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(
        fontSize: config.getParameter('ui.font_size_sm', defaultValue: 14.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_regular', defaultValue: 400)],
        color: colorScheme.onInverseSurface,
      ),
      actionTextColor: colorScheme.primary,
      elevation: config.getParameter('ui.elevation_lg', defaultValue: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_md', defaultValue: 8.0),
        ),
      ),
    ),

    listTileTheme: ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: config.getParameter('ui.spacing_md', defaultValue: 16.0),
        vertical: config.getParameter('ui.spacing_sm', defaultValue: 8.0),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_md', defaultValue: 8.0),
        ),
      ),
      tileColor: colorScheme.surfaceVariant,
      selectedTileColor: colorScheme.primary.withOpacity(0.2),
      selectedColor: colorScheme.primary,
      textColor: colorScheme.onSurface,
      iconColor: colorScheme.onSurface,
      titleTextStyle: TextStyle(
        fontSize: config.getParameter('ui.font_size_md', defaultValue: 16.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_medium', defaultValue: 500)],
        color: colorScheme.onSurface,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: config.getParameter('ui.font_size_sm', defaultValue: 14.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_regular', defaultValue: 400)],
        color: colorScheme.onSurface.withOpacity(0.7),
      ),
    ),

    dataTableTheme: DataTableThemeData(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_md', defaultValue: 8.0),
        ),
      ),
      dataRowColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return colorScheme.primary.withOpacity(0.2);
        }
        return null;
      }),
      headingRowColor: MaterialStateProperty.all(colorScheme.surfaceVariant),
      headingTextStyle: TextStyle(
        fontSize: config.getParameter('ui.font_size_sm', defaultValue: 14.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_bold', defaultValue: 700)],
        color: colorScheme.onSurface,
      ),
      dataTextStyle: TextStyle(
        fontSize: config.getParameter('ui.font_size_sm', defaultValue: 14.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_regular', defaultValue: 400)],
        color: colorScheme.onSurface,
      ),
    ),

    expansionTileTheme: ExpansionTileThemeData(
      backgroundColor: colorScheme.surfaceVariant,
      collapsedBackgroundColor: colorScheme.surface,
      textColor: colorScheme.onSurface,
      collapsedTextColor: colorScheme.onSurface,
      iconColor: colorScheme.onSurface,
      collapsedIconColor: colorScheme.onSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_md', defaultValue: 8.0),
        ),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_md', defaultValue: 8.0),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceVariant,
      contentPadding: EdgeInsets.symmetric(
        horizontal: config.getParameter('ui.spacing_md', defaultValue: 16.0),
        vertical: config.getParameter('ui.spacing_md', defaultValue: 16.0),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_md', defaultValue: 8.0),
        ),
        borderSide: BorderSide(
          color: colorScheme.outline,
          width: 1.0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_md', defaultValue: 8.0),
        ),
        borderSide: BorderSide(
          color: colorScheme.outline,
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_md', defaultValue: 8.0),
        ),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_md', defaultValue: 8.0),
        ),
        borderSide: BorderSide(
          color: colorScheme.error,
          width: 1.0,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_md', defaultValue: 8.0),
        ),
        borderSide: BorderSide(
          color: colorScheme.error,
          width: 2.0,
        ),
      ),
      labelStyle: TextStyle(
        fontSize: config.getParameter('ui.font_size_sm', defaultValue: 14.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_medium', defaultValue: 500)],
        color: colorScheme.onSurface,
      ),
      hintStyle: TextStyle(
        fontSize: config.getParameter('ui.font_size_md', defaultValue: 16.0),
        fontWeight: FontWeight.values[
            config.getParameter('ui.font_weight_regular', defaultValue: 400)],
        color: colorScheme.onSurface.withOpacity(
          config.getParameter('ui.opacity_hint', defaultValue: 0.6),
        ),
      ),
    ),
  );
}
