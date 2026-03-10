import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import '../../core/central_config.dart';
import '../../core/logging/logging_service.dart';

/// Network File Synchronization Service
/// Provides automatic file synchronization across network devices
class NetworkFileSyncService {
  static final NetworkFileSyncService _instance =
      NetworkFileSyncService._internal();
  factory NetworkFileSyncService() => _instance;
  NetworkFileSyncService._internal();

  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();

  bool _isInitialized = false;
  final Map<String, SyncSession> _activeSyncs = {};
  final StreamController<SyncEvent> _syncEventController =
      StreamController.broadcast();
  final List<OfflineSyncOperation> _offlineQueue = [];
  Timer? _offlineRetryTimer;

  Stream<SyncEvent> get syncEvents => _syncEventController.stream;

  /// Initialize sync service with offline support
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info(
          'Initializing Network File Sync Service with offline support',
          'NetworkFileSyncService');

      // Register with CentralConfig
      await _config.registerComponent('NetworkFileSyncService', '1.0.0',
          'Automatic file synchronization with offline support',
          parameters: {
            'sync_interval': 300, // 5 minutes
            'max_sync_sessions': 5,
            'enable_offline_support': true,
            'offline_queue_max_size': 1000,
            'auto_retry_offline_sync': true,
            'offline_sync_retry_interval': 60, // 1 minute
          });

      // Initialize offline queue
      await _initializeOfflineQueue();

      // Load pending offline syncs
      await _loadPendingOfflineSyncs();

      _isInitialized = true;
      _logger.info('Network File Sync Service initialized successfully',
          'NetworkFileSyncService');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Network File Sync Service',
          'NetworkFileSyncService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Create sync session with offline support
  Future<String> createSyncSession({
    required String localPath,
    required String remoteIP,
    required String remotePath,
    required int remotePort,
    SyncDirection direction = SyncDirection.bidirectional,
    bool enableAutoSync = true,
    Duration? syncInterval,
    int maxRetries = 3,
    bool enableOfflineSupport = true,
  }) async {
    if (!_isInitialized) await initialize();

    // Validate input parameters
    _validateSyncParameters(localPath, remoteIP, remotePort);

    final sessionId = _generateSessionId();
    final localDir = Directory(localPath);

    if (!await localDir.exists()) {
      throw SyncException('Local directory does not exist: $localPath',
          SyncErrorType.invalidLocalPath);
    }

    final session = SyncSession(
      id: sessionId,
      localPath: localPath,
      remoteIP: remoteIP,
      remotePath: remotePath,
      remotePort: remotePort,
      direction: direction,
      status: SyncStatus.idle,
      enableAutoSync: enableAutoSync,
      syncInterval: syncInterval ??
          Duration(
              seconds:
                  _config.getParameter('sync_interval', defaultValue: 300)),
      lastSyncTime: null,
      syncStats: SyncStats.empty(),
      maxRetries: maxRetries,
      enableOfflineSupport: enableOfflineSupport,
    );

    _activeSyncs[sessionId] = session;
    _emitSyncEvent(SyncEventType.sessionCreated, session: session);

    // Start auto sync if enabled
    if (enableAutoSync) {
      _startAutoSync(session);
    }

    _logger.info(
        'Created sync session: $sessionId between $localPath and $remoteIP:$remotePath',
        'NetworkFileSyncService');

    return sessionId;
  }

  /// Start sync with offline support
  Future<void> startSync(String sessionId) async {
    final session = _activeSyncs[sessionId];
    if (session == null) {
      throw SyncException(
          'Sync session not found: $sessionId', SyncErrorType.sessionNotFound);
    }

    if (session.status == SyncStatus.syncing) {
      throw SyncException('Sync already in progress for session: $sessionId',
          SyncErrorType.syncInProgress);
    }

    try {
      session.status = SyncStatus.syncing;
      _emitSyncEvent(SyncEventType.syncStarted, session: session);

      await _performSync(session);

      session.status = SyncStatus.idle;
      session.lastSyncTime = DateTime.now();
      _emitSyncEvent(SyncEventType.syncCompleted, session: session);
    } catch (e) {
      session.status = SyncStatus.error;
      session.lastError = e.toString();
      _emitSyncEvent(SyncEventType.syncFailed, session: session);
      _logger.error(
          'Sync failed for session $sessionId: $e', 'NetworkFileSyncService');

      // Handle offline scenario
      if (session.enableOfflineSupport && _isNetworkOffline(e)) {
        await _queueOfflineSync(session, e);
        session.status = SyncStatus.offline;
        _emitSyncEvent(SyncEventType.offlineQueued, session: session);
      } else {
        rethrow;
      }
    }
  }

  /// Process offline sync queue when network is restored
  Future<void> processOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;

    _logger.info(
        'Processing offline sync queue (${_offlineQueue.length} items)',
        'NetworkFileSyncService');

    final completedSessions = <String>[];
    final failedSessions = <String, String>{};

    for (final offlineSync in _offlineQueue) {
      try {
        final session = _activeSyncs[offlineSync.sessionId];
        if (session != null && session.enableOfflineSupport) {
          await startSync(offlineSync.sessionId);
          completedSessions.add(offlineSync.sessionId);
        }
      } catch (e) {
        failedSessions[offlineSync.sessionId] = e.toString();
        _logger.warning(
            'Offline sync failed for session ${offlineSync.sessionId}: $e',
            'NetworkFileSyncService');
      }
    }

    // Remove completed syncs from queue
    _offlineQueue
        .removeWhere((sync) => completedSessions.contains(sync.sessionId));

    // Update failed syncs
    for (final entry in failedSessions.entries) {
      final offlineSync =
          _offlineQueue.firstWhere((sync) => sync.sessionId == entry.key);
      offlineSync.retryCount++;
      offlineSync.lastError = entry.value;
    }

    // Save updated offline queue
    await _saveOfflineQueue();

    _logger.info(
        'Offline queue processing completed. Completed: ${completedSessions.length}, Failed: ${failedSessions.length}',
        'NetworkFileSyncService');
  }

  /// Queue sync operation for offline execution
  Future<void> _queueOfflineSync(SyncSession session, dynamic error) async {
    final offlineSync = OfflineSyncOperation(
      sessionId: session.id,
      timestamp: DateTime.now(),
      error: error.toString(),
      retryCount: 0,
    );

    _offlineQueue.add(offlineSync);
    await _saveOfflineQueue();

    _logger.info('Queued offline sync for session ${session.id}',
        'NetworkFileSyncService');

    // Start offline retry timer if not already running
    if (_offlineRetryTimer == null) {
      _startOfflineRetryTimer();
    }
  }

  /// Check if error indicates network is offline
  bool _isNetworkOffline(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('connection refused') ||
        errorString.contains('network unreachable') ||
        errorString.contains('timeout') ||
        errorString.contains('no route to host');
  }

  /// Start offline retry timer
  void _startOfflineRetryTimer() {
    final retryInterval = Duration(
        seconds: _config.getParameter('offline_sync_retry_interval',
            defaultValue: 60));

    _offlineRetryTimer = Timer.periodic(retryInterval, (timer) async {
      try {
        await processOfflineQueue();

        // Stop timer if queue is empty
        if (_offlineQueue.isEmpty) {
          timer.cancel();
          _offlineRetryTimer = null;
        }
      } catch (e) {
        _logger.error(
            'Error processing offline queue: $e', 'NetworkFileSyncService');
      }
    });
  }

  /// Initialize offline queue storage
  Future<void> _initializeOfflineQueue() async {
    // In a real implementation, this would initialize persistent storage for offline queue
    _logger.info('Offline queue initialized', 'NetworkFileSyncService');
  }

  /// Load pending offline syncs
  Future<void> _loadPendingOfflineSyncs() async {
    // In a real implementation, this would load from persistent storage
    _logger.info('Loaded pending offline syncs', 'NetworkFileSyncService');
  }

  /// Save offline queue to persistent storage
  Future<void> _saveOfflineQueue() async {
    // In a real implementation, this would save to persistent storage
    _logger.info('Offline queue saved (${_offlineQueue.length} items)',
        'NetworkFileSyncService');
  }

  /// Get offline queue status
  Map<String, dynamic> getOfflineQueueStatus() {
    return {
      'queue_size': _offlineQueue.length,
      'pending_sessions':
          _offlineQueue.map((sync) => sync.sessionId).toSet().length,
      'total_retry_count':
          _offlineQueue.fold(0, (sum, sync) => sum + sync.retryCount),
      'is_retry_timer_active': _offlineRetryTimer?.isActive ?? false,
    };
  }

  /// Clear offline queue
  Future<void> clearOfflineQueue() async {
    _offlineQueue.clear();
    await _saveOfflineQueue();
    _offlineRetryTimer?.cancel();
    _offlineRetryTimer = null;
    _logger.info('Offline queue cleared', 'NetworkFileSyncService');
  }

  /// Validate sync parameters
  void _validateSyncParameters(
      String localPath, String remoteIP, int remotePort) {
    // Local path validation
    if (localPath.trim().isEmpty) {
      throw SyncException(
          'Local path cannot be empty', SyncErrorType.invalidLocalPath);
    }

    final localDir = Directory(localPath);
    if (localDir.isAbsolute && !localPath.startsWith('/')) {
      // Additional validation for absolute paths
      if (!Platform.isWindows && !localPath.startsWith('/')) {
        throw SyncException(
            'Invalid local path format', SyncErrorType.invalidLocalPath);
      }
    }

    // Remote IP validation
    final ipRegex = RegExp(r'^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$');
    if (!ipRegex.hasMatch(remoteIP)) {
      throw SyncException(
          'Invalid remote IP address format', SyncErrorType.invalidRemoteHost);
    }

    // Port validation
    if (remotePort < 1 || remotePort > 65535) {
      throw SyncException(
          'Port must be between 1 and 65535', SyncErrorType.invalidRemoteHost);
    }
  }

  /// Perform sync with enhanced error handling and retry
  Future<void> _performSync(SyncSession session) async {
    int retryCount = 0;

    while (retryCount <= session.maxRetries) {
      try {
        final localFiles = await _getLocalFileManifest(session.localPath);
        final remoteFiles = await _getRemoteFileManifest(session);

        final changes = await _calculateSyncChanges(
          localFiles: localFiles,
          remoteFiles: remoteFiles,
          direction: session.direction,
        );

        // Apply changes with progress tracking
        int processed = 0;
        for (final change in changes) {
          try {
            await _applySyncChange(change, session);
            session.syncStats.filesSynced++;
            processed++;
            _emitSyncEvent(SyncEventType.fileSynced,
                session: session, filePath: change.filePath);
          } catch (e) {
            session.syncStats.errors++;
            _logger.warning('Failed to sync file ${change.filePath}: $e',
                'NetworkFileSyncService');

            // Continue with next file instead of failing entire sync
            if (retryCount >= session.maxRetries) {
              throw SyncException('Failed to sync file: ${change.filePath}',
                  SyncErrorType.syncFailed);
            }
          }
        }

        session.syncStats.totalSyncs++;
        session.syncStats.lastSyncDuration =
            DateTime.now().difference(session.lastSyncTime ?? DateTime.now());
        return; // Success
      } catch (e) {
        retryCount++;
        _logger.warning(
            'Sync attempt ${retryCount} failed for session ${session.id}: $e',
            'NetworkFileSyncService');

        if (retryCount <= session.maxRetries) {
          // Wait before retry with exponential backoff
          await Future.delayed(Duration(seconds: retryCount * 2));
        } else {
          // All retries exhausted
          throw SyncException('Sync failed after ${retryCount} attempts: $e',
              SyncErrorType.syncFailed);
        }
      }
    }
  }

  /// Start manual sync
  Future<void> startSync(String sessionId) async {
    final session = _activeSyncs[sessionId];
    if (session == null) {
      throw Exception('Sync session not found: $sessionId');
    }

    if (session.status == SyncStatus.syncing) {
      throw Exception('Sync already in progress for session: $sessionId');
    }

    try {
      session.status = SyncStatus.syncing;
      _emitSyncEvent(SyncEventType.syncStarted, session: session);

      await _performSync(session);

      session.status = SyncStatus.idle;
      session.lastSyncTime = DateTime.now();
      _emitSyncEvent(SyncEventType.syncCompleted, session: session);
    } catch (e) {
      session.status = SyncStatus.error;
      session.lastError = e.toString();
      _emitSyncEvent(SyncEventType.syncFailed, session: session);
      _logger.error(
          'Sync failed for session $sessionId', 'NetworkFileSyncService',
          error: e);
    }
  }

  /// Stop sync session
  Future<void> stopSyncSession(String sessionId) async {
    final session = _activeSyncs[sessionId];
    if (session != null) {
      session.status = SyncStatus.stopped;
      session.autoSyncTimer?.cancel();
      _emitSyncEvent(SyncEventType.sessionStopped, session: session);
      _activeSyncs.remove(sessionId);
    }
  }

  /// Perform synchronization
  Future<void> _performSync(SyncSession session) async {
    final localFiles = await _getLocalFileManifest(session.localPath);
    final remoteFiles = await _getRemoteFileManifest(session);

    final changes = await _calculateSyncChanges(
      localFiles: localFiles,
      remoteFiles: remoteFiles,
      direction: session.direction,
    );

    // Apply changes
    for (final change in changes) {
      try {
        await _applySyncChange(change, session);
        session.syncStats.filesSynced++;
        _emitSyncEvent(SyncEventType.fileSynced,
            session: session, filePath: change.filePath);
      } catch (e) {
        session.syncStats.errors++;
        _logger.warning('Failed to sync file ${change.filePath}: $e',
            'NetworkFileSyncService');
      }
    }

    session.syncStats.totalSyncs++;
    session.syncStats.lastSyncDuration =
        DateTime.now().difference(session.lastSyncTime ?? DateTime.now());
  }

  /// Get local file manifest
  Future<Map<String, FileInfo>> _getLocalFileManifest(String localPath) async {
    final manifest = <String, FileInfo>{};
    final dir = Directory(localPath);

    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final relativePath = entity.path.substring(localPath.length + 1);
        final stat = await entity.stat();
        final hash = await _calculateFileHash(entity);

        manifest[relativePath] = FileInfo(
          path: relativePath,
          size: stat.size,
          modified: stat.modified,
          hash: hash,
          isDirectory: false,
        );
      }
    }

    return manifest;
  }

  /// Get remote file manifest via network
  Future<Map<String, FileInfo>> _getRemoteFileManifest(
      SyncSession session) async {
    // This would connect to remote device and get file manifest
    // For now, return empty (placeholder for actual implementation)
    // In real implementation, this would use the file sharing service or direct network connection

    final manifest = <String, FileInfo>{};

    // Placeholder: simulate getting remote manifest
    // In real app, this would query the remote device

    return manifest;
  }

  /// Calculate sync changes
  Future<List<SyncChange>> _calculateSyncChanges({
    required Map<String, FileInfo> localFiles,
    required Map<String, FileInfo> remoteFiles,
    required SyncDirection direction,
  }) async {
    final changes = <SyncChange>[];

    // Check for files that exist locally but not remotely
    for (final localEntry in localFiles.entries) {
      final remoteFile = remoteFiles[localEntry.key];

      if (remoteFile == null) {
        // File exists locally but not remotely
        if (direction == SyncDirection.bidirectional ||
            direction == SyncDirection.localToRemote) {
          changes.add(SyncChange(
            filePath: localEntry.key,
            changeType: SyncChangeType.upload,
            sourceInfo: localEntry.value,
          ));
        }
      } else {
        // File exists in both, check if different
        if (localEntry.value.hash != remoteFile.hash) {
          final conflictResolution = _config.getParameter(
              'sync_conflict_resolution',
              defaultValue: 'newer_wins');

          switch (conflictResolution) {
            case 'newer_wins':
              if (localEntry.value.modified.isAfter(remoteFile.modified)) {
                changes.add(SyncChange(
                  filePath: localEntry.key,
                  changeType: SyncChangeType.upload,
                  sourceInfo: localEntry.value,
                  targetInfo: remoteFile,
                ));
              } else if (direction == SyncDirection.bidirectional ||
                  direction == SyncDirection.remoteToLocal) {
                changes.add(SyncChange(
                  filePath: localEntry.key,
                  changeType: SyncChangeType.download,
                  sourceInfo: remoteFile,
                  targetInfo: localEntry.value,
                ));
              }
              break;
            case 'local_wins':
              changes.add(SyncChange(
                filePath: localEntry.key,
                changeType: SyncChangeType.upload,
                sourceInfo: localEntry.value,
                targetInfo: remoteFile,
              ));
              break;
          }
        }
      }
    }

    // Check for files that exist remotely but not locally
    if (direction == SyncDirection.bidirectional ||
        direction == SyncDirection.remoteToLocal) {
      for (final remoteEntry in remoteFiles.entries) {
        if (!localFiles.containsKey(remoteEntry.key)) {
          changes.add(SyncChange(
            filePath: remoteEntry.key,
            changeType: SyncChangeType.download,
            sourceInfo: remoteEntry.value,
          ));
        }
      }
    }

    return changes;
  }

  /// Apply sync change
  Future<void> _applySyncChange(SyncChange change, SyncSession session) async {
    switch (change.changeType) {
      case SyncChangeType.upload:
        // Upload local file to remote
        await _uploadFile(change.filePath, session);
        break;
      case SyncChangeType.download:
        // Download remote file to local
        await _downloadFile(change.filePath, session);
        break;
      case SyncChangeType.delete:
        // Delete file (not implemented in this basic version)
        break;
    }
  }

  /// Upload file to remote device
  Future<void> _uploadFile(String filePath, SyncSession session) async {
    // Implementation would use the file sharing service
    // For now, this is a placeholder
    _logger.info('Uploading file: $filePath to ${session.remoteIP}',
        'NetworkFileSyncService');
  }

  /// Download file from remote device
  Future<void> _downloadFile(String filePath, SyncSession session) async {
    // Implementation would use the file sharing service
    // For now, this is a placeholder
    _logger.info('Downloading file: $filePath from ${session.remoteIP}',
        'NetworkFileSyncService');
  }

  /// Calculate file hash
  Future<String> _calculateFileHash(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Start auto sync for session
  void _startAutoSync(SyncSession session) {
    session.autoSyncTimer = Timer.periodic(session.syncInterval, (timer) {
      if (session.status != SyncStatus.syncing) {
        startSync(session.id);
      }
    });
  }

  /// Get sync session status
  SyncSession? getSyncSession(String sessionId) {
    return _activeSyncs[sessionId];
  }

  /// Get all active sync sessions
  List<SyncSession> getActiveSyncSessions() {
    return _activeSyncs.values.toList();
  }

  /// Generate unique session ID
  String _generateSessionId() {
    return 'sync_${DateTime.now().millisecondsSinceEpoch}_${_activeSyncs.length}';
  }

  /// Emit sync event
  void _emitSyncEvent(SyncEventType type,
      {SyncSession? session, String? filePath}) {
    final event = SyncEvent(
      type: type,
      timestamp: DateTime.now(),
      session: session,
      filePath: filePath,
    );
    _syncEventController.add(event);
  }

  void dispose() {
    _syncEventController.close();
    // Stop all sync sessions
    for (final session in _activeSyncs.values) {
      session.autoSyncTimer?.cancel();
    }
    _activeSyncs.clear();
  }
}

/// Sync Session Model
class SyncSession {
  final String id;
  final String localPath;
  final String remoteIP;
  final String remotePath;
  final int remotePort;
  final SyncDirection direction;
  SyncStatus status;
  final bool enableAutoSync;
  final Duration syncInterval;
  DateTime? lastSyncTime;
  Timer? autoSyncTimer;
  final SyncStats syncStats;
  String? lastError;

  SyncSession({
    required this.id,
    required this.localPath,
    required this.remoteIP,
    required this.remotePath,
    required this.remotePort,
    required this.direction,
    required this.status,
    required this.enableAutoSync,
    required this.syncInterval,
    this.lastSyncTime,
    required this.syncStats,
    this.lastError,
  });
}

/// File Info Model
class FileInfo {
  final String path;
  final int size;
  final DateTime modified;
  final String hash;
  final bool isDirectory;

  FileInfo({
    required this.path,
    required this.size,
    required this.modified,
    required this.hash,
    required this.isDirectory,
  });
}

/// Sync Change Model
class SyncChange {
  final String filePath;
  final SyncChangeType changeType;
  final FileInfo sourceInfo;
  final FileInfo? targetInfo;

  SyncChange({
    required this.filePath,
    required this.changeType,
    required this.sourceInfo,
    this.targetInfo,
  });
}

/// Sync Direction Enum
enum SyncDirection {
  localToRemote,
  remoteToLocal,
  bidirectional,
}

/// Sync Status Enum
enum SyncStatus {
  idle,
  syncing,
  error,
  stopped,
}

/// Sync Change Type Enum
enum SyncChangeType {
  upload,
  download,
  delete,
}

/// Sync Event Types
enum SyncEventType {
  sessionCreated,
  sessionStopped,
  syncStarted,
  syncCompleted,
  syncFailed,
  fileSynced,
}

/// Sync Event
class SyncEvent {
  final SyncEventType type;
  final DateTime timestamp;
  final SyncSession? session;
  final String? filePath;

  SyncEvent({
    required this.type,
    required this.timestamp,
    this.session,
    this.filePath,
  });
}

/// Sync Statistics
class SyncStats {
  int totalSyncs;
  int filesSynced;
  int errors;
  Duration? lastSyncDuration;

  SyncStats({
    required this.totalSyncs,
    required this.filesSynced,
    required this.errors,
    this.lastSyncDuration,
  });

  factory SyncStats.empty() => SyncStats(
        totalSyncs: 0,
        filesSynced: 0,
        errors: 0,
      );
}
