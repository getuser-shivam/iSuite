import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'performance_optimization_service.dart';

/// Enhanced Build Optimization Service
/// Provides comprehensive build optimization with parallel execution, caching, and performance monitoring
class BuildOptimizationService {
  static final BuildOptimizationService _instance =
      BuildOptimizationService._internal();
  factory BuildOptimizationService() => _instance;
  BuildOptimizationService._internal();

  final PerformanceOptimizationService _performanceService =
      PerformanceOptimizationService();
  final StreamController<BuildEvent> _buildEventController =
      StreamController.broadcast();

  Stream<BuildEvent> get buildEvents => _buildEventController.stream;

  // Build cache management
  final Map<String, BuildCacheEntry> _buildCache = {};
  final Map<String, DependencyGraph> _dependencyGraphs = {};

  // Parallel execution management
  final Map<String, BuildTask> _runningTasks = {};
  final Semaphore _buildSemaphore = Semaphore(4); // Max 4 parallel builds

  // Build analytics
  final Map<String, BuildAnalytics> _buildAnalytics = {};
  final Map<String, BuildMetrics> _buildMetrics = {};

  bool _isInitialized = false;

  // Configuration
  static const String _cacheDirectory = '.build_cache';
  static const Duration _cacheExpiration = Duration(days: 7);
  static const int _maxCacheSize = 2 * 1024 * 1024 * 1024; // 2GB
  static const int _maxParallelTasks = 4;

  /// Initialize build optimization service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeCacheDirectory();
      await _loadBuildCache();
      await _loadDependencyGraphs();

      _isInitialized = true;
      _emitBuildEvent(BuildEventType.serviceInitialized);
    } catch (e) {
      _emitBuildEvent(BuildEventType.initializationFailed, error: e.toString());
      rethrow;
    }
  }

  /// Execute optimized build with parallel processing and caching
  Future<BuildResult> executeOptimizedBuild({
    required String projectPath,
    required List<BuildTarget> targets,
    BuildMode mode = BuildMode.debug,
    Map<String, dynamic>? buildConfig,
    bool enableParallel = true,
    bool useCache = true,
  }) async {
    final buildId = 'build_${DateTime.now().millisecondsSinceEpoch}';
    final startTime = DateTime.now();

    _emitBuildEvent(BuildEventType.buildStarted,
        buildId: buildId, details: 'Targets: ${targets.length}, Mode: $mode');

    try {
      // Analyze dependencies
      final dependencyGraph = await _analyzeDependencies(projectPath);
      _dependencyGraphs[buildId] = dependencyGraph;

      // Determine build tasks based on targets and dependencies
      final tasks =
          await _planBuildTasks(projectPath, targets, mode, dependencyGraph);

      // Apply caching optimizations
      final optimizedTasks =
          useCache ? await _applyBuildCaching(tasks, buildId) : tasks;

      // Execute build tasks (parallel if enabled)
      final results = enableParallel
          ? await _executeParallelBuild(optimizedTasks, buildId)
          : await _executeSequentialBuild(optimizedTasks, buildId);

      // Collect build artifacts
      final artifacts = await _collectBuildArtifacts(results, targets);

      // Generate build analytics
      final analytics =
          _generateBuildAnalytics(buildId, startTime, results, tasks.length);

      final buildResult = BuildResult(
        buildId: buildId,
        success: results.every((r) => r.success),
        targets: targets,
        artifacts: artifacts,
        analytics: analytics,
        warnings: results.expand((r) => r.warnings).toList(),
        errors: results.expand((r) => r.errors).toList(),
      );

      _emitBuildEvent(
          buildResult.success
              ? BuildEventType.buildCompleted
              : BuildEventType.buildFailed,
          buildId: buildId,
          details: 'Duration: ${analytics.totalBuildTime.inMilliseconds}ms');

      return buildResult;
    } catch (e) {
      final analytics = _generateBuildAnalytics(buildId, startTime, [], 0);
      _emitBuildEvent(BuildEventType.buildFailed,
          buildId: buildId, error: e.toString());

      return BuildResult(
        buildId: buildId,
        success: false,
        targets: targets,
        artifacts: [],
        analytics: analytics,
        warnings: [],
        errors: [e.toString()],
      );
    }
  }

  /// Clean build cache and artifacts
  Future<CacheCleanupResult> cleanBuildCache({
    bool cleanExpired = true,
    bool cleanUnused = true,
    Duration? maxAge,
    int? maxSize,
  }) async {
    _emitBuildEvent(BuildEventType.cacheCleanupStarted);

    int removedEntries = 0;
    int freedSpace = 0;

    try {
      final cacheDir = Directory(_cacheDirectory);
      if (!await cacheDir.exists()) {
        return CacheCleanupResult(
            success: true, removedEntries: 0, freedSpace: 0);
      }

      final entries = await cacheDir.list().toList();
      final now = DateTime.now();

      for (final entry in entries) {
        if (entry is! File) continue;

        final stat = await entry.stat();
        final age = now.difference(stat.modified);
        final shouldRemove =
            (cleanExpired && age > (maxAge ?? _cacheExpiration)) ||
                (cleanUnused && !_isCacheEntryUsed(entry.path));

        if (shouldRemove) {
          await entry.delete();
          removedEntries++;
          freedSpace += stat.size;
        }
      }

      // Check total cache size
      if (maxSize != null) {
        final totalSize = await _calculateCacheSize();
        if (totalSize > maxSize) {
          // Remove oldest entries until under limit
          final sortedEntries = await _getCacheEntriesSortedByAge();
          for (final entry in sortedEntries) {
            if (await _calculateCacheSize() <= maxSize) break;
            await entry.delete();
            removedEntries++;
            freedSpace += await entry.length();
          }
        }
      }

      _emitBuildEvent(BuildEventType.cacheCleanupCompleted,
          details:
              'Removed: $removedEntries entries, Freed: ${freedSpace ~/ 1024}KB');

      return CacheCleanupResult(
        success: true,
        removedEntries: removedEntries,
        freedSpace: freedSpace,
      );
    } catch (e) {
      _emitBuildEvent(BuildEventType.cacheCleanupFailed, error: e.toString());
      return CacheCleanupResult(
        success: false,
        removedEntries: removedEntries,
        freedSpace: freedSpace,
        error: e.toString(),
      );
    }
  }

  /// Get build performance analytics
  BuildAnalytics getBuildAnalytics(String buildId) {
    return _buildAnalytics[buildId] ?? BuildAnalytics.empty(buildId);
  }

  /// Get build cache statistics
  Future<CacheStatistics> getCacheStatistics() async {
    final cacheDir = Directory(_cacheDirectory);
    if (!await cacheDir.exists()) {
      return CacheStatistics.empty();
    }

    final entries = await cacheDir.list().toList();
    int totalSize = 0;
    int entryCount = 0;
    final Map<String, int> entriesByType = {};

    for (final entry in entries) {
      if (entry is! File) continue;

      entryCount++;
      final size = await entry.length();
      totalSize += size;

      final extension = path.extension(entry.path).toLowerCase();
      entriesByType[extension] = (entriesByType[extension] ?? 0) + 1;
    }

    final hitRate = _calculateCacheHitRate();
    final oldestEntry = await _getOldestCacheEntry();
    final newestEntry = await _getNewestCacheEntry();

    return CacheStatistics(
      totalSize: totalSize,
      entryCount: entryCount,
      entriesByType: entriesByType,
      hitRate: hitRate,
      oldestEntry: oldestEntry,
      newestEntry: newestEntry,
      averageEntrySize: entryCount > 0 ? totalSize ~/ entryCount : 0,
    );
  }

  /// Export build optimization report
  Future<String> exportBuildReport({
    DateTime? startDate,
    DateTime? endDate,
    bool includeCacheStats = true,
    bool includeAnalytics = true,
    bool includePerformance = true,
  }) async {
    final report = StringBuffer();
    report.writeln('Build Optimization Report');
    report.writeln('Generated: ${DateTime.now()}');
    report.writeln('=' * 50);

    if (includeCacheStats) {
      report.writeln('\nCache Statistics:');
      final cacheStats = await getCacheStatistics();
      report.writeln(cacheStats.toString());
    }

    if (includeAnalytics) {
      report.writeln('\nBuild Analytics:');
      final recentBuilds = _buildAnalytics.values
          .where((a) => startDate == null || a.startTime.isAfter(startDate))
          .where((a) => endDate == null || a.startTime.isBefore(endDate))
          .toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));

      for (final analytics in recentBuilds.take(10)) {
        report.writeln(analytics.toString());
      }
    }

    if (includePerformance) {
      report.writeln('\nPerformance Metrics:');
      final performanceReport =
          await _performanceService.exportPerformanceReport();
      report.writeln(performanceReport);
    }

    return report.toString();
  }

  // Private helper methods

  Future<void> _initializeCacheDirectory() async {
    final cacheDir = Directory(_cacheDirectory);
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
  }

  Future<void> _loadBuildCache() async {
    final cacheFile = File(path.join(_cacheDirectory, 'build_cache.json'));
    if (!await cacheFile.exists()) return;

    try {
      final jsonData = await cacheFile.readAsString();
      final cacheData = json.decode(jsonData) as Map<String, dynamic>;

      for (final entry in cacheData.entries) {
        _buildCache[entry.key] = BuildCacheEntry.fromJson(entry.value);
      }
    } catch (e) {
      // Ignore cache loading errors
      _emitBuildEvent(BuildEventType.cacheLoadFailed, error: e.toString());
    }
  }

  Future<void> _loadDependencyGraphs() async {
    final graphsFile =
        File(path.join(_cacheDirectory, 'dependency_graphs.json'));
    if (!await graphsFile.exists()) return;

    try {
      final jsonData = await graphsFile.readAsString();
      final graphsData = json.decode(jsonData) as Map<String, dynamic>;

      for (final entry in graphsData.entries) {
        _dependencyGraphs[entry.key] = DependencyGraph.fromJson(entry.value);
      }
    } catch (e) {
      // Ignore dependency graph loading errors
    }
  }

  Future<DependencyGraph> _analyzeDependencies(String projectPath) async {
    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    final pubspecLockFile = File(path.join(projectPath, 'pubspec.lock'));

    final dependencies = <String, DependencyInfo>{};

    if (await pubspecFile.exists()) {
      final pubspecContent = await pubspecFile.readAsString();
      // Parse dependencies from pubspec.yaml
      // This is a simplified implementation
      dependencies.addAll(_parsePubspecDependencies(pubspecContent));
    }

    if (await pubspecLockFile.exists()) {
      final lockContent = await pubspecLockFile.readAsString();
      // Parse locked versions
      dependencies.addAll(_parsePubspecLockDependencies(lockContent));
    }

    return DependencyGraph(
      projectPath: projectPath,
      dependencies: dependencies,
      lastAnalyzed: DateTime.now(),
    );
  }

  Future<List<BuildTask>> _planBuildTasks(
    String projectPath,
    List<BuildTarget> targets,
    BuildMode mode,
    DependencyGraph dependencyGraph,
  ) async {
    final tasks = <BuildTask>[];

    for (final target in targets) {
      // Create build task based on target and dependencies
      final task = BuildTask(
        id: '${target.platform}_${target.architecture}_${DateTime.now().millisecondsSinceEpoch}',
        target: target,
        mode: mode,
        dependencies: dependencyGraph.getDependenciesForTarget(target),
        priority: _calculateTaskPriority(target, mode),
      );

      tasks.add(task);
    }

    // Sort tasks by priority and dependencies
    tasks.sort((a, b) {
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;

      // Check dependencies
      if (a.dependencies.contains(b.id)) return 1;
      if (b.dependencies.contains(a.id)) return -1;

      return 0;
    });

    return tasks;
  }

  Future<List<BuildTask>> _applyBuildCaching(
      List<BuildTask> tasks, String buildId) async {
    final optimizedTasks = <BuildTask>[];

    for (final task in tasks) {
      final cacheKey = _generateCacheKey(task);
      final cachedResult = _buildCache[cacheKey];

      if (cachedResult != null &&
          !cachedResult.isExpired &&
          await _validateCacheEntry(cachedResult)) {
        // Use cached result
        _emitBuildEvent(BuildEventType.cacheHit,
            buildId: buildId, details: 'Task: ${task.id}');
        task.cachedResult = cachedResult;
      } else {
        // Task needs to be executed
        optimizedTasks.add(task);
      }
    }

    return optimizedTasks;
  }

  Future<List<TaskResult>> _executeParallelBuild(
      List<BuildTask> tasks, String buildId) async {
    final results = <TaskResult>[];
    final completer = Completer<List<TaskResult>>();

    if (tasks.isEmpty) {
      completer.complete([]);
      return completer.future;
    }

    int completedTasks = 0;
    final maxConcurrent = min(tasks.length, _maxParallelTasks);

    for (int i = 0; i < maxConcurrent; i++) {
      _executeBuildTask(tasks[i], buildId).then((result) {
        results.add(result);
        completedTasks++;

        if (completedTasks >= tasks.length) {
          completer.complete(results);
        }
      });
    }

    return completer.future;
  }

  Future<List<TaskResult>> _executeSequentialBuild(
      List<BuildTask> tasks, String buildId) async {
    final results = <TaskResult>[];

    for (final task in tasks) {
      final result = await _executeBuildTask(task, buildId);
      results.add(result);
    }

    return results;
  }

  Future<TaskResult> _executeBuildTask(BuildTask task, String buildId) async {
    return await _performanceService.trackOperation(
      'build_task_${task.id}',
      () async {
        try {
          // Execute the actual build command
          final result = await _runBuildCommand(task);

          // Cache successful results
          if (result.success && task.shouldCache) {
            await _cacheBuildResult(task, result);
          }

          return result;
        } catch (e) {
          return TaskResult(
            taskId: task.id,
            success: false,
            errors: [e.toString()],
            warnings: [],
            artifacts: [],
            buildTime: Duration.zero,
          );
        }
      },
    );
  }

  Future<TaskResult> _runBuildCommand(BuildTask task) async {
    // This would execute the actual Flutter build command
    // For now, return a mock result
    await Future.delayed(Duration(seconds: 2)); // Simulate build time

    return TaskResult(
      taskId: task.id,
      success: true,
      errors: [],
      warnings: ['Mock warning'],
      artifacts: ['mock_artifact.apk'],
      buildTime: Duration(seconds: 2),
    );
  }

  Future<List<BuildArtifact>> _collectBuildArtifacts(
      List<TaskResult> results, List<BuildTarget> targets) async {
    final artifacts = <BuildArtifact>[];

    for (final result in results) {
      if (result.success) {
        for (final artifactPath in result.artifacts) {
          final file = File(artifactPath);
          if (await file.exists()) {
            final stat = await file.stat();
            artifacts.add(BuildArtifact(
              path: artifactPath,
              size: stat.size,
              modified: stat.modified,
              target: targets.firstWhere((t) =>
                  t.platform.toString().contains(result.taskId.split('_')[0])),
            ));
          }
        }
      }
    }

    return artifacts;
  }

  BuildAnalytics _generateBuildAnalytics(String buildId, DateTime startTime,
      List<TaskResult> results, int totalTasks) {
    final endTime = DateTime.now();
    final totalBuildTime = endTime.difference(startTime);

    final successfulTasks = results.where((r) => r.success).length;
    final failedTasks = results.where((r) => !r.success).length;

    final totalBuildTimeMs =
        results.fold<int>(0, (sum, r) => sum + r.buildTime.inMilliseconds);
    final averageTaskTime = results.isNotEmpty
        ? Duration(milliseconds: totalBuildTimeMs ~/ results.length)
        : Duration.zero;

    final analytics = BuildAnalytics(
      buildId: buildId,
      startTime: startTime,
      endTime: endTime,
      totalBuildTime: totalBuildTime,
      totalTasks: totalTasks,
      successfulTasks: successfulTasks,
      failedTasks: failedTasks,
      averageTaskTime: averageTaskTime,
      cacheHitRate: _calculateCacheHitRate(),
      parallelEfficiency: _calculateParallelEfficiency(results),
    );

    _buildAnalytics[buildId] = analytics;
    return analytics;
  }

  String _generateCacheKey(BuildTask task) {
    final keyData =
        '${task.target.platform}_${task.target.architecture}_${task.mode}_${task.dependencies.join(',')}';
    return sha256.convert(utf8.encode(keyData)).toString();
  }

  Future<bool> _validateCacheEntry(BuildCacheEntry entry) async {
    // Check if cached artifacts still exist
    for (final artifact in entry.artifacts) {
      final file = File(artifact);
      if (!await file.exists()) {
        return false;
      }
    }
    return true;
  }

  Future<void> _cacheBuildResult(BuildTask task, TaskResult result) async {
    final cacheKey = _generateCacheKey(task);
    final cacheEntry = BuildCacheEntry(
      key: cacheKey,
      taskId: task.id,
      artifacts: result.artifacts,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(_cacheExpiration),
      metadata: {
        'target': task.target.toString(),
        'mode': task.mode.toString(),
        'buildTime': result.buildTime.inMilliseconds.toString(),
      },
    );

    _buildCache[cacheKey] = cacheEntry;
    await _saveBuildCache();
  }

  Future<void> _saveBuildCache() async {
    final cacheFile = File(path.join(_cacheDirectory, 'build_cache.json'));
    final cacheData =
        _buildCache.map((key, value) => MapEntry(key, value.toJson()));
    await cacheFile.writeAsString(json.encode(cacheData));
  }

  Map<String, DependencyInfo> _parsePubspecDependencies(String content) {
    // Simplified parsing - in real implementation, use yaml parser
    final dependencies = <String, DependencyInfo>{};
    // Implementation would parse pubspec.yaml
    return dependencies;
  }

  Map<String, DependencyInfo> _parsePubspecLockDependencies(String content) {
    // Simplified parsing
    final dependencies = <String, DependencyInfo>{};
    // Implementation would parse pubspec.lock
    return dependencies;
  }

  int _calculateTaskPriority(BuildTarget target, BuildMode mode) {
    // Higher priority for release builds and critical platforms
    int priority = 1;

    if (mode == BuildMode.release) priority += 2;
    if (target.platform == TargetPlatform.android ||
        target.platform == TargetPlatform.ios) priority += 1;

    return priority;
  }

  bool _isCacheEntryUsed(String path) {
    // Check if cache entry is referenced in recent builds
    final fileName = path.split('/').last;
    return _buildCache.values.any((entry) =>
        entry.artifacts.any((artifact) => artifact.contains(fileName)));
  }

  Future<int> _calculateCacheSize() async {
    final cacheDir = Directory(_cacheDirectory);
    if (!await cacheDir.exists()) return 0;

    int totalSize = 0;
    await for (final entity in cacheDir.list()) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }

  Future<List<File>> _getCacheEntriesSortedByAge() async {
    final cacheDir = Directory(_cacheDirectory);
    final entries = <File>[];

    await for (final entity in cacheDir.list()) {
      if (entity is File) {
        entries.add(entity);
      }
    }

    entries
        .sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
    return entries;
  }

  Future<DateTime?> _getOldestCacheEntry() async {
    final entries = await _getCacheEntriesSortedByAge();
    return entries.isNotEmpty ? entries.first.statSync().modified : null;
  }

  Future<DateTime?> _getNewestCacheEntry() async {
    final entries = await _getCacheEntriesSortedByAge();
    return entries.isNotEmpty ? entries.last.statSync().modified : null;
  }

  double _calculateCacheHitRate() {
    // Simplified calculation
    return 0.75; // 75% hit rate placeholder
  }

  double _calculateParallelEfficiency(List<TaskResult> results) {
    if (results.length <= 1) return 1.0;

    final totalTime =
        results.fold<int>(0, (sum, r) => sum + r.buildTime.inMilliseconds);
    final longestTaskTime =
        results.map((r) => r.buildTime.inMilliseconds).reduce(max);

    return longestTaskTime / totalTime;
  }

  void _emitBuildEvent(
    BuildEventType type, {
    String? buildId,
    String? details,
    String? error,
  }) {
    final event = BuildEvent(
      type: type,
      timestamp: DateTime.now(),
      buildId: buildId,
      details: details,
      error: error,
    );

    _buildEventController.add(event);
  }

  void dispose() {
    _buildEventController.close();
  }
}

/// Semaphore for controlling parallel execution
class Semaphore {
  final int _maxCount;
  int _currentCount = 0;
  final List<Completer<void>> _waitQueue = [];

  Semaphore(this._maxCount);

  Future<void> acquire() async {
    if (_currentCount < _maxCount) {
      _currentCount++;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    await completer.future;
  }

  void release() {
    _currentCount--;
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeAt(0);
      _currentCount++;
      completer.complete();
    }
  }
}

/// Build target configuration
class BuildTarget {
  final TargetPlatform platform;
  final String architecture;
  final Map<String, dynamic> config;

  BuildTarget({
    required this.platform,
    required this.architecture,
    this.config = const {},
  });

  @override
  String toString() => '${platform}_$architecture';
}

/// Build mode
enum BuildMode {
  debug,
  profile,
  release,
}

/// Target platform
enum TargetPlatform {
  android,
  ios,
  windows,
  linux,
  macos,
  web,
}

/// Build task
class BuildTask {
  final String id;
  final BuildTarget target;
  final BuildMode mode;
  final List<String> dependencies;
  final int priority;
  BuildCacheEntry? cachedResult;

  BuildTask({
    required this.id,
    required this.target,
    required this.mode,
    required this.dependencies,
    required this.priority,
  });

  bool get shouldCache => mode != BuildMode.debug;
}

/// Task execution result
class TaskResult {
  final String taskId;
  final bool success;
  final List<String> errors;
  final List<String> warnings;
  final List<String> artifacts;
  final Duration buildTime;

  TaskResult({
    required this.taskId,
    required this.success,
    required this.errors,
    required this.warnings,
    required this.artifacts,
    required this.buildTime,
  });
}

/// Build result
class BuildResult {
  final String buildId;
  final bool success;
  final List<BuildTarget> targets;
  final List<BuildArtifact> artifacts;
  final BuildAnalytics analytics;
  final List<String> warnings;
  final List<String> errors;

  BuildResult({
    required this.buildId,
    required this.success,
    required this.targets,
    required this.artifacts,
    required this.analytics,
    required this.warnings,
    required this.errors,
  });
}

/// Build artifact
class BuildArtifact {
  final String path;
  final int size;
  final DateTime modified;
  final BuildTarget target;

  BuildArtifact({
    required this.path,
    required this.size,
    required this.modified,
    required this.target,
  });
}

/// Build analytics
class BuildAnalytics {
  final String buildId;
  final DateTime startTime;
  final DateTime endTime;
  final Duration totalBuildTime;
  final int totalTasks;
  final int successfulTasks;
  final int failedTasks;
  final Duration averageTaskTime;
  final double cacheHitRate;
  final double parallelEfficiency;

  BuildAnalytics({
    required this.buildId,
    required this.startTime,
    required this.endTime,
    required this.totalBuildTime,
    required this.totalTasks,
    required this.successfulTasks,
    required this.failedTasks,
    required this.averageTaskTime,
    required this.cacheHitRate,
    required this.parallelEfficiency,
  });

  factory BuildAnalytics.empty(String buildId) {
    return BuildAnalytics(
      buildId: buildId,
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      totalBuildTime: Duration.zero,
      totalTasks: 0,
      successfulTasks: 0,
      failedTasks: 0,
      averageTaskTime: Duration.zero,
      cacheHitRate: 0.0,
      parallelEfficiency: 0.0,
    );
  }

  @override
  String toString() {
    return '''
Build: $buildId
Duration: ${totalBuildTime.inMilliseconds}ms
Tasks: $totalTasks (Success: $successfulTasks, Failed: $failedTasks)
Average Task Time: ${averageTaskTime.inMilliseconds}ms
Cache Hit Rate: ${(cacheHitRate * 100).round()}%
Parallel Efficiency: ${(parallelEfficiency * 100).round()}%
''';
  }
}

/// Build metrics
class BuildMetrics {
  final String metricName;
  final List<double> values;
  final DateTime timestamp;

  BuildMetrics({
    required this.metricName,
    required this.values,
    required this.timestamp,
  });
}

/// Dependency graph
class DependencyGraph {
  final String projectPath;
  final Map<String, DependencyInfo> dependencies;
  final DateTime lastAnalyzed;

  DependencyGraph({
    required this.projectPath,
    required this.dependencies,
    required this.lastAnalyzed,
  });

  List<String> getDependenciesForTarget(BuildTarget target) {
    // Return dependencies relevant to the target
    return dependencies.keys
        .where((dep) => dep.contains(target.platform.toString()))
        .toList();
  }

  Map<String, dynamic> toJson() => {
        'projectPath': projectPath,
        'dependencies': dependencies.map((k, v) => MapEntry(k, v.toJson())),
        'lastAnalyzed': lastAnalyzed.toIso8601String(),
      };

  factory DependencyGraph.fromJson(Map<String, dynamic> json) {
    return DependencyGraph(
      projectPath: json['projectPath'],
      dependencies: (json['dependencies'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, DependencyInfo.fromJson(v)),
      ),
      lastAnalyzed: DateTime.parse(json['lastAnalyzed']),
    );
  }
}

/// Dependency information
class DependencyInfo {
  final String name;
  final String version;
  final List<String> dependencies;

  DependencyInfo({
    required this.name,
    required this.version,
    required this.dependencies,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        'dependencies': dependencies,
      };

  factory DependencyInfo.fromJson(Map<String, dynamic> json) {
    return DependencyInfo(
      name: json['name'],
      version: json['version'],
      dependencies: List<String>.from(json['dependencies']),
    );
  }
}

/// Build cache entry
class BuildCacheEntry {
  final String key;
  final String taskId;
  final List<String> artifacts;
  final DateTime createdAt;
  final DateTime expiresAt;
  final Map<String, String> metadata;

  BuildCacheEntry({
    required this.key,
    required this.taskId,
    required this.artifacts,
    required this.createdAt,
    required this.expiresAt,
    required this.metadata,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'key': key,
        'taskId': taskId,
        'artifacts': artifacts,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'metadata': metadata,
      };

  factory BuildCacheEntry.fromJson(Map<String, dynamic> json) {
    return BuildCacheEntry(
      key: json['key'],
      taskId: json['taskId'],
      artifacts: List<String>.from(json['artifacts']),
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      metadata: Map<String, String>.from(json['metadata']),
    );
  }
}

/// Build event types
enum BuildEventType {
  serviceInitialized,
  initializationFailed,
  buildStarted,
  buildCompleted,
  buildFailed,
  cacheHit,
  cacheMiss,
  cacheCleanupStarted,
  cacheCleanupCompleted,
  cacheCleanupFailed,
  cacheLoadFailed,
  taskStarted,
  taskCompleted,
  taskFailed,
}

/// Build event
class BuildEvent {
  final BuildEventType type;
  final DateTime timestamp;
  final String? buildId;
  final String? details;
  final String? error;

  BuildEvent({
    required this.type,
    required this.timestamp,
    this.buildId,
    this.details,
    this.error,
  });
}

/// Cache cleanup result
class CacheCleanupResult {
  final bool success;
  final int removedEntries;
  final int freedSpace;
  final String? error;

  CacheCleanupResult({
    required this.success,
    required this.removedEntries,
    required this.freedSpace,
    this.error,
  });
}

/// Cache statistics
class CacheStatistics {
  final int totalSize;
  final int entryCount;
  final Map<String, int> entriesByType;
  final double hitRate;
  final DateTime? oldestEntry;
  final DateTime? newestEntry;
  final int averageEntrySize;

  CacheStatistics({
    required this.totalSize,
    required this.entryCount,
    required this.entriesByType,
    required this.hitRate,
    required this.oldestEntry,
    required this.newestEntry,
    required this.averageEntrySize,
  });

  factory CacheStatistics.empty() {
    return CacheStatistics(
      totalSize: 0,
      entryCount: 0,
      entriesByType: {},
      hitRate: 0.0,
      oldestEntry: null,
      newestEntry: null,
      averageEntrySize: 0,
    );
  }

  @override
  String toString() {
    return '''
Cache Statistics:
Total Size: ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB
Entry Count: $entryCount
Average Entry Size: ${(averageEntrySize / 1024).toStringAsFixed(2)} KB
Hit Rate: ${(hitRate * 100).round()}%
Entries by Type: $entriesByType
Oldest Entry: $oldestEntry
Newest Entry: $newestEntry
''';
  }
}
