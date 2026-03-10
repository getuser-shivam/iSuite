import 'package:flutter/material.dart';
import '../../domain/models/file.dart';

class FileCard extends StatelessWidget {
  const FileCard({
    required this.file,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.onToggleEncryption,
    super.key,
  });
  final FileModel file;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleEncryption;

  @override
  Widget build(BuildContext context) => Card(
        elevation: file.isEncrypted ? 6 : 2,
        shadowColor: file.isEncrypted ? Colors.orange.withOpacity(0.2) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: file.status == FileStatus.failed
                ? Colors.red.withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File icon and status
              Row(
                children: [
                  Icon(
                    _getFileIcon(),
                    size: 32,
                    color: _getFileColor(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          file.formattedSize,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // Status indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      file.status.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // File details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type and date
                    Row(
                      children: [
                        Icon(
                          Icons.category,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          file.type.name,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          file.formattedDate,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                        ),
                      ],
                    ),

                    // Tags
                    if (file.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: file.tags
                            .map((tag) => Chip(
                                  label: tag,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  labelStyle: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                ))
                            .toList(),
                      ),
                    ],

                    // Description
                    if (file.description != null &&
                        file.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        file.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Action buttons
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Favorite button
                  IconButton(
                    onPressed: onToggleFavorite,
                    icon: file.tags.contains('favorite')
                        ? const Icon(Icons.favorite)
                        : const Icon(Icons.favorite_border),
                    tooltip: file.tags.contains('favorite')
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                    color: file.tags.contains('favorite')
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),

                  // Encryption button
                  IconButton(
                    onPressed: onToggleEncryption,
                    icon: file.isEncrypted
                        ? const Icon(Icons.lock)
                        : const Icon(Icons.lock_open),
                    tooltip: file.isEncrypted ? 'Decrypt file' : 'Encrypt file',
                    color: file.isEncrypted
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),

                  // Edit button
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit file',
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),

                  // Delete button
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete file',
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  IconData _getFileIcon() {
    switch (file.type) {
      case FileType.image:
        return Icons.image;
      case FileType.video:
        return Icons.video_file;
      case FileType.audio:
        return Icons.audio_file;
      case FileType.archive:
        return Icons.archive;
      case FileType.document:
        return Icons.description;
      case FileType.other:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor() {
    switch (file.type) {
      case FileType.image:
        return Colors.blue;
      case FileType.video:
        return Colors.red;
      case FileType.audio:
        return Colors.purple;
      case FileType.archive:
        return Colors.orange;
      case FileType.document:
        return Colors.green;
      case FileType.other:
        return Colors.grey;
    }
  }

  Color _getStatusColor() {
    switch (file.status) {
      case FileStatus.uploading:
        return Colors.blue;
      case FileStatus.processing:
        return Colors.orange;
      case FileStatus.completed:
        return Colors.green;
      case FileStatus.failed:
        return Colors.red;
      case FileStatus.deleted:
        return Colors.grey;
    }
  }
}
