import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/backend/enhanced_pocketbase_service.dart';
import '../core/config/enhanced_config_manager.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/auth_screen.dart';
import '../presentation/screens/files_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/network_screen.dart';
import '../presentation/theme/enhanced_app_theme.dart';
import '../presentation/widgets/enhanced_scaffold.dart';
import '../presentation/widgets/adaptive_navigation.dart';
import '../presentation/widgets/responsive_layout.dart';

/// Enhanced Main App Widget - Advanced Cross-Platform Free Solution
/// Features: Responsive design, adaptive navigation, theme switching
/// Performance: Lazy loading, optimized rebuilds, memory management
/// Accessibility: Screen reader support, high contrast, large text
class EnhancedISuiteApp extends ConsumerStatefulWidget {
  const EnhancedISuiteApp({super.key});

  @override
  ConsumerState<EnhancedISuiteApp> createState() => _EnhancedISuiteAppState();
}

class _EnhancedISuiteAppState extends ConsumerState<EnhancedISuiteApp> 
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final GoRouter _router;
  late final AnimationController _themeAnimationController;
  late final AnimationController _navigationAnimationController;
  bool _isInitialized = false;
  bool _isAppPaused = false;
  String? _lastRoute;

  // Theme and layout state
  ThemeMode _themeMode = ThemeMode.system;
  bool _isDarkMode = false;
  bool _isHighContrast = false;
  bool _isLargeText = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
    _setupAnimations();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeAnimationController.dispose();
    _navigationAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      default:
        break;
    }
  }

  /// Initialize the app with enhanced services
  Future<void> _initializeApp() async {
    try {
      // Show loading state
      setState(() {});

      // Initialize enhanced configuration manager
      await EnhancedConfigManager.instance.initialize();
      
      // Initialize enhanced PocketBase service
      await EnhancedPocketBaseService.instance.initialize();
      
      // Load theme preferences
      await _loadThemePreferences();
      
      // Setup theme monitoring
      _setupThemeMonitoring();
      
      // Create router
      _router = _createEnhancedRouter();
      
      // Setup performance monitoring
      _setupPerformanceMonitoring();
      
      setState(() {
        _isInitialized = true;
      });
      
      debugPrint('Enhanced iSuite initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('Failed to initialize app: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Show error screen with retry option
      _showInitializationError(e);
    }
  }

  /// Setup animations for smooth transitions
  void _setupAnimations() {
    _themeAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _navigationAnimationController = AnimationController(
      duration: Duration(milliseconds: 250),
      vsync: this,
    );
  }

  /// Load theme preferences from configuration
  Future<void> _loadThemePreferences() async {
    final config = EnhancedConfigManager.instance;
    
    _themeMode = _parseThemeMode(config.getParameter('ui.theme_mode') ?? 'system');
    _isDarkMode = config.getParameter('ui.enable_dark_mode') ?? false;
    _isHighContrast = config.getParameter('accessibility.enable_high_contrast') ?? false;
    _isLargeText = config.getParameter('accessibility.enable_large_text') ?? false;
  }

  /// Parse theme mode from string
  ThemeMode _parseThemeMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Setup theme monitoring for dynamic changes
  void _setupThemeMonitoring() {
    // Listen to configuration changes
    EnhancedConfigManager.instance.events.listen((event) {
      if (event.key.startsWith('ui.theme') || event.key.startsWith('accessibility')) {
        _loadThemePreferences();
        if (mounted) setState(() {});
      }
    });
  }

  /// Setup performance monitoring
  void _setupPerformanceMonitoring() {
    if (kDebugMode) {
      // Enable performance overlay in debug mode
      WidgetsBinding.instance.addTimingsCallback((timings) {
        for (final timing in timings) {
          if (timing.totalSpan.inMilliseconds > 16) {
            debugPrint('Slow frame: ${timing.totalSpan.inMilliseconds}ms');
          }
        }
      });
    }
  }

  /// Create enhanced router with better error handling
  GoRouter _createEnhancedRouter() {
    return GoRouter(
      initialLocation: '/auth',
      redirect: (context, state) {
        return _handleRouteRedirect(state);
      },
      refreshListenable: _createRefreshListenable(),
      routes: [
        // Authentication routes
        GoRoute(
          path: '/auth',
          name: 'auth',
          builder: (context, state) => const AuthScreen(),
        ),
        
        // Main app routes with enhanced shell
        ShellRoute(
          builder: (context, state, child) => EnhancedScaffold(
            child: child,
            animationController: _navigationAnimationController,
          ),
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/files',
              name: 'files',
              builder: (context, state) => const FilesScreen(),
            ),
            GoRoute(
              path: '/network',
              name: 'network',
              builder: (context, state) => const NetworkScreen(),
            ),
            GoRoute(
              path: '/settings',
              name: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
        
        // Detail routes
        GoRoute(
          path: '/files/:id',
          name: 'file_detail',
          parent: ShellRoute(
            builder: (context, state, child) => EnhancedScaffold(
              child: child,
              animationController: _navigationAnimationController,
            ),
          ),
          builder: (context, state) {
            final fileId = state.pathParameters['id']!;
            return FileDetailScreen(fileId: fileId);
          },
        ),
      ],
      
      // Enhanced error handling
      errorBuilder: (context, state) => EnhancedErrorScreen(
        error: state.error,
        onRetry: () => context.go('/home'),
      ),
      
      // Custom transitions
      extraCodec: const CustomTransitionCodec(),
    );
  }

  /// Handle route redirects with authentication
  String? _handleRouteRedirect(GoRouterState state) {
    final isAuthenticated = ref.read(authProvider);
    final location = state.location;
    
    // Redirect to auth if not authenticated and not on auth page
    if (!isAuthenticated && !location.startsWith('/auth')) {
      return '/auth';
    }
    
    // Redirect to home if authenticated and on auth page
    if (isAuthenticated && location.startsWith('/auth')) {
      return '/home';
    }
    
    // Store last route for analytics
    _lastRoute = location;
    
    return null;
  }

  /// Create refresh listenable for router
  Listenable? _createRefreshListenable() {
    // Listen to authentication changes
    return [
      // Authentication state changes
      ref.listen(authProvider, (previous, next) {
        if (previous != next) {
          // Router will automatically rebuild
        }
      }),
      
      // Configuration changes
      EnhancedConfigManager.instance.events.where((event) => 
        event.type == ConfigEventType.parameterChanged
      ).listen((event) {
        // Handle configuration changes that affect routing
        if (event.key == 'navigation.enable_nested_navigation') {
          // Rebuild router if navigation structure changes
        }
      }),
    ];
  }

  /// Handle app resumed state
  void _handleAppResumed() {
    _isAppPaused = false;
    
    // Refresh data if needed
    _refreshDataIfNeeded();
    
    // Check for updates
    _checkForUpdates();
    
    debugPrint('App resumed');
  }

  /// Handle app paused state
  void _handleAppPaused() {
    _isAppPaused = true;
    
    // Save current state
    _saveAppState();
    
    // Pause background operations
    _pauseBackgroundOperations();
    
    debugPrint('App paused');
  }

  /// Handle app detached state
  void _handleAppDetached() {
    // Cleanup resources
    _cleanupResources();
    
    debugPrint('App detached');
  }

  /// Refresh data if needed
  Future<void> _refreshDataIfNeeded() async {
    try {
      final lastSync = EnhancedPocketBaseService.instance.lastSyncTime;
      final now = DateTime.now();
      
      if (lastSync == null || now.difference(lastSync).inMinutes > 5) {
        await EnhancedPocketBaseService.instance.performAutoSync();
      }
    } catch (e) {
      debugPrint('Failed to refresh data: $e');
    }
  }

  /// Check for app updates
  Future<void> _checkForUpdates() async {
    // Implementation depends on platform
    // This is a placeholder for update checking
    debugPrint('Checking for updates...');
  }

  /// Save app state
  Future<void> _saveAppState() async {
    try {
      // Save current route
      if (_lastRoute != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_route', _lastRoute!);
      }
      
      // Save other state as needed
    } catch (e) {
      debugPrint('Failed to save app state: $e');
    }
  }

  /// Pause background operations
  void _pauseBackgroundOperations() {
    // Pause timers, background sync, etc.
  }

  /// Cleanup resources
  Future<void> _cleanupResources() async {
    try {
      await EnhancedPocketBaseService.instance.dispose();
      await EnhancedConfigManager.instance.dispose();
    } catch (e) {
      debugPrint('Failed to cleanup resources: $e');
    }
  }

  /// Show initialization error screen
  void _showInitializationError(dynamic error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Initialization Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Failed to initialize the app: $error'),
            const SizedBox(height: 16),
            const Text('Please check your configuration and try again.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _retryInitialization(),
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  /// Retry initialization
  Future<void> _retryInitialization() async {
    Navigator.of(context).pop();
    await _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildLoadingScreen();
    }

    return _buildEnhancedApp();
  }

  /// Build loading screen with animations
  Widget _buildLoadingScreen() {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(seconds: 1),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.folder_shared,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Loading text
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Column(
                      children: [
                        Text(
                          'iSuite',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Loading your free cross-platform suite...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Progress indicator
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(seconds: 2),
                builder: (context, value, child) {
                  return SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      value: value,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build enhanced app with all features
  Widget _buildEnhancedApp() {
    return Consumer(
      builder: (context, ref, child) {
        return MaterialApp.router(
          title: 'iSuite - Enhanced Free Cross-Platform Suite',
          debugShowCheckedModeBanner: false,
          
          // Enhanced theme configuration
          theme: EnhancedAppTheme.lightTheme.copyWith(
            textTheme: _isLargeText ? _createLargeTextTheme() : null,
          ),
          darkTheme: EnhancedAppTheme.darkTheme.copyWith(
            textTheme: _isLargeText ? _createLargeTextTheme() : null,
          ),
          themeMode: _themeMode,
          
          // High contrast theme
          highContrastTheme: _isHighContrast ? _createHighContrastTheme() : null,
          
          // Router configuration
          routerConfig: _router,
          
          // Builder for additional configuration
          builder: (context, child) {
            return MediaQuery(
              // Ensure font scale doesn't break layout
              data: MediaQuery.of(context).copyWith(
                textScaleFactor: _isLargeText ? 1.2 : 1.0,
              ),
              child: ResponsiveLayout(
                child: child!,
              ),
            );
          },
          
          // Localizations
          localizationsDelegates: const [
            // Add your localization delegates here
          ],
          supportedLocales: const [
            Locale('en', 'US'),
            // Add more locales as needed
          ],
        );
      },
    );
  }

  /// Create large text theme
  TextTheme _createLargeTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(fontSize: 68.4), // 57 * 1.2
      displayMedium: TextStyle(fontSize: 54.0), // 45 * 1.2
      displaySmall: TextStyle(fontSize: 43.2), // 36 * 1.2
      headlineLarge: TextStyle(fontSize: 38.4), // 32 * 1.2
      headlineMedium: TextStyle(fontSize: 33.6), // 28 * 1.2
      headlineSmall: TextStyle(fontSize: 28.8), // 24 * 1.2
      titleLarge: TextStyle(fontSize: 26.4),   // 22 * 1.2
      titleMedium: TextStyle(fontSize: 19.2),  // 16 * 1.2
      titleSmall: TextStyle(fontSize: 16.8),   // 14 * 1.2
      bodyLarge: TextStyle(fontSize: 19.2),   // 16 * 1.2
      bodyMedium: TextStyle(fontSize: 16.8),  // 14 * 1.2
      bodySmall: TextStyle(fontSize: 14.4),   // 12 * 1.2
      labelLarge: TextStyle(fontSize: 16.8),  // 14 * 1.2
      labelMedium: TextStyle(fontSize: 14.4), // 12 * 1.2
      labelSmall: TextStyle(fontSize: 13.2),  // 11 * 1.2
    );
  }

  /// Create high contrast theme
  ThemeData _createHighContrastTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.highContrast(
        primary: Colors.black,
        secondary: Colors.white,
        surface: Colors.white,
        background: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.black,
        onBackground: Colors.black,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(fontWeight: FontWeight.bold),
        bodySmall: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Authentication state provider with enhanced features
final authProvider = Provider<bool>((ref) {
  return EnhancedPocketBaseService.instance.isAuthenticated;
});

/// Enhanced error screen with retry functionality
class EnhancedErrorScreen extends StatelessWidget {
  final dynamic error;
  final VoidCallback onRetry;

  const EnhancedErrorScreen({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                error.toString(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Try Again'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// File detail screen placeholder
class FileDetailScreen extends StatelessWidget {
  final String fileId;

  const FileDetailScreen({
    super.key,
    required this.fileId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Details'),
      ),
      body: Center(
        child: Text('File ID: $fileId'),
      ),
    );
  }
}

/// Custom transition codec for smooth animations
class CustomTransitionCodec extends TransitionCodec {
  const CustomTransitionCodec();

  @override
  Widget buildTransition<T>(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}
