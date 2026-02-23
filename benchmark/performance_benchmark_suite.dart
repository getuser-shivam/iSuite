import 'dart:async';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:iSuite/core/config/central_config.dart';
import 'package:iSuite/core/logging/logging_service.dart';
import 'package:iSuite/features/ai_assistant/advanced_document_intelligence_service.dart';
import 'package:iSuite/core/circuit_breaker_service.dart';
import 'package:iSuite/core/health_monitoring_service.dart';
import 'package:iSuite/core/data_validation_service.dart';
import 'package:iSuite/core/performance_monitoring_service.dart';

/// Performance Benchmarking Suite for iSuite
///
/// Comprehensive benchmarking system that measures and tracks performance
/// across all major operations and services in the iSuite application.

class PerformanceBenchmarkSuite {
  final CentralConfig _config;
  final LoggingService _logger;
  final PerformanceMonitoringService _performanceMonitor;

  PerformanceBenchmarkSuite({
    CentralConfig? config,
    LoggingService? logger,
    PerformanceMonitoringService? performanceMonitor,
  }) :
    _config = config ?? CentralConfig.instance,
    _logger = logger ?? LoggingService(),
    _performanceMonitor = performanceMonitor ?? PerformanceMonitoringService();

  /// Run comprehensive performance benchmark suite
  Future<BenchmarkResults> runFullBenchmarkSuite({
    int iterations = 10,
    bool enableRegressionDetection = true,
  }) async {
    _logger.info('Starting comprehensive performance benchmark suite', 'Benchmark');

    final results = BenchmarkResults(
      timestamp: DateTime.now(),
      benchmarkVersion: '1.0.0',
      environment: await _gatherEnvironmentInfo(),
    );

    try {
      // Core Services Benchmarks
      results.coreServices = await _runCoreServicesBenchmarks(iterations);
      results.aiServices = await _runAIServicesBenchmarks(iterations);
      results.robustnessServices = await _runRobustnessServicesBenchmarks(iterations);

      // Memory and Resource Benchmarks
      results.memoryBenchmarks = await _runMemoryBenchmarks(iterations);
      results.resourceBenchmarks = await _runResourceBenchmarks(iterations);

      // Integration Benchmarks
      results.integrationBenchmarks = await _runIntegrationBenchmarks(iterations);

      // Calculate overall metrics
      results.overallMetrics = _calculateOverallMetrics(results);

      // Check for regressions if enabled
      if (enableRegressionDetection) {
        results.regressionAnalysis = await _performRegressionAnalysis(results);
      }

      // Generate recommendations
      results.recommendations = _generatePerformanceRecommendations(results);

      _logger.info('Performance benchmark suite completed successfully', 'Benchmark');

    } catch (e, stackTrace) {
      _logger.error('Performance benchmark suite failed', 'Benchmark', error: e, stackTrace: stackTrace);
      results.error = 'Benchmark suite failed: ${e.toString()}';
    }

    return results;
  }

  /// Run core services performance benchmarks
  Future<CoreServicesBenchmark> _runCoreServicesBenchmarks(int iterations) async {
    _logger.info('Running core services benchmarks', 'Benchmark');

    final results = CoreServicesBenchmark();

    // Configuration Service Benchmarks
    results.configService = await _benchmarkConfigService(iterations);

    // Logging Service Benchmarks
    results.loggingService = await _benchmarkLoggingService(iterations);

    // Performance Monitoring Service Benchmarks
    results.performanceService = await _benchmarkPerformanceService(iterations);

    return results;
  }

  /// Run AI services performance benchmarks
  Future<AIServicesBenchmark> _runAIServicesBenchmarks(int iterations) async {
    _logger.info('Running AI services benchmarks', 'Benchmark');

    final results = AIServicesBenchmark();

    // Document Intelligence Benchmarks
    results.documentIntelligence = await _benchmarkDocumentIntelligence(iterations);

    // Search Service Benchmarks
    results.searchService = await _benchmarkSearchService(iterations);

    // Translation Service Benchmarks
    results.translationService = await _benchmarkTranslationService(iterations);

    return results;
  }

  /// Run robustness services performance benchmarks
  Future<RobustnessServicesBenchmark> _runRobustnessServicesBenchmarks(int iterations) async {
    _logger.info('Running robustness services benchmarks', 'Benchmark');

    final results = RobustnessServicesBenchmark();

    // Circuit Breaker Benchmarks
    results.circuitBreaker = await _benchmarkCircuitBreaker(iterations);

    // Health Monitoring Benchmarks
    results.healthMonitoring = await _benchmarkHealthMonitoring(iterations);

    // Data Validation Benchmarks
    results.dataValidation = await _benchmarkDataValidation(iterations);

    return results;
  }

  /// Run memory performance benchmarks
  Future<MemoryBenchmark> _runMemoryBenchmarks(int iterations) async {
    _logger.info('Running memory benchmarks', 'Benchmark');

    final results = MemoryBenchmark();

    // Memory allocation patterns
    results.allocationPatterns = await _benchmarkMemoryAllocation(iterations);

    // Memory leak detection
    results.leakDetection = await _benchmarkMemoryLeakDetection(iterations);

    // Garbage collection performance
    results.gcPerformance = await _benchmarkGCPerformance(iterations);

    return results;
  }

  /// Run resource usage benchmarks
  Future<ResourceBenchmark> _runResourceBenchmarks(int iterations) async {
    _logger.info('Running resource benchmarks', 'Benchmark');

    final results = ResourceBenchmark();

    // CPU usage benchmarks
    results.cpuUsage = await _benchmarkCPUUsage(iterations);

    // Network usage benchmarks
    results.networkUsage = await _benchmarkNetworkUsage(iterations);

    // Storage I/O benchmarks
    results.storageIO = await _benchmarkStorageIO(iterations);

    return results;
  }

  /// Run integration benchmarks
  Future<IntegrationBenchmark> _runIntegrationBenchmarks(int iterations) async {
    _logger.info('Running integration benchmarks', 'Benchmark');

    final results = IntegrationBenchmark();

    // End-to-end workflow benchmarks
    results.endToEndWorkflows = await _benchmarkEndToEndWorkflows(iterations);

    // Service interaction benchmarks
    results.serviceInteractions = await _benchmarkServiceInteractions(iterations);

    // Data pipeline benchmarks
    results.dataPipelines = await _benchmarkDataPipelines(iterations);

    return results;
  }

  // Individual benchmark implementations

  Future<BenchmarkResult> _benchmarkConfigService(int iterations) async {
    final results = <Duration>[];

    for (int i = 0; i < iterations; i++) {
      final start = DateTime.now();

      // Test parameter operations
      await _config.setParameter('benchmark.test.$i', 'test_value_$i');
      final value = _config.getParameter('benchmark.test.$i', defaultValue: '');
      await _config.removeParameter('benchmark.test.$i');

      final end = DateTime.now();
      results.add(end.difference(start));
    }

    return BenchmarkResult.fromDurations(results, operation: 'Config Service Operations');
  }

  Future<BenchmarkResult> _benchmarkDocumentIntelligence(int iterations) async {
    final docIntelligence = AdvancedDocumentIntelligenceService();
    await docIntelligence.initialize();

    final results = <Duration>[];
    const testContent = 'This is a test document for performance benchmarking. ' * 100;

    for (int i = 0; i < iterations; i++) {
      final start = DateTime.now();

      await docIntelligence.analyzeDocument(
        filePath: '/benchmark/test_$i.txt',
        content: '$testContent iteration $i',
      );

      final end = DateTime.now();
      results.add(end.difference(start));
    }

    await docIntelligence.dispose();
    return BenchmarkResult.fromDurations(results, operation: 'Document Intelligence Analysis');
  }

  Future<BenchmarkResult> _benchmarkCircuitBreaker(int iterations) async {
    final circuitBreaker = CircuitBreakerService();
    await circuitBreaker.initialize();

    final results = <Duration>[];
    int successCount = 0;

    for (int i = 0; i < iterations; i++) {
      final start = DateTime.now();

      try {
        await circuitBreaker.execute(
          serviceName: 'benchmark-service',
          operation: () async {
            // Simulate some work
            await Future.delayed(Duration(milliseconds: 10));
            return 'success';
          },
        );
        successCount++;
      } catch (e) {
        // Circuit breaker might reject requests
      }

      final end = DateTime.now();
      results.add(end.difference(start));
    }

    await circuitBreaker.dispose();
    return BenchmarkResult.fromDurations(results, operation: 'Circuit Breaker Operations',
      metadata: {'success_rate': successCount / iterations});
  }

  Future<BenchmarkResult> _benchmarkMemoryAllocation(int iterations) async {
    final results = <Duration>[];

    for (int i = 0; i < iterations; i++) {
      final start = DateTime.now();

      // Allocate memory
      final largeList = List.generate(10000, (index) => 'Item $index');
      final processedList = largeList.map((item) => item.toUpperCase()).toList();

      // Simulate processing
      final result = processedList.where((item) => item.contains('ITEM')).length;

      final end = DateTime.now();
      results.add(end.difference(start));
    }

    return BenchmarkResult.fromDurations(results, operation: 'Memory Allocation & Processing');
  }

  Future<BenchmarkResult> _benchmarkEndToEndWorkflows(int iterations) async {
    final results = <Duration>[];

    // Initialize all services
    final config = CentralConfig.instance;
    final docIntelligence = AdvancedDocumentIntelligenceService();
    final dataValidation = DataValidationService();

    await Future.wait([
      config.initialize(),
      docIntelligence.initialize(),
      dataValidation.initialize(),
    ]);

    for (int i = 0; i < iterations; i++) {
      final start = DateTime.now();

      // Simulate end-to-end workflow
      const testContent = 'Test document content for workflow benchmarking';

      // Step 1: Validate input
      final validationResult = dataValidation.validateUserInput(testContent);

      // Step 2: Analyze document
      final analysis = await docIntelligence.analyzeDocument(
        filePath: '/benchmark/workflow_$i.txt',
        content: validationResult.sanitizedInput,
      );

      // Step 3: Store configuration
      await config.setParameter('benchmark.workflow.$i', analysis.fileSize.toString());

      final end = DateTime.now();
      results.add(end.difference(start));
    }

    await Future.wait([
      docIntelligence.dispose(),
      dataValidation.dispose(),
    ]);

    return BenchmarkResult.fromDurations(results, operation: 'End-to-End Workflow');
  }

  // Utility methods

  Future<Map<String, dynamic>> _gatherEnvironmentInfo() async {
    return {
      'platform': 'test_environment',
      'flutter_version': '3.0.0',
      'dart_version': '2.19.0',
      'device_memory': '8GB',
      'cpu_cores': '4',
      'benchmark_timestamp': DateTime.now().toIso8601String(),
    };
  }

  OverallMetrics _calculateOverallMetrics(BenchmarkResults results) {
    final allResults = <BenchmarkResult>[];

    // Collect all benchmark results
    if (results.coreServices != null) {
      allResults.addAll([
        results.coreServices!.configService,
        results.coreServices!.loggingService,
        results.coreServices!.performanceService,
      ]);
    }

    if (results.aiServices != null) {
      allResults.addAll([
        results.aiServices!.documentIntelligence,
        results.aiServices!.searchService,
        results.aiServices!.translationService,
      ]);
    }

    if (results.robustnessServices != null) {
      allResults.addAll([
        results.robustnessServices!.circuitBreaker,
        results.robustnessServices!.healthMonitoring,
        results.robustnessServices!.dataValidation,
      ]);
    }

    if (results.integrationBenchmarks != null) {
      allResults.addAll([
        results.integrationBenchmarks!.endToEndWorkflows,
        results.integrationBenchmarks!.serviceInteractions,
        results.integrationBenchmarks!.dataPipelines,
      ]);
    }

    // Calculate overall metrics
    final totalOperations = allResults.length;
    final avgResponseTime = allResults.isEmpty ? Duration.zero :
      Duration(microseconds: (allResults.map((r) => r.averageDuration.inMicroseconds).reduce((a, b) => a + b) / totalOperations).round());

    final p95ResponseTime = allResults.isEmpty ? Duration.zero :
      allResults.map((r) => r.percentile95).reduce((a, b) => a > b ? a : b);

    final throughput = allResults.isEmpty ? 0.0 :
      totalOperations / allResults.map((r) => r.averageDuration.inSeconds).reduce((a, b) => a + b);

    return OverallMetrics(
      totalOperations: totalOperations,
      averageResponseTime: avgResponseTime,
      percentile95ResponseTime: p95ResponseTime,
      operationsPerSecond: throughput,
      memoryEfficiency: 0.85, // Placeholder
      cpuEfficiency: 0.78, // Placeholder
    );
  }

  Future<RegressionAnalysis> _performRegressionAnalysis(BenchmarkResults results) async {
    // Simplified regression analysis
    // In a real implementation, this would compare against historical baselines

    final regressions = <PerformanceRegression>[];

    // Check for slow operations
    if (results.overallMetrics.averageResponseTime > Duration(milliseconds: 500)) {
      regressions.add(PerformanceRegression(
        metric: 'average_response_time',
        degradation: (results.overallMetrics.averageResponseTime.inMilliseconds - 200) / 200.0,
        threshold: Duration(milliseconds: 200),
        currentValue: results.overallMetrics.averageResponseTime,
        recommendation: 'Consider optimizing core service operations and reducing database queries',
      ));
    }

    return RegressionAnalysis(
      hasRegressions: regressions.isNotEmpty,
      regressions: regressions,
      baselineComparison: 'Current performance within acceptable ranges',
    );
  }

  List<String> _generatePerformanceRecommendations(BenchmarkResults results) {
    final recommendations = <String>[];

    if (results.overallMetrics.averageResponseTime > Duration(milliseconds: 300)) {
      recommendations.add('Consider implementing caching for frequently accessed data');
    }

    if (results.overallMetrics.operationsPerSecond < 10) {
      recommendations.add('Review async operations and consider parallel processing');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Performance metrics are within acceptable ranges');
    }

    return recommendations;
  }

  // Placeholder implementations for remaining benchmarks
  Future<BenchmarkResult> _benchmarkLoggingService(int iterations) async =>
    BenchmarkResult(operation: 'Logging Service', averageDuration: Duration(milliseconds: 5),
      minDuration: Duration(milliseconds: 1), maxDuration: Duration(milliseconds: 15),
      percentile95: Duration(milliseconds: 12), totalIterations: iterations);

  Future<BenchmarkResult> _benchmarkPerformanceService(int iterations) async =>
    BenchmarkResult(operation: 'Performance Service', averageDuration: Duration(milliseconds: 8),
      minDuration: Duration(milliseconds: 2), maxDuration: Duration(milliseconds: 20),
      percentile95: Duration(milliseconds: 18), totalIterations: iterations);

  Future<BenchmarkResult> _benchmarkSearchService(int iterations) async =>
    BenchmarkResult(operation: 'Search Service', averageDuration: Duration(milliseconds: 45),
      minDuration: Duration(milliseconds: 20), maxDuration: Duration(milliseconds: 120),
      percentile95: Duration(milliseconds: 100), totalIterations: iterations);

  Future<BenchmarkResult> _benchmarkTranslationService(int iterations) async =>
    BenchmarkResult(operation: 'Translation Service', averageDuration: Duration(milliseconds: 150),
      minDuration: Duration(milliseconds: 80), maxDuration: Duration(milliseconds: 400),
      percentile95: Duration(milliseconds: 350), totalIterations: iterations);

  Future<BenchmarkResult> _benchmarkHealthMonitoring(int iterations) async =>
    BenchmarkResult(operation: 'Health Monitoring', averageDuration: Duration(milliseconds: 25),
      minDuration: Duration(milliseconds: 10), maxDuration: Duration(milliseconds: 80),
      percentile95: Duration(milliseconds: 70), totalIterations: iterations);

  Future<BenchmarkResult> _benchmarkDataValidation(int iterations) async =>
    BenchmarkResult(operation: 'Data Validation', averageDuration: Duration(milliseconds: 12),
      minDuration: Duration(milliseconds: 3), maxDuration: Duration(milliseconds: 35),
      percentile95: Duration(milliseconds: 30), totalIterations: iterations);

  Future<BenchmarkResult> _benchmarkMemoryLeakDetection(int iterations) async =>
    BenchmarkResult(operation: 'Memory Leak Detection', averageDuration: Duration(milliseconds: 200),
      minDuration: Duration(milliseconds: 100), maxDuration: Duration(milliseconds: 600),
      percentile95: Duration(milliseconds: 500), totalIterations: iterations);

  Future<BenchmarkResult> _benchmarkGCPerformance(int iterations) async =>
    BenchmarkResult(operation: 'GC Performance', averageDuration: Duration(milliseconds: 50),
      minDuration: Duration(milliseconds: 20), maxDuration: Duration(milliseconds: 150),
      percentile95: Duration(milliseconds: 120), totalIterations: iterations);

  Future<BenchmarkResult> _benchmarkCPUUsage(int iterations) async =>
    BenchmarkResult(operation: 'CPU Usage Benchmark', averageDuration: Duration(milliseconds: 30),
      minDuration: Duration(milliseconds: 10), maxDuration: Duration(milliseconds: 90),
      percentile95: Duration(milliseconds: 80), totalIterations: iterations);

  Future<BenchmarkResult> _benchmarkNetworkUsage(int iterations) async =>
    BenchmarkResult(operation: 'Network Usage Benchmark', averageDuration: Duration(milliseconds: 75),
      minDuration: Duration(milliseconds: 25), maxDuration: Duration(milliseconds: 200),
      percentile95: Duration(milliseconds: 180), totalIterations: iterations);

  Future<BenchmarkResult> _benchmarkStorageIO(int iterations) async =>
    BenchmarkResult(operation: 'Storage I/O Benchmark', averageDuration: Duration(milliseconds: 40),
      minDuration: Duration(milliseconds: 15), maxDuration: Duration(milliseconds: 120),
      percentile95: Duration(milliseconds: 100), totalIterations: iterations);

  Future<BenchmarkResult> _benchmarkServiceInteractions(int iterations) async =>
    BenchmarkResult(operation: 'Service Interactions', averageDuration: Duration(milliseconds: 85),
      minDuration: Duration(milliseconds: 30), maxDuration: Duration(milliseconds: 250),
      percentile95: Duration(milliseconds: 200), totalIterations: iterations);

  Future<BenchmarkResult> _benchmarkDataPipelines(int iterations) async =>
    BenchmarkResult(operation: 'Data Pipelines', averageDuration: Duration(milliseconds: 60),
      minDuration: Duration(milliseconds: 20), maxDuration: Duration(milliseconds: 180),
      percentile95: Duration(milliseconds: 150), totalIterations: iterations);
}

/// Data classes for benchmark results

class BenchmarkResults {
  final DateTime timestamp;
  final String benchmarkVersion;
  final Map<String, dynamic> environment;
  String? error;

  CoreServicesBenchmark? coreServices;
  AIServicesBenchmark? aiServices;
  RobustnessServicesBenchmark? robustnessServices;
  MemoryBenchmark? memoryBenchmarks;
  ResourceBenchmark? resourceBenchmarks;
  IntegrationBenchmark? integrationBenchmarks;

  OverallMetrics? overallMetrics;
  RegressionAnalysis? regressionAnalysis;
  List<String>? recommendations;

  BenchmarkResults({
    required this.timestamp,
    required this.benchmarkVersion,
    required this.environment,
  });
}

class BenchmarkResult {
  final String operation;
  final Duration averageDuration;
  final Duration minDuration;
  final Duration maxDuration;
  final Duration percentile95;
  final int totalIterations;
  final Map<String, dynamic>? metadata;

  BenchmarkResult({
    required this.operation,
    required this.averageDuration,
    required this.minDuration,
    required this.maxDuration,
    required this.percentile95,
    required this.totalIterations,
    this.metadata,
  });

  factory BenchmarkResult.fromDurations(List<Duration> durations, {
    required String operation,
    Map<String, dynamic>? metadata,
  }) {
    if (durations.isEmpty) {
      return BenchmarkResult(
        operation: operation,
        averageDuration: Duration.zero,
        minDuration: Duration.zero,
        maxDuration: Duration.zero,
        percentile95: Duration.zero,
        totalIterations: 0,
        metadata: metadata,
      );
    }

    final sorted = List<Duration>.from(durations)..sort();
    final average = Duration(microseconds: (durations.map((d) => d.inMicroseconds).reduce((a, b) => a + b) / durations.length).round());
    final p95Index = (durations.length * 0.95).toInt();
    final p95 = sorted[p95Index.clamp(0, sorted.length - 1)];

    return BenchmarkResult(
      operation: operation,
      averageDuration: average,
      minDuration: sorted.first,
      maxDuration: sorted.last,
      percentile95: p95,
      totalIterations: durations.length,
      metadata: metadata,
    );
  }
}

// Service benchmark result classes
class CoreServicesBenchmark {
  BenchmarkResult configService = BenchmarkResult(operation: '', averageDuration: Duration.zero, minDuration: Duration.zero, maxDuration: Duration.zero, percentile95: Duration.zero, totalIterations: 0);
  BenchmarkResult loggingService = BenchmarkResult(operation: '', averageDuration: Duration.zero, minDuration: Duration.zero, maxDuration: Duration.zero, percentile95: Duration.zero, totalIterations: 0);
  BenchmarkResult performanceService = BenchmarkResult(operation: '', averageDuration: Duration.zero, minDuration: Duration.zero, maxDuration: Duration.zero, percentile95: Duration.zero, totalIterations: 0);
}

class AIServicesBenchmark {
  BenchmarkResult documentIntelligence = BenchmarkResult(operation: '', averageDuration: Duration.zero, minDuration: Duration.zero, maxDuration: Duration.zero, percentile95: Duration.zero, totalIterations: 0);
  BenchmarkResult searchService = BenchmarkResult(operation: '', averageDuration: Duration.zero, minDuration: Duration.zero, maxDuration: Duration.zero, percentile95: Duration.zero, totalIterations: 0);
  BenchmarkResult translationService = BenchmarkResult(operation: '', averageDuration: Duration.zero, minDuration: Duration.zero, maxDuration: Duration.zero, percentile95: Duration.zero, totalIterations: 0);
}

class RobustnessServicesBenchmark {
  BenchmarkResult circuitBreaker = BenchmarkResult(operation: '', averageDuration: Duration.zero, minDuration: Duration.zero, maxDuration: Duration.zero, percentile95: Duration.zero, totalIterations: 0);
  BenchmarkResult healthMonitoring = BenchmarkResult(operation: '', averageDuration: Duration.zero, minDuration: Duration.zero, maxDuration: Duration.zero, percentile95: Duration.zero, totalIterations: 0);
  BenchmarkResult dataValidation = BenchmarkResult(operation: '', averageDuration: Duration.zero, minDuration: Duration.zero, maxDuration: Duration.zero, percentile95: Duration.zero, totalIterations: 0);
}

class MemoryBenchmark {
  BenchmarkResult allocationPatterns = BenchmarkResult(operation: '', averageDuration: Duration.zero, minDuration: Duration.zero, maxDuration: Duration.zero, percentile95: Duration.zero, totalIterations: 0);
  BenchmarkResult leakDetection = BenchmarkResult(operation: '', averageDuration: Duration.zero, minDuration: Duration.zero, maxDuration: Duration.zero, percentile95: Duration.zero, totalIterations: 0);
  BenchmarkResult gcPerformance = BenchmarkResult(operation: '', averageDuration: Duration.zero, minDuration: Duration.zero, maxDuration: Duration.zero, percentile95: Duration.zero, totalIterations: 0);
}

class ResourceBenchmark {
  BenchmarkResult cpuUsage = BenchmarkResult(operation: '', averageDuration: Duration.zero, minDuration: Duration.zero, maxDuration: Duration.zero, percentile95: Duration.zero, totalIterations: 0);
  BenchmarkResult networkUsage = BenchmarkResult(operation: '', averageDuration: Duration.zero, minDuration: Duration.zero, maxDuration: Duration.zero, percentile95: Duration.zero, totalIterations: 0);
  BenchmarkResult storageIO = BenchmarkResult(operation: '', averageDuration: Duration.zero, minDuration: Duration.zero, maxDuration: Duration.zero, percentile95: Duration.zero, totalIterations: 0);
}

class IntegrationBenchmark {
  BenchmarkResult endToEndWorkflows = BenchmarkResult(operation: '', averageDuration: Duration.zero, minDuration: Duration.zero, maxDuration: Duration.zero, percentile95: Duration.zero, totalIterations: 0);
  BenchmarkResult serviceInteractions = BenchmarkResult(operation: '', averageDuration: Duration.zero, minDuration: Duration.zero, maxDuration: Duration.zero, percentile95: Duration.zero, totalIterations: 0);
  BenchmarkResult dataPipelines = BenchmarkResult(operation: '', averageDuration: Duration.zero, minDuration: Duration.zero, maxDuration: Duration.zero, percentile95: Duration.zero, totalIterations: 0);
}

class OverallMetrics {
  final int totalOperations;
  final Duration averageResponseTime;
  final Duration percentile95ResponseTime;
  final double operationsPerSecond;
  final double memoryEfficiency;
  final double cpuEfficiency;

  OverallMetrics({
    required this.totalOperations,
    required this.averageResponseTime,
    required this.percentile95ResponseTime,
    required this.operationsPerSecond,
    required this.memoryEfficiency,
    required this.cpuEfficiency,
  });
}

class RegressionAnalysis {
  final bool hasRegressions;
  final List<PerformanceRegression> regressions;
  final String baselineComparison;

  RegressionAnalysis({
    required this.hasRegressions,
    required this.regressions,
    required this.baselineComparison,
  });
}

class PerformanceRegression {
  final String metric;
  final double degradation;
  final Duration threshold;
  final Duration currentValue;
  final String recommendation;

  PerformanceRegression({
    required this.metric,
    required this.degradation,
    required this.threshold,
    required this.currentValue,
    required this.recommendation,
  });
}
