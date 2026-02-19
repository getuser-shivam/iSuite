import 'package:flutter/material.dart';

class FileFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FileFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: label,
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: isSelected 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
          : Theme.of(context).colorScheme.surface,
      labelStyle: TextStyle(
        color: isSelected 
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected 
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
