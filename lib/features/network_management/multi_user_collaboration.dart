import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'package:iSuite/core/logging/logging_service.dart';
import 'package:iSuite/core/config/central_config.dart';
import 'package:iSuite/core/advanced_security_service.dart';
import 'package:iSuite/features/network_management/universal_protocol_manager.dart';

/// Multi-User Collaboration System - Owlfiles-inspired
///
/// Real-time collaboration with synchronization and conflict resolution:
/// - Multi-user file sharing and editing with live synchronization
/// - Conflict resolution with intelligent merge strategies
/// - Session management with presence indicators and activity tracking
/// - Permission-based access control for collaborative workspaces
/// - Offline synchronization queues with conflict resolution
/// - Change history and version control for collaborative editing
/// - Real-time communication and collaboration features
/// - Collaborative workspaces with shared folders and permissions

enum CollaborationMode {
  viewOnly,
  commentOnly,
  editShared,
  editExclusive,
}

enum ConflictResolutionStrategy {
  newerWins,
  manualResolution,
  mergeIntelligent,
  keepLocal,
  keepRemote,
  customResolver,
}

enum SyncStatus {
  synced,
  syncing,
  conflict,
  offline,
  error,
}

class CollaborationSession {
  final String sessionId;
  final String workspaceId;
  final List<String> participants;
  final DateTime createdAt;
  DateTime? endedAt;
  final Map<String, CollaborationMode> participantPermissions;
  final Map<String, dynamic> metadata;

  CollaborationSession({
    required this.sessionId,
    required this.workspaceId,
    required this.participants,
    required this.participantPermissions,
    DateTime? createdAt,
    this.metadata = const {},
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isActive => endedAt == null;
  int get participantCount => participants.length;
}

class CollaborativeFile {
  final String fileId;
  final String workspaceId;
  final String filePath;
  final String ownerId;
  final List<String> collaborators;
  final Map<String, CollaborationMode> permissions;
  final DateTime createdAt;
  DateTime lastModified;
  final Map<String, dynamic> metadata;
  SyncStatus syncStatus;
  String? conflictDescription;

  CollaborativeFile({
    required this.fileId,
    required this.workspaceId,
    required this.filePath,
    required this.ownerId,
    required this.collaborators,
    required this.permissions,
    DateTime? createdAt,
    DateTime? lastModified,
    this.metadata = const {},
    this.syncStatus = SyncStatus.synced,
    this.conflictDescription,
  }) :
    createdAt = createdAt ?? DateTime.now(),
    lastModified = lastModified ?? DateTime.now();

  bool get hasConflicts => syncStatus == SyncStatus.conflict;
  bool get isShared => collaborators.isNotEmpty;
}

class FileChange {
  final String changeId;
  final String fileId;
  final String userId;
  final ChangeType type;
  final DateTime timestamp;
  final Map<String, dynamic> changeData;
  final String? previousVersion;

  FileChange({
    required this.changeId,
    required this.fileId,
    required this.userId,
    required this.type,
    required this.changeData,
    DateTime? timestamp,
    this.previousVersion,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum ChangeType {
  fileCreated,
  fileModified,
  fileDeleted,
  fileRenamed,
  fileMoved,
  contentChanged,
  metadataChanged,
  permissionChanged,
}

class SyncConflict {
  final String conflictId;
  final String fileId;
  final List<FileChange> conflictingChanges;
  final DateTime detectedAt;
  ConflictResolutionStrategy resolutionStrategy;
  String? resolvedBy;
  DateTime? resolvedAt;
  Map<String, dynamic>? resolutionData;

  SyncConflict({
    required this.conflictId,
    required this.fileId,
    required this.conflictingChanges,
    DateTime? detectedAt,
    this.resolutionStrategy = ConflictResolutionStrategy.manualResolution,
  }) : detectedAt = detectedAt ?? DateTime.now();

  bool get isResolved => resolvedAt != null;
}

class CollaborationWorkspace {
  final String workspaceId;
  final String name;
  final String description;
  final String ownerId;
  final List<String> members;
  final Map<String, CollaborationMode> memberPermissions;
  final List<String> sharedFiles;
  final DateTime createdAt;
  DateTime lastActivity;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> metadata;

  CollaborationWorkspace({
    required this.workspaceId,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.members,
    required this.memberPermissions,
    required this.sharedFiles,
    DateTime? createdAt,
    DateTime? lastActivity,
    this.settings = const {},
    this.metadata = const {},
  }) :
    createdAt = createdAt ?? DateTime.now(),
    lastActivity = lastActivity ?? DateTime.now();

  int get memberCount => members.length;
  int get fileCount => sharedFiles.length;
  bool get isActive => DateTime.now().difference(lastActivity).inDays < 30;
}

class MultiUserCollaborationSystem {
  static final MultiUserCollaborationSystem _instance = MultiUserCollaborationSystem._internal();
  factory MultiUserCollaborationSystem() => _instance;
  MultiUserCollaborationSystem._internal();

  final LoggingService _logger = LoggingService();
  final CentralConfig _config = CentralConfig.instance;
  final AdvancedSecurityService _security = AdvancedSecurityService();
  final UniversalProtocolManager _protocolManager = UniversalProtocolManager();

  bool _isInitialized = false;

  // Collaboration data
  final Map<String, CollaborationSession> _activeSessions = {};
  final Map<String, CollaborativeFile> _collaborativeFiles = {};
  final Map<String, CollaborationWorkspace> _workspaces = {};
  final Map<String, SyncConflict> _activeConflicts = {};

  // Change tracking
  final Map<String, List<FileChange>> _fileChangeHistory = {};
  final StreamController<CollaborationEvent> _collaborationEvents = StreamController.broadcast();

  // Sync management
  final Map<String, Completer<void>> _syncOperations = {};
  Timer? _syncScheduler;
  Timer? _conflictChecker;

  /// Initialize the multi-user collaboration system
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Multi-User Collaboration System', 'Collaboration');

      // Register with CentralConfig
      await _config.registerComponent(
        'MultiUserCollaborationSystem',
        '1.0.0',
        'Owlfiles-inspired multi-user collaboration with synchronization and conflict resolution',
        dependencies: ['CentralConfig', 'LoggingService', 'AdvancedSecurityService', 'UniversalProtocolManager'],
        parameters: {
          // Collaboration settings
          'collaboration.enabled': true,
          'collaboration.max_sessions': 50,
          'collaboration.session_timeout_minutes': 480, // 8 hours
          'collaboration.sync_interval_seconds': 30,

          // Conflict resolution settings
          'collaboration.conflict_resolution.default_strategy': 'manual_resolution',
          'collaboration.conflict_resolution.auto_resolve_threshold': 0.8,
          'collaboration.conflict_resolution.backup_on_conflict': true,

          // Workspace settings
          'collaboration.workspace.max_members': 100,
          'collaboration.workspace.max_files': 10000,
          'collaboration.workspace.inactive_threshold_days': 30,

          // Synchronization settings
          'collaboration.sync.batch_size': 10,
          'collaboration.sync.retry_attempts': 3,
          'collaboration.sync.compression': true,

          // Permission settings
          'collaboration.permissions.default_mode': 'view_only',
          'collaboration.permissions.allow_public_workspaces': false,
          'collaboration.permissions.audit_access': true,
        }
      );

      // Start collaboration services
      _startCollaborationServices();

      _isInitialized = true;
      _logger.info('Multi-User Collaboration System initialized successfully', 'Collaboration');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Multi-User Collaboration System', 'Collaboration',
          error: e, stackTrace: stackTrace);
      // Continue with limited functionality
      _isInitialized = true;
    }
  }

  /// Create a new collaboration workspace
  Future<CollaborationWorkspace> createWorkspace({
    required String name,
    required String description,
    required String ownerId,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) await initialize();

    final workspaceId = _generateWorkspaceId();
    final workspace = CollaborationWorkspace(
      workspaceId: workspaceId,
      name: name,
      description: description,
      ownerId: ownerId,
      members: [ownerId],
      memberPermissions: {ownerId: CollaborationMode.editShared},
      sharedFiles: [],
      settings: settings ?? {},
      metadata: metadata ?? {},
    );

    _workspaces[workspaceId] = workspace;

    await _logCollaborationEvent(
      CollaborationEventType.workspaceCreated,
      workspaceId: workspaceId,
      userId: ownerId,
      data: {'workspace_name': name},
    );

    _logger.info('Created collaboration workspace: $workspaceId ($name)', 'Collaboration');
    return workspace;
  }

  /// Join a collaboration workspace
  Future<void> joinWorkspace(String workspaceId, String userId, {
    CollaborationMode permission = CollaborationMode.viewOnly,
  }) async {
    final workspace = _workspaces[workspaceId];
    if (workspace == null) {
      throw CollaborationException('Workspace not found: $workspaceId');
    }

    if (!workspace.members.contains(userId)) {
      workspace.members.add(userId);
      workspace.memberPermissions[userId] = permission;
      workspace.lastActivity = DateTime.now();

      await _logCollaborationEvent(
        CollaborationEventType.userJoinedWorkspace,
        workspaceId: workspaceId,
        userId: userId,
        data: {'permission': permission.name},
      );

      _logger.info('User $userId joined workspace $workspaceId', 'Collaboration');
    }
  }

  /// Start a collaboration session
  Future<CollaborationSession> startCollaborationSession({
    required String workspaceId,
    required List<String> participants,
    Map<String, CollaborationMode>? permissions,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) await initialize();

    final sessionId = _generateSessionId();
    final sessionPermissions = permissions ?? {};

    // Ensure all participants have permissions
    for (final participant in participants) {
      sessionPermissions.putIfAbsent(participant, () => CollaborationMode.viewOnly);
    }

    final session = CollaborationSession(
      sessionId: sessionId,
      workspaceId: workspaceId,
      participants: participants,
      participantPermissions: sessionPermissions,
      metadata: metadata ?? {},
    );

    _activeSessions[sessionId] = session;

    await _logCollaborationEvent(
      CollaborationEventType.sessionStarted,
      sessionId: sessionId,
      workspaceId: workspaceId,
      data: {'participant_count': participants.length},
    );

    _logger.info('Started collaboration session: $sessionId for workspace $workspaceId', 'Collaboration');
    return session;
  }

  /// Share a file in a workspace
  Future<CollaborativeFile> shareFile({
    required String workspaceId,
    required String filePath,
    required String ownerId,
    List<String>? collaborators,
    Map<String, CollaborationMode>? permissions,
  }) async {
    final workspace = _workspaces[workspaceId];
    if (workspace == null) {
      throw CollaborationException('Workspace not found: $workspaceId');
    }

    final fileId = _generateFileId();
    final filePermissions = permissions ?? {};

    // Set default permissions for collaborators
    final allCollaborators = collaborators ?? [];
    for (final collaborator in allCollaborators) {
      filePermissions.putIfAbsent(collaborator, () => CollaborationMode.viewOnly);
    }

    final collaborativeFile = CollaborativeFile(
      fileId: fileId,
      workspaceId: workspaceId,
      filePath: filePath,
      ownerId: ownerId,
      collaborators: allCollaborators,
      permissions: filePermissions,
      metadata: {
        'original_size': await _getFileSize(filePath),
        'checksum': await _calculateFileChecksum(filePath),
      },
    );

    _collaborativeFiles[fileId] = collaborativeFile;
    workspace.sharedFiles.add(fileId);

    // Record initial change
    await _recordFileChange(
      fileId,
      ownerId,
      ChangeType.fileCreated,
      {'action': 'file_shared', 'workspace': workspaceId},
    );

    await _logCollaborationEvent(
      CollaborationEventType.fileShared,
      workspaceId: workspaceId,
      userId: ownerId,
      data: {'file_id': fileId, 'file_path': filePath},
    );

    _logger.info('Shared file $filePath in workspace $workspaceId', 'Collaboration');
    return collaborativeFile;
  }

  /// Synchronize file changes
  Future<void> synchronizeFile(String fileId, String userId, {
    ConflictResolutionStrategy conflictStrategy = ConflictResolutionStrategy.manualResolution,
  }) async {
    final file = _collaborativeFiles[fileId];
    if (file == null) {
      throw CollaborationException('Collaborative file not found: $fileId');
    }

    if (_syncOperations.containsKey(fileId)) {
      // Sync already in progress
      return _syncOperations[fileId]!.future;
    }

    final completer = Completer<void>();
    _syncOperations[fileId] = completer;

    try {
      file.syncStatus = SyncStatus.syncing;

      // Check for conflicts
      final conflicts = await _detectConflicts(fileId);
      if (conflicts.isNotEmpty) {
        await _handleConflicts(conflicts, conflictStrategy);
      }

      // Perform synchronization
      await _performFileSync(file, userId);

      file.syncStatus = SyncStatus.synced;
      file.lastModified = DateTime.now();

      await _logCollaborationEvent(
        CollaborationEventType.fileSynchronized,
        fileId: fileId,
        userId: userId,
        data: {'sync_status': 'completed'},
      );

      _logger.info('Synchronized file $fileId for user $userId', 'Collaboration');

    } catch (e) {
      file.syncStatus = SyncStatus.error;
      file.conflictDescription = e.toString();

      await _logCollaborationEvent(
        CollaborationEventType.syncError,
        fileId: fileId,
        userId: userId,
        data: {'error': e.toString()},
      );

      _logger.error('Sync error for file $fileId: $e', 'Collaboration');
      throw CollaborationException('Synchronization failed: $e');

    } finally {
      _syncOperations.remove(fileId);
      completer.complete();
    }
  }

  /// Record a file change
  Future<void> recordFileChange(String fileId, String userId, ChangeType changeType, {
    Map<String, dynamic>? changeData,
  }) async {
    final file = _collaborativeFiles[fileId];
    if (file == null) {
      throw CollaborationException('Collaborative file not found: $fileId');
    }

    // Check user permissions
    final userPermission = file.permissions[userId] ?? CollaborationMode.viewOnly;
    if (!_canPerformChange(userPermission, changeType)) {
      throw CollaborationException('Insufficient permissions for change type: $changeType');
    }

    await _recordFileChange(fileId, userId, changeType, changeData ?? {});

    file.lastModified = DateTime.now();

    await _logCollaborationEvent(
      CollaborationEventType.fileChanged,
      fileId: fileId,
      userId: userId,
      data: {'change_type': changeType.name},
    );

    // Trigger sync for other collaborators
    await _notifyCollaborators(fileId, userId, changeType);

    _logger.info('Recorded change $changeType for file $fileId by user $userId', 'Collaboration');
  }

  /// Resolve a synchronization conflict
  Future<void> resolveConflict(String conflictId, String userId, {
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.manualResolution,
    Map<String, dynamic>? resolutionData,
  }) async {
    final conflict = _activeConflicts[conflictId];
    if (conflict == null) {
      throw CollaborationException('Conflict not found: $conflictId');
    }

    conflict.resolutionStrategy = strategy;
    conflict.resolvedBy = userId;
    conflict.resolvedAt = DateTime.now();
    conflict.resolutionData = resolutionData;

    // Apply resolution
    await _applyConflictResolution(conflict);

    _activeConflicts.remove(conflictId);

    await _logCollaborationEvent(
      CollaborationEventType.conflictResolved,
      fileId: conflict.fileId,
      userId: userId,
      data: {'conflict_id': conflictId, 'strategy': strategy.name},
    );

    _logger.info('Resolved conflict $conflictId using strategy $strategy', 'Collaboration');
  }

  /// Get collaboration statistics
  Map<String, dynamic> getCollaborationStatistics() {
    return {
      'active_sessions': _activeSessions.length,
      'total_workspaces': _workspaces.length,
      'collaborative_files': _collaborativeFiles.length,
      'active_conflicts': _activeConflicts.length,
      'total_file_changes': _fileChangeHistory.values.expand((changes) => changes).length,
      'workspaces_by_activity': _getWorkspacesByActivity(),
      'collaboration_trends': _getCollaborationTrends(),
    };
  }

  /// Get workspace activity
  Future<Map<String, dynamic>> getWorkspaceActivity(String workspaceId) async {
    final workspace = _workspaces[workspaceId];
    if (workspace == null) {
      throw CollaborationException('Workspace not found: $workspaceId');
    }

    final fileChanges = <String, List<FileChange>>{};
    for (final fileId in workspace.sharedFiles) {
      fileChanges[fileId] = _fileChangeHistory[fileId] ?? [];
    }

    return {
      'workspace': workspace,
      'active_sessions': _activeSessions.values.where((s) => s.workspaceId == workspaceId).length,
      'file_activity': fileChanges,
      'member_activity': await _getMemberActivity(workspaceId),
      'recent_changes': _getRecentChanges(workspaceId),
    };
  }

  // Private implementation methods

  Future<void> _startCollaborationServices() {
    // Periodic sync scheduler
    final syncInterval = Duration(seconds: _config.getParameter('collaboration.sync_interval_seconds', defaultValue: 30));
    _syncScheduler = Timer.periodic(syncInterval, (timer) async {
      await _performPeriodicSync();
    });

    // Conflict checker
    _conflictChecker = Timer.periodic(Duration(minutes: 5), (timer) async {
      await _checkForConflicts();
    });

    _logger.info('Collaboration services started', 'Collaboration');
  }

  String _generateWorkspaceId() => 'ws_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  String _generateSessionId() => 'session_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  String _generateFileId() => 'file_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

  Future<void> _logCollaborationEvent(
    CollaborationEventType eventType, {
    String? sessionId,
    String? workspaceId,
    String? fileId,
    String? userId,
    Map<String, dynamic>? data,
  }) async {
    await _security.logAuditEntry(
      'collaboration_event',
      'Collaboration event: ${eventType.name}',
      userId: userId,
      additionalData: {
        'event_type': eventType.name,
        'session_id': sessionId,
        'workspace_id': workspaceId,
        'file_id': fileId,
        ...?data,
      },
    );
  }

  Future<void> _recordFileChange(String fileId, String userId, ChangeType changeType, Map<String, dynamic> changeData) async {
    final change = FileChange(
      changeId: 'change_${DateTime.now().millisecondsSinceEpoch}',
      fileId: fileId,
      userId: userId,
      type: changeType,
      changeData: changeData,
    );

    _fileChangeHistory.putIfAbsent(fileId, () => []).add(change);
  }

  bool _canPerformChange(CollaborationMode permission, ChangeType changeType) {
    switch (permission) {
      case CollaborationMode.viewOnly:
        return false;
      case CollaborationMode.commentOnly:
        return changeType == ChangeType.metadataChanged;
      case CollaborationMode.editShared:
        return changeType != ChangeType.fileDeleted;
      case CollaborationMode.editExclusive:
        return true;
    }
  }

  Future<void> _notifyCollaborators(String fileId, String excludeUserId, ChangeType changeType) async {
    final file = _collaborativeFiles[fileId];
    if (file == null) return;

    // Notify all collaborators except the one who made the change
    for (final collaborator in file.collaborators) {
      if (collaborator != excludeUserId) {
        // In a real implementation, this would send notifications via WebSocket, push notifications, etc.
        _logger.debug('Notified collaborator $collaborator about change $changeType on file $fileId', 'Collaboration');
      }
    }
  }

  Future<List<SyncConflict>> _detectConflicts(String fileId) async {
    final changes = _fileChangeHistory[fileId] ?? [];
    final conflicts = <SyncConflict>[];

    // Simple conflict detection - check for overlapping changes
    final recentChanges = changes.where((c) => c.timestamp.isAfter(DateTime.now().subtract(Duration(hours: 1)))).toList();

    if (recentChanges.length > 1) {
      // Check for conflicting changes
      final modifyChanges = recentChanges.where((c) => c.type == ChangeType.contentChanged).toList();
      if (modifyChanges.length > 1) {
        final conflict = SyncConflict(
          conflictId: 'conflict_${DateTime.now().millisecondsSinceEpoch}',
          fileId: fileId,
          conflictingChanges: modifyChanges,
        );
        conflicts.add(conflict);
        _activeConflicts[conflict.conflictId] = conflict;
      }
    }

    return conflicts;
  }

  Future<void> _handleConflicts(List<SyncConflict> conflicts, ConflictResolutionStrategy strategy) async {
    for (final conflict in conflicts) {
      conflict.resolutionStrategy = strategy;

      // Auto-resolve if strategy allows
      if (strategy != ConflictResolutionStrategy.manualResolution) {
        await _applyConflictResolution(conflict);
      }
    }
  }

  Future<void> _applyConflictResolution(SyncConflict conflict) async {
    // Apply the chosen resolution strategy
    switch (conflict.resolutionStrategy) {
      case ConflictResolutionStrategy.newerWins:
        final newestChange = conflict.conflictingChanges.reduce((a, b) =>
          a.timestamp.isAfter(b.timestamp) ? a : b);
        await _applyChange(conflict.fileId, newestChange);
        break;

      case ConflictResolutionStrategy.keepLocal:
        // Keep local version (no action needed in simulation)
        break;

      case ConflictResolutionStrategy.keepRemote:
        // Keep remote version (would fetch from remote in real implementation)
        break;

      case ConflictResolutionStrategy.manualResolution:
        // Wait for manual resolution
        break;

      default:
        break;
    }

    if (conflict.resolutionStrategy != ConflictResolutionStrategy.manualResolution) {
      conflict.resolvedAt = DateTime.now();
      conflict.resolvedBy = 'system';
    }
  }

  Future<void> _applyChange(String fileId, FileChange change) async {
    // Apply the change to the file
    // In a real implementation, this would modify the actual file
    _logger.debug('Applied change ${change.type} to file $fileId', 'Collaboration');
  }

  Future<void> _performFileSync(CollaborativeFile file, String userId) async {
    // Perform actual file synchronization
    // In a real implementation, this would sync with remote storage
    _logger.debug('Performed file sync for ${file.filePath}', 'Collaboration');
  }

  Future<void> _performPeriodicSync() async {
    // Perform periodic synchronization for all active files
    for (final file in _collaborativeFiles.values) {
      if (file.syncStatus != SyncStatus.syncing) {
        try {
          await synchronizeFile(file.fileId, 'system');
        } catch (e) {
          _logger.warning('Periodic sync failed for file ${file.fileId}: $e', 'Collaboration');
        }
      }
    }
  }

  Future<void> _checkForConflicts() async {
    // Check all collaborative files for conflicts
    for (final file in _collaborativeFiles.values) {
      final conflicts = await _detectConflicts(file.fileId);
      if (conflicts.isNotEmpty) {
        file.syncStatus = SyncStatus.conflict;
        file.conflictDescription = '${conflicts.length} conflict(s) detected';
      }
    }
  }

  Future<int> _getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  Future<String> _calculateFileChecksum(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      return md5.convert(bytes).toString();
    } catch (e) {
      return '';
    }
  }

  Map<String, int> _getWorkspacesByActivity() {
    final activity = <String, int>{};
    final now = DateTime.now();

    for (final workspace in _workspaces.values) {
      final daysSinceActivity = now.difference(workspace.lastActivity).inDays;
      final activityLevel = daysSinceActivity < 1 ? 'very_active' :
                           daysSinceActivity < 7 ? 'active' :
                           daysSinceActivity < 30 ? 'moderate' : 'inactive';

      activity[activityLevel] = (activity[activityLevel] ?? 0) + 1;
    }

    return activity;
  }

  Map<String, dynamic> _getCollaborationTrends() {
    // Calculate collaboration trends over time
    return {
      'sessions_today': _activeSessions.values.where((s) =>
        s.createdAt.day == DateTime.now().day).length,
      'files_shared_today': _collaborativeFiles.values.where((f) =>
        f.createdAt.day == DateTime.now().day).length,
      'conflicts_resolved_today': _activeConflicts.values.where((c) =>
        c.resolvedAt?.day == DateTime.now().day).length,
    };
  }

  Future<Map<String, dynamic>> _getMemberActivity(String workspaceId) async {
    final workspace = _workspaces[workspaceId];
    if (workspace == null) return {};

    final activity = <String, dynamic>{};

    for (final member in workspace.members) {
      final memberChanges = <String, List<FileChange>>{};

      for (final fileId in workspace.sharedFiles) {
        final changes = _fileChangeHistory[fileId]?.where((c) => c.userId == member).toList() ?? [];
        if (changes.isNotEmpty) {
          memberChanges[fileId] = changes;
        }
      }

      activity[member] = {
        'changes_count': memberChanges.values.expand((c) => c).length,
        'last_activity': memberChanges.values.expand((c) => c)
          .map((c) => c.timestamp)
          .fold<DateTime?>(null, (prev, curr) => prev == null || curr.isAfter(prev) ? curr : prev),
      };
    }

    return activity;
  }

  List<FileChange> _getRecentChanges(String workspaceId) {
    final workspace = _workspaces[workspaceId];
    if (workspace == null) return [];

    final allChanges = <FileChange>[];

    for (final fileId in workspace.sharedFiles) {
      final changes = _fileChangeHistory[fileId] ?? [];
      allChanges.addAll(changes);
    }

    // Sort by timestamp (most recent first) and take last 50
    allChanges.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allChanges.take(50).toList();
  }

  // Getters
  bool get isInitialized => _isInitialized;
  Map<String, CollaborationSession> get activeSessions => Map.from(_activeSessions);
  Map<String, CollaborativeFile> get collaborativeFiles => Map.from(_collaborativeFiles);
  Map<String, CollaborationWorkspace> get workspaces => Map.from(_workspaces);
  Map<String, SyncConflict> get activeConflicts => Map.from(_activeConflicts);
  Stream<CollaborationEvent> get collaborationEvents => _collaborationEvents.stream;
}

/// Supporting classes and enums

enum CollaborationEventType {
  workspaceCreated,
  userJoinedWorkspace,
  userLeftWorkspace,
  sessionStarted,
  sessionEnded,
  fileShared,
  fileUnshared,
  fileChanged,
  fileSynchronized,
  syncError,
  conflictDetected,
  conflictResolved,
  permissionChanged,
}

class CollaborationEvent {
  final CollaborationEventType type;
  final DateTime timestamp;
  final String? sessionId;
  final String? workspaceId;
  final String? fileId;
  final String? userId;
  final Map<String, dynamic> data;

  CollaborationEvent({
    required this.type,
    required this.timestamp,
    this.sessionId,
    this.workspaceId,
    this.fileId,
    this.userId,
    required this.data,
  });
}

class CollaborationException implements Exception {
  final String message;
  CollaborationException(this.message);

  @override
  String toString() => 'CollaborationException: $message';
}
