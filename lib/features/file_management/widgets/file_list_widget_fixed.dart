import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_management_provider_fixed.dart';
import '../file_model.dart';

/// Fixed File List Widget
/// Simplified for immediate build success
class FileListWidgetFixed extends StatelessWidget {
  const FileListWidgetFixed({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FileManagementProviderFixed>(
      builder: (context, provider) {
        if (provider.files.isEmpty) {
          return const Center(
            child: Text('No files found'),
          );
        }

        return ListView.builder(
          itemCount: provider.files.length,
          itemBuilder: (context, index) {
            final file = provider.files[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getFileIconColor(file).withOpacity(0.1),
                child: Icon(
                  _getFileIcon(file),
                  color: _getFileIconColor(file),
                  size: 20,
                ),
              ),
              title: Text(
                file.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                file.isDirectory ? 'Folder' : _formatFileSize(file.size),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (action) => _handleFileAction(action, file),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'open', child: Text('Open')),
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  const PopupMenuItem(value: 'share', child: Text('Share')),
                  const PopupMenuItem(value: 'compress', child: Text('Compress')),
                ],
              ),
              onTap: () {
                provider.selectFile(file);
              },
            );
          },
        );
      },
    );
  }

  IconData _getFileIcon(FileModel file) {
    if (file.isDirectory) {
      return Icons.folder;
    }
    
    final extension = file.name.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
      case 'md':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(FileModel file) {
    if (file.isDirectory) {
      return Colors.blue;
    }
    
    final extension = file.name.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.green;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Colors.purple;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Colors.orange;
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _handleFileAction(String action, FileModel file) {
    switch (action) {
      case 'open':
        print('Opening ${file.name}...');
        break;
      case 'rename':
        print('Renaming ${file.name}...');
        break;
      case 'delete':
        print('Deleting ${file.name}...');
        break;
      case 'share':
        print('Sharing ${file.name}...');
        break;
      case 'compress':
        print('Compressing ${file.name}...');
        break;
    }
  }
}
