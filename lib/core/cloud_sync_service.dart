import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../domain/models/task.dart';
import '../domain/models/reminder.dart';
import '../domain/models/note.dart';
import '../domain/models/calendar_event.dart';
import '../domain/models/file.dart';
import '../domain/models/network_model.dart';
import '../domain/models/file_sharing_model.dart';
import '../core/utils.dart';

class CloudSyncService {
  final SupabaseClient _client = SupabaseClientConfig.client;

  // Sync metadata to track last sync times and versions
  Future<Map<String, dynamic>> getSyncMetadata(String userId) async {
    try {
      final response = await _client
          .from(SupabaseClientConfig.syncMetadataTable)
          .select()
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      // Return default metadata if not found
      return {
        'user_id': userId,
        'last_sync_tasks': null,
        'last_sync_reminders': null,
        'last_sync_notes': null,
        'last_sync_calendar': null,
        'last_sync_files': null,
        'last_sync_networks': null,
        'last_sync_file_connections': null,
        'version': 1,
      };
    }
  }

  Future<void> updateSyncMetadata(String userId, Map<String, dynamic> metadata) async {
    try {
      await _client
          .from(SupabaseClientConfig.syncMetadataTable)
          .upsert({
            'user_id': userId,
            ...metadata,
          });
    } catch (e) {
      AppUtils.logError('CloudSyncService', 'Failed to update sync metadata', e);
    }
  }

  // Tasks sync
  Future<void> syncTasks(String userId, List<TaskModel> localTasks) async {
    try {
      AppUtils.logInfo('CloudSyncService', 'Starting tasks sync for user: $userId');

      // Get last sync time
      final metadata = await getSyncMetadata(userId);
      final lastSync = metadata['last_sync_tasks'];

      // Upload local changes to cloud
      final localChanges = localTasks.where((task) {
        return lastSync == null || task.updatedAt.isAfter(DateTime.parse(lastSync));
      }).toList();

      if (localChanges.isNotEmpty) {
        final tasksData = localChanges.map((task) => {
          'id': task.id,
          'user_id': userId,
          'title': task.title,
          'description': task.description,
          'is_completed': task.isCompleted,
          'priority': task.priority.name,
          'due_date': task.dueDate?.toIso8601String(),
          'created_at': task.createdAt.toIso8601String(),
          'updated_at': task.updatedAt.toIso8601String(),
          'category': task.category,
          'tags': jsonEncode(task.tags),
          'metadata': jsonEncode(task.metadata),
        }).toList();

        await _client.from(SupabaseClientConfig.tasksTable).upsert(tasksData);
        AppUtils.logInfo('CloudSyncService', 'Uploaded ${localChanges.length} task changes');
      }

      // Download remote changes
      final query = _client.from(SupabaseClientConfig.tasksTable).select();
      if (lastSync != null) {
        query.gt('updated_at', lastSync);
      }

      final remoteTasks = await query.eq('user_id', userId);
      AppUtils.logInfo('CloudSyncService', 'Downloaded ${remoteTasks.length} remote task changes');

      // Update local tasks (this would be handled by the repository/provider)
      // For now, just log
      if (remoteTasks.isNotEmpty) {
        AppUtils.logInfo('CloudSyncService', 'Remote tasks to sync: ${remoteTasks.length}');
      }

      // Update sync metadata
      await updateSyncMetadata(userId, {'last_sync_tasks': DateTime.now().toIso8601String()});

      AppUtils.logInfo('CloudSyncService', 'Tasks sync completed successfully');
    } catch (e) {
      AppUtils.logError('CloudSyncService', 'Tasks sync failed', e);
      rethrow;
    }
  }

  // Reminders sync
  Future<void> syncReminders(String userId, List<ReminderModel> localReminders) async {
    try {
      AppUtils.logInfo('CloudSyncService', 'Starting reminders sync for user: $userId');

      final metadata = await getSyncMetadata(userId);
      final lastSync = metadata['last_sync_reminders'];

      // Upload local changes
      final localChanges = localReminders.where((reminder) {
        return lastSync == null || reminder.updatedAt.isAfter(DateTime.parse(lastSync));
      }).toList();

      if (localChanges.isNotEmpty) {
        final remindersData = localChanges.map((reminder) => {
          'id': reminder.id,
          'user_id': userId,
          'title': reminder.title,
          'description': reminder.description,
          'due_date': reminder.dueDate.toIso8601String(),
          'priority': reminder.priority.name,
          'is_recurring': reminder.isRecurring,
          'recurrence_pattern': reminder.recurrencePattern?.name,
          'is_completed': reminder.isCompleted,
          'created_at': reminder.createdAt.toIso8601String(),
          'updated_at': reminder.updatedAt.toIso8601String(),
          'category': reminder.category,
          'tags': jsonEncode(reminder.tags),
          'metadata': jsonEncode(reminder.metadata),
        }).toList();

        await _client.from(SupabaseClientConfig.remindersTable).upsert(remindersData);
        AppUtils.logInfo('CloudSyncService', 'Uploaded ${localChanges.length} reminder changes');
      }

      // Download remote changes
      final query = _client.from(SupabaseClientConfig.remindersTable).select();
      if (lastSync != null) {
        query.gt('updated_at', lastSync);
      }

      final remoteReminders = await query.eq('user_id', userId);
      AppUtils.logInfo('CloudSyncService', 'Downloaded ${remoteReminders.length} remote reminder changes');

      // Update sync metadata
      await updateSyncMetadata(userId, {'last_sync_reminders': DateTime.now().toIso8601String()});

      AppUtils.logInfo('CloudSyncService', 'Reminders sync completed successfully');
    } catch (e) {
      AppUtils.logError('CloudSyncService', 'Reminders sync failed', e);
      rethrow;
    }
  }

  // Notes sync
  Future<void> syncNotes(String userId, List<NoteModel> localNotes) async {
    try {
      AppUtils.logInfo('CloudSyncService', 'Starting notes sync for user: $userId');

      final metadata = await getSyncMetadata(userId);
      final lastSync = metadata['last_sync_notes'];

      // Upload local changes
      final localChanges = localNotes.where((note) {
        return lastSync == null || note.updatedAt.isAfter(DateTime.parse(lastSync));
      }).toList();

      if (localChanges.isNotEmpty) {
        final notesData = localChanges.map((note) => {
          'id': note.id,
          'user_id': userId,
          'title': note.title,
          'content': note.content,
          'is_favorite': note.isFavorite,
          'category': note.category,
          'tags': jsonEncode(note.tags),
          'created_at': note.createdAt.toIso8601String(),
          'updated_at': note.updatedAt.toIso8601String(),
          'metadata': jsonEncode(note.metadata),
        }).toList();

        await _client.from(SupabaseClientConfig.notesTable).upsert(notesData);
        AppUtils.logInfo('CloudSyncService', 'Uploaded ${localChanges.length} note changes');
      }

      // Download remote changes
      final query = _client.from(SupabaseClientConfig.notesTable).select();
      if (lastSync != null) {
        query.gt('updated_at', lastSync);
      }

      final remoteNotes = await query.eq('user_id', userId);
      AppUtils.logInfo('CloudSyncService', 'Downloaded ${remoteNotes.length} remote note changes');

      // Update sync metadata
      await updateSyncMetadata(userId, {'last_sync_notes': DateTime.now().toIso8601String()});

      AppUtils.logInfo('CloudSyncService', 'Notes sync completed successfully');
    } catch (e) {
      AppUtils.logError('CloudSyncService', 'Notes sync failed', e);
      rethrow;
    }
  }

  // Calendar events sync
  Future<void> syncCalendarEvents(String userId, List<CalendarEventModel> localEvents) async {
    try {
      AppUtils.logInfo('CloudSyncService', 'Starting calendar events sync for user: $userId');

      final metadata = await getSyncMetadata(userId);
      final lastSync = metadata['last_sync_calendar'];

      // Upload local changes
      final localChanges = localEvents.where((event) {
        return lastSync == null || event.updatedAt.isAfter(DateTime.parse(lastSync));
      }).toList();

      if (localChanges.isNotEmpty) {
        final eventsData = localChanges.map((event) => {
          'id': event.id,
          'user_id': userId,
          'title': event.title,
          'description': event.description,
          'start_time': event.startTime.toIso8601String(),
          'end_time': event.endTime.toIso8601String(),
          'is_all_day': event.isAllDay,
          'location': event.location,
          'category': event.category,
          'tags': jsonEncode(event.tags),
          'recurrence_rule': event.recurrenceRule,
          'reminder_minutes': event.reminderMinutes,
          'created_at': event.createdAt.toIso8601String(),
          'updated_at': event.updatedAt.toIso8601String(),
          'metadata': jsonEncode(event.metadata),
        }).toList();

        await _client.from(SupabaseClientConfig.calendarEventsTable).upsert(eventsData);
        AppUtils.logInfo('CloudSyncService', 'Uploaded ${localChanges.length} calendar event changes');
      }

      // Download remote changes
      final query = _client.from(SupabaseClientConfig.calendarEventsTable).select();
      if (lastSync != null) {
        query.gt('updated_at', lastSync);
      }

      final remoteEvents = await query.eq('user_id', userId);
      AppUtils.logInfo('CloudSyncService', 'Downloaded ${remoteEvents.length} remote calendar event changes');

      // Update sync metadata
      await updateSyncMetadata(userId, {'last_sync_calendar': DateTime.now().toIso8601String()});

      AppUtils.logInfo('CloudSyncService', 'Calendar events sync completed successfully');
    } catch (e) {
      AppUtils.logError('CloudSyncService', 'Calendar events sync failed', e);
      rethrow;
    }
  }

  // File metadata sync
  Future<void> syncFiles(String userId, List<FileModel> localFiles) async {
    try {
      AppUtils.logInfo('CloudSyncService', 'Starting files sync for user: $userId');

      final metadata = await getSyncMetadata(userId);
      final lastSync = metadata['last_sync_files'];

      // Upload local changes
      final localChanges = localFiles.where((file) {
        return lastSync == null || file.updatedAt.isAfter(DateTime.parse(lastSync));
      }).toList();

      if (localChanges.isNotEmpty) {
        final filesData = localChanges.map((file) => {
          'id': file.id,
          'user_id': userId,
          'name': file.name,
          'path': file.path,
          'size': file.size,
          'mime_type': file.mimeType,
          'category': file.category,
          'tags': jsonEncode(file.tags),
          'is_favorite': file.isFavorite,
          'cloud_url': file.cloudUrl,
          'local_path': file.localPath,
          'sync_status': file.syncStatus.name,
          'created_at': file.createdAt.toIso8601String(),
          'updated_at': file.updatedAt.toIso8601String(),
          'metadata': jsonEncode(file.metadata),
        }).toList();

        await _client.from(SupabaseClientConfig.filesTable).upsert(filesData);
        AppUtils.logInfo('CloudSyncService', 'Uploaded ${localChanges.length} file metadata changes');
      }

      // Download remote changes
      final query = _client.from(SupabaseClientConfig.filesTable).select();
      if (lastSync != null) {
        query.gt('updated_at', lastSync);
      }

      final remoteFiles = await query.eq('user_id', userId);
      AppUtils.logInfo('CloudSyncService', 'Downloaded ${remoteFiles.length} remote file metadata changes');

      // Update sync metadata
      await updateSyncMetadata(userId, {'last_sync_files': DateTime.now().toIso8601String()});

      AppUtils.logInfo('CloudSyncService', 'Files sync completed successfully');
    } catch (e) {
      AppUtils.logError('CloudSyncService', 'Files sync failed', e);
      rethrow;
    }
  }

  // Networks sync
  Future<void> syncNetworks(String userId, List<NetworkModel> localNetworks) async {
    try {
      AppUtils.logInfo('CloudSyncService', 'Starting networks sync for user: $userId');

      final metadata = await getSyncMetadata(userId);
      final lastSync = metadata['last_sync_networks'];

      // Upload local changes
      final localChanges = localNetworks.where((network) {
        return lastSync == null || (network.lastConnected != null && network.lastConnected!.isAfter(DateTime.parse(lastSync)));
      }).toList();

      if (localChanges.isNotEmpty) {
        final networksData = localChanges.map((network) => {
          'id': network.id,
          'user_id': userId,
          'ssid': network.ssid,
          'type': network.type.name,
          'security_type': network.securityType.name,
          'ip_address': network.ipAddress,
          'gateway': network.gateway,
          'subnet': network.subnet,
          'dns': network.dns,
          'last_connected': network.lastConnected?.toIso8601String(),
          'is_saved': network.isSaved,
          'metadata': jsonEncode(network.metadata),
        }).toList();

        await _client.from(SupabaseClientConfig.networksTable).upsert(networksData);
        AppUtils.logInfo('CloudSyncService', 'Uploaded ${localChanges.length} network changes');
      }

      // Download remote changes
      final query = _client.from(SupabaseClientConfig.networksTable).select();
      if (lastSync != null) {
        query.gt('last_connected', lastSync);
      }

      final remoteNetworks = await query.eq('user_id', userId);
      AppUtils.logInfo('CloudSyncService', 'Downloaded ${remoteNetworks.length} remote network changes');

      // Update sync metadata
      await updateSyncMetadata(userId, {'last_sync_networks': DateTime.now().toIso8601String()});

      AppUtils.logInfo('CloudSyncService', 'Networks sync completed successfully');
    } catch (e) {
      AppUtils.logError('CloudSyncService', 'Networks sync failed', e);
      rethrow;
    }
  }

  // File connections sync
  Future<void> syncFileConnections(String userId, List<FileSharingModel> localConnections) async {
    try {
      AppUtils.logInfo('CloudSyncService', 'Starting file connections sync for user: $userId');

      final metadata = await getSyncMetadata(userId);
      final lastSync = metadata['last_sync_file_connections'];

      // Upload local changes
      final localChanges = localConnections.where((connection) {
        return lastSync == null || connection.updatedAt.isAfter(DateTime.parse(lastSync));
      }).toList();

      if (localChanges.isNotEmpty) {
        final connectionsData = localChanges.map((connection) => {
          'id': connection.id,
          'user_id': userId,
          'name': connection.name,
          'description': connection.description,
          'protocol': connection.protocol.name,
          'host': connection.host,
          'port': connection.port,
          'username': connection.username,
          'password': connection.password, // Note: In production, encrypt passwords
          'remote_path': connection.remotePath,
          'local_path': connection.localPath,
          'is_secure': connection.isSecure,
          'is_active': connection.isActive,
          'created_at': connection.createdAt.toIso8601String(),
          'updated_at': connection.updatedAt.toIso8601String(),
          'last_connected': connection.lastConnected?.toIso8601String(),
          'max_connections': connection.maxConnections,
          'current_connections': connection.currentConnections,
          'metadata': jsonEncode(connection.metadata),
        }).toList();

        await _client.from(SupabaseClientConfig.fileConnectionsTable).upsert(connectionsData);
        AppUtils.logInfo('CloudSyncService', 'Uploaded ${localChanges.length} file connection changes');
      }

      // Download remote changes
      final query = _client.from(SupabaseClientConfig.fileConnectionsTable).select();
      if (lastSync != null) {
        query.gt('updated_at', lastSync);
      }

      final remoteConnections = await query.eq('user_id', userId);
      AppUtils.logInfo('CloudSyncService', 'Downloaded ${remoteConnections.length} remote file connection changes');

      // Update sync metadata
      await updateSyncMetadata(userId, {'last_sync_file_connections': DateTime.now().toIso8601String()});

      AppUtils.logInfo('CloudSyncService', 'File connections sync completed successfully');
    } catch (e) {
      AppUtils.logError('CloudSyncService', 'File connections sync failed', e);
      rethrow;
    }
  }

  // File storage operations
  Future<String?> uploadFile(String userId, String filePath, String fileName) async {
    try {
      AppUtils.logInfo('CloudSyncService', 'Uploading file: $fileName');

      final file = File(filePath);
      final fileBytes = await file.readAsBytes();

      final filePathInStorage = '$userId/$fileName';
      await _client.storage.from(SupabaseClientConfig.filesBucket).uploadBinary(
        filePathInStorage,
        fileBytes,
        fileOptions: FileOptions(
          contentType: _getMimeType(fileName),
        ),
      );

      final publicUrl = _client.storage.from(SupabaseClientConfig.filesBucket).getPublicUrl(filePathInStorage);
      AppUtils.logInfo('CloudSyncService', 'File uploaded successfully: $publicUrl');

      return publicUrl;
    } catch (e) {
      AppUtils.logError('CloudSyncService', 'File upload failed', e);
      return null;
    }
  }

  Future<bool> downloadFile(String userId, String remoteFileName, String localPath) async {
    try {
      AppUtils.logInfo('CloudSyncService', 'Downloading file: $remoteFileName');

      final filePathInStorage = '$userId/$remoteFileName';
      final fileBytes = await _client.storage.from(SupabaseClientConfig.filesBucket).download(filePathInStorage);

      final localFile = File(localPath);
      await localFile.writeAsBytes(fileBytes);

      AppUtils.logInfo('CloudSyncService', 'File downloaded successfully');
      return true;
    } catch (e) {
      AppUtils.logError('CloudSyncService', 'File download failed', e);
      return false;
    }
  }

  Future<bool> deleteFile(String userId, String fileName) async {
    try {
      AppUtils.logInfo('CloudSyncService', 'Deleting file: $fileName');

      final filePathInStorage = '$userId/$fileName';
      await _client.storage.from(SupabaseClientConfig.filesBucket).remove([filePathInStorage]);

      AppUtils.logInfo('CloudSyncService', 'File deleted successfully');
      return true;
    } catch (e) {
      AppUtils.logError('CloudSyncService', 'File deletion failed', e);
      return false;
    }
  }

  // Helper method to get MIME type
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'json':
        return 'application/json';
      default:
        return 'application/octet-stream';
    }
  }

  // Bulk sync method
  Future<void> syncAllData(String userId, {
    List<TaskModel>? tasks,
    List<ReminderModel>? reminders,
    List<NoteModel>? notes,
    List<CalendarEventModel>? calendarEvents,
    List<FileModel>? files,
    List<NetworkModel>? networks,
    List<FileSharingModel>? fileConnections,
  }) async {
    try {
      AppUtils.logInfo('CloudSyncService', 'Starting full data sync for user: $userId');

      await Future.wait([
        if (tasks != null) syncTasks(userId, tasks),
        if (reminders != null) syncReminders(userId, reminders),
        if (notes != null) syncNotes(userId, notes),
        if (calendarEvents != null) syncCalendarEvents(userId, calendarEvents),
        if (files != null) syncFiles(userId, files),
        if (networks != null) syncNetworks(userId, networks),
        if (fileConnections != null) syncFileConnections(userId, fileConnections),
      ]);

      AppUtils.logInfo('CloudSyncService', 'Full data sync completed successfully');
    } catch (e) {
      AppUtils.logError('CloudSyncService', 'Full data sync failed', e);
      rethrow;
    }
  }
}
