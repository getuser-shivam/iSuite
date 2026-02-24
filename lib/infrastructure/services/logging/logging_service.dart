import 'dart:developer' as developer;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// Comprehensive logging service for iSuite
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  static const String _logFileName = 'isuite.log';
  static const int _maxLogLines = 10000;
  static const int _maxFileSizeMB = 10;

  File? _logFile;
  final List<String> _logBuffer = [];
  bool _isInitialized = false;

  /// Initialize the logging service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/$_logFileName');
      _isInitialized = true;

      // Clean up old logs if file is too large
      await _cleanupOldLogs();

      log(LogLevel.INFO, 'LoggingService initialized', 'LoggingService');
    } catch (e) {
      developer.log('Failed to initialize logging: $e', name: 'LoggingService');
    }
  }

  /// Log a message with specified level and category
  void log(LogLevel level, String message, String category,
      {Object? error, StackTrace? stackTrace}) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
    final logEntry = '[$timestamp] ${level.name} [$category] $message';

    // Add error details if provided
    if (error != null) {
      final errorEntry = '[$timestamp] ${level.name} [$category] Error: $error';
      _logBuffer.add(errorEntry);

      if (stackTrace != null) {
        final stackEntry = '[$timestamp] ${level.name} [$category] StackTrace: $stackTrace';
        _logBuffer.add(stackEntry);
      }
    }

    _logBuffer.add(logEntry);

    // Also log to console for development
    developer.log(message, name: category, error: error, stackTrace: stackTrace);

    // Write to file asynchronously
    _writeToFile();
  }

  /// Convenience methods for different log levels
  void info(String message, String category) => log(LogLevel.INFO, message, category);
  void warning(String message, String category) => log(LogLevel.WARNING, message, category);
  void error(String message, String category, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.ERROR, message, category, error: error, stackTrace: stackTrace);
  void debug(String message, String category) => log(LogLevel.DEBUG, message, category);

  /// Log performance metrics
  void logPerformance(String operation, Duration duration, String category) {
    final message = 'Performance: $operation completed in ${duration.inMilliseconds}ms';
    log(LogLevel.INFO, message, category);
  }

  /// Log user action for analytics
  void logUserAction(String action, String category, {Map<String, dynamic>? metadata}) {
    final message = 'User Action: $action${metadata != null ? ' - $metadata' : ''}';
    log(LogLevel.INFO, message, category);
  }

  /// Get recent logs for debugging
  Future<List<String>> getRecentLogs({int count = 100}) async {
    if (!_isInitialized) return [];

    try {
      if (await _logFile!.exists()) {
        final lines = await _logFile!.readAsLines();
        return lines.reversed.take(count).toList().reversed.toList();
      }
    } catch (e) {
      developer.log('Failed to read logs: $e', name: 'LoggingService');
    }

    return _logBuffer.reversed.take(count).toList().reversed.toList();
  }

  /// Clear all logs
  Future<void> clearLogs() async {
    _logBuffer.clear();

    if (_isInitialized && await _logFile!.exists()) {
      await _logFile!.writeAsString('');
    }

    log(LogLevel.INFO, 'Logs cleared', 'LoggingService');
  }

  /// Export logs to a file for sharing
  Future<String?> exportLogs() async {
    if (!_isInitialized) return null;

    try {
      final directory = await getTemporaryDirectory();
      final exportFile = File('${directory.path}/isuite_logs_${DateTime.now().millisecondsSinceEpoch}.txt');

      final allLogs = await getRecentLogs(count: _maxLogLines);
      await exportFile.writeAsString(allLogs.join('\n'));

      return exportFile.path;
    } catch (e) {
      log(LogLevel.ERROR, 'Failed to export logs: $e', 'LoggingService');
      return null;
    }
  }

  /// Write buffered logs to file
  Future<void> _writeToFile() async {
    if (!_isInitialized || _logBuffer.isEmpty) return;

    try {
      final content = _logBuffer.join('\n') + '\n';
      await _logFile!.writeAsString(content, mode: FileMode.append);
      _logBuffer.clear();

      // Check file size and rotate if needed
      await _rotateLogFileIfNeeded();
    } catch (e) {
      developer.log('Failed to write to log file: $e', name: 'LoggingService');
    }
  }

  /// Clean up old logs and rotate files
  Future<void> _cleanupOldLogs() async {
    if (!_isInitialized) return;

    try {
      final fileSize = await _logFile!.length();
      final maxSizeBytes = _maxFileSizeMB * 1024 * 1024;

      if (fileSize > maxSizeBytes) {
        // Rotate log file
        final backupFile = File('${_logFile!.path}.old');
        if (await backupFile.exists()) {
          await backupFile.delete();
        }

        await _logFile!.copy(backupFile.path);
        await _logFile!.writeAsString('');
      }
    } catch (e) {
      developer.log('Failed to cleanup logs: $e', name: 'LoggingService');
    }
  }

  /// Rotate log file if it gets too large
  Future<void> _rotateLogFileIfNeeded() async {
    if (!_isInitialized) return;

    try {
      final lines = await _logFile!.readAsLines();
      if (lines.length > _maxLogLines) {
        // Keep only the most recent half of the logs
        final keepLines = lines.sublist(lines.length - (_maxLogLines ~/ 2));
        await _logFile!.writeAsString(keepLines.join('\n') + '\n');
      }
    } catch (e) {
      developer.log('Failed to rotate log file: $e', name: 'LoggingService');
    }
  }
}

/// Log levels for different types of messages
enum LogLevel {
  DEBUG,
  INFO,
  WARNING,
  ERROR,
}

/// Enhanced error handling with logging
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final LoggingService _logger = LoggingService();

  /// Handle and log an error
  void handleError(Object error, StackTrace stackTrace, String context,
      {String? userMessage, bool showToUser = true}) {

    // Log the error
    _logger.error('Unhandled error in $context: $error', 'ErrorHandler',
        error: error, stackTrace: stackTrace);

    // Could show user-friendly message here
    if (showToUser && userMessage != null) {
      // Implementation for showing error to user
      _logger.info('User notified of error: $userMessage', 'ErrorHandler');
    }
  }

  /// Handle async errors
  void handleAsyncError(Object error, StackTrace stackTrace, String context) {
    handleError(error, stackTrace, context);
  }

  /// Log performance issues
  void logPerformanceIssue(String operation, Duration duration, String threshold) {
    _logger.warning('Performance issue: $operation took ${duration.inMilliseconds}ms (threshold: $threshold)',
        'PerformanceMonitor');
  }
}

/// Performance monitoring utility
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final LoggingService _logger = LoggingService();
  final Map<String, DateTime> _startTimes = {};

  /// Start timing an operation
  void startTiming(String operationId) {
    _startTimes[operationId] = DateTime.now();
  }

  /// End timing and log the result
  void endTiming(String operationId, {String? category = 'Performance'}) {
    final startTime = _startTimes.remove(operationId);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _logger.logPerformance(operationId, duration, category ?? 'Performance');
    }
  }

  /// Time an async operation
  Future<T> timeAsync<T>(String operationId, Future<T> Function() operation,
      {String? category = 'Performance'}) async {
    startTiming(operationId);
    try {
      final result = await operation();
      endTiming(operationId, category: category);
      return result;
    } catch (e) {
      endTiming(operationId, category: category);
      rethrow;
    }
  }
}
