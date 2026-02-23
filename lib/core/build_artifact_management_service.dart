import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'build_optimization_service.dart';

/// Build Artifact Management Service
/// Provides comprehensive management of build artifacts including storage, versioning, cleanup, and distribution
class BuildArtifactManagementService {
  static final BuildArtifactManagementService _instance = BuildArtifactManagementService._internal();
  factory BuildArtifactManagementService() => _instance;
  BuildArtifactManagementService._internal();

  final BuildOptimizationService _buildOptimization = BuildOptimizationService();
  final StreamController<ArtifactEvent> _artifactEventController = StreamController.broadcast();

  Stream<ArtifactEvent> get artifactEvents => _artifactEventController.stream;

  // Artifact storage
  final Map<String, StoredArtifact> _storedArtifacts = {};
  final Map<String, ArtifactVersion> _artifactVersions = {};
  final Map<String, ArtifactCollection> _artifactCollections = {};

  // Cleanup policies
  final Map<String, CleanupPolicy> _cleanupPolicies = {};

  // Distribution channels
  final Map<String, DistributionChannel> _distributionChannels = {};

  bool _isInitialized = false;

  // Configuration
  static const String _artifactsDirectory = '.build_artifacts';
  static const String _metadataFile = 'artifacts_metadata.json';
  static const int _maxStoredArtifacts = 10000;
  static const Duration _cleanupCheckInterval = Duration(hours: 6);

  Timer? _cleanupTimer;

  /// Initialize artifact management service
  Future<void> initialize({
    Map<String, CleanupPolicy>? cleanupPolicies,
    Map<String, DistributionChannel>? distributionChannels,
  }) async {
    if (_isInitialized) return;

    try {
      await _initializeArtifactsDirectory();
      await _loadArtifactMetadata();

      // Initialize cleanup policies
      if (cleanupPolicies != null) {
        _cleanupPolicies.addAll(cleanupPolicies);
      } else {
        await _initializeDefaultCleanupPolicies();
      }

      // Initialize distribution channels
      if (distributionChannels != null) {
        _distributionChannels.addAll(distributionChannels);
      } else {
        await _initializeDefaultDistributionChannels();
      }

      // Start cleanup scheduler
      _startCleanupScheduler();

      _isInitialized = true;
      _emitArtifactEvent(ArtifactEventType.serviceInitialized);

    } catch (e) {
      _emitArtifactEvent(ArtifactEventType.initializationFailed, error: e.toString());
      rethrow;
    }
  }

  /// Store build artifacts
  Future<ArtifactStorageResult> storeArtifacts({
    required String buildId,
    required List<BuildArtifact> artifacts,
    required TargetPlatform platform,
    String? version,
    String? branch,
    Map<String, String>? metadata,
    StorageStrategy strategy = StorageStrategy.standard,
  }) async {
    _emitArtifactEvent(ArtifactEventType.storageStarted, details: 'Build: $buildId, Artifacts: ${artifacts.length}');

    try {
      final artifactId = 'artifact_${buildId}_${DateTime.now().millisecondsSinceEpoch}';
      final storedArtifacts = <StoredArtifact>[];

      // Process each artifact
      for (final artifact in artifacts) {
        final storedArtifact = await _storeSingleArtifact(
          artifact,
          artifactId,
          platform,
          strategy,
        );
        storedArtifacts.add(storedArtifact);
      }

      // Create artifact collection
      final collection = ArtifactCollection(
        collectionId: artifactId,
        buildId: buildId,
        platform: platform,
        artifacts: storedArtifacts,
        version: version,
        branch: branch,
        createdAt: DateTime.now(),
        metadata: metadata,
        totalSize: storedArtifacts.fold<int>(0, (sum, a) => sum + a.size),
      );

      _artifactCollections[artifactId] = collection;

      // Update versions
      if (version != null) {
        await _updateArtifactVersion(collection);
      }

      // Apply cleanup policies
      await _applyCleanupPolicies();

      await _saveArtifactMetadata();

      final result = ArtifactStorageResult(
        success: true,
        artifactId: artifactId,
        storedArtifacts: storedArtifacts,
        totalSize: collection.totalSize,
        collection: collection,
      );

      _emitArtifactEvent(ArtifactEventType.storageCompleted,
        details: 'ID: $artifactId, Size: ${collection.totalSize ~/ 1024}KB');

      return result;

    } catch (e) {
      _emitArtifactEvent(ArtifactEventType.storageFailed, error: e.toString());
      return ArtifactStorageResult(
        success: false,
        artifactId: '',
        storedArtifacts: [],
        totalSize: 0,
        error: e.toString(),
      );
    }
  }

  /// Retrieve stored artifacts
  Future<ArtifactRetrievalResult> retrieveArtifacts({
    String? artifactId,
    String? buildId,
    String? version,
    TargetPlatform? platform,
    RetrievalStrategy strategy = RetrievalStrategy.latest,
  }) async {
    try {
      List<StoredArtifact> artifacts = [];

      if (artifactId != null) {
        // Retrieve specific collection
        final collection = _artifactCollections[artifactId];
        if (collection != null) {
          artifacts = collection.artifacts;
        }
      } else {
        // Find collections matching criteria
        final matchingCollections = _findArtifactCollections(
          buildId: buildId,
          version: version,
          platform: platform,
          strategy: strategy,
        );

        if (matchingCollections.isNotEmpty) {
          final collection = matchingCollections.first;
          artifacts = collection.artifacts;
        }
      }

      // Verify artifact integrity
      final integrityResults = await _verifyArtifactIntegrity(artifacts);

      final result = ArtifactRetrievalResult(
        success: artifacts.isNotEmpty,
        artifacts: artifacts,
        integrityVerified: integrityResults.every((r) => r.verified),
        integrityResults: integrityResults,
      );

      _emitArtifactEvent(ArtifactEventType.retrievalCompleted,
        details: 'Retrieved: ${artifacts.length} artifacts');

      return result;

    } catch (e) {
      _emitArtifactEvent(ArtifactEventType.retrievalFailed, error: e.toString());
      return ArtifactRetrievalResult(
        success: false,
        artifacts: [],
        integrityVerified: false,
        integrityResults: [],
        error: e.toString(),
      );
    }
  }

  /// Distribute artifacts to channels
  Future<ArtifactDistributionResult> distributeArtifacts({
    required String artifactId,
    required List<String> channels,
    DistributionMode mode = DistributionMode.automatic,
    Map<String, dynamic>? distributionConfig,
  }) async {
    _emitArtifactEvent(ArtifactEventType.distributionStarted,
      details: 'Artifact: $artifactId, Channels: ${channels.length}');

    try {
      final collection = _artifactCollections[artifactId];
      if (collection == null) {
        throw ArtifactException('Artifact collection not found: $artifactId');
      }

      final distributionResults = <ChannelDistributionResult>[];

      for (final channelName in channels) {
        final channel = _distributionChannels[channelName];
        if (channel == null) continue;

        final result = await _distributeToChannel(collection, channel, mode, distributionConfig);
        distributionResults.add(result);
      }

      final success = distributionResults.every((r) => r.success);

      final result = ArtifactDistributionResult(
        success: success,
        artifactId: artifactId,
        distributionResults: distributionResults,
        distributedChannels: distributionResults.where((r) => r.success).length,
      );

      _emitArtifactEvent(
        success ? ArtifactEventType.distributionCompleted : ArtifactEventType.distributionFailed,
        details: 'Distributed to ${result.distributedChannels} channels'
      );

      return result;

    } catch (e) {
      _emitArtifactEvent(ArtifactEventType.distributionFailed, error: e.toString());
      return ArtifactDistributionResult(
        success: false,
        artifactId: artifactId,
        distributionResults: [],
        distributedChannels: 0,
        error: e.toString(),
      );
    }
  }

  /// Clean up artifacts based on policies
  Future<ArtifactCleanupResult> cleanupArtifacts({
    CleanupStrategy strategy = CleanupStrategy.policyBased,
    DateTime? beforeDate,
    int? maxAgeDays,
    int? maxTotalSize,
    bool dryRun = false,
  }) async {
    _emitArtifactEvent(ArtifactEventType.cleanupStarted,
      details: 'Strategy: $strategy, Dry run: $dryRun');

    try {
      final cleanupPlan = await _planArtifactCleanup(
        strategy: strategy,
        beforeDate: beforeDate,
        maxAgeDays: maxAgeDays,
        maxTotalSize: maxTotalSize,
      );

      if (dryRun) {
        return ArtifactCleanupResult(
          success: true,
          dryRun: true,
          plannedRemovals: cleanupPlan.artifactsToRemove.length,
          spaceToFree: cleanupPlan.totalSizeToFree,
          artifactsToRemove: cleanupPlan.artifactsToRemove,
        );
      }

      // Execute cleanup
      int removedCount = 0;
      int freedSpace = 0;

      for (final artifactId in cleanupPlan.artifactsToRemove) {
        final collection = _artifactCollections[artifactId];
        if (collection != null) {
          for (final artifact in collection.artifacts) {
            try {
              final file = File(artifact.storagePath);
              if (await file.exists()) {
                freedSpace += await file.length();
                await file.delete();
              }
              removedCount++;
            } catch (e) {
              // Continue with other artifacts
            }
          }

          _artifactCollections.remove(artifactId);
        }
      }

      await _saveArtifactMetadata();

      final result = ArtifactCleanupResult(
        success: true,
        dryRun: false,
        removedArtifacts: removedCount,
        freedSpace: freedSpace,
        artifactsToRemove: cleanupPlan.artifactsToRemove,
      );

      _emitArtifactEvent(ArtifactEventType.cleanupCompleted,
        details: 'Removed: $removedCount artifacts, Freed: ${freedSpace ~/ 1024}KB');

      return result;

    } catch (e) {
      _emitArtifactEvent(ArtifactEventType.cleanupFailed, error: e.toString());
      return ArtifactCleanupResult(
        success: false,
        dryRun: dryRun,
        removedArtifacts: 0,
        freedSpace: 0,
        artifactsToRemove: [],
        error: e.toString(),
      );
    }
  }

  /// Get artifact statistics
  Future<ArtifactStatistics> getArtifactStatistics({
    DateTime? startDate,
    DateTime? endDate,
    TargetPlatform? platform,
  }) async {
    final collections = _artifactCollections.values.where((collection) {
      if (startDate != null && collection.createdAt.isBefore(startDate)) return false;
      if (endDate != null && collection.createdAt.isAfter(endDate)) return false;
      if (platform != null && collection.platform != platform) return false;
      return true;
    }).toList();

    final totalCollections = collections.length;
    final totalArtifacts = collections.fold<int>(0, (sum, c) => sum + c.artifacts.length);
    final totalSize = collections.fold<int>(0, (sum, c) => sum + c.totalSize);

    final platformDistribution = <TargetPlatform, int>{};
    for (final collection in collections) {
      platformDistribution[collection.platform] = (platformDistribution[collection.platform] ?? 0) + 1;
    }

    final sizeDistribution = _calculateSizeDistribution(collections);
    final ageDistribution = _calculateAgeDistribution(collections);

    return ArtifactStatistics(
      totalCollections: totalCollections,
      totalArtifacts: totalArtifacts,
      totalSizeBytes: totalSize,
      averageCollectionSize: totalCollections > 0 ? totalSize / totalCollections : 0,
      platformDistribution: platformDistribution,
      sizeDistribution: sizeDistribution,
      ageDistribution: ageDistribution,
      storageEfficiency: _calculateStorageEfficiency(collections),
    );
  }

  /// Export artifact management report
  Future<String> exportArtifactReport({
    DateTime? startDate,
    DateTime? endDate,
    bool includeStatistics = true,
    bool includeCleanupPlan = true,
    bool includeDistributionStatus = true,
  }) async {
    final report = StringBuffer();
    report.writeln('Artifact Management Report');
    report.writeln('Generated: ${DateTime.now()}');
    report.writeln('=' * 50);

    if (includeStatistics) {
      report.writeln('\nARTIFACT STATISTICS:');
      final stats = await getArtifactStatistics(
        startDate: startDate,
        endDate: endDate,
      );
      report.writeln(stats.toString());
      report.writeln();
    }

    if (includeCleanupPlan) {
      report.writeln('CLEANUP PLAN:');
      final cleanupPlan = await cleanupArtifacts(dryRun: true);
      report.writeln('Planned removals: ${cleanupPlan.plannedRemovals}');
      report.writeln('Space to free: ${cleanupPlan.spaceToFree ~/ 1024}KB');
      report.writeln();
    }

    if (includeDistributionStatus) {
      report.writeln('DISTRIBUTION STATUS:');
      for (final entry in _distributionChannels.entries) {
        final channel = entry.value;
        report.writeln('• ${channel.name}: ${channel.status}');
      }
    }

    return report.toString();
  }

  // Private methods

  Future<void> _initializeArtifactsDirectory() async {
    final dir = Directory(_artifactsDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Create subdirectories for organization
    for (final platform in TargetPlatform.values) {
      final platformDir = Directory(path.join(_artifactsDirectory, platform.toString()));
      if (!await platformDir.exists()) {
        await platformDir.create();
      }
    }
  }

  Future<void> _loadArtifactMetadata() async {
    final metadataFile = File(path.join(_artifactsDirectory, _metadataFile));
    if (!await metadataFile.exists()) return;

    try {
      final content = await metadataFile.readAsString();
      final metadata = json.decode(content) as Map<String, dynamic>;

      // Load stored artifacts
      final storedArtifacts = metadata['storedArtifacts'] as Map<String, dynamic>?;
      if (storedArtifacts != null) {
        for (final entry in storedArtifacts.entries) {
          _storedArtifacts[entry.key] = StoredArtifact.fromJson(entry.value);
        }
      }

      // Load artifact collections
      final collections = metadata['collections'] as Map<String, dynamic>?;
      if (collections != null) {
        for (final entry in collections.entries) {
          _artifactCollections[entry.key] = ArtifactCollection.fromJson(entry.value);
        }
      }

    } catch (e) {
      // Ignore metadata loading errors
    }
  }

  Future<void> _initializeDefaultCleanupPolicies() async {
    _cleanupPolicies['standard'] = CleanupPolicy(
      name: 'standard',
      maxAge: const Duration(days: 30),
      maxTotalSize: 5 * 1024 * 1024 * 1024, // 5GB
      keepVersions: 5,
      excludePatterns: ['latest', 'stable'],
      enabled: true,
    );

    _cleanupPolicies['aggressive'] = CleanupPolicy(
      name: 'aggressive',
      maxAge: const Duration(days: 7),
      maxTotalSize: 1 * 1024 * 1024 * 1024, // 1GB
      keepVersions: 2,
      excludePatterns: ['latest'],
      enabled: false,
    );
  }

  Future<void> _initializeDefaultDistributionChannels() async {
    _distributionChannels['internal'] = DistributionChannel(
      name: 'internal',
      type: DistributionType.internal,
      endpoint: 'http://artifacts.internal.company.com',
      credentials: {}, // Would be populated securely
      status: ChannelStatus.active,
    );

    _distributionChannels['staging'] = DistributionChannel(
      name: 'staging',
      type: DistributionType.staging,
      endpoint: 'https://artifacts-staging.company.com',
      credentials: {}, // Would be populated securely
      status: ChannelStatus.active,
    );

    _distributionChannels['production'] = DistributionChannel(
      name: 'production',
      type: DistributionType.production,
      endpoint: 'https://artifacts.company.com',
      credentials: {}, // Would be populated securely
      status: ChannelStatus.active,
    );
  }

  void _startCleanupScheduler() {
    _cleanupTimer = Timer.periodic(_cleanupCheckInterval, (_) async {
      await _applyCleanupPolicies();
    });
  }

  Future<StoredArtifact> _storeSingleArtifact(
    BuildArtifact artifact,
    String collectionId,
    TargetPlatform platform,
    StorageStrategy strategy,
  ) async {
    // Determine storage path
    final platformDir = path.join(_artifactsDirectory, platform.toString());
    final fileName = '${artifact.target.platform}_${artifact.target.architecture}_${path.basename(artifact.path)}';
    final storagePath = path.join(platformDir, collectionId, fileName);

    // Ensure directory exists
    final storageDir = Directory(path.dirname(storagePath));
    if (!await storageDir.exists()) {
      await storageDir.create(recursive: true);
    }

    // Copy or move artifact
    final sourceFile = File(artifact.path);
    final targetFile = File(storagePath);

    if (strategy == StorageStrategy.move) {
      await sourceFile.rename(storagePath);
    } else {
      await sourceFile.copy(storagePath);
    }

    // Calculate checksum
    final bytes = await targetFile.readAsBytes();
    final checksum = sha256.convert(bytes).toString();

    // Create stored artifact
    final storedArtifact = StoredArtifact(
      artifactId: '${collectionId}_${DateTime.now().millisecondsSinceEpoch}',
      originalPath: artifact.path,
      storagePath: storagePath,
      fileName: fileName,
      size: bytes.length,
      checksum: checksum,
      platform: platform,
      createdAt: DateTime.now(),
      metadata: {
        'originalSize': artifact.size,
        'modified': artifact.modified.toIso8601String(),
      },
    );

    _storedArtifacts[storedArtifact.artifactId] = storedArtifact;

    return storedArtifact;
  }

  Future<void> _updateArtifactVersion(ArtifactCollection collection) async {
    if (collection.version == null) return;

    final versionKey = '${collection.platform}_${collection.version}';
    final existingVersion = _artifactVersions[versionKey];

    if (existingVersion == null ||
        collection.createdAt.isAfter(existingVersion.createdAt)) {
      _artifactVersions[versionKey] = ArtifactVersion(
        version: collection.version!,
        platform: collection.platform,
        collectionId: collection.collectionId,
        createdAt: collection.createdAt,
        isLatest: true,
      );

      // Mark previous versions as not latest
      final otherVersions = _artifactVersions.values
          .where((v) => v.platform == collection.platform && v.version != collection.version)
          .toList();

      for (final version in otherVersions) {
        version.isLatest = false;
      }
    }
  }

  List<ArtifactCollection> _findArtifactCollections({
    String? buildId,
    String? version,
    TargetPlatform? platform,
    RetrievalStrategy strategy = RetrievalStrategy.latest,
  }) {
    var collections = _artifactCollections.values.toList();

    // Apply filters
    if (buildId != null) {
      collections = collections.where((c) => c.buildId == buildId).toList();
    }

    if (version != null) {
      collections = collections.where((c) => c.version == version).toList();
    }

    if (platform != null) {
      collections = collections.where((c) => c.platform == platform).toList();
    }

    if (collections.isEmpty) return [];

    // Apply strategy
    switch (strategy) {
      case RetrievalStrategy.latest:
        collections.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return [collections.first];
      case RetrievalStrategy.all:
        return collections;
      case RetrievalStrategy.highestVersion:
        // Would need version comparison logic
        collections.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return [collections.first];
    }
  }

  Future<List<IntegrityVerificationResult>> _verifyArtifactIntegrity(List<StoredArtifact> artifacts) async {
    final results = <IntegrityVerificationResult>[];

    for (final artifact in artifacts) {
      try {
        final file = File(artifact.storagePath);
        if (!await file.exists()) {
          results.add(IntegrityVerificationResult(
            artifactId: artifact.artifactId,
            verified: false,
            error: 'File not found',
          ));
          continue;
        }

        final bytes = await file.readAsBytes();
        final calculatedChecksum = sha256.convert(bytes).toString();

        final verified = calculatedChecksum == artifact.checksum;
        results.add(IntegrityVerificationResult(
          artifactId: artifact.artifactId,
          verified: verified,
          error: verified ? null : 'Checksum mismatch',
        ));

      } catch (e) {
        results.add(IntegrityVerificationResult(
          artifactId: artifact.artifactId,
          verified: false,
          error: e.toString(),
        ));
      }
    }

    return results;
  }

  Future<void> _applyCleanupPolicies() async {
    for (final policy in _cleanupPolicies.values.where((p) => p.enabled)) {
      await cleanupArtifacts(
        strategy: CleanupStrategy.policyBased,
        maxAgeDays: policy.maxAge?.inDays,
        maxTotalSize: policy.maxTotalSize,
      );
    }
  }

  Future<CleanupPlan> _planArtifactCleanup({
    CleanupStrategy strategy = CleanupStrategy.policyBased,
    DateTime? beforeDate,
    int? maxAgeDays,
    int? maxTotalSize,
  }) async {
    final artifactsToRemove = <String>[];
    int totalSizeToFree = 0;

    final cutoffDate = beforeDate ?? (maxAgeDays != null
        ? DateTime.now().subtract(Duration(days: maxAgeDays))
        : null);

    // Sort collections by age (oldest first)
    final sortedCollections = _artifactCollections.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final collection in sortedCollections) {
      var shouldRemove = false;

      switch (strategy) {
        case CleanupStrategy.ageBased:
          if (cutoffDate != null && collection.createdAt.isBefore(cutoffDate)) {
            shouldRemove = true;
          }
          break;

        case CleanupStrategy.sizeBased:
          if (maxTotalSize != null) {
            final currentTotalSize = _artifactCollections.values
                .fold<int>(0, (sum, c) => sum + c.totalSize);
            if (currentTotalSize > maxTotalSize) {
              shouldRemove = true;
            }
          }
          break;

        case CleanupStrategy.policyBased:
          shouldRemove = await _shouldRemoveByPolicy(collection);
          break;
      }

      if (shouldRemove) {
        artifactsToRemove.add(collection.collectionId);
        totalSizeToFree += collection.totalSize;
      }
    }

    return CleanupPlan(
      artifactsToRemove: artifactsToRemove,
      totalSizeToFree: totalSizeToFree,
    );
  }

  Future<bool> _shouldRemoveByPolicy(ArtifactCollection collection) async {
    for (final policy in _cleanupPolicies.values.where((p) => p.enabled)) {
      // Check age
      if (policy.maxAge != null &&
          collection.createdAt.isBefore(DateTime.now().subtract(policy.maxAge!))) {
        // Check exclusions
        if (!policy.excludePatterns.any((pattern) =>
            collection.version?.contains(pattern) ?? false)) {
          return true;
        }
      }

      // Check total size (simplified - would need to track running total)
      // Implementation would check if removing this collection would help meet size limits
    }

    return false;
  }

  Future<ChannelDistributionResult> _distributeToChannel(
    ArtifactCollection collection,
    DistributionChannel channel,
    DistributionMode mode,
    Map<String, dynamic>? config,
  ) async {
    try {
      // Create distribution package
      final packagePath = await _createDistributionPackage(collection);

      // Upload to channel
      final uploadResult = await _uploadToChannel(packagePath, channel, config);

      // Clean up temporary package
      try {
        await File(packagePath).delete();
      } catch (e) {
        // Ignore cleanup errors
      }

      return ChannelDistributionResult(
        channelName: channel.name,
        success: uploadResult.success,
        packagePath: packagePath,
        uploadUrl: uploadResult.uploadUrl,
        error: uploadResult.error,
      );

    } catch (e) {
      return ChannelDistributionResult(
        channelName: channel.name,
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<String> _createDistributionPackage(ArtifactCollection collection) async {
    final tempDir = await Directory.systemTemp.createTemp('artifact_dist_');
    final packagePath = path.join(tempDir.path, '${collection.collectionId}.zip');

    // Create archive
    final archive = Archive();

    for (final artifact in collection.artifacts) {
      final file = File(artifact.storagePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final archiveFile = ArchiveFile(
          artifact.fileName,
          bytes.length,
          bytes,
        );
        archive.addFile(archiveFile);
      }
    }

    // Write archive
    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);
    if (zipData != null) {
      await File(packagePath).writeAsBytes(zipData);
    }

    return packagePath;
  }

  Future<UploadResult> _uploadToChannel(
    String packagePath,
    DistributionChannel channel,
    Map<String, dynamic>? config,
  ) async {
    // Placeholder implementation - would integrate with actual distribution APIs
    // For example: AWS S3, Google Cloud Storage, Azure Blob Storage, etc.

    try {
      // Simulate upload delay
      await Future.delayed(const Duration(seconds: 2));

      return UploadResult(
        success: true,
        uploadUrl: '${channel.endpoint}/${path.basename(packagePath)}',
      );

    } catch (e) {
      return UploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _saveArtifactMetadata() async {
    final metadata = {
      'storedArtifacts': _storedArtifacts.map((key, value) => MapEntry(key, value.toJson())),
      'collections': _artifactCollections.map((key, value) => MapEntry(key, value.toJson())),
      'versions': _artifactVersions.map((key, value) => MapEntry(key, value.toJson())),
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    final metadataFile = File(path.join(_artifactsDirectory, _metadataFile));
    await metadataFile.writeAsString(json.encode(metadata));
  }

  Map<String, int> _calculateSizeDistribution(List<ArtifactCollection> collections) {
    final distribution = <String, int>{};

    for (final collection in collections) {
      final sizeCategory = _getSizeCategory(collection.totalSize);
      distribution[sizeCategory] = (distribution[sizeCategory] ?? 0) + 1;
    }

    return distribution;
  }

  Map<String, int> _calculateAgeDistribution(List<ArtifactCollection> collections) {
    final distribution = <String, int>{};
    final now = DateTime.now();

    for (final collection in collections) {
      final age = now.difference(collection.createdAt);
      final ageCategory = _getAgeCategory(age);
      distribution[ageCategory] = (distribution[ageCategory] ?? 0) + 1;
    }

    return distribution;
  }

  String _getSizeCategory(int sizeBytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = sizeBytes.toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    if (size < 1) return '<1${units[unitIndex]}';
    if (size < 10) return '<10${units[unitIndex]}';
    if (size < 100) return '<100${units[unitIndex]}';
    return '100${units[unitIndex]}+';
  }

  String _getAgeCategory(Duration age) {
    if (age.inDays < 1) return '<1 day';
    if (age.inDays < 7) return '<1 week';
    if (age.inDays < 30) return '<1 month';
    if (age.inDays < 90) return '<3 months';
    return '3+ months';
  }

  double _calculateStorageEfficiency(List<ArtifactCollection> collections) {
    if (collections.isEmpty) return 0.0;

    // Calculate deduplication efficiency (simplified)
    final totalSize = collections.fold<int>(0, (sum, c) => sum + c.totalSize);
    final uniqueArtifacts = <String>{};

    for (final collection in collections) {
      for (final artifact in collection.artifacts) {
        uniqueArtifacts.add(artifact.checksum);
      }
    }

    // Assume each unique artifact takes some base size
    const assumedArtifactSize = 1024 * 1024; // 1MB average
    final optimalSize = uniqueArtifacts.length * assumedArtifactSize;

    if (optimalSize == 0) return 1.0;
    return optimalSize / totalSize;
  }

  void _emitArtifactEvent(ArtifactEventType type, {
    String? details,
    String? error,
  }) {
    final event = ArtifactEvent(
      type: type,
      timestamp: DateTime.now(),
      details: details,
      error: error,
    );

    _artifactEventController.add(event);
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _artifactEventController.close();
  }
}

/// Supporting data classes

class StoredArtifact {
  final String artifactId;
  final String originalPath;
  final String storagePath;
  final String fileName;
  final int size;
  final String checksum;
  final TargetPlatform platform;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  StoredArtifact({
    required this.artifactId,
    required this.originalPath,
    required this.storagePath,
    required this.fileName,
    required this.size,
    required this.checksum,
    required this.platform,
    required this.createdAt,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'artifactId': artifactId,
    'originalPath': originalPath,
    'storagePath': storagePath,
    'fileName': fileName,
    'size': size,
    'checksum': checksum,
    'platform': platform.toString(),
    'createdAt': createdAt.toIso8601String(),
    'metadata': metadata,
  };

  factory StoredArtifact.fromJson(Map<String, dynamic> json) {
    return StoredArtifact(
      artifactId: json['artifactId'],
      originalPath: json['originalPath'],
      storagePath: json['storagePath'],
      fileName: json['fileName'],
      size: json['size'],
      checksum: json['checksum'],
      platform: TargetPlatform.values.firstWhere(
        (p) => p.toString() == json['platform'],
      ),
      createdAt: DateTime.parse(json['createdAt']),
      metadata: Map<String, dynamic>.from(json['metadata']),
    );
  }
}

class ArtifactCollection {
  final String collectionId;
  final String buildId;
  final TargetPlatform platform;
  final List<StoredArtifact> artifacts;
  final String? version;
  final String? branch;
  final DateTime createdAt;
  final Map<String, String>? metadata;
  final int totalSize;

  ArtifactCollection({
    required this.collectionId,
    required this.buildId,
    required this.platform,
    required this.artifacts,
    this.version,
    this.branch,
    required this.createdAt,
    this.metadata,
    required this.totalSize,
  });

  Map<String, dynamic> toJson() => {
    'collectionId': collectionId,
    'buildId': buildId,
    'platform': platform.toString(),
    'artifacts': artifacts.map((a) => a.toJson()).toList(),
    'version': version,
    'branch': branch,
    'createdAt': createdAt.toIso8601String(),
    'metadata': metadata,
    'totalSize': totalSize,
  };

  factory ArtifactCollection.fromJson(Map<String, dynamic> json) {
    return ArtifactCollection(
      collectionId: json['collectionId'],
      buildId: json['buildId'],
      platform: TargetPlatform.values.firstWhere(
        (p) => p.toString() == json['platform'],
      ),
      artifacts: (json['artifacts'] as List).map((a) => StoredArtifact.fromJson(a)).toList(),
      version: json['version'],
      branch: json['branch'],
      createdAt: DateTime.parse(json['createdAt']),
      metadata: json['metadata'] != null ? Map<String, String>.from(json['metadata']) : null,
      totalSize: json['totalSize'],
    );
  }
}

class ArtifactVersion {
  final String version;
  final TargetPlatform platform;
  final String collectionId;
  final DateTime createdAt;
  bool isLatest;

  ArtifactVersion({
    required this.version,
    required this.platform,
    required this.collectionId,
    required this.createdAt,
    this.isLatest = false,
  });
}

class CleanupPolicy {
  final String name;
  final Duration? maxAge;
  final int? maxTotalSize;
  final int? keepVersions;
  final List<String> excludePatterns;
  final bool enabled;

  CleanupPolicy({
    required this.name,
    this.maxAge,
    this.maxTotalSize,
    this.keepVersions,
    required this.excludePatterns,
    required this.enabled,
  });
}

class DistributionChannel {
  final String name;
  final DistributionType type;
  final String endpoint;
  final Map<String, String> credentials;
  ChannelStatus status;

  DistributionChannel({
    required this.name,
    required this.type,
    required this.endpoint,
    required this.credentials,
    this.status = ChannelStatus.active,
  });
}

class ArtifactStorageResult {
  final bool success;
  final String artifactId;
  final List<StoredArtifact> storedArtifacts;
  final int totalSize;
  final ArtifactCollection? collection;
  final String? error;

  ArtifactStorageResult({
    required this.success,
    required this.artifactId,
    required this.storedArtifacts,
    required this.totalSize,
    this.collection,
    this.error,
  });
}

class ArtifactRetrievalResult {
  final bool success;
  final List<StoredArtifact> artifacts;
  final bool integrityVerified;
  final List<IntegrityVerificationResult> integrityResults;
  final String? error;

  ArtifactRetrievalResult({
    required this.success,
    required this.artifacts,
    required this.integrityVerified,
    required this.integrityResults,
    this.error,
  });
}

class ArtifactDistributionResult {
  final bool success;
  final String artifactId;
  final List<ChannelDistributionResult> distributionResults;
  final int distributedChannels;
  final String? error;

  ArtifactDistributionResult({
    required this.success,
    required this.artifactId,
    required this.distributionResults,
    required this.distributedChannels,
    this.error,
  });
}

class ArtifactCleanupResult {
  final bool success;
  final bool dryRun;
  final int removedArtifacts;
  final int freedSpace;
  final List<String> artifactsToRemove;
  final int? plannedRemovals;
  final int? spaceToFree;
  final String? error;

  ArtifactCleanupResult({
    required this.success,
    required this.dryRun,
    this.removedArtifacts = 0,
    this.freedSpace = 0,
    this.artifactsToRemove = const [],
    this.plannedRemovals,
    this.spaceToFree,
    this.error,
  });
}

class ArtifactStatistics {
  final int totalCollections;
  final int totalArtifacts;
  final int totalSizeBytes;
  final double averageCollectionSize;
  final Map<TargetPlatform, int> platformDistribution;
  final Map<String, int> sizeDistribution;
  final Map<String, int> ageDistribution;
  final double storageEfficiency;

  ArtifactStatistics({
    required this.totalCollections,
    required this.totalArtifacts,
    required this.totalSizeBytes,
    required this.averageCollectionSize,
    required this.platformDistribution,
    required this.sizeDistribution,
    required this.ageDistribution,
    required this.storageEfficiency,
  });

  @override
  String toString() {
    return '''
Artifact Statistics:
Total Collections: $totalCollections
Total Artifacts: $totalArtifacts
Total Size: ${(totalSizeBytes / 1024 / 1024).toStringAsFixed(2)} MB
Average Collection Size: ${(averageCollectionSize / 1024 / 1024).toStringAsFixed(2)} MB
Platform Distribution: $platformDistribution
Storage Efficiency: ${(storageEfficiency * 100).round()}%
''';
  }
}

class CleanupPlan {
  final List<String> artifactsToRemove;
  final int totalSizeToFree;

  CleanupPlan({
    required this.artifactsToRemove,
    required this.totalSizeToFree,
  });
}

class IntegrityVerificationResult {
  final String artifactId;
  final bool verified;
  final String? error;

  IntegrityVerificationResult({
    required this.artifactId,
    required this.verified,
    this.error,
  });
}

class ChannelDistributionResult {
  final String channelName;
  final bool success;
  final String? packagePath;
  final String? uploadUrl;
  final String? error;

  ChannelDistributionResult({
    required this.channelName,
    required this.success,
    this.packagePath,
    this.uploadUrl,
    this.error,
  });
}

class UploadResult {
  final bool success;
  final String? uploadUrl;
  final String? error;

  UploadResult({
    required this.success,
    this.uploadUrl,
    this.error,
  });
}

/// Enums

enum StorageStrategy {
  standard,  // Copy artifacts
  move,      // Move artifacts (destructive)
  compressed, // Compress before storage
}

enum RetrievalStrategy {
  latest,         // Get latest version
  all,           // Get all matching
  highestVersion, // Get highest version number
}

enum CleanupStrategy {
  ageBased,      // Remove by age
  sizeBased,     // Remove by total size
  policyBased,   // Use cleanup policies
}

enum DistributionMode {
  automatic,  // Auto-distribute based on rules
  manual,     // Manual distribution
  staged,     // Staged rollout
}

enum DistributionType {
  internal,
  staging,
  production,
  cdn,
  marketplace,
}

enum ChannelStatus {
  active,
  inactive,
  maintenance,
  error,
}

enum ArtifactEventType {
  serviceInitialized,
  initializationFailed,
  storageStarted,
  storageCompleted,
  storageFailed,
  retrievalCompleted,
  retrievalFailed,
  distributionStarted,
  distributionCompleted,
  distributionFailed,
  cleanupStarted,
  cleanupCompleted,
  cleanupFailed,
}

/// Event classes

class ArtifactEvent {
  final ArtifactEventType type;
  final DateTime timestamp;
  final String? details;
  final String? error;

  ArtifactEvent({
    required this.type,
    required this.timestamp,
    this.details,
    this.error,
  });
}

/// Exception class

class ArtifactException implements Exception {
  final String message;

  ArtifactException(this.message);

  @override
  String toString() => 'ArtifactException: $message';
}
