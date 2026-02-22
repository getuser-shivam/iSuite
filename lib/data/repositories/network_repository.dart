import 'dart:async';
import 'package:sqflite/sqflite.dart';

import '../../core/utils.dart';
import '../../domain/models/network_model.dart';
import '../database_helper.dart';

class NetworkRepository {
  static NetworkRepository? _instance;
  static NetworkRepository get instance =>
      _instance ??= NetworkRepository._internal();
  NetworkRepository._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<List<NetworkModel>> getSavedNetworks() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'saved_networks',
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => NetworkModel.fromMap(map)).toList();
    } catch (e) {
      AppUtils.logError('Failed to get saved networks', error: e);
      return [];
    }
  }

  Future<bool> saveNetwork(NetworkModel network) async {
    try {
      final db = await _databaseHelper.database;

      // Check if network already exists
      final existing = await db.query(
        'saved_networks',
        where: 'ssid = ?',
        whereArgs: [network.ssid],
      );

      final networkToSave = network.copyWith(
        savedAt: DateTime.now(),
        isSaved: true,
      );

      if (existing.isNotEmpty) {
        // Update existing network
        await db.update(
          'saved_networks',
          networkToSave.toMap(),
          where: 'ssid = ?',
          whereArgs: [network.ssid],
        );
      } else {
        // Insert new network
        await db.insert('saved_networks', networkToSave.toMap());
      }

      AppUtils.logInfo('Saved network: ${network.ssid}');
      return true;
    } catch (e) {
      AppUtils.logError('Failed to save network', error: e);
      return false;
    }
  }

  Future<bool> removeSavedNetwork(String ssid) async {
    try {
      final db = await _databaseHelper.database;

      final count = await db.delete(
        'saved_networks',
        where: 'ssid = ?',
        whereArgs: [ssid],
      );

      if (count > 0) {
        AppUtils.logInfo('Removed saved network: $ssid');
        return true;
      }
      return false;
    } catch (e) {
      AppUtils.logError('Failed to remove saved network', error: e);
      return false;
    }
  }

  Future<bool> updateNetworkPassword(String ssid, String password) async {
    try {
      final db = await _databaseHelper.database;

      final count = await db.update(
        'saved_networks',
        {
          'password': password,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'ssid = ?',
        whereArgs: [ssid],
      );

      if (count > 0) {
        AppUtils.logInfo('Updated network password: $ssid');
        return true;
      }
      return false;
    } catch (e) {
      AppUtils.logError('Failed to update network password', error: e);
      return false;
    }
  }

  Future<bool> isNetworkSaved(String ssid) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.query(
        'saved_networks',
        where: 'ssid = ?',
        whereArgs: [ssid],
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      AppUtils.logError('Failed to check if network is saved', error: e);
      return false;
    }
  }

  Future<NetworkModel?> getSavedNetwork(String ssid) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'saved_networks',
        where: 'ssid = ?',
        whereArgs: [ssid],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return NetworkModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      AppUtils.logError('Failed to get saved network', error: e);
      return null;
    }
  }

  Future<List<NetworkModel>> getNetworksBySecurityType(
      SecurityType securityType) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'saved_networks',
        where: 'security_type = ?',
        whereArgs: [securityType.name],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => NetworkModel.fromMap(map)).toList();
    } catch (e) {
      AppUtils.logError('Failed to get networks by security type', error: e);
      return [];
    }
  }

  Future<Map<String, dynamic>> getNetworkStats() async {
    try {
      final db = await _databaseHelper.database;

      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_networks,
          COUNT(CASE WHEN security_type = 'open' THEN 1 END) as open_networks,
          COUNT(CASE WHEN security_type = 'wep' THEN 1 END) as wep_networks,
          COUNT(CASE WHEN security_type = 'wpa' THEN 1 END) as wpa_networks,
          COUNT(CASE WHEN security_type = 'wpa2' THEN 1 END) as wpa2_networks,
          COUNT(CASE WHEN security_type = 'wpa3' THEN 1 END) as wpa3_networks,
          AVG(signal_strength) as avg_signal_strength
        FROM saved_networks
      ''');

      return result.isNotEmpty ? result.first : {};
    } catch (e) {
      AppUtils.logError('Failed to get network stats', error: e);
      return {};
    }
  }

  Future<bool> clearAllSavedNetworks() async {
    try {
      final db = await _databaseHelper.database;

      await db.delete('saved_networks');
      AppUtils.logInfo('Cleared all saved networks');
      return true;
    } catch (e) {
      AppUtils.logError('Failed to clear saved networks', error: e);
      return false;
    }
  }

  Future<List<NetworkModel>> searchNetworks(String query) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'saved_networks',
        where: 'ssid LIKE ? OR bssid LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => NetworkModel.fromMap(map)).toList();
    } catch (e) {
      AppUtils.logError('Failed to search networks', error: e);
      return [];
    }
  }

  Future<bool> updateNetworkPriority(String ssid, int priority) async {
    try {
      final db = await _databaseHelper.database;

      final count = await db.update(
        'saved_networks',
        {
          'priority': priority,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'ssid = ?',
        whereArgs: [ssid],
      );

      if (count > 0) {
        AppUtils.logInfo('Updated network priority: $ssid');
        return true;
      }
      return false;
    } catch (e) {
      AppUtils.logError('Failed to update network priority', error: e);
      return false;
    }
  }

  Future<List<NetworkModel>> getNetworksByPriority(int minPriority) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'saved_networks',
        where: 'priority >= ?',
        whereArgs: [minPriority],
        orderBy: 'priority DESC, created_at DESC',
      );

      return maps.map((map) => NetworkModel.fromMap(map)).toList();
    } catch (e) {
      AppUtils.logError('Failed to get networks by priority', error: e);
      return [];
    }
  }
}
