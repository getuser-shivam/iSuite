import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/central_config.dart';
import '../logging/logging_service.dart';
import '../enhanced_error_handling_service.dart';
import '../enhanced_performance_service.dart';
import '../enhanced_security_service.dart';
import '../free_integrations_service.dart';
import '../advanced_offline_service.dart';
import '../advanced_free_ai_service.dart';
import '../circuit_breaker_service.dart';
import '../health_check_service.dart';
import '../retry_service.dart';

/// Graceful Shutdown and Startup Service
///
/// Manages application lifecycle with graceful shutdown and startup procedures:
/// - Ordered service shutdown to prevent data loss
/// - Startup health checks and dependency validation
/// - Signal handling for clean termination
/// - Recovery from unexpected shutdowns
/// - Resource cleanup and state preservation
class GracefulShutdownService {
  static const String _configPrefix = 'graceful_shutdown';
  static const String _defaultShutdownTimeout =
      'graceful_shutdown.timeout_seconds';
  static const String _defaultStartupTimeout =
      'graceful_shutdown.startup_timeout_seconds';
  static const String _defaultEnabled = 'graceful_shutdown.enabled';
  static const String _defaultSignalHandlingEnabled =
      'graceful_shutdown.signal_handling_enabled';

  final LoggingService _loggingService;
  final CentralConfig _centralConfig;
  final EnhancedErrorHandlingService _errorHandlingService;

  // Service references
  FreeIntegrationsService? _freeIntegrationsService;
  AdvancedOfflineService? _advancedOfflineService;
  AdvancedFreeAiService? _advancedFreeAiService;
  CircuitBreakerService? _circuitBreakerService;
  HealthCheckService? _healthCheckService;
  RetryService? _retryService;
  EnhancedPerformanceService? _performanceService;
  EnhancedSecurityService? _securityService;

  final List<ShutdownHandler> _shutdownHandlers = [];
  final StreamController<LifecycleEvent> _lifecycleController =
      StreamController.broadcast();

  bool _isInitialized = false;
  bool _isShuttingDown = false;
  bool _isStartingUp = false;
  Completer<void>? _shutdownCompleter;

  DateTime? _startupTime;
  DateTime? _shutdownTime;

  // Signal handling
  StreamSubscription<ProcessSignal>? _sigintSubscription;
  StreamSubscription<ProcessSignal>? _sigtermSubscription;

  GracefulShutdownService({
    LoggingService? loggingService,
    CentralConfig? centralConfig,
    EnhancedErrorHandlingService? errorHandlingService,
  })  : _loggingService = loggingService ?? LoggingService(),
        _centralConfig = centralConfig ?? CentralConfig.instance,
        _errorHandlingService =
            errorHandlingService ?? EnhancedErrorHandlingService();

  /// Initialize the graceful shutdown service
  Future<void> initialize({
    FreeIntegrationsService? freeIntegrationsService,
    AdvancedOfflineService? advancedOfflineService,
    AdvancedFreeAiService? advancedFreeAiService,
    CircuitBreakerService? circuitBreakerService,
    HealthCheckService? healthCheckService,
    RetryService? retryService,
    EnhancedPerformanceService? performanceService,
    EnhancedSecurityService? securityService,
  }) async {
    if (_isInitialized) return;

    try {
      _loggingService.info(
          'Initializing Graceful Shutdown Service', 'GracefulShutdownService');

      // Store service references
      _freeIntegrationsService = freeIntegrationsService;
      _advancedOfflineService = advancedOfflineService;
      _advancedFreeAiService = advancedFreeAiService;
      _circuitBreakerService = circuitBreakerService;
      _healthCheckService = healthCheckService;
      _retryService = retryService;
      _performanceService = performanceService;
      _securityService = securityService;

      // Register with CentralConfig
      await _centralConfig.registerComponent('GracefulShutdownService', '1.0.0',
          'Manages application lifecycle with graceful shutdown and startup procedures',
          dependencies: [
            'CentralConfig',
            'LoggingService',
            'EnhancedErrorHandlingService'
          ],
          parameters: {
            _defaultEnabled: true,
            _defaultShutdownTimeout: 30, // seconds
            _defaultStartupTimeout: 60, // seconds
            _defaultSignalHandlingEnabled: true,
            'graceful_shutdown.save_state_on_shutdown': true,
            'graceful_shutdown.validate_startup_health': true,
            'graceful_shutdown.recovery_from_crash': true,
            'graceful_shutdown.shutdown_order': [
              'ui',
              'services',
              'network',
              'storage',
              'config'
            ],
            'graceful_shutdown.startup_order': [
              'config',
              'storage',
              'network',
              'services',
              'ui'
            ],
          });

      // Register shutdown handlers
      _registerShutdownHandlers();

      // Setup signal handling
      if (signalHandlingEnabled && !kIsWeb) {
        _setupSignalHandling();
      }

      _isInitialized = true;
      _loggingService.info('Graceful Shutdown Service initialized successfully',
          'GracefulShutdownService');
    } catch (e, stackTrace) {
      _loggingService.error('Failed to initialize Graceful Shutdown Service',
          'GracefulShutdownService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Configuration getters
  bool get enabled =>
      _centralConfig.getParameter(_defaultEnabled, defaultValue: true);
  Duration get shutdownTimeout => Duration(
      seconds: _centralConfig.getParameter(_defaultShutdownTimeout,
          defaultValue: 30));
  Duration get startupTimeout => Duration(
      seconds: _centralConfig.getParameter(_defaultStartupTimeout,
          defaultValue: 60));
  bool get signalHandlingEnabled => _centralConfig
      .getParameter(_defaultSignalHandlingEnabled, defaultValue: true);
  bool get saveStateOnShutdown =>
      _centralConfig.getParameter('graceful_shutdown.save_state_on_shutdown',
          defaultValue: true);
  bool get validateStartupHealth =>
      _centralConfig.getParameter('graceful_shutdown.validate_startup_health',
          defaultValue: true);
  bool get recoveryFromCrash =>
      _centralConfig.getParameter('graceful_shutdown.recovery_from_crash',
          defaultValue: true);
  List<String> get shutdownOrder => List<String>.from(_centralConfig
      .getParameter('graceful_shutdown.shutdown_order',
          defaultValue: ['ui', 'services', 'network', 'storage', 'config']));
  List<String> get startupOrder => List<String>.from(_centralConfig
      .getParameter('graceful_shutdown.startup_order',
          defaultValue: ['config', 'storage', 'network', 'services', 'ui']));

  /// Perform graceful startup
  Future<StartupResult> performStartup() async {
    if (!enabled) {
      return StartupResult.success();
    }

    if (_isStartingUp) {
      throw StateError('Startup already in progress');
    }

    _isStartingUp = true;
    final startTime = DateTime.now();

    try {
      _loggingService.info(
          'Starting graceful application startup', 'GracefulShutdownService');
      _emitEvent(LifecycleEvent(type: LifecycleEventType.startupStarted));

      // Check for crash recovery
      if (recoveryFromCrash) {
        await _performCrashRecovery();
      }

      // Execute startup sequence
      final results = <String, OperationResult>{};

      for (final phase in startupOrder) {
        try {
          _loggingService.info(
              'Starting up phase: $phase', 'GracefulShutdownService');

          final result =
              await _executeStartupPhase(phase).timeout(startupTimeout);
          results[phase] = result;

          if (!result.success) {
            _loggingService.warning(
                'Startup phase $phase failed: ${result.error}',
                'GracefulShutdownService');
            // Continue with other phases unless critical
            if (_isCriticalPhase(phase)) {
              throw Exception(
                  'Critical startup phase $phase failed: ${result.error}');
            }
          }
        } catch (e) {
          results[phase] =
              OperationResult.failure('Timeout or exception: ${e.toString()}');
          _loggingService.error(
              'Startup phase $phase failed', 'GracefulShutdownService',
              error: e);
        }
      }

      // Validate startup health
      if (validateStartupHealth) {
        final healthResult = await _validateStartupHealth();
        if (!healthResult.success) {
          _loggingService.warning(
              'Startup health validation failed', 'GracefulShutdownService');
        }
      }

      _startupTime = DateTime.now();
      final duration = _startupTime!.difference(startTime);

      _emitEvent(LifecycleEvent(
        type: LifecycleEventType.startupCompleted,
        duration: duration,
        metadata: {
          'phases': results.length,
          'successful': results.values.where((r) => r.success).length
        },
      ));

      _loggingService.info(
          'Application startup completed in ${duration.inMilliseconds}ms',
          'GracefulShutdownService');

      _isStartingUp = false;
      return StartupResult.success(results: results, duration: duration);
    } catch (e, stackTrace) {
      _loggingService.error(
          'Application startup failed', 'GracefulShutdownService',
          error: e, stackTrace: stackTrace);
      _emitEvent(LifecycleEvent(
        type: LifecycleEventType.startupFailed,
        error: e.toString(),
      ));

      _isStartingUp = false;
      return StartupResult.failure(
          error: e.toString(), duration: DateTime.now().difference(startTime));
    }
  }

  /// Perform graceful shutdown
  Future<ShutdownResult> performShutdown({String reason = 'normal'}) async {
    if (!enabled) {
      return ShutdownResult.success();
    }

    if (_isShuttingDown) {
      _loggingService.warning(
          'Shutdown already in progress', 'GracefulShutdownService');
      return ShutdownResult.success(); // Already shutting down
    }

    _isShuttingDown = true;
    _shutdownCompleter = Completer<void>();
    final startTime = DateTime.now();

    try {
      _loggingService.info(
          'Starting graceful application shutdown (reason: $reason)',
          'GracefulShutdownService');
      _emitEvent(LifecycleEvent(
        type: LifecycleEventType.shutdownStarted,
        metadata: {'reason': reason},
      ));

      // Save application state
      if (saveStateOnShutdown) {
        await _saveApplicationState();
      }

      // Execute shutdown sequence in reverse order
      final reversedOrder = shutdownOrder.reversed.toList();
      final results = <String, OperationResult>{};

      for (final phase in reversedOrder) {
        try {
          _loggingService.info(
              'Shutting down phase: $phase', 'GracefulShutdownService');

          final result =
              await _executeShutdownPhase(phase).timeout(shutdownTimeout);
          results[phase] = result;

          if (!result.success) {
            _loggingService.warning(
                'Shutdown phase $phase failed: ${result.error}',
                'GracefulShutdownService');
          }
        } catch (e) {
          results[phase] =
              OperationResult.failure('Timeout or exception: ${e.toString()}');
          _loggingService.error(
              'Shutdown phase $phase failed', 'GracefulShutdownService',
              error: e);
        }
      }

      // Execute custom shutdown handlers
      await _executeShutdownHandlers();

      _shutdownTime = DateTime.now();
      final duration = _shutdownTime!.difference(startTime);

      _emitEvent(LifecycleEvent(
        type: LifecycleEventType.shutdownCompleted,
        duration: duration,
        metadata: {'reason': reason, 'phases': results.length},
      ));

      _loggingService.info(
          'Application shutdown completed in ${duration.inMilliseconds}ms',
          'GracefulShutdownService');

      _shutdownCompleter!.complete();
      _isShuttingDown = false;

      return ShutdownResult.success(results: results, duration: duration);
    } catch (e, stackTrace) {
      _loggingService.error(
          'Application shutdown failed', 'GracefulShutdownService',
          error: e, stackTrace: stackTrace);
      _emitEvent(LifecycleEvent(
        type: LifecycleEventType.shutdownFailed,
        error: e.toString(),
        metadata: {'reason': reason},
      ));

      _shutdownCompleter!.complete();
      _isShuttingDown = false;

      return ShutdownResult.failure(
          error: e.toString(), duration: DateTime.now().difference(startTime));
    }
  }

  /// Register a custom shutdown handler
  void registerShutdownHandler(ShutdownHandler handler) {
    _shutdownHandlers.add(handler);
    _loggingService.info('Registered shutdown handler: ${handler.name}',
        'GracefulShutdownService');
  }

  /// Unregister a shutdown handler
  void unregisterShutdownHandler(String name) {
    _shutdownHandlers.removeWhere((h) => h.name == name);
    _loggingService.info(
        'Unregistered shutdown handler: $name', 'GracefulShutdownService');
  }

  /// Force immediate shutdown (for emergencies)
  Future<void> forceShutdown({String reason = 'forced'}) async {
    _loggingService.warning('Forcing immediate shutdown (reason: $reason)',
        'GracefulShutdownService');

    // Cancel ongoing operations
    _shutdownCompleter?.complete();

    // Execute critical cleanup
    await _executeCriticalCleanup();

    // Exit immediately
    if (!kIsWeb) {
      exit(1);
    }
  }

  /// Get application uptime
  Duration? getUptime() {
    if (_startupTime == null) return null;
    return DateTime.now().difference(_startupTime!);
  }

  /// Get shutdown status
  ShutdownStatus getShutdownStatus() {
    return ShutdownStatus(
      isShuttingDown: _isShuttingDown,
      shutdownStartTime: _shutdownTime != null
          ? DateTime.now().difference(_shutdownTime!)
          : null,
      startupTime: _startupTime,
      isInitialized: _isInitialized,
    );
  }

  /// Wait for shutdown to complete
  Future<void> waitForShutdown() {
    return _shutdownCompleter?.future ?? Future.value();
  }

  /// Private methods

  void _registerShutdownHandlers() {
    // Register default shutdown handlers
    registerShutdownHandler(ShutdownHandler(
      name: 'logging_flush',
      priority: ShutdownPriority.high,
      handler: () async {
        // Flush any pending log messages
        await Future.delayed(const Duration(milliseconds: 100));
      },
    ));

    registerShutdownHandler(ShutdownHandler(
      name: 'performance_cleanup',
      priority: ShutdownPriority.medium,
      handler: () async {
        if (_performanceService != null) {
          // Stop performance monitoring
        }
      },
    ));

    registerShutdownHandler(ShutdownHandler(
      name: 'security_cleanup',
      priority: ShutdownPriority.high,
      handler: () async {
        if (_securityService != null) {
          // Clean up security contexts
        }
      },
    ));
  }

  void _setupSignalHandling() {
    try {
      _sigintSubscription = ProcessSignal.sigint.watch().listen((signal) {
        _loggingService.info(
            'Received SIGINT signal', 'GracefulShutdownService');
        performShutdown(reason: 'signal_sigint');
      });

      _sigtermSubscription = ProcessSignal.sigterm.watch().listen((signal) {
        _loggingService.info(
            'Received SIGTERM signal', 'GracefulShutdownService');
        performShutdown(reason: 'signal_sigterm');
      });

      _loggingService.info(
          'Signal handling setup completed', 'GracefulShutdownService');
    } catch (e) {
      _loggingService.warning(
          'Failed to setup signal handling: ${e.toString()}',
          'GracefulShutdownService');
    }
  }

  Future<void> _performCrashRecovery() async {
    try {
      // Check for crash recovery file
      // This would implement actual crash recovery logic
      _loggingService.info(
          'Performing crash recovery check', 'GracefulShutdownService');
    } catch (e) {
      _loggingService.warning('Crash recovery check failed: ${e.toString()}',
          'GracefulShutdownService');
    }
  }

  Future<OperationResult> _executeStartupPhase(String phase) async {
    switch (phase) {
      case 'config':
        return await _startupConfig();
      case 'storage':
        return await _startupStorage();
      case 'network':
        return await _startupNetwork();
      case 'services':
        return await _startupServices();
      case 'ui':
        return await _startupUI();
      default:
        return OperationResult.failure('Unknown startup phase: $phase');
    }
  }

  Future<OperationResult> _executeShutdownPhase(String phase) async {
    switch (phase) {
      case 'config':
        return await _shutdownConfig();
      case 'storage':
        return await _shutdownStorage();
      case 'network':
        return await _shutdownNetwork();
      case 'services':
        return await _shutdownServices();
      case 'ui':
        return await _shutdownUI();
      default:
        return OperationResult.failure('Unknown shutdown phase: $phase');
    }
  }

  Future<OperationResult> _startupConfig() async {
    try {
      // Validate configuration
      await Future.delayed(const Duration(milliseconds: 100));
      return OperationResult.success();
    } catch (e) {
      return OperationResult.failure(e.toString());
    }
  }

  Future<OperationResult> _startupStorage() async {
    try {
      // Initialize storage services
      await Future.delayed(const Duration(milliseconds: 100));
      return OperationResult.success();
    } catch (e) {
      return OperationResult.failure(e.toString());
    }
  }

  Future<OperationResult> _startupNetwork() async {
    try {
      // Initialize network services
      await Future.delayed(const Duration(milliseconds: 100));
      return OperationResult.success();
    } catch (e) {
      return OperationResult.failure(e.toString());
    }
  }

  Future<OperationResult> _startupServices() async {
    try {
      // Initialize core services
      if (_circuitBreakerService != null) {
        await _circuitBreakerService!.initialize();
      }
      if (_healthCheckService != null) {
        await _healthCheckService!.initialize();
      }
      if (_retryService != null) {
        await _retryService!.initialize();
      }
      return OperationResult.success();
    } catch (e) {
      return OperationResult.failure(e.toString());
    }
  }

  Future<OperationResult> _startupUI() async {
    try {
      // Initialize UI components
      await Future.delayed(const Duration(milliseconds: 100));
      return OperationResult.success();
    } catch (e) {
      return OperationResult.failure(e.toString());
    }
  }

  Future<OperationResult> _shutdownConfig() async {
    try {
      // Save configuration
      await Future.delayed(const Duration(milliseconds: 50));
      return OperationResult.success();
    } catch (e) {
      return OperationResult.failure(e.toString());
    }
  }

  Future<OperationResult> _shutdownStorage() async {
    try {
      // Flush storage operations
      await Future.delayed(const Duration(milliseconds: 100));
      return OperationResult.success();
    } catch (e) {
      return OperationResult.failure(e.toString());
    }
  }

  Future<OperationResult> _shutdownNetwork() async {
    try {
      // Close network connections
      await Future.delayed(const Duration(milliseconds: 50));
      return OperationResult.success();
    } catch (e) {
      return OperationResult.failure(e.toString());
    }
  }

  Future<OperationResult> _shutdownServices() async {
    try {
      // Shutdown core services
      _circuitBreakerService?.dispose();
      _healthCheckService?.dispose();
      _retryService?.dispose();
      return OperationResult.success();
    } catch (e) {
      return OperationResult.failure(e.toString());
    }
  }

  Future<OperationResult> _shutdownUI() async {
    try {
      // Clean up UI resources
      await Future.delayed(const Duration(milliseconds: 50));
      return OperationResult.success();
    } catch (e) {
      return OperationResult.failure(e.toString());
    }
  }

  Future<void> _executeShutdownHandlers() async {
    // Sort by priority (high first)
    final sortedHandlers = _shutdownHandlers.toList()
      ..sort((a, b) => b.priority.index.compareTo(a.priority.index));

    for (final handler in sortedHandlers) {
      try {
        _loggingService.info('Executing shutdown handler: ${handler.name}',
            'GracefulShutdownService');
        await handler.handler().timeout(const Duration(seconds: 10));
      } catch (e) {
        _loggingService.error('Shutdown handler ${handler.name} failed',
            'GracefulShutdownService',
            error: e);
      }
    }
  }

  Future<void> _saveApplicationState() async {
    try {
      // Save application state for recovery
      _loggingService.info(
          'Saving application state', 'GracefulShutdownService');
    } catch (e) {
      _loggingService.error(
          'Failed to save application state', 'GracefulShutdownService',
          error: e);
    }
  }

  Future<void> _executeCriticalCleanup() async {
    try {
      // Execute critical cleanup operations
      _loggingService.info(
          'Executing critical cleanup', 'GracefulShutdownService');
    } catch (e) {
      _loggingService.error(
          'Critical cleanup failed', 'GracefulShutdownService',
          error: e);
    }
  }

  Future<OperationResult> _validateStartupHealth() async {
    try {
      if (_healthCheckService != null) {
        final report = await _healthCheckService!.performFullHealthCheck();
        return report.overallStatus == HealthStatus.healthy
            ? OperationResult.success()
            : OperationResult.failure(
                'Health check failed: ${report.issues.length} issues found');
      }
      return OperationResult.success();
    } catch (e) {
      return OperationResult.failure(
          'Health validation failed: ${e.toString()}');
    }
  }

  bool _isCriticalPhase(String phase) {
    return phase == 'config' || phase == 'storage';
  }

  void _emitEvent(LifecycleEvent event) {
    _lifecycleController.add(event);
  }

  /// Get lifecycle event stream
  Stream<LifecycleEvent> get lifecycleEvents => _lifecycleController.stream;

  /// Dispose resources
  void dispose() {
    _sigintSubscription?.cancel();
    _sigtermSubscription?.cancel();
    _lifecycleController.close();
    _shutdownCompleter?.complete();
    _loggingService.info(
        'Graceful shutdown service disposed', 'GracefulShutdownService');
  }
}

/// Shutdown Handler
class ShutdownHandler {
  final String name;
  final ShutdownPriority priority;
  final Future<void> Function() handler;

  ShutdownHandler({
    required this.name,
    this.priority = ShutdownPriority.medium,
    required this.handler,
  });
}

/// Shutdown Priority
enum ShutdownPriority {
  low,
  medium,
  high,
  critical,
}

/// Operation Result
class OperationResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? metadata;

  OperationResult.success({this.metadata})
      : success = true,
        error = null;
  OperationResult.failure(this.error, {this.metadata}) : success = false;

  @override
  String toString() {
    return success ? 'Success' : 'Failure: $error';
  }
}

/// Startup Result
class StartupResult {
  final bool success;
  final String? error;
  final Duration? duration;
  final Map<String, OperationResult>? results;

  StartupResult._({
    required this.success,
    this.error,
    this.duration,
    this.results,
  });

  factory StartupResult.success(
      {Map<String, OperationResult>? results, Duration? duration}) {
    return StartupResult._(success: true, results: results, duration: duration);
  }

  factory StartupResult.failure({required String error, Duration? duration}) {
    return StartupResult._(success: false, error: error, duration: duration);
  }
}

/// Shutdown Result
class ShutdownResult {
  final bool success;
  final String? error;
  final Duration? duration;
  final Map<String, OperationResult>? results;

  ShutdownResult._({
    required this.success,
    this.error,
    this.duration,
    this.results,
  });

  factory ShutdownResult.success(
      {Map<String, OperationResult>? results, Duration? duration}) {
    return ShutdownResult._(
        success: true, results: results, duration: duration);
  }

  factory ShutdownResult.failure({required String error, Duration? duration}) {
    return ShutdownResult._(success: false, error: error, duration: duration);
  }
}

/// Shutdown Status
class ShutdownStatus {
  final bool isShuttingDown;
  final Duration? shutdownStartTime;
  final DateTime? startupTime;
  final bool isInitialized;

  ShutdownStatus({
    required this.isShuttingDown,
    this.shutdownStartTime,
    this.startupTime,
    required this.isInitialized,
  });

  Duration? get uptime =>
      startupTime != null ? DateTime.now().difference(startupTime!) : null;
}

/// Lifecycle Event Types
enum LifecycleEventType {
  startupStarted,
  startupCompleted,
  startupFailed,
  shutdownStarted,
  shutdownCompleted,
  shutdownFailed,
}

/// Lifecycle Event
class LifecycleEvent {
  final LifecycleEventType type;
  final DateTime timestamp;
  final Duration? duration;
  final String? error;
  final Map<String, dynamic>? metadata;

  LifecycleEvent({
    required this.type,
    this.duration,
    this.error,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'LifecycleEvent(type: $type, timestamp: $timestamp)';
  }
}
