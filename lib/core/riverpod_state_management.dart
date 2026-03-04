import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'advanced_file_operations_service.dart';
import 'advanced_ui_service.dart';
import 'central_config.dart';
import 'performance_optimization_service.dart';

// ============================================================================
// PROVIDERS - Core Service Providers
// ============================================================================

/// Central configuration provider
final centralConfigProvider = Provider<CentralConfig>((ref) {
  return CentralConfig.instance;
});

/// Performance optimization service provider
final performanceServiceProvider =
    Provider<PerformanceOptimizationService>((ref) {
  return PerformanceOptimizationService.instance;
});

/// Advanced file operations service provider
final fileOperationsServiceProvider =
    Provider<AdvancedFileOperationsService>((ref) {
  return AdvancedFileOperationsService.instance;
});

/// Advanced UI service provider
final uiServiceProvider = Provider<AdvancedUIService>((ref) {
  return AdvancedUIService.instance;
});

// ============================================================================
// ASYNC INITIALIZATION PROVIDERS
// ============================================================================

/// App initialization provider - coordinates all services
final appInitializationProvider =
    FutureProvider<AppInitializationState>((ref) async {
  final config = ref.watch(centralConfigProvider);
  final performance = ref.watch(performanceServiceProvider);
  final fileOps = ref.watch(fileOperationsServiceProvider);
  final uiService = ref.watch(uiServiceProvider);

  final initializationState = AppInitializationState();

  try {
    // Initialize configuration first
    await config.initialize();
    initializationState.configInitialized = true;

    // Initialize performance monitoring
    await performance.initialize();
    initializationState.performanceInitialized = true;

    // Initialize file operations
    await fileOps.initialize();
    initializationState.fileOperationsInitialized = true;

    // Initialize UI service
    await uiService.initialize();
    initializationState.uiInitialized = true;

    initializationState.isFullyInitialized = true;
    return initializationState;
  } catch (e) {
    initializationState.initializationError = e.toString();
    return initializationState;
  }
});

// ============================================================================
// STATE NOTIFIERS - Complex State Management
// ============================================================================

/// File operations state notifier
class FileOperationsNotifier extends StateNotifier<FileOperationsState> {
  final AdvancedFileOperationsService _fileService;
  final PerformanceOptimizationService _performanceService;

  FileOperationsNotifier(this._fileService, this._performanceService)
      : super(FileOperationsState());

  /// Perform batch file operation
  Future<void> performBatchOperation({
    required BatchOperationType type,
    required List<String> sourcePaths,
    required String destinationPath,
    BatchOperationOptions? options,
  }) async {
    state =
        state.copyWith(isLoading: true, currentOperation: 'Batch ${type.name}');

    try {
      final result = await _performanceService.trackOperation(
        'batch_operation_${type.name}',
        () => _fileService.performBatchOperation(
          type: type,
          sourcePaths: sourcePaths,
          destinationPath: destinationPath,
          options: options,
        ),
      );

      state = state.copyWith(
        isLoading: false,
        lastResult: result,
        operationHistory: [...state.operationHistory, result],
        currentOperation: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        currentOperation: null,
      );
    }
  }

  /// Perform file search
  Future<void> searchFiles({
    required String directory,
    String? query,
    List<String>? fileTypes,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    int? minSize,
    int? maxSize,
  }) async {
    state = state.copyWith(isSearching: true);

    try {
      final result = await _performanceService.trackOperation(
        'file_search',
        () => _fileService.searchFiles(
          directory: directory,
          query: query,
          fileTypes: fileTypes,
          modifiedAfter: modifiedAfter,
          modifiedBefore: modifiedBefore,
          minSize: minSize,
          maxSize: maxSize,
        ),
      );

      state = state.copyWith(
        isSearching: false,
        searchResults: result,
      );
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        error: e.toString(),
      );
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear search results
  void clearSearchResults() {
    state = state.copyWith(searchResults: null);
  }
}

/// UI state notifier
class UINotifier extends StateNotifier<UIState> {
  final AdvancedUIService _uiService;
  final CentralConfig _config;

  UINotifier(this._uiService, this._config) : super(UIState()) {
    _initializeFromConfig();
  }

  void _initializeFromConfig() {
    // Load initial UI settings from config
    final fontScale =
        _config.getParameter('accessibility.font_scale', defaultValue: 1.0);
    final highContrast = _config.getParameter(
        'accessibility.high_contrast_enabled',
        defaultValue: false);
    final keyboardNav = _config.getParameter(
        'accessibility.keyboard_navigation_enabled',
        defaultValue: true);

    state = state.copyWith(
      fontScale: fontScale,
      highContrastEnabled: highContrast,
      keyboardNavigationEnabled: keyboardNav,
    );
  }

  /// Set font scale
  Future<void> setFontScale(double scale) async {
    await _uiService.setFontScale(scale);
    state = state.copyWith(fontScale: scale);
  }

  /// Toggle high contrast mode
  Future<void> toggleHighContrast() async {
    final newValue = !state.highContrastEnabled;
    await _uiService.setHighContrastMode(newValue);
    state = state.copyWith(highContrastEnabled: newValue);
  }

  /// Set keyboard navigation
  Future<void> setKeyboardNavigation(bool enabled) async {
    await _uiService.setKeyboardNavigationEnabled(enabled);
    state = state.copyWith(keyboardNavigationEnabled: enabled);
  }

  /// Set theme mode
  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  /// Set screen size category
  void updateScreenSize(ScreenSizeCategory category) {
    state = state.copyWith(screenSizeCategory: category);
  }
}

/// Theme provider with dynamic theming
class ThemeProvider extends StateNotifier<ThemeData> {
  final AdvancedUIService _uiService;

  ThemeProvider(this._uiService)
      : super(_uiService.getThemeData(brightness: Brightness.light));

  /// Update theme based on brightness and settings
  void updateTheme({
    required Brightness brightness,
    bool highContrast = false,
  }) {
    state = _uiService.getThemeData(
      brightness: brightness,
      highContrast: highContrast,
    );
  }
}

/// Configuration state notifier
class ConfigurationNotifier extends StateNotifier<ConfigurationState> {
  final CentralConfig _config;

  ConfigurationNotifier(this._config) : super(ConfigurationState()) {
    _loadInitialConfig();
  }

  void _loadInitialConfig() {
    // Load initial configuration values
    final appName = _config.appName;
    final appVersion = _config.appVersion;
    final primaryFramework = _config.primaryFramework;
    final backendFramework = _config.backendFramework;

    state = state.copyWith(
      appName: appName,
      appVersion: appVersion,
      primaryFramework: primaryFramework,
      backendFramework: backendFramework,
      isLoaded: true,
    );
  }

  /// Update configuration parameter
  Future<void> updateParameter(String key, dynamic value) async {
    try {
      await _config.setParameter(key, value);
      await _config.notifyConfigurationChanged();

      state = state.copyWith(
        lastUpdatedKey: key,
        lastUpdatedValue: value,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Reload configuration
  Future<void> reloadConfiguration() async {
    try {
      await _config.reloadConfiguration();
      state = state.copyWith(
        isReloading: false,
        lastReloadTime: DateTime.now(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isReloading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Performance monitoring state notifier
class PerformanceNotifier extends StateNotifier<PerformanceState> {
  final PerformanceOptimizationService _performanceService;
  Timer? _monitoringTimer;

  PerformanceNotifier(this._performanceService) : super(PerformanceState()) {
    _startMonitoring();
  }

  void _startMonitoring() {
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updatePerformanceMetrics();
    });
  }

  Future<void> _updatePerformanceMetrics() async {
    final metrics = _performanceService.getPerformanceStatistics();
    final memoryStats = _performanceService.getMemoryStatistics();

    state = state.copyWith(
      performanceMetrics: metrics,
      memoryStatistics: memoryStats,
      lastUpdated: DateTime.now(),
    );
  }

  /// Run memory optimization
  Future<void> optimizeMemory() async {
    state = state.copyWith(isOptimizing: true);

    try {
      final result = await _performanceService.optimizeMemory();
      state = state.copyWith(
        isOptimizing: false,
        lastOptimizationResult: result,
      );
    } catch (e) {
      state = state.copyWith(
        isOptimizing: false,
        error: e.toString(),
      );
    }
  }

  /// Clear performance data
  void clearPerformanceData() {
    state = state.copyWith(
      performanceMetrics: PerformanceStatistics.empty(),
      memoryStatistics: MemoryStatistics.empty(),
      error: null,
    );
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    super.dispose();
  }
}

// ============================================================================
// STATE CLASSES
// ============================================================================

/// App initialization state
class AppInitializationState {
  bool configInitialized = false;
  bool performanceInitialized = false;
  bool fileOperationsInitialized = false;
  bool uiInitialized = false;
  String? initializationError;

  bool get isFullyInitialized =>
      configInitialized &&
      performanceInitialized &&
      fileOperationsInitialized &&
      uiInitialized &&
      initializationError == null;
}

/// File operations state
class FileOperationsState {
  final bool isLoading;
  final bool isSearching;
  final BatchOperationResult? lastResult;
  final SearchResult? searchResults;
  final List<BatchOperationResult> operationHistory;
  final String? currentOperation;
  final String? error;

  FileOperationsState({
    this.isLoading = false,
    this.isSearching = false,
    this.lastResult,
    this.searchResults,
    this.operationHistory = const [],
    this.currentOperation,
    this.error,
  });

  FileOperationsState copyWith({
    bool? isLoading,
    bool? isSearching,
    BatchOperationResult? lastResult,
    SearchResult? searchResults,
    List<BatchOperationResult>? operationHistory,
    String? currentOperation,
    String? error,
  }) {
    return FileOperationsState(
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      lastResult: lastResult ?? this.lastResult,
      searchResults: searchResults ?? this.searchResults,
      operationHistory: operationHistory ?? this.operationHistory,
      currentOperation: currentOperation ?? this.currentOperation,
      error: error ?? this.error,
    );
  }
}

/// UI state
class UIState {
  final double fontScale;
  final bool highContrastEnabled;
  final bool keyboardNavigationEnabled;
  final ThemeMode themeMode;
  final ScreenSizeCategory screenSizeCategory;
  final bool isLoading;

  UIState({
    this.fontScale = 1.0,
    this.highContrastEnabled = false,
    this.keyboardNavigationEnabled = true,
    this.themeMode = ThemeMode.system,
    this.screenSizeCategory = ScreenSizeCategory.mobile,
    this.isLoading = false,
  });

  UIState copyWith({
    double? fontScale,
    bool? highContrastEnabled,
    bool? keyboardNavigationEnabled,
    ThemeMode? themeMode,
    ScreenSizeCategory? screenSizeCategory,
    bool? isLoading,
  }) {
    return UIState(
      fontScale: fontScale ?? this.fontScale,
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
      keyboardNavigationEnabled:
          keyboardNavigationEnabled ?? this.keyboardNavigationEnabled,
      themeMode: themeMode ?? this.themeMode,
      screenSizeCategory: screenSizeCategory ?? this.screenSizeCategory,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Configuration state
class ConfigurationState {
  final bool isLoaded;
  final bool isReloading;
  final String? appName;
  final String? appVersion;
  final String? primaryFramework;
  final String? backendFramework;
  final String? lastUpdatedKey;
  final dynamic lastUpdatedValue;
  final DateTime? lastUpdated;
  final DateTime? lastReloadTime;
  final String? error;

  ConfigurationState({
    this.isLoaded = false,
    this.isReloading = false,
    this.appName,
    this.appVersion,
    this.primaryFramework,
    this.backendFramework,
    this.lastUpdatedKey,
    this.lastUpdatedValue,
    this.lastUpdated,
    this.lastReloadTime,
    this.error,
  });

  ConfigurationState copyWith({
    bool? isLoaded,
    bool? isReloading,
    String? appName,
    String? appVersion,
    String? primaryFramework,
    String? backendFramework,
    String? lastUpdatedKey,
    dynamic lastUpdatedValue,
    DateTime? lastUpdated,
    DateTime? lastReloadTime,
    String? error,
  }) {
    return ConfigurationState(
      isLoaded: isLoaded ?? this.isLoaded,
      isReloading: isReloading ?? this.isReloading,
      appName: appName ?? this.appName,
      appVersion: appVersion ?? this.appVersion,
      primaryFramework: primaryFramework ?? this.primaryFramework,
      backendFramework: backendFramework ?? this.backendFramework,
      lastUpdatedKey: lastUpdatedKey ?? this.lastUpdatedKey,
      lastUpdatedValue: lastUpdatedValue ?? this.lastUpdatedValue,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastReloadTime: lastReloadTime ?? this.lastReloadTime,
      error: error ?? this.error,
    );
  }
}

/// Performance state
class PerformanceState {
  final PerformanceStatistics performanceMetrics;
  final MemoryStatistics memoryStatistics;
  final bool isOptimizing;
  final MemoryCleanupResult? lastOptimizationResult;
  final DateTime? lastUpdated;
  final String? error;

  PerformanceState({
    PerformanceStatistics? performanceMetrics,
    MemoryStatistics? memoryStatistics,
    this.isOptimizing = false,
    this.lastOptimizationResult,
    this.lastUpdated,
    this.error,
  })  : performanceMetrics =
            performanceMetrics ?? PerformanceStatistics.empty(),
        memoryStatistics = memoryStatistics ?? MemoryStatistics.empty();

  PerformanceState copyWith({
    PerformanceStatistics? performanceMetrics,
    MemoryStatistics? memoryStatistics,
    bool? isOptimizing,
    MemoryCleanupResult? lastOptimizationResult,
    DateTime? lastUpdated,
    String? error,
  }) {
    return PerformanceState(
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      memoryStatistics: memoryStatistics ?? this.memoryStatistics,
      isOptimizing: isOptimizing ?? this.isOptimizing,
      lastOptimizationResult:
          lastOptimizationResult ?? this.lastOptimizationResult,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      error: error ?? this.error,
    );
  }
}

// ============================================================================
// STATE NOTIFIER PROVIDERS
// ============================================================================

/// File operations state notifier provider
final fileOperationsProvider =
    StateNotifierProvider<FileOperationsNotifier, FileOperationsState>((ref) {
  final fileService = ref.watch(fileOperationsServiceProvider);
  final performanceService = ref.watch(performanceServiceProvider);
  return FileOperationsNotifier(fileService, performanceService);
});

/// UI state notifier provider
final uiProvider = StateNotifierProvider<UINotifier, UIState>((ref) {
  final uiService = ref.watch(uiServiceProvider);
  final config = ref.watch(centralConfigProvider);
  return UINotifier(uiService, config);
});

/// Theme provider
final themeProvider = StateNotifierProvider<ThemeProvider, ThemeData>((ref) {
  final uiService = ref.watch(uiServiceProvider);
  return ThemeProvider(uiService);
});

/// Configuration state notifier provider
final configurationProvider =
    StateNotifierProvider<ConfigurationNotifier, ConfigurationState>((ref) {
  final config = ref.watch(centralConfigProvider);
  return ConfigurationNotifier(config);
});

/// Performance state notifier provider
final performanceProvider =
    StateNotifierProvider<PerformanceNotifier, PerformanceState>((ref) {
  final performanceService = ref.watch(performanceServiceProvider);
  return PerformanceNotifier(performanceService);
});

// ============================================================================
// COMPUTED PROVIDERS - Derived State
// ============================================================================

/// Combined app state provider
final appStateProvider = Provider<AppState>((ref) {
  final initState = ref.watch(appInitializationProvider);
  final configState = ref.watch(configurationProvider);
  final uiState = ref.watch(uiProvider);
  final performanceState = ref.watch(performanceProvider);

  return AppState(
    isInitialized: initState.maybeWhen(
      data: (data) => data.isFullyInitialized,
      orElse: () => false,
    ),
    isLoading: uiState.isLoading || performanceState.isOptimizing,
    hasError: configState.error != null || performanceState.error != null,
    errorMessage: configState.error ?? performanceState.error,
    themeMode: uiState.themeMode,
    fontScale: uiState.fontScale,
    highContrastEnabled: uiState.highContrastEnabled,
  );
});

/// File operations status provider
final fileOperationsStatusProvider = Provider<FileOperationsStatus>((ref) {
  final fileOpsState = ref.watch(fileOperationsProvider);
  final performanceState = ref.watch(performanceProvider);

  return FileOperationsStatus(
    isActive: fileOpsState.isLoading || fileOpsState.isSearching,
    currentOperation: fileOpsState.currentOperation,
    lastResult: fileOpsState.lastResult,
    operationCount: fileOpsState.operationHistory.length,
    hasError: fileOpsState.error != null,
    errorMessage: fileOpsState.error,
    memoryPressure: performanceState.memoryStatistics.memoryPressure,
  );
});

/// System health provider
final systemHealthProvider = Provider<SystemHealth>((ref) {
  final performanceState = ref.watch(performanceProvider);
  final configState = ref.watch(configurationProvider);
  final initState = ref.watch(appInitializationProvider);

  final isHealthy = initState.maybeWhen(
        data: (data) => data.isFullyInitialized,
        orElse: () => false,
      ) &&
      configState.error == null &&
      performanceState.error == null;

  final issues = <HealthIssue>[];

  if (configState.error != null) {
    issues.add(HealthIssue(
      type: HealthIssueType.configuration,
      severity: HealthSeverity.high,
      message: configState.error!,
    ));
  }

  if (performanceState.error != null) {
    issues.add(HealthIssue(
      type: HealthIssueType.performance,
      severity: HealthSeverity.medium,
      message: performanceState.error!,
    ));
  }

  if (performanceState.memoryStatistics.memoryPressure == MemoryPressure.high) {
    issues.add(HealthIssue(
      type: HealthIssueType.memory,
      severity: HealthSeverity.medium,
      message: 'High memory pressure detected',
    ));
  }

  return SystemHealth(
    isHealthy: isHealthy,
    issues: issues,
    lastChecked: DateTime.now(),
  );
});

// ============================================================================
// UTILITY PROVIDERS
// ============================================================================

/// Async configuration parameter provider
final configParameterProvider =
    FutureProvider.family<String?, String>((ref, key) async {
  final config = ref.watch(centralConfigProvider);
  // In real implementation, this would handle async config loading
  return config.getParameter(key)?.toString();
});

/// Cached async data provider
final cachedAsyncDataProvider =
    FutureProvider.family<dynamic, String>((ref, cacheKey) async {
  final performanceService = ref.watch(performanceServiceProvider);

  // Check cache first
  final cached = performanceService.getCachedObject(cacheKey);
  if (cached != null) {
    return cached;
  }

  // Simulate async data loading
  await Future.delayed(const Duration(milliseconds: 100));

  final data = 'Sample data for $cacheKey'; // Placeholder

  // Cache the result
  performanceService.cacheObject(cacheKey, data,
      ttl: const Duration(minutes: 5));

  return data;
});

/// Stream provider for real-time updates
final realTimeUpdatesProvider = StreamProvider<UpdateEvent>((ref) {
  final fileOpsService = ref.watch(fileOperationsServiceProvider);
  final performanceService = ref.watch(performanceServiceProvider);

  // Combine multiple streams
  return StreamGroup.merge([
    fileOpsService.operationEvents.map((event) => UpdateEvent(
          type: UpdateEventType.fileOperation,
          data: {'event': event.type.toString(), 'details': event.details},
        )),
    performanceService.performanceEvents.map((event) => UpdateEvent(
          type: UpdateEventType.performance,
          data: {'event': event.type.toString(), 'details': event.details},
        )),
  ]);
});

// ============================================================================
// DATA CLASSES
// ============================================================================

/// App state
class AppState {
  final bool isInitialized;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final ThemeMode themeMode;
  final double fontScale;
  final bool highContrastEnabled;

  AppState({
    required this.isInitialized,
    required this.isLoading,
    required this.hasError,
    this.errorMessage,
    required this.themeMode,
    required this.fontScale,
    required this.highContrastEnabled,
  });
}

/// File operations status
class FileOperationsStatus {
  final bool isActive;
  final String? currentOperation;
  final BatchOperationResult? lastResult;
  final int operationCount;
  final bool hasError;
  final String? errorMessage;
  final MemoryPressure memoryPressure;

  FileOperationsStatus({
    required this.isActive,
    this.currentOperation,
    this.lastResult,
    required this.operationCount,
    required this.hasError,
    this.errorMessage,
    required this.memoryPressure,
  });
}

/// System health
class SystemHealth {
  final bool isHealthy;
  final List<HealthIssue> issues;
  final DateTime lastChecked;

  SystemHealth({
    required this.isHealthy,
    required this.issues,
    required this.lastChecked,
  });
}

/// Health issue
class HealthIssue {
  final HealthIssueType type;
  final HealthSeverity severity;
  final String message;

  HealthIssue({
    required this.type,
    required this.severity,
    required this.message,
  });
}

/// Update event for real-time streams
class UpdateEvent {
  final UpdateEventType type;
  final Map<String, dynamic> data;

  UpdateEvent({
    required this.type,
    required this.data,
  });
}

// ============================================================================
// ENUMS
// ============================================================================

enum UpdateEventType {
  fileOperation,
  performance,
  configuration,
  system,
}

enum HealthIssueType {
  configuration,
  performance,
  memory,
  network,
  storage,
}

enum HealthSeverity {
  low,
  medium,
  high,
  critical,
}
