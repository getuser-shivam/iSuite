import 'package:flutter/material.dart';
import '../../domain/models/reminder.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../core/utils.dart';
import '../../core/notification_service.dart';

class ReminderProvider extends ChangeNotifier {
  List<ReminderModel> _reminders = [];
  bool _isLoading = false;
  String? _error;
  ReminderStatus _filterStatus = ReminderStatus.active;
  ReminderPriority _filterPriority = ReminderPriority.medium;
  String _searchQuery = '';

  List<ReminderModel> get reminders => _filteredReminders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ReminderStatus get filterStatus => _filterStatus;
  ReminderPriority get filterPriority => _filterPriority;
  String get searchQuery => _searchQuery;

  // Notification methods
  Future<void> _scheduleReminderNotification(ReminderModel reminder) async {
    if (reminder.isCompleted || reminder.dueDate == null) return;

    try {
      await NotificationService().scheduleReminderNotification(
        id: reminder.id.hashCode,
        title: reminder.title,
        body: reminder.description ?? 'Reminder due',
        scheduledTime: reminder.dueDate!,
        payload: 'reminder_${reminder.id}',
      );
    } catch (e) {
      AppUtils.logError('ReminderProvider', 'Failed to schedule notification', e);
    }
  }

  Future<void> _cancelReminderNotification(ReminderModel reminder) async {
    try {
      await NotificationService().cancelNotification(reminder.id.hashCode);
    } catch (e) {
      AppUtils.logError('ReminderProvider', 'Failed to cancel notification', e);
    }
  }

  // Computed properties
  List<ReminderModel> get allReminders => _reminders;
  List<ReminderModel> get activeReminders => _reminders.where((r) => r.isActive).toList();
  List<ReminderModel> get completedReminders => _reminders.where((r) => r.isCompleted).toList();
  List<ReminderModel> get overdueReminders => _reminders.where((r) => r.isOverdue).toList();
  List<ReminderModel> get upcomingReminders => _getUpcomingReminders(24); // Next 24 hours

  int get totalReminders => _reminders.length;
  int get activeCount => activeReminders.length;
  int get completedCount => completedReminders.length;
  int get overdueCount => overdueReminders.length;

  Map<ReminderPriority, int> get priorityCounts {
    final counts = <ReminderPriority, int>{};
    for (final reminder in activeReminders) {
      counts[reminder.priority] = (counts[reminder.priority] ?? 0) + 1;
    }
    return counts;
  }

  ReminderProvider() {
    loadReminders();
  }

  List<ReminderModel> get _filteredReminders {
    return _reminders.where((reminder) {
      // Status filter
      if (_filterStatus != ReminderStatus.active && reminder.status != _filterStatus) {
        return false;
      }

      // Priority filter (only for active reminders)
      if (_filterPriority != ReminderPriority.medium && reminder.priority != _filterPriority) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final titleMatch = reminder.title.toLowerCase().contains(query);
        final descriptionMatch = reminder.description?.toLowerCase().contains(query) ?? false;
        final tagsMatch = reminder.tags.any((tag) => tag.toLowerCase().contains(query));

        if (!titleMatch && !descriptionMatch && !tagsMatch) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  Future<void> loadReminders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppUtils.logInfo('Loading reminders...', tag: 'ReminderProvider');
      _reminders = await ReminderRepository.getAllReminders();
      AppUtils.logInfo('Reminders loaded: ${_reminders.length} reminders', tag: 'ReminderProvider');
    } catch (e) {
      _error = 'Failed to load reminders: ${e.toString()}';
      AppUtils.logError('Failed to load reminders', tag: 'ReminderProvider', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createReminder({
    required String title,
    String? description,
    required DateTime dueDate,
    ReminderRepeat repeat = ReminderRepeat.none,
    ReminderPriority priority = ReminderPriority.medium,
    List<String> tags = const [],
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppUtils.logInfo('Creating reminder: $title', tag: 'ReminderProvider');

      final reminder = ReminderModel(
        id: AppUtils.generateRandomId(),
        title: title,
        description: description,
        dueDate: dueDate,
        repeat: repeat,
        priority: priority,
        tags: tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ReminderRepository.createReminder(reminder);
      _reminders.add(reminder);

      // Schedule notification for the new reminder
      await _scheduleReminderNotification(reminder);

      AppUtils.logInfo('Reminder created: ${reminder.id}', tag: 'ReminderProvider');
    } catch (e) {
      _error = 'Failed to create reminder: ${e.toString()}';
      AppUtils.logError('Failed to create reminder', tag: 'ReminderProvider', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppUtils.logInfo('Updating reminder: ${reminder.id}', tag: 'ReminderProvider');

      final updatedReminder = reminder.copyWith(updatedAt: DateTime.now());

      // Cancel existing notification
      await _cancelReminderNotification(reminder);

      await ReminderRepository.updateReminder(updatedReminder);

      final index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        _reminders[index] = updatedReminder;
      }

      // Schedule new notification if needed
      await _scheduleReminderNotification(updatedReminder);

      AppUtils.logInfo('Reminder updated: ${reminder.id}', tag: 'ReminderProvider');
    } catch (e) {
      _error = 'Failed to update reminder: ${e.toString()}';
      AppUtils.logError('Failed to update reminder', tag: 'ReminderProvider', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteReminder(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppUtils.logInfo('Deleting reminder: $id', tag: 'ReminderProvider');

      // Find the reminder to cancel its notification
      final reminder = _reminders.firstWhere((r) => r.id == id);
      await _cancelReminderNotification(reminder);

      await ReminderRepository.deleteReminder(id);
      _reminders.removeWhere((r) => r.id == id);

      AppUtils.logInfo('Reminder deleted: $id', tag: 'ReminderProvider');
    } catch (e) {
      _error = 'Failed to delete reminder: ${e.toString()}';
      AppUtils.logError('Failed to delete reminder', tag: 'ReminderProvider', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markCompleted(String id) async {
    try {
      AppUtils.logInfo('Marking reminder completed: $id', tag: 'ReminderProvider');

      // Find the reminder to cancel its notification
      final reminder = _reminders.firstWhere((r) => r.id == id);
      await _cancelReminderNotification(reminder);

      await ReminderRepository.markCompleted(id);
      await loadReminders(); // Reload to get updated data

      AppUtils.logInfo('Reminder marked completed: $id', tag: 'ReminderProvider');
    } catch (e) {
      _error = 'Failed to mark reminder completed: ${e.toString()}';
      AppUtils.logError('Failed to mark reminder completed', tag: 'ReminderProvider', error: e);
      notifyListeners();
    }
  }

  Future<void> snoozeReminder(String id, Duration duration) async {
    try {
      AppUtils.logInfo('Snoozing reminder: $id for ${duration.inMinutes} minutes', tag: 'ReminderProvider');

      await ReminderRepository.snoozeReminder(id, duration);
      await loadReminders(); // Reload to get updated data

      AppUtils.logInfo('Reminder snoozed: $id', tag: 'ReminderProvider');
    } catch (e) {
      _error = 'Failed to snooze reminder: ${e.toString()}';
      AppUtils.logError('Failed to snooze reminder', tag: 'ReminderProvider', error: e);
      notifyListeners();
    }
  }

  Future<void> dismissReminder(String id) async {
    try {
      AppUtils.logInfo('Dismissing reminder: $id', tag: 'ReminderProvider');

      await ReminderRepository.dismissReminder(id);
      await loadReminders(); // Reload to get updated data

      AppUtils.logInfo('Reminder dismissed: $id', tag: 'ReminderProvider');
    } catch (e) {
      _error = 'Failed to dismiss reminder: ${e.toString()}';
      AppUtils.logError('Failed to dismiss reminder', tag: 'ReminderProvider', error: e);
      notifyListeners();
    }
  }

  void setFilterStatus(ReminderStatus status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setFilterPriority(ReminderPriority priority) {
    _filterPriority = priority;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _filterStatus = ReminderStatus.active;
    _filterPriority = ReminderPriority.medium;
    _searchQuery = '';
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  List<ReminderModel> _getUpcomingReminders(int hours) {
    final now = DateTime.now();
    final future = now.add(Duration(hours: hours));

    return _reminders.where((reminder) {
      return reminder.isActive &&
             reminder.dueDate.isAfter(now) &&
             reminder.dueDate.isBefore(future);
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  // Statistics
  Future<Map<String, int>> getReminderStats() async {
    try {
      return await ReminderRepository.getReminderStats();
    } catch (e) {
      AppUtils.logError('Failed to get reminder stats', error: e);
      return {};
    }
  }
}
