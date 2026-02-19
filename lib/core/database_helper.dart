import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  static const String _databaseName = 'isuite.db';
  static const int _databaseVersion = 2;

  // Tables
  static const String tableTasks = 'tasks';
  static const String tableCalendarEvents = 'calendar_events';
  static const String tableNotes = 'notes';
  static const String tableFiles = 'files';

  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Create tasks table
    await db.execute('''
      CREATE TABLE $tableTasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        category TEXT NOT NULL,
        tags TEXT,
        due_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        completed_at TEXT,
        user_id TEXT
      )
    ''');

    // Create calendar_events table
    await db.execute('''
      CREATE TABLE $tableCalendarEvents (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        event_type TEXT NOT NULL,
        status TEXT NOT NULL,
        priority TEXT NOT NULL,
        category TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        is_all_day INTEGER NOT NULL DEFAULT 0,
        location TEXT,
        tags TEXT,
        reminder_minutes INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        user_id TEXT
      )
    ''');

    // Create notes table
    await db.execute('''
      CREATE TABLE $tableNotes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        priority TEXT NOT NULL,
        category TEXT NOT NULL,
        tags TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        word_count INTEGER DEFAULT 0,
        reading_time INTEGER DEFAULT 0,
        due_date TEXT,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        color TEXT,
        is_encrypted INTEGER NOT NULL DEFAULT 0,
        password TEXT,
        user_id TEXT
      )
    ''');

    // Create files table
    await db.execute('''
      CREATE TABLE $tableFiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        path TEXT NOT NULL,
        size INTEGER NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        uploaded_at TEXT,
        mime_type TEXT,
        thumbnail TEXT,
        metadata TEXT,
        user_id TEXT,
        is_encrypted INTEGER NOT NULL DEFAULT 0,
        password TEXT,
        tags TEXT,
        description TEXT,
        download_count INTEGER DEFAULT 0,
        last_accessed TEXT
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_tasks_status ON $tableTasks(status)');
    await db.execute('CREATE INDEX idx_tasks_due_date ON $tableTasks(due_date)');
    await db.execute('CREATE INDEX idx_tasks_user_id ON $tableTasks(user_id)');

    await db.execute('CREATE INDEX idx_calendar_events_start_date ON $tableCalendarEvents(start_date)');
    await db.execute('CREATE INDEX idx_calendar_events_end_date ON $tableCalendarEvents(end_date)');
    await db.execute('CREATE INDEX idx_calendar_events_status ON $tableCalendarEvents(status)');
    await db.execute('CREATE INDEX idx_calendar_events_user_id ON $tableCalendarEvents(user_id)');

    await db.execute('CREATE INDEX idx_notes_status ON $tableNotes(status)');
    await db.execute('CREATE INDEX idx_notes_type ON $tableNotes(type)');
    await db.execute('CREATE INDEX idx_notes_created_at ON $tableNotes(created_at)');
    await db.execute('CREATE INDEX idx_notes_user_id ON $tableNotes(user_id)');

    await db.execute('CREATE INDEX idx_files_type ON $tableFiles(type)');
    await db.execute('CREATE INDEX idx_files_status ON $tableFiles(status)');
    await db.execute('CREATE INDEX idx_files_created_at ON $tableFiles(created_at)');
    await db.execute('CREATE INDEX idx_files_user_id ON $tableFiles(user_id)');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add files table if upgrading from version 1
      await db.execute('''
        CREATE TABLE $tableFiles (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          path TEXT NOT NULL,
          size INTEGER NOT NULL,
          type TEXT NOT NULL,
          status TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          uploaded_at TEXT,
          mime_type TEXT,
          thumbnail TEXT,
          metadata TEXT,
          user_id TEXT,
          is_encrypted INTEGER NOT NULL DEFAULT 0,
          password TEXT,
          tags TEXT,
          description TEXT,
          download_count INTEGER DEFAULT 0,
          last_accessed TEXT
        )
      ''');

      await db.execute('CREATE INDEX idx_files_type ON $tableFiles(type)');
      await db.execute('CREATE INDEX idx_files_status ON $tableFiles(status)');
      await db.execute('CREATE INDEX idx_files_created_at ON $tableFiles(created_at)');
      await db.execute('CREATE INDEX idx_files_user_id ON $tableFiles(user_id)');
    }
  }

  // Utility methods
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  static Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
