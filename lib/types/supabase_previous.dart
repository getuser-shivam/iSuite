// Auto-generated Supabase types for iSuite
// Generated with: supabase gen types dart --local > lib/types/supabase.dart

// Database Tables
typedef Json = Map<String, dynamic>;

// Users table
typedef Users = Map<String, dynamic>;

class UsersRow {
  final String id;
  final String email;
  final String? name;
  final String? avatar_url;
  final DateTime? created_at;
  final DateTime? updated_at;
  final bool? is_active;
  final String? role;
  final Json? preferences;
  final Json? metadata;

  const UsersRow({
    required this.id,
    required this.email,
    this.name,
    this.avatar_url,
    this.created_at,
    this.updated_at,
    this.is_active,
    this.role,
    this.preferences,
    this.metadata,
  });

  factory UsersRow.fromMap(Map<String, dynamic> map) {
    return UsersRow(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String?,
      avatar_url: map['avatar_url'] as String?,
      created_at: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updated_at: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      is_active: map['is_active'] as bool?,
      role: map['role'] as String?,
      preferences: map['preferences'] as Json?,
      metadata: map['metadata'] as Json?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatar_url,
      'created_at': created_at?.toIso8601String(),
      'updated_at': updated_at?.toIso8601String(),
      'is_active': is_active,
      'role': role,
      'preferences': preferences,
      'metadata': metadata,
    };
  }
}

// Tasks table
typedef Tasks = Map<String, dynamic>;

class TasksRow {
  final String id;
  final String user_id;
  final String title;
  final String? description;
  final bool is_completed;
  final String priority;
  final String status;
  final DateTime? due_date;
  final DateTime? created_at;
  final DateTime? updated_at;
  final String? category;
  final List<String> tags;
  final Json? metadata;

  const TasksRow({
    required this.id,
    required this.user_id,
    required this.title,
    this.description,
    required this.is_completed,
    required this.priority,
    required this.status,
    this.due_date,
    this.created_at,
    this.updated_at,
    this.category,
    this.tags = const [],
    this.metadata,
  });

  factory TasksRow.fromMap(Map<String, dynamic> map) {
    return TasksRow(
      id: map['id'] as String,
      user_id: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      is_completed: map['is_completed'] as bool,
      priority: map['priority'] as String,
      status: map['status'] as String,
      due_date: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      created_at: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updated_at: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      category: map['category'] as String?,
      tags: List<String>.from(map['tags'] ?? []),
      metadata: map['metadata'] as Json?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': user_id,
      'title': title,
      'description': description,
      'is_completed': is_completed,
      'priority': priority,
      'status': status,
      'due_date': due_date?.toIso8601String(),
      'created_at': created_at?.toIso8601String(),
      'updated_at': updated_at?.toIso8601String(),
      'category': category,
      'tags': tags,
      'metadata': metadata,
    };
  }
}

// Notes table
typedef Notes = Map<String, dynamic>;

class NotesRow {
  final String id;
  final String user_id;
  final String title;
  final String content;
  final String type;
  final String priority;
  final bool is_pinned;
  final bool is_favorite;
  final bool is_archived;
  final bool is_encrypted;
  final DateTime? due_date;
  final DateTime? created_at;
  final DateTime? updated_at;
  final String? category;
  final List<String> tags;
  final String? color;
  final Json? metadata;

  const NotesRow({
    required this.id,
    required this.user_id,
    required this.title,
    required this.content,
    required this.type,
    required this.priority,
    required this.is_pinned,
    required this.is_favorite,
    required this.is_archived,
    required this.is_encrypted,
    this.due_date,
    this.created_at,
    this.updated_at,
    this.category,
    this.tags = const [],
    this.color,
    this.metadata,
  });

  factory NotesRow.fromMap(Map<String, dynamic> map) {
    return NotesRow(
      id: map['id'] as String,
      user_id: map['user_id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      type: map['type'] as String,
      priority: map['priority'] as String,
      is_pinned: map['is_pinned'] as bool,
      is_favorite: map['is_favorite'] as bool,
      is_archived: map['is_archived'] as bool,
      is_encrypted: map['is_encrypted'] as bool,
      due_date: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      created_at: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updated_at: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      category: map['category'] as String?,
      tags: List<String>.from(map['tags'] ?? []),
      color: map['color'] as String?,
      metadata: map['metadata'] as Json?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': user_id,
      'title': title,
      'content': content,
      'type': type,
      'priority': priority,
      'is_pinned': is_pinned,
      'is_favorite': is_favorite,
      'is_archived': is_archived,
      'is_encrypted': is_encrypted,
      'due_date': due_date?.toIso8601String(),
      'created_at': created_at?.toIso8601String(),
      'updated_at': updated_at?.toIso8601String(),
      'category': category,
      'tags': tags,
      'color': color,
      'metadata': metadata,
    };
  }
}

// Files table
typedef Files = Map<String, dynamic>;

class FilesRow {
  final String id;
  final String user_id;
  final String name;
  final String path;
  final String type;
  final int size;
  final String mime_type;
  final DateTime? created_at;
  final DateTime? updated_at;
  final String? category;
  final List<String> tags;
  final Json? metadata;
  final bool? is_shared;
  final String? share_token;

  const FilesRow({
    required this.id,
    required this.user_id,
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    required this.mime_type,
    this.created_at,
    this.updated_at,
    this.category,
    this.tags = const [],
    this.metadata,
    this.is_shared,
    this.share_token,
  });

  factory FilesRow.fromMap(Map<String, dynamic> map) {
    return FilesRow(
      id: map['id'] as String,
      user_id: map['user_id'] as String,
      name: map['name'] as String,
      path: map['path'] as String,
      type: map['type'] as String,
      size: map['size'] as int,
      mime_type: map['mime_type'] as String,
      created_at: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updated_at: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      category: map['category'] as String?,
      tags: List<String>.from(map['tags'] ?? []),
      metadata: map['metadata'] as Json?,
      is_shared: map['is_shared'] as bool?,
      share_token: map['share_token'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': user_id,
      'name': name,
      'path': path,
      'type': type,
      'size': size,
      'mime_type': mime_type,
      'created_at': created_at?.toIso8601String(),
      'updated_at': updated_at?.toIso8601String(),
      'category': category,
      'tags': tags,
      'metadata': metadata,
      'is_shared': is_shared,
      'share_token': share_token,
    };
  }
}

// Calendar Events table
typedef CalendarEvents = Map<String, dynamic>;

class CalendarEventsRow {
  final String id;
  final String user_id;
  final String title;
  final String? description;
  final DateTime start_time;
  final DateTime end_time;
  final String location;
  final bool is_all_day;
  final String recurrence;
  final DateTime? created_at;
  final DateTime? updated_at;
  final String? category;
  final List<String> attendees;
  final Json? metadata;

  const CalendarEventsRow({
    required this.id,
    required this.user_id,
    required this.title,
    this.description,
    required this.start_time,
    required this.end_time,
    required this.location,
    required this.is_all_day,
    required this.recurrence,
    this.created_at,
    this.updated_at,
    this.category,
    this.attendees = const [],
    this.metadata,
  });

  factory CalendarEventsRow.fromMap(Map<String, dynamic> map) {
    return CalendarEventsRow(
      id: map['id'] as String,
      user_id: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      start_time: DateTime.parse(map['start_time'] as String),
      end_time: DateTime.parse(map['end_time'] as String),
      location: map['location'] as String,
      is_all_day: map['is_all_day'] as bool,
      recurrence: map['recurrence'] as String,
      created_at: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updated_at: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      category: map['category'] as String?,
      attendees: List<String>.from(map['attendees'] ?? []),
      metadata: map['metadata'] as Json?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': user_id,
      'title': title,
      'description': description,
      'start_time': start_time.toIso8601String(),
      'end_time': end_time.toIso8601String(),
      'location': location,
      'is_all_day': is_all_day,
      'recurrence': recurrence,
      'created_at': created_at?.toIso8601String(),
      'updated_at': updated_at?.toIso8601String(),
      'category': category,
      'attendees': attendees,
      'metadata': metadata,
    };
  }
}

// Reminders table
typedef Reminders = Map<String, dynamic>;

class RemindersRow {
  final String id;
  final String user_id;
  final String title;
  final String? description;
  final DateTime reminder_time;
  final String priority;
  final bool is_completed;
  final String type;
  final DateTime? created_at;
  final DateTime? updated_at;
  final String? related_entity_type;
  final String? related_entity_id;
  final Json? metadata;

  const RemindersRow({
    required this.id,
    required this.user_id,
    required this.title,
    this.description,
    required this.reminder_time,
    required this.priority,
    required this.is_completed,
    required this.type,
    this.created_at,
    this.updated_at,
    this.related_entity_type,
    this.related_entity_id,
    this.metadata,
  });

  factory RemindersRow.fromMap(Map<String, dynamic> map) {
    return RemindersRow(
      id: map['id'] as String,
      user_id: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      reminder_time: DateTime.parse(map['reminder_time'] as String),
      priority: map['priority'] as String,
      is_completed: map['is_completed'] as bool,
      type: map['type'] as String,
      created_at: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updated_at: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      related_entity_type: map['related_entity_type'] as String?,
      related_entity_id: map['related_entity_id'] as String?,
      metadata: map['metadata'] as Json?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': user_id,
      'title': title,
      'description': description,
      'reminder_time': reminder_time.toIso8601String(),
      'priority': priority,
      'is_completed': is_completed,
      'type': type,
      'created_at': created_at?.toIso8601String(),
      'updated_at': updated_at?.toIso8601String(),
      'related_entity_type': related_entity_type,
      'related_entity_id': related_entity_id,
      'metadata': metadata,
    };
  }
}

// Analytics table
typedef Analytics = Map<String, dynamic>;

class AnalyticsRow {
  final String id;
  final String user_id;
  final String event_type;
  final String event_name;
  final Json event_data;
  final DateTime created_at;
  final String? session_id;
  final String? device_info;
  final Json? metadata;

  const AnalyticsRow({
    required this.id,
    required this.user_id,
    required this.event_type,
    required this.event_name,
    required this.event_data,
    required this.created_at,
    this.session_id,
    this.device_info,
    this.metadata,
  });

  factory AnalyticsRow.fromMap(Map<String, dynamic> map) {
    return AnalyticsRow(
      id: map['id'] as String,
      user_id: map['user_id'] as String,
      event_type: map['event_type'] as String,
      event_name: map['event_name'] as String,
      event_data: map['event_data'] as Json,
      created_at: DateTime.parse(map['created_at'] as String),
      session_id: map['session_id'] as String?,
      device_info: map['device_info'] as String?,
      metadata: map['metadata'] as Json?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': user_id,
      'event_type': event_type,
      'event_name': event_name,
      'event_data': event_data,
      'created_at': created_at.toIso8601String(),
      'session_id': session_id,
      'device_info': device_info,
      'metadata': metadata,
    };
  }
}

// Backups table
typedef Backups = Map<String, dynamic>;

class BackupsRow {
  final String id;
  final String user_id;
  final String name;
  final String type;
  final String file_path;
  final int file_size;
  final bool is_encrypted;
  final DateTime created_at;
  final DateTime? restored_at;
  final Json? metadata;

  const BackupsRow({
    required this.id,
    required this.user_id,
    required this.name,
    required this.type,
    required this.file_path,
    required this.file_size,
    required this.is_encrypted,
    required this.created_at,
    this.restored_at,
    this.metadata,
  });

  factory BackupsRow.fromMap(Map<String, dynamic> map) {
    return BackupsRow(
      id: map['id'] as String,
      user_id: map['user_id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      file_path: map['file_path'] as String,
      file_size: map['file_size'] as int,
      is_encrypted: map['is_encrypted'] as bool,
      created_at: DateTime.parse(map['created_at'] as String),
      restored_at: map['restored_at'] != null
          ? DateTime.parse(map['restored_at'] as String)
          : null,
      metadata: map['metadata'] as Json?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': user_id,
      'name': name,
      'type': type,
      'file_path': file_path,
      'file_size': file_size,
      'is_encrypted': is_encrypted,
      'created_at': created_at.toIso8601String(),
      'restored_at': restored_at?.toIso8601String(),
      'metadata': metadata,
    };
  }
}

// Database Functions
class SupabaseFunctions {
  static const String getUserProfile = 'get_user_profile';
  static const String updateUserProfile = 'update_user_profile';
  static const String getUserTasks = 'get_user_tasks';
  static const String createUserTask = 'create_user_task';
  static const String updateUserTask = 'update_user_task';
  static const String deleteUserTask = 'delete_user_task';
  static const String getUserNotes = 'get_user_notes';
  static const String createUserNote = 'create_user_note';
  static const String updateUserNote = 'update_user_note';
  static const String deleteUserNote = 'delete_user_note';
  static const String getUserFiles = 'get_user_files';
  static const String uploadUserFile = 'upload_user_file';
  static const String deleteUserFile = 'delete_user_file';
  static const String getUserCalendarEvents = 'get_user_calendar_events';
  static const String createUserCalendarEvent = 'create_user_calendar_event';
  static const String updateUserCalendarEvent = 'update_user_calendar_event';
  static const String deleteUserCalendarEvent = 'delete_user_calendar_event';
  static const String getUserReminders = 'get_user_reminders';
  static const String createUserReminder = 'create_user_reminder';
  static const String updateUserReminder = 'update_user_reminder';
  static const String deleteUserReminder = 'delete_user_reminder';
  static const String trackAnalyticsEvent = 'track_analytics_event';
  static const String getUserAnalytics = 'get_user_analytics';
  static const String createUserBackup = 'create_user_backup';
  static const String restoreUserBackup = 'restore_user_backup';
  static const String getUserBackups = 'get_user_backups';
}

// Realtime Subscriptions
class SupabaseSubscriptions {
  static const String userTasks = 'user_tasks';
  static const String userNotes = 'user_notes';
  static const String userFiles = 'user_files';
  static const String userCalendarEvents = 'user_calendar_events';
  static const String userReminders = 'user_reminders';
  static const String userAnalytics = 'user_analytics';
  static const String userBackups = 'user_backups';
}

// Storage Buckets
class SupabaseStorage {
  static const String userFiles = 'user_files';
  static const String userBackups = 'user_backups';
  static const String userAvatars = 'user_avatars';
  static const String appAssets = 'app_assets';
}

// Database Views
class SupabaseViews {
  static const String userDashboard = 'user_dashboard';
  static const String userStatistics = 'user_statistics';
  static const String userActivity = 'user_activity';
}

// Enums for type safety
enum TaskPriority { low, medium, high, urgent }

enum TaskStatus { pending, in_progress, completed, cancelled }

enum NoteType { text, checklist, voice, image }

enum NotePriority { low, medium, high }

enum FileType { document, image, video, audio, other }

enum ReminderPriority { low, medium, high, urgent }

enum ReminderType { notification, email, sms }

enum AnalyticsEventType { user_action, system_event, error, performance }

enum BackupType { full, incremental, differential }

enum CalendarEventType { meeting, appointment, reminder, task }

// Sync Metadata for type safety
class SyncMetadata {
  final String userId;
  final DateTime? lastSyncTasks;
  final DateTime? lastSyncReminders;
  final DateTime? lastSyncNotes;
  final DateTime? lastSyncCalendar;
  final DateTime? lastSyncFiles;
  final DateTime? lastSyncNetworks;
  final DateTime? lastSyncFileConnections;
  final int version;

  const SyncMetadata({
    required this.userId,
    this.lastSyncTasks,
    this.lastSyncReminders,
    this.lastSyncNotes,
    this.lastSyncCalendar,
    this.lastSyncFiles,
    this.lastSyncNetworks,
    this.lastSyncFileConnections,
    this.version = 1,
  });

  factory SyncMetadata.fromMap(Map<String, dynamic> map) {
    return SyncMetadata(
      userId: map['user_id'] as String,
      lastSyncTasks: map['last_sync_tasks'] != null
          ? DateTime.parse(map['last_sync_tasks'] as String)
          : null,
      lastSyncReminders: map['last_sync_reminders'] != null
          ? DateTime.parse(map['last_sync_reminders'] as String)
          : null,
      lastSyncNotes: map['last_sync_notes'] != null
          ? DateTime.parse(map['last_sync_notes'] as String)
          : null,
      lastSyncCalendar: map['last_sync_calendar'] != null
          ? DateTime.parse(map['last_sync_calendar'] as String)
          : null,
      lastSyncFiles: map['last_sync_files'] != null
          ? DateTime.parse(map['last_sync_files'] as String)
          : null,
      lastSyncNetworks: map['last_sync_networks'] != null
          ? DateTime.parse(map['last_sync_networks'] as String)
          : null,
      lastSyncFileConnections: map['last_sync_file_connections'] != null
          ? DateTime.parse(map['last_sync_file_connections'] as String)
          : null,
      version: map['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'last_sync_tasks': lastSyncTasks?.toIso8601String(),
      'last_sync_reminders': lastSyncReminders?.toIso8601String(),
      'last_sync_notes': lastSyncNotes?.toIso8601String(),
      'last_sync_calendar': lastSyncCalendar?.toIso8601String(),
      'last_sync_files': lastSyncFiles?.toIso8601String(),
      'last_sync_networks': lastSyncNetworks?.toIso8601String(),
      'last_sync_file_connections': lastSyncFileConnections?.toIso8601String(),
      'version': version,
    };
  }
}
