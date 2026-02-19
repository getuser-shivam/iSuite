import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reminder_provider.dart';
import '../../domain/models/reminder.dart';
import '../../core/utils.dart';
import '../../core/constants.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          IconButton(
            onPressed: () => _showCreateReminderDialog(context),
            icon: const Icon(Icons.add),
            tooltip: 'Add Reminder',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'filter',
                child: Text('Filter'),
              ),
              const PopupMenuItem(
                value: 'sort',
                child: Text('Sort'),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Text('Refresh'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ReminderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.loadReminders,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final reminders = provider.reminders;

          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No reminders found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateReminderDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Reminder'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.loadReminders,
            child: ListView(
              padding: EdgeInsets.all(AppConstants.defaultPadding),
              children: [
                // Overdue reminders section
                if (provider.overdueReminders.isNotEmpty) ...[
                  _buildSectionHeader('Overdue', Colors.red),
                  ...provider.overdueReminders.map((reminder) => _buildReminderCard(context, reminder, provider)),
                  const SizedBox(height: 16),
                ],

                // Active reminders section
                if (provider.activeReminders.isNotEmpty) ...[
                  _buildSectionHeader('Active', Colors.blue),
                  ...provider.activeReminders.map((reminder) => _buildReminderCard(context, reminder, provider)),
                  const SizedBox(height: 16),
                ],

                // Completed reminders section
                if (provider.completedReminders.isNotEmpty) ...[
                  _buildSectionHeader('Completed', Colors.green),
                  ...provider.completedReminders.map((reminder) => _buildReminderCard(context, reminder, provider)),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateReminderDialog(context),
        child: const Icon(Icons.add),
        tooltip: 'Add Reminder',
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            color: color,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context, ReminderModel reminder, ReminderProvider provider) {
    return Semantics(
      label: 'Reminder: ${reminder.title}',
      hint: 'Due ${reminder.formattedDueDate}. ${reminder.isOverdue ? 'Overdue.' : ''} Priority: ${reminder.priority.name}. Tap to view details.',
      child: Card(
        margin: EdgeInsets.only(bottom: AppConstants.defaultPadding / 2),
        child: Dismissible(
          key: Key(reminder.id),
          direction: DismissDirection.horizontal,
          background: Container(
            color: Colors.green,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: const Icon(Icons.check, color: Colors.white),
          ),
          secondaryBackground: Container(
            color: Colors.orange,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.snooze, color: Colors.white),
          ),
          onDismissed: (direction) {
            if (direction == DismissDirection.startToEnd) {
              provider.markCompleted(reminder.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${reminder.title} marked as completed')),
              );
            } else {
              provider.snoozeReminder(reminder.id, const Duration(hours: 1));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${reminder.title} snoozed for 1 hour')),
              );
            }
          },
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: reminder.priorityColor,
              child: Icon(
                reminder.priorityIcon,
                color: Colors.white,
              ),
            ),
            title: Text(
              reminder.title,
              style: TextStyle(
                decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reminder.description != null) ...[
                  Text(reminder.description!, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      reminder.formattedDueDate,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      reminder.timeUntilDue,
                      style: TextStyle(
                        fontSize: 12,
                        color: reminder.isOverdue ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                if (reminder.tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: reminder.tags.map((tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 10)),
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                ],
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleReminderAction(context, value, reminder, provider),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'complete', child: Text('Mark Complete')),
                const PopupMenuItem(value: 'snooze', child: Text('Snooze')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
            onTap: () => _showReminderDetails(context, reminder),
          ),
        ),
      ),
    );
  }

  void _showCreateReminderDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final tagsController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    ReminderPriority selectedPriority = ReminderPriority.medium;
    ReminderRepeat selectedRepeat = ReminderRepeat.none;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Reminder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => selectedDate = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text('${selectedDate.month}/${selectedDate.day}/${selectedDate.year}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setState(() => selectedTime = time);
                          }
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(selectedTime.format(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ReminderPriority>(
                  value: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: ReminderPriority.values.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(priority.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedPriority = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ReminderRepeat>(
                  value: selectedRepeat,
                  decoration: const InputDecoration(
                    labelText: 'Repeat',
                    border: OutlineInputBorder(),
                  ),
                  items: ReminderRepeat.values.map((repeat) {
                    return DropdownMenuItem(
                      value: repeat,
                      child: Text(repeat.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedRepeat = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma-separated)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  AppUtils.showErrorSnackBar(context, 'Title is required');
                  return;
                }

                final dueDate = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                final tags = tagsController.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();

                await Provider.of<ReminderProvider>(context, listen: false).createReminder(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                  dueDate: dueDate,
                  priority: selectedPriority,
                  repeat: selectedRepeat,
                  tags: tags,
                );

                Navigator.of(context).pop();
                AppUtils.showSuccessSnackBar(context, 'Reminder created');
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReminderDetails(BuildContext context, ReminderModel reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reminder.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (reminder.description != null) ...[
                Text('Description: ${reminder.description}'),
                const SizedBox(height: 8),
              ],
              Text('Due: ${reminder.formattedDueDate}'),
              Text('Priority: ${reminder.priority.name}'),
              Text('Repeat: ${reminder.repeat.name}'),
              Text('Status: ${reminder.status.name}'),
              if (reminder.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Tags: ${reminder.tags.join(', ')}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final provider = Provider.of<ReminderProvider>(context, listen: false);

    switch (action) {
      case 'filter':
        _showFilterDialog(context, provider);
        break;
      case 'sort':
        // Implement sort options
        break;
      case 'refresh':
        provider.loadReminders();
        break;
    }
  }

  void _handleReminderAction(BuildContext context, String action, ReminderModel reminder, ReminderProvider provider) {
    switch (action) {
      case 'edit':
        // Implement edit functionality
        AppUtils.showSuccessSnackBar(context, 'Edit functionality coming soon');
        break;
      case 'complete':
        provider.markCompleted(reminder.id);
        AppUtils.showSuccessSnackBar(context, 'Reminder marked as completed');
        break;
      case 'snooze':
        _showSnoozeDialog(context, reminder, provider);
        break;
      case 'delete':
        _showDeleteDialog(context, reminder, provider);
        break;
    }
  }

  void _showFilterDialog(BuildContext context, ReminderProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Reminders'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ReminderStatus>(
              value: provider.filterStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: ReminderStatus.values.map((status) {
                return DropdownMenuItem(value: status, child: Text(status.name));
              }).toList(),
              onChanged: (value) => provider.setFilterStatus(value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ReminderPriority>(
              value: provider.filterPriority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: ReminderPriority.values.map((priority) {
                return DropdownMenuItem(value: priority, child: Text(priority.name));
              }).toList(),
              onChanged: (value) => provider.setFilterPriority(value!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showSnoozeDialog(BuildContext context, ReminderModel reminder, ReminderProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Snooze Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('15 minutes'),
              onTap: () {
                provider.snoozeReminder(reminder.id, const Duration(minutes: 15));
                Navigator.of(context).pop();
                AppUtils.showSuccessSnackBar(context, 'Reminder snoozed for 15 minutes');
              },
            ),
            ListTile(
              title: const Text('1 hour'),
              onTap: () {
                provider.snoozeReminder(reminder.id, const Duration(hours: 1));
                Navigator.of(context).pop();
                AppUtils.showSuccessSnackBar(context, 'Reminder snoozed for 1 hour');
              },
            ),
            ListTile(
              title: const Text('Tomorrow'),
              onTap: () {
                provider.snoozeReminder(reminder.id, const Duration(days: 1));
                Navigator.of(context).pop();
                AppUtils.showSuccessSnackBar(context, 'Reminder snoozed until tomorrow');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ReminderModel reminder, ReminderProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteReminder(reminder.id);
              Navigator.of(context).pop();
              AppUtils.showSuccessSnackBar(context, 'Reminder deleted');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
