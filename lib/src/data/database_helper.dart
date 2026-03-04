import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'isuite.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        avatar TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        priority INTEGER NOT NULL DEFAULT 0,
        due_date INTEGER,
        user_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create notes table
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT,
        user_id TEXT NOT NULL,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        user_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create reminders table
    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        due_date INTEGER NOT NULL,
        repeat TEXT NOT NULL,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        snooze_until INTEGER,
        completed_at INTEGER,
        tags TEXT,
        user_id TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create calendar_events table
    await db.execute('''
      CREATE TABLE calendar_events (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        start_time INTEGER NOT NULL,
        end_time INTEGER NOT NULL,
        location TEXT,
        attendees TEXT,
        reminder_time INTEGER,
        is_all_day INTEGER NOT NULL DEFAULT 0,
        recurrence_rule TEXT,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        user_id TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create files table
    await db.execute('''
      CREATE TABLE files (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        mime_type TEXT,
        category TEXT,
        tags TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        user_id TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        icon TEXT,
        user_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create analytics table
    await db.execute('''
      CREATE TABLE analytics (
        id TEXT PRIMARY KEY,
        event_type TEXT NOT NULL,
        event_data TEXT,
        timestamp INTEGER NOT NULL,
        user_id TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create backups table
    await db.execute('''
      CREATE TABLE backups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        backup_path TEXT NOT NULL,
        backup_size INTEGER NOT NULL,
        backup_type TEXT NOT NULL,
        is_encrypted INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        user_id TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create saved_networks table
    await db.execute('''
      CREATE TABLE saved_networks (
        id TEXT PRIMARY KEY,
        ssid TEXT NOT NULL,
        bssid TEXT NOT NULL,
        signal_strength INTEGER NOT NULL,
        security_type TEXT NOT NULL,
        password TEXT,
        is_saved INTEGER NOT NULL DEFAULT 1,
        saved_at INTEGER,
        last_connected INTEGER,
        priority INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create file_sharing_connections table
    await db.execute('''
      CREATE TABLE file_sharing_connections (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        host TEXT NOT NULL,
        port INTEGER NOT NULL,
        protocol TEXT NOT NULL,
        username TEXT,
        password TEXT,
        is_secure INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        custom_headers TEXT,
        last_tested INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create file_transfers table
    await db.execute('''
      CREATE TABLE file_transfers (
        id TEXT PRIMARY KEY,
        connection_id TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_path TEXT,
        file_size INTEGER NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        progress REAL NOT NULL DEFAULT 0.0,
        speed REAL NOT NULL DEFAULT 0.0,
        duration INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        completed_at INTEGER,
        FOREIGN KEY (connection_id) REFERENCES file_sharing_connections (id) ON DELETE CASCADE
      )
    ''');

    // Create shared_files table
    await db.execute('''
      CREATE TABLE shared_files (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        path TEXT NOT NULL,
        size INTEGER NOT NULL,
        mime_type TEXT NOT NULL,
        shared_at INTEGER NOT NULL,
        expires_at INTEGER,
        is_shared INTEGER NOT NULL DEFAULT 1,
        share_url TEXT,
        qr_code TEXT,
        download_count INTEGER NOT NULL DEFAULT 0,
        metadata TEXT,
        password TEXT,
        is_public INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Update users table with missing columns
    await db.execute('''
      ALTER TABLE users ADD COLUMN avatar_url TEXT
    ''');

    await db.execute('''
      ALTER TABLE users ADD COLUMN phone TEXT
    ''');

    await db.execute('''
      ALTER TABLE users ADD COLUMN timezone TEXT DEFAULT 'UTC'
    ''');

    await db.execute('''
      ALTER TABLE users ADD COLUMN language TEXT DEFAULT 'en'
    ''');

    await db.execute('''
      ALTER TABLE users ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1
    ''');

    await db.execute('''
      ALTER TABLE users ADD COLUMN email_verified INTEGER NOT NULL DEFAULT 0
    ''');

    await db.execute('''
      ALTER TABLE users ADD COLUMN last_login_at INTEGER
    ''');

    // Update tasks table with missing columns
    await db.execute('''
      ALTER TABLE tasks ADD COLUMN category_id TEXT
    ''');

    await db.execute('''
      ALTER TABLE tasks ADD COLUMN tags TEXT
    ''');

    await db.execute('''
      ALTER TABLE tasks ADD COLUMN completed_at INTEGER
    ''');

    // Update notes table with missing columns
    await db.execute('''
      ALTER TABLE notes ADD COLUMN category TEXT
    ''');

    await db.execute('''
      ALTER TABLE notes ADD COLUMN tags TEXT
    ''');

    await db.execute('''
      ALTER TABLE notes ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_tasks_user_id ON tasks(user_id)');
    await db.execute('CREATE INDEX idx_notes_user_id ON notes(user_id)');
    await db.execute('CREATE INDEX idx_tasks_due_date ON tasks(due_date)');
    await db.execute('CREATE INDEX idx_notes_is_pinned ON notes(is_pinned)');
    await db
        .execute('CREATE INDEX idx_reminders_user_id ON reminders(user_id)');
    await db
        .execute('CREATE INDEX idx_reminders_due_date ON reminders(due_date)');
    await db.execute('CREATE INDEX idx_reminders_status ON reminders(status)');

    // Additional indexes for new tables
    await db.execute(
        'CREATE INDEX idx_calendar_events_user_id ON calendar_events(user_id)');
    await db.execute(
        'CREATE INDEX idx_calendar_events_start_time ON calendar_events(start_time)');
    await db.execute('CREATE INDEX idx_files_user_id ON files(user_id)');
    await db.execute('CREATE INDEX idx_files_category ON files(category)');
    await db
        .execute('CREATE INDEX idx_categories_user_id ON categories(user_id)');
    await db
        .execute('CREATE INDEX idx_analytics_user_id ON analytics(user_id)');
    await db.execute(
        'CREATE INDEX idx_analytics_timestamp ON analytics(timestamp)');
    await db.execute('CREATE INDEX idx_backups_user_id ON backups(user_id)');
    await db.execute(
        'CREATE INDEX idx_saved_networks_ssid ON saved_networks(ssid)');
    await db.execute(
        'CREATE INDEX idx_file_sharing_connections_protocol ON file_sharing_connections(protocol)');
    await db.execute(
        'CREATE INDEX idx_file_transfers_connection_id ON file_transfers(connection_id)');
    await db.execute(
        'CREATE INDEX idx_shared_files_shared_at ON shared_files(shared_at)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Example: Add new column to existing table
      // await db.execute('ALTER TABLE tasks ADD COLUMN category TEXT');
    }
  }

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    data['created_at'] = DateTime.now().millisecondsSinceEpoch;
    data['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    return db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    values['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    return db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  // Transaction support
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return db.transaction(action);
  }

  // Raw query support
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return db.rawQuery(sql, arguments);
  }

  Future<int> rawUpdate(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return db.rawUpdate(sql, arguments);
  }

  // Database maintenance
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('tasks');
      await txn.delete('notes');
      await txn.delete('settings');
      await txn.delete('users');
    });
  }

  // Get database info
  Future<int> getVersion() async {
    final db = await database;
    return db.getVersion();
  }

  Future<String> getPath() async => join(await getDatabasesPath(), 'isuite.db');
}
