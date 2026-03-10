import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../config/central_config.dart';

/// Enhanced Logging Service for iSuite
/// Provides comprehensive logging with multiple levels, file output, and performance tracking
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  final CentralConfig _config = CentralConfig.instance;

  // Logger instance
  late final Logger _logger;

  // Event controllers
  final StreamController<LogEvent> _logEventController = StreamController<LogEvent>.broadcast();
  final StreamController<AnalyticsEvent> _analyticsEventController = StreamController<AnalyticsEvent>.broadcast();

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

  // Analytics and monitoring
  final Map<String, LogAnalytics> _logAnalytics = {};
  final Map<String, ErrorTracker> _errorTrackers = {};
  bool _monitoringEnabled = true;
  Timer? _monitoringTimer;
  final Map<String, HealthMetric> _healthMetrics = {};

  Stream<AnalyticsEvent> get analyticsEvents =>
      _analyticsEventController.stream;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize logger with enhanced configuration
  void _initializeLogger() {
    // Initialize the logger instance
    _logger = Logger(
      filter: null,
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      output: null,
    );
  }

  /// Initialize logging service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize logger with enhanced configuration
      _initializeLogger();

      // Register with CentralConfig with comprehensive parameters (enhanced)
      _config.setParameter('logging.enabled', true);
      _config.setParameter('logging.level', 'info');
      _config.setParameter('logging.file.enabled', true);
      _config.setParameter('logging.file.path', 'logs/isuite.log');
      _config.setParameter('logging.file.max_size_mb', 10);
      _config.setParameter('logging.file.max_files', 5);
      _config.setParameter('logging.file.compression', true);
      _config.setParameter('logging.file.rotation', 'daily');

      // Console logging settings
      _config.setParameter('logging.console.enabled', true);
      _config.setParameter('logging.console.colors', true);
      _config.setParameter('logging.console.pretty_print', true);

      // Performance tracking
      _config.setParameter('logging.performance.enabled', true);
      _config.setParameter('logging.performance.slow_operation_threshold_ms', 100);
      _config.setParameter('logging.performance.memory_tracking', true);
      _config.setParameter('logging.performance.metrics_retention_days', 7);

      // Analytics and monitoring
      _config.setParameter('logging.analytics.enabled', true);
      _config.setParameter('logging.analytics.error_tracking', true);
      _config.setParameter('logging.analytics.performance_tracking', true);
      _config.setParameter('logging.analytics.usage_tracking', true);

      // Monitoring settings
      _config.setParameter('logging.monitoring.enabled', true);
      _config.setParameter('logging.monitoring.interval_seconds', 300);
      _config.setParameter('logging.monitoring.alert_on_errors', true);
      _config.setParameter('logging.monitoring.alert_threshold', 10);

      // Security settings
      _config.setParameter('logging.security.enabled', true);
      _config.setParameter('logging.security.audit_trail', true);
      _config.setParameter('logging.security.sensitive_data_masking', true);
      _config.setParameter('logging.security.encryption', false);

      // Filtering and routing
      _config.setParameter('logging.filter.enabled', false);
      _config.setParameter('logging.filter.exclude_patterns', '');
      _config.setParameter('logging.filter.include_only', '');
      _config.setParameter('logging.routing.enabled', false);
      _config.setParameter('logging.routing.rules', '');

      // External integrations
      _config.setParameter('logging.external.sentry_enabled', false);
      _config.setParameter('logging.external.sentry_dsn', '');
      _config.setParameter('logging.external.elastic_enabled', false);
      _config.setParameter('logging.external.elastic_endpoint', '');

      // Development settings
      _config.setParameter('logging.development.stacktrace_full', false);
      _config.setParameter('logging.development.async_logging', true);
      _config.setParameter('logging.development.buffer_size', 1000);

      // Enhanced logging service initialization completed
      _isInitialized = true;
      _logger?.i('Logging service initialized successfully with enhanced features');

      // Start monitoring if enabled
      if (_monitoringEnabled) {
        _startMonitoring();
      }

      // Log initialization success
      info('Logging Service initialized with advanced monitoring', 'LoggingService');
    } catch (e, stackTrace) {
      // Fallback to console logging if file initialization fails
      _setupFallbackLogger();
      developer.log('Failed to initialize Logging Service: $e',
          name: 'LoggingService');
    }
  }

  /// Track error with analytics
  void trackError(String component, String errorType,
      {String? details, Map<String, dynamic>? metadata}) {
    final tracker =
        _errorTrackers.putIfAbsent(component, () => ErrorTracker(component));
    tracker.recordError(errorType, details: details, metadata: metadata);

    // Emit analytics event
    _emitAnalyticsEvent(AnalyticsEventType.errorTracked,
        component: component,
        data: {
          'errorType': errorType,
          'details': details,
          'metadata': metadata,
          'count': tracker.getErrorCount(errorType),
        });

    // Log the tracked error
    warning('Error tracked: $errorType in $component', 'ErrorTracker');
  }

  /// Get error analytics for component
  ErrorTracker? getErrorAnalytics(String component) {
    return _errorTrackers[component];
  }

  /// Get log analytics for component
  LogAnalytics getLogAnalytics(String component) {
    return _logAnalytics.putIfAbsent(component, () => LogAnalytics(component));
  }

  /// Start health monitoring
  void _startMonitoring() {
    _monitoringTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      _performHealthCheck();
    });

    info('Health monitoring started', 'Monitoring');
  }

  /// Perform health check
  void _performHealthCheck() {
    final healthData = {
      'timestamp': DateTime.now(),
      'performanceMetrics': _performanceMetrics.length,
      'activeStopwatches': _performanceStopwatches.length,
      'logAnalytics': _logAnalytics.length,
      'errorTrackers': _errorTrackers.length,
      'logFileSize': _logFile != null && _logFile!.existsSync()
          ? _logFile!.lengthSync()
          : 0,
    };

    // Update health metrics
    _healthMetrics['system'] = HealthMetric(
      component: 'system',
      status: 'healthy',
      lastCheck: DateTime.now(),
      metrics: healthData,
    );

    // Emit monitoring event
    _emitAnalyticsEvent(AnalyticsEventType.healthCheck,
        component: 'system', data: healthData);

    debug('Health check completed', 'Monitoring');
  }

  /// Get health status
  Map<String, HealthMetric> getHealthStatus() {
    return Map.from(_healthMetrics);
  }

  /// Export analytics data
  Map<String, dynamic> exportAnalyticsData() {
    return {
      'logAnalytics': _logAnalytics.map((k, v) => MapEntry(k, v.toJson())),
      'errorTrackers': _errorTrackers.map((k, v) => MapEntry(k, v.toJson())),
      'performanceMetrics': _performanceMetrics.map((m) => m.toJson()).toList(),
      'healthMetrics': _healthMetrics.map((k, v) => MapEntry(k, v.toJson())),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Clear analytics data
  void clearAnalyticsData() {
    _logAnalytics.clear();
    _errorTrackers.clear();
    _healthMetrics.clear();
    info('Analytics data cleared', 'Analytics');
  }

  /// Enable/disable monitoring
  void setMonitoringEnabled(bool enabled) {
    _monitoringEnabled = enabled;
    if (enabled && _monitoringTimer == null) {
      _startMonitoring();
    } else if (!enabled && _monitoringTimer != null) {
      _monitoringTimer!.cancel();
      _monitoringTimer = null;
    }
    info('Monitoring ${enabled ? 'enabled' : 'disabled'}', 'Monitoring');
  }

  /// Emit analytics event
  void _emitAnalyticsEvent(
    AnalyticsEventType type, {
    String? component,
    Map<String, dynamic>? data,
  }) {
    final event = AnalyticsEvent(
      type: type,
      timestamp: DateTime.now(),
      component: component,
      data: data ?? {},
    );
    _analyticsEventController.add(event);
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
  void error(String message,
      [String? tag, dynamic error, StackTrace? stackTrace]) {
    _log(Level.error, message, tag, error: error, stackTrace: stackTrace);
  }

  /// Log fatal message
  void fatal(String message,
      [String? tag, dynamic error, StackTrace? stackTrace]) {
    _log(Level.fatal, message, tag, error: error, stackTrace: stackTrace);
  }

  /// Start performance tracking
  void startPerformanceTracking(String operation) {
    _performanceStopwatches[operation] = Stopwatch()..start();
  }

  /// Stop performance tracking and record metric
  void stopPerformanceTracking(String operation,
      [Map<String, dynamic>? metadata]) {
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

      debug(
          'Performance: $operation completed in ${stopwatch.elapsedMilliseconds}ms',
          'Performance');
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
      developer.log('Failed to initialize file logging: $e',
          name: 'LoggingService');
    }
  }

  Future<void> _rotateLogFile() async {
    if (_logFile != null && await _logFile!.exists()) {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final archiveFile =
          File('${_logFile!.parent.path}/isuite_logs_$timestamp.txt');
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
      _logger.log(level, formattedMessage,
          error: error, stackTrace: stackTrace);

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
    _analyticsEventController.close();
    _monitoringTimer?.cancel();
    _performanceStopwatches.clear();
    _performanceMetrics.clear();
    _logAnalytics.clear();
    _errorTrackers.clear();
    _healthMetrics.clear();
  }

  // Getters
  bool get monitoringEnabled => _monitoringEnabled;
  List<PerformanceMetric> get performanceMetrics =>
      List.from(_performanceMetrics);
  Map<String, LogAnalytics> get logAnalytics => Map.from(_logAnalytics);
  Map<String, ErrorTracker> get errorTrackers => Map.from(_errorTrackers);
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

/// Log Analytics for tracking log patterns and statistics
class LogAnalytics {
  final String component;
  final Map<String, int> _logCounts = {};
  final Map<String, DateTime> _lastLogTimes = {};
  int _totalLogs = 0;

  LogAnalytics(this.component);

  void recordLog(String level, DateTime timestamp) {
    _logCounts[level] = (_logCounts[level] ?? 0) + 1;
    _lastLogTimes[level] = timestamp;
    _totalLogs++;
  }

  int getLogCount(String level) => _logCounts[level] ?? 0;
  int get totalLogs => _totalLogs;
  DateTime? getLastLogTime(String level) => _lastLogTimes[level];

  Map<String, dynamic> toJson() {
    return {
      'component': component,
      'logCounts': Map.from(_logCounts),
      'lastLogTimes':
          _lastLogTimes.map((k, v) => MapEntry(k, v.toIso8601String())),
      'totalLogs': _totalLogs,
    };
  }
}

/// Error Tracker for monitoring error patterns
class ErrorTracker {
  final String component;
  final Map<String, List<ErrorRecord>> _errorRecords = {};
  final Map<String, int> _errorCounts = {};

  ErrorTracker(this.component);

  void recordError(String errorType,
      {String? details, Map<String, dynamic>? metadata}) {
    final record = ErrorRecord(
      errorType: errorType,
      timestamp: DateTime.now(),
      details: details,
      metadata: metadata ?? {},
    );

    _errorRecords.putIfAbsent(errorType, () => []).add(record);
    _errorCounts[errorType] = (_errorCounts[errorType] ?? 0) + 1;

    // Keep only last 100 errors per type
    if (_errorRecords[errorType]!.length > 100) {
      _errorRecords[errorType] = _errorRecords[errorType]!.sublist(-100);
    }
  }

  int getErrorCount(String errorType) => _errorCounts[errorType] ?? 0;
  List<ErrorRecord> getErrorRecords(String errorType) =>
      List.from(_errorRecords[errorType] ?? []);
  Map<String, int> get allErrorCounts => Map.from(_errorCounts);

  Map<String, dynamic> toJson() {
    return {
      'component': component,
      'errorCounts': Map.from(_errorCounts),
      'errorRecords': _errorRecords
          .map((k, v) => MapEntry(k, v.map((r) => r.toJson()).toList())),
    };
  }
}

class ErrorRecord {
  final String errorType;
  final DateTime timestamp;
  final String? details;
  final Map<String, dynamic> metadata;

  ErrorRecord({
    required this.errorType,
    required this.timestamp,
    this.details,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'errorType': errorType,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
      'metadata': metadata,
    };
  }
}

/// Health Metric for system monitoring
class HealthMetric {
  final String component;
  final String status;
  final DateTime lastCheck;
  final Map<String, dynamic> metrics;

  HealthMetric({
    required this.component,
    required this.status,
    required this.lastCheck,
    required this.metrics,
  });

  Map<String, dynamic> toJson() {
    return {
      'component': component,
      'status': status,
      'lastCheck': lastCheck.toIso8601String(),
      'metrics': metrics,
    };
  }
}

/// Analytics Event Types
enum AnalyticsEventType {
  errorTracked,
  healthCheck,
  performanceAlert,
  logPattern,
}

/// Analytics Event
class AnalyticsEvent {
  final AnalyticsEventType type;
  final DateTime timestamp;
  final String? component;
  final Map<String, dynamic> data;

  AnalyticsEvent({
    required this.type,
    required this.timestamp,
    this.component,
    required this.data,
  });
}

// Custom output classes

class FileOutput extends LogOutput {
  final File file;
  late IOSink _sink;

  FileOutput({required this.file});

  @override
  Future<void> init() async {
    _sink = file.openWrite(mode: FileMode.append);
  }

  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      _sink.writeln('${DateTime.now().toIso8601String()}: $line');
    }
  }

  @override
  Future<void> destroy() async {
    await _sink.close();
  }
}

class MultiOutput extends LogOutput {
  final List<LogOutput> outputs;

  MultiOutput(this.outputs);

  @override
  Future<void> init() async {
    for (final output in outputs) {
      await output.init();
    }
  }

  @override
  void output(OutputEvent event) {
    for (final output in outputs) {
      output.output(event);
    }
  }

  @override
  Future<void> destroy() async {
    for (final output in outputs) {
      await output.destroy();
    }
  }
}
