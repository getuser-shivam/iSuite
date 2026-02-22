import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';

class CollaborationEngine {
  static CollaborationEngine? _instance;
  static CollaborationEngine get instance =>
      _instance ??= CollaborationEngine._internal();
  CollaborationEngine._internal();

  // WebSocket Connection
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String? _sessionId;
  String? _userId;
  String? _userName;

  // Collaboration State
  final Map<String, CollaborationUser> _users = {};
  final Map<String, CollaborationSession> _sessions = {};
  final List<CollaborationEvent> _events = [];
  final Map<String, dynamic> _sharedState = {};

  // Real-time Sync
  Timer? _heartbeatTimer;
  Timer? _syncTimer;
  final Map<String, DateTime> _lastSync = {};

  // Event Listeners
  final Map<String, List<Function(CollaborationEvent)>> _listeners = {};

  // Configuration
  bool _autoSync = true;
  Duration _syncInterval = Duration(seconds: 5);
  Duration _heartbeatInterval = Duration(seconds: 30);
  int _maxEvents = 1000;

  // Getters
  bool get isConnected => _isConnected;
  String? get sessionId => _sessionId;
  String? get userId => _userId;
  String? get userName => _userName;
  Map<String, CollaborationUser> get users => Map.from(_users);
  Map<String, CollaborationSession> get sessions => Map.from(_sessions);
  List<CollaborationEvent> get events => List.from(_events);
  bool get autoSync => _autoSync;

  /// Initialize collaboration engine
  Future<void> initialize({
    required String userId,
    required String userName,
    String? serverUrl,
  }) async {
    _userId = userId;
    _userName = userName;

    try {
      // Connect to collaboration server
      await _connectToServer(serverUrl ?? 'ws://localhost:8080/collaboration');

      // Start heartbeat
      _startHeartbeat();

      // Start auto-sync
      if (_autoSync) {
        _startAutoSync();
      }

      debugPrint('Collaboration engine initialized for user: $userName');
    } catch (e) {
      debugPrint('Failed to initialize collaboration engine: $e');
      rethrow;
    }
  }

  Future<void> _connectToServer(String serverUrl) async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));

      _channel!.stream.listen(
        _handleServerMessage,
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _isConnected = false;
          _notifyConnectionChange();
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          _isConnected = false;
          _notifyConnectionChange();
        },
      );

      // Send authentication message
      await _sendAuthMessage();

      _isConnected = true;
      _notifyConnectionChange();
    } catch (e) {
      debugPrint('Failed to connect to collaboration server: $e');
      rethrow;
    }
  }

  Future<void> _sendAuthMessage() async {
    final authMessage = {
      'type': 'auth',
      'userId': _userId,
      'userName': _userName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    _channel!.sink.add(jsonEncode(authMessage));
  }

  void _handleServerMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final event = CollaborationEvent.fromMap(data);

      _processEvent(event);
    } catch (e) {
      debugPrint('Error processing server message: $e');
    }
  }

  void _processEvent(CollaborationEvent event) {
    switch (event.type) {
      case CollaborationEventType.authSuccess:
        _sessionId = event.data['sessionId'];
        _broadcastEvent(event);
        break;

      case CollaborationEventType.userJoined:
        final user = CollaborationUser.fromMap(event.data);
        _users[user.id] = user;
        _broadcastEvent(event);
        break;

      case CollaborationEventType.userLeft:
        final userId = event.data['userId'];
        _users.remove(userId);
        _broadcastEvent(event);
        break;

      case CollaborationEventType.sessionCreated:
        final session = CollaborationSession.fromMap(event.data);
        _sessions[session.id] = session;
        _broadcastEvent(event);
        break;

      case CollaborationEventType.sessionUpdated:
        final sessionId = event.data['sessionId'];
        final session = CollaborationSession.fromMap(event.data);
        _sessions[sessionId] = session;
        _broadcastEvent(event);
        break;

      case CollaborationEventType.stateChanged:
        final key = event.data['key'];
        final value = event.data['value'];
        _sharedState[key] = value;
        _broadcastEvent(event);
        break;

      case CollaborationEventType.cursorMoved:
        _broadcastEvent(event);
        break;

      case CollaborationEventType.selectionChanged:
        _broadcastEvent(event);
        break;

      case CollaborationEventType.textChanged:
        _broadcastEvent(event);
        break;

      case CollaborationEventType.heartbeat:
        // Update user last seen
        final userId = event.data['userId'];
        final user = _users[userId];
        if (user != null) {
          _users[userId] = user.copyWith(lastSeen: DateTime.now());
        }
        break;
    }

    // Add to events list
    _events.add(event);
    if (_events.length > _maxEvents) {
      _events.removeAt(0);
    }
  }

  void _broadcastEvent(CollaborationEvent event) {
    // Notify all listeners
    final listeners = _listeners[event.type.name] ?? [];
    for (final listener in listeners) {
      try {
        listener(event);
      } catch (e) {
        debugPrint('Error in event listener: $e');
      }
    }
  }

  void _notifyConnectionChange() {
    final event = CollaborationEvent(
      id: const Uuid().v4(),
      type: _isConnected
          ? CollaborationEventType.connected
          : CollaborationEventType.disconnected,
      userId: _userId,
      sessionId: _sessionId,
      timestamp: DateTime.now(),
      data: {'isConnected': _isConnected},
    );

    _broadcastEvent(event);
  }

  /// Create a new collaboration session
  Future<String> createSession({
    required String name,
    String? description,
    CollaborationSessionType type = CollaborationSessionType.document,
    Map<String, dynamic>? initialData,
  }) async {
    final sessionId = const Uuid().v4();

    final session = CollaborationSession(
      id: sessionId,
      name: name,
      description: description,
      type: type,
      ownerId: _userId!,
      createdAt: DateTime.now(),
      isActive: true,
      participants: [_userId!],
      data: initialData ?? {},
    );

    // Send session creation event
    await _sendEvent(CollaborationEvent(
      id: const Uuid().v4(),
      type: CollaborationEventType.sessionCreated,
      userId: _userId,
      sessionId: _sessionId,
      timestamp: DateTime.now(),
      data: session.toMap(),
    ));

    return sessionId;
  }

  /// Join an existing session
  Future<bool> joinSession(String sessionId) async {
    try {
      await _sendEvent(CollaborationEvent(
        id: const Uuid().v4(),
        type: CollaborationEventType.sessionJoined,
        userId: _userId,
        sessionId: _sessionId,
        timestamp: DateTime.now(),
        data: {'sessionId': sessionId},
      ));

      return true;
    } catch (e) {
      debugPrint('Failed to join session: $e');
      return false;
    }
  }

  /// Leave a session
  Future<bool> leaveSession(String sessionId) async {
    try {
      await _sendEvent(CollaborationEvent(
        id: const Uuid().v4(),
        type: CollaborationEventType.sessionLeft,
        userId: _userId,
        sessionId: _sessionId,
        timestamp: DateTime.now(),
        data: {'sessionId': sessionId},
      ));

      return true;
    } catch (e) {
      debugPrint('Failed to leave session: $e');
      return false;
    }
  }

  /// Update shared state
  Future<void> updateState(String key, dynamic value) async {
    _sharedState[key] = value;

    await _sendEvent(CollaborationEvent(
      id: const Uuid().v4(),
      type: CollaborationEventType.stateChanged,
      userId: _userId,
      sessionId: _sessionId,
      timestamp: DateTime.now(),
      data: {'key': key, 'value': value},
    ));
  }

  /// Send cursor position
  Future<void> sendCursorPosition({
    required String x,
    required String y,
    String? documentId,
  }) async {
    await _sendEvent(CollaborationEvent(
      id: const Uuid().v4(),
      type: CollaborationEventType.cursorMoved,
      userId: _userId,
      sessionId: _sessionId,
      timestamp: DateTime.now(),
      data: {
        'x': x,
        'y': y,
        'documentId': documentId,
      },
    ));
  }

  /// Send text changes
  Future<void> sendTextChange({
    required String text,
    required int position,
    required int length,
    String? documentId,
  }) async {
    await _sendEvent(CollaborationEvent(
      id: const Uuid().v4(),
      type: CollaborationEventType.textChanged,
      userId: _userId,
      sessionId: _sessionId,
      timestamp: DateTime.now(),
      data: {
        'text': text,
        'position': position,
        'length': length,
        'documentId': documentId,
      },
    ));
  }

  /// Send selection change
  Future<void> sendSelectionChange({
    required int start,
    required int end,
    String? documentId,
  }) async {
    await _sendEvent(CollaborationEvent(
      id: const Uuid().v4(),
      type: CollaborationEventType.selectionChanged,
      userId: _userId,
      sessionId: _sessionId,
      timestamp: DateTime.now(),
      data: {
        'start': start,
        'end': end,
        'documentId': documentId,
      },
    ));
  }

  /// Send event to server
  Future<void> _sendEvent(CollaborationEvent event) async {
    if (!_isConnected || _channel == null) {
      debugPrint('Not connected to collaboration server');
      return;
    }

    try {
      _channel!.sink.add(jsonEncode(event.toMap()));
    } catch (e) {
      debugPrint('Failed to send event: $e');
    }
  }

  /// Start heartbeat
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _sendHeartbeat();
    });
  }

  /// Send heartbeat
  Future<void> _sendHeartbeat() async {
    await _sendEvent(CollaborationEvent(
      id: const Uuid().v4(),
      type: CollaborationEventType.heartbeat,
      userId: _userId,
      sessionId: _sessionId,
      timestamp: DateTime.now(),
      data: {},
    ));
  }

  /// Start auto-sync
  void _startAutoSync() {
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      _performAutoSync();
    });
  }

  /// Perform auto-sync
  Future<void> _performAutoSync() async {
    // Sync shared state changes
    for (final entry in _sharedState.entries) {
      final key = entry.key;
      final value = entry.value;
      final lastSync = _lastSync[key];

      if (lastSync == null ||
          DateTime.now().difference(lastSync).inSeconds >
              _syncInterval.inSeconds) {
        await updateState(key, value);
        _lastSync[key] = DateTime.now();
      }
    }
  }

  /// Add event listener
  void addEventListener(
      CollaborationEventType type, Function(CollaborationEvent) listener) {
    _listeners.putIfAbsent(type.name, []).add(listener);
  }

  /// Remove event listener
  void removeEventListener(
      CollaborationEventType type, Function(CollaborationEvent) listener) {
    _listeners[type.name]?.remove(listener);
  }

  /// Get active users in session
  List<CollaborationUser> getActiveUsers() {
    return _users.values
        .where((user) =>
            user.isActive &&
            DateTime.now().difference(user.lastSeen).inMinutes < 5)
        .toList();
  }

  /// Get session statistics
  Map<String, dynamic> getSessionStats(String sessionId) {
    final session = _sessions[sessionId];
    if (session == null) return {};

    final activeUsers = _users.values
        .where(
            (user) => session.participants.contains(user.id) && user.isActive)
        .toList();

    return {
      'participantCount': session.participants.length,
      'activeUserCount': activeUsers.length,
      'duration': DateTime.now().difference(session.createdAt).inMinutes,
      'eventCount': _events.where((e) => e.sessionId == sessionId).length,
      'lastActivity': _events
          .where((e) => e.sessionId == sessionId)
          .map((e) => e.timestamp)
          .fold<DateTime>(
              DateTime(0), (max, time) => time.isAfter(max) ? time : max),
    };
  }

  /// Disconnect from collaboration server
  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _syncTimer?.cancel();

    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }

    _isConnected = false;
    _sessionId = null;
    _users.clear();
    _sessions.clear();
    _events.clear();
    _sharedState.clear();
    _lastSync.clear();

    debugPrint('Disconnected from collaboration server');
  }

  /// Dispose collaboration engine
  void dispose() {
    disconnect();
    _listeners.clear();
  }
}

// Collaboration Models
class CollaborationUser {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isActive;
  final DateTime lastSeen;
  final Map<String, dynamic>? metadata;

  const CollaborationUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isActive = true,
    required this.lastSeen,
    this.metadata,
  });

  CollaborationUser copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? isActive,
    DateTime? lastSeen,
    Map<String, dynamic>? metadata,
  }) {
    return CollaborationUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      lastSeen: lastSeen ?? this.lastSeen,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'isActive': isActive,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  factory CollaborationUser.fromMap(Map<String, dynamic> map) {
    return CollaborationUser(
      id: map['id'],
      name: map['name'],
      avatarUrl: map['avatarUrl'],
      isActive: map['isActive'] ?? true,
      lastSeen: DateTime.fromMillisecondsSinceEpoch(map['lastSeen']),
      metadata: map['metadata'],
    );
  }
}

class CollaborationSession {
  final String id;
  final String name;
  final String? description;
  final CollaborationSessionType type;
  final String ownerId;
  final DateTime createdAt;
  final bool isActive;
  final List<String> participants;
  final Map<String, dynamic> data;

  const CollaborationSession({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.ownerId,
    required this.createdAt,
    this.isActive = true,
    required this.participants,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'ownerId': ownerId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isActive': isActive,
      'participants': participants,
      'data': data,
    };
  }

  factory CollaborationSession.fromMap(Map<String, dynamic> map) {
    return CollaborationSession(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      type: CollaborationSessionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CollaborationSessionType.document,
      ),
      ownerId: map['ownerId'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      isActive: map['isActive'] ?? true,
      participants: List<String>.from(map['participants'] ?? []),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
    );
  }
}

class CollaborationEvent {
  final String id;
  final CollaborationEventType type;
  final String? userId;
  final String? sessionId;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const CollaborationEvent({
    required this.id,
    required this.type,
    this.userId,
    this.sessionId,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'userId': userId,
      'sessionId': sessionId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'data': data,
    };
  }

  factory CollaborationEvent.fromMap(Map<String, dynamic> map) {
    return CollaborationEvent(
      id: map['id'],
      type: CollaborationEventType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CollaborationEventType.unknown,
      ),
      userId: map['userId'],
      sessionId: map['sessionId'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
    );
  }
}

// Enums
enum CollaborationEventType {
  connected,
  disconnected,
  authSuccess,
  userJoined,
  userLeft,
  sessionCreated,
  sessionUpdated,
  sessionJoined,
  sessionLeft,
  stateChanged,
  cursorMoved,
  selectionChanged,
  textChanged,
  heartbeat,
  unknown,
}

enum CollaborationSessionType {
  document,
  whiteboard,
  code,
  design,
  meeting,
  chat,
}
