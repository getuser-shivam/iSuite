import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_management_provider_fixed.dart';
import '../file_model.dart';

/// Fixed File Operations Bar
/// Simplified for immediate build success
class FileOperationsBarFixed extends StatelessWidget {
  const FileOperationsBarFixed({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FileManagementProviderFixed>(
      builder: (context, provider) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.refreshFiles,
                tooltip: 'Refresh files',
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  // Add new file functionality
                  provider.selectFile(FileModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: 'New File',
                    path: '/new_file.txt',
                    size: 0,
                    isDirectory: false,
                    modified: DateTime.now(),
                  ));
                },
                tooltip: 'Add new file',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  // Delete functionality
                  if (provider.selectedFiles.isNotEmpty) {
                    provider.deleteFile(provider.selectedFiles.first.path);
                  }
                },
                tooltip: 'Delete selected',
              ),
              IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: () {
                  // Create folder functionality
                  provider.selectFile(FileModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: 'New Folder',
                    path: '/new_folder',
                    size: 0,
                    isDirectory: true,
                    modified: DateTime.now(),
                  ));
                },
                tooltip: 'Create folder',
              ),
              IconButton(
                icon: const Icon(Icons.upload_file),
                onPressed: () {
                  // Upload functionality
                  final selectedFiles = provider.selectedFiles;
                  if (selectedFiles.isNotEmpty) {
                    // Simulate upload
                    for (final file in selectedFiles) {
                      print('Uploading ${file.name}...');
                    }
                  }
                },
                tooltip: 'Upload files',
              ),
              PopupMenuButton<String>(
                onSelected: (String action) {
                  switch (action) {
                    case 'copy':
                      // Copy functionality
                      final selectedFiles = provider.selectedFiles;
                      if (selectedFiles.isNotEmpty) {
                        for (final file in selectedFiles) {
                          print('Copying ${file.name}...');
                        }
                      }
                      break;
                    case 'move':
                      // Move functionality
                      final selectedFiles = provider.selectedFiles;
                      if (selectedFiles.isNotEmpty) {
                        for (final file in selectedFiles) {
                          print('Moving ${file.name}...');
                        }
                      }
                      break;
                    case 'delete':
                      // Delete functionality
                      final selectedFiles = provider.selectedFiles;
                      if (selectedFiles.isNotEmpty) {
                        for (final file in selectedFiles) {
                          provider.deleteFile(file.path);
                        }
                      }
                      break;
                    case 'compress':
                      // Compress functionality
                      final selectedFiles = provider.selectedFiles;
                      if (selectedFiles.isNotEmpty) {
                        for (final file in selectedFiles) {
                          print('Compressing ${file.name}...');
                        }
                      }
                      break;
                    default:
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                      value: 'copy', child: Text('Copy')),
                  const PopupMenuItem<String>(
                      value: 'move', child: Text('Move')),
                  const PopupMenuItem<String>(
                      value: 'delete', child: Text('Delete')),
                  const PopupMenuItem<String>(
                      value: 'compress', child: Text('Compress')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
