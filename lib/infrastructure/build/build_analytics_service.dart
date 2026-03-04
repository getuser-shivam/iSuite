import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'build_optimization_service.dart';

/// Advanced Build Analytics and Performance Monitoring Service
/// Provides comprehensive build analytics, performance tracking, and optimization insights
class BuildAnalyticsService {
  static final BuildAnalyticsService _instance =
      BuildAnalyticsService._internal();
  factory BuildAnalyticsService() => _instance;
  BuildAnalyticsService._internal();

  final BuildOptimizationService _buildOptimization =
      BuildOptimizationService();
  final StreamController<BuildAnalyticsEvent> _analyticsEventController =
      StreamController.broadcast();

  Stream<BuildAnalyticsEvent> get analyticsEvents =>
      _analyticsEventController.stream;

  // Analytics data storage
  final Map<String, BuildSession> _buildSessions = {};
  final Map<String, BuildMetrics> _buildMetrics = {};
  final Map<String, PerformanceBaseline> _performanceBaselines = {};
  final List<BuildTrend> _buildTrends = [];

  bool _isInitialized = false;
  Timer? _analyticsCleanupTimer;

  // Configuration
  static const String _analyticsDirectory = '.build_analytics';
  static const Duration _cleanupInterval = Duration(hours: 24);
  static const int _maxStoredSessions = 1000;
  static const int _maxTrendDataPoints = 1000;

  /// Initialize build analytics service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeAnalyticsDirectory();
      await _loadStoredAnalytics();
      _startAnalyticsCleanup();

      _isInitialized = true;
      _emitAnalyticsEvent(BuildAnalyticsEventType.serviceInitialized);
    } catch (e) {
      _emitAnalyticsEvent(BuildAnalyticsEventType.initializationFailed,
          error: e.toString());
      rethrow;
    }
  }

  /// Record build session with detailed analytics
  Future<void> recordBuildSession(BuildResult buildResult) async {
    final session = BuildSession(
      sessionId: buildResult.buildId,
      startTime: buildResult.analytics.startTime,
      endTime: buildResult.analytics.endTime,
      duration: buildResult.analytics.totalBuildTime,
      success: buildResult.success,
      targets: buildResult.targets,
      artifacts: buildResult.artifacts,
      errors: buildResult.errors,
      warnings: buildResult.warnings,
      buildMode: buildResult.buildMode,
      metadata: await _collectBuildMetadata(),
    );

    _buildSessions[session.sessionId] = session;

    // Update performance baselines
    await _updatePerformanceBaselines(session);

    // Analyze trends
    await _analyzeBuildTrends(session);

    // Clean up old sessions
    _cleanupOldSessions();

    _emitAnalyticsEvent(BuildAnalyticsEventType.sessionRecorded,
        details:
            'Session: ${session.sessionId}, Duration: ${session.duration.inMilliseconds}ms');
  }

  /// Get build performance analytics
  Future<BuildPerformanceAnalytics> getBuildPerformanceAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    List<BuildMode>? modes,
    List<TargetPlatform>? platforms,
  }) async {
    final sessions = _getFilteredSessions(
      startDate: startDate,
      endDate: endDate,
      modes: modes,
      platforms: platforms,
    );

    if (sessions.isEmpty) {
      return BuildPerformanceAnalytics.empty();
    }

    // Calculate success rate
    final totalBuilds = sessions.length;
    final successfulBuilds = sessions.where((s) => s.success).length;
    final successRate = totalBuilds > 0 ? successfulBuilds / totalBuilds : 0.0;

    // Calculate average build times
    final buildTimes = sessions.map((s) => s.duration.inMilliseconds).toList();
    final averageBuildTime =
        buildTimes.reduce((a, b) => a + b) / buildTimes.length;

    // Calculate build time distribution
    buildTimes.sort();
    final p50BuildTime = buildTimes[buildTimes.length ~/ 2];
    final p90BuildTime = buildTimes[(buildTimes.length * 0.9).floor()];
    final p95BuildTime = buildTimes[(buildTimes.length * 0.95).floor()];

    // Calculate failure analysis
    final failuresByPlatform = <TargetPlatform, int>{};
    final failuresByMode = <BuildMode, int>{};
    final commonErrors = <String, int>{};

    for (final session in sessions.where((s) => !s.success)) {
      for (final target in session.targets) {
        failuresByPlatform[target.platform] =
            (failuresByPlatform[target.platform] ?? 0) + 1;
      }
      failuresByMode[session.buildMode] =
          (failuresByMode[session.buildMode] ?? 0) + 1;

      for (final error in session.errors) {
        commonErrors[error] = (commonErrors[error] ?? 0) + 1;
      }
    }

    // Calculate performance trends
    final trendAnalysis = await _calculatePerformanceTrends(sessions);

    return BuildPerformanceAnalytics(
      totalBuilds: totalBuilds,
      successfulBuilds: successfulBuilds,
      failedBuilds: totalBuilds - successfulBuilds,
      successRate: successRate,
      averageBuildTime: Duration(milliseconds: averageBuildTime.round()),
      medianBuildTime: Duration(milliseconds: p50BuildTime),
      p90BuildTime: Duration(milliseconds: p90BuildTime),
      p95BuildTime: Duration(milliseconds: p95BuildTime),
      failuresByPlatform: failuresByPlatform,
      failuresByMode: failuresByMode,
      commonErrors: commonErrors,
      performanceTrend: trendAnalysis,
      analysisPeriod: startDate != null && endDate != null
          ? endDate.difference(startDate)
          : null,
    );
  }

  /// Get build quality metrics
  Future<BuildQualityMetrics> getBuildQualityMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final sessions =
        _getFilteredSessions(startDate: startDate, endDate: endDate);

    if (sessions.isEmpty) {
      return BuildQualityMetrics.empty();
    }

    // Calculate quality scores
    final qualityScores = <double>[];
    final warningCounts = <int>[];
    final errorCounts = <int>[];

    for (final session in sessions) {
      final score = _calculateBuildQualityScore(session);
      qualityScores.add(score);
      warningCounts.add(session.warnings.length);
      errorCounts.add(session.errors.length);
    }

    final averageQualityScore =
        qualityScores.reduce((a, b) => a + b) / qualityScores.length;
    final averageWarnings =
        warningCounts.reduce((a, b) => a + b) / warningCounts.length;
    final averageErrors =
        errorCounts.reduce((a, b) => a + b) / errorCounts.length;

    // Calculate quality distribution
    qualityScores.sort();
    final medianQualityScore = qualityScores[qualityScores.length ~/ 2];

    // Identify quality issues
    final qualityIssues = _identifyQualityIssues(sessions);

    return BuildQualityMetrics(
      averageQualityScore: averageQualityScore,
      medianQualityScore: medianQualityScore,
      averageWarningsPerBuild: averageWarnings,
      averageErrorsPerBuild: averageErrors,
      totalQualityIssues: qualityIssues.length,
      qualityIssuesByCategory: _categorizeQualityIssues(qualityIssues),
      qualityTrend: await _calculateQualityTrends(sessions),
      analysisPeriod: startDate != null && endDate != null
          ? endDate.difference(startDate)
          : null,
    );
  }

  /// Get build resource utilization analytics
  Future<BuildResourceAnalytics> getBuildResourceAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final sessions =
        _getFilteredSessions(startDate: startDate, endDate: endDate);

    if (sessions.isEmpty) {
      return BuildResourceAnalytics.empty();
    }

    // Analyze cache performance
    final cacheStats = await _buildOptimization.getCacheStatistics();
    final cacheHits = cacheStats.hitRate * sessions.length;
    final cacheMisses = sessions.length - cacheHits.round();

    // Analyze memory usage patterns
    final memoryStats = _buildOptimization.getMemoryUsageStatistics();

    // Analyze build parallelization efficiency
    final parallelizationMetrics =
        _calculateParallelizationEfficiency(sessions);

    // Calculate resource bottlenecks
    final bottlenecks = await _identifyResourceBottlenecks(sessions);

    return BuildResourceAnalytics(
      cacheHitRate: cacheStats.hitRate,
      cacheHits: cacheHits.round(),
      cacheMisses: cacheMisses,
      averageMemoryUsage: memoryStats.averageUsage,
      peakMemoryUsage: memoryStats.peakUsage,
      parallelizationEfficiency: parallelizationMetrics.efficiency,
      averageParallelTasks: parallelizationMetrics.averageTasks,
      resourceBottlenecks: bottlenecks,
      analysisPeriod: startDate != null && endDate != null
          ? endDate.difference(startDate)
          : null,
    );
  }

  /// Generate comprehensive build report
  Future<String> generateBuildReport({
    DateTime? startDate,
    DateTime? endDate,
    bool includePerformance = true,
    bool includeQuality = true,
    bool includeResources = true,
    bool includeRecommendations = true,
  }) async {
    final report = StringBuffer();
    report.writeln('Build Analytics Report');
    report.writeln('Generated: ${DateTime.now()}');
    report.writeln('=' * 50);

    final period = startDate != null && endDate != null
        ? 'Period: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}'
        : 'All time';
    report.writeln(period);
    report.writeln();

    if (includePerformance) {
      report.writeln('PERFORMANCE ANALYTICS:');
      final perf = await getBuildPerformanceAnalytics(
        startDate: startDate,
        endDate: endDate,
      );
      report.writeln(perf.toString());
      report.writeln();
    }

    if (includeQuality) {
      report.writeln('QUALITY METRICS:');
      final quality = await getBuildQualityMetrics(
        startDate: startDate,
        endDate: endDate,
      );
      report.writeln(quality.toString());
      report.writeln();
    }

    if (includeResources) {
      report.writeln('RESOURCE UTILIZATION:');
      final resources = await getBuildResourceAnalytics(
        startDate: startDate,
        endDate: endDate,
      );
      report.writeln(resources.toString());
      report.writeln();
    }

    if (includeRecommendations) {
      report.writeln('RECOMMENDATIONS:');
      final recommendations = await _generateBuildRecommendations(
        startDate: startDate,
        endDate: endDate,
      );
      for (final rec in recommendations) {
        report.writeln('• ${rec.title}: ${rec.description}');
        if (rec.estimatedImpact != null) {
          report.writeln('  Estimated impact: ${rec.estimatedImpact}');
        }
      }
    }

    return report.toString();
  }

  /// Get build optimization recommendations
  Future<List<BuildRecommendation>> getBuildRecommendations({
    DateTime? startDate,
    DateTime? endDate,
    int maxRecommendations = 10,
  }) async {
    final recommendations = <BuildRecommendation>[];

    final perfAnalytics = await getBuildPerformanceAnalytics(
      startDate: startDate,
      endDate: endDate,
    );

    final qualityMetrics = await getBuildQualityMetrics(
      startDate: startDate,
      endDate: endDate,
    );

    final resourceAnalytics = await getBuildResourceAnalytics(
      startDate: startDate,
      endDate: endDate,
    );

    // Performance recommendations
    if (perfAnalytics.successRate < 0.9) {
      recommendations.add(BuildRecommendation(
        title: 'Improve Build Reliability',
        description:
            'Build success rate is ${(perfAnalytics.successRate * 100).round()}%. '
            'Investigate common failure patterns and implement fixes.',
        priority: RecommendationPriority.high,
        category: RecommendationCategory.reliability,
        estimatedImpact: 'Increase success rate by 10-20%',
      ));
    }

    if (perfAnalytics.averageBuildTime > Duration(minutes: 5)) {
      recommendations.add(BuildRecommendation(
        title: 'Optimize Build Speed',
        description:
            'Average build time is ${perfAnalytics.averageBuildTime.inSeconds}s. '
            'Consider parallelization, caching, and incremental builds.',
        priority: RecommendationPriority.high,
        category: RecommendationCategory.performance,
        estimatedImpact: 'Reduce build time by 30-50%',
      ));
    }

    // Quality recommendations
    if (qualityMetrics.averageQualityScore < 0.8) {
      recommendations.add(BuildRecommendation(
        title: 'Improve Build Quality',
        description:
            'Average quality score is ${(qualityMetrics.averageQualityScore * 100).round()}%. '
            'Address warnings and errors to improve code quality.',
        priority: RecommendationPriority.medium,
        category: RecommendationCategory.quality,
        estimatedImpact: 'Increase quality score by 15-25%',
      ));
    }

    // Resource recommendations
    if (resourceAnalytics.cacheHitRate < 0.7) {
      recommendations.add(BuildRecommendation(
        title: 'Improve Cache Utilization',
        description:
            'Cache hit rate is ${(resourceAnalytics.cacheHitRate * 100).round()}%. '
            'Optimize caching strategies and reduce cache misses.',
        priority: RecommendationPriority.medium,
        category: RecommendationCategory.resources,
        estimatedImpact: 'Increase cache hit rate by 20-30%',
      ));
    }

    // Sort by priority and limit results
    recommendations
        .sort((a, b) => a.priority.index.compareTo(b.priority.index));
    return recommendations.take(maxRecommendations).toList();
  }

  /// Export analytics data
  Future<String> exportAnalyticsData({
    DateTime? startDate,
    DateTime? endDate,
    bool includeSessions = true,
    bool includeMetrics = true,
    bool includeTrends = true,
  }) async {
    final data = <String, dynamic>{
      'exportTimestamp': DateTime.now().toIso8601String(),
      'period': {
        'start': startDate?.toIso8601String(),
        'end': endDate?.toIso8601String(),
      },
    };

    if (includeSessions) {
      final sessions =
          _getFilteredSessions(startDate: startDate, endDate: endDate);
      data['sessions'] = sessions.map((s) => s.toJson()).toList();
    }

    if (includeMetrics) {
      data['performanceAnalytics'] = (await getBuildPerformanceAnalytics(
        startDate: startDate,
        endDate: endDate,
      ))
          .toJson();

      data['qualityMetrics'] = (await getBuildQualityMetrics(
        startDate: startDate,
        endDate: endDate,
      ))
          .toJson();

      data['resourceAnalytics'] = (await getBuildResourceAnalytics(
        startDate: startDate,
        endDate: endDate,
      ))
          .toJson();
    }

    if (includeTrends) {
      data['trends'] = _buildTrends.map((t) => t.toJson()).toList();
    }

    return json.encode(data);
  }

  // Private methods

  Future<void> _initializeAnalyticsDirectory() async {
    final dir = Directory(_analyticsDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  Future<void> _loadStoredAnalytics() async {
    final sessionsFile =
        File(path.join(_analyticsDirectory, 'build_sessions.json'));
    if (await sessionsFile.exists()) {
      try {
        final content = await sessionsFile.readAsString();
        final sessionsData = json.decode(content) as List;
        for (final sessionData in sessionsData) {
          final session = BuildSession.fromJson(sessionData);
          _buildSessions[session.sessionId] = session;
        }
      } catch (e) {
        // Ignore load errors
      }
    }
  }

  void _startAnalyticsCleanup() {
    _analyticsCleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _cleanupOldAnalytics();
    });
  }

  List<BuildSession> _getFilteredSessions({
    DateTime? startDate,
    DateTime? endDate,
    List<BuildMode>? modes,
    List<TargetPlatform>? platforms,
  }) {
    return _buildSessions.values.where((session) {
      if (startDate != null && session.startTime.isBefore(startDate))
        return false;
      if (endDate != null && session.startTime.isAfter(endDate)) return false;
      if (modes != null && !modes.contains(session.buildMode)) return false;
      if (platforms != null &&
          !session.targets.any((t) => platforms.contains(t.platform)))
        return false;
      return true;
    }).toList();
  }

  Future<void> _updatePerformanceBaselines(BuildSession session) async {
    for (final target in session.targets) {
      final key =
          '${target.platform}_${target.architecture}_${session.buildMode}';
      final existing = _performanceBaselines[key];

      if (existing == null) {
        _performanceBaselines[key] = PerformanceBaseline(
          target: target,
          buildMode: session.buildMode,
          baselineBuildTime: session.duration,
          baselineSuccessRate: session.success ? 1.0 : 0.0,
          sampleCount: 1,
          lastUpdated: session.endTime,
        );
      } else {
        // Update rolling average
        final newSampleCount = existing.sampleCount + 1;
        final newAvgTime = ((existing.baselineBuildTime.inMilliseconds *
                    existing.sampleCount) +
                session.duration.inMilliseconds) /
            newSampleCount;
        final newSuccessRate =
            ((existing.baselineSuccessRate * existing.sampleCount) +
                    (session.success ? 1.0 : 0.0)) /
                newSampleCount;

        _performanceBaselines[key] = PerformanceBaseline(
          target: target,
          buildMode: session.buildMode,
          baselineBuildTime: Duration(milliseconds: newAvgTime.round()),
          baselineSuccessRate: newSuccessRate,
          sampleCount: newSampleCount,
          lastUpdated: session.endTime,
        );
      }
    }
  }

  Future<void> _analyzeBuildTrends(BuildSession session) async {
    _buildTrends.add(BuildTrend(
      timestamp: session.endTime,
      buildTime: session.duration.inMilliseconds.toDouble(),
      success: session.success,
      targetCount: session.targets.length,
      artifactCount: session.artifacts.length,
      errorCount: session.errors.length,
      warningCount: session.warnings.length,
    ));

    // Maintain trend data limit
    if (_buildTrends.length > _maxTrendDataPoints) {
      _buildTrends.removeAt(0);
    }
  }

  void _cleanupOldSessions() {
    if (_buildSessions.length <= _maxStoredSessions) return;

    // Remove oldest sessions
    final sortedSessions = _buildSessions.values.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final toRemove =
        sortedSessions.take(_buildSessions.length - _maxStoredSessions);
    for (final session in toRemove) {
      _buildSessions.remove(session.sessionId);
    }
  }

  void _cleanupOldAnalytics() {
    // Cleanup old trend data (keep last 30 days)
    final cutoff = DateTime.now().subtract(Duration(days: 30));
    _buildTrends.removeWhere((trend) => trend.timestamp.isBefore(cutoff));
  }

  Future<Map<String, dynamic>> _collectBuildMetadata() async {
    return {
      'flutterVersion': await _getFlutterVersion(),
      'dartVersion': await _getDartVersion(),
      'platform': Platform.operatingSystem,
      'architecture': await _getSystemArchitecture(),
      'availableMemory': await _getAvailableMemory(),
      'cpuCount': Platform.numberOfProcessors,
    };
  }

  Future<String> _getFlutterVersion() async {
    try {
      final result = await Process.run('flutter', ['--version']);
      return result.stdout.toString().split('\n').first;
    } catch (e) {
      return 'unknown';
    }
  }

  Future<String> _getDartVersion() async {
    try {
      final result = await Process.run('dart', ['--version']);
      return result.stdout.toString().trim();
    } catch (e) {
      return 'unknown';
    }
  }

  Future<String> _getSystemArchitecture() async {
    try {
      if (Platform.isWindows) {
        final result =
            await Process.run('wmic', ['cpu', 'get', 'Architecture']);
        return result.stdout.toString().trim();
      } else if (Platform.isLinux || Platform.isMacOS) {
        final result = await Process.run('uname', ['-m']);
        return result.stdout.toString().trim();
      }
    } catch (e) {
      // Ignore
    }
    return 'unknown';
  }

  Future<int> _getAvailableMemory() async {
    // This is a simplified implementation
    // In a real app, you'd use platform-specific APIs
    return 1024 * 1024 * 1024; // 1GB placeholder
  }

  double _calculateBuildQualityScore(BuildSession session) {
    double score = 1.0;

    // Deduct for errors
    score -= session.errors.length * 0.1;

    // Deduct for warnings
    score -= session.warnings.length * 0.02;

    // Deduct for long build times (relative to baseline)
    final baseline = _performanceBaselines.values.firstWhere(
      (b) => b.buildMode == session.buildMode,
      orElse: () => null,
    );

    if (baseline != null) {
      final ratio = session.duration.inMilliseconds /
          baseline.baselineBuildTime.inMilliseconds;
      if (ratio > 1.5) {
        // 50% slower than baseline
        score -= 0.1;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  List<QualityIssue> _identifyQualityIssues(List<BuildSession> sessions) {
    final issues = <QualityIssue>[];

    // Identify sessions with high error counts
    final highErrorSessions = sessions.where((s) => s.errors.length > 5);
    if (highErrorSessions.isNotEmpty) {
      issues.add(QualityIssue(
        type: QualityIssueType.consistentlyHighErrors,
        severity: QualitySeverity.high,
        description:
            '${highErrorSessions.length} builds with high error counts',
        affectedSessions: highErrorSessions.length,
      ));
    }

    // Identify builds with no tests
    final buildsWithoutTests =
        sessions.where((s) => s.metadata?['testCount'] == 0);
    if (buildsWithoutTests.isNotEmpty) {
      issues.add(QualityIssue(
        type: QualityIssueType.missingTests,
        severity: QualitySeverity.medium,
        description: '${buildsWithoutTests.length} builds without tests',
        affectedSessions: buildsWithoutTests.length,
      ));
    }

    return issues;
  }

  Map<QualityIssueType, int> _categorizeQualityIssues(
      List<QualityIssue> issues) {
    final categories = <QualityIssueType, int>{};
    for (final issue in issues) {
      categories[issue.type] = (categories[issue.type] ?? 0) + 1;
    }
    return categories;
  }

  Future<TrendAnalysis> _calculatePerformanceTrends(
      List<BuildSession> sessions) async {
    if (sessions.length < 2) {
      return TrendAnalysis(
        direction: TrendDirection.stable,
        changeRate: 0.0,
        confidence: 0.0,
      );
    }

    final sortedSessions = sessions.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final firstHalf = sortedSessions.take(sortedSessions.length ~/ 2).toList();
    final secondHalf = sortedSessions.skip(sortedSessions.length ~/ 2).toList();

    final firstHalfAvg = firstHalf
            .map((s) => s.duration.inMilliseconds)
            .reduce((a, b) => a + b) /
        firstHalf.length;
    final secondHalfAvg = secondHalf
            .map((s) => s.duration.inMilliseconds)
            .reduce((a, b) => a + b) /
        secondHalf.length;

    final changeRate = (secondHalfAvg - firstHalfAvg) / firstHalfAvg;
    final confidence = 0.8; // Simplified confidence calculation

    TrendDirection direction;
    if (changeRate > 0.1) {
      direction = TrendDirection.worsening;
    } else if (changeRate < -0.1) {
      direction = TrendDirection.improving;
    } else {
      direction = TrendDirection.stable;
    }

    return TrendAnalysis(
      direction: direction,
      changeRate: changeRate,
      confidence: confidence,
    );
  }

  Future<TrendAnalysis> _calculateQualityTrends(
      List<BuildSession> sessions) async {
    final qualityScores = sessions.map(_calculateBuildQualityScore).toList();

    if (qualityScores.length < 2) {
      return TrendAnalysis(
        direction: TrendDirection.stable,
        changeRate: 0.0,
        confidence: 0.0,
      );
    }

    final firstHalf = qualityScores.take(qualityScores.length ~/ 2).toList();
    final secondHalf = qualityScores.skip(qualityScores.length ~/ 2).toList();

    final firstHalfAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondHalfAvg =
        secondHalf.reduce((a, b) => a + b) / secondHalf.length;

    final changeRate = (secondHalfAvg - firstHalfAvg) / firstHalfAvg;

    TrendDirection direction;
    if (changeRate > 0.05) {
      direction = TrendDirection.improving;
    } else if (changeRate < -0.05) {
      direction = TrendDirection.worsening;
    } else {
      direction = TrendDirection.stable;
    }

    return TrendAnalysis(
      direction: direction,
      changeRate: changeRate,
      confidence: 0.8,
    );
  }

  ParallelizationMetrics _calculateParallelizationEfficiency(
      List<BuildSession> sessions) {
    // Simplified parallelization analysis
    final avgTargets =
        sessions.map((s) => s.targets.length).reduce((a, b) => a + b) /
            sessions.length;
    const maxParallelTasks = 4; // From build optimization service

    final efficiency =
        avgTargets > 1 ? (avgTargets / maxParallelTasks).clamp(0.0, 1.0) : 1.0;

    return ParallelizationMetrics(
      efficiency: efficiency,
      averageTasks: avgTargets,
      maxParallelTasks: maxParallelTasks,
    );
  }

  Future<List<ResourceBottleneck>> _identifyResourceBottlenecks(
      List<BuildSession> sessions) async {
    final bottlenecks = <ResourceBottleneck>[];

    // Check for memory bottlenecks
    final highMemorySessions = sessions
        .where((s) =>
                s.metadata?['peakMemoryUsage'] != null &&
                s.metadata!['peakMemoryUsage'] > 500 * 1024 * 1024 // 500MB
            )
        .length;

    if (highMemorySessions > sessions.length * 0.1) {
      // 10% of builds
      bottlenecks.add(ResourceBottleneck(
        resource: 'memory',
        severity: BottleneckSeverity.medium,
        description: '${highMemorySessions} builds exceeded memory threshold',
        impact: 'May cause system slowdown or build failures',
      ));
    }

    // Check for disk space issues
    final largeArtifactSessions = sessions
        .where((s) =>
                s.artifacts.fold<int>(0, (sum, a) => sum + a.size) >
                100 * 1024 * 1024 // 100MB
            )
        .length;

    if (largeArtifactSessions > sessions.length * 0.2) {
      // 20% of builds
      bottlenecks.add(ResourceBottleneck(
        resource: 'disk',
        severity: BottleneckSeverity.low,
        description: '${largeArtifactSessions} builds produced large artifacts',
        impact: 'May consume excessive disk space',
      ));
    }

    return bottlenecks;
  }

  Future<List<BuildRecommendation>> _generateBuildRecommendations({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await getBuildRecommendations(
      startDate: startDate,
      endDate: endDate,
      maxRecommendations: 5,
    );
  }

  void _emitAnalyticsEvent(
    BuildAnalyticsEventType type, {
    String? details,
    String? error,
  }) {
    final event = BuildAnalyticsEvent(
      type: type,
      timestamp: DateTime.now(),
      details: details,
      error: error,
    );

    _analyticsEventController.add(event);
  }

  void dispose() {
    _analyticsCleanupTimer?.cancel();
    _analyticsEventController.close();
  }
}

/// Supporting data classes

class BuildSession {
  final String sessionId;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final bool success;
  final List<BuildTarget> targets;
  final List<BuildArtifact> artifacts;
  final List<String> errors;
  final List<String> warnings;
  final BuildMode buildMode;
  final Map<String, dynamic> metadata;

  BuildSession({
    required this.sessionId,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.success,
    required this.targets,
    required this.artifacts,
    required this.errors,
    required this.warnings,
    required this.buildMode,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'duration': duration.inMilliseconds,
        'success': success,
        'targets': targets
            .map((t) => {
                  'platform': t.platform.toString(),
                  'architecture': t.architecture
                })
            .toList(),
        'artifacts':
            artifacts.map((a) => {'path': a.path, 'size': a.size}).toList(),
        'errors': errors,
        'warnings': warnings,
        'buildMode': buildMode.toString(),
        'metadata': metadata,
      };

  factory BuildSession.fromJson(Map<String, dynamic> json) {
    return BuildSession(
      sessionId: json['sessionId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      duration: Duration(milliseconds: json['duration']),
      success: json['success'],
      targets: (json['targets'] as List)
          .map((t) => BuildTarget(
                platform: TargetPlatform.values
                    .firstWhere((p) => p.toString() == t['platform']),
                architecture: t['architecture'],
              ))
          .toList(),
      artifacts: (json['artifacts'] as List)
          .map((a) => BuildArtifact(
                path: a['path'],
                size: a['size'],
                modified: DateTime.now(), // Placeholder
                target: BuildTarget(
                    platform: TargetPlatform.android,
                    architecture: 'arm64'), // Placeholder
              ))
          .toList(),
      errors: List<String>.from(json['errors']),
      warnings: List<String>.from(json['warnings']),
      buildMode:
          BuildMode.values.firstWhere((m) => m.toString() == json['buildMode']),
      metadata: Map<String, dynamic>.from(json['metadata']),
    );
  }
}

class PerformanceBaseline {
  final BuildTarget target;
  final BuildMode buildMode;
  final Duration baselineBuildTime;
  final double baselineSuccessRate;
  final int sampleCount;
  final DateTime lastUpdated;

  PerformanceBaseline({
    required this.target,
    required this.buildMode,
    required this.baselineBuildTime,
    required this.baselineSuccessRate,
    required this.sampleCount,
    required this.lastUpdated,
  });
}

class BuildTrend {
  final DateTime timestamp;
  final double buildTime;
  final bool success;
  final int targetCount;
  final int artifactCount;
  final int errorCount;
  final int warningCount;

  BuildTrend({
    required this.timestamp,
    required this.buildTime,
    required this.success,
    required this.targetCount,
    required this.artifactCount,
    required this.errorCount,
    required this.warningCount,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'buildTime': buildTime,
        'success': success,
        'targetCount': targetCount,
        'artifactCount': artifactCount,
        'errorCount': errorCount,
        'warningCount': warningCount,
      };
}

class BuildPerformanceAnalytics {
  final int totalBuilds;
  final int successfulBuilds;
  final int failedBuilds;
  final double successRate;
  final Duration averageBuildTime;
  final Duration medianBuildTime;
  final Duration p90BuildTime;
  final Duration p95BuildTime;
  final Map<TargetPlatform, int> failuresByPlatform;
  final Map<BuildMode, int> failuresByMode;
  final Map<String, int> commonErrors;
  final TrendAnalysis performanceTrend;
  final Duration? analysisPeriod;

  BuildPerformanceAnalytics({
    required this.totalBuilds,
    required this.successfulBuilds,
    required this.failedBuilds,
    required this.successRate,
    required this.averageBuildTime,
    required this.medianBuildTime,
    required this.p90BuildTime,
    required this.p95BuildTime,
    required this.failuresByPlatform,
    required this.failuresByMode,
    required this.commonErrors,
    required this.performanceTrend,
    this.analysisPeriod,
  });

  factory BuildPerformanceAnalytics.empty() {
    return BuildPerformanceAnalytics(
      totalBuilds: 0,
      successfulBuilds: 0,
      failedBuilds: 0,
      successRate: 0.0,
      averageBuildTime: Duration.zero,
      medianBuildTime: Duration.zero,
      p90BuildTime: Duration.zero,
      p95BuildTime: Duration.zero,
      failuresByPlatform: {},
      failuresByMode: {},
      commonErrors: {},
      performanceTrend: TrendAnalysis(
        direction: TrendDirection.stable,
        changeRate: 0.0,
        confidence: 0.0,
      ),
    );
  }

  @override
  String toString() {
    return '''
Total Builds: $totalBuilds
Success Rate: ${(successRate * 100).round()}%
Average Build Time: ${averageBuildTime.inSeconds}s
Median Build Time: ${medianBuildTime.inSeconds}s
90th Percentile: ${p90BuildTime.inSeconds}s
95th Percentile: ${p95BuildTime.inSeconds}s
Performance Trend: ${performanceTrend.direction} (${(performanceTrend.changeRate * 100).round()}%)
''';
  }

  Map<String, dynamic> toJson() => {
        'totalBuilds': totalBuilds,
        'successfulBuilds': successfulBuilds,
        'failedBuilds': failedBuilds,
        'successRate': successRate,
        'averageBuildTime': averageBuildTime.inMilliseconds,
        'medianBuildTime': medianBuildTime.inMilliseconds,
        'p90BuildTime': p90BuildTime.inMilliseconds,
        'p95BuildTime': p95BuildTime.inMilliseconds,
        'failuresByPlatform':
            failuresByPlatform.map((k, v) => MapEntry(k.toString(), v)),
        'failuresByMode':
            failuresByMode.map((k, v) => MapEntry(k.toString(), v)),
        'commonErrors': commonErrors,
      };
}

class BuildQualityMetrics {
  final double averageQualityScore;
  final double medianQualityScore;
  final double averageWarningsPerBuild;
  final double averageErrorsPerBuild;
  final int totalQualityIssues;
  final Map<QualityIssueType, int> qualityIssuesByCategory;
  final TrendAnalysis qualityTrend;
  final Duration? analysisPeriod;

  BuildQualityMetrics({
    required this.averageQualityScore,
    required this.medianQualityScore,
    required this.averageWarningsPerBuild,
    required this.averageErrorsPerBuild,
    required this.totalQualityIssues,
    required this.qualityIssuesByCategory,
    required this.qualityTrend,
    this.analysisPeriod,
  });

  factory BuildQualityMetrics.empty() {
    return BuildQualityMetrics(
      averageQualityScore: 0.0,
      medianQualityScore: 0.0,
      averageWarningsPerBuild: 0.0,
      averageErrorsPerBuild: 0.0,
      totalQualityIssues: 0,
      qualityIssuesByCategory: {},
      qualityTrend: TrendAnalysis(
        direction: TrendDirection.stable,
        changeRate: 0.0,
        confidence: 0.0,
      ),
    );
  }

  @override
  String toString() {
    return '''
Average Quality Score: ${(averageQualityScore * 100).round()}%
Median Quality Score: ${(medianQualityScore * 100).round()}%
Average Warnings/Build: ${averageWarningsPerBuild.toStringAsFixed(1)}
Average Errors/Build: ${averageErrorsPerBuild.toStringAsFixed(1)}
Total Quality Issues: $totalQualityIssues
Quality Trend: ${qualityTrend.direction}
''';
  }

  Map<String, dynamic> toJson() => {
        'averageQualityScore': averageQualityScore,
        'medianQualityScore': medianQualityScore,
        'averageWarningsPerBuild': averageWarningsPerBuild,
        'averageErrorsPerBuild': averageErrorsPerBuild,
        'totalQualityIssues': totalQualityIssues,
        'qualityIssuesByCategory':
            qualityIssuesByCategory.map((k, v) => MapEntry(k.toString(), v)),
      };
}

class BuildResourceAnalytics {
  final double cacheHitRate;
  final int cacheHits;
  final int cacheMisses;
  final int averageMemoryUsage;
  final int peakMemoryUsage;
  final double parallelizationEfficiency;
  final double averageParallelTasks;
  final List<ResourceBottleneck> resourceBottlenecks;
  final Duration? analysisPeriod;

  BuildResourceAnalytics({
    required this.cacheHitRate,
    required this.cacheHits,
    required this.cacheMisses,
    required this.averageMemoryUsage,
    required this.peakMemoryUsage,
    required this.parallelizationEfficiency,
    required this.averageParallelTasks,
    required this.resourceBottlenecks,
    this.analysisPeriod,
  });

  factory BuildResourceAnalytics.empty() {
    return BuildResourceAnalytics(
      cacheHitRate: 0.0,
      cacheHits: 0,
      cacheMisses: 0,
      averageMemoryUsage: 0,
      peakMemoryUsage: 0,
      parallelizationEfficiency: 0.0,
      averageParallelTasks: 0.0,
      resourceBottlenecks: [],
    );
  }

  @override
  String toString() {
    return '''
Cache Hit Rate: ${(cacheHitRate * 100).round()}%
Cache Performance: $cacheHits hits, $cacheMisses misses
Average Memory Usage: ${averageMemoryUsage ~/ 1024}KB
Peak Memory Usage: ${peakMemoryUsage ~/ 1024}KB
Parallelization Efficiency: ${(parallelizationEfficiency * 100).round()}%
Average Parallel Tasks: ${averageParallelTasks.toStringAsFixed(1)}
Resource Bottlenecks: ${resourceBottlenecks.length}
''';
  }

  Map<String, dynamic> toJson() => {
        'cacheHitRate': cacheHitRate,
        'cacheHits': cacheHits,
        'cacheMisses': cacheMisses,
        'averageMemoryUsage': averageMemoryUsage,
        'peakMemoryUsage': peakMemoryUsage,
        'parallelizationEfficiency': parallelizationEfficiency,
        'averageParallelTasks': averageParallelTasks,
        'resourceBottlenecks': resourceBottlenecks
            .map((b) => {
                  'resource': b.resource,
                  'severity': b.severity.toString(),
                  'description': b.description,
                  'impact': b.impact,
                })
            .toList(),
      };
}

class BuildRecommendation {
  final String title;
  final String description;
  final RecommendationPriority priority;
  final RecommendationCategory category;
  final String? estimatedImpact;

  BuildRecommendation({
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    this.estimatedImpact,
  });
}

class TrendAnalysis {
  final TrendDirection direction;
  final double changeRate;
  final double confidence;

  TrendAnalysis({
    required this.direction,
    required this.changeRate,
    required this.confidence,
  });
}

class ParallelizationMetrics {
  final double efficiency;
  final double averageTasks;
  final int maxParallelTasks;

  ParallelizationMetrics({
    required this.efficiency,
    required this.averageTasks,
    required this.maxParallelTasks,
  });
}

class ResourceBottleneck {
  final String resource;
  final BottleneckSeverity severity;
  final String description;
  final String impact;

  ResourceBottleneck({
    required this.resource,
    required this.severity,
    required this.description,
    required this.impact,
  });
}

class QualityIssue {
  final QualityIssueType type;
  final QualitySeverity severity;
  final String description;
  final int affectedSessions;

  QualityIssue({
    required this.type,
    required this.severity,
    required this.description,
    required this.affectedSessions,
  });
}

/// Enums

enum BuildAnalyticsEventType {
  serviceInitialized,
  initializationFailed,
  sessionRecorded,
  analysisStarted,
  analysisCompleted,
  analysisFailed,
}

enum TrendDirection {
  improving,
  stable,
  worsening,
}

enum RecommendationPriority {
  low,
  medium,
  high,
  critical,
}

enum RecommendationCategory {
  performance,
  reliability,
  quality,
  resources,
  security,
}

enum BottleneckSeverity {
  low,
  medium,
  high,
  critical,
}

enum QualityIssueType {
  consistentlyHighErrors,
  missingTests,
  lowCodeCoverage,
  outdatedDependencies,
  securityVulnerabilities,
}

enum QualitySeverity {
  low,
  medium,
  high,
  critical,
}

/// Event classes

class BuildAnalyticsEvent {
  final BuildAnalyticsEventType type;
  final DateTime timestamp;
  final String? details;
  final String? error;

  BuildAnalyticsEvent({
    required this.type,
    required this.timestamp,
    this.details,
    this.error,
  });
}
