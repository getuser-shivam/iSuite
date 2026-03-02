import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import '../config/central_config.dart';
import '../logging/logging_service.dart';
import '../enhanced_error_handling_service.dart';
import '../free_database_service.dart';
import '../free_cloud_storage_service.dart';

/// Backup and Restore Service
///
/// Provides comprehensive backup and restore capabilities for iSuite:
/// - Automated scheduled backups
/// - Manual backup creation
/// - Incremental and full backups
/// - Cloud storage integration
/// - Backup encryption and compression
/// - Restore from multiple sources
/// - Backup verification and integrity checks
/// - Retention policy management
class BackupRestoreService {
  static const String _configPrefix = 'backup_restore';
  static const String _defaultEnabled = 'backup_restore.enabled';
  static const String _defaultScheduleEnabled = 'backup_restore.schedule_enabled';
  static const String _defaultScheduleInterval = 'backup_restore.schedule_interval_hours';
  static const String _defaultRetentionDays = 'backup_restore.retention_days';
  static const String _defaultCompressionEnabled = 'backup_restore.compression_enabled';
  static const String _defaultEncryptionEnabled = 'backup_restore.encryption_enabled';

  final LoggingService _loggingService;
  final CentralConfig _centralConfig;
  final EnhancedErrorHandlingService _errorHandlingService;
  final FreeDatabaseService? _databaseService;
  final FreeCloudStorageService? _cloudStorageService;

  Timer? _backupTimer;
  final Map<String, BackupOperation> _activeOperations = {};
  final StreamController<BackupEvent> _backupController = StreamController.broadcast();

  bool _isInitialized = false;

  BackupRestoreService({
    LoggingService? loggingService,
    CentralConfig? centralConfig,
    EnhancedErrorHandlingService? errorHandlingService,
    FreeDatabaseService? databaseService,
    FreeCloudStorageService? cloudStorageService,
  }) : _loggingService = loggingService ?? LoggingService(),
       _centralConfig = centralConfig ?? CentralConfig.instance,
       _errorHandlingService = errorHandlingService ?? EnhancedErrorHandlingService(),
       _databaseService = databaseService,
       _cloudStorageService = cloudStorageService;

  /// Initialize the backup and restore service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _loggingService.info('Initializing Backup and Restore Service', 'BackupRestoreService');

      // Register with CentralConfig
      await _centralConfig.registerComponent(
        'BackupRestoreService',
        '1.0.0',
        'Comprehensive backup and restore capabilities for iSuite',
        dependencies: ['CentralConfig', 'LoggingService', 'EnhancedErrorHandlingService'],
        parameters: {
          _defaultEnabled: true,
          _defaultScheduleEnabled: true,
          _defaultScheduleInterval: 24, // hours
          _defaultRetentionDays: 30,
          _defaultCompressionEnabled: true,
          _defaultEncryptionEnabled: false, // Disabled by default for simplicity
          'backup_restore.backup_location': 'backups',
          'backup_restore.include_databases': true,
          'backup_restore.include_files': true,
          'backup_restore.include_settings': true,
          'backup_restore.include_logs': false,
          'backup_restore.max_concurrent_backups': 2,
          'backup_restore.cloud_backup_enabled': false,
          'backup_restore.verify_backups': true,
        }
      );

      // Create backup directory
      await _ensureBackupDirectory();

      // Start scheduled backups
      if (enabled && scheduleEnabled) {
        _startScheduledBackups();
      }

      _isInitialized = true;
      _loggingService.info('Backup and Restore Service initialized successfully', 'BackupRestoreService');

    } catch (e, stackTrace) {
      _loggingService.error('Failed to initialize Backup and Restore Service', 'BackupRestoreService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Configuration getters
  bool get enabled => _centralConfig.getParameter(_defaultEnabled, defaultValue: true);
  bool get scheduleEnabled => _centralConfig.getParameter(_defaultScheduleEnabled, defaultValue: true);
  Duration get scheduleInterval => Duration(hours: _centralConfig.getParameter(_defaultScheduleInterval, defaultValue: 24));
  int get retentionDays => _centralConfig.getParameter(_defaultRetentionDays, defaultValue: 30);
  bool get compressionEnabled => _centralConfig.getParameter(_defaultCompressionEnabled, defaultValue: true);
  bool get encryptionEnabled => _centralConfig.getParameter(_defaultEncryptionEnabled, defaultValue: false);
  String get backupLocation => _centralConfig.getParameter('backup_restore.backup_location', defaultValue: 'backups');
  bool get includeDatabases => _centralConfig.getParameter('backup_restore.include_databases', defaultValue: true);
  bool get includeFiles => _centralConfig.getParameter('backup_restore.include_files', defaultValue: true);
  bool get includeSettings => _centralConfig.getParameter('backup_restore.include_settings', defaultValue: true);
  bool get includeLogs => _centralConfig.getParameter('backup_restore.include_logs', defaultValue: false);
  int get maxConcurrentBackups => _centralConfig.getParameter('backup_restore.max_concurrent_backups', defaultValue: 2);
  bool get cloudBackupEnabled => _centralConfig.getParameter('backup_restore.cloud_backup_enabled', defaultValue: false);
  bool get verifyBackups => _centralConfig.getParameter('backup_restore.verify_backups', defaultValue: true);

  /// Create a manual backup
  Future<BackupResult> createBackup({
    String? name,
    BackupType type = BackupType.full,
    bool includeCloud = true,
    Map<String, dynamic>? options,
  }) async {
    final backupId = name ?? 'backup_${DateTime.now().millisecondsSinceEpoch}';
    final operation = BackupOperation(
      id: backupId,
      type: BackupOperationType.backup,
      status: BackupStatus.inProgress,
      startTime: DateTime.now(),
    );

    _activeOperations[backupId] = operation;

    try {
      _loggingService.info('Starting backup: $backupId (type: $type)', 'BackupRestoreService');
      _emitEvent(BackupEvent(type: BackupEventType.backupStarted, operationId: backupId));

      // Check concurrent backup limit
      if (_activeOperations.values.where((op) => op.type == BackupOperationType.backup).length >= maxConcurrentBackups) {
        throw Exception('Maximum concurrent backups exceeded');
      }

      final result = await _performBackup(backupId, type, options ?? {});

      operation.status = result.success ? BackupStatus.completed : BackupStatus.failed;
      operation.endTime = DateTime.now();
      operation.result = result;

      if (result.success && includeCloud && cloudBackupEnabled) {
        await _uploadToCloud(result.backupPath);
      }

      _emitEvent(BackupEvent(
        type: result.success ? BackupEventType.backupCompleted : BackupEventType.backupFailed,
        operationId: backupId,
        result: result,
      ));

      _loggingService.info('Backup $backupId completed: ${result.success ? 'SUCCESS' : 'FAILED'}', 'BackupRestoreService');

      return result;

    } catch (e, stackTrace) {
      operation.status = BackupStatus.failed;
      operation.endTime = DateTime.now();
      operation.error = e.toString();

      _emitEvent(BackupEvent(
        type: BackupEventType.backupFailed,
        operationId: backupId,
        error: e.toString(),
      ));

      _loggingService.error('Backup $backupId failed', 'BackupRestoreService', error: e, stackTrace: stackTrace);

      return BackupResult.failure(
        backupId: backupId,
        error: e.toString(),
        duration: operation.duration!,
      );

    } finally {
      _activeOperations.remove(backupId);
    }
  }

  /// Restore from backup
  Future<RestoreResult> restoreFromBackup({
    required String backupPath,
    RestoreOptions? options,
  }) async {
    final operationId = 'restore_${DateTime.now().millisecondsSinceEpoch}';
    final operation = BackupOperation(
      id: operationId,
      type: BackupOperationType.restore,
      status: BackupStatus.inProgress,
      startTime: DateTime.now(),
    );

    _activeOperations[operationId] = operation;

    try {
      _loggingService.info('Starting restore from: $backupPath', 'BackupRestoreService');
      _emitEvent(BackupEvent(type: BackupEventType.restoreStarted, operationId: operationId));

      final result = await _performRestore(backupPath, options ?? RestoreOptions());

      operation.status = result.success ? BackupStatus.completed : BackupStatus.failed;
      operation.endTime = DateTime.now();
      operation.result = result;

      _emitEvent(BackupEvent(
        type: result.success ? BackupEventType.restoreCompleted : BackupEventType.restoreFailed,
        operationId: operationId,
        result: result,
      ));

      _loggingService.info('Restore completed: ${result.success ? 'SUCCESS' : 'FAILED'}', 'BackupRestoreService');

      return result;

    } catch (e, stackTrace) {
      operation.status = BackupStatus.failed;
      operation.endTime = DateTime.now();
      operation.error = e.toString();

      _emitEvent(BackupEvent(
        type: BackupEventType.restoreFailed,
        operationId: operationId,
        error: e.toString(),
      ));

      _loggingService.error('Restore failed', 'BackupRestoreService', error: e, stackTrace: stackTrace);

      return RestoreResult.failure(
        error: e.toString(),
        duration: operation.duration!,
      );

    } finally {
      _activeOperations.remove(operationId);
    }
  }

  /// Perform the actual backup operation
  Future<BackupResult> _performBackup(String backupId, BackupType type, Map<String, dynamic> options) async {
    final startTime = DateTime.now();
    final backupDir = await _getBackupDirectory();
    final backupPath = path.join(backupDir, '$backupId.zip');

    try {
      final archive = Archive();

      // Include databases
      if (includeDatabases) {
        await _addDatabasesToArchive(archive, type);
      }

      // Include files
      if (includeFiles) {
        await _addFilesToArchive(archive, type);
      }

      // Include settings
      if (includeSettings) {
        await _addSettingsToArchive(archive);
      }

      // Include logs (if enabled)
      if (includeLogs) {
        await _addLogsToArchive(archive);
      }

      // Add metadata
      await _addMetadataToArchive(archive, backupId, type, startTime);

      // Compress and save
      final compressed = compressionEnabled ? _compressArchive(archive) : archive;
      await _saveArchive(compressed, backupPath);

      // Encrypt if enabled
      if (encryptionEnabled) {
        await _encryptBackup(backupPath);
      }

      // Verify backup
      final size = await _getFileSize(backupPath);
      if (verifyBackups) {
        await _verifyBackup(backupPath, archive);
      }

      final duration = DateTime.now().difference(startTime);

      return BackupResult.success(
        backupId: backupId,
        backupPath: backupPath,
        type: type,
        size: size,
        duration: duration,
        fileCount: archive.length,
      );

    } catch (e) {
      // Clean up failed backup
      try {
        final file = File(backupPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}

      throw e;
    }
  }

  /// Perform the actual restore operation
  Future<RestoreResult> _performRestore(String backupPath, RestoreOptions options) async {
    final startTime = DateTime.now();

    try {
      // Verify backup file exists
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw Exception('Backup file not found: $backupPath');
      }

      // Decrypt if needed
      final decryptedPath = encryptionEnabled ? await _decryptBackup(backupPath) : backupPath;

      // Load and decompress archive
      final archive = await _loadArchive(decryptedPath);

      // Verify archive integrity
      if (verifyBackups) {
        await _verifyArchiveIntegrity(archive);
      }

      // Extract files
      int filesRestored = 0;

      for (final file in archive) {
        if (file.isFile) {
          final shouldRestore = options.shouldRestoreFile(file.name);
          if (shouldRestore) {
            await _restoreFile(file, options.overwriteExisting);
            filesRestored++;
          }
        }
      }

      // Clean up decrypted file if it was temporary
      if (decryptedPath != backupPath) {
        try {
          await File(decryptedPath).delete();
        } catch (_) {}
      }

      final duration = DateTime.now().difference(startTime);

      return RestoreResult.success(
        filesRestored: filesRestored,
        duration: duration,
      );

    } catch (e) {
      throw e;
    }
  }

  /// Add databases to archive
  Future<void> _addDatabasesToArchive(Archive archive, BackupType type) async {
    if (_databaseService == null) return;

    final databases = await _databaseService!.getDatabaseNames();

    for (final dbName in databases) {
      try {
        final dbPath = await _databaseService!.getDatabasePath(dbName);
        if (dbPath != null) {
          final dbFile = File(dbPath);
          if (await dbFile.exists()) {
            final bytes = await dbFile.readAsBytes();
            final archiveFile = ArchiveFile('databases/$dbName.db', bytes.length, bytes);
            archive.addFile(archiveFile);
          }
        }
      } catch (e) {
        _loggingService.warning('Failed to backup database $dbName: ${e.toString()}', 'BackupRestoreService');
      }
    }
  }

  /// Add files to archive
  Future<void> _addFilesToArchive(Archive archive, BackupType type) async {
    // Add documents, images, and other user files
    final directories = [
      'documents',
      'images',
      'downloads',
      'cache',
    ];

    for (final dir in directories) {
      try {
        final dirPath = path.join(await _getAppDirectory(), dir);
        final directory = Directory(dirPath);

        if (await directory.exists()) {
          await for (final file in directory.list(recursive: true)) {
            if (file is File) {
              final relativePath = path.relative(file.path, from: await _getAppDirectory());
              final bytes = await file.readAsBytes();
              final archiveFile = ArchiveFile('files/$relativePath', bytes.length, bytes);
              archive.addFile(archiveFile);
            }
          }
        }
      } catch (e) {
        _loggingService.warning('Failed to backup directory $dir: ${e.toString()}', 'BackupRestoreService');
      }
    }
  }

  /// Add settings to archive
  Future<void> _addSettingsToArchive(Archive archive) async {
    try {
      // Add CentralConfig settings
      final settings = _centralConfig.getAllParameters();
      final settingsJson = jsonEncode(settings);
      final bytes = utf8.encode(settingsJson);
      final archiveFile = ArchiveFile('settings/config.json', bytes.length, bytes);
      archive.addFile(archiveFile);
    } catch (e) {
      _loggingService.warning('Failed to backup settings: ${e.toString()}', 'BackupRestoreService');
    }
  }

  /// Add logs to archive
  Future<void> _addLogsToArchive(Archive archive) async {
    try {
      final logDir = await _getLogDirectory();
      final directory = Directory(logDir);

      if (await directory.exists()) {
        await for (final file in directory.list()) {
          if (file is File && file.path.endsWith('.log')) {
            final bytes = await file.readAsBytes();
            final fileName = path.basename(file.path);
            final archiveFile = ArchiveFile('logs/$fileName', bytes.length, bytes);
            archive.addFile(archiveFile);
          }
        }
      }
    } catch (e) {
      _loggingService.warning('Failed to backup logs: ${e.toString()}', 'BackupRestoreService');
    }
  }

  /// Add metadata to archive
  Future<void> _addMetadataToArchive(Archive archive, String backupId, BackupType type, DateTime startTime) async {
    final metadata = {
      'backup_id': backupId,
      'type': type.toString(),
      'timestamp': startTime.toIso8601String(),
      'platform': Platform.operatingSystem,
      'version': '1.0.0', // Would come from app version
      'compression': compressionEnabled,
      'encryption': encryptionEnabled,
    };

    final metadataJson = jsonEncode(metadata);
    final bytes = utf8.encode(metadataJson);
    final archiveFile = ArchiveFile('metadata.json', bytes.length, bytes);
    archive.addFile(archiveFile);
  }

  /// Compress archive
  Archive _compressArchive(Archive archive) {
    final encoder = ZipEncoder();
    final compressed = Archive();

    for (final file in archive) {
      if (file.isFile) {
        final compressedData = encoder.encode(file.getContent() as List<int>);
        final compressedFile = ArchiveFile(file.name, compressedData.length, compressedData);
        compressed.addFile(compressedFile);
      }
    }

    return compressed;
  }

  /// Save archive to file
  Future<void> _saveArchive(Archive archive, String filePath) async {
    final encoder = ZipEncoder();
    final bytes = encoder.encode(archive);
    final file = File(filePath);
    await file.writeAsBytes(bytes);
  }

  /// Load archive from file
  Future<Archive> _loadArchive(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final decoder = ZipDecoder();
    return decoder.decodeBytes(bytes);
  }

  /// Encrypt backup
  Future<void> _encryptBackup(String filePath) async {
    // Simple encryption using a key from config
    // In production, use proper encryption
    final key = _centralConfig.getParameter('backup_restore.encryption_key', defaultValue: 'default_key');
    final keyBytes = utf8.encode(key);

    final file = File(filePath);
    final bytes = await file.readAsBytes();

    // Simple XOR encryption (not secure, replace with proper encryption)
    final encrypted = <int>[];
    for (int i = 0; i < bytes.length; i++) {
      encrypted.add(bytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    await file.writeAsBytes(encrypted);
  }

  /// Decrypt backup
  Future<String> _decryptBackup(String filePath) async {
    final key = _centralConfig.getParameter('backup_restore.encryption_key', defaultValue: 'default_key');
    final keyBytes = utf8.encode(key);

    final file = File(filePath);
    final bytes = await file.readAsBytes();

    // Decrypt
    final decrypted = <int>[];
    for (int i = 0; i < bytes.length; i++) {
      decrypted.add(bytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    // Save to temporary file
    final tempPath = '${filePath}.decrypted';
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(decrypted);

    return tempPath;
  }

  /// Verify backup integrity
  Future<void> _verifyBackup(String backupPath, Archive originalArchive) async {
    try {
      final loadedArchive = await _loadArchive(backupPath);

      if (loadedArchive.length != originalArchive.length) {
        throw Exception('Archive file count mismatch');
      }

      // Verify metadata exists
      final metadataFile = loadedArchive.findFile('metadata.json');
      if (metadataFile == null) {
        throw Exception('Metadata file missing from backup');
      }

    } catch (e) {
      throw Exception('Backup verification failed: ${e.toString()}');
    }
  }

  /// Verify archive integrity
  Future<void> _verifyArchiveIntegrity(Archive archive) async {
    // Check for metadata
    final metadataFile = archive.findFile('metadata.json');
    if (metadataFile == null) {
      throw Exception('Invalid backup: metadata missing');
    }

    // Parse metadata
    try {
      final metadataContent = utf8.decode(metadataFile.content as List<int>);
      final metadata = jsonDecode(metadataContent) as Map<String, dynamic>;

      // Verify required fields
      final requiredFields = ['backup_id', 'timestamp', 'type'];
      for (final field in requiredFields) {
        if (!metadata.containsKey(field)) {
          throw Exception('Invalid backup metadata: missing $field');
        }
      }

    } catch (e) {
      throw Exception('Invalid backup metadata: ${e.toString()}');
    }
  }

  /// Restore individual file
  Future<void> _restoreFile(ArchiveFile file, bool overwrite) async {
    final targetPath = path.join(await _getAppDirectory(), file.name);
    final targetFile = File(targetPath);

    // Check if file exists and overwrite policy
    if (await targetFile.exists() && !overwrite) {
      return; // Skip existing files
    }

    // Ensure directory exists
    final dir = Directory(path.dirname(targetPath));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Write file
    await targetFile.writeAsBytes(file.content as List<int>);
  }

  /// Upload backup to cloud
  Future<void> _uploadToCloud(String backupPath) async {
    if (_cloudStorageService == null) return;

    try {
      final fileName = path.basename(backupPath);
      await _cloudStorageService!.uploadFile(
        localPath: backupPath,
        remotePath: 'backups/$fileName',
      );

      _loggingService.info('Backup uploaded to cloud: $fileName', 'BackupRestoreService');

    } catch (e) {
      _loggingService.warning('Failed to upload backup to cloud: ${e.toString()}', 'BackupRestoreService');
    }
  }

  /// Get list of available backups
  Future<List<BackupInfo>> getAvailableBackups() async {
    final backupDir = await _getBackupDirectory();
    final directory = Directory(backupDir);

    if (!await directory.exists()) {
      return [];
    }

    final backups = <BackupInfo>[];

    await for (final file in directory.list()) {
      if (file is File && file.path.endsWith('.zip')) {
        try {
          final info = await _getBackupInfo(file.path);
          if (info != null) {
            backups.add(info);
          }
        } catch (e) {
          _loggingService.warning('Failed to read backup info for ${file.path}: ${e.toString()}', 'BackupRestoreService');
        }
      }
    }

    // Sort by creation time (newest first)
    backups.sort((a, b) => b.created.compareTo(a.created));

    return backups;
  }

  /// Get backup information
  Future<BackupInfo?> _getBackupInfo(String backupPath) async {
    try {
      final file = File(backupPath);
      final stat = await file.stat();

      // Try to read metadata
      final archive = await _loadArchive(backupPath);
      final metadataFile = archive.findFile('metadata.json');

      if (metadataFile != null) {
        final metadataContent = utf8.decode(metadataFile.content as List<int>);
        final metadata = jsonDecode(metadataContent) as Map<String, dynamic>;

        return BackupInfo(
          id: metadata['backup_id'] ?? path.basenameWithoutExtension(backupPath),
          path: backupPath,
          type: BackupType.values.firstWhere(
            (t) => t.toString() == metadata['type'],
            orElse: () => BackupType.full,
          ),
          created: DateTime.parse(metadata['timestamp']),
          size: stat.size,
          compressed: metadata['compression'] ?? false,
          encrypted: metadata['encryption'] ?? false,
        );
      }

      // Fallback for backups without metadata
      return BackupInfo(
        id: path.basenameWithoutExtension(backupPath),
        path: backupPath,
        type: BackupType.full,
        created: stat.modified,
        size: stat.size,
        compressed: false,
        encrypted: false,
      );

    } catch (e) {
      return null;
    }
  }

  /// Clean up old backups based on retention policy
  Future<void> cleanupOldBackups() async {
    try {
      final backups = await getAvailableBackups();
      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));

      int deletedCount = 0;
      for (final backup in backups) {
        if (backup.created.isBefore(cutoffDate)) {
          try {
            await File(backup.path).delete();
            deletedCount++;
          } catch (e) {
            _loggingService.warning('Failed to delete old backup ${backup.id}: ${e.toString()}', 'BackupRestoreService');
          }
        }
      }

      if (deletedCount > 0) {
        _loggingService.info('Cleaned up $deletedCount old backups', 'BackupRestoreService');
      }

    } catch (e) {
      _loggingService.error('Failed to cleanup old backups', 'BackupRestoreService', error: e);
    }
  }

  /// Get backup directory
  Future<String> _getBackupDirectory() async {
    final appDir = await _getAppDirectory();
    final backupDir = path.join(appDir, backupLocation);
    await Directory(backupDir).create(recursive: true);
    return backupDir;
  }

  /// Get app directory
  Future<String> _getAppDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return appDir.path;
  }

  /// Get log directory
  Future<String> _getLogDirectory() async {
    final appDir = await _getAppDirectory();
    return path.join(appDir, 'logs');
  }

  /// Ensure backup directory exists
  Future<void> _ensureBackupDirectory() async {
    final backupDir = await _getBackupDirectory();
    await Directory(backupDir).create(recursive: true);
  }

  /// Get file size
  Future<int> _getFileSize(String filePath) async {
    final file = File(filePath);
    final stat = await file.stat();
    return stat.size;
  }

  /// Start scheduled backups
  void _startScheduledBackups() {
    _backupTimer = Timer.periodic(scheduleInterval, (_) async {
      try {
        await createBackup(type: BackupType.full);
        await cleanupOldBackups();
      } catch (e) {
        _loggingService.error('Scheduled backup failed', 'BackupRestoreService', error: e);
      }
    });

    _loggingService.info('Scheduled backups started', 'BackupRestoreService');
  }

  /// Get active operations
  Map<String, BackupOperation> getActiveOperations() {
    return Map.from(_activeOperations);
  }

  /// Cancel operation
  Future<void> cancelOperation(String operationId) async {
    final operation = _activeOperations[operationId];
    if (operation != null) {
      operation.status = BackupStatus.cancelled;
      _activeOperations.remove(operationId);
      _emitEvent(BackupEvent(type: BackupEventType.operationCancelled, operationId: operationId));
    }
  }

  /// Emit backup event
  void _emitEvent(BackupEvent event) {
    _backupController.add(event);
  }

  /// Get backup event stream
  Stream<BackupEvent> get backupEvents => _backupController.stream;

  /// Dispose resources
  void dispose() {
    _backupTimer?.cancel();
    _backupController.close();
    _loggingService.info('Backup and restore service disposed', 'BackupRestoreService');
  }
}

/// Backup Types
enum BackupType {
  full,
  incremental,
  differential,
}

/// Backup Status
enum BackupStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled,
}

/// Backup Operation Types
enum BackupOperationType {
  backup,
  restore,
}

/// Backup Operation
class BackupOperation {
  final String id;
  final BackupOperationType type;
  BackupStatus status;
  final DateTime startTime;
  DateTime? endTime;
  dynamic result;
  String? error;

  BackupOperation({
    required this.id,
    required this.type,
    required this.status,
    required this.startTime,
    this.endTime,
    this.result,
    this.error,
  });

  Duration? get duration => endTime != null ? endTime!.difference(startTime) : null;
}

/// Backup Result
class BackupResult {
  final bool success;
  final String backupId;
  final String? backupPath;
  final BackupType? type;
  final int? size;
  final Duration? duration;
  final int? fileCount;
  final String? error;

  BackupResult._({
    required this.success,
    this.backupId = '',
    this.backupPath,
    this.type,
    this.size,
    this.duration,
    this.fileCount,
    this.error,
  });

  factory BackupResult.success({
    required String backupId,
    required String backupPath,
    required BackupType type,
    required int size,
    required Duration duration,
    required int fileCount,
  }) {
    return BackupResult._(
      success: true,
      backupId: backupId,
      backupPath: backupPath,
      type: type,
      size: size,
      duration: duration,
      fileCount: fileCount,
    );
  }

  factory BackupResult.failure({
    required String backupId,
    required String error,
    required Duration duration,
  }) {
    return BackupResult._(
      success: false,
      backupId: backupId,
      error: error,
      duration: duration,
    );
  }
}

/// Restore Result
class RestoreResult {
  final bool success;
  final int? filesRestored;
  final Duration? duration;
  final String? error;

  RestoreResult._({
    required this.success,
    this.filesRestored,
    this.duration,
    this.error,
  });

  factory RestoreResult.success({
    required int filesRestored,
    required Duration duration,
  }) {
    return RestoreResult._(
      success: true,
      filesRestored: filesRestored,
      duration: duration,
    );
  }

  factory RestoreResult.failure({
    required String error,
    required Duration duration,
  }) {
    return RestoreResult._(
      success: false,
      error: error,
      duration: duration,
    );
  }
}

/// Restore Options
class RestoreOptions {
  final bool overwriteExisting;
  final Set<String> includePatterns;
  final Set<String> excludePatterns;

  RestoreOptions({
    this.overwriteExisting = true,
    this.includePatterns = const {},
    this.excludePatterns = const {},
  });

  bool shouldRestoreFile(String filePath) {
    // Check exclude patterns first
    for (final pattern in excludePatterns) {
      if (filePath.contains(pattern)) {
        return false;
      }
    }

    // Check include patterns (if specified)
    if (includePatterns.isNotEmpty) {
      for (final pattern in includePatterns) {
        if (filePath.contains(pattern)) {
          return true;
        }
      }
      return false; // Not in include patterns
    }

    return true; // Include by default
  }
}

/// Backup Info
class BackupInfo {
  final String id;
  final String path;
  final BackupType type;
  final DateTime created;
  final int size;
  final bool compressed;
  final bool encrypted;

  BackupInfo({
    required this.id,
    required this.path,
    required this.type,
    required this.created,
    required this.size,
    required this.compressed,
    required this.encrypted,
  });

  String get sizeFormatted {
    const units = ['B', 'KB', 'MB', 'GB'];
    int unitIndex = 0;
    double sizeValue = size.toDouble();

    while (sizeValue >= 1024 && unitIndex < units.length - 1) {
      sizeValue /= 1024;
      unitIndex++;
    }

    return '${sizeValue.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  @override
  String toString() {
    return 'BackupInfo(id: $id, type: $type, created: $created, size: $sizeFormatted)';
  }
}

/// Backup Event Types
enum BackupEventType {
  backupStarted,
  backupCompleted,
  backupFailed,
  restoreStarted,
  restoreCompleted,
  restoreFailed,
  operationCancelled,
  cleanupCompleted,
}

/// Backup Event
class BackupEvent {
  final BackupEventType type;
  final DateTime timestamp;
  final String? operationId;
  final dynamic result;
  final String? error;

  BackupEvent({
    required this.type,
    this.operationId,
    this.result,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'BackupEvent(type: $type, operationId: $operationId)';
  }
}
