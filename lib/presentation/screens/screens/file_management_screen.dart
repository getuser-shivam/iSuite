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
  FileSystemEntity? _selectedFile;

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
      _selectedFile = null;
    });
    _loadFiles(directory);
  }

  void _selectFile(FileSystemEntity file) {
    setState(() {
      _selectedFile = file;
    });
  }

  bool _isImageFile(String path) {
    final extension = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension);
  }

  bool _isTextFile(String path) {
    final extension = path.split('.').last.toLowerCase();
    return ['txt', 'md', 'json', 'xml', 'html', 'css', 'js', 'dart'].contains(extension);
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
      body: Row(
        children: [
          // File list
          Expanded(
            flex: 2,
            child: _currentDirectory == null
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
                              selected: _selectedFile == entity,
                              onTap: () {
                                if (isDirectory) {
                                  _navigateToDirectory(entity as Directory);
                                } else {
                                  _selectFile(entity);
                                }
                              },
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
          ),
          // File preview
          if (_selectedFile != null && _selectedFile is File)
            Expanded(
              flex: 3,
              child: _buildFilePreview(_selectedFile as File),
            ),
        ],
      ),
    );
  }

  Widget _buildFilePreview(File file) {
    final path = file.path;

    if (_isImageFile(path)) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Image Preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Image.file(
              file,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Text('Error loading image'));
              },
            ),
          ),
        ],
      );
    } else if (_isTextFile(path)) {
      return FutureBuilder<String>(
        future: file.readAsString(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error reading file'));
          } else {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Text Preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(snapshot.data ?? ''),
                  ),
                ),
              ],
            );
          }
        },
      );
    } else {
      return const Center(child: Text('Preview not available for this file type'));
    }
  }
}
