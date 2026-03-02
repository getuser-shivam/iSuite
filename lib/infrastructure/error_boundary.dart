import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? errorWidget;
  final Function(String)? onError;
  final bool enableCrashReporting;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorWidget,
    this.onError,
    this.enableCrashReporting = true,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  String? _errorMessage;
  String? _errorDetails;
  DateTime? _errorTime;
  int _errorCount = 0;

  @override
  void initState() {
    super.initState();
    // Set up global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleError(details);
    };

    // Handle platform errors (Android/iOS)
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true;
    };
  }

  void _handleError(FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);

    final errorInfo = _extractErrorInfo(details);

    setState(() {
      _hasError = true;
      _errorMessage = errorInfo['message'];
      _errorDetails = errorInfo['details'];
      _errorTime = DateTime.now();
      _errorCount++;
    });

    // Log error
    _logError(errorInfo);

    // Notify parent
    widget.onError?.call(errorInfo['message'] ?? 'Unknown error');
  }

  bool _handlePlatformError(Object error, StackTrace stack) {
    final errorInfo = {
      'message': error.toString(),
      'details': stack.toString(),
      'type': 'platform_error',
    };

    setState(() {
      _hasError = true;
      _errorMessage = error.toString();
      _errorDetails = stack.toString();
      _errorTime = DateTime.now();
      _errorCount++;
    });

    _logError(errorInfo);
    widget.onError?.call(error.toString());

    return true;
  }

  Map<String, String> _extractErrorInfo(FlutterErrorDetails details) {
    return {
      'message': details.exceptionAsString(),
      'details': details.stack.toString(),
      'type': 'flutter_error',
      'library': details.library ?? 'unknown',
      'context': details.context?.toString() ?? 'none',
    };
  }

  Future<void> _logError(Map<String, String> errorInfo) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logFile = File('${directory.path}/error_log.txt');

      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final logEntry = '''
[$timestamp] ERROR #$_errorCount
Type: ${errorInfo['type']}
Message: ${errorInfo['message']}
Details: ${errorInfo['details']}
${errorInfo['library'] != null ? 'Library: ${errorInfo['library']}' : ''}
${errorInfo['context'] != null ? 'Context: ${errorInfo['context']}' : ''}
---
''';

      await logFile.writeAsString(logEntry, mode: FileMode.append);

      // Also log to console
      debugPrint('ERROR LOGGED: ${errorInfo['message']}');
    } catch (e) {
      debugPrint('Failed to log error: $e');
    }
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _errorDetails = null;
      _errorTime = null;
    });
  }

  void _resetErrorCount() {
    setState(() {
      _errorCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ?? _buildEnhancedErrorWidget();
    }

    return widget.child;
  }

  Widget _buildEnhancedErrorWidget() {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Application Error'),
          backgroundColor: Colors.red,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _retry,
              tooltip: 'Retry',
            ),
            IconButton(
              icon: const Icon(Icons.restore),
              onPressed: _resetErrorCount,
              tooltip: 'Reset Counter',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 20),
              const Text(
                'Oops! Something went wrong.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Error Count: $_errorCount',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_errorTime != null) ...[
                const SizedBox(height: 5),
                Text(
                  'Time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_errorTime!)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Error Message:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _errorMessage ?? 'An unexpected error occurred.',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_errorDetails != null && _errorDetails!.isNotEmpty) ...[
                const Text(
                  'Technical Details:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _errorDetails!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Application'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Could implement feedback/reporting here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error reported (feature not implemented)'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.report),
                    label: const Text('Report Issue'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'If this error persists, try restarting the application or contact support.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
