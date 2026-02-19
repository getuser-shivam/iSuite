import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/ui_helper.dart';
import '../providers/task_automation_provider.dart';
import '../providers/task_provider.dart';
import '../../domain/models/task.dart';

/// AI-powered task automation and smart scheduling widget
class TaskAutomationWidget extends StatefulWidget {
  const TaskAutomationWidget({super.key});

  @override
  State<TaskAutomationWidget> createState() => _TaskAutomationWidgetState();
}

class _TaskAutomationWidgetState extends State<TaskAutomationWidget> {
  bool _isExpanded = false;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TaskAutomationProvider, TaskProvider>(
      builder: (context, automationProvider, taskProvider, child) {
        return Card(
          margin: EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppConstants.cardRadius),
                    bottom: Radius.zero,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: AppConstants.largeIconSize,
                    ),
                    SizedBox(width: AppConstants.defaultSpacing),
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
              SizedBox(height: AppConstants.defaultSpacing),
              
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
        );
      },
    );
  }

  Widget _buildSuggestionCard(BuildContext context, Task task, TaskAutomationProvider automationProvider) {
    return Card(
      margin: EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        contentPadding: EdgeInsets.all(AppConstants.defaultPadding),
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
            SizedBox(height: AppConstants.smallSpacing),
            Text(
              task.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: AppConstants.smallIconSize,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                SizedBox(width: AppConstants.smallSpacing),
                Text(
                  '${task.estimatedTime} min',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppConstants.smallSpacing),
            Wrap(
              spacing: AppConstants.smallSpacing,
              runSpacing: AppConstants.smallSpacing,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.smallPadding,
                    vertical: AppConstants.extraSmallPadding,
                  ),
                  decoration: BoxDecoration(
                    color: task.priority.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                  ),
                  child: Text(
                    task.priority.name.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (task.isRecurring) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.smallPadding,
                      vertical: AppConstants.extraSmallPadding,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                    ),
                    child: Text(
                      'RECURRING',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => automationProvider.acceptAutomatedTask(task),
              tooltip: 'Accept suggestion',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => automationProvider.rejectAutomatedTask(task),
              tooltip: 'Reject suggestion',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateNewSuggestions(TaskProvider taskProvider) async {
    await automationProvider.generateAutomatedTasks(taskProvider.tasks);
  }

  Future<void> _acceptAllSuggestions(TaskProvider taskProvider, TaskAutomationProvider automationProvider) async {
    for (final task in automationProvider.automatedTasks) {
      await automationProvider.acceptAutomatedTask(task);
      // Add to actual task list
      await taskProvider.createTask(task);
    }
    
    UIHelper.showSuccessSnackBar(
      // ignore: use_build_context_synchronously
      null,
      'Accepted ${automationProvider.automatedTasks.length} suggestions',
    );
  }

  Future<void> _rejectAllSuggestions(TaskAutomationProvider automationProvider) async {
    for (final task in automationProvider.automatedTasks) {
      automationProvider.rejectAutomatedTask(task);
    }
    
    UIHelper.showInfoSnackBar(
      // ignore: use_build_context_synchronously
      null,
      'Rejected ${automationProvider.automatedTasks.length} suggestions',
    );
  }

  void _clearAllSuggestions(TaskAutomationProvider automationProvider) {
    automationProvider.clearAutomatedTasks();
    
    UIHelper.showInfoSnackBar(
      // ignore: use_build_context_synchronously
      null,
      'Cleared all suggestions',
    );
  }
}
