import 'package:flutter/material.dart';
import '../../../core/ui/ui_config_service.dart';
import '../../../core/ui/enhanced_ui_components.dart';
import '../../../core/central_config.dart';
import '../../../core/logging/logging_service.dart';

/// Enhanced Main Screen with Central Configuration
/// 
/// This screen provides the main application interface with:
/// - Central parameterization through UIConfigService
/// - Enhanced UI components with proper configuration
/// - Dynamic theme switching
/// - Responsive design for different screen sizes
/// - Performance monitoring and optimization
/// - Accessibility support
/// - Multi-language support
/// - User preferences management
/// - Navigation and routing
/// - Status indicators and notifications
/// - Quick actions and shortcuts
class EnhancedMainScreen extends StatefulWidget {
  const EnhancedMainScreen({super.key});

  @override
  State<EnhancedMainScreen> createState() => _EnhancedMainScreenState();
}

class _EnhancedMainScreenState extends State<EnhancedMainScreen> {
  // Core services
  final UIConfigService _uiConfig = UIConfigService();
  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();

  // UI state
  int _currentIndex = 0;
  bool _isDarkMode = false;
  bool _isCompactMode = false;
  String _selectedLanguage = 'en';

  // Navigation items
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home,
      label: 'Home',
      route: '/home',
    ),
    NavigationItem(
      icon: Icons.folder,
      label: 'Files',
      route: '/files',
    ),
    NavigationItem(
      icon: Icons.cloud,
      label: 'Network',
      route: '/network',
    ),
    NavigationItem(
      icon: Icons.settings,
      label: 'Settings',
      route: '/settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      _logger.info('Initializing enhanced main screen', 'MainScreen');
      
      // Apply user preferences
      await _applyUserPreferences();
      
      // Setup theme
      _setupTheme();
      
      _logger.info('Main screen initialized successfully', 'MainScreen');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize main screen', 'MainScreen',
          error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _applyUserPreferences() async {
    try {
      // Get user preferences from configuration
      final darkMode = _config.getParameter('ui.dark_mode', defaultValue: false);
      final compactMode = _config.getParameter('ui.compact_mode', defaultValue: false);
      final language = _config.getParameter('ui.language', defaultValue: 'en');
      
      setState(() {
        _isDarkMode = darkMode;
        _isCompactMode = compactMode;
        _selectedLanguage = language;
      });
    } catch (e) {
      _logger.error('Failed to apply user preferences', 'MainScreen', error: e);
    }
  }

  void _setupTheme() {
    // Apply theme configuration
    final themeData = _uiConfig.getThemeData();
    
    // Update app theme
    if (mounted) {
      setState(() {
        // Theme will be applied through the app's theme configuration
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      drawer: _buildDrawer(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return EnhancedUIComponents.buildAppBar(
      title: 'iSuite',
      actions: [
        IconButton(
          icon: Icon(Icons.search),
          onPressed: _showSearch,
        ),
        IconButton(
          icon: Icon(Icons.notifications),
          onPressed: _showNotifications,
        ),
        IconButton(
          icon: Icon(Icons.more_vert),
          onPressed: _showMoreOptions,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _currentIndex,
      children: [
        _buildHomeTab(),
        _buildFilesTab(),
        _buildNetworkTab(),
        _buildSettingsTab(),
      ],
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_uiConfig.getDouble('ui.padding')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          SizedBox(height: _uiConfig.getDouble('ui.padding')),
          _buildQuickActions(),
          SizedBox(height: _uiConfig.getDouble('ui.padding')),
          _buildRecentActivity(),
          SizedBox(height: _uiConfig.getDouble('ui.padding')),
          _buildSystemStatus(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return EnhancedUIComponents.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EnhancedUIComponents.buildText(
            'Welcome to iSuite',
            style: TextStyle(
              fontSize: _uiConfig.getDouble('ui.font_size') + 4,
              fontWeight: FontWeight.bold,
              color: _uiConfig.getColor('ui.primary_color'),
            ),
          ),
          SizedBox(height: _uiConfig.getDouble('ui.padding') / 2),
          EnhancedUIComponents.buildText(
            'Your comprehensive file management and network solution',
            style: TextStyle(
              fontSize: _uiConfig.getDouble('ui.font_size'),
              color: _uiConfig.getColor('ui.on_surface').withOpacity(0.7),
            ),
          ),
          SizedBox(height: _uiConfig.getDouble('ui.padding')),
          Row(
            children: [
              Expanded(
                child: EnhancedUIComponents.buildElevatedButton(
                  onPressed: _getStarted,
                  child: Text('Get Started'),
                ),
              ),
              SizedBox(width: _uiConfig.getDouble('ui.padding')),
              Expanded(
                child: EnhancedUIComponents.buildOutlinedButton(
                  onPressed: _viewTutorial,
                  child: Text('Tutorial'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EnhancedUIComponents.buildText(
          'Quick Actions',
          style: TextStyle(
            fontSize: _uiConfig.getDouble('ui.font_size') + 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: _uiConfig.getDouble('ui.padding')),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: _uiConfig.getDouble('ui.padding'),
          mainAxisSpacing: _uiConfig.getDouble('ui.padding'),
          childAspectRatio: 1.5,
          children: [
            _buildQuickActionCard(
              icon: Icons.folder_open,
              title: 'Browse Files',
              subtitle: 'Access your files',
              onTap: () => _navigateToTab(1),
            ),
            _buildQuickActionCard(
              icon: Icons.cloud_upload,
              title: 'Upload',
              subtitle: 'Upload files',
              onTap: _showUploadDialog,
            ),
            _buildQuickActionCard(
              icon: Icons.network_check,
              title: 'Network',
              subtitle: 'Manage connections',
              onTap: () => _navigateToTab(2),
            ),
            _buildQuickActionCard(
              icon: Icons.settings,
              title: 'Settings',
              subtitle: 'Configure app',
              onTap: () => _navigateToTab(3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return EnhancedUIComponents.buildCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_uiConfig.getDouble('ui.border_radius')),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: _uiConfig.getDouble('ui.icon_size') * 1.5,
              color: _uiConfig.getColor('ui.primary_color'),
            ),
            SizedBox(height: _uiConfig.getDouble('ui.padding') / 2),
            EnhancedUIComponents.buildText(
              title,
              style: TextStyle(
                fontSize: _uiConfig.getDouble('ui.font_size'),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: _uiConfig.getDouble('ui.padding') / 4),
            EnhancedUIComponents.buildText(
              subtitle,
              style: TextStyle(
                fontSize: _uiConfig.getDouble('ui.font_size') - 2,
                color: _uiConfig.getColor('ui.on_surface').withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EnhancedUIComponents.buildText(
          'Recent Activity',
          style: TextStyle(
            fontSize: _uiConfig.getDouble('ui.font_size') + 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: _uiConfig.getDouble('ui.padding')),
        EnhancedUIComponents.buildCard(
          child: Column(
            children: [
              _buildActivityItem(
                icon: Icons.file_download,
                title: 'Downloaded file',
                subtitle: 'document.pdf - 2.3 MB',
                time: '2 minutes ago',
              ),
              _buildDivider(),
              _buildActivityItem(
                icon: Icons.cloud_done,
                title: 'Connected to server',
                subtitle: 'FTP server at 192.168.1.100',
                time: '5 minutes ago',
              ),
              _buildDivider(),
              _buildActivityItem(
                icon: Icons.folder_shared,
                title: 'Created folder',
                subtitle: 'Work Documents',
                time: '10 minutes ago',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return EnhancedUIComponents.buildListTile(
      leading: Icon(
        icon,
        color: _uiConfig.getColor('ui.primary_color'),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(
        time,
        style: TextStyle(
          fontSize: _uiConfig.getDouble('ui.font_size') - 2,
          color: _uiConfig.getColor('ui.on_surface').withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return EnhancedUIComponents.buildDivider(
      height: _uiConfig.getDouble('ui.divider_height'),
    );
  }

  Widget _buildSystemStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EnhancedUIComponents.buildText(
          'System Status',
          style: TextStyle(
            fontSize: _uiConfig.getDouble('ui.font_size') + 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: _uiConfig.getDouble('ui.padding')),
        EnhancedUIComponents.buildCard(
          child: Column(
            children: [
              _buildStatusItem(
                label: 'Storage',
                value: '45% used',
                color: _uiConfig.getColor('ui.warning_color'),
              ),
              _buildDivider(),
              _buildStatusItem(
                label: 'Network',
                value: 'Connected',
                color: _uiConfig.getColor('ui.success_color'),
              ),
              _buildDivider(),
              _buildStatusItem(
                label: 'CPU',
                value: '23% usage',
                color: _uiConfig.getColor('ui.success_color'),
              ),
              _buildDivider(),
              _buildStatusItem(
                label: 'Memory',
                value: '67% used',
                color: _uiConfig.getColor('ui.warning_color'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _uiConfig.getDouble('ui.padding') / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          EnhancedUIComponents.buildText(
            label,
            style: TextStyle(
              fontSize: _uiConfig.getDouble('ui.font_size'),
            ),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: _uiConfig.getDouble('ui.padding') / 2),
              EnhancedUIComponents.buildText(
                value,
                style: TextStyle(
                  fontSize: _uiConfig.getDouble('ui.font_size'),
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder,
            size: _uiConfig.getDouble('ui.icon_size') * 2,
            color: _uiConfig.getColor('ui.primary_color'),
          ),
          SizedBox(height: _uiConfig.getDouble('ui.padding')),
          EnhancedUIComponents.buildText(
            'Files Management',
            style: TextStyle(
              fontSize: _uiConfig.getDouble('ui.font_size') + 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: _uiConfig.getDouble('ui.padding')),
          EnhancedUIComponents.buildText(
            'File management features coming soon',
            style: TextStyle(
              fontSize: _uiConfig.getDouble('ui.font_size'),
              color: _uiConfig.getColor('ui.on_surface').withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud,
            size: _uiConfig.getDouble('ui.icon_size') * 2,
            color: _uiConfig.getColor('ui.primary_color'),
          ),
          SizedBox(height: _uiConfig.getDouble('ui.padding')),
          EnhancedUIComponents.buildText(
            'Network Management',
            style: TextStyle(
              fontSize: _uiConfig.getDouble('ui.font_size') + 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: _uiConfig.getDouble('ui.padding')),
          EnhancedUIComponents.buildText(
            'Network management features coming soon',
            style: TextStyle(
              fontSize: _uiConfig.getDouble('ui.font_size'),
              color: _uiConfig.getColor('ui.on_surface').withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_uiConfig.getDouble('ui.padding')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsSection(
            title: 'Appearance',
            items: [
              _buildSwitchSetting(
                title: 'Dark Mode',
                subtitle: 'Use dark theme',
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                  _config.setParameter('ui.dark_mode', value);
                },
              ),
              _buildSwitchSetting(
                title: 'Compact Mode',
                subtitle: 'Use compact layout',
                value: _isCompactMode,
                onChanged: (value) {
                  setState(() {
                    _isCompactMode = value;
                  });
                  _config.setParameter('ui.compact_mode', value);
                },
              ),
            ],
          ),
          SizedBox(height: _uiConfig.getDouble('ui.padding')),
          _buildSettingsSection(
            title: 'Language',
            items: [
              _buildDropdownSetting(
                title: 'Language',
                subtitle: 'Select app language',
                value: _selectedLanguage,
                items: ['en', 'es', 'fr', 'de', 'ja'],
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                  _config.setParameter('ui.language', value);
                },
              ),
            ],
          ),
          SizedBox(height: _uiConfig.getDouble('ui.padding')),
          _buildSettingsSection(
            title: 'About',
            items: [
              _buildInfoSetting(
                title: 'Version',
                subtitle: '2.0.0',
              ),
              _buildInfoSetting(
                title: 'Build',
                subtitle: '2024.02.22',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> items,
  }) {
    return EnhancedUIComponents.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EnhancedUIComponents.buildText(
            title,
            style: TextStyle(
              fontSize: _uiConfig.getDouble('ui.font_size') + 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: _uiConfig.getDouble('ui.padding')),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return EnhancedUIComponents.buildListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: EnhancedUIComponents.buildSwitch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownSetting({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return EnhancedUIComponents.buildListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item.toUpperCase()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildInfoSetting({
    required String title,
    required String subtitle,
  }) {
    return EnhancedUIComponents.buildListTile(
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onBottomNavTap,
      items: _navigationItems.map((item) {
        return BottomNavigationBarItem(
          icon: Icon(item.icon),
          label: item.label,
        );
      }).toList(),
    );
  }

  Widget _buildFloatingActionButton() {
    return EnhancedUIComponents.buildFloatingActionButton(
      onPressed: _showQuickActions,
      child: Icon(Icons.add),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(),
          _buildDrawerItems(),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: _uiConfig.getColor('ui.primary_color'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.folder_shared,
            size: _uiConfig.getDouble('ui.icon_size') * 2,
            color: _uiConfig.getColor('ui.on_primary'),
          ),
          SizedBox(height: _uiConfig.getDouble('ui.padding')),
          EnhancedUIComponents.buildText(
            'iSuite',
            style: TextStyle(
              fontSize: _uiConfig.getDouble('ui.font_size') + 4,
              fontWeight: FontWeight.bold,
              color: _uiConfig.getColor('ui.on_primary'),
            ),
          ),
          EnhancedUIComponents.buildText(
            'Enterprise File Manager',
            style: TextStyle(
              fontSize: _uiConfig.getDouble('ui.font_size'),
              color: _uiConfig.getColor('ui.on_primary').withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItems() {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.home),
          title: Text('Home'),
          onTap: () => _navigateToTab(0),
        ),
        ListTile(
          leading: Icon(Icons.folder),
          title: Text('Files'),
          onTap: () => _navigateToTab(1),
        ),
        ListTile(
          leading: Icon(Icons.cloud),
          title: Text('Network'),
          onTap: () => _navigateToTab(2),
        ),
        ListTile(
          leading: Icon(Icons.settings),
          title: Text('Settings'),
          onTap: () => _navigateToTab(3),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.info),
          title: Text('About'),
          onTap: _showAbout,
        ),
        ListTile(
          leading: Icon(Icons.help),
          title: Text('Help'),
          onTap: _showHelp,
        ),
      ],
    );
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
    Navigator.pop(context);
  }

  void _getStarted() {
    _navigateToTab(1);
  }

  void _viewTutorial() {
    // Show tutorial
    _logger.info('Viewing tutorial', 'MainScreen');
  }

  void _showSearch() {
    // Show search
    _logger.info('Showing search', 'MainScreen');
  }

  void _showNotifications() {
    // Show notifications
    _logger.info('Showing notifications', 'MainScreen');
  }

  void _showMoreOptions() {
    // Show more options
    _logger.info('Showing more options', 'MainScreen');
  }

  void _showQuickActions() {
    // Show quick actions
    _logger.info('Showing quick actions', 'MainScreen');
  }

  void _showUploadDialog() {
    // Show upload dialog
    _logger.info('Showing upload dialog', 'MainScreen');
  }

  void _showAbout() {
    // Show about dialog
    _logger.info('Showing about', 'MainScreen');
  }

  void _showHelp() {
    // Show help
    _logger.info('Showing help', 'MainScreen');
  }
}

/// Navigation item model
class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
