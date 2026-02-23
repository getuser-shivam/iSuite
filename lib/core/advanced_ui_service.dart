import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'config/central_config.dart';

/// Advanced UI Service for modern, responsive Flutter applications
/// Provides Material Design 3 themes, adaptive layouts, and responsive components
class AdvancedUIService {
  static final AdvancedUIService _instance = AdvancedUIService._internal();
  factory AdvancedUIService() => _instance;
  AdvancedUIService._internal();

  final CentralConfig _config = CentralConfig.instance;

  // Theme configurations
  late ThemeData _lightTheme;
  late ThemeData _darkTheme;
  late ThemeData _highContrastTheme;

  bool _isInitialized = false;
  ThemeMode _currentThemeMode = ThemeMode.system;

  /// Initialize UI service with Material Design 3 and CentralConfig integration
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize CentralConfig UI parameters
    await _config.setupUIConfig();

    // Configure system UI
    await _configureSystemUI();

    // Initialize themes with parameterized values
    await _initializeThemes();

    _isInitialized = true;
  }

  /// Get responsive theme data based on brightness and accessibility
  ThemeData getThemeData({
    required Brightness brightness,
    bool highContrast = false,
    bool useMaterial3 = true,
  }) {
    if (highContrast) {
      return _highContrastTheme;
    }

    return brightness == Brightness.light ? _lightTheme : _darkTheme;
  }

  /// Get adaptive text theme for different screen sizes
  TextTheme getAdaptiveTextTheme(BuildContext context, {bool highContrast = false}) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < mobileBreakpoint;

    final baseTheme = Theme.of(context).textTheme;

    if (highContrast) {
      return baseTheme.copyWith(
        headlineLarge: baseTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: baseTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
        ),
        bodyLarge: baseTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
      );
    }

    // Adaptive sizing based on screen size
    final scaleFactor = isSmallScreen ? 0.9 : 1.0;

    return baseTheme.copyWith(
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        fontSize: (baseTheme.headlineLarge?.fontSize ?? 32) * scaleFactor,
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        fontSize: (baseTheme.headlineMedium?.fontSize ?? 28) * scaleFactor,
      ),
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        fontSize: (baseTheme.bodyLarge?.fontSize ?? 16) * scaleFactor,
        height: 1.6,
      ),
    );
  }

  /// Create responsive container with adaptive padding and margins
  Widget responsiveContainer({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? maxWidth,
    double? maxHeight,
    bool centerContent = false,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < mobileBreakpoint;
    final isTablet = screenSize.width >= mobileBreakpoint && screenSize.width < tabletBreakpoint;
    final isDesktop = screenSize.width >= tabletBreakpoint;

    // Adaptive padding
    final adaptivePadding = padding ?? EdgeInsets.symmetric(
      horizontal: isSmallScreen ? 16 : isTablet ? 24 : 32,
      vertical: isSmallScreen ? 12 : isTablet ? 16 : 24,
    );

    // Adaptive margin
    final adaptiveMargin = margin ?? EdgeInsets.symmetric(
      horizontal: isSmallScreen ? 8 : isTablet ? 12 : 16,
      vertical: isSmallScreen ? 4 : isTablet ? 8 : 12,
    );

    Widget container = Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? (isDesktop ? 1200 : double.infinity),
        maxHeight: maxHeight,
      ),
      padding: adaptivePadding,
      margin: adaptiveMargin,
      child: child,
    );

    if (centerContent) {
      container = Center(child: container);
    }

    return container;
  }

  /// Create adaptive grid layout
  Widget adaptiveGrid({
    required BuildContext context,
    required List<Widget> children,
    int minCrossAxisCount = 1,
    double mainAxisSpacing = 16.0,
    double crossAxisSpacing = 16.0,
    double childAspectRatio = 1.0,
  }) {
    final screenSize = MediaQuery.of(context).size;

    // Determine grid configuration based on screen size
    late int crossAxisCount;
    if (screenSize.width >= desktopBreakpoint) {
      crossAxisCount = minCrossAxisCount + 3;
    } else if (screenSize.width >= tabletBreakpoint) {
      crossAxisCount = minCrossAxisCount + 2;
    } else if (screenSize.width >= mobileBreakpoint) {
      crossAxisCount = minCrossAxisCount + 1;
    } else {
      crossAxisCount = minCrossAxisCount;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount.clamp(minCrossAxisCount, 6),
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }

  /// Create modern card with hover effects and accessibility
  Widget modernCard({
    required BuildContext context,
    required Widget child,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool elevated = true,
    Color? backgroundColor,
    Color? borderColor,
    double? borderRadius,
    List<BoxShadow>? boxShadow,
    bool enableHover = true,
    String? semanticLabel,
  }) {
    final theme = Theme.of(context);
    final isHighContrast = theme.brightness == Brightness.highContrastDark ||
                          theme.brightness == Brightness.highContrastLight;

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: AnimatedContainer(
        duration: defaultAnimationDuration,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.cardColor,
          borderRadius: BorderRadius.circular(borderRadius ?? defaultBorderRadius),
          border: borderColor != null ? Border.all(color: borderColor, width: 1) : null,
          boxShadow: elevated && !isHighContrast ? (boxShadow ?? [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: defaultElevation,
              offset: const Offset(0, 2),
            ),
          ]) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(borderRadius ?? defaultBorderRadius),
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  /// Create responsive navigation bar
  Widget responsiveNavigationBar({
    required BuildContext context,
    required List<NavigationItem> items,
    int currentIndex = 0,
    ValueChanged<int>? onTap,
    bool showLabels = true,
    NavigationType type = NavigationType.bottom,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width >= tabletBreakpoint;

    switch (type) {
      case NavigationType.bottom:
        return _buildBottomNavigationBar(context, items, currentIndex, onTap, showLabels);
      case NavigationType.rail:
        if (isLargeScreen) {
          return _buildNavigationRail(context, items, currentIndex, onTap, showLabels);
        }
        return _buildBottomNavigationBar(context, items, currentIndex, onTap, showLabels);
      case NavigationType.drawer:
        return _buildNavigationDrawer(context, items, currentIndex, onTap);
      default:
        return _buildBottomNavigationBar(context, items, currentIndex, onTap, showLabels);
    }
  }

  /// Create adaptive app bar with responsive actions
  PreferredSizeWidget adaptiveAppBar({
    required BuildContext context,
    Widget? title,
    List<Widget>? actions,
    bool automaticallyImplyLeading = true,
    PreferredSizeWidget? bottom,
    double? elevation,
    Color? backgroundColor,
    Color? foregroundColor,
    bool centerTitle = true,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < mobileBreakpoint;

    // Adaptive actions - show fewer on small screens
    final adaptiveActions = actions != null && isSmallScreen && actions.length > 3
        ? actions.take(2).toList() + [_buildMoreActionsMenu(actions.skip(2).toList())]
        : actions;

    return AppBar(
      title: title,
      actions: adaptiveActions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      bottom: bottom,
      elevation: elevation ?? (Theme.of(context).useMaterial3 ? 0 : 4),
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      centerTitle: centerTitle,
      scrolledUnderElevation: 4,
      shadowColor: Theme.of(context).shadowColor,
    );
  }

  /// Create responsive layout with sidebar for large screens
  Widget responsiveLayout({
    required BuildContext context,
    required Widget mainContent,
    Widget? sidebar,
    Widget? bottomBar,
    double sidebarWidth = 280,
    bool showSidebarOnLargeScreen = true,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width >= tabletBreakpoint;

    if (isLargeScreen && showSidebarOnLargeScreen && sidebar != null) {
      return Row(
        children: [
          SizedBox(
            width: sidebarWidth,
            child: sidebar,
          ),
          Expanded(
            child: Scaffold(
              body: mainContent,
              bottomNavigationBar: bottomBar,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      body: mainContent,
      drawer: sidebar,
      bottomNavigationBar: bottomBar,
    );
  }

  /// Create loading indicator with adaptive sizing
  Widget adaptiveLoadingIndicator({
    required BuildContext context,
    String? message,
    double? size,
    Color? color,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < mobileBreakpoint;

    final adaptiveSize = size ?? (isSmallScreen ? 24.0 : 36.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: adaptiveSize,
          height: adaptiveSize,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Theme.of(context).colorScheme.primary,
            ),
            strokeWidth: isSmallScreen ? 2.0 : 3.0,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Create responsive dialog
  Future<T?> showResponsiveDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < mobileBreakpoint;

    if (isSmallScreen) {
      // Use full screen dialog on small screens
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: screenSize.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                  ],
                ),
                Expanded(child: builder(context)),
              ],
            ),
          ),
        ),
      );
    } else {
      // Use regular dialog on larger screens
      return showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        barrierLabel: barrierLabel,
        builder: builder,
      );
    }
  }

  /// Create adaptive button with responsive sizing
  Widget adaptiveButton({
    required BuildContext context,
    required Widget child,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    ButtonStyle? style,
    bool expanded = false,
    Size? minimumSize,
    EdgeInsetsGeometry? padding,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < mobileBreakpoint;

    final adaptiveMinimumSize = minimumSize ?? Size(
      isSmallScreen ? 120 : 160,
      isSmallScreen ? 44 : 52,
    );

    final adaptivePadding = padding ?? EdgeInsets.symmetric(
      horizontal: isSmallScreen ? 16 : 24,
      vertical: isSmallScreen ? 12 : 16,
    );

    final adaptiveStyle = (style ?? ElevatedButton.styleFrom()).copyWith(
      minimumSize: MaterialStateProperty.all(adaptiveMinimumSize),
      padding: MaterialStateProperty.all(adaptivePadding),
      textStyle: MaterialStateProperty.all(
        Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: isSmallScreen ? 14 : 16,
        ),
      ),
    );

    Widget button = ElevatedButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: adaptiveStyle,
      child: child,
    );

    if (expanded) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  /// Get current screen size category
  ScreenSizeCategory getScreenSizeCategory(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= desktopBreakpoint) return ScreenSizeCategory.desktop;
    if (width >= tabletBreakpoint) return ScreenSizeCategory.tablet;
    if (width >= mobileBreakpoint) return ScreenSizeCategory.mobile;
    return ScreenSizeCategory.small;
  }

  /// Check if high contrast mode is enabled
  bool isHighContrastEnabled(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    return brightness == Brightness.highContrastDark ||
           brightness == Brightness.highContrastLight;
  }

  // Private methods

  Future<void> _configureSystemUI() async {
    // Configure system UI overlay
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _initializeThemes() async {
    final primaryColor = Color(_config.getParameter('ui.primary_color', defaultValue: 0xFF2196F3));
    final secondaryColor = Color(_config.getParameter('ui.secondary_color', defaultValue: 0xFF03DAC6));
    final accentColor = Color(_config.getParameter('ui.accent_color', defaultValue: 0xFFFF4081));
    final errorColor = Color(_config.getParameter('ui.error_color', defaultValue: 0xFFB00020));
    final warningColor = Color(_config.getParameter('ui.warning_color', defaultValue: 0xFFFF9800));
    final successColor = Color(_config.getParameter('ui.success_color', defaultValue: 0xFF4CAF50));
    final infoColor = Color(_config.getParameter('ui.info_color', defaultValue: 0xFF2196F3));

    final surfaceColor = Color(_config.getParameter('ui.surface_color', defaultValue: 0xFFFFFFFF));
    final backgroundColor = Color(_config.getParameter('ui.background_color', defaultValue: 0xFFFAFAFA));
    final cardColor = Color(_config.getParameter('ui.card_color', defaultValue: 0xFFFFFFFF));
    final dialogColor = Color(_config.getParameter('ui.dialog_color', defaultValue: 0xFFFFFFFF));

    final onPrimaryColor = Color(_config.getParameter('ui.on_primary', defaultValue: 0xFFFFFFFF));
    final onSecondaryColor = Color(_config.getParameter('ui.on_secondary', defaultValue: 0xFF000000));
    final onSurfaceColor = Color(_config.getParameter('ui.on_surface', defaultValue: 0xFF000000));
    final onBackgroundColor = Color(_config.getParameter('ui.on_background', defaultValue: 0xFF000000));
    final onErrorColor = Color(_config.getParameter('ui.on_error', defaultValue: 0xFFFFFFFF));

    // Light theme
    _lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: onPrimaryColor,
        onSecondary: onSecondaryColor,
        onSurface: onSurfaceColor,
        onBackground: onBackgroundColor,
        onError: onErrorColor,
      ),
      cardColor: cardColor,
      dialogBackgroundColor: dialogColor,
      scaffoldBackgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(defaultBorderRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: defaultElevation,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
    );

    // Dark theme with Material Design 3
    _darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1976D2), // Blue primary
        brightness: Brightness.dark,
      ),
      fontFamily: 'Roboto',
      cardTheme: CardTheme(
        elevation: defaultElevation,
        margin: const EdgeInsets.all(defaultMargin),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: defaultElevation,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(defaultBorderRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
        ),
        filled: true,
        fillColor: Colors.grey.shade900,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: defaultElevation,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
    );

    // High contrast theme
    _highContrastTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.highContrastLight(),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
          height: 1.3,
        ),
        bodyLarge: TextStyle(
          fontWeight: FontWeight.w500,
          height: 1.5,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    List<NavigationItem> items,
    int currentIndex,
    ValueChanged<int>? onTap,
    bool showLabels,
  ) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelBehavior: showLabels
          ? NavigationDestinationLabelBehavior.onlyShowSelected
          : NavigationDestinationLabelBehavior.alwaysHide,
      destinations: items.map((item) => NavigationDestination(
        icon: item.icon,
        selectedIcon: item.selectedIcon ?? item.icon,
        label: item.label,
        tooltip: item.tooltip,
      )).toList(),
    );
  }

  Widget _buildNavigationRail(
    BuildContext context,
    List<NavigationItem> items,
    int currentIndex,
    ValueChanged<int>? onTap,
    bool showLabels,
  ) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelType: showLabels ? NavigationRailLabelType.all : NavigationRailLabelType.none,
      destinations: items.map((item) => NavigationRailDestination(
        icon: item.icon,
        selectedIcon: item.selectedIcon ?? item.icon,
        label: Text(item.label),
      )).toList(),
      leading: const SizedBox(height: 16),
      trailing: const SizedBox(height: 16),
    );
  }

  Widget _buildNavigationDrawer(
    BuildContext context,
    List<NavigationItem> items,
    int currentIndex,
    ValueChanged<int>? onTap,
  ) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Navigation',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ...items.asMap().entries.map((entry) => ListTile(
            leading: entry.value.icon,
            title: Text(entry.value.label),
            selected: entry.key == currentIndex,
            onTap: () {
              onTap?.call(entry.key);
              Navigator.of(context).pop();
            },
          )),
        ],
      ),
    );
  }

  Widget _buildMoreActionsMenu(List<Widget> actions) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        // Handle menu selection
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'more',
          child: Row(
            children: [
              Icon(Icons.more_vert),
              SizedBox(width: 8),
              Text('More'),
            ],
          ),
        ),
      ],
      child: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(Icons.more_vert),
      ),
    );
  }
}

/// Navigation item configuration
class NavigationItem {
  final Widget icon;
  final Widget? selectedIcon;
  final String label;
  final String? tooltip;

  const NavigationItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.tooltip,
  });
}

/// Navigation type enum
enum NavigationType {
  bottom,
  rail,
  drawer,
}

/// Screen size categories
enum ScreenSizeCategory {
  small,    // < 600px
  mobile,   // 600-1199px
  tablet,   // 1200-1919px
  desktop,  // >= 1920px
}

/// Animation presets
class UIAnimations {
  static Curve defaultCurve = _config.getParameter('ui.animation_curve', defaultValue: Curves.easeInOut);
  static Curve bounceCurve = _config.getParameter('ui.animation_bounce_curve', defaultValue: Curves.bounceOut);
  static Curve elasticCurve = _config.getParameter('ui.animation_elastic_curve', defaultValue: Curves.elasticOut);

  static Animation<double> fadeIn(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: defaultCurve,
    ));
  }

  static Animation<double> slideUp(AnimationController controller) {
    return Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: defaultCurve,
    ));
  }

  static Animation<double> scaleIn(AnimationController controller) {
    return Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: bounceCurve,
    ));
  }
}

/// Responsive utilities
class ResponsiveUtils {
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < AdvancedUIService.mobileBreakpoint;
  }

  static bool isTabletScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AdvancedUIService.mobileBreakpoint && width < AdvancedUIService.tabletBreakpoint;
  }

  static bool isDesktopScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= AdvancedUIService.tabletBreakpoint;
  }

  static double responsiveValue({
    required BuildContext context,
    required double small,
    required double medium,
    required double large,
  }) {
    final screenSize = AdvancedUIService().getScreenSizeCategory(context);

    switch (screenSize) {
      case ScreenSizeCategory.small:
        return small;
      case ScreenSizeCategory.mobile:
        return small;
      case ScreenSizeCategory.tablet:
        return medium;
      case ScreenSizeCategory.desktop:
        return large;
    }
  }

  static EdgeInsets responsivePadding(BuildContext context) {
    return EdgeInsets.all(responsiveValue(
      context: context,
      small: 8.0,
      medium: 16.0,
      large: 24.0,
    ));
  }

  static double responsiveFontSize(BuildContext context, double baseSize) {
    final scale = responsiveValue(
      context: context,
      small: 0.9,
      medium: 1.0,
      large: 1.1,
    );
    return baseSize * scale;
  }
}

/// Accessibility helpers
class AccessibilityHelpers {
  static Widget accessibleButton({
    required BuildContext context,
    required Widget child,
    required VoidCallback onPressed,
    String? semanticLabel,
    String? tooltip,
    bool enabled = true,
    bool autofocus = false,
  }) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: enabled,
      child: Tooltip(
        message: tooltip ?? semanticLabel ?? '',
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          autofocus: autofocus,
          child: child,
        ),
      ),
    );
  }

  static Widget accessibleText({
    required BuildContext context,
    required String text,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    bool selectable = false,
  }) {
    final accessibleStyle = style?.copyWith(
      height: 1.5, // Better line height for accessibility
    ) ?? const TextStyle(height: 1.5);

    return Semantics(
      label: text,
      child: selectable
          ? SelectableText(
              text,
              style: accessibleStyle,
              textAlign: textAlign,
              maxLines: maxLines,
            )
          : Text(
              text,
              style: accessibleStyle,
              textAlign: textAlign,
              maxLines: maxLines,
            ),
    );
  }

  static Widget accessibleImage({
    required String imageUrl,
    required String semanticLabel,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const CircularProgressIndicator();
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image);
        },
      ),
    );
  }
}

/// Gesture and interaction helpers
class InteractionHelpers {
  static Widget gestureDetector({
    required Widget child,
    VoidCallback? onTap,
    VoidCallback? onDoubleTap,
    VoidCallback? onLongPress,
    ValueChanged<bool>? onHover,
    bool enableFeedback = true,
  }) {
    return MouseRegion(
      onHover: onHover != null ? (event) => onHover(true) : null,
      onExit: onHover != null ? (event) => onHover(false) : null,
      child: GestureDetector(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        child: child,
      ),
    );
  }

  static Widget animatedContainer({
    required Widget child,
    Duration duration = AdvancedUIService.defaultAnimationDuration,
    Curve curve = Curves.easeInOut,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    double? elevation,
  }) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        boxShadow: elevation != null && elevation > 0 ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: elevation,
            offset: Offset(0, elevation / 2),
          ),
        ] : null,
      ),
      padding: padding,
      child: child,
    );
  }
}
