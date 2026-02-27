class AppConstants {
  // App Information
  static const String APP_NAME = 'iSuite';
  static const String APP_VERSION = '1.0.0';
  static const String APP_DESCRIPTION =
      'A comprehensive cross-platform suite of tools and utilities';

  // Environment
  static const bool IS_RELEASE_MODE = bool.fromEnvironment('dart.vm.product');
  static const bool IS_DEBUG_MODE = !IS_RELEASE_MODE;

  // API Configuration
  static const String API_BASE_URL = 'https://api.isuite.app';
  static const Duration API_TIMEOUT = Duration(seconds: 30);

  // Database Configuration
  static const String DATABASE_NAME = 'isuite.db';
  static const int DATABASE_VERSION = 1;

  // Storage Keys
  static const String THEME_KEY = 'theme_mode';
  static const String USER_KEY = 'user_data';
  static const String FIRST_LAUNCH_KEY = 'first_launch';
  static const String LANGUAGE_KEY = 'language';

  // UI Constants
  static const double DEFAULT_PADDING = 16;
  static const double SMALL_PADDING = 8;
  static const double LARGE_PADDING = 24;
  static const double EXTRA_LARGE_PADDING = 32;
  static const double CARD_RADIUS = 12;
  static const double BUTTON_RADIUS = 8;
  static const double INPUT_RADIUS = 8;
  static const double DIALOG_RADIUS = 16;
  static const double BOTTOM_SHEET_RADIUS = 20;
  static const double APP_BAR_HEIGHT = 56;
  static const double BOTTOM_NAV_HEIGHT = 60;
  static const double FAB_SIZE = 56;
  static const double ICON_SIZE = 24;
  static const double SMALL_ICON_SIZE = 16;
  static const double LARGE_ICON_SIZE = 32;
  static const double DEFAULT_SPACING = 8;
  static const double SMALL_SPACING = 4;
  static const double LARGE_SPACING = 16;
  static const double DEFAULT_BORDER_WIDTH = 1;
  static const double THICK_BORDER_WIDTH = 2;
  static const double DEFAULT_ELEVATION = 2;
  static const double CARD_ELEVATION = 4;
  static const double FAB_ELEVATION = 6;
  static const double DEFAULT_OPACITY = 0.8;
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
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp'
  ];
  static const List<String> supportedDocumentFormats = [
    'pdf',
    'doc',
    'docx',
    'txt'
  ];
  static const List<String> supportedVideoFormats = [
    'mp4',
    'avi',
    'mov',
    'wmv',
    'flv',
    'webm'
  ];
  static const List<String> supportedAudioFormats = [
    'mp3',
    'wav',
    'flac',
    'aac',
    'ogg'
  ];
  static const List<String> supportedArchiveFormats = [
    'zip',
    'rar',
    '7z',
    'tar',
    'gz'
  ];

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
  static const String networkErrorMessage =
      'Please check your internet connection';
  static const String serverErrorMessage =
      'Server error. Please try again later';
  static const String genericErrorMessage =
      'Something went wrong. Please try again';

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
  static const double headline1Size = 32;
  static const double headline2Size = 28;
  static const double headline3Size = 24;
  static const double headline4Size = 20;
  static const double headline5Size = 16;
  static const double headline6Size = 14;
  static const double bodyText1Size = 16;
  static const double bodyText2Size = 14;
  static const double subtitle1Size = 16;
  static const double subtitle2Size = 14;
  static const double captionSize = 12;
  static const double overlineSize = 10;
  static const double buttonSize = 14;
  static const double inputSize = 16;
  static const double labelSize = 12;

  // Breakpoints for responsive design
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1200;
  static const double desktopBreakpoint = 1800;

  // Grid constants
  static const int gridColumns = 12;
  static const double gridSpacing = 8;
  static const double gridGutter = 16;

  // Form constants
  static const double inputHeight = 48;
  static const double buttonHeight = 48;
  static const double smallButtonHeight = 36;
  static const double largeButtonHeight = 56;
  static const double inputFieldSpacing = 16;
  static const double formSectionSpacing = 24;

  // List constants
  static const double listItemHeight = 56;
  static const double listTilePadding = 16;
  static const double listSeparatorHeight = 1;
  static const double listGroupSpacing = 8;

  // Image constants
  static const double avatarSize = 40;
  static const double largeAvatarSize = 80;
  static const double thumbnailSize = 64;
  static const double largeThumbnailSize = 128;
  static const double imageAspectRatio = 16.0 / 9.0;
  static const double squareImageAspectRatio = 1;

  // Loading constants
  static const double loadingIndicatorSize = 24;
  static const double largeLoadingIndicatorSize = 48;
  static const Duration loadingTimeout = Duration(seconds: 30);

  // Animation constants
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.bounceInOut;
  static const Curve elasticCurve = Curves.elasticOut;
  static const Duration debounceDelay = Duration(milliseconds: 300);
  static const Duration throttleDelay = Duration(milliseconds: 100);

  // Accessibility constants
  static const double minTouchTargetSize = 44;
  static const double minInteractiveSize = 48;
  static const double maxTextScale = 2;
  static const double minTextScale = 0.8;
}
