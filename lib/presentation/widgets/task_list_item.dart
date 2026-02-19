import 'package:flutter/material.dart';
import '../../domain/models/task.dart';

class TaskListItem extends StatefulWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskListItem({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem> {
  final bool _isSwiped = false;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          widget.onDelete();
        }
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: widget.task.isOverdue ? 4 : 1,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Checkbox for completion
              Checkbox(
                value: widget.task.isCompleted,
                onChanged: (_) => widget.onToggle(),
                activeColor: widget.task.category.color,
              ),
              const SizedBox(width: 12),
              // Category icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.task.isCompleted 
                      ? Colors.green.withAlpha(32)
                      : widget.task.category.color.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.task.category.icon,
                  size: 16,
                  color: widget.task.category.color,
                ),
              ),
            ],
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.task.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: widget.task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: widget.task.isCompleted
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                      : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.task.description != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.task.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  // Priority indicator
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.task.priority.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.task.status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.task.status.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: widget.task.status.color,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Due date
                  if (widget.task.dueDate != null) ...[
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: widget.task.isOverdue 
                          ? Colors.red
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.task.dueDateFormatted,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.task.isOverdue 
                            ? Colors.red
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: widget.task.isOverdue ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ],
              ),
              
              // Tags
              if (widget.task.tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: widget.task.tags.take(3).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) => _handleAction(value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle',
                child: ListTile(
                  leading: Icon(
                    widget.task.isCompleted ? Icons.refresh : Icons.check_circle,
                    color: widget.task.isCompleted ? Colors.orange : Colors.green,
                  ),
                  title: Text(widget.task.isCompleted ? 'Reopen' : 'Complete'),
                  contentPadding: const EdgeInsets.all(0),
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Edit'),
                  contentPadding: const EdgeInsets.all(0),
                ),
              ),
              PopupMenuItem(
                value: 'duplicate',
                child: ListTile(
                  leading: const Icon(Icons.copy, color: Colors.purple),
                  title: const Text('Duplicate'),
                  contentPadding: const EdgeInsets.all(0),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete'),
                  contentPadding: const EdgeInsets.all(0),
                ),
              ),
            ],
          ),
          onTap: widget.onTap,
        ),
      ),
    );
  }

  void _handleAction(String action) {
    switch (action) {
      case 'toggle':
        widget.onToggle();
        break;
      case 'edit':
        widget.onEdit();
        break;
      case 'duplicate':
        // TODO: Implement duplicate functionality
        break;
      case 'delete':
        widget.onDelete();
        break;
    }
  }
}
