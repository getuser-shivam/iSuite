import 'package:flutter/material.dart';

class TaskFilterChip extends StatelessWidget {
  const TaskFilterChip({
    required this.label,
    required this.onTap,
    super.key,
    this.isClearButton = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool isClearButton;

  @override
  Widget build(BuildContext context) => ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor: isClearButton
            ? Colors.red.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        side: BorderSide(
          color: isClearButton
              ? Colors.red.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
        labelStyle: TextStyle(
          color: isClearButton
              ? Colors.red
              : Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
        avatar: isClearButton
            ? const Icon(Icons.clear, size: 16)
            : Icon(
                Icons.filter_list,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
      );
}
