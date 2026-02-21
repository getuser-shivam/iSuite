import 'package:collection/collection.dart';

import '../../domain/models/analytics.dart';
import '../../domain/models/calendar_event.dart';
import '../../domain/models/file.dart';
import '../../domain/models/note.dart';
import '../../domain/models/task.dart';
import 'calendar_repository.dart';
import 'file_repository.dart';
import 'note_repository.dart';
import 'task_repository.dart';

class AnalyticsRepository {
  static Future<AnalyticsModel> getAnalytics({
    TimePeriod period = TimePeriod.month,
  }) async {
    final now = DateTime.now();
    final startDate = _getStartDate(now, period);

    // Get all data
    final tasks = await TaskRepository.getAllTasks();
    final notes = await NoteRepository.getAllNotes();
    final files = await FileRepository.getAllFiles();
    final events = await CalendarRepository.getAllEvents();

    // Filter by period if needed
    final filteredTasks = period == TimePeriod.all
        ? tasks
        : tasks.where((task) => task.createdAt.isAfter(startDate)).toList();

    final filteredNotes = period == TimePeriod.all
        ? notes
        : notes.where((note) => note.createdAt.isAfter(startDate)).toList();

    final filteredFiles = period == TimePeriod.all
        ? files
        : files.where((file) => file.createdAt.isAfter(startDate)).toList();

    final filteredEvents = period == TimePeriod.all
        ? events
        : events.where((event) => event.createdAt.isAfter(startDate)).toList();

    // Compute task analytics
    final taskAnalytics = _computeTaskAnalytics(filteredTasks);

    // Compute note analytics
    final noteAnalytics = _computeNoteAnalytics(filteredNotes);

    // Compute file analytics
    final fileAnalytics = _computeFileAnalytics(filteredFiles);

    // Compute event analytics
    final eventAnalytics = _computeEventAnalytics(filteredEvents);

    // Combine all analytics
    return AnalyticsModel(
      // Tasks
      totalTasks: taskAnalytics['total'] ?? 0,
      completedTasks: taskAnalytics['completed'] ?? 0,
      pendingTasks: taskAnalytics['pending'] ?? 0,
      overdueTasks: taskAnalytics['overdue'] ?? 0,
      highPriorityTasks: taskAnalytics['highPriority'] ?? 0,
      mediumPriorityTasks: taskAnalytics['mediumPriority'] ?? 0,
      lowPriorityTasks: taskAnalytics['lowPriority'] ?? 0,
      tasksByCategory: taskAnalytics['byCategory'] ?? {},
      taskCompletionTrend: taskAnalytics['completionTrend'] ?? [],
      taskStatusDistribution: taskAnalytics['statusDistribution'] ?? [],
      taskPriorityDistribution: taskAnalytics['priorityDistribution'] ?? [],
      taskCompletionRate: taskAnalytics['completionRate'] ?? 0.0,

      // Notes
      totalNotes: noteAnalytics['total'] ?? 0,
      draftNotes: noteAnalytics['draft'] ?? 0,
      publishedNotes: noteAnalytics['published'] ?? 0,
      textNotes: noteAnalytics['text'] ?? 0,
      checklistNotes: noteAnalytics['checklist'] ?? 0,
      encryptedNotes: noteAnalytics['encrypted'] ?? 0,
      favoriteNotes: noteAnalytics['favorite'] ?? 0,
      totalWordCount: noteAnalytics['wordCount'] ?? 0,
      averageReadingTime: noteAnalytics['readingTime'] ?? 0,
      notesByCategory: noteAnalytics['byCategory'] ?? {},
      noteCreationTrend: noteAnalytics['creationTrend'] ?? [],
      noteTypeDistribution: noteAnalytics['typeDistribution'] ?? [],
      noteStatusDistribution: noteAnalytics['statusDistribution'] ?? [],

      // Files
      totalFiles: fileAnalytics['total'] ?? 0,
      imageFiles: fileAnalytics['images'] ?? 0,
      documentFiles: fileAnalytics['documents'] ?? 0,
      videoFiles: fileAnalytics['videos'] ?? 0,
      audioFiles: fileAnalytics['audio'] ?? 0,
      archiveFiles: fileAnalytics['archives'] ?? 0,
      encryptedFiles: fileAnalytics['encrypted'] ?? 0,
      favoriteFiles: fileAnalytics['favorites'] ?? 0,
      totalFileSize: fileAnalytics['totalSize'] ?? 0.0,
      totalDownloads: fileAnalytics['downloads'] ?? 0,
      filesByType: fileAnalytics['byType'] ?? {},
      fileUploadTrend: fileAnalytics['uploadTrend'] ?? [],
      fileTypeDistribution: fileAnalytics['typeDistribution'] ?? [],
      fileSizeByType: fileAnalytics['sizeByType'] ?? [],

      // Events
      totalEvents: eventAnalytics['total'] ?? 0,
      upcomingEvents: eventAnalytics['upcoming'] ?? 0,
      pastEvents: eventAnalytics['past'] ?? 0,
      meetingEvents: eventAnalytics['meetings'] ?? 0,
      reminderEvents: eventAnalytics['reminders'] ?? 0,
      personalEvents: eventAnalytics['personal'] ?? 0,
      workEvents: eventAnalytics['work'] ?? 0,
      eventsByCategory: eventAnalytics['byCategory'] ?? {},
      eventCreationTrend: eventAnalytics['creationTrend'] ?? [],
      eventTypeDistribution: eventAnalytics['typeDistribution'] ?? [],
      eventStatusDistribution: eventAnalytics['statusDistribution'] ?? [],

      // Overall
      totalItems: (taskAnalytics['total'] ?? 0) +
          (noteAnalytics['total'] ?? 0) +
          (fileAnalytics['total'] ?? 0) +
          (eventAnalytics['total'] ?? 0),
      selectedPeriod: period,
    );
  }

  static Map<String, dynamic> _computeTaskAnalytics(List<Task> tasks) {
    final now = DateTime.now();

    final total = tasks.length;
    final completed =
        tasks.where((t) => t.status == TaskStatus.completed).length;
    final pending = tasks.where((t) => t.status == TaskStatus.pending).length;
    final overdue = tasks.where((t) => t.isOverdue).length;

    final highPriority =
        tasks.where((t) => t.priority == TaskPriority.high).length;
    final mediumPriority =
        tasks.where((t) => t.priority == TaskPriority.medium).length;
    final lowPriority =
        tasks.where((t) => t.priority == TaskPriority.low).length;

    final byCategory = <String, int>{};
    for (final task in tasks) {
      byCategory[task.category.name] =
          (byCategory[task.category.name] ?? 0) + 1;
    }

    // Completion trend (daily for last 30 days)
    final completionTrend = <TimeSeriesData>[];
    final dailyCompleted = <DateTime, int>{};

    for (final task in tasks.where((t) => t.status == TaskStatus.completed)) {
      final date = DateTime(
          task.completedAt?.year ?? task.updatedAt.year,
          task.completedAt?.month ?? task.updatedAt.month,
          task.completedAt?.day ?? task.updatedAt.day);
      dailyCompleted[date] = (dailyCompleted[date] ?? 0) + 1;
    }

    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    for (var i = 0; i < 30; i++) {
      final date = thirtyDaysAgo.add(Duration(days: i));
      final dayDate = DateTime(date.year, date.month, date.day);
      completionTrend.add(TimeSeriesData(
        date: dayDate,
        value: (dailyCompleted[dayDate] ?? 0).toDouble(),
        label: 'Completed Tasks',
      ));
    }

    final statusDistribution = [
      ChartDataPoint(label: 'Completed', value: completed.toDouble()),
      ChartDataPoint(label: 'Pending', value: pending.toDouble()),
      ChartDataPoint(label: 'Overdue', value: overdue.toDouble()),
    ];

    final priorityDistribution = [
      ChartDataPoint(label: 'High', value: highPriority.toDouble()),
      ChartDataPoint(label: 'Medium', value: mediumPriority.toDouble()),
      ChartDataPoint(label: 'Low', value: lowPriority.toDouble()),
    ];

    final completionRate = total > 0 ? (completed / total) * 100 : 0.0;

    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'overdue': overdue,
      'highPriority': highPriority,
      'mediumPriority': mediumPriority,
      'lowPriority': lowPriority,
      'byCategory': byCategory,
      'completionTrend': completionTrend,
      'statusDistribution': statusDistribution,
      'priorityDistribution': priorityDistribution,
      'completionRate': completionRate,
    };
  }

  static Map<String, dynamic> _computeNoteAnalytics(List<Note> notes) {
    final total = notes.length;
    final draft = notes.where((n) => n.status == NoteStatus.draft).length;
    final published =
        notes.where((n) => n.status == NoteStatus.published).length;

    final text = notes.where((n) => n.type == NoteType.text).length;
    final checklist = notes.where((n) => n.type == NoteType.checklist).length;
    final encrypted = notes.where((n) => n.isEncrypted).length;
    final favorite = notes.where((n) => n.isFavorite).length;

    final wordCount =
        notes.fold<int>(0, (sum, note) => sum + (note.wordCount ?? 0));
    final readingTime = notes.isNotEmpty
        ? notes.fold<int>(0, (sum, note) => sum + (note.readingTime ?? 0)) ~/
            notes.length
        : 0;

    final byCategory = <String, int>{};
    for (final note in notes) {
      byCategory[note.category.name] =
          (byCategory[note.category.name] ?? 0) + 1;
    }

    // Creation trend
    final creationTrend = <TimeSeriesData>[];
    final dailyCreated = <DateTime, int>{};

    for (final note in notes) {
      final date = DateTime(
          note.createdAt.year, note.createdAt.month, note.createdAt.day);
      dailyCreated[date] = (dailyCreated[date] ?? 0) + 1;
    }

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    for (var i = 0; i < 30; i++) {
      final date = thirtyDaysAgo.add(Duration(days: i));
      final dayDate = DateTime(date.year, date.month, date.day);
      creationTrend.add(TimeSeriesData(
        date: dayDate,
        value: (dailyCreated[dayDate] ?? 0).toDouble(),
        label: 'Created Notes',
      ));
    }

    final typeDistribution = [
      ChartDataPoint(label: 'Text', value: text.toDouble()),
      ChartDataPoint(label: 'Checklist', value: checklist.toDouble()),
    ];

    final statusDistribution = [
      ChartDataPoint(label: 'Draft', value: draft.toDouble()),
      ChartDataPoint(label: 'Published', value: published.toDouble()),
    ];

    return {
      'total': total,
      'draft': draft,
      'published': published,
      'text': text,
      'checklist': checklist,
      'encrypted': encrypted,
      'favorite': favorite,
      'wordCount': wordCount,
      'readingTime': readingTime,
      'byCategory': byCategory,
      'creationTrend': creationTrend,
      'typeDistribution': typeDistribution,
      'statusDistribution': statusDistribution,
    };
  }

  static Map<String, dynamic> _computeFileAnalytics(List<FileModel> files) {
    final total = files.length;
    final images = files.where((f) => f.isImage).length;
    final documents = files.where((f) => f.isDocument).length;
    final videos = files.where((f) => f.isVideo).length;
    final audio = files.where((f) => f.isAudio).length;
    final archives = files.where((f) => f.isArchive).length;
    final encrypted = files.where((f) => f.isEncrypted).length;
    final favorites = files.where((f) => f.tags.contains('favorite')).length;

    final totalSize = files.fold<double>(0, (sum, file) => sum + file.size);
    final downloads =
        files.fold<int>(0, (sum, file) => sum + (file.downloadCount ?? 0));

    final byType = <String, int>{};
    for (final file in files) {
      byType[file.type.name] = (byType[file.type.name] ?? 0) + 1;
    }

    // Upload trend
    final uploadTrend = <TimeSeriesData>[];
    final dailyUploaded = <DateTime, int>{};

    for (final file in files) {
      final date = DateTime(
          file.createdAt.year, file.createdAt.month, file.createdAt.day);
      dailyUploaded[date] = (dailyUploaded[date] ?? 0) + 1;
    }

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    for (var i = 0; i < 30; i++) {
      final date = thirtyDaysAgo.add(Duration(days: i));
      final dayDate = DateTime(date.year, date.month, date.day);
      uploadTrend.add(TimeSeriesData(
        date: dayDate,
        value: (dailyUploaded[dayDate] ?? 0).toDouble(),
        label: 'Uploaded Files',
      ));
    }

    final typeDistribution = [
      ChartDataPoint(label: 'Images', value: images.toDouble()),
      ChartDataPoint(label: 'Documents', value: documents.toDouble()),
      ChartDataPoint(label: 'Videos', value: videos.toDouble()),
      ChartDataPoint(label: 'Audio', value: audio.toDouble()),
      ChartDataPoint(label: 'Archives', value: archives.toDouble()),
    ];

    final sizeByType = byType.entries.map((entry) {
      final typeFiles = files.where((f) => f.type.name == entry.key).toList();
      final size = typeFiles.fold<double>(0, (sum, file) => sum + file.size);
      return ChartDataPoint(label: entry.key, value: size);
    }).toList();

    return {
      'total': total,
      'images': images,
      'documents': documents,
      'videos': videos,
      'audio': audio,
      'archives': archives,
      'encrypted': encrypted,
      'favorites': favorites,
      'totalSize': totalSize,
      'downloads': downloads,
      'byType': byType,
      'uploadTrend': uploadTrend,
      'typeDistribution': typeDistribution,
      'sizeByType': sizeByType,
    };
  }

  static Map<String, dynamic> _computeEventAnalytics(
      List<CalendarEvent> events) {
    final now = DateTime.now();
    final total = events.length;
    final upcoming = events.where((e) => e.startDate.isAfter(now)).length;
    final past = events.where((e) => e.endDate.isBefore(now)).length;

    final meetings =
        events.where((e) => e.eventType == EventType.meeting).length;
    final reminders =
        events.where((e) => e.eventType == EventType.reminder).length;
    final personal =
        events.where((e) => e.category == EventCategory.personal).length;
    final work = events.where((e) => e.category == EventCategory.work).length;

    final byCategory = <String, int>{};
    for (final event in events) {
      byCategory[event.category.name] =
          (byCategory[event.category.name] ?? 0) + 1;
    }

    // Creation trend
    final creationTrend = <TimeSeriesData>[];
    final dailyCreated = <DateTime, int>{};

    for (final event in events) {
      final date = DateTime(
          event.createdAt.year, event.createdAt.month, event.createdAt.day);
      dailyCreated[date] = (dailyCreated[date] ?? 0) + 1;
    }

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    for (var i = 0; i < 30; i++) {
      final date = thirtyDaysAgo.add(Duration(days: i));
      final dayDate = DateTime(date.year, date.month, date.day);
      creationTrend.add(TimeSeriesData(
        date: dayDate,
        value: (dailyCreated[dayDate] ?? 0).toDouble(),
        label: 'Created Events',
      ));
    }

    final typeDistribution = [
      ChartDataPoint(label: 'Meetings', value: meetings.toDouble()),
      ChartDataPoint(label: 'Reminders', value: reminders.toDouble()),
    ];

    final statusDistribution = [
      ChartDataPoint(label: 'Upcoming', value: upcoming.toDouble()),
      ChartDataPoint(label: 'Past', value: past.toDouble()),
    ];

    return {
      'total': total,
      'upcoming': upcoming,
      'past': past,
      'meetings': meetings,
      'reminders': reminders,
      'personal': personal,
      'work': work,
      'byCategory': byCategory,
      'creationTrend': creationTrend,
      'typeDistribution': typeDistribution,
      'statusDistribution': statusDistribution,
    };
  }

  static DateTime _getStartDate(DateTime now, TimePeriod period) {
    switch (period) {
      case TimePeriod.today:
        return DateTime(now.year, now.month, now.day);
      case TimePeriod.week:
        return now.subtract(const Duration(days: 7));
      case TimePeriod.month:
        return DateTime(now.year, now.month);
      case TimePeriod.quarter:
        final quarterStart = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTime(now.year, quarterStart);
      case TimePeriod.year:
        return DateTime(now.year);
      case TimePeriod.all:
        return DateTime(2000); // Far in the past
    }
  }
}
