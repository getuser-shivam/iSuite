class AppConstants {
  // App Information
  static const String appName = 'iSuite';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'A comprehensive cross-platform suite of tools and utilities';

  // Environment
  static const bool isReleaseMode = bool.fromEnvironment('dart.vm.product');
  static const bool isDebugMode = !isReleaseMode;

  // API Configuration
  static const String apiBaseUrl = 'https://api.isuite.app';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Database Configuration
  static const String databaseName = 'isuite.db';
  static const int databaseVersion = 1;

  // Storage Keys
  static const String themeKey = 'theme_mode';
  static const String userKey = 'user_data';
  static const String firstLaunchKey = 'first_launch';
  static const String languageKey = 'language';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;
  static const double cardRadius = 12.0;
  static const double buttonRadius = 8.0;
  static const double inputRadius = 8.0;
  static const double dialogRadius = 16.0;
  static const double bottomSheetRadius = 20.0;
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 60.0;
  static const double fabSize = 56.0;
  static const double iconSize = 24.0;
  static const double smallIconSize = 16.0;
  static const double largeIconSize = 32.0;
  static const double defaultSpacing = 8.0;
  static const double smallSpacing = 4.0;
  static const double largeSpacing = 16.0;
  static const double defaultBorderWidth = 1.0;
  static const double thickBorderWidth = 2.0;
  static const double defaultElevation = 2.0;
  static const double cardElevation = 4.0;
  static const double fabElevation = 6.0;
  static const double defaultOpacity = 0.8;
  static const double disabledOpacity = 0.5;
  static const double overlayOpacity = 0.3;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Network Configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // File Size Limits
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> supportedDocumentFormats = ['pdf', 'doc', 'docx', 'txt'];
  static const List<String> supportedVideoFormats = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm'];
  static const List<String> supportedAudioFormats = ['mp3', 'wav', 'flac', 'aac', 'ogg'];
  static const List<String> supportedArchiveFormats = ['zip', 'rar', '7z', 'tar', 'gz'];

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int maxUsernameLength = 50;
  static const int maxEmailLength = 100;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB

  // Notification Channels
  static const String generalNotificationChannel = 'general';
  static const String taskNotificationChannel = 'tasks';
  static const String reminderNotificationChannel = 'reminders';

  // Deep Links
  static const String appScheme = 'isuite';
  static const String webUrl = 'https://isuite.app';

  // Social Links
  static const String githubUrl = 'https://github.com/getuser-shivam/iSuite';
  static const String supportEmail = 'support@isuite.app';

  // Privacy & Legal
  static const String privacyPolicyUrl = 'https://isuite.app/privacy';
  static const String termsOfServiceUrl = 'https://isuite.app/terms';

  // Feature Flags
  static const bool enableCloudSync = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;

  // Error Messages
  static const String networkErrorMessage = 'Please check your internet connection';
  static const String serverErrorMessage = 'Server error. Please try again later';
  static const String genericErrorMessage = 'Something went wrong. Please try again';

  // Success Messages
  static const String saveSuccessMessage = 'Saved successfully';
  static const String deleteSuccessMessage = 'Deleted successfully';
  static const String updateSuccessMessage = 'Updated successfully';

  // Color Constants (for consistent theming)
  static const int primaryColorValue = 0xFF2196F3; // Blue
  static const int secondaryColorValue = 0xFF4CAF50; // Green
  static const int errorColorValue = 0xFFF44336; // Red
  static const int warningColorValue = 0xFFFF9800; // Orange
  static const int infoColorValue = 0xFF2196F3; // Blue
  static const int successColorValue = 0xFF4CAF50; // Green
  
  // Text Styles
  static const double headline1Size = 32.0;
  static const double headline2Size = 28.0;
  static const double headline3Size = 24.0;
  static const double headline4Size = 20.0;
  static const double headline5Size = 16.0;
  static const double headline6Size = 14.0;
  static const double bodyText1Size = 16.0;
  static const double bodyText2Size = 14.0;
  static const double subtitle1Size = 16.0;
  static const double subtitle2Size = 14.0;
  static const double captionSize = 12.0;
  static const double overlineSize = 10.0;
  static const double buttonSize = 14.0;
  static const double inputSize = 16.0;
  static const double labelSize = 12.0;
  
  // Breakpoints for responsive design
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1200.0;
  static const double desktopBreakpoint = 1800.0;
  
  // Grid constants
  static const int gridColumns = 12;
  static const double gridSpacing = 8.0;
  static const double gridGutter = 16.0;
  
  // Form constants
  static const double inputHeight = 48.0;
  static const double buttonHeight = 48.0;
  static const double smallButtonHeight = 36.0;
  static const double largeButtonHeight = 56.0;
  static const double inputFieldSpacing = 16.0;
  static const double formSectionSpacing = 24.0;
  
  // List constants
  static const double listItemHeight = 56.0;
  static const double listTilePadding = 16.0;
  static const double listSeparatorHeight = 1.0;
  static const double listGroupSpacing = 8.0;
  
  // Image constants
  static const double avatarSize = 40.0;
  static const double largeAvatarSize = 80.0;
  static const double thumbnailSize = 64.0;
  static const double largeThumbnailSize = 128.0;
  static const double imageAspectRatio = 16.0 / 9.0;
  static const double squareImageAspectRatio = 1.0;
  
  // Loading constants
  static const double loadingIndicatorSize = 24.0;
  static const double largeLoadingIndicatorSize = 48.0;
  static const Duration loadingTimeout = Duration(seconds: 30);
  
  // Animation constants
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.bounceInOut;
  static const Curve elasticCurve = Curves.elasticOut;
  static const Duration debounceDelay = Duration(milliseconds: 300);
  static const Duration throttleDelay = Duration(milliseconds: 100);
  
  // Accessibility constants
  static const double minTouchTargetSize = 44.0;
  static const double minInteractiveSize = 48.0;
  static const double maxTextScale = 2.0;
  static const double minTextScale = 0.8;
}
