import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:collection/collection.dart';
import 'performance_optimization_service.dart';
import '../../core/config/central_config.dart';

/// Advanced File Operations Service
/// Provides comprehensive file management operations with batch processing, search, compression, and intelligent features
class AdvancedFileOperationsService {
  static final AdvancedFileOperationsService _instance = AdvancedFileOperationsService._internal();
  factory AdvancedFileOperationsService() => _instance;
  AdvancedFileOperationsService._internal();

  final PerformanceOptimizationService _performanceService = PerformanceOptimizationService();
  final CentralConfig _config = CentralConfig.instance;
  final StreamController<FileOperationEvent> _operationEventController = StreamController.broadcast();

  Stream<FileOperationEvent> get operationEvents => _operationEventController.stream;

  // Operation management
  final Map<String, FileOperation> _activeOperations = {};
  final Map<String, BatchOperation> _batchOperations = {};
  final Semaphore _fileOperationSemaphore = Semaphore(5); // Limit concurrent file operations

  // Search and indexing
  final Map<String, FileIndex> _fileIndexes = {};
  final Map<String, SearchCache> _searchCache = {};

  // Compression and archiving
  final Map<String, CompressionProfile> _compressionProfiles = {};

  bool _isInitialized = false;

  // Configuration
  static const int _maxBatchSize = 100;
  static const Duration _operationTimeout = Duration(minutes: 30);
  static const int _searchCacheSize = 1000;

  /// Initialize advanced file operations service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Register with CentralConfig
      await _config.registerComponent(
        'AdvancedFileOperationsService',
        '1.0.0',
        'Advanced file operations with batch processing, search, compression, and AI analysis using comprehensive centralized parameterization',
        dependencies: ['PerformanceOptimizationService'],
        parameters: {
          // === BATCH OPERATIONS ===
          'file_ops.max_batch_size': _config.getParameter('file_ops.max_batch_size', defaultValue: 100),
          'file_ops.batch_operation_timeout_minutes': _config.getParameter('file_ops.batch_operation_timeout_minutes', defaultValue: 30),
          'file_ops.batch_progress_reporting': _config.getParameter('file_ops.batch_progress_reporting', defaultValue: true),
          'file_ops.batch_parallel_operations': _config.getParameter('file_ops.batch_parallel_operations', defaultValue: 5),
          'file_ops.batch_error_handling': _config.getParameter('file_ops.batch_error_handling', defaultValue: 'continue'),

          // === SEARCH CONFIGURATION ===
          'file_ops.search_cache_size': _config.getParameter('file_ops.search_cache_size', defaultValue: 1000),
          'file_ops.search_timeout_ms': _config.getParameter('file_ops.search_timeout_ms', defaultValue: 30000),
          'file_ops.search_max_results': _config.getParameter('file_ops.search_max_results', defaultValue: 1000),
          'file_ops.search_case_sensitive': _config.getParameter('file_ops.search_case_sensitive', defaultValue: false),
          'file_ops.search_include_hidden_files': _config.getParameter('file_ops.search_include_hidden_files', defaultValue: false),
          'file_ops.search_follow_symlinks': _config.getParameter('file_ops.search_follow_symlinks', defaultValue: false),

          // === COMPRESSION SETTINGS ===
          'file_ops.compression_threads': _config.getParameter('file_ops.compression_threads', defaultValue: 4),
          'file_ops.compression_buffer_size': _config.getParameter('file_ops.compression_buffer_size', defaultValue: 1048576),
          'file_ops.compression_default_format': _config.getParameter('file_ops.compression_default_format', defaultValue: 'zip'),
          'file_ops.compression_default_level': _config.getParameter('file_ops.compression_default_level', defaultValue: 'normal'),
          'file_ops.compression_max_file_size': _config.getParameter('file_ops.compression_max_file_size', defaultValue: 1073741824),
          'file_ops.compression_verify_integrity': _config.getParameter('file_ops.compression_verify_integrity', defaultValue: true),

          // === FILE PREVIEW SETTINGS ===
          'file_ops.preview_max_file_size': _config.getParameter('file_ops.preview_max_file_size', defaultValue: 1048576),
          'file_ops.preview_image_max_width': _config.getParameter('file_ops.preview_image_max_width', defaultValue: 1024),
          'file_ops.preview_image_max_height': _config.getParameter('file_ops.preview_image_max_height', defaultValue: 1024),
          'file_ops.preview_video_max_duration': _config.getParameter('file_ops.preview_video_max_duration', defaultValue: 30),
          'file_ops.preview_text_max_lines': _config.getParameter('file_ops.preview_text_max_lines', defaultValue: 1000),
          'file_ops.preview_cache_enabled': _config.getParameter('file_ops.preview_cache_enabled', defaultValue: true),
          'file_ops.preview_cache_size': _config.getParameter('file_ops.preview_cache_size', defaultValue: 100),

          // === DUPLICATE DETECTION ===
          'file_ops.duplicate_detection_method': _config.getParameter('file_ops.duplicate_detection_method', defaultValue: 'content_hash'),
          'file_ops.duplicate_min_file_size': _config.getParameter('file_ops.duplicate_min_file_size', defaultValue: 1024),
          'file_ops.duplicate_max_file_size': _config.getParameter('file_ops.duplicate_max_file_size', defaultValue: 1073741824),
          'file_ops.duplicate_scan_hidden_files': _config.getParameter('file_ops.duplicate_scan_hidden_files', defaultValue: false),
          'file_ops.duplicate_follow_symlinks': _config.getParameter('file_ops.duplicate_follow_symlinks', defaultValue: false),

          // === SYNCHRONIZATION ===
          'file_ops.sync_conflict_strategy': _config.getParameter('file_ops.sync_conflict_strategy', defaultValue: 'last_write_wins'),
          'file_ops.sync_bidirectional_enabled': _config.getParameter('file_ops.sync_bidirectional_enabled', defaultValue: true),
          'file_ops.sync_preview_changes': _config.getParameter('file_ops.sync_preview_changes', defaultValue: true),
          'file_ops.sync_dry_run_enabled': _config.getParameter('file_ops.sync_dry_run_enabled', defaultValue: false),
          'file_ops.sync_backup_on_conflict': _config.getParameter('file_ops.sync_backup_on_conflict', defaultValue: true),

          // === FILE SYSTEM ANALYSIS ===
          'file_ops.analysis_include_hidden_files': _config.getParameter('file_ops.analysis_include_hidden_files', defaultValue: false),
          'file_ops.analysis_max_depth': _config.getParameter('file_ops.analysis_max_depth', defaultValue: 10),
          'file_ops.analysis_generate_charts': _config.getParameter('file_ops.analysis_generate_charts', defaultValue: true),
          'file_ops.analysis_chart_max_items': _config.getParameter('file_ops.analysis_chart_max_items', defaultValue: 20),
          'file_ops.analysis_timeout_minutes': _config.getParameter('file_ops.analysis_timeout_minutes', defaultValue: 10),

          // === PERFORMANCE SETTINGS ===
          'file_ops.performance_monitoring_enabled': _config.getParameter('file_ops.performance_monitoring_enabled', defaultValue: true),
          'file_ops.performance_slow_operation_threshold': _config.getParameter('file_ops.performance_slow_operation_threshold', defaultValue: 5000),
          'file_ops.performance_memory_limit_mb': _config.getParameter('file_ops.performance_memory_limit_mb', defaultValue: 512),
          'file_ops.performance_cpu_limit_percent': _config.getParameter('file_ops.performance_cpu_limit_percent', defaultValue: 80),

          // === SECURITY SETTINGS ===
          'file_ops.security_safe_operations_only': _config.getParameter('file_ops.security_safe_operations_only', defaultValue: true),
          'file_ops.security_validate_paths': _config.getParameter('file_ops.security_validate_paths', defaultValue: true),
          'file_ops.security_sandbox_operations': _config.getParameter('file_ops.security_sandbox_operations', defaultValue: true),
          'file_ops.security_audit_operations': _config.getParameter('file_ops.security_audit_operations', defaultValue: true),

          // === LOGGING CONFIGURATION ===
          'file_ops.logging_level': _config.getParameter('file_ops.logging_level', defaultValue: 'info'),
          'file_ops.logging_operation_details': _config.getParameter('file_ops.logging_operation_details', defaultValue: true),
          'file_ops.logging_performance_metrics': _config.getParameter('file_ops.logging_performance_metrics', defaultValue: true),
          'file_ops.logging_error_details': _config.getParameter('file_ops.logging_error_details', defaultValue: true),
          'file_ops.logging_file_operations': _config.getParameter('file_ops.logging_file_operations', defaultValue: true),

          // === CACHE SETTINGS ===
          'file_ops.cache_enabled': _config.getParameter('file_ops.cache_enabled', defaultValue: true),
          'file_ops.cache_ttl_minutes': _config.getParameter('file_ops.cache_ttl_minutes', defaultValue: 30),
          'file_ops.cache_max_entries': _config.getParameter('file_ops.cache_max_entries', defaultValue: 10000),
          'file_ops.cache_cleanup_interval_minutes': _config.getParameter('file_ops.cache_cleanup_interval_minutes', defaultValue: 15),
          'file_ops.cache_persistence_enabled': _config.getParameter('file_ops.cache_persistence_enabled', defaultValue: false),

          // === INDEXING SETTINGS ===
          'file_ops.indexing_enabled': _config.getParameter('file_ops.indexing_enabled', defaultValue: true),
          'file_ops.indexing_update_interval_hours': _config.getParameter('file_ops.indexing_update_interval_hours', defaultValue: 24),
          'file_ops.indexing_max_index_size': _config.getParameter('file_ops.indexing_max_index_size', defaultValue: 1073741824),
          'file_ops.indexing_exclude_patterns': _config.getParameter('file_ops.indexing_exclude_patterns', defaultValue: '*.tmp,*.log,*.cache'),
          'file_ops.indexing_include_hidden_files': _config.getParameter('file_ops.indexing_include_hidden_files', defaultValue: false),

          // === UI INTEGRATION ===
          'file_ops.ui_progress_indicators': _config.getParameter('file_ops.ui_progress_indicators', defaultValue: true),
          'file_ops.ui_operation_notifications': _config.getParameter('file_ops.ui_operation_notifications', defaultValue: true),
          'file_ops.ui_drag_drop_enabled': _config.getParameter('file_ops.ui_drag_drop_enabled', defaultValue: true),
          'file_ops.ui_context_menus': _config.getParameter('file_ops.ui_context_menus', defaultValue: true),
          'file_ops.ui_keyboard_shortcuts': _config.getParameter('file_ops.ui_keyboard_shortcuts', defaultValue: true),

          // === NETWORK OPERATIONS ===
          'file_ops.network_timeout_seconds': _config.getParameter('file_ops.network_timeout_seconds', defaultValue: 30),
          'file_ops.network_retry_attempts': _config.getParameter('file_ops.network_retry_attempts', defaultValue: 3),
          'file_ops.network_chunk_size': _config.getParameter('file_ops.network_chunk_size', defaultValue: 1048576),
          'file_ops.network_buffer_size': _config.getParameter('file_ops.network_buffer_size', defaultValue: 8192),

          // === CLOUD INTEGRATION ===
          'file_ops.cloud_sync_enabled': _config.getParameter('file_ops.cloud_sync_enabled', defaultValue: false),
          'file_ops.cloud_sync_interval_minutes': _config.getParameter('file_ops.cloud_sync_interval_minutes', defaultValue: 15),
          'file_ops.cloud_backup_enabled': _config.getParameter('file_ops.cloud_backup_enabled', defaultValue: false),
          'file_ops.cloud_backup_interval_hours': _config.getParameter('file_ops.cloud_backup_interval_hours', defaultValue: 24),
          'file_ops.cloud_max_concurrent_uploads': _config.getParameter('file_ops.cloud_max_concurrent_uploads', defaultValue: 3),

          // === ADVANCED FEATURES ===
          'file_ops.ai_analysis_enabled': _config.getParameter('file_ops.ai_analysis_enabled', defaultValue: true),
          'file_ops.ai_metadata_extraction': _config.getParameter('file_ops.ai_metadata_extraction', defaultValue: true),
          'file_ops.ai_duplicate_detection': _config.getParameter('file_ops.ai_duplicate_detection', defaultValue: false),
          'file_ops.ai_smart_organization': _config.getParameter('file_ops.ai_smart_organization', defaultValue: false),

          // === ERROR HANDLING ===
          'file_ops.error_recovery_enabled': _config.getParameter('file_ops.error_recovery_enabled', defaultValue: true),
          'file_ops.error_max_retry_attempts': _config.getParameter('file_ops.error_max_retry_attempts', defaultValue: 3),
          'file_ops.error_retry_delay_seconds': _config.getParameter('file_ops.error_retry_delay_seconds', defaultValue: 5),
          'file_ops.error_user_friendly_messages': _config.getParameter('file_ops.error_user_friendly_messages', defaultValue: true),
          'file_ops.error_detailed_logging': _config.getParameter('file_ops.error_detailed_logging', defaultValue: true),

          // === MONITORING AND ANALYTICS ===
          'file_ops.analytics_enabled': _config.getParameter('file_ops.analytics_enabled', defaultValue: true),
          'file_ops.analytics_track_operations': _config.getParameter('file_ops.analytics_track_operations', defaultValue: true),
          'file_ops.analytics_track_performance': _config.getParameter('file_ops.analytics_track_performance', defaultValue: true),
          'file_ops.analytics_track_errors': _config.getParameter('file_ops.analytics_track_errors', defaultValue: true),
          'file_ops.analytics_report_interval_hours': _config.getParameter('file_ops.analytics_report_interval_hours', defaultValue: 24),
        }
      );

      // Register component relationships
      await _config.registerComponentRelationship(
        'AdvancedFileOperationsService',
        'PerformanceOptimizationService',
        RelationshipType.depends_on,
        'Uses performance optimization for operation tracking and caching',
      );

      await _config.registerComponentRelationship(
        'AdvancedFileOperationsService',
        'AIFileAnalysisService',
        RelationshipType.uses,
        'Integrates with AI service for intelligent file operations',
      );

      // Initialize compression profiles
      _initializeCompressionProfiles();

      // Load existing indexes
      await _loadFileIndexes();

      _isInitialized = true;
      _emitOperationEvent(FileOperationEventType.serviceInitialized);

    } catch (e) {
      _emitOperationEvent(FileOperationEventType.initializationFailed, error: e.toString());
      rethrow;
    }
  }

  /// Perform batch file operations
  Future<BatchOperationResult> performBatchOperation({
    required BatchOperationType type,
    required List<String> sourcePaths,
    required String destinationPath,
    BatchOperationOptions? options,
    Function(BatchProgress)? onProgress,
  }) async {
    if (sourcePaths.length > _maxBatchSize) {
      throw FileOperationException('Batch size exceeds maximum limit of $_maxBatchSize');
    }

    final operationId = 'batch_${type.toString().split('.').last}_${DateTime.now().millisecondsSinceEpoch}';
    final batchOperation = BatchOperation(
      id: operationId,
      type: type,
      sourcePaths: sourcePaths,
      destinationPath: destinationPath,
      options: options ?? BatchOperationOptions(),
      startTime: DateTime.now(),
    );

    _batchOperations[operationId] = batchOperation;

    try {
      _emitOperationEvent(FileOperationEventType.batchStarted, operationId: operationId,
        details: 'Type: $type, Files: ${sourcePaths.length}');

      final result = await _executeBatchOperation(batchOperation, onProgress);

      _emitOperationEvent(FileOperationEventType.batchCompleted, operationId: operationId,
        details: 'Success: ${result.successfulOperations}/${result.totalOperations}');

      return result;

    } catch (e) {
      _emitOperationEvent(FileOperationEventType.batchFailed, operationId: operationId,
        error: e.toString());
      rethrow;
    } finally {
      _batchOperations.remove(operationId);
    }
  }

  /// Advanced file search with multiple criteria
  Future<SearchResult> searchFiles({
    required String directory,
    String? query,
    List<String>? fileTypes,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    int? minSize,
    int? maxSize,
    bool includeSubdirectories = true,
    bool useCache = true,
    SearchOptions? options,
  }) async {
    final searchId = 'search_${DateTime.now().millisecondsSinceEpoch}';

    _emitOperationEvent(FileOperationEventType.searchStarted, operationId: searchId);

    try {
      // Check cache first
      if (useCache) {
        final cachedResult = _getCachedSearchResult(directory, query, fileTypes);
        if (cachedResult != null) {
          _emitOperationEvent(FileOperationEventType.searchCompleted, operationId: searchId,
            details: 'Cached results: ${cachedResult.files.length} files');
          return cachedResult;
        }
      }

      final searchOptions = options ?? SearchOptions();
      final results = <FileSearchResult>[];

      await _performFileSearch(
        directory: directory,
        query: query,
        fileTypes: fileTypes,
        modifiedAfter: modifiedAfter,
        modifiedBefore: modifiedBefore,
        minSize: minSize,
        maxSize: maxSize,
        includeSubdirectories: includeSubdirectories,
        results: results,
        searchOptions: searchOptions,
      );

      final searchResult = SearchResult(
        searchId: searchId,
        query: query,
        directory: directory,
        files: results,
        totalFiles: results.length,
        searchTime: DateTime.now().difference(DateTime.now()), // Will be updated
        filters: SearchFilters(
          fileTypes: fileTypes,
          modifiedAfter: modifiedAfter,
          modifiedBefore: modifiedBefore,
          minSize: minSize,
          maxSize: maxSize,
        ),
      );

      // Cache results
      if (useCache) {
        _cacheSearchResult(searchResult);
      }

      _emitOperationEvent(FileOperationEventType.searchCompleted, operationId: searchId,
        details: 'Found ${results.length} files');

      return searchResult;

    } catch (e) {
      _emitOperationEvent(FileOperationEventType.searchFailed, operationId: searchId,
        error: e.toString());
      rethrow;
    }
  }

  /// Compress files with advanced options
  Future<CompressionResult> compressFiles({
    required List<String> sourcePaths,
    required String outputPath,
    CompressionFormat format = CompressionFormat.zip,
    CompressionLevel level = CompressionLevel.normal,
    String? password,
    Function(double)? onProgress,
  }) async {
    final operationId = 'compress_${DateTime.now().millisecondsSinceEpoch}';

    _emitOperationEvent(FileOperationEventType.compressionStarted, operationId: operationId,
      details: 'Files: ${sourcePaths.length}, Format: $format');

    try {
      final result = await _performCompression(
        sourcePaths: sourcePaths,
        outputPath: outputPath,
        format: format,
        level: level,
        password: password,
        onProgress: onProgress,
      );

      _emitOperationEvent(FileOperationEventType.compressionCompleted, operationId: operationId,
        details: 'Compressed ${result.filesProcessed} files to ${result.outputSize} bytes');

      return result;

    } catch (e) {
      _emitOperationEvent(FileOperationEventType.compressionFailed, operationId: operationId,
        error: e.toString());
      rethrow;
    }
  }

  /// Extract compressed archives
  Future<ExtractionResult> extractArchive({
    required String archivePath,
    required String outputDirectory,
    String? password,
    Function(double)? onProgress,
  }) async {
    final operationId = 'extract_${DateTime.now().millisecondsSinceEpoch}';

    _emitOperationEvent(FileOperationEventType.extractionStarted, operationId: operationId,
      details: 'Archive: $archivePath');

    try {
      final result = await _performExtraction(
        archivePath: archivePath,
        outputDirectory: outputDirectory,
        password: password,
        onProgress: onProgress,
      );

      _emitOperationEvent(FileOperationEventType.extractionCompleted, operationId: operationId,
        details: 'Extracted ${result.filesExtracted} files');

      return result;

    } catch (e) {
      _emitOperationEvent(FileOperationEventType.extractionFailed, operationId: operationId,
        error: e.toString());
      rethrow;
    }
  }

  /// Find duplicate files
  Future<DuplicateFilesResult> findDuplicateFiles({
    required String directory,
    bool includeSubdirectories = true,
    DuplicateDetectionMethod method = DuplicateDetectionMethod.contentHash,
    Function(DuplicateProgress)? onProgress,
  }) async {
    final operationId = 'duplicates_${DateTime.now().millisecondsSinceEpoch}';

    _emitOperationEvent(FileOperationEventType.duplicateSearchStarted, operationId: operationId);

    try {
      final result = await _performDuplicateDetection(
        directory: directory,
        includeSubdirectories: includeSubdirectories,
        method: method,
        onProgress: onProgress,
      );

      _emitOperationEvent(FileOperationEventType.duplicateSearchCompleted, operationId: operationId,
        details: 'Found ${result.totalDuplicates} duplicate groups');

      return result;

    } catch (e) {
      _emitOperationEvent(FileOperationEventType.duplicateSearchFailed, operationId: operationId,
        error: e.toString());
      rethrow;
    }
  }

  /// Generate file previews and thumbnails
  Future<FilePreviewResult> generateFilePreview({
    required String filePath,
    PreviewType type = PreviewType.thumbnail,
    int maxWidth = 256,
    int maxHeight = 256,
    bool generateMetadata = true,
  }) async {
    final operationId = 'preview_${DateTime.now().millisecondsSinceEpoch}';

    _emitOperationEvent(FileOperationEventType.previewGenerationStarted, operationId: operationId,
      details: 'File: ${path.basename(filePath)}, Type: $type');

    try {
      final result = await _generateFilePreview(
        filePath: filePath,
        type: type,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        generateMetadata: generateMetadata,
      );

      _emitOperationEvent(FileOperationEventType.previewGenerationCompleted, operationId: operationId);

      return result;

    } catch (e) {
      _emitOperationEvent(FileOperationEventType.previewGenerationFailed, operationId: operationId,
        error: e.toString());
      rethrow;
    }
  }

  /// Synchronize directories with conflict resolution
  Future<DirectorySyncResult> synchronizeDirectories({
    required String sourceDirectory,
    required String targetDirectory,
    SyncMode mode = SyncMode.bidirectional,
    ConflictResolutionStrategy conflictStrategy = ConflictResolutionStrategy.lastWriteWins,
    Function(SyncProgress)? onProgress,
  }) async {
    final operationId = 'sync_${DateTime.now().millisecondsSinceEpoch}';

    _emitOperationEvent(FileOperationEventType.syncStarted, operationId: operationId,
      details: 'Mode: $mode, Strategy: $conflictStrategy');

    try {
      final result = await _performDirectorySync(
        sourceDirectory: sourceDirectory,
        targetDirectory: targetDirectory,
        mode: mode,
        conflictStrategy: conflictStrategy,
        onProgress: onProgress,
      );

      _emitOperationEvent(FileOperationEventType.syncCompleted, operationId: operationId,
        details: 'Synced ${result.filesCopied} files, ${result.filesDeleted} deleted');

      return result;

    } catch (e) {
      _emitOperationEvent(FileOperationEventType.syncFailed, operationId: operationId,
        error: e.toString());
      rethrow;
    }
  }

  /// Analyze file system usage and patterns
  Future<FileSystemAnalysis> analyzeFileSystem({
    required String directory,
    bool includeSubdirectories = true,
    bool generateCharts = true,
    Function(AnalysisProgress)? onProgress,
  }) async {
    final operationId = 'analysis_${DateTime.now().millisecondsSinceEpoch}';

    _emitOperationEvent(FileOperationEventType.analysisStarted, operationId: operationId);

    try {
      final result = await _performFileSystemAnalysis(
        directory: directory,
        includeSubdirectories: includeSubdirectories,
        generateCharts: generateCharts,
        onProgress: onProgress,
      );

      _emitOperationEvent(FileOperationEventType.analysisCompleted, operationId: operationId,
        details: 'Analyzed ${result.totalFiles} files, ${result.totalSize} bytes');

      return result;

    } catch (e) {
      _emitOperationEvent(FileOperationEventType.analysisFailed, operationId: operationId,
        error: e.toString());
      rethrow;
    }
  }

  /// Get operation status
  OperationStatus getOperationStatus(String operationId) {
    final batchOp = _batchOperations[operationId];
    if (batchOp != null) {
      return OperationStatus(
        operationId: operationId,
        type: OperationType.batch,
        status: OperationStatusType.running,
        startTime: batchOp.startTime,
        progress: batchOp.progress,
      );
    }

    final activeOp = _activeOperations[operationId];
    if (activeOp != null) {
      return OperationStatus(
        operationId: operationId,
        type: OperationType.single,
        status: OperationStatusType.running,
        startTime: activeOp.startTime,
      );
    }

    return OperationStatus(
      operationId: operationId,
      type: OperationType.unknown,
      status: OperationStatusType.notFound,
    );
  }

  /// Cancel operation
  Future<bool> cancelOperation(String operationId) async {
    final batchOp = _batchOperations[operationId];
    if (batchOp != null) {
      batchOp.isCancelled = true;
      _emitOperationEvent(FileOperationEventType.batchCancelled, operationId: operationId);
      return true;
    }

    final activeOp = _activeOperations[operationId];
    if (activeOp != null) {
      activeOp.isCancelled = true;
      _emitOperationEvent(FileOperationEventType.operationCancelled, operationId: operationId);
      return true;
    }

    return false;
  }

  // Private methods

  void _initializeCompressionProfiles() {
    _compressionProfiles['fast'] = CompressionProfile(
      name: 'fast',
      format: CompressionFormat.zip,
      level: CompressionLevel.fast,
      description: 'Fast compression with good speed',
    );

    _compressionProfiles['normal'] = CompressionProfile(
      name: 'normal',
      format: CompressionFormat.zip,
      level: CompressionLevel.normal,
      description: 'Balanced compression and speed',
    );

    _compressionProfiles['maximum'] = CompressionProfile(
      name: 'maximum',
      format: CompressionFormat.zip,
      level: CompressionLevel.maximum,
      description: 'Maximum compression with slower speed',
    );

    _compressionProfiles['archive'] = CompressionProfile(
      name: 'archive',
      format: CompressionFormat.tarGz,
      level: CompressionLevel.maximum,
      description: 'Archive format for long-term storage',
    );
  }

  Future<void> _loadFileIndexes() async {
    // Load or create file indexes for faster searching
    // Implementation would load from persistent storage
  }

  Future<BatchOperationResult> _executeBatchOperation(
    BatchOperation operation,
    Function(BatchProgress)? onProgress,
  ) async {
    final results = <OperationResult>[];
    int completed = 0;

    for (final sourcePath in operation.sourcePaths) {
      if (operation.isCancelled) break;

      try {
        final result = await _executeSingleFileOperation(
          type: operation.type,
          sourcePath: sourcePath,
          destinationPath: operation.destinationPath,
          options: operation.options,
        );

        results.add(result);
        completed++;

        final progress = BatchProgress(
          completed: completed,
          total: operation.sourcePaths.length,
          currentFile: path.basename(sourcePath),
          successCount: results.where((r) => r.success).length,
          failureCount: results.where((r) => !r.success).length,
        );

        onProgress?.call(progress);
        operation.progress = progress;

      } catch (e) {
        results.add(OperationResult(
          success: false,
          sourcePath: sourcePath,
          error: e.toString(),
        ));

        completed++;
        final progress = BatchProgress(
          completed: completed,
          total: operation.sourcePaths.length,
          currentFile: path.basename(sourcePath),
          successCount: results.where((r) => r.success).length,
          failureCount: results.where((r) => !r.success).length,
        );

        onProgress?.call(progress);
        operation.progress = progress;
      }
    }

    return BatchOperationResult(
      operationId: operation.id,
      totalOperations: operation.sourcePaths.length,
      successfulOperations: results.where((r) => r.success).length,
      failedOperations: results.where((r) => !r.success).length,
      results: results,
      duration: DateTime.now().difference(operation.startTime),
    );
  }

  Future<OperationResult> _executeSingleFileOperation({
    required BatchOperationType type,
    required String sourcePath,
    required String destinationPath,
    required BatchOperationOptions options,
  }) async {
    return await _performanceService.trackOperation(
      'file_operation_${type.toString().split('.').last}',
      () async {
        switch (type) {
          case BatchOperationType.copy:
            return await _copyFile(sourcePath, destinationPath, options.overwrite);
          case BatchOperationType.move:
            return await _moveFile(sourcePath, destinationPath, options.overwrite);
          case BatchOperationType.delete:
            return await _deleteFile(sourcePath);
          case BatchOperationType.rename:
            return await _renameFile(sourcePath, destinationPath);
        }
      },
    );
  }

  Future<OperationResult> _copyFile(String sourcePath, String destinationPath, bool overwrite) async {
    try {
      final sourceFile = File(sourcePath);
      final destFile = File(destinationPath);

      if (!await sourceFile.exists()) {
        return OperationResult(
          success: false,
          sourcePath: sourcePath,
          error: 'Source file does not exist',
        );
      }

      if (!overwrite && await destFile.exists()) {
        return OperationResult(
          success: false,
          sourcePath: sourcePath,
          error: 'Destination file exists and overwrite is disabled',
        );
      }

      await sourceFile.copy(destinationPath);

      return OperationResult(
        success: true,
        sourcePath: sourcePath,
        destinationPath: destinationPath,
        bytesProcessed: await sourceFile.length(),
      );

    } catch (e) {
      return OperationResult(
        success: false,
        sourcePath: sourcePath,
        error: e.toString(),
      );
    }
  }

  Future<OperationResult> _moveFile(String sourcePath, String destinationPath, bool overwrite) async {
    try {
      final sourceFile = File(sourcePath);
      final destFile = File(destinationPath);

      if (!await sourceFile.exists()) {
        return OperationResult(
          success: false,
          sourcePath: sourcePath,
          error: 'Source file does not exist',
        );
      }

      if (!overwrite && await destFile.exists()) {
        return OperationResult(
          success: false,
          sourcePath: sourcePath,
          error: 'Destination file exists and overwrite is disabled',
        );
      }

      final fileSize = await sourceFile.length();
      await sourceFile.rename(destinationPath);

      return OperationResult(
        success: true,
        sourcePath: sourcePath,
        destinationPath: destinationPath,
        bytesProcessed: fileSize,
      );

    } catch (e) {
      return OperationResult(
        success: false,
        sourcePath: sourcePath,
        error: e.toString(),
      );
    }
  }

  Future<OperationResult> _deleteFile(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        return OperationResult(
          success: false,
          sourcePath: filePath,
          error: 'File does not exist',
        );
      }

      final fileSize = await file.length();
      await file.delete();

      return OperationResult(
        success: true,
        sourcePath: filePath,
        bytesProcessed: fileSize,
      );

    } catch (e) {
      return OperationResult(
        success: false,
        sourcePath: filePath,
        error: e.toString(),
      );
    }
  }

  Future<OperationResult> _renameFile(String oldPath, String newPath) async {
    try {
      final file = File(oldPath);

      if (!await file.exists()) {
        return OperationResult(
          success: false,
          sourcePath: oldPath,
          error: 'File does not exist',
        );
      }

      final fileSize = await file.length();
      await file.rename(newPath);

      return OperationResult(
        success: true,
        sourcePath: oldPath,
        destinationPath: newPath,
        bytesProcessed: fileSize,
      );

    } catch (e) {
      return OperationResult(
        success: false,
        sourcePath: oldPath,
        error: e.toString(),
      );
    }
  }

  Future<void> _performFileSearch({
    required String directory,
    String? query,
    List<String>? fileTypes,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    int? minSize,
    int? maxSize,
    required bool includeSubdirectories,
    required List<FileSearchResult> results,
    required SearchOptions searchOptions,
  }) async {
    final dir = Directory(directory);

    if (!await dir.exists()) {
      throw FileOperationException('Directory does not exist: $directory');
    }

    await for (final entity in dir.list(recursive: includeSubdirectories)) {
      if (entity is File) {
        final matches = await _fileMatchesCriteria(
          entity,
          query: query,
          fileTypes: fileTypes,
          modifiedAfter: modifiedAfter,
          modifiedBefore: modifiedBefore,
          minSize: minSize,
          maxSize: maxSize,
        );

        if (matches) {
          final stat = await entity.stat();
          results.add(FileSearchResult(
            path: entity.path,
            name: path.basename(entity.path),
            size: stat.size,
            modified: stat.modified,
            type: _getFileType(entity.path),
          ));

          // Limit results if specified
          if (searchOptions.maxResults != null && results.length >= searchOptions.maxResults!) {
            break;
          }
        }
      }
    }
  }

  Future<bool> _fileMatchesCriteria(
    File file,
    String? query,
    List<String>? fileTypes,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    int? minSize,
    int? maxSize,
  ) async {
    final stat = await file.stat();

    // Check file types
    if (fileTypes != null && fileTypes.isNotEmpty) {
      final fileType = _getFileType(file.path);
      if (!fileTypes.contains(fileType)) {
        return false;
      }
    }

    // Check modification dates
    if (modifiedAfter != null && stat.modified.isBefore(modifiedAfter)) {
      return false;
    }

    if (modifiedBefore != null && stat.modified.isAfter(modifiedBefore)) {
      return false;
    }

    // Check file size
    if (minSize != null && stat.size < minSize) {
      return false;
    }

    if (maxSize != null && stat.size > maxSize) {
      return false;
    }

    // Check query (filename search)
    if (query != null && query.isNotEmpty) {
      final fileName = path.basename(file.path).toLowerCase();
      if (!fileName.contains(query.toLowerCase())) {
        return false;
      }
    }

    return true;
  }

  String _getFileType(String filePath) {
    final mimeType = lookupMimeType(filePath);
    if (mimeType == null) return 'unknown';

    if (mimeType.startsWith('image/')) return 'image';
    if (mimeType.startsWith('video/')) return 'video';
    if (mimeType.startsWith('audio/')) return 'audio';
    if (mimeType.startsWith('text/')) return 'text';
    if (mimeType == 'application/pdf') return 'pdf';
    if (mimeType.contains('zip') || mimeType.contains('rar') || mimeType.contains('tar')) return 'archive';

    return 'document';
  }

  SearchResult? _getCachedSearchResult(String directory, String? query, List<String>? fileTypes) {
    final cacheKey = _generateSearchCacheKey(directory, query, fileTypes);
    final cached = _searchCache[cacheKey];

    if (cached != null && !cached.isExpired) {
      return cached.result;
    }

    return null;
  }

  void _cacheSearchResult(SearchResult result) {
    final cacheKey = _generateSearchCacheKey(result.directory, result.query, result.filters.fileTypes);

    _searchCache[cacheKey] = SearchCache(
      key: cacheKey,
      result: result,
      cachedAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(minutes: 30)), // Cache for 30 minutes
    );

    // Maintain cache size
    if (_searchCache.length > _searchCacheSize) {
      final oldestKey = _searchCache.keys.first;
      _searchCache.remove(oldestKey);
    }
  }

  String _generateSearchCacheKey(String directory, String? query, List<String>? fileTypes) {
    final keyData = '$directory|$query|${fileTypes?.join(',') ?? ''}';
    return sha256.convert(utf8.encode(keyData)).toString();
  }

  Future<CompressionResult> _performCompression({
    required List<String> sourcePaths,
    required String outputPath,
    required CompressionFormat format,
    required CompressionLevel level,
    String? password,
    Function(double)? onProgress,
  }) async {
    final archive = Archive();
    int totalBytes = 0;
    int processedFiles = 0;

    for (final sourcePath in sourcePaths) {
      final file = File(sourcePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final fileName = path.basename(sourcePath);

        archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
        totalBytes += bytes.length;
        processedFiles++;

        onProgress?.call(processedFiles / sourcePaths.length);
      }
    }

    // Encode archive
    final encoder = _getArchiveEncoder(format);
    final encodedData = encoder.encode(archive);

    if (encodedData != null) {
      await File(outputPath).writeAsBytes(encodedData);
    }

    return CompressionResult(
      success: true,
      filesProcessed: processedFiles,
      totalInputSize: totalBytes,
      outputSize: encodedData?.length ?? 0,
      compressionRatio: totalBytes > 0 ? (encodedData?.length ?? 0) / totalBytes : 0.0,
      outputPath: outputPath,
    );
  }

  Future<ExtractionResult> _performExtraction({
    required String archivePath,
    required String outputDirectory,
    String? password,
    Function(double)? onProgress,
  }) async {
    final file = File(archivePath);
    if (!await file.exists()) {
      throw FileOperationException('Archive file does not exist: $archivePath');
    }

    final bytes = await file.readAsBytes();
    final archive = _getArchiveDecoder(archivePath).decodeBytes(bytes);

    int extractedFiles = 0;
    for (final archiveFile in archive) {
      if (archiveFile.isFile) {
        final outputPath = path.join(outputDirectory, archiveFile.name);
        await Directory(path.dirname(outputPath)).create(recursive: true);
        await File(outputPath).writeAsBytes(archiveFile.content as List<int>);
        extractedFiles++;

        onProgress?.call(extractedFiles / archive.length);
      }
    }

    return ExtractionResult(
      success: true,
      filesExtracted: extractedFiles,
      totalFiles: archive.length,
      outputDirectory: outputDirectory,
    );
  }

  Future<DuplicateFilesResult> _performDuplicateDetection({
    required String directory,
    required bool includeSubdirectories,
    required DuplicateDetectionMethod method,
    Function(DuplicateProgress)? onProgress,
  }) async {
    final fileHashes = <String, List<String>>{};
    final dir = Directory(directory);

    await for (final entity in dir.list(recursive: includeSubdirectories)) {
      if (entity is File) {
        final hash = await _calculateFileHash(entity.path, method);
        fileHashes.putIfAbsent(hash, () => []).add(entity.path);
      }
    }

    final duplicateGroups = fileHashes.values
        .where((files) => files.length > 1)
        .map((files) => DuplicateGroup(
          filePaths: files,
          fileCount: files.length,
          totalSize: 0, // Would calculate actual sizes
        ))
        .toList();

    return DuplicateFilesResult(
      duplicateGroups: duplicateGroups,
      totalDuplicates: duplicateGroups.length,
      totalDuplicateFiles: duplicateGroups.fold<int>(0, (sum, group) => sum + group.fileCount),
      method: method,
    );
  }

  Future<FilePreviewResult> _generateFilePreview({
    required String filePath,
    required PreviewType type,
    required int maxWidth,
    required int maxHeight,
    required bool generateMetadata,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileOperationException('File does not exist: $filePath');
    }

    final mimeType = lookupMimeType(filePath);
    final fileMetadata = generateMetadata ? await _generateFileMetadata(file) : null;

    // For this implementation, we'll create basic previews
    // Real implementation would use image processing libraries
    Uint8List? thumbnailData;
    if (mimeType?.startsWith('image/') ?? false) {
      // Generate thumbnail for images
      thumbnailData = await file.readAsBytes(); // Placeholder - would resize
    }

    return FilePreviewResult(
      filePath: filePath,
      previewType: type,
      thumbnailData: thumbnailData,
      metadata: fileMetadata,
      mimeType: mimeType,
    );
  }

  Future<DirectorySyncResult> _performDirectorySync({
    required String sourceDirectory,
    required String targetDirectory,
    required SyncMode mode,
    required ConflictResolutionStrategy conflictStrategy,
    Function(SyncProgress)? onProgress,
  }) async {
    final sourceDir = Directory(sourceDirectory);
    final targetDir = Directory(targetDirectory);

    final sourceFiles = await _getAllFiles(sourceDirectory);
    final targetFiles = await _getAllFiles(targetDirectory);

    final filesToCopy = <String>[];
    final filesToDelete = <String>[];

    // Determine files to copy
    for (final sourceFile in sourceFiles) {
      final relativePath = path.relative(sourceFile, from: sourceDirectory);
      final targetFile = path.join(targetDirectory, relativePath);

      if (!await File(targetFile).exists()) {
        filesToCopy.add(sourceFile);
      } else {
        // Check modification times
        final sourceStat = await File(sourceFile).stat();
        final targetStat = await File(targetFile).stat();

        if (sourceStat.modified.isAfter(targetStat.modified)) {
          filesToCopy.add(sourceFile);
        }
      }
    }

    // Determine files to delete (for bidirectional sync)
    if (mode == SyncMode.bidirectional) {
      for (final targetFile in targetFiles) {
        final relativePath = path.relative(targetFile, from: targetDirectory);
        final sourceFile = path.join(sourceDirectory, relativePath);

        if (!await File(sourceFile).exists()) {
          filesToDelete.add(targetFile);
        }
      }
    }

    // Perform copy operations
    int filesCopied = 0;
    for (final file in filesToCopy) {
      final relativePath = path.relative(file, from: sourceDirectory);
      final targetPath = path.join(targetDirectory, relativePath);

      await Directory(path.dirname(targetPath)).create(recursive: true);
      await File(file).copy(targetPath);
      filesCopied++;

      onProgress?.call(SyncProgress(
        phase: 'copy',
        completed: filesCopied,
        total: filesToCopy.length + filesToDelete.length,
        currentFile: relativePath,
      ));
    }

    // Perform delete operations
    int filesDeleted = 0;
    for (final file in filesToDelete) {
      await File(file).delete();
      filesDeleted++;

      onProgress?.call(SyncProgress(
        phase: 'delete',
        completed: filesCopied + filesDeleted,
        total: filesToCopy.length + filesToDelete.length,
        currentFile: path.basename(file),
      ));
    }

    return DirectorySyncResult(
      sourceDirectory: sourceDirectory,
      targetDirectory: targetDirectory,
      filesCopied: filesCopied,
      filesDeleted: filesDeleted,
      conflictsResolved: 0, // Would track actual conflicts
      syncMode: mode,
      duration: Duration.zero, // Would track actual duration
    );
  }

  Future<FileSystemAnalysis> _performFileSystemAnalysis({
    required String directory,
    required bool includeSubdirectories,
    required bool generateCharts,
    Function(AnalysisProgress)? onProgress,
  }) async {
    final dir = Directory(directory);
    final fileTypes = <String, int>{};
    final sizeDistribution = <String, int>{};
    int totalFiles = 0;
    int totalSize = 0;

    await for (final entity in dir.list(recursive: includeSubdirectories)) {
      if (entity is File) {
        totalFiles++;
        final stat = await entity.stat();
        totalSize += stat.size;

        final type = _getFileType(entity.path);
        fileTypes[type] = (fileTypes[type] ?? 0) + 1;

        // Size categories
        final sizeCategory = _getSizeCategory(stat.size);
        sizeDistribution[sizeCategory] = (sizeDistribution[sizeCategory] ?? 0) + 1;

        onProgress?.call(AnalysisProgress(
          filesProcessed: totalFiles,
          currentFile: path.basename(entity.path),
        ));
      }
    }

    return FileSystemAnalysis(
      directory: directory,
      totalFiles: totalFiles,
      totalSize: totalSize,
      fileTypes: fileTypes,
      sizeDistribution: sizeDistribution,
      largestFiles: [], // Would populate with actual data
      oldestFiles: [], // Would populate with actual data
      recentlyModified: [], // Would populate with actual data
    );
  }

  Future<List<String>> _getAllFiles(String directory) async {
    final files = <String>[];
    final dir = Directory(directory);

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        files.add(entity.path);
      }
    }

    return files;
  }

  Future<String> _calculateFileHash(String filePath, DuplicateDetectionMethod method) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();

    switch (method) {
      case DuplicateDetectionMethod.contentHash:
        return sha256.convert(bytes).toString();
      case DuplicateDetectionMethod.metadataHash:
        final stat = await file.stat();
        final metadata = '${stat.size}_${stat.modified.millisecondsSinceEpoch}';
        return sha256.convert(utf8.encode(metadata)).toString();
      case DuplicateDetectionMethod.nameHash:
        final name = path.basename(filePath);
        return sha256.convert(utf8.encode(name)).toString();
    }
  }

  ArchiveEncoder _getArchiveEncoder(CompressionFormat format) {
    switch (format) {
      case CompressionFormat.zip:
        return ZipEncoder();
      case CompressionFormat.tar:
        return TarEncoder();
      case CompressionFormat.tarGz:
        return TarEncoder(); // Would need additional gzip encoding
      default:
        return ZipEncoder();
    }
  }

  ArchiveDecoder _getArchiveDecoder(String filePath) {
    final extension = path.extension(filePath).toLowerCase();

    switch (extension) {
      case '.zip':
        return ZipDecoder();
      case '.tar':
        return TarDecoder();
      case '.gz':
      case '.tgz':
        return TarDecoder(); // Would need additional gzip decoding
      default:
        return ZipDecoder();
    }
  }

  Future<FileMetadata> _generateFileMetadata(File file) async {
    final stat = await file.stat();
    final mimeType = lookupMimeType(file.path);

    return FileMetadata(
      path: file.path,
      size: stat.size,
      modified: stat.modified,
      created: stat.changed,
      mimeType: mimeType,
      extension: path.extension(file.path),
      isReadable: true, // Would check actual permissions
      isWritable: true, // Would check actual permissions
    );
  }

  String _getSizeCategory(int sizeBytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = sizeBytes.toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '<1${units[unitIndex]}';
  }

  void _emitOperationEvent(FileOperationEventType type, {
    String? operationId,
    String? details,
    String? error,
  }) {
    final event = FileOperationEvent(
      type: type,
      timestamp: DateTime.now(),
      operationId: operationId,
      details: details,
      error: error,
    );

    _operationEventController.add(event);
  }

  void dispose() {
    _operationEventController.close();
  }
}

/// Supporting data classes

class FileOperation {
  final String id;
  final DateTime startTime;
  bool isCancelled = false;

  FileOperation({
    required this.id,
    required this.startTime,
  });
}

class BatchOperation {
  final String id;
  final BatchOperationType type;
  final List<String> sourcePaths;
  final String destinationPath;
  final BatchOperationOptions options;
  final DateTime startTime;
  BatchProgress? progress;
  bool isCancelled = false;

  BatchOperation({
    required this.id,
    required this.type,
    required this.sourcePaths,
    required this.destinationPath,
    required this.options,
    required this.startTime,
  });
}

class BatchOperationOptions {
  final bool overwrite;
  final bool preserveTimestamps;
  final bool followSymlinks;
  final int bufferSize;

  BatchOperationOptions({
    this.overwrite = false,
    this.preserveTimestamps = true,
    this.followSymlinks = false,
    this.bufferSize = 8192,
  });
}

class BatchProgress {
  final int completed;
  final int total;
  final String? currentFile;
  final int successCount;
  final int failureCount;

  BatchProgress({
    required this.completed,
    required this.total,
    this.currentFile,
    required this.successCount,
    required this.failureCount,
  });

  double get progressPercentage => total > 0 ? completed / total : 0.0;
}

class BatchOperationResult {
  final String operationId;
  final int totalOperations;
  final int successfulOperations;
  final int failedOperations;
  final List<OperationResult> results;
  final Duration duration;

  BatchOperationResult({
    required this.operationId,
    required this.totalOperations,
    required this.successfulOperations,
    required this.failedOperations,
    required this.results,
    required this.duration,
  });
}

class OperationResult {
  final bool success;
  final String sourcePath;
  final String? destinationPath;
  final String? error;
  final int? bytesProcessed;

  OperationResult({
    required this.success,
    required this.sourcePath,
    this.destinationPath,
    this.error,
    this.bytesProcessed,
  });
}

class SearchResult {
  final String searchId;
  final String? query;
  final String directory;
  final List<FileSearchResult> files;
  final int totalFiles;
  final Duration searchTime;
  final SearchFilters filters;

  SearchResult({
    required this.searchId,
    required this.query,
    required this.directory,
    required this.files,
    required this.totalFiles,
    required this.searchTime,
    required this.filters,
  });
}

class FileSearchResult {
  final String path;
  final String name;
  final int size;
  final DateTime modified;
  final String type;

  FileSearchResult({
    required this.path,
    required this.name,
    required this.size,
    required this.modified,
    required this.type,
  });
}

class SearchFilters {
  final List<String>? fileTypes;
  final DateTime? modifiedAfter;
  final DateTime? modifiedBefore;
  final int? minSize;
  final int? maxSize;

  SearchFilters({
    this.fileTypes,
    this.modifiedAfter,
    this.modifiedBefore,
    this.minSize,
    this.maxSize,
  });
}

class SearchOptions {
  final int? maxResults;
  final bool caseSensitive;
  final bool includeHidden;

  SearchOptions({
    this.maxResults,
    this.caseSensitive = false,
    this.includeHidden = false,
  });
}

class SearchCache {
  final String key;
  final SearchResult result;
  final DateTime cachedAt;
  final DateTime expiresAt;

  SearchCache({
    required this.key,
    required this.result,
    required this.cachedAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class CompressionResult {
  final bool success;
  final int filesProcessed;
  final int totalInputSize;
  final int outputSize;
  final double compressionRatio;
  final String outputPath;
  final String? error;

  CompressionResult({
    required this.success,
    required this.filesProcessed,
    required this.totalInputSize,
    required this.outputSize,
    required this.compressionRatio,
    required this.outputPath,
    this.error,
  });
}

class ExtractionResult {
  final bool success;
  final int filesExtracted;
  final int totalFiles;
  final String outputDirectory;
  final String? error;

  ExtractionResult({
    required this.success,
    required this.filesExtracted,
    required this.totalFiles,
    required this.outputDirectory,
    this.error,
  });
}

class DuplicateFilesResult {
  final List<DuplicateGroup> duplicateGroups;
  final int totalDuplicates;
  final int totalDuplicateFiles;
  final DuplicateDetectionMethod method;

  DuplicateFilesResult({
    required this.duplicateGroups,
    required this.totalDuplicates,
    required this.totalDuplicateFiles,
    required this.method,
  });
}

class DuplicateGroup {
  final List<String> filePaths;
  final int fileCount;
  final int totalSize;

  DuplicateGroup({
    required this.filePaths,
    required this.fileCount,
    required this.totalSize,
  });
}

class FilePreviewResult {
  final String filePath;
  final PreviewType type;
  final Uint8List? thumbnailData;
  final FileMetadata? metadata;
  final String? mimeType;

  FilePreviewResult({
    required this.filePath,
    required this.type,
    this.thumbnailData,
    this.metadata,
    this.mimeType,
  });
}

class FileMetadata {
  final String path;
  final int size;
  final DateTime modified;
  final DateTime created;
  final String? mimeType;
  final String extension;
  final bool isReadable;
  final bool isWritable;

  FileMetadata({
    required this.path,
    required this.size,
    required this.modified,
    required this.created,
    this.mimeType,
    required this.extension,
    required this.isReadable,
    required this.isWritable,
  });
}

class DirectorySyncResult {
  final String sourceDirectory;
  final String targetDirectory;
  final int filesCopied;
  final int filesDeleted;
  final int conflictsResolved;
  final SyncMode syncMode;
  final Duration duration;

  DirectorySyncResult({
    required this.sourceDirectory,
    required this.targetDirectory,
    required this.filesCopied,
    required this.filesDeleted,
    required this.conflictsResolved,
    required this.syncMode,
    required this.duration,
  });
}

class FileSystemAnalysis {
  final String directory;
  final int totalFiles;
  final int totalSize;
  final Map<String, int> fileTypes;
  final Map<String, int> sizeDistribution;
  final List<FileInfo> largestFiles;
  final List<FileInfo> oldestFiles;
  final List<FileInfo> recentlyModified;

  FileSystemAnalysis({
    required this.directory,
    required this.totalFiles,
    required this.totalSize,
    required this.fileTypes,
    required this.sizeDistribution,
    required this.largestFiles,
    required this.oldestFiles,
    required this.recentlyModified,
  });
}

class FileInfo {
  final String path;
  final int size;
  final DateTime modified;

  FileInfo({
    required this.path,
    required this.size,
    required this.modified,
  });
}

class OperationStatus {
  final String operationId;
  final OperationType type;
  final OperationStatusType status;
  final DateTime? startTime;
  final BatchProgress? progress;

  OperationStatus({
    required this.operationId,
    required this.type,
    required this.status,
    this.startTime,
    this.progress,
  });
}

class FileIndex {
  final String directory;
  final Map<String, IndexedFile> files;
  final DateTime lastIndexed;

  FileIndex({
    required this.directory,
    required this.files,
    required this.lastIndexed,
  });
}

class IndexedFile {
  final String path;
  final String hash;
  final int size;
  final DateTime modified;

  IndexedFile({
    required this.path,
    required this.hash,
    required this.size,
    required this.modified,
  });
}

class CompressionProfile {
  final String name;
  final CompressionFormat format;
  final CompressionLevel level;
  final String description;

  CompressionProfile({
    required this.name,
    required this.format,
    required this.level,
    required this.description,
  });
}

/// Enums

enum BatchOperationType {
  copy,
  move,
  delete,
  rename,
}

enum CompressionFormat {
  zip,
  tar,
  tarGz,
  sevenZip,
}

enum CompressionLevel {
  fast,
  normal,
  maximum,
}

enum DuplicateDetectionMethod {
  contentHash,
  metadataHash,
  nameHash,
}

enum PreviewType {
  thumbnail,
  icon,
  metadata,
}

enum SyncMode {
  unidirectional,
  bidirectional,
  mirror,
}

enum ConflictResolutionStrategy {
  lastWriteWins,
  manual,
  merge,
}

enum OperationType {
  single,
  batch,
  unknown,
}

enum OperationStatusType {
  notFound,
  queued,
  running,
  completed,
  failed,
  cancelled,
}

/// Progress classes

class DuplicateProgress {
  final int filesScanned;
  final int duplicatesFound;
  final String currentFile;

  DuplicateProgress({
    required this.filesScanned,
    required this.duplicatesFound,
    required this.currentFile,
  });
}

class SyncProgress {
  final String phase;
  final int completed;
  final int total;
  final String currentFile;

  SyncProgress({
    required this.phase,
    required this.completed,
    required this.total,
    required this.currentFile,
  });

  double get progressPercentage => total > 0 ? completed / total : 0.0;
}

class AnalysisProgress {
  final int filesProcessed;
  final String currentFile;

  AnalysisProgress({
    required this.filesProcessed,
    required this.currentFile,
  });
}

/// Event classes

class FileOperationEvent {
  final FileOperationEventType type;
  final DateTime timestamp;
  final String? operationId;
  final String? details;
  final String? error;

  FileOperationEvent({
    required this.type,
    required this.timestamp,
    this.operationId,
    this.details,
    this.error,
  });
}

/// Event types

enum FileOperationEventType {
  serviceInitialized,
  initializationFailed,
  batchStarted,
  batchCompleted,
  batchFailed,
  batchCancelled,
  searchStarted,
  searchCompleted,
  searchFailed,
  compressionStarted,
  compressionCompleted,
  compressionFailed,
  extractionStarted,
  extractionCompleted,
  extractionFailed,
  duplicateSearchStarted,
  duplicateSearchCompleted,
  duplicateSearchFailed,
  previewGenerationStarted,
  previewGenerationCompleted,
  previewGenerationFailed,
  syncStarted,
  syncCompleted,
  syncFailed,
  analysisStarted,
  analysisCompleted,
  analysisFailed,
  operationStarted,
  operationCompleted,
  operationFailed,
  operationCancelled,
}

/// Exception class

class FileOperationException implements Exception {
  final String message;

  FileOperationException(this.message);

  @override
  String toString() => 'FileOperationException: $message';
}
