import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/central_config.dart';
import 'logging_service.dart';

/// Enhanced UI/UX Service for iSuite
/// Provides beautiful, accessible, and modern UI components using FREE design libraries
/// Includes animations, themes, components, and user experience enhancements
class EnhancedUIUXService {
  static final EnhancedUIUXService _instance = EnhancedUIUXService._internal();
  factory EnhancedUIUXService() => _instance;

  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();

  bool _isInitialized = false;
  final Map<String, ThemeData> _customThemes = {};
  final Map<String, AnimationController> _animationControllers = {};

  // UI Enhancement settings
  bool _highContrastEnabled = false;
  bool _reducedMotionEnabled = false;
  double _textScaleFactor = 1.0;
  ThemeMode _themeMode = ThemeMode.system;

  final StreamController<UIEvent> _uiEventController =
      StreamController.broadcast();

  Stream<UIEvent> get uiEvents => _uiEventController.stream;

  EnhancedUIUXService._internal();

  /// Initialize enhanced UI/UX service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Register with CentralConfig
      await _config.registerComponent('EnhancedUIUXService', '1.0.0',
          'Enhanced UI/UX service with beautiful components, animations, and accessibility features',
          dependencies: [
            'CentralConfig',
            'LoggingService'
          ],
          parameters: {
            // Theme settings
            'ui.theme.mode': 'system', // system, light, dark
            'ui.theme.custom_enabled': true,
            'ui.theme.dynamic_colors': true,

            // Accessibility
            'ui.accessibility.high_contrast': false,
            'ui.accessibility.reduced_motion': false,
            'ui.accessibility.large_text': false,
            'ui.accessibility.screen_reader': false,

            // Animations
            'ui.animations.enabled': true,
            'ui.animations.duration_ms': 300,
            'ui.animations.curve': 'easeOutCubic',

            // Components
            'ui.components.ripple_effect': true,
            'ui.components.elevation': true,
            'ui.components.shadows': true,

            // Layout
            'ui.layout.adaptive': true,
            'ui.layout.tablet_optimized': true,
            'ui.layout.desktop_optimized': true,

            // Performance
            'ui.performance.lazy_loading': true,
            'ui.performance.image_optimization': true,
            'ui.performance.animation_optimization': true,
          });

      // Load UI preferences
      await _loadUIPreferences();

      _isInitialized = true;
      _emitUIEvent(UIEventType.initialized);

      _logger.info('Enhanced UI/UX Service initialized', 'EnhancedUIUXService');
    } catch (e, stackTrace) {
      _logger.error(
          'Failed to initialize Enhanced UI/UX Service', 'EnhancedUIUXService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get enhanced theme data
  Future<ThemeData> getEnhancedTheme({
    required Brightness brightness,
    bool useMaterial3 = true,
    bool highContrast = false,
  }) async {
    final baseTheme = brightness == Brightness.light
        ? ThemeData.light(useMaterial3: useMaterial3)
        : ThemeData.dark(useMaterial3: useMaterial3);

    // Get theme parameters from config
    final primaryColor =
        await _config.getParameter<int>('ui.primary_color') ?? 0xFF2196F3;
    final secondaryColor =
        await _config.getParameter<int>('ui.secondary_color') ?? 0xFF03DAC6;
    final borderRadius =
        await _config.getParameter<double>('ui.border_radius_large') ?? 16.0;

    // Enhanced color scheme
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Color(primaryColor),
      brightness: brightness,
      secondary: Color(secondaryColor),
      surfaceTint: highContrast ? Colors.transparent : null,
    );

    // Apply high contrast adjustments
    final adjustedColorScheme = highContrast
        ? colorScheme.copyWith(
            primary: Colors.white,
            onPrimary: Colors.black,
            secondary: Colors.yellow,
            onSecondary: Colors.black,
            surface: Colors.black,
            onSurface: Colors.white,
          )
        : colorScheme;

    return baseTheme.copyWith(
      colorScheme: adjustedColorScheme,

      // Enhanced component themes
      appBarTheme: await _getEnhancedAppBarTheme(brightness),
      cardTheme: await _getEnhancedCardTheme(),
      buttonTheme: await _getEnhancedButtonTheme(),
      inputDecorationTheme: await _getEnhancedInputTheme(),
      floatingActionButtonTheme: await _getEnhancedFABTheme(),

      // Typography
      textTheme: await _getEnhancedTextTheme(brightness),

      // Animations and transitions
      pageTransitionsTheme: await _getEnhancedPageTransitions(),

      // Custom properties
      extensions: <ThemeExtension<dynamic>>[
        CustomUITheme(
          borderRadius: BorderRadius.circular(borderRadius),
          shadowColor:
              brightness == Brightness.light ? Colors.black12 : Colors.white12,
          animationDuration: Duration(
              milliseconds: await _config
                      .getParameter<int>('ui.animations.duration_ms') ??
                  300),
        ),
      ],
    );
  }

  /// Create beautiful loading shimmer effect
  Widget createShimmerLoading({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
    Duration? duration,
    ShimmerDirection direction = ShimmerDirection.ltr,
  }) {
    final brightness = Theme.of(child as BuildContext).brightness;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            baseColor ??
                (brightness == Brightness.light
                    ? Colors.grey[300]!
                    : Colors.grey[700]!),
            highlightColor ??
                (brightness == Brightness.light
                    ? Colors.grey[100]!
                    : Colors.grey[800]!),
            baseColor ??
                (brightness == Brightness.light
                    ? Colors.grey[300]!
                    : Colors.grey[700]!),
          ],
          stops: const [0.1, 0.5, 0.9],
        ),
      ),
      child: child,
    );
  }

  /// Create animated gradient background
  Widget createAnimatedGradientBackground({
    required List<Color> colors,
    required Widget child,
    Duration duration = const Duration(seconds: 3),
    bool animate = true,
  }) {
    if (!animate || _reducedMotionEnabled) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: child,
      );
    }

    return AnimatedContainer(
      duration: duration,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }

  /// Create glass morphism effect
  Widget createGlassMorphism({
    required Widget child,
    double blur = 10,
    double opacity = 0.1,
    Color? tintColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: (tintColor ?? Colors.white).withOpacity(opacity),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Create animated icon button with ripple
  Widget createAnimatedIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    double size = 24,
    String? tooltip,
    bool enableFeedback = true,
  }) {
    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          icon,
          key: ValueKey<IconData>(icon),
          color: color,
          size: size,
        ),
      ),
      onPressed: onPressed,
      tooltip: tooltip,
      enableFeedback: enableFeedback && !_reducedMotionEnabled,
    );
  }

  /// Create modern card with hover effects
  Widget createModernCard({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    double elevation = 2,
    Color? backgroundColor,
    BorderRadius? borderRadius,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: elevation,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: child,
      ),
    );
  }

  /// Create smooth page transition
  Route createSmoothPageRoute({
    required Widget page,
    RouteSettings? settings,
    bool maintainState = true,
  }) {
    return PageRouteBuilder(
      settings: settings,
      maintainState: maintainState,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Create responsive layout builder
  Widget createResponsiveLayout({
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= 600) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }

  /// Create adaptive text that scales with accessibility settings
  Widget createAdaptiveText(
    String text, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    final scaledStyle = style?.copyWith(
      fontSize: (style.fontSize ?? 14) * _textScaleFactor,
    );

    return Text(
      text,
      style: scaledStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      textScaleFactor: _highContrastEnabled ? 1.2 : 1.0,
    );
  }

  /// Show modern snackbar
  void showModernSnackBar({
    required BuildContext context,
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
    bool floating = true,
  }) {
    final snackBar = SnackBar(
      content: Text(message),
      action: action,
      duration: duration,
      behavior: floating ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: floating ? const EdgeInsets.all(8) : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Create loading overlay
  Widget createLoadingOverlay({
    required BuildContext context,
    required bool isLoading,
    required Widget child,
    String? loadingText,
  }) {
    if (!isLoading) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (loadingText != null) ...[
                        const SizedBox(height: 16),
                        Text(loadingText),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Update UI preferences
  Future<void> updateUIPreferences({
    ThemeMode? themeMode,
    bool? highContrast,
    bool? reducedMotion,
    double? textScaleFactor,
  }) async {
    if (themeMode != null) {
      _themeMode = themeMode;
      await _config.setParameter(
          'ui.theme.mode', themeMode.toString().split('.').last);
    }

    if (highContrast != null) {
      _highContrastEnabled = highContrast;
      await _config.setParameter(
          'ui.accessibility.high_contrast', highContrast);
    }

    if (reducedMotion != null) {
      _reducedMotionEnabled = reducedMotion;
      await _config.setParameter(
          'ui.accessibility.reduced_motion', reducedMotion);
    }

    if (textScaleFactor != null) {
      _textScaleFactor = textScaleFactor;
      await _config.setParameter(
          'ui.accessibility.text_scale', textScaleFactor);
    }

    _emitUIEvent(UIEventType.preferencesUpdated);
  }

  /// Get current theme mode
  ThemeMode get themeMode => _themeMode;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  // Private helper methods

  Future<void> _loadUIPreferences() async {
    final themeModeStr = await _config.getParameter<String>('ui.theme.mode',
        defaultValue: 'system');
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.toString().split('.').last == themeModeStr,
      orElse: () => ThemeMode.system,
    );

    _highContrastEnabled = await _config.getParameter<bool>(
        'ui.accessibility.high_contrast',
        defaultValue: false);
    _reducedMotionEnabled = await _config.getParameter<bool>(
        'ui.accessibility.reduced_motion',
        defaultValue: false);
    _textScaleFactor = await _config
        .getParameter<double>('ui.accessibility.text_scale', defaultValue: 1.0);
  }

  Future<AppBarTheme> _getEnhancedAppBarTheme(Brightness brightness) async {
    return AppBarTheme(
      elevation: await _config.getParameter<double>('appbar.elevation') ?? 0.0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor:
          brightness == Brightness.light ? Colors.black87 : Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      scrolledUnderElevation:
          await _config.getParameter<double>('ui.elevation_high') ?? 4.0,
      titleTextStyle: TextStyle(
        fontSize:
            await _config.getParameter<double>('appbar.title_font_size') ??
                20.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: brightness == Brightness.light ? Colors.black87 : Colors.white,
      ),
      toolbarTextStyle: TextStyle(
        fontSize:
            await _config.getParameter<double>('ui.font_size_medium') ?? 14.0,
        fontWeight: FontWeight.w500,
        color: brightness == Brightness.light ? Colors.black87 : Colors.white,
      ),
    );
  }

  Future<CardTheme> _getEnhancedCardTheme() async {
    return CardTheme(
      elevation:
          await _config.getParameter<double>('ui.elevation_medium') ?? 2.0,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
            await _config.getParameter<double>('ui.border_radius_large') ??
                16.0),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.symmetric(
        horizontal:
            await _config.getParameter<double>('ui.margin_small') ?? 8.0,
        vertical: await _config.getParameter<double>('ui.margin_small') ?? 4.0,
      ),
    );
  }

  Future<AnimatedButtonTheme> _getEnhancedButtonTheme() async {
    return AnimatedButtonTheme(
      style: ElevatedButton.styleFrom(
        elevation:
            await _config.getParameter<double>('ui.elevation_low') ?? 0.0,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal:
              await _config.getParameter<double>('ui.padding_medium') ?? 24.0,
          vertical:
              await _config.getParameter<double>('ui.padding_medium') ?? 12.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
              await _config.getParameter<double>('ui.border_radius_medium') ??
                  12.0),
        ),
        animationDuration: Duration(
            milliseconds:
                await _config.getParameter<int>('ui.animations.duration_ms') ??
                    200),
      ),
    );
  }

  Future<InputDecorationTheme> _getEnhancedInputTheme() async {
    return InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x0F000000), // 6% black
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
            await _config.getParameter<double>('ui.border_radius_medium') ??
                12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
            await _config.getParameter<double>('ui.border_radius_medium') ??
                12.0),
        borderSide: BorderSide(
          color: const Color(0x1F000000), // 12% black
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
            await _config.getParameter<double>('ui.border_radius_medium') ??
                12.0),
        borderSide: const BorderSide(
          color: Color(0xFF2196F3),
          width: 2,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal:
            await _config.getParameter<double>('ui.padding_medium') ?? 16.0,
        vertical:
            await _config.getParameter<double>('ui.padding_medium') ?? 12.0,
      ),
    );
  }

  Future<FloatingActionButtonThemeData> _getEnhancedFABTheme() async {
    return FloatingActionButtonThemeData(
      elevation: await _config.getParameter<double>('fab.elevation') ?? 6.0,
      focusElevation:
          await _config.getParameter<double>('fab.elevation') ?? 6.0 + 2.0,
      hoverElevation:
          await _config.getParameter<double>('fab.elevation') ?? 6.0 + 2.0,
      backgroundColor: const Color(0xFF2196F3),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
            await _config.getParameter<double>('fab.size') ?? 56.0 / 2),
      ),
      extendedPadding: EdgeInsets.symmetric(
          horizontal: await _config
                  .getParameter<double>('fab.extended_padding_horizontal') ??
              16.0),
      extendedIconLabelSpacing:
          await _config.getParameter<double>('fab.extended_icon_spacing') ??
              8.0,
    );
  }

  Future<TextTheme> _getEnhancedTextTheme(Brightness brightness) async {
    final baseColor =
        brightness == Brightness.light ? Colors.black87 : Colors.white;

    return TextTheme(
      displayLarge: TextStyle(
        fontSize:
            await _config.getParameter<double>('ui.font_size_display_large') ??
                57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
        color: baseColor,
      ),
      displayMedium: TextStyle(
        fontSize:
            await _config.getParameter<double>('ui.font_size_display_medium') ??
                45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.16,
        color: baseColor,
      ),
      headlineLarge: TextStyle(
        fontSize:
            await _config.getParameter<double>('ui.font_size_headline_large') ??
                32,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.25,
        color: baseColor,
      ),
      titleLarge: TextStyle(
        fontSize:
            await _config.getParameter<double>('ui.font_size_title_large') ??
                22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.0,
        height: 1.27,
        color: baseColor,
      ),
      bodyLarge: TextStyle(
        fontSize:
            await _config.getParameter<double>('ui.font_size_body_large') ?? 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
        color: baseColor,
      ),
      labelLarge: TextStyle(
        fontSize:
            await _config.getParameter<double>('ui.font_size_label_large') ??
                14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        color: baseColor,
      ),
    );
  }

  Future<PageTransitionsTheme> _getEnhancedPageTransitions() async {
    final curve = await _config.getParameter<String>('ui.animations.curve',
        defaultValue: 'easeOutCubic');
    final duration = Duration(
        milliseconds:
            await _config.getParameter<int>('ui.animations.duration_ms') ??
                300);

    return PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _createSmoothTransitionBuilder(curve, duration),
        TargetPlatform.iOS: _createSmoothTransitionBuilder(curve, duration),
        TargetPlatform.windows: _createSmoothTransitionBuilder(curve, duration),
        TargetPlatform.macOS: _createSmoothTransitionBuilder(curve, duration),
        TargetPlatform.linux: _createSmoothTransitionBuilder(curve, duration),
      },
    );
  }

  PageTransitionsBuilder _createSmoothTransitionBuilder(
      String curve, Duration duration) {
    return SmoothPageTransitionBuilder(curve: curve, duration: duration);
  }

  void _emitUIEvent(UIEventType type, {Map<String, dynamic>? data}) {
    final event = UIEvent(
      type: type,
      timestamp: DateTime.now(),
      data: data,
    );
    _uiEventController.add(event);
  }

  /// Dispose service
  Future<void> dispose() async {
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    _uiEventController.close();
    _isInitialized = false;
    _logger.info('Enhanced UI/UX Service disposed', 'EnhancedUIUXService');
  }
}

/// Supporting Classes and Extensions

enum UIEventType {
  initialized,
  preferencesUpdated,
  themeChanged,
  animationCompleted,
  componentRendered,
}

class UIEvent {
  final UIEventType type;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  UIEvent({
    required this.type,
    required this.timestamp,
    this.data,
  });
}

class CustomUITheme extends ThemeExtension<CustomUITheme> {
  final BorderRadius borderRadius;
  final Color shadowColor;
  final Duration animationDuration;

  CustomUITheme({
    required this.borderRadius,
    required this.shadowColor,
    required this.animationDuration,
  });

  @override
  CustomUITheme copyWith({
    BorderRadius? borderRadius,
    Color? shadowColor,
    Duration? animationDuration,
  }) {
    return CustomUITheme(
      borderRadius: borderRadius ?? this.borderRadius,
      shadowColor: shadowColor ?? this.shadowColor,
      animationDuration: animationDuration ?? this.animationDuration,
    );
  }

  @override
  CustomUITheme lerp(ThemeExtension<CustomUITheme>? other, double t) {
    if (other is! CustomUITheme) return this;
    return CustomUITheme(
      borderRadius: BorderRadius.lerp(borderRadius, other.borderRadius, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      animationDuration: Duration(
        milliseconds: ((animationDuration.inMilliseconds * (1 - t)) +
                (other.animationDuration.inMilliseconds * t))
            .round(),
      ),
    );
  }
}

class AnimatedButtonTheme extends ThemeExtension<AnimatedButtonTheme> {
  final ButtonStyle style;

  AnimatedButtonTheme({required this.style});

  @override
  AnimatedButtonTheme copyWith({ButtonStyle? style}) {
    return AnimatedButtonTheme(style: style ?? this.style);
  }

  @override
  AnimatedButtonTheme lerp(
      ThemeExtension<AnimatedButtonTheme>? other, double t) {
    if (other is! AnimatedButtonTheme) return this;
    return AnimatedButtonTheme(style: style);
  }
}

class SmoothPageTransitionBuilder extends PageTransitionsBuilder {
  final String curve;
  final Duration duration;

  SmoothPageTransitionBuilder({
    required this.curve,
    required this.duration,
  });

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;

    final curveTween = CurveTween(curve: _getCurve(curve));
    final tween = Tween(begin: begin, end: end).chain(curveTween);
    final offsetAnimation = animation.drive(tween);

    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }

  Curve _getCurve(String curveName) {
    switch (curveName) {
      case 'easeOutCubic':
        return Curves.easeOutCubic;
      case 'easeInOut':
        return Curves.easeInOut;
      case 'bounceOut':
        return Curves.bounceOut;
      case 'elasticOut':
        return Curves.elasticOut;
      default:
        return Curves.easeOutCubic;
    }
  }
}

/// Enhanced UI Components Library

class EnhancedUIComponents {
  /// Create a beautiful onboarding card
  static Widget onboardingCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Create an animated progress indicator
  static Widget animatedProgressIndicator({
    required double progress,
    Color? color,
    double size = 100,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress),
        duration: duration,
        builder: (context, value, child) {
          return CircularProgressIndicator(
            value: value,
            color: color,
            strokeWidth: 8,
          );
        },
      ),
    );
  }

  /// Create a modern bottom sheet
  static Future<T?> showModernBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    Color? backgroundColor,
    double? elevation,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation ?? 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: builder(context),
      ),
    );
  }
}
