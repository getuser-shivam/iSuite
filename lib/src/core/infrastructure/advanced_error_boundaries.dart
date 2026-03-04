import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logging/logging_service.dart';
import '../enhanced_error_handling_service.dart';

/// Comprehensive Error Boundaries and Fallback UI System
///
/// Features:
/// - Hierarchical error boundaries for different app sections
/// - Automatic error recovery and retry mechanisms
/// - Graceful fallback UI components
/// - Error reporting and analytics integration
/// - User-friendly error messages and recovery options
/// - Offline and network error handling
/// - State preservation during error recovery

/// Root Error Boundary Widget
class AppErrorBoundary extends StatefulWidget {
  final Widget child;
  final ErrorBoundaryConfig config;

  const AppErrorBoundary({
    super.key,
    required this.child,
    this.config = const ErrorBoundaryConfig(),
  });

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  ErrorDetails? _currentError;
  bool _hasError = false;
  int _errorCount = 0;

  @override
  void didUpdateWidget(AppErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset error state when configuration changes
    if (widget.config != oldWidget.config) {
      _hasError = false;
      _currentError = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && _currentError != null) {
      return ErrorFallbackUI(
        error: _currentError!,
        config: widget.config,
        onRetry: _handleRetry,
        onReport: _handleReport,
        onDismiss: _handleDismiss,
      );
    }

    return ErrorBoundary(
      fallbackBuilder: (context, error, stackTrace) {
        _handleError(error, stackTrace);
        return ErrorFallbackUI(
          error: _currentError!,
          config: widget.config,
          onRetry: _handleRetry,
          onReport: _handleReport,
          onDismiss: _handleDismiss,
        );
      },
      child: widget.child,
    );
  }

  void _handleError(Object error, StackTrace stackTrace) {
    _errorCount++;
    _hasError = true;

    _currentError = ErrorDetails(
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      context: 'App Root',
      userId: 'unknown', // Would get from auth service
      deviceInfo: _getDeviceInfo(),
      appVersion: '2.0.0', // Would get from package info
    );

    // Log error
    final loggingService = LoggingService();
    loggingService.error(
      'App Error Boundary caught error',
      'AppErrorBoundary',
      error: error,
      stackTrace: stackTrace,
    );

    // Report error if auto-reporting is enabled
    if (widget.config.enableAutoReporting) {
      _reportError(_currentError!);
    }
  }

  void _handleRetry() {
    setState(() {
      _hasError = false;
      _currentError = null;
    });
  }

  void _handleReport() {
    if (_currentError != null) {
      _reportError(_currentError!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error report sent. Thank you!')),
      );
    }
  }

  void _handleDismiss() {
    setState(() {
      _hasError = false;
      _currentError = null;
    });
  }

  void _reportError(ErrorDetails error) {
    // Implement error reporting logic
    // This could send to analytics service, crash reporting service, etc.
    final errorHandlingService = EnhancedErrorHandlingService();
    errorHandlingService.reportError(
      error: error.error,
      stackTrace: error.stackTrace,
      context: error.context,
      additionalData: {
        'deviceInfo': error.deviceInfo,
        'appVersion': error.appVersion,
        'userId': error.userId,
      },
    );
  }

  Map<String, dynamic> _getDeviceInfo() {
    return {
      'platform': 'unknown', // Would use device_info_plus
      'version': 'unknown',
      'model': 'unknown',
    };
  }
}

/// Screen-Level Error Boundary
class ScreenErrorBoundary extends StatefulWidget {
  final Widget child;
  final String screenName;
  final ErrorBoundaryConfig config;
  final Widget Function(BuildContext, Object, StackTrace)? fallbackBuilder;

  const ScreenErrorBoundary({
    super.key,
    required this.child,
    required this.screenName,
    this.config = const ErrorBoundaryConfig(),
    this.fallbackBuilder,
  });

  @override
  State<ScreenErrorBoundary> createState() => _ScreenErrorBoundaryState();
}

class _ScreenErrorBoundaryState extends State<ScreenErrorBoundary> {
  ErrorDetails? _currentError;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError && _currentError != null) {
      if (widget.fallbackBuilder != null) {
        return widget.fallbackBuilder!(
            context, _currentError!.error, _currentError!.stackTrace);
      }

      return ScreenErrorFallbackUI(
        screenName: widget.screenName,
        error: _currentError!,
        config: widget.config,
        onRetry: _handleRetry,
        onGoBack: _handleGoBack,
      );
    }

    return ErrorBoundary(
      fallbackBuilder: (context, error, stackTrace) {
        _handleError(error, stackTrace);
        if (widget.fallbackBuilder != null) {
          return widget.fallbackBuilder!(context, error, stackTrace);
        }
        return ScreenErrorFallbackUI(
          screenName: widget.screenName,
          error: _currentError!,
          config: widget.config,
          onRetry: _handleRetry,
          onGoBack: _handleGoBack,
        );
      },
      child: widget.child,
    );
  }

  void _handleError(Object error, StackTrace stackTrace) {
    _hasError = true;

    _currentError = ErrorDetails(
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      context: widget.screenName,
      userId: 'unknown',
      deviceInfo: {},
      appVersion: '2.0.0',
    );

    // Log screen-specific error
    final loggingService = LoggingService();
    loggingService.error(
      'Screen error boundary caught error on ${widget.screenName}',
      'ScreenErrorBoundary',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _handleRetry() {
    setState(() {
      _hasError = false;
      _currentError = null;
    });
  }

  void _handleGoBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // Reset to home screen
      Navigator.of(context).pushReplacementNamed('/');
    }
  }
}

/// Component-Level Error Boundary
class ComponentErrorBoundary extends StatefulWidget {
  final Widget child;
  final String componentName;
  final Widget? fallbackWidget;
  final bool showErrorDetails;

  const ComponentErrorBoundary({
    super.key,
    required this.child,
    required this.componentName,
    this.fallbackWidget,
    this.showErrorDetails = false,
  });

  @override
  State<ComponentErrorBoundary> createState() => _ComponentErrorBoundaryState();
}

class _ComponentErrorBoundaryState extends State<ComponentErrorBoundary> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      if (widget.fallbackWidget != null) {
        return widget.fallbackWidget!;
      }

      return ComponentErrorFallbackUI(
        componentName: widget.componentName,
        showErrorDetails: widget.showErrorDetails,
        onRetry: () => setState(() => _hasError = false),
      );
    }

    return ErrorBoundary(
      fallbackBuilder: (context, error, stackTrace) {
        setState(() => _hasError = true);

        final loggingService = LoggingService();
        loggingService.error(
          'Component error boundary caught error in ${widget.componentName}',
          'ComponentErrorBoundary',
          error: error,
          stackTrace: stackTrace,
        );

        if (widget.fallbackWidget != null) {
          return widget.fallbackWidget!;
        }

        return ComponentErrorFallbackUI(
          componentName: widget.componentName,
          showErrorDetails: widget.showErrorDetails,
          onRetry: () => setState(() => _hasError = false),
        );
      },
      child: widget.child,
    );
  }
}

/// Network-Aware Error Boundary
class NetworkErrorBoundary extends ConsumerStatefulWidget {
  final Widget child;
  final Widget? offlineWidget;
  final Widget? errorWidget;

  const NetworkErrorBoundary({
    super.key,
    required this.child,
    this.offlineWidget,
    this.errorWidget,
  });

  @override
  ConsumerState<NetworkErrorBoundary> createState() =>
      _NetworkErrorBoundaryState();
}

class _NetworkErrorBoundaryState extends ConsumerState<NetworkErrorBoundary> {
  @override
  Widget build(BuildContext context) {
    final networkStatus = ref.watch(networkStatusProvider);

    return networkStatus.when(
      data: (status) {
        if (status == NetworkStatus.offline) {
          return widget.offlineWidget ?? const NetworkOfflineUI();
        }
        return widget.child;
      },
      error: (error, stackTrace) {
        return widget.errorWidget ?? NetworkErrorUI(error: error);
      },
      loading: () => const CircularProgressIndicator(),
    );
  }
}

/// Error Boundary Configuration
class ErrorBoundaryConfig {
  final bool enableAutoReporting;
  final bool showErrorDetails;
  final bool enableRetry;
  final int maxRetries;
  final Duration retryDelay;
  final bool enableOfflineMode;

  const ErrorBoundaryConfig({
    this.enableAutoReporting = true,
    this.showErrorDetails = false,
    this.enableRetry = true,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.enableOfflineMode = true,
  });
}

/// Error Details
class ErrorDetails {
  final Object error;
  final StackTrace stackTrace;
  final DateTime timestamp;
  final String context;
  final String userId;
  final Map<String, dynamic> deviceInfo;
  final String appVersion;

  ErrorDetails({
    required this.error,
    required this.stackTrace,
    required this.timestamp,
    required this.context,
    required this.userId,
    required this.deviceInfo,
    required this.appVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'error': error.toString(),
      'stackTrace': stackTrace.toString(),
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'userId': userId,
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
    };
  }
}

/// Error Fallback UI Components

/// Main App Error Fallback UI
class ErrorFallbackUI extends StatelessWidget {
  final ErrorDetails error;
  final ErrorBoundaryConfig config;
  final VoidCallback onRetry;
  final VoidCallback onReport;
  final VoidCallback onDismiss;

  const ErrorFallbackUI({
    super.key,
    required this.error,
    required this.config,
    required this.onRetry,
    required this.onReport,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We encountered an unexpected error. Our team has been notified.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (config.showErrorDetails) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error Details:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.error.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (config.enableRetry)
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: onReport,
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Report Issue'),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: onDismiss,
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen Error Fallback UI
class ScreenErrorFallbackUI extends StatelessWidget {
  final String screenName;
  final ErrorDetails error;
  final ErrorBoundaryConfig config;
  final VoidCallback onRetry;
  final VoidCallback onGoBack;

  const ScreenErrorFallbackUI({
    super.key,
    required this.screenName,
    required this.error,
    required this.config,
    required this.onRetry,
    required this.onGoBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Error - $screenName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onGoBack,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                '$screenName encountered an error',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'This screen is temporarily unavailable.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: onGoBack,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Component Error Fallback UI
class ComponentErrorFallbackUI extends StatelessWidget {
  final String componentName;
  final bool showErrorDetails;
  final VoidCallback onRetry;

  const ComponentErrorFallbackUI({
    super.key,
    required this.componentName,
    required this.showErrorDetails,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.error),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.error,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '$componentName Error',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This component encountered an error and cannot be displayed.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                textStyle: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Network Offline UI
class NetworkOfflineUI extends StatelessWidget {
  const NetworkOfflineUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'No Internet Connection',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Please check your internet connection and try again.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  // Trigger connectivity check
                  // This would integrate with connectivity_plus
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Check Connection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Network Error UI
class NetworkErrorUI extends StatelessWidget {
  final Object error;

  const NetworkErrorUI({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Network Error',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to connect to the server. Please try again later.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  // Retry network operation
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Async Error Boundary for Future Builders
class AsyncErrorBoundary extends StatelessWidget {
  final AsyncSnapshot snapshot;
  final Widget Function(BuildContext) loadingBuilder;
  final Widget Function(BuildContext, Object, StackTrace) errorBuilder;
  final Widget Function(BuildContext, dynamic) dataBuilder;

  const AsyncErrorBoundary({
    super.key,
    required this.snapshot,
    required this.loadingBuilder,
    required this.errorBuilder,
    required this.dataBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return loadingBuilder(context);
    }

    if (snapshot.hasError) {
      return errorBuilder(context, snapshot.error!, snapshot.stackTrace!);
    }

    if (snapshot.hasData) {
      return dataBuilder(context, snapshot.data);
    }

    return loadingBuilder(context);
  }
}

/// Error Boundary Riverpod Providers
final errorBoundaryConfigProvider = Provider<ErrorBoundaryConfig>((ref) {
  return const ErrorBoundaryConfig();
});

final errorReportingProvider = Provider<ErrorReportingService>((ref) {
  return ErrorReportingService();
});

/// Error Reporting Service
class ErrorReportingService {
  final LoggingService _logger = LoggingService();

  Future<void> reportError({
    required Object error,
    required StackTrace stackTrace,
    required String context,
    Map<String, dynamic>? additionalData,
  }) async {
    // Log the error
    _logger.error(
      'Error reported from $context',
      'ErrorReportingService',
      error: error,
      stackTrace: stackTrace,
    );

    // Here you would integrate with error reporting services like:
    // - Firebase Crashlytics
    // - Sentry
    // - Bugsnag
    // - Rollbar
    // - Custom error reporting service

    // For now, just log the error with additional context
    final errorData = {
      'error': error.toString(),
      'stackTrace': stackTrace.toString(),
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
      'additionalData': additionalData ?? {},
    };

    _logger.info('Error report data: $errorData', 'ErrorReportingService');
  }

  Future<void> reportNonFatalError({
    required String message,
    required String context,
    Map<String, dynamic>? additionalData,
  }) async {
    _logger.warning(
      'Non-fatal error reported from $context: $message',
      'ErrorReportingService',
    );

    final errorData = {
      'message': message,
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
      'additionalData': additionalData ?? {},
    };

    _logger.info('Non-fatal error report: $errorData', 'ErrorReportingService');
  }
}

/// Error Recovery Strategies
abstract class ErrorRecoveryStrategy {
  Future<bool> canRecover(Object error);
  Future<bool> recover(Object error, BuildContext context);
}

/// Automatic Retry Strategy
class RetryRecoveryStrategy implements ErrorRecoveryStrategy {
  final int maxRetries;
  final Duration delay;

  RetryRecoveryStrategy({
    this.maxRetries = 3,
    this.delay = const Duration(seconds: 1),
  });

  @override
  Future<bool> canRecover(Object error) async {
    // Check if error is retryable (network errors, temporary failures)
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('temporary');
  }

  @override
  Future<bool> recover(Object error, BuildContext context) async {
    // Show retry dialog
    final shouldRetry = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Error'),
        content: const Text('Would you like to retry the operation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );

    return shouldRetry ?? false;
  }
}

/// Offline Mode Strategy
class OfflineRecoveryStrategy implements ErrorRecoveryStrategy {
  @override
  Future<bool> canRecover(Object error) async {
    // Check if error is network-related
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('offline');
  }

  @override
  Future<bool> recover(Object error, BuildContext context) async {
    // Show offline mode dialog
    final enableOffline = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline Mode Available'),
        content: const Text('Would you like to continue in offline mode?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enable Offline Mode'),
          ),
        ],
      ),
    );

    return enableOffline ?? false;
  }
}

/// Error Recovery Manager
class ErrorRecoveryManager {
  final List<ErrorRecoveryStrategy> _strategies = [
    RetryRecoveryStrategy(),
    OfflineRecoveryStrategy(),
  ];

  Future<bool> attemptRecovery(Object error, BuildContext context) async {
    for (final strategy in _strategies) {
      if (await strategy.canRecover(error)) {
        final recovered = await strategy.recover(error, context);
        if (recovered) {
          return true;
        }
      }
    }

    return false;
  }
}
