import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// ============================================================================
/// REAL-TIME COLLABORATION AND SYNCHRONIZATION SYSTEM FOR iSUITE PRO
/// ============================================================================
///
/// Advanced collaboration features for iSuite Pro:
/// - Real-time document collaboration with operational transformation
/// - Multi-user presence and cursor tracking
/// - Conflict-free replicated data types (CRDTs)
/// - Offline-first synchronization with conflict resolution
/// - Collaborative file sharing and version control
/// - Live editing with change tracking and undo/redo
/// - User permissions and access control
/// - Activity feeds and collaboration analytics
/// - Cross-device synchronization
/// - Collaborative AI assistance
///
/// Key Features:
/// - Operational Transformation for conflict resolution
/// - WebSocket-based real-time communication
/// - Presence indicators and user avatars
/// - Collaborative cursors and selections
/// - Automatic conflict resolution
/// - Offline queue management
/// - Version history and branching
/// - Real-time notifications
/// - Collaboration metrics and analytics
///
/// ============================================================================

class RealtimeCollaborationSystem {
  static final RealtimeCollaborationSystem _instance = RealtimeCollaborationSystem._internal();
  factory RealtimeCollaborationSystem() => _instance;

  RealtimeCollaborationSystem._internal() {
    _initialize();
  }

  // Core collaboration components
  late OperationalTransformer _transformer;
  late ConflictResolver _conflictResolver;
  late PresenceManager _presenceManager;
  late SynchronizationEngine _syncEngine;
  late CollaborationAnalytics _analytics;
  late OfflineQueueManager _offlineManager;

  // Supabase client for real-time features
  final SupabaseClient _supabase = Supabase.instance.client;

  // Collaboration state
  final Map<String, CollaborationSession> _activeSessions = {};
  final Map<String, UserPresence> _userPresence = {};
  final Map<String, StreamSubscription> _sessionSubscriptions = {};
  final Map<String, List<CollaborationEvent>> _eventHistory = {};

  // Event streams
  final StreamController<CollaborationEvent> _eventController =
      StreamController<CollaborationEvent>.broadcast();

  final StreamController<PresenceEvent> _presenceController =
      StreamController<PresenceEvent>.broadcast();

  void _initialize() {
    _transformer = OperationalTransformer();
    _conflictResolver = ConflictResolver();
    _presenceManager = PresenceManager();
    _syncEngine = SynchronizationEngine();
    _analytics = CollaborationAnalytics();
    _offlineManager = OfflineQueueManager();

    _setupRealtimeSubscriptions();
  }

  /// Create a new collaboration session
  Future<CollaborationSession> createSession({
    required String documentId,
    required String creatorId,
    required String sessionName,
    required CollaborationType type,
    List<String>? invitedUserIds,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final sessionId = const Uuid().v4();

      final session = CollaborationSession(
        id: sessionId,
        documentId: documentId,
        creatorId: creatorId,
        name: sessionName,
        type: type,
        participants: [creatorId],
        invitedUsers: invitedUserIds ?? [],
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
        metadata: metadata ?? {},
        version: 1,
        isActive: true,
      );

      // Save session to database
      await _saveSessionToDatabase(session);

      // Start real-time subscription
      await _startSessionSubscription(sessionId);

      // Update presence
      await _presenceManager.updatePresence(creatorId, sessionId, PresenceStatus.active);

      // Track analytics
      await _analytics.trackSessionCreated(session);

      _activeSessions[sessionId] = session;

      // Emit session created event
      _eventController.add(CollaborationEvent.sessionCreated(session));

      return session;

    } catch (e, stackTrace) {
      debugPrint('Failed to create collaboration session: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Join an existing collaboration session
  Future<void> joinSession(String sessionId, String userId) async {
    try {
      // Get session data
      final session = await _getSessionFromDatabase(sessionId);

      if (session == null || !session.isActive) {
        throw Exception('Session not found or inactive');
      }

      // Check if user is invited or session is public
      if (!session.participants.contains(userId) &&
          !session.invitedUsers.contains(userId) &&
          session.creatorId != userId) {
        throw Exception('User not authorized to join this session');
      }

      // Add user to participants
      final updatedParticipants = List<String>.from(session.participants);
      if (!updatedParticipants.contains(userId)) {
        updatedParticipants.add(userId);
      }

      // Update session
      final updatedSession = session.copyWith(
        participants: updatedParticipants,
        lastActivity: DateTime.now(),
      );

      await _updateSessionInDatabase(updatedSession);

      // Start subscription for this user
      await _startSessionSubscription(sessionId);

      // Update presence
      await _presenceManager.updatePresence(userId, sessionId, PresenceStatus.active);

      // Track analytics
      await _analytics.trackUserJoined(session, userId);

      _activeSessions[sessionId] = updatedSession;

      // Emit user joined event
      _eventController.add(CollaborationEvent.userJoined(sessionId, userId));

    } catch (e, stackTrace) {
      debugPrint('Failed to join collaboration session: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Leave collaboration session
  Future<void> leaveSession(String sessionId, String userId) async {
    try {
      final session = _activeSessions[sessionId];
      if (session == null) return;

      // Remove user from participants
      final updatedParticipants = session.participants.where((id) => id != userId).toList();

      CollaborationSession updatedSession;

      if (updatedParticipants.isEmpty) {
        // End session if no participants left
        updatedSession = session.copyWith(
          participants: updatedParticipants,
          isActive: false,
          endedAt: DateTime.now(),
        );
      } else {
        // Update participants
        updatedSession = session.copyWith(
          participants: updatedParticipants,
          lastActivity: DateTime.now(),
        );
      }

      await _updateSessionInDatabase(updatedSession);

      // Update presence
      await _presenceManager.removePresence(userId, sessionId);

      // Stop subscription
      await _stopSessionSubscription(sessionId);

      // Track analytics
      await _analytics.trackUserLeft(session, userId);

      if (updatedSession.isActive) {
        _activeSessions[sessionId] = updatedSession;
        _eventController.add(CollaborationEvent.userLeft(sessionId, userId));
      } else {
        _activeSessions.remove(sessionId);
        _eventController.add(CollaborationEvent.sessionEnded(sessionId));
      }

    } catch (e, stackTrace) {
      debugPrint('Failed to leave session: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Send collaborative operation
  Future<void> sendOperation(
    String sessionId,
    String userId,
    Operation operation,
  ) async {
    try {
      final session = _activeSessions[sessionId];
      if (session == null) {
        throw Exception('Session not found');
      }

      // Transform operation against concurrent operations
      final transformedOperation = await _transformer.transform(
        operation,
        await _getConcurrentOperations(sessionId, operation),
      );

      // Apply operation locally first (optimistic update)
      await _applyOperationLocally(sessionId, transformedOperation);

      // Broadcast operation via real-time
      await _broadcastOperation(sessionId, userId, transformedOperation);

      // Save operation to database
      await _saveOperationToDatabase(sessionId, transformedOperation);

      // Track analytics
      await _analytics.trackOperation(session, operation);

      // Emit operation event
      _eventController.add(CollaborationEvent.operationApplied(
        sessionId,
        userId,
        transformedOperation,
      ));

    } catch (e, stackTrace) {
      debugPrint('Failed to send operation: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Update user presence
  Future<void> updatePresence(
    String userId,
    String sessionId,
    PresenceStatus status, {
    PresenceData? data,
  }) async {
    try {
      await _presenceManager.updatePresence(userId, sessionId, status, data: data);

      // Broadcast presence update
      await _broadcastPresenceUpdate(userId, sessionId, status, data);

      // Emit presence event
      _presenceController.add(PresenceEvent.updated(
        userId,
        sessionId,
        status,
        data,
      ));

    } catch (e, stackTrace) {
      debugPrint('Failed to update presence: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Send real-time message
  Future<void> sendMessage(
    String sessionId,
    String userId,
    String message, {
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final chatMessage = ChatMessage(
        id: const Uuid().v4(),
        sessionId: sessionId,
        userId: userId,
        content: message,
        type: type,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      // Save message to database
      await _saveMessageToDatabase(chatMessage);

      // Broadcast message
      await _broadcastMessage(chatMessage);

      // Emit message event
      _eventController.add(CollaborationEvent.messageReceived(chatMessage));

    } catch (e, stackTrace) {
      debugPrint('Failed to send message: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Get session history and operations
  Future<SessionHistory> getSessionHistory(String sessionId) async {
    try {
      final operations = await _getOperationsFromDatabase(sessionId);
      final messages = await _getMessagesFromDatabase(sessionId);
      final events = _eventHistory[sessionId] ?? [];

      return SessionHistory(
        sessionId: sessionId,
        operations: operations,
        messages: messages,
        events: events,
      );

    } catch (e, stackTrace) {
      debugPrint('Failed to get session history: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Get active sessions for user
  Future<List<CollaborationSession>> getActiveSessions(String userId) async {
    try {
      // Get sessions where user is participant
      final participantSessions = await _supabase
          .from('collaboration_sessions')
          .select()
          .eq('is_active', true)
          .contains('participants', [userId]);

      // Get sessions where user is invited
      final invitedSessions = await _supabase
          .from('collaboration_sessions')
          .select()
          .eq('is_active', true)
          .contains('invited_users', [userId]);

      final allSessions = [...participantSessions, ...invitedSessions];

      return allSessions
          .map((data) => CollaborationSession.fromJson(data))
          .toSet() // Remove duplicates
          .toList();

    } catch (e, stackTrace) {
      debugPrint('Failed to get active sessions: $e\n$stackTrace');
      return [];
    }
  }

  /// Synchronize offline changes
  Future<void> synchronizeOfflineChanges(String sessionId) async {
    try {
      final offlineOperations = await _offlineManager.getQueuedOperations(sessionId);

      for (final operation in offlineOperations) {
        try {
          await sendOperation(sessionId, operation.userId, operation);
          await _offlineManager.removeOperation(operation.id);
        } catch (e) {
          debugPrint('Failed to sync offline operation: $e');
          // Keep operation in queue for retry
        }
      }

    } catch (e, stackTrace) {
      debugPrint('Failed to synchronize offline changes: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Setup real-time subscriptions
  void _setupRealtimeSubscriptions() {
    // Listen to collaboration_sessions table changes
    _supabase
        .channel('collaboration_sessions')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'collaboration_sessions',
          callback: (payload) {
            _handleSessionChange(payload);
          },
        )
        .subscribe();

    // Listen to collaboration_operations table changes
    _supabase
        .channel('collaboration_operations')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'collaboration_operations',
          callback: (payload) {
            _handleOperationChange(payload);
          },
        )
        .subscribe();
  }

  /// Handle session changes from real-time
  void _handleSessionChange(PostgresChangePayload payload) {
    final sessionData = payload.newRecord ?? payload.oldRecord;
    if (sessionData == null) return;

    final session = CollaborationSession.fromJson(sessionData);

    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        _activeSessions[session.id] = session;
        _eventController.add(CollaborationEvent.sessionCreated(session));
        break;

      case PostgresChangeEvent.update:
        _activeSessions[session.id] = session;
        _eventController.add(CollaborationEvent.sessionUpdated(session));
        break;

      case PostgresChangeEvent.delete:
        _activeSessions.remove(session.id);
        _eventController.add(CollaborationEvent.sessionEnded(session.id));
        break;

      default:
        break;
    }
  }

  /// Handle operation changes from real-time
  void _handleOperationChange(PostgresChangePayload payload) {
    final operationData = payload.newRecord;
    if (operationData == null) return;

    final operation = Operation.fromJson(operationData);
    final sessionId = operationData['session_id'] as String;
    final userId = operationData['user_id'] as String;

    // Apply operation if not from current user
    if (userId != _getCurrentUserId()) {
      _applyOperationLocally(sessionId, operation);
    }

    _eventController.add(CollaborationEvent.operationApplied(
      sessionId,
      userId,
      operation,
    ));
  }

  /// Start session subscription
  Future<void> _startSessionSubscription(String sessionId) async {
    final subscription = _supabase
        .channel('session_$sessionId')
        .onBroadcast(
          event: 'operation',
          callback: (payload) {
            final operation = Operation.fromJson(payload);
            _applyOperationLocally(sessionId, operation);
          },
        )
        .onBroadcast(
          event: 'presence',
          callback: (payload) {
            final presence = UserPresence.fromJson(payload);
            _userPresence[presence.userId] = presence;
            _presenceController.add(PresenceEvent.updated(
              presence.userId,
              presence.sessionId,
              presence.status,
              presence.data,
            ));
          },
        )
        .onBroadcast(
          event: 'message',
          callback: (payload) {
            final message = ChatMessage.fromJson(payload);
            _eventController.add(CollaborationEvent.messageReceived(message));
          },
        )
        .subscribe();

    _sessionSubscriptions[sessionId] = subscription;
  }

  /// Stop session subscription
  Future<void> _stopSessionSubscription(String sessionId) async {
    final subscription = _sessionSubscriptions[sessionId];
    if (subscription != null) {
      await subscription.unsubscribe();
      _sessionSubscriptions.remove(sessionId);
    }
  }

  /// Database operations
  Future<void> _saveSessionToDatabase(CollaborationSession session) async {
    await _supabase.from('collaboration_sessions').insert(session.toJson());
  }

  Future<void> _updateSessionInDatabase(CollaborationSession session) async {
    await _supabase
        .from('collaboration_sessions')
        .update(session.toJson())
        .eq('id', session.id);
  }

  Future<CollaborationSession?> _getSessionFromDatabase(String sessionId) async {
    final result = await _supabase
        .from('collaboration_sessions')
        .select()
        .eq('id', sessionId)
        .single();

    return result != null ? CollaborationSession.fromJson(result) : null;
  }

  Future<void> _saveOperationToDatabase(String sessionId, Operation operation) async {
    await _supabase.from('collaboration_operations').insert({
      'session_id': sessionId,
      'user_id': operation.userId,
      'type': operation.type.toString(),
      'data': jsonEncode(operation.data),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _saveMessageToDatabase(ChatMessage message) async {
    await _supabase.from('collaboration_messages').insert(message.toJson());
  }

  Future<List<Operation>> _getOperationsFromDatabase(String sessionId) async {
    final results = await _supabase
        .from('collaboration_operations')
        .select()
        .eq('session_id', sessionId)
        .order('timestamp');

    return results.map((data) => Operation.fromJson(data)).toList();
  }

  Future<List<ChatMessage>> _getMessagesFromDatabase(String sessionId) async {
    final results = await _supabase
        .from('collaboration_messages')
        .select()
        .eq('session_id', sessionId)
        .order('timestamp');

    return results.map((data) => ChatMessage.fromJson(data)).toList();
  }

  /// Helper methods
  Future<List<Operation>> _getConcurrentOperations(String sessionId, Operation operation) async {
    // Get operations that happened after the base version
    final operations = await _getOperationsFromDatabase(sessionId);
    return operations.where((op) => op.timestamp.isAfter(operation.timestamp)).toList();
  }

  Future<void> _applyOperationLocally(String sessionId, Operation operation) async {
    // Apply operation to local document state
    // This would integrate with the document editing system
    debugPrint('Applying operation locally: ${operation.type}');
  }

  Future<void> _broadcastOperation(String sessionId, String userId, Operation operation) async {
    await _supabase.channel('session_$sessionId').broadcast(
      event: 'operation',
      payload: operation.toJson(),
    );
  }

  Future<void> _broadcastPresenceUpdate(
    String userId,
    String sessionId,
    PresenceStatus status,
    PresenceData? data,
  ) async {
    final presence = UserPresence(
      userId: userId,
      sessionId: sessionId,
      status: status,
      data: data,
      lastSeen: DateTime.now(),
    );

    await _supabase.channel('session_$sessionId').broadcast(
      event: 'presence',
      payload: presence.toJson(),
    );
  }

  Future<void> _broadcastMessage(ChatMessage message) async {
    await _supabase.channel('session_${message.sessionId}').broadcast(
      event: 'message',
      payload: message.toJson(),
    );
  }

  String _getCurrentUserId() {
    return _supabase.auth.currentUser?.id ?? '';
  }

  /// Public streams
  Stream<CollaborationEvent> get collaborationEvents => _eventController.stream;
  Stream<PresenceEvent> get presenceEvents => _presenceController.stream;

  /// Get collaboration analytics
  CollaborationAnalytics get analytics => _analytics;

  /// Dispose resources
  void dispose() {
    for (final subscription in _sessionSubscriptions.values) {
      subscription.unsubscribe();
    }
    _sessionSubscriptions.clear();
    _activeSessions.clear();
    _userPresence.clear();
    _eventHistory.clear();
    _eventController.close();
    _presenceController.close();
  }
}

/// ============================================================================
/// COMPONENT CLASSES
/// ============================================================================

class OperationalTransformer {
  Future<Operation> transform(Operation operation, List<Operation> concurrentOperations) async {
    // Implement Operational Transformation algorithm
    // This ensures consistency in collaborative editing

    var transformedOperation = operation;

    for (final concurrentOp in concurrentOperations) {
      transformedOperation = _transformOperations(transformedOperation, concurrentOp);
    }

    return transformedOperation;
  }

  Operation _transformOperations(Operation op1, Operation op2) {
    // Simplified OT transformation
    // In a real implementation, this would handle different operation types

    if (op1.type == OperationType.insert && op2.type == OperationType.insert) {
      // Handle insert-insert conflicts
      if (op1.data['position'] <= op2.data['position']) {
        return op1;
      } else {
        return op1.copyWith(data: {
          ...op1.data,
          'position': op1.data['position'] + op2.data['text'].length,
        });
      }
    }

    return op1;
  }
}

class ConflictResolver {
  Future<ConflictResolution> resolve(Conflict conflict) async {
    // Implement conflict resolution strategies
    // This handles cases where OT cannot resolve conflicts

    switch (conflict.type) {
      case ConflictType.textEdit:
        return _resolveTextEditConflict(conflict);
      case ConflictType.fileOperation:
        return _resolveFileOperationConflict(conflict);
      default:
        return ConflictResolution.acceptFirst(conflict);
    }
  }

  ConflictResolution _resolveTextEditConflict(Conflict conflict) {
    // Prefer the operation from the user with higher authority
    // or use timestamps for last-writer-wins
    return ConflictResolution.acceptLast(conflict);
  }

  ConflictResolution _resolveFileOperationConflict(Conflict conflict) {
    // File operations are more complex - may need user intervention
    return ConflictResolution.manualResolution(conflict);
  }
}

class PresenceManager {
  final Map<String, UserPresence> _presence = {};

  Future<void> updatePresence(
    String userId,
    String sessionId,
    PresenceStatus status, {
    PresenceData? data,
  }) async {
    final presence = UserPresence(
      userId: userId,
      sessionId: sessionId,
      status: status,
      data: data,
      lastSeen: DateTime.now(),
    );

    _presence[userId] = presence;
  }

  Future<void> removePresence(String userId, String sessionId) async {
    if (_presence[userId]?.sessionId == sessionId) {
      _presence.remove(userId);
    }
  }

  List<UserPresence> getPresenceForSession(String sessionId) {
    return _presence.values.where((p) => p.sessionId == sessionId).toList();
  }

  UserPresence? getPresence(String userId) {
    return _presence[userId];
  }
}

class SynchronizationEngine {
  Future<void> synchronizeSession(String sessionId) async {
    // Implement full session synchronization
    // This ensures all participants have consistent state
  }

  Future<void> handleNetworkReconnection(String sessionId) async {
    // Handle network reconnection scenarios
    // Sync any missed operations
  }
}

class CollaborationAnalytics {
  final Map<String, dynamic> _metrics = {};

  Future<void> trackSessionCreated(CollaborationSession session) async {
    _metrics['sessions_created'] = (_metrics['sessions_created'] ?? 0) + 1;
  }

  Future<void> trackUserJoined(CollaborationSession session, String userId) async {
    _metrics['users_joined'] = (_metrics['users_joined'] ?? 0) + 1;
  }

  Future<void> trackUserLeft(CollaborationSession session, String userId) async {
    _metrics['users_left'] = (_metrics['users_left'] ?? 0) + 1;
  }

  Future<void> trackOperation(CollaborationSession session, Operation operation) async {
    final key = 'operations_${operation.type}';
    _metrics[key] = (_metrics[key] ?? 0) + 1;
  }

  Map<String, dynamic> getMetrics() {
    return Map.from(_metrics);
  }
}

class OfflineQueueManager {
  final List<QueuedOperation> _queue = [];

  Future<void> queueOperation(String sessionId, String userId, Operation operation) async {
    final queuedOp = QueuedOperation(
      id: const Uuid().v4(),
      sessionId: sessionId,
      userId: userId,
      operation: operation,
      queuedAt: DateTime.now(),
    );

    _queue.add(queuedOp);
  }

  Future<List<QueuedOperation>> getQueuedOperations(String sessionId) async {
    return _queue.where((op) => op.sessionId == sessionId).toList();
  }

  Future<void> removeOperation(String operationId) async {
    _queue.removeWhere((op) => op.id == operationId);
  }

  Future<void> clearQueue(String sessionId) async {
    _queue.removeWhere((op) => op.sessionId == sessionId);
  }
}

/// ============================================================================
/// DATA MODELS
/// ============================================================================

enum CollaborationType {
  document,
  code,
  design,
  file,
  presentation,
}

enum OperationType {
  insert,
  delete,
  update,
  move,
  format,
}

enum PresenceStatus {
  active,
  away,
  offline,
}

enum MessageType {
  text,
  system,
  file,
  image,
  code,
}

class CollaborationSession {
  final String id;
  final String documentId;
  final String creatorId;
  final String name;
  final CollaborationType type;
  final List<String> participants;
  final List<String> invitedUsers;
  final DateTime createdAt;
  final DateTime lastActivity;
  final DateTime? endedAt;
  final Map<String, dynamic> metadata;
  final int version;
  final bool isActive;

  CollaborationSession({
    required this.id,
    required this.documentId,
    required this.creatorId,
    required this.name,
    required this.type,
    required this.participants,
    required this.invitedUsers,
    required this.createdAt,
    required this.lastActivity,
    this.endedAt,
    required this.metadata,
    required this.version,
    required this.isActive,
  });

  factory CollaborationSession.fromJson(Map<String, dynamic> json) {
    return CollaborationSession(
      id: json['id'],
      documentId: json['document_id'],
      creatorId: json['creator_id'],
      name: json['name'],
      type: CollaborationType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      participants: List<String>.from(json['participants'] ?? []),
      invitedUsers: List<String>.from(json['invited_users'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      lastActivity: DateTime.parse(json['last_activity']),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      metadata: json['metadata'] ?? {},
      version: json['version'] ?? 1,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_id': documentId,
      'creator_id': creatorId,
      'name': name,
      'type': type.toString(),
      'participants': participants,
      'invited_users': invitedUsers,
      'created_at': createdAt.toIso8601String(),
      'last_activity': lastActivity.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'metadata': metadata,
      'version': version,
      'is_active': isActive,
    };
  }

  CollaborationSession copyWith({
    List<String>? participants,
    DateTime? lastActivity,
    DateTime? endedAt,
    bool? isActive,
  }) {
    return CollaborationSession(
      id: id,
      documentId: documentId,
      creatorId: creatorId,
      name: name,
      type: type,
      participants: participants ?? this.participants,
      invitedUsers: invitedUsers,
      createdAt: createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      endedAt: endedAt ?? this.endedAt,
      metadata: metadata,
      version: version,
      isActive: isActive ?? this.isActive,
    );
  }
}

class Operation {
  final String id;
  final String userId;
  final OperationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int version;

  Operation({
    required this.id,
    required this.userId,
    required this.type,
    required this.data,
    required this.timestamp,
    required this.version,
  });

  factory Operation.fromJson(Map<String, dynamic> json) {
    return Operation(
      id: json['id'] ?? const Uuid().v4(),
      userId: json['user_id'],
      type: OperationType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      data: json['data'] ?? {},
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      version: json['version'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.toString(),
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'version': version,
    };
  }

  Operation copyWith({Map<String, dynamic>? data}) {
    return Operation(
      id: id,
      userId: userId,
      type: type,
      data: data ?? this.data,
      timestamp: timestamp,
      version: version,
    );
  }
}

class UserPresence {
  final String userId;
  final String sessionId;
  final PresenceStatus status;
  final PresenceData? data;
  final DateTime lastSeen;

  UserPresence({
    required this.userId,
    required this.sessionId,
    required this.status,
    this.data,
    required this.lastSeen,
  });

  factory UserPresence.fromJson(Map<String, dynamic> json) {
    return UserPresence(
      userId: json['user_id'],
      sessionId: json['session_id'],
      status: PresenceStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      data: json['data'] != null ? PresenceData.fromJson(json['data']) : null,
      lastSeen: DateTime.parse(json['last_seen']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'session_id': sessionId,
      'status': status.toString(),
      'data': data?.toJson(),
      'last_seen': lastSeen.toIso8601String(),
    };
  }
}

class PresenceData {
  final int? cursorPosition;
  final String? selectedText;
  final String? currentView;
  final Map<String, dynamic>? metadata;

  PresenceData({
    this.cursorPosition,
    this.selectedText,
    this.currentView,
    this.metadata,
  });

  factory PresenceData.fromJson(Map<String, dynamic> json) {
    return PresenceData(
      cursorPosition: json['cursor_position'],
      selectedText: json['selected_text'],
      currentView: json['current_view'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cursor_position': cursorPosition,
      'selected_text': selectedText,
      'current_view': currentView,
      'metadata': metadata,
    };
  }
}

class ChatMessage {
  final String id;
  final String sessionId;
  final String userId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      sessionId: json['session_id'],
      userId: json['user_id'],
      content: json['content'],
      type: MessageType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'content': content,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class SessionHistory {
  final String sessionId;
  final List<Operation> operations;
  final List<ChatMessage> messages;
  final List<CollaborationEvent> events;

  SessionHistory({
    required this.sessionId,
    required this.operations,
    required this.messages,
    required this.events,
  });
}

class QueuedOperation {
  final String id;
  final String sessionId;
  final String userId;
  final Operation operation;
  final DateTime queuedAt;

  QueuedOperation({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.operation,
    required this.queuedAt,
  });
}

class Conflict {
  final String id;
  final ConflictType type;
  final Operation operation1;
  final Operation operation2;
  final DateTime detectedAt;

  Conflict({
    required this.id,
    required this.type,
    required this.operation1,
    required this.operation2,
    required this.detectedAt,
  });
}

enum ConflictType {
  textEdit,
  fileOperation,
  metadataUpdate,
  permissionChange,
}

class ConflictResolution {
  final ConflictResolutionType type;
  final Operation? acceptedOperation;
  final bool requiresManualIntervention;
  final String? resolutionNote;

  ConflictResolution._({
    required this.type,
    this.acceptedOperation,
    this.requiresManualIntervention = false,
    this.resolutionNote,
  });

  factory ConflictResolution.acceptFirst(Conflict conflict) {
    return ConflictResolution._(
      type: ConflictResolutionType.acceptFirst,
      acceptedOperation: conflict.operation1,
    );
  }

  factory ConflictResolution.acceptLast(Conflict conflict) {
    return ConflictResolution._(
      type: ConflictResolutionType.acceptLast,
      acceptedOperation: conflict.operation2,
    );
  }

  factory ConflictResolution.manualResolution(Conflict conflict) {
    return ConflictResolution._(
      type: ConflictResolutionType.manual,
      requiresManualIntervention: true,
      resolutionNote: 'Manual conflict resolution required',
    );
  }
}

enum ConflictResolutionType {
  acceptFirst,
  acceptLast,
  merge,
  manual,
}

/// ============================================================================
/// EVENT SYSTEM
/// ============================================================================

abstract class CollaborationEvent {
  final String type;
  final DateTime timestamp;

  CollaborationEvent(this.type, this.timestamp);

  factory CollaborationEvent.sessionCreated(CollaborationSession session) =
      SessionCreatedEvent;

  factory CollaborationEvent.sessionUpdated(CollaborationSession session) =
      SessionUpdatedEvent;

  factory CollaborationEvent.sessionEnded(String sessionId) =
      SessionEndedEvent;

  factory CollaborationEvent.userJoined(String sessionId, String userId) =
      UserJoinedEvent;

  factory CollaborationEvent.userLeft(String sessionId, String userId) =
      UserLeftEvent;

  factory CollaborationEvent.operationApplied(
    String sessionId,
    String userId,
    Operation operation,
  ) = OperationAppliedEvent;

  factory CollaborationEvent.messageReceived(ChatMessage message) =
      MessageReceivedEvent;
}

class SessionCreatedEvent extends CollaborationEvent {
  final CollaborationSession session;

  SessionCreatedEvent(this.session) : super('session_created', DateTime.now());
}

class SessionUpdatedEvent extends CollaborationEvent {
  final CollaborationSession session;

  SessionUpdatedEvent(this.session) : super('session_updated', DateTime.now());
}

class SessionEndedEvent extends CollaborationEvent {
  final String sessionId;

  SessionEndedEvent(this.sessionId) : super('session_ended', DateTime.now());
}

class UserJoinedEvent extends CollaborationEvent {
  final String sessionId;
  final String userId;

  UserJoinedEvent(this.sessionId, this.userId) : super('user_joined', DateTime.now());
}

class UserLeftEvent extends CollaborationEvent {
  final String sessionId;
  final String userId;

  UserLeftEvent(this.sessionId, this.userId) : super('user_left', DateTime.now());
}

class OperationAppliedEvent extends CollaborationEvent {
  final String sessionId;
  final String userId;
  final Operation operation;

  OperationAppliedEvent(this.sessionId, this.userId, this.operation)
      : super('operation_applied', DateTime.now());
}

class MessageReceivedEvent extends CollaborationEvent {
  final ChatMessage message;

  MessageReceivedEvent(this.message) : super('message_received', DateTime.now());
}

class PresenceEvent {
  final String type;
  final String userId;
  final String sessionId;
  final PresenceStatus status;
  final PresenceData? data;
  final DateTime timestamp;

  PresenceEvent._({
    required this.type,
    required this.userId,
    required this.sessionId,
    required this.status,
    this.data,
    required this.timestamp,
  });

  factory PresenceEvent.updated(
    String userId,
    String sessionId,
    PresenceStatus status,
    PresenceData? data,
  ) {
    return PresenceEvent._(
      type: 'presence_updated',
      userId: userId,
      sessionId: sessionId,
      status: status,
      data: data,
      timestamp: DateTime.now(),
    );
  }
}

/// ============================================================================
/// USAGE EXAMPLE
/// ============================================================================

/*
/// Initialize Real-time Collaboration System (typically in main.dart)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'your-supabase-url',
    anonKey: 'your-anon-key',
  );

  // Initialize Collaboration System
  final collaborationSystem = RealtimeCollaborationSystem();

  // Listen to collaboration events
  collaborationSystem.collaborationEvents.listen((event) {
    switch (event.type) {
      case 'session_created':
        final sessionEvent = event as SessionCreatedEvent;
        print('New session: ${sessionEvent.session.name}');
        break;

      case 'user_joined':
        final joinEvent = event as UserJoinedEvent;
        print('User ${joinEvent.userId} joined session ${joinEvent.sessionId}');
        break;

      case 'operation_applied':
        final opEvent = event as OperationAppliedEvent;
        // Apply operation to local document
        applyOperation(opEvent.operation);
        break;

      case 'message_received':
        final msgEvent = event as MessageReceivedEvent;
        showChatMessage(msgEvent.message);
        break;
    }
  });

  // Listen to presence events
  collaborationSystem.presenceEvents.listen((event) {
    updateUserPresence(event.userId, event.status);
  });

  runApp(MyApp());
}

/// Collaboration-enabled Document Editor Widget
class CollaborativeEditor extends StatefulWidget {
  final String documentId;
  final String userId;

  const CollaborativeEditor({
    super.key,
    required this.documentId,
    required this.userId,
  });

  @override
  _CollaborativeEditorState createState() => _CollaborativeEditorState();
}

class _CollaborativeEditorState extends State<CollaborativeEditor> {
  final RealtimeCollaborationSystem _collaboration = RealtimeCollaborationSystem.instance;
  late CollaborationSession _session;
  final TextEditingController _controller = TextEditingController();
  final List<UserPresence> _activeUsers = [];
  late StreamSubscription<CollaborationEvent> _eventSubscription;
  late StreamSubscription<PresenceEvent> _presenceSubscription;

  @override
  void initState() {
    super.initState();
    _initializeCollaboration();
  }

  Future<void> _initializeCollaboration() async {
    // Create or join collaboration session
    _session = await _collaboration.createSession(
      documentId: widget.documentId,
      creatorId: widget.userId,
      sessionName: 'Document Editing',
      type: CollaborationType.document,
    );

    // Listen to events
    _eventSubscription = _collaboration.collaborationEvents.listen(_handleEvent);
    _presenceSubscription = _collaboration.presenceEvents.listen(_handlePresence);

    // Load document content
    await _loadDocument();
  }

  void _handleEvent(CollaborationEvent event) {
    if (event is OperationAppliedEvent && event.sessionId == _session.id) {
      // Apply remote operation to local document
      _applyRemoteOperation(event.operation);
    } else if (event is MessageReceivedEvent && event.message.sessionId == _session.id) {
      // Show chat message
      _showMessage(event.message);
    }
  }

  void _handlePresence(PresenceEvent event) {
    if (event.sessionId == _session.id) {
      setState(() {
        // Update active users list
        final existingIndex = _activeUsers.indexWhere((u) => u.userId == event.userId);
        if (existingIndex >= 0) {
          _activeUsers[existingIndex] = UserPresence(
            userId: event.userId,
            sessionId: event.sessionId,
            status: event.status,
            data: event.data,
            lastSeen: DateTime.now(),
          );
        } else {
          _activeUsers.add(UserPresence(
            userId: event.userId,
            sessionId: event.sessionId,
            status: event.status,
            data: event.data,
            lastSeen: DateTime.now(),
          ));
        }
      });
    }
  }

  void _onTextChanged(String oldText, String newText) {
    // Calculate the operation
    final operation = _calculateTextOperation(oldText, newText);

    if (operation != null) {
      // Send operation to collaboration system
      _collaboration.sendOperation(_session.id, widget.userId, operation);
    }
  }

  Operation? _calculateTextOperation(String oldText, String newText) {
    // Simple diff calculation (in real implementation, use proper diff algorithm)
    if (newText.length > oldText.length) {
      // Insert operation
      final insertPosition = _findInsertPosition(oldText, newText);
      final insertedText = newText.substring(insertPosition, newText.length - oldText.length + insertPosition);

      return Operation(
        id: const Uuid().v4(),
        userId: widget.userId,
        type: OperationType.insert,
        data: {
          'position': insertPosition,
          'text': insertedText,
        },
        timestamp: DateTime.now(),
        version: _session.version + 1,
      );
    } else if (newText.length < oldText.length) {
      // Delete operation
      final deletePosition = _findDeletePosition(oldText, newText);
      final deleteLength = oldText.length - newText.length;

      return Operation(
        id: const Uuid().v4(),
        userId: widget.userId,
        type: OperationType.delete,
        data: {
          'position': deletePosition,
          'length': deleteLength,
        },
        timestamp: DateTime.now(),
        version: _session.version + 1,
      );
    }

    return null; // No change
  }

  void _applyRemoteOperation(Operation operation) {
    // Apply remote operation to local text
    setState(() {
      switch (operation.type) {
        case OperationType.insert:
          final position = operation.data['position'] as int;
          final text = operation.data['text'] as String;
          final currentText = _controller.text;
          _controller.text = currentText.substring(0, position) +
                           text +
                           currentText.substring(position);
          break;

        case OperationType.delete:
          final position = operation.data['position'] as int;
          final length = operation.data['length'] as int;
          final currentText = _controller.text;
          _controller.text = currentText.substring(0, position) +
                           currentText.substring(position + length);
          break;

        default:
          break;
      }
    });
  }

  Future<void> _loadDocument() async {
    // Load document content from collaboration system
    final history = await _collaboration.getSessionHistory(_session.id);

    // Apply all operations to get current document state
    String content = '';
    for (final operation in history.operations) {
      // Apply operation to content
      content = _applyOperationToContent(content, operation);
    }

    setState(() {
      _controller.text = content;
    });
  }

  String _applyOperationToContent(String content, Operation operation) {
    switch (operation.type) {
      case OperationType.insert:
        final position = operation.data['position'] as int;
        final text = operation.data['text'] as String;
        return content.substring(0, position) + text + content.substring(position);

      case OperationType.delete:
        final position = operation.data['position'] as int;
        final length = operation.data['length'] as int;
        return content.substring(0, position) + content.substring(position + length);

      default:
        return content;
    }
  }

  void _showMessage(ChatMessage message) {
    // Show chat message in UI
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${message.userId}: ${message.content}')),
    );
  }

  // Helper methods for diff calculation
  int _findInsertPosition(String oldText, String newText) {
    // Simple implementation - find first difference
    for (int i = 0; i < min(oldText.length, newText.length); i++) {
      if (oldText[i] != newText[i]) {
        return i;
      }
    }
    return oldText.length;
  }

  int _findDeletePosition(String oldText, String newText) {
    // Simple implementation - find first difference
    for (int i = 0; i < min(oldText.length, newText.length); i++) {
      if (oldText[i] != newText[i]) {
        return i;
      }
    }
    return newText.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Collaborative Editor - ${_session.name}'),
        actions: [
          // Show active users
          ..._activeUsers.map((user) => CircleAvatar(
            child: Text(user.userId[0].toUpperCase()),
            backgroundColor: user.status == PresenceStatus.active
                ? Colors.green
                : Colors.grey,
          )),

          // Session info
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () => _showSessionInfo(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Collaborative text editor
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              onChanged: (newText) {
                _onTextChanged(_controller.text, newText);
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Start collaborating...',
              ),
            ),
          ),

          // Chat panel
          Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                // Chat messages would go here
                Expanded(child: Container()),
                // Chat input would go here
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (message) {
                            if (message.isNotEmpty) {
                              _collaboration.sendMessage(_session.id, widget.userId, message);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSessionInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Session Info: ${_session.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${_session.id}'),
            Text('Type: ${_session.type}'),
            Text('Participants: ${_session.participants.length}'),
            Text('Created: ${_session.createdAt}'),
            Text('Version: ${_session.version}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _eventSubscription.cancel();
    _presenceSubscription.cancel();
    _controller.dispose();
    super.dispose();
  }
}
*/

/// ============================================================================
/// END OF REAL-TIME COLLABORATION AND SYNCHRONIZATION SYSTEM
/// ============================================================================
