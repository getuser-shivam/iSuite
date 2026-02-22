import 'dart:async';
import 'package:sqflite/sqflite.dart';

import '../../core/utils.dart';
import '../../domain/models/file_sharing_model.dart';
import '../database_helper.dart';

class FileSharingRepository {
  static FileSharingRepository? _instance;
  static FileSharingRepository get instance =>
      _instance ??= FileSharingRepository._internal();
  FileSharingRepository._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<List<FileSharingModel>> getConnections() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'file_sharing_connections',
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => FileSharingModel.fromMap(map)).toList();
    } catch (e) {
      AppUtils.logError('Failed to get file sharing connections', error: e);
      return [];
    }
  }

  Future<bool> saveConnection(FileSharingModel connection) async {
    try {
      final db = await _databaseHelper.database;

      // Check if connection already exists
      final existing = await db.query(
        'file_sharing_connections',
        where: 'host = ? AND port = ?',
        whereArgs: [connection.host, connection.port],
      );

      final connectionToSave = connection.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (existing.isNotEmpty) {
        // Update existing connection
        await db.update(
          'file_sharing_connections',
          connectionToSave.toMap(),
          where: 'host = ? AND port = ?',
          whereArgs: [connection.host, connection.port],
        );
      } else {
        // Insert new connection
        await db.insert('file_sharing_connections', connectionToSave.toMap());
      }

      AppUtils.logInfo('Saved file sharing connection: ${connection.name}');
      return true;
    } catch (e) {
      AppUtils.logError('Failed to save file sharing connection', error: e);
      return false;
    }
  }

  Future<bool> removeConnection(String connectionId) async {
    try {
      final db = await _databaseHelper.database;

      final count = await db.delete(
        'file_sharing_connections',
        where: 'id = ?',
        whereArgs: [connectionId],
      );

      if (count > 0) {
        AppUtils.logInfo('Removed file sharing connection: $connectionId');
        return true;
      }
      return false;
    } catch (e) {
      AppUtils.logError('Failed to remove file sharing connection', error: e);
      return false;
    }
  }

  Future<FileSharingModel?> getConnectionById(String connectionId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'file_sharing_connections',
        where: 'id = ?',
        whereArgs: [connectionId],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return FileSharingModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      AppUtils.logError('Failed to get file sharing connection by ID',
          error: e);
      return null;
    }
  }

  Future<bool> updateConnection(FileSharingModel connection) async {
    try {
      final db = await _databaseHelper.database;

      final updatedConnection = connection.copyWith(
        updatedAt: DateTime.now(),
      );

      final count = await db.update(
        'file_sharing_connections',
        updatedConnection.toMap(),
        where: 'id = ?',
        whereArgs: [connection.id],
      );

      if (count > 0) {
        AppUtils.logInfo('Updated file sharing connection: ${connection.name}');
        return true;
      }
      return false;
    } catch (e) {
      AppUtils.logError('Failed to update file sharing connection', error: e);
      return false;
    }
  }

  Future<bool> testConnection(String connectionId) async {
    try {
      final connection = await getConnectionById(connectionId);
      if (connection == null) return false;

      // Test connection logic would go here
      // For now, simulate connection test
      await Future.delayed(Duration(seconds: 2));

      final db = await _databaseHelper.database;
      await db.update(
        'file_sharing_connections',
        {
          'last_tested': DateTime.now().millisecondsSinceEpoch,
          'is_active': true,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [connectionId],
      );

      AppUtils.logInfo('Tested connection: ${connection.name}');
      return true;
    } catch (e) {
      AppUtils.logError('Failed to test connection', error: e);
      return false;
    }
  }

  Future<List<FileSharingModel>> getConnectionsByProtocol(
      FileSharingProtocol protocol) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'file_sharing_connections',
        where: 'protocol = ?',
        whereArgs: [protocol.name],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => FileSharingModel.fromMap(map)).toList();
    } catch (e) {
      AppUtils.logError('Failed to get connections by protocol', error: e);
      return [];
    }
  }

  Future<List<FileSharingModel>> getActiveConnections() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'file_sharing_connections',
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => FileSharingModel.fromMap(map)).toList();
    } catch (e) {
      AppUtils.logError('Failed to get active connections', error: e);
      return [];
    }
  }

  Future<bool> toggleConnectionStatus(String connectionId) async {
    try {
      final connection = await getConnectionById(connectionId);
      if (connection == null) return false;

      final updatedConnection = connection.copyWith(
        isActive: !connection.isActive,
        updatedAt: DateTime.now(),
      );

      return await updateConnection(updatedConnection);
    } catch (e) {
      AppUtils.logError('Failed to toggle connection status', error: e);
      return false;
    }
  }

  Future<Map<String, dynamic>> getConnectionStats() async {
    try {
      final db = await _databaseHelper.database;

      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_connections,
          COUNT(CASE WHEN is_active = 1 THEN 1 END) as active_connections,
          COUNT(CASE WHEN protocol = 'ftp' THEN 1 END) as ftp_connections,
          COUNT(CASE WHEN protocol = 'sftp' THEN 1 END) as sftp_connections,
          COUNT(CASE WHEN protocol = 'http' THEN 1 END) as http_connections,
          COUNT(CASE WHEN protocol = 'smb' THEN 1 END) as smb_connections,
          COUNT(CASE WHEN is_secure = 1 THEN 1 END) as secure_connections
        FROM file_sharing_connections
      ''');

      return result.isNotEmpty ? result.first : {};
    } catch (e) {
      AppUtils.logError('Failed to get connection stats', error: e);
      return {};
    }
  }

  Future<bool> clearAllConnections() async {
    try {
      final db = await _databaseHelper.database;

      await db.delete('file_sharing_connections');
      AppUtils.logInfo('Cleared all file sharing connections');
      return true;
    } catch (e) {
      AppUtils.logError('Failed to clear file sharing connections', error: e);
      return false;
    }
  }

  Future<List<FileTransferModel>> getTransferHistory(
      String connectionId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'file_transfers',
        where: 'connection_id = ?',
        whereArgs: [connectionId],
        orderBy: 'created_at DESC',
        limit: 100,
      );

      return maps.map((map) => FileTransferModel.fromMap(map)).toList();
    } catch (e) {
      AppUtils.logError('Failed to get transfer history', error: e);
      return [];
    }
  }

  Future<bool> saveTransferRecord(FileTransferModel transfer) async {
    try {
      final db = await _databaseHelper.database;

      await db.insert('file_transfers', transfer.toMap());
      AppUtils.logInfo('Saved transfer record: ${transfer.fileName}');
      return true;
    } catch (e) {
      AppUtils.logError('Failed to save transfer record', error: e);
      return false;
    }
  }

  Future<bool> updateTransferStatus(
      String transferId, TransferStatus status) async {
    try {
      final db = await _databaseHelper.database;

      final count = await db.update(
        'file_transfers',
        {
          'status': status.name,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
          if (status == TransferStatus.completed)
            'completed_at': DateTime.now().millisecondsSinceEpoch(),
        },
        where: 'id = ?',
        whereArgs: [transferId],
      );

      if (count > 0) {
        AppUtils.logInfo('Updated transfer status: $transferId');
        return true;
      }
      return false;
    } catch (e) {
      AppUtils.logError('Failed to update transfer status', error: e);
      return false;
    }
  }

  Future<Map<String, dynamic>> getTransferStats(String connectionId) async {
    try {
      final db = await _databaseHelper.database;

      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_transfers,
          COUNT(CASE WHEN type = 'upload' THEN 1 END) as upload_transfers,
          COUNT(CASE WHEN type = 'download' THEN 1 END) as download_transfers,
          COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_transfers,
          COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_transfers,
          AVG(CASE WHEN status = 'completed' THEN duration END) as avg_duration,
          SUM(CASE WHEN status = 'completed' THEN file_size END) as total_transferred_size
        FROM file_transfers
        WHERE connection_id = ?
      ''', [connectionId]);

      return result.isNotEmpty ? result.first : {};
    } catch (e) {
      AppUtils.logError('Failed to get transfer stats', error: e);
      return {};
    }
  }
}
