import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_theme.dart';
import 'core/app_router.dart';
import 'core/constants.dart';
import 'core/supabase_client.dart';
import 'core/notification_service.dart';
import 'core/component_registry.dart';
import 'core/component_factory.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/task_provider.dart';
import 'presentation/providers/calendar_provider.dart';
import 'presentation/providers/note_provider.dart';
import 'presentation/providers/file_provider.dart';
import 'presentation/providers/analytics_provider.dart';
import 'presentation/providers/backup_provider.dart';
import 'presentation/providers/search_provider.dart';
import 'presentation/providers/reminder_provider.dart';
import 'presentation/providers/task_suggestion_provider.dart';
import 'presentation/providers/task_automation_provider.dart';
import 'presentation/providers/network_provider.dart';
import 'presentation/providers/file_sharing_provider.dart';
import 'presentation/providers/cloud_sync_provider.dart';
import 'data/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    // Initialize component factory and registry first
    await ComponentFactory.instance.initialize();
    debugPrint('Component factory initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('Component factory initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  try {
    // Initialize database with error handling
    await DatabaseHelper.instance.database;
    debugPrint('Database initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('Database initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue without database for now
  }

  try {
    // Initialize Supabase with error handling
    await SupabaseClientConfig.initialize();
    debugPrint('Supabase initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('Supabase initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue without Supabase for now
  }

  try {
    // Initialize NotificationService with error handling
    await NotificationService().initialize();
    debugPrint('Notification service initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('Notification service initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue without notifications for now
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: ComponentFactory.instance.createAllProviders(),
        child: Builder(
          builder: (context) => Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) => MaterialApp.router(
              title: AppConstants.appName,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              routerConfig: AppRouter.router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: 1.0, // Prevent text scaling issues
                ),
                child: GoogleFonts.montserrat(
                  textStyle: Theme.of(context).textTheme,
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: child!,
                  ),
                ),
              ),
              restorationScopeId: 'app', // Enable state restoration
            ),
          ),
        ),
      );
}
