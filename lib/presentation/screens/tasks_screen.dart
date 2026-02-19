import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/task_list_item.dart';
import '../widgets/task_filter_chip.dart';
import '../widgets/add_task_dialog.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));

    _scrollController.addListener(_onScroll);
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 100) {
      _fabAnimationController.reverse();
    } else {
      _fabAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tasks'),
            actions: [
              IconButton(
                icon: Icon(
                  taskProvider.isGridView ? Icons.view_list : Icons.grid_view,
                ),
                onPressed: () => taskProvider.toggleViewMode(),
                tooltip: taskProvider.isGridView ? 'List View' : 'Grid View',
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(context, taskProvider, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'clear_completed',
                    child: ListTile(
                      leading: Icon(Icons.clear_all),
                      title: Text('Clear Completed'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'refresh',
                    child: ListTile(
                      leading: Icon(Icons.refresh),
                      title: Text('Refresh'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottom: TabBar(
            tabs: [
              Tab(
                text: 'All (${taskProvider.totalTasks})',
                icon: const Icon(Icons.list),
              ),
              Tab(
                text: 'Pending (${taskProvider.pendingTasks})',
                icon: const Icon(Icons.pending),
              ),
              Tab(
                text: 'Completed (${taskProvider.completedTasks})',
                icon: const Icon(Icons.check_circle),
              ),
              Tab(
                text: 'Overdue (${taskProvider.overdueTasks})',
                icon: const Icon(Icons.warning),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search and Filter Section
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  taskProvider.setSearchQuery('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      onChanged: (value) => taskProvider.setSearchQuery(value),
                    ),
                    const SizedBox(height: 12),
                    
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          TaskFilterChip(
                            label: 'Status: ${taskProvider.selectedStatus.label}',
                            onTap: () => _showStatusFilterDialog(context, taskProvider),
                          ),
                          const SizedBox(width: 8),
                          TaskFilterChip(
                            label: 'Category: ${taskProvider.selectedCategory.label}',
                            onTap: () => _showCategoryFilterDialog(context, taskProvider),
                          ),
                          const SizedBox(width: 8),
                          TaskFilterChip(
                            label: 'Priority: ${taskProvider.selectedPriority.label}',
                            onTap: () => _showPriorityFilterDialog(context, taskProvider),
                          ),
                          const SizedBox(width: 8),
                          TaskFilterChip(
                            label: 'Sort: ${taskProvider.sortBy.label}',
                            onTap: () => _showSortDialog(context, taskProvider),
                          ),
                          if (taskProvider.searchQuery.isNotEmpty || 
                              taskProvider.selectedStatus != TaskStatus.todo ||
                              taskProvider.selectedCategory != TaskCategory.work ||
                              taskProvider.selectedPriority != TaskPriority.medium) ...[
                            const SizedBox(width: 8),
                            TaskFilterChip(
                              label: 'Clear Filters',
                              onTap: () => taskProvider.clearFilters(),
                              isClearButton: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Task List/Grid
              Expanded(
                child: TabBarView(
                  children: [
                    _buildTaskList(context, taskProvider, TaskStatus.todo),
                    _buildTaskList(context, taskProvider, TaskStatus.inProgress),
                    _buildTaskList(context, taskProvider, TaskStatus.completed),
                    _buildOverdueTasks(context, taskProvider),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton.extended(
              onPressed: () => _showAddTaskDialog(context, taskProvider),
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskList(BuildContext context, TaskProvider taskProvider, TaskStatus status) {
    final tasks = status == TaskStatus.todo 
        ? taskProvider.filteredTasks.where((t) => t.status == TaskStatus.todo || t.status == TaskStatus.inProgress).toList()
        : status == TaskStatus.completed
            ? taskProvider.filteredTasks.where((t) => t.isCompleted).toList()
            : taskProvider.filteredTasks.where((t) => t.status == status).toList();

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == TaskStatus.completed ? Icons.check_circle : Icons.inbox,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              status == TaskStatus.completed 
                  ? 'No completed tasks'
                  : status == TaskStatus.inProgress
                      ? 'No tasks in progress'
                      : 'No pending tasks',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              status == TaskStatus.completed
                  ? 'Completed tasks will appear here'
                  : 'Start adding tasks to see them here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await taskProvider.refreshTasks();
      },
      child: taskProvider.isGridView
          ? _buildTaskGrid(context, tasks)
          : _buildTaskListView(context, tasks),
    );
  }

  Widget _buildOverdueTasks(BuildContext context, TaskProvider taskProvider) {
    final overdueTasks = taskProvider.filteredTasks.where((t) => t.isOverdue).toList();

    if (overdueTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No overdue tasks!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Great job staying on top of your tasks',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: overdueTasks.length,
      itemBuilder: (context, index) {
        final task = overdueTasks[index];
        return TaskListItem(
          task: task,
          onTap: () => _showTaskDetails(context, task),
          onToggle: () => taskProvider.toggleTaskCompletion(task),
          onEdit: () => _showEditTaskDialog(context, taskProvider, task),
          onDelete: () => _showDeleteConfirmation(context, taskProvider, task),
        );
      },
    );
  }

  Widget _buildTaskListView(BuildContext context, List<Task> tasks) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskListItem(
          task: task,
          onTap: () => _showTaskDetails(context, task),
          onToggle: () => taskProvider.toggleTaskCompletion(task),
          onEdit: () => _showEditTaskDialog(context, taskProvider, task),
          onDelete: () => _showDeleteConfirmation(context, taskProvider, task),
        );
      },
    );
  }

  Widget _buildTaskGrid(BuildContext context, List<Task> tasks) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskCard(
            task: task,
            onTap: () => _showTaskDetails(context, task),
            onToggle: () => taskProvider.toggleTaskCompletion(task),
            onEdit: () => _showEditTaskDialog(context, taskProvider, task),
            onDelete: () => _showDeleteConfirmation(context, taskProvider, task),
          );
        },
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, TaskProvider taskProvider) {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        onSave: (taskData) async {
          Navigator.pop(context);
          await taskProvider.createTask(**taskData);
        },
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, TaskProvider taskProvider, Task task) {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        task: task,
        onSave: (taskData) async {
          Navigator.pop(context);
          final updatedTask = task.copyWith(
            title: taskData['title'],
            description: taskData['description'],
            priority: taskData['priority'],
            category: taskData['category'],
            dueDate: taskData['dueDate'],
            tags: taskData['tags'],
            estimatedMinutes: taskData['estimatedMinutes'],
          );
          await taskProvider.updateTask(updatedTask);
        },
      ),
    );
  }

  void _showTaskDetails(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController, _) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (task.description != null) ...[
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],
              _buildDetailRow('Category', task.category.label),
              _buildDetailRow('Priority', task.priority.label),
              _buildDetailRow('Status', task.status.label),
              if (task.dueDate != null) _buildDetailRow('Due Date', task.dueDateFormatted),
              if (task.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Tags',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: task.tags.map((tag) => Chip(
                    label: Text(tag),
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditTaskDialog(context, 
                            Provider.of<TaskProvider>(context, listen: false), task);
                      },
                      child: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Provider.of<TaskProvider>(context, listen: false)
                            .toggleTaskCompletion(task);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: task.isCompleted ? Colors.orange : Colors.green,
                      ),
                      child: Text(task.isCompleted ? 'Reopen' : 'Complete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, TaskProvider taskProvider, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await taskProvider.deleteTask(task.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showStatusFilterDialog(BuildContext context, TaskProvider taskProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskStatus.values.map((status) => RadioListTile<TaskStatus>(
            title: Text(status.label),
            value: status,
            groupValue: taskProvider.selectedStatus,
            onChanged: (value) {
              if (value != null) {
                taskProvider.setStatusFilter(value);
                Navigator.pop(context);
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showCategoryFilterDialog(BuildContext context, TaskProvider taskProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskCategory.values.map((category) => RadioListTile<TaskCategory>(
            title: Row(
              children: [
                Icon(category.icon, size: 20, color: category.color),
                const SizedBox(width: 12),
                Text(category.label),
              ],
            ),
            value: category,
            groupValue: taskProvider.selectedCategory,
            onChanged: (value) {
              if (value != null) {
                taskProvider.setCategoryFilter(value);
                Navigator.pop(context);
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showPriorityFilterDialog(BuildContext context, TaskProvider taskProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Priority'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskPriority.values.map((priority) => RadioListTile<TaskPriority>(
            title: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: priority.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(priority.label),
              ],
            ),
            value: priority,
            groupValue: taskProvider.selectedPriority,
            onChanged: (value) {
              if (value != null) {
                taskProvider.setPriorityFilter(value);
                Navigator.pop(context);
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showSortDialog(BuildContext context, TaskProvider taskProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Tasks'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SortOption.values.map((option) => RadioListTile<SortOption>(
            title: Text(option.label),
            value: option,
            groupValue: taskProvider.sortBy,
            onChanged: (value) {
              if (value != null) {
                taskProvider.setSortOption(value);
                Navigator.pop(context);
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, TaskProvider taskProvider, String action) {
    switch (action) {
      case 'clear_completed':
        _showClearCompletedDialog(context, taskProvider);
        break;
      case 'refresh':
        taskProvider.refreshTasks();
        break;
    }
  }

  void _showClearCompletedDialog(BuildContext context, TaskProvider taskProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Completed Tasks'),
        content: const Text('Are you sure you want to delete all completed tasks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await taskProvider.deleteCompletedTasks();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}
