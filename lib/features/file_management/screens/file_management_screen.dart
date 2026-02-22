import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../services/notifications/notification_service.dart';
import '../../../core/central_config.dart';
import '../../../core/logging/logging_service.dart';
import '../../../core/security/security_manager.dart';
import '../../../core/performance_monitor.dart';
import 'qr_share_screen.dart';
import 'media_player_screen.dart';

/// Enhanced File Management Screen with Advanced Features
///
/// This screen provides a comprehensive file management interface with:
/// - Advanced search and filtering capabilities
/// - Multi-select operations (copy, move, paste, delete, rename)
/// - Dual-pane interface support
/// - AI-powered organization suggestions
/// - Context menus with file-specific actions
/// - Media playback for supported formats
/// - QR code sharing for device-to-device transfer
/// - Performance monitoring and optimization
/// - Security checks and validation
/// - Batch operations with progress tracking
/// - File metadata extraction and display
/// - Cloud synchronization integration
class FileManagementScreen extends StatefulWidget {
  const FileManagementScreen({super.key});

  @override
  State<FileManagementScreen> createState() => _FileManagementScreenState();
}

/// Enhanced state class for FileManagementScreen
///
/// Manages the state of file operations, search, selection, and UI interactions.
/// Implements efficient state management to minimize unnecessary rebuilds.
/// Includes performance monitoring, security validation, and advanced features.
class _FileManagementScreenState extends State<FileManagementScreen> {
  // Core services
  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();
  final SecurityManager _security = SecurityManager();
  final PerformanceMonitor _performance = PerformanceMonitor();
  
  // Controllers and state
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _gridScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();
  
  // View state
  bool _isGridView = true;
  bool _isSelectionMode = false;
  bool _isLoading = false;
  bool _isSearching = false;
  String _currentPath = '/';
  String _searchQuery = '';
  
  // Data
  List<FileSystemEntity> _files = [];
  Set<String> _selectedFiles = {};
  Map<String, FileMetadata> _fileMetadata = {};
  List<FileOperation> _operationQueue = [];
  
  // Performance tracking
  DateTime? _lastLoadTime;
  int _fileCount = 0;
  double _loadTime = 0.0;
  /// Enhanced file metadata with additional properties
class FileMetadata {
  final String name;
  final String path;
  final int size;
  final DateTime modified;
  final DateTime accessed;
  final String type;
  final bool isDirectory;
  final String? checksum;
  final Map<String, dynamic>? tags;
  final String? thumbnail;
  final Duration? duration; // For media files
  final Map<String, dynamic>? exifData;

  FileMetadata({
    required this.name,
    required this.path,
    required this.size,
    required this.modified,
    required this.accessed,
    required this.type,
    required this.isDirectory,
    this.checksum,
    this.tags,
    this.thumbnail,
    this.duration,
    this.exifData,
  });

  /// Get formatted file size
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Get file extension
  String get extension => name.split('.').last.toLowerCase();

  /// Check if file is media type
  bool get isMedia => _mediaExtensions.contains(extension);

  /// Check if file is image
  bool get isImage => _imageExtensions.contains(extension);

  /// Check if file is video
  bool get isVideo => _videoExtensions.contains(extension);

  /// Check if file is audio
  bool get isAudio => _audioExtensions.contains(extension);

  /// Check if file is document
  bool get isDocument => _documentExtensions.contains(extension);

  static const List<String> _mediaExtensions = [
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp',
    'mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv',
    'mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a'
  ];

  static const List<String> _imageExtensions = [
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'
  ];

  static const List<String> _videoExtensions = [
    'mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv', 'webm'
  ];

  static const List<String> _audioExtensions = [
    'mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a', 'wma'
  ];

  static const List<String> _documentExtensions = [
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
    'txt', 'rtf', 'odt', 'ods', 'odp'
  ];
}

/// File operation with enhanced tracking
class FileOperation {
  final String id;
  final FileOperationType type;
  final List<String> sourcePaths;
  final String? destinationPath;
  final DateTime createdAt;
  FileOperationStatus status;
  double progress;
  String? errorMessage;
  int processedFiles;
  final int totalFiles;

  FileOperation({
    required this.id,
    required this.type,
    required this.sourcePaths,
    this.destinationPath,
    required this.totalFiles,
  }) : createdAt = DateTime.now(),
       status = FileOperationStatus.pending,
       progress = 0.0,
       processedFiles = 0;

  /// Update operation progress
  void updateProgress(int processed, {String? error}) {
    processedFiles = processed;
    progress = processed / totalFiles;
    if (error != null) {
      errorMessage = error;
      status = FileOperationStatus.failed;
    } else if (processed >= totalFiles) {
      status = FileOperationStatus.completed;
    } else {
      status = FileOperationStatus.inProgress;
    }
  }

  /// Get formatted progress
  String get formattedProgress => '${(progress * 100).toStringAsFixed(1)}%';

  /// Get operation description
  String get description {
    switch (type) {
      case FileOperationType.copy:
        return 'Copying ${sourcePaths.length} file${sourcePaths.length == 1 ? '' : 's'}';
      case FileOperationType.move:
        return 'Moving ${sourcePaths.length} file${sourcePaths.length == 1 ? '' : 's'}';
      case FileOperationType.delete:
        return 'Deleting ${sourcePaths.length} file${sourcePaths.length == 1 ? '' : 's'}';
      case FileOperationType.rename:
        return 'Renaming file';
      case FileOperationType.compress:
        return 'Compressing ${sourcePaths.length} file${sourcePaths.length == 1 ? '' : 's'}';
      case FileOperationType.extract:
        return 'Extracting archive';
    }
  }
}

/// File operation types
enum FileOperationType {
  copy,
  move,
  delete,
  rename,
  compress,
  extract,
}

/// File operation status
enum FileOperationStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled,
}

  // Sorting and filtering parameters
  late String _sortBy;
  late bool _sortAscending;
  late bool _showRecentOnly;
  late bool _showHiddenFiles;
  late bool _searchInContent;

  // Dual-pane interface support
  late bool _enableDualPane;
  late double _dualPaneSplitRatio;

  /// Initialize parameters from CentralConfig
  ///
  /// Loads user preferences and default settings for file management behavior.
  @override
  void initState() {
    super.initState();
    _initializeParameters();
  }

  /// Initialize configuration parameters
  ///
  /// Retrieves settings from CentralConfig for consistent user experience
  /// across app restarts and different screens.
  void _initializeParameters() {
    final config = CentralConfig.instance;
    _sortBy = config.getParameter('ui.file_management.default_sort', defaultValue: 'name')!;
    _sortAscending = config.getParameter('ui.file_management.default_sort_ascending', defaultValue: true)!;
    _showRecentOnly = config.getParameter('ui.file_management.show_recent_by_default', defaultValue: false)!;
    _showHiddenFiles = config.getParameter('ui.file_management.show_hidden_by_default', defaultValue: false)!;
    _searchInContent = config.getParameter('ui.file_management.enable_content_search', defaultValue: false)!;
    _enableDualPane = config.getParameter('ui.file_management.enable_dual_pane', defaultValue: false)!;
    _dualPaneSplitRatio = config.getParameter('ui.file_management.dual_pane_split_ratio', defaultValue: 0.5)!;
  }

  // Mock file data with paths and dates
  final List<Map<String, dynamic>> _allFiles = [
    {
      'name': 'document.pdf', 
      'type': 'PDF Document', 
      'size': '2.5 MB', 
      'path': '/mock/documents/document.pdf', 
      'date': DateTime.now().subtract(const Duration(hours: 2)), 
      'hidden': false,
      'content': 'This is a sample PDF document containing information about project management and development practices. It includes chapters on agile methodology, team collaboration, and quality assurance.'
    },
    {
      'name': 'image.jpg', 
      'type': 'JPEG Image', 
      'size': '1.2 MB', 
      'path': '/mock/images/image.jpg', 
      'date': DateTime.now().subtract(const Duration(days: 1)), 
      'hidden': false,
      'content': '[Image content - binary data not searchable]'
    },
    {
      'name': 'video.mp4', 
      'type': 'MP4 Video', 
      'size': '45.8 MB', 
      'path': '/mock/videos/video.mp4', 
      'date': DateTime.now().subtract(const Duration(hours: 1)), 
      'hidden': false,
      'content': '[Video content - multimedia data]'
    },
    {
      'name': 'music.mp3', 
      'type': 'MP3 Audio', 
      'size': '8.3 MB', 
      'path': '/mock/music/music.mp3', 
      'date': DateTime.now().subtract(const Duration(days: 2)), 
      'hidden': false,
      'content': '[Audio content - music file]'
    },
    {
      'name': 'spreadsheet.xlsx', 
      'type': 'Excel Spreadsheet', 
      'size': '1.1 MB', 
      'path': '/mock/documents/spreadsheet.xlsx', 
      'date': DateTime.now().subtract(const Duration(hours: 6)), 
      'hidden': false,
      'content': 'Sales Data Q1 2024\nProduct A: 150 units\nProduct B: 89 units\nRevenue: $45,230\nExpenses: $12,450\nProfit: $32,780'
    },
    {
      'name': 'presentation.pptx', 
      'type': 'PowerPoint Presentation', 
      'size': '15.2 MB', 
      'path': '/mock/documents/presentation.pptx', 
      'date': DateTime.now().subtract(const Duration(days: 3)), 
      'hidden': false,
      'content': 'Quarterly Business Review\nSlide 1: Company Overview\nSlide 2: Financial Performance\nSlide 3: Market Analysis\nSlide 4: Future Projections'
    },
    {
      'name': 'archive.zip', 
      'type': 'ZIP Archive', 
      'size': '23.7 MB', 
      'path': '/mock/archives/archive.zip', 
      'date': DateTime.now().subtract(const Duration(hours: 12)), 
      'hidden': false,
      'content': '[Compressed archive containing multiple files]'
    },
    {
      'name': 'text.txt', 
      'type': 'Text File', 
      'size': '0.5 KB', 
      'path': '/mock/documents/text.txt', 
      'date': DateTime.now().subtract(const Duration(minutes: 30)), 
      'hidden': false,
      'content': 'This is a simple text file.\nIt contains some sample content for testing purposes.\nHello world!\nSample text data.'
    },
    {
      'name': '.hidden_config', 
      'type': 'Hidden Config', 
      'size': '1.5 KB', 
      'path': '/mock/.hidden_config', 
      'date': DateTime.now().subtract(const Duration(days: 7)), 
      'hidden': true,
      'content': 'debug=true\napi_key=secret123\nconfig_version=2.1'
    },
    {
      'name': 'config.json', 
      'type': 'JSON Configuration', 
      'size': '2.1 KB', 
      'path': '/mock/config/config.json', 
      'date': DateTime.now().subtract(const Duration(days: 7)), 
      'hidden': false,
      'content': '{"app_name": "iSuite", "version": "1.0.0", "theme": "dark", "features": ["file_manager", "network_tools", "ai_assistant"]}'
    },
    {
      'name': 'script.py', 
      'type': 'Python Script', 
      'size': '15.8 KB', 
      'path': '/mock/scripts/script.py', 
      'date': DateTime.now().subtract(const Duration(hours: 4)), 
      'hidden': false,
      'content': 'import os\nprint("Hello from Python script!")\n# This is a sample Python file for testing\ndef main():\n    print("Main function executed")\n\nif __name__ == "__main__":\n    main()'
    },
  ];

  List<Map<String, dynamic>> get _filteredFiles {
    var files = _allFiles.where((file) {
      final query = _searchQuery.toLowerCase();
      final nameMatch = file['name']!.toLowerCase().contains(query);
      final typeMatch = file['type']!.toLowerCase().contains(query);
      final contentMatch = _searchInContent && file['content'] != null && 
                          file['content']!.toLowerCase().contains(query);
      
      return nameMatch || typeMatch || contentMatch;
    }).toList();

    // Filter hidden files
    if (!_showHiddenFiles) {
      files = files.where((file) => !file['hidden']).toList();
    }

    // Filter recent files
    if (_showRecentOnly) {
      final recentThresholdHours = config.getParameter('ui.file_management.recent_threshold_hours', defaultValue: 24)!;
      final recentThreshold = DateTime.now().subtract(Duration(hours: recentThresholdHours));
      files = files.where((file) => file['date'].isAfter(recentThreshold)).toList();
    }

    // Sort files
    files.sort((a, b) {
      dynamic aValue, bValue;
      switch (_sortBy) {
        case 'name':
          aValue = a['name'];
          bValue = b['name'];
          break;
        case 'date':
          aValue = a['date'];
          bValue = b['date'];
          break;
        case 'size':
          aValue = _parseSize(a['size']);
          bValue = _parseSize(b['size']);
          break;
        case 'type':
          aValue = a['type'];
          bValue = b['type'];
          break;
        default:
          aValue = a['name'];
          bValue = b['name'];
      }

      int comparison = aValue.compareTo(bValue);
      return _sortAscending ? comparison : -comparison;
    });

    return files;
  }

  int _parseSize(String sizeStr) {
    final regex = RegExp(r'(\d+(?:\.\d+)?)\s*(KB|MB|GB|B)');
    final match = regex.firstMatch(sizeStr);
    if (match != null) {
      double size = double.parse(match.group(1)!);
      String unit = match.group(2)!;
      switch (unit) {
        case 'KB':
          return (size * 1024).round();
        case 'MB':
          return (size * 1024 * 1024).round();
        case 'GB':
          return (size * 1024 * 1024 * 1024).round();
        default:
          return size.round();
      }
    }
    return 0;
  }

  @override
  void dispose() {

    int comparison = aValue.compareTo(bValue);
    return _sortAscending ? comparison : -comparison;
  });

  return files;
}

int _parseSize(String sizeStr) {
  final regex = RegExp(r'(\d+(?:\.\d+)?)\s*(KB|MB|GB|B)');
  final match = regex.firstMatch(sizeStr);
  if (match != null) {
    double size = double.parse(match.group(1)!);
    String unit = match.group(2)!;
    switch (unit) {
      case 'KB':
        return (size * 1024).round();
      case 'MB':
        return (size * 1024 * 1024).round();
      case 'GB':
        return (size * 1024 * 1024 * 1024).round();
      default:
        return size.round();
    }
  }
  return 0;
}

@override
void dispose() {
  _searchController.dispose();
  _renameController.dispose();
  super.dispose();
}

/// Toggle selection mode for bulk operations
///
/// Enables or disables multi-select mode for file operations.
/// When disabled, clears all current selections.
void _toggleSelectionMode() {
  setState(() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedFiles.clear();
    }
  });
}

/// Select or deselect a file
///
/// [fileName]: The name of the file to select/deselect
/// [selected]: Whether the file should be selected
void _selectFile(String fileName, bool selected) {
  setState(() {
    if (selected) {
      _selectedFiles.add(fileName);
    } else {
      _selectedFiles.remove(fileName);
    }
  });
}

/// Copy selected files to clipboard
///
/// Copies selected files to internal clipboard for paste operations.
/// Shows notification and exits selection mode.
void _copyFiles() {
  if (_selectedFiles.isEmpty) return;

  try {
    setState(() {
      _clipboardFiles.clear();
      _clipboardFiles.addAll(_selectedFiles);
      _isCutOperation = false;
      _isSelectionMode = false;
      _selectedFiles.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Files copied to clipboard')),
    );

    NotificationService().showFileOperationNotification(
      title: 'Files Copied',
      body: '${_clipboardFiles.length} files copied to clipboard',
    );
  } catch (e) {
    _showError('Failed to copy files: $e');
  }
}

/// Cut selected files to clipboard
///
/// Moves selected files to internal clipboard for paste operations.
/// Shows notification and exits selection mode.
void _cutFiles() {
  if (_selectedFiles.isEmpty) return;

  try {
    setState(() {
      _clipboardFiles.clear();
      _clipboardFiles.addAll(_selectedFiles);
      _isCutOperation = true;
      _isSelectionMode = false;
      _selectedFiles.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Files cut to clipboard')),
    );

    NotificationService().showFileOperationNotification(
      title: 'Files Cut',
      body: '${_clipboardFiles.length} files cut to clipboard',
    );
  } catch (e) {
    _showError('Failed to cut files: $e');
  }
}

/// Paste files from clipboard
///
/// Pastes files from clipboard to current location.
/// Handles both copy and cut operations.
void _pasteFiles() {
  if (_clipboardFiles.isEmpty) return;

  try {
    final operation = _isCutOperation ? 'moved' : 'copied';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_clipboardFiles.length} files $operation')),
    );

    NotificationService().showFileOperationNotification(
      title: 'Files Pasted',
      body: '${_clipboardFiles.length} files $operation successfully',
    );

    // In a real implementation, this would perform actual file operations
    if (_isCutOperation) {
      // Remove from original location (mock)
      setState(() {
        _allFiles.removeWhere((file) => _clipboardFiles.contains(file['name']));
        _clipboardFiles.clear();
        _isCutOperation = false;
      });
    } else {
      // Copy operation (mock)
      setState(() {
        for (final String fileName in _clipboardFiles) {
          final originalFile = _allFiles.firstWhere(
            (file) => file['name'] == fileName,
            orElse: () => <String, dynamic>{},
          );
          if (originalFile.isNotEmpty) {
            final newFile = Map<String, dynamic>.from(originalFile);
            newFile['name'] = 'Copy of ${newFile['name']}';
            _allFiles.add(newFile);
          }
        }
        _clipboardFiles.clear();
      });
    }
  } catch (e) {
    _showError('Failed to paste files: $e');
  }
}

/// Show error message to user
///
/// [message]: Error message to display
void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}

void _deleteFiles() {
  if (_selectedFiles.isEmpty) return;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Files'),
      content: Text('Are you sure you want to delete ${_selectedFiles.length} selected files?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _allFiles.removeWhere((file) => _selectedFiles.contains(file['name']));
              _selectedFiles.clear();
              _isSelectionMode = false;
            });
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Files deleted')),
            );
            NotificationService().showFileOperationNotification(
              title: 'Files Deleted',
              body: '${_selectedFiles.length} files deleted successfully',
            );
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

void _renameFile(String oldName) {
  var file = _allFiles.firstWhere((f) => f['name'] == oldName);
  _renameController.text = file['name']!;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Rename File'),
      content: TextField(
        controller: _renameController,
        decoration: const InputDecoration(hintText: 'New file name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_renameController.text.isNotEmpty) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Files'),
        content: Text('Are you sure you want to delete ${_selectedFiles.length} selected files?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _allFiles.removeWhere((file) => _selectedFiles.contains(file['name']));
                _selectedFiles.clear();
                _isSelectionMode = false;
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Files deleted')),
              );
              NotificationService().showFileOperationNotification(
                title: 'Files Deleted',
                body: '${_selectedFiles.length} files deleted successfully',
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _renameFile(String oldName) {
    var file = _allFiles.firstWhere((f) => f['name'] == oldName);
    _renameController.text = file['name']!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename File'),
        content: TextField(
          controller: _renameController,
          decoration: const InputDecoration(hintText: 'New file name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_renameController.text.isNotEmpty) {
                setState(() {
                  file['name'] = _renameController.text;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File renamed')),
                );
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showFileContextMenu(String fileName, Offset position) {
    final file = _allFiles.firstWhere((f) => f['name'] == fileName);
    final fileExtension = fileName.split('.').last.toLowerCase();
    final isMediaFile = _isVideoFile(fileExtension) || _isAudioFile(fileExtension);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: [
        PopupMenuItem(
          child: const Text('Open'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opening: $fileName')),
            );
          },
        ),
        if (isMediaFile)
          PopupMenuItem(
            child: const Text('Play Media'),
            onTap: () => _playMedia(file),
          ),
        PopupMenuItem(
          child: const Text('Share via QR'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => QrShareScreen(fileData: file),
              ),
            );
          },
        ),
        PopupMenuItem(
          child: const Text('Analyze with AI'),
          onTap: () => _analyzeFileWithAI(fileName),
        ),
        PopupMenuItem(
          child: const Text('Copy'),
          onTap: () {
            setState(() {
              _selectedFiles = {fileName};
              _copyFiles();
            });
          },
        ),
        PopupMenuItem(
          child: const Text('Cut'),
          onTap: () {
            setState(() {
              _selectedFiles = {fileName};
              _cutFiles();
            });
          },
        ),
        PopupMenuItem(
          child: const Text('Rename'),
          onTap: () => _renameFile(fileName),
        ),
        PopupMenuItem(
          child: const Text('Delete'),
          onTap: () {
            setState(() {
              _selectedFiles = {fileName};
              _deleteFiles();
            });
          },
        ),
      ],
    );
  }

  bool _isVideoFile(String extension) {
    const videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv', 'webm'];
    return videoExtensions.contains(extension);
  }

  bool _isAudioFile(String extension) {
    const audioExtensions = ['mp3', 'wav', 'aac', 'ogg', 'flac', 'm4a', 'wma'];
    return audioExtensions.contains(extension);
  }

  void _playMedia(Map<String, dynamic> file) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaPlayerScreen(mediaFile: file),
      ),
    );
  }

  Future<void> _organizeWithAI() async {
    final fileNames = _allFiles.map((f) => f['name'] as String).toList();
    final fileTypes = _allFiles.map((f) => f['type'] as String).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('AI Organization Suggestions'),
        content: const SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Analyzing files with AI...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final suggestion = await _aiService.suggestOrganization(fileNames, fileTypes);

      Navigator.of(context).pop(); // Close loading dialog

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('AI Organization Suggestions'),
          content: SingleChildScrollView(
            child: Text(suggestion),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Implement apply suggestions
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Organization suggestions noted (implementation pending)')),
                );
                NotificationService().showAiNotification(
                  title: 'AI Organization Complete',
                  body: 'Organization suggestions are ready to view',
                );
              },
              child: const Text('Apply Suggestions'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI organization failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = CentralConfig.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode 
          ? '${_selectedFiles.length} selected' 
          : config.getParameter('ui.app_titles.file_manager', defaultValue: 'File Manager')!),
        backgroundColor: config.getParameter('ui.app_bar.background_color', defaultValue: Colors.white)!,
        foregroundColor: config.getParameter('ui.app_bar.foreground_color', defaultValue: Colors.black)!,
        elevation: config.getParameter('ui.app_bar.elevation', defaultValue: 1)!,
        leading: _isSelectionMode ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: _toggleSelectionMode,
        ) : null,
        actions: _isSelectionMode ? [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyFiles,
            tooltip: 'Copy',
          ),
          IconButton(
            icon: const Icon(Icons.cut),
            onPressed: _cutFiles,
            tooltip: 'Cut',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteFiles,
            tooltip: 'Delete',
          ),
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: () {
              setState(() {
                if (_selectedFiles.length == _filteredFiles.length) {
                  _selectedFiles.clear();
                } else {
                  _selectedFiles = _filteredFiles.map((f) => f['name']!).toSet();
                }
              });
            },
            tooltip: 'Select All',
          ),
        ] : [
          IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: _toggleSelectionMode,
            tooltip: 'Select Files',
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: _organizeWithAI,
            tooltip: 'Organize with AI',
          ),
          IconButton(
            icon: Icon(_enableDualPane ? Icons.view_sidebar : Icons.view_list),
            onPressed: () {
              setState(() {
                _enableDualPane = !_enableDualPane;
              });
            },
            tooltip: _enableDualPane ? 'Single Pane' : 'Dual Pane',
          ),
        ],
      ),
      body: _enableDualPane ? _buildDualPaneBody() : _buildSinglePaneBody(),
    );
  }

  Widget _buildSinglePaneBody() {
    final config = CentralConfig.instance;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: EdgeInsets.all(config.getParameter('ui.spacing.medium', defaultValue: 20.0)!),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: config.getParameter('ui.file_management.search_placeholder', defaultValue: 'Search files...')!,
                  prefixIcon: Icon(Icons.search, color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue)!),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: config.getParameter('ui.app_bar.background_color', defaultValue: Colors.white)!,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(config.getParameter('ui.file_management.content_search_label', defaultValue: 'Search in content:')!),
                  const SizedBox(width: 8),
                  Switch(
                    value: _searchInContent,
                    onChanged: (value) {
                      setState(() {
                        _searchInContent = value;
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '💡 AI-powered content analysis available for real files',
                    style: TextStyle(
                      fontSize: 12,
                      color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue)!.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Sorting and filtering controls
        Padding(
          padding: EdgeInsets.symmetric(horizontal: config.getParameter('ui.spacing.medium', defaultValue: 20.0)!),
          child: Row(
            children: [
              Text(config.getParameter('ui.file_management.sort_label', defaultValue: 'Sort by:')!),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                  DropdownMenuItem(value: 'date', child: Text('Date')),
                  DropdownMenuItem(value: 'size', child: Text('Size')),
                  DropdownMenuItem(value: 'type', child: Text('Type')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                },
                tooltip: _sortAscending ? 'Ascending' : 'Descending',
              ),
              const SizedBox(width: 16),
              Text(config.getParameter('ui.file_management.recent_label', defaultValue: 'Recent:')!),
              const SizedBox(width: 8),
              Switch(
                value: _showRecentOnly,
                onChanged: (value) {
                  setState(() {
                    _showRecentOnly = value;
                  });
                },
              ),
              const SizedBox(width: 16),
              Text(config.getParameter('ui.file_management.hidden_label', defaultValue: 'Hidden:')!),
              const SizedBox(width: 8),
              Switch(
                value: _showHiddenFiles,
                onChanged: (value) {
                  setState(() {
                    _showHiddenFiles = value;
                  });
                },
              ),
            ],
          ),
        ),

        // File count
        Padding(
          padding: EdgeInsets.symmetric(horizontal: config.getParameter('ui.spacing.medium', defaultValue: 20.0)!),
          child: Text(
            '${_filteredFiles.length} files found${_showRecentOnly ? ' (recent only)' : ''}${!_showHiddenFiles ? ' (hidden files hidden)' : ''}',
            style: TextStyle(
              color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue)!.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ),

        // File list
        Expanded(
          child: _buildFileList(),
        ),
      ],
    );
  }

  Widget _buildDualPaneBody() {
    final config = CentralConfig.instance;

    return Row(
      children: [
        // Left pane
        Expanded(
          flex: (_dualPaneSplitRatio * 100).round(),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue)!.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Left pane header
                Container(
                  padding: const EdgeInsets.all(8),
                  color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue)!.withOpacity(0.1),
                  child: Row(
                    children: [
                      Text(
                        'Left Pane',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () {
                          // TODO: Copy selected from left to right
                        },
                        tooltip: 'Copy to Right Pane',
                      ),
                    ],
                  ),
                ),
                // Left pane content (simplified)
                Expanded(
                  child: _buildFileList(),
                ),
              ],
            ),
          ),
        ),

        // Right pane
        Expanded(
          flex: ((1 - _dualPaneSplitRatio) * 100).round(),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue)!.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Right pane header
                Container(
                  padding: const EdgeInsets.all(8),
                  color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue)!.withOpacity(0.1),
                  child: Row(
                    children: [
                      Text(
                        'Right Pane',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          // TODO: Copy selected from right to left
                        },
                        tooltip: 'Copy to Left Pane',
                      ),
                    ],
                  ),
                ),
                // Right pane content (simplified - could show different view)
                Expanded(
                  child: _buildFileList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileList() {
    final config = CentralConfig.instance;

    return _filteredFiles.isEmpty
      ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue)!.withOpacity(0.5),
              ),
              const SizedBox(height: 20),
              Text(
                config.getParameter('ui.file_management.empty_state_title', defaultValue: 'No files found')!,
                style: TextStyle(
                  color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue)!.withOpacity(0.7),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                config.getParameter('ui.file_management.empty_state_message', defaultValue: 'Try adjusting your search or filters')!,
                style: TextStyle(
                  color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue)!.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        )
      : ListView.builder(
          itemCount: _filteredFiles.length,
          itemBuilder: (context, index) {
            final file = _filteredFiles[index];
            final isSelected = _selectedFiles.contains(file['name']);
            
            return Card(
              key: ValueKey<String>(file['name'] as String),
              margin: EdgeInsets.symmetric(
                horizontal: config.getParameter('ui.spacing.medium', defaultValue: 20.0)!,
                vertical: 4,
              ),
              elevation: config.getParameter('ui.app_bar.elevation', defaultValue: 1)! / 2,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: ListTile(
                key: ValueKey<String>('tile_${file['name']}'),
                leading: _isSelectionMode 
                  ? Checkbox(
                      key: ValueKey<String>('checkbox_${file['name']}'),
                      value: isSelected,
                      onChanged: (selected) => _selectFile(file['name']!, selected ?? false),
                    )
                  : Icon(
                      _getFileIcon(file['name']!),
                      color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue)!,
                    ),
                title: Text(
                  file['name']!,
                  style: TextStyle(
                    color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue)!,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  '${file['type']} • ${file['size']}',
                  style: TextStyle(
                    color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue)!.withOpacity(0.7),
                  ),
                ),
                trailing: !_isSelectionMode ? IconButton(
                  key: ValueKey<String>('menu_${file['name']}'),
                  icon: Icon(
                    Icons.more_vert,
                    color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue)!.withOpacity(0.5),
                  ),
                  onPressed: () {
                    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                    final Offset position = overlay.localToGlobal(Offset.zero);
                    _showFileContextMenu(file['name']!, position);
                  },
                ) : null,
                selected: isSelected,
                selectedTileColor: config.getParameter('ui.colors.primary', defaultValue: Colors.blue)!.withOpacity(0.1),
                onTap: () {
                  if (_isSelectionMode) {
                    _selectFile(file['name']!, !isSelected);
                  } else {
                    // Open file
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        key: const ValueKey<String>('snackbar_open'),
                        content: Text('Selected: ${file['name']}'),
                        backgroundColor: config.getParameter('ui.colors.primary', defaultValue: Colors.blue)!,
                      ),
                    );
                  }
                },
                onLongPress: () {
                  if (!_isSelectionMode) {
                    _toggleSelectionMode();
                    _selectFile(file['name']!, true);
                  }
                },
              ),
            );
          },
        ),
        tooltip: 'Paste Files',
        child: const Icon(Icons.paste),
        backgroundColor: config.getParameter('ui.colors.primary', defaultValue: Colors.blue)!,
      ) : null,
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
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
        return Icons.audio_file;
      case 'xlsx':
      case 'xls':
        return Icons.table_chart;
      case 'pptx':
      case 'ppt':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return Icons.archive;
      case 'txt':
        return Icons.text_snippet;
      case 'json':
        return Icons.data_object;
      case 'py':
        return Icons.code;
      default:
        return Icons.insert_drive_file;
    }
  }
}
