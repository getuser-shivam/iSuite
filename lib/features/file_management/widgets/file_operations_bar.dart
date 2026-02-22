import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/file_management_bloc.dart';
import '../providers/file_management_provider.dart';

class FileOperationsBar extends StatelessWidget {
  const FileOperationsBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FileManagementBloc, FileManagementState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          color: Colors.grey[100],
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search files...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.select_all),
                onPressed: () {
                  // Select all files
                },
                tooltip: 'Select All',
              ),
              IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: () {
                  // Create new folder
                },
                tooltip: 'New Folder',
              ),
              IconButton(
                icon: const Icon(Icons.upload_file),
                onPressed: () {
                  // Upload files
                },
                tooltip: 'Upload Files',
              ),
              PopupMenuButton<String>(
                onSelected: (action) => _handleBatchOperation(action),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'copy', child: Text('Copy')),
                  const PopupMenuItem(value: 'move', child: Text('Move')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  const PopupMenuItem(value: 'compress', child: Text('Compress')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleBatchOperation(String action) {
    // Handle batch operations
    switch (action) {
      case 'copy':
        // Copy selected files
        break;
      case 'move':
        // Move selected files
        break;
      case 'delete':
        // Delete selected files
        break;
      case 'compress':
        // Compress selected files
        break;
    }
  }
}
