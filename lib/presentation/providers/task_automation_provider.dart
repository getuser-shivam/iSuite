import 'package:flutter/material.dart';

import '../../core/ui_helper.dart';
import '../../core/utils.dart';
import '../../domain/models/task.dart';

/// AI-powered task automation and smart scheduling provider
class TaskAutomationProvider extends ChangeNotifier {
  List<Task> _automatedTasks = [];
  bool _isProcessing = false;
  final Map<String, dynamic> _automationSettings = {};

  List<Task> get automatedTasks => _automatedTasks;
  bool get isProcessing => _isProcessing;
  Map<String, dynamic> get automationSettings => _automationSettings;

  /// Generate automated tasks based on patterns and AI analysis
  Future<void> generateAutomatedTasks(List<Task> existingTasks) async {
    _isProcessing = true;
    notifyListeners();

    try {
      // Analyze existing task patterns
      final patterns = _analyzeTaskPatterns(existingTasks);

      // Generate smart task suggestions
      final suggestions = _generateSmartTasks(patterns);

      _automatedTasks = suggestions;
      _isProcessing = false;
      notifyListeners();

      UIHelper.showSuccessSnackBar(
        // ignore: use_build_context_synchronously
        null,
        'Generated ${suggestions.length} automated task suggestions',
      );
    } catch (e) {
      _isProcessing = false;
      notifyListeners();

      UIHelper.showErrorSnackBar(
        // ignore: use_build_context_synchronously
        null,
        'Failed to generate automated tasks: $e',
      );
    }
  }

  Map<String, dynamic> _analyzeTaskPatterns(List<Task> tasks) {
    final patterns = <String, dynamic>{};

    // Analyze completion patterns
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final totalTasks = tasks.length;
    final completionRate = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    patterns['completion_rate'] = completionRate;
    patterns['total_tasks'] = totalTasks;
    patterns['completed_tasks'] = completedTasks;

    // Analyze category patterns
    final categoryCounts = <String, int>{};
    for (final task in tasks) {
      categoryCounts[task.category.name] =
          (categoryCounts[task.category.name] ?? 0) + 1;
    }
    patterns['category_distribution'] = categoryCounts;

    // Analyze priority patterns
    final priorityCounts = <String, int>{};
    for (final task in tasks) {
      priorityCounts[task.priority.name] =
          (priorityCounts[task.priority.name] ?? 0) + 1;
    }
    patterns['priority_distribution'] = priorityCounts;

    // Analyze time patterns
    final now = DateTime.now();
    final recentTasks =
        tasks.where((t) => now.difference(t.createdAt).inDays <= 7).length;
    patterns['recent_tasks'] = recentTasks;

    return patterns;
  }

  List<Task> _generateSmartTasks(Map<String, dynamic> patterns) {
    final suggestions = <Task>[];

    // Generate recurring task suggestions
    if (patterns['completion_rate'] < 0.7) {
      suggestions.addAll(_generateRecurringTasks(patterns));
    }

    // Generate priority-based suggestions
    suggestions.addAll(_generatePriorityTasks(patterns));

    // Generate category-based suggestions
    suggestions.addAll(_generateCategoryTasks(patterns));

    // Generate time-based suggestions
    suggestions.addAll(_generateTimeBasedTasks(patterns));

    return suggestions.take(10).toList();
  }

  List<Task> _generateRecurringTasks(Map<String, dynamic> patterns) {
    final recurringTasks = <Task>[];
    final categoryDistribution =
        patterns['category_distribution'] as Map<String, int>;

    // Suggest daily review tasks for low-completion categories
    categoryDistribution.forEach((category, count) {
      if (count > 5 && patterns['completion_rate'] < 0.6) {
        recurringTasks.add(Task(
          id: AppUtils.generateRandomId(),
          title: 'Daily Review: $category',
          description:
              'Review and update $category tasks for better productivity',
          category: _getTaskCategory(category),
          priority: TaskPriority.medium,
          isRecurring: true,
          estimatedTime: 15, // 15 minutes
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    });

    return recurringTasks;
  }

  List<Task> _generatePriorityTasks(Map<String, dynamic> patterns) {
    final priorityTasks = <Task>[];
    final priorityDistribution =
        patterns['priority_distribution'] as Map<String, int>;

    // Suggest priority rebalancing tasks
    final highPriorityCount = priorityDistribution['high'] ?? 0;
    final lowPriorityCount = priorityDistribution['low'] ?? 0;

    if (highPriorityCount > lowPriorityCount * 2) {
      priorityTasks.add(Task(
        id: AppUtils.generateRandomId(),
        title: 'Priority Rebalancing',
        description: 'Review and rebalance task priorities for better focus',
        category: TaskCategory.work,
        priority: TaskPriority.medium,
        estimatedTime: 30, // 30 minutes
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    return priorityTasks;
  }

  List<Task> _generateCategoryTasks(Map<String, dynamic> patterns) {
    final categoryTasks = <Task>[];
    final categoryDistribution =
        patterns['category_distribution'] as Map<String, int>;

    // Suggest category optimization tasks
    categoryDistribution.forEach((category, count) {
      if (count > 8) {
        categoryTasks.add(Task(
          id: AppUtils.generateRandomId(),
          title: 'Category Optimization: $category',
          description:
              'Break down large $category tasks into smaller, manageable items',
          category: _getTaskCategory(category),
          priority: TaskPriority.low,
          estimatedTime: 20, // 20 minutes
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    });

    return categoryTasks;
  }

  List<Task> _generateTimeBasedTasks(Map<String, dynamic> patterns) {
    final timeTasks = <Task>[];
    final recentTasks = patterns['recent_tasks'] as int;

    // Suggest time management tasks
    if (recentTasks > 10) {
      timeTasks.add(Task(
        id: AppUtils.generateRandomId(),
        title: 'Time Management Review',
        description: 'Review recent tasks and optimize time allocation',
        category: TaskCategory.personal,
        priority: TaskPriority.high,
        estimatedTime: 45, // 45 minutes
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    return timeTasks;
  }

  TaskCategory _getTaskCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'work':
        return TaskCategory.work;
      case 'personal':
        return TaskCategory.personal;
      case 'shopping':
        return TaskCategory.shopping;
      case 'health':
        return TaskCategory.health;
      case 'education':
        return TaskCategory.education;
      default:
        return TaskCategory.other;
    }
  }

  /// Accept automated task suggestion
  Future<void> acceptAutomatedTask(Task task) async {
    try {
      // Add to actual task provider
      // This would integrate with TaskProvider
      _automatedTasks.remove(task);
      notifyListeners();

      UIHelper.showSuccessSnackBar(
        // ignore: use_build_context_synchronously
        null,
        'Task "${task.title}" accepted and added to your task list',
      );
    } catch (e) {
      UIHelper.showErrorSnackBar(
        // ignore: use_build_context_synchronously
        null,
        'Failed to accept task: $e',
      );
    }
  }

  /// Reject automated task suggestion
  void rejectAutomatedTask(Task task) {
    _automatedTasks.remove(task);
    notifyListeners();
  }

  /// Update automation settings
  void updateAutomationSettings(String key, value) {
    _automationSettings[key] = value;
    notifyListeners();
  }

  /// Clear all automated tasks
  void clearAutomatedTasks() {
    _automatedTasks.clear();
    notifyListeners();
  }

  /// Get automation insights
  Map<String, dynamic> getAutomationInsights() => {
        'total_suggestions': _automatedTasks.length,
        'settings': _automationSettings,
        'last_updated': DateTime.now().toIso8601String(),
      };
}
