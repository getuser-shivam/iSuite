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
  static const double cardRadius = 12.0;
  static const double buttonRadius = 8.0;
  static const double inputRadius = 8.0;

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
}
