import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// Enhanced Logging Service for iSuite
/// Provides comprehensive logging with multiple levels, file output, and performance tracking
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  // Logger instance
  late final Logger _logger;
  
  // File logging
  File? _logFile;
  bool _fileLoggingEnabled = true;
  int _maxLogFileSize = 10 * 1024 * 1024; // 10MB
  
  // Performance tracking
  final Map<String, Stopwatch> _performanceStopwatches = {};
  final List<PerformanceMetric> _performanceMetrics = [];
  
  // Log levels
  static const Map<String, Level> _logLevels = {
    'debug': Level.debug,
    'info': Level.info,
    'warning': Level.warning,
    'error': Level.error,
    'fatal': Level.fatal,
  };

  // State
  bool _isInitialized = false;
  final StreamController<LogEvent> _logEventController = StreamController.broadcast();

  Stream<LogEvent> get logEvents => _logEventController.stream;

  /// Initialize logging service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize file logging
      await _initializeFileLogging();

      // Setup logger
      _setupLogger();

      _isInitialized = true;
      
      // Log initialization
      info('Logging Service initialized', 'LoggingService');
      
    } catch (e, stackTrace) {
      // Fallback to console logging if file initialization fails
      _setupFallbackLogger();
      developer.log('Failed to initialize Logging Service: $e', name: 'LoggingService');
    }
  }

  /// Log debug message
  void debug(String message, [String? tag]) {
    _log(Level.debug, message, tag);
  }

  /// Log info message
  void info(String message, [String? tag]) {
    _log(Level.info, message, tag);
  }

  /// Log warning message
  void warning(String message, [String? tag]) {
    _log(Level.warning, message, tag);
  }

  /// Log error message
  void error(String message, [String? tag, dynamic error, StackTrace? stackTrace]) {
    _log(Level.error, message, tag, error: error, stackTrace: stackTrace);
  }

  /// Log fatal message
  void fatal(String message, [String? tag, dynamic error, StackTrace? stackTrace]) {
    _log(Level.fatal, message, tag, error: error, stackTrace: stackTrace);
  }

  /// Start performance tracking
  void startPerformanceTracking(String operation) {
    _performanceStopwatches[operation] = Stopwatch()..start();
  }

  /// Stop performance tracking and record metric
  void stopPerformanceTracking(String operation, [Map<String, dynamic>? metadata]) {
    final stopwatch = _performanceStopwatches[operation];
    if (stopwatch != null) {
      stopwatch.stop();
      
      final metric = PerformanceMetric(
        operation: operation,
        duration: stopwatch.elapsed,
        timestamp: DateTime.now(),
        metadata: metadata ?? {},
      );
      
      _performanceMetrics.add(metric);
      _performanceStopwatches.remove(operation);
      
      // Keep only last 1000 metrics
      if (_performanceMetrics.length > 1000) {
        _performanceMetrics.removeRange(0, _performanceMetrics.length - 1000);
      }
      
      debug('Performance: $operation completed in ${stopwatch.elapsedMilliseconds}ms', 'Performance');
    }
  }

  /// Get performance metrics
  List<PerformanceMetric> getPerformanceMetrics() {
    return List.from(_performanceMetrics);
  }

  /// Get performance metrics for operation
  List<PerformanceMetric> getPerformanceMetricsForOperation(String operation) {
    return _performanceMetrics.where((m) => m.operation == operation).toList();
  }

  /// Clear performance metrics
  void clearPerformanceMetrics() {
    _performanceMetrics.clear();
    _performanceStopwatches.clear();
  }

  /// Get average performance for operation
  Duration getAveragePerformance(String operation) {
    final metrics = getPerformanceMetricsForOperation(operation);
    if (metrics.isEmpty) return Duration.zero;
    
    final totalMicroseconds = metrics.fold<int>(
      0,
      (sum, metric) => sum + metric.duration.inMicroseconds,
    );
    
    return Duration(microseconds: totalMicroseconds ~/ metrics.length);
  }

  /// Private helper methods

  Future<void> _initializeFileLogging() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/isuite_logs.txt');
      
      // Check file size and rotate if necessary
      if (await _logFile!.exists()) {
        final fileSize = await _logFile!.length();
        if (fileSize > _maxLogFileSize) {
          await _rotateLogFile();
        }
      }
      
    } catch (e) {
      _fileLoggingEnabled = false;
      developer.log('Failed to initialize file logging: $e', name: 'LoggingService');
    }
  }

  Future<void> _rotateLogFile() async {
    if (_logFile != null && await _logFile!.exists()) {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final archiveFile = File('${_logFile!.parent.path}/isuite_logs_$timestamp.txt');
      await _logFile!.rename(archiveFile.path);
    }
  }

  void _setupLogger() {
    _logger = Logger(
      level: kDebugMode ? Level.debug : Level.info,
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      output: MultiOutput([
        ConsoleOutput(),
        if (_fileLoggingEnabled && _logFile != null)
          FileOutput(file: _logFile!),
      ]),
    );
  }

  void _setupFallbackLogger() {
    _logger = Logger(
      level: Level.info,
      printer: PrettyPrinter(
        methodCount: 1,
        errorMethodCount: 5,
        lineLength: 80,
        colors: false,
        printEmojis: false,
        printTime: true,
      ),
      output: ConsoleOutput(),
    );
  }

  void _log(
    Level level,
    String message,
    String? tag, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    try {
      final timestamp = DateTime.now();
      final formattedMessage = tag != null ? '[$tag] $message' : message;
      
      // Log to logger
      _logger.log(level, formattedMessage, error: error, stackTrace: stackTrace);
      
      // Emit log event
      final logEvent = LogEvent(
        level: level,
        message: message,
        tag: tag,
        timestamp: timestamp,
        error: error,
        stackTrace: stackTrace,
      );
      
      _logEventController.add(logEvent);
      
      // Log to developer console in debug mode
      if (kDebugMode) {
        developer.log(
          formattedMessage,
          name: tag ?? 'iSuite',
          time: timestamp,
          level: _getDeveloperLogLevel(level),
          error: error,
          stackTrace: stackTrace,
        );
      }
      
    } catch (e) {
      // Fallback logging if something goes wrong
      developer.log('Logging error: $e', name: 'LoggingService');
      developer.log(message, name: tag ?? 'iSuite');
    }
  }

  int _getDeveloperLogLevel(Level level) {
    switch (level) {
      case Level.debug:
        return 0;
      case Level.info:
        return 1;
      case Level.warning:
        return 2;
      case Level.error:
        return 3;
      case Level.fatal:
        return 4;
      default:
        return 1;
    }
  }

  /// Dispose logging service
  void dispose() {
    _logEventController.close();
    _performanceStopwatches.clear();
    _performanceMetrics.clear();
  }

  // Getters
  bool get isInitialized => _isInitialized;
  List<PerformanceMetric> get performanceMetrics => List.from(_performanceMetrics);
}

// Supporting classes

class LogEvent {
  final Level level;
  final String message;
  final String? tag;
  final DateTime timestamp;
  final dynamic error;
  final StackTrace? stackTrace;

  LogEvent({
    required this.level,
    required this.message,
    this.tag,
    required this.timestamp,
    this.error,
    this.stackTrace,
  });
}

class PerformanceMetric {
  final String operation;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PerformanceMetric({
    required this.operation,
    required this.duration,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'duration': duration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

// Custom output classes

class FileOutput extends LogOutput {
  final File file;
  late IOSink _sink;

  FileOutput({required this.file});

  @override
  void init() {
    _sink = file.openWrite(mode: FileMode.append);
  }

  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      _sink.writeln('${DateTime.now().toIso8601String()}: $line');
    }
  }

  @override
  void destroy() {
    _sink.close();
  }
}

class MultiOutput extends LogOutput {
  final List<LogOutput> outputs;

  MultiOutput(this.outputs);

  @override
  void init() {
    for (final output in outputs) {
      output.init();
    }
  }

  @override
  void output(OutputEvent event) {
    for (final output in outputs) {
      output.output(event);
    }
  }

  @override
  void destroy() {
    for (final output in outputs) {
      output.destroy();
    }
  }
}
