import 'features/cloud_storage/screens/cloud_storage_screen.dart';
import 'features/ai_assistant/document_ai_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/error_boundary.dart';
import 'services/notifications/notification_service.dart';
import 'services/logging/logging_service.dart';
import 'core/accessibility_manager.dart';
import 'core/dependency_injection.dart';
import 'core/offline_manager.dart';

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
      scaffoldBackgroundColor: config.backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: config.surfaceColor,
        foregroundColor: config.primaryColor,
        elevation: config.cardElevation,
      ),
      cardTheme: CardThemeData(
        elevation: config.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(config.borderRadius)),
        ),
        color: config.surfaceColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: config.primaryColor,
          foregroundColor: config.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(config.borderRadius),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: config.defaultPadding,
            vertical: config.defaultPadding / 2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius),
        ),
        filled: true,
        fillColor: config.surfaceColor,
      ),
    );

    final darkTheme = ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        elevation: config.cardElevation,
      ),
      cardTheme: CardThemeData(
        elevation: config.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(config.borderRadius)),
        ),
        color: Colors.grey[800],
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: config.primaryColor,
          foregroundColor: config.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(config.borderRadius),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: config.defaultPadding,
            vertical: config.defaultPadding / 2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius),
        ),
        filled: true,
        fillColor: Colors.grey[800],
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
