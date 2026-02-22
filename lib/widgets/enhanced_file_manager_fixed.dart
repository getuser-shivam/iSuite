import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class EnhancedFileManagerFixed extends StatefulWidget {
  const EnhancedFileManagerFixed({Key? key}) : super(key: key);

  @override
  State<EnhancedFileManagerFixed> createState() => _EnhancedFileManagerFixedState();
}

class _EnhancedFileManagerFixedState extends State<EnhancedFileManagerFixed> {
  String _currentPath = '/';
  List<FileSystemEntity> _files = [];
  bool _isLoading = true;
  final Set<String> _selectedFiles = {};
  bool _isSelectionMode = false;
  final TextEditingController _searchController = TextEditingController();
  List<FileSystemEntity> _filteredFiles = [];

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  Future<void> _loadDirectory() async {
    setState(() => _isLoading = true);
    try {
      final directory = Directory(_currentPath);
      final files = await directory.list().toList();
      files.sort((a, b) {
        if (a is Directory && b is File) return -1;
        if (a is File && b is Directory) return 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });
      setState(() {
        _files = files;
        _filteredFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading directory: $e')),
      );
    }
  }

  void _filterFiles(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFiles = _files;
      } else {
        _filteredFiles = _files.where((file) {
          final fileName = path.basename(file.path).toLowerCase();
          return fileName.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _toggleFileSelection(String filePath) {
    setState(() {
      if (_selectedFiles.contains(filePath)) {
        _selectedFiles.remove(filePath);
      } else {
        _selectedFiles.add(filePath);
      }
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedFiles.clear();
      }
    });
  }

  void _selectAllFiles() {
    setState(() {
      _selectedFiles.clear();
      for (final file in _filteredFiles) {
        _selectedFiles.add(file.path);
      }
    });
  }

  void _deselectAllFiles() {
    setState(() => _selectedFiles.clear());
  }

  Future<void> _deleteSelectedFiles() async {
    if (_selectedFiles.isEmpty) return;

    final confirmed = await _showConfirmDialog(
      'Delete Files',
      'Are you sure you want to delete ${_selectedFiles.length} file(s)?',
    );

    if (confirmed != true) return;

    for (final filePath in _selectedFiles) {
      try {
        final entity = FileSystemEntity.isDirectorySync(filePath) 
            ? Directory(filePath) 
            : File(filePath);
        await entity.delete(recursive: true);
      } catch (e) {
        debugPrint('Error deleting $filePath: $e');
      }
    }

    setState(() => _selectedFiles.clear());
    _loadDirectory();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selectedFiles.length} file(s) deleted')),
    );
  }

  Future<void> _compressSelectedFiles() async {
    if (_selectedFiles.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compression functionality coming soon')),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enhanced File Manager - $_currentPath'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectedFiles.length == _filteredFiles.length 
                  ? _deselectAllFiles 
                  : _selectAllFiles,
              tooltip: _selectedFiles.length == _filteredFiles.length 
                  ? 'Deselect All' 
                  : 'Select All',
            ),
          if (_selectedFiles.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (action) => _handleBatchAction(action),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'copy', child: Text('Copy')),
                const PopupMenuItem(value: 'move', child: Text('Move')),
                const PopupMenuItem(value: 'compress', child: Text('Compress')),
              ],
              child: Chip(
                label: Text('${_selectedFiles.length} selected'),
                avatar: const Icon(Icons.checklist),
              ),
            ),
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.close : Icons.checklist),
            onPressed: _toggleSelectionMode,
            tooltip: _isSelectionMode ? 'Exit Selection' : 'Select Multiple',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDirectory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[100],
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search files...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterFiles('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _filterFiles,
            ),
          ),
          
          // File List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFiles.isEmpty
                    ? const Center(child: Text('No files found'))
                    : ListView.builder(
                        itemCount: _filteredFiles.length,
                        itemBuilder: (context, index) {
                          final file = _filteredFiles[index];
                          final isSelected = _selectedFiles.contains(file.path);
                          final fileName = path.basename(file.path);
                          final isDirectory = file is Directory;
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getFileIconColor(file.path).withOpacity(0.1),
                                child: Icon(
                                  _getFileIcon(file.path),
                                  color: _getFileIconColor(file.path),
                                ),
                              ),
                              title: Text(
                                fileName.isEmpty ? '/' : fileName,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: isDirectory 
                                  ? 'Folder'
                                  : _formatFileSize(file),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isSelectionMode)
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (_) => _toggleFileSelection(file.path),
                                    ),
                                  PopupMenuButton<String>(
                                    onSelected: (action) => _handleFileAction(action, file),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'preview', child: Text('Preview')),
                                      const PopupMenuItem(value: 'rename', child: Text('Rename')),
                                      const PopupMenuItem(value: 'share', child: Text('Share')),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () {
                                if (_isSelectionMode) {
                                  _toggleFileSelection(file.path);
                                } else {
                                  _handleFileTap(file);
                                }
                              },
                              selected: isSelected,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'upload',
            onPressed: _uploadFile,
            child: const Icon(Icons.upload_file),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'create_folder',
            onPressed: _createFolder,
            child: const Icon(Icons.create_new_folder),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return Icons.image;
      case '.mp4':
      case '.avi':
      case '.mov':
        return Icons.video_file;
      case '.mp3':
      case '.wav':
      case '.flac':
        return Icons.audio_file;
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.txt':
      case '.md':
        return Icons.text_snippet;
      default:
        return FileSystemEntity.isDirectorySync(filePath) ? Icons.folder : Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return Colors.green;
      case '.mp4':
      case '.avi':
      case '.mov':
        return Colors.purple;
      case '.mp3':
      case '.wav':
      case '.flac':
        return Colors.orange;
      case '.pdf':
        return Colors.red;
      case '.doc':
      case '.docx':
        return Colors.blue;
      default:
        return FileSystemEntity.isDirectorySync(filePath) ? Colors.blue : Colors.grey;
    }
  }

  String _formatFileSize(FileSystemEntity file) {
    if (file is File) {
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return 'Folder';
  }

  void _handleFileTap(FileSystemEntity file) {
    if (file is Directory) {
      setState(() {
        _currentPath = file.path;
        _selectedFiles.clear();
        _isSelectionMode = false;
      });
      _loadDirectory();
    } else {
      _showFilePreview(file);
    }
  }

  void _handleFileAction(String action, FileSystemEntity file) async {
    switch (action) {
      case 'preview':
        if (file is File) {
          _showFilePreview(file);
        }
        break;
      case 'rename':
        _renameFile(file);
        break;
      case 'share':
        _shareFile(file);
        break;
    }
  }

  void _handleBatchAction(String action) async {
    switch (action) {
      case 'copy':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copy functionality coming soon')),
        );
        break;
      case 'move':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Move functionality coming soon')),
        );
        break;
      case 'compress':
        await _compressSelectedFiles();
        break;
    }
  }

  void _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected: ${result!.files.single.name}')),
      );
    }
  }

  void _createFolder() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            hintText: 'Enter folder name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.isNotEmpty) {
      try {
        final newDir = Directory('$_currentPath/${controller.text}');
        await newDir.create();
        _loadDirectory();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Folder created: ${controller.text}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating folder: $e')),
        );
      }
    }
  }

  void _renameFile(FileSystemEntity file) async {
    final controller = TextEditingController(
      text: path.basename(file.path),
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New Name',
            hintText: 'Enter new name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.isNotEmpty) {
      try {
        final newPath = path.join(path.dirname(file.path), controller.text);
        if (file is Directory) {
          await Directory(file.path).rename(newPath);
        } else {
          await File(file.path).rename(newPath);
        }
        _loadDirectory();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Renamed to: ${controller.text}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error renaming: $e')),
        );
      }
    }
  }

  void _shareFile(FileSystemEntity file) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share functionality coming soon for ${path.basename(file.path)}')),
    );
  }

  void _showFilePreview(FileSystemEntity file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('File: ${path.basename(file.path)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Path: ${file.path}'),
            if (file is File) Text('Size: ${_formatFileSize(file)}'),
            Text('Type: ${path.extension(file.path)}'),
            const SizedBox(height: 16),
            const Text('Preview functionality coming soon'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
