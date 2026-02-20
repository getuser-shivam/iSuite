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
  final bool _isExpanded = false;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Consumer2<TaskAutomationProvider, TaskProvider>(
      builder: (context, automationProvider, taskProvider, child) {
        return Card(
          margin: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppConstants.cardRadius),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: AppConstants.largeIconSize,
                    ),
                    const SizedBox(width: AppConstants.defaultSpacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Task Automation',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Smart task suggestions based on your patterns',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.defaultSpacing),
              
              // Automation Insights
              if (automationProvider.automatedTasks.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI-Powered Suggestions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: AppConstants.defaultSpacing),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                        ),
                        child: ListView.builder(
                          controller: _scrollController,
                          shrinkWrap: true,
                          itemCount: automationProvider.automatedTasks.length,
                          itemBuilder: (context, index) {
                            final task = automationProvider.automatedTasks[index];
                            return _buildSuggestionCard(context, Task, automationProvider);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Action Buttons
              Container(
                padding: EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: automationProvider.isProcessing 
                                ? null 
                                : () => _generateNewSuggestions(taskProvider),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Generate Suggestions'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: AppConstants.defaultPadding,
                                vertical: AppConstants.smallPadding,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: AppConstants.defaultSpacing),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: automationProvider.automatedTasks.isEmpty 
                                ? null 
                                : () => _acceptAllSuggestions(taskProvider, automationProvider),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Accept All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: AppConstants.defaultPadding,
                                vertical: AppConstants.smallPadding,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppConstants.defaultSpacing),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: automationProvider.automatedTasks.isEmpty 
                                ? null 
                                : () => _rejectAllSuggestions(automationProvider),
                            icon: const Icon(Icons.close),
                            label: const Text('Reject All'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).primaryColor,
                              side: BorderSide(color: Theme.of(context).primaryColor),
                              padding: EdgeInsets.symmetric(
                                horizontal: AppConstants.defaultPadding,
                                vertical: AppConstants.smallPadding,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: AppConstants.defaultSpacing),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _clearAllSuggestions(automationProvider),
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear All'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: BorderSide(color: Colors.orange),
                              padding: EdgeInsets.symmetric(
                                horizontal: AppConstants.defaultPadding,
                                vertical: AppConstants.smallPadding,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );,
    );
  }

  Widget _buildSuggestionCard(BuildContext context, Task task, TaskAutomationProvider automationProvider) => Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppConstants.defaultPadding),
        leading: Container(
          width: AppConstants.avatarSize,
          height: AppConstants.avatarSize,
          decoration: BoxDecoration(
            color: task.category.color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            task.category.icon,
            color: task.category.color,
            size: AppConstants.iconSize,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              task.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.smallSpacing),
            Text(
              task.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
          ],
        ),
      );
    },
  );
}

Widget _buildVoiceStatus(TaskAutomationProvider provider) {
  return Container(
    padding: EdgeInsets.all(AppConstants.defaultPadding),
    decoration: BoxDecoration(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    ),
    child: Row(
      children: [
        Icon(
          Icons.mic,
          size: AppConstants.largeIconSize,
          color: provider.isListening 
            ? Colors.red.withValues(alpha: 0.8)
            : Theme.of(context).primaryColor,
        ),
        const SizedBox(width: AppConstants.defaultSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.isListening ? 'Listening...' : 'Voice Assistant',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: provider.isListening 
                    ? Colors.red
                    : Theme.of(context).primaryColor,
                ),
              ),
              if (provider.currentSession != null)
                Text(
                  'Confidence: ${(provider.currentSession!.confidence * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildVoiceButton(TaskAutomationProvider provider) {
  return GestureDetector(
    onTap: () {
      if (provider.isListening) {
        provider.stopListening();
      } else {
        provider.startListening();
      }
    },
    child: Container(
      width: AppConstants.fabSize,
      height: AppConstants.fabSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: provider.isListening 
          ? Colors.red.withValues(alpha: 0.8)
          : Theme.of(context).primaryColor.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: AppConstants.cardRadius,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        provider.isListening ? Icons.stop : Icons.mic,
        color: Colors.white,
        size: AppConstants.iconSize,
      ),
    ),
  );
}

Widget _buildCommandHistory(TaskAutomationProvider provider) {
  return Container(
    height: 200,
    child: ListView.builder(
      itemCount: provider.commandHistory.length,
      itemBuilder: (context, index) {
        final command = provider.commandHistory[index];
        return ListTile(
          title: command.action,
          subtitle: 'Confidence: ${(command.confidence * 100).toStringAsFixed(0)}%',
          trailing: IconButton(
            icon: Icons.delete,
            onPressed: () => _deleteCommand(index),
          ),
        );
      },
    ),
  );
}

Widget _buildLastResponse(TaskAutomationProvider provider) {
  return Container(
    padding: EdgeInsets.all(AppConstants.defaultPadding),
    margin: const EdgeInsets.only(top: AppConstants.smallPadding),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    ),
    child: Text(
      provider.lastResponse ?? 'No response yet',
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  );
}

void _deleteCommand(int index) {
  // Implementation for deleting command from history
}

void _acceptSuggestion(Task task, TaskAutomationProvider automationProvider) async {
    await automationProvider.acceptAutomatedTask(task);
    UIHelper.showSuccessSnackBar(
      // ignore: use_build_context_synchronously
      null,
      'Accepted ${automationProvider.automatedTasks.length} suggestions',
    );
  }

  void _rejectSuggestion(Task task, TaskAutomationProvider automationProvider) async {
    await automationProvider.rejectAutomatedTask(task);
    UIHelper.showInfoSnackBar(
      // ignore: use_build_context_synchronously
      null,
      'Rejected suggestion',
    );
  }

  void _clearAllSuggestions(TaskAutomationProvider automationProvider) async {
    automationProvider.clearAutomatedTasks();
    UIHelper.showInfoSnackBar(
      // ignore: use_build_context_synchronously
      null,
      'Cleared all suggestions',
    );
  }

  Future<void> _generateNewSuggestions(TaskProvider taskProvider) async {
    await automationProvider.generateAutomatedTasks(taskProvider.tasks);
  }
}
