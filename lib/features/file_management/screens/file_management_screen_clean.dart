import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_management_provider_minimal.dart';
import '../widgets/file_operations_bar_working.dart';

/// Clean File Management Screen
/// Simple implementation for immediate build success
class FileManagementScreen extends StatelessWidget {
  const FileManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Manager'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          FileOperationsBar(),
          Expanded(
            child: FileListWidgetSimple(),
          ),
        ],
      ],
    );
  }
}
}
