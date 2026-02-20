import 'package:sqflite/sqflite.dart';

import '../../domain/models/file.dart';
import '../core/database_helper.dart';

class FileRepository {
  static const String _tableName = 'files';
  static const String _columnId = 'id';
  static const String _columnName = 'name';
  static const String _columnPath = 'path';
  static const String _columnSize = 'size';
  static const String _columnType = 'type';
  static const String _columnStatus = 'status';
  static const String _columnCreatedAt = 'created_at';
  static const String _columnUpdatedAt = 'updated_at';
  static const String _columnUploadedAt = 'uploaded_at';
  static const String _columnMimeType = 'mime_type';
  static const String _columnThumbnail = 'thumbnail';
  static const String _columnMetadata = 'metadata';
  static const String _columnUserId = 'user_id';
  static const String _columnIsEncrypted = 'is_encrypted';
  static const String _columnPassword = 'password';
  static const String _columnTags = 'tags';
  static const String _columnDescription = 'description';
  static const String _columnDownloadCount = 'download_count';
  static const String _columnLastAccessed = 'last_accessed';

  static Future<List<FileModel>> getAllFiles() async {
    final db = await DatabaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName, orderBy: '$_columnUpdatedAt DESC');
    return List.generate(maps.length, (i) => FileModel.fromJson(maps[i]));
  }

  static Future<FileModel?> getFileById(String id) async {
    final db = await DatabaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: '$_columnId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return FileModel.fromJson(maps.first);
    }
    return null;
  }

  static Future<List<FileModel>> getFilesByType(FileType type) async {
    final db = await DatabaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: '$_columnType = ?',
      whereArgs: [type.name],
      orderBy: '$_columnUpdatedAt DESC',
    );
    return List.generate(maps.length, (i) => FileModel.fromJson(maps[i]));
  }

  static Future<List<FileModel>> getFilesByStatus(FileStatus status) async {
    final db = await DatabaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: '$_columnStatus = ?',
      whereArgs: [status.name],
      orderBy: '$_columnUpdatedAt DESC',
    );
    return List.generate(maps.length, (i) => FileModel.fromJson(maps[i]));
  }

  static Future<List<FileModel>> searchFiles(String query) async {
    final db = await DatabaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: '$_columnName LIKE ? OR $_columnDescription LIKE ? OR $_columnTags LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: '$_columnUpdatedAt DESC',
    );
    return List.generate(maps.length, (i) => FileModel.fromJson(maps[i]));
  }

  static Future<List<FileModel>> getRecentFiles({int limit = 10}) async {
    final db = await DatabaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: '$_columnUpdatedAt DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => FileModel.fromJson(maps[i]));
  }

  static Future<List<FileModel>> getFilesBySizeRange(int minSize, int maxSize) async {
    final db = await DatabaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: '$_columnSize >= ? AND $_columnSize <= ?',
      whereArgs: [minSize, maxSize],
      orderBy: '$_columnSize DESC',
    );
    return List.generate(maps.length, (i) => FileModel.fromJson(maps[i]));
  }

  static Future<int> getFileCount() async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
    return Sqflite.firstIntValue(result, 0) ?? 0;
  }

  static Future<Map<String, dynamic>> getFileStatistics() async {
    final db = await DatabaseHelper.database;
    final totalResult = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
    final totalFiles = Sqflite.firstIntValue(totalResult, 0) ?? 0;
    
    final sizeResult = await db.rawQuery('SELECT SUM($_columnSize) FROM $_tableName');
    final totalSize = Sqflite.firstIntValue(sizeResult, 0) ?? 0;
    
    final typeStats = await db.rawQuery('''
      SELECT $_columnType, COUNT(*) as count 
      FROM $_tableName 
      GROUP BY $_columnType
    ''');
    
    final var typeCounts = <FileType, int>{};
    for (final stat in typeStats) {
      final typeStr = stat[$_columnType] as String;
      final type = FileType.values.firstWhere((t) => t.name == typeStr);
      typeCounts[type] = stat['count'] as int;
    }
    
    return {
      'totalFiles': totalFiles,
      'totalSize': totalSize,
      'typeCounts': typeCounts.map((key, value) => MapEntry(key.name, value)),
    };
  }

  static Future<String> createFile(FileModel file) async {
    final db = await DatabaseHelper.database;
    await db.insert(_tableName, file.toJson());
    return file.id;
  }

  static Future<void> updateFile(FileModel file) async {
    final db = await DatabaseHelper.database;
    await db.update(
      _tableName,
      file.toJson(),
      where: '$_columnId = ?',
      whereArgs: [file.id],
    );
  }

  static Future<void> deleteFile(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete(
      _tableName,
      where: '$_columnId = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteAllFiles() async {
    final db = await DatabaseHelper.database;
    await db.delete(_tableName);
  }

  static Future<void> incrementDownloadCount(String id) async {
    final db = await DatabaseHelper.database;
    await db.rawUpdate(
      _tableName,
      '$_columnDownloadCount = $_columnDownloadCount + 1',
      where: '$_columnId = ?',
      whereArgs: [id],
    );
  }

  static Future<void> updateLastAccessed(String id) async {
    final db = await DatabaseHelper.database;
    await db.update(
      _tableName,
      {$_columnLastAccessed': DateTime.now().toIso8601String()},
      where: '$_columnId = ?',
      whereArgs: [id],
    );
  }

  static Future<void> toggleFileEncryption(String id, bool isEncrypted, {String? password}) async {
    final db = await DatabaseHelper.database;
    await db.update(
      _tableName,
      {
        _columnIsEncrypted: isEncrypted ? 1 : 0,
        if (password != null) _columnPassword: password,
      },
      where: '$_columnId = ?',
      whereArgs: [id],
    );
  }

  static Future<void> addFileTag(String id, String tag) async {
    final db = await DatabaseHelper.database;
    final file = await getFileById(id);
    if (file != null) {
      final updatedTags = List<String>.from(file.tags)..add(tag);
      final updatedFile = file.copyWith(tags: updatedTags);
      await updateFile(updatedFile);
    }
  }

  static Future<void> removeFileTag(String id, String tag) async {
    final db = await DatabaseHelper.database;
    final file = await getFileById(id);
    if (file != null) {
      final updatedTags = List<String>.from(file.tags)..remove(tag);
      final updatedFile = file.copyWith(tags: updatedTags);
      await updateFile(updatedFile);
    }
  }

  static Future<void> batchUpdateFiles(List<FileModel> files) async {
    final db = await DatabaseHelper.database;
    final batch = db.batch();
    
    for (final file in files) {
      batch.update(
        _tableName,
        file.toJson(),
        where: '$_columnId = ?',
        whereArgs: [file.id],
      );
    }
    
    await batch.commit(noResult: true);
  }

  static Future<void> batchDeleteFiles(List<String> ids) async {
    final db = await DatabaseHelper.database;
    final batch = db.batch();
    
    for (final id in ids) {
      batch.delete(
        _tableName,
        where: '$_columnId = ?',
        whereArgs: [id],
      );
    }
    
    await batch.commit(noResult: true);
  }
}
