import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Master Application Controller
/// Provides build and run capabilities with comprehensive logging and error handling
class MasterApp {
  static final MasterApp _instance = MasterApp._internal();
  factory MasterApp() => _instance;
  MasterApp._internal();

  final LoggingService _logger = LoggingService();
  bool _isInitialized = false;
  bool _isRunning = false;
  final StreamController<AppEvent> _eventController = StreamController.broadcast();

  Stream<AppEvent> get events => _eventController.stream;

  /// Initialize master application
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Master Application', 'MasterApp');

      // Load environment variables
      await dotenv.load(fileName: '.env');

      // Initialize all services in dependency order
      await _initializeServices();

      _isInitialized = true;
      _emitEvent(AppEvent.initialized);

      _logger.info('Master Application initialized successfully', 'MasterApp');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Master Application', 'MasterApp',
          error: e, stackTrace: stackTrace);
      _emitEvent(AppEvent.error, error: e.toString());
      rethrow;
    }
  }

  /// Run the application with console logging
  Future<void> runWithConsoleLogs() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isRunning) {
      _logger.warning('Application is already running', 'MasterApp');
      return;
    }

    try {
      _isRunning = true;
      _logger.info('Starting application with console logging enabled', 'MasterApp');

      // Set up console logging
      _setupConsoleLogging();

      // Run the Flutter app
      await _runFlutterApp();

    } catch (e, stackTrace) {
      _logger.error('Application failed to run', 'MasterApp',
          error: e, stackTrace: stackTrace);
      _emitEvent(AppEvent.error, error: e.toString());
      _isRunning = false;
      rethrow;
    }
  }

  /// Stop the application
  Future<void> stop() async {
    if (!_isRunning) return;

    try {
      _logger.info('Stopping application', 'MasterApp');
      _isRunning = false;
      _emitEvent(AppEvent.stopped);

    } catch (e, stackTrace) {
      _logger.error('Failed to stop application', 'MasterApp',
          error: e, stackTrace: stackTrace);
      _isRunning = false;
    }
  }

  /// Restart the application
  Future<void> restart() async {
    await stop();
    await Future.delayed(Duration(seconds: 1));
    await runWithConsoleLogs();
  }

  /// Get application status
  AppStatus getStatus() {
    return AppStatus(
      isInitialized: _isInitialized,
      isRunning: _isRunning,
      lastEvent: _lastEvent,
      metrics: _getMetrics(),
    );
  }

  /// Get application metrics
  AppMetrics _getMetrics() {
    return AppMetrics(
      uptime: DateTime.now().difference(_startTime),
      memoryUsage: _getMemoryUsage(),
      errorCount: _errorCount,
      warningCount: _warningCount,
      buildCount: _buildCount,
      networkRequests: _networkRequestCount,
      cacheHits: _cacheHits,
      lastError: _lastError,
    );
  }

  /// Private helper methods

  Future<void> _initializeServices() async {
    // Initialize core services in dependency order
    final services = [
      () => LoggingService().initialize(),
      () => CentralConfig.instance.initialize(),
      () => RobustnessManager().initialize(),
      () => SupabaseService().initialize(),
      () => ResilienceManager().initialize(),
      () => HealthMonitor().initialize(),
      () => PluginManager().initialize(),
      () => OfflineManager().initialize(),
    ];

    for (final service in services) {
      await service();
    }
  }

  Future<void> _runFlutterApp() async {
    // Run the Flutter app
    runApp(iSuiteApp());
  }

  void _setupConsoleLogging() {
    // Redirect Flutter logs to console
    FlutterError.onError = (FlutterErrorDetails details) {
      _logger.error(
        'Flutter Error: ${details.exception}',
        'MasterApp',
        error: details.exception,
        stackTrace: details.stackTrace,
      );
    };

    // Redirect app logs to console
    developer.log('=== Application Logs ===');
    developer.log('Build Configuration: ${kDebugMode ? 'Debug' : 'Release'}');
    developer.log('Platform: ${Platform.operatingSystem}');
    developer.log('Architecture: Clean Architecture + Hybrid Database Strategy');
    developer.log('Performance: Optimized for cross-platform deployment');
    developer.log('Security: Row Level Security + Token Management');
    developer.log('=== End Application Logs ===');
  }

  void _emitEvent(AppEvent event) {
    _lastEvent = event;
    _eventController.add(event);
  }

  // Metrics tracking
  DateTime _startTime = DateTime.now();
  int _buildCount = 0;
  int _errorCount = 0;
  int _warningCount = 0;
  int _networkRequestCount = 0;
  int _cacheHits = 0;
  String? _lastError;

  double _getMemoryUsage() {
    // Simplified memory usage calculation
    return 0.0; // Would need to implement actual memory tracking
  }
}

/// Application status
class AppStatus {
  final bool isInitialized;
  final bool isRunning;
  final AppEvent? lastEvent;
  final AppMetrics metrics;

  AppStatus({
    required this.isInitialized,
    required this.isRunning,
    this.lastEvent,
    required this.metrics,
  });
}

/// Application events
enum AppEvent {
  initialized,
  started,
  stopped,
  error,
  warning,
  info,
}

/// Application metrics
class AppMetrics {
  final Duration uptime;
  final double memoryUsage;
  final int errorCount;
  final int warningCount;
  final int buildCount;
  final int networkRequests;
  final int cacheHits;
  final String? lastError;
}

/// iSuite Application with enhanced features
class iSuiteApp extends StatefulWidget {
  const iSuiteApp({super.key});

  @override
  State<iSuiteAppState> createState() => iSuiteAppState();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iSuite - Enterprise File Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: MainScreen(),
      onGenerateRoute: AppRouter.router.config,
    );
  }
}

class iSuiteAppState extends State<iSuiteAppState> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize master application
    await MasterApp.instance.initialize();
    
    // Setup error handling
    FlutterError.onError = (error, stackTrace) {
      MasterApp.instance._logger.error(
        'Uncaught Flutter Error: ${error}',
        'MasterApp',
        error: error,
        stackTrace: stackTrace,
      );
    };
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: 'iSuite - Enterprise File Manager',
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
          IconButton(
            icon: Icons.sync,
            onPressed: () => _syncData(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_shared,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 16),
            Text(
              'iSuite - Enterprise File Manager',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Cross-Platform File Management Suite',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _runTests(context),
              child: Text('Run Tests'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _showLogs(context),
              child: Text('Show Logs'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: 'Application Settings',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: 'Console Logging',
              subtitle: 'Enable console output for debugging',
              value: kDebugMode,
              onChanged: (value) {
                kDebugMode = value;
                setState(() {});
              },
            ),
            SwitchListTile(
              title: 'Performance Monitoring',
              subtitle: 'Track app performance metrics',
              value: true,
              onChanged: (value) {
                setState(() {});
              },
            ),
            SwitchListTile(
              title: 'Auto Sync',
              subtitle: 'Automatic data synchronization',
              value: true,
              onChanged: (value) {
                setState(() {});
              },
            ),
            SwitchListTile(
              title: 'Error Tracking',
              subtitle: 'Automatic error reporting',
              value: true,
              onChanged: (value) {
                setState(() {});
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _syncData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      content: Text('Syncing data to cloud...'),
      duration: Duration(seconds: 2),
    );
  }

  Future<void> _runTests(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      content: Text('Running comprehensive test suite...'),
      duration: Duration(seconds: 3),
    );

    // Run tests with console output
    final result = await Process.run(
      'flutter test',
      workingDirectory: '.',
      runInShell: true,
      stdout: (process) => _processStdout(process),
      stderr: (process) => _processStderr(process),
      exitCode: 0,
      onExit: (code) => _processExitCode(code),
    );

    if (result.exitCode == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        content: Text('All tests passed!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        content: Text('Tests failed with exit code: ${result.exitCode}'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      );
    }
  }

  void _processStdout(String output) {
    developer.log('=== Test Output ===');
    for (final line in output.split('\n')) {
      developer.log(line);
    }
  }

  void _processStderr(String error) {
    developer.log('=== Error Output ===');
    for (final line in error.split('\n')) {
      developer.log(line);
    }
  }

  void _processExitCode(int exitCode) {
    developer.log('=== Exit Code: $exitCode === 0 ? 'SUCCESS' : 'FAILED'} ===');
  }

  void _showLogs(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: 'Application Logs',
        content: Container(
          height: 400,
          child: SingleChildScrollView(
            child: Text(
              _getFormattedLogs(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getFormattedLogs() {
    // Get logs from logging service
    final logs = LoggingService().getLogHistory();
    return logs.map((log) =>
        '${log.timestamp.toIso8601String()} [${log.level.name}] ${log.message}');
  }
}

class SwitchListTile extends StatelessWidget {
  const SwitchListTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged: onChanged,
      ),
    );
  }
}

class TextButton extends StatelessWidget {
  const TextButton({
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: child,
    );
  }
}
