import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/central_config.dart';
import 'core/component_factory.dart';
import 'core/component_registry.dart';
import 'features/file_management/screens/enhanced_file_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize central configuration
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
      providers: ComponentFactory.instance.getAllProviders(),
      child: MaterialApp(
        title: 'iSuite - File Manager',
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
        home: const EnhancedFileManagementScreen(),
      ),
    );
  }
}
