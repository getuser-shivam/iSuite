# iSuite Database Schema Documentation

## Table of Contents

- [Overview](#overview)
- [Database Tables](#database-tables)
- [Entity Relationships](#entity-relationships)
- [Indexes](#indexes)
- [Data Types](#data-types)
- [Migration Strategy](#migration-strategy)
- [Performance Optimization](#performance-optimization)

---

## Overview

iSuite uses **SQLite** as its local database solution, providing a robust, ACID-compliant data storage system with support for offline functionality and data synchronization.

### Database Configuration

- **Database Name**: `isuite.db`
- **Version**: 1
- **Foreign Keys**: Enabled with cascade operations
- **WAL Mode**: Write-Ahead Logging for better concurrency
- **Journaling**: Enabled for data integrity

---

## Database Tables

### Users Table

**Purpose**: Stores user authentication data and preferences

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  avatar TEXT,
  created_at INTEGER NOT NULL,
  last_login_at INTEGER,
  preferences TEXT, -- JSON string storing user preferences
  is_email_verified INTEGER NOT NULL DEFAULT 0,
  is_premium INTEGER NOT NULL DEFAULT 0
);
```

**Fields Description**:

| Field | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique user identifier |
| `name` | TEXT | NOT NULL | User display name |
| `email` | TEXT | UNIQUE NOT NULL | User email address |
| `avatar` | TEXT | NULLABLE | Profile picture URL |
| `created_at` | INTEGER | NOT NULL | Account creation timestamp (Unix epoch) |
| `last_login_at` | INTEGER | NULLABLE | Last login timestamp (Unix epoch) |
| `preferences` | TEXT | NULLABLE | User preferences as JSON string |
| `is_email_verified` | INTEGER | NOT NULL DEFAULT 0 | Email verification status (0/1) |
| `is_premium` | INTEGER | NOT NULL DEFAULT 0 | Premium subscription status (0/1) |

### Tasks Table

**Purpose**: Core task management data storage

```sql
CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  priority INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'todo',
  category TEXT NOT NULL DEFAULT 'work',
  due_date INTEGER,
  user_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  completed_at INTEGER,
  tags TEXT, -- JSON array of tag strings
  is_recurring INTEGER NOT NULL DEFAULT 0,
  recurrence_pattern TEXT,
  estimated_minutes INTEGER,
  actual_minutes INTEGER,
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);
```

**Fields Description**:

| Field | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique task identifier |
| `title` | TEXT | NOT NULL | Task title |
| `description` | TEXT | NULLABLE | Detailed task description |
| `priority` | INTEGER | NOT NULL DEFAULT 0 | Priority level (1-4) |
| `status` | TEXT | NOT NULL DEFAULT 'todo' | Task status |
| `category` | TEXT | NOT NULL DEFAULT 'work' | Task category |
| `due_date` | INTEGER | NULLABLE | Due date timestamp (Unix epoch) |
| `user_id` | TEXT | NOT NULL | Foreign key to users table |
| `created_at` | INTEGER | NOT NULL | Creation timestamp (Unix epoch) |
| `completed_at` | INTEGER | NULLABLE | Completion timestamp (Unix epoch) |
| `tags` | TEXT | NULLABLE | Tags as JSON array string |
| `is_recurring` | INTEGER | NOT NULL DEFAULT 0 | Recurring task flag (0/1) |
| `recurrence_pattern` | TEXT | NULLABLE | Recurrence pattern string |
| `estimated_minutes` | INTEGER | NULLABLE | Estimated time in minutes |
| `actual_minutes` | INTEGER | NULLABLE | Actual time taken in minutes |

### Settings Table

**Purpose**: Application settings and user preferences

```sql
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  user_id TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

**Fields Description**:

| Field | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `key` | TEXT | PRIMARY KEY | Setting identifier |
| `value` | TEXT | NOT NULL | Setting value |
| `user_id` | TEXT | NULLABLE | Foreign key to users table |
| `created_at` | INTEGER | NOT NULL | Creation timestamp (Unix epoch) |
| `updated_at` | INTEGER | NOT NULL | Last update timestamp (Unix epoch) |

---

## Entity Relationships

### Entity Relationship Diagram

```
Users (1) ----< (1) Tasks
   |                     |
   |                     |
   |                     |
   +----< (1) Settings
```

### Relationship Rules

1. **One-to-Many**: Users can have multiple tasks
2. **Cascade Delete**: Deleting a user removes all associated tasks
3. **Optional Settings**: Settings can be global or user-specific
4. **Referential Integrity**: All foreign keys must reference valid users

### Data Consistency

- **User Task Ownership**: All tasks must have a valid user_id
- **Task Status Workflow**: Tasks follow defined status transitions
- **Priority Validation**: Priority values must be within defined range
- **Category Validation**: Categories must be from predefined enum

---

## Indexes

### Performance Indexes

```sql
-- Users table indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);

-- Tasks table indexes
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_category ON tasks(category);
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_tasks_created_at ON tasks(created_at);
CREATE INDEX idx_tasks_completed_at ON tasks(completed_at);

-- Settings table indexes
CREATE INDEX idx_settings_user_id ON settings(user_id);
CREATE INDEX idx_settings_key ON settings(key);
CREATE INDEX idx_settings_updated_at ON settings(updated_at);
```

### Index Strategy

1. **Foreign Key Indexes**: All foreign keys are indexed
2. **Query Optimization**: Common query patterns are indexed
3. **Composite Indexes**: Multi-column indexes for complex queries
4. **Maintenance**: Indexes are optimized for read-heavy operations

---

## Data Types

### Enum Mappings

#### Task Priority

| Value | Database | Application | Color |
|--------|-----------|-------------|--------|
| Low | 1 | TaskPriority.low | Colors.grey |
| Medium | 2 | TaskPriority.medium | Colors.orange |
| High | 3 | TaskPriority.high | Colors.red |
| Urgent | 4 | TaskPriority.urgent | Colors.purple |

#### Task Status

| Value | Database | Application | Color |
|--------|-----------|-------------|--------|
| To Do | 'todo' | TaskStatus.todo | Colors.blue |
| In Progress | 'in_progress' | TaskStatus.inProgress | Colors.orange |
| Completed | 'completed' | TaskStatus.completed | Colors.green |
| Cancelled | 'cancelled' | TaskStatus.cancelled | Colors.grey |

#### Task Category

| Value | Database | Application | Icon | Color |
|--------|-----------|-------------|--------|--------|
| Work | 'work' | TaskCategory.work | Icons.work | Colors.blue |
| Personal | 'personal' | TaskCategory.personal | Icons.person | Colors.green |
| Shopping | 'shopping' | TaskCategory.shopping | Icons.shopping_cart | Colors.orange |
| Health | 'health' | TaskCategory.health | Icons.favorite | Colors.red |
| Education | 'education' | TaskCategory.education | Icons.school | Colors.purple |
| Finance | 'finance' | TaskCategory.finance | Icons.account_balance | Colors.teal |
| Other | 'other' | TaskCategory.other | Icons.category | Colors.grey |

### JSON Data Storage

#### Tags Array
```dart
// Stored as JSON string in database
List<String> tags = ['urgent', 'project', 'meeting'];
String tagsJson = json.encode(tags);

// Retrieval
List<String> retrievedTags = List<String>.from(json.decode(tagsJson));
```

#### User Preferences
```dart
// Stored as JSON string
class UserPreferences {
  final String language;
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final bool biometricEnabled;
  final String dateFormat;
  final String timeFormat;
  final bool autoBackupEnabled;
  
  Map<String, dynamic> toJson() => {
    'language': language,
    'notificationsEnabled': notificationsEnabled,
    // ... other fields
  };
}
```

---

## Migration Strategy

### Version Control

- **Current Version**: 1
- **Migration Files**: `database/migrations/`
- **Version Tracking**: Database version stored in metadata

### Migration Process

```dart
class DatabaseHelper {
  static const int _databaseVersion = 1;
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      // Execute migration scripts
      await _migrateFromV1ToV2(db);
    }
  }
  
  Future<void> _migrateFromV1ToV2(Database db) async {
    // Migration logic
    await db.execute('ALTER TABLE tasks ADD COLUMN new_column TEXT');
  }
}
```

### Migration Best Practices

1. **Backward Compatibility**: Maintain compatibility with older app versions
2. **Data Integrity**: Ensure no data loss during migration
3. **Rollback Support**: Ability to revert failed migrations
4. **Testing**: Test migrations with sample data
5. **Performance**: Minimize migration time and resource usage

---

## Performance Optimization

### Query Optimization

#### Efficient Queries

```dart
// Good: Indexed query
Future<List<Task>> getTasksByUser(String userId) async {
  return await _database.query(
    'tasks',
    where: 'user_id = ?',
    whereArgs: [userId],
    orderBy: 'created_at DESC',
  );
}

// Bad: Full table scan
Future<List<Task>> getAllTasks() async {
  return await _database.query('tasks');
}
```

#### Batch Operations

```dart
// Batch insert for better performance
Future<void> insertMultipleTasks(List<Task> tasks) async {
  final batch = _database.batch();
  for (final task in tasks) {
    batch.insert('tasks', task.toJson());
  }
  await batch.commit(noResult: true);
}
```

### Connection Management

```dart
class DatabaseHelper {
  static Database? _database;
  static final _lock = Lock();
  
  Future<Database> get database async {
    if (_database == null) {
      _lock.synchronized(() async {
        _database = await openDatabase('isuite.db');
      }());
    }
    return _database!;
  }
}
```

### Memory Management

```dart
// Stream-based queries for large datasets
Stream<List<Task>> watchTasksByUser(String userId) {
  return _database.query('tasks', 
    where: 'user_id = ?',
    whereArgs: [userId],
  ).map((maps) => maps.map((map) => Task.fromJson(map)).toList());
}
```

---

## Data Integrity

### Constraints

```sql
-- Example of data integrity constraints
CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL CHECK(length(title) > 0),
  priority INTEGER NOT NULL CHECK(priority BETWEEN 1 AND 4),
  status TEXT NOT NULL CHECK(status IN ('todo', 'in_progress', 'completed', 'cancelled')),
  user_id TEXT NOT NULL,
  due_date INTEGER CHECK(due_date IS NULL OR due_date > strftime('%s', 'now')),
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  completed_at INTEGER CHECK(completed_at IS NULL OR completed_at >= created_at),
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);
```

### Validation Rules

```dart
// Application-level validation
class TaskValidator {
  static String? validateTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return 'Title is required';
    }
    if (title.trim().length > 200) {
      return 'Title must be 200 characters or less';
    }
    return null;
  }
  
  static String? validateDueDate(DateTime? dueDate) {
    if (dueDate != null && dueDate.isBefore(DateTime.now())) {
      return 'Due date cannot be in the past';
    }
    return null;
  }
}
```

---

## Backup and Recovery

### Backup Strategy

```dart
class BackupManager {
  static Future<void> createBackup() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.query('SELECT * FROM tasks');
    final backupFile = File('backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await backupFile.writeAsString(json.encode(data));
  }
  
  static Future<void> restoreFromBackup(String backupPath) async {
    final backupData = await File(backupPath).readAsString();
    final tasks = List<Map<String, dynamic>>.from(json.decode(backupData));
    
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final task in tasks) {
      batch.insert('tasks', task);
    }
    await batch.commit(noResult: true);
  }
}
```

### Recovery Procedures

1. **Automatic Backups**: Daily automatic backups
2. **Manual Exports**: User-initiated data exports
3. **Cloud Sync**: Optional cloud synchronization
4. **Data Validation**: Verify data integrity after restore

---

## Security Considerations

### Data Protection

```dart
class SecureDatabaseHelper {
  static Future<void> encryptSensitiveData() async {
    // Implement data encryption for sensitive fields
  }
  
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
```

### Access Control

```dart
class AccessControl {
  static bool canAccessTask(Task task, String userId) {
    // Check if user owns the task
    return task.userId == userId;
  }
  
  static bool canModifyTask(Task task, String userId) {
    return canAccessTask(task, userId) && 
           task.status != TaskStatus.completed;
  }
}
```

---

## Monitoring and Maintenance

### Performance Metrics

```dart
class DatabaseMetrics {
  static Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await DatabaseHelper.instance.database;
    
    final result = await db.rawQuery('''
      SELECT 
        (SELECT COUNT(*) FROM tasks) as total_tasks,
        (SELECT COUNT(*) FROM tasks WHERE status = 'completed') as completed_tasks,
        (SELECT COUNT(*) FROM tasks WHERE due_date < strftime('%s', 'now')) as overdue_tasks,
        (SELECT COUNT(*) FROM sqlite_master WHERE name = 'tasks') as table_size
    ''');
    
    return result.first;
  }
}
```

### Maintenance Operations

```dart
class DatabaseMaintenance {
  static Future<void> vacuum() async {
    final db = await DatabaseHelper.instance.database;
    await db.execute('VACUUM');
  }
  
  static Future<void> analyze() async {
    final db = await DatabaseHelper.instance.database;
    await db.execute('ANALYZE');
  }
  
  static Future<void> reindex() async {
    final db = await DatabaseHelper.instance.database;
    await db.execute('REINDEX');
  }
}
```

---

## API Reference

### Common Queries

```dart
// Get all tasks for a user
Future<List<Task>> getUserTasks(String userId) async {
  return await _database.query(
    'tasks',
    where: 'user_id = ?',
    whereArgs: [userId],
    orderBy: 'created_at DESC',
  );
}

// Get tasks due today
Future<List<Task>> getTasksDueToday() async {
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  
  return await _database.query(
    'tasks',
    where: 'due_date >= ? AND due_date < ?',
    whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
    orderBy: 'due_date ASC',
  );
}

// Search tasks
Future<List<Task>> searchTasks(String query, String userId) async {
  return await _database.query(
    'tasks',
    where: 'user_id = ? AND (title LIKE ? OR description LIKE ?)',
    whereArgs: [userId, '%$query%', '%$query%'],
    orderBy: 'created_at DESC',
  );
}
```

---

*Last updated: February 2026*
*Version: 1.0.0*
