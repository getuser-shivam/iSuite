import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/central_config.dart';
import 'presentation/screens/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handling for robustness
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Log the error (you can integrate with logging service here)
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error');
    debugPrint('Stack trace: $stack');
    return true; // Prevent the app from crashing
  };

  // Run the app in a zone for uncaught exceptions
  runZonedGuarded(() async {
    // Initialize CentralConfig first
    await CentralConfig.instance.initialize();

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
        systemNavigationBarColor: Colors.transparent,
      ),
    );

    runApp(
      const ProviderScope(
        child: ISuiteApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Uncaught Error: $error');
    debugPrint('Stack trace: $stack');
    // You can show a crash screen or report to analytics here
  });
}
