import 'package:flutter/material.dart';
import '../../domain/models/task.dart';

class TaskCard extends StatefulWidget {
  const TaskCard({
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: widget.task.priority.color.withOpacity(0.1),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) => _animationController.reverse(),
        onTapCancel: () => _animationController.reverse(),
        onTap: widget.onTap,
        onLongPress: () => _showActionMenu(context),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Card(
              elevation: widget.task.isOverdue ? 6 : 2,
              shadowColor: widget.task.priority.color.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: widget.task.isCompleted
                      ? Colors.green.withOpacity(0.3)
                      : widget.task.isOverdue
                          ? Colors.red.withOpacity(0.3)
                          : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      if (widget.task.isCompleted)
                        Colors.green.withOpacity(0.05)
                      else
                        widget.task.isOverdue
                            ? Colors.red.withOpacity(0.05)
                            : Colors.transparent,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with status and priority
                      Row(
                        children: [
                          // Priority indicator
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: widget.task.priority.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status indicator
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    widget.task.status.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
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
                          ),
                          // Category icon
                          Icon(
                            widget.task.category.icon,
                            size: 16,
                            color: widget.task.category.color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        widget.task.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: widget.task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: widget.task.isCompleted
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5)
                                      : null,
                                ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (widget.task.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.task.description!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const Spacer(),

                      // Bottom section with due date and actions
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.task.dueDate != null) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: widget.task.isOverdue
                                      ? Colors.red
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.task.dueDateFormatted,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: widget.task.isOverdue
                                        ? Colors.red
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                    fontWeight: widget.task.isOverdue
                                        ? FontWeight.bold
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Tags
                          if (widget.task.tags.isNotEmpty) ...[
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: widget.task.tags
                                  .take(2)
                                  .map((tag) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          tag,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                            if (widget.task.tags.length > 2)
                              Text(
                                '+${widget.task.tags.length - 2}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],

                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!widget.task.isCompleted) ...[
                                IconButton(
                                  onPressed: widget.onToggle,
                                  icon: const Icon(Icons.check_circle_outline),
                                  iconSize: 20,
                                  tooltip: 'Mark Complete',
                                ),
                                IconButton(
                                  onPressed: widget.onEdit,
                                  icon: const Icon(Icons.edit_outlined),
                                  iconSize: 20,
                                  tooltip: 'Edit Task',
                                ),
                              ] else ...[
                                IconButton(
                                  onPressed: widget.onToggle,
                                  icon: const Icon(Icons.refresh),
                                  iconSize: 20,
                                  tooltip: 'Reopen Task',
                                ),
                              ],
                              IconButton(
                                onPressed: widget.onDelete,
                                icon: const Icon(Icons.delete_outline),
                                iconSize: 20,
                                tooltip: 'Delete Task',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Task Actions',
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
            ListTile(
              leading: Icon(
                widget.task.isCompleted ? Icons.refresh : Icons.check_circle,
                color: widget.task.isCompleted ? Colors.orange : Colors.green,
              ),
              title: Text(
                  widget.task.isCompleted ? 'Reopen Task' : 'Mark Complete'),
              onTap: () {
                Navigator.pop(context);
                widget.onToggle();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Task'),
              onTap: () {
                Navigator.pop(context);
                widget.onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.purple),
              title: const Text('Share Task'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Task'),
              onTap: () {
                Navigator.pop(context);
                widget.onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
