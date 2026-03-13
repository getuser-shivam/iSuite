import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/config/central_parameterized_config.dart';
import '../core/config/component_relationship_manager.dart';
import '../core/config/unified_service_orchestrator.dart';
import '../core/orchestrator/application_orchestrator.dart';
import '../core/registry/service_registry.dart';
import '../core/logging/enhanced_logger.dart';
import '../providers/config_provider.dart';
import '../providers/functional_providers.dart';
import 'theme/parameterized_theme_manager.dart';
import 'screens/functional_main_screen.dart';

/// Enhanced Parameterized Application
/// Features: Central parameterization, component coordination, service orchestration
/// Performance: Lazy loading, dependency injection, optimized initialization
/// Architecture: Clean architecture with centralized configuration and component management
class EnhancedParameterizedISuiteApp extends ConsumerWidget {
  const EnhancedParameterizedISuiteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configProvider = ref.watch(configurationProvider);
    final themeProvider = ref.watch(parameterizedThemeProvider);
    final appOrchestrator = ApplicationOrchestrator.instance;
    
    // Listen to application state
    final appState = appOrchestrator.state;
    
    if (appState == ApplicationState.initializing) {
      return _buildInitializationScreen(context, ref);
    } else if (appState == ApplicationState.error) {
      return _buildErrorScreen(context, ref, appOrchestrator.startupError);
    } else {
      return _buildMainApp(context, ref);
    }
  }

  /// Build initialization screen
  Widget _buildInitializationScreen(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = ref.watch(configurationProvider);
    final themeProvider = ref.watch(parameterizedThemeProvider);
    final appOrchestrator = ApplicationOrchestrator.instance;
    
    return MaterialApp(
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: themeProvider._themeManager.getSupportedLocales(configProvider),
      home: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App logo or icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.cloud_done,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                
                // App name
                Text(
                  configProvider.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  l10n.initializing,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Progress indicator
                Column(
                  children: [
                    const LinearProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      '${appOrchestrator.completedSteps.length} / ${appOrchestrator.startupSteps.length} ${l10n.completedSteps}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Completed steps
                Container(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: appOrchestrator.completedSteps.map((step) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build error screen
  Widget _buildErrorScreen(BuildContext context, WidgetRef ref, String? error) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = ref.watch(configurationProvider);
    final themeProvider = ref.watch(parameterizedThemeProvider);
    
    return MaterialApp(
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: themeProvider._themeManager.getSupportedLocales(configProvider),
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Error title
                Text(
                  l10n.initializationFailed,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Error message
                Text(
                  error ?? 'Unknown error occurred',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Retry button
                ElevatedButton(
                  onPressed: () {
                    // Restart application
                    ApplicationOrchestrator.instance.restart();
                  },
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build main application
  Widget _buildMainApp(BuildContext context, WidgetRef ref) {
    final configProvider = ref.watch(configurationProvider);
    final themeProvider = ref.watch(parameterizedThemeProvider);
    
    return MaterialApp(
      title: configProvider.appName,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: themeProvider._themeManager.getSupportedLocales(configProvider),
      locale: themeProvider._themeManager.getLocale(configProvider),
      home: const FunctionalMainScreen(),
    );
  }

  }

