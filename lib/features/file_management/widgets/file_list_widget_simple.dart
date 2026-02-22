import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_management_provider_simple.dart';
import '../file_model.dart';

/// Simple File List Widget
/// Bypasses complex BLoC for immediate build success
class FileListWidgetSimple extends StatelessWidget {
  const FileListWidgetSimple({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FileManagementProviderSimple>(
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
              leading: Icon(
                file.isDirectory
                    ? Icons.folder
                    : Icons.insert_drive_file_outlined,
              ),
              title: Text(file.name),
              subtitle: Text('${file.size} bytes'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  // Simple delete functionality
                  provider.deleteFile(file.path);
                },
              ),
            );
          },
        );
      },
    );
  }
}
