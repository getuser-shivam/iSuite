import 'package:flutter/material.dart';
import '../../domain/models/note.dart';

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
      elevation: note.isPinned ? 6 : 2,
      shadowColor: note.priority.color.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: note.isArchived ? Colors.grey.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and metadata
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
                      ),
                      const SizedBox(height: 4),
                      
                      // Type and category
                      Row(
                        children: [
                          Icon(
                            note.type.icon,
                            size: 16,
                            color: note.type.color,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            note.type.label,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Icon(
                            note.priority.icon,
                            size: 16,
                            color: note.priority.color,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            note.priority.label,
                            style: Status: note.status.color != NoteStatus.draft 
                                ? Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Due date and priority
                        if (note.dueDate != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.alarm,
                                size: 16,
                                color: note.isOverdue ? Colors.red : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Due: ${note.formattedDate}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: note.isOverdue ? Colors.red : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              ),
                            ],
                          ),
                        ],
                        
                        // Tags
                        if (note.tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4.0,
                            runSpacing: WrapAlignment.start,
                            children: note.tags.map((tag) => Chip(
                              label: tag,
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          )).toList(),
                        ),
                        ],
                      ],
                    ),
                    
                    // Content preview
                    if (note.content != null && note.content!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        note.excerpt,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      ),
                    ],
                    
                    // Metadata
                    Row(
                      children: [
                        if (note.wordCount != null) ...[
                          Icon(
                            Icons.description,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${note.wordCount} words',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                        ],
                        if (note.readingTime != null) ...[
                          Icon(
                            Icons.timer,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${note.readingTime} min read',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                        ],
                      ],
                    ],
                  ],
                ),
                  ),
                ),
              ),
            ),
            
            // Action buttons
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Pin button
                IconButton(
                  onPressed: () => onTogglePin(),
                  icon: note.isPinned 
                      ? Icons.push_pin 
                      : Icons.push_pin_outline,
                  tooltip: note.isPinned ? 'Unpin note' : 'Pin note',
                  color: note.isPinned 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Favorite button
                IconButton(
                  onPressed: () => onToggleFavorite(),
                  icon: note.isFavorite 
                      ? Icons.favorite 
                      : Icons.favorite_border,
                  tooltip: note.isFavorite ? 'Remove from favorites' : 'Add to favorites',
                  color: note.isFavorite 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Archive button
                IconButton(
                  onPressed: () => onToggleArchive(),
                  icon: note.isArchived 
                      ? Icons.archive 
                      : Icons.archive_outlined,
                  tooltip: note.isArchived ? 'Unarchive note' : 'Archive note',
                  color: note.isArchived 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Edit button
                IconButton(
                  onPressed: () => onEdit(),
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit note',
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Delete button
                IconButton(
                  onPressed: () => onDelete(),
                  icon: Icons.delete_outline,
                  tooltip: 'Delete note',
                  color: Colors.red,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
