import 'package:flutter/material.dart';

/// Error Boundary Widget for comprehensive error handling
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context, FlutterErrorDetails errorDetails)? fallbackBuilder;
  final void Function(FlutterErrorDetails errorDetails)? onError;
  final bool reportErrors;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallbackBuilder,
    this.onError,
    this.reportErrors = true,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    // Set up global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleError(details);
    };

    // Set up platform-specific error handling
    WidgetsFlutterBinding.ensureInitialized();

    // Handle async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      final details = FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'platform_dispatcher',
      );
      _handleError(details);
      return true;
    };
  }

  void _handleError(FlutterErrorDetails details) {
    setState(() {
      _errorDetails = details;
      _hasError = true;
    });

    // Call custom error handler
    widget.onError?.call(details);

    // Report error if enabled
    if (widget.reportErrors) {
      _reportError(details);
    }

    // Log error details
    debugPrint('Error Boundary caught error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  }

  void _reportError(FlutterErrorDetails details) {
    // In a real app, you would send this to a crash reporting service
    // like Sentry, Firebase Crashlytics, etc.

    // For now, just log to console
    debugPrint('Error reported: ${details.exception}');
    debugPrint('Library: ${details.library}');
    debugPrint('Context: ${details.context}');
    debugPrint('Stack: ${details.stack}');

    // You could send to a remote service here:
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
    // Sentry.captureException(error, stackTrace: stackTrace);
  }

  void _resetError() {
    setState(() {
      _errorDetails = null;
      _hasError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && _errorDetails != null) {
      // Use custom fallback builder if provided
      if (widget.fallbackBuilder != null) {
        return widget.fallbackBuilder!(context, _errorDetails!);
      }

      // Default error UI
      return _buildDefaultErrorUI();
    }

    // Wrap child in error zone
    return ErrorWidget.builder = (FlutterErrorDetails details) {
      _handleError(details);
      return _buildDefaultErrorUI();
    };

    // Return child if no error
    return widget.child;
  }

  Widget _buildDefaultErrorUI() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Error'),
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 72,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'The application encountered an unexpected error.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_errorDetails != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorDetails!.exception.toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _resetError,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Report error
                      if (_errorDetails != null) {
                        _reportError(_errorDetails!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error reported')),
                        );
                      }
                    },
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Report Error'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
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

/// Performance Monitor Widget for real-time performance tracking
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool enableLogging;
  final Duration monitoringInterval;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.enableLogging = true,
    this.monitoringInterval = const Duration(seconds: 5),
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  // Performance metrics
  int _frameCount = 0;
  DateTime? _lastFrameTime;
  double _averageFrameTime = 0;
  double _fps = 0;

  // Memory and resource metrics
  int _memoryUsage = 0;
  double _cpuUsage = 0;

  // Performance history for analysis
  final List<double> _frameTimeHistory = [];
  final List<double> _fpsHistory = [];
  static const int _maxHistorySize = 100;

  @override
  void initState() {
    super.initState();
    _startPerformanceMonitoring();
  }

  @override
  void dispose() {
    // Clean up any resources
    super.dispose();
  }

  void _startPerformanceMonitoring() {
    // Monitor frame callbacks
    WidgetsBinding.instance.addPostFrameCallback(_onFrameCallback);

    // Monitor system resources periodically
    _startSystemResourceMonitoring();
  }

  void _onFrameCallback(Duration timestamp) {
    final now = DateTime.now();

    if (_lastFrameTime != null) {
      final frameTime = now.difference(_lastFrameTime!).inMicroseconds / 1000.0; // ms
      _frameCount++;

      // Calculate running average
      _averageFrameTime = (_averageFrameTime * (_frameCount - 1) + frameTime) / _frameCount;

      // Calculate FPS
      _fps = 1000.0 / frameTime;

      // Store in history
      _frameTimeHistory.add(frameTime);
      _fpsHistory.add(_fps);

      // Limit history size
      if (_frameTimeHistory.length > _maxHistorySize) {
        _frameTimeHistory.removeAt(0);
        _fpsHistory.removeAt(0);
      }

      // Log performance if enabled
      if (widget.enableLogging && _frameCount % 60 == 0) { // Log every 60 frames
        _logPerformanceMetrics();
      }

      // Check for performance issues
      _checkPerformanceHealth();
    }

    _lastFrameTime = now;

    // Schedule next callback
    WidgetsBinding.instance.addPostFrameCallback(_onFrameCallback);
  }

  void _startSystemResourceMonitoring() async {
    // Note: In a real app, you would use platform-specific APIs
    // or packages like 'system_info' for accurate system metrics
    // This is a simplified implementation

    while (mounted) {
      await Future.delayed(widget.monitoringInterval);

      // Simulate system resource monitoring
      // In real implementation, use platform channels or packages
      setState(() {
        // Mock values - replace with real system monitoring
        _memoryUsage = (50 + (DateTime.now().millisecondsSinceEpoch % 50)).toInt(); // MB
        _cpuUsage = 10 + (DateTime.now().millisecondsSinceEpoch % 30).toDouble(); // %
      });
    }
  }

  void _logPerformanceMetrics() {
    debugPrint('Performance Metrics:');
    debugPrint('  FPS: ${_fps.toStringAsFixed(1)}');
    debugPrint('  Avg Frame Time: ${_averageFrameTime.toStringAsFixed(2)}ms');
    debugPrint('  Memory Usage: ${_memoryUsage}MB');
    debugPrint('  CPU Usage: ${_cpuUsage.toStringAsFixed(1)}%');
  }

  void _checkPerformanceHealth() {
    // Check for performance issues
    if (_fps < 30) {
      debugPrint('⚠️ Low FPS detected: ${_fps.toStringAsFixed(1)}');
      // In a real app, you might trigger performance optimizations
    }

    if (_averageFrameTime > 33) { // > 30 FPS
      debugPrint('⚠️ High frame time detected: ${_averageFrameTime.toStringAsFixed(2)}ms');
    }

    if (_memoryUsage > 200) { // Arbitrary threshold
      debugPrint('⚠️ High memory usage detected: ${_memoryUsage}MB');
    }
  }

  // Public API for accessing performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'fps': _fps,
      'averageFrameTime': _averageFrameTime,
      'memoryUsage': _memoryUsage,
      'cpuUsage': _cpuUsage,
      'frameCount': _frameCount,
      'frameTimeHistory': List<double>.from(_frameTimeHistory),
      'fpsHistory': List<double>.from(_fpsHistory),
    };
  }

  void resetMetrics() {
    setState(() {
      _frameCount = 0;
      _lastFrameTime = null;
      _averageFrameTime = 0;
      _fps = 0;
      _frameTimeHistory.clear();
      _fpsHistory.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Provide performance metrics to child widgets via InheritedWidget
    return _PerformanceMonitorProvider(
      metrics: getPerformanceMetrics(),
      resetMetrics: resetMetrics,
      child: widget.child,
    );
  }
}

/// InheritedWidget to provide performance metrics to child widgets
class _PerformanceMonitorProvider extends InheritedWidget {
  final Map<String, dynamic> metrics;
  final VoidCallback resetMetrics;

  const _PerformanceMonitorProvider({
    required this.metrics,
    required this.resetMetrics,
    required super.child,
  });

  static _PerformanceMonitorProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_PerformanceMonitorProvider>();
  }

  @override
  bool updateShouldNotify(_PerformanceMonitorProvider oldWidget) {
    return !const MapEquality().equals(metrics, oldWidget.metrics);
  }
}

/// Extension to easily access performance metrics
extension PerformanceMonitorExtension on BuildContext {
  Map<String, dynamic>? get performanceMetrics {
    return _PerformanceMonitorProvider.of(this)?.metrics;
  }

  void resetPerformanceMetrics() {
    _PerformanceMonitorProvider.of(this)?.resetMetrics();
  }
}

/// Performance Overlay Widget for debugging
class PerformanceOverlay extends StatelessWidget {
  const PerformanceOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = context.performanceMetrics;

    if (metrics == null) return const SizedBox.shrink();

    return Positioned(
      top: 50,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontFamily: 'monospace',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('FPS: ${metrics['fps'].toStringAsFixed(1)}'),
              Text('Frame Time: ${metrics['averageFrameTime'].toStringAsFixed(2)}ms'),
              Text('Memory: ${metrics['memoryUsage']}MB'),
              Text('CPU: ${metrics['cpuUsage'].toStringAsFixed(1)}%'),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: () => context.resetPerformanceMetrics(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Reset', style: TextStyle(fontSize: 8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Performance Warning Widget
class PerformanceWarning extends StatefulWidget {
  final Widget child;

  const PerformanceWarning({super.key, required this.child});

  @override
  State<PerformanceWarning> createState() => _PerformanceWarningState();
}

class _PerformanceWarningState extends State<PerformanceWarning> {
  bool _showWarning = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkPerformance();
  }

  void _checkPerformance() {
    final metrics = context.performanceMetrics;
    if (metrics != null) {
      final fps = metrics['fps'] as double;
      final shouldShow = fps < 30; // Show warning if FPS drops below 30

      if (shouldShow != _showWarning) {
        setState(() {
          _showWarning = shouldShow;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showWarning)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.red.withOpacity(0.8),
              padding: const EdgeInsets.all(8),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Performance Warning: Low FPS detected',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
