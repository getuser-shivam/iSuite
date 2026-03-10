import 'package:flutter/material.dart';
import '../../core/cloud_sync_service.dart';
import '../../core/utils.dart';

class CloudSyncProvider extends ChangeNotifier {
  CloudSyncProvider() {
    // Initialize sync status from local storage if needed
  }
  final CloudSyncService _syncService = CloudSyncService();

  bool _isSyncing = false;
  String? _syncError;
  DateTime? _lastSyncTime;
  final Map<String, bool> _syncStatus = {
    'tasks': false,
    'reminders': false,
    'notes': false,
    'calendar': false,
    'files': false,
    'networks': false,
    'file_connections': false,
  };

  // Getters
  bool get isSyncing => _isSyncing;
  String? get syncError => _syncError;
  DateTime? get lastSyncTime => _lastSyncTime;
  Map<String, bool> get syncStatus => _syncStatus;

  bool get hasSyncError => _syncError != null;
  bool get isAllSynced => _syncStatus.values.every((synced) => synced);

  Future<void> syncAllData(
    String userId, {
    List<dynamic>? tasks,
    List<dynamic>? reminders,
    List<dynamic>? notes,
    List<dynamic>? calendarEvents,
    List<dynamic>? files,
    List<dynamic>? networks,
    List<dynamic>? fileConnections,
  }) async {
    if (_isSyncing) return;

    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      AppUtils.logInfo('CloudSyncProvider', 'Starting full cloud sync');

      await _syncService.syncAllData(
        userId,
        tasks: tasks?.cast(),
        reminders: reminders?.cast(),
        notes: notes?.cast(),
        calendarEvents: calendarEvents?.cast(),
        files: files?.cast(),
        networks: networks?.cast(),
        fileConnections: fileConnections?.cast(),
      );

      _lastSyncTime = DateTime.now();
      _updateSyncStatus(true);

      AppUtils.logInfo(
          'CloudSyncProvider', 'Cloud sync completed successfully');
    } catch (e) {
      _syncError = 'Sync failed: $e';
      AppUtils.logError('CloudSyncProvider', 'Cloud sync failed', e);
      _updateSyncStatus(false);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> syncTasks(String userId, List<dynamic> tasks) async {
    try {
      await _syncService.syncTasks(userId, tasks.cast());
      _syncStatus['tasks'] = true;
      notifyListeners();
    } catch (e) {
      _syncStatus['tasks'] = false;
      AppUtils.logError('CloudSyncProvider', 'Tasks sync failed', e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> syncReminders(String userId, List<dynamic> reminders) async {
    try {
      await _syncService.syncReminders(userId, reminders.cast());
      _syncStatus['reminders'] = true;
      notifyListeners();
    } catch (e) {
      _syncStatus['reminders'] = false;
      AppUtils.logError('CloudSyncProvider', 'Reminders sync failed', e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> syncNotes(String userId, List<dynamic> notes) async {
    try {
      await _syncService.syncNotes(userId, notes.cast());
      _syncStatus['notes'] = true;
      notifyListeners();
    } catch (e) {
      _syncStatus['notes'] = false;
      AppUtils.logError('CloudSyncProvider', 'Notes sync failed', e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> syncCalendarEvents(
      String userId, List<dynamic> calendarEvents) async {
    try {
      await _syncService.syncCalendarEvents(userId, calendarEvents.cast());
      _syncStatus['calendar'] = true;
      notifyListeners();
    } catch (e) {
      _syncStatus['calendar'] = false;
      AppUtils.logError('CloudSyncProvider', 'Calendar sync failed', e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> syncFiles(String userId, List<dynamic> files) async {
    try {
      await _syncService.syncFiles(userId, files.cast());
      _syncStatus['files'] = true;
      notifyListeners();
    } catch (e) {
      _syncStatus['files'] = false;
      AppUtils.logError('CloudSyncProvider', 'Files sync failed', e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> syncNetworks(String userId, List<dynamic> networks) async {
    try {
      await _syncService.syncNetworks(userId, networks.cast());
      _syncStatus['networks'] = true;
      notifyListeners();
    } catch (e) {
      _syncStatus['networks'] = false;
      AppUtils.logError('CloudSyncProvider', 'Networks sync failed', e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> syncFileConnections(
      String userId, List<dynamic> fileConnections) async {
    try {
      await _syncService.syncFileConnections(userId, fileConnections.cast());
      _syncStatus['file_connections'] = true;
      notifyListeners();
    } catch (e) {
      _syncStatus['file_connections'] = false;
      AppUtils.logError('CloudSyncProvider', 'File connections sync failed', e);
      notifyListeners();
      rethrow;
    }
  }

  Future<String?> uploadFile(
      String userId, String filePath, String fileName) async {
    try {
      return await _syncService.uploadFile(userId, filePath, fileName);
    } catch (e) {
      AppUtils.logError('CloudSyncProvider', 'File upload failed', e);
      rethrow;
    }
  }

  Future<bool> downloadFile(
      String userId, String remoteFileName, String localPath) async {
    try {
      return await _syncService.downloadFile(userId, remoteFileName, localPath);
    } catch (e) {
      AppUtils.logError('CloudSyncProvider', 'File download failed', e);
      rethrow;
    }
  }

  Future<bool> deleteFile(String userId, String fileName) async {
    try {
      return await _syncService.deleteFile(userId, fileName);
    } catch (e) {
      AppUtils.logError('CloudSyncProvider', 'File deletion failed', e);
      rethrow;
    }
  }

  void clearError() {
    _syncError = null;
    notifyListeners();
  }

  void _updateSyncStatus(bool status) {
    _syncStatus.updateAll((key, value) => status);
  }

  void resetSyncStatus() {
    _syncStatus.updateAll((key, value) => false);
    notifyListeners();
  }

  // Get sync status for a specific data type
  bool getSyncStatus(String dataType) => _syncStatus[dataType] ?? false;

  // Manual sync trigger
  Future<void> manualSync(String userId) async {
    await syncAllData(userId);
  }
}
