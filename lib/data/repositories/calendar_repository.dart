import 'package:sqflite/sqflite.dart';
import '../../domain/models/calendar_event.dart';
import '../database_helper.dart';

class CalendarRepository {
  static const String _tableName = 'calendar_events';

  Future<List<CalendarEvent>> getAllEvents({String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: userId != null ? 'userId = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'startTime ASC',
    );
    return maps.map(CalendarEvent.fromJson).toList();
  }

  Future<CalendarEvent?> getEventById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return CalendarEvent.fromJson(maps.first);
    }
    return null;
  }

  Future<String> createEvent(CalendarEvent event) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(_tableName, event.toJson());
    return event.id;
  }

  Future<int> updateEvent(CalendarEvent event) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      _tableName,
      event.toJson(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<CalendarEvent>> getEventsByDate(DateTime date,
      {String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where:
          'startTime >= ? AND startTime < ?${userId != null ? ' AND userId = ?' : ''}',
      whereArgs: userId != null
          ? [
              startOfDay.millisecondsSinceEpoch,
              endOfDay.millisecondsSinceEpoch,
              userId
            ]
          : [
              startOfDay.millisecondsSinceEpoch,
              endOfDay.millisecondsSinceEpoch
            ],
      orderBy: 'startTime ASC',
    );
    return maps.map(CalendarEvent.fromJson).toList();
  }

  Future<List<CalendarEvent>> getEventsByDateRange(DateTime start, DateTime end,
      {String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where:
          'startTime >= ? AND startTime <= ?${userId != null ? ' AND userId = ?' : ''}',
      whereArgs: userId != null
          ? [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch, userId]
          : [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'startTime ASC',
    );
    return maps.map(CalendarEvent.fromJson).toList();
  }

  Future<List<CalendarEvent>> getEventsByType(EventType type,
      {String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'type = ?${userId != null ? ' AND userId = ?' : ''}',
      whereArgs: userId != null ? [type.name, userId] : [type.name],
      orderBy: 'startTime ASC',
    );
    return maps.map(CalendarEvent.fromJson).toList();
  }

  Future<List<CalendarEvent>> searchEvents(String query,
      {String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where:
          '(title LIKE ? OR description LIKE ? OR location LIKE ?)${userId != null ? ' AND userId = ?' : ''}',
      whereArgs: userId != null
          ? ['%$query%', '%$query%', '%$query%', userId]
          : ['%$query%', '%$query%', '%$query%'],
      orderBy: 'startTime ASC',
    );
    return maps.map(CalendarEvent.fromJson).toList();
  }

  Future<int> getEventCount({String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName${userId != null ? ' WHERE userId = ?' : ''}',
      userId != null ? [userId] : null,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<CalendarEvent>> getUpcomingEvents(
      {String? userId, int limit = 10}) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where:
          'startTime > ? AND status != ?${userId != null ? ' AND userId = ?' : ''}',
      whereArgs: userId != null
          ? [now.millisecondsSinceEpoch, 'cancelled', userId]
          : [now.millisecondsSinceEpoch, 'cancelled'],
      orderBy: 'startTime ASC',
      limit: limit,
    );
    return maps.map(CalendarEvent.fromJson).toList();
  }
}
