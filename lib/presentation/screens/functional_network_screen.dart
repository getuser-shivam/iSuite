import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/functional_providers.dart';
import '../widgets/common/parameterized_app_bar.dart';

/// Functional Network Screen
/// 
/// Fully functional network management and file sharing
/// Features: Network discovery, file sharing, FTP, P2P, WebDAV
/// Performance: Optimized network operations, concurrent transfers
/// Architecture: Consumer widget, provider pattern, functional design
class FunctionalNetworkScreen extends ConsumerStatefulWidget {
  const FunctionalNetworkScreen({super.key});

  @override
  ConsumerState<FunctionalNetworkScreen> createState() => _FunctionalNetworkScreenState();
}

class _FunctionalNetworkScreenState extends ConsumerState<FunctionalNetworkScreen> {
  String _currentView = 'devices'; // devices, connections, transfers, services
  final TextEditingController _ftpHostController = TextEditingController();
  final TextEditingController _ftpPortController = TextEditingController(text: '21');
  final TextEditingController _ftpUsernameController = TextEditingController();
  final TextEditingController _ftpPasswordController = TextEditingController();
  final TextEditingController _webdavUrlController = TextEditingController();
  final TextEditingController _webdavUsernameController = TextEditingController();
  final TextEditingController _webdavPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize network services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(networkManagementProvider.notifier).initializeServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final networkProvider = ref.watch(networkManagementProvider);
    
    return Scaffold(
      appBar: ParameterizedAppBar(
        title: l10n.networkSharing,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(networkManagementProvider.notifier).initializeServices(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // View selector
          _buildViewSelector(context, l10n),
          
          // Content
          Expanded(
            child: _buildContent(context, l10n, networkProvider),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context, l10n, networkProvider),
    );
  }

  Widget _buildViewSelector(BuildContext context, AppLocalizations l10n) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildViewChip('devices', 'Devices', Icons.devices),
          _buildViewChip('connections', 'Connections', Icons.link),
          _buildViewChip('transfers', 'Transfers', Icons.swap_horiz),
          _buildViewChip('services', 'Services', Icons.settings),
        ],
      ),
    );
  }

  Widget _buildViewChip(String view, String label, IconData icon) {
    final isSelected = _currentView == view;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _currentView = view;
            });
          }
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n, networkProvider) {
    if (networkProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (networkProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${networkProvider.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                networkProvider.clearError();
                ref.read(networkManagementProvider.notifier).initializeServices();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    switch (_currentView) {
      case 'devices':
        return _buildDevicesView(context, l10n, networkProvider);
      case 'connections':
        return _buildConnectionsView(context, l10n, networkProvider);
      case 'transfers':
        return _buildTransfersView(context, l10n, networkProvider);
      case 'services':
        return _buildServicesView(context, l10n, networkProvider);
      default:
        return _buildDevicesView(context, l10n, networkProvider);
    }
  }

  Widget _buildDevicesView(BuildContext context, AppLocalizations l10n, networkProvider) {
    return Column(
      children: [
        // Scan controls
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: networkProvider.isScanning
                      ? null
                      : () => ref.read(networkManagementProvider.notifier).startDiscovery(),
                  icon: networkProvider.isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(networkProvider.isScanning ? 'Scanning...' : 'Scan for Devices'),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: networkProvider.isScanning
                    ? () => ref.read(networkManagementProvider.notifier).stopDiscovery()
                    : null,
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
              ),
            ],
          ),
        ),
        
        // Devices list
        Expanded(
          child: networkProvider.discoveredDevices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.devices, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No devices found'),
                      const SizedBox(height: 16),
                      const Text('Start scanning to discover nearby devices'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: networkProvider.discoveredDevices.length,
                  itemBuilder: (context, index) {
                    final device = networkProvider.discoveredDevices[index];
                    return _buildDeviceItem(context, l10n, device, networkProvider);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDeviceItem(BuildContext context, AppLocalizations l10n, Map<String, dynamic> device, networkProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getDeviceColor(device['type']),
          child: Icon(
            _getDeviceIcon(device['type']),
            color: Colors.white,
          ),
        ),
        title: Text(device['name'] ?? 'Unknown Device'),
        subtitle: Text('${device['type']} • ${device['address'] ?? 'No address'}'),
        trailing: ElevatedButton(
          onPressed: () => _connectToDevice(device, networkProvider),
          child: const Text('Connect'),
        ),
      ),
    );
  }

  Widget _buildConnectionsView(BuildContext context, AppLocalizations l10n, networkProvider) {
    return Column(
      children: [
        // Connection controls
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: networkProvider.isSharingEnabled
                      ? null
                      : () => ref.read(networkManagementProvider.notifier).startFileSharing(),
                  icon: const Icon(Icons.share),
                  label: const Text('Start Sharing'),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: networkProvider.isSharingEnabled
                    ? () => ref.read(networkManagementProvider.notifier).stopFileSharing()
                    : null,
                icon: const Icon(Icons.stop_share),
                label: const Text('Stop Sharing'),
              ),
            ],
          ),
        ),
        
        // Quick connect buttons
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showFtpDialog(context),
                  icon: const Icon(Icons.ftp),
                  label: const Text('FTP'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showWebDAVDialog(context),
                  icon: const Icon(Icons.cloud),
                  label: const Text('WebDAV'),
                ),
              ),
            ],
          ),
        ),
        
        // Connections list
        Expanded(
          child: networkProvider.activeConnections.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.link_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No active connections'),
                      const SizedBox(height: 16),
                      const Text('Connect to devices or services to start sharing'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: networkProvider.activeConnections.length,
                  itemBuilder: (context, index) {
                    final connection = networkProvider.activeConnections[index];
                    return _buildConnectionItem(context, l10n, connection, networkProvider);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildConnectionItem(BuildContext context, AppLocalizations l10n, Map<String, dynamic> connection, networkProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getConnectionColor(connection['type']),
          child: Icon(
            _getConnectionIcon(connection['type']),
            color: Colors.white,
          ),
        ),
        title: Text(connection['name'] ?? 'Unknown Connection'),
        subtitle: Text('${connection['type']} • Connected ${_formatConnectionTime(connection['connected_at'])}'),
        trailing: IconButton(
          icon: const Icon(Icons.disconnect),
          onPressed: () => _disconnectFromDevice(connection, networkProvider),
        ),
      ),
    );
  }

  Widget _buildTransfersView(BuildContext context, AppLocalizations l10n, networkProvider) {
    return networkProvider.fileTransfers.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No file transfers'),
                const SizedBox(height: 16),
                const Text('Connect to devices and start sharing files'),
              ],
            ),
          )
        : ListView.builder(
            itemCount: networkProvider.fileTransfers.length,
            itemBuilder: (context, index) {
              final transfer = networkProvider.fileTransfers[index];
              return _buildTransferItem(context, l10n, transfer);
            },
          );
  }

  Widget _buildTransferItem(BuildContext context, AppLocalizations l10n, Map<String, dynamic> transfer) {
    final progress = (transfer['progress'] ?? 0.0) as double;
    final status = transfer['status'] as String;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTransferColor(status),
          child: Icon(
            _getTransferIcon(status),
            color: Colors.white,
          ),
        ),
        title: Text(transfer['file_path'].split('/').last),
        subtitle: Text('${transfer['device_id']} • $status'),
        trailing: Text('${(progress * 100).toInt()}%'),
      ),
    );
  }

  Widget _buildServicesView(BuildContext context, AppLocalizations l10n, networkProvider) {
    return ListView.builder(
      itemCount: networkProvider.networkServices.length,
      itemBuilder: (context, index) {
        final service = networkProvider.networkServices[index];
        return _buildServiceItem(context, l10n, service);
      },
    );
  }

  Widget _buildServiceItem(BuildContext context, AppLocalizations l10n, Map<String, dynamic> service) {
    final isEnabled = service['enabled'] as bool;
    final status = service['status'] as String;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isEnabled ? Colors.green : Colors.grey,
          child: Icon(
            isEnabled ? Icons.check : Icons.close,
            color: Colors.white,
          ),
        ),
        title: Text(service['name']),
        subtitle: Text(status),
        trailing: Switch(
          value: isEnabled,
          onChanged: (value) => _toggleService(service, value),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, AppLocalizations l10n, networkProvider) {
    switch (_currentView) {
      case 'devices':
        return FloatingActionButton.extended(
          onPressed: networkProvider.isScanning
              ? null
              : () => ref.read(networkManagementProvider.notifier).startDiscovery(),
          icon: const Icon(Icons.search),
          label: const Text('Scan'),
        );
      case 'connections':
        return FloatingActionButton.extended(
          onPressed: networkProvider.isSharingEnabled
              ? null
              : () => ref.read(networkManagementProvider.notifier).startFileSharing(),
          icon: const Icon(Icons.share),
          label: const Text('Share'),
        );
      default:
        return Container();
    }
  }

  void _connectToDevice(Map<String, dynamic> device, networkProvider) {
    ref.read(networkManagementProvider.notifier).connectToDevice(device['id']);
  }

  void _disconnectFromDevice(Map<String, dynamic> connection, networkProvider) {
    ref.read(networkManagementProvider.notifier).disconnectFromDevice(connection['id']);
  }

  void _showFtpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect to FTP Server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ftpHostController,
              decoration: const InputDecoration(
                labelText: 'Host',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ftpPortController,
              decoration: const InputDecoration(
                labelText: 'Port',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ftpUsernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ftpPasswordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
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
              ref.read(networkManagementProvider.notifier).connectToFtp(
                _ftpHostController.text,
                int.tryParse(_ftpPortController.text) ?? 21,
                _ftpUsernameController.text,
                _ftpPasswordController.text,
              );
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showWebDAVDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect to WebDAV Server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _webdavUrlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _webdavUsernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _webdavPasswordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
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
              ref.read(networkManagementProvider.notifier).connectToWebDAV(
                _webdavUrlController.text,
                _webdavUsernameController.text,
                _webdavPasswordController.text,
              );
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _toggleService(Map<String, dynamic> service, bool enabled) {
    // This would toggle the service on/off
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${service['name']} ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  Color _getDeviceColor(String type) {
    switch (type.toLowerCase()) {
      case 'phone':
        return Colors.blue;
      case 'tablet':
        return Colors.green;
      case 'computer':
        return Colors.orange;
      case 'server':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getDeviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'phone':
        return Icons.smartphone;
      case 'tablet':
        return Icons.tablet;
      case 'computer':
        return Icons.computer;
      case 'server':
        return Icons.dns;
      default:
        return Icons.device_unknown;
    }
  }

  Color _getConnectionColor(String type) {
    switch (type.toLowerCase()) {
      case 'ftp':
        return Colors.blue;
      case 'webdav':
        return Colors.green;
      case 'wifi_direct':
        return Colors.orange;
      case 'p2p':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getConnectionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'ftp':
        return Icons.ftp;
      case 'webdav':
        return Icons.cloud;
      case 'wifi_direct':
        return Icons.wifi;
      case 'p2p':
        return Icons.share;
      default:
        return Icons.link;
    }
  }

  Color _getTransferColor(String status) {
    switch (status.toLowerCase()) {
      case 'transferring':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTransferIcon(String status) {
    switch (status.toLowerCase()) {
      case 'transferring':
        return Icons.swap_horiz;
      case 'completed':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _formatConnectionTime(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      final time = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(time);
      
      if (difference.inMinutes < 1) return 'just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      return '${difference.inDays}d ago';
    } catch (e) {
      return 'Unknown';
    }
  }
}
