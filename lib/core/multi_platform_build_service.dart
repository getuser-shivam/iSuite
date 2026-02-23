import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'build_optimization_service.dart';
import 'build_analytics_service.dart';

/// Multi-Platform Build Support Service
/// Provides comprehensive build support for multiple platforms with platform-specific optimizations
class MultiPlatformBuildService {
  static final MultiPlatformBuildService _instance = MultiPlatformBuildService._internal();
  factory MultiPlatformBuildService() => _instance;
  MultiPlatformBuildService._internal();

  final BuildOptimizationService _buildOptimization = BuildOptimizationService();
  final BuildAnalyticsService _buildAnalytics = BuildAnalyticsService();
  final StreamController<MultiPlatformBuildEvent> _eventController = StreamController.broadcast();

  Stream<MultiPlatformBuildEvent> get multiPlatformBuildEvents => _eventController.stream;

  // Platform configurations
  final Map<TargetPlatform, PlatformConfiguration> _platformConfigs = {};
  final Map<String, BuildEnvironment> _buildEnvironments = {};

  // Build matrices and strategies
  final Map<String, BuildMatrix> _buildMatrices = {};
  final Map<TargetPlatform, BuildStrategy> _platformStrategies = {};

  bool _isInitialized = false;

  // Configuration
  static const String _platformsConfigFile = 'multiplatform_config.json';
  static const int _maxConcurrentPlatformBuilds = 2; // Limit concurrent platform builds

  /// Initialize multi-platform build service
  Future<void> initialize({
    Map<TargetPlatform, PlatformConfiguration>? platformConfigs,
    List<BuildEnvironment>? environments,
  }) async {
    if (_isInitialized) return;

    try {
      // Load platform configurations
      await _loadPlatformConfigurations();

      // Add custom configurations
      if (platformConfigs != null) {
        _platformConfigs.addAll(platformConfigs);
      }

      // Initialize build environments
      if (environments != null) {
        for (final env in environments) {
          _buildEnvironments[env.name] = env;
        }
      } else {
        await _initializeDefaultEnvironments();
      }

      // Initialize platform strategies
      _initializePlatformStrategies();

      _isInitialized = true;
      _emitEvent(MultiPlatformBuildEventType.serviceInitialized);

    } catch (e) {
      _emitEvent(MultiPlatformBuildEventType.initializationFailed, error: e.toString());
      rethrow;
    }
  }

  /// Execute multi-platform build
  Future<MultiPlatformBuildResult> executeMultiPlatformBuild({
    required String projectPath,
    required List<TargetPlatform> platforms,
    BuildMode mode = BuildMode.release,
    Map<String, dynamic>? buildConfig,
    String? environment,
    bool parallelPlatforms = true,
    bool optimizeForDistribution = true,
  }) async {
    _emitEvent(MultiPlatformBuildEventType.buildStarted,
      details: 'Platforms: ${platforms.length}, Mode: $mode');

    final buildId = 'multiplatform_${DateTime.now().millisecondsSinceEpoch}';
    final startTime = DateTime.now();

    try {
      // Validate platforms and environments
      await _validatePlatformsAndEnvironment(platforms, environment);

      // Create build matrix
      final buildMatrix = _createBuildMatrix(projectPath, platforms, mode, buildConfig);
      _buildMatrices[buildId] = buildMatrix;

      // Prepare build environments
      final buildEnvs = await _prepareBuildEnvironments(buildMatrix, environment);

      // Execute platform builds
      final platformResults = parallelPlatforms
          ? await _executeParallelPlatformBuilds(buildMatrix, buildEnvs, buildId)
          : await _executeSequentialPlatformBuilds(buildMatrix, buildEnvs, buildId);

      // Process and optimize results
      final processedResults = await _processBuildResults(platformResults, optimizeForDistribution);

      // Generate distribution artifacts
      final distributionResult = optimizeForDistribution
          ? await _generateDistributionArtifacts(processedResults, buildId)
          : null;

      // Record analytics for each platform build
      for (final result in processedResults) {
        await _buildAnalytics.recordBuildSession(result.buildResult);
      }

      final totalTime = DateTime.now().difference(startTime);
      final success = processedResults.every((r) => r.success);

      final result = MultiPlatformBuildResult(
        buildId: buildId,
        platforms: platforms,
        buildMode: mode,
        platformResults: processedResults,
        distributionResult: distributionResult,
        totalBuildTime: totalTime,
        success: success,
        buildMatrix: buildMatrix,
        environment: environment,
      );

      _emitEvent(
        success ? MultiPlatformBuildEventType.buildCompleted : MultiPlatformBuildEventType.buildFailed,
        details: 'Success: ${processedResults.where((r) => r.success).length}/${platforms.length}, Time: ${totalTime.inSeconds}s'
      );

      return result;

    } catch (e) {
      final totalTime = DateTime.now().difference(startTime);
      _emitEvent(MultiPlatformBuildEventType.buildFailed,
        error: e.toString());

      return MultiPlatformBuildResult(
        buildId: buildId,
        platforms: platforms,
        buildMode: mode,
        platformResults: [],
        totalBuildTime: totalTime,
        success: false,
        buildMatrix: BuildMatrix(platforms: [], buildConfigs: {}),
        environment: environment,
      );
    }
  }

  /// Get platform-specific build status
  Future<PlatformBuildStatus> getPlatformBuildStatus(TargetPlatform platform) async {
    final config = _platformConfigs[platform];
    final strategy = _platformStrategies[platform];

    if (config == null) {
      return PlatformBuildStatus(
        platform: platform,
        isSupported: false,
        isConfigured: false,
        requirementsMet: false,
      );
    }

    final requirementsMet = await _checkPlatformRequirements(platform, config);
    final isConfigured = await _checkPlatformConfiguration(platform, config);

    return PlatformBuildStatus(
      platform: platform,
      isSupported: true,
      isConfigured: isConfigured,
      requirementsMet: requirementsMet,
      configuration: config,
      strategy: strategy,
      availableArchitectures: config.supportedArchitectures,
      recommendedBuildMode: _getRecommendedBuildMode(platform),
    );
  }

  /// Configure platform-specific settings
  Future<void> configurePlatform({
    required TargetPlatform platform,
    required PlatformConfiguration config,
    BuildStrategy? strategy,
  }) async {
    _platformConfigs[platform] = config;

    if (strategy != null) {
      _platformStrategies[platform] = strategy;
    }

    await _savePlatformConfiguration(platform, config);
    _emitEvent(MultiPlatformBuildEventType.platformConfigured,
      details: 'Platform: $platform');
  }

  /// Get build matrix for platforms
  BuildMatrix getBuildMatrix(String projectPath, List<TargetPlatform> platforms, BuildMode mode) {
    return _createBuildMatrix(projectPath, platforms, mode, null);
  }

  /// Optimize build order for platforms
  List<TargetPlatform> optimizeBuildOrder(List<TargetPlatform> platforms) {
    // Sort platforms by build time and dependencies
    final platformMetrics = <TargetPlatform, PlatformBuildMetrics>{};

    for (final platform in platforms) {
      platformMetrics[platform] = _getPlatformBuildMetrics(platform);
    }

    return platforms.toList()
      ..sort((a, b) {
        final metricsA = platformMetrics[a]!;
        final metricsB = platformMetrics[b]!;

        // Sort by build time (fastest first)
        final timeCompare = metricsA.averageBuildTime.compareTo(metricsB.averageBuildTime);
        if (timeCompare != 0) return timeCompare;

        // Then by reliability (most reliable first)
        return metricsB.successRate.compareTo(metricsA.successRate);
      });
  }

  /// Get platform compatibility report
  Future<PlatformCompatibilityReport> getPlatformCompatibilityReport(
    String projectPath,
    List<TargetPlatform> platforms,
  ) async {
    final compatibilityResults = <TargetPlatform, PlatformCompatibilityResult>{};

    for (final platform in platforms) {
      final status = await getPlatformBuildStatus(platform);
      final compatibility = await _assessPlatformCompatibility(projectPath, platform, status);

      compatibilityResults[platform] = compatibility;
    }

    final overallCompatibility = _calculateOverallCompatibility(compatibilityResults);

    return PlatformCompatibilityReport(
      platforms: platforms,
      compatibilityResults: compatibilityResults,
      overallCompatibility: overallCompatibility,
      recommendations: _generateCompatibilityRecommendations(compatibilityResults),
      generatedAt: DateTime.now(),
    );
  }

  /// Export multi-platform build configuration
  Future<String> exportBuildConfiguration() async {
    final config = {
      'platforms': _platformConfigs.map((platform, config) => MapEntry(
        platform.toString(),
        config.toJson(),
      )),
      'environments': _buildEnvironments.map((name, env) => MapEntry(name, env.toJson())),
      'strategies': _platformStrategies.map((platform, strategy) => MapEntry(
        platform.toString(),
        strategy.toJson(),
      )),
      'exportedAt': DateTime.now().toIso8601String(),
    };

    return json.encode(config);
  }

  /// Import multi-platform build configuration
  Future<void> importBuildConfiguration(String jsonConfig) async {
    try {
      final config = json.decode(jsonConfig) as Map<String, dynamic>;

      // Import platform configurations
      final platforms = config['platforms'] as Map<String, dynamic>?;
      if (platforms != null) {
        for (final entry in platforms.entries) {
          final platform = _parseTargetPlatform(entry.key);
          if (platform != null) {
            final platformConfig = PlatformConfiguration.fromJson(entry.value);
            _platformConfigs[platform] = platformConfig;
          }
        }
      }

      // Import environments
      final environments = config['environments'] as Map<String, dynamic>?;
      if (environments != null) {
        for (final entry in environments.entries) {
          final env = BuildEnvironment.fromJson(entry.value);
          _buildEnvironments[env.name] = env;
        }
      }

      // Import strategies
      final strategies = config['strategies'] as Map<String, dynamic>?;
      if (strategies != null) {
        for (final entry in strategies.entries) {
          final platform = _parseTargetPlatform(entry.key);
          if (platform != null) {
            final strategy = BuildStrategy.fromJson(entry.value);
            _platformStrategies[platform] = strategy;
          }
        }
      }

      _emitEvent(MultiPlatformBuildEventType.configurationImported);

    } catch (e) {
      _emitEvent(MultiPlatformBuildEventType.configurationImportFailed, error: e.toString());
      rethrow;
    }
  }

  // Private methods

  Future<void> _loadPlatformConfigurations() async {
    try {
      final configFile = File(_platformsConfigFile);
      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        final config = json.decode(content) as Map<String, dynamic>;

        final platforms = config['platforms'] as Map<String, dynamic>?;
        if (platforms != null) {
          for (final entry in platforms.entries) {
            final platform = _parseTargetPlatform(entry.key);
            if (platform != null) {
              _platformConfigs[platform] = PlatformConfiguration.fromJson(entry.value);
            }
          }
        }
      } else {
        // Initialize with default configurations
        await _initializeDefaultPlatformConfigurations();
      }
    } catch (e) {
      // Use defaults on error
      await _initializeDefaultPlatformConfigurations();
    }
  }

  Future<void> _initializeDefaultPlatformConfigurations() async {
    // Android configuration
    _platformConfigs[TargetPlatform.android] = PlatformConfiguration(
      platform: TargetPlatform.android,
      supportedArchitectures: ['armeabi-v7a', 'arm64-v8a', 'x86', 'x86_64'],
      minSdkVersion: 21,
      targetSdkVersion: 33,
      buildToolsVersion: '33.0.2',
      requiredDependencies: ['flutter', 'android_sdk', 'java'],
      buildCommands: {
        'debug': 'flutter build apk --debug',
        'profile': 'flutter build apk --profile',
        'release': 'flutter build apk --release',
      },
      artifactPatterns: ['build/app/outputs/flutter-apk/*.apk'],
      optimizationFlags: ['--split-per-abi', '--target-platform=android-arm64'],
    );

    // iOS configuration
    _platformConfigs[TargetPlatform.ios] = PlatformConfiguration(
      platform: TargetPlatform.ios,
      supportedArchitectures: ['arm64'],
      minSdkVersion: 12,
      targetSdkVersion: 16,
      buildToolsVersion: '15.0',
      requiredDependencies: ['flutter', 'xcode', 'cocoapods'],
      buildCommands: {
        'debug': 'flutter build ios --debug --no-codesign',
        'profile': 'flutter build ios --profile --no-codesign',
        'release': 'flutter build ios --release --no-codesign',
      },
      artifactPatterns: ['build/ios/iphoneos/*.app'],
      optimizationFlags: ['--target-platform=ios-arm64'],
    );

    // Windows configuration
    _platformConfigs[TargetPlatform.windows] = PlatformConfiguration(
      platform: TargetPlatform.windows,
      supportedArchitectures: ['x64', 'x86'],
      buildToolsVersion: '10.0',
      requiredDependencies: ['flutter', 'visual_studio', 'windows_sdk'],
      buildCommands: {
        'debug': 'flutter build windows --debug',
        'profile': 'flutter build windows --profile',
        'release': 'flutter build windows --release',
      },
      artifactPatterns: ['build/windows/**/*.exe'],
      optimizationFlags: ['--target-platform=windows-x64'],
    );

    // Web configuration
    _platformConfigs[TargetPlatform.web] = PlatformConfiguration(
      platform: TargetPlatform.web,
      supportedArchitectures: ['js'],
      requiredDependencies: ['flutter', 'chrome'],
      buildCommands: {
        'debug': 'flutter build web --debug',
        'profile': 'flutter build web --profile',
        'release': 'flutter build web --release',
      },
      artifactPatterns: ['build/web/**'],
      optimizationFlags: ['--web-renderer=canvaskit'],
    );

    // Linux configuration
    _platformConfigs[TargetPlatform.linux] = PlatformConfiguration(
      platform: TargetPlatform.linux,
      supportedArchitectures: ['x64', 'arm64'],
      requiredDependencies: ['flutter', 'gtk', 'clang'],
      buildCommands: {
        'debug': 'flutter build linux --debug',
        'profile': 'flutter build linux --profile',
        'release': 'flutter build linux --release',
      },
      artifactPatterns: ['build/linux/**/*.so'],
      optimizationFlags: ['--target-platform=linux-x64'],
    );

    // macOS configuration
    _platformConfigs[TargetPlatform.macos] = PlatformConfiguration(
      platform: TargetPlatform.macos,
      supportedArchitectures: ['x64', 'arm64'],
      minSdkVersion: 10,
      targetSdkVersion: 13,
      requiredDependencies: ['flutter', 'xcode'],
      buildCommands: {
        'debug': 'flutter build macos --debug',
        'profile': 'flutter build macos --profile',
        'release': 'flutter build macos --release',
      },
      artifactPatterns: ['build/macos/Build/Products/**/*.app'],
      optimizationFlags: ['--target-platform=darwin-arm64'],
    );
  }

  Future<void> _initializeDefaultEnvironments() async {
    _buildEnvironments['development'] = BuildEnvironment(
      name: 'development',
      description: 'Development build environment',
      variables: {
        'FLUTTER_BUILD_MODE': 'debug',
        'DART_VM_OPTIONS': '--enable-vm-service',
      },
      enabledPlatforms: TargetPlatform.values,
    );

    _buildEnvironments['staging'] = BuildEnvironment(
      name: 'staging',
      description: 'Staging build environment',
      variables: {
        'FLUTTER_BUILD_MODE': 'profile',
        'API_ENDPOINT': 'https://api-staging.example.com',
      },
      enabledPlatforms: [TargetPlatform.android, TargetPlatform.ios, TargetPlatform.web],
    );

    _buildEnvironments['production'] = BuildEnvironment(
      name: 'production',
      description: 'Production build environment',
      variables: {
        'FLUTTER_BUILD_MODE': 'release',
        'API_ENDPOINT': 'https://api.example.com',
      },
      enabledPlatforms: [TargetPlatform.android, TargetPlatform.ios, TargetPlatform.web],
    );
  }

  void _initializePlatformStrategies() {
    // Android strategy
    _platformStrategies[TargetPlatform.android] = BuildStrategy(
      platform: TargetPlatform.android,
      parallelBuilds: true,
      maxConcurrentBuilds: 2,
      incrementalBuilds: true,
      cachingStrategy: CachingStrategy.aggressive,
      optimizationLevel: OptimizationLevel.high,
      customBuildSteps: ['clean', 'assemble', 'bundle'],
    );

    // iOS strategy
    _platformStrategies[TargetPlatform.ios] = BuildStrategy(
      platform: TargetPlatform.ios,
      parallelBuilds: false, // iOS builds are typically sequential
      maxConcurrentBuilds: 1,
      incrementalBuilds: true,
      cachingStrategy: CachingStrategy.moderate,
      optimizationLevel: OptimizationLevel.high,
      customBuildSteps: ['pod install', 'archive', 'export'],
    );

    // Web strategy
    _platformStrategies[TargetPlatform.web] = BuildStrategy(
      platform: TargetPlatform.web,
      parallelBuilds: true,
      maxConcurrentBuilds: 3,
      incrementalBuilds: true,
      cachingStrategy: CachingStrategy.aggressive,
      optimizationLevel: OptimizationLevel.medium,
      customBuildSteps: ['build', 'optimize'],
    );

    // Desktop strategies (Windows, Linux, macOS)
    for (final platform in [TargetPlatform.windows, TargetPlatform.linux, TargetPlatform.macos]) {
      _platformStrategies[platform] = BuildStrategy(
        platform: platform,
        parallelBuilds: true,
        maxConcurrentBuilds: 2,
        incrementalBuilds: true,
        cachingStrategy: CachingStrategy.moderate,
        optimizationLevel: OptimizationLevel.medium,
        customBuildSteps: ['configure', 'build', 'package'],
      );
    }
  }

  Future<void> _validatePlatformsAndEnvironment(List<TargetPlatform> platforms, String? environment) async {
    final errors = <String>[];

    // Validate platforms
    for (final platform in platforms) {
      final status = await getPlatformBuildStatus(platform);
      if (!status.isSupported) {
        errors.add('Platform $platform is not supported');
      } else if (!status.requirementsMet) {
        errors.add('Platform $platform requirements not met');
      }
    }

    // Validate environment
    if (environment != null && !_buildEnvironments.containsKey(environment)) {
      errors.add('Build environment "$environment" not found');
    }

    if (errors.isNotEmpty) {
      throw MultiPlatformBuildException('Validation failed: ${errors.join(", ")}');
    }
  }

  BuildMatrix _createBuildMatrix(
    String projectPath,
    List<TargetPlatform> platforms,
    BuildMode mode,
    Map<String, dynamic>? buildConfig,
  ) {
    final buildConfigs = <TargetPlatform, PlatformBuildConfig>{};

    for (final platform in platforms) {
      final platformConfig = _platformConfigs[platform];
      if (platformConfig != null) {
        buildConfigs[platform] = PlatformBuildConfig(
          platform: platform,
          buildMode: mode,
          architectures: platformConfig.supportedArchitectures,
          buildCommand: platformConfig.buildCommands[mode.toString().split('.').last] ?? '',
          optimizationFlags: platformConfig.optimizationFlags,
          customConfig: buildConfig,
        );
      }
    }

    return BuildMatrix(
      platforms: platforms,
      buildConfigs: buildConfigs,
      buildMode: mode,
      createdAt: DateTime.now(),
    );
  }

  Future<Map<TargetPlatform, BuildEnvironment>> _prepareBuildEnvironments(
    BuildMatrix matrix,
    String? environmentName,
  ) async {
    final environments = <TargetPlatform, BuildEnvironment>{};

    for (final platform in matrix.platforms) {
      if (environmentName != null && _buildEnvironments.containsKey(environmentName)) {
        environments[platform] = _buildEnvironments[environmentName]!;
      } else {
        // Use default environment
        environments[platform] = _buildEnvironments['development']!;
      }
    }

    return environments;
  }

  Future<List<PlatformBuildResult>> _executeParallelPlatformBuilds(
    BuildMatrix matrix,
    Map<TargetPlatform, BuildEnvironment> environments,
    String buildId,
  ) async {
    final results = <PlatformBuildResult>[];
    final semaphore = Semaphore(_maxConcurrentPlatformBuilds);

    final futures = <Future>[];

    for (final platform in matrix.platforms) {
      final future = semaphore.acquire().then((_) async {
        try {
          final result = await _executePlatformBuild(platform, matrix, environments[platform]!, buildId);
          results.add(result);
        } finally {
          semaphore.release();
        }
      });

      futures.add(future);
    }

    await Future.wait(futures);
    return results;
  }

  Future<List<PlatformBuildResult>> _executeSequentialPlatformBuilds(
    BuildMatrix matrix,
    Map<TargetPlatform, BuildEnvironment> environments,
    String buildId,
  ) async {
    final results = <PlatformBuildResult>[];

    for (final platform in matrix.platforms) {
      final result = await _executePlatformBuild(platform, matrix, environments[platform]!, buildId);
      results.add(result);
    }

    return results;
  }

  Future<PlatformBuildResult> _executePlatformBuild(
    TargetPlatform platform,
    BuildMatrix matrix,
    BuildEnvironment environment,
    String buildId,
  ) async {
    final config = matrix.buildConfigs[platform];
    if (config == null) {
      return PlatformBuildResult(
        platform: platform,
        success: false,
        errors: ['No build configuration found for platform'],
        buildTime: Duration.zero,
      );
    }

    final startTime = DateTime.now();

    try {
      // Set environment variables
      final originalEnv = Map<String, String>.from(Platform.environment);
      environment.variables.forEach((key, value) {
        Platform.environment[key] = value;
      });

      // Execute build using BuildOptimizationService
      final targets = [BuildTarget(
        platform: platform,
        architecture: config.architectures.first,
        config: config.customConfig,
      )];

      final buildResult = await _buildOptimization.executeOptimizedBuild(
        projectPath: '', // Would be passed from parent
        targets: targets,
        mode: config.buildMode,
        buildConfig: config.customConfig,
      );

      final buildTime = DateTime.now().difference(startTime);

      // Restore environment
      Platform.environment.clear();
      Platform.environment.addAll(originalEnv);

      return PlatformBuildResult(
        platform: platform,
        success: buildResult.success,
        buildResult: buildResult,
        artifacts: buildResult.artifacts,
        errors: buildResult.errors,
        warnings: buildResult.warnings,
        buildTime: buildTime,
      );

    } catch (e) {
      final buildTime = DateTime.now().difference(startTime);

      // Restore environment
      Platform.environment.clear();
      Platform.environment.addAll(Platform.environment);

      return PlatformBuildResult(
        platform: platform,
        success: false,
        errors: [e.toString()],
        buildTime: buildTime,
      );
    }
  }

  Future<List<PlatformBuildResult>> _processBuildResults(
    List<PlatformBuildResult> results,
    bool optimizeForDistribution,
  ) async {
    if (!optimizeForDistribution) return results;

    // Apply platform-specific optimizations
    final processedResults = <PlatformBuildResult>[];

    for (final result in results) {
      if (result.success && result.buildResult != null) {
        final optimizedResult = await _optimizePlatformResult(result);
        processedResults.add(optimizedResult);
      } else {
        processedResults.add(result);
      }
    }

    return processedResults;
  }

  Future<DistributionResult> _generateDistributionArtifacts(
    List<PlatformBuildResult> results,
    String buildId,
  ) async {
    final distributionArtifacts = <DistributionArtifact>[];

    // Group artifacts by platform
    final platformArtifacts = <TargetPlatform, List<BuildArtifact>>{};
    for (final result in results) {
      if (result.success && result.artifacts.isNotEmpty) {
        platformArtifacts[result.platform] = result.artifacts;
      }
    }

    // Create distribution packages
    for (final entry in platformArtifacts.entries) {
      final platform = entry.key;
      final artifacts = entry.value;

      final distArtifact = DistributionArtifact(
        platform: platform,
        artifacts: artifacts,
        packageName: 'app_${platform}_${buildId}',
        createdAt: DateTime.now(),
        metadata: {
          'buildId': buildId,
          'artifactCount': artifacts.length,
          'totalSize': artifacts.fold<int>(0, (sum, a) => sum + a.size),
        },
      );

      distributionArtifacts.add(distArtifact);
    }

    return DistributionResult(
      artifacts: distributionArtifacts,
      totalPlatforms: platformArtifacts.length,
      totalArtifacts: distributionArtifacts.fold<int>(0, (sum, a) => sum + a.artifacts.length),
      createdAt: DateTime.now(),
    );
  }

  Future<bool> _checkPlatformRequirements(TargetPlatform platform, PlatformConfiguration config) async {
    // Check if required dependencies are available
    for (final dependency in config.requiredDependencies) {
      if (!await _isDependencyAvailable(dependency)) {
        return false;
      }
    }

    // Check platform-specific requirements
    switch (platform) {
      case TargetPlatform.android:
        return await _checkAndroidRequirements(config);
      case TargetPlatform.ios:
        return await _checkIOSRequirements(config);
      case TargetPlatform.windows:
        return await _checkWindowsRequirements(config);
      case TargetPlatform.macos:
        return await _checkMacOSRequirements(config);
      case TargetPlatform.linux:
        return await _checkLinuxRequirements(config);
      case TargetPlatform.web:
        return await _checkWebRequirements(config);
      default:
        return false;
    }
  }

  Future<bool> _checkPlatformConfiguration(TargetPlatform platform, PlatformConfiguration config) async {
    // Check if platform-specific configuration files exist and are valid
    switch (platform) {
      case TargetPlatform.android:
        return await _checkAndroidConfiguration(config);
      case TargetPlatform.ios:
        return await _checkIOSConfiguration(config);
      default:
        return true; // Other platforms may not need specific config validation
    }
  }

  Future<bool> _isDependencyAvailable(String dependency) async {
    // Check if dependency is available in PATH or installed
    try {
      switch (dependency) {
        case 'flutter':
          final result = await Process.run('flutter', ['--version']);
          return result.exitCode == 0;
        case 'java':
          final result = await Process.run('java', ['-version']);
          return result.exitCode == 0;
        case 'android_sdk':
          return Platform.environment['ANDROID_HOME'] != null ||
                 Platform.environment['ANDROID_SDK_ROOT'] != null;
        case 'xcode':
          if (Platform.isMacOS) {
            final result = await Process.run('xcodebuild', ['-version']);
            return result.exitCode == 0;
          }
          return false;
        case 'visual_studio':
          if (Platform.isWindows) {
            // Check for common VS installation paths
            return true; // Simplified check
          }
          return false;
        default:
          return true; // Assume available for unknown dependencies
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkAndroidRequirements(PlatformConfiguration config) async {
    return await _isDependencyAvailable('flutter') &&
           await _isDependencyAvailable('java') &&
           await _isDependencyAvailable('android_sdk');
  }

  Future<bool> _checkIOSRequirements(PlatformConfiguration config) async {
    return Platform.isMacOS &&
           await _isDependencyAvailable('flutter') &&
           await _isDependencyAvailable('xcode');
  }

  Future<bool> _checkWindowsRequirements(PlatformConfiguration config) async {
    return Platform.isWindows &&
           await _isDependencyAvailable('flutter') &&
           await _isDependencyAvailable('visual_studio');
  }

  Future<bool> _checkMacOSRequirements(PlatformConfiguration config) async {
    return Platform.isMacOS &&
           await _isDependencyAvailable('flutter') &&
           await _isDependencyAvailable('xcode');
  }

  Future<bool> _checkLinuxRequirements(PlatformConfiguration config) async {
    return Platform.isLinux &&
           await _isDependencyAvailable('flutter');
  }

  Future<bool> _checkWebRequirements(PlatformConfiguration config) async {
    return await _isDependencyAvailable('flutter');
  }

  Future<bool> _checkAndroidConfiguration(PlatformConfiguration config) async {
    // Check for Android configuration files
    final androidDir = Directory('android');
    if (!await androidDir.exists()) return false;

    final gradleFile = File('android/app/build.gradle');
    return await gradleFile.exists();
  }

  Future<bool> _checkIOSConfiguration(PlatformConfiguration config) async {
    if (!Platform.isMacOS) return false;

    final iosDir = Directory('ios');
    if (!await iosDir.exists()) return false;

    final projectFile = File('ios/Runner.xcodeproj/project.pbxproj');
    return await projectFile.exists();
  }

  BuildMode _getRecommendedBuildMode(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android:
      case TargetPlatform.ios:
        return BuildMode.release;
      case TargetPlatform.web:
        return BuildMode.release;
      default:
        return BuildMode.debug;
    }
  }

  PlatformBuildMetrics _getPlatformBuildMetrics(TargetPlatform platform) {
    // Return cached or default metrics
    // In a real implementation, this would track historical build data
    return PlatformBuildMetrics(
      platform: platform,
      averageBuildTime: const Duration(minutes: 2),
      successRate: 0.9,
      lastBuildTime: DateTime.now().subtract(const Duration(hours: 1)),
    );
  }

  Future<PlatformCompatibilityResult> _assessPlatformCompatibility(
    String projectPath,
    TargetPlatform platform,
    PlatformBuildStatus status,
  ) async {
    final issues = <CompatibilityIssue>[];
    final compatibility = CompatibilityLevel.full;

    if (!status.isSupported) {
      issues.add(CompatibilityIssue(
        type: CompatibilityIssueType.notSupported,
        severity: CompatibilitySeverity.blocking,
        description: 'Platform is not supported by the current Flutter version',
      ));
      return PlatformCompatibilityResult(
        platform: platform,
        compatibility: CompatibilityLevel.none,
        issues: issues,
      );
    }

    if (!status.requirementsMet) {
      issues.add(CompatibilityIssue(
        type: CompatibilityIssueType.missingRequirements,
        severity: CompatibilitySeverity.blocking,
        description: 'Platform requirements are not met',
      ));
      return PlatformCompatibilityResult(
        platform: platform,
        compatibility: CompatibilityLevel.none,
        issues: issues,
      );
    }

    // Check project compatibility
    final projectIssues = await _checkProjectCompatibility(projectPath, platform);
    issues.addAll(projectIssues);

    return PlatformCompatibilityResult(
      platform: platform,
      compatibility: issues.any((issue) => issue.severity == CompatibilitySeverity.blocking)
          ? CompatibilityLevel.none
          : issues.any((issue) => issue.severity == CompatibilitySeverity.major)
              ? CompatibilityLevel.partial
              : CompatibilityLevel.full,
      issues: issues,
    );
  }

  Future<List<CompatibilityIssue>> _checkProjectCompatibility(String projectPath, TargetPlatform platform) async {
    final issues = <CompatibilityIssue>[];

    // Check pubspec.yaml for platform-specific configurations
    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    if (await pubspecFile.exists()) {
      final content = await pubspecFile.readAsString();

      // Check for platform-specific issues
      switch (platform) {
        case TargetPlatform.web:
          if (!content.contains('flutter_web')) {
            issues.add(CompatibilityIssue(
              type: CompatibilityIssueType.configurationIssue,
              severity: CompatibilitySeverity.minor,
              description: 'Consider adding flutter_web specific configuration',
            ));
          }
          break;
        case TargetPlatform.windows:
        case TargetPlatform.linux:
        case TargetPlatform.macos:
          if (!content.contains('desktop')) {
            issues.add(CompatibilityIssue(
              type: CompatibilityIssueType.configurationIssue,
              severity: CompatibilitySeverity.minor,
              description: 'Consider enabling desktop support in pubspec.yaml',
            ));
          }
          break;
        default:
          break;
      }
    }

    return issues;
  }

  CompatibilityLevel _calculateOverallCompatibility(Map<TargetPlatform, PlatformCompatibilityResult> results) {
    if (results.isEmpty) return CompatibilityLevel.none;

    final hasFullCompatibility = results.values.any((r) => r.compatibility == CompatibilityLevel.full);
    final hasPartialCompatibility = results.values.any((r) => r.compatibility == CompatibilityLevel.partial);

    if (hasFullCompatibility) return CompatibilityLevel.full;
    if (hasPartialCompatibility) return CompatibilityLevel.partial;
    return CompatibilityLevel.none;
  }

  List<String> _generateCompatibilityRecommendations(Map<TargetPlatform, PlatformCompatibilityResult> results) {
    final recommendations = <String>[];

    for (final entry in results.entries) {
      final platform = entry.key;
      final result = entry.value;

      for (final issue in result.issues) {
        switch (issue.type) {
          case CompatibilityIssueType.missingRequirements:
            recommendations.add('Install required dependencies for $platform platform');
            break;
          case CompatibilityIssueType.configurationIssue:
            recommendations.add('Update configuration for $platform platform: ${issue.description}');
            break;
          case CompatibilityIssueType.notSupported:
            recommendations.add('Consider updating Flutter version for $platform support');
            break;
          default:
            recommendations.add('Address compatibility issue for $platform: ${issue.description}');
        }
      }
    }

    return recommendations;
  }

  Future<void> _savePlatformConfiguration(TargetPlatform platform, PlatformConfiguration config) async {
    // Save to file for persistence
    final configData = {
      'platforms': {
        platform.toString(): config.toJson(),
      },
    };

    final configFile = File(_platformsConfigFile);
    await configFile.writeAsString(json.encode(configData));
  }

  TargetPlatform? _parseTargetPlatform(String platformString) {
    try {
      return TargetPlatform.values.firstWhere(
        (p) => p.toString() == platformString,
      );
    } catch (e) {
      return null;
    }
  }

  Future<PlatformBuildResult> _optimizePlatformResult(PlatformBuildResult result) async {
    if (!result.success || result.buildResult == null) return result;

    // Apply platform-specific optimizations
    final optimizedArtifacts = <BuildArtifact>[];

    for (final artifact in result.artifacts) {
      final optimizedArtifact = await _optimizeArtifact(artifact, result.platform);
      optimizedArtifacts.add(optimizedArtifact);
    }

    return PlatformBuildResult(
      platform: result.platform,
      success: result.success,
      buildResult: result.buildResult,
      artifacts: optimizedArtifacts,
      errors: result.errors,
      warnings: result.warnings,
      buildTime: result.buildTime,
    );
  }

  Future<BuildArtifact> _optimizeArtifact(BuildArtifact artifact, TargetPlatform platform) async {
    // Apply platform-specific optimizations (compression, signing, etc.)
    // For now, return the original artifact
    return artifact;
  }

  void _emitEvent(MultiPlatformBuildEventType type, {
    String? details,
    String? error,
  }) {
    final event = MultiPlatformBuildEvent(
      type: type,
      timestamp: DateTime.now(),
      details: details,
      error: error,
    );

    _eventController.add(event);
  }

  void dispose() {
    _eventController.close();
  }
}

/// Supporting data classes

class PlatformConfiguration {
  final TargetPlatform platform;
  final List<String> supportedArchitectures;
  final int? minSdkVersion;
  final int? targetSdkVersion;
  final String? buildToolsVersion;
  final List<String> requiredDependencies;
  final Map<String, String> buildCommands;
  final List<String> artifactPatterns;
  final List<String> optimizationFlags;

  PlatformConfiguration({
    required this.platform,
    required this.supportedArchitectures,
    this.minSdkVersion,
    this.targetSdkVersion,
    this.buildToolsVersion,
    required this.requiredDependencies,
    required this.buildCommands,
    required this.artifactPatterns,
    required this.optimizationFlags,
  });

  Map<String, dynamic> toJson() => {
    'platform': platform.toString(),
    'supportedArchitectures': supportedArchitectures,
    'minSdkVersion': minSdkVersion,
    'targetSdkVersion': targetSdkVersion,
    'buildToolsVersion': buildToolsVersion,
    'requiredDependencies': requiredDependencies,
    'buildCommands': buildCommands,
    'artifactPatterns': artifactPatterns,
    'optimizationFlags': optimizationFlags,
  };

  factory PlatformConfiguration.fromJson(Map<String, dynamic> json) {
    return PlatformConfiguration(
      platform: TargetPlatform.values.firstWhere(
        (p) => p.toString() == json['platform'],
      ),
      supportedArchitectures: List<String>.from(json['supportedArchitectures']),
      minSdkVersion: json['minSdkVersion'],
      targetSdkVersion: json['targetSdkVersion'],
      buildToolsVersion: json['buildToolsVersion'],
      requiredDependencies: List<String>.from(json['requiredDependencies']),
      buildCommands: Map<String, String>.from(json['buildCommands']),
      artifactPatterns: List<String>.from(json['artifactPatterns']),
      optimizationFlags: List<String>.from(json['optimizationFlags']),
    );
  }
}

class BuildEnvironment {
  final String name;
  final String description;
  final Map<String, String> variables;
  final List<TargetPlatform> enabledPlatforms;

  BuildEnvironment({
    required this.name,
    required this.description,
    required this.variables,
    required this.enabledPlatforms,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'variables': variables,
    'enabledPlatforms': enabledPlatforms.map((p) => p.toString()).toList(),
  };

  factory BuildEnvironment.fromJson(Map<String, dynamic> json) {
    return BuildEnvironment(
      name: json['name'],
      description: json['description'],
      variables: Map<String, String>.from(json['variables']),
      enabledPlatforms: (json['enabledPlatforms'] as List).map((p) =>
        TargetPlatform.values.firstWhere((tp) => tp.toString() == p),
      ).toList(),
    );
  }
}

class BuildStrategy {
  final TargetPlatform platform;
  final bool parallelBuilds;
  final int maxConcurrentBuilds;
  final bool incrementalBuilds;
  final CachingStrategy cachingStrategy;
  final OptimizationLevel optimizationLevel;
  final List<String> customBuildSteps;

  BuildStrategy({
    required this.platform,
    required this.parallelBuilds,
    required this.maxConcurrentBuilds,
    required this.incrementalBuilds,
    required this.cachingStrategy,
    required this.optimizationLevel,
    required this.customBuildSteps,
  });

  Map<String, dynamic> toJson() => {
    'platform': platform.toString(),
    'parallelBuilds': parallelBuilds,
    'maxConcurrentBuilds': maxConcurrentBuilds,
    'incrementalBuilds': incrementalBuilds,
    'cachingStrategy': cachingStrategy.toString(),
    'optimizationLevel': optimizationLevel.toString(),
    'customBuildSteps': customBuildSteps,
  };

  factory BuildStrategy.fromJson(Map<String, dynamic> json) {
    return BuildStrategy(
      platform: TargetPlatform.values.firstWhere(
        (p) => p.toString() == json['platform'],
      ),
      parallelBuilds: json['parallelBuilds'],
      maxConcurrentBuilds: json['maxConcurrentBuilds'],
      incrementalBuilds: json['incrementalBuilds'],
      cachingStrategy: CachingStrategy.values.firstWhere(
        (c) => c.toString() == json['cachingStrategy'],
      ),
      optimizationLevel: OptimizationLevel.values.firstWhere(
        (o) => o.toString() == json['optimizationLevel'],
      ),
      customBuildSteps: List<String>.from(json['customBuildSteps']),
    );
  }
}

class BuildMatrix {
  final List<TargetPlatform> platforms;
  final Map<TargetPlatform, PlatformBuildConfig> buildConfigs;
  final BuildMode buildMode;
  final DateTime createdAt;

  BuildMatrix({
    required this.platforms,
    required this.buildConfigs,
    required this.buildMode,
    required this.createdAt,
  });
}

class PlatformBuildConfig {
  final TargetPlatform platform;
  final BuildMode buildMode;
  final List<String> architectures;
  final String buildCommand;
  final List<String> optimizationFlags;
  final Map<String, dynamic>? customConfig;

  PlatformBuildConfig({
    required this.platform,
    required this.buildMode,
    required this.architectures,
    required this.buildCommand,
    required this.optimizationFlags,
    this.customConfig,
  });
}

class MultiPlatformBuildResult {
  final String buildId;
  final List<TargetPlatform> platforms;
  final BuildMode buildMode;
  final List<PlatformBuildResult> platformResults;
  final DistributionResult? distributionResult;
  final Duration totalBuildTime;
  final bool success;
  final BuildMatrix buildMatrix;
  final String? environment;

  MultiPlatformBuildResult({
    required this.buildId,
    required this.platforms,
    required this.buildMode,
    required this.platformResults,
    this.distributionResult,
    required this.totalBuildTime,
    required this.success,
    required this.buildMatrix,
    this.environment,
  });
}

class PlatformBuildResult {
  final TargetPlatform platform;
  final bool success;
  final BuildResult? buildResult;
  final List<BuildArtifact> artifacts;
  final List<String> errors;
  final List<String> warnings;
  final Duration buildTime;

  PlatformBuildResult({
    required this.platform,
    required this.success,
    this.buildResult,
    this.artifacts = const [],
    this.errors = const [],
    this.warnings = const [],
    required this.buildTime,
  });
}

class DistributionResult {
  final List<DistributionArtifact> artifacts;
  final int totalPlatforms;
  final int totalArtifacts;
  final DateTime createdAt;

  DistributionResult({
    required this.artifacts,
    required this.totalPlatforms,
    required this.totalArtifacts,
    required this.createdAt,
  });
}

class DistributionArtifact {
  final TargetPlatform platform;
  final List<BuildArtifact> artifacts;
  final String packageName;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  DistributionArtifact({
    required this.platform,
    required this.artifacts,
    required this.packageName,
    required this.createdAt,
    required this.metadata,
  });
}

class PlatformBuildStatus {
  final TargetPlatform platform;
  final bool isSupported;
  final bool isConfigured;
  final bool requirementsMet;
  final PlatformConfiguration? configuration;
  final BuildStrategy? strategy;
  final List<String> availableArchitectures;
  final BuildMode recommendedBuildMode;

  PlatformBuildStatus({
    required this.platform,
    required this.isSupported,
    required this.isConfigured,
    required this.requirementsMet,
    this.configuration,
    this.strategy,
    this.availableArchitectures = const [],
    this.recommendedBuildMode = BuildMode.debug,
  });
}

class PlatformCompatibilityReport {
  final List<TargetPlatform> platforms;
  final Map<TargetPlatform, PlatformCompatibilityResult> compatibilityResults;
  final CompatibilityLevel overallCompatibility;
  final List<String> recommendations;
  final DateTime generatedAt;

  PlatformCompatibilityReport({
    required this.platforms,
    required this.compatibilityResults,
    required this.overallCompatibility,
    required this.recommendations,
    required this.generatedAt,
  });
}

class PlatformCompatibilityResult {
  final TargetPlatform platform;
  final CompatibilityLevel compatibility;
  final List<CompatibilityIssue> issues;

  PlatformCompatibilityResult({
    required this.platform,
    required this.compatibility,
    required this.issues,
  });
}

class CompatibilityIssue {
  final CompatibilityIssueType type;
  final CompatibilitySeverity severity;
  final String description;

  CompatibilityIssue({
    required this.type,
    required this.severity,
    required this.description,
  });
}

class PlatformBuildMetrics {
  final TargetPlatform platform;
  final Duration averageBuildTime;
  final double successRate;
  final DateTime lastBuildTime;

  PlatformBuildMetrics({
    required this.platform,
    required this.averageBuildTime,
    required this.successRate,
    required this.lastBuildTime,
  });
}

/// Enums

enum CachingStrategy {
  none,
  conservative,
  moderate,
  aggressive,
}

enum OptimizationLevel {
  none,
  low,
  medium,
  high,
  maximum,
}

enum CompatibilityLevel {
  none,
  partial,
  full,
}

enum CompatibilityIssueType {
  notSupported,
  missingRequirements,
  configurationIssue,
  versionIncompatibility,
}

enum CompatibilitySeverity {
  minor,
  major,
  blocking,
}

enum MultiPlatformBuildEventType {
  serviceInitialized,
  initializationFailed,
  buildStarted,
  buildCompleted,
  buildFailed,
  platformConfigured,
  configurationImported,
  configurationImportFailed,
}

/// Event classes

class MultiPlatformBuildEvent {
  final MultiPlatformBuildEventType type;
  final DateTime timestamp;
  final String? details;
  final String? error;

  MultiPlatformBuildEvent({
    required this.type,
    required this.timestamp,
    this.details,
    this.error,
  });
}

/// Exception class

class MultiPlatformBuildException implements Exception {
  final String message;

  MultiPlatformBuildException(this.message);

  @override
  String toString() => 'MultiPlatformBuildException: $message';
}
