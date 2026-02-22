import 'package:flutter/material.dart';
import '../../core/central_config.dart';
import '../../core/component_factory.dart';
import '../../core/utils.dart';
import '../../data/repositories/task_repository.dart';
import '../../domain/models/task.dart';

class TaskProvider extends ChangeNotifier implements ParameterizedComponent {
  TaskProvider() {
    _initializeFromConfig();
    loadTasks();
  }
  Future<void> _initializeFromConfig() async {
    await CentralConfig.instance.initialize();

    // Update parameters from central config
    _maxTasksPerPage =
        CentralConfig.instance.getParameter('max_tasks_per_page', 50);
    _enableTaskSuggestions =
        CentralConfig.instance.getParameter('enable_task_suggestions', true);
    _autoSaveInterval = CentralConfig.instance
        .getParameter('auto_save_interval', Duration(minutes: 5));
    _taskHistoryLimit =
        CentralConfig.instance.getParameter('task_history_limit', 1000);
    _enableTaskRecurrence =
        CentralConfig.instance.getParameter('enable_task_recurrence', true);
  }

  // Parameterized component implementation
  @override
  void updateParameters(Map<String, dynamic> parameters) {
    for (final entry in parameters.entries) {
      switch (entry.key) {
        case 'max_tasks_per_page':
          _maxTasksPerPage = entry.value as int;
          break;
        case 'enable_task_suggestions':
          _enableTaskSuggestions = entry.value as bool;
          break;
        case 'auto_save_interval':
          _autoSaveInterval = entry.value as Duration;
          break;
        case 'task_history_limit':
          _taskHistoryLimit = entry.value as int;
          break;
        case 'enable_task_recurrence':
          _enableTaskRecurrence = entry.value as bool;
          break;
      }
    }
    notifyListeners();
  }

  // Private fields with defaults from config
  int _maxTasksPerPage = 50;
  bool _enableTaskSuggestions = true;
  Duration _autoSaveInterval = Duration(minutes: 5);
  int _taskHistoryLimit = 1000;
  bool _enableTaskRecurrence = true;
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  TaskStatus _selectedStatus = TaskStatus.todo;
  TaskCategory _selectedCategory = TaskCategory.work;
  TaskPriority _selectedPriority = TaskPriority.medium;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;
  bool _isGridView = true;
  SortOption _sortBy = SortOption.createdAt;
  bool _sortAscending = false;

  // Getters
  List<Task> get tasks => _tasks;
  List<Task> get filteredTasks => _filteredTasks;
  TaskStatus get selectedStatus => _selectedStatus;
  TaskCategory get selectedCategory => _selectedCategory;
  TaskPriority get selectedPriority => _selectedPriority;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isGridView => _isGridView;
  SortOption get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  // Computed properties
  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((task) => task.isCompleted).length;
  int get pendingTasks => _tasks.where((task) => !task.isCompleted).length;
  int get overdueTasks => _tasks.where((task) => task.isOverdue).length;
  int get dueTodayTasks => _tasks.where((task) => task.isDueToday).length;

  double get completionRate {
    if (_tasks.isEmpty) return 0;
    return completedTasks / _tasks.length;
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await TaskRepository.getAllTasks();
      _applyFiltersAndSort();
    } catch (e) {
      _error = 'Failed to load tasks: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTask({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    TaskCategory category = TaskCategory.work,
    DateTime? dueDate,
    List<String> tags = const [],
    int? estimatedMinutes,
    bool isRecurring = false,
    String? recurrencePattern,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final task = Task(
        id: AppUtils.generateRandomId(),
        title: title.trim(),
        description: description?.trim(),
        priority: priority,
        category: category,
        dueDate: dueDate,
        createdAt: DateTime.now(),
        tags: tags,
        userId: CentralConfig.instance
            .getParameter('current_user_id', 'default_user'),
        isRecurring: isRecurring,
        recurrencePattern: recurrencePattern,
        estimatedMinutes: estimatedMinutes,
      );

      await TaskRepository.createTask(task);
      _tasks.insert(0, task);
      _applyFiltersAndSort();

      _error = null;
    } catch (e) {
      _error = 'Failed to create task: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTask(Task task) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await TaskRepository.updateTask(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
      }
      _applyFiltersAndSort();

      _error = null;
    } catch (e) {
      _error = 'Failed to update task: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await TaskRepository.deleteTask(taskId);
      _tasks.removeWhere((task) => task.id == taskId);
      _applyFiltersAndSort();

      _error = null;
    } catch (e) {
      _error = 'Failed to delete task: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(
      status: task.isCompleted ? TaskStatus.todo : TaskStatus.completed,
      completedAt: task.isCompleted ? null : DateTime.now(),
      actualMinutes: task.isCompleted ? null : task.estimatedMinutes,
    );

    await updateTask(updatedTask);
  }

  Future<void> markTaskInProgress(Task task) async {
    if (task.status == TaskStatus.inProgress) return;

    final updatedTask = task.copyWith(status: TaskStatus.inProgress);
    await updateTask(updatedTask);
  }

  Future<void> deleteCompletedTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final completedTaskIds = _tasks
          .where((task) => task.isCompleted)
          .map((task) => task.id)
          .toList();

      for (final taskId in completedTaskIds) {
        await TaskRepository.deleteTask(taskId);
      }

      _tasks.removeWhere((task) => task.isCompleted);
      _applyFiltersAndSort();

      _error = null;
    } catch (e) {
      _error = 'Failed to delete completed tasks: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStatusFilter(TaskStatus status) {
    _selectedStatus = status;
    _applyFiltersAndSort();
  }

  void setCategoryFilter(TaskCategory category) {
    _selectedCategory = category;
    _applyFiltersAndSort();
  }

  void setPriorityFilter(TaskPriority priority) {
    _selectedPriority = priority;
    _applyFiltersAndSort();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFiltersAndSort();
  }

  void clearFilters() {
    _selectedStatus = TaskStatus.todo;
    _selectedCategory = TaskCategory.work;
    _selectedPriority = TaskPriority.medium;
    _searchQuery = '';
    _applyFiltersAndSort();
  }

  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  void setSortOption(SortOption sortBy, {bool ascending = false}) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    _filteredTasks = _tasks.where((task) {
      // Status filter
      if (_selectedStatus != TaskStatus.todo &&
          task.status != _selectedStatus) {
        return false;
      }

      // Category filter
      if (_selectedCategory != TaskCategory.other &&
          task.category != _selectedCategory) {
        return false;
      }

      // Priority filter
      if (_selectedPriority != TaskPriority.medium &&
          task.priority != _selectedPriority) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final titleMatch = task.title.toLowerCase().contains(query);
        final descriptionMatch =
            task.description?.toLowerCase().contains(query) ?? false;
        final tagsMatch =
            task.tags.any((tag) => tag.toLowerCase().contains(query));

        if (!titleMatch && !descriptionMatch && !tagsMatch) {
          return false;
        }
      }

      return true;
    }).toList();

    // Apply sorting
    _filteredTasks.sort((a, b) {
      var comparison = 0;

      switch (_sortBy) {
        case SortOption.title:
          comparison = a.title.compareTo(b.title);
          break;
        case SortOption.priority:
          comparison = b.priority.value.compareTo(a.priority.value);
          break;
        case SortOption.dueDate:
          if (a.dueDate == null && b.dueDate == null) {
            comparison = 0;
          } else if (a.dueDate == null) {
            comparison = 1;
          } else if (b.dueDate == null) {
            comparison = -1;
          } else {
            comparison = a.dueDate!.compareTo(b.dueDate!);
          }
          break;
        case SortOption.createdAt:
          comparison = b.createdAt.compareTo(a.createdAt);
          break;
        case SortOption.status:
          comparison = a.status.name.compareTo(b.status.name);
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });

    notifyListeners();
  }

  Future<void> refreshTasks() async {
    await loadTasks();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Statistics methods
  Map<TaskCategory, int> getTasksByCategory() {
    final categoryCount = <TaskCategory, int>{};
    for (final category in TaskCategory.values) {
      categoryCount[category] =
          _tasks.where((task) => task.category == category).length;
    }
    return categoryCount;
  }

  Map<TaskPriority, int> getTasksByPriority() {
    final priorityCount = <TaskPriority, int>{};
    for (final priority in TaskPriority.values) {
      priorityCount[priority] =
          _tasks.where((task) => task.priority == priority).length;
    }
    return priorityCount;
  }

  Map<TaskStatus, int> getTasksByStatus() {
    final statusCount = <TaskStatus, int>{};
    for (final status in TaskStatus.values) {
      statusCount[status] =
          _tasks.where((task) => task.status == status).length;
    }
    return statusCount;
  }

  List<Task> getTasksForDateRange(DateTime start, DateTime end) =>
      _tasks.where((task) {
        if (task.dueDate == null) return false;
        return task.dueDate!.isAfter(start) && task.dueDate!.isBefore(end);
      }).toList();

  // Get configuration parameters
  Map<String, dynamic> getConfigurationParameters() {
    return {
      'max_tasks_per_page': _maxTasksPerPage,
      'enable_task_suggestions': _enableTaskSuggestions,
      'auto_save_interval': _autoSaveInterval,
      'task_history_limit': _taskHistoryLimit,
      'enable_task_recurrence': _enableTaskRecurrence,
    };
  }
}

enum SortOption {
  title('Title'),
  priority('Priority'),
  dueDate('Due Date'),
  createdAt('Created At'),
  status('Status');

  const SortOption(this.label);
  final String label;
}
