import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_management_provider_simple.dart';
import '../widgets/file_list_widget.dart';
import '../widgets/file_operations_bar.dart';

class FileManagementScreen extends StatelessWidget {
  const FileManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FileManagementProviderSimple(),
      child: const FileManagementView(),
    );
  }
}

class FileManagementView extends StatelessWidget {
  const FileManagementView({Key? key}) : super(key: key);

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
          FileOperationsBar(),
          Expanded(
            child: FileListWidget(),
          ),
        ],
      ),
    );
  }
}
