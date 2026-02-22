import 'features/cloud_storage/screens/cloud_storage_screen.dart';
import 'features/ai_assistant/document_ai_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/central_config.dart';
import 'core/ui/error_boundary.dart';
import 'core/services/notification_service.dart';
import 'core/services/logging_service.dart';
import 'core/ui/accessibility_manager.dart';
import 'core/config/dependency_injection.dart';
import 'core/network/offline_manager.dart';
import 'core/robustness_manager.dart';
import 'core/project_finalizer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging service first
  await LoggingService().initialize();
  final logger = LoggingService();

  try {
    logger.info('Starting iSuite application', 'Main');

    // Initialize accessibility manager
    await AccessibilityManager().initialize();
    logger.info('Accessibility manager initialized', 'Main');

    // Initialize service locator
    await ServiceLocator().initialize();
    logger.info('Service locator initialized', 'Main');

    // Load environment variables
    await dotenv.load(fileName: ".env");
    logger.info('Environment variables loaded', 'Main');

    // Initialize central configuration
    await CentralConfig.instance.initialize();
    logger.info('Central configuration initialized', 'Main');

    // Initialize component factory
    await ComponentFactory.instance.initialize();
    logger.info('Component factory initialized', 'Main');

    // Initialize component registry
    await ComponentRegistry.instance.initialize();
    logger.info('Component registry initialized', 'Main');

    // Initialize notification service
    await NotificationService().initialize();
    logger.info('Notification service initialized', 'Main');

    // Initialize robustness manager
    await RobustnessManager.instance.initialize();
    logger.info('Robustness manager initialized', 'Main');

    // Finalize project and perform quality checks
    final finalizer = ProjectFinalizer();
    final finalizationResult = await finalizer.finalizeProject();
    
    if (!finalizationResult.isSuccessful) {
      logger.warning('Project finalization found issues', 'Main');
      for (final error in finalizationResult._errors) {
        logger.error('Finalization error: $error', 'Main');
      }
    }
    
    if (finalizationResult._warnings.isNotEmpty) {
      logger.info('Project finalization warnings', 'Main');
      for (final warning in finalizationResult._warnings) {
        logger.warning('Finalization warning: $warning', 'Main');
      }
    }

    logger.info('Application initialization completed successfully', 'Main');

  } catch (e, stackTrace) {
    logger.error('Failed to initialize application', 'Main',
        error: e, stackTrace: stackTrace);

    // Show error and exit gracefully
    runApp(ErrorBoundary(
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Application Failed to Start',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${e.toString()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => exit(0),
                    child: const Text('Exit Application'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
    return;
  }

  runApp(const ErrorBoundary(child: ISuiteApp()));
}

class ISuiteApp extends StatelessWidget {
  const ISuiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = CentralConfig.instance;
    
    final lightTheme = ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
      scaffoldBackgroundColor: config.getParameter('ui.colors.background.light', defaultValue: Colors.white),
      appBarTheme: AppBarTheme(
        backgroundColor: config.getParameter('ui.colors.surface.light', defaultValue: Colors.white),
        foregroundColor: config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
        elevation: config.getParameter('ui.app_bar.elevation', defaultValue: 4.0),
      ),
      cardTheme: CardThemeData(
        elevation: config.getParameter('ui.shadow.elevation.medium', defaultValue: 4.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(config.getParameter('ui.border_radius.medium', defaultValue: 8.0))),
        ),
        color: config.getParameter('ui.colors.surface.light', defaultValue: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
          foregroundColor: config.getParameter('ui.colors.surface.light', defaultValue: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(config.getParameter('ui.border_radius.medium', defaultValue: 8.0)),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: config.getParameter('ui.spacing.medium', defaultValue: 20.0),
            vertical: config.getParameter('ui.spacing.medium', defaultValue: 20.0) / 2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.getParameter('ui.border_radius.medium', defaultValue: 8.0)),
        ),
        filled: true,
        fillColor: config.getParameter('ui.colors.surface.light', defaultValue: Colors.white),
      ),
    );

    final darkTheme = ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: config.getParameter('ui.colors.background.dark', defaultValue: Colors.grey[900]),
      appBarTheme: AppBarTheme(
        backgroundColor: config.getParameter('ui.colors.surface.dark', defaultValue: Colors.grey[800]),
        foregroundColor: config.getParameter('ui.colors.surface.light', defaultValue: Colors.white),
        elevation: config.getParameter('ui.app_bar.elevation', defaultValue: 4.0),
      ),
      cardTheme: CardThemeData(
        elevation: config.getParameter('ui.shadow.elevation.medium', defaultValue: 4.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(config.getParameter('ui.border_radius.medium', defaultValue: 8.0))),
        ),
        color: config.getParameter('ui.colors.surface.dark', defaultValue: Colors.grey[800]),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
          foregroundColor: config.getParameter('ui.colors.surface.light', defaultValue: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(config.getParameter('ui.border_radius.medium', defaultValue: 8.0)),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: config.getParameter('ui.spacing.medium', defaultValue: 20.0),
            vertical: config.getParameter('ui.spacing.medium', defaultValue: 20.0) / 2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.getParameter('ui.border_radius.medium', defaultValue: 8.0)),
        ),
        filled: true,
        fillColor: config.getParameter('ui.colors.surface.dark', defaultValue: Colors.grey[800]),
      ),
    );

    return ErrorBoundary(
      child: ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) => MultiProvider(
            providers: ComponentFactory.instance.getAllProviders(),
            child: MaterialApp(
              title: config.appTitle,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeProvider.themeMode,
              // Internationalization support
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en', ''), // English
              ],
              home: const MainScreen(),
            ),
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = CentralConfig.instance;
    
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(config.appTitle),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.folder, color: config.primaryColor), text: config.filesTabTitle),
              Tab(icon: Icon(Icons.wifi, color: config.primaryColor), text: config.networkTabTitle),
              Tab(icon: Icon(Icons.cloud_upload, color: config.primaryColor), text: config.ftpTabTitle),
              Tab(icon: Icon(Icons.cloud, color: config.primaryColor), text: 'Cloud'),
              Tab(icon: Icon(Icons.smart_toy, color: config.primaryColor), text: config.aiTabTitle),
              Tab(icon: Icon(Icons.settings, color: config.primaryColor), text: config.settingsTabTitle),
            ],
            indicatorColor: config.accentColor,
            labelColor: config.primaryColor,
          ),
        ),
        body: const TabBarView(
          children: [
            FileManagementScreen(),
            NetworkManagementScreen(),
            FtpClientScreen(),
            CloudStorageScreen(),
            AiAssistantScreen(),
            SettingsScreen(),
          ],
        ),
      ),
    );
  }
}
