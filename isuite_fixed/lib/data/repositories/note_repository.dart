import 'package:sqflite/sqflite.dart';
import '../../domain/models/note.dart';
import '../database_helper.dart';

class NoteRepository {
  static const String _tableName = 'notes';

  static Future<List<Note>> getAllNotes({String? userId}) async {
    // Placeholder implementation
    return [];
  }

  static Future<void> createNote(Note note) async {
    // Placeholder implementation
  }

  Future<List<Note>> getAllNotesInstance({String? userId}) async {

  Future<Note?> getNoteById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Note.fromJson(maps.first);
    }
    return null;
  }

  Future<String> createNote(Note note) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(_tableName, note.toJson());
    return note.id;
  }

  Future<int> updateNote(Note note) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      _tableName,
      note.toJson(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Note>> getNotesByType(NoteType type, {String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'type = ?${userId != null ? ' AND userId = ?' : ''}',
      whereArgs: userId != null ? [type.name, userId] : [type.name],
      orderBy: 'updatedAt DESC',
    );
    return maps.map(Note.fromJson).toList();
  }

  Future<List<Note>> getNotesByCategory(NoteCategory category,
      {String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'category = ?${userId != null ? ' AND userId = ?' : ''}',
      whereArgs: userId != null ? [category.name, userId] : [category.name],
      orderBy: 'updatedAt DESC',
    );
    return maps.map(Note.fromJson).toList();
  }

  Future<List<Note>> getNotesByStatus(NoteStatus status,
      {String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'status = ?${userId != null ? ' AND userId = ?' : ''}',
      whereArgs: userId != null ? [status.name, userId] : [status.name],
      orderBy: 'updatedAt DESC',
    );
    return maps.map(Note.fromJson).toList();
  }

  Future<List<Note>> getNotesByPriority(NotePriority priority,
      {String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'priority = ?${userId != null ? ' AND userId = ?' : ''}',
      whereArgs: userId != null ? [priority.value, userId] : [priority.value],
      orderBy: 'updatedAt DESC',
    );
    return maps.map(Note.fromJson).toList();
  }

  Future<List<Note>> getFavoriteNotes({String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'isFavorite = ?${userId != null ? ' AND userId = ?' : ''}',
      whereArgs: userId != null ? [1, userId] : [1],
      orderBy: 'updatedAt DESC',
    );
    return maps.map(Note.fromJson).toList();
  }

  Future<List<Note>> getPinnedNotes({String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'isPinned = ?${userId != null ? ' AND userId = ?' : ''}',
      whereArgs: userId != null ? [1, userId] : [1],
      orderBy: 'updatedAt DESC',
    );
    return maps.map(Note.fromJson).toList();
  }

  Future<List<Note>> getArchivedNotes({String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'isArchived = ?${userId != null ? ' AND userId = ?' : ''}',
      whereArgs: userId != null ? [1, userId] : [1],
      orderBy: 'updatedAt DESC',
    );
    return maps.map(Note.fromJson).toList();
  }

  Future<List<Note>> searchNotes(String query, {String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where:
          '(title LIKE ? OR content LIKE ? OR tags LIKE ?)${userId != null ? ' AND userId = ?' : ''}',
      whereArgs: userId != null
          ? ['%$query%', '%$query%', '%$query%', userId]
          : ['%$query%', '%$query%', '%$query%'],
      orderBy: 'updatedAt DESC',
    );
    return maps.map(Note.fromJson).toList();
  }

  Future<List<Note>> getNotesDueToday({String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where:
          'dueDate >= ? AND dueDate < ?${userId != null ? ' AND userId = ?' : ''}',
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
      orderBy: 'dueDate ASC',
    );
    return maps.map(Note.fromJson).toList();
  }

  Future<List<Note>> getOverdueNotes({String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();

    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where:
          'dueDate < ? AND status != ? AND status != ?${userId != null ? ' AND userId = ?' : ''}',
      whereArgs: userId != null
          ? [now.millisecondsSinceEpoch, 'completed', 'archived', userId]
          : [now.millisecondsSinceEpoch, 'completed', 'archived'],
      orderBy: 'dueDate ASC',
    );
    return maps.map(Note.fromJson).toList();
  }

  Future<List<Note>> getRecentNotes({String? userId, int limit = 10}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: userId != null ? 'userId = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'updatedAt DESC',
      limit: limit,
    );
    return maps.map(Note.fromJson).toList();
  }

  Future<int> getNoteCount({String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName${userId != null ? ' WHERE userId = ?' : ''}',
      userId != null ? [userId] : null,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, int>> getNoteStatistics({String? userId}) async {
    final db = await DatabaseHelper.instance.database;

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as total FROM $_tableName${userId != null ? ' WHERE userId = ?' : ''}',
      userId != null ? [userId] : null,
    );

    final draftResult = await db.rawQuery(
      'SELECT COUNT(*) as draft FROM $_tableName${userId != null ? ' WHERE userId = ? AND status = ?' : ''}',
      userId != null ? [userId, 'draft'] : ['draft'],
    );

    final publishedResult = await db.rawQuery(
      'SELECT COUNT(*) as published FROM $_tableName${userId != null ? ' WHERE userId = ? AND status = ?' : ''}',
      userId != null ? [userId, 'published'] : ['published'],
    );

    final archivedResult = await db.rawQuery(
      'SELECT COUNT(*) as archived FROM $_tableName${userId != null ? ' WHERE userId = ? AND isArchived = ?' : ''}',
      userId != null ? [userId, 'archived'] : ['archived'],
    );

    final favoriteResult = await db.rawQuery(
      'SELECT COUNT(*) as favorite FROM $_tableName${userId != null ? ' WHERE userId = ? AND isFavorite = ?' : ''}',
      userId != null ? [userId, 'favorite'] : ['favorite'],
    );

    final pinnedResult = await db.rawQuery(
      'SELECT COUNT(*) as pinned FROM $_tableName${userId != null ? ' WHERE userId = ? AND isPinned = ?' : ''}',
      userId != null ? [userId, 'pinned'] : ['pinned'],
    );

    return {
      'total': Sqflite.firstIntValue(totalResult) ?? 0,
      'draft': Sqflite.firstIntValue(draftResult) ?? 0,
      'published': Sqflite.firstIntValue(publishedResult) ?? 0,
      'archived': Sqflite.firstIntValue(archivedResult) ?? 0,
      'favorite': Sqflite.firstIntValue(favoriteResult) ?? 0,
      'pinned': Sqflite.firstIntValue(pinnedResult) ?? 0,
    };
  }

  Future<void> deleteAllNotes({String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      _tableName,
      where: userId != null ? 'userId = ?' : null,
      whereArgs: userId != null ? [userId] : null,
    );
  }

  Future<void> toggleNoteFavorite(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      await updateNote(note.copyWith(isFavorite: !note.isFavorite));
    }
  }

  Future<void> toggleNotePin(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      await updateNote(note.copyWith(isPinned: !note.isPinned));
    }
  }

  Future<void> archiveNote(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      await updateNote(
          note.copyWith(isArchived: true, status: NoteStatus.archived));
    }
  }

  Future<void> unarchiveNote(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      await updateNote(
          note.copyWith(isArchived: false, status: NoteStatus.draft));
    }
  }

  Future<void> deleteNoteAttachment(
      String noteId, String attachmentPath) async {
    final note = await getNoteById(noteId);
    if (note != null) {
      final updatedAttachments = List<String>.from(note.attachments)
        ..remove(attachmentPath);
      await updateNote(note.copyWith(attachments: updatedAttachments));
    }
  }

  Future<void> addNoteAttachment(String noteId, String attachmentPath) async {
    final note = await getNoteById(noteId);
    if (note != null) {
      final updatedAttachments = List<String>.from(note.attachments)
        ..add(attachmentPath);
      await updateNote(note.copyWith(attachments: updatedAttachments));
    }
  }

  Future<void> updateNoteWordCount(String id, int wordCount) async {
    final note = await getNoteById(id);
    if (note != null) {
      await updateNote(note.copyWith(wordCount: wordCount));
    }
  }

  Future<void> updateNoteReadingTime(String id, int readingTime) async {
    final note = await getNoteById(id);
    if (note != null) {
      await updateNote(note.copyWith(readingTime: readingTime));
    }
  }

  Future<void> encryptNote(String id, String password) async {
    final note = await getNoteById(id);
    if (note != null) {
      await updateNote(note.copyWith(isEncrypted: true, password: password));
    }
  }

  Future<void> decryptNote(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      await updateNote(note.copyWith(isEncrypted: false));
    }
  }
}
