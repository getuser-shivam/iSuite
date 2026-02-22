import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/central_config_enhanced.dart';
import 'core/logging_service_enhanced.dart';
import 'core/robustness_manager_enhanced.dart';
import 'core/mock_services.dart';
import 'core/supabase_service.dart';
import 'core/app_router.dart';
import 'presentation/widgets/app_drawer.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging service first
  await LoggingService().initialize();
  final logger = LoggingService();

  try {
    logger.info('Starting iSuite application', 'Main');

    // Load environment variables
    await dotenv.load(fileName: '.env');
    logger.info('Environment variables loaded', 'Main');

    // Initialize central configuration
    await CentralConfig.instance.initialize();
    logger.info('Central configuration initialized', 'Main');

    // Initialize robustness manager
    await RobustnessManager().initialize();
    logger.info('Robustness manager initialized', 'Main');

    // Initialize Supabase service
    await SupabaseService().initialize();
    logger.info('Supabase service initialized', 'Main');

    // Initialize mock services for demonstration
    await ResilienceManager().initialize();
    logger.info('Resilience manager initialized', 'Main');

    await HealthMonitor().initialize();
    logger.info('Health monitor initialized', 'Main');

    await PluginManager().initialize();
    logger.info('Plugin manager initialized', 'Main');

    await OfflineManager().initialize();
    logger.info('Offline manager initialized', 'Main');

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    logger.info('All services initialized successfully', 'Main');

    // Run the app
    runApp(const ISuite());

  } catch (e, stackTrace) {
    logger.error('Failed to initialize application', 'Main', error: e, stackTrace: stackTrace);
    runApp(ErrorApp(error: e.toString()));
  }
}

class ISuite extends StatelessWidget {
  const ISuite({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'iSuite - Enterprise File Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      routerConfig: AppRouter.router,
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[700],
                ),
                const SizedBox(height: 16),
                Text(
                  'Application Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to start iSuite due to an initialization error.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    error,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.red[900],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Attempt to restart the app
                    main();
                  },
                  child: const Text('Restart App'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
