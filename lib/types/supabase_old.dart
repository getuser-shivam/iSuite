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
}

// User profiles table
typedef UserProfiles = Map<String, dynamic>;

class UserProfilesRow {
  final String id;
  final String user_id;
  final String? name;
  final String? avatar_url;
  final String? bio;
  final String? phone;
  final String? website;
  final String? location;
  final Json? preferences;
  final Json? metadata;
  final DateTime? created_at;
  final DateTime? updated_at;

  const UserProfilesRow({
    required this.id,
    required this.user_id,
    this.name,
    this.avatar_url,
    this.bio,
    this.phone,
    this.website,
    this.location,
    this.preferences,
    this.metadata,
    this.created_at,
    this.updated_at,
  });

  factory UserProfilesRow.fromMap(Map<String, dynamic> map) {
    return UserProfilesRow(
      id: map['id'] as String,
      user_id: map['user_id'] as String,
      name: map['name'] as String?,
      avatar_url: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
      phone: map['phone'] as String?,
      website: map['website'] as String?,
      location: map['location'] as String?,
      preferences: map['preferences'] as Json?,
      metadata: map['metadata'] as Json?,
      created_at: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updated_at: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}

// Files table
typedef Files = Map<String, dynamic>;

class FilesRow {
  final String id;
  final String user_id;
  final String name;
  final String? description;
  final String? type;
  final String? mime_type;
  final int? size;
  final String? path;
  final String? bucket;
  final String? url;
  final bool? is_public;
  final bool? is_shared;
  final List<String>? shared_with;
  final Json? metadata;
  final DateTime? created_at;
  final DateTime? updated_at;
  final DateTime? deleted_at;

  const FilesRow({
    required this.id,
    required this.user_id,
    required this.name,
    this.description,
    this.type,
    this.mime_type,
    this.size,
    this.path,
    this.bucket,
    this.url,
    this.is_public,
    this.is_shared,
    this.shared_with,
    this.metadata,
    this.created_at,
    this.updated_at,
    this.deleted_at,
  });

  factory FilesRow.fromMap(Map<String, dynamic> map) {
    return FilesRow(
      id: map['id'] as String,
      user_id: map['user_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      type: map['type'] as String?,
      mime_type: map['mime_type'] as String?,
      size: map['size'] as int?,
      path: map['path'] as String?,
      bucket: map['bucket'] as String?,
      url: map['url'] as String?,
      is_public: map['is_public'] as bool?,
      is_shared: map['is_shared'] as bool?,
      shared_with: map['shared_with'] != null
          ? List<String>.from(map['shared_with'])
          : null,
      metadata: map['metadata'] as Json?,
      created_at: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updated_at: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      deleted_at: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
    );
  }
}

// File connections table
typedef FileConnections = Map<String, dynamic>;

class FileConnectionsRow {
  final String id;
  final String user_id;
  final String file_id;
  final String connection_type;
  final String? connection_config;
  final bool? is_active;
  final DateTime? created_at;
  final DateTime? updated_at;
  final DateTime? last_accessed;

  const FileConnectionsRow({
    required this.id,
    required this.user_id,
    required this.file_id,
    required this.connection_type,
    this.connection_config,
    this.is_active,
    this.created_at,
    this.updated_at,
    this.last_accessed,
  });

  factory FileConnectionsRow.fromMap(Map<String, dynamic> map) {
    return FileConnectionsRow(
      id: map['id'] as String,
      user_id: map['user_id'] as String,
      file_id: map['file_id'] as String,
      connection_type: map['connection_type'] as String,
      connection_config: map['connection_config'] as String?,
      is_active: map['is_active'] as bool?,
      created_at: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updated_at: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      last_accessed: map['last_accessed'] != null
          ? DateTime.parse(map['last_accessed'] as String)
          : null,
    );
  }
}

// Networks table
typedef Networks = Map<String, dynamic>;

class NetworksRow {
  final String id;
  final String user_id;
  final String name;
  final String? description;
  final String? type;
  final String? host;
  final int? port;
  final String? username;
  final String? password;
  final String? path;
  final bool? is_active;
  final Json? metadata;
  final DateTime? created_at;
  final DateTime? updated_at;

  const NetworksRow({
    required this.id,
    required this.user_id,
    required this.name,
    this.description,
    this.type,
    this.host,
    this.port,
    this.username,
    this.password,
    this.path,
    this.is_active,
    this.metadata,
    this.created_at,
    this.updated_at,
  });

  factory NetworksRow.fromMap(Map<String, dynamic> map) {
    return NetworksRow(
      id: map['id'] as String,
      user_id: map['user_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      type: map['type'] as String?,
      host: map['host'] as String?,
      port: map['port'] as int?,
      username: map['username'] as String?,
      password: map['password'] as String?,
      path: map['path'] as String?,
      is_active: map['is_active'] as bool?,
      metadata: map['metadata'] as Json?,
      created_at: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updated_at: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}

// Tasks table
typedef Tasks = Map<String, dynamic>;

class TasksRow {
  final String id;
  final String user_id;
  final String title;
  final String? description;
  final String? status;
  final String? priority;
  final DateTime? due_date;
  final DateTime? created_at;
  final DateTime? updated_at;
  final DateTime? completed_at;
  final Json? metadata;

  const TasksRow({
    required this.id,
    required this.user_id,
    required this.title,
    this.description,
    this.status,
    this.priority,
    this.due_date,
    this.created_at,
    this.updated_at,
    this.completed_at,
    this.metadata,
  });

  factory TasksRow.fromMap(Map<String, dynamic> map) {
    return TasksRow(
      id: map['id'] as String,
      user_id: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: map['status'] as String?,
      priority: map['priority'] as String?,
      due_date: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      created_at: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updated_at: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      completed_at: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      metadata: map['metadata'] as Json?,
    );
  }
}

// Reminders table
typedef Reminders = Map<String, dynamic>;

class RemindersRow {
  final String id;
  final String user_id;
  final String title;
  final String? description;
  final DateTime? remind_at;
  final String? frequency;
  final bool? is_completed;
  final DateTime? created_at;
  final DateTime? updated_at;
  final DateTime? completed_at;
  final Json? metadata;

  const RemindersRow({
    required this.id,
    required this.user_id,
    required this.title,
    this.description,
    this.remind_at,
    this.frequency,
    this.is_completed,
    this.created_at,
    this.updated_at,
    this.completed_at,
    this.metadata,
  });

  factory RemindersRow.fromMap(Map<String, dynamic> map) {
    return RemindersRow(
      id: map['id'] as String,
      user_id: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      remind_at: map['remind_at'] != null
          ? DateTime.parse(map['remind_at'] as String)
          : null,
      frequency: map['frequency'] as String?,
      is_completed: map['is_completed'] as bool?,
      created_at: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updated_at: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      completed_at: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      metadata: map['metadata'] as Json?,
    );
  }
}

// Notes table
typedef Notes = Map<String, dynamic>;

class NotesRow {
  final String id;
  final String user_id;
  final String title;
  final String? content;
  final List<String>? tags;
  final bool? is_pinned;
  final bool? is_archived;
  final Json? metadata;
  final DateTime? created_at;
  final DateTime? updated_at;

  const NotesRow({
    required this.id,
    required this.user_id,
    required this.title,
    this.content,
    this.tags,
    this.is_pinned,
    this.is_archived,
    this.metadata,
    this.created_at,
    this.updated_at,
  });

  factory NotesRow.fromMap(Map<String, dynamic> map) {
    return NotesRow(
      id: map['id'] as String,
      user_id: map['user_id'] as String,
      title: map['title'] as String,
      content: map['content'] as String?,
      tags: map['tags'] != null
          ? List<String>.from(map['tags'])
          : null,
      is_pinned: map['is_pinned'] as bool?,
      is_archived: map['is_archived'] as bool?,
      metadata: map['metadata'] as Json?,
      created_at: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updated_at: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}

// Calendar events table
typedef CalendarEvents = Map<String, dynamic>;

class CalendarEventsRow {
  final String id;
  final String user_id;
  final String title;
  final String? description;
  final DateTime? start_date;
  final DateTime? end_date;
  final String? location;
  final List<String>? attendees;
  final bool? is_all_day;
  final Json? metadata;
  final DateTime? created_at;
  final DateTime? updated_at;

  const CalendarEventsRow({
    required this.id,
    required this.user_id,
    required this.title,
    this.description,
    this.start_date,
    this.end_date,
    this.location,
    this.attendees,
    this.is_all_day,
    this.metadata,
    this.created_at,
    this.updated_at,
  });

  factory CalendarEventsRow.fromMap(Map<String, dynamic> map) {
    return CalendarEventsRow(
      id: map['id'] as String,
      user_id: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      start_date: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String)
          : null,
      end_date: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      location: map['location'] as String?,
      attendees: map['attendees'] != null
          ? List<String>.from(map['attendees'])
          : null,
      is_all_day: map['is_all_day'] as bool?,
      metadata: map['metadata'] as Json?,
      created_at: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updated_at: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}

// Sync metadata table
typedef SyncMetadata = Map<String, dynamic>;

class SyncMetadataRow {
  final String id;
  final String user_id;
  final String? table_name;
  final String? record_id;
  final String? action;
  final Json? old_data;
  final Json? new_data;
  final DateTime? created_at;
  final DateTime? updated_at;

  const SyncMetadataRow({
    required this.id,
    required this.user_id,
    this.table_name,
    this.record_id,
    this.action,
    this.old_data,
    this.new_data,
    this.created_at,
    this.updated_at,
  });

  factory SyncMetadataRow.fromMap(Map<String, dynamic> map) {
    return SyncMetadataRow(
      id: map['id'] as String,
      user_id: map['user_id'] as String,
      table_name: map['table_name'] as String?,
      record_id: map['record_id'] as String?,
      action: map['action'] as String?,
      old_data: map['old_data'] as Json?,
      new_data: map['new_data'] as Json?,
      created_at: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updated_at: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}

// User settings table
typedef UserSettings = Map<String, dynamic>;

class UserSettingsRow {
  final String id;
  final String user_id;
  final String? theme;
  final String? language;
  final String? timezone;
  final bool? notifications_enabled;
  final bool? auto_backup;
  final Json? preferences;
  final Json? metadata;
  final DateTime? created_at;
  final DateTime? updated_at;

  const UserSettingsRow({
    required this.id,
    required this.user_id,
    this.theme,
    this.language,
    this.timezone,
    this.notifications_enabled,
    this.auto_backup,
    this.preferences,
    this.metadata,
    this.created_at,
    this.updated_at,
  });

  factory UserSettingsRow.fromMap(Map<String, dynamic> map) {
    return UserSettingsRow(
      id: map['id'] as String,
      user_id: map['user_id'] as String,
      theme: map['theme'] as String?,
      language: map['language'] as String?,
      timezone: map['timezone'] as String?,
      notifications_enabled: map['notifications_enabled'] as bool?,
      auto_backup: map['auto_backup'] as bool?,
      preferences: map['preferences'] as Json?,
      metadata: map['metadata'] as Json?,
      created_at: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updated_at: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}

// App settings table
typedef AppSettings = Map<String, dynamic>;

class AppSettingsRow {
  final String id;
  final String? key;
  final dynamic value;
  final String? description;
  final bool? is_public;
  final Json? metadata;
  final DateTime? created_at;
  final DateTime? updated_at;

  const AppSettingsRow({
    required this.id,
    this.key,
    this.value,
    this.description,
    this.is_public,
    this.metadata,
    this.created_at,
    this.updated_at,
  });

  factory AppSettingsRow.fromMap(Map<String, dynamic> map) {
    return AppSettingsRow(
      id: map['id'] as String,
      key: map['key'] as String?,
      value: map['value'],
      description: map['description'] as String?,
      is_public: map['is_public'] as bool?,
      metadata: map['metadata'] as Json?,
      created_at: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updated_at: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}

// Feature flags table
typedef FeatureFlags = Map<String, dynamic>;

class FeatureFlagsRow {
  final String id;
  final String? name;
  final bool? enabled;
  final String? description;
  final Json? metadata;
  final DateTime? created_at;
  final DateTime? updated_at;

  const FeatureFlagsRow({
    required this.id,
    this.name,
    this.enabled,
    this.description,
    this.metadata,
    this.created_at,
    this.updated_at,
  });

  factory FeatureFlagsRow.fromMap(Map<String, dynamic> map) {
    return FeatureFlagsRow(
      id: map['id'] as String,
      name: map['name'] as String?,
      enabled: map['enabled'] as bool?,
      description: map['description'] as String?,
      metadata: map['metadata'] as Json?,
      created_at: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updated_at: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
