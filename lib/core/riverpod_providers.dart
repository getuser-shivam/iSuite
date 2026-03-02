import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/supabase_service.dart';
import 'core/circuit_breaker_service.dart';
import 'core/health_check_service.dart';
import 'core/retry_service.dart';
import 'core/advanced_file_operations_service.dart';
import 'core/network_management_service.dart';
import 'core/cloud_storage_service.dart';
import 'core/advanced_analytics_service.dart';
import 'core/memory_leak_detection_service.dart';
import 'core/monitoring_dashboard_service.dart';
import 'core/config/central_config.dart';

// =============================================================================
// CORE SERVICE PROVIDERS
// =============================================================================

/// Supabase Service Provider
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  throw StateError(
    'SupabaseService has not been initialized. '
    'Please ensure all services are properly configured in main.dart before accessing providers. '
    'This usually indicates a dependency injection configuration issue.'
  );
});

/// Circuit Breaker Service Provider
final circuitBreakerServiceProvider = Provider<CircuitBreakerService>((ref) {
  throw StateError(
    'CircuitBreakerService has not been initialized. '
    'Please ensure circuit breaker service is configured in the service initialization. '
    'This protects against cascading failures in distributed systems.'
  );
});

/// Health Check Service Provider
final healthCheckServiceProvider = Provider<HealthCheckService>((ref) {
  throw StateError(
    'HealthCheckService has not been initialized. '
    'Please ensure health monitoring services are configured. '
    'Health checks are critical for system reliability and monitoring.'
  );
});

/// Retry Service Provider
final retryServiceProvider = Provider<RetryService>((ref) {
  throw StateError(
    'RetryService has not been initialized. '
    'Please ensure retry mechanisms are configured for resilient operations. '
    'Retry services help handle transient failures gracefully.'
  );
});

// =============================================================================
// BUSINESS SERVICE PROVIDERS
// =============================================================================

/// File Operations Service Provider
final fileOperationsServiceProvider = Provider<AdvancedFileOperationsService>((ref) {
  throw StateError(
    'AdvancedFileOperationsService has not been initialized. '
    'Please ensure file system services are properly configured. '
    'File operations are fundamental to the application functionality.'
  );
});

/// Network Management Service Provider
final networkManagementServiceProvider = Provider<NetworkManagementService>((ref) {
  throw StateError(
    'NetworkManagementService has not been initialized. '
    'Please ensure network services are configured for connectivity management. '
    'Network services are essential for distributed operations.'
  );
});

/// Cloud Storage Service Provider
final cloudStorageServiceProvider = Provider<CloudStorageService>((ref) {
  throw StateError(
    'CloudStorageService has not been initialized. '
    'Please ensure cloud storage services are configured for file synchronization. '
    'Cloud storage enables cross-device file access and backup capabilities.'
  );
});

/// Analytics Service Provider
final analyticsServiceProvider = Provider<AdvancedAnalyticsService>((ref) {
  throw StateError(
    'AdvancedAnalyticsService has not been initialized. '
    'Please ensure analytics services are configured for usage tracking and insights. '
    'Analytics help understand user behavior and system performance.'
  );
});

// =============================================================================
// ROBUSTNESS SERVICE PROVIDERS
// =============================================================================

/// Memory Leak Detection Service Provider
final memoryLeakDetectionServiceProvider = Provider<MemoryLeakDetectionService>((ref) {
  throw StateError(
    'MemoryLeakDetectionService has not been initialized. '
    'Please ensure memory monitoring services are configured for performance optimization. '
    'Memory leak detection prevents application crashes and performance degradation.'
  );
});

/// Monitoring Dashboard Service Provider
final monitoringDashboardServiceProvider = Provider<MonitoringDashboardService>((ref) {
  throw StateError(
    'MonitoringDashboardService has not been initialized. '
    'Please ensure monitoring dashboard services are configured for system visibility. '
    'Monitoring dashboards provide real-time insights into system health and performance.'
  );
});

// =============================================================================
// STATE MANAGEMENT PROVIDERS
// =============================================================================

/// Navigation State Provider
final navigationProvider = StateProvider<int>((ref) => 0);

/// App State Provider
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

/// Theme Provider with Riverpod
final themeProvider = StateNotifierProvider<ThemeStateNotifier, ThemeState>((ref) {
  return ThemeStateNotifier();
});

/// Floating Action Button State Provider
final fabProvider = StateProvider<FABState>((ref) {
  return const FABState(
    icon: Icons.add,
    label: 'Quick Action',
    onPressed: _defaultFABAction,
  );
});

/// System Health Provider
final systemHealthProvider = StateNotifierProvider<SystemHealthNotifier, SystemHealth>((ref) {
  return SystemHealthNotifier();
});

// =============================================================================
// INTERNATIONALIZATION PROVIDERS
// =============================================================================

/// Locale Provider for internationalization
final localeProvider = StateProvider<Locale>((ref) {
  // Get initial locale from config or system
  return const Locale('en'); // Default to English
});

/// Supported Locales Provider
final supportedLocalesProvider = Provider<List<Locale>>((ref) {
  return const [
    Locale('en'), // English
    Locale('es'), // Spanish
    Locale('fr'), // French
    Locale('de'), // German
    Locale('zh'), // Chinese
    Locale('ja'), // Japanese
    Locale('hi'), // Hindi
    Locale('pt'), // Portuguese
    Locale('ru'), // Russian
    Locale('ar'), // Arabic
  ];
});

/// Current Language Name Provider
final currentLanguageNameProvider = Provider<String>((ref) {
  final locale = ref.watch(localeProvider);
  final languageNames = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'zh': '中文',
    'ja': '日本語',
    'hi': 'हिन्दी',
    'pt': 'Português',
    'ru': 'Русский',
    'ar': 'العربية',
  };
  return languageNames[locale.languageCode] ?? 'English';
});

// =============================================================================
// DATA PROVIDERS
// =============================================================================

/// User Profile Provider
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final currentUser = await supabaseService.getCurrentUser();
  if (currentUser != null) {
    return await supabaseService.getUserProfile(currentUser.id);
  }
  return null;
});

/// Files List Provider
final filesListProvider = StateNotifierProvider<FilesListNotifier, List<FileItem>>((ref) {
  return FilesListNotifier();
});

/// Network Status Provider
final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final networkService = ref.watch(networkManagementServiceProvider);
  // This would return a stream from the network service
  return Stream.value(NetworkStatus.online); // Placeholder
});

/// Analytics Data Provider
final analyticsDataProvider = FutureProvider<AnalyticsData>((ref) async {
  final analyticsService = ref.watch(analyticsServiceProvider);
  // This would fetch analytics data
  return AnalyticsData.empty(); // Placeholder
});

// =============================================================================
// CONFIGURATION PROVIDERS
// =============================================================================

/// Central Config Provider
final centralConfigProvider = Provider<CentralConfig>((ref) {
  return CentralConfig.instance;
});

/// App Configuration Provider
final appConfigProvider = FutureProvider<AppConfiguration>((ref) async {
  final config = ref.watch(centralConfigProvider);
  await config.initialize();

  return AppConfiguration(
    appName: config.getParameter('app.name', defaultValue: 'iSuite Pro'),
    version: config.getParameter('app.version', defaultValue: '2.0.0'),
    theme: config.getParameter('ui.theme_mode', defaultValue: 'system'),
    language: config.getParameter('app.language', defaultValue: 'en'),
  );
});

// =============================================================================
// STATE NOTIFIERS
// =============================================================================

/// App State Notifier
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState.initial());

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void updateUser(User? user) {
    state = state.copyWith(currentUser: user);
  }
}

/// Theme State Notifier
class ThemeStateNotifier extends StateNotifier<ThemeState> {
  ThemeStateNotifier() : super(ThemeState.system());

  Future<ThemeData> buildLightTheme() async {
    final config = CentralConfig.instance;
    await config.initialize();

    final primaryColor = Color(config.getParameter('ui.primary_color', defaultValue: 0xFF2196F3));
    final borderRadius = config.getParameter('ui.border_radius_medium', defaultValue: 12.0);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 2,
      ),
    );
  }

  Future<ThemeData> buildDarkTheme() async {
    final config = CentralConfig.instance;
    await config.initialize();

    final primaryColor = Color(config.getParameter('ui.primary_color', defaultValue: 0xFF2196F3));
    final borderRadius = config.getParameter('ui.border_radius_medium', defaultValue: 12.0);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 2,
      ),
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void toggleTheme() {
    final newMode = state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    setThemeMode(newMode);
  }
}

/// System Health Notifier
class SystemHealthNotifier extends StateNotifier<SystemHealth> {
  SystemHealthNotifier() : super(SystemHealth.healthy());

  void updateHealth(double score, List<String> issues) {
    HealthStatus status;
    if (score >= 90) {
      status = HealthStatus.healthy;
    } else if (score >= 70) {
      status = HealthStatus.warning;
    } else {
      status = HealthStatus.unhealthy;
    }

    state = SystemHealth(
      score: score,
      status: status,
      issues: issues,
      lastChecked: DateTime.now(),
    );
  }

  void markAsHealthy() {
    state = SystemHealth.healthy();
  }

  void reportIssue(String issue) {
    final newIssues = List<String>.from(state.issues)..add(issue);
    final newScore = (state.score - 10).clamp(0, 100);

    HealthStatus status;
    if (newScore >= 90) {
      status = HealthStatus.healthy;
    } else if (newScore >= 70) {
      status = HealthStatus.warning;
    } else {
      status = HealthStatus.unhealthy;
    }

    state = SystemHealth(
      score: newScore,
      status: status,
      issues: newIssues,
      lastChecked: DateTime.now(),
    );
  }
}

/// Files List Notifier
class FilesListNotifier extends StateNotifier<List<FileItem>> {
  FilesListNotifier() : super([]);

  void addFile(FileItem file) {
    state = [...state, file];
  }

  void removeFile(String id) {
    state = state.where((file) => file.id != id).toList();
  }

  void updateFile(FileItem updatedFile) {
    state = state.map((file) => file.id == updatedFile.id ? updatedFile : file).toList();
  }

  void clearFiles() {
    state = [];
  }

  void setFiles(List<FileItem> files) {
    state = files;
  }
}

// =============================================================================
// DATA MODELS
// =============================================================================

/// App State
class AppState {
  final bool isLoading;
  final String? error;
  final User? currentUser;
  final bool isInitialized;

  AppState({
    required this.isLoading,
    this.error,
    this.currentUser,
    required this.isInitialized,
  });

  factory AppState.initial() {
    return AppState(
      isLoading: false,
      error: null,
      currentUser: null,
      isInitialized: false,
    );
  }

  AppState copyWith({
    bool? isLoading,
    String? error,
    User? currentUser,
    bool? isInitialized,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentUser: currentUser ?? this.currentUser,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

/// Theme State
class ThemeState {
  final ThemeMode themeMode;
  final ThemeData? lightTheme;
  final ThemeData? darkTheme;

  ThemeState({
    required this.themeMode,
    this.lightTheme,
    this.darkTheme,
  });

  factory ThemeState.system() {
    return ThemeState(themeMode: ThemeMode.system);
  }

  ThemeState copyWith({
    ThemeMode? themeMode,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
    );
  }
}

/// Floating Action Button State
class FABState {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const FABState({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
}

/// System Health
enum HealthStatus {
  healthy,
  warning,
  unhealthy,
}

class SystemHealth {
  final double score;
  final HealthStatus status;
  final List<String> issues;
  final DateTime lastChecked;

  SystemHealth({
    required this.score,
    required this.status,
    required this.issues,
    required this.lastChecked,
  });

  factory SystemHealth.healthy() {
    return SystemHealth(
      score: 100.0,
      status: HealthStatus.healthy,
      issues: [],
      lastChecked: DateTime.now(),
    );
  }
}

/// Network Status
enum NetworkStatus {
  online,
  offline,
  limited,
}

/// User Model
class User {
  final String id;
  final String email;
  final String? name;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    this.name,
    this.createdAt,
  });
}

/// File Item
class FileItem {
  final String id;
  final String name;
  final String path;
  final int size;
  final DateTime modified;
  final String type;
  final bool isDirectory;

  FileItem({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.modified,
    required this.type,
    this.isDirectory = false,
  });
}

/// Analytics Data
class AnalyticsData {
  final int totalUsers;
  final int activeUsers;
  final int totalFiles;
  final int totalOperations;
  final Map<String, int> operationsByType;

  AnalyticsData({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalFiles,
    required this.totalOperations,
    required this.operationsByType,
  });

  factory AnalyticsData.empty() {
    return AnalyticsData(
      totalUsers: 0,
      activeUsers: 0,
      totalFiles: 0,
      totalOperations: 0,
      operationsByType: {},
    );
  }
}

/// App Configuration
class AppConfiguration {
  final String appName;
  final String version;
  final String theme;
  final String language;

  AppConfiguration({
    required this.appName,
    required this.version,
    required this.theme,
    required this.language,
  });
}

// =============================================================================
// UTILITY FUNCTIONS
// =============================================================================

void _defaultFABAction() {
  // Default FAB action - can be overridden by providers
  print('FAB pressed - no action defined');
}

// =============================================================================
// PROVIDER OVERRIDES FOR TESTING
// =============================================================================

/// Override providers for testing
final testOverrides = <Override>[
  // Add test overrides here
];

// =============================================================================
// ASYNC PROVIDERS FOR COMPLEX OPERATIONS
// =============================================================================

/// File Upload Provider
final fileUploadProvider = FutureProvider.family<String?, FileItem>((ref, file) async {
  final cloudStorage = ref.watch(cloudStorageServiceProvider);
  // This would upload the file and return the URL
  return 'https://example.com/uploaded/${file.name}'; // Placeholder
});

/// Network Scan Provider
final networkScanProvider = FutureProvider<List<String>>((ref) async {
  final networkService = ref.watch(networkManagementServiceProvider);
  // This would scan the network and return device IPs
  return ['192.168.1.1', '192.168.1.2']; // Placeholder
});

/// AI Analysis Provider
final aiAnalysisProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, filePath) async {
  final analyticsService = ref.watch(analyticsServiceProvider);
  // This would perform AI analysis on the file
  return {
    'categorized': true,
    'category': 'document',
    'tags': ['important', 'work'],
    'sentiment': 'neutral',
  }; // Placeholder
});

// =============================================================================
// STREAM PROVIDERS FOR REAL-TIME DATA
// =============================================================================

/// Real-time Supabase Events Provider
final supabaseEventsProvider = StreamProvider<SupabaseEventData>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return supabaseService.events;
});

/// Health Check Stream Provider
final healthCheckStreamProvider = StreamProvider<HealthStatusEvent>((ref) {
  final healthService = ref.watch(healthCheckServiceProvider);
  return healthService.statusEvents;
});

/// Memory Usage Stream Provider
final memoryUsageProvider = StreamProvider<MemoryUsage>((ref) {
  final memoryService = ref.watch(memoryLeakDetectionServiceProvider);
  return memoryService.memoryEvents.map((event) => event.memoryUsage!).whereType<MemoryUsage>();
});

// =============================================================================
// COMPUTED PROVIDERS
// =============================================================================

/// Computed provider for total file size
final totalFileSizeProvider = Provider<int>((ref) {
  final files = ref.watch(filesListProvider);
  return files.fold(0, (total, file) => total + file.size);
});

/// Computed provider for file type distribution
final fileTypeDistributionProvider = Provider<Map<String, int>>((ref) {
  final files = ref.watch(filesListProvider);
  final distribution = <String, int>{};

  for (final file in files) {
    distribution[file.type] = (distribution[file.type] ?? 0) + 1;
  }

  return distribution;
});

/// Computed provider for system status
final systemStatusProvider = Provider<String>((ref) {
  final health = ref.watch(systemHealthProvider);
  final network = ref.watch(networkStatusProvider).maybeWhen(
    data: (status) => status,
    orElse: () => NetworkStatus.offline,
  );

  if (health.status == HealthStatus.unhealthy) {
    return 'System Unhealthy';
  }

  if (network == NetworkStatus.offline) {
    return 'Offline Mode';
  }

  return 'All Systems Operational';
});

// =============================================================================
// END OF RIVERPOD PROVIDERS
// =============================================================================
