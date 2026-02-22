import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'file_preview.dart';

class EnhancedFileManager extends StatefulWidget {
  const EnhancedFileManager({Key? key}) : super(key: key);

  @override
  State<EnhancedFileManager> createState() => _EnhancedFileManagerState();
}

class _EnhancedFileManagerState extends State<EnhancedFileManager> {
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

  Future<void> _moveSelectedFiles() async {
    if (_selectedFiles.isEmpty) return;

    final selectedPath = await _showFolderPicker('Select destination folder');
    if (selectedPath == null) return;

    for (final filePath in _selectedFiles) {
      try {
        final entity = FileSystemEntity.isDirectorySync(filePath) 
            ? Directory(filePath) 
            : File(filePath);
        final fileName = path.basename(filePath);
        final newPath = path.join(selectedPath!, fileName);
        
        if (entity is Directory) {
          await Directory(filePath).rename(newPath);
        } else {
          await File(filePath).rename(newPath);
        }
      } catch (e) {
        debugPrint('Error moving $filePath: $e');
      }
    }

    setState(() => _selectedFiles.clear());
    _loadDirectory();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selectedFiles.length} file(s) moved')),
    );
  }

  Future<void> _copySelectedFiles() async {
    if (_selectedFiles.isEmpty) return;

    final selectedPath = await _showFolderPicker('Select destination folder');
    if (selectedPath == null) return;

    for (final filePath in _selectedFiles) {
      try {
        final entity = FileSystemEntity.isDirectorySync(filePath) 
            ? Directory(filePath) 
            : File(filePath);
        final fileName = path.basename(filePath);
        final newPath = path.join(selectedPath!, fileName);
        
        if (entity is Directory) {
          await Directory(filePath).copy(newPath);
        } else {
          await File(filePath).copy(newPath);
        }
      } catch (e) {
        debugPrint('Error copying $filePath: $e');
      }
    }

    setState(() => _selectedFiles.clear());
    _loadDirectory();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selectedFiles.length} file(s) copied')),
    );
  }

  Future<String?> _showFolderPicker(String title) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 400,
          height: 300,
          child: FutureBuilder<List<String>>(
            future: _getFolderList(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final folder = snapshot.data![index];
                  return ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(folder),
                    onTap: () => Navigator.pop(context, folder),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<List<String>> _getFolderList() async {
    final folders = <String>[];
    final currentDir = Directory(_currentPath);
    
    await for (final entity in currentDir.list()) {
      if (entity is Directory) {
        folders.add(path.basename(entity.path));
      }
    }
    
    return folders;
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
                const PopupMenuItem(value: 'delete', child: Text('Delete'), enabled: false),
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
                                      const PopupMenuItem(value: 'copy', child: Text('Copy')),
                                      const PopupMenuItem(value: 'move', child: Text('Move')),
                                      const PopupMenuItem(value: 'delete', child: Text('Delete'), enabled: false),
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FilePreviewWidget(filePath: file.path),
        ),
      );
    }
  }

  void _handleFileAction(String action, FileSystemEntity file) async {
    switch (action) {
      case 'preview':
        if (file is File) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FilePreviewWidget(filePath: file.path),
            ),
          );
        }
        break;
      case 'rename':
        _renameFile(file);
        break;
      case 'copy':
        setState(() {
          _selectedFiles = {file.path};
          _isSelectionMode = true;
        });
        break;
      case 'move':
        setState(() {
          _selectedFiles = {file.path};
          _isSelectionMode = true;
        });
        break;
      case 'share':
        _shareFile(file);
        break;
    }
  }

  void _handleBatchAction(String action) async {
    switch (action) {
      case 'copy':
        await _copySelectedFiles();
        break;
      case 'move':
        await _moveSelectedFiles();
        break;
      case 'delete':
        await _deleteSelectedFiles();
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

  Future<void> _compressSelectedFiles() async {
    if (_selectedFiles.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compression functionality coming soon')),
    );
  }
}
