import 'package:flutter/material.dart';
import '../../domain/models/note.dart';

/// Working Note Card Widget with proper structure
class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleArchive;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePin,
    required this.onToggleFavorite,
    required this.onToggleArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and actions
              Row(
                children: [
                  // Pin indicator
                  if (note.isPinned) ...[
                    Icon(
                      Icons.push_pin,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                  ],
                  
                  // Title
                  Expanded(
                    child: Text(
                      note.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: note.isPinned ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Action buttons
                  _buildActionButtons(context),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Content preview
              if (note.content?.isNotEmpty == true) ...[
                Text(
                  note.content ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              
              // Footer with metadata
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pin button
        IconButton(
          onPressed: onTogglePin,
          icon: Icon(
            note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
          ),
          tooltip: note.isPinned ? 'Unpin note' : 'Pin note',
          color: note.isPinned 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        
        // Favorite button
        IconButton(
          onPressed: onToggleFavorite,
          icon: Icon(
            note.isFavorite ? Icons.favorite : Icons.favorite_border,
          ),
          tooltip: note.isFavorite ? 'Remove from favorites' : 'Add to favorites',
          color: note.isFavorite 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        
        // Archive button
        IconButton(
          onPressed: onToggleArchive,
          icon: Icon(
            note.isArchived ? Icons.archive : Icons.archive_outlined,
          ),
          tooltip: note.isArchived ? 'Unarchive note' : 'Archive note',
          color: note.isArchived 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        
        // Edit button
        IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit note',
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        
        // Delete button
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete note',
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        // Type indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getTypeColor(note.type).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            note.type.name.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _getTypeColor(note.type),
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Priority indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getPriorityColor(note.priority).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            note.priority.name.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _getPriorityColor(note.priority),
            ),
          ),
        ),
        
        const Spacer(),
        
        // Date
        Text(
          _formatDate(note.updatedAt ?? note.createdAt ?? DateTime.now()),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(NoteType type) {
    switch (type) {
      case NoteType.text:
        return Colors.blue;
      case NoteType.checklist:
        return Colors.green;
      case NoteType.voice:
        return Colors.purple;
      case NoteType.image:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(NotePriority priority) {
    switch (priority) {
      case NotePriority.high:
        return Colors.red;
      case NotePriority.medium:
        return Colors.orange;
      case NotePriority.low:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }
}
