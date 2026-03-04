import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../config/central_config.dart';
import 'logging_service.dart';

/// Free Database Options Service for iSuite
/// Provides multiple FREE database alternatives: SQLite (built-in), Hive, and Isar
/// Users can choose the best database for their needs - all completely free!
class FreeDatabaseService {
  static final FreeDatabaseService _instance = FreeDatabaseService._internal();
  factory FreeDatabaseService() => _instance;

  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();

  // Database instances
  Isar? _isarInstance;
  final Map<String, Box> _hiveBoxes = {};

  // Database types
  DatabaseType _activeDatabase = DatabaseType.sqlite; // Default to SQLite

  bool _isInitialized = false;
  final StreamController<DatabaseEvent> _databaseEventController =
      StreamController.broadcast();

  Stream<DatabaseEvent> get databaseEvents => _databaseEventController.stream;

  FreeDatabaseService._internal();

  /// Initialize free database service with user's choice
  Future<void> initialize({DatabaseType? preferredDatabase}) async {
    if (_isInitialized) return;

    try {
      // Get user's preferred database from config
      final configDatabase = await _config.getParameter<String>('database.type',
          defaultValue: 'sqlite');
      _activeDatabase = preferredDatabase ??
          DatabaseType.values.firstWhere(
            (type) => type.toString().split('.').last == configDatabase,
            orElse: () => DatabaseType.sqlite,
          );

      _logger.info(
          'Initializing Free Database Service with ${_activeDatabase.name}',
          'FreeDatabaseService');

      // Register with CentralConfig
      await _config.registerComponent('FreeDatabaseService', '1.0.0',
          'Multi-database service with SQLite, Hive, and Isar - all completely free!',
          dependencies: [
            'CentralConfig',
            'LoggingService'
          ],
          parameters: {
            // Database selection
            'database.type': _activeDatabase.toString().split('.').last,
            'database.sqlite.enabled': true,
            'database.hive.enabled': true,
            'database.isar.enabled': true,

            // SQLite settings
            'database.sqlite.path': 'isuite.db',
            'database.sqlite.journal_mode': 'WAL',
            'database.sqlite.synchronous': 'NORMAL',

            // Hive settings
            'database.hive.path': 'hive_data',
            'database.hive.encryption_enabled': false,
            'database.hive.lazy_boxes_enabled': true,

            // Isar settings
            'database.isar.path': 'isar_data',
            'database.isar.max_size': 1000000000, // 1GB
            'database.isar.compaction_enabled': true,

            // Performance settings
            'database.cache.enabled': true,
            'database.cache.size_mb': 50,
            'database.performance.monitoring_enabled': true,

            // Backup settings
            'database.backup.enabled': true,
            'database.backup.interval_hours': 24,
            'database.backup.max_backups': 7,
          });

      // Initialize the chosen database
      await _initializeChosenDatabase();

      _isInitialized = true;
      _emitDatabaseEvent(DatabaseEventType.initialized);

      _logger.info(
          'Free Database Service initialized successfully with ${_activeDatabase.name}',
          'FreeDatabaseService');
    } catch (e, stackTrace) {
      _logger.error(
          'Failed to initialize Free Database Service', 'FreeDatabaseService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Switch to a different database type
  Future<void> switchDatabase(DatabaseType newDatabase) async {
    if (newDatabase == _activeDatabase) return;

    _logger.info(
        'Switching database from ${_activeDatabase.name} to ${newDatabase.name}',
        'FreeDatabaseService');

    // Close current database
    await _closeCurrentDatabase();

    // Update configuration
    await _config.setParameter(
        'database.type', newDatabase.toString().split('.').last);
    _activeDatabase = newDatabase;

    // Initialize new database
    await _initializeChosenDatabase();

    _emitDatabaseEvent(DatabaseEventType.switched,
        data: {'from': _activeDatabase.name, 'to': newDatabase.name});
    _logger.info('Successfully switched to ${newDatabase.name} database',
        'FreeDatabaseService');
  }

  /// Get current active database type
  DatabaseType get activeDatabase => _activeDatabase;

  /// Check if database is initialized
  bool get isInitialized => _isInitialized;

  /// SQLite Operations (Built-in, completely free)

  /// Execute SQLite query
  Future<List<Map<String, dynamic>>> querySQLite(String sql,
      [List<dynamic>? arguments]) async {
    if (_activeDatabase != DatabaseType.sqlite) {
      throw UnsupportedError(
          'SQLite operations only available when SQLite is active database');
    }

    // SQLite operations would be handled by existing database_helper.dart
    // This is a placeholder - actual implementation would delegate to SQLite database
    _logger.debug('Executing SQLite query: $sql', 'FreeDatabaseService');
    return []; // Placeholder
  }

  /// Insert data into SQLite table
  Future<int> insertSQLite(String table, Map<String, dynamic> data) async {
    if (_activeDatabase != DatabaseType.sqlite) {
      throw UnsupportedError(
          'SQLite operations only available when SQLite is active database');
    }

    _logger.debug('Inserting into SQLite table: $table', 'FreeDatabaseService');
    return 0; // Placeholder
  }

  /// Update SQLite data
  Future<int> updateSQLite(
      String table, Map<String, dynamic> data, String where,
      [List<dynamic>? whereArgs]) async {
    if (_activeDatabase != DatabaseType.sqlite) {
      throw UnsupportedError(
          'SQLite operations only available when SQLite is active database');
    }

    _logger.debug('Updating SQLite table: $table', 'FreeDatabaseService');
    return 0; // Placeholder
  }

  /// Delete from SQLite
  Future<int> deleteSQLite(String table, String where,
      [List<dynamic>? whereArgs]) async {
    if (_activeDatabase != DatabaseType.sqlite) {
      throw UnsupportedError(
          'SQLite operations only available when SQLite is active database');
    }

    _logger.debug('Deleting from SQLite table: $table', 'FreeDatabaseService');
    return 0; // Placeholder
  }

  /// Hive Operations (Fast NoSQL, completely free)

  /// Get or create Hive box
  Future<Box<T>> getHiveBox<T>(String boxName) async {
    if (_activeDatabase != DatabaseType.hive) {
      throw UnsupportedError(
          'Hive operations only available when Hive is active database');
    }

    if (_hiveBoxes.containsKey(boxName)) {
      return _hiveBoxes[boxName] as Box<T>;
    }

    final box = await Hive.openBox<T>(boxName);
    _hiveBoxes[boxName] = box;

    _logger.debug('Opened Hive box: $boxName', 'FreeDatabaseService');
    return box;
  }

  /// Store data in Hive
  Future<void> putHive<T>(String boxName, dynamic key, T value) async {
    final box = await getHiveBox<T>(boxName);
    await box.put(key, value);
    _logger.debug(
        'Stored data in Hive box $boxName: $key', 'FreeDatabaseService');
  }

  /// Get data from Hive
  Future<T?> getHive<T>(String boxName, dynamic key) async {
    final box = await getHiveBox<T>(boxName);
    final value = box.get(key);
    _logger.debug(
        'Retrieved data from Hive box $boxName: $key', 'FreeDatabaseService');
    return value;
  }

  /// Delete from Hive
  Future<void> deleteHive(String boxName, dynamic key) async {
    final box = await getHiveBox(boxName);
    await box.delete(key);
    _logger.debug(
        'Deleted data from Hive box $boxName: $key', 'FreeDatabaseService');
  }

  /// Get all keys from Hive box
  Future<List<dynamic>> getHiveKeys(String boxName) async {
    final box = await getHiveBox(boxName);
    return box.keys.toList();
  }

  /// Isar Operations (Advanced NoSQL with search, completely free)

  /// Initialize Isar instance
  Future<void> _initializeIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    final isarPath = path.join(
        dir.path,
        await _config.getParameter<String>('database.isar.path',
            defaultValue: 'isar_data'));

    _isarInstance = await Isar.open(
      [], // Schema would be defined based on data models
      directory: isarPath,
      maxSizeMiB: (await _config.getParameter<int>('database.isar.max_size',
                  defaultValue: 1000000000) /
              (1024 * 1024))
          .round(),
    );

    _logger.debug(
        'Isar database initialized at: $isarPath', 'FreeDatabaseService');
  }

  /// Get Isar instance
  Isar get isar {
    if (_activeDatabase != DatabaseType.isar) {
      throw UnsupportedError(
          'Isar operations only available when Isar is active database');
    }
    if (_isarInstance == null) {
      throw StateError('Isar not initialized');
    }
    return _isarInstance!;
  }

  /// Generic database operations (work with any active database)

  /// Store data generically
  Future<void> store(
      String collection, String key, Map<String, dynamic> data) async {
    switch (_activeDatabase) {
      case DatabaseType.sqlite:
        await insertSQLite(collection, {...data, 'id': key});
        break;
      case DatabaseType.hive:
        await putHive(collection, key, data);
        break;
      case DatabaseType.isar:
        // Isar would use specific collections
        _logger.warning('Isar generic operations not implemented yet',
            'FreeDatabaseService');
        break;
    }
  }

  /// Retrieve data generically
  Future<Map<String, dynamic>?> retrieve(String collection, String key) async {
    switch (_activeDatabase) {
      case DatabaseType.sqlite:
        final results =
            await querySQLite('SELECT * FROM $collection WHERE id = ?', [key]);
        return results.isNotEmpty ? results.first : null;
      case DatabaseType.hive:
        return await getHive<Map<String, dynamic>>(collection, key);
      case DatabaseType.isar:
        // Isar would use specific queries
        _logger.warning('Isar generic operations not implemented yet',
            'FreeDatabaseService');
        return null;
    }
  }

  /// Delete data generically
  Future<void> remove(String collection, String key) async {
    switch (_activeDatabase) {
      case DatabaseType.sqlite:
        await deleteSQLite(collection, 'id = ?', [key]);
        break;
      case DatabaseType.hive:
        await deleteHive(collection, key);
        break;
      case DatabaseType.isar:
        // Isar would use specific deletion
        _logger.warning('Isar generic operations not implemented yet',
            'FreeDatabaseService');
        break;
    }
  }

  /// Query data generically
  Future<List<Map<String, dynamic>>> find(
    String collection, {
    Map<String, dynamic>? filter,
    int? limit,
    int? offset,
  }) async {
    switch (_activeDatabase) {
      case DatabaseType.sqlite:
        String where = '';
        List<dynamic> args = [];
        if (filter != null) {
          final conditions = <String>[];
          filter.forEach((key, value) {
            conditions.add('$key = ?');
            args.add(value);
          });
          where = conditions.join(' AND ');
        }
        return await querySQLite(
            'SELECT * FROM $collection ${where.isNotEmpty ? 'WHERE $where' : ''} LIMIT ? OFFSET ?',
            [...args, limit ?? -1, offset ?? 0]);
      case DatabaseType.hive:
        final box = await getHiveBox<Map<String, dynamic>>(collection);
        var values = box.values;
        if (filter != null) {
          values = values.where((item) {
            return filter.entries
                .every((entry) => item[entry.key] == entry.value);
          });
        }
        final list = values.toList();
        final start = offset ?? 0;
        final end = limit != null ? start + limit : list.length;
        return list.sublist(start, end.clamp(0, list.length));
      case DatabaseType.isar:
        // Isar would use specific queries
        _logger.warning('Isar generic operations not implemented yet',
            'FreeDatabaseService');
        return [];
    }
  }

  /// Database maintenance operations

  /// Optimize database performance
  Future<void> optimize() async {
    _logger.info(
        'Optimizing ${_activeDatabase.name} database', 'FreeDatabaseService');

    switch (_activeDatabase) {
      case DatabaseType.sqlite:
        // SQLite optimization (VACUUM, ANALYZE, etc.)
        await querySQLite('VACUUM');
        await querySQLite('ANALYZE');
        break;
      case DatabaseType.hive:
        // Hive optimization (compact boxes)
        for (final box in _hiveBoxes.values) {
          await box.compact();
        }
        break;
      case DatabaseType.isar:
        // Isar optimization (compact database)
        await _isarInstance?.compact();
        break;
    }

    _emitDatabaseEvent(DatabaseEventType.optimized);
    _logger.info('Database optimization completed', 'FreeDatabaseService');
  }

  /// Create database backup
  Future<String?> backup({String? customPath}) async {
    final backupEnabled = await _config
        .getParameter<bool>('database.backup.enabled', defaultValue: true);
    if (!backupEnabled) return null;

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupName = '${_activeDatabase.name}_backup_$timestamp';

    try {
      switch (_activeDatabase) {
        case DatabaseType.sqlite:
          // SQLite backup
          final dbPath = await _config.getParameter<String>(
              'database.sqlite.path',
              defaultValue: 'isuite.db');
          final backupPath = customPath ?? '$backupName.db';
          await File(dbPath).copy(backupPath);
          break;
        case DatabaseType.hive:
          // Hive backup
          final hivePath = await _config.getParameter<String>(
              'database.hive.path',
              defaultValue: 'hive_data');
          final backupPath = customPath ?? backupName;
          await _backupDirectory(hivePath, backupPath);
          break;
        case DatabaseType.isar:
          // Isar backup
          final isarPath = await _config.getParameter<String>(
              'database.isar.path',
              defaultValue: 'isar_data');
          final backupPath = customPath ?? backupName;
          await _backupDirectory(isarPath, backupPath);
          break;
      }

      _emitDatabaseEvent(DatabaseEventType.backedUp,
          data: {'path': customPath ?? backupName});
      _logger.info('Database backup created: ${customPath ?? backupName}',
          'FreeDatabaseService');
      return customPath ?? backupName;
    } catch (e) {
      _logger.error('Database backup failed', 'FreeDatabaseService', error: e);
      return null;
    }
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getStats() async {
    final stats = <String, dynamic>{
      'database_type': _activeDatabase.name,
      'initialized': _isInitialized,
    };

    switch (_activeDatabase) {
      case DatabaseType.sqlite:
        // SQLite stats
        final tables = await querySQLite(
            "SELECT name FROM sqlite_master WHERE type='table'");
        stats.addAll({
          'table_count': tables.length,
          'tables': tables.map((t) => t['name']).toList(),
        });
        break;
      case DatabaseType.hive:
        // Hive stats
        stats.addAll({
          'box_count': _hiveBoxes.length,
          'boxes': _hiveBoxes.keys.toList(),
        });
        break;
      case DatabaseType.isar:
        // Isar stats
        if (_isarInstance != null) {
          stats.addAll({
            'collection_count': _isarInstance!.collections.length,
            'collections':
                _isarInstance!.collections.map((c) => c.name).toList(),
          });
        }
        break;
    }

    return stats;
  }

  /// Private helper methods

  Future<void> _initializeChosenDatabase() async {
    switch (_activeDatabase) {
      case DatabaseType.sqlite:
        // SQLite is handled by existing database_helper.dart
        _logger.debug('SQLite database active', 'FreeDatabaseService');
        break;
      case DatabaseType.hive:
        await _initializeHive();
        break;
      case DatabaseType.isar:
        await _initializeIsar();
        break;
    }
  }

  Future<void> _initializeHive() async {
    final appDir = await getApplicationDocumentsDirectory();
    final hivePath = path.join(
        appDir.path,
        await _config.getParameter<String>('database.hive.path',
            defaultValue: 'hive_data'));

    Hive.init(hivePath);
    _logger.debug(
        'Hive database initialized at: $hivePath', 'FreeDatabaseService');
  }

  Future<void> _closeCurrentDatabase() async {
    switch (_activeDatabase) {
      case DatabaseType.sqlite:
        // SQLite handled elsewhere
        break;
      case DatabaseType.hive:
        await _closeHiveBoxes();
        break;
      case DatabaseType.isar:
        await _isarInstance?.close();
        _isarInstance = null;
        break;
    }
  }

  Future<void> _closeHiveBoxes() async {
    for (final box in _hiveBoxes.values) {
      await box.close();
    }
    _hiveBoxes.clear();
  }

  Future<void> _backupDirectory(String sourcePath, String backupPath) async {
    final sourceDir = Directory(sourcePath);
    final backupDir = Directory(backupPath);

    if (await sourceDir.exists()) {
      await backupDir.create(recursive: true);
      await for (final entity in sourceDir.list()) {
        final newPath = path.join(backupDir.path, path.basename(entity.path));
        if (entity is File) {
          await entity.copy(newPath);
        } else if (entity is Directory) {
          await _backupDirectory(entity.path, newPath);
        }
      }
    }
  }

  void _emitDatabaseEvent(DatabaseEventType type,
      {Map<String, dynamic>? data}) {
    final event = DatabaseEvent(
      type: type,
      databaseType: _activeDatabase,
      timestamp: DateTime.now(),
      data: data,
    );
    _databaseEventController.add(event);
  }

  /// Dispose service
  Future<void> dispose() async {
    await _closeCurrentDatabase();
    _databaseEventController.close();
    _isInitialized = false;
    _logger.info('Free Database Service disposed', 'FreeDatabaseService');
  }
}

/// Database Types (All Completely Free!)
enum DatabaseType {
  sqlite, // Built-in SQLite - fastest for relational data
  hive, // NoSQL key-value store - fastest for simple data
  isar, // Advanced NoSQL with search - best for complex queries
}

/// Database Event Types
enum DatabaseEventType {
  initialized,
  switched,
  optimized,
  backedUp,
  error,
}

/// Database Event
class DatabaseEvent {
  final DatabaseEventType type;
  final DatabaseType databaseType;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  DatabaseEvent({
    required this.type,
    required this.databaseType,
    required this.timestamp,
    this.data,
  });
}

/// Free Database Comparison Helper
class FreeDatabaseComparison {
  static const Map<DatabaseType, Map<String, dynamic>> features = {
    DatabaseType.sqlite: {
      'name': 'SQLite',
      'type': 'Relational',
      'best_for': 'Complex queries, relationships, transactions',
      'performance': 'Excellent for reads/writes',
      'storage': 'File-based',
      'free': true,
      'setup_complexity': 'Low',
    },
    DatabaseType.hive: {
      'name': 'Hive',
      'type': 'NoSQL Key-Value',
      'best_for': 'Simple data storage, caching, user preferences',
      'performance': 'Fastest for simple operations',
      'storage': 'File-based with encryption',
      'free': true,
      'setup_complexity': 'Very Low',
    },
    DatabaseType.isar: {
      'name': 'Isar',
      'type': 'Advanced NoSQL',
      'best_for': 'Complex objects, search, filtering, large datasets',
      'performance': 'Excellent for complex queries',
      'storage': 'File-based with advanced features',
      'free': true,
      'setup_complexity': 'Medium',
    },
  };

  static DatabaseType recommendFor(Usecase usecase) {
    switch (usecase) {
      case Usecase.simpleStorage:
        return DatabaseType.hive;
      case Usecase.complexQueries:
        return DatabaseType.isar;
      case Usecase.relationships:
        return DatabaseType.sqlite;
      case Usecase.caching:
        return DatabaseType.hive;
      case Usecase.userData:
        return DatabaseType.isar;
    }
  }
}

/// Use Cases for Database Selection
enum Usecase {
  simpleStorage, // User preferences, settings
  complexQueries, // Search, filtering, complex data
  relationships, // Related data, joins
  caching, // Temporary data storage
  userData, // User profiles, app data
}
