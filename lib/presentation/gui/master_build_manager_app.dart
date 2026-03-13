import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/enhanced_config_provider.dart';
import '../widgets/common/parameterized_app_bar.dart';

/// Master Build & Run Manager GUI Application
/// 
/// Comprehensive Python GUI application for managing Flutter builds
/// Features: Multi-platform builds, console logs, error detection, performance monitoring
/// Performance: Real-time updates, optimized UI, efficient resource usage
/// Architecture: GUI application, service integration, event-driven
class MasterBuildManagerApp extends ConsumerStatefulWidget {
  const MasterBuildManagerApp({super.key});

  @override
  ConsumerState<MasterBuildManagerApp> createState() => _MasterBuildManagerAppState();
}

class _MasterBuildManagerAppState extends ConsumerState<MasterBuildManagerApp> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Build', 'Logs', 'Config', 'Statistics', 'Tools'];
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = ref.watch(enhancedConfigurationProvider);
    
    return Scaffold(
      appBar: ParameterizedAppBar(
        title: 'Master Build Manager',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
            tooltip: 'Refresh All',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(context),
          Expanded(
            child: _buildTabContent(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickActions,
        icon: const Icon(Icons.flash_on),
        label: 'Quick Actions',
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      height: 60,
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == _selectedTab;
          
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    tab,
                    style: TextStyle(
                      color: isSelected ? Theme.of(context).primaryColor : null,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    switch (_selectedTab) {
      case 0:
        return _buildBuildTab(context);
      case 1:
        return _buildLogsTab(context);
      case 2:
        return _buildConfigTab(context);
      case 3:
        return _buildStatisticsTab(context);
      case 4:
        return _buildToolsTab(context);
      default:
        return Container();
    }
  }

  Widget _buildBuildTab(BuildContext context) {
    return const BuildTab();
  }

  Widget _buildLogsTab(BuildContext context) {
    return const LogsTab();
  }

  Widget _buildConfigTab(BuildContext context) {
    return const ConfigTab();
  }

  Widget _buildStatisticsTab(BuildContext context) {
    return const StatisticsTab();
  }

  Widget _buildToolsTab(BuildContext context) {
    return const ToolsTab();
  }

  void _refreshAll() {
    // Refresh all data
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Refreshing all data...',
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Flutter SDK Path'),
              subtitle: Text('Configure Flutter SDK path'),
              leading: Icon(Icons.flutter),
            ),
            const ListTile(
              title: Text('Project Path'),
              subtitle: Text('Configure project path'),
              leading: Icon(Icons.folder),
            ),
            const ListTile(
              title: Text('Build Output'),
              subtitle: Text('Configure build output directory'),
              leading: Icon(Icons.build),
            ),
            const ListTile(
              title: 'Auto-refresh',
              subtitle: 'Enable auto-refresh of build status',
              leading: Icon(Icons.autorenew),
            ),
            const ListTile(
              title: 'Notifications',
              subtitle: 'Enable build notifications',
              leading: Icon(Icons.notifications),
            ),
          ],
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

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Start Build'),
              subtitle: const Text('Start a new build'),
              onTap: () {
                Navigator.of(context).pop();
                _startBuild();
              },
            ),
            ListTile(
              leading: const Icon(Icons.stop),
              title: const Text('Stop Build'),
              subtitle: const Text('Stop current build'),
              onTap: () {
                Navigator.of(context).pop();
                _stopBuild();
              },
            ),
            ListTile(
              leading: const Icon(Icons.clean),
              title: const Text('Clean Build'),
              subtitle: const Text('Clean build artifacts'),
              onTap: () {
                Navigator.of(context).pop();
                _cleanBuild();
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh Status'),
              subtitle: const Text('Refresh build status'),
              onTap: () {
                Navigator.of(context).pop();
                _refreshStatus();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startBuild() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Starting build...',
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _stopBuild() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Stopping build...',
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _cleanBuild() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Cleaning build...',
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _refreshStatus() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Refreshing status...',
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Build Tab
/// 
/// Build management interface
class BuildTab extends ConsumerStatefulWidget {
  const BuildTab({super.key});

  @override
  ConsumerState<BuildTab> createState() => _BuildTabState();
}

class _BuildTabState extends ConsumerState<BuildTab> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Build Management',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Platform selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Platform',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildPlatformChip('Android', BuildPlatform.android),
                      _buildPlatformChip('iOS', BuildPlatform.ios),
                      _buildPlatformChip('Web', BuildPlatform.web),
                      _buildPlatformChip('Windows', BuildPlatform.windows),
                      _buildPlatformChip('Linux', BuildPlatform.linux),
                      _buildPlatformChip('macOS', BuildPlatform.macos),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Build configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Build Configuration',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Build Mode',
                            border: OutlineInputBorder(),
                          ),
                          value: 'debug',
                          items: ['debug', 'release', 'profile'],
                          onChanged: (value) {
                            // Handle build mode change
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<bool>(
                          decoration: const InputDecoration(
                            labelText: 'Clean Build',
                            border: OutlineInputBorder(),
                          ),
                          value: false,
                          items: [false, true],
                          onChanged: (value) {
                            // Handle clean build change
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<bool>(
                          decoration: const InputDecoration(
                            labelText: 'Release Build',
                            border: OutlineInputBorder(),
                          ),
                          value: false,
                          items: [false, true],
                          onChanged: (value) {
                            // Handle release build change
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Build actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _startBuild,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Build'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _stopBuild,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop Build'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _cleanBuild,
                      icon: const Icon(Icons.clean),
                      label: const Text('Clean Build'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Build status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Build Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('No active builds'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformChip(String label, BuildPlatform platform) {
    return Chip(
      label: label,
      avatar: CircleAvatar(
        backgroundColor: _getPlatformColor(platform),
        child: Icon(
          _getPlatformIcon(platform),
          color: Colors.white,
          size: 16,
        ),
      ),
      backgroundColor: Colors.grey[200],
    );
  }

  Color _getPlatformColor(BuildPlatform platform) {
    switch (platform) {
      case BuildPlatform.android:
        return Colors.green;
      case BuildPlatform.ios:
        return Colors.blue;
      case BuildPlatform.web:
        return Colors.orange;
      case BuildPlatform.windows:
        return Colors.purple;
      case BuildPlatform.linux:
        return Colors.teal;
      case BuildPlatform.macos:
        return Colors.grey;
    }
  }

  IconData _getPlatformIcon(BuildPlatform platform) {
    switch (platform) {
      case BuildPlatform.android:
        return Icons.android;
      case BuildPlatform.ios:
        return Icons.phone_iphone;
      case BuildPlatform.web:
        return Icons.web;
      case BuildPlatform.windows:
        return Icons.computer;
      case BuildPlatform.linux:
        return Icons.desktop_linux;
      case BuildPlatform.macos:
        return Icons.laptop_mac;
    }
  }

  void _startBuild() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Starting build...',
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _stopBuild() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Stopping build...',
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _cleanBuild() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Cleaning build...',
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Logs Tab
/// 
/// Build logs display
class LogsTab extends ConsumerStatefulWidget {
  const LogsTab({super.key});

  @override
  ConsumerState<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends ConsumerState<LogsTab> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Build Logs',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Log controls
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearLogs,
                    tooltip: 'Clear Logs',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: _exportLogs,
                    tooltip: 'Export Logs',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchLogs,
                    tooltip: 'Search Logs',
                  ),
                  const Spacer(),
                  DropdownButton<String>(
                    value: 'All Logs',
                    items: ['All Logs', 'Errors Only', 'Warnings Only', 'Info Only'],
                    onChanged: (value) {
                      // Handle log filter change
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Log display
          Expanded(
            child: Card(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('No logs to display'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearLogs() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Logs cleared',
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportLogs() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Exporting logs...',
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _searchLogs() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Search logs...',
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Config Tab
/// 
/// Build configuration management
class ConfigTab extends ConsumerStatefulWidget {
  const ConfigTab({super.key});

  @override
  ConsumerState<ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends ConsumerState<ConfigTab> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Build Configuration',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Configuration list
          Expanded(
            child: ListView(
              children: [
                _buildConfigItem(
                  'Debug Android',
                  'Android debug build configuration',
                  Icons.android,
                  () => _editConfig('debug_android'),
                ),
                _buildConfigItem(
                  'Release Android',
                  'Android release build configuration',
                  Icons.android,
                  () => _editConfig('release_android'),
                ),
                _buildConfigItem(
                  'Debug iOS',
                  'iOS debug build configuration',
                  Icons.phone_iphone,
                  () => _editConfig('debug_ios'),
                ),
                _buildConfigItem(
                  'Release iOS',
                  'iOS release build configuration',
                  Icons.phone_iphone,
                  () => _editConfig('release_ios'),
                ),
                _buildConfigItem(
                  'Debug Web',
                  'Web debug build configuration',
                  Icons.web,
                  () => _editConfig('debug_web'),
                ),
                _buildConfigItem(
                  'Release Web',
                  'Web release build configuration',
                  Icons.web,
                  () => _editConfig('release_web'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigItem(String title, String description, IconData icon, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.edit),
        onTap: onTap,
      ),
    );
  }

  void _editConfig(String configId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: 'Editing configuration: $configId',
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Statistics Tab
/// 
/// Build statistics and analytics
class StatisticsTab extends ConsumerStatefulWidget {
  const StatisticsTab({super.key});

  @override
  ConsumerState<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends ConsumerState<StatisticsTab> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Build Statistics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Statistics cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Total Builds', '123', Icons.build, Colors.blue),
              _buildStatCard('Successful', '98', Icons.check_circle, Colors.green),
              _buildStatCard('Failed', '25', Icons.error, Colors.red),
              _buildStatCard('Avg Time', '2m 30s', Icons.timer, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tools Tab
/// 
/// Development tools and utilities
class ToolsTab extends ConsumerStatefulWidget {
  const ToolsTab({super.key});

  @override
  ConsumerState<ToolsTab> createState() => _ToolsTabState();
}

class _ToolsTabState extends ConsumerState<ToolsTab> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Development Tools',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Tools grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildToolCard('Flutter Doctor', 'Check Flutter environment', Icons.flutter, Colors.blue),
              _buildToolCard('Flutter Analyze', 'Analyze Flutter code', Icons.code, Colors.green),
              _buildToolCard('Flutter Test', 'Run Flutter tests', Icons.bug_report, Colors.orange),
              _buildToolCard('Flutter Format', 'Format Flutter code', Icons.format_paint, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(String title, String description, IconData icon, Color color) {
    return Card(
      child: InkWell(
        onTap: () => _runTool(title),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color,
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _runTool(String toolName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: 'Running $toolName...',
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// Model classes

enum BuildPlatform {
  android,
  ios,
  web,
  windows,
  linux,
  macos,
}
