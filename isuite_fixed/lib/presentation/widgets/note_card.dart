import 'package:flutter/material.dart';
import '../../domain/models/note.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.onToggleArchive,
    required this.onTogglePin,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleArchive;
  final VoidCallback onTogglePin;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          note.content?.substring(0, 100) ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(note.category).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                note.category.name.toUpperCase(),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: _getCategoryColor(note.category),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (note.isPinned) ...[
                              Icon(
                                Icons.push_pin,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                            if (note.isFavorite) ...[
                              Icon(
                                Icons.favorite,
                                size: 16,
                                color: Colors.red,
                              ),
                            ],
                            if (note.isArchived) ...[
                              Icon(
                                Icons.archive,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      // Pin button
                      IconButton(
                        onPressed: onTogglePin,
                        icon: Icon(note.isPinned 
                            ? Icons.push_pin 
                            : Icons.push_pin_outlined),
                        tooltip: note.isPinned ? 'Unpin note' : 'Pin note',
                        color: note.isPinned 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      
                      // Favorite button
                      IconButton(
                        onPressed: onToggleFavorite,
                        icon: Icon(note.isFavorite 
                            ? Icons.favorite 
                            : Icons.favorite_border),
                        tooltip: note.isFavorite ? 'Remove from favorites' : 'Add to favorites',
                        color: note.isFavorite 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      
                      // Archive button
                      IconButton(
                        onPressed: onToggleArchive,
                        icon: Icon(note.isArchived 
                            ? Icons.archive 
                            : Icons.archive_outlined),
                        tooltip: note.isArchived ? 'Unarchive note' : 'Archive note',
                        color: note.isArchived 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      
                      // Edit button
                      IconButton(
                        onPressed: onEdit,
                        icon: Icon(Icons.edit_outlined),
                        tooltip: 'Edit note',
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      
                      // Delete button
                      IconButton(
                        onPressed: onDelete,
                        icon: Icon(Icons.delete_outline),
                        tooltip: 'Delete note',
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
              if (note.dueDate != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Due: ${_formatDate(note.dueDate!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(NoteCategory category) {
    switch (category) {
      case NoteCategory.personal:
        return Colors.blue;
      case NoteCategory.work:
        return Colors.green;
      case NoteCategory.study:
        return Colors.purple;
      case NoteCategory.ideas:
        return Colors.orange;
      case NoteCategory.meeting:
        return Colors.red;
      case NoteCategory.project:
        return Colors.teal;
      case NoteCategory.shopping:
        return Colors.amber;
      case NoteCategory.health:
        return Colors.pink;
      case NoteCategory.finance:
        return Colors.brown;
      case NoteCategory.travel:
        return Colors.indigo;
      case NoteCategory.other:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
