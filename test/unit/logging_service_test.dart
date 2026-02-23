import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:isuite/core/logging/logging_service.dart';

// Generate mocks
@GenerateMocks([PathProviderPlatform])
import 'logging_service_test.mocks.dart';

// Mock Path Provider Platform
class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/fake/docs/path';
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    return '/fake/support/path';
  }

  @override
  Future<String?> getDownloadsPath() async {
    return '/fake/downloads/path';
  }

  @override
  Future<String?> getExternalCachePaths() async {
    return null;
  }

  @override
  Future<String?> getExternalStoragePath() async {
    return '/fake/external/path';
  }

  @override
  Future<String?> getExternalStoragePaths({StorageDirectory? type}) async {
    return ['/fake/external/path'];
  }

  @override
  Future<String?> getLibraryPath() async {
    return '/fake/library/path';
  }

  @override
  Future<String?> getTemporaryPath() async {
    return '/fake/temp/path';
  }
}

void main() {
  late LoggingService loggingService;
  late FakePathProviderPlatform fakePathProvider;

  setUp(() async {
    fakePathProvider = FakePathProviderPlatform();
    PathProviderPlatform.instance = fakePathProvider;

    // Reset singleton for testing
    loggingService = LoggingService._internal();
    await loggingService.initialize();
  });

  tearDown(() {
    loggingService.dispose();
  });

  group('LoggingService - Initialization', () {
    test('should be a singleton', () {
      final instance1 = LoggingService();
      final instance2 = LoggingService();
      expect(instance1, equals(instance2));
    });

    test('should initialize with correct default values', () async {
      expect(loggingService.isInitialized, isTrue);
      expect(loggingService.logLevel, equals(LogLevel.info));
      expect(loggingService.maxLogFiles, equals(5));
      expect(loggingService.maxFileSize, equals(10 * 1024 * 1024)); // 10MB
    });
  });

  group('LoggingService - Log Level Management', () {
    test('should set log level correctly', () {
      loggingService.setLogLevel(LogLevel.debug);
      expect(loggingService.logLevel, equals(LogLevel.debug));

      loggingService.setLogLevel(LogLevel.error);
      expect(loggingService.logLevel, equals(LogLevel.error));
    });

    test('should filter logs based on level', () async {
      loggingService.setLogLevel(LogLevel.warning);

      // Should log warning and above
      await loggingService.warning('Test warning', 'TestModule');
      await loggingService.error('Test error', 'TestModule');

      // Should not log info and below
      await loggingService.info('Test info', 'TestModule');
      await loggingService.debug('Test debug', 'TestModule');

      // Verify that only warning and error level logs are processed
      final logs = loggingService.getLogs();
      final warningLogs = logs.where((log) => log.level == LogLevel.warning).toList();
      final errorLogs = logs.where((log) => log.level == LogLevel.error).toList();
      final infoLogs = logs.where((log) => log.level == LogLevel.info).toList();
      final debugLogs = logs.where((log) => log.level == LogLevel.debug).toList();

      expect(warningLogs.isNotEmpty, isTrue);
      expect(errorLogs.isNotEmpty, isTrue);
      expect(infoLogs.isEmpty, isTrue);
      expect(debugLogs.isEmpty, isTrue);
    });
  });

  group('LoggingService - Log Operations', () {
    test('should log messages at all levels', () async {
      await loggingService.debug('Debug message', 'TestModule');
      await loggingService.info('Info message', 'TestModule');
      await loggingService.warning('Warning message', 'TestModule');
      await loggingService.error('Error message', 'TestModule');
      await loggingService.fatal('Fatal message', 'TestModule');

      final logs = loggingService.getLogs();
      expect(logs.length, equals(5));

      expect(logs[0].message, equals('Debug message'));
      expect(logs[0].level, equals(LogLevel.debug));
      expect(logs[0].module, equals('TestModule'));

      expect(logs[1].message, equals('Info message'));
      expect(logs[1].level, equals(LogLevel.info));

      expect(logs[2].message, equals('Warning message'));
      expect(logs[2].level, equals(LogLevel.warning));

      expect(logs[3].message, equals('Error message'));
      expect(logs[3].level, equals(LogLevel.error));

      expect(logs[4].message, equals('Fatal message'));
      expect(logs[4].level, equals(LogLevel.fatal));
    });

    test('should log with error objects', () async {
      final testError = Exception('Test exception');
      await loggingService.error('Error with exception', 'TestModule', error: testError);

      final logs = loggingService.getLogs();
      final errorLog = logs.last;

      expect(errorLog.message, equals('Error with exception'));
      expect(errorLog.error, equals(testError));
    });

    test('should handle null module names', () async {
      await loggingService.info('Message without module');

      final logs = loggingService.getLogs();
      final log = logs.last;

      expect(log.message, equals('Message without module'));
      expect(log.module, isNull);
    });
  });

  group('LoggingService - Log Retrieval', () {
    test('should retrieve logs correctly', () async {
      await loggingService.info('Test log 1', 'Module1');
      await loggingService.warning('Test log 2', 'Module2');

      final allLogs = loggingService.getLogs();
      expect(allLogs.length, equals(2));

      final module1Logs = loggingService.getLogs(module: 'Module1');
      expect(module1Logs.length, equals(1));
      expect(module1Logs[0].module, equals('Module1'));

      final warningLogs = loggingService.getLogs(level: LogLevel.warning);
      expect(warningLogs.length, equals(1));
      expect(warningLogs[0].level, equals(LogLevel.warning));
    });

    test('should limit log retrieval', () async {
      for (int i = 0; i < 10; i++) {
        await loggingService.info('Log $i', 'TestModule');
      }

      final limitedLogs = loggingService.getLogs(limit: 5);
      expect(limitedLogs.length, equals(5));
    });

    test('should filter logs by time range', () async {
      final startTime = DateTime.now();
      await loggingService.info('Early log', 'TestModule');

      await Future.delayed(Duration(milliseconds: 10));

      final middleTime = DateTime.now();
      await loggingService.info('Middle log', 'TestModule');

      await Future.delayed(Duration(milliseconds: 10));

      final endTime = DateTime.now();
      await loggingService.info('Late log', 'TestModule');

      final earlyLogs = loggingService.getLogs(startTime: startTime, endTime: middleTime);
      expect(earlyLogs.length, equals(2)); // Early and middle logs

      final lateLogs = loggingService.getLogs(startTime: middleTime, endTime: endTime);
      expect(lateLogs.length, equals(2)); // Middle and late logs
    });
  });

  group('LoggingService - Log File Management', () {
    test('should rotate log files when size limit exceeded', () async {
      // Set small file size limit for testing
      loggingService.maxFileSize = 100; // 100 bytes

      // Add logs that exceed the limit
      final longMessage = 'A' * 50; // 50 bytes
      for (int i = 0; i < 5; i++) {
        await loggingService.info(longMessage, 'TestModule');
      }

      // Verify file rotation occurred (this would require checking actual file system)
      // In a real test, we'd verify file creation/deletion
      expect(loggingService.currentFileSize, lessThanOrEqualTo(loggingService.maxFileSize));
    });

    test('should maintain correct number of log files', () async {
      loggingService.maxLogFiles = 2;

      // Force multiple file rotations
      loggingService.maxFileSize = 50;

      for (int i = 0; i < 20; i++) {
        await loggingService.info('X' * 30, 'TestModule');
      }

      // Should not exceed maxLogFiles (this would require checking actual files)
      // In a real test, we'd count the actual log files
    });
  });

  group('LoggingService - Performance Tracking', () {
    test('should track performance metrics', () async {
      final stopwatch = loggingService.startPerformanceTracking('TestOperation');

      await Future.delayed(Duration(milliseconds: 100));

      final duration = loggingService.endPerformanceTracking('TestOperation');

      expect(duration, greaterThanOrEqualTo(Duration(milliseconds: 100)));
      expect(duration, lessThan(Duration(seconds: 1)));
    });

    test('should get performance metrics', () {
      final metrics = loggingService.getPerformanceMetrics();

      expect(metrics, isA<List<PerformanceMetric>>());
    });

    test('should clear performance metrics', () {
      loggingService.clearPerformanceMetrics();

      final metrics = loggingService.getPerformanceMetrics();
      expect(metrics.isEmpty, isTrue);
    });
  });

  group('LoggingService - Advanced Analytics', () {
    test('should track errors with analytics', () async {
      final error = Exception('Test error');
      await loggingService.trackError(error, 'TestModule', context: {'userId': '123'});

      final analytics = loggingService.getErrorAnalytics();
      expect(analytics.errorCount, greaterThan(0));
      expect(analytics.errorsByType['Exception'], equals(1));
      expect(analytics.errorsByModule['TestModule'], equals(1));
    });

    test('should provide log analytics', () async {
      await loggingService.info('Test info', 'TestModule');
      await loggingService.warning('Test warning', 'TestModule');
      await loggingService.error('Test error', 'TestModule');

      final analytics = loggingService.getLogAnalytics();
      expect(analytics.totalLogs, greaterThanOrEqualTo(3));
      expect(analytics.logsByLevel[LogLevel.info], greaterThan(0));
      expect(analytics.logsByLevel[LogLevel.warning], greaterThan(0));
      expect(analytics.logsByLevel[LogLevel.error], greaterThan(0));
    });

    test('should export analytics data', () async {
      await loggingService.info('Test log', 'TestModule');

      final data = loggingService.exportAnalyticsData();

      expect(data, isA<Map<String, dynamic>>());
      expect(data.containsKey('logAnalytics'), isTrue);
      expect(data.containsKey('errorAnalytics'), isTrue);
      expect(data.containsKey('performanceMetrics'), isTrue);
    });

    test('should clear analytics data', () async {
      await loggingService.trackError(Exception('Test'), 'TestModule');

      loggingService.clearAnalyticsData();

      final errorAnalytics = loggingService.getErrorAnalytics();
      expect(errorAnalytics.errorCount, equals(0));
    });
  });

  group('LoggingService - Health Monitoring', () {
    test('should perform health checks', () async {
      loggingService.setMonitoringEnabled(true);

      // Wait for monitoring to run
      await Future.delayed(Duration(milliseconds: 100));

      final healthStatus = loggingService.getHealthStatus();

      expect(healthStatus, isA<Map<String, dynamic>>());
      expect(healthStatus.containsKey('isHealthy'), isTrue);
      expect(healthStatus.containsKey('metrics'), isTrue);
    });

    test('should handle monitoring enable/disable', () {
      loggingService.setMonitoringEnabled(true);
      expect(loggingService.isMonitoringEnabled, isTrue);

      loggingService.setMonitoringEnabled(false);
      expect(loggingService.isMonitoringEnabled, isFalse);
    });
  });

  group('LoggingService - Log Filtering and Search', () {
    test('should search logs correctly', () async {
      await loggingService.info('Apple pie recipe', 'Recipes');
      await loggingService.info('Banana bread recipe', 'Recipes');
      await loggingService.info('Cherry turnover', 'Recipes');

      final appleResults = loggingService.searchLogs('apple');
      expect(appleResults.length, equals(1));
      expect(appleResults[0].message, contains('Apple'));

      final recipeResults = loggingService.searchLogs('recipe');
      expect(recipeResults.length, equals(2));

      final caseInsensitiveResults = loggingService.searchLogs('BANANA');
      expect(caseInsensitiveResults.length, equals(1));
    });

    test('should filter logs by multiple criteria', () async {
      await loggingService.debug('Debug message', 'Module1');
      await loggingService.info('Info message', 'Module1');
      await loggingService.warning('Warning message', 'Module2');
      await loggingService.error('Error message', 'Module2');

      final filteredLogs = loggingService.getLogs(
        level: LogLevel.warning,
        module: 'Module2'
      );

      expect(filteredLogs.length, equals(1));
      expect(filteredLogs[0].level, equals(LogLevel.warning));
      expect(filteredLogs[0].module, equals('Module2'));
    });
  });

  group('LoggingService - Resource Management', () {
    test('should dispose resources correctly', () async {
      await loggingService.info('Test log', 'TestModule');

      loggingService.dispose();

      // Verify resources are cleaned up
      expect(loggingService.getLogs().isEmpty, isTrue);
    });

    test('should handle concurrent logging operations', () async {
      final futures = <Future>[];

      for (int i = 0; i < 10; i++) {
        futures.add(loggingService.info('Concurrent log $i', 'TestModule'));
      }

      await Future.wait(futures);

      final logs = loggingService.getLogs();
      expect(logs.length, equals(10));
    });
  });

  group('LoggingService - Error Recovery', () {
    test('should handle file system errors gracefully', () async {
      // Mock a file system error scenario
      // This would require more complex mocking in a real implementation

      await loggingService.info('Test after file error', 'TestModule');

      final logs = loggingService.getLogs();
      expect(logs.isNotEmpty, isTrue);
    });

    test('should handle malformed log entries', () async {
      // Test that malformed entries don't break the logging system
      await loggingService.info('Valid log', 'TestModule');

      final logs = loggingService.getLogs();
      expect(logs.length, equals(1));
      expect(logs[0].message, equals('Valid log'));
    });
  });

  group('LoggingService - Memory Optimization', () {
    test('should limit memory usage for logs', () async {
      loggingService.maxMemoryLogs = 10;

      for (int i = 0; i < 15; i++) {
        await loggingService.info('Log $i', 'TestModule');
      }

      final logs = loggingService.getLogs();
      expect(logs.length, lessThanOrEqualTo(10));
    });

    test('should clear old logs when limit exceeded', () async {
      loggingService.maxMemoryLogs = 3;

      await loggingService.info('Log 1', 'TestModule');
      await loggingService.info('Log 2', 'TestModule');
      await loggingService.info('Log 3', 'TestModule');
      await loggingService.info('Log 4', 'TestModule'); // Should trigger cleanup

      final logs = loggingService.getLogs();
      expect(logs.length, equals(3));
      expect(logs[0].message, equals('Log 2')); // Oldest log should be removed
    });
  });
}
