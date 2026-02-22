import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/central_config.dart';
import '../../../core/plugin_manager.dart';
import '../../../core/accessibility_manager.dart';
import '../../../services/logging/logging_service.dart';

/// Plugin Marketplace and Management Screen
class PluginMarketplaceScreen extends StatefulWidget {
  const PluginMarketplaceScreen({super.key});

  @override
  State<PluginMarketplaceScreen> createState() => _PluginMarketplaceScreenState();
}

class _PluginMarketplaceScreenState extends State<PluginMarketplaceScreen> {
  final PluginManager _pluginManager = PluginManager();
  final AccessibilityManager _accessibility = AccessibilityManager();
  final LoggingService _logger = LoggingService();

  List<MarketplacePlugin> _marketplacePlugins = [];
  List<PluginInfo> _installedPlugins = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePluginManager();
    _announceScreenEntry();
  }

  void _announceScreenEntry() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _accessibility.announceToScreenReader(
        'Plugin marketplace screen opened. Browse and manage plugins for iSuite.',
        assertion: 'screen opened',
      );
    });
  }

  Future<void> _initializePluginManager() async {
    setState(() => _isLoading = true);

    try {
      await _pluginManager.initialize();

      // Listen to plugin events
      _pluginManager.pluginEvents.listen(_handlePluginEvent);

      // Load data
      await _loadMarketplacePlugins();
      _loadInstalledPlugins();

    } catch (e) {
      setState(() => _errorMessage = 'Failed to initialize plugin manager: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handlePluginEvent(PluginEvent event) {
    switch (event.type) {
      case PluginEventType.installed:
        _loadInstalledPlugins();
        _showMessage('Plugin installed successfully');
        break;
      case PluginEventType.uninstalled:
        _loadInstalledPlugins();
        _showMessage('Plugin uninstalled successfully');
        break;
      case PluginEventType.started:
        _showMessage('Plugin started');
        break;
      case PluginEventType.stopped:
        _showMessage('Plugin stopped');
        break;
      default:
        break;
    }
  }

  Future<void> _loadMarketplacePlugins() async {
    try {
      final plugins = await _pluginManager.getMarketplacePlugins();
      setState(() => _marketplacePlugins = plugins);
    } catch (e) {
      _logger.error('Failed to load marketplace plugins', 'PluginMarketplaceScreen', error: e);
    }
  }

  void _loadInstalledPlugins() {
    setState(() => _installedPlugins = _pluginManager.loadedPlugins.values.toList());
  }

  @override
  Widget build(BuildContext context) {
    final config = CentralConfig.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin Marketplace'),
        backgroundColor: config.primaryColor,
        foregroundColor: config.surfaceColor,
        elevation: config.getParameter('ui.app_bar.elevation', defaultValue: 4.0),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.install_file),
            onPressed: _installFromFile,
            tooltip: 'Install from file',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildMainContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Plugin Manager Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializePluginManager,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.store), text: 'Marketplace'),
              Tab(icon: Icon(Icons.inventory), text: 'Installed'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildMarketplaceTab(),
                _buildInstalledTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketplaceTab() {
    if (_marketplacePlugins.isEmpty) {
      return _buildEmptyState(
        'No Plugins Available',
        'Check back later for new plugins from the marketplace.',
        Icons.store,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(CentralConfig.instance.getParameter('ui.spacing.medium', defaultValue: 20.0)),
      itemCount: _marketplacePlugins.length,
      itemBuilder: (context, index) => _buildMarketplacePluginCard(_marketplacePlugins[index]),
    );
  }

  Widget _buildMarketplacePluginCard(MarketplacePlugin plugin) {
    final isInstalled = _installedPlugins.any((p) => p.id == plugin.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: CentralConfig.instance.getParameter('ui.shadow.elevation.low', defaultValue: 2.0),
      child: Padding(
        padding: EdgeInsets.all(CentralConfig.instance.getParameter('ui.spacing.medium', defaultValue: 20.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plugin.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        plugin.rating.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              plugin.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'by ${plugin.author}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${plugin.downloads} downloads',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: plugin.tags.map((tag) => Chip(
                label: Text(
                  tag,
                  style: const TextStyle(fontSize: 10),
                ),
                backgroundColor: Colors.blue[50],
                side: const BorderSide(color: Colors.blue, width: 0.5),
              )).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'v${plugin.version}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: isInstalled ? null : () => _installFromMarketplace(plugin),
                  icon: Icon(isInstalled ? Icons.check : Icons.download),
                  label: Text(isInstalled ? 'Installed' : 'Install'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isInstalled ? Colors.green : CentralConfig.instance.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstalledTab() {
    if (_installedPlugins.isEmpty) {
      return _buildEmptyState(
        'No Plugins Installed',
        'Install plugins from the marketplace to extend iSuite functionality.',
        Icons.inventory,
        _installFromFile,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(CentralConfig.instance.getParameter('ui.spacing.medium', defaultValue: 20.0)),
      itemCount: _installedPlugins.length,
      itemBuilder: (context, index) => _buildInstalledPluginCard(_installedPlugins[index]),
    );
  }

  Widget _buildInstalledPluginCard(PluginInfo plugin) {
    final isActive = _pluginManager.activePlugins.containsKey(plugin.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: CentralConfig.instance.getParameter('ui.shadow.elevation.low', defaultValue: 2.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: CentralConfig.instance.primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.extension,
            color: CentralConfig.instance.primaryColor,
          ),
        ),
        title: Text(
          plugin.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('v${plugin.version} by ${plugin.author}'),
            Text(
              plugin.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) => _handlePluginAction(plugin, value),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(isActive ? 'Stop Plugin' : 'Start Plugin'),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Text('Settings'),
                ),
                const PopupMenuItem(
                  value: 'info',
                  child: Text('Plugin Info'),
                ),
                const PopupMenuItem(
                  value: 'uninstall',
                  child: Text('Uninstall', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showPluginDetails(plugin),
      ),
    );
  }

  Widget _buildEmptyState(String title, String message, IconData icon, [VoidCallback? action]) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: action,
                icon: const Icon(Icons.add),
                label: const Text('Install Plugin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CentralConfig.instance.primaryColor,
                  foregroundColor: CentralConfig.instance.surfaceColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadMarketplacePlugins();
    _loadInstalledPlugins();
    setState(() => _isLoading = false);
    _accessibility.announceToScreenReader('Data refreshed');
  }

  Future<void> _installFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'plugin'],
    );

    if (result != null && result.files.single.path != null) {
      final success = await _pluginManager.installPlugin(File(result.files.single.path!));
      if (success) {
        _showMessage('Plugin installed successfully');
        _loadInstalledPlugins();
      } else {
        _showError('Failed to install plugin');
      }
    }
  }

  Future<void> _installFromMarketplace(MarketplacePlugin plugin) async {
    final success = await _pluginManager.installFromMarketplace(plugin.id);
    if (success) {
      _showMessage('Plugin installed from marketplace');
      _loadInstalledPlugins();
    } else {
      _showError('Failed to install plugin from marketplace');
    }
  }

  void _handlePluginAction(PluginInfo plugin, String action) {
    switch (action) {
      case 'toggle':
        if (_pluginManager.activePlugins.containsKey(plugin.id)) {
          _pluginManager.stopPlugin(plugin.id);
        } else {
          _pluginManager.startPlugin(plugin.id);
        }
        break;
      case 'settings':
        _showPluginSettings(plugin);
        break;
      case 'info':
        _showPluginDetails(plugin);
        break;
      case 'uninstall':
        _confirmUninstallPlugin(plugin);
        break;
    }
  }

  void _showPluginDetails(PluginInfo plugin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(plugin.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Version: ${plugin.version}'),
              Text('Author: ${plugin.author}'),
              const SizedBox(height: 12),
              Text('Description:', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(plugin.description),
              if (plugin.permissions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Permissions:', style: const TextStyle(fontWeight: FontWeight.bold)),
                ...plugin.permissions.map((perm) => Text('• $perm')),
              ],
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

  void _showPluginSettings(PluginInfo plugin) {
    // Implementation for plugin settings dialog
    _showMessage('Plugin settings - Coming soon!');
  }

  void _confirmUninstallPlugin(PluginInfo plugin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uninstall Plugin'),
        content: Text('Are you sure you want to uninstall "${plugin.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await _pluginManager.uninstallPlugin(plugin.id);
              if (success) {
                _showMessage('Plugin uninstalled successfully');
              } else {
                _showError('Failed to uninstall plugin');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _pluginManager.dispose();
    super.dispose();
  }
}
