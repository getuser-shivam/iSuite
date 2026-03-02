import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/central_config.dart';
import '../services/logging/logging_service.dart';

/// Accessibility Manager for enhanced user experience
class AccessibilityManager {
  static final AccessibilityManager _instance = AccessibilityManager._internal();
  factory AccessibilityManager() => _instance;
  AccessibilityManager._internal();

  final LoggingService _logger = LoggingService();
  final CentralConfig _config = CentralConfig.instance;

  bool _isInitialized = false;

  /// Initialize accessibility features
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing accessibility manager', 'AccessibilityManager');

      // Set up system UI overlays
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);

      // Configure accessibility settings
      _configureAccessibility();

      _isInitialized = true;
      _logger.info('Accessibility manager initialized', 'AccessibilityManager');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize accessibility manager', 'AccessibilityManager',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Configure accessibility settings
  void _configureAccessibility() {
    // Set up text scaling
    // Set up high contrast mode
    // Set up screen reader announcements
  }

  /// Get accessible text scale factor
  double getAccessibleTextScale(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final systemScale = mediaQuery.textScaleFactor;

    // Limit text scaling to prevent UI breaking
    const minScale = 0.8;
    const maxScale = 2.0;

    return systemScale.clamp(minScale, maxScale);
  }

  /// Check if high contrast mode is enabled
  bool isHighContrastEnabled(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    // In a real implementation, check system high contrast setting
    return brightness == Brightness.dark;
  }

  /// Announce content to screen readers
  void announceToScreenReader(String message, {String? assertion = 'content'}) {
    try {
      SemanticsService.announce(message, assertion ?? 'content');
      _logger.debug('Announced to screen reader: $message', 'AccessibilityManager');
    } catch (e) {
      _logger.error('Failed to announce to screen reader', 'AccessibilityManager', error: e);
    }
  }

  /// Get accessible colors based on theme
  AccessibleColors getAccessibleColors(BuildContext context) {
    final isHighContrast = isHighContrastEnabled(context);
    final theme = Theme.of(context);

    if (isHighContrast) {
      return AccessibleColors(
        primary: Colors.yellow,
        onPrimary: Colors.black,
        secondary: Colors.blue,
        onSecondary: Colors.white,
        surface: Colors.black,
        onSurface: Colors.white,
        error: Colors.red,
        onError: Colors.white,
      );
    }

    return AccessibleColors(
      primary: theme.primaryColor,
      onPrimary: theme.primaryTextTheme.bodyLarge?.color ?? Colors.white,
      secondary: theme.colorScheme.secondary,
      onSecondary: theme.colorScheme.onSecondary,
      surface: theme.colorScheme.surface,
      onSurface: theme.colorScheme.onSurface,
      error: theme.colorScheme.error,
      onError: theme.colorScheme.onError,
    );
  }

  /// Get accessible font sizes
  AccessibleFontSizes getAccessibleFontSizes(BuildContext context) {
    final textScale = getAccessibleTextScale(context);
    final baseSize = 14.0;

    return AccessibleFontSizes(
      small: baseSize * 0.8 * textScale,
      medium: baseSize * textScale,
      large: baseSize * 1.2 * textScale,
      xlarge: baseSize * 1.5 * textScale,
      xxlarge: baseSize * 2.0 * textScale,
    );
  }

  /// Create accessible button with proper semantics
  Widget createAccessibleButton({
    required Widget child,
    required VoidCallback onPressed,
    required String label,
    String? hint,
    bool enabled = true,
    Key? key,
  }) {
    return Semantics(
      key: key,
      label: label,
      hint: hint,
      enabled: enabled,
      button: true,
      child: ExcludeSemantics(
        child: child,
      ),
    );
  }

  /// Create accessible text with proper semantics
  Widget createAccessibleText(
    String text, {
    TextStyle? style,
    Key? key,
    bool isHeader = false,
    String? semanticLabel,
  }) {
    return Semantics(
      key: key,
      label: semanticLabel ?? text,
      header: isHeader,
      child: Text(
        text,
        style: style,
      ),
    );
  }

  /// Handle keyboard navigation focus
  void handleKeyboardFocus(BuildContext context, FocusNode node) {
    FocusScope.of(context).requestFocus(node);
    announceToScreenReader('Focused on ${node.debugLabel ?? 'element'}');
  }

  /// Check if screen reader is enabled
  Future<bool> isScreenReaderEnabled() async {
    // In a real implementation, check platform-specific accessibility settings
    // For now, return false as we can't reliably detect this
    return false;
  }
}

/// Accessible color scheme
class AccessibleColors {
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color surface;
  final Color onSurface;
  final Color error;
  final Color onError;

  const AccessibleColors({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.surface,
    required this.onSurface,
    required this.error,
    required this.onError,
  });
}

/// Accessible font sizes
class AccessibleFontSizes {
  final double small;
  final double medium;
  final double large;
  final double xlarge;
  final double xxlarge;

  const AccessibleFontSizes({
    required this.small,
    required this.medium,
    required this.large,
    required this.xlarge,
    required this.xxlarge,
  });
}

/// Enhanced accessibility widget for complex UI elements
class AccessibleWrapper extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final bool? enabled;
  final bool? checked;
  final bool? selected;
  final String? value;
  final VoidCallback? onTap;

  const AccessibleWrapper({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.enabled,
    this.checked,
    this.selected,
    this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      enabled: enabled,
      checked: checked,
      selected: selected,
      value: value,
      onTap: onTap != null ? () {
        onTap!();
        AccessibilityManager().announceToScreenReader('$label activated');
      } : null,
      child: child,
    );
  }
}

/// Keyboard navigation helper
class KeyboardNavigator {
  static const Map<LogicalKeyboardKey, String> _keyDescriptions = {
    LogicalKeyboardKey.tab: 'Next element',
    LogicalKeyboardKey.shiftLeft: 'Modifier',
    LogicalKeyboardKey.controlLeft: 'Modifier',
    LogicalKeyboardKey.altLeft: 'Modifier',
    LogicalKeyboardKey.escape: 'Exit or cancel',
    LogicalKeyboardKey.enter: 'Activate',
    LogicalKeyboardKey.space: 'Activate or toggle',
    LogicalKeyboardKey.arrowUp: 'Navigate up',
    LogicalKeyboardKey.arrowDown: 'Navigate down',
    LogicalKeyboardKey.arrowLeft: 'Navigate left',
    LogicalKeyboardKey.arrowRight: 'Navigate right',
  };

  /// Get description for a keyboard key
  static String getKeyDescription(LogicalKeyboardKey key) {
    return _keyDescriptions[key] ?? 'Key pressed';
  }

  /// Announce keyboard navigation
  static void announceNavigation(String direction, BuildContext context) {
    AccessibilityManager().announceToScreenReader('Navigated $direction');
  }
}
