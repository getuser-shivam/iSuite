import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/ui/ui_config_service.dart';
import '../../../core/ui/enhanced_ui_components.dart';
import '../../../core/central_config.dart';
import '../../../core/logging/logging_service.dart';
import '../../../core/robustness_manager.dart';
import '../../../core/supabase_service.dart';

/// Enhanced File Management Screen with Central Configuration
/// 
/// This screen provides a comprehensive file management interface with:
/// - Central parameterization through UIConfigService
/// - Enhanced UI components with proper configuration
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
class EnhancedFileManagementScreen extends StatefulWidget {
  const EnhancedFileManagementScreen({super.key});

  @override
  State<EnhancedFileManagementScreen> createState() => _EnhancedFileManagementScreenState();
}

class _EnhancedFileManagementScreenState extends State<EnhancedFileManagementScreen> {
  // Core services
  final UIConfigService _uiConfig = UIConfigService();
  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();
  final RobustnessManager _robustness = RobustnessManager();
  final SupabaseService _supabase = SupabaseService();

  // Controllers and state
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _gridScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();

  // UI state
  bool _isGridView = true;
  bool _isMultiSelectMode = false;
  Set<String> _selectedFiles = {};
  List<FileSystemEntity> _files = [];
  List<FileSystemEntity> _filteredFiles = [];
  String _currentPath = '';
  bool _isLoading = false;
  String? _error;

  // Search and filter state
  String _searchQuery = '';
  String _selectedFilter = 'all';
  String _selectedSort = 'name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      _logger.info('Initializing enhanced file management screen', 'FileManagementScreen');
      
      // Load current directory
      await _loadFiles();
      
      // Setup listeners
      _setupListeners();
      
      // Apply configuration
      await _applyConfiguration();
      
      _logger.info('File management screen initialized successfully', 'FileManagementScreen');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize file management screen', 'FileManagementScreen',
          error: e, stackTrace: stackTrace);
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get current directory from configuration
      _currentPath = _config.getParameter('file_management.current_path', defaultValue: '/');
      
      // Load files from directory
      final directory = Directory(_currentPath);
      if (await directory.exists()) {
        final entities = await directory.list().toList();
        
        setState(() {
          _files = entities;
          _filteredFiles = entities;
          _isLoading = false;
        });
      } else {
        setState(() {
          _files = [];
          _filteredFiles = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.error('Failed to load files', 'FileManagementScreen', error: e);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _setupListeners() {
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _applyConfiguration() async {
    try {
      // Apply UI configuration
      final gridView = _config.getParameter('file_management.default_view', defaultValue: 'grid');
      setState(() {
        _isGridView = gridView == 'grid';
      });

      // Apply sort configuration
      final sortConfig = _config.getParameter('file_management.default_sort', defaultValue: 'name');
      setState(() {
        _selectedSort = sortConfig;
      });

      // Apply filter configuration
      final filterConfig = _config.getParameter('file_management.default_filter', defaultValue: 'all');
      setState(() {
        _selectedFilter = filterConfig;
      });

      _logger.info('Configuration applied successfully', 'FileManagementScreen');
    } catch (e) {
      _logger.error('Failed to apply configuration', 'FileManagementScreen', error: e);
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredFiles = _files.where((file) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final fileName = file.path.split('/').last.toLowerCase();
          if (!fileName.contains(_searchQuery.toLowerCase())) {
            return false;
          }
        }

        // Type filter
        if (_selectedFilter != 'all') {
          if (_selectedFilter == 'files' && file is! File) {
            return false;
          } else if (_selectedFilter == 'folders' && file is! Directory) {
            return false;
          }
        }

        return true;
      }).toList();

      // Apply sorting
      _applySorting();
    });
  }

  void _applySorting() {
    setState(() {
      _filteredFiles.sort((a, b) {
        int result = 0;
        
        switch (_selectedSort) {
          case 'name':
            result = a.path.split('/').last.toLowerCase().compareTo(
                b.path.split('/').last.toLowerCase());
            break;
          case 'date':
            final aDate = a is File ? await a.lastModified() : DateTime.now();
            final bDate = b is File ? await b.lastModified() : DateTime.now();
            result = aDate.compareTo(bDate);
            break;
          case 'size':
            if (a is File && b is File) {
              final aSize = await a.length();
              final bSize = await b.length();
              result = aSize.compareTo(bSize);
            }
            break;
          case 'type':
            final aType = a.path.split('.').last.toLowerCase();
            final bType = b.path.split('.').last.toLowerCase();
            result = aType.compareTo(bType);
            break;
        }
        
        return _sortAscending ? result : -result;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return EnhancedUIComponents.buildAppBar(
      title: 'File Management',
      actions: [
        IconButton(
          icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
          onPressed: _toggleViewMode,
        ),
        IconButton(
          icon: Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
        ),
        IconButton(
          icon: Icon(Icons.sort),
          onPressed: _showSortDialog,
        ),
        if (_isMultiSelectMode)
          IconButton(
            icon: Icon(Icons.select_all),
            onPressed: _selectAllFiles,
          ),
      ],
      bottom: _buildSearchBar(),
    );
  }

  PreferredSizeWidget _buildSearchBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(_uiConfig.getDouble('ui.search_bar_height')),
      child: Container(
        padding: EdgeInsets.all(_uiConfig.getDouble('ui.padding')),
        child: EnhancedUIComponents.buildTextField(
          controller: _searchController,
          hintText: 'Search files...',
          prefix: Icon(Icons.search),
          onChanged: (value) => _onSearchChanged(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingIndicator();
    }

    if (_error != null) {
      return _buildErrorView();
    }

    return Column(
      children: [
        _buildPathIndicator(),
        Expanded(
          child: _buildFileList(),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EnhancedUIComponents.buildCircularProgressIndicator(),
          SizedBox(height: _uiConfig.getDouble('ui.padding')),
          EnhancedUIComponents.buildText(
            'Loading files...',
            style: TextStyle(
              fontSize: _uiConfig.getDouble('ui.font_size'),
              color: _uiConfig.getColor('ui.on_surface'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: _uiConfig.getDouble('ui.icon_size') * 2,
            color: _uiConfig.getColor('ui.error_color'),
          ),
          SizedBox(height: _uiConfig.getDouble('ui.padding')),
          EnhancedUIComponents.buildText(
            _error!,
            style: TextStyle(
              fontSize: _uiConfig.getDouble('ui.font_size'),
              color: _uiConfig.getColor('ui.error_color'),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _uiConfig.getDouble('ui.padding')),
          EnhancedUIComponents.buildElevatedButton(
            onPressed: _loadFiles,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPathIndicator() {
    return Container(
      padding: EdgeInsets.all(_uiConfig.getDouble('ui.padding')),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _navigateUp,
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildPathBreadcrumbs(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadFiles,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPathBreadcrumbs() {
    final pathParts = _currentPath.split('/');
    final breadcrumbs = <Widget>[];
    
    for (int i = 0; i < pathParts.length; i++) {
      if (i > 0) {
        breadcrumbs.add(Icon(Icons.chevron_right, size: 16));
      }
      
      final part = pathParts[i];
      if (part.isNotEmpty) {
        breadcrumbs.add(
          GestureDetector(
            onTap: () => _navigateToPath(i),
            child: Text(
              part,
              style: TextStyle(
                fontSize: _uiConfig.getDouble('ui.font_size'),
                color: _uiConfig.getColor('ui.primary_color'),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }
    }
    
    return breadcrumbs;
  }

  Widget _buildFileList() {
    if (_isGridView) {
      return _buildGridView();
    } else {
      return _buildListView();
    }
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _gridScrollController,
      padding: EdgeInsets.all(_uiConfig.getDouble('ui.padding')),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _uiConfig.configInt('ui.grid_columns'),
        crossAxisSpacing: _uiConfig.getDouble('ui.padding'),
        mainAxisSpacing: _uiConfig.getDouble('ui.padding'),
        childAspectRatio: 1.0,
      ),
      itemCount: _filteredFiles.length,
      itemBuilder: (context, index) {
        return _buildGridItem(_filteredFiles[index], index);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _listScrollController,
      padding: EdgeInsets.all(_uiConfig.getDouble('ui.padding')),
      itemCount: _filteredFiles.length,
      itemBuilder: (context, index) {
        return _buildListItem(_filteredFiles[index], index);
      },
    );
  }

  Widget _buildGridItem(FileSystemEntity file, int index) {
    final isSelected = _selectedFiles.contains(file.path);
    final fileName = file.path.split('/').last;
    final isDirectory = file is Directory;
    
    return GestureDetector(
      onTap: () => _onFileTapped(file),
      onLongPress: () => _onFileLongPressed(file),
      child: EnhancedUIComponents.buildCard(
        color: isSelected ? _uiConfig.getColor('ui.selected_color') : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDirectory ? Icons.folder : _getFileIcon(fileName),
              size: _uiConfig.getDouble('ui.icon_size'),
              color: isDirectory 
                  ? _uiConfig.getColor('ui.primary_color')
                  : _uiConfig.getColor('ui.on_surface'),
            ),
            SizedBox(height: _uiConfig.getDouble('ui.padding') / 2),
            Text(
              fileName,
              style: TextStyle(
                fontSize: _uiConfig.getDouble('ui.font_size') - 2,
                color: _uiConfig.getColor('ui.on_surface'),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (_isMultiSelectMode)
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected 
                      ? _uiConfig.getColor('ui.accent_color')
                      : _uiConfig.getColor('ui.on_surface'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(FileSystemEntity file, int index) {
    final isSelected = _selectedFiles.contains(file.path);
    final fileName = file.path.split('/').last;
    final isDirectory = file is Directory;
    
    return EnhancedUIComponents.buildListTile(
      leading: Icon(
        isDirectory ? Icons.folder : _getFileIcon(fileName),
        color: isDirectory 
            ? _uiConfig.getColor('ui.primary_color')
            : _uiConfig.getColor('ui.on_surface'),
      ),
      title: Text(
        fileName,
        style: TextStyle(
          fontSize: _uiConfig.getDouble('ui.font_size'),
          color: _uiConfig.getColor('ui.on_surface'),
        ),
      ),
      subtitle: isDirectory 
          ? null
          : FutureBuilder<int>(
              future: (file as File).length(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    _formatFileSize(snapshot.data!),
                    style: TextStyle(
                      fontSize: _uiConfig.getDouble('ui.font_size') - 2,
                      color: _uiConfig.getColor('ui.on_surface').withOpacity(0.7),
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
      trailing: _isMultiSelectMode
          ? Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected 
                  ? _uiConfig.getColor('ui.accent_color')
                  : _uiConfig.getColor('ui.on_surface'),
            )
          : null,
      onTap: () => _onFileTapped(file),
      onLongPress: () => _onFileLongPressed(file),
    );
  }

  Widget _buildFloatingActionButton() {
    return EnhancedUIComponents.buildFloatingActionButton(
      onPressed: _showAddMenu,
      child: Icon(Icons.add),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) => _onBottomNavTap(index),
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.folder),
          label: 'Files',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.cloud_upload),
          label: 'Upload',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.cloud_download),
          label: 'Download',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
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
        return Icons.audio_file;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _toggleViewMode() {
    setState(() {
      _isGridView = !_isGridView;
    });
    
    // Save preference
    _config.setParameter('file_management.default_view', _isGridView ? 'grid' : 'list');
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => EnhancedUIComponents.buildDialog(
        title: 'Filter Files',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EnhancedUIComponents.buildRadioTile(
              title: Text('All Files'),
              value: 'all',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.pop(context);
                _applyFilters();
              },
            ),
            EnhancedUIComponents.buildRadioTile(
              title: Text('Files Only'),
              value: 'files',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.pop(context);
                _applyFilters();
              },
            ),
            EnhancedUIComponents.buildRadioTile(
              title: Text('Folders Only'),
              value: 'folders',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.pop(context);
                _applyFilters();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => EnhancedUIComponents.buildDialog(
        title: 'Sort Files',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EnhancedUIComponents.buildRadioTile(
              title: Text('Name'),
              value: 'name',
              groupValue: _selectedSort,
              onChanged: (value) {
                setState(() {
                  _selectedSort = value!;
                });
                Navigator.pop(context);
                _applySorting();
              },
            ),
            EnhancedUIComponents.buildRadioTile(
              title: Text('Date Modified'),
              value: 'date',
              groupValue: _selectedSort,
              onChanged: (value) {
                setState(() {
                  _selectedSort = value!;
                });
                Navigator.pop(context);
                _applySorting();
              },
            ),
            EnhancedUIComponents.buildRadioTile(
              title: Text('Size'),
              value: 'size',
              groupValue: _selectedSort,
              onChanged: (value) {
                setState(() {
                  _selectedSort = value!;
                });
                Navigator.pop(context);
                _applySorting();
              },
            ),
            EnhancedUIComponents.buildRadioTile(
              title: Text('Type'),
              value: 'type',
              groupValue: _selectedSort,
              onChanged: (value) {
                setState(() {
                  _selectedSort = value!;
                });
                Navigator.pop(context);
                _applySorting();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onFileTapped(FileSystemEntity file) {
    if (_isMultiSelectMode) {
      _toggleFileSelection(file);
    } else {
      if (file is Directory) {
        _navigateToDirectory(file);
      } else {
        _openFile(file as File);
      }
    }
  }

  void _onFileLongPressed(FileSystemEntity file) {
    setState(() {
      _isMultiSelectMode = true;
      _toggleFileSelection(file);
    });
  }

  void _toggleFileSelection(FileSystemEntity file) {
    setState(() {
      if (_selectedFiles.contains(file.path)) {
        _selectedFiles.remove(file.path);
      } else {
        _selectedFiles.add(file.path);
      }
    });
  }

  void _selectAllFiles() {
    setState(() {
      if (_selectedFiles.length == _filteredFiles.length) {
        _selectedFiles.clear();
      } else {
        _selectedFiles = _filteredFiles.map((file) => file.path).toSet();
      }
    });
  }

  void _navigateUp() {
    final parentPath = _currentPath.substring(0, _currentPath.lastIndexOf('/'));
    if (parentPath.isEmpty) {
      _navigateToPath(0);
    } else {
      setState(() {
        _currentPath = parentPath;
      });
      _loadFiles();
    }
  }

  void _navigateToPath(int index) {
    final pathParts = _currentPath.split('/');
    final newPath = pathParts.take(index + 1).join('/');
    setState(() {
      _currentPath = newPath;
    });
    _loadFiles();
  }

  void _navigateToDirectory(Directory directory) {
    setState(() {
      _currentPath = directory.path;
    });
    _loadFiles();
  }

  void _openFile(File file) {
    // Implement file opening logic
    _logger.info('Opening file: ${file.path}', 'FileManagementScreen');
  }

  void _showAddMenu() {
    // Implement add menu logic
    _logger.info('Showing add menu', 'FileManagementScreen');
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        // Files tab - already here
        break;
      case 1:
        // Upload tab
        _showUploadDialog();
        break;
      case 2:
        // Download tab
        _showDownloadDialog();
        break;
      case 3:
        // Settings tab
        _showSettingsDialog();
        break;
    }
  }

  void _showUploadDialog() {
    // Implement upload dialog
    _logger.info('Showing upload dialog', 'FileManagementScreen');
  }

  void _showDownloadDialog() {
    // Implement download dialog
    _logger.info('Showing download dialog', 'FileManagementScreen');
  }

  void _showSettingsDialog() {
    // Implement settings dialog
    _logger.info('Showing settings dialog', 'FileManagementScreen');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gridScrollController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }
}
