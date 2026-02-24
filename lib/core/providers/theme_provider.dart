import 'package:flutter/material.dart';
import '../config/central_config.dart';

/// Theme Provider - Manages app theme and appearance with central configuration
class ThemeProvider extends ChangeNotifier {
  final CentralConfig _config = CentralConfig.instance;

  // Centralized theme parameters
  late ThemeMode _themeMode;
  late double _textScaleFactor;
  late bool _useMaterial3;
  late bool _useHighContrast;
  late bool _reduceMotion;
  late Color _primaryColor;
  late Color _secondaryColor;

  // Component-specific theme parameters
  late double _borderRadius;
  late double _elevation;
  late Duration _animationDuration;

  // UI Parameters from central config
  late double _paddingSmall;
  late double _paddingMedium;
  late double _paddingLarge;
  late double _marginSmall;
  late double _marginMedium;
  late double _marginLarge;
  late double _borderRadiusSmall;
  late double _borderRadiusMedium;
  late double _borderRadiusLarge;
  late double _borderRadiusXLarge;
  late double _elevationLow;
  late double _elevationMedium;
  late double _elevationHigh;
  late double _elevationXHigh;
  late double _iconSizeSmall;
  late double _iconSizeMedium;
  late double _iconSizeLarge;
  late double _iconSizeXLarge;
  late double _iconSizeXXLarge;
  late double _fontSizeSmall;
  late double _fontSizeMedium;
  late double _fontSizeLarge;
  late double _fontSizeXLarge;
  late double _fontSizeXXLarge;
  late double _fontSizeHuge;
  late Duration _animationDurationFast;
  late Duration _animationDurationMedium;
  late Duration _animationDurationSlow;
  late Duration _animationDurationSlowest;
  late Duration _animationDelayShort;
  late Duration _animationDelayMedium;
  late Duration _animationDelayLong;
  late Duration _animationDelayXLong;
  late int _gridCrossAxisCount;
  late double _gridCrossAxisSpacing;
  late double _gridMainAxisSpacing;
  late double _gridChildAspectRatio;
  late double _cardMinHeight;
  late double _cardMaxWidth;
  late double _cardActionTileWidth;
  late double _cardActionTileHeight;
  late double _opacityLow;
  late double _opacityMedium;
  late double _opacityHigh;
  late double _opacityOverlay;
  late double _blurRadiusSmall;
  late double _blurRadiusMedium;
  late double _blurRadiusLarge;
  late Offset _shadowOffset;

  // UI Color getters
  Color get uiSurfaceColor => Color(_surfaceColor);
  Color get uiBackgroundColor => Color(_backgroundColor);
  Color get uiErrorColor => Color(_errorColor ?? 0xFFB00020);

  // Card color getters
  Color get uiCardPrimaryColor => Color(_cardPrimaryColor ?? _primaryColor);
  Color get uiCardSecondaryColor => Color(_cardSecondaryColor ?? _secondaryColor);
  Color get uiCardSuccessColor => Color(_cardSuccessColor ?? 0xFF4CAF50);
  Color get uiCardWarningColor => Color(_cardWarningColor ?? 0xFFFF9800);
  Color get uiCardErrorColor => Color(_cardErrorColor ?? 0xFFF44336);
  Color get uiCardInfoColor => Color(_cardInfoColor ?? _primaryColor);

  // Spacing getters
  double get uiPaddingSmall => _paddingSmall;
  double get uiPaddingMedium => _paddingMedium;
  double get uiPaddingLarge => _paddingLarge;
  double get uiMarginSmall => _marginSmall;
  double get uiMarginMedium => _marginMedium;
  double get uiMarginLarge => _marginLarge;

  // Border radius getters
  double get uiBorderRadiusSmall => _borderRadiusSmall;
  double get uiBorderRadiusMedium => _borderRadiusMedium;
  double get uiBorderRadiusLarge => _borderRadiusLarge;
  double get uiBorderRadiusXLarge => _borderRadiusXLarge;

  // Elevation getters
  double get uiElevationLow => _elevationLow;
  double get uiElevationMedium => _elevationMedium;
  double get uiElevationHigh => _elevationHigh;
  double get uiElevationXHigh => _elevationXHigh;

  // Icon size getters
  double get uiIconSizeSmall => _iconSizeSmall;
  double get uiIconSizeMedium => _iconSizeMedium;
  double get uiIconSizeLarge => _iconSizeLarge;
  double get uiIconSizeXLarge => _iconSizeXLarge;
  double get uiIconSizeXXLarge => _iconSizeXXLarge;

  // Font size getters
  double get uiFontSizeSmall => _fontSizeSmall;
  double get uiFontSizeMedium => _fontSizeMedium;
  double get uiFontSizeLarge => _fontSizeLarge;
  double get uiFontSizeXLarge => _fontSizeXLarge;
  double get uiFontSizeXXLarge => _fontSizeXXLarge;
  double get uiFontSizeHuge => _fontSizeHuge;

  // Animation getters
  Duration get uiAnimationDurationFast => _animationDurationFast;
  Duration get uiAnimationDurationMedium => _animationDurationMedium;
  Duration get uiAnimationDurationSlow => _animationDurationSlow;
  Duration get uiAnimationDurationSlowest => _animationDurationSlowest;
  Duration get uiAnimationDelayShort => _animationDelayShort;
  Duration get uiAnimationDelayMedium => _animationDelayMedium;
  Duration get uiAnimationDelayLong => _animationDelayLong;
  Duration get uiAnimationDelayXLong => _animationDelayXLong;

  // Grid layout getters
  int get uiGridCrossAxisCount => _gridCrossAxisCount;
  double get uiGridCrossAxisSpacing => _gridCrossAxisSpacing;
  double get uiGridMainAxisSpacing => _gridMainAxisSpacing;
  double get uiGridChildAspectRatio => _gridChildAspectRatio;

  // Card dimension getters
  double get uiCardMinHeight => _cardMinHeight;
  double get uiCardMaxWidth => _cardMaxWidth;
  double get uiCardActionTileWidth => _cardActionTileWidth;
  double get uiCardActionTileHeight => _cardActionTileHeight;

  // Opacity getters
  double get uiOpacityLow => _opacityLow;
  double get uiOpacityMedium => _opacityMedium;
  double get uiOpacityHigh => _opacityHigh;
  double get uiOpacityOverlay => _opacityOverlay;

  // Blur radius getters
  double get uiBlurRadiusSmall => _blurRadiusSmall;
  double get uiBlurRadiusMedium => _blurRadiusMedium;
  double get uiBlurRadiusLarge => _blurRadiusLarge;

  // Shadow getters
  Offset get uiShadowOffset => _shadowOffset;

  // Navigation & App Configuration Parameters
  late bool _enableBottomNav;
  late bool _enableDrawer;
  late bool _enableFab;
  late bool _enableAppBar;
  late bool _enableSearch;
  late bool _enableNotifications;
  late Duration _navigationAnimationDuration;
  late String _navigationTransitionType;
  late bool _enableNestedNavigation;
  late int _maxBackStack;
  late bool _enableGestures;

  // App Bar Parameters
  late bool _appBarEnableTitleAnimation;
  late double _appBarElevation;
  late double _appBarHeight;
  late bool _appBarEnableTransparency;
  late double _appBarTitleFontSize;
  late bool _appBarEnableActionsAnimation;

  // Bottom Navigation Parameters
  late double _bottomNavHeight;
  late bool _bottomNavEnableLabels;
  late double _bottomNavIconSize;
  late Duration _bottomNavAnimationDuration;
  late bool _bottomNavEnableIndicator;
  late double _bottomNavIndicatorHeight;

  // FAB Parameters
  late double _fabSize;
  late double _fabElevation;
  late double _fabExtendedPaddingHorizontal;
  late double _fabExtendedIconSpacing;
  late Duration _fabAnimationDuration;
  late bool _fabEnableHeroAnimation;

  // Performance Parameters
  late bool _performanceEnableImageCaching;
  late int _performanceImageCacheSizeMb;
  late bool _performanceEnableListVirtualization;
  late int _performanceVirtualizationThreshold;
  late bool _performanceEnablePreloading;
  late int _performancePreloadDistance;
  late bool _performanceEnableCompression;
  late int _performanceCompressionLevel;
  late bool _performanceEnableMemoryOptimization;
  late int _performanceGcThresholdMb;

  // Error Handling Parameters
  late bool _errorEnableErrorBoundary;
  late bool _errorEnableErrorReporting;
  late String _errorReportEndpoint;
  late bool _errorEnableRetryDialog;
  late int _errorMaxRetryAttempts;
  late int _errorRetryDelayMs;
  late bool _errorEnableOfflineFallback;
  late bool _errorEnableErrorToast;
  late int _errorToastDurationSeconds;

  // Accessibility Parameters
  late bool _accessibilityEnableScreenReader;
  late bool _accessibilityEnableHighContrast;
  late bool _accessibilityEnableReducedMotion;
  late bool _accessibilityEnableLargeText;
  late double _accessibilityTouchTargetSize;
  late double _accessibilityFocusIndicatorWidth;
  late bool _accessibilityEnableKeyboardNavigation;
  late bool _accessibilityAnnounceRouteChanges;

  // Notification Parameters
  late bool _notificationsEnablePush;
  late bool _notificationsEnableLocal;
  late bool _notificationsEnableSound;
  late bool _notificationsEnableVibration;
  late int _notificationsMaxNotifications;
  late int _notificationsAutoHideSeconds;
  late bool _notificationsGroupSimilar;
  late bool _notificationsEnableActions;

  // Search Parameters
  late bool _searchEnableGlobalSearch;
  late int _searchMaxResults;
  late int _searchTimeoutSeconds;
  late bool _searchEnableFuzzySearch;
  late bool _searchEnableRecentSearches;
  late int _searchMaxRecentSearches;
  late bool _searchEnableSearchSuggestions;
  late bool _searchEnableVoiceSearch;

  // Data Management Parameters
  late bool _dataEnableAutoSave;
  late int _dataAutoSaveIntervalSeconds;
  late bool _dataEnableBackup;
  late int _dataBackupIntervalHours;
  late int _dataBackupRetentionDays;
  late bool _dataEnableEncryption;
  late String _dataEncryptionAlgorithm;
  late bool _dataEnableCompression;
  late String _dataCompressionAlgorithm;

  // Platform Parameters
  late bool _platformEnablePlatformOptimizations;
  late bool _platformAndroidEnableBiometric;
  late bool _platformIosEnableFaceId;
  late bool _platformWindowsEnableSystemIntegration;
  late bool _platformWebEnablePwa;
  late bool _platformWebEnableServiceWorker;

  // Analytics Parameters
  late bool _analyticsEnableAnalytics;
  late String _analyticsProvider;
  late bool _analyticsEnableCrashReporting;
  late bool _analyticsEnablePerformanceMonitoring;
  late double _analyticsSamplingRate;
  late bool _analyticsEnableUserTracking;
  late bool _analyticsAnonymizeIp;

  // Internationalization Parameters
  late bool _i18nEnableI18n;
  late String _i18nDefaultLocale;
  late String _i18nSupportedLocales;
  late bool _i18nEnableRtl;
  late bool _i18nEnablePluralization;
  late String _i18nDateFormat;
  late String _i18nTimeFormat;

  // Security Parameters
  late bool _securityEnableSslPinning;
  late bool _securityEnableCertificateValidation;
  late bool _securityEnableDataSanitization;
  late bool _securityEnablePrivacyMode;
  late int _securitySessionTimeoutMinutes;
  late bool _securityEnableAutoLock;
  late int _securityAutoLockTimeoutMinutes;
  late bool _securityEnableSecureStorage;

  // Debug Parameters
  late bool _debugEnableDebugMode;
  late bool _debugEnablePerformanceOverlay;
  late bool _debugEnableLogging;
  late String _debugLogLevel;
  late bool _debugEnableHotReload;
  late bool _debugEnableDevTools;
  late bool _debugEnableMockData;
  late bool _debugEnableUiInspector;

  // Experimental Parameters
  late bool _experimentalEnableExperimentalFeatures;
  late bool _experimentalEnableAiFeatures;
  late bool _experimentalEnableCloudSync;
  late bool _experimentalEnableCollaboration;
  late bool _experimentalEnableVoiceCommands;
  late bool _experimentalEnableArFeatures;
  late bool _experimentalEnableMlFeatures;
  late bool _experimentalEnableBlockchain;

  // Integration Parameters
  late bool _integrationsEnableGoogleDrive;
  late bool _integrationsEnableDropbox;
  late bool _integrationsEnableOnedrive;
  late bool _integrationsEnableFirebase;
  late bool _integrationsEnableStripe;
  late bool _integrationsEnablePaypal;
  late bool _integrationsEnableSocialLogin;
  late bool _integrationsEnablePushNotifications;
  double get textScaleFactor => _textScaleFactor;
  bool get useMaterial3 => _useMaterial3;
  bool get useHighContrast => _useHighContrast;
  bool get reduceMotion => _reduceMotion;
  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;
  double get borderRadius => _borderRadius;
  double get elevation => _elevation;
  Duration get animationDuration => _animationDuration;
  bool get isInitialized => _isInitialized;

  ThemeProvider() {
    _initializeProvider();
  }

  /// Initialize provider with central configuration
  Future<void> _initializeProvider() async {
    try {
      // Initialize central config
      await _config.initialize();

      // Load all theme parameters from central config
      await _loadThemeParameters();

      _isInitialized = true;
      notifyListeners();

      // Set up parameter change listeners for hot reload
      _setupParameterListeners();

    } catch (e) {
      debugPrint('ThemeProvider initialization error: $e');
      // Use fallback defaults
      _setFallbackDefaults();
    }
  }

  Future<void> _loadThemeParameters() async {
    // Theme mode
    final themeModeIndex = await _config.getParameter<int>('theme.mode');
    _themeMode = themeModeIndex != null
        ? ThemeMode.values[themeModeIndex.clamp(0, ThemeMode.values.length - 1)]
        : ThemeMode.system;

    // Accessibility and usability
    _textScaleFactor = await _config.getParameter<double>('theme.text_scale') ?? 1.0;
    _useMaterial3 = await _config.getParameter<bool>('theme.material3') ?? true;
    _useHighContrast = await _config.getParameter<bool>('theme.high_contrast') ?? false;
    _reduceMotion = await _config.getParameter<bool>('theme.reduce_motion') ?? false;

    // Colors
    final primaryColorValue = await _config.getParameter<int>('theme.primary_color');
    _primaryColor = primaryColorValue != null ? Color(primaryColorValue) : const Color(0xFF2196F3);

    final secondaryColorValue = await _config.getParameter<int>('theme.secondary_color');
    _secondaryColor = secondaryColorValue != null ? Color(secondaryColorValue) : const Color(0xFF03DAC6);

    // UI Colors
    _surfaceColor = await _config.getParameter<int>('ui.surface_color') ?? 0xFFFFFFFF;
    _backgroundColor = await _config.getParameter<int>('ui.background_color') ?? 0xFFFAFAFA;
    _errorColor = await _config.getParameter<int>('ui.error_color');

    // Card Colors
    _cardPrimaryColor = await _config.getParameter<int>('ui.card_primary_color');
    _cardSecondaryColor = await _config.getParameter<int>('ui.card_secondary_color');
    _cardSuccessColor = await _config.getParameter<int>('ui.card_success_color');
    _cardWarningColor = await _config.getParameter<int>('ui.card_warning_color');
    _cardErrorColor = await _config.getParameter<int>('ui.card_error_color');
    _cardInfoColor = await _config.getParameter<int>('ui.card_info_color');

    // Component styling
    _borderRadius = await _config.getParameter<double>('theme.border_radius') ?? 12.0;
    _elevation = await _config.getParameter<double>('theme.elevation') ?? 2.0;

    final animationDurationMs = await _config.getParameter<int>('theme.animation_duration_ms') ?? 200;
    _animationDuration = Duration(milliseconds: animationDurationMs);

    // UI Spacing
    _paddingSmall = await _config.getParameter<double>('ui.padding_small') ?? 8.0;
    _paddingMedium = await _config.getParameter<double>('ui.padding_medium') ?? 16.0;
    _paddingLarge = await _config.getParameter<double>('ui.padding_large') ?? 24.0;
    _marginSmall = await _config.getParameter<double>('ui.margin_small') ?? 4.0;
    _marginMedium = await _config.getParameter<double>('ui.margin_medium') ?? 8.0;
    _marginLarge = await _config.getParameter<double>('ui.margin_large') ?? 16.0;

    // UI Border Radius
    _borderRadiusSmall = await _config.getParameter<double>('ui.border_radius_small') ?? 4.0;
    _borderRadiusMedium = await _config.getParameter<double>('ui.border_radius_medium') ?? 8.0;
    _borderRadiusLarge = await _config.getParameter<double>('ui.border_radius_large') ?? 12.0;
    _borderRadiusXLarge = await _config.getParameter<double>('ui.border_radius_xlarge') ?? 16.0;

    // UI Elevation
    _elevationLow = await _config.getParameter<double>('ui.elevation_low') ?? 1.0;
    _elevationMedium = await _config.getParameter<double>('ui.elevation_medium') ?? 2.0;
    _elevationHigh = await _config.getParameter<double>('ui.elevation_high') ?? 4.0;
    _elevationXHigh = await _config.getParameter<double>('ui.elevation_xhigh') ?? 8.0;

    // UI Icon Sizes
    _iconSizeSmall = await _config.getParameter<double>('ui.icon_size_small') ?? 16.0;
    _iconSizeMedium = await _config.getParameter<double>('ui.icon_size_medium') ?? 20.0;
    _iconSizeLarge = await _config.getParameter<double>('ui.icon_size_large') ?? 24.0;
    _iconSizeXLarge = await _config.getParameter<double>('ui.icon_size_xlarge') ?? 28.0;
    _iconSizeXXLarge = await _config.getParameter<double>('ui.icon_size_xxlarge') ?? 32.0;

    // UI Font Sizes
    _fontSizeSmall = await _config.getParameter<double>('ui.font_size_small') ?? 12.0;
    _fontSizeMedium = await _config.getParameter<double>('ui.font_size_medium') ?? 14.0;
    _fontSizeLarge = await _config.getParameter<double>('ui.font_size_large') ?? 16.0;
    _fontSizeXLarge = await _config.getParameter<double>('ui.font_size_xlarge') ?? 18.0;
    _fontSizeXXLarge = await _config.getParameter<double>('ui.font_size_xxlarge') ?? 20.0;
    _fontSizeHuge = await _config.getParameter<double>('ui.font_size_huge') ?? 24.0;

    // UI Animation Durations
    final fastDuration = await _config.getParameter<int>('ui.animation_duration_fast') ?? 200;
    _animationDurationFast = Duration(milliseconds: fastDuration);

    final mediumDuration = await _config.getParameter<int>('ui.animation_duration_medium') ?? 300;
    _animationDurationMedium = Duration(milliseconds: mediumDuration);

    final slowDuration = await _config.getParameter<int>('ui.animation_duration_slow') ?? 500;
    _animationDurationSlow = Duration(milliseconds: slowDuration);

    final slowestDuration = await _config.getParameter<int>('ui.animation_duration_slowest') ?? 800;
    _animationDurationSlowest = Duration(milliseconds: slowestDuration);

    // UI Animation Delays
    final shortDelay = await _config.getParameter<int>('ui.animation_delay_short') ?? 100;
    _animationDelayShort = Duration(milliseconds: shortDelay);

    final mediumDelay = await _config.getParameter<int>('ui.animation_delay_medium') ?? 200;
    _animationDelayMedium = Duration(milliseconds: mediumDelay);

    final longDelay = await _config.getParameter<int>('ui.animation_delay_long') ?? 400;
    _animationDelayLong = Duration(milliseconds: longDelay);

    final xlongDelay = await _config.getParameter<int>('ui.animation_delay_xlong') ?? 600;
    _animationDelayXLong = Duration(milliseconds: xlongDelay);

    // UI Grid Layout
    _gridCrossAxisCount = await _config.getParameter<int>('ui.grid_cross_axis_count') ?? 2;
    _gridCrossAxisSpacing = await _config.getParameter<double>('ui.grid_cross_axis_spacing') ?? 12.0;
    _gridMainAxisSpacing = await _config.getParameter<double>('ui.grid_main_axis_spacing') ?? 12.0;
    _gridChildAspectRatio = await _config.getParameter<double>('ui.grid_child_aspect_ratio') ?? 1.1;

    // UI Card Dimensions
    _cardMinHeight = await _config.getParameter<double>('ui.card_min_height') ?? 120.0;
    _cardMaxWidth = await _config.getParameter<double>('ui.card_max_width') ?? 400.0;
    _cardActionTileWidth = await _config.getParameter<double>('ui.card_action_tile_width') ?? 100.0;
    _cardActionTileHeight = await _config.getParameter<double>('ui.card_action_tile_height') ?? 100.0;

    // UI Opacity Values
    _opacityLow = await _config.getParameter<double>('ui.opacity_low') ?? 0.1;
    _opacityMedium = await _config.getParameter<double>('ui.opacity_medium') ?? 0.2;
    _opacityHigh = await _config.getParameter<double>('ui.opacity_high') ?? 0.3;
    _opacityOverlay = await _config.getParameter<double>('ui.opacity_overlay') ?? 0.8;

    // UI Blur Radius
    _blurRadiusSmall = await _config.getParameter<double>('ui.blur_radius_small') ?? 4.0;
    _blurRadiusMedium = await _config.getParameter<double>('ui.blur_radius_medium') ?? 8.0;
    _blurRadiusLarge = await _config.getParameter<double>('ui.blur_radius_large') ?? 12.0;

    // UI Shadow Offset
    _shadowOffset = Offset(shadowOffsetX, shadowOffsetY);

    // Navigation & Routing
    _enableBottomNav = await _config.getParameter<bool>('navigation.enable_bottom_nav') ?? true;
    _enableDrawer = await _config.getParameter<bool>('navigation.enable_drawer') ?? false;
    _enableFab = await _config.getParameter<bool>('navigation.enable_fab') ?? true;
    _enableAppBar = await _config.getParameter<bool>('navigation.enable_app_bar') ?? true;
    _enableSearch = await _config.getParameter<bool>('navigation.enable_search') ?? true;
    _enableNotifications = await _config.getParameter<bool>('navigation.enable_notifications') ?? true;

    final navAnimationDuration = await _config.getParameter<int>('navigation.animation_duration_ms') ?? 300;
    _navigationAnimationDuration = Duration(milliseconds: navAnimationDuration);
    _navigationTransitionType = await _config.getParameter<String>('navigation.transition_type') ?? 'slide';
    _enableNestedNavigation = await _config.getParameter<bool>('navigation.enable_nested_navigation') ?? true;
    _maxBackStack = await _config.getParameter<int>('navigation.max_back_stack') ?? 10;
    _enableGestures = await _config.getParameter<bool>('navigation.enable_gestures') ?? true;

    // App Bar
    _appBarEnableTitleAnimation = await _config.getParameter<bool>('appbar.enable_title_animation') ?? true;
    _appBarElevation = await _config.getParameter<double>('appbar.elevation') ?? 0.0;
    _appBarHeight = await _config.getParameter<double>('appbar.height') ?? 56.0;
    _appBarEnableTransparency = await _config.getParameter<bool>('appbar.enable_transparency') ?? false;
    _appBarTitleFontSize = await _config.getParameter<double>('appbar.title_font_size') ?? 20.0;
    _appBarEnableActionsAnimation = await _config.getParameter<bool>('appbar.enable_actions_animation') ?? true;

    // Bottom Navigation
    _bottomNavHeight = await _config.getParameter<double>('bottom_nav.height') ?? 80.0;
    _bottomNavEnableLabels = await _config.getParameter<bool>('bottom_nav.enable_labels') ?? false;
    _bottomNavIconSize = await _config.getParameter<double>('bottom_nav.icon_size') ?? 24.0;

    final bottomNavAnimationDuration = await _config.getParameter<int>('bottom_nav.animation_duration_ms') ?? 300;
    _bottomNavAnimationDuration = Duration(milliseconds: bottomNavAnimationDuration);
    _bottomNavEnableIndicator = await _config.getParameter<bool>('bottom_nav.enable_indicator') ?? true;
    _bottomNavIndicatorHeight = await _config.getParameter<double>('bottom_nav.indicator_height') ?? 3.0;

    // FAB
    _fabSize = await _config.getParameter<double>('fab.size') ?? 56.0;
    _fabElevation = await _config.getParameter<double>('fab.elevation') ?? 6.0;
    _fabExtendedPaddingHorizontal = await _config.getParameter<double>('fab.extended_padding_horizontal') ?? 16.0;
    _fabExtendedIconSpacing = await _config.getParameter<double>('fab.extended_icon_spacing') ?? 8.0;

    final fabAnimationDuration = await _config.getParameter<int>('fab.animation_duration_ms') ?? 200;
    _fabAnimationDuration = Duration(milliseconds: fabAnimationDuration);
    _fabEnableHeroAnimation = await _config.getParameter<bool>('fab.enable_hero_animation') ?? true;

    // Performance
    _performanceEnableImageCaching = await _config.getParameter<bool>('performance.enable_image_caching') ?? true;
    _performanceImageCacheSizeMb = await _config.getParameter<int>('performance.image_cache_size_mb') ?? 100;
    _performanceEnableListVirtualization = await _config.getParameter<bool>('performance.enable_list_virtualization') ?? true;
    _performanceVirtualizationThreshold = await _config.getParameter<int>('performance.virtualization_threshold') ?? 50;
    _performanceEnablePreloading = await _config.getParameter<bool>('performance.enable_preloading') ?? true;
    _performancePreloadDistance = await _config.getParameter<int>('performance.preload_distance') ?? 5;
    _performanceEnableCompression = await _config.getParameter<bool>('performance.enable_compression') ?? false;
    _performanceCompressionLevel = await _config.getParameter<int>('performance.compression_level') ?? 6;
    _performanceEnableMemoryOptimization = await _config.getParameter<bool>('performance.enable_memory_optimization') ?? true;
    _performanceGcThresholdMb = await _config.getParameter<int>('performance.gc_threshold_mb') ?? 50;

    // Error Handling
    _errorEnableErrorBoundary = await _config.getParameter<bool>('error.enable_error_boundary') ?? true;
    _errorEnableErrorReporting = await _config.getParameter<bool>('error.enable_error_reporting') ?? false;
    _errorReportEndpoint = await _config.getParameter<String>('error.error_report_endpoint') ?? '';
    _errorEnableRetryDialog = await _config.getParameter<bool>('error.enable_retry_dialog') ?? true;
    _errorMaxRetryAttempts = await _config.getParameter<int>('error.max_retry_attempts') ?? 3;
    _errorRetryDelayMs = await _config.getParameter<int>('error.retry_delay_ms') ?? 1000;
    _errorEnableOfflineFallback = await _config.getParameter<bool>('error.enable_offline_fallback') ?? true;
    _errorEnableErrorToast = await _config.getParameter<bool>('error.enable_error_toast') ?? true;
    _errorToastDurationSeconds = await _config.getParameter<int>('error.toast_duration_seconds') ?? 4;

    // Accessibility
    _accessibilityEnableScreenReader = await _config.getParameter<bool>('accessibility.enable_screen_reader') ?? true;
    _accessibilityEnableHighContrast = await _config.getParameter<bool>('accessibility.enable_high_contrast') ?? false;
    _accessibilityEnableReducedMotion = await _config.getParameter<bool>('accessibility.enable_reduced_motion') ?? false;
    _accessibilityEnableLargeText = await _config.getParameter<bool>('accessibility.enable_large_text') ?? false;
    _accessibilityTouchTargetSize = await _config.getParameter<double>('accessibility.touch_target_size') ?? 44.0;
    _accessibilityFocusIndicatorWidth = await _config.getParameter<double>('accessibility.focus_indicator_width') ?? 2.0;
    _accessibilityEnableKeyboardNavigation = await _config.getParameter<bool>('accessibility.enable_keyboard_navigation') ?? true;
    _accessibilityAnnounceRouteChanges = await _config.getParameter<bool>('accessibility.announce_route_changes') ?? true;

    // Notifications
    _notificationsEnablePush = await _config.getParameter<bool>('notifications.enable_push') ?? true;
    _notificationsEnableLocal = await _config.getParameter<bool>('notifications.enable_local') ?? true;
    _notificationsEnableSound = await _config.getParameter<bool>('notifications.enable_sound') ?? true;
    _notificationsEnableVibration = await _config.getParameter<bool>('notifications.enable_vibration') ?? true;
    _notificationsMaxNotifications = await _config.getParameter<int>('notifications.max_notifications') ?? 50;
    _notificationsAutoHideSeconds = await _config.getParameter<int>('notifications.auto_hide_seconds') ?? 5;
    _notificationsGroupSimilar = await _config.getParameter<bool>('notifications.group_similar') ?? true;
    _notificationsEnableActions = await _config.getParameter<bool>('notifications.enable_actions') ?? true;

    // Search
    _searchEnableGlobalSearch = await _config.getParameter<bool>('search.enable_global_search') ?? true;
    _searchMaxResults = await _config.getParameter<int>('search.max_results') ?? 100;
    _searchTimeoutSeconds = await _config.getParameter<int>('search.search_timeout_seconds') ?? 10;
    _searchEnableFuzzySearch = await _config.getParameter<bool>('search.enable_fuzzy_search') ?? true;
    _searchEnableRecentSearches = await _config.getParameter<bool>('search.enable_recent_searches') ?? true;
    _searchMaxRecentSearches = await _config.getParameter<int>('search.max_recent_searches') ?? 10;
    _searchEnableSearchSuggestions = await _config.getParameter<bool>('search.enable_search_suggestions') ?? true;
    _searchEnableVoiceSearch = await _config.getParameter<bool>('search.enable_voice_search') ?? false;

    // Data Management
    _dataEnableAutoSave = await _config.getParameter<bool>('data.enable_auto_save') ?? true;
    _dataAutoSaveIntervalSeconds = await _config.getParameter<int>('data.auto_save_interval_seconds') ?? 30;
    _dataEnableBackup = await _config.getParameter<bool>('data.enable_backup') ?? true;
    _dataBackupIntervalHours = await _config.getParameter<int>('data.backup_interval_hours') ?? 24;
    _dataBackupRetentionDays = await _config.getParameter<int>('data.backup_retention_days') ?? 30;
    _dataEnableEncryption = await _config.getParameter<bool>('data.enable_encryption') ?? true;
    _dataEncryptionAlgorithm = await _config.getParameter<String>('data.encryption_algorithm') ?? 'AES-256-GCM';
    _dataEnableCompression = await _config.getParameter<bool>('data.enable_compression') ?? false;
    _dataCompressionAlgorithm = await _config.getParameter<String>('data.compression_algorithm') ?? 'gzip';

    // Platform
    _platformEnablePlatformOptimizations = await _config.getParameter<bool>('platform.enable_platform_optimizations') ?? true;
    _platformAndroidEnableBiometric = await _config.getParameter<bool>('platform.android.enable_biometric') ?? true;
    _platformIosEnableFaceId = await _config.getParameter<bool>('platform.ios.enable_face_id') ?? true;
    _platformWindowsEnableSystemIntegration = await _config.getParameter<bool>('platform.windows.enable_system_integration') ?? true;
    _platformWebEnablePwa = await _config.getParameter<bool>('platform.web.enable_pwa') ?? true;
    _platformWebEnableServiceWorker = await _config.getParameter<bool>('platform.web.enable_service_worker') ?? true;

    // Analytics
    _analyticsEnableAnalytics = await _config.getParameter<bool>('analytics.enable_analytics') ?? false;
    _analyticsProvider = await _config.getParameter<String>('analytics.analytics_provider') ?? 'none';
    _analyticsEnableCrashReporting = await _config.getParameter<bool>('analytics.enable_crash_reporting') ?? false;
    _analyticsEnablePerformanceMonitoring = await _config.getParameter<bool>('analytics.enable_performance_monitoring') ?? true;
    _analyticsSamplingRate = await _config.getParameter<double>('analytics.sampling_rate') ?? 1.0;
    _analyticsEnableUserTracking = await _config.getParameter<bool>('analytics.enable_user_tracking') ?? false;
    _analyticsAnonymizeIp = await _config.getParameter<bool>('analytics.anonymize_ip') ?? true;

    // Internationalization
    _i18nEnableI18n = await _config.getParameter<bool>('i18n.enable_i18n') ?? true;
    _i18nDefaultLocale = await _config.getParameter<String>('i18n.default_locale') ?? 'en';
    _i18nSupportedLocales = await _config.getParameter<String>('i18n.supported_locales') ?? 'en,es,fr,de,zh,ja';
    _i18nEnableRtl = await _config.getParameter<bool>('i18n.enable_rtl') ?? true;
    _i18nEnablePluralization = await _config.getParameter<bool>('i18n.enable_pluralization') ?? true;
    _i18nDateFormat = await _config.getParameter<String>('i18n.date_format') ?? 'medium';
    _i18nTimeFormat = await _config.getParameter<String>('i18n.time_format') ?? 'medium';

    // Security
    _securityEnableSslPinning = await _config.getParameter<bool>('security.enable_ssl_pinning') ?? false;
    _securityEnableCertificateValidation = await _config.getParameter<bool>('security.enable_certificate_validation') ?? true;
    _securityEnableDataSanitization = await _config.getParameter<bool>('security.enable_data_sanitization') ?? true;
    _securityEnablePrivacyMode = await _config.getParameter<bool>('security.enable_privacy_mode') ?? false;
    _securitySessionTimeoutMinutes = await _config.getParameter<int>('security.session_timeout_minutes') ?? 30;
    _securityEnableAutoLock = await _config.getParameter<bool>('security.enable_auto_lock') ?? false;
    _securityAutoLockTimeoutMinutes = await _config.getParameter<int>('security.auto_lock_timeout_minutes') ?? 5;
    _securityEnableSecureStorage = await _config.getParameter<bool>('security.enable_secure_storage') ?? true;

    // Debug
    _debugEnableDebugMode = await _config.getParameter<bool>('debug.enable_debug_mode') ?? false;
    _debugEnablePerformanceOverlay = await _config.getParameter<bool>('debug.enable_performance_overlay') ?? false;
    _debugEnableLogging = await _config.getParameter<bool>('debug.enable_logging') ?? true;
    _debugLogLevel = await _config.getParameter<String>('debug.log_level') ?? 'info';
    _debugEnableHotReload = await _config.getParameter<bool>('debug.enable_hot_reload') ?? true;
    _debugEnableDevTools = await _config.getParameter<bool>('debug.enable_dev_tools') ?? false;
    _debugEnableMockData = await _config.getParameter<bool>('debug.enable_mock_data') ?? false;
    _debugEnableUiInspector = await _config.getParameter<bool>('debug.enable_ui_inspector') ?? false;

    // Experimental
    _experimentalEnableExperimentalFeatures = await _config.getParameter<bool>('experimental.enable_experimental_features') ?? false;
    _experimentalEnableAiFeatures = await _config.getParameter<bool>('experimental.enable_ai_features') ?? true;
    _experimentalEnableCloudSync = await _config.getParameter<bool>('experimental.enable_cloud_sync') ?? true;
    _experimentalEnableCollaboration = await _config.getParameter<bool>('experimental.enable_collaboration') ?? false;
    _experimentalEnableVoiceCommands = await _config.getParameter<bool>('experimental.enable_voice_commands') ?? false;
    _experimentalEnableArFeatures = await _config.getParameter<bool>('experimental.enable_ar_features') ?? false;
    _experimentalEnableMlFeatures = await _config.getParameter<bool>('experimental.enable_ml_features') ?? false;
    _experimentalEnableBlockchain = await _config.getParameter<bool>('experimental.enable_blockchain') ?? false;

    // Integrations
    _integrationsEnableGoogleDrive = await _config.getParameter<bool>('integrations.enable_google_drive') ?? false;
    _integrationsEnableDropbox = await _config.getParameter<bool>('integrations.enable_dropbox') ?? false;
    _integrationsEnableOnedrive = await _config.getParameter<bool>('integrations.enable_onedrive') ?? false;
    _integrationsEnableFirebase = await _config.getParameter<bool>('integrations.enable_firebase') ?? false;
    _integrationsEnableStripe = await _config.getParameter<bool>('integrations.enable_stripe') ?? false;
    _integrationsEnablePaypal = await _config.getParameter<bool>('integrations.enable_paypal') ?? false;
    _integrationsEnableSocialLogin = await _config.getParameter<bool>('integrations.enable_social_login') ?? false;
    _integrationsEnablePushNotifications = await _config.getParameter<bool>('integrations.enable_push_notifications') ?? false;
  }

  void _setFallbackDefaults() {
    _themeMode = ThemeMode.system;
    _textScaleFactor = 1.0;
    _useMaterial3 = true;
    _useHighContrast = false;
    _reduceMotion = false;
    _primaryColor = const Color(0xFF2196F3);
    _secondaryColor = const Color(0xFF03DAC6);
    _borderRadius = 12.0;
    _elevation = 2.0;
    _animationDuration = const Duration(milliseconds: 200);
    _isInitialized = true;
  }

  /// Set up listeners for parameter changes (hot reload support)
  void _setupParameterListeners() {
    _config.events.listen((event) {
      if (event.type == ConfigEventType.parameterChanged && event.parameterKey?.startsWith('theme.') == true) {
        _handleParameterChange(event.parameterKey!, event.newValue);
      }
    });
  }

  void _handleParameterChange(String key, dynamic value) {
    bool shouldNotify = true;

    switch (key) {
      case 'theme.mode':
        if (value is int) {
          _themeMode = ThemeMode.values[value.clamp(0, ThemeMode.values.length - 1)];
        }
        break;
      case 'theme.text_scale':
        if (value is double) {
          _textScaleFactor = value.clamp(0.5, 3.0);
        }
        break;
      case 'theme.material3':
        if (value is bool) {
          _useMaterial3 = value;
        }
        break;
      case 'theme.high_contrast':
        if (value is bool) {
          _useHighContrast = value;
        }
        break;
      case 'theme.reduce_motion':
        if (value is bool) {
          _reduceMotion = value;
        }
        break;
      case 'theme.primary_color':
        if (value is int) {
          _primaryColor = Color(value);
        }
        break;
      case 'theme.secondary_color':
        if (value is int) {
          _secondaryColor = Color(value);
        }
        break;
      case 'theme.border_radius':
        if (value is double) {
          _borderRadius = value.clamp(0.0, 32.0);
        }
        break;
      case 'theme.elevation':
        if (value is double) {
          _elevation = value.clamp(0.0, 24.0);
        }
        break;
      case 'theme.animation_duration_ms':
        if (value is int) {
          _animationDuration = Duration(milliseconds: value.clamp(0, 2000));
        }
        break;
      default:
        shouldNotify = false;
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }

  /// Public methods for updating theme settings
  Future<void> setThemeMode(ThemeMode mode) async {
    await _config.setParameter('theme.mode', mode.index);
    // Parameter change will be handled by listener
  }

  Future<void> toggleTheme() async {
    final nextMode = switch (_themeMode) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      ThemeMode.system => ThemeMode.light,
    };
    await setThemeMode(nextMode);
  }

  Future<void> setTextScaleFactor(double factor) async {
    await _config.setParameter('theme.text_scale', factor.clamp(0.5, 3.0));
  }

  Future<void> setMaterial3Enabled(bool enabled) async {
    await _config.setParameter('theme.material3', enabled);
  }

  Future<void> setHighContrastEnabled(bool enabled) async {
    await _config.setParameter('theme.high_contrast', enabled);
  }

  Future<void> setReduceMotionEnabled(bool enabled) async {
    await _config.setParameter('theme.reduce_motion', enabled);
  }

  Future<void> setPrimaryColor(Color color) async {
    await _config.setParameter('theme.primary_color', color.value);
  }

  Future<void> setSecondaryColor(Color color) async {
    await _config.setParameter('theme.secondary_color', color.value);
  }

  Future<void> setBorderRadius(double radius) async {
    await _config.setParameter('theme.border_radius', radius.clamp(0.0, 32.0));
  }

  Future<void> setDefaultElevation(double elevation) async {
    await _config.setParameter('theme.elevation', elevation.clamp(0.0, 24.0));
  }

  Future<void> setAnimationDuration(Duration duration) async {
    await _config.setParameter('theme.animation_duration_ms', duration.inMilliseconds);
  }

  /// Reset all theme settings to defaults
  Future<void> resetToDefaults() async {
    await _config.setParameter('theme.mode', ThemeMode.system.index);
    await _config.setParameter('theme.text_scale', 1.0);
    await _config.setParameter('theme.material3', true);
    await _config.setParameter('theme.high_contrast', false);
    await _config.setParameter('theme.reduce_motion', false);
    await _config.setParameter('theme.primary_color', const Color(0xFF2196F3).value);
    await _config.setParameter('theme.secondary_color', const Color(0xFF03DAC6).value);
    await _config.setParameter('theme.border_radius', 12.0);
    await _config.setParameter('theme.elevation', 2.0);
    await _config.setParameter('theme.animation_duration_ms', 200);
  }

  /// Export theme configuration
  Map<String, dynamic> exportThemeConfig() {
    return {
      'version': '2.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'themeMode': _themeMode.index,
      'textScaleFactor': _textScaleFactor,
      'useMaterial3': _useMaterial3,
      'useHighContrast': _useHighContrast,
      'reduceMotion': _reduceMotion,
      'primaryColor': _primaryColor.value,
      'secondaryColor': _secondaryColor.value,
      'borderRadius': _borderRadius,
      'elevation': _elevation,
      'animationDurationMs': _animationDuration.inMilliseconds,
    };
  }

  /// Import theme configuration
  Future<void> importThemeConfig(Map<String, dynamic> config) async {
    try {
      if (config['themeMode'] is int) {
        await setThemeMode(ThemeMode.values[config['themeMode']]);
      }
      if (config['textScaleFactor'] is double) {
        await setTextScaleFactor(config['textScaleFactor']);
      }
      if (config['useMaterial3'] is bool) {
        await setMaterial3Enabled(config['useMaterial3']);
      }
      if (config['useHighContrast'] is bool) {
        await setHighContrastEnabled(config['useHighContrast']);
      }
      if (config['reduceMotion'] is bool) {
        await setReduceMotionEnabled(config['reduceMotion']);
      }
      if (config['primaryColor'] is int) {
        await setPrimaryColor(Color(config['primaryColor']));
      }
      if (config['secondaryColor'] is int) {
        await setSecondaryColor(Color(config['secondaryColor']));
      }
      if (config['borderRadius'] is double) {
        await setBorderRadius(config['borderRadius']);
      }
      if (config['elevation'] is double) {
        await setDefaultElevation(config['elevation']);
      }
      if (config['animationDurationMs'] is int) {
        await setAnimationDuration(Duration(milliseconds: config['animationDurationMs']));
      }
    } catch (e) {
      debugPrint('Error importing theme config: $e');
    }
  }

  /// Get theme health status
  Map<String, dynamic> getThemeHealthStatus() {
    return {
      'isInitialized': _isInitialized,
      'themeMode': _themeMode.toString(),
      'textScaleFactor': _textScaleFactor,
      'useMaterial3': _useMaterial3,
      'useHighContrast': _useHighContrast,
      'reduceMotion': _reduceMotion,
      'primaryColor': _primaryColor.toString(),
      'secondaryColor': _secondaryColor.toString(),
      'borderRadius': _borderRadius,
      'elevation': _elevation,
      'animationDuration': _animationDuration.toString(),
    };
  }

  /// Legacy methods for backward compatibility
  void toggleMaterial3() {
    setMaterial3Enabled(!_useMaterial3);
  }

  @override
  void dispose() {
    _config.dispose();
    super.dispose();
  }
}
