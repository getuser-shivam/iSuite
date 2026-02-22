import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/advanced_parameterization.dart';
import 'core/central_config.dart';
import 'core/component_factory.dart';
import 'core/component_registry.dart';
import 'presentation/providers/enhanced_file_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/task_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/file_provider.dart';
import 'features/file_management/screens/enhanced_file_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize advanced parameterization system
  await AdvancedCentralConfig.instance.initialize();
  
  // Initialize legacy central configuration for backward compatibility
  await CentralConfig.instance.initialize();
  
  // Initialize component factory
  await ComponentFactory.instance.initialize();
  
  // Initialize component registry
  await ComponentRegistry.instance.initialize();
  
  runApp(const iSuiteApp());
}

class iSuiteApp extends StatelessWidget {
  const iSuiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Enhanced providers with advanced parameterization
        ChangeNotifierProvider(create: (_) => EnhancedFileProvider()),
        
        // Legacy providers for backward compatibility
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FileProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'iSuite - Advanced File Manager',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFF5F5F5),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 1,
              ),
              cardTheme: const CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF121212),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1E1E1E),
                foregroundColor: Colors.white,
                elevation: 1,
              ),
              cardTheme: const CardThemeData(
                elevation: 2,
                color: Color(0xFF2A2A2A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            themeMode: themeProvider.themeMode,
            home: const EnhancedFileManagementScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
