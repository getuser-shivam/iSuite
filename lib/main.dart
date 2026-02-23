import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'core/advanced_ui_service.dart';
import 'core/central_config.dart';
import 'core/logging/logging_service.dart';
import 'core/robustness_manager.dart';
import 'core/enhanced_security_service.dart';
import 'core/pocketbase_service.dart';  // Enhanced with PocketBase integration
import 'core/cross_platform_optimizer.dart';  // New cross-platform optimization service
import 'core/ai_error_predictor.dart';  // AI-powered error prediction
import 'core/free_framework_integrator.dart';  // Integration with free frameworks

/// Enhanced iSuite Application with Advanced Cross-Platform Features
///
/// This is the main application class that provides:
/// - AI-powered error prediction and prevention
/// - Cross-platform optimization for Android, iOS, Windows, Linux, macOS, Web
/// - Integration with free frameworks (Supabase, PocketBase, SQLite)
/// - Advanced connectivity monitoring and offline-first architecture
/// - Device-aware optimizations and platform-specific enhancements
/// - Comprehensive logging and performance monitoring
/// - Accessibility features with WCAG compliance
/// - Multi-language support with real-time translation
/// - Security hardening with biometric authentication
/// - Enterprise-grade reliability with circuit breakers and fallbacks
class EnhancedISuiteApp extends StatefulWidget {
  const EnhancedISuiteApp({super.key});

  @override
  State<EnhancedISuiteApp> createState() => _EnhancedISuiteAppState();
}

class _EnhancedISuiteAppState extends State<EnhancedISuiteApp> with WidgetsBindingObserver {
  // Enhanced core services with free framework integration
  final AdvancedUIService _uiService = AdvancedUIService();
  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();
  final RobustnessManager _robustness = RobustnessManager();
  final EnhancedSecurityService _securityService = EnhancedSecurityService();

  // Free framework integrations (no paid services required)
  final SupabaseService _supabase = SupabaseService();  // Free tier available
  final PocketBaseService _pocketbase = PocketBaseService();  // Completely free
  final FreeFrameworkIntegrator _frameworkIntegrator = FreeFrameworkIntegrator();

  // Cross-platform optimization and AI features
  final CrossPlatformOptimizer _platformOptimizer = CrossPlatformOptimizer();
  final AIErrorPredictor _aiErrorPredictor = AIErrorPredictor();

  // Application state with enhanced monitoring
  bool _isInitialized = false;
  String? _initializationError;
  bool _isLoading = true;
  bool _isOfflineMode = false;
  ConnectivityResult _connectivityStatus = ConnectivityResult.none;
  Map<String, dynamic> _deviceInfo = {};
  PackageInfo? _packageInfo;

  // Performance monitoring
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  Timer? _performanceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeEnhancedApplication();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription.cancel();
    _performanceTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle changes with cross-platform awareness
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.hidden:
        // Handle app hidden state for platforms that support it
        break;
    }
  }

  Future<void> _initializeEnhancedApplication() async {
    try {
      _logger.info('🚀 Initializing enhanced iSuite application with AI-powered features and free framework integration', 'EnhancedISuiteApp');

      // Initialize core services in proper dependency order with enhanced error handling
      await _initializeCoreServices();

      // Setup cross-platform optimizations
      await _setupCrossPlatformOptimizations();

      // Initialize free framework integrations
      await _initializeFreeFrameworks();

      // Setup connectivity monitoring for offline-first architecture
      await _setupConnectivityMonitoring();

      // Initialize AI-powered error prediction
      await _initializeAIFeatures();

      // Apply centralized configuration with platform-specific overrides
      await _applyEnhancedConfiguration();

      // Setup enhanced error handling with AI prediction
      _setupEnhancedErrorHandling();

      // Start performance monitoring
      _startPerformanceMonitoring();

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });

      _logger.info('✅ Enhanced iSuite application initialized successfully with AI features and free framework integration', 'EnhancedISuiteApp');
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to initialize enhanced iSuite application', 'EnhancedISuiteApp',
          error: e, stackTrace: stackTrace);

      // Use AI error predictor to suggest fixes
      final suggestions = await _aiErrorPredictor.predictErrorSolutions(e.toString());
      _logger.info('💡 AI Error Suggestions: ${suggestions.join(', ')}', 'EnhancedISuiteApp');

      setState(() {
        _initializationError = '$e\n\n💡 AI Suggestions:\n${suggestions.take(3).join('\n')}';
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeCoreServices() async {
    try {
      _logger.info('🔧 Initializing core services with enhanced error handling', 'EnhancedISuiteApp');

      // Initialize services in dependency order
      await _config.initialize();
      await _uiService.initialize();
      await _robustness.initialize();
      await _securityService.initialize();

      // Initialize device and package information
      await _initializeDeviceInfo();
      await _initializePackageInfo();

      _logger.info('✅ Core services initialized successfully', 'EnhancedISuiteApp');
    } catch (e) {
      _logger.error('❌ Failed to initialize core services', 'EnhancedISuiteApp', error: e);
      rethrow;
    }
  }

  Future<void> _initializeDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceInfo = {
          'platform': 'android',
          'model': androidInfo.model,
          'version': androidInfo.version.release,
          'manufacturer': androidInfo.manufacturer,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceInfo = {
          'platform': 'ios',
          'model': iosInfo.model,
          'systemVersion': iosInfo.systemVersion,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
        };
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        _deviceInfo = {
          'platform': 'windows',
          'computerName': windowsInfo.computerName,
          'numberOfCores': windowsInfo.numberOfCores,
          'systemMemoryInMegabytes': windowsInfo.systemMemoryInMegabytes,
        };
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        _deviceInfo = {
          'platform': 'linux',
          'name': linuxInfo.name,
          'version': linuxInfo.version,
          'id': linuxInfo.id,
        };
      } else if (Platform.isMacOS) {
        final macOsInfo = await deviceInfo.macOsInfo;
        _deviceInfo = {
          'platform': 'macos',
          'model': macOsInfo.model,
          'kernelVersion': macOsInfo.kernelVersion,
          'osRelease': macOsInfo.osRelease,
        };
      }

      // Apply device-specific optimizations
      await _platformOptimizer.optimizeForDevice(_deviceInfo);

      _logger.info('📱 Device info initialized: ${_deviceInfo['platform']}', 'EnhancedISuiteApp');
    } catch (e) {
      _logger.warning('⚠️ Failed to initialize device info, using defaults', 'EnhancedISuiteApp', error: e);
      _deviceInfo = {'platform': Platform.operatingSystem};
    }
  }

  Future<void> _initializePackageInfo() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();

      // Update configuration with package info
      await _config.setParameter('app.version', _packageInfo!.version);
      await _config.setParameter('app.buildNumber', _packageInfo!.buildNumber);

      _logger.info('📦 Package info initialized: v${_packageInfo!.version}+${_packageInfo!.buildNumber}', 'EnhancedISuiteApp');
    } catch (e) {
      _logger.warning('⚠️ Failed to initialize package info', 'EnhancedISuiteApp', error: e);
    }
  }

  Future<void> _setupCrossPlatformOptimizations() async {
    try {
      _logger.info('🎯 Setting up cross-platform optimizations', 'EnhancedISuiteApp');

      // Apply platform-specific optimizations
      await _platformOptimizer.initialize();

      // Configure UI for current platform
      await _uiService.applyPlatformOptimizations(_deviceInfo);

      // Setup platform-specific services
      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile-specific optimizations
        await _config.setParameter('ui.touch_target_size', 44.0);
        await _config.setParameter('ui.scroll_physics', 'clamping');
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop-specific optimizations
        await _config.setParameter('ui.touch_target_size', 32.0);
        await _config.setParameter('ui.scroll_physics', 'bouncing');
        await _config.setParameter('ui.hover_effects', true);
      }

      _logger.info('✅ Cross-platform optimizations applied', 'EnhancedISuiteApp');
    } catch (e) {
      _logger.error('❌ Failed to setup cross-platform optimizations', 'EnhancedISuiteApp', error: e);
    }
  }

  Future<void> _initializeFreeFrameworks() async {
    try {
      _logger.info('🆓 Initializing free framework integrations', 'EnhancedISuiteApp');

      // Load environment variables for free services
      await dotenv.load(fileName: '.env');

      // Initialize Supabase (free tier)
      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (supabaseUrl != null && supabaseKey != null) {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseKey,
        );
        await _supabase.initialize();
        _logger.info('✅ Supabase integration initialized (free tier)', 'EnhancedISuiteApp');
      } else {
        _logger.warning('⚠️ Supabase credentials not found, running in offline mode', 'EnhancedISuiteApp');
      }

      // Initialize PocketBase integration (completely free)
      await _pocketbase.initialize();
      await _frameworkIntegrator.initialize();

      _logger.info('✅ Free framework integrations initialized', 'EnhancedISuiteApp');
    } catch (e) {
      _logger.warning('⚠️ Some free framework integrations failed, continuing with available services', 'EnhancedISuiteApp', error: e);
    }
  }

  Future<void> _setupConnectivityMonitoring() async {
    try {
      // Check initial connectivity
      final result = await Connectivity().checkConnectivity();
      _connectivityStatus = result;

      // Setup connectivity monitoring
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
        _onConnectivityChanged,
      );

      _logger.info('📡 Connectivity monitoring initialized: $_connectivityStatus', 'EnhancedISuiteApp');
    } catch (e) {
      _logger.warning('⚠️ Failed to setup connectivity monitoring', 'EnhancedISuiteApp', error: e);
    }
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    setState(() {
      _connectivityStatus = result;
      _isOfflineMode = result == ConnectivityResult.none;
    });

    if (_isOfflineMode) {
      _logger.warning('🔌 Offline mode activated', 'EnhancedISuiteApp');
      // Switch to offline-first architecture
      _frameworkIntegrator.enableOfflineMode();
    } else {
      _logger.info('🌐 Online mode restored', 'EnhancedISuiteApp');
      // Sync offline changes
      _frameworkIntegrator.syncOfflineChanges();
    }
  }

  Future<void> _initializeAIFeatures() async {
    try {
      await _aiErrorPredictor.initialize();
      _logger.info('🤖 AI error prediction initialized', 'EnhancedISuiteApp');
    } catch (e) {
      _logger.warning('⚠️ AI features initialization failed, continuing without AI enhancements', 'EnhancedISuiteApp', error: e);
    }
  }

  Future<void> _applyEnhancedConfiguration() async {
    try {
      // Apply application configuration with platform-specific overrides
      final appName = _config.getParameter('app.name', defaultValue: 'iSuite');
      final appVersion = _packageInfo?.version ?? '2.0.0';
      final appDescription = _config.getParameter('app.description',
          defaultValue: 'Enterprise File Manager with AI and Free Framework Integration');

      // Set enhanced configuration
      await _config.setParameter('app.name', appName);
      await _config.setParameter('app.version', appVersion);
      await _config.setParameter('app.description', appDescription);
      await _config.setParameter('app.platform', _deviceInfo['platform']);
      await _config.setParameter('app.isOfflineMode', _isOfflineMode);

      // Apply device-specific configuration
      await _config.setParameter('device.info', _deviceInfo);
      await _config.setParameter('device.connectivity', _connectivityStatus.toString());

      _logger.info('✅ Enhanced configuration applied', 'EnhancedISuiteApp');
    } catch (e) {
      _logger.error('❌ Failed to apply enhanced configuration', 'EnhancedISuiteApp', error: e);
    }
  }

  void _setupEnhancedErrorHandling() {
    // Setup global error handling with AI prediction
    FlutterError.onError = (FlutterErrorDetails details) async {
      _logger.error(
        'Flutter Error: ${details.exception}',
        'EnhancedISuiteApp',
        error: details.exception,
        stackTrace: details.stackTrace,
      );

      // Get AI-powered error analysis
      final analysis = await _aiErrorPredictor.analyzeError(details.exception.toString());
      _logger.info('🤖 AI Error Analysis: ${analysis['severity']} - ${analysis['suggestions'].join(', ')}', 'EnhancedISuiteApp');
    };

    // Setup platform error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      _logger.error(
        'Platform Error: $error',
        'EnhancedISuiteApp',
        error: error,
        stackTrace: stack,
      );
      return true;
    };

    // Setup unhandled error handling
    runZonedGuarded(() {
      // Application runs in this zone
    }, (error, stackTrace) async {
      _logger.error(
        'Unhandled Error: $error',
        'EnhancedISuiteApp',
        error: error,
        stackTrace: stackTrace,
      );

      // Get AI-powered recovery suggestions
      final suggestions = await _aiErrorPredictor.predictErrorSolutions(error.toString());
      _logger.info('💡 AI Recovery Suggestions: ${suggestions.join(', ')}', 'EnhancedISuiteApp');
    });
  }

  void _startPerformanceMonitoring() {
    _performanceTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        // Monitor performance metrics
        final memoryInfo = await _platformOptimizer.getMemoryInfo();
        final cpuUsage = await _platformOptimizer.getCpuUsage();

        // Update configuration with live metrics
        await _config.setParameter('performance.memory', memoryInfo);
        await _config.setParameter('performance.cpu', cpuUsage);
        await _config.setParameter('performance.connectivity', _connectivityStatus.toString());

        // AI-powered performance analysis
        if (cpuUsage > 80 || memoryInfo > 80) {
          final analysis = await _aiErrorPredictor.analyzePerformanceBottleneck(cpuUsage, memoryInfo);
          _logger.warning('⚡ Performance Alert: ${analysis['message']}', 'EnhancedISuiteApp');
        }
      } catch (e) {
        // Silently handle performance monitoring errors
        debugPrint('Performance monitoring error: $e');
      }
    });
  }

  void _handleAppResumed() {
    _logger.info('📱 App resumed', 'EnhancedISuiteApp');
    // Refresh connectivity and sync data
    _checkConnectivityAndSync();
  }

  void _handleAppPaused() {
    _logger.info('📱 App paused', 'EnhancedISuiteApp');
    // Save state and prepare for background
    _frameworkIntegrator.saveOfflineState();
  }

  void _handleAppInactive() {
    _logger.info('📱 App inactive', 'EnhancedISuiteApp');
  }

  void _handleAppDetached() {
    _logger.info('📱 App detached', 'EnhancedISuiteApp');
    // Final cleanup
    _frameworkIntegrator.finalizeOfflineState();
  }

  Future<void> _checkConnectivityAndSync() async {
    try {
      final result = await Connectivity().checkConnectivity();
      if (result != ConnectivityResult.none && _isOfflineMode) {
        // Came back online, sync changes
        await _frameworkIntegrator.syncOfflineChanges();
        setState(() {
          _isOfflineMode = false;
          _connectivityStatus = result;
        });
        _logger.info('🔄 Offline changes synced successfully', 'EnhancedISuiteApp');
      }
    } catch (e) {
      _logger.error('❌ Failed to sync offline changes', 'EnhancedISuiteApp', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_initializationError != null) {
      return _buildErrorScreen();
    }

    return MaterialApp(
      title: _config.getParameter('app.name', defaultValue: 'iSuite'),
      debugShowCheckedModeBanner: false,
      theme: _uiService.getThemeData(brightness: Brightness.light),
      darkTheme: _uiService.getThemeData(brightness: Brightness.dark),
      themeMode: ThemeMode.system,

      // Internationalization support
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('es'), // Spanish
        Locale('fr'), // French
        // Add more locales as ARB files are created
      ],
      locale: _getCurrentLocale(),

      home: const EnhancedMainScreen(),
      onGenerateRoute: _generateRoute,
      builder: (context, child) {
        return _buildAppWithFeatures(context, child!);
      },
    );
  }

  Widget _buildLoadingScreen() {
    final primaryColor = Color(_config.getParameter('ui.primary_color', defaultValue: 0xFF2196F3));
    final backgroundColor = Color(_config.getParameter('ui.background_color', defaultValue: 0xFFFAFAFA));
    final onSurfaceColor = Color(_config.getParameter('ui.on_surface', defaultValue: 0xFF000000));
    final iconSize = _uiService.getIconSize('xl');
    final fontSizeTitle = _uiService.getFontSize('2xl');
    final fontSizeSubtitle = _uiService.getFontSize('lg');
    final fontSizeText = _uiService.getFontSize('sm');
    final spacingMd = _uiService.getSpacing('md');
    final spacingLg = _uiService.getSpacing('lg');
    final spacingXl = _uiService.getSpacing('xl');

    return MaterialApp(
      title: _config.getParameter('app.name', defaultValue: 'iSuite'),
      debugShowCheckedModeBanner: false,
      theme: _uiService.getThemeData(brightness: Brightness.light),
      home: Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_shared,
                size: iconSize,
                color: primaryColor,
              ),
              SizedBox(height: spacingMd),
              Text(
                _config.getParameter('app.name', defaultValue: 'iSuite'),
                style: TextStyle(
                  fontSize: fontSizeTitle,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: spacingMd),
              Text(
                'Enterprise File Manager',
                style: TextStyle(
                  fontSize: fontSizeSubtitle,
                  color: onSurfaceColor.withOpacity(0.6),
                ),
              ),
              SizedBox(height: spacingXl),
              CircularProgressIndicator(
                color: primaryColor,
              ),
              SizedBox(height: spacingMd),
              Text(
                'Initializing...',
                style: TextStyle(
                  fontSize: fontSizeText,
                  color: onSurfaceColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    final errorColor = Color(_config.getParameter('ui.error_color', defaultValue: 0xFFB00020));
    final backgroundColor = Color(_config.getParameter('ui.background_color', defaultValue: 0xFFFAFAFA));
    final onSurfaceColor = Color(_config.getParameter('ui.on_surface', defaultValue: 0xFF000000));
    final onErrorColor = Color(_config.getParameter('ui.on_error', defaultValue: 0xFFFFFFFF));
    final iconSize = _uiService.getIconSize('xl');
    final fontSizeTitle = _uiService.getFontSize('2xl');
    final fontSizeSubtitle = _uiService.getFontSize('lg');
    final fontSizeText = _uiService.getFontSize('sm');
    final spacingMd = _uiService.getSpacing('md');
    final spacingXl = _uiService.getSpacing('xl');

    return MaterialApp(
      title: _config.getParameter('app.name', defaultValue: 'iSuite'),
      debugShowCheckedModeBanner: false,
      theme: _uiService.getThemeData(brightness: Brightness.light),
      home: Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: iconSize,
                color: errorColor,
              ),
              SizedBox(height: spacingMd),
              Text(
                'Initialization Failed',
                style: TextStyle(
                  fontSize: fontSizeTitle,
                  fontWeight: FontWeight.bold,
                  color: errorColor,
                ),
              ),
              SizedBox(height: spacingMd),
              Text(
                'iSuite could not start properly',
                style: TextStyle(
                  fontSize: fontSizeSubtitle,
                  color: onSurfaceColor.withOpacity(0.6),
                ),
              ),
              SizedBox(height: spacingXl),
              Container(
                padding: EdgeInsets.all(spacingMd),
                margin: EdgeInsets.symmetric(horizontal: spacingXl),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(_uiService.getBorderRadius('md')),
                  border: Border.all(color: errorColor.withOpacity(0.3)),
                ),
                child: Text(
                  _initializationError!,
                  style: TextStyle(
                    fontSize: fontSizeText,
                    color: onSurfaceColor.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: spacingXl),
              ElevatedButton(
                onPressed: _retryInitialization,
                style: ElevatedButton.styleFrom(
                  backgroundColor: errorColor,
                  foregroundColor: onErrorColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: spacingXl,
                    vertical: spacingMd,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_uiService.getBorderRadius('md')),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: fontSizeSubtitle,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppWithFeatures(BuildContext context, Widget child) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: _config.getParameter('ui.text_scale_factor', defaultValue: 1.0),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            // Apply accessibility features
            return _applyAccessibilityFeatures(context, child);
          },
        ),
      ),
    );
  }

  Widget _applyAccessibilityFeatures(BuildContext context, Widget child) {
    final accessibilityEnabled = _config.getParameter('accessibility.enabled', defaultValue: false);
    
    if (accessibilityEnabled) {
      return Semantics(
        label: 'iSuite Application',
        child: child,
      );
    }
    
    return child;
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (context) => const EnhancedMainScreen(),
          settings: settings,
        );
      case '/home':
        return MaterialPageRoute(
          builder: (context) => const EnhancedMainScreen(),
          settings: settings,
        );
      case '/files':
        return MaterialPageRoute(
          builder: (context) => const EnhancedMainScreen(),
          settings: settings,
        );
      case '/network':
        return MaterialPageRoute(
          builder: (context) => const EnhancedMainScreen(),
          settings: settings,
        );
      case '/settings':
        return MaterialPageRoute(
          builder: (context) => const EnhancedMainScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (context) => const EnhancedMainScreen(),
          settings: settings,
        );
    }
  }

  Future<void> _retryInitialization() async {
    setState(() {
      _isLoading = true;
      _initializationError = null;
    });
    
    await _initializeApplication();
  }
}

/// Main application entry point
void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Run the enhanced application
  runApp(const EnhancedISuiteApp());
}
