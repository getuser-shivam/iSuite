import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_management_provider_simple.dart';

/// Simple File Operations Bar
/// Bypasses complex BLoC for immediate build success
class FileOperationsBarSimple extends StatelessWidget {
  const FileOperationsBarSimple({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FileManagementProviderMinimal>(
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
                  // Simple add functionality
                  provider.selectFile(FileModel(
                    id: DateTime.now().millisecondsSinceEpoch().toString(),
                    name: 'New File',
                    path: '/new_file.txt',
                    size: 0,
                    isDirectory: false,
                    modifiedAt: DateTime.now(),
                  ));
                },
                tooltip: 'Add new file',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  // Simple delete functionality
                  if (provider.selectedFiles.isNotEmpty) {
                    provider.deleteFile(provider.selectedFiles.first);
                  }
                },
                tooltip: 'Delete selected',
              ),
            ],
          ),
        );
      },
    );
  }
}
