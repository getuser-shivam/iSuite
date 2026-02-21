import 'package:equatable/equatable.dart';

enum ChartType {
  bar,
  line,
  pie,
  doughnut,
}

enum TimePeriod {
  today,
  week,
  month,
  quarter,
  year,
  all,
}

enum MetricType {
  tasks,
  notes,
  files,
  events,
}

class ChartDataPoint extends Equatable {
  const ChartDataPoint({
    required this.label,
    required this.value,
    this.color,
  });
  final String label;
  final double value;
  final String? color;

  @override
  List<Object?> get props => [label, value, color];
}

class TimeSeriesData extends Equatable {
  const TimeSeriesData({
    required this.date,
    required this.value,
    required this.label,
  });
  final DateTime date;
  final double value;
  final String label;

  @override
  List<Object?> get props => [date, value, label];
}

class AnalyticsModel extends Equatable {
  const AnalyticsModel({
    // Tasks
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.pendingTasks = 0,
    this.overdueTasks = 0,
    this.highPriorityTasks = 0,
    this.mediumPriorityTasks = 0,
    this.lowPriorityTasks = 0,
    this.tasksByCategory = const {},
    this.taskCompletionTrend = const [],
    this.taskStatusDistribution = const [],
    this.taskPriorityDistribution = const [],
    this.taskCompletionRate = 0.0,

    // Notes
    this.totalNotes = 0,
    this.draftNotes = 0,
    this.publishedNotes = 0,
    this.textNotes = 0,
    this.checklistNotes = 0,
    this.encryptedNotes = 0,
    this.favoriteNotes = 0,
    this.totalWordCount = 0,
    this.averageReadingTime = 0,
    this.notesByCategory = const {},
    this.noteCreationTrend = const [],
    this.noteTypeDistribution = const [],
    this.noteStatusDistribution = const [],

    // Files
    this.totalFiles = 0,
    this.imageFiles = 0,
    this.documentFiles = 0,
    this.videoFiles = 0,
    this.audioFiles = 0,
    this.archiveFiles = 0,
    this.encryptedFiles = 0,
    this.favoriteFiles = 0,
    this.totalFileSize = 0.0,
    this.totalDownloads = 0,
    this.filesByType = const {},
    this.fileUploadTrend = const [],
    this.fileTypeDistribution = const [],
    this.fileSizeByType = const [],

    // Events
    this.totalEvents = 0,
    this.upcomingEvents = 0,
    this.pastEvents = 0,
    this.meetingEvents = 0,
    this.reminderEvents = 0,
    this.personalEvents = 0,
    this.workEvents = 0,
    this.eventsByCategory = const {},
    this.eventCreationTrend = const [],
    this.eventTypeDistribution = const [],
    this.eventStatusDistribution = const [],

    // Overall
    this.totalItems = 0,
    DateTime? lastUpdated,
    this.selectedPeriod = TimePeriod.month,
  }) : lastUpdated = lastUpdated ?? DateTime.now();
  // Task Analytics
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int overdueTasks;
  final int highPriorityTasks;
  final int mediumPriorityTasks;
  final int lowPriorityTasks;
  final Map<String, int> tasksByCategory;
  final List<TimeSeriesData> taskCompletionTrend;
  final List<ChartDataPoint> taskStatusDistribution;
  final List<ChartDataPoint> taskPriorityDistribution;
  final double taskCompletionRate;

  // Note Analytics
  final int totalNotes;
  final int draftNotes;
  final int publishedNotes;
  final int textNotes;
  final int checklistNotes;
  final int encryptedNotes;
  final int favoriteNotes;
  final int totalWordCount;
  final int averageReadingTime;
  final Map<String, int> notesByCategory;
  final List<TimeSeriesData> noteCreationTrend;
  final List<ChartDataPoint> noteTypeDistribution;
  final List<ChartDataPoint> noteStatusDistribution;

  // File Analytics
  final int totalFiles;
  final int imageFiles;
  final int documentFiles;
  final int videoFiles;
  final int audioFiles;
  final int archiveFiles;
  final int encryptedFiles;
  final int favoriteFiles;
  final double totalFileSize;
  final int totalDownloads;
  final Map<String, int> filesByType;
  final List<TimeSeriesData> fileUploadTrend;
  final List<ChartDataPoint> fileTypeDistribution;
  final List<ChartDataPoint> fileSizeByType;

  // Calendar Analytics
  final int totalEvents;
  final int upcomingEvents;
  final int pastEvents;
  final int meetingEvents;
  final int reminderEvents;
  final int personalEvents;
  final int workEvents;
  final Map<String, int> eventsByCategory;
  final List<TimeSeriesData> eventCreationTrend;
  final List<ChartDataPoint> eventTypeDistribution;
  final List<ChartDataPoint> eventStatusDistribution;

  // Overall Analytics
  final int totalItems;
  final DateTime lastUpdated;
  final TimePeriod selectedPeriod;

  AnalyticsModel copyWith({
    // Tasks
    int? totalTasks,
    int? completedTasks,
    int? pendingTasks,
    int? overdueTasks,
    int? highPriorityTasks,
    int? mediumPriorityTasks,
    int? lowPriorityTasks,
    Map<String, int>? tasksByCategory,
    List<TimeSeriesData>? taskCompletionTrend,
    List<ChartDataPoint>? taskStatusDistribution,
    List<ChartDataPoint>? taskPriorityDistribution,
    double? taskCompletionRate,

    // Notes
    int? totalNotes,
    int? draftNotes,
    int? publishedNotes,
    int? textNotes,
    int? checklistNotes,
    int? encryptedNotes,
    int? favoriteNotes,
    int? totalWordCount,
    int? averageReadingTime,
    Map<String, int>? notesByCategory,
    List<TimeSeriesData>? noteCreationTrend,
    List<ChartDataPoint>? noteTypeDistribution,
    List<ChartDataPoint>? noteStatusDistribution,

    // Files
    int? totalFiles,
    int? imageFiles,
    int? documentFiles,
    int? videoFiles,
    int? audioFiles,
    int? archiveFiles,
    int? encryptedFiles,
    int? favoriteFiles,
    double? totalFileSize,
    int? totalDownloads,
    Map<String, int>? filesByType,
    List<TimeSeriesData>? fileUploadTrend,
    List<ChartDataPoint>? fileTypeDistribution,
    List<ChartDataPoint>? fileSizeByType,

    // Events
    int? totalEvents,
    int? upcomingEvents,
    int? pastEvents,
    int? meetingEvents,
    int? reminderEvents,
    int? personalEvents,
    int? workEvents,
    Map<String, int>? eventsByCategory,
    List<TimeSeriesData>? eventCreationTrend,
    List<ChartDataPoint>? eventTypeDistribution,
    List<ChartDataPoint>? eventStatusDistribution,

    // Overall
    int? totalItems,
    DateTime? lastUpdated,
    TimePeriod? selectedPeriod,
  }) =>
      AnalyticsModel(
        // Tasks
        totalTasks: totalTasks ?? this.totalTasks,
        completedTasks: completedTasks ?? this.completedTasks,
        pendingTasks: pendingTasks ?? this.pendingTasks,
        overdueTasks: overdueTasks ?? this.overdueTasks,
        highPriorityTasks: highPriorityTasks ?? this.highPriorityTasks,
        mediumPriorityTasks: mediumPriorityTasks ?? this.mediumPriorityTasks,
        lowPriorityTasks: lowPriorityTasks ?? this.lowPriorityTasks,
        tasksByCategory: tasksByCategory ?? this.tasksByCategory,
        taskCompletionTrend: taskCompletionTrend ?? this.taskCompletionTrend,
        taskStatusDistribution:
            taskStatusDistribution ?? this.taskStatusDistribution,
        taskPriorityDistribution:
            taskPriorityDistribution ?? this.taskPriorityDistribution,
        taskCompletionRate: taskCompletionRate ?? this.taskCompletionRate,

        // Notes
        totalNotes: totalNotes ?? this.totalNotes,
        draftNotes: draftNotes ?? this.draftNotes,
        publishedNotes: publishedNotes ?? this.publishedNotes,
        textNotes: textNotes ?? this.textNotes,
        checklistNotes: checklistNotes ?? this.checklistNotes,
        encryptedNotes: encryptedNotes ?? this.encryptedNotes,
        favoriteNotes: favoriteNotes ?? this.favoriteNotes,
        totalWordCount: totalWordCount ?? this.totalWordCount,
        averageReadingTime: averageReadingTime ?? this.averageReadingTime,
        notesByCategory: notesByCategory ?? this.notesByCategory,
        noteCreationTrend: noteCreationTrend ?? this.noteCreationTrend,
        noteTypeDistribution: noteTypeDistribution ?? this.noteTypeDistribution,
        noteStatusDistribution:
            noteStatusDistribution ?? this.noteStatusDistribution,

        // Files
        totalFiles: totalFiles ?? this.totalFiles,
        imageFiles: imageFiles ?? this.imageFiles,
        documentFiles: documentFiles ?? this.documentFiles,
        videoFiles: videoFiles ?? this.videoFiles,
        audioFiles: audioFiles ?? this.audioFiles,
        archiveFiles: archiveFiles ?? this.archiveFiles,
        encryptedFiles: encryptedFiles ?? this.encryptedFiles,
        favoriteFiles: favoriteFiles ?? this.favoriteFiles,
        totalFileSize: totalFileSize ?? this.totalFileSize,
        totalDownloads: totalDownloads ?? this.totalDownloads,
        filesByType: filesByType ?? this.filesByType,
        fileUploadTrend: fileUploadTrend ?? this.fileUploadTrend,
        fileTypeDistribution: fileTypeDistribution ?? this.fileTypeDistribution,
        fileSizeByType: fileSizeByType ?? this.fileSizeByType,

        // Events
        totalEvents: totalEvents ?? this.totalEvents,
        upcomingEvents: upcomingEvents ?? this.upcomingEvents,
        pastEvents: pastEvents ?? this.pastEvents,
        meetingEvents: meetingEvents ?? this.meetingEvents,
        reminderEvents: reminderEvents ?? this.reminderEvents,
        personalEvents: personalEvents ?? this.personalEvents,
        workEvents: workEvents ?? this.workEvents,
        eventsByCategory: eventsByCategory ?? this.eventsByCategory,
        eventCreationTrend: eventCreationTrend ?? this.eventCreationTrend,
        eventTypeDistribution:
            eventTypeDistribution ?? this.eventTypeDistribution,
        eventStatusDistribution:
            eventStatusDistribution ?? this.eventStatusDistribution,

        // Overall
        totalItems: totalItems ?? this.totalItems,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      );

  // Computed properties
  String get formattedTotalFileSize {
    final totalBytes = totalFileSize.toInt();
    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024)
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    if (totalBytes < 1024 * 1024 * 1024)
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  double get productivityScore {
    // Calculate based on completion rates and activity
    final taskScore = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;
    final noteScore = totalNotes > 0 ? (publishedNotes / totalNotes) * 100 : 0;
    final fileScore = totalFiles > 0 ? (favoriteFiles / totalFiles) * 100 : 0;
    final eventScore =
        totalEvents > 0 ? (upcomingEvents / totalEvents) * 100 : 0;

    return (taskScore + noteScore + fileScore + eventScore) / 4;
  }

  bool get hasData => totalItems > 0;

  @override
  List<Object?> get props => [
        // Tasks
        totalTasks,
        completedTasks,
        pendingTasks,
        overdueTasks,
        highPriorityTasks,
        mediumPriorityTasks,
        lowPriorityTasks,
        tasksByCategory,
        taskCompletionTrend,
        taskStatusDistribution,
        taskPriorityDistribution,
        taskCompletionRate,

        // Notes
        totalNotes,
        draftNotes,
        publishedNotes,
        textNotes,
        checklistNotes,
        encryptedNotes,
        favoriteNotes,
        totalWordCount,
        averageReadingTime,
        notesByCategory,
        noteCreationTrend,
        noteTypeDistribution,
        noteStatusDistribution,

        // Files
        totalFiles,
        imageFiles,
        documentFiles,
        videoFiles,
        audioFiles,
        archiveFiles,
        encryptedFiles,
        favoriteFiles,
        totalFileSize,
        totalDownloads,
        filesByType,
        fileUploadTrend,
        fileTypeDistribution,
        fileSizeByType,

        // Events
        totalEvents,
        upcomingEvents,
        pastEvents,
        meetingEvents,
        reminderEvents,
        personalEvents,
        workEvents,
        eventsByCategory,
        eventCreationTrend,
        eventTypeDistribution,
        eventStatusDistribution,

        // Overall
        totalItems,
        lastUpdated,
        selectedPeriod,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalyticsModel &&
        other.totalTasks == totalTasks &&
        other.completedTasks == completedTasks &&
        other.pendingTasks == pendingTasks &&
        other.overdueTasks == overdueTasks &&
        other.highPriorityTasks == highPriorityTasks &&
        other.mediumPriorityTasks == mediumPriorityTasks &&
        other.lowPriorityTasks == lowPriorityTasks &&
        other.tasksByCategory == tasksByCategory &&
        other.taskCompletionTrend == taskCompletionTrend &&
        other.taskStatusDistribution == taskStatusDistribution &&
        other.taskPriorityDistribution == taskPriorityDistribution &&
        other.taskCompletionRate == taskCompletionRate &&
        other.totalNotes == totalNotes &&
        other.draftNotes == draftNotes &&
        other.publishedNotes == publishedNotes &&
        other.textNotes == textNotes &&
        other.checklistNotes == checklistNotes &&
        other.encryptedNotes == encryptedNotes &&
        other.favoriteNotes == favoriteNotes &&
        other.totalWordCount == totalWordCount &&
        other.averageReadingTime == averageReadingTime &&
        other.notesByCategory == notesByCategory &&
        other.noteCreationTrend == noteCreationTrend &&
        other.noteTypeDistribution == noteTypeDistribution &&
        other.noteStatusDistribution == noteStatusDistribution &&
        other.totalFiles == totalFiles &&
        other.imageFiles == imageFiles &&
        other.documentFiles == documentFiles &&
        other.videoFiles == videoFiles &&
        other.audioFiles == audioFiles &&
        other.archiveFiles == archiveFiles &&
        other.encryptedFiles == encryptedFiles &&
        other.favoriteFiles == favoriteFiles &&
        other.totalFileSize == totalFileSize &&
        other.totalDownloads == totalDownloads &&
        other.filesByType == filesByType &&
        other.fileUploadTrend == fileUploadTrend &&
        other.fileTypeDistribution == fileTypeDistribution &&
        other.fileSizeByType == fileSizeByType &&
        other.totalEvents == totalEvents &&
        other.upcomingEvents == upcomingEvents &&
        other.pastEvents == pastEvents &&
        other.meetingEvents == meetingEvents &&
        other.reminderEvents == reminderEvents &&
        other.personalEvents == personalEvents &&
        other.workEvents == workEvents &&
        other.eventsByCategory == eventsByCategory &&
        other.eventCreationTrend == eventCreationTrend &&
        other.eventTypeDistribution == eventTypeDistribution &&
        other.eventStatusDistribution == eventStatusDistribution &&
        other.totalItems == totalItems &&
        other.lastUpdated == lastUpdated &&
        other.selectedPeriod == selectedPeriod;
  }

  @override
  int get hashCode => Object.hash(
        totalTasks,
        completedTasks,
        pendingTasks,
        overdueTasks,
        highPriorityTasks,
        mediumPriorityTasks,
        lowPriorityTasks,
        totalNotes,
        totalFiles,
        totalEvents,
        lastUpdated,
        selectedPeriod,
      );
        taskCompletionTrend,
        taskStatusDistribution,
        taskPriorityDistribution,
        taskCompletionRate,
        totalNotes,
        draftNotes,
        publishedNotes,
        textNotes,
        checklistNotes,
        encryptedNotes,
        favoriteNotes,
        totalWordCount,
        averageReadingTime,
        notesByCategory,
        noteCreationTrend,
        noteTypeDistribution,
        noteStatusDistribution,
        totalFiles,
        imageFiles,
        documentFiles,
        videoFiles,
        audioFiles,
        archiveFiles,
        encryptedFiles,
        favoriteFiles,
        totalFileSize,
        totalDownloads,
        filesByType,
        fileUploadTrend,
        fileTypeDistribution,
        fileSizeByType,
        totalEvents,
        upcomingEvents,
        pastEvents,
        meetingEvents,
        reminderEvents,
        personalEvents,
        workEvents,
        eventsByCategory,
        eventCreationTrend,
        eventTypeDistribution,
        eventStatusDistribution,
        totalItems,
        lastUpdated,
        selectedPeriod,
      );
}
