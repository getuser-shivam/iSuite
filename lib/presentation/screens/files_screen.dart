import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils.dart';
import '../providers/file_provider.dart';
import '../widgets/file_card.dart';
import '../widgets/file_filter_chip.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  late FileProvider _fileProvider;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fileProvider = Provider.of<FileProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Files'),
          actions: [
            IconButton(
              onPressed: () => _showUploadDialog(context),
              icon: const Icon(Icons.upload_file),
              tooltip: 'Upload File',
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'refresh',
                  child: ListTile(
                    leading: Icon(Icons.refresh),
                    title: Text('Refresh'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'select_all',
                  child: ListTile(
                    leading: Icon(Icons.select_all),
                    title: Text('Select All'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete_selected',
                  child: ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('Delete Selected'),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchAndFilters(context),
            _buildFileStats(),
            Expanded(
              child: Consumer<FileProvider>(
                builder: (context, fileProvider, child) {
                  if (fileProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (fileProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            fileProvider.error!,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => fileProvider.refreshFiles(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (fileProvider.filteredFiles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.folder_open,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No files found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _showUploadDialog(context),
                            child: const Text('Upload File'),
                          ),
                        ],
                      ),
                    );
                  }

                  return _buildFileList(fileProvider);
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showUploadDialog(context),
          tooltip: 'Upload File',
          child: const Icon(Icons.add),
        ),
      );

  Widget _buildSearchAndFilters(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search files...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _searchController.clear,
                  icon: const Icon(Icons.clear),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                _fileProvider.setSearchQuery(value);
              },
            ),
            const SizedBox(height: 16),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FileFilterChip(
                    label: 'All',
                    isSelected: _fileProvider.selectedType == FileType.document,
                    onTap: () => _fileProvider.setTypeFilter(FileType.document),
                  ),
                  FileFilterChip(
                    label: 'Images',
                    isSelected: _fileProvider.selectedType == FileType.image,
                    onTap: () => _fileProvider.setTypeFilter(FileType.image),
                  ),
                  FileFilterChip(
                    label: 'Videos',
                    isSelected: _fileProvider.selectedType == FileType.video,
                    onTap: () => _fileProvider.setTypeFilter(FileType.video),
                  ),
                  FileFilterChip(
                    label: 'Audio',
                    isSelected: _fileProvider.selectedType == FileType.audio,
                    onTap: () => _fileProvider.setTypeFilter(FileType.audio),
                  ),
                  FileFilterChip(
                    label: 'Archives',
                    isSelected: _fileProvider.selectedType == FileType.archive,
                    onTap: () => _fileProvider.setTypeFilter(FileType.archive),
                  ),
                  const SizedBox(width: 8),
                  FileFilterChip(
                    label: 'Encrypted',
                    isSelected: _fileProvider.showEncrypted,
                    onTap: () => _fileProvider.toggleEncryptedFilter(),
                  ),
                  FileFilterChip(
                    label: 'Favorites',
                    isSelected: _fileProvider.showFavorites,
                    onTap: () => _fileProvider.toggleFavoriteFilter(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Size filter
            Consumer<FileProvider>(
              builder: (context, fileProvider, child) => DropdownButton<String>(
                value: fileProvider.selectedSizeFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Sizes')),
                  DropdownMenuItem(
                      value: 'small', child: Text('Small (< 100KB)')),
                  DropdownMenuItem(
                      value: 'medium', child: Text('Medium (100KB - 1MB)')),
                  DropdownMenuItem(
                      value: 'large', child: Text('Large (1MB - 100MB)')),
                  DropdownMenuItem(
                      value: 'huge', child: Text('Huge (> 100MB)')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _fileProvider.setSizeFilter(value);
                  }
                },
              ),
            ),
          ],
        ),
      );

  Widget _buildFileStats() => Consumer<FileProvider>(
        builder: (context, fileProvider, child) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Files',
                  fileProvider.totalFiles.toString(),
                  Icons.folder,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatCard(
                  'Total Size',
                  fileProvider.formattedTotalSize,
                  Icons.storage,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatCard(
                  'Encrypted',
                  fileProvider.encryptedFiles.toString(),
                  Icons.lock,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatCard(
                  'Favorites',
                  fileProvider.favoriteFiles.toString(),
                  Icons.favorite,
                  Colors.red,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildStatCard(
          String title, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      );

  Widget _buildFileList(FileProvider fileProvider) {
    if (fileProvider.isGridView) {
      return GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: fileProvider.filteredFiles.length,
        itemBuilder: (context, index) {
          final file = fileProvider.filteredFiles[index];
          return FileCard(
            file: file,
            onTap: () => _showFileDetails(context, file),
            onEdit: () => _showEditDialog(context, file),
            onDelete: () => _showDeleteDialog(context, file),
            onToggleFavorite: () => fileProvider.toggleFileFavorite(file.id),
            onToggleEncryption: () => _showEncryptionDialog(context, file),
          );
        },
      );
    } else {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        itemCount: fileProvider.filteredFiles.length,
        itemBuilder: (context, index) {
          final file = fileProvider.filteredFiles[index];
          return FileCard(
            file: file,
            onTap: () => _showFileDetails(context, file),
            onEdit: () => _showEditDialog(context, file),
            onDelete: () => _showDeleteDialog(context, file),
            onToggleFavorite: () => fileProvider.toggleFileFavorite(file.id),
            onToggleEncryption: () => _showEncryptionDialog(context, file),
          );
        },
      );
    }
  }

  void _showFileDetails(BuildContext context, FileModel file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type: ${file.type.name}'),
              Text('Size: ${file.formattedSize}'),
              Text('Status: ${file.status.name}'),
              Text('Created: ${file.formattedDate}'),
              if (file.description != null)
                Text('Description: ${file.description}'),
              if (file.tags.isNotEmpty) Text('Tags: ${file.tags.join(', ')}'),
              if (file.isEncrypted) const Text('Encrypted: Yes'),
              if (file.downloadCount != null)
                Text('Downloads: ${file.downloadCount}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload File'),
        content: const Text(
            'File upload functionality will be implemented in the next update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, FileModel file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit File'),
        content: const Text(
            'File editing functionality will be implemented in the next update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, FileModel file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete ${file.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              fileProvider.deleteFile(file.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEncryptionDialog(BuildContext context, FileModel file) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file.isEncrypted ? 'Decrypt File' : 'Encrypt File'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!file.isEncrypted) ...[
              const Text('Enter password to encrypt this file:'),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ] else ...[
              const Text('Enter password to decrypt this file:'),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (passwordController.text.isNotEmpty) {
                fileProvider.toggleFileEncryption(
                  file.id,
                  !file.isEncrypted,
                  password: passwordController.text,
                );
              }
            },
            child: Text(file.isEncrypted ? 'Decrypt' : 'Encrypt'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'refresh':
        _fileProvider.refreshFiles();
        break;
      case 'select_all':
        // Implement select all functionality
        break;
      case 'delete_selected':
        // Implement batch delete functionality
        break;
    }
  }
}
