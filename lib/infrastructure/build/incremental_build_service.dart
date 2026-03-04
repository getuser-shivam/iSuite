import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';
import 'build_optimization_service.dart';

/// Incremental Build Support Service
/// Provides intelligent incremental builds by tracking changes and rebuilding only what's necessary
class IncrementalBuildService {
  static final IncrementalBuildService _instance =
      IncrementalBuildService._internal();
  factory IncrementalBuildService() => _instance;
  IncrementalBuildService._internal();

  final BuildOptimizationService _buildOptimization =
      BuildOptimizationService();
  final StreamController<IncrementalBuildEvent> _eventController =
      StreamController.broadcast();

  Stream<IncrementalBuildEvent> get incrementalBuildEvents =>
      _eventController.stream;

  // File tracking
  final Map<String, FileState> _fileStates = {};
  final Map<String, DirectoryWatcher> _directoryWatchers = {};

  // Build state management
  final Map<String, BuildState> _buildStates = {};
  final Map<String, Set<String>> _dependencyGraph = {};

  // Incremental build configuration
  final Map<String, IncrementalBuildConfig> _buildConfigs = {};

  bool _isInitialized = false;
  Timer? _changeProcessingTimer;

  // Configuration
  static const Duration _changeProcessingDelay = Duration(milliseconds: 500);
  static const String _buildStateDirectory = '.incremental_build';
  static const int _maxTrackedFiles = 10000;

  /// Initialize incremental build service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeBuildStateDirectory();
      await _loadBuildStates();
      await _loadDependencyGraphs();

      _isInitialized = true;
      _emitEvent(IncrementalBuildEventType.serviceInitialized);
    } catch (e) {
      _emitEvent(IncrementalBuildEventType.initializationFailed,
          error: e.toString());
      rethrow;
    }
  }

  /// Start incremental build monitoring for a project
  Future<void> startIncrementalMonitoring(String projectPath) async {
    final config = IncrementalBuildConfig(
      projectPath: projectPath,
      watchPatterns: [
        'lib/**/*.dart',
        'pubspec.yaml',
        'assets/**/*',
        'android/**/*',
        'ios/**/*',
        'windows/**/*',
        'linux/**/*',
        'macos/**/*',
        'web/**/*',
      ],
      ignorePatterns: [
        '.git/**',
        'build/**',
        '.dart_tool/**',
        'test/**',
        '**/*.tmp',
        '**/*.bak',
      ],
    );

    _buildConfigs[projectPath] = config;
    await _startFileWatching(projectPath, config);

    _emitEvent(IncrementalBuildEventType.monitoringStarted,
        projectPath: projectPath);
  }

  /// Stop incremental build monitoring
  Future<void> stopIncrementalMonitoring(String projectPath) async {
    final watcher = _directoryWatchers[projectPath];
    if (watcher != null) {
      await watcher.events.drain();
      _directoryWatchers.remove(projectPath);
    }

    _buildConfigs.remove(projectPath);
    _emitEvent(IncrementalBuildEventType.monitoringStopped,
        projectPath: projectPath);
  }

  /// Perform incremental build based on changes
  Future<IncrementalBuildResult> performIncrementalBuild({
    required String projectPath,
    required List<BuildTarget> targets,
    BuildMode mode = BuildMode.debug,
    bool forceFullBuild = false,
  }) async {
    final startTime = DateTime.now();
    _emitEvent(IncrementalBuildEventType.buildStarted,
        projectPath: projectPath);

    try {
      // Get current build state
      final buildState =
          _buildStates[projectPath] ?? BuildState.empty(projectPath);

      // Determine changed files
      final changedFiles = forceFullBuild
          ? await _getAllProjectFiles(projectPath)
          : await _getChangedFiles(projectPath, buildState);

      if (changedFiles.isEmpty && !forceFullBuild) {
        _emitEvent(IncrementalBuildEventType.buildSkipped,
            projectPath: projectPath, details: 'No changes detected');
        return IncrementalBuildResult(
          buildId: 'incremental_${DateTime.now().millisecondsSinceEpoch}',
          success: true,
          projectPath: projectPath,
          targets: targets,
          changedFiles: [],
          rebuiltTargets: [],
          skippedTargets: targets,
          buildTime: Duration.zero,
          reason: 'No changes detected',
        );
      }

      // Analyze what needs to be rebuilt
      final rebuildPlan = await _analyzeRebuildRequirements(
          projectPath, changedFiles, targets, mode);

      // Execute incremental build
      final buildResult =
          await _executeIncrementalBuild(projectPath, rebuildPlan, mode);

      // Update build state
      final newBuildState = BuildState(
        projectPath: projectPath,
        lastBuildTime: DateTime.now(),
        lastBuildMode: mode,
        fileHashes: await _calculateFileHashes(projectPath),
        buildArtifacts: buildResult.artifacts,
      );

      _buildStates[projectPath] = newBuildState;
      await _saveBuildState(newBuildState);

      final totalTime = DateTime.now().difference(startTime);

      final result = IncrementalBuildResult(
        buildId: buildResult.buildId,
        success: buildResult.success,
        projectPath: projectPath,
        targets: targets,
        changedFiles: changedFiles,
        rebuiltTargets: rebuildPlan.targetsToRebuild,
        skippedTargets: rebuildPlan.targetsToSkip,
        buildTime: totalTime,
        reason: rebuildPlan.reason,
      );

      _emitEvent(
          result.success
              ? IncrementalBuildEventType.buildCompleted
              : IncrementalBuildEventType.buildFailed,
          projectPath: projectPath,
          details:
              'Rebuilt: ${rebuildPlan.targetsToRebuild.length}, Skipped: ${rebuildPlan.targetsToSkip.length}');

      return result;
    } catch (e) {
      final totalTime = DateTime.now().difference(startTime);
      _emitEvent(IncrementalBuildEventType.buildFailed,
          projectPath: projectPath, error: e.toString());

      return IncrementalBuildResult(
        buildId: 'incremental_${DateTime.now().millisecondsSinceEpoch}',
        success: false,
        projectPath: projectPath,
        targets: targets,
        changedFiles: [],
        rebuiltTargets: [],
        skippedTargets: targets,
        buildTime: totalTime,
        reason: 'Build failed: $e',
      );
    }
  }

  /// Get incremental build status
  IncrementalBuildStatus getIncrementalBuildStatus(String projectPath) {
    final config = _buildConfigs[projectPath];
    final buildState = _buildStates[projectPath];
    final isMonitoring = _directoryWatchers.containsKey(projectPath);

    return IncrementalBuildStatus(
      projectPath: projectPath,
      isMonitoring: isMonitoring,
      lastBuildTime: buildState?.lastBuildTime,
      trackedFiles: _fileStates.length,
      buildConfigurations: config != null ? 1 : 0,
    );
  }

  /// Clear incremental build cache
  Future<void> clearIncrementalCache(String projectPath) async {
    _buildStates.remove(projectPath);
    _fileStates.clear();
    _dependencyGraph.clear();

    final stateFile = File(path.join(
        _buildStateDirectory, '${_getProjectHash(projectPath)}.json'));
    if (await stateFile.exists()) {
      await stateFile.delete();
    }

    _emitEvent(IncrementalBuildEventType.cacheCleared,
        projectPath: projectPath);
  }

  /// Get build impact analysis
  Future<BuildImpactAnalysis> analyzeBuildImpact(
    String projectPath,
    List<String> changedFiles,
    List<BuildTarget> targets,
  ) async {
    final affectedTargets = <BuildTarget>[];
    final unaffectedTargets = <BuildTarget>[];
    final reasons = <String>[];

    for (final target in targets) {
      final impact =
          await _calculateBuildImpact(projectPath, changedFiles, target);

      if (impact.requiresRebuild) {
        affectedTargets.add(target);
        reasons.add('${target.platform}: ${impact.reason}');
      } else {
        unaffectedTargets.add(target);
      }
    }

    return BuildImpactAnalysis(
      projectPath: projectPath,
      changedFiles: changedFiles,
      affectedTargets: affectedTargets,
      unaffectedTargets: unaffectedTargets,
      impactReasons: reasons,
      estimatedTimeSavings:
          _estimateTimeSavings(affectedTargets.length, targets.length),
    );
  }

  // Private methods

  Future<void> _initializeBuildStateDirectory() async {
    final dir = Directory(_buildStateDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  Future<void> _loadBuildStates() async {
    final dir = Directory(_buildStateDirectory);
    if (!await dir.exists()) return;

    await for (final file in dir.list()) {
      if (file is File && file.path.endsWith('.json')) {
        try {
          final content = await file.readAsString();
          final stateData = json.decode(content) as Map<String, dynamic>;
          final buildState = BuildState.fromJson(stateData);
          _buildStates[buildState.projectPath] = buildState;
        } catch (e) {
          // Skip corrupted state files
        }
      }
    }
  }

  Future<void> _loadDependencyGraphs() async {
    // Load dependency information for incremental builds
    // This would analyze pubspec files and import relationships
  }

  Future<void> _startFileWatching(
      String projectPath, IncrementalBuildConfig config) async {
    final watcher = DirectoryWatcher(projectPath);
    _directoryWatchers[projectPath] = watcher;

    // Initialize file states
    await _initializeFileStates(projectPath, config);

    // Listen for changes
    watcher.events.listen((event) {
      _handleFileChange(projectPath, event, config);
    });
  }

  Future<void> _initializeFileStates(
      String projectPath, IncrementalBuildConfig config) async {
    final projectDir = Directory(projectPath);
    await for (final file in projectDir.list(recursive: true)) {
      if (file is File && _shouldTrackFile(file.path, config)) {
        final hash = await _calculateFileHash(file.path);
        _fileStates[file.path] = FileState(
          path: file.path,
          hash: hash,
          lastModified: await file.lastModified(),
          size: await file.length(),
        );
      }
    }
  }

  void _handleFileChange(
      String projectPath, WatchEvent event, IncrementalBuildConfig config) {
    if (!_shouldTrackFile(event.path, config)) return;

    // Debounce changes
    _changeProcessingTimer?.cancel();
    _changeProcessingTimer = Timer(_changeProcessingDelay, () async {
      await _processFileChange(projectPath, event);
    });
  }

  Future<void> _processFileChange(String projectPath, WatchEvent event) async {
    final file = File(event.path);
    if (!await file.exists()) return;

    final newHash = await _calculateFileHash(event.path);
    final existingState = _fileStates[event.path];

    if (existingState == null || existingState.hash != newHash) {
      // File has changed
      _fileStates[event.path] = FileState(
        path: event.path,
        hash: newHash,
        lastModified: await file.lastModified(),
        size: await file.length(),
      );

      _emitEvent(IncrementalBuildEventType.fileChanged,
          projectPath: projectPath, details: event.path);
    }
  }

  Future<List<String>> _getChangedFiles(
      String projectPath, BuildState buildState) async {
    final changedFiles = <String>[];

    for (final entry in _fileStates.entries) {
      final currentHash = entry.value.hash;
      final previousHash = buildState.fileHashes[entry.key];

      if (previousHash == null || currentHash != previousHash) {
        changedFiles.add(entry.key);
      }
    }

    return changedFiles;
  }

  Future<List<String>> _getAllProjectFiles(String projectPath) async {
    final files = <String>[];
    final projectDir = Directory(projectPath);

    await for (final file in projectDir.list(recursive: true)) {
      if (file is File) {
        files.add(file.path);
      }
    }

    return files;
  }

  Future<RebuildPlan> _analyzeRebuildRequirements(
    String projectPath,
    List<String> changedFiles,
    List<BuildTarget> targets,
    BuildMode mode,
  ) async {
    final targetsToRebuild = <BuildTarget>[];
    final targetsToSkip = <BuildTarget>[];
    final reasons = <String>[];

    for (final target in targets) {
      final impact =
          await _calculateBuildImpact(projectPath, changedFiles, target);

      if (impact.requiresRebuild) {
        targetsToRebuild.add(target);
        reasons.add('${target.platform}: ${impact.reason}');
      } else {
        targetsToSkip.add(target);
      }
    }

    return RebuildPlan(
      targetsToRebuild: targetsToRebuild,
      targetsToSkip: targetsToSkip,
      reason: reasons.isNotEmpty ? reasons.join('; ') : 'No rebuilds needed',
    );
  }

  Future<BuildImpact> _calculateBuildImpact(
    String projectPath,
    List<String> changedFiles,
    BuildTarget target,
  ) async {
    // Check for critical files that always require rebuild
    final criticalFiles = [
      'pubspec.yaml',
      'pubspec.lock',
      path.join('android', 'build.gradle'),
      path.join('ios', 'Podfile'),
    ];

    for (final file in changedFiles) {
      final relativePath = path.relative(file, from: projectPath);

      if (criticalFiles.any((critical) => relativePath.contains(critical))) {
        return BuildImpact(
            requiresRebuild: true,
            reason: 'Critical configuration file changed');
      }

      // Check if file is relevant to target platform
      if (_isFileRelevantToTarget(relativePath, target)) {
        return BuildImpact(
            requiresRebuild: true, reason: 'Platform-specific file changed');
      }

      // Check if it's a core library file
      if (relativePath.startsWith('lib/') && relativePath.endsWith('.dart')) {
        return BuildImpact(
            requiresRebuild: true, reason: 'Core library file changed');
      }
    }

    // Check for asset changes
    final assetChanges = changedFiles
        .where((file) =>
            path.relative(file, from: projectPath).startsWith('assets/'))
        .toList();

    if (assetChanges.isNotEmpty) {
      return BuildImpact(
          requiresRebuild: true,
          reason: '${assetChanges.length} asset(s) changed');
    }

    return BuildImpact(
        requiresRebuild: false, reason: 'No relevant changes detected');
  }

  Future<BuildResult> _executeIncrementalBuild(
    String projectPath,
    RebuildPlan rebuildPlan,
    BuildMode mode,
  ) async {
    // Only rebuild targets that need it
    final effectiveTargets = rebuildPlan.targetsToRebuild;

    if (effectiveTargets.isEmpty) {
      return BuildResult(
        buildId: 'incremental_${DateTime.now().millisecondsSinceEpoch}',
        success: true,
        targets: [],
        artifacts: [],
        analytics: BuildAnalytics.empty('incremental'),
        warnings: [],
        errors: [],
      );
    }

    // Use the build optimization service for the actual build
    return await _buildOptimization.executeOptimizedBuild(
      projectPath: projectPath,
      targets: effectiveTargets,
      mode: mode,
      enableParallel: true,
      useCache: true,
    );
  }

  bool _shouldTrackFile(String filePath, IncrementalBuildConfig config) {
    final relativePath = path.relative(filePath, from: config.projectPath);

    // Check ignore patterns
    for (final pattern in config.ignorePatterns) {
      if (_matchesPattern(relativePath, pattern)) {
        return false;
      }
    }

    // Check watch patterns
    for (final pattern in config.watchPatterns) {
      if (_matchesPattern(relativePath, pattern)) {
        return true;
      }
    }

    return false;
  }

  bool _matchesPattern(String path, String pattern) {
    // Simple glob matching - in production, use a proper glob library
    final regexPattern = pattern
        .replaceAll('.', '\\.')
        .replaceAll('*', '.*')
        .replaceAll('?', '.');
    final regex = RegExp('^$regexPattern\$');
    return regex.hasMatch(path);
  }

  bool _isFileRelevantToTarget(String relativePath, BuildTarget target) {
    switch (target.platform) {
      case TargetPlatform.android:
        return relativePath.startsWith('android/') ||
            relativePath.startsWith('lib/') ||
            relativePath == 'pubspec.yaml';
      case TargetPlatform.ios:
        return relativePath.startsWith('ios/') ||
            relativePath.startsWith('lib/') ||
            relativePath == 'pubspec.yaml';
      case TargetPlatform.windows:
        return relativePath.startsWith('windows/') ||
            relativePath.startsWith('lib/') ||
            relativePath == 'pubspec.yaml';
      case TargetPlatform.linux:
        return relativePath.startsWith('linux/') ||
            relativePath.startsWith('lib/') ||
            relativePath == 'pubspec.yaml';
      case TargetPlatform.macos:
        return relativePath.startsWith('macos/') ||
            relativePath.startsWith('lib/') ||
            relativePath == 'pubspec.yaml';
      case TargetPlatform.web:
        return relativePath.startsWith('web/') ||
            relativePath.startsWith('lib/') ||
            relativePath == 'pubspec.yaml';
      default:
        return true;
    }
  }

  Future<String> _calculateFileHash(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return '';

    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  Future<Map<String, String>> _calculateFileHashes(String projectPath) async {
    final hashes = <String, String>{};

    for (final entry in _fileStates.entries) {
      hashes[entry.key] = entry.value.hash;
    }

    return hashes;
  }

  Future<void> _saveBuildState(BuildState buildState) async {
    final projectHash = _getProjectHash(buildState.projectPath);
    final stateFile =
        File(path.join(_buildStateDirectory, '$projectHash.json'));

    final stateData = buildState.toJson();
    await stateFile.writeAsString(json.encode(stateData));
  }

  String _getProjectHash(String projectPath) {
    return sha256.convert(utf8.encode(projectPath)).toString().substring(0, 8);
  }

  double _estimateTimeSavings(int rebuildCount, int totalCount) {
    if (totalCount == 0) return 0.0;

    final skipRatio = (totalCount - rebuildCount) / totalCount;
    // Assume 70% time savings for skipped builds
    return skipRatio * 0.7;
  }

  void _emitEvent(
    IncrementalBuildEventType type, {
    String? projectPath,
    String? details,
    String? error,
  }) {
    final event = IncrementalBuildEvent(
      type: type,
      timestamp: DateTime.now(),
      projectPath: projectPath,
      details: details,
      error: error,
    );

    _eventController.add(event);
  }

  void dispose() {
    _changeProcessingTimer?.cancel();
    for (final watcher in _directoryWatchers.values) {
      watcher.events.drain();
    }
    _directoryWatchers.clear();
    _eventController.close();
  }
}

/// Supporting data classes

class FileState {
  final String path;
  final String hash;
  final DateTime lastModified;
  final int size;

  FileState({
    required this.path,
    required this.hash,
    required this.lastModified,
    required this.size,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'hash': hash,
        'lastModified': lastModified.toIso8601String(),
        'size': size,
      };

  factory FileState.fromJson(Map<String, dynamic> json) {
    return FileState(
      path: json['path'],
      hash: json['hash'],
      lastModified: DateTime.parse(json['lastModified']),
      size: json['size'],
    );
  }
}

class BuildState {
  final String projectPath;
  final DateTime lastBuildTime;
  final BuildMode lastBuildMode;
  final Map<String, String> fileHashes;
  final List<String> buildArtifacts;

  BuildState({
    required this.projectPath,
    required this.lastBuildTime,
    required this.lastBuildMode,
    required this.fileHashes,
    required this.buildArtifacts,
  });

  factory BuildState.empty(String projectPath) {
    return BuildState(
      projectPath: projectPath,
      lastBuildTime: DateTime.fromMillisecondsSinceEpoch(0),
      lastBuildMode: BuildMode.debug,
      fileHashes: {},
      buildArtifacts: [],
    );
  }

  Map<String, dynamic> toJson() => {
        'projectPath': projectPath,
        'lastBuildTime': lastBuildTime.toIso8601String(),
        'lastBuildMode': lastBuildMode.toString(),
        'fileHashes': fileHashes,
        'buildArtifacts': buildArtifacts,
      };

  factory BuildState.fromJson(Map<String, dynamic> json) {
    return BuildState(
      projectPath: json['projectPath'],
      lastBuildTime: DateTime.parse(json['lastBuildTime']),
      lastBuildMode: BuildMode.values.firstWhere(
        (e) => e.toString() == json['lastBuildMode'],
        orElse: () => BuildMode.debug,
      ),
      fileHashes: Map<String, String>.from(json['fileHashes']),
      buildArtifacts: List<String>.from(json['buildArtifacts']),
    );
  }
}

class IncrementalBuildConfig {
  final String projectPath;
  final List<String> watchPatterns;
  final List<String> ignorePatterns;

  IncrementalBuildConfig({
    required this.projectPath,
    required this.watchPatterns,
    required this.ignorePatterns,
  });
}

class RebuildPlan {
  final List<BuildTarget> targetsToRebuild;
  final List<BuildTarget> targetsToSkip;
  final String reason;

  RebuildPlan({
    required this.targetsToRebuild,
    required this.targetsToSkip,
    required this.reason,
  });
}

class BuildImpact {
  final bool requiresRebuild;
  final String reason;

  BuildImpact({
    required this.requiresRebuild,
    required this.reason,
  });
}

class IncrementalBuildResult {
  final String buildId;
  final bool success;
  final String projectPath;
  final List<BuildTarget> targets;
  final List<String> changedFiles;
  final List<BuildTarget> rebuiltTargets;
  final List<BuildTarget> skippedTargets;
  final Duration buildTime;
  final String reason;

  IncrementalBuildResult({
    required this.buildId,
    required this.success,
    required this.projectPath,
    required this.targets,
    required this.changedFiles,
    required this.rebuiltTargets,
    required this.skippedTargets,
    required this.buildTime,
    required this.reason,
  });

  double get timeSavingsRatio {
    if (targets.isEmpty) return 0.0;
    return skippedTargets.length / targets.length;
  }

  @override
  String toString() {
    return '''
Incremental Build Result:
ID: $buildId
Success: $success
Project: $projectPath
Targets: ${targets.length}
Changed Files: ${changedFiles.length}
Rebuilt: ${rebuiltTargets.length}
Skipped: ${skippedTargets.length}
Build Time: ${buildTime.inMilliseconds}ms
Time Savings: ${(timeSavingsRatio * 100).round()}%
Reason: $reason
''';
  }
}

class IncrementalBuildStatus {
  final String projectPath;
  final bool isMonitoring;
  final DateTime? lastBuildTime;
  final int trackedFiles;
  final int buildConfigurations;

  IncrementalBuildStatus({
    required this.projectPath,
    required this.isMonitoring,
    this.lastBuildTime,
    required this.trackedFiles,
    required this.buildConfigurations,
  });

  @override
  String toString() {
    return '''
Incremental Build Status:
Project: $projectPath
Monitoring: $isMonitoring
Last Build: $lastBuildTime
Tracked Files: $trackedFiles
Configurations: $buildConfigurations
''';
  }
}

class BuildImpactAnalysis {
  final String projectPath;
  final List<String> changedFiles;
  final List<BuildTarget> affectedTargets;
  final List<BuildTarget> unaffectedTargets;
  final List<String> impactReasons;
  final double estimatedTimeSavings;

  BuildImpactAnalysis({
    required this.projectPath,
    required this.changedFiles,
    required this.affectedTargets,
    required this.unaffectedTargets,
    required this.impactReasons,
    required this.estimatedTimeSavings,
  });

  @override
  String toString() {
    return '''
Build Impact Analysis:
Project: $projectPath
Changed Files: ${changedFiles.length}
Affected Targets: ${affectedTargets.length}
Unaffected Targets: ${unaffectedTargets.length}
Estimated Time Savings: ${(estimatedTimeSavings * 100).round()}%
Impact Reasons:
${impactReasons.map((r) => '  • $r').join('\n')}
''';
  }
}

/// Incremental build event types
enum IncrementalBuildEventType {
  serviceInitialized,
  initializationFailed,
  monitoringStarted,
  monitoringStopped,
  fileChanged,
  buildStarted,
  buildCompleted,
  buildFailed,
  buildSkipped,
  cacheCleared,
}

/// Incremental build event
class IncrementalBuildEvent {
  final IncrementalBuildEventType type;
  final DateTime timestamp;
  final String? projectPath;
  final String? details;
  final String? error;

  IncrementalBuildEvent({
    required this.type,
    required this.timestamp,
    this.projectPath,
    this.details,
    this.error,
  });
}
