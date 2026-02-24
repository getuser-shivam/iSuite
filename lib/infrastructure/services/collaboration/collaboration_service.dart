import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../../../core/logging/logging_service.dart';
import '../../../core/central_config.dart';
import '../../../services/notifications/notification_service.dart';

/// Real-time Collaboration Service
/// Enables live file sharing, synchronization, and team collaboration features
class CollaborationService {
  static final CollaborationService _instance = CollaborationService._internal();
  factory CollaborationService() => _instance;
  CollaborationService._internal();

  final LoggingService _logger = LoggingService();
  final CentralConfig _config = CentralConfig.instance;

  WebSocketChannel? _channel;
  final StreamController<CollaborationEvent> _eventController = StreamController<CollaborationEvent>.broadcast();
  final Map<String, CollaborationSession> _activeSessions = {};
  final Map<String, List<Collaborator>> _sessionCollaborators = {};

  bool _isConnected = false;
  String? _currentUserId;
  String? _currentSessionId;

  /// Initialize collaboration service
  Future<void> initialize(String userId) async {
    try {
      _logger.info('Initializing Collaboration Service for user: $userId', 'CollaborationService');

      _currentUserId = userId;

      // Connect to collaboration server
      await _connectToServer();

      // Load existing sessions
      await _loadActiveSessions();

      _logger.info('Collaboration Service initialized successfully', 'CollaborationService');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Collaboration Service', 'CollaborationService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get collaboration events stream
  Stream<CollaborationEvent> get events => _eventController.stream;

  /// Check if service is connected
  bool get isConnected => _isConnected;

  /// Get active sessions
  Map<String, CollaborationSession> get activeSessions => Map.unmodifiable(_activeSessions);

  /// Create new collaboration session
  Future<CollaborationSession> createSession({
    required String sessionName,
    required List<String> fileIds,
    required CollaborationType type,
    String? description,
    Map<String, dynamic>? settings,
  }) async {
    try {
      _logger.info('Creating collaboration session: $sessionName', 'CollaborationService');

      final session = CollaborationSession(
        id: _generateSessionId(),
        name: sessionName,
        creatorId: _currentUserId!,
        fileIds: fileIds,
        type: type,
        description: description,
        settings: settings ?? {},
        createdAt: DateTime.now(),
        isActive: true,
        collaborators: [_currentUserId!],
      );

      _activeSessions[session.id] = session;
      _sessionCollaborators[session.id] = [Collaborator(
        userId: _currentUserId!,
        role: CollaborationRole.owner,
        joinedAt: DateTime.now(),
        isOnline: true,
      )];

      // Broadcast session creation
      _sendMessage({
        'type': 'session_created',
        'session': session.toJson(),
      });

      _eventController.add(CollaborationEvent(
        type: CollaborationEventType.sessionCreated,
        sessionId: session.id,
        data: {'session': session},
      ));

      _logger.info('Collaboration session created: ${session.id}', 'CollaborationService');
      return session;

    } catch (e, stackTrace) {
      _logger.error('Failed to create collaboration session', 'CollaborationService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Join existing collaboration session
  Future<bool> joinSession(String sessionId, {String? accessCode}) async {
    try {
      _logger.info('Joining collaboration session: $sessionId', 'CollaborationService');

      // Verify session exists and user can join
      final session = _activeSessions[sessionId];
      if (session == null) {
        throw Exception('Session not found: $sessionId');
      }

      if (!session.isActive) {
        throw Exception('Session is not active: $sessionId');
      }

      // Add user to session
      if (!session.collaborators.contains(_currentUserId)) {
        session.collaborators.add(_currentUserId!);
        _sessionCollaborators[sessionId] ??= [];
        _sessionCollaborators[sessionId]!.add(Collaborator(
          userId: _currentUserId!,
          role: CollaborationRole.participant,
          joinedAt: DateTime.now(),
          isOnline: true,
        ));
      }

      _currentSessionId = sessionId;

      // Broadcast user joined
      _sendMessage({
        'type': 'user_joined',
        'sessionId': sessionId,
        'userId': _currentUserId,
      });

      _eventController.add(CollaborationEvent(
        type: CollaborationEventType.userJoined,
        sessionId: sessionId,
        data: {'userId': _currentUserId},
      ));

      _logger.info('Successfully joined collaboration session: $sessionId', 'CollaborationService');
      return true;

    } catch (e, stackTrace) {
      _logger.error('Failed to join collaboration session: $sessionId', 'CollaborationService',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Leave current collaboration session
  Future<void> leaveSession() async {
    if (_currentSessionId == null) return;

    try {
      _logger.info('Leaving collaboration session: $_currentSessionId', 'CollaborationService');

      final sessionId = _currentSessionId!;

      // Remove user from session
      final session = _activeSessions[sessionId];
      if (session != null) {
        session.collaborators.remove(_currentUserId);
        _sessionCollaborators[sessionId]?.removeWhere((c) => c.userId == _currentUserId);
      }

      // Broadcast user left
      _sendMessage({
        'type': 'user_left',
        'sessionId': sessionId,
        'userId': _currentUserId,
      });

      _eventController.add(CollaborationEvent(
        type: CollaborationEventType.userLeft,
        sessionId: sessionId,
        data: {'userId': _currentUserId},
      ));

      _currentSessionId = null;

      _logger.info('Successfully left collaboration session', 'CollaborationService');

    } catch (e, stackTrace) {
      _logger.error('Failed to leave collaboration session', 'CollaborationService',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Send file change event
  Future<void> sendFileChange({
    required String fileId,
    required String changeType,
    required Map<String, dynamic> changeData,
  }) async {
    if (_currentSessionId == null) return;

    try {
      final event = {
        'type': 'file_change',
        'sessionId': _currentSessionId,
        'fileId': fileId,
        'changeType': changeType,
        'changeData': changeData,
        'userId': _currentUserId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _sendMessage(event);

      _eventController.add(CollaborationEvent(
        type: CollaborationEventType.fileChanged,
        sessionId: _currentSessionId!,
        data: event,
      ));

    } catch (e, stackTrace) {
      _logger.error('Failed to send file change event', 'CollaborationService',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Send cursor position update
  Future<void> sendCursorUpdate(String fileId, int position, {String? selection}) async {
    if (_currentSessionId == null) return;

    try {
      final event = {
        'type': 'cursor_update',
        'sessionId': _currentSessionId,
        'fileId': fileId,
        'userId': _currentUserId,
        'position': position,
        'selection': selection,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _sendMessage(event);

      _eventController.add(CollaborationEvent(
        type: CollaborationEventType.cursorMoved,
        sessionId: _currentSessionId!,
        data: event,
      ));

    } catch (e, stackTrace) {
      _logger.error('Failed to send cursor update', 'CollaborationService',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Send typing indicator
  Future<void> sendTypingIndicator(String fileId, bool isTyping) async {
    if (_currentSessionId == null) return;

    try {
      final event = {
        'type': 'typing_indicator',
        'sessionId': _currentSessionId,
        'fileId': fileId,
        'userId': _currentUserId,
        'isTyping': isTyping,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _sendMessage(event);

    } catch (e, stackTrace) {
      _logger.error('Failed to send typing indicator', 'CollaborationService',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Get collaborators for current session
  List<Collaborator> getCurrentCollaborators() {
    if (_currentSessionId == null) return [];
    return _sessionCollaborators[_currentSessionId] ?? [];
  }

  /// Get session activity feed
  Future<List<ActivityItem>> getSessionActivity(String sessionId, {int limit = 50}) async {
    // Implementation would fetch activity from server/local storage
    // For now, return mock data
    return [
      ActivityItem(
        id: '1',
        sessionId: sessionId,
        userId: _currentUserId!,
        action: 'joined_session',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        metadata: {},
      ),
    ];
  }

  /// Invite user to session
  Future<bool> inviteUser(String sessionId, String userEmail, {String? message}) async {
    try {
      _logger.info('Inviting user $userEmail to session $sessionId', 'CollaborationService');

      // Implementation would send invitation via email/API
      _sendMessage({
        'type': 'user_invited',
        'sessionId': sessionId,
        'inviteeEmail': userEmail,
        'inviterId': _currentUserId,
        'message': message,
      });

      return true;

    } catch (e, stackTrace) {
      _logger.error('Failed to invite user to session', 'CollaborationService',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Connect to collaboration server
  Future<void> _connectToServer() async {
    try {
      final serverUrl = _config.getParameter('collaboration.server_url',
          defaultValue: 'ws://localhost:8080/ws');

      _channel = IOWebSocketChannel.connect(Uri.parse(serverUrl));

      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          _logger.error('WebSocket error', 'CollaborationService', error: error);
          _isConnected = false;
        },
        onDone: () {
          _logger.info('WebSocket connection closed', 'CollaborationService');
          _isConnected = false;
        },
      );

      // Send authentication
      _sendMessage({
        'type': 'authenticate',
        'userId': _currentUserId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _isConnected = true;
      _logger.info('Connected to collaboration server', 'CollaborationService');

    } catch (e, stackTrace) {
      _logger.error('Failed to connect to collaboration server', 'CollaborationService',
          error: e, stackTrace: stackTrace);
      _isConnected = false;
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);

      switch (data['type']) {
        case 'session_created':
          _handleSessionCreated(data);
          break;
        case 'user_joined':
          _handleUserJoined(data);
          break;
        case 'user_left':
          _handleUserLeft(data);
          break;
        case 'file_change':
          _handleFileChange(data);
          break;
        case 'cursor_update':
          _handleCursorUpdate(data);
          break;
        case 'typing_indicator':
          _handleTypingIndicator(data);
          break;
        case 'session_ended':
          _handleSessionEnded(data);
          break;
      }

    } catch (e, stackTrace) {
      _logger.error('Failed to handle WebSocket message', 'CollaborationService',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Send message via WebSocket
  void _sendMessage(Map<String, dynamic> message) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  /// Load active sessions from server/storage
  Future<void> _loadActiveSessions() async {
    // Implementation would load sessions from server or local storage
    _logger.debug('Loading active collaboration sessions', 'CollaborationService');
  }

  /// Generate unique session ID
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${_currentUserId}';
  }

  // Event handlers
  void _handleSessionCreated(Map<String, dynamic> data) {
    final session = CollaborationSession.fromJson(data['session']);
    _activeSessions[session.id] = session;

    _eventController.add(CollaborationEvent(
      type: CollaborationEventType.sessionCreated,
      sessionId: session.id,
      data: data,
    ));
  }

  void _handleUserJoined(Map<String, dynamic> data) {
    final sessionId = data['sessionId'] as String;
    final userId = data['userId'] as String;

    final session = _activeSessions[sessionId];
    if (session != null && !session.collaborators.contains(userId)) {
      session.collaborators.add(userId);
    }

    _eventController.add(CollaborationEvent(
      type: CollaborationEventType.userJoined,
      sessionId: sessionId,
      data: data,
    ));
  }

  void _handleUserLeft(Map<String, dynamic> data) {
    final sessionId = data['sessionId'] as String;
    final userId = data['userId'] as String;

    final session = _activeSessions[sessionId];
    if (session != null) {
      session.collaborators.remove(userId);
    }

    _eventController.add(CollaborationEvent(
      type: CollaborationEventType.userLeft,
      sessionId: sessionId,
      data: data,
    ));
  }

  void _handleFileChange(Map<String, dynamic> data) {
    _eventController.add(CollaborationEvent(
      type: CollaborationEventType.fileChanged,
      sessionId: data['sessionId'],
      data: data,
    ));
  }

  void _handleCursorUpdate(Map<String, dynamic> data) {
    _eventController.add(CollaborationEvent(
      type: CollaborationEventType.cursorMoved,
      sessionId: data['sessionId'],
      data: data,
    ));
  }

  void _handleTypingIndicator(Map<String, dynamic> data) {
    _eventController.add(CollaborationEvent(
      type: CollaborationEventType.typingIndicator,
      sessionId: data['sessionId'],
      data: data,
    ));
  }

  void _handleSessionEnded(Map<String, dynamic> data) {
    final sessionId = data['sessionId'] as String;
    final session = _activeSessions[sessionId];
    if (session != null) {
      session.isActive = false;
    }

    _eventController.add(CollaborationEvent(
      type: CollaborationEventType.sessionEnded,
      sessionId: sessionId,
      data: data,
    ));
  }

  /// Dispose resources
  void dispose() {
    _channel?.sink.close();
    _eventController.close();
    _activeSessions.clear();
    _sessionCollaborators.clear();
  }
}

/// Collaboration session model
class CollaborationSession {
  final String id;
  final String name;
  final String creatorId;
  final List<String> fileIds;
  final CollaborationType type;
  final String? description;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  bool isActive;
  final List<String> collaborators;

  CollaborationSession({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.fileIds,
    required this.type,
    this.description,
    required this.settings,
    required this.createdAt,
    required this.isActive,
    required this.collaborators,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'creatorId': creatorId,
    'fileIds': fileIds,
    'type': type.name,
    'description': description,
    'settings': settings,
    'createdAt': createdAt.toIso8601String(),
    'isActive': isActive,
    'collaborators': collaborators,
  };

  factory CollaborationSession.fromJson(Map<String, dynamic> json) {
    return CollaborationSession(
      id: json['id'],
      name: json['name'],
      creatorId: json['creatorId'],
      fileIds: List<String>.from(json['fileIds']),
      type: CollaborationType.values.firstWhere((e) => e.name == json['type']),
      description: json['description'],
      settings: Map<String, dynamic>.from(json['settings']),
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'],
      collaborators: List<String>.from(json['collaborators']),
    );
  }
}

/// Collaboration type
enum CollaborationType {
  documentEditing,
  fileSharing,
  codeReview,
  brainstorming,
  projectPlanning,
}

/// Collaboration role
enum CollaborationRole {
  owner,
  editor,
  viewer,
}

/// Collaborator information
class Collaborator {
  final String userId;
  final CollaborationRole role;
  final DateTime joinedAt;
  final bool isOnline;
  final Map<String, dynamic>? metadata;

  Collaborator({
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.isOnline,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'role': role.name,
    'joinedAt': joinedAt.toIso8601String(),
    'isOnline': isOnline,
    'metadata': metadata,
  };
}

/// Activity item for session history
class ActivityItem {
  final String id;
  final String sessionId;
  final String userId;
  final String action;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  ActivityItem({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.action,
    required this.timestamp,
    required this.metadata,
  });
}

/// Collaboration event
class CollaborationEvent {
  final CollaborationEventType type;
  final String sessionId;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  CollaborationEvent({
    required this.type,
    required this.sessionId,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Collaboration event types
enum CollaborationEventType {
  sessionCreated,
  sessionEnded,
  userJoined,
  userLeft,
  fileChanged,
  cursorMoved,
  typingIndicator,
}
