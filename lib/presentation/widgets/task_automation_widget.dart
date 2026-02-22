import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/ui_helper.dart';
import '../../domain/models/task.dart';
import '../providers/task_automation_provider.dart';
import '../providers/task_provider.dart';

/// AI-powered task automation and smart scheduling widget
class TaskAutomationWidget extends StatefulWidget {
  const TaskAutomationWidget({super.key});

  @override
  State<TaskAutomationWidget> createState() => _TaskAutomationWidgetState();
}

class _TaskAutomationWidgetState extends State<TaskAutomationWidget> {
  bool _isExpanded = false;
  final _scrollController = ScrollController();
  late TaskAutomationProvider _automationProvider;
  late TaskProvider _taskProvider;

  @override
  void initState() {
    super.initState();
    _automationProvider = Provider.of<TaskAutomationProvider>(context, listen: false);
    _taskProvider = Provider.of<TaskProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TaskAutomationProvider, TaskProvider>(
      builder: (context, automationProvider, taskProvider, child) {
        _automationProvider = automationProvider;
        _taskProvider = taskProvider;

        return Card(
          margin: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              // Header
              ListTile(
                leading: Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor),
                title: Text('AI Task Automation'),
                subtitle: Text('Smart suggestions and automation'),
                trailing: IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ),
              
              // Content
              if (_isExpanded) _buildExpandedContent(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // Automation Status
          _buildAutomationStatus(),
          
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Suggested Tasks
          _buildSuggestedTasks(),
          
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildAutomationStatus() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, color: Theme.of(context).primaryColor),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Automation Status',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  'AI is analyzing your tasks...',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: true, // TODO: Connect to provider
            onChanged: (value) {
              // TODO: Toggle automation
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedTasks() {
    final suggestions = _automationProvider.automatedTasks;
    
    if (suggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.lightbulb_outline, size: 48, color: Colors.grey),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                'No suggestions yet',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'AI will suggest tasks based on your patterns',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested Tasks',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppConstants.smallPadding),
        ...suggestions.map((task) => _buildSuggestionCard(task)),
      ],
    );
  }

  Widget _buildSuggestionCard(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (task.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.check, color: Colors.green),
                  onPressed: () => _acceptSuggestion(task),
                  tooltip: 'Accept',
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () => _rejectSuggestion(task),
                  tooltip: 'Reject',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _generateNewSuggestions,
            icon: Icon(Icons.refresh),
            label: Text('Generate Suggestions'),
          ),
        ),
        const SizedBox(width: AppConstants.smallPadding),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _clearAllSuggestions,
            icon: Icon(Icons.clear_all),
            label: Text('Clear All'),
          ),
        ),
      ],
    );
  }

  void _acceptSuggestion(Task task) async {
    try {
      await _automationProvider.acceptAutomatedTask(task);
      if (mounted) {
        UIHelper.showSuccessSnackBar(
          context,
          'Accepted suggestion: ${task.title}',
        );
      }
    } catch (e) {
      if (mounted) {
        UIHelper.showErrorSnackBar(
          context,
          'Failed to accept suggestion: $e',
        );
      }
    }
  }

  void _rejectSuggestion(Task task) async {
    try {
      await _automationProvider.rejectAutomatedTask(task);
      if (mounted) {
        UIHelper.showInfoSnackBar(
          context,
          'Rejected suggestion: ${task.title}',
        );
      }
    } catch (e) {
      if (mounted) {
        UIHelper.showErrorSnackBar(
          context,
          'Failed to reject suggestion: $e',
        );
      }
    }
  }

  void _generateNewSuggestions() async {
    try {
      await _automationProvider.generateAutomatedTasks(_taskProvider.tasks);
      if (mounted) {
        UIHelper.showSuccessSnackBar(
          context,
          'Generated new suggestions',
        );
      }
    } catch (e) {
      if (mounted) {
        UIHelper.showErrorSnackBar(
          context,
          'Failed to generate suggestions: $e',
        );
      }
    }
  }

  void _clearAllSuggestions() async {
    try {
      await _automationProvider.clearAutomatedTasks();
      if (mounted) {
        UIHelper.showInfoSnackBar(
          context,
          'Cleared all suggestions',
        );
      }
    } catch (e) {
      if (mounted) {
        UIHelper.showErrorSnackBar(
          context,
          'Failed to clear suggestions: $e',
        );
      }
    }
  }
}
