import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_management_provider_simple.dart';
import '../file_model.dart';

class FileListWidget extends StatelessWidget {
  const FileListWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FileManagementProviderSimple>(
      builder: (context, provider) {
        if (provider.files.isEmpty) {
          return const Center(
            child: Text('No files found'),
              ],
            ),
          );
        } else if (state is FileManagementOperationInProgress) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  '${provider.lastOperation}...',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFileList(List<FileModel> files) {
    if (files.isEmpty) {
      return const Center(
        child: Text('No files found'),
      );
    }

    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
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
            // Handle file tap
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
        // Open file
        break;
      case 'rename':
        // Rename file
        break;
      case 'delete':
        // Delete file
        break;
      case 'share':
        // Share file
        break;
      case 'compress':
        // Compress file
        break;
    }
  }
}
