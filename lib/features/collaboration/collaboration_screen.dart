import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/central_config.dart';
import '../../../core/accessibility_manager.dart';
import '../../../services/collaboration/collaboration_service.dart';
import '../../../services/notifications/notification_service.dart';

/// Collaboration Screen - Real-time team collaboration interface
class CollaborationScreen extends StatefulWidget {
  const CollaborationScreen({super.key});

  @override
  State<CollaborationScreen> createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends State<CollaborationScreen> {
  final CollaborationService _collaborationService = CollaborationService();
  final AccessibilityManager _accessibility = AccessibilityManager();

  List<CollaborationSession> _sessions = [];
  List<Collaborator> _currentCollaborators = [];
  bool _isLoading = true;
  String? _currentSessionId;

  @override
  void initState() {
    super.initState();
    _initializeCollaboration();
    _announceScreenEntry();
  }

  void _announceScreenEntry() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _accessibility.announceToScreenReader(
        'Collaboration screen opened. Create or join team sessions for real-time file collaboration.',
        assertion: 'screen opened',
      );
    });
  }

  Future<void> _initializeCollaboration() async {
    setState(() => _isLoading = true);

    try {
      // Initialize with current user ID (would come from auth service)
      await _collaborationService.initialize('current_user_id');

      // Listen to collaboration events
      _collaborationService.events.listen(_handleCollaborationEvent);

      // Load sessions
      setState(() {
        _sessions = _collaborationService.activeSessions.values.toList();
        _isLoading = false;
      });

    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to initialize collaboration: $e');
    }
  }

  void _handleCollaborationEvent(CollaborationEvent event) {
    switch (event.type) {
      case CollaborationEventType.sessionCreated:
        setState(() {
          _sessions.add(event.data['session'] as CollaborationSession);
        });
        break;

      case CollaborationEventType.userJoined:
        if (event.sessionId == _currentSessionId) {
          _loadCurrentCollaborators();
        }
        break;

      case CollaborationEventType.userLeft:
        if (event.sessionId == _currentSessionId) {
          _loadCurrentCollaborators();
        }
        break;

      case CollaborationEventType.sessionEnded:
        setState(() {
          _sessions.removeWhere((s) => s.id == event.sessionId);
        });
        if (_currentSessionId == event.sessionId) {
          _currentSessionId = null;
          _currentCollaborators.clear();
        }
        break;

      default:
        // Handle other events
        break;
    }
  }

  void _loadCurrentCollaborators() {
    if (_currentSessionId != null) {
      setState(() {
        _currentCollaborators = _collaborationService.getCurrentCollaborators();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = CentralConfig.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Collaboration'),
        backgroundColor: config.primaryColor,
        foregroundColor: config.surfaceColor,
        elevation: config.getParameter('ui.app_bar.elevation', defaultValue: 4.0),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewSession,
            tooltip: 'Create new session',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSessions,
            tooltip: 'Refresh sessions',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildMainContent(),
      floatingActionButton: _currentSessionId != null
          ? FloatingActionButton.extended(
              onPressed: _leaveCurrentSession,
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Leave Session'),
              backgroundColor: Colors.red,
            )
          : null,
    );
  }

  Widget _buildMainContent() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.group_work), text: 'Sessions'),
              Tab(icon: Icon(Icons.people), text: 'Collaborators'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSessionsTab(),
                _buildCollaboratorsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsTab() {
    if (_sessions.isEmpty) {
      return _buildEmptyState(
        'No Active Sessions',
        'Create a new collaboration session to start working with your team.',
        Icons.group_work,
        _createNewSession,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(CentralConfig.instance.getParameter('ui.spacing.medium', defaultValue: 20.0)),
      itemCount: _sessions.length,
      itemBuilder: (context, index) => _buildSessionCard(_sessions[index]),
    );
  }

  Widget _buildSessionCard(CollaborationSession session) {
    final isCurrentSession = session.id == _currentSessionId;
    final accessibleColors = _accessibility.getAccessibleColors(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: CentralConfig.instance.getParameter('ui.shadow.elevation.low', defaultValue: 2.0),
      color: isCurrentSession ? accessibleColors.primary.withOpacity(0.1) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accessibleColors.primary,
          child: Icon(
            _getSessionIcon(session.type),
            color: accessibleColors.onPrimary,
          ),
        ),
        title: Text(
          session.name,
          style: TextStyle(
            fontWeight: isCurrentSession ? FontWeight.bold : FontWeight.normal,
            color: isCurrentSession ? accessibleColors.primary : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${session.collaborators.length} collaborators • ${session.type.name}'),
            if (session.description != null)
              Text(
                session.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              'Created ${session.createdAt.toString().split('.')[0]}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (session.isActive)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              )
            else
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) => _handleSessionAction(session, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'join',
                  child: Text('Join Session'),
                ),
                const PopupMenuItem(
                  value: 'invite',
                  child: Text('Invite Users'),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Text('Session Settings'),
                ),
                if (session.creatorId == 'current_user_id') // Replace with actual user ID
                  const PopupMenuItem(
                    value: 'end',
                    child: Text('End Session', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ],
        ),
        onTap: () => _joinSession(session),
      ),
    );
  }

  Widget _buildCollaboratorsTab() {
    if (_currentSessionId == null) {
      return _buildEmptyState(
        'No Active Session',
        'Join or create a collaboration session to see team members.',
        Icons.people,
        null,
      );
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(CentralConfig.instance.getParameter('ui.spacing.medium', defaultValue: 20.0)),
          color: Colors.blue[50],
          child: Row(
            children: [
              const Icon(Icons.info, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Active collaborators in current session',
                  style: TextStyle(color: Colors.blue[800]),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(CentralConfig.instance.getParameter('ui.spacing.medium', defaultValue: 20.0)),
            itemCount: _currentCollaborators.length,
            itemBuilder: (context, index) => _buildCollaboratorCard(_currentCollaborators[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildCollaboratorCard(Collaborator collaborator) {
    final accessibleColors = _accessibility.getAccessibleColors(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: collaborator.isOnline ? Colors.green : Colors.grey,
          child: Text(
            collaborator.userId.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(collaborator.userId), // Replace with actual user name
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Role: ${collaborator.role.name}'),
            Text(
              'Joined: ${collaborator.joinedAt.toString().split('.')[0]}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: collaborator.isOnline ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String message, IconData icon, VoidCallback? action) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: action,
                icon: const Icon(Icons.add),
                label: const Text('Get Started'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CentralConfig.instance.primaryColor,
                  foregroundColor: CentralConfig.instance.surfaceColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _createNewSession() async {
    final result = await showDialog<CollaborationSession?>(
      context: context,
      builder: (context) => const CreateSessionDialog(),
    );

    if (result != null) {
      setState(() {
        _sessions.add(result);
      });

      // Auto-join the created session
      await _joinSession(result);
    }
  }

  Future<void> _joinSession(CollaborationSession session) async {
    final success = await _collaborationService.joinSession(session.id);

    if (success) {
      setState(() {
        _currentSessionId = session.id;
        _loadCurrentCollaborators();
      });

      NotificationService().showFileOperationNotification(
        title: 'Joined Session',
        body: 'Successfully joined "${session.name}"',
      );

      _accessibility.announceToScreenReader(
        'Joined collaboration session ${session.name}',
        assertion: 'session joined',
      );
    } else {
      _showError('Failed to join session');
    }
  }

  Future<void> _leaveCurrentSession() async {
    await _collaborationService.leaveSession();

    setState(() {
      _currentSessionId = null;
      _currentCollaborators.clear();
    });

    NotificationService().showFileOperationNotification(
      title: 'Left Session',
      body: 'Successfully left the collaboration session',
    );

    _accessibility.announceToScreenReader(
      'Left collaboration session',
      assertion: 'session left',
    );
  }

  void _handleSessionAction(CollaborationSession session, String action) {
    switch (action) {
      case 'join':
        _joinSession(session);
        break;
      case 'invite':
        _inviteUsers(session);
        break;
      case 'settings':
        _showSessionSettings(session);
        break;
      case 'end':
        _endSession(session);
        break;
    }
  }

  void _inviteUsers(CollaborationSession session) {
    showDialog(
      context: context,
      builder: (context) => InviteUsersDialog(sessionId: session.id),
    );
  }

  void _showSessionSettings(CollaborationSession session) {
    showDialog(
      context: context,
      builder: (context) => SessionSettingsDialog(session: session),
    );
  }

  void _endSession(CollaborationSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session'),
        content: Text('Are you sure you want to end "${session.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implementation to end session
              _showMessage('Session ended');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshSessions() async {
    setState(() => _isLoading = true);

    // Simulate refresh delay
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _sessions = _collaborationService.activeSessions.values.toList();
      _isLoading = false;
    });

    _accessibility.announceToScreenReader('Sessions refreshed');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  IconData _getSessionIcon(CollaborationType type) {
    switch (type) {
      case CollaborationType.documentEditing:
        return Icons.edit_document;
      case CollaborationType.fileSharing:
        return Icons.share;
      case CollaborationType.codeReview:
        return Icons.code;
      case CollaborationType.brainstorming:
        return Icons.lightbulb;
      case CollaborationType.projectPlanning:
        return Icons.task;
    }
  }

  @override
  void dispose() {
    _collaborationService.dispose();
    super.dispose();
  }
}

/// Create Session Dialog
class CreateSessionDialog extends StatefulWidget {
  const CreateSessionDialog({super.key});

  @override
  State<CreateSessionDialog> createState() => _CreateSessionDialogState();
}

class _CreateSessionDialogState extends State<CreateSessionDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  CollaborationType _selectedType = CollaborationType.documentEditing;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Collaboration Session'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Session Name',
                hintText: 'Enter session name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Describe the session purpose',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CollaborationType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Session Type',
              ),
              items: CollaborationType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name.replaceAll('_', ' ').toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createSession,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _createSession() {
    if (_nameController.text.isEmpty) return;

    final session = CollaborationSession(
      id: '', // Will be generated by service
      name: _nameController.text,
      creatorId: 'current_user_id', // Replace with actual user ID
      fileIds: [], // Add file selection later
      type: _selectedType,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      settings: {},
      createdAt: DateTime.now(),
      isActive: true,
      collaborators: ['current_user_id'],
    );

    Navigator.of(context).pop(session);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

/// Invite Users Dialog
class InviteUsersDialog extends StatefulWidget {
  final String sessionId;

  const InviteUsersDialog({super.key, required this.sessionId});

  @override
  State<InviteUsersDialog> createState() => _InviteUsersDialogState();
}

class _InviteUsersDialogState extends State<InviteUsersDialog> {
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite Users'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter user email',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Invitation Message (Optional)',
              hintText: 'Add a personal message',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _sendInvitation,
          child: const Text('Send Invite'),
        ),
      ],
    );
  }

  void _sendInvitation() {
    if (_emailController.text.isEmpty) return;

    // Implementation would send invitation
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invitation sent to ${_emailController.text}')),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}

/// Session Settings Dialog
class SessionSettingsDialog extends StatelessWidget {
  final CollaborationSession session;

  const SessionSettingsDialog({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Settings - ${session.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Allow File Uploads'),
              trailing: Switch(
                value: session.settings['allowUploads'] ?? true,
                onChanged: (value) {
                  // Update setting
                },
              ),
            ),
            ListTile(
              title: const Text('Real-time Cursor Tracking'),
              trailing: Switch(
                value: session.settings['cursorTracking'] ?? true,
                onChanged: (value) {
                  // Update setting
                },
              ),
            ),
            ListTile(
              title: const Text('Typing Indicators'),
              trailing: Switch(
                value: session.settings['typingIndicators'] ?? true,
                onChanged: (value) {
                  // Update setting
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
