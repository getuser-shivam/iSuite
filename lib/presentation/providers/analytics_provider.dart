import 'package:flutter/material.dart';
import '../../domain/models/analytics.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../core/utils.dart';

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsModel? _analytics;
  bool _isLoading = false;
  String? _error;
  TimePeriod _selectedPeriod = TimePeriod.month;

  // Getters
  AnalyticsModel? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  TimePeriod get selectedPeriod => _selectedPeriod;

  // Computed properties
  bool get hasData => _analytics != null && _analytics!.hasData;
  double get productivityScore => _analytics?.productivityScore ?? 0.0;
  String get formattedTotalFileSize => _analytics?.formattedTotalFileSize ?? '0 B';

  AnalyticsProvider() {
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppUtils.logInfo('Loading analytics data...', tag: 'AnalyticsProvider');
      _analytics = await AnalyticsRepository.getAnalytics(period: _selectedPeriod);
      AppUtils.logInfo('Analytics data loaded successfully', tag: 'AnalyticsProvider');
      _error = null;
    } catch (e) {
      _error = 'Failed to load analytics: ${e.toString()}';
      AppUtils.logError('Failed to load analytics', tag: 'AnalyticsProvider', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAnalytics({TimePeriod? period}) async {
    if (period != null && period != _selectedPeriod) {
      _selectedPeriod = period;
      await _loadAnalytics();
    } else {
      await _loadAnalytics();
    }
  }

  Future<void> setTimePeriod(TimePeriod period) async {
    if (period != _selectedPeriod) {
      _selectedPeriod = period;
      await _loadAnalytics();
    }
  }

  Future<void> refreshAnalytics() async {
    await _loadAnalytics();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper methods for accessing analytics data safely
  int get totalTasks => _analytics?.totalTasks ?? 0;
  int get completedTasks => _analytics?.completedTasks ?? 0;
  int get pendingTasks => _analytics?.pendingTasks ?? 0;
  int get overdueTasks => _analytics?.overdueTasks ?? 0;
  double get taskCompletionRate => _analytics?.taskCompletionRate ?? 0.0;

  int get totalNotes => _analytics?.totalNotes ?? 0;
  int get draftNotes => _analytics?.draftNotes ?? 0;
  int get publishedNotes => _analytics?.publishedNotes ?? 0;
  int get totalWordCount => _analytics?.totalWordCount ?? 0;
  int get averageReadingTime => _analytics?.averageReadingTime ?? 0;

  int get totalFiles => _analytics?.totalFiles ?? 0;
  double get totalFileSize => _analytics?.totalFileSize ?? 0.0;
  int get totalDownloads => _analytics?.totalDownloads ?? 0;

  int get totalEvents => _analytics?.totalEvents ?? 0;
  int get upcomingEvents => _analytics?.upcomingEvents ?? 0;
  int get pastEvents => _analytics?.pastEvents ?? 0;

  List<ChartDataPoint> get taskStatusDistribution => _analytics?.taskStatusDistribution ?? [];
  List<ChartDataPoint> get taskPriorityDistribution => _analytics?.taskPriorityDistribution ?? [];
  List<ChartDataPoint> get noteTypeDistribution => _analytics?.noteTypeDistribution ?? [];
  List<ChartDataPoint> get noteStatusDistribution => _analytics?.noteStatusDistribution ?? [];
  List<ChartDataPoint> get fileTypeDistribution => _analytics?.fileTypeDistribution ?? [];
  List<ChartDataPoint> get eventTypeDistribution => _analytics?.eventTypeDistribution ?? [];

  List<TimeSeriesData> get taskCompletionTrend => _analytics?.taskCompletionTrend ?? [];
  List<TimeSeriesData> get noteCreationTrend => _analytics?.noteCreationTrend ?? [];
  List<TimeSeriesData> get fileUploadTrend => _analytics?.fileUploadTrend ?? [];
  List<TimeSeriesData> get eventCreationTrend => _analytics?.eventCreationTrend ?? [];

  Map<String, int> get tasksByCategory => _analytics?.tasksByCategory ?? {};
  Map<String, int> get notesByCategory => _analytics?.notesByCategory ?? {};
  Map<String, int> get filesByType => _analytics?.filesByType ?? {};
  Map<String, int> get eventsByCategory => _analytics?.eventsByCategory ?? {};

  // Summary statistics
  Map<String, dynamic> get summaryStats => {
        'totalItems': _analytics?.totalItems ?? 0,
        'productivityScore': productivityScore,
        'mostActiveCategory': _getMostActiveCategory(),
        'mostUsedFeature': _getMostUsedFeature(),
        'growthRate': _calculateGrowthRate(),
      };

  String _getMostActiveCategory() {
    final categories = <String, int>{};

    tasksByCategory.forEach((key, value) => categories[key] = (categories[key] ?? 0) + value);
    notesByCategory.forEach((key, value) => categories[key] = (categories[key] ?? 0) + value);
    eventsByCategory.forEach((key, value) => categories[key] = (categories[key] ?? 0) + value);

    if (categories.isEmpty) return 'None';

    final sorted = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  String _getMostUsedFeature() {
    final features = {
      'Tasks': totalTasks,
      'Notes': totalNotes,
      'Files': totalFiles,
      'Events': totalEvents,
    };

    if (features.values.every((value) => value == 0)) return 'None';

    final sorted = features.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  double _calculateGrowthRate() {
    // Simple growth calculation based on recent trends
    // For now, return a mock value; in real implementation, compare with previous period
    final recentTasks = taskCompletionTrend.where((t) => t.date.isAfter(DateTime.now().subtract(const Duration(days: 7)))).toList();
    final previousTasks = taskCompletionTrend.where((t) => t.date.isAfter(DateTime.now().subtract(const Duration(days: 14))) && t.date.isBefore(DateTime.now().subtract(const Duration(days: 7)))).toList();

    if (recentTasks.isEmpty || previousTasks.isEmpty) return 0.0;

    final recentAvg = recentTasks.fold<double>(0, (sum, t) => sum + t.value) / recentTasks.length;
    final previousAvg = previousTasks.fold<double>(0, (sum, t) => sum + t.value) / previousTasks.length;

    if (previousAvg == 0) return recentAvg > 0 ? 100.0 : 0.0;

    return ((recentAvg - previousAvg) / previousAvg) * 100;
  }

  // Export methods for sharing analytics
  Future<String> exportAnalyticsAsJson() async {
    if (_analytics == null) return '{}';

    // Convert analytics to JSON format
    return '''
    {
      "summary": ${summaryStats.toString()},
      "tasks": {
        "total": $totalTasks,
        "completed": $completedTasks,
        "completionRate": $taskCompletionRate
      },
      "notes": {
        "total": $totalNotes,
        "published": $publishedNotes,
        "wordCount": $totalWordCount
      },
      "files": {
        "total": $totalFiles,
        "totalSize": $totalFileSize,
        "downloads": $totalDownloads
      },
      "events": {
        "total": $totalEvents,
        "upcoming": $upcomingEvents
      },
      "exportedAt": "${DateTime.now().toIso8601String()}"
    }
    ''';
  }
}
