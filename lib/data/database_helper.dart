import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'isuite.db');

    return await openDatabase(
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

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_tasks_user_id ON tasks(user_id)');
    await db.execute('CREATE INDEX idx_notes_user_id ON notes(user_id)');
    await db.execute('CREATE INDEX idx_tasks_due_date ON tasks(due_date)');
    await db.execute('CREATE INDEX idx_notes_is_pinned ON notes(is_pinned)');
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
    return await db.insert(table, data);
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
    return await db.query(
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
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  // Transaction support
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  // Raw query support
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  Future<int> rawUpdate(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
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
    return await db.getVersion();
  }

  Future<String> getPath() async {
    return join(await getDatabasesPath(), 'isuite.db');
  }
}
