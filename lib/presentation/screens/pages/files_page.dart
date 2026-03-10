import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Files Page - File Management Features
class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<FileSystemEntity> _files = [];
  Directory? _currentDirectory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialDirectory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Manager'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Files', icon: Icon(Icons.folder)),
            Tab(text: 'Recent', icon: Icon(Icons.history)),
            Tab(text: 'Favorites', icon: Icon(Icons.star)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFilesTab(),
          _buildRecentTab(),
          _buildFavoritesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFileActions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilesTab() {
    return Column(
      children: [
        // Current path and navigation
        Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _currentDirectory?.parent != null ? _goUp : null,
              ),
              Expanded(
                child: Text(
                  _currentDirectory?.path ?? 'Loading...',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshFiles,
              ),
            ],
          ),
        ),

        // Files list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _files.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No files in this directory',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _files.length,
                      itemBuilder: (context, index) {
                        final entity = _files[index];
                        return _buildFileListItem(entity);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFileListItem(FileSystemEntity entity) {
    final isDirectory = entity is Directory;
    final fileName = entity.path.split(Platform.pathSeparator).last;
    final fileStat = entity.statSync();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          isDirectory ? Icons.folder : _getFileIcon(fileName),
          color: isDirectory ? Colors.blue : Colors.grey,
        ),
        title: Text(fileName),
        subtitle: Text(
          isDirectory
              ? 'Directory'
              : '${_formatFileSize(fileStat.size)} • ${_formatDate(fileStat.modified)}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleFileAction(action, entity),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'open', child: Text('Open')),
            const PopupMenuItem(value: 'rename', child: Text('Rename')),
            const PopupMenuItem(value: 'copy', child: Text('Copy')),
            const PopupMenuItem(value: 'move', child: Text('Move')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
            const PopupMenuItem(value: 'share', child: Text('Share')),
          ],
        ),
        onTap: () => _handleFileTap(entity),
      ),
    );
  }

  Widget _buildRecentTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recently Accessed Files',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildRecentFileItem('document.pdf', '2 hours ago'),
                _buildRecentFileItem('presentation.pptx', '1 day ago'),
                _buildRecentFileItem('image.jpg', '2 days ago'),
                _buildRecentFileItem('spreadsheet.xlsx', '3 days ago'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentFileItem(String fileName, String timeAgo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getFileIcon(fileName),
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(fileName),
        subtitle: Text(timeAgo),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showFileOptions(context, fileName),
        ),
        onTap: () => _openRecentFile(fileName),
      ),
    );
  }

  Widget _buildFavoritesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Favorite Files',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildFavoriteItem('Important Docs', Icons.folder, Colors.blue),
                _buildFavoriteItem('Photos', Icons.photo_library, Colors.green),
                _buildFavoriteItem('Music', Icons.music_note, Colors.orange),
                _buildFavoriteItem(
                    'Videos', Icons.video_library, Colors.purple),
                _buildFavoriteItem('Downloads', Icons.download, Colors.red),
                _buildFavoriteItem(
                    'Desktop', Icons.desktop_windows, Colors.teal),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteItem(String title, IconData icon, Color color) {
    return Card(
      child: InkWell(
        onTap: () => _openFavoriteFolder(title),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _loadInitialDirectory() async {
    try {
      setState(() => _isLoading = true);

      // Try to get documents directory first
      Directory? initialDir;
      try {
        initialDir = await getApplicationDocumentsDirectory();
      } catch (e) {
        // Fallback to current directory
        initialDir = Directory.current;
      }

      await _loadDirectory(initialDir);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading directory: $e')),
        );
      }
    }
  }

  Future<void> _loadDirectory(Directory directory) async {
    try {
      setState(() => _isLoading = true);

      final entities = await directory.list().toList();
      entities.sort((a, b) {
        // Directories first, then files, alphabetically
        final aIsDir = a is Directory;
        final bIsDir = b is Directory;

        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;

        return a.path.compareTo(b.path);
      });

      setState(() {
        _currentDirectory = directory;
        _files = entities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading directory: $e')),
        );
      }
    }
  }

  Future<void> _refreshFiles() async {
    if (_currentDirectory != null) {
      await _loadDirectory(_currentDirectory!);
    }
  }

  void _goUp() {
    if (_currentDirectory?.parent != null) {
      _loadDirectory(_currentDirectory!.parent);
    }
  }

  void _handleFileTap(FileSystemEntity entity) {
    if (entity is Directory) {
      _loadDirectory(entity);
    } else {
      _openFile(entity as File);
    }
  }

  void _openFile(File file) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Opening file: ${file.path.split(Platform.pathSeparator).last}')),
    );
  }

  void _handleFileAction(String action, FileSystemEntity entity) {
    switch (action) {
      case 'open':
        _handleFileTap(entity);
        break;
      case 'rename':
        _renameFile(entity);
        break;
      case 'copy':
        _copyFile(entity);
        break;
      case 'move':
        _moveFile(entity);
        break;
      case 'delete':
        _deleteFile(entity);
        break;
      case 'share':
        _shareFile(entity);
        break;
    }
  }

  void _renameFile(FileSystemEntity entity) {
    final fileName = entity.path.split(Platform.pathSeparator).last;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename File'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'New name'),
          controller: TextEditingController(text: fileName),
          onSubmitted: (newName) {
            Navigator.of(context).pop();
            _performRename(entity, newName);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _performRename(FileSystemEntity entity, String newName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Renaming "${entity.path.split(Platform.pathSeparator).last}" to "$newName"')),
    );
  }

  void _copyFile(FileSystemEntity entity) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copy feature - Coming soon!')),
    );
  }

  void _moveFile(FileSystemEntity entity) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Move feature - Coming soon!')),
    );
  }

  void _deleteFile(FileSystemEntity entity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text(
            'Are you sure you want to delete "${entity.path.split(Platform.pathSeparator).last}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _performDelete(entity);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _performDelete(FileSystemEntity entity) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File deletion not implemented in demo')),
    );
  }

  void _shareFile(FileSystemEntity entity) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Sharing "${entity.path.split(Platform.pathSeparator).last}"')),
    );
  }

  void _showFileActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.create_new_folder),
              title: const Text('Create Folder'),
              onTap: () {
                Navigator.of(context).pop();
                _createNewFolder();
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Upload File'),
              onTap: () {
                Navigator.of(context).pop();
                _uploadFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Files'),
              onTap: () {
                Navigator.of(context).pop();
                _searchFiles();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createNewFolder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Folder name'),
          onSubmitted: (name) {
            Navigator.of(context).pop();
            _performCreateFolder(name);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _performCreateFolder(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Created folder: $name')),
    );
  }

  void _uploadFile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File upload feature - Coming soon!')),
    );
  }

  void _searchFiles() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File search feature - Coming soon!')),
    );
  }

  void _showFileOptions(BuildContext context, String fileName) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Add to Favorites'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _openRecentFile(String fileName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening recent file: $fileName')),
    );
  }

  void _openFavoriteFolder(String folderName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening favorite folder: $folderName')),
    );
  }
}
