import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/ui/ui_config_service.dart';
import 'core/ui/enhanced_ui_components.dart';
import 'core/central_config.dart';
import 'core/logging/logging_service.dart';
import 'core/robustness_manager.dart';
import 'core/supabase_service.dart';
import 'screens/enhanced_main_screen.dart';

/// Enhanced iSuite Application with Central Configuration
/// 
/// This is the main application class that provides:
/// - Central parameterization through UIConfigService
/// - Enhanced UI components with proper configuration
/// - Dynamic theme switching
/// - Responsive design for different screen sizes
/// - Performance monitoring and optimization
/// - Accessibility support
/// - Multi-language support
/// - Error handling and recovery
/// - Service initialization and management
/// - Configuration management
/// - Logging and debugging
class EnhancedISuiteApp extends StatefulWidget {
  const EnhancedISuiteApp({super.key});

  @override
  State<EnhancedISuiteApp> createState() => _EnhancedISuiteAppState();
}

class _EnhancedISuiteAppState extends State<EnhancedISuiteApp> {
  // Core services
  final UIConfigService _uiConfig = UIConfigService();
  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();
  final RobustnessManager _robustness = RobustnessManager();
  final SupabaseService _supabase = SupabaseService();

  // Application state
  bool _isInitialized = false;
  String? _initializationError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApplication();
  }

  Future<void> _initializeApplication() async {
    try {
      _logger.info('Initializing enhanced iSuite application', 'ISuiteApp');
      
      // Initialize core services
      await _initializeServices();
      
      // Apply configuration
      await _applyConfiguration();
      
      // Setup error handling
      _setupErrorHandling();
      
      // Apply accessibility settings
      await _uiConfig.applyAccessibilitySettings();
      
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
      
      _logger.info('iSuite application initialized successfully', 'ISuiteApp');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize iSuite application', 'ISuiteApp',
          error: e, stackTrace: stackTrace);
      setState(() {
        _initializationError = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize services in dependency order
      await _config.initialize();
      await _uiConfig.initialize();
      await _robustness.initialize();
      await _supabase.initialize();
      
      _logger.info('Core services initialized successfully', 'ISuiteApp');
    } catch (e) {
      _logger.error('Failed to initialize core services', 'ISuiteApp', error: e);
      rethrow;
    }
  }

  Future<void> _applyConfiguration() async {
    try {
      // Apply application configuration
      final appName = _config.getParameter('app.name', defaultValue: 'iSuite');
      final appVersion = _config.getParameter('app.version', defaultValue: '2.0.0');
      final appDescription = _config.getParameter('app.description', 
          defaultValue: 'Enterprise File Manager');
      
      // Update app configuration
      await _config.setParameter('app.name', appName);
      await _config.setParameter('app.version', appVersion);
      await _config.setParameter('app.description', appDescription);
      
      _logger.info('Configuration applied successfully', 'ISuiteApp');
    } catch (e) {
      _logger.error('Failed to apply configuration', 'ISuiteApp', error: e);
    }
  }

  void _setupErrorHandling() {
    // Setup global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      _logger.error(
        'Flutter Error: ${details.exception}',
        'ISuiteApp',
        error: details.exception,
        stackTrace: details.stackTrace,
      );
    };

    // Setup platform error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      _logger.error(
        'Platform Error: $error',
        'ISuiteApp',
        error: error,
        stackTrace: stack,
      );
      return true;
    };
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
      theme: _uiConfig.getThemeData(),
      home: const EnhancedMainScreen(),
      onGenerateRoute: _generateRoute,
      builder: (context, child) {
        return _buildAppWithFeatures(context, child!);
      },
    );
  }

  Widget _buildLoadingScreen() {
    return MaterialApp(
      title: 'iSuite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_shared,
                size: 64,
                color: Colors.blue,
              ),
              SizedBox(height: 16),
              Text(
                'iSuite',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Enterprise File Manager',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(
                color: Colors.blue,
              ),
              SizedBox(height: 16),
              Text(
                'Initializing...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return MaterialApp(
      title: 'iSuite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.light,
        ),
      ),
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'Initialization Failed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'iSuite could not start properly',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 32),
              Text(
                _initializationError!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _retryInitialization,
                child: Text('Retry'),
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
