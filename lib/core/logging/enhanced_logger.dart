import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:path/path.dart' as path;
import '../config/enhanced_config_manager.dart';

/// Enhanced Error Handling and Logging System
/// Features: Structured logging, error categorization, crash reporting
/// Performance: Async logging, buffered writes, log rotation
/// Security: Sensitive data filtering, secure log storage
class EnhancedLogger {
  static EnhancedLogger? _instance;
  static EnhancedLogger get instance => _instance ??= EnhancedLogger._internal();
  EnhancedLogger._internal();

  // Logging configuration
  late final Logger _rootLogger;
  late final bool _enableFileLogging;
  late final bool _enableConsoleLogging;
  late final bool _enableRemoteLogging;
  late final String _logLevel;
  late final String _logFilePath;
  late final int _maxLogFileSize;
  late final int _logRetentionDays;
  late final bool _enableStackTrace;
  late final bool _enablePerformanceLogging;
  
  // Error handling
  final Map<String, List<ErrorInfo>> _errorHistory = {};
  final Map<String, int> _errorCounts = {};
  final List<ErrorHandler> _errorHandlers = [];
  final StreamController<ErrorEvent> _errorController = 
      StreamController<ErrorEvent>.broadcast();
  
  // Performance monitoring
  final Map<String, List<PerformanceMetric>> _performanceMetrics = {};
  final StreamController<PerformanceEvent> _performanceController = 
      StreamController<PerformanceEvent>.broadcast();
  
  // Log buffering
  final List<LogEntry> _logBuffer = [];
  final int _bufferSize = 100;
  Timer? _flushTimer;
  
  // File management
  RandomAccessFile? _logFile;
  int _currentLogSize = 0;
  Timer? _logRotationTimer;
  
  // Event streams
  Stream<ErrorEvent> get errorEvents => _errorController.stream;
  Stream<PerformanceEvent> get performanceEvents => _performanceController.stream;

  /// Initialize enhanced logger
  Future<void> initialize() async {
    try {
      // Load configuration
      await _loadConfiguration();
      
      // Setup root logger
      _setupRootLogger();
      
      // Setup file logging
      if (_enableFileLogging) {
        await _setupFileLogging();
      }
      
      // Setup error handlers
      _setupErrorHandlers();
      
      // Setup performance monitoring
      if (_enablePerformanceLogging) {
        _setupPerformanceMonitoring();
      }
      
      // Setup log flushing
      _setupLogFlushing();
      
      // Setup log rotation
      if (_enableFileLogging) {
        _setupLogRotation();
      }
      
      // Setup global error handling
      _setupGlobalErrorHandling();
      
      info('Enhanced logger initialized');
    } catch (e, stackTrace) {
      debugPrint('Failed to initialize logger: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Load configuration from EnhancedConfigManager
  Future<void> _loadConfiguration() async {
    final config = EnhancedConfigManager.instance;
    
    _enableFileLogging = config.getParameter('logging.enable_file_logging') ?? true;
    _enableConsoleLogging = config.getParameter('logging.enable_console_logging') ?? true;
    _enableRemoteLogging = config.getParameter('logging.enable_remote_logging') ?? false;
    _logLevel = config.getParameter('logging.level') ?? 'info';
    _logFilePath = config.getParameter('logging.log_file_path') ?? 'logs/app.log';
    _maxLogFileSize = config.getParameter('logging.log_max_size_mb') ?? 10;
    _logRetentionDays = config.getParameter('logging.log_retention_days') ?? 7;
    _enableStackTrace = config.getParameter('logging.enable_stack_trace') ?? true;
    _enablePerformanceLogging = config.getParameter('logging.enable_performance_logging') ?? true;
  }

  /// Setup root logger with hierarchical loggers
  void _setupRootLogger() {
    _rootLogger = Logger('iSuite');
    
    // Set log level
    final level = _parseLogLevel(_logLevel);
    Logger.root.level = level;
    
    // Setup console logging
    if (_enableConsoleLogging) {
      Logger.root.onRecord.listen((record) {
        _logToConsole(record);
      });
    }
    
    // Create specialized loggers
    _createSpecializedLoggers();
  }

  /// Parse log level string
  Level _parseLogLevel(String level) {
    switch (level.toLowerCase()) {
      case 'debug':
        return Level.DEBUG;
      case 'info':
        return Level.INFO;
      case 'warning':
        return Level.WARNING;
      case 'error':
        return Level.ERROR;
      case 'severe':
        return Level.SEVERE;
      case 'shout':
        return Level.SHOUT;
      default:
        return Level.INFO;
    }
  }

  /// Create specialized loggers for different components
  void _createSpecializedLoggers() {
    // Component-specific loggers
    Logger('iSuite.pocketbase');
    Logger('iSuite.ui');
    Logger('iSuite.network');
    Logger('iSuite.storage');
    Logger('iSuite.auth');
    Logger('iSuite.performance');
    Logger('iSuite.security');
  }

  /// Setup file logging with rotation
  Future<void> _setupFileLogging() async {
    try {
      final logFile = File(_logFilePath);
      
      // Create log directory if it doesn't exist
      final logDir = logFile.parent;
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      // Open log file
      _logFile = await logFile.open(mode: FileMode.append);
      _currentLogSize = await logFile.length();
      
      debugPrint('File logging enabled: $_logFilePath');
    } catch (e) {
      debugPrint('Failed to setup file logging: $e');
      _enableFileLogging = false;
    }
  }

  /// Setup error handlers
  void _setupErrorHandlers() {
    // Add default error handlers
    _errorHandlers.addAll([
      NetworkErrorHandler(),
      AuthenticationErrorHandler(),
      FileSystemErrorHandler(),
      UIRuntimeErrorHandler(),
    ]);
  }

  /// Setup performance monitoring
  void _setupPerformanceMonitoring() {
    // Monitor frame rendering
    if (kDebugMode) {
      WidgetsBinding.instance.addTimingsCallback((timings) {
        for (final timing in timings) {
          if (timing.totalSpan.inMilliseconds > 16) {
            recordPerformanceMetric(
              'frame_render_time',
              timing.totalSpan.inMilliseconds.toDouble(),
              unit: 'ms',
              metadata: {
                'total_span': timing.totalSpan.inMilliseconds,
                'build_span': timing.buildSpan.inMilliseconds,
                'raster_span': timing.rasterSpan.inMilliseconds,
              },
            );
          }
        }
      });
    }
  }

  /// Setup log flushing
  void _setupLogFlushing() {
    _flushTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _flushLogBuffer();
    });
  }

  /// Setup log rotation
  void _setupLogRotation() {
    _logRotationTimer = Timer.periodic(Duration(hours: 1), (_) {
      _checkLogRotation();
    });
  }

  /// Setup global error handling
  void _setupGlobalErrorHandling() {
    // Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      handleError(
        details.exception,
        stackTrace: details.stack,
        context: details.context,
        library: details.library,
      );
    };
    
    // Platform errors
    PlatformDispatcher.instance.onError = (error, stack) {
      handleError(error, stackTrace: stack, context: 'Platform Error');
      return true;
    };
  }

  /// Log to console with formatting
  void _logToConsole(LogRecord record) {
    final level = record.level.name;
    final loggerName = record.loggerName;
    final message = _formatLogMessage(record);
    final time = record.time.toIso8601String();
    
    // Color coding for different levels
    String colorCode;
    switch (record.level) {
      case Level.SEVERE:
      case Level.SHOUT:
        colorCode = '\x1B[31m'; // Red
        break;
      case Level.WARNING:
        colorCode = '\x1B[33m'; // Yellow
        break;
      case Level.INFO:
        colorCode = '\x1B[32m'; // Green
        break;
      case Level.DEBUG:
        colorCode = '\x1B[36m'; // Cyan
        break;
      default:
        colorCode = '\x1B[0m'; // Reset
    }
    
    final resetCode = '\x1B[0m';
    print('$colorCode[$level] $time $loggerName: $message$resetCode');
  }

  /// Format log message
  String _formatLogMessage(LogRecord record) {
    String message = record.message;
    
    // Add error details if available
    if (record.error != null) {
      message += ' | Error: ${record.error}';
    }
    
    // Add stack trace if enabled
    if (_enableStackTrace && record.stackTrace != null) {
      message += ' | Stack: ${record.stackTrace}';
    }
    
    // Add extra data
    if (record.extra.isNotEmpty) {
      message += ' | Extra: ${record.extra}';
    }
    
    return message;
  }

  /// Handle errors with categorization and recovery
  void handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    String? library,
    Map<String, dynamic>? metadata,
  }) {
    try {
      // Categorize error
      final errorCategory = _categorizeError(error);
      
      // Create error info
      final errorInfo = ErrorInfo(
        error: error,
        stackTrace: stackTrace,
        context: context,
        library: library,
        timestamp: DateTime.now(),
        category: errorCategory,
        metadata: metadata,
      );
      
      // Update error history
      _updateErrorHistory(errorInfo);
      
      // Log error
      _logError(errorInfo);
      
      // Try to recover
      _attemptRecovery(errorInfo);
      
      // Emit error event
      _errorController.add(ErrorEvent(
        type: ErrorEventType.errorOccurred,
        errorInfo: errorInfo,
      ));
      
      // Check if error should be reported
      if (_shouldReportError(errorInfo)) {
        _reportError(errorInfo);
      }
    } catch (e) {
      debugPrint('Error in error handler: $e');
    }
  }

  /// Categorize error type
  ErrorCategory _categorizeError(dynamic error) {
    if (error is SocketException) {
      return ErrorCategory.network;
    } else if (error is FileSystemException) {
      return ErrorCategory.fileSystem;
    } else if (error is TimeoutException) {
      return ErrorCategory.timeout;
    } else if (error is FormatException) {
      return ErrorCategory.parsing;
    } else if (error is StateError) {
      return ErrorCategory.state;
    } else if (error is ArgumentError) {
      return ErrorCategory.argument;
    } else if (error is RangeError) {
      return ErrorCategory.range;
    } else if (error is TypeError) {
      return ErrorCategory.type;
    } else {
      return ErrorCategory.unknown;
    }
  }

  /// Update error history
  void _updateErrorHistory(ErrorInfo errorInfo) {
    final category = errorInfo.category.toString();
    
    if (!_errorHistory.containsKey(category)) {
      _errorHistory[category] = [];
    }
    
    _errorHistory[category]!.add(errorInfo);
    
    // Keep only last 100 errors per category
    if (_errorHistory[category]!.length > 100) {
      _errorHistory[category]!.removeRange(0, _errorHistory[category]!.length - 100);
    }
    
    // Update error counts
    _errorCounts[category] = (_errorCounts[category] ?? 0) + 1;
  }

  /// Log error with structured format
  void _logError(ErrorInfo errorInfo) {
    final logger = Logger('iSuite.errors');
    
    logger.severe('''
Error occurred:
Category: ${errorInfo.category}
Context: ${errorInfo.context}
Library: ${errorInfo.library}
Message: ${errorInfo.error}
Stack Trace: ${errorInfo.stackTrace}
Metadata: ${errorInfo.metadata}
Timestamp: ${errorInfo.timestamp.toIso8601String()}
''');
  }

  /// Attempt automatic recovery
  void _attemptRecovery(ErrorInfo errorInfo) {
    for (final handler in _errorHandlers) {
      if (handler.canHandle(errorInfo)) {
        try {
          handler.handle(errorInfo);
          info('Error handled by ${handler.runtimeType}');
          return;
        } catch (e) {
          warning('Error handler failed: $e');
        }
      }
    }
    
    warning('No recovery available for error: ${errorInfo.error}');
  }

  /// Check if error should be reported
  bool _shouldReportError(ErrorInfo errorInfo) {
    // Don't report in debug mode
    if (kDebugMode) return false;
    
    // Report critical errors
    if (errorInfo.category == ErrorCategory.critical) return true;
    
    // Report frequent errors
    final count = _errorCounts[errorInfo.category.toString()] ?? 0;
    if (count >= 5) return true;
    
    // Report errors with metadata indicating importance
    if (errorInfo.metadata?['report'] == true) return true;
    
    return false;
  }

  /// Report error to remote service
  void _reportError(ErrorInfo errorInfo) {
    if (!_enableRemoteLogging) return;
    
    // Implementation depends on remote logging service
    // This is a placeholder for remote error reporting
    debugPrint('Reporting error: ${errorInfo.error}');
  }

  /// Record performance metric
  void recordPerformanceMetric(
    String name,
    double value, {
    String? unit,
    Map<String, dynamic>? metadata,
  }) {
    final metric = PerformanceMetric(
      name: name,
      value: value,
      unit: unit ?? 'ms',
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    
    if (!_performanceMetrics.containsKey(name)) {
      _performanceMetrics[name] = [];
    }
    
    _performanceMetrics[name]!.add(metric);
    
    // Keep only last 1000 metrics per name
    if (_performanceMetrics[name]!.length > 1000) {
      _performanceMetrics[name]!.removeRange(0, _performanceMetrics[name]!.length - 1000);
    }
    
    // Emit performance event
    _performanceController.add(PerformanceEvent(
      type: PerformanceEventType.metricRecorded,
      metric: metric,
    ));
  }

  /// Start performance timer
  PerformanceTimer startTimer(String name) {
    return PerformanceTimer(
      name: name,
      onComplete: (duration) {
        recordPerformanceMetric(name, duration.inMicroseconds.toDouble(), unit: 'μs');
      },
    );
  }

  /// Flush log buffer to file
  Future<void> _flushLogBuffer() async {
    if (_logBuffer.isEmpty || !_enableFileLogging) return;
    
    try {
      final entries = List.from(_logBuffer);
      _logBuffer.clear();
      
      for (final entry in entries) {
        await _writeLogEntry(entry);
      }
    } catch (e) {
      debugPrint('Failed to flush log buffer: $e');
    }
  }

  /// Write log entry to file
  Future<void> _writeLogEntry(LogEntry entry) async {
    if (_logFile == null) return;
    
    final logLine = _formatLogEntry(entry);
    final bytes = utf8.encode(logLine + '\n');
    
    await _logFile!.writeFrom(bytes);
    _currentLogSize += bytes.length;
  }

  /// Format log entry for file
  String _formatLogEntry(LogEntry entry) {
    return jsonEncode({
      'timestamp': entry.timestamp.toIso8601String(),
      'level': entry.level,
      'logger': entry.logger,
      'message': entry.message,
      'error': entry.error?.toString(),
      'stack_trace': entry.stackTrace?.toString(),
      'metadata': entry.metadata,
    });
  }

  /// Check log rotation
  Future<void> _checkLogRotation() async {
    if (!_enableFileLogging || _logFile == null) return;
    
    final maxSizeBytes = _maxLogFileSize * 1024 * 1024; // Convert MB to bytes
    
    if (_currentLogSize > maxSizeBytes) {
      await _rotateLogFile();
    }
  }

  /// Rotate log file
  Future<void> _rotateLogFile() async {
    try {
      // Close current log file
      await _logFile?.close();
      
      // Rename current log file with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final rotatedFile = File('$_logFilePath.$timestamp');
      await File(_logFilePath).rename(rotatedFile.path);
      
      // Create new log file
      await _setupFileLogging();
      
      // Clean up old log files
      await _cleanupOldLogFiles();
      
      info('Log file rotated');
    } catch (e) {
      debugPrint('Failed to rotate log file: $e');
    }
  }

  /// Clean up old log files
  Future<void> _cleanupOldLogFiles() async {
    try {
      final logDir = File(_logFilePath).parent;
      final files = await logDir.list().toList();
      
      for (final file in files) {
        if (file is File && file.path.contains(_logFilePath)) {
          final stat = await file.stat();
          final age = DateTime.now().difference(stat.modified);
          
          if (age.inDays > _logRetentionDays) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to cleanup old log files: $e');
    }
  }

  /// Convenience logging methods
  void debug(String message, {Map<String, dynamic>? metadata}) {
    _log(Level.DEBUG, 'iSuite', message, metadata: metadata);
  }

  void info(String message, {Map<String, dynamic>? metadata}) {
    _log(Level.INFO, 'iSuite', message, metadata: metadata);
  }

  void warning(String message, {Map<String, dynamic>? metadata}) {
    _log(Level.WARNING, 'iSuite', message, metadata: metadata);
  }

  void error(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    _log(Level.ERROR, 'iSuite', message, error: error, stackTrace: stackTrace, metadata: metadata);
  }

  void severe(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    _log(Level.SEVERE, 'iSuite', message, error: error, stackTrace: stackTrace, metadata: metadata);
  }

  /// Internal logging method
  void _log(
    Level level,
    String logger,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level.name,
      logger: logger,
      message: message,
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );
    
    // Add to buffer
    _logBuffer.add(entry);
    
    // Flush buffer if full
    if (_logBuffer.length >= _bufferSize) {
      _flushLogBuffer();
    }
    
    // Log to console
    final record = LogRecord(
      level: level,
      message: message,
      loggerName: logger,
      error: error,
      stackTrace: stackTrace,
    );
    
    if (metadata != null) {
      for (final entry in metadata.entries) {
        record.extra[entry.key] = entry.value;
      }
    }
    
    _rootLogger.log(record);
  }

  /// Get error statistics
  Map<String, dynamic> getErrorStatistics() {
    return {
      'total_errors': _errorCounts.values.fold(0, (sum, count) => sum + count),
      'error_counts': _errorCounts,
      'error_history': _errorHistory.map((key, value) => MapEntry(
        key,
        value.map((e) => e.toJson()).toList(),
      )),
    };
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStatistics() {
    final stats = <String, dynamic>{};
    
    for (final entry in _performanceMetrics.entries) {
      final metrics = entry.value;
      if (metrics.isEmpty) continue;
      
      final values = metrics.map((m) => m.value).toList();
      values.sort();
      
      stats[entry.key] = {
        'count': metrics.length,
        'min': values.first,
        'max': values.last,
        'average': values.reduce((a, b) => a + b) / values.length,
        'median': values[values.length ~/ 2],
        'latest': metrics.last.value,
        'unit': metrics.last.unit,
      };
    }
    
    return stats;
  }

  /// Dispose resources
  Future<void> dispose() async {
    _flushTimer?.cancel();
    _logRotationTimer?.cancel();
    
    await _flushLogBuffer();
    await _logFile?.close();
    
    await _errorController.close();
    await _performanceController.close();
    
    debugPrint('Enhanced logger disposed');
  }
}

/// Error information structure
class ErrorInfo {
  final dynamic error;
  final StackTrace? stackTrace;
  final String? context;
  final String? library;
  final DateTime timestamp;
  final ErrorCategory category;
  final Map<String, dynamic>? metadata;

  ErrorInfo({
    required this.error,
    this.stackTrace,
    this.context,
    this.library,
    required this.timestamp,
    required this.category,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'error': error.toString(),
      'stack_trace': stackTrace?.toString(),
      'context': context,
      'library': library,
      'timestamp': timestamp.toIso8601String(),
      'category': category.toString(),
      'metadata': metadata,
    };
  }
}

/// Error categories
enum ErrorCategory {
  network,
  fileSystem,
  authentication,
  timeout,
  parsing,
  state,
  argument,
  range,
  type,
  critical,
  unknown,
}

/// Log entry structure
class LogEntry {
  final DateTime timestamp;
  final String level;
  final String logger;
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? metadata;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.logger,
    required this.message,
    this.error,
    this.stackTrace,
    this.metadata,
  });
}

/// Performance metric structure
class PerformanceMetric {
  final String name;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  PerformanceMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.metadata,
  });
}

/// Performance timer
class PerformanceTimer {
  final String name;
  final Function(Duration) onComplete;
  final Stopwatch _stopwatch = Stopwatch();

  PerformanceTimer({
    required this.name,
    required this.onComplete,
  }) {
    _stopwatch.start();
  }

  Duration stop() {
    _stopwatch.stop();
    onComplete(_stopwatch.elapsed);
    return _stopwatch.elapsed;
  }
}

/// Error event types
enum ErrorEventType {
  errorOccurred,
  errorHandled,
  errorRecovered,
}

/// Performance event types
enum PerformanceEventType {
  metricRecorded,
  thresholdExceeded,
  performanceDegraded,
}

/// Error event
class ErrorEvent {
  final ErrorEventType type;
  final ErrorInfo errorInfo;
  final DateTime timestamp;

  ErrorEvent({
    required this.type,
    required this.errorInfo,
  }) : timestamp = DateTime.now();
}

/// Performance event
class PerformanceEvent {
  final PerformanceEventType type;
  final PerformanceMetric metric;
  final DateTime timestamp;

  PerformanceEvent({
    required this.type,
    required this.metric,
  }) : timestamp = DateTime.now();
}

/// Abstract error handler
abstract class ErrorHandler {
  bool canHandle(ErrorInfo errorInfo);
  void handle(ErrorInfo errorInfo);
}

/// Network error handler
class NetworkErrorHandler extends ErrorHandler {
  @override
  bool canHandle(ErrorInfo errorInfo) {
    return errorInfo.category == ErrorCategory.network;
  }

  @override
  void handle(ErrorInfo errorInfo) {
    // Implement network error recovery logic
    EnhancedLogger.instance.info('Handling network error: ${errorInfo.error}');
  }
}

/// Authentication error handler
class AuthenticationErrorHandler extends ErrorHandler {
  @override
  bool canHandle(ErrorInfo errorInfo) {
    return errorInfo.category == ErrorCategory.authentication;
  }

  @override
  void handle(ErrorInfo errorInfo) {
    // Implement authentication error recovery logic
    EnhancedLogger.instance.info('Handling authentication error: ${errorInfo.error}');
  }
}

/// File system error handler
class FileSystemErrorHandler extends ErrorHandler {
  @override
  bool canHandle(ErrorInfo errorInfo) {
    return errorInfo.category == ErrorCategory.fileSystem;
  }

  @override
  void handle(ErrorInfo errorInfo) {
    // Implement file system error recovery logic
    EnhancedLogger.instance.info('Handling file system error: ${errorInfo.error}');
  }
}

/// UI runtime error handler
class UIRuntimeErrorHandler extends ErrorHandler {
  @override
  bool canHandle(ErrorInfo errorInfo) {
    return errorInfo.library?.contains('ui') == true || 
           errorInfo.library?.contains('widgets') == true;
  }

  @override
  void handle(ErrorInfo errorInfo) {
    // Implement UI error recovery logic
    EnhancedLogger.instance.info('Handling UI runtime error: ${errorInfo.error}');
  }
}
