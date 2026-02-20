import 'dart:convert';

import '../../core/utils.dart';
import '../../domain/models/backup.dart';
import '../../domain/models/calendar_event.dart';
import '../../domain/models/file.dart';
import '../../domain/models/note.dart';
import '../../domain/models/task.dart';
import 'calendar_repository.dart';
import 'file_repository.dart';
import 'note_repository.dart';
import 'task_repository.dart';

class BackupRepository {
  static Future<String> createBackup({
    required BackupType type,
    String name = '',
    String? description,
    bool encrypt = false,
    String? password,
  }) async {
    final backupData = <String, dynamic>{
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'type': type.name,
      'name': name.isEmpty
          ? 'Backup ${DateTime.now().toString().split('.')[0]}'
          : name,
      'description': description,
      'data': <String, dynamic>{},
    };

    try {
      // Collect data based on backup type
      switch (type) {
        case BackupType.full:
          backupData['data'] = await _collectAllData();
          break;
        case BackupType.tasks:
          backupData['data']['tasks'] = await _collectTasksData();
          break;
        case BackupType.notes:
          backupData['data']['notes'] = await _collectNotesData();
          break;
        case BackupType.files:
          backupData['data']['files'] = await _collectFilesData();
          break;
        case BackupType.calendar:
          backupData['data']['events'] = await _collectEventsData();
          break;
        case BackupType.custom:
          // Custom backup - collect all for now
          backupData['data'] = await _collectAllData();
          break;
      }

      // Calculate size
      final jsonString = jsonEncode(backupData);
      backupData['size'] = utf8.encode(jsonString).length;

      // Encrypt if requested (simple base64 for demo)
      var finalData = jsonString;
      if (encrypt && password != null) {
        // Simple encryption - in real app, use proper encryption
        finalData = base64Encode(utf8.encode(jsonString));
        backupData['encrypted'] = true;
      }

      return finalData;
    } catch (e) {
      AppUtils.logError('Failed to create backup', error: e);
      rethrow;
    }
  }

  static Future<void> restoreBackup({
    required String backupData,
    required BackupType type,
    String? password,
  }) async {
    try {
      // Decrypt if needed
      var jsonString = backupData;
      if (password != null) {
        try {
          jsonString = utf8.decode(base64Decode(backupData));
        } catch (e) {
          throw Exception('Invalid password or corrupted backup');
        }
      }

      final Map<String, dynamic> data = jsonDecode(jsonString);

      // Validate backup format
      if (!data.containsKey('version') || !data.containsKey('data')) {
        throw Exception('Invalid backup format');
      }

      // Restore data based on type
      switch (type) {
        case BackupType.full:
          await _restoreAllData(data['data']);
          break;
        case BackupType.tasks:
          await _restoreTasksData(data['data']['tasks'] ?? []);
          break;
        case BackupType.notes:
          await _restoreNotesData(data['data']['notes'] ?? []);
          break;
        case BackupType.files:
          await _restoreFilesData(data['data']['files'] ?? []);
          break;
        case BackupType.calendar:
          await _restoreEventsData(data['data']['events'] ?? []);
          break;
        case BackupType.custom:
          await _restoreAllData(data['data']);
          break;
      }

      AppUtils.logInfo('Backup restored successfully', tag: 'BackupRepository');
    } catch (e) {
      AppUtils.logError('Failed to restore backup', error: e);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> _collectAllData() async => {
        'tasks': await _collectTasksData(),
        'notes': await _collectNotesData(),
        'files': await _collectFilesData(),
        'events': await _collectEventsData(),
      };

  static Future<List<Map<String, dynamic>>> _collectTasksData() async {
    final tasks = await TaskRepository.getAllTasks();
    return tasks.map((task) => task.toJson()).toList();
  }

  static Future<List<Map<String, dynamic>>> _collectNotesData() async {
    final notes = await NoteRepository.getAllNotes();
    return notes.map((note) => note.toJson()).toList();
  }

  static Future<List<Map<String, dynamic>>> _collectFilesData() async {
    final files = await FileRepository.getAllFiles();
    return files.map((file) => file.toJson()).toList();
  }

  static Future<List<Map<String, dynamic>>> _collectEventsData() async {
    final events = await CalendarRepository.getAllEvents();
    return events.map((event) => event.toJson()).toList();
  }

  static Future<void> _restoreAllData(Map<String, dynamic> data) async {
    await _restoreTasksData(data['tasks'] ?? []);
    await _restoreNotesData(data['notes'] ?? []);
    await _restoreFilesData(data['files'] ?? []);
    await _restoreEventsData(data['events'] ?? []);
  }

  static Future<void> _restoreTasksData(List<dynamic> tasksData) async {
    for (final taskJson in tasksData) {
      try {
        final task = Task.fromJson(taskJson as Map<String, dynamic>);
        // Generate new ID to avoid conflicts
        final newTask = task.copyWith(id: AppUtils.generateRandomId());
        await TaskRepository.createTask(newTask);
      } catch (e) {
        AppUtils.logWarning('Failed to restore task: $e',
            tag: 'BackupRepository');
      }
    }
  }

  static Future<void> _restoreNotesData(List<dynamic> notesData) async {
    for (final noteJson in notesData) {
      try {
        final note = Note.fromJson(noteJson as Map<String, dynamic>);
        final newNote = note.copyWith(id: AppUtils.generateRandomId());
        await NoteRepository.createNote(newNote);
      } catch (e) {
        AppUtils.logWarning('Failed to restore note: $e',
            tag: 'BackupRepository');
      }
    }
  }

  static Future<void> _restoreFilesData(List<dynamic> filesData) async {
    for (final fileJson in filesData) {
      try {
        final file = FileModel.fromJson(fileJson as Map<String, dynamic>);
        final newFile = file.copyWith(id: AppUtils.generateRandomId());
        await FileRepository.createFile(newFile);
      } catch (e) {
        AppUtils.logWarning('Failed to restore file: $e',
            tag: 'BackupRepository');
      }
    }
  }

  static Future<void> _restoreEventsData(List<dynamic> eventsData) async {
    for (final eventJson in eventsData) {
      try {
        final event = CalendarEvent.fromJson(eventJson as Map<String, dynamic>);
        final newEvent = event.copyWith(id: AppUtils.generateRandomId());
        await CalendarRepository.createEvent(newEvent);
      } catch (e) {
        AppUtils.logWarning('Failed to restore event: $e',
            tag: 'BackupRepository');
      }
    }
  }

  // Utility methods for backup management
  static Future<List<BackupModel>> getBackupHistory() async {
    // In a real app, this would load from persistent storage
    // For now, return empty list
    return [];
  }

  static Future<void> saveBackupMetadata(BackupModel backup) async {
    // Save backup metadata to persistent storage
    // Implementation depends on storage solution
    AppUtils.logInfo('Backup metadata saved: ${backup.name}',
        tag: 'BackupRepository');
  }

  static Future<bool> validateBackup(String backupData) async {
    try {
      final Map<String, dynamic> data = jsonDecode(backupData);
      return data.containsKey('version') && data.containsKey('data');
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, int>> getBackupStats(String backupData) async {
    try {
      final Map<String, dynamic> data = jsonDecode(backupData);
      final backupDataMap = data['data'] as Map<String, dynamic>;

      return {
        'tasks': (backupDataMap['tasks'] as List?)?.length ?? 0,
        'notes': (backupDataMap['notes'] as List?)?.length ?? 0,
        'files': (backupDataMap['files'] as List?)?.length ?? 0,
        'events': (backupDataMap['events'] as List?)?.length ?? 0,
      };
    } catch (e) {
      return {};
    }
  }
}
