# iSuite Database Schema Documentation

## Table of Contents

- [Overview](#overview)
- [Database Architecture](#database-architecture)
- [Table Schemas](#table-schemas)
- [Relationships](#relationships)
- [Indexes](#indexes)
- [Migrations](#migrations)
- [Data Models](#data-models)
- [Query Examples](#query-examples)
- [Performance Considerations](#performance-considerations)

---

## Overview

iSuite uses SQLite as its local database storage solution, providing fast, reliable offline data storage with optional cloud synchronization through Supabase. The database is designed using relational principles with proper normalization and indexing for optimal performance.

### Database Characteristics

- **Type**: SQLite (local) + Supabase (cloud sync)
- **Version**: 1.0
- **Location**: Device local storage
- **Backup**: Automatic cloud sync (optional)
- **Encryption**: Device-level encryption support

---

## Database Architecture

### Design Principles

1. **Normalization**: Third Normal Form (3NF) compliance
2. **Data Integrity**: Foreign key constraints and validation
3. **Performance**: Strategic indexing and query optimization
4. **Scalability**: Flexible schema for future enhancements
5. **Security**: Sensitive data encryption and access control

### Database Files

```
database/
├── schema/
│   ├── v1.0.0_initial_schema.sql    # Initial database schema
│   ├── v1.1.0_add_reminders.sql     # Reminders feature addition
│   └── v1.2.0_add_analytics.sql     # Analytics feature addition
├── migrations/
│   ├── migration_manager.dart        # Migration handling logic
│   └── migration_scripts.dart       # Migration scripts collection
└── seeds/
    ├── sample_data.sql              # Sample data for development
    └── test_data.sql                # Test data fixtures
```

---

## Table Schemas

### 1. Users Table

Stores user account information and preferences.

```sql
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    avatar_url TEXT,
    phone TEXT,
    timezone TEXT DEFAULT 'UTC',
    language TEXT DEFAULT 'en',
    theme_preference TEXT DEFAULT 'system',
    notification_preferences TEXT, -- JSON string
    is_active INTEGER DEFAULT 1,
    email_verified INTEGER DEFAULT 0,
    last_login_at INTEGER,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
```

**Field Descriptions:**
- `id`: UUID v4 string
- `notification_preferences`: JSON object with notification settings
- `theme_preference`: 'light', 'dark', or 'system'
- `timezone`: IANA timezone identifier
- `last_login_at`: Unix timestamp

### 2. Tasks Table

Core task management functionality.

```sql
CREATE TABLE tasks (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    priority INTEGER DEFAULT 1, -- 0=low, 1=normal, 2=high, 3=urgent
    status TEXT DEFAULT 'pending', -- pending, in_progress, completed, cancelled
    category TEXT,
    tags TEXT, -- JSON array of tags
    due_date INTEGER,
    reminder_id TEXT,
    estimated_duration INTEGER, -- in minutes
    actual_duration INTEGER, -- in minutes
    completion_percentage INTEGER DEFAULT 0,
    is_recurring INTEGER DEFAULT 0,
    recurrence_pattern TEXT, -- JSON object for recurrence rules
    parent_task_id TEXT, -- for subtasks
    order_index INTEGER,
    color TEXT,
    is_favorite INTEGER DEFAULT 0,
    attachments TEXT, -- JSON array of attachment paths
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    completed_at INTEGER,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    FOREIGN KEY (parent_task_id) REFERENCES tasks (id) ON DELETE SET NULL,
    FOREIGN KEY (reminder_id) REFERENCES reminders (id) ON DELETE SET NULL
);
```

### 3. Notes Table

Rich text notes with organization features.

```sql
CREATE TABLE notes (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT,
    content_type TEXT DEFAULT 'text', -- text, markdown, rich_text
    category TEXT,
    tags TEXT, -- JSON array
    is_pinned INTEGER DEFAULT 0,
    is_archived INTEGER DEFAULT 0,
    is_favorite INTEGER DEFAULT 0,
    color TEXT,
    font_size INTEGER DEFAULT 14,
    attachments TEXT, -- JSON array
    checklist_items TEXT, -- JSON array of checklist items
    word_count INTEGER DEFAULT 0,
    reading_time INTEGER DEFAULT 0, -- in minutes
    password_hash TEXT, -- for encrypted notes
    shared_with TEXT, -- JSON array of user IDs
    view_count INTEGER DEFAULT 0,
    last_accessed_at INTEGER,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);
```

### 4. Calendar Events Table

Calendar and scheduling functionality.

```sql
CREATE TABLE calendar_events (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,
    start_time INTEGER NOT NULL,
    end_time INTEGER NOT NULL,
    is_all_day INTEGER DEFAULT 0,
    timezone TEXT DEFAULT 'UTC',
    recurrence_rule TEXT, -- RRULE format
    attendees TEXT, -- JSON array of attendee objects
    meeting_url TEXT,
    attachments TEXT, -- JSON array
    reminders TEXT, -- JSON array of reminder times
    status TEXT DEFAULT 'confirmed', -- confirmed, tentative, cancelled
    visibility TEXT DEFAULT 'private', -- private, public, shared
    color TEXT,
    calendar_type TEXT DEFAULT 'personal', -- personal, work, family
    external_id TEXT, -- for sync with external calendars
    sync_status TEXT DEFAULT 'pending', -- pending, synced, error
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);
```

### 5. Files Table

File management and storage.

```sql
CREATE TABLE files (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    original_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    mime_type TEXT NOT NULL,
    file_hash TEXT, -- SHA-256 hash for integrity
    category TEXT,
    tags TEXT, -- JSON array
    is_favorite INTEGER DEFAULT 0,
    is_shared INTEGER DEFAULT 0,
    shared_with TEXT, -- JSON array of user IDs
    access_count INTEGER DEFAULT 0,
    last_accessed_at INTEGER,
    thumbnail_path TEXT,
    metadata TEXT, -- JSON object with file-specific metadata
    cloud_path TEXT, -- for cloud storage
    sync_status TEXT DEFAULT 'pending',
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);
```

### 6. Reminders Table

Reminder and notification system.

```sql
CREATE TABLE reminders (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    reminder_type TEXT NOT NULL, -- task, event, custom
    target_id TEXT, -- ID of related task/event
    trigger_time INTEGER NOT NULL,
    repeat_pattern TEXT, -- JSON object for repeat rules
    notification_method TEXT DEFAULT 'push', -- push, email, sms
    is_active INTEGER DEFAULT 1,
    is_completed INTEGER DEFAULT 0,
    priority INTEGER DEFAULT 1,
    sound TEXT,
    vibration_pattern TEXT, -- JSON array
    led_color TEXT,
    snooze_count INTEGER DEFAULT 0,
    next_trigger_time INTEGER,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    triggered_at INTEGER,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);
```

### 7. Categories Table

Organization categories for tasks, notes, and files.

```sql
CREATE TABLE categories (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    color TEXT,
    icon TEXT,
    parent_category_id TEXT,
    item_type TEXT NOT NULL, -- task, note, file, all
    sort_order INTEGER DEFAULT 0,
    is_default INTEGER DEFAULT 0,
    is_active INTEGER DEFAULT 1,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    FOREIGN KEY (parent_category_id) REFERENCES categories (id) ON DELETE SET NULL,
    UNIQUE(user_id, name, item_type)
);
```

### 8. Settings Table

Application settings and preferences.

```sql
CREATE TABLE settings (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    setting_key TEXT NOT NULL,
    setting_value TEXT,
    setting_type TEXT DEFAULT 'string', -- string, integer, boolean, json
    category TEXT DEFAULT 'general',
    is_synced INTEGER DEFAULT 1,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    UNIQUE(user_id, setting_key)
);
```

### 9. Analytics Table

Usage analytics and metrics.

```sql
CREATE TABLE analytics (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    event_data TEXT, -- JSON object with event details
    screen_name TEXT,
    session_id TEXT,
    device_info TEXT, -- JSON object
    app_version TEXT,
    timestamp INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);
```

### 10. Backup Table

Backup and restore information.

```sql
CREATE TABLE backups (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    backup_name TEXT NOT NULL,
    backup_path TEXT NOT NULL,
    backup_size INTEGER NOT NULL,
    backup_type TEXT NOT NULL, -- full, incremental, auto
    is_encrypted INTEGER DEFAULT 1,
    encryption_method TEXT,
    cloud_backup_path TEXT,
    status TEXT DEFAULT 'completed', -- pending, completed, failed
    error_message TEXT,
    created_at INTEGER NOT NULL,
    completed_at INTEGER,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);
```

---

## Relationships

### Entity Relationship Diagram

```
Users (1) ──────── (∞) Tasks
Users (1) ──────── (∞) Notes
Users (1) ──────── (∞) Calendar Events
Users (1) ──────── (∞) Files
Users (1) ──────── (∞) Reminders
Users (1) ──────── (∞) Categories
Users (1) ──────── (∞) Settings
Users (1) ──────── (∞) Analytics
Users (1) ──────── (∞) Backups

Tasks (∞) ──────── (1) Reminders (optional)
Tasks (∞) ──────── (1) Tasks (parent-child)

Categories (∞) ──── (1) Categories (parent-child)
```

### Relationship Types

1. **One-to-Many**: User to all data tables
2. **One-to-One**: Task to Reminder (optional)
3. **Self-Referencing**: Tasks (subtasks), Categories (hierarchy)
4. **Polymorphic**: Categories can apply to multiple item types

---

## Indexes

### Primary Indexes

All tables have primary key indexes on their `id` fields.

### Secondary Indexes

```sql
-- Users table indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_active ON users(is_active);

-- Tasks table indexes
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_tasks_category ON tasks(category);
CREATE INDEX idx_tasks_created_at ON tasks(created_at);
CREATE INDEX idx_tasks_parent_task ON tasks(parent_task_id);

-- Notes table indexes
CREATE INDEX idx_notes_user_id ON notes(user_id);
CREATE INDEX idx_notes_category ON notes(category);
CREATE INDEX idx_notes_pinned ON notes(is_pinned);
CREATE INDEX idx_notes_archived ON notes(is_archived);
CREATE INDEX idx_notes_created_at ON notes(created_at);

-- Calendar events indexes
CREATE INDEX idx_events_user_id ON calendar_events(user_id);
CREATE INDEX idx_events_start_time ON calendar_events(start_time);
CREATE INDEX idx_events_end_time ON calendar_events(end_time);
CREATE INDEX idx_events_calendar_type ON calendar_events(calendar_type);

-- Files table indexes
CREATE INDEX idx_files_user_id ON files(user_id);
CREATE INDEX idx_files_category ON files(category);
CREATE INDEX idx_files_mime_type ON files(mime_type);
CREATE INDEX idx_files_created_at ON files(created_at);

-- Reminders table indexes
CREATE INDEX idx_reminders_user_id ON reminders(user_id);
CREATE INDEX idx_reminders_trigger_time ON reminders(trigger_time);
CREATE INDEX idx_reminders_active ON reminders(is_active);
CREATE INDEX idx_reminders_type ON reminders(reminder_type);

-- Categories table indexes
CREATE INDEX idx_categories_user_id ON categories(user_id);
CREATE INDEX idx_categories_parent ON categories(parent_category_id);
CREATE INDEX idx_categories_item_type ON categories(item_type);

-- Settings table indexes
CREATE INDEX idx_settings_user_id ON settings(user_id);
CREATE INDEX idx_settings_key ON settings(setting_key);
CREATE INDEX idx_settings_category ON settings(category);

-- Analytics table indexes
CREATE INDEX idx_analytics_user_id ON analytics(user_id);
CREATE INDEX idx_analytics_event_type ON analytics(event_type);
CREATE INDEX idx_analytics_timestamp ON analytics(timestamp);

-- Backups table indexes
CREATE INDEX idx_backups_user_id ON backups(user_id);
CREATE INDEX idx_backups_type ON backups(backup_type);
CREATE INDEX idx_backups_created_at ON backups(created_at);
```

### Composite Indexes

```sql
-- Tasks performance indexes
CREATE INDEX idx_tasks_user_status ON tasks(user_id, status);
CREATE INDEX idx_tasks_user_priority ON tasks(user_id, priority);
CREATE INDEX idx_tasks_user_due_date ON tasks(user_id, due_date);

-- Notes performance indexes
CREATE INDEX idx_notes_user_pinned ON notes(user_id, is_pinned);
CREATE INDEX idx_notes_user_archived ON notes(user_id, is_archived);

-- Calendar events performance indexes
CREATE INDEX idx_events_user_time ON calendar_events(user_id, start_time, end_time);
```

---

## Migrations

### Migration Strategy

The database uses version-controlled migrations to handle schema changes:

```dart
class MigrationManager {
  static const int currentVersion = 1;
  
  static final List<Migration> migrations = [
    Migration(
      version: 1,
      description: 'Initial database schema',
      up: _createInitialSchema,
      down: _dropInitialSchema,
    ),
    Migration(
      version: 2,
      description: 'Add reminders table',
      up: _createRemindersTable,
      down: _dropRemindersTable,
    ),
    Migration(
      version: 3,
      description: 'Add analytics table',
      up: _createAnalyticsTable,
      down: _dropAnalyticsTable,
    ),
  ];
  
  static Future<void> migrate(Database db, int fromVersion, int toVersion) async {
    for (int version = fromVersion + 1; version <= toVersion; version++) {
      final migration = migrations.firstWhere((m) => m.version == version);
      await migration.up(db);
    }
  }
}
```

### Migration Scripts

#### Version 1.0.0 - Initial Schema

```sql
-- Create all initial tables
-- (See table schemas above)
```

#### Version 1.1.0 - Add Reminders

```sql
CREATE TABLE reminders (
    -- (See reminders table schema above)
);

-- Add reminder_id to tasks table
ALTER TABLE tasks ADD COLUMN reminder_id TEXT;
ALTER TABLE tasks ADD FOREIGN KEY (reminder_id) REFERENCES reminders (id) ON DELETE SET NULL;
```

#### Version 1.2.0 - Add Analytics

```sql
CREATE TABLE analytics (
    -- (See analytics table schema above)
);
```

---

## Data Models

### Task Model

```dart
class Task {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final String? category;
  final List<String> tags;
  final DateTime? dueDate;
  final String? reminderId;
  final int? estimatedDuration;
  final int? actualDuration;
  final int completionPercentage;
  final bool isRecurring;
  final RecurrencePattern? recurrencePattern;
  final String? parentTaskId;
  final int? orderIndex;
  final String? color;
  final bool isFavorite;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.priority = TaskPriority.normal,
    this.status = TaskStatus.pending,
    this.category,
    this.tags = const [],
    this.dueDate,
    this.reminderId,
    this.estimatedDuration,
    this.actualDuration,
    this.completionPercentage = 0,
    this.isRecurring = false,
    this.recurrencePattern,
    this.parentTaskId,
    this.orderIndex,
    this.color,
    this.isFavorite = false,
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  // Database mapping
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'priority': priority.index,
      'status': status.name,
      'category': category,
      'tags': jsonEncode(tags),
      'due_date': dueDate?.millisecondsSinceEpoch,
      'reminder_id': reminderId,
      'estimated_duration': estimatedDuration,
      'actual_duration': actualDuration,
      'completion_percentage': completionPercentage,
      'is_recurring': isRecurring ? 1 : 0,
      'recurrence_pattern': recurrencePattern != null 
          ? jsonEncode(recurrencePattern!.toMap()) : null,
      'parent_task_id': parentTaskId,
      'order_index': orderIndex,
      'color': color,
      'is_favorite': isFavorite ? 1 : 0,
      'attachments': jsonEncode(attachments),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      description: map['description'],
      priority: TaskPriority.values[map['priority'] ?? 1],
      status: TaskStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TaskStatus.pending,
      ),
      category: map['category'],
      tags: map['tags'] != null 
          ? List<String>.from(jsonDecode(map['tags'])) 
          : [],
      dueDate: map['due_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['due_date']) 
          : null,
      reminderId: map['reminder_id'],
      estimatedDuration: map['estimated_duration'],
      actualDuration: map['actual_duration'],
      completionPercentage: map['completion_percentage'] ?? 0,
      isRecurring: (map['is_recurring'] ?? 0) == 1,
      recurrencePattern: map['recurrence_pattern'] != null 
          ? RecurrencePattern.fromMap(jsonDecode(map['recurrence_pattern'])) 
          : null,
      parentTaskId: map['parent_task_id'],
      orderIndex: map['order_index'],
      color: map['color'],
      isFavorite: (map['is_favorite'] ?? 0) == 1,
      attachments: map['attachments'] != null 
          ? List<String>.from(jsonDecode(map['attachments'])) 
          : [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      completedAt: map['completed_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at']) 
          : null,
    );
  }
}
```

---

## Query Examples

### Common Queries

#### Get User Tasks with Filters

```sql
SELECT * FROM tasks 
WHERE user_id = ? 
  AND status = ?
  AND due_date >= ?
ORDER BY priority DESC, due_date ASC
LIMIT ? OFFSET ?;
```

#### Search Notes with Full Text

```sql
SELECT * FROM notes 
WHERE user_id = ? 
  AND (title LIKE ? OR content LIKE ?)
  AND is_archived = 0
ORDER BY is_favorite DESC, updated_at DESC;
```

#### Get Calendar Events for Date Range

```sql
SELECT * FROM calendar_events 
WHERE user_id = ? 
  AND start_time >= ? 
  AND end_time <= ?
ORDER BY start_time ASC;
```

#### Get Analytics Summary

```sql
SELECT 
  event_type,
  COUNT(*) as count,
  DATE(timestamp) as date
FROM analytics 
WHERE user_id = ? 
  AND timestamp >= ?
GROUP BY event_type, DATE(timestamp)
ORDER BY date DESC, count DESC;
```

### Complex Queries

#### Task Statistics

```sql
SELECT 
  COUNT(*) as total_tasks,
  COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_tasks,
  COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_tasks,
  COUNT(CASE WHEN due_date < ? AND status != 'completed' THEN 1 END) as overdue_tasks,
  AVG(CASE WHEN actual_duration IS NOT NULL THEN actual_duration END) as avg_duration
FROM tasks 
WHERE user_id = ?;
```

#### Category Usage

```sql
SELECT 
  c.name,
  c.color,
  COUNT(t.id) as task_count,
  COUNT(n.id) as note_count,
  COUNT(f.id) as file_count
FROM categories c
LEFT JOIN tasks t ON c.id = t.category AND c.item_type IN ('task', 'all')
LEFT JOIN notes n ON c.id = n.category AND c.item_type IN ('note', 'all')
LEFT JOIN files f ON c.id = f.category AND c.item_type IN ('file', 'all')
WHERE c.user_id = ? AND c.is_active = 1
GROUP BY c.id, c.name, c.color
ORDER BY task_count DESC, note_count DESC, file_count DESC;
```

---

## Performance Considerations

### Query Optimization

1. **Use Indexes**: Ensure all WHERE clause columns are indexed
2. **Limit Results**: Use LIMIT and OFFSET for pagination
3. **Avoid N+1 Queries**: Use JOINs when appropriate
4. **Batch Operations**: Use transactions for multiple inserts/updates

### Memory Management

```dart
// Use streams for large datasets
Stream<List<Task>> getTasksStream(String userId) {
  return (await database).query('tasks', where: 'user_id = ?', whereArgs: [userId])
      .map((maps) => maps.map((map) => Task.fromMap(map)).toList())
      .asStream();
}

// Paginated loading
Future<List<Task>> getTasksPaginated(String userId, int page, int limit) async {
  final offset = page * limit;
  final maps = await database.query(
    'tasks',
    where: 'user_id = ?',
    whereArgs: [userId],
    orderBy: 'created_at DESC',
    limit: limit,
    offset: offset,
  );
  return maps.map((map) => Task.fromMap(map)).toList();
}
```

### Database Maintenance

```dart
// Vacuum and optimize
Future<void> optimizeDatabase() async {
  final db = await database;
  await db.execute('VACUUM');
  await db.execute('ANALYZE');
}

// Clean old analytics data
Future<void> cleanupOldAnalytics() async {
  final cutoffTime = DateTime.now().subtract(Duration(days: 90)).millisecondsSinceEpoch;
  await database.delete(
    'analytics',
    where: 'timestamp < ?',
    whereArgs: [cutoffTime],
  );
}
```

---

## Conclusion

This database schema provides a robust foundation for the iSuite application, ensuring:

- **Data Integrity**: Proper constraints and relationships
- **Performance**: Strategic indexing and query optimization
- **Scalability**: Flexible schema for future enhancements
- **Security**: Encryption and access controls
- **Maintainability**: Clear documentation and migration strategy

The schema is designed to handle the complex data relationships required by a comprehensive productivity suite while maintaining excellent performance characteristics.

---

**Note**: This schema documentation is updated with each database version change. Always refer to the latest version in the repository.
