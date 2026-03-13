import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/orchestrator/application_orchestrator.dart';
import 'core/config/parameterization_validation_suite.dart';
import 'core/logging/enhanced_logger.dart';
import 'presentation/enhanced_parameterized_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handling for robustness
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Log the error with enhanced logger
    EnhancedLogger.instance.error('Flutter Error: ${details.exception}', 
      error: details.exception, stackTrace: details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    EnhancedLogger.instance.error('Platform Error: $error', error: error, stackTrace: stack);
    return true; // Prevent the app from crashing
  };

  // Run the app in a zone for uncaught exceptions
  runZonedGuarded(() async {
    // Step 1: Initialize application orchestrator (handles all initialization)
    final appOrchestrator = ApplicationOrchestrator.instance;
    await appOrchestrator.initialize();
    
    // Step 2: Initialize parameterization validation suite
    await ParameterizationValidationSuite.instance.initialize();
    EnhancedLogger.instance.info('Parameterization Validation Suite initialized');

    // Step 3: Run validation suite (optional, can be skipped in production)
    if (kDebugMode) {
      final validationResult = await ParameterizationValidationSuite.instance.runCompleteValidation();
      if (!validationResult.success) {
        EnhancedLogger.instance.warning('Validation suite found issues, continuing anyway...');
      } else {
        EnhancedLogger.instance.info('Validation suite passed successfully');
      }
    }

    // Step 4: Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Step 5: Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );

    EnhancedLogger.instance.info('Starting Enhanced Organized iSuite Application');

    // Step 6: Run the enhanced parameterized app
    runApp(
      const ProviderScope(
        child: EnhancedParameterizedApp(),
      ),
    );
  }, (error, stack) {
    EnhancedLogger.instance.error('Uncaught Error in main: $error', error: error, stackTrace: stack);
    // You can show a crash screen or report to analytics here
  });
}
