import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/ui_helper.dart';

/// AI-powered task suggestions provider
class TaskSuggestionProvider extends ChangeNotifier {
  List<String> _suggestions = [];
  bool _isLoading = false;

  List<String> get suggestions => _suggestions;
  bool get isLoading => _isLoading;

  /// Generate AI-powered task suggestions based on user patterns
  Future<void> generateSuggestions(String input) async {
    if (input.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Simulate AI suggestion generation
      await Future.delayed(AppConstants.mediumAnimation);

      _suggestions = _generateMockSuggestions(input);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      UIHelper.showErrorSnackBar(
        // ignore: use_build_context_synchronously
        null,
        'Failed to generate suggestions',
      );
    }
  }

  List<String> _generateMockSuggestions(String input) {
    final lowerInput = input.toLowerCase();
    final suggestions = <String>[];

    // Time-based suggestions
    if (lowerInput.contains('meeting') || lowerInput.contains('call')) {
      suggestions.addAll([
        'Schedule follow-up meeting',
        'Prepare meeting agenda',
        'Set reminder for meeting',
        'Share meeting notes',
      ]);
    }

    // Task completion patterns
    if (lowerInput.contains('complete') || lowerInput.contains('done')) {
      suggestions.addAll([
        'Mark related tasks as complete',
        'Update project progress',
        'Notify team members',
        'Archive completed tasks',
      ]);
    }

    // Priority-based suggestions
    if (lowerInput.contains('urgent') || lowerInput.contains('important')) {
      suggestions.addAll([
        'Set high priority',
        'Add deadline reminder',
        'Block time for focused work',
        'Minimize distractions',
      ]);
    }

    // General productivity suggestions
    suggestions.addAll([
      'Break down into smaller tasks',
      'Set time estimates',
      'Add subtasks',
      'Create recurring task',
      'Schedule review session',
    ]);

    return suggestions.take(5).toList();
  }

  void clearSuggestions() {
    _suggestions.clear();
    notifyListeners();
  }

  void selectSuggestion(String suggestion) {
    // Remove selected suggestion and add to task input
    _suggestions.remove(suggestion);
    notifyListeners();
  }
}
