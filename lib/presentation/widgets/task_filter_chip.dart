import 'package:flutter/material.dart';

class TaskFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isClearButton;

  const TaskFilterChip({
    super.key,
    required this.label,
    required this.onTap,
    this.isClearButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: isClearButton 
          ? Colors.red.withOpacity(0.1)
          : Theme.of(context).colorScheme.primary.withOpacity(0.1),
      side: BorderSide(
        color: isClearButton 
            ? Colors.red.withOpacity(0.3)
            : Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
}
