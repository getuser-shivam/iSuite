import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/collaboration_engine.dart';
import '../../core/base_component.dart';
import '../../core/utils.dart';
import '../../domain/models/task.dart';
import '../../domain/models/note.dart';

class CollaborationProvider extends BaseProvider {
  static const String _id = 'collaboration_provider';
  
  @override
  String get id => _id;
  
  @override
  String get name => 'Collaboration Provider';
  
  @override
  String get version => '1.0.0';
  
  @override
  List<Type> get dependencies => [];

  final CollaborationEngine _engine = CollaborationEngine.instance;
  
  // Collaboration State
  bool _isConnected = false;
  String? _currentSessionId;
  List<CollaborationUser> _activeUsers = [];
  List<CollaborationSession> _availableSessions = [];
  List<CollaborationEvent> _recentEvents = [];
  Map<String, dynamic> _sharedState = {};
  String? _error;
  
  // Real-time Features
  bool _autoSync = true;
  bool _showCursors = true;
  bool _showSelections = true;
  Map<String, CollaborationCursor> _cursors = {};
  Map<String, CollaborationSelection> _selections = {};
  
  // Getters
  bool get isConnected => _isConnected;
  String? get currentSessionId => _currentSessionId;
  List<CollaborationUser> get activeUsers => List.from(_activeUsers);
  List<CollaborationSession> get availableSessions => List.from(_availableSessions);
  List<CollaborationEvent> get recentEvents => List.from(_recentEvents);
  Map<String, dynamic> get sharedState => Map.from(_sharedState);
  String? get error => _error;
  bool get autoSync => _autoSync;
  bool get showCursors => _showCursors;
  bool get showSelections => _showSelections;
  Map<String, CollaborationCursor> get cursors => Map.from(_cursors);
  Map<String, CollaborationSelection> get selections => Map.from(_selections);

  CollaborationProvider() {
    // Set default parameters
    _parameters['auto_sync'] = true;
    _parameters['show_cursors'] = true;
    _parameters['show_selections'] = true;
    _parameters['max_events'] = 100;
    _parameters['sync_interval'] = Duration(seconds: 5);
    _parameters['heartbeat_interval'] = Duration(seconds: 30);
  }

  @override
  Future<void> onInitialize() async {
    try {
      // Set up event listeners
      _setupEventListeners();
      
      AppUtils.logInfo('CollaborationProvider', 'Collaboration provider initialized');
    } catch (e) {
      setError('Failed to initialize collaboration provider: $e');
      AppUtils.logError('CollaborationProvider', 'Initialization failed', e);
    }
  }

  void _setupEventListeners() {
    // Connection events
    _engine.addEventListener(CollaborationEventType.connected, _handleConnected);
    _engine.addEventListener(CollaborationEventType.disconnected, _handleDisconnected);
    
    // User events
    _engine.addEventListener(CollaborationEventType.userJoined, _handleUserJoined);
    _engine.addEventListener(CollaborationEventType.userLeft, _handleUserLeft);
    
    // Session events
    _engine.addEventListener(CollaborationEventType.sessionCreated, _handleSessionCreated);
    _engine.addEventListener(CollaborationEventType.sessionUpdated, _handleSessionUpdated);
    
    // State events
    _engine.addEventListener(CollaborationEventType.stateChanged, _handleStateChanged);
    
    // Real-time events
    _engine.addEventListener(CollaborationEventType.cursorMoved, _handleCursorMoved);
    _engine.addEventListener(CollaborationEventType.selectionChanged, _handleSelectionChanged);
    _engine.addEventListener(CollaborationEventType.textChanged, _handleTextChanged);
  }

  Future<bool> connect({
    required String userId,
    required String userName,
    String? serverUrl,
  }) async {
    try {
      clearError();
      
      await _engine.initialize(
        userId: userId,
        userName: userName,
        serverUrl: serverUrl,
      );
      
      return true;
    } catch (e) {
      setError('Failed to connect: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _engine.disconnect();
      _isConnected = false;
      _currentSessionId = null;
      _activeUsers.clear();
      _availableSessions.clear();
      _recentEvents.clear();
      _cursors.clear();
      _selections.clear();
      notifyListeners();
    } catch (e) {
      setError('Failed to disconnect: $e');
    }
  }

  Future<String> createSession({
    required String name,
    String? description,
    CollaborationSessionType type = CollaborationSessionType.document,
    Map<String, dynamic>? initialData,
  }) async {
    try {
      final sessionId = await _engine.createSession(
        name: name,
        description: description,
        type: type,
        initialData: initialData,
      );
      
      return sessionId;
    } catch (e) {
      setError('Failed to create session: $e');
      rethrow;
    }
  }

  Future<bool> joinSession(String sessionId) async {
    try {
      final success = await _engine.joinSession(sessionId);
      if (success) {
        _currentSessionId = sessionId;
      }
      return success;
    } catch (e) {
      setError('Failed to join session: $e');
      return false;
    }
  }

  Future<bool> leaveSession() async {
    if (_currentSessionId == null) return true;
    
    try {
      final success = await _engine.leaveSession(_currentSessionId!);
      if (success) {
        _currentSessionId = null;
      }
      return success;
    } catch (e) {
      setError('Failed to leave session: $e');
      return false;
    }
  }

  Future<void> updateSharedState(String key, dynamic value) async {
    try {
      _sharedState[key] = value;
      await _engine.updateState(key, value);
    } catch (e) {
      setError('Failed to update shared state: $e');
    }
  }

  Future<void> sendCursorPosition({
    required String x,
    required String y,
    String? documentId,
  }) async {
    try {
      await _engine.sendCursorPosition(
        x: x,
        y: y,
        documentId: documentId ?? _currentSessionId,
      );
    } catch (e) {
      setError('Failed to send cursor position: $e');
    }
  }

  Future<void> sendTextChange({
    required String text,
    required int position,
    required int length,
    String? documentId,
  }) async {
    try {
      await _engine.sendTextChange(
        text: text,
        position: position,
        length: length,
        documentId: documentId ?? _currentSessionId,
      );
    } catch (e) {
      setError('Failed to send text change: $e');
    }
  }

  Future<void> sendSelectionChange({
    required int start,
    required int end,
    String? documentId,
  }) async {
    try {
      await _engine.sendSelectionChange(
        start: start,
        end: end,
        documentId: documentId ?? _currentSessionId,
      );
    } catch (e) {
      setError('Failed to send selection change: $e');
    }
  }

  // Task Collaboration
  Future<void> shareTask(Task task) async {
    try {
      await updateSharedState('task_${task.id}', task.toMap());
    } catch (e) {
      setError('Failed to share task: $e');
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await updateSharedState('task_${task.id}', task.toMap());
    } catch (e) {
      setError('Failed to update task: $e');
    }
  }

  Future<void> completeTask(String taskId) async {
    try {
      await updateSharedState('task_${taskId}_completed', true);
    } catch (e) {
      setError('Failed to complete task: $e');
    }
  }

  // Note Collaboration
  Future<void> shareNote(Note note) async {
    try {
      await updateSharedState('note_${note.id}', note.toMap());
    } catch (e) {
      setError('Failed to share note: $e');
    }
  }

  Future<void> updateNote(Note note) async {
    try {
      await updateSharedState('note_${note.id}', note.toMap());
    } catch (e) {
      setError('Failed to update note: $e');
    }
  }

  // Event Handlers
  void _handleConnected(CollaborationEvent event) {
    _isConnected = true;
    clearError();
    notifyListeners();
    AppUtils.logInfo('CollaborationProvider', 'Connected to collaboration server');
  }

  void _handleDisconnected(CollaborationEvent event) {
    _isConnected = false;
    _currentSessionId = null;
    _activeUsers.clear();
    notifyListeners();
    AppUtils.logInfo('CollaborationProvider', 'Disconnected from collaboration server');
  }

  void _handleUserJoined(CollaborationEvent event) {
    final user = CollaborationUser.fromMap(event.data);
    _activeUsers.add(user);
    notifyListeners();
    AppUtils.logInfo('CollaborationProvider', 'User joined: ${user.name}');
  }

  void _handleUserLeft(CollaborationEvent event) {
    final userId = event.data['userId'];
    _activeUsers.removeWhere((user) => user.id == userId);
    notifyListeners();
    AppUtils.logInfo('CollaborationProvider', 'User left: $userId');
  }

  void _handleSessionCreated(CollaborationEvent event) {
    final session = CollaborationSession.fromMap(event.data);
    _availableSessions.add(session);
    notifyListeners();
    AppUtils.logInfo('CollaborationProvider', 'Session created: ${session.name}');
  }

  void _handleSessionUpdated(CollaborationEvent event) {
    final session = CollaborationSession.fromMap(event.data);
    final index = _availableSessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      _availableSessions[index] = session;
      notifyListeners();
    }
  }

  void _handleStateChanged(CollaborationEvent event) {
    final key = event.data['key'];
    final value = event.data['value'];
    _sharedState[key] = value;
    notifyListeners();
    
    // Handle specific state changes
    if (key.startsWith('task_') && !key.endsWith('_completed')) {
      _handleTaskStateChange(key, value);
    } else if (key.startsWith('note_')) {
      _handleNoteStateChange(key, value);
    }
  }

  void _handleTaskStateChange(String key, dynamic value) {
    // Notify task provider about changes
    // This would integrate with TaskProvider
    AppUtils.logInfo('CollaborationProvider', 'Task state changed: $key');
  }

  void _handleNoteStateChange(String key, dynamic value) {
    // Notify note provider about changes
    // This would integrate with NoteProvider
    AppUtils.logInfo('CollaborationProvider', 'Note state changed: $key');
  }

  void _handleCursorMoved(CollaborationEvent event) {
    if (!_showCursors) return;
    
    final cursor = CollaborationCursor(
      userId: event.userId!,
      x: event.data['x'],
      y: event.data['y'],
      timestamp: event.timestamp,
    );
    
    _cursors[event.userId!] = cursor;
    notifyListeners();
  }

  void _handleSelectionChanged(CollaborationEvent event) {
    if (!_showSelections) return;
    
    final selection = CollaborationSelection(
      userId: event.userId!,
      start: event.data['start'],
      end: event.data['end'],
      timestamp: event.timestamp,
    );
    
    _selections[event.userId!] = selection;
    notifyListeners();
  }

  void _handleTextChanged(CollaborationEvent event) {
    // Handle text changes for collaborative editing
    _recentEvents.insert(0, event);
    
    final maxEvents = getParameter<int>('max_events', 100);
    if (_recentEvents.length > maxEvents) {
      _recentEvents.removeRange(maxEvents, _recentEvents.length);
    }
    
    notifyListeners();
  }

  // Utility Methods
  List<CollaborationUser> getActiveUsersInSession(String sessionId) {
    return _activeUsers.where((user) => 
        _engine.sessions[sessionId]?.participants.contains(user.id) ?? false
    ).toList();
  }

  Map<String, dynamic> getSessionStats(String sessionId) {
    return _engine.getSessionStats(sessionId);
  }

  void toggleAutoSync() {
    _autoSync = !_autoSync;
    setParameter('auto_sync', _autoSync);
    notifyListeners();
  }

  void toggleCursors() {
    _showCursors = !_showCursors;
    setParameter('show_cursors', _showCursors);
    if (!_showCursors) {
      _cursors.clear();
    }
    notifyListeners();
  }

  void toggleSelections() {
    _showSelections = !_showSelections;
    setParameter('show_selections', _showSelections);
    if (!_showSelections) {
      _selections.clear();
    }
    notifyListeners();
  }

  Future<void> refreshSessions() async {
    _availableSessions.clear();
    // This would fetch available sessions from server
    notifyListeners();
  }

  Future<void> refreshUsers() async {
    _activeUsers.clear();
    // This would fetch active users from server
    notifyListeners();
  }

  @override
  void onDispose() {
    _engine.dispose();
    super.dispose();
  }
}

// Collaboration Models
class CollaborationCursor {
  final String userId;
  final String x;
  final String y;
  final DateTime timestamp;

  const CollaborationCursor({
    required this.userId,
    required this.x,
    required this.y,
    required this.timestamp,
  });
}

class CollaborationSelection {
  final String userId;
  final int start;
  final int end;
  final DateTime timestamp;

  const CollaborationSelection({
    required this.userId,
    required this.start,
    required this.end,
    required this.timestamp,
  });
}
