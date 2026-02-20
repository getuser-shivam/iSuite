import 'package:sqflite/sqflite.dart';
import '../../domain/models/reminder.dart';
import '../database_helper.dart';

class ReminderRepository {
  static Future<List<ReminderModel>> getAllReminders() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps =
        await db.query('reminders', orderBy: 'due_date ASC');
    return List.generate(maps.length, (i) => _fromMap(maps[i]));
  }

  static Future<ReminderModel?> getReminderById(String id) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return _fromMap(maps.first);
    }
    return null;
  }

  static Future<List<ReminderModel>> getActiveReminders() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminders',
      where: 'status = ?',
      whereArgs: [ReminderStatus.active.name],
      orderBy: 'due_date ASC',
    );
    return List.generate(maps.length, (i) => _fromMap(maps[i]));
  }

  static Future<List<ReminderModel>> getOverdueReminders() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminders',
      where: 'status = ? AND due_date < ?',
      whereArgs: [ReminderStatus.active.name, now],
      orderBy: 'due_date ASC',
    );
    return List.generate(maps.length, (i) => _fromMap(maps[i]));
  }

  static Future<List<ReminderModel>> getUpcomingReminders(
      {int hours = 24}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final future =
        DateTime.now().add(Duration(hours: hours)).millisecondsSinceEpoch;
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminders',
      where: 'status = ? AND due_date >= ? AND due_date <= ?',
      whereArgs: [ReminderStatus.active.name, now, future],
      orderBy: 'due_date ASC',
    );
    return List.generate(maps.length, (i) => _fromMap(maps[i]));
  }

  static Future<String> createReminder(ReminderModel reminder) async {
    final db = await DatabaseHelper().database;
    final id = reminder.id;
    await db.insert('reminders', _toMap(reminder));
    return id;
  }

  static Future<void> updateReminder(ReminderModel reminder) async {
    final db = await DatabaseHelper().database;
    await db.update(
      'reminders',
      _toMap(reminder),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  static Future<void> deleteReminder(String id) async {
    final db = await DatabaseHelper().database;
    await db.delete(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> markCompleted(String id) async {
    final db = await DatabaseHelper().database;
    await db.update(
      'reminders',
      {
        'status': ReminderStatus.completed.name,
        'completed_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> snoozeReminder(String id, Duration duration) async {
    final snoozeUntil = DateTime.now().add(duration).millisecondsSinceEpoch;
    final db = await DatabaseHelper().database;
    await db.update(
      'reminders',
      {
        'status': ReminderStatus.snoozed.name,
        'snooze_until': snoozeUntil,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> dismissReminder(String id) async {
    final db = await DatabaseHelper().database;
    await db.update(
      'reminders',
      {
        'status': ReminderStatus.dismissed.name,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> getReminderCount() async {
    final db = await DatabaseHelper().database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM reminders');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<Map<String, int>> getReminderStats() async {
    final db = await DatabaseHelper().database;
    final totalResult = await db.rawQuery('SELECT COUNT(*) FROM reminders');
    final total = Sqflite.firstIntValue(totalResult) ?? 0;

    final activeResult = await db.rawQuery(
        'SELECT COUNT(*) FROM reminders WHERE status = ?',
        [ReminderStatus.active.name]);
    final active = Sqflite.firstIntValue(activeResult) ?? 0;

    final completedResult = await db.rawQuery(
        'SELECT COUNT(*) FROM reminders WHERE status = ?',
        [ReminderStatus.completed.name]);
    final completed = Sqflite.firstIntValue(completedResult) ?? 0;

    final overdueResult = await db.rawQuery(
        'SELECT COUNT(*) FROM reminders WHERE status = ? AND due_date < ?',
        [ReminderStatus.active.name, DateTime.now().millisecondsSinceEpoch]);
    final overdue = Sqflite.firstIntValue(overdueResult) ?? 0;

    return {
      'total': total,
      'active': active,
      'completed': completed,
      'overdue': overdue,
    };
  }

  static Map<String, dynamic> _toMap(ReminderModel reminder) => {
        'id': reminder.id,
        'title': reminder.title,
        'description': reminder.description,
        'due_date': reminder.dueDate.millisecondsSinceEpoch,
        'repeat': reminder.repeat.name,
        'priority': reminder.priority.name,
        'status': reminder.status.name,
        'created_at': reminder.createdAt.millisecondsSinceEpoch,
        'updated_at': reminder.updatedAt.millisecondsSinceEpoch,
        'snooze_until': reminder.snoozeUntil?.millisecondsSinceEpoch,
        'completed_at': reminder.completedAt?.millisecondsSinceEpoch,
        'tags': reminder.tags.join(','),
        'user_id': reminder.userId,
      };

  static ReminderModel _fromMap(Map<String, dynamic> map) => ReminderModel(
        id: map['id'],
        title: map['title'],
        description: map['description'],
        dueDate: DateTime.fromMillisecondsSinceEpoch(map['due_date']),
        repeat:
            ReminderRepeat.values.firstWhere((r) => r.name == map['repeat']),
        priority: ReminderPriority.values
            .firstWhere((p) => p.name == map['priority']),
        status:
            ReminderStatus.values.firstWhere((s) => s.name == map['status']),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
        snoozeUntil: map['snooze_until'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['snooze_until'])
            : null,
        completedAt: map['completed_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'])
            : null,
        tags: map['tags'] != null
            ? (map['tags'] as String)
                .split(',')
                .where((tag) => tag.isNotEmpty)
                .toList()
            : [],
        userId: map['user_id'],
      );
}
