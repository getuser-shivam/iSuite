import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileManagementScreen extends ConsumerStatefulWidget {
  const FileManagementScreen({super.key});

  @override
  State<FileManagementScreen> createState() => _FileManagementScreenState();
}

class _FileManagementScreenState extends ConsumerState<FileManagementScreen> {
  List<FileSystemEntity> _files = [];
  Directory? _currentDirectory;

  @override
  void initState() {
    super.initState();
    _loadInitialDirectory();
  }

  Future<void> _loadInitialDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    setState(() {
      _currentDirectory = directory;
    });
    _loadFiles(directory);
  }

  void _loadFiles(Directory directory) {
    setState(() {
      _files = directory.listSync();
    });
  }

  void _navigateToDirectory(Directory directory) {
    setState(() {
      _currentDirectory = directory;
    });
    _loadFiles(directory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _currentDirectory != null ? _loadFiles(_currentDirectory!) : null,
          ),
        ],
      ),
      body: _currentDirectory == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Current: ${_currentDirectory!.path}'),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _files.length,
                    itemBuilder: (context, index) {
                      final entity = _files[index];
                      final isDirectory = entity is Directory;
                      final name = entity.path.split('/').last;

                      return ListTile(
                        leading: Icon(isDirectory ? Icons.folder : Icons.file_present),
                        title: Text(name),
                        onTap: isDirectory
                            ? () => _navigateToDirectory(entity as Directory)
                            : null,
                        trailing: isDirectory
                            ? const Icon(Icons.arrow_forward)
                            : PopupMenuButton<String>(
                                onSelected: (value) {
                                  // Handle file operations
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$value not implemented yet')),
                                  );
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'Rename', child: Text('Rename')),
                                  const PopupMenuItem(value: 'Delete', child: Text('Delete')),
                                  const PopupMenuItem(value: 'Copy', child: Text('Copy')),
                                ],
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
