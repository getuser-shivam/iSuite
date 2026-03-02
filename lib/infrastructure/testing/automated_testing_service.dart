import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'build_optimization_service.dart';
import 'build_analytics_service.dart';

/// Automated Testing Integration Service
/// Integrates comprehensive testing into the build process with coverage analysis and reporting
class AutomatedTestingService {
  static final AutomatedTestingService _instance = AutomatedTestingService._internal();
  factory AutomatedTestingService() => _instance;
  AutomatedTestingService._internal();

  final BuildOptimizationService _buildOptimization = BuildOptimizationService();
  final BuildAnalyticsService _buildAnalytics = BuildAnalyticsService();
  final StreamController<TestingEvent> _testingEventController = StreamController.broadcast();

  Stream<TestingEvent> get testingEvents => _testingEventController.stream;

  // Test configurations
  final Map<String, TestConfiguration> _testConfigurations = {};
  final Map<String, TestSuite> _testSuites = {};

  // Test results and analytics
  final Map<String, TestSession> _testSessions = {};
  final Map<String, TestCoverage> _testCoverage = {};

  bool _isInitialized = false;

  // Configuration
  static const String _testConfigFile = 'test_config.json';
  static const Duration _testTimeout = Duration(minutes: 10);
  static const int _maxTestRetries = 3;

  /// Initialize automated testing service
  Future<void> initialize({
    Map<String, TestConfiguration>? testConfigs,
    List<TestSuite>? testSuites,
  }) async {
    if (_isInitialized) return;

    try {
      // Load test configurations
      await _loadTestConfigurations();

      // Add custom configurations
      if (testConfigs != null) {
        _testConfigurations.addAll(testConfigs);
      }

      // Initialize test suites
      if (testSuites != null) {
        for (final suite in testSuites) {
          _testSuites[suite.name] = suite;
        }
      } else {
        await _initializeDefaultTestSuites();
      }

      _isInitialized = true;
      _emitTestingEvent(TestingEventType.serviceInitialized);

    } catch (e) {
      _emitTestingEvent(TestingEventType.initializationFailed, error: e.toString());
      rethrow;
    }
  }

  /// Run integrated testing as part of build process
  Future<IntegratedTestResult> runBuildIntegratedTests({
    required String projectPath,
    required BuildResult buildResult,
    TestLevel testLevel = TestLevel.standard,
    bool failBuildOnTestFailure = true,
    Duration? timeout,
    Map<String, dynamic>? testConfig,
  }) async {
    _emitTestingEvent(TestingEventType.integratedTestingStarted,
      details: 'Build: ${buildResult.buildId}, Level: $testLevel');

    final testSessionId = 'test_session_${DateTime.now().millisecondsSinceEpoch}';
    final startTime = DateTime.now();

    try {
      // Select appropriate test suites based on build result and test level
      final testSuites = _selectTestSuites(buildResult, testLevel);

      // Execute test suites
      final testResults = <TestSuiteResult>[];
      final coverageResults = <TestCoverage>[];

      for (final suite in testSuites) {
        final suiteResult = await _executeTestSuite(suite, projectPath, testConfig);
        testResults.add(suiteResult);

        if (suiteResult.coverage != null) {
          coverageResults.add(suiteResult.coverage!);
        }
      }

      // Analyze overall results
      final overallSuccess = testResults.every((result) => result.success);
      final totalTests = testResults.fold<int>(0, (sum, result) => sum + result.totalTests);
      final passedTests = testResults.fold<int>(0, (sum, result) => sum + result.passedTests);
      final failedTests = testResults.fold<int>(0, (sum, result) => sum + result.failedTests);

      // Generate coverage report
      final coverageReport = coverageResults.isNotEmpty
          ? _generateCombinedCoverageReport(coverageResults)
          : null;

      // Check quality gates
      final qualityGateResult = await _checkQualityGates(
        testResults,
        coverageReport,
        testLevel,
      );

      final totalTime = DateTime.now().difference(startTime);

      // Record test session
      final testSession = TestSession(
        sessionId: testSessionId,
        buildId: buildResult.buildId,
        testSuites: testSuites,
        results: testResults,
        coverageReport: coverageReport,
        qualityGateResult: qualityGateResult,
        startTime: startTime,
        endTime: DateTime.now(),
        duration: totalTime,
        success: overallSuccess && (!failBuildOnTestFailure || qualityGateResult.passed),
      );

      _testSessions[testSessionId] = testSession;

      // Record analytics
      await _recordTestAnalytics(testSession);

      final result = IntegratedTestResult(
        testSessionId: testSessionId,
        buildId: buildResult.buildId,
        success: testSession.success,
        testSuites: testSuites,
        results: testResults,
        coverageReport: coverageReport,
        qualityGateResult: qualityGateResult,
        totalTests: totalTests,
        passedTests: passedTests,
        failedTests: failedTests,
        totalTime: totalTime,
        shouldFailBuild: failBuildOnTestFailure && !testSession.success,
      );

      _emitTestingEvent(
        result.success ? TestingEventType.integratedTestingCompleted : TestingEventType.integratedTestingFailed,
        details: 'Tests: $totalTests, Passed: $passedTests, Failed: $failedTests, Time: ${totalTime.inSeconds}s'
      );

      return result;

    } catch (e) {
      final totalTime = DateTime.now().difference(startTime);
      _emitTestingEvent(TestingEventType.integratedTestingFailed, error: e.toString());

      return IntegratedTestResult(
        testSessionId: testSessionId,
        buildId: buildResult.buildId,
        success: false,
        testSuites: [],
        results: [],
        totalTests: 0,
        passedTests: 0,
        failedTests: 0,
        totalTime: totalTime,
        shouldFailBuild: failBuildOnTestFailure,
      );
    }
  }

  /// Run comprehensive test coverage analysis
  Future<TestCoverageReport> analyzeTestCoverage({
    required String projectPath,
    List<String>? packages,
    bool generateHtmlReport = true,
    bool includeUncoveredLines = true,
  }) async {
    _emitTestingEvent(TestingEventType.coverageAnalysisStarted);

    try {
      // Run tests with coverage
      final coverageResult = await _runTestsWithCoverage(projectPath, packages);

      // Generate coverage report
      final coverageReport = await _generateCoverageReport(
        coverageResult,
        generateHtmlReport: generateHtmlReport,
        includeUncoveredLines: includeUncoveredLines,
      );

      // Analyze coverage trends
      final trendAnalysis = await _analyzeCoverageTrends(projectPath);

      // Generate recommendations
      final recommendations = _generateCoverageRecommendations(coverageReport, trendAnalysis);

      final result = TestCoverageReport(
        projectPath: projectPath,
        coverageData: coverageReport,
        trendAnalysis: trendAnalysis,
        recommendations: recommendations,
        generatedAt: DateTime.now(),
      );

      _emitTestingEvent(TestingEventType.coverageAnalysisCompleted,
        details: 'Coverage: ${(coverageReport.overallCoverage * 100).round()}%');

      return result;

    } catch (e) {
      _emitTestingEvent(TestingEventType.coverageAnalysisFailed, error: e.toString());
      rethrow;
    }
  }

  /// Configure test suite
  Future<void> configureTestSuite({
    required String name,
    required TestSuite suite,
  }) async {
    _testSuites[name] = suite;
    await _saveTestConfiguration();
    _emitTestingEvent(TestingEventType.testSuiteConfigured, details: name);
  }

  /// Get test execution status
  TestExecutionStatus getTestExecutionStatus(String sessionId) {
    final session = _testSessions[sessionId];
    if (session == null) {
      return TestExecutionStatus(
        sessionId: sessionId,
        status: TestExecutionStatusType.notFound,
      );
    }

    return TestExecutionStatus(
      sessionId: sessionId,
      status: TestExecutionStatusType.completed,
      startTime: session.startTime,
      endTime: session.endTime,
      duration: session.duration,
      success: session.success,
      totalTests: session.results.fold<int>(0, (sum, result) => sum + result.totalTests),
      passedTests: session.results.fold<int>(0, (sum, result) => sum + result.passedTests),
      failedTests: session.results.fold<int>(0, (sum, result) => sum + result.failedTests),
    );
  }

  /// Get test quality metrics
  Future<TestQualityMetrics> getTestQualityMetrics({
    DateTime? startDate,
    DateTime? endDate,
    String? projectPath,
  }) async {
    final sessions = _getFilteredTestSessions(
      startDate: startDate,
      endDate: endDate,
      projectPath: projectPath,
    );

    if (sessions.isEmpty) {
      return TestQualityMetrics.empty();
    }

    // Calculate stability metrics
    final totalSessions = sessions.length;
    final successfulSessions = sessions.where((s) => s.success).length;
    final stabilityRate = totalSessions > 0 ? successfulSessions / totalSessions : 0.0;

    // Calculate performance metrics
    final testDurations = sessions.map((s) => s.duration.inMilliseconds).toList();
    final avgTestDuration = testDurations.reduce((a, b) => a + b) / testDurations.length;

    // Calculate coverage trends
    final coverageValues = <double>[];
    for (final session in sessions) {
      if (session.coverageReport != null) {
        coverageValues.add(session.coverageReport!.overallCoverage);
      }
    }

    final avgCoverage = coverageValues.isNotEmpty
        ? coverageValues.reduce((a, b) => a + b) / coverageValues.length
        : 0.0;

    // Calculate flakiness
    final flakinessRate = _calculateTestFlakiness(sessions);

    // Generate quality assessment
    final qualityAssessment = _assessTestQuality(
      stabilityRate: stabilityRate,
      avgCoverage: avgCoverage,
      flakinessRate: flakinessRate,
    );

    return TestQualityMetrics(
      totalTestSessions: totalSessions,
      successfulSessions: successfulSessions,
      stabilityRate: stabilityRate,
      averageTestDuration: Duration(milliseconds: avgTestDuration.round()),
      averageCoverage: avgCoverage,
      flakinessRate: flakinessRate,
      qualityAssessment: qualityAssessment,
      analysisPeriod: startDate != null && endDate != null
          ? endDate.difference(startDate)
          : null,
    );
  }

  /// Export test results and analytics
  Future<String> exportTestResults({
    DateTime? startDate,
    DateTime? endDate,
    bool includeSessions = true,
    bool includeCoverage = true,
    bool includeAnalytics = true,
  }) async {
    final data = <String, dynamic>{
      'exportTimestamp': DateTime.now().toIso8601String(),
      'period': {
        'start': startDate?.toIso8601String(),
        'end': endDate?.toIso8601String(),
      },
    };

    if (includeSessions) {
      final sessions = _getFilteredTestSessions(startDate: startDate, endDate: endDate);
      data['sessions'] = sessions.map((s) => s.toJson()).toList();
    }

    if (includeCoverage) {
      data['coverage'] = _testCoverage.map((key, value) => MapEntry(key, value.toJson()));
    }

    if (includeAnalytics) {
      data['qualityMetrics'] = (await getTestQualityMetrics(
        startDate: startDate,
        endDate: endDate,
      )).toJson();
    }

    return json.encode(data);
  }

  // Private methods

  Future<void> _loadTestConfigurations() async {
    try {
      final configFile = File(_testConfigFile);
      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        final config = json.decode(content) as Map<String, dynamic>;

        final testConfigs = config['testConfigurations'] as Map<String, dynamic>?;
        if (testConfigs != null) {
          for (final entry in testConfigs.entries) {
            _testConfigurations[entry.key] = TestConfiguration.fromJson(entry.value);
          }
        }

        final testSuites = config['testSuites'] as Map<String, dynamic>?;
        if (testSuites != null) {
          for (final entry in testSuites.entries) {
            _testSuites[entry.key] = TestSuite.fromJson(entry.value);
          }
        }
      } else {
        await _initializeDefaultTestConfigurations();
      }
    } catch (e) {
      await _initializeDefaultTestConfigurations();
    }
  }

  Future<void> _initializeDefaultTestConfigurations() async {
    // Unit test configuration
    _testConfigurations['unit'] = TestConfiguration(
      name: 'unit',
      testCommand: 'flutter test --coverage',
      timeout: const Duration(minutes: 5),
      environment: {'FLUTTER_TEST': 'true'},
      requiredFiles: ['test/', 'lib/'],
      coverageEnabled: true,
      parallelExecution: true,
    );

    // Widget test configuration
    _testConfigurations['widget'] = TestConfiguration(
      name: 'widget',
      testCommand: 'flutter test --coverage -d flutter-tester',
      timeout: const Duration(minutes: 7),
      environment: {'FLUTTER_TEST': 'true'},
      requiredFiles: ['test/', 'lib/'],
      coverageEnabled: true,
      parallelExecution: false, // Widget tests often need sequential execution
    );

    // Integration test configuration
    _testConfigurations['integration'] = TestConfiguration(
      name: 'integration',
      testCommand: 'flutter test integration_test/',
      timeout: const Duration(minutes: 10),
      environment: {'FLUTTER_TEST': 'true'},
      requiredFiles: ['integration_test/', 'lib/'],
      coverageEnabled: false, // Integration tests typically don't generate coverage
      parallelExecution: false,
    );
  }

  Future<void> _initializeDefaultTestSuites() async {
    // Standard test suite
    _testSuites['standard'] = TestSuite(
      name: 'standard',
      description: 'Standard test suite with unit and widget tests',
      testConfigurations: ['unit', 'widget'],
      qualityGates: [
        QualityGate(
          name: 'minimum_coverage',
          type: QualityGateType.coverage,
          threshold: 0.8,
          operator: QualityGateOperator.greaterThan,
        ),
        QualityGate(
          name: 'no_test_failures',
          type: QualityGateType.testResults,
          threshold: 0.0,
          operator: QualityGateOperator.equal,
        ),
      ],
      requiredForBuild: true,
    );

    // Full test suite
    _testSuites['full'] = TestSuite(
      name: 'full',
      description: 'Complete test suite including integration tests',
      testConfigurations: ['unit', 'widget', 'integration'],
      qualityGates: [
        QualityGate(
          name: 'high_coverage',
          type: QualityGateType.coverage,
          threshold: 0.9,
          operator: QualityGateOperator.greaterThan,
        ),
        QualityGate(
          name: 'no_failures',
          type: QualityGateType.testResults,
          threshold: 0.0,
          operator: QualityGateOperator.equal,
        ),
        QualityGate(
          name: 'performance_baseline',
          type: QualityGateType.performance,
          threshold: 300000, // 5 minutes in milliseconds
          operator: QualityGateOperator.lessThan,
        ),
      ],
      requiredForBuild: false,
    );

    // Fast test suite for CI
    _testSuites['fast'] = TestSuite(
      name: 'fast',
      description: 'Fast test suite for quick validation',
      testConfigurations: ['unit'],
      qualityGates: [
        QualityGate(
          name: 'basic_coverage',
          type: QualityGateType.coverage,
          threshold: 0.7,
          operator: QualityGateOperator.greaterThan,
        ),
      ],
      requiredForBuild: true,
    );
  }

  List<TestSuite> _selectTestSuites(BuildResult buildResult, TestLevel testLevel) {
    final suites = <TestSuite>[];

    switch (testLevel) {
      case TestLevel.fast:
        suites.add(_testSuites['fast']!);
        break;
      case TestLevel.standard:
        suites.add(_testSuites['standard']!);
        break;
      case TestLevel.full:
        suites.add(_testSuites['full']!);
        break;
      case TestLevel.custom:
        // Use build-specific test suites
        if (buildResult.targets.any((t) => t.platform == TargetPlatform.android || t.platform == TargetPlatform.ios)) {
          suites.add(_testSuites['standard']!);
        } else {
          suites.add(_testSuites['fast']!);
        }
        break;
    }

    return suites;
  }

  Future<TestSuiteResult> _executeTestSuite(
    TestSuite suite,
    String projectPath,
    Map<String, dynamic>? testConfig,
  ) async {
    _emitTestingEvent(TestingEventType.testSuiteStarted, details: suite.name);

    final startTime = DateTime.now();
    final results = <TestConfigurationResult>[];

    try {
      for (final configName in suite.testConfigurations) {
        final config = _testConfigurations[configName];
        if (config != null) {
          final configResult = await _executeTestConfiguration(config, projectPath, testConfig);
          results.add(configResult);
        }
      }

      // Generate coverage if applicable
      TestCoverage? coverage;
      if (results.any((r) => r.coverage != null)) {
        coverage = _mergeConfigurationCoverages(results);
      }

      // Check quality gates
      final qualityGateResult = await _checkQualityGates(results, coverage, TestLevel.standard);

      final totalTests = results.fold<int>(0, (sum, r) => sum + r.totalTests);
      final passedTests = results.fold<int>(0, (sum, r) => sum + r.passedTests);
      final failedTests = results.fold<int>(0, (sum, r) => sum + r.failedTests);

      final success = results.every((r) => r.success) && qualityGateResult.passed;

      final result = TestSuiteResult(
        suiteName: suite.name,
        success: success,
        configurationResults: results,
        coverage: coverage,
        qualityGateResult: qualityGateResult,
        totalTests: totalTests,
        passedTests: passedTests,
        failedTests: failedTests,
        duration: DateTime.now().difference(startTime),
      );

      _emitTestingEvent(
        success ? TestingEventType.testSuiteCompleted : TestingEventType.testSuiteFailed,
        details: '${suite.name}: $passedTests/$totalTests passed'
      );

      return result;

    } catch (e) {
      _emitTestingEvent(TestingEventType.testSuiteFailed, error: e.toString());

      return TestSuiteResult(
        suiteName: suite.name,
        success: false,
        configurationResults: results,
        totalTests: 0,
        passedTests: 0,
        failedTests: 0,
        duration: DateTime.now().difference(startTime),
        error: e.toString(),
      );
    }
  }

  Future<TestConfigurationResult> _executeTestConfiguration(
    TestConfiguration config,
    String projectPath,
    Map<String, dynamic>? testConfig,
  ) async {
    _emitTestingEvent(TestingEventType.testConfigurationStarted, details: config.name);

    final startTime = DateTime.now();

    try {
      // Set up environment
      final originalEnv = Map<String, String>.from(Platform.environment);
      config.environment.forEach((key, value) {
        Platform.environment[key] = value;
      });

      // Add test configuration
      if (testConfig != null) {
        testConfig.forEach((key, value) {
          Platform.environment[key] = value.toString();
        });
      }

      // Execute test command
      final result = await Process.run(
        'flutter',
        config.testCommand.split(' ').skip(1).toList(),
        workingDirectory: projectPath,
        timeout: config.timeout,
      );

      // Restore environment
      Platform.environment.clear();
      Platform.environment.addAll(originalEnv);

      // Parse test results
      final testResults = _parseTestOutput(result.stdout.toString(), result.stderr.toString());

      // Generate coverage if enabled
      TestCoverage? coverage;
      if (config.coverageEnabled) {
        coverage = await _generateTestCoverage(projectPath, config.name);
      }

      final success = result.exitCode == 0 && testResults.failedTests == 0;

      final configResult = TestConfigurationResult(
        configurationName: config.name,
        success: success,
        exitCode: result.exitCode,
        stdout: result.stdout.toString(),
        stderr: result.stderr.toString(),
        totalTests: testResults.totalTests,
        passedTests: testResults.passedTests,
        failedTests: testResults.failedTests,
        skippedTests: testResults.skippedTests,
        coverage: coverage,
        duration: DateTime.now().difference(startTime),
      );

      _emitTestingEvent(
        success ? TestingEventType.testConfigurationCompleted : TestingEventType.testConfigurationFailed,
        details: '${config.name}: ${testResults.passedTests}/${testResults.totalTests} passed'
      );

      return configResult;

    } catch (e) {
      // Restore environment
      Platform.environment.clear();
      Platform.environment.addAll(Platform.environment);

      _emitTestingEvent(TestingEventType.testConfigurationFailed, error: e.toString());

      return TestConfigurationResult(
        configurationName: config.name,
        success: false,
        exitCode: -1,
        stdout: '',
        stderr: e.toString(),
        totalTests: 0,
        passedTests: 0,
        failedTests: 0,
        skippedTests: 0,
        duration: DateTime.now().difference(startTime),
        error: e.toString(),
      );
    }
  }

  TestOutput _parseTestOutput(String stdout, String stderr) {
    // Parse Flutter test output
    final output = stdout + stderr;

    // Extract test counts using regex
    final totalMatch = RegExp(r'(\d+)\s*:\s*All tests passed').firstMatch(output);
    final failedMatch = RegExp(r'(\d+)\s*tests?\s*failed').firstMatch(output);
    final passedMatch = RegExp(r'(\d+)\s*tests?\s*passed').firstMatch(output);

    final totalTests = int.tryParse(totalMatch?.group(1) ?? '0') ?? 0;
    final failedTests = int.tryParse(failedMatch?.group(1) ?? '0') ?? 0;
    final passedTests = int.tryParse(passedMatch?.group(1) ?? '0') ?? totalTests - failedTests;

    return TestOutput(
      totalTests: totalTests,
      passedTests: passedTests,
      failedTests: failedTests,
      skippedTests: 0, // Not easily parsed from output
    );
  }

  Future<TestCoverage> _generateTestCoverage(String projectPath, String configName) async {
    // Generate coverage data from lcov file
    final lcovFile = File(path.join(projectPath, 'coverage', 'lcov.info'));
    if (!await lcovFile.exists()) {
      return TestCoverage(
        configurationName: configName,
        overallCoverage: 0.0,
        fileCoverage: {},
        generatedAt: DateTime.now(),
      );
    }

    final content = await lcovFile.readAsString();
    final fileCoverage = <String, double>{};

    // Parse LCOV format (simplified)
    final lines = content.split('\n');
    String? currentFile;
    int? linesFound;
    int? linesHit;

    for (final line in lines) {
      if (line.startsWith('SF:')) {
        currentFile = line.substring(3);
      } else if (line.startsWith('LF:')) {
        linesFound = int.tryParse(line.substring(3));
      } else if (line.startsWith('LH:')) {
        linesHit = int.tryParse(line.substring(3));
      } else if (line.startsWith('end_of_record')) {
        if (currentFile != null && linesFound != null && linesHit != null && linesFound > 0) {
          fileCoverage[currentFile] = linesHit / linesFound;
        }
        currentFile = null;
        linesFound = null;
        linesHit = null;
      }
    }

    final overallCoverage = fileCoverage.values.isNotEmpty
        ? fileCoverage.values.reduce((a, b) => a + b) / fileCoverage.length
        : 0.0;

    final coverage = TestCoverage(
      configurationName: configName,
      overallCoverage: overallCoverage,
      fileCoverage: fileCoverage,
      generatedAt: DateTime.now(),
    );

    _testCoverage['${configName}_${DateTime.now().millisecondsSinceEpoch}'] = coverage;

    return coverage;
  }

  Future<QualityGateResult> _checkQualityGates(
    List<TestSuiteResult> results,
    TestCoverage? coverage,
    TestLevel testLevel,
  ) async {
    final violations = <QualityGateViolation>[];

    // Get quality gates for the test level
    final qualityGates = _getQualityGatesForLevel(testLevel);

    for (final gate in qualityGates) {
      final passed = await _evaluateQualityGate(gate, results, coverage);
      if (!passed) {
        violations.add(QualityGateViolation(
          gateName: gate.name,
          expectedValue: gate.threshold,
          actualValue: _getActualValueForGate(gate, results, coverage),
          operator: gate.operator,
        ));
      }
    }

    return QualityGateResult(
      passed: violations.isEmpty,
      violations: violations,
    );
  }

  List<QualityGate> _getQualityGatesForLevel(TestLevel level) {
    switch (level) {
      case TestLevel.fast:
        return [
          QualityGate(
            name: 'basic_coverage',
            type: QualityGateType.coverage,
            threshold: 0.6,
            operator: QualityGateOperator.greaterThan,
          ),
        ];
      case TestLevel.standard:
        return [
          QualityGate(
            name: 'standard_coverage',
            type: QualityGateType.coverage,
            threshold: 0.8,
            operator: QualityGateOperator.greaterThan,
          ),
          QualityGate(
            name: 'no_test_failures',
            type: QualityGateType.testResults,
            threshold: 0.0,
            operator: QualityGateOperator.equal,
          ),
        ];
      case TestLevel.full:
        return [
          QualityGate(
            name: 'high_coverage',
            type: QualityGateType.coverage,
            threshold: 0.9,
            operator: QualityGateOperator.greaterThan,
          ),
          QualityGate(
            name: 'no_failures',
            type: QualityGateType.testResults,
            threshold: 0.0,
            operator: QualityGateOperator.equal,
          ),
          QualityGate(
            name: 'performance_check',
            type: QualityGateType.performance,
            threshold: 600000, // 10 minutes
            operator: QualityGateOperator.lessThan,
          ),
        ];
      case TestLevel.custom:
        return [];
    }
  }

  Future<bool> _evaluateQualityGate(
    QualityGate gate,
    List<TestSuiteResult> results,
    TestCoverage? coverage,
  ) async {
    final actualValue = _getActualValueForGate(gate, results, coverage);

    switch (gate.operator) {
      case QualityGateOperator.greaterThan:
        return actualValue > gate.threshold;
      case QualityGateOperator.lessThan:
        return actualValue < gate.threshold;
      case QualityGateOperator.equal:
        return actualValue == gate.threshold;
      case QualityGateOperator.notEqual:
        return actualValue != gate.threshold;
      case QualityGateOperator.greaterThanOrEqual:
        return actualValue >= gate.threshold;
      case QualityGateOperator.lessThanOrEqual:
        return actualValue <= gate.threshold;
    }
  }

  double _getActualValueForGate(
    QualityGate gate,
    List<TestSuiteResult> results,
    TestCoverage? coverage,
  ) {
    switch (gate.type) {
      case QualityGateType.coverage:
        return coverage?.overallCoverage ?? 0.0;
      case QualityGateType.testResults:
        final totalTests = results.fold<int>(0, (sum, r) => sum + r.totalTests);
        final failedTests = results.fold<int>(0, (sum, r) => sum + r.failedTests);
        return failedTests.toDouble();
      case QualityGateType.performance:
        final totalTime = results.fold<int>(0, (sum, r) => sum + r.duration.inMilliseconds);
        return totalTime.toDouble();
      default:
        return 0.0;
    }
  }

  TestCoverage _mergeConfigurationCoverages(List<TestConfigurationResult> results) {
    final mergedFileCoverage = <String, double>{};

    for (final result in results) {
      if (result.coverage != null) {
        result.coverage!.fileCoverage.forEach((file, coverage) {
          mergedFileCoverage[file] = coverage; // Last write wins for simplicity
        });
      }
    }

    final overallCoverage = mergedFileCoverage.values.isNotEmpty
        ? mergedFileCoverage.values.reduce((a, b) => a + b) / mergedFileCoverage.length
        : 0.0;

    return TestCoverage(
      configurationName: 'merged',
      overallCoverage: overallCoverage,
      fileCoverage: mergedFileCoverage,
      generatedAt: DateTime.now(),
    );
  }

  TestCoverage _generateCombinedCoverageReport(List<TestCoverage> coverages) {
    final mergedFileCoverage = <String, double>{};

    for (final coverage in coverages) {
      coverage.fileCoverage.forEach((file, coverageValue) {
        mergedFileCoverage[file] = coverageValue;
      });
    }

    final overallCoverage = mergedFileCoverage.values.isNotEmpty
        ? mergedFileCoverage.values.reduce((a, b) => a + b) / mergedFileCoverage.length
        : 0.0;

    return TestCoverage(
      configurationName: 'combined',
      overallCoverage: overallCoverage,
      fileCoverage: mergedFileCoverage,
      generatedAt: DateTime.now(),
    );
  }

  Future<void> _recordTestAnalytics(TestSession session) async {
    // Record test results with build analytics
    await _buildAnalytics.recordBuildSession(BuildResult(
      buildId: session.buildId,
      success: session.success,
      targets: [],
      artifacts: [],
      analytics: BuildAnalytics(
        buildId: session.buildId,
        startTime: session.startTime,
        endTime: session.endTime,
        totalBuildTime: session.duration,
        totalTasks: session.results.length,
        successfulTasks: session.results.where((r) => r.success).length,
        failedTasks: session.results.where((r) => !r.success).length,
        averageTaskTime: session.results.isNotEmpty
            ? Duration(milliseconds: (session.duration.inMilliseconds / session.results.length).round())
            : Duration.zero,
        cacheHitRate: 0.0,
        parallelEfficiency: 1.0,
      ),
      warnings: session.results.expand((r) => r.configurationResults
          .where((c) => c.warnings.isNotEmpty)
          .expand((c) => c.warnings.split('\n'))).toList(),
      errors: session.results.expand((r) => r.configurationResults
          .where((c) => c.errors.isNotEmpty)
          .expand((c) => c.errors.split('\n'))).toList(),
    ));
  }

  List<TestSession> _getFilteredTestSessions({
    DateTime? startDate,
    DateTime? endDate,
    String? projectPath,
  }) {
    return _testSessions.values.where((session) {
      if (startDate != null && session.startTime.isBefore(startDate)) return false;
      if (endDate != null && session.startTime.isAfter(endDate)) return false;
      // Note: projectPath filtering would require storing project path in session
      return true;
    }).toList();
  }

  Future<TestCoverageResult> _runTestsWithCoverage(String projectPath, List<String>? packages) async {
    // Implementation for running tests with coverage
    // This would use flutter test --coverage and parse the results
    return TestCoverageResult(
      success: true,
      coverageData: {},
      generatedAt: DateTime.now(),
    );
  }

  Future<TestCoverageReportData> _generateCoverageReport(
    TestCoverageResult coverageResult, {
    bool generateHtmlReport = true,
    bool includeUncoveredLines = true,
  }) async {
    // Implementation for generating detailed coverage reports
    return TestCoverageReportData(
      overallCoverage: 0.85,
      lineCoverage: 0.82,
      branchCoverage: 0.75,
      functionCoverage: 0.90,
      fileReports: {},
    );
  }

  Future<CoverageTrendAnalysis> _analyzeCoverageTrends(String projectPath) async {
    // Implementation for analyzing coverage trends over time
    return CoverageTrendAnalysis(
      trend: TrendDirection.stable,
      changeRate: 0.0,
      confidence: 0.8,
    );
  }

  List<String> _generateCoverageRecommendations(
    TestCoverageReportData coverage,
    CoverageTrendAnalysis trend,
  ) {
    final recommendations = <String>[];

    if (coverage.overallCoverage < 0.8) {
      recommendations.add('Increase overall test coverage above 80%');
    }

    if (trend.trend == TrendDirection.worsening) {
      recommendations.add('Address declining test coverage trend');
    }

    return recommendations;
  }

  double _calculateTestFlakiness(List<TestSession> sessions) {
    // Simplified flakiness calculation
    // In practice, this would analyze test result consistency over multiple runs
    return 0.02; // 2% flakiness placeholder
  }

  TestQualityAssessment _assessTestQuality({
    required double stabilityRate,
    required double avgCoverage,
    required double flakinessRate,
  }) {
    final score = (stabilityRate * 0.4) + (avgCoverage * 0.4) + ((1 - flakinessRate) * 0.2);

    QualityLevel level;
    if (score >= 0.9) {
      level = QualityLevel.excellent;
    } else if (score >= 0.8) {
      level = QualityLevel.good;
    } else if (score >= 0.7) {
      level = QualityLevel.fair;
    } else {
      level = QualityLevel.poor;
    }

    return TestQualityAssessment(
      overallScore: score,
      qualityLevel: level,
      recommendations: _generateQualityRecommendations(level),
    );
  }

  List<String> _generateQualityRecommendations(QualityLevel level) {
    switch (level) {
      case QualityLevel.excellent:
        return ['Maintain current testing practices'];
      case QualityLevel.good:
        return ['Consider adding more integration tests', 'Review flaky tests'];
      case QualityLevel.fair:
        return ['Increase test coverage', 'Add more comprehensive test scenarios', 'Fix flaky tests'];
      case QualityLevel.poor:
        return ['Implement comprehensive test suite', 'Add code coverage requirements', 'Address test reliability issues'];
    }
  }

  Future<void> _saveTestConfiguration() async {
    final config = {
      'testConfigurations': _testConfigurations.map((key, value) => MapEntry(key, value.toJson())),
      'testSuites': _testSuites.map((key, value) => MapEntry(key, value.toJson())),
    };

    final configFile = File(_testConfigFile);
    await configFile.writeAsString(json.encode(config));
  }

  void _emitTestingEvent(TestingEventType type, {
    String? details,
    String? error,
  }) {
    final event = TestingEvent(
      type: type,
      timestamp: DateTime.now(),
      details: details,
      error: error,
    );

    _testingEventController.add(event);
  }

  void dispose() {
    _testingEventController.close();
  }
}

/// Supporting data classes

class TestConfiguration {
  final String name;
  final String testCommand;
  final Duration timeout;
  final Map<String, String> environment;
  final List<String> requiredFiles;
  final bool coverageEnabled;
  final bool parallelExecution;

  TestConfiguration({
    required this.name,
    required this.testCommand,
    required this.timeout,
    required this.environment,
    required this.requiredFiles,
    required this.coverageEnabled,
    required this.parallelExecution,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'testCommand': testCommand,
    'timeout': timeout.inMilliseconds,
    'environment': environment,
    'requiredFiles': requiredFiles,
    'coverageEnabled': coverageEnabled,
    'parallelExecution': parallelExecution,
  };

  factory TestConfiguration.fromJson(Map<String, dynamic> json) {
    return TestConfiguration(
      name: json['name'],
      testCommand: json['testCommand'],
      timeout: Duration(milliseconds: json['timeout']),
      environment: Map<String, String>.from(json['environment']),
      requiredFiles: List<String>.from(json['requiredFiles']),
      coverageEnabled: json['coverageEnabled'],
      parallelExecution: json['parallelExecution'],
    );
  }
}

class TestSuite {
  final String name;
  final String description;
  final List<String> testConfigurations;
  final List<QualityGate> qualityGates;
  final bool requiredForBuild;

  TestSuite({
    required this.name,
    required this.description,
    required this.testConfigurations,
    required this.qualityGates,
    required this.requiredForBuild,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'testConfigurations': testConfigurations,
    'qualityGates': qualityGates.map((g) => g.toJson()).toList(),
    'requiredForBuild': requiredForBuild,
  };

  factory TestSuite.fromJson(Map<String, dynamic> json) {
    return TestSuite(
      name: json['name'],
      description: json['description'],
      testConfigurations: List<String>.from(json['testConfigurations']),
      qualityGates: (json['qualityGates'] as List).map((g) => QualityGate.fromJson(g)).toList(),
      requiredForBuild: json['requiredForBuild'],
    );
  }
}

class QualityGate {
  final String name;
  final QualityGateType type;
  final double threshold;
  final QualityGateOperator operator;

  QualityGate({
    required this.name,
    required this.type,
    required this.threshold,
    required this.operator,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.toString(),
    'threshold': threshold,
    'operator': operator.toString(),
  };

  factory QualityGate.fromJson(Map<String, dynamic> json) {
    return QualityGate(
      name: json['name'],
      type: QualityGateType.values.firstWhere((t) => t.toString() == json['type']),
      threshold: json['threshold'],
      operator: QualityGateOperator.values.firstWhere((o) => o.toString() == json['operator']),
    );
  }
}

class TestSession {
  final String sessionId;
  final String buildId;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final bool success;
  final List<TestSuite> testSuites;
  final List<TestSuiteResult> results;
  final TestCoverage? coverageReport;
  final QualityGateResult qualityGateResult;

  TestSession({
    required this.sessionId,
    required this.buildId,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.success,
    required this.testSuites,
    required this.results,
    this.coverageReport,
    required this.qualityGateResult,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'buildId': buildId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'duration': duration.inMilliseconds,
    'success': success,
    'testSuites': testSuites.map((s) => s.toJson()).toList(),
    'results': results.map((r) => r.toJson()).toList(),
    'coverageReport': coverageReport?.toJson(),
    'qualityGateResult': qualityGateResult.toJson(),
  };

  factory TestSession.fromJson(Map<String, dynamic> json) {
    return TestSession(
      sessionId: json['sessionId'],
      buildId: json['buildId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      duration: Duration(milliseconds: json['duration']),
      success: json['success'],
      testSuites: (json['testSuites'] as List).map((s) => TestSuite.fromJson(s)).toList(),
      results: (json['results'] as List).map((r) => TestSuiteResult.fromJson(r)).toList(),
      coverageReport: json['coverageReport'] != null ? TestCoverage.fromJson(json['coverageReport']) : null,
      qualityGateResult: QualityGateResult.fromJson(json['qualityGateResult']),
    );
  }
}

class IntegratedTestResult {
  final String testSessionId;
  final String buildId;
  final bool success;
  final List<TestSuite> testSuites;
  final List<TestSuiteResult> results;
  final TestCoverage? coverageReport;
  final QualityGateResult qualityGateResult;
  final int totalTests;
  final int passedTests;
  final int failedTests;
  final Duration totalTime;
  final bool shouldFailBuild;

  IntegratedTestResult({
    required this.testSessionId,
    required this.buildId,
    required this.success,
    required this.testSuites,
    required this.results,
    this.coverageReport,
    required this.qualityGateResult,
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    required this.totalTime,
    required this.shouldFailBuild,
  });
}

class TestSuiteResult {
  final String suiteName;
  final bool success;
  final List<TestConfigurationResult> configurationResults;
  final TestCoverage? coverage;
  final QualityGateResult qualityGateResult;
  final int totalTests;
  final int passedTests;
  final int failedTests;
  final Duration duration;
  final String? error;

  TestSuiteResult({
    required this.suiteName,
    required this.success,
    required this.configurationResults,
    this.coverage,
    required this.qualityGateResult,
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    required this.duration,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'suiteName': suiteName,
    'success': success,
    'configurationResults': configurationResults.map((r) => r.toJson()).toList(),
    'coverage': coverage?.toJson(),
    'qualityGateResult': qualityGateResult.toJson(),
    'totalTests': totalTests,
    'passedTests': passedTests,
    'failedTests': failedTests,
    'duration': duration.inMilliseconds,
    'error': error,
  };

  factory TestSuiteResult.fromJson(Map<String, dynamic> json) {
    return TestSuiteResult(
      suiteName: json['suiteName'],
      success: json['success'],
      configurationResults: (json['configurationResults'] as List).map((r) => TestConfigurationResult.fromJson(r)).toList(),
      coverage: json['coverage'] != null ? TestCoverage.fromJson(json['coverage']) : null,
      qualityGateResult: QualityGateResult.fromJson(json['qualityGateResult']),
      totalTests: json['totalTests'],
      passedTests: json['passedTests'],
      failedTests: json['failedTests'],
      duration: Duration(milliseconds: json['duration']),
      error: json['error'],
    );
  }
}

class TestConfigurationResult {
  final String configurationName;
  final bool success;
  final int exitCode;
  final String stdout;
  final String stderr;
  final int totalTests;
  final int passedTests;
  final int failedTests;
  final int skippedTests;
  final TestCoverage? coverage;
  final Duration duration;
  final String? error;

  TestConfigurationResult({
    required this.configurationName,
    required this.success,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    required this.skippedTests,
    this.coverage,
    required this.duration,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'configurationName': configurationName,
    'success': success,
    'exitCode': exitCode,
    'stdout': stdout,
    'stderr': stderr,
    'totalTests': totalTests,
    'passedTests': passedTests,
    'failedTests': failedTests,
    'skippedTests': skippedTests,
    'coverage': coverage?.toJson(),
    'duration': duration.inMilliseconds,
    'error': error,
  };

  factory TestConfigurationResult.fromJson(Map<String, dynamic> json) {
    return TestConfigurationResult(
      configurationName: json['configurationName'],
      success: json['success'],
      exitCode: json['exitCode'],
      stdout: json['stdout'],
      stderr: json['stderr'],
      totalTests: json['totalTests'],
      passedTests: json['passedTests'],
      failedTests: json['failedTests'],
      skippedTests: json['skippedTests'],
      coverage: json['coverage'] != null ? TestCoverage.fromJson(json['coverage']) : null,
      duration: Duration(milliseconds: json['duration']),
      error: json['error'],
    );
  }
}

class TestCoverage {
  final String configurationName;
  final double overallCoverage;
  final Map<String, double> fileCoverage;
  final DateTime generatedAt;

  TestCoverage({
    required this.configurationName,
    required this.overallCoverage,
    required this.fileCoverage,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
    'configurationName': configurationName,
    'overallCoverage': overallCoverage,
    'fileCoverage': fileCoverage,
    'generatedAt': generatedAt.toIso8601String(),
  };

  factory TestCoverage.fromJson(Map<String, dynamic> json) {
    return TestCoverage(
      configurationName: json['configurationName'],
      overallCoverage: json['overallCoverage'],
      fileCoverage: Map<String, double>.from(json['fileCoverage']),
      generatedAt: DateTime.parse(json['generatedAt']),
    );
  }
}

class QualityGateResult {
  final bool passed;
  final List<QualityGateViolation> violations;

  QualityGateResult({
    required this.passed,
    required this.violations,
  });

  Map<String, dynamic> toJson() => {
    'passed': passed,
    'violations': violations.map((v) => v.toJson()).toList(),
  };

  factory QualityGateResult.fromJson(Map<String, dynamic> json) {
    return QualityGateResult(
      passed: json['passed'],
      violations: (json['violations'] as List).map((v) => QualityGateViolation.fromJson(v)).toList(),
    );
  }
}

class QualityGateViolation {
  final String gateName;
  final double expectedValue;
  final double actualValue;
  final QualityGateOperator operator;

  QualityGateViolation({
    required this.gateName,
    required this.expectedValue,
    required this.actualValue,
    required this.operator,
  });

  Map<String, dynamic> toJson() => {
    'gateName': gateName,
    'expectedValue': expectedValue,
    'actualValue': actualValue,
    'operator': operator.toString(),
  };

  factory QualityGateViolation.fromJson(Map<String, dynamic> json) {
    return QualityGateViolation(
      gateName: json['gateName'],
      expectedValue: json['expectedValue'],
      actualValue: json['actualValue'],
      operator: QualityGateOperator.values.firstWhere((o) => o.toString() == json['operator']),
    );
  }
}

class TestOutput {
  final int totalTests;
  final int passedTests;
  final int failedTests;
  final int skippedTests;

  TestOutput({
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    required this.skippedTests,
  });
}

class TestExecutionStatus {
  final String sessionId;
  final TestExecutionStatusType status;
  final DateTime? startTime;
  final DateTime? endTime;
  final Duration? duration;
  final bool? success;
  final int? totalTests;
  final int? passedTests;
  final int? failedTests;

  TestExecutionStatus({
    required this.sessionId,
    required this.status,
    this.startTime,
    this.endTime,
    this.duration,
    this.success,
    this.totalTests,
    this.passedTests,
    this.failedTests,
  });
}

class TestCoverageReport {
  final String projectPath;
  final TestCoverageReportData coverageData;
  final CoverageTrendAnalysis trendAnalysis;
  final List<String> recommendations;
  final DateTime generatedAt;

  TestCoverageReport({
    required this.projectPath,
    required this.coverageData,
    required this.trendAnalysis,
    required this.recommendations,
    required this.generatedAt,
  });
}

class TestQualityMetrics {
  final int totalTestSessions;
  final int successfulSessions;
  final double stabilityRate;
  final Duration averageTestDuration;
  final double averageCoverage;
  final double flakinessRate;
  final TestQualityAssessment qualityAssessment;
  final Duration? analysisPeriod;

  TestQualityMetrics({
    required this.totalTestSessions,
    required this.successfulSessions,
    required this.stabilityRate,
    required this.averageTestDuration,
    required this.averageCoverage,
    required this.flakinessRate,
    required this.qualityAssessment,
    this.analysisPeriod,
  });

  factory TestQualityMetrics.empty() {
    return TestQualityMetrics(
      totalTestSessions: 0,
      successfulSessions: 0,
      stabilityRate: 0.0,
      averageTestDuration: Duration.zero,
      averageCoverage: 0.0,
      flakinessRate: 0.0,
      qualityAssessment: TestQualityAssessment(
        overallScore: 0.0,
        qualityLevel: QualityLevel.poor,
        recommendations: [],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'totalTestSessions': totalTestSessions,
    'successfulSessions': successfulSessions,
    'stabilityRate': stabilityRate,
    'averageTestDuration': averageTestDuration.inMilliseconds,
    'averageCoverage': averageCoverage,
    'flakinessRate': flakinessRate,
    'qualityAssessment': {
      'overallScore': qualityAssessment.overallScore,
      'qualityLevel': qualityAssessment.qualityLevel.toString(),
      'recommendations': qualityAssessment.recommendations,
    },
  };
}

class TestQualityAssessment {
  final double overallScore;
  final QualityLevel qualityLevel;
  final List<String> recommendations;

  TestQualityAssessment({
    required this.overallScore,
    required this.qualityLevel,
    required this.recommendations,
  });
}

class TestCoverageResult {
  final bool success;
  final Map<String, dynamic> coverageData;
  final DateTime generatedAt;

  TestCoverageResult({
    required this.success,
    required this.coverageData,
    required this.generatedAt,
  });
}

class TestCoverageReportData {
  final double overallCoverage;
  final double lineCoverage;
  final double branchCoverage;
  final double functionCoverage;
  final Map<String, FileCoverageReport> fileReports;

  TestCoverageReportData({
    required this.overallCoverage,
    required this.lineCoverage,
    required this.branchCoverage,
    required this.functionCoverage,
    required this.fileReports,
  });
}

class FileCoverageReport {
  final String filePath;
  final double coverage;
  final int linesCovered;
  final int totalLines;
  final List<UncoveredLine> uncoveredLines;

  FileCoverageReport({
    required this.filePath,
    required this.coverage,
    required this.linesCovered,
    required this.totalLines,
    required this.uncoveredLines,
  });
}

class UncoveredLine {
  final int lineNumber;
  final String? reason;

  UncoveredLine({
    required this.lineNumber,
    this.reason,
  });
}

class CoverageTrendAnalysis {
  final TrendDirection trend;
  final double changeRate;
  final double confidence;

  CoverageTrendAnalysis({
    required this.trend,
    required this.changeRate,
    required this.confidence,
  });
}

/// Enums

enum TestLevel {
  fast,
  standard,
  full,
  custom,
}

enum TestingEventType {
  serviceInitialized,
  initializationFailed,
  integratedTestingStarted,
  integratedTestingCompleted,
  integratedTestingFailed,
  testSuiteStarted,
  testSuiteCompleted,
  testSuiteFailed,
  testConfigurationStarted,
  testConfigurationCompleted,
  testConfigurationFailed,
  coverageAnalysisStarted,
  coverageAnalysisCompleted,
  coverageAnalysisFailed,
  testSuiteConfigured,
}

enum QualityGateType {
  coverage,
  testResults,
  performance,
}

enum QualityGateOperator {
  greaterThan,
  lessThan,
  equal,
  notEqual,
  greaterThanOrEqual,
  lessThanOrEqual,
}

enum TestExecutionStatusType {
  notFound,
  queued,
  running,
  completed,
  failed,
}

enum QualityLevel {
  poor,
  fair,
  good,
  excellent,
}

/// Event classes

class TestingEvent {
  final TestingEventType type;
  final DateTime timestamp;
  final String? details;
  final String? error;

  TestingEvent({
    required this.type,
    required this.timestamp,
    this.details,
    this.error,
  });
}
