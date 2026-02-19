import 'package:sqflite/sqflite.dart';
import '../../domain/models/task.dart';
import '../database_helper.dart';

class TaskRepository {
  static const String _tableName = 'tasks';
  static final Map<String, Map<String, dynamic>> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  Future<List<Task>> getAllTasks({String? userId}) async {
    final cacheKey = 'all_tasks_${userId ?? 'all'}';
    
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (DateTime.now().difference(cached['timestamp']) < _cacheDuration) {
        return List<Task>.from(cached['data']);
      } else {
        _cache.remove(cacheKey);
      }
    }

    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: userId != null ? 'userId = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'createdAt DESC',
    );
    final tasks = maps.map((map) => Task.fromJson(map)).toList();

    _cache[cacheKey] = {
      'data': List<Task>.from(tasks),
      'timestamp': DateTime.now(),
    };

    return tasks;
  }

  Future<List<Task>> getTasksByStatus(TaskStatus status, {String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'status = ?${userId != null ? ' AND userId = ?' : ''}',
      whereArgs: userId != null ? [status.name, userId] : [status.name],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Task.fromJson(map)).toList();
  }

  Future<List<Task>> getTasksByCategory(TaskCategory category, {String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'category = ?${userId != null ? ' AND userId = ?' : ''}',
      whereArgs: userId != null ? [category.name, userId] : [category.name],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Task.fromJson(map)).toList();
  }

  Future<List<Task>> getTasksByPriority(TaskPriority priority, {String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'priority = ?${userId != null ? ' AND userId = ?' : ''}',
      whereArgs: userId != null ? [priority.value, userId] : [priority.value],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Task.fromJson(map)).toList();
  }

  Future<List<Task>> getTasksDueToday({String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'dueDate >= ? AND dueDate < ?${userId != null ? ' AND userId = ?' : ''}',
      whereArgs: userId != null 
          ? [today.millisecondsSinceEpoch, tomorrow.millisecondsSinceEpoch, userId]
          : [today.millisecondsSinceEpoch, tomorrow.millisecondsSinceEpoch],
      orderBy: 'dueDate ASC',
    );
    return maps.map((map) => Task.fromJson(map)).toList();
  }

  Future<List<Task>> getOverdueTasks({String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'dueDate < ? AND status != ?${userId != null ? ' AND userId = ?' : ''}',
      whereArgs: userId != null 
          ? [now.millisecondsSinceEpoch, TaskStatus.completed.name, userId]
          : [now.millisecondsSinceEpoch, TaskStatus.completed.name],
      orderBy: 'dueDate ASC',
    );
    return maps.map((map) => Task.fromJson(map)).toList();
  }

  Future<List<Task>> searchTasks(String query, {String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: '(title LIKE ? OR description LIKE ?)${userId != null ? ' AND userId = ?' : ''}',
      whereArgs: userId != null 
          ? ['%$query%', '%$query%', userId]
          : ['%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Task.fromJson(map)).toList();
  }

  Future<Task?> getTaskById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Task.fromJson(maps.first);
    }
    return null;
  }

  static void clearCache() {
    _cache.clear();
  }

  Future<int> createTask(Task task) async {
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert(_tableName, task.toJson());
    clearCache();
    return id;
  }

  Future<void> updateTask(Task task) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      _tableName,
      task.toJson(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    clearCache();
  }

  Future<void> deleteTask(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    clearCache();
  }

  Future<List<Task>> getTasksPage(int offset, int limit, {String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: userId != null ? 'userId = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'createdAt DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => Task.fromJson(map)).toList();
  }

  Future<void> batchCreateTasks(List<Task> tasks) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final task in tasks) {
      batch.insert(_tableName, task.toJson());
    }
    await batch.commit(noResult: true);
    clearCache();
  }

  Future<int> getTaskCount({String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName${userId != null ? ' WHERE userId = ?' : ''}',
      userId != null ? [userId] : null,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getCompletedTaskCount({String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE status = ?${userId != null ? ' AND userId = ?' : ''}',
      userId != null ? [TaskStatus.completed.name, userId] : [TaskStatus.completed.name],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getPendingTaskCount({String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE status != ?${userId != null ? ' AND userId = ?' : ''}',
      userId != null ? [TaskStatus.completed.name, userId] : [TaskStatus.completed.name],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getOverdueTaskCount({String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE dueDate < ? AND status != ?${userId != null ? ' AND userId = ?' : ''}',
      userId != null 
          ? [now.millisecondsSinceEpoch, TaskStatus.completed.name, userId]
          : [now.millisecondsSinceEpoch, TaskStatus.completed.name],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, int>> getTaskStatistics({String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT 
        status,
        COUNT(*) as count
      FROM $_tableName
      ${userId != null ? 'WHERE userId = ?' : ''}
      GROUP BY status
    ''', userId != null ? [userId] : null);

    final Map<String, int> statistics = {};
    for (final row in result) {
      statistics[row['status'] as String] = row['count'] as int;
    }
    return statistics;
  }

  Future<List<Task>> getTasksWithPagination({
    int page = 0,
    int limit = 20,
    String? sortBy,
    bool ascending = true,
    String? userId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final offset = page * limit;
    final orderBy = sortBy != null 
        ? '$sortBy ${ascending ? 'ASC' : 'DESC'}'
        : 'createdAt DESC';
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: userId != null ? 'userId = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => Task.fromJson(map)).toList();
  }
}
