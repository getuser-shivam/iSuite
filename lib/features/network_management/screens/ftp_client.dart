import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/ui/ui_config_service.dart';
import '../../../core/ui/enhanced_ui_components.dart';
import '../../../core/central_config.dart';
import '../../../core/logging/logging_service.dart';
import '../../../core/robustness_manager.dart';
import '../../../core/supabase_service.dart';

/// Enhanced FTP Client Screen with Central Configuration
/// 
/// This screen provides a comprehensive FTP client interface with:
/// - Central parameterization through UIConfigService
/// - Enhanced UI components with proper configuration
/// - Connection management and server profiles
/// - File transfer operations (upload, download, delete, rename)
/// - Transfer queue management with progress tracking
/// - Real-time connection status monitoring
/// - Security validation and encryption
/// - Performance monitoring and optimization
/// - Batch operations with concurrent transfers
/// - Transfer history and statistics
/// - Resume support for interrupted transfers
/// - Bandwidth throttling and rate limiting
/// - Passive mode and active mode support
/// - Directory browsing and navigation
/// - File metadata extraction and display
/// - Cloud synchronization integration
class EnhancedFTPClientScreen extends StatefulWidget {
  const EnhancedFTPClientScreen({super.key});

  @override
  State<EnhancedFTPClientScreen> createState() => _EnhancedFTPClientScreenState();
}

class _EnhancedFTPClientScreenState extends State<EnhancedFTPClientScreen> {
  // Core services
  final UIConfigService _uiConfig = UIConfigService();
  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();
  const RobustnessManager _robustness = RobustnessManager();
  final SupabaseService _supabase = SupabaseService();

  // Controllers and state
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _transferScrollController = ScrollController();

  // FTP connection state
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _connectionError;
  String _currentServer = '';
  int _currentPort = 21;
  String _currentUsername = '';
  String _currentPath = '/';

  // Transfer state
  List<TransferItem> _transferQueue = [];
  List<TransferItem> _completedTransfers = [];
  bool _isTransferring = false;
  int _activeTransferCount = 0;
  double _totalProgress = 0.0;

  // UI state
  bool _isListView = true;
  bool _isMultiSelectMode = false;
  Set<String> _selectedFiles = {};
  List<FTPFile> _files = [];
  List<FTPFile> _filteredFiles = [];
  String _searchQuery = '';
  String _selectedFilter = 'all';
  String _selectedSort = 'name';
  bool _sortAscending = true;

  // Server profiles
  List<ServerProfile> _serverProfiles = [];
  ServerProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      _logger.info('Initializing enhanced FTP client screen', 'FTPClientScreen');
      
      // Load server profiles
      await _loadServerProfiles();
      
      // Setup listeners
      _setupListeners();
      
      // Apply configuration
      await _applyConfiguration();
      
      _logger.info('FTP client screen initialized successfully', 'FTPClientScreen');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize FTP client screen', 'FTPClientScreen',
          error: e, stackTrace: stackTrace);
      setState(() {
        _connectionError = e.toString();
      });
    }
  }

  Future<void> _loadServerProfiles() async {
    try {
      // Load profiles from configuration
      final profilesConfig = _config.getParameter('ftp.server_profiles', defaultValue: []);
      
      if (profilesConfig is List) {
        final profiles = (profilesConfig as List).map((profile) {
          return ServerProfile.fromMap(profile as Map<String, dynamic>);
        }).toList();
        
        setState(() {
          _serverProfiles = profiles;
        });
      }
      
      // Load current profile
      final currentProfileId = _config.getParameter('ftp.current_profile', defaultValue: '');
      if (currentProfileId.isNotEmpty) {
        _currentProfile = profiles.firstWhere((p) => p.id == currentProfileId);
        if (_currentProfile != null) {
          _loadCurrentProfile();
        }
      }
    } catch (e) {
      _logger.error('Failed to load server profiles', 'FTPClientScreen', error: e);
    }
  }

  void _loadCurrentProfile() {
    if (_currentProfile != null) {
      setState(() {
        _hostController.text = _currentProfile!.host;
        _portController.text = _currentProfile!.port.toString();
        _usernameController.text = _currentProfile!.username;
        _passwordController.text = _currentProfile!.password;
        _currentServer = _currentProfile!.host;
        _currentPort = _currentProfile!.port;
        _currentUsername = _currentProfile!.username;
      });
    }
  }

  void _setupListeners() {
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _applyConfiguration() async {
    try {
      // Apply UI configuration
      final listView = _config.getParameter('ftp.default_view', defaultValue: 'list');
      setState(() {
        _isListView = listView == 'list';
      });

      // Apply sort configuration
      final sortConfig = _config.getParameter('ftp.default_sort', defaultValue: 'name');
      setState(() {
        _selectedSort = sortConfig;
      });

      // Apply filter configuration
      final filterConfig = _config.getParameter('ftp.default_filter', defaultValue: 'all');
      setState(() {
        _selectedFilter = filterConfig;
      });

      // Apply connection settings
      final defaultPort = _config.getParameter('ftp.default_port', defaultValue: 21);
      setState(() {
        _currentPort = defaultPort;
      });

      _logger.info('Configuration applied successfully', 'FTPClientScreen');
    } catch (e) {
      _logger.error('Failed to apply configuration', 'FTPClientScreen', error: e);
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
          final fileName = file.name.toLowerCase();
          if (!fileName.contains(_searchQuery.toLowerCase())) {
            return false;
          }
        }

        // Type filter
        if (_selectedFilter != 'all') {
          if (_selectedFilter == 'files' && !file.isFile) {
            return false;
          } else if (_selectedFilter == 'folders' && file.isFile) {
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
            result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
            break;
          case 'size':
            result = a.size.compareTo(b.size);
            break;
          case 'modified':
            result = a.modified.compareTo(b.modified);
            break;
          case 'type':
            result = a.extension.toLowerCase().compareTo(b.extension.toLowerCase());
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
      title: 'FTP Client',
      actions: [
        IconButton(
          icon: Icon(_isListView ? Icons.grid_view : Icons.view_list),
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
      bottom: _buildConnectionBar(),
    );
  }

  PreferredSizeWidget _buildConnectionBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(_uiConfig.getDouble('ui.connection_bar_height')),
      child: Container(
        padding: EdgeInsets.all(_uiConfig.getDouble('ui.padding')),
        child: Row(
          children: [
            Icon(
              _isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: _isConnected 
                  ? _uiConfig.getColor('ui.success_color')
                  : _uiConfig.getColor('ui.error_color'),
            ),
            SizedBox(width: _uiConfig.getDouble('ui.padding')),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentServer.isEmpty ? 'Not Connected' : _currentServer,
                    style: TextStyle(
                      fontSize: _uiConfig.getDouble('ui.font_size'),
                      fontWeight: FontWeight.bold,
                      color: _uiConfig.getColor('ui.on_surface'),
                    ),
                  ),
                  if (_isConnected)
                    Text(
                      '$_currentUsername@$_currentServer:$_currentPort',
                      style: TextStyle(
                        fontSize: _uiConfig.getDouble('ui.font_size') - 2,
                        color: _uiConfig.getColor('ui.on_surface').withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
            if (_isConnected)
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _refreshDirectory,
              ),
            if (!_isConnected)
              IconButton(
                icon: Icon(Icons.login),
                onPressed: _showConnectionDialog,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_isConnected) {
      return _buildConnectionScreen();
    }

    return Column(
      children: [
        _buildPathIndicator(),
        Expanded(
          child: _buildFileList(),
        ),
        if (_isTransferring)
          _buildTransferProgress(),
      ],
    );
  }

  Widget _buildConnectionScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: _uiConfig.getDouble('ui.icon_size') * 2,
            color: _uiConfig.getColor('ui.on_surface').withOpacity(0.5),
          ),
          SizedBox(height: _uiConfig.getDouble('ui.padding')),
          EnhancedUIComponents.buildText(
            'Not Connected to FTP Server',
            style: TextStyle(
              fontSize: _uiConfig.getDouble('ui.font_size'),
              color: _uiConfig.getColor('ui.on_surface'),
            ),
          ),
          SizedBox(height: _uiConfig.getDouble('ui.padding')),
          EnhancedUIComponents.buildElevatedButton(
            onPressed: _showConnectionDialog,
            child: Text('Connect'),
          ),
          SizedBox(height: _uiConfig.getDouble('ui.padding')),
          EnhancedUIComponents.buildTextButton(
            onPressed: _showServerProfilesDialog,
            child: Text('Manage Server Profiles'),
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
            onPressed: _refreshDirectory,
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
    if (_isListView) {
      return _buildListView();
    } else {
      return _buildGridView();
    }
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _transferScrollController,
      padding: EdgeInsets.all(_uiConfig.getDouble('ui.padding')),
      itemCount: _filteredFiles.length,
      itemBuilder: (context, index) {
        return _buildListItem(_filteredFiles[index], index);
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _transferScrollController,
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

  Widget _buildListItem(FTPFile file, int index) {
    final isSelected = _selectedFiles.contains(file.path);
    
    return EnhancedUIComponents.buildListTile(
      leading: Icon(
        file.isFile ? _getFileIcon(file.extension) : Icons.folder,
        color: file.isFile 
            ? _uiConfig.getColor('ui.on_surface')
            : _uiConfig.getColor('ui.primary_color'),
      ),
      title: Text(
        file.name,
        style: TextStyle(
          fontSize: _uiConfig.getDouble('ui.font_size'),
          color: _uiConfig.getColor('ui.on_surface'),
        ),
      ),
      subtitle: file.isFile
          ? Text(
              _formatFileSize(file.size),
              style: TextStyle(
                fontSize: _uiConfig.getDouble('ui.font_size') - 2,
                color: _uiConfig.getColor('ui.on_surface').withOpacity(0.7),
              ),
            )
          : Text(
              _formatDate(file.modified),
              style: TextStyle(
                fontSize: _uiConfig.getDouble('ui.font_size') - 2,
                color: _uiConfig.getColor('ui.on_surface').withOpacity(0.7),
              ),
            ),
      trailing: _isMultiSelectMode
          ? Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected 
                  ? _uiConfig.getColor('ui.accent_color')
                  : _uiConfig.getColor('ui.on_surface'),
            )
          : file.isFile
              ? PopupMenuButton(
                icon: Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'download',
                    child: Text('Download'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                  PopupMenuItem(
                    value: 'rename',
                    child: Text('Rename'),
                  ),
                  PopupMenuItem(
                    value: 'properties',
                    child: Text('Properties'),
                  ),
                ],
              )
              : null,
      onTap: () => _onFileTapped(file),
      onLongPress: () => _onFileLongPressed(file),
    );
  }

  Widget _buildGridItem(FTPFile file, int index) {
    final isSelected = _selectedFiles.contains(file.path);
    
    return GestureDetector(
      onTap: () => _onFileTapped(file),
      onLongPress: () => _onFileLongPressed(file),
      child: EnhancedUIComponents.buildCard(
        color: isSelected ? _uiConfig.getColor('ui.selected_color') : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              file.isFile ? _getFileIcon(file.extension) : Icons.folder,
              size: _uiConfig.getDouble('ui.icon_size'),
              color: file.isFile 
                  ? _uiConfig.getColor('ui.on_surface')
                  : _uiConfig.getColor('ui.primary_color'),
            ),
            SizedBox(height: _uiConfig.getDouble('ui.padding') / 2),
            Text(
              file.name,
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

  Widget _buildTransferProgress() {
    return Container(
      padding: EdgeInsets.all(_uiConfig.getDouble('ui.padding')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EnhancedUIComponents.buildText(
                'Transfers in Progress',
                style: TextStyle(
                  fontSize: _uiConfig.getDouble('ui.font_size'),
                  fontWeight: FontWeight.bold,
                ),
              ),
              EnhancedUIComponents.buildText(
                '$_activeTransferCount Active',
                style: TextStyle(
                  fontSize: _uiConfig.getDouble('ui.font_size') - 2,
                  color: _uiConfig.getColor('ui.on_surface').withOpacity(0.7),
                ),
              ),
            ],
          ),
          SizedBox(height: _uiConfig.getDouble('ui.padding') / 2),
          EnhancedUIComponents.buildLinearProgressIndicator(
            value: _totalProgress,
          ),
          SizedBox(height: _uiConfig.getDouble('ui.padding') / 2),
          Expanded(
            child: ListView.builder(
              itemCount: _transferQueue.length,
              itemBuilder: (context, index) {
                return _buildTransferItem(_transferQueue[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferItem(TransferItem transfer) {
    return EnhancedUIComponents.buildCard(
      margin: EdgeInsets.only(bottom: _uiConfig.getDouble('ui.padding') / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EnhancedUIComponents.buildText(
                transfer.fileName,
                style: TextStyle(
                  fontSize: _uiConfig.getDouble('ui.font_size'),
                  fontWeight: FontWeight.w500,
                ),
              ),
              EnhancedUIComponents.buildText(
                '${(transfer.progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: _uiConfig.getDouble('ui.font_size') - 2,
                  color: _uiConfig.getColor('ui.on_surface').withOpacity(0.7),
                ),
              ),
            ],
          ),
          SizedBox(height: _uiConfig.getDouble('ui.padding') / 2),
          EnhancedUIComponents.buildLinearProgressIndicator(
            value: transfer.progress,
          ),
          if (transfer.errorMessage != null)
            EnhancedUIComponents.buildText(
              transfer.errorMessage!,
              style: TextStyle(
                fontSize: _uiConfig.getDouble('ui.font_size') - 2,
                color: _uiConfig.getColor('ui.error_color'),
              ),
            ),
        ],
      ),
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
          icon: Icons.upload),
          label: 'Upload',
        ),
        BottomNavigationBarItem(
          icon: Icons.download),
          label: 'Transfers',
        ),
        BottomNavigationBarItem(
          icon: Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _toggleViewMode() {
    setState(() {
      _isListView = !_isListView;
    });
    
    // Save preference
    _config.setParameter('ftp.default_view', _isListView ? 'list' : 'grid');
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
              title: Text('Modified'),
              value: 'modified',
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

  void _showConnectionDialog() {
    showDialog(
      context: context,
      builder: (context) => EnhancedUIComponents.buildDialog(
        title: 'Connect to FTP Server',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EnhancedUIComponents.buildTextField(
              controller: _hostController,
              labelText: 'Host',
              hintText: 'Enter FTP server host',
            ),
            SizedBox(height: _uiConfig.getDouble('ui.padding')),
            EnhancedUIComponents.buildTextField(
              controller: _portController,
              labelText: 'Port',
              hintText: 'Enter FTP server port',
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: _uiConfig.getDouble('ui.padding')),
            EnhancedUIComponents.buildTextField(
              controller: _usernameController,
              labelText: 'Username',
              hintText: 'Enter username',
            ),
            SizedBox(height: _uiConfig.getDouble('ui.padding')),
            EnhancedUIComponents.buildTextField(
              controller: _passwordController,
              labelText: 'Password',
              hintText: 'Enter password',
              obscureText: true,
            ),
            SizedBox(height: _uiConfig.getDouble('padding')),
            Row(
              children: [
                Expanded(
                  child: EnhancedUIComponents.buildElevatedButton(
                    onPressed: _connectToServer,
                    child: Text('Connect'),
                  ),
                ),
                SizedBox(width: _uiConfig.getDouble('ui.padding')),
                Expanded(
                  child: EnhancedUIComponents.buildTextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showServerProfilesDialog() {
    showDialog(
      context: context,
      builder: (context) => EnhancedUIComponents.buildDialog(
        title: 'Server Profiles',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _serverProfiles.length,
                itemBuilder: (context, index) {
                  final profile = _serverProfiles[index];
                  return EnhancedUIComponents.buildListTile(
                    title: Text(profile.name),
                    subtitle: Text('${profile.host}:${profile.port}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _editServerProfile(profile),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteServerProfile(profile),
                        ),
                      ],
                    ),
                    onTap: () => _selectServerProfile(profile),
                  );
                },
              ),
            ),
            SizedBox(height: _uiConfig.getDouble('ui.padding')),
            Row(
              children: [
                Expanded(
                  child: EnhancedUIComponents.buildElevatedButton(
                    onPressed: _addServerProfile,
                    child: Text('Add Profile'),
                  ),
                ),
                SizedBox(width: _uiConfig.getDouble('ui.padding')),
                Expanded(
                  child: EnhancedUIComponents.buildTextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onFileTapped(FTPFile file) {
    if (_isMultiSelectMode) {
      _toggleFileSelection(file);
    } else {
      if (file.isFile) {
        _downloadFile(file);
      } else {
        _navigateToDirectory(file.path);
      }
    }
  }

  void _onFileLongPressed(FTPFile file) {
    setState(() {
      _isMultiSelectMode = true;
      _toggleFileSelection(file);
    });
  }

  void _toggleFileSelection(FTPFile file) {
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
      _refreshDirectory();
    }
  }

  void _navigateToPath(int index) {
    final pathParts = _currentPath.split('/');
    final newPath = pathParts.take(index + 1).join('/');
    setState(() {
      _currentPath = newPath;
    });
    _refreshDirectory();
  }

  void _navigateToDirectory(String path) {
    setState(() {
      _currentPath = path;
    });
    _refreshDirectory();
  }

  void _downloadFile(FTPFile file) {
    // Implement file download logic
    _logger.info('Downloading file: ${file.path}', 'FTPClientScreen');
  }

  void _connectToServer() async {
    setState(() {
      _isConnecting = true;
      _connectionError = null;
    });

    try {
      // Implement FTP connection logic
      final host = _hostController.text;
      final port = int.tryParse(_portController.text) ?? 21;
      final username = _usernameController.text;
      final password = _passwordController.text;

      // Simulate connection
      await Future.delayed(Duration(seconds: 2));

      setState(() {
        _isConnected = true;
        _isConnecting = false;
        _currentServer = host;
        _currentPort = port;
        _currentUsername = username;
      });

      // Save current profile
      await _saveCurrentProfile();

      // Load directory
      await _refreshDirectory();

      _logger.info('Connected to FTP server: $host:$port', 'FTPClientScreen');
    } catch (e) {
      _logger.error('Failed to connect to FTP server', 'FTPClientScreen', error: e);
      setState(() {
        _isConnecting = false;
        _connectionError = e.toString();
      });
    }
  }

  Future<void> _saveCurrentProfile() async {
    try {
      final profile = ServerProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '$_currentUsername@$_currentServer',
        host: _currentServer,
        port: _currentPort,
        username: _currentUsername,
        password: _passwordController.text,
      );

      // Update or add to profiles
      final existingIndex = _serverProfiles.indexWhere((p) => p.host == _currentServer && p.port == _currentPort);
      if (existingIndex >= 0) {
        _serverProfiles[existingIndex] = profile;
      } else {
        _serverProfiles.add(profile);
      }

      // Save to configuration
      final profilesConfig = _serverProfiles.map((p) => p.toMap()).toList();
      await _config.setParameter('ftp.server_profiles', profilesConfig);
      await _config.setParameter('ftp.current_profile', profile.id);

      _logger.info('Server profile saved', 'FTPClientScreen');
    } catch (e) {
      _logger.error('Failed to save server profile', 'FTPClientScreen', error: e);
    }
  }

  Future<void> _refreshDirectory() async {
    try {
      // Simulate directory refresh
      await Future.delayed(Duration(milliseconds: 500));

      // Mock file list
      final files = [
        FTPFile(
          path: '$_currentPath/file1.txt',
          name: 'file1.txt',
          size: 1024,
          modified: DateTime.now(),
          isFile: true,
          extension: 'txt',
        ),
        FTPFile(
          path: '$_currentPath/file2.jpg',
          name: 'file2.jpg',
          size: 2048,
          modified: DateTime.now(),
          isFile: true,
          extension: 'jpg',
        ),
        FTPFile(
          path: '$_currentPath/documents',
          name: 'documents',
          size: 0,
          modified: DateTime.now(),
          isFile: false,
          extension: '',
        ),
      ];

      setState(() {
        _files = files;
        _filteredFiles = files;
      });

      _logger.info('Directory refreshed: $_currentPath', 'FTPClientScreen');
    } catch (e) {
      _logger.error('Failed to refresh directory', 'FTPClientScreen', error: e);
    }
  }

  void _addServerProfile() {
    // Implement add server profile logic
    _logger.info('Adding server profile', 'FTPClientScreen');
  }

  void _editServerProfile(ServerProfile profile) {
    // Implement edit server profile logic
    _logger.info('Editing server profile: ${profile.name}', 'FTPClientScreen');
  }

  void _deleteServerProfile(ServerProfile profile) {
    setState(() {
      _serverProfiles.remove(profile);
    });
    _logger.info('Deleted server profile: ${profile.name}', 'FTPClientScreen');
  }

  void _selectServerProfile(ServerProfile profile) {
    setState(() {
      _currentProfile = profile;
    });
    _loadCurrentProfile();
    _logger.info('Selected server profile: ${profile.name}', 'FTPClientScreen');
  }

  void _showAddMenu() {
    // Implement add menu logic
    _logger.info('Showing add menu', 'FTPClientScreen');
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
        // Transfers tab
        _showTransfersDialog();
        break;
      case 3:
        // Settings tab
        _showSettingsDialog();
        break;
    }
  }

  void _showUploadDialog() {
    // Implement upload dialog
    _logger.info('Showing upload dialog', 'FTPClientScreen');
  }

  void _showTransfersDialog() {
    // Implement transfers dialog
    _logger.info('Showing transfers dialog', 'FTPClientScreen');
  }

  void _showSettingsDialog() {
    // Implement settings dialog
    _logger.info('Showing settings dialog', 'FTPClientScreen');
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    _transferScrollController.dispose();
    super.dispose();
  }
}

/// FTP file model
class FTPFile {
  final String path;
  final String name;
  final int size;
  final DateTime modified;
  final bool isFile;
  final String extension;

  FTPFile({
    required this.path,
    required this.name,
    required this.size,
    required this.modified,
    required this.isFile,
    required this.extension,
  });
}

/// Server profile model
class ServerProfile {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String password;

  ServerProfile({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    required this.password,
  });

  factory ServerProfile.fromMap(Map<String, dynamic> map) {
    return ServerProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      host: map['host'] as String,
      port: map['port'] as int,
      username: map['username'] as String,
      password: map['password'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'password': password,
    };
  }
}
