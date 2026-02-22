import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/app_config.dart';
import 'core/enhanced_parameterization.dart';
import 'features/file_management/screens/file_management_screen.dart';
import 'features/cloud_management/screens/cloud_management_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/home/screens/home_screen.dart';

void main() {
  runApp(const OwlfilesApp());
}

class OwlfilesApp extends StatelessWidget {
  const OwlfilesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: ThemeData(
        primarySwatch: AppConfig.primaryColor,
        useMaterial3: true,
        scaffoldBackgroundColor: AppConfig.backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: AppConfig.cardElevation,
        ),
        cardTheme: CardTheme(
          elevation: AppConfig.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: Builder(
        builder: (context) {
          // Initialize enhanced parameterization
          final enhancedParam = EnhancedParameterization(CentralConfig.instance);
          
          return Consumer<EnhancedParameterization>(
            builder: (context, paramSystem) {
              // Initialize parameters when app starts
              WidgetsBinding.instance.addPostFrameCallback((_) {
                enhancedParam.setAllParameters(paramSystem.getAllParameters());
              });
              
              return MaterialApp(
                title: AppConfig.appName,
                theme: ThemeData(
                  primarySwatch: AppConfig.primaryColor,
                  useMaterial3: true,
                  scaffoldBackgroundColor: AppConfig.backgroundColor,
                  appBarTheme: AppBarTheme(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: AppConfig.cardElevation,
                  ),
                  cardTheme: CardTheme(
                    elevation: AppConfig.cardElevation,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  home: const FileManagementScreen(),
                );
            },
          );
        },
      ),
    );
  }
}
