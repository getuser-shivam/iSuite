class AppConfig {
  static const String appName = 'Owlfiles';
  static const String appVersion = '1.0.0';
  
  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double cardElevation = 2.0;
  static const double borderRadius = 8.0;
  static const double iconSize = 24.0;
  
  // Animation Configuration
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Curve defaultAnimationCurve = Curves.easeInOut;
  
  // File Management Configuration
  static const int maxFileSizeForPreview = 10 * 1024 * 1024; // 10MB
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
  static const List<String> supportedVideoFormats = ['mp4', 'avi', 'mov', 'wmv', 'flv'];
  static const List<String> supportedAudioFormats = ['mp3', 'wav', 'flac', 'aac', 'ogg'];
  static const List<String> supportedDocumentFormats = ['pdf', 'doc', 'docx', 'txt', 'md', 'json', 'xml'];
  
  // Cloud Configuration
  static const Duration cloudSyncInterval = Duration(minutes: 5);
  static const Duration shareLinkExpiration = Duration(hours: 24);
  static const int maxConcurrentUploads = 3;
  
  // Performance Configuration
  static const int filesPerPage = 50;
  static const Duration searchDebounce = Duration(milliseconds: 300);
  static const bool enableCaching = true;
  
  // Security Configuration
  static const bool requireAuthenticationForSensitiveOps = true;
  static const int maxLoginAttempts = 3;
  static const Duration loginLockoutDuration = Duration(minutes: 15);
  
  // Theme Configuration
  static const bool enableDarkMode = true;
  static const bool enableCustomThemes = true;
  
  // Storage Configuration
  static const String defaultDownloadPath = '/storage/emulated/0/Download/Owlfiles';
  static const String defaultCachePath = '/storage/emulated/0/Android/data/com.isuite.owlfiles/cache';
  
  // Network Configuration
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  
  // UI Text Configuration
  static const String emptyStateMessage = 'No files found';
  static const String loadingMessage = 'Loading...';
  static const String errorMessage = 'An error occurred';
  static const String successMessage = 'Operation completed successfully';
  
  // Feature Flags
  static const bool enableQRSharing = true;
  static const bool enableCloudSync = true;
  static const bool enableFileEncryption = true;
  static const bool enableBatchOperations = true;
  static const bool enableFilePreview = true;
  static const bool enableCompression = true;
  static const bool enableSearch = true;
  
  // Default Values
  static const Map<String, dynamic> defaultSettings = {
    'theme': 'system',
    'autoSync': true,
    'showHiddenFiles': false,
    'defaultViewMode': 'list',
    'defaultSortOrder': 'name',
    'enableNotifications': true,
    'maxFileSizeWarning': 50 * 1024 * 1024, // 50MB
  };
  
  // Getters for computed values
  static String getStoragePath() => defaultDownloadPath;
  static String getCachePath() => defaultCachePath;
  static Duration getAnimationDuration() => defaultAnimationDuration;
  static Curve getAnimationCurve() => defaultAnimationCurve;
  static double getPadding() => defaultPadding;
  static double getBorderRadius() => borderRadius;
  static double getIconSize() => iconSize;
  static bool isFeatureEnabled(String feature) => defaultSettings[feature] ?? false;
}

class AppConstants {
  // Error Messages
  static const String genericError = 'An unexpected error occurred';
  static const String networkError = 'Network error occurred';
  static const String fileNotFoundError = 'File not found';
  static const String permissionDenied = 'Permission denied';
  static const String operationFailed = 'Operation failed';
  static const String invalidInput = 'Invalid input provided';
  static const String authenticationFailed = 'Authentication failed';
  static const String quotaExceeded = 'Storage quota exceeded';
  
  // Success Messages
  static const String fileOperationSuccess = 'File operation completed successfully';
  static const String fileShareSuccess = 'File shared successfully';
  static const String cloudSyncSuccess = 'Cloud sync completed successfully';
  static const String compressionSuccess = 'Compression completed successfully';
  
  // Navigation Routes
  static const String homeRoute = '/home';
  static const String filesRoute = '/files';
  static const String cloudRoute = '/cloud';
  static const String settingsRoute = '/settings';
  static const String filePreviewRoute = '/preview';
  static const String qrShareRoute = '/qr-share';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  
  // Text Styles
  static const double titleFontSize = 18.0;
  static const double subtitleFontSize = 14.0;
  static const double bodyFontSize = 16.0;
  static const double captionFontSize = 12.0;
  
  // Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 840.0;
  static const double desktopBreakpoint = 1200.0;
  
  // File Size Limits
  static const int maxFileSizeForUpload = 100 * 1024 * 1024; // 100MB
  static const int maxFileSizeForCompression = 500 * 1024 * 1024; // 500MB
  static const int maxConcurrentOperations = 5;
  
  // Cache Configuration
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const Duration cacheExpiration = Duration(hours: 24);
  
  // Search Configuration
  static const int minSearchLength = 2;
  static const int maxSearchResults = 1000;
  
  // Share Configuration
  static const int maxShareLinksPerUser = 10;
  static const Duration shareLinkCleanupInterval = Duration(hours: 1);
  
  // Validation
  static const String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phoneRegex = r'^\+?[1-9]\d{1,14}$';
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  
  // File Type Icons
  static const Map<String, String> fileTypeIcons = {
    'folder': 'folder',
    'image': 'image',
    'video': 'video_file',
    'audio': 'audio_file',
    'document': 'description',
    'pdf': 'picture_as_pdf',
    'archive': 'archive',
    'text': 'text_snippet',
    'spreadsheet': 'table_chart',
    'presentation': 'slideshow',
    'unknown': 'insert_drive_file',
  };
  
  // File Type Colors
  static const Map<String, Color> fileTypeColors = {
    'folder': Colors.blue,
    'image': Colors.green,
    'video': Colors.purple,
    'audio': Colors.orange,
    'document': Colors.blue,
    'pdf': Colors.red,
    'archive': Colors.amber,
    'text': Colors.grey,
    'spreadsheet': Colors.green,
    'presentation': Colors.indigo,
    'unknown': Colors.grey,
  };
}
