import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_management_provider_fixed.dart';
import '../widgets/file_list_widget_fixed.dart';
import '../widgets/file_operations_bar_fixed.dart';

/// Fixed File Management Screen
/// Simplified for immediate build success
class FileManagementScreenFixed extends StatelessWidget {
  const FileManagementScreenFixed({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FileManagementProviderFixed(),
      child: const FileManagementViewFixed(),
    );
  }
}

class FileManagementViewFixed extends StatelessWidget {
  const FileManagementViewFixed({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Manager'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh files
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              // Show sort options
            },
          ),
          IconButton(
            icon: const Icon(Icons.view_module),
            onPressed: () {
              // Toggle view mode
            },
          ),
        ],
      ),
      body: const Column(
        children: [
          FileOperationsBarFixed(),
          Expanded(
            child: FileListWidgetFixed(),
          ),
        ],
      ),
    );
  }
}
