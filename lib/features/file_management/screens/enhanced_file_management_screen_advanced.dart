import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/enhanced_file_provider.dart';
import '../../core/advanced_parameterization.dart';

class EnhancedFileManagementScreen extends StatefulWidget {
  const EnhancedFileManagementScreen({super.key});

  @override
  State<EnhancedFileManagementScreen> createState() => _EnhancedFileManagementScreenState();
}

class _EnhancedFileManagementScreenState extends State<EnhancedFileManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnhancedFileProvider>().loadFiles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('iSuite - Advanced File Manager'),
        actions: [
          Consumer<EnhancedFileProvider>(
            builder: (context, provider, child) {
              return PopupMenuButton<FileViewMode>(
                icon: const Icon(Icons.view_module),
                onSelected: (mode) {
                  provider.viewMode = mode;
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: FileViewMode.list,
                    child: ListTile(
                      leading: Icon(Icons.list),
                      title: Text('List View'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: FileViewMode.grid,
                    child: ListTile(
                      leading: Icon(Icons.grid_view),
                      title: Text('Grid View'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: FileViewMode.details,
                    child: ListTile(
                      leading: Icon(Icons.table_rows),
                      title: Text('Details View'),
                    ),
                  ),
                ],
              );
            },
          ),
          Consumer<EnhancedFileProvider>(
            builder: (context, provider, child) {
              return PopupMenuButton<FileSortOrder>(
                icon: const Icon(Icons.sort),
                onSelected: (order) {
                  provider.sortOrder = order;
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: FileSortOrder.name,
                    child: ListTile(
                      leading: Icon(Icons.sort_by_alpha),
                      title: Text('Sort by Name'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: FileSortOrder.date,
                    child: ListTile(
                      leading: Icon(Icons.schedule),
                      title: Text('Sort by Date'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: FileSortOrder.size,
                    child: ListTile(
                      leading: Icon(Icons.storage),
                      title: Text('Sort by Size'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: FileSortOrder.type,
                    child: ListTile(
                      leading: Icon(Icons.category),
                      title: Text('Sort by Type'),
                    ),
                  ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showParameterSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildParameterInfo(),
          Expanded(child: _buildFileList()),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Consumer<EnhancedFileProvider>(
            builder: (context, provider, child) {
              return FloatingActionButton.extended(
                onPressed: () => _showUploadDialog(context),
                icon: const Icon(Icons.upload),
                label: const Text('Upload File'),
              );
            },
          ),
          const SizedBox(height: 8),
          Consumer<EnhancedFileProvider>(
            builder: (context, provider, child) {
              if (provider.uploadQueue.isNotEmpty) {
                return FloatingActionButton.extended(
                  onPressed: () => _showUploadQueue(context),
                  icon: const Icon(Icons.cloud_upload),
                  label: Text('${provider.uploadQueue.length} uploads'),
                  backgroundColor: Colors.orange,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search files...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              context.read<EnhancedFileProvider>().loadFiles();
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (query) {
          context.read<EnhancedFileProvider>().loadFiles(query: query);
        },
      ),
    );
  }

  Widget _buildParameterInfo() {
    return Consumer<EnhancedFileProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Parameters',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildParameterChip('Max Files', '${provider.maxFilesPerPage}'),
                  _buildParameterChip('Thumbnails', provider.enableThumbnails ? 'On' : 'Off'),
                  _buildParameterChip('Quality', '${(provider.thumbnailQuality * 100).round()}%'),
                  _buildParameterChip('Uploads', '${provider.concurrentUploads}'),
                  _buildParameterChip('Cache', '${provider.cacheTimeout.inMinutes}m'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParameterChip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.blue.shade300),
      labelStyle: const TextStyle(fontSize: 12),
    );
  }

  Widget _buildFileList() {
    return Consumer<EnhancedFileProvider>(
      builder: (context, provider, child) {
        if (provider.files.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No files found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        switch (provider.viewMode) {
          case FileViewMode.grid:
            return _buildGridView(provider);
          case FileViewMode.details:
            return _buildDetailsView(provider);
          case FileViewMode.list:
          default:
            return _buildListView(provider);
        }
      },
    );
  }

  Widget _buildListView(EnhancedFileProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: provider.files.length,
      itemBuilder: (context, index) {
        final file = provider.files[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: _buildFileIcon(file),
            title: Text(file.name),
            subtitle: Text(_formatFileSize(file.size)),
            trailing: PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'download',
                  child: ListTile(
                    leading: Icon(Icons.download),
                    title: Text('Download'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading: Icon(Icons.share),
                    title: Text('Share'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView(EnhancedFileProvider provider) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: provider.files.length,
      itemBuilder: (context, index) {
        final file = provider.files[index];
        return Card(
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: _buildFileIcon(file),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  file.name,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailsView(EnhancedFileProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: provider.files.length,
      itemBuilder: (context, index) {
        final file = provider.files[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFileIcon(file),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Size: ${_formatFileSize(file.size)}'),
                      Text('Modified: ${_formatDate(file.modifiedAt)}'),
                      Text('Type: ${file.mimeType}'),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'download',
                      child: ListTile(
                        leading: Icon(Icons.download),
                        title: Text('Download'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: ListTile(
                        leading: Icon(Icons.share),
                        title: Text('Share'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileIcon(file) {
    IconData iconData;
    Color color;
    
    if (file.isDirectory) {
      iconData = Icons.folder;
      color = Colors.blue;
    } else if (file.isImage) {
      iconData = Icons.image;
      color = Colors.green;
    } else if (file.isVideo) {
      iconData = Icons.video_file;
      color = Colors.red;
    } else if (file.isAudio) {
      iconData = Icons.audio_file;
      color = Colors.purple;
    } else if (file.isDocument) {
      iconData = Icons.description;
      color = Colors.orange;
    } else {
      iconData = Icons.insert_drive_file;
      color = Colors.grey;
    }
    
    return Icon(iconData, color: color, size: 48);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showParameterSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ParameterSettingsDialog(),
    );
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UploadDialog(),
    );
  }

  void _showUploadQueue(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UploadQueueDialog(),
    );
  }
}

class ParameterSettingsDialog extends StatefulWidget {
  const ParameterSettingsDialog({super.key});

  @override
  State<ParameterSettingsDialog> createState() => _ParameterSettingsDialogState();
}

class _ParameterSettingsDialogState extends State<ParameterSettingsDialog> {
  late int _maxFilesPerPage;
  late bool _enableThumbnails;
  late double _thumbnailQuality;
  late int _concurrentUploads;
  late Duration _cacheTimeout;
  late bool _enableCompression;
  late double _compressionLevel;

  @override
  void initState() {
    super.initState();
    final provider = context.read<EnhancedFileProvider>();
    _maxFilesPerPage = provider.maxFilesPerPage;
    _enableThumbnails = provider.enableThumbnails;
    _thumbnailQuality = provider.thumbnailQuality;
    _concurrentUploads = provider.concurrentUploads;
    _cacheTimeout = provider.cacheTimeout;
    _enableCompression = provider.enableCompression;
    _compressionLevel = provider.compressionLevel;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Parameter Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderListTile(
              title: 'Max Files Per Page',
              value: _maxFilesPerPage.toDouble(),
              min: 5,
              max: 200,
              divisions: 39,
              label: '$_maxFilesPerPage',
              onChanged: (value) {
                setState(() {
                  _maxFilesPerPage = value.round();
                });
              },
            ),
            SwitchListTile(
              title: const Text('Enable Thumbnails'),
              value: _enableThumbnails,
              onChanged: (value) {
                setState(() {
                  _enableThumbnails = value;
                });
              },
            ),
            if (_enableThumbnails)
              SliderListTile(
                title: 'Thumbnail Quality',
                value: _thumbnailQuality,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: '${(_thumbnailQuality * 100).round()}%',
                onChanged: (value) {
                  setState(() {
                    _thumbnailQuality = value;
                  });
                },
              ),
            SliderListTile(
              title: 'Concurrent Uploads',
              value: _concurrentUploads.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$_concurrentUploads',
              onChanged: (value) {
                setState(() {
                  _concurrentUploads = value.round();
                });
              },
            ),
            SliderListTile(
              title: 'Cache Timeout (minutes)',
              value: _cacheTimeout.inMinutes.toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              label: '${_cacheTimeout.inMinutes}m',
              onChanged: (value) {
                setState(() {
                  _cacheTimeout = Duration(minutes: value.round());
                });
              },
            ),
            SwitchListTile(
              title: const Text('Enable Compression'),
              value: _enableCompression,
              onChanged: (value) {
                setState(() {
                  _enableCompression = value;
                });
              },
            ),
            if (_enableCompression)
              SliderListTile(
                title: 'Compression Level',
                value: _compressionLevel,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: '${(_compressionLevel * 100).round()}%',
                onChanged: (value) {
                  setState(() {
                    _compressionLevel = value;
                  });
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final provider = context.read<EnhancedFileProvider>();
            provider.updateParameters({
              'max_files_per_page': _maxFilesPerPage,
              'enable_thumbnails': _enableThumbnails,
              'thumbnail_quality': _thumbnailQuality,
              'concurrent_uploads': _concurrentUploads,
              'cache_timeout': _cacheTimeout.inMilliseconds,
              'enable_compression': _enableCompression,
              'compression_level': _compressionLevel,
            });
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class SliderListTile extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;

  const SliderListTile({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class UploadDialog extends StatelessWidget {
  const UploadDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload File'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_upload, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text('File upload functionality would be implemented here.'),
          Text('This would open a file picker and upload the selected file.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class UploadQueueDialog extends StatelessWidget {
  const UploadQueueDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedFileProvider>(
      builder: (context, provider, child) {
        return AlertDialog(
          title: Text('Upload Queue (${provider.uploadQueue.length})'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: provider.uploadQueue.length,
              itemBuilder: (context, index) {
                final task = provider.uploadQueue[index];
                return Card(
                  child: ListTile(
                    leading: _buildUploadStatusIcon(task.status),
                    title: Text('File ${index + 1}'),
                    subtitle: Text('Status: ${task.status.name}'),
                    trailing: Text('${(task.progress * 100).round()}%'),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUploadStatusIcon(UploadStatus status) {
    switch (status) {
      case UploadStatus.pending:
        return const Icon(Icons.schedule, color: Colors.grey);
      case UploadStatus.uploading:
        return const Icon(Icons.cloud_upload, color: Colors.blue);
      case UploadStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case UploadStatus.failed:
        return const Icon(Icons.error, color: Colors.red);
    }
  }
}
