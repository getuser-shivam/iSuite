import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/supabase_client.dart';
import '../core/utils.dart';
import '../domain/models/file.dart';
import '../domain/models/file_sharing_model.dart';
import '../domain/models/network_model.dart';
import '../domain/models/reminder.dart';
import '../domain/models/task.dart';
import '../domain/models/note.dart';
import '../domain/models/calendar_event.dart';

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

      return response ?? {};
    } catch (e) {
      AppUtils.logError('Failed to get sync metadata', tag: 'CloudSyncService', error: e);
      return {};
    }
  }

  Future<void> updateSyncMetadata(String userId, Map<String, dynamic> metadata) async {
    try {
      await _client
          .from(SupabaseClientConfig.syncMetadataTable)
          .upsert({
            'user_id': userId,
            ...metadata,
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      AppUtils.logError('Failed to update sync metadata', tag: 'CloudSyncService', error: e);
      rethrow;
    }
  }

  // Task synchronization
  Future<void> syncTasks(String userId) async {
    try {
      final lastSync = await _getLastSyncTime(userId, 'tasks');
      
      // Get local tasks
      final localTasks = await _getLocalTasks();
      
      // Get remote tasks
      final remoteTasks = await _getRemoteTasks(userId, lastSync);
      
      // Merge tasks (conflict resolution: latest wins)
      final mergedTasks = _mergeTasks(localTasks, remoteTasks);
      
      // Update local storage
      await _updateLocalTasks(mergedTasks);
      
      // Update remote storage
      await _updateRemoteTasks(userId, mergedTasks);
      
      // Update sync metadata
      await updateSyncMetadata(userId, {
        'last_sync_tasks': DateTime.now().toIso8601String(),
        'task_version': DateTime.now().millisecondsSinceEpoch,
      });
      
      AppUtils.logInfo('Tasks sync completed successfully', tag: 'CloudSyncService');
    } catch (e) {
      AppUtils.logError('Tasks sync failed', tag: 'CloudSyncService', error: e);
      rethrow;
    }
  }

  Future<List<Task>> _getLocalTasks() async {
    // This would typically fetch from local database
    // For now, return empty list
    return [];
  }

  Future<List<Map<String, dynamic>>> _getRemoteTasks(String userId, DateTime? lastSync) async {
    try {
      var query = _client
          .from(SupabaseClientConfig.tasksTable)
          .select();
      
      if (lastSync != null) {
        query = query.gt('updated_at', lastSync.toIso8601String());
      }
      
      final response = await query.eq('user_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppUtils.logError('Failed to get remote tasks', tag: 'CloudSyncService', error: e);
      return [];
    }
  }

  List<Task> _mergeTasks(List<Task> localTasks, List<Map<String, dynamic>> remoteTasks) {
    // Simple merge logic - in production, this would be more sophisticated
    final mergedTasks = <Task>[];
    
    // Add local tasks
    mergedTasks.addAll(localTasks);
    
    // Convert remote tasks and add/update
    for (final remoteTask in remoteTasks) {
      try {
        final task = Task.fromJson(remoteTask);
        final existingIndex = mergedTasks.indexWhere((t) => t.id == task.id);
        
        if (existingIndex >= 0) {
          // Update existing task if remote is newer
          if (task.createdAt?.isAfter(mergedTasks[existingIndex].createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)) ?? false) {
            mergedTasks[existingIndex] = task;
          }
        } else {
          // Add new task
          mergedTasks.add(task);
        }
      } catch (e) {
        AppUtils.logError('Failed to parse remote task', tag: 'CloudSyncService', error: e);
      }
    }
    
    return mergedTasks;
  }

  Future<void> _updateLocalTasks(List<Task> tasks) async {
    // This would typically update local database
    // For now, just log
    AppUtils.logInfo('Updated ${tasks.length} local tasks', tag: 'CloudSyncService');
  }

  Future<void> _updateRemoteTasks(String userId, List<Task> tasks) async {
    try {
      final tasksData = tasks.map((task) => task.toJson()).toList();
      
      await _client
          .from(SupabaseClientConfig.tasksTable)
          .upsert(tasksData);
          
      AppUtils.logInfo('Updated ${tasks.length} remote tasks', tag: 'CloudSyncService');
    } catch (e) {
      AppUtils.logError('Failed to update remote tasks', tag: 'CloudSyncService', error: e);
      rethrow;
    }
  }

  // Note synchronization
  Future<void> syncNotes(String userId) async {
    try {
      final lastSync = await _getLastSyncTime(userId, 'notes');
      
      // Get local notes
      final localNotes = await _getLocalNotes();
      
      // Get remote notes
      final remoteNotes = await _getRemoteNotes(userId, lastSync);
      
      // Merge notes
      final mergedNotes = _mergeNotes(localNotes, remoteNotes);
      
      // Update local storage
      await _updateLocalNotes(mergedNotes);
      
      // Update remote storage
      await _updateRemoteNotes(userId, mergedNotes);
      
      // Update sync metadata
      await updateSyncMetadata(userId, {
        'last_sync_notes': DateTime.now().toIso8601String(),
        'note_version': DateTime.now().millisecondsSinceEpoch,
      });
      
      AppUtils.logInfo('Notes sync completed successfully', tag: 'CloudSyncService');
    } catch (e) {
      AppUtils.logError('Notes sync failed', tag: 'CloudSyncService', error: e);
      rethrow;
    }
  }

  Future<List<Note>> _getLocalNotes() async {
    // This would typically fetch from local database
    return [];
  }

  Future<List<Map<String, dynamic>>> _getRemoteNotes(String userId, DateTime? lastSync) async {
    try {
      var query = _client
          .from(SupabaseClientConfig.notesTable)
          .select();
      
      if (lastSync != null) {
        query = query.gt('updated_at', lastSync.toIso8601String());
      }
      
      final response = await query.eq('user_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppUtils.logError('Failed to get remote notes', tag: 'CloudSyncService', error: e);
      return [];
    }
  }

  List<Note> _mergeNotes(List<Note> localNotes, List<Map<String, dynamic>> remoteNotes) {
    final mergedNotes = <Note>[];
    mergedNotes.addAll(localNotes);
    
    for (final remoteNote in remoteNotes) {
      try {
        final note = Note.fromJson(remoteNote);
        final existingIndex = mergedNotes.indexWhere((n) => n.id == note.id);
        
        if (existingIndex >= 0) {
          if (note.updatedAt?.isAfter(mergedNotes[existingIndex].updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)) ?? false) {
            mergedNotes[existingIndex] = note;
          }
        } else {
          mergedNotes.add(note);
        }
      } catch (e) {
        AppUtils.logError('Failed to parse remote note', tag: 'CloudSyncService', error: e);
      }
    }
    
    return mergedNotes;
  }

  Future<void> _updateLocalNotes(List<Note> notes) async {
    AppUtils.logInfo('Updated ${notes.length} local notes', tag: 'CloudSyncService');
  }

  Future<void> _updateRemoteNotes(String userId, List<Note> notes) async {
    try {
      final notesData = notes.map((note) => note.toJson()).toList();
      
      await _client
          .from(SupabaseClientConfig.notesTable)
          .upsert(notesData);
          
      AppUtils.logInfo('Updated ${notes.length} remote notes', tag: 'CloudSyncService');
    } catch (e) {
      AppUtils.logError('Failed to update remote notes', tag: 'CloudSyncService', error: e);
      rethrow;
    }
  }

  // Calendar event synchronization
  Future<void> syncCalendarEvents(String userId) async {
    try {
      final lastSync = await _getLastSyncTime(userId, 'calendar_events');
      
      // Get local events
      final localEvents = await _getLocalCalendarEvents();
      
      // Get remote events
      final remoteEvents = await _getRemoteCalendarEvents(userId, lastSync);
      
      // Merge events
      final mergedEvents = _mergeCalendarEvents(localEvents, remoteEvents);
      
      // Update local storage
      await _updateLocalCalendarEvents(mergedEvents);
      
      // Update remote storage
      await _updateRemoteCalendarEvents(userId, mergedEvents);
      
      // Update sync metadata
      await updateSyncMetadata(userId, {
        'last_sync_calendar_events': DateTime.now().toIso8601String(),
        'calendar_event_version': DateTime.now().millisecondsSinceEpoch,
      });
      
      AppUtils.logInfo('Calendar events sync completed successfully', tag: 'CloudSyncService');
    } catch (e) {
      AppUtils.logError('Calendar events sync failed', tag: 'CloudSyncService', error: e);
      rethrow;
    }
  }

  Future<List<CalendarEvent>> _getLocalCalendarEvents() async {
    // This would typically fetch from local database
    return [];
  }

  Future<List<Map<String, dynamic>>> _getRemoteCalendarEvents(String userId, DateTime? lastSync) async {
    try {
      var query = _client
          .from(SupabaseClientConfig.calendarEventsTable)
          .select();
      
      if (lastSync != null) {
        query = query.gt('updated_at', lastSync.toIso8601String());
      }
      
      final response = await query.eq('user_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppUtils.logError('Failed to get remote calendar events', tag: 'CloudSyncService', error: e);
      return [];
    }
  }

  List<CalendarEvent> _mergeCalendarEvents(List<CalendarEvent> localEvents, List<Map<String, dynamic>> remoteEvents) {
    final mergedEvents = <CalendarEvent>[];
    mergedEvents.addAll(localEvents);
    
    for (final remoteEvent in remoteEvents) {
      try {
        final event = CalendarEvent.fromJson(remoteEvent);
        final existingIndex = mergedEvents.indexWhere((e) => e.id == event.id);
        
        if (existingIndex >= 0) {
          if (event.updatedAt?.isAfter(mergedEvents[existingIndex].updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)) ?? false) {
            mergedEvents[existingIndex] = event;
          }
        } else {
          mergedEvents.add(event);
        }
      } catch (e) {
        AppUtils.logError('Failed to parse remote calendar event', tag: 'CloudSyncService', error: e);
      }
    }
    
    return mergedEvents;
  }

  Future<void> _updateLocalCalendarEvents(List<CalendarEvent> events) async {
    AppUtils.logInfo('Updated ${events.length} local calendar events', tag: 'CloudSyncService');
  }

  Future<void> _updateRemoteCalendarEvents(String userId, List<CalendarEvent> events) async {
    try {
      final eventsData = events.map((event) => event.toJson()).toList();
      
      await _client
          .from(SupabaseClientConfig.calendarEventsTable)
          .upsert(eventsData);
          
      AppUtils.logInfo('Updated ${events.length} remote calendar events', tag: 'CloudSyncService');
    } catch (e) {
      AppUtils.logError('Failed to update remote calendar events', tag: 'CloudSyncService', error: e);
      rethrow;
    }
  }

  // Helper methods
  Future<DateTime?> _getLastSyncTime(String userId, String syncType) async {
    try {
      final metadata = await getSyncMetadata(userId);
      final lastSyncString = metadata['last_sync_$syncType'] as String?;
      return lastSyncString != null ? DateTime.parse(lastSyncString) : null;
    } catch (e) {
      AppUtils.logError('Failed to get last sync time', tag: 'CloudSyncService', error: e);
      return null;
    }
  }

  // Full synchronization
  Future<void> syncAll(String userId) async {
    try {
      await syncTasks(userId);
      await syncNotes(userId);
      await syncCalendarEvents(userId);
      
      AppUtils.logInfo('Full synchronization completed successfully', tag: 'CloudSyncService');
    } catch (e) {
      AppUtils.logError('Full synchronization failed', tag: 'CloudSyncService', error: e);
      rethrow;
    }
  }

  // File storage operations
  Future<String?> uploadFile(String userId, String filePath, String fileName) async {
    try {
      AppUtils.logInfo('Uploading file: $fileName', tag: 'CloudSyncService');

      final file = File(filePath);
      final fileBytes = await file.readAsBytes();

      final filePathInStorage = '$userId/$fileName';
      
      final response = await _client.storage
          .from(SupabaseClientConfig.filesBucket)
          .uploadBinary(
            filePathInStorage,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      AppUtils.logInfo('File uploaded successfully: $fileName', tag: 'CloudSyncService');
      return response;
    } catch (e) {
      AppUtils.logError('File upload failed', tag: 'CloudSyncService', error: e);
      rethrow;
    }
  }

  Future<String?> downloadFile(String userId, String fileName) async {
    try {
      AppUtils.logInfo('Downloading file: $fileName', tag: 'CloudSyncService');

      final filePathInStorage = '$userId/$fileName';
      
      final response = await _client.storage
          .from(SupabaseClientConfig.filesBucket)
          .createSignedUrl(filePathInStorage, 3600); // 1 hour expiry

      AppUtils.logInfo('File download URL generated: $fileName', tag: 'CloudSyncService');
      return response;
    } catch (e) {
      AppUtils.logError('File download failed', tag: 'CloudSyncService', error: e);
      rethrow;
    }
  }

  Future<void> deleteFile(String userId, String fileName) async {
    try {
      AppUtils.logInfo('Deleting file: $fileName', tag: 'CloudSyncService');

      final filePathInStorage = '$userId/$fileName';
      
      await _client.storage
          .from(SupabaseClientConfig.filesBucket)
          .remove([filePathInStorage]);

      AppUtils.logInfo('File deleted successfully: $fileName', tag: 'CloudSyncService');
    } catch (e) {
      AppUtils.logError('File deletion failed', tag: 'CloudSyncService', error: e);
      rethrow;
    }
  }
}
