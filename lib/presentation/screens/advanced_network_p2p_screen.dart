import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/enhanced_config_provider.dart';
import '../widgets/common/parameterized_app_bar.dart';
import '../../core/services/advanced_p2p_file_sharing_service.dart';
import '../../core/services/advanced_cross_platform_network_service.dart';

/// Advanced Network & P2P GUI Screen
/// 
/// Comprehensive GUI for network and P2P file sharing
/// Features: Device discovery, connection management, file transfers, real-time updates
/// Performance: Optimized UI, real-time updates, efficient data visualization
/// Architecture: Widget composition, service integration, event-driven updates
/// 
/// Based on research from open-source projects:
/// - Photon: Cross-platform file transfer UI
/// - AirDash: WebRTC file sharing interface
/// - FileGator: Multi-protocol file management
class AdvancedNetworkP2PScreen extends ConsumerStatefulWidget {
  const AdvancedNetworkP2PScreen({super.key});

  @override
  ConsumerState<AdvancedNetworkP2PScreen> createState() => _AdvancedNetworkP2PScreenState();
}

class _AdvancedNetworkP2PScreenState extends ConsumerState<AdvancedNetworkP2PScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final AdvancedP2PFileSharingService _p2pService = AdvancedP2PFileSharingService.instance;
  final AdvancedCrossPlatformNetworkService _networkService = AdvancedCrossPlatformNetworkService.instance;
  
  List<P2PDevice> _p2pDevices = [];
  List<NetworkDevice> _networkDevices = [];
  List<P2PConnection> _p2pConnections = [];
  List<NetworkConnection> _networkConnections = [];
  List<FileTransfer> _p2pTransfers = [];
  List<NetworkTransfer> _networkTransfers = [];
  
  bool _isDiscovering = false;
  bool _autoRefresh = true;
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeServices();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    _p2pService.dispose();
    _networkService.dispose();
    super.dispose();
  }
  
  Future<void> _initializeServices() async {
    await _p2pService.initialize();
    await _networkService.initialize();
    
    // Listen to P2P events
    _p2pService.p2pEvents.listen((event) {
      setState(() {
        _handleP2PEvent(event);
      });
    });
    
    // Listen to network events
    _networkService.networkEvents.listen((event) {
      setState(() {
        _handleNetworkEvent(event);
      });
    });
    
    // Start auto-refresh
    if (_autoRefresh) {
      _startAutoRefresh();
    }
    
    // Initial discovery
    await _startDiscovery();
  }
  
  void _handleP2PEvent(P2PEvent event) {
    switch (event.type) {
      case P2PEventType.deviceFound:
        if (event.data is P2PDevice) {
          _p2pDevices.add(event.data);
        }
        break;
      case P2PEventType.connectionEstablished:
        if (event.data is P2PConnection) {
          _p2pConnections.add(event.data);
        }
        break;
      case P2PEventType.transferProgress:
        if (event.data is FileTransfer) {
          final transfer = event.data as FileTransfer;
          final index = _p2pTransfers.indexWhere((t) => t.id == transfer.id);
          if (index >= 0) {
            _p2pTransfers[index] = transfer;
          } else {
            _p2pTransfers.add(transfer);
          }
        }
        break;
      case P2PEventType.transferCompleted:
        if (event.data is FileTransfer) {
          final transfer = event.data as FileTransfer;
          final index = _p2pTransfers.indexWhere((t) => t.id == transfer.id);
          if (index >= 0) {
            _p2pTransfers[index] = transfer;
          }
        }
        break;
      default:
        break;
    }
  }
  
  void _handleNetworkEvent(NetworkEvent event) {
    switch (event.type) {
      case NetworkEventType.deviceFound:
        if (event.data is List) {
          _networkDevices.addAll(event.data.cast<NetworkDevice>());
        }
        break;
      case NetworkEventType.connectionEstablished:
        if (event.data is NetworkConnection) {
          _networkConnections.add(event.data);
        }
        break;
      case NetworkEventType.transferProgress:
        if (event.data is NetworkTransfer) {
          final transfer = event.data as NetworkTransfer;
          final index = _networkTransfers.indexWhere((t) => t.id == transfer.id);
          if (index >= 0) {
            _networkTransfers[index] = transfer;
          } else {
            _networkTransfers.add(transfer);
          }
        }
        break;
      case NetworkEventType.transferCompleted:
        if (event.data is NetworkTransfer) {
          final transfer = event.data as NetworkTransfer;
          final index = _networkTransfers.indexWhere((t) => t.id == transfer.id);
          if (index >= 0) {
            _networkTransfers[index] = transfer;
          }
        }
        break;
      default:
        break;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Network & P2P'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isDiscovering ? Icons.stop : Icons.refresh),
            onPressed: _isDiscovering ? _stopDiscovery : _startDiscovery,
            tooltip: _isDiscovering ? 'Stop Discovery' : 'Start Discovery',
          ),
          IconButton(
            icon: Icon(_autoRefresh ? Icons.sync : Icons.sync_disabled),
            onPressed: _toggleAutoRefresh,
            tooltip: _autoRefresh ? 'Disable Auto-refresh' : 'Enable Auto-refresh',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
            tooltip: 'Settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'P2P Devices', icon: Icon(Icons.devices)),
            Tab(text: 'Network', icon: Icon(Icons.wifi)),
            Tab(text: 'Transfers', icon: Icon(Icons.swap_horiz)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildP2PDevicesTab(),
          _buildNetworkTab(),
          _buildTransfersTab(),
          _buildStatisticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickActions,
        icon: const Icon(Icons.flash_on),
        label: const Text('Quick Actions'),
      ),
    );
  }

  Widget _buildP2PDevicesTab() {
    return Column(
      children: [
        // Discovery status
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                _isDiscovering ? Icons.search : Icons.done_all,
                color: _isDiscovering ? Colors.orange : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                _isDiscovering ? 'Discovering P2P devices...' : 'Discovery complete',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text('${_p2pDevices.length} devices found'),
            ],
          ),
        ),
        
        // Devices list
        Expanded(
          child: _p2pDevices.isEmpty
              ? _buildEmptyState('No P2P devices found', 'Start device discovery to find nearby devices')
              : ListView.builder(
                  itemCount: _p2pDevices.length,
                  itemBuilder: (context, index) {
                    final device = _p2pDevices[index];
                    return _buildP2PDeviceCard(device);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNetworkTab() {
    return Column(
      children: [
        // Network discovery status
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                _isDiscovering ? Icons.search : Icons.done_all,
                color: _isDiscovering ? Colors.orange : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                _isDiscovering ? 'Scanning network...' : 'Network scan complete',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text('${_networkDevices.length} devices found'),
            ],
          ),
        ),
        
        // Add connection button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddConnectionDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Connection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Network devices list
        Expanded(
          child: _networkDevices.isEmpty
              ? _buildEmptyState('No network devices found', 'Scan network to discover devices')
              : ListView.builder(
                  itemCount: _networkDevices.length,
                  itemBuilder: (context, index) {
                    final device = _networkDevices[index];
                    return _buildNetworkDeviceCard(device);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTransfersTab() {
    return Column(
      children: [
        // Transfer status
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.swap_horiz),
              const SizedBox(width: 8),
              Text(
                'Active Transfers',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text('${_p2pTransfers.length + _networkTransfers.length} active'),
            ],
          ),
        ),
        
        // Transfers list
        Expanded(
          child: (_p2pTransfers.isEmpty && _networkTransfers.isEmpty)
              ? _buildEmptyState('No active transfers', 'Start a file transfer to see progress')
              : ListView(
                  children: [
                    // P2P transfers
                    if (_p2pTransfers.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('P2P Transfers', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ..._p2pTransfers.map((transfer) => _buildTransferCard(transfer, true)),
                    ],
                    
                    // Network transfers
                    if (_networkTransfers.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Network Transfers', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ..._networkTransfers.map((transfer) => _buildNetworkTransferCard(transfer)),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab() {
    final p2pStats = _p2pService.getStatistics();
    final networkStats = _networkService.getStatistics();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Network & P2P Statistics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // P2P Statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'P2P Statistics',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2,
                    children: [
                      _buildStatCard('Total Transfers', '${p2pStats.totalTransfers}', Icons.swap_horiz),
                      _buildStatCard('Completed', '${p2pStats.completedTransfers}', Icons.check_circle),
                      _buildStatCard('Failed', '${p2pStats.failedTransfers}', Icons.error),
                      _buildStatCard('Active Connections', '${p2pStats.activeConnections}', Icons.link),
                      _buildStatCard('Discovered Devices', '${p2pStats.discoveredDevices}', Icons.devices),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Network Statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Network Statistics',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2,
                    children: [
                      _buildStatCard('Total Connections', '${networkStats.totalConnections}', Icons.link),
                      _buildStatCard('Active Connections', '${networkStats.activeConnections}', Icons.link),
                      _buildStatCard('Discovered Devices', '${networkStats.discoveredDevices}', Icons.devices),
                      _buildStatCard('HTTP Connections', '${networkStats.httpConnections}', Icons.http),
                      _buildStatCard('WebSocket Connections', '${networkStats.webSocketConnections}', Icons.wifi),
                      _buildStatCard('FTP Connections', '${networkStats.ftpConnections}', Icons.ftp),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildP2PDeviceCard(P2PDevice device) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getDeviceTypeColor(device.type),
          child: Icon(
            _getDeviceTypeIcon(device.type),
            color: Colors.white,
          ),
        ),
        title: Text(device.name),
        subtitle: Text('${device.type.name} • ${device.address}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              device.isAvailable ? Icons.wifi : Icons.wifi_off,
              color: device.isAvailable ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: device.isAvailable ? () => _connectToP2PDevice(device) : null,
              child: const Text('Connect'),
            ),
          ],
        ),
        onTap: () => _showP2PDeviceDetails(device),
      ),
    );
  }

  Widget _buildNetworkDeviceCard(NetworkDevice device) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNetworkDeviceTypeColor(device.type),
          child: Icon(
            _getNetworkDeviceTypeIcon(device.type),
            color: Colors.white,
          ),
        ),
        title: Text(device.name),
        subtitle: Text('${device.type.name} • ${device.address}:${device.port}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              device.isAvailable ? Icons.cloud : Icons.cloud_off,
              color: device.isAvailable ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: device.isAvailable ? () => _connectToNetworkDevice(device) : null,
              child: const Text('Connect'),
            ),
          ],
        ),
        onTap: () => _showNetworkDeviceDetails(device),
      ),
    );
  }

  Widget _buildTransferCard(FileTransfer transfer, bool isP2P) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTransferStatusColor(transfer.status),
          child: Icon(
            _getTransferStatusIcon(transfer.status),
            color: Colors.white,
          ),
        ),
        title: Text(transfer.file?.path.split('/').last ?? 'Unknown'),
        subtitle: Text('${transfer.status.name} • ${_formatBytes(transfer.transferredBytes)}/${_formatBytes(transfer.totalBytes)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (transfer.status == TransferStatus.transferring || transfer.status == TransferStatus.receiving) ...[
              Text('${transfer.progress.toStringAsFixed(1)}%'),
              const SizedBox(width: 8),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  value: transfer.progress / 100,
                  strokeWidth: 2,
                ),
              ),
            ],
            if (transfer.status == TransferStatus.completed) ...[
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () => _openTransferedFile(transfer),
                tooltip: 'Open File',
              ),
            ],
            if (transfer.status == TransferStatus.failed) ...[
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _retryTransfer(transfer),
                tooltip: 'Retry Transfer',
              ),
            ],
            if (transfer.status == TransferStatus.transferring || transfer.status == TransferStatus.receiving) ...[
              IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: () => _cancelTransfer(transfer),
                tooltip: 'Cancel Transfer',
              ),
            ],
          ],
        ),
        onTap: () => _showTransferDetails(transfer, isP2P),
      ),
    );
  }

  Widget _buildNetworkTransferCard(NetworkTransfer transfer) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTransferStatusColor(transfer.status),
          child: Icon(
            _getTransferStatusIcon(transfer.status),
            color: Colors.white,
          ),
        ),
        title: Text(transfer.file?.path.split('/').last ?? transfer.remotePath ?? 'Unknown'),
        subtitle: Text('${transfer.type.name} • ${transfer.status.name} • ${_formatBytes(transfer.transferredBytes)}/${_formatBytes(transfer.totalBytes)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (transfer.status == TransferStatus.transferring) ...[
              Text('${transfer.progress.toStringAsFixed(1)}%'),
              const SizedBox(width: 8),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  value: transfer.progress / 100,
                  strokeWidth: 2,
                ),
              ),
            ],
            if (transfer.status == TransferStatus.completed) ...[
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () => _openTransferedFile(transfer),
                tooltip: 'Open File',
              ),
            ],
            if (transfer.status == TransferStatus.failed) ...[
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _retryTransfer(transfer),
                tooltip: 'Retry Transfer',
              ),
            ],
            if (transfer.status == TransferStatus.transferring) ...[
              IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: () => _cancelTransfer(transfer),
                tooltip: 'Cancel Transfer',
              ),
            ],
          ],
        ),
        onTap: () => _showNetworkTransferDetails(transfer),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
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

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_other,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Action methods
  
  Future<void> _startDiscovery() async {
    setState(() {
      _isDiscovering = true;
    });
    
    await _p2pService.startDeviceDiscovery();
    await _networkService.discoverNetworkDevices();
    
    setState(() {
      _isDiscovering = false;
    });
  }
  
  Future<void> _stopDiscovery() async {
    setState(() {
      _isDiscovering = false;
    });
  }
  
  void _toggleAutoRefresh() {
    setState(() {
      _autoRefresh = !_autoRefresh;
    });
    
    if (_autoRefresh) {
      _startAutoRefresh();
    } else {
      _stopAutoRefresh();
    }
  }
  
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _startDiscovery();
    });
  }
  
  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
  
  Future<void> _connectToP2PDevice(P2PDevice device) async {
    try {
      await _p2pService.connectToDevice(device);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect: $e')),
      );
    }
  }
  
  Future<void> _connectToNetworkDevice(NetworkDevice device) async {
    try {
      switch (device.type) {
        case NetworkDeviceType.http:
          await _networkService.connectHTTP('http://${device.address}:${device.port}');
          break;
        case NetworkDeviceType.websocket:
          await _networkService.connectWebSocket('ws://${device.address}:${device.port}');
          break;
        case NetworkDeviceType.ftp:
          await _networkService.connectFTP(device.address, device.port, '', '');
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Protocol not yet implemented')),
          );
          return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect: $e')),
      );
    }
  }
  
  Future<void> _cancelTransfer(FileTransfer transfer) async {
    await _p2pService.cancelTransfer(transfer.id);
  }
  
  Future<void> _retryTransfer(FileTransfer transfer) async {
    // Implement retry logic
  }
  
  void _openTransferedFile(FileTransfer transfer) {
    if (transfer.file != null) {
      // Open the file
    }
  }
  
  void _showP2PDeviceDetails(P2PDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(device.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${device.type.name}'),
            Text('Address: ${device.address}'),
            Text('Available: ${device.isAvailable ? 'Yes' : 'No'}'),
            Text('Discovered: ${device.discoveredAt}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _connectToP2PDevice(device);
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
  
  void _showNetworkDeviceDetails(NetworkDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(device.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${device.type.name}'),
            Text('Address: ${device.address}'),
            Text('Port: ${device.port}'),
            Text('Available: ${device.isAvailable ? 'Yes' : 'No'}'),
            Text('Discovered: ${device.discoveredAt}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _connectToNetworkDevice(device);
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
  
  void _showTransferDetails(FileTransfer transfer, bool isP2P) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transfer Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: ${transfer.file?.path ?? 'Unknown'}'),
            Text('Status: ${transfer.status.name}'),
            Text('Progress: ${transfer.progress.toStringAsFixed(1)}%'),
            Text('Transferred: ${_formatBytes(transfer.transferredBytes)}'),
            Text('Total: ${_formatBytes(transfer.totalBytes)}'),
            if (transfer.duration != null) Text('Duration: ${transfer.duration!.inSeconds}s'),
            if (transfer.error != null) Text('Error: ${transfer.error}'),
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
  
  void _showNetworkTransferDetails(NetworkTransfer transfer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transfer Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${transfer.type.name}'),
            Text('Status: ${transfer.status.name}'),
            Text('Progress: ${transfer.progress.toStringAsFixed(1)}%'),
            Text('Transferred: ${_formatBytes(transfer.transferredBytes)}'),
            Text('Total: ${_formatBytes(transfer.totalBytes)}'),
            if (transfer.duration != null) Text('Duration: ${transfer.duration!.inSeconds}s'),
            if (transfer.error != null) Text('Error: ${transfer.error}'),
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
  
  void _showAddConnectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Port',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<NetworkDeviceType>(
              decoration: const InputDecoration(
                labelText: 'Protocol',
                border: OutlineInputBorder(),
              ),
              items: NetworkDeviceType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name),
                );
              }).toList(),
              onChanged: (value) {
                // Handle protocol selection
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Add connection logic
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
  
  void _showSettings() {
    _tabController.animateTo(3); // Navigate to statistics tab
  }
  
  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
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
              leading: const Icon(Icons.search),
              title: const Text('Start Device Discovery'),
              subtitle: const Text('Scan for nearby devices'),
              onTap: () {
                Navigator.of(context).pop();
                _startDiscovery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Manual Connection'),
              subtitle: const Text('Connect to a specific device'),
              onTap: () {
                Navigator.of(context).pop();
                _showAddConnectionDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Send File'),
              subtitle: const Text('Send a file to connected device'),
              onTap: () {
                Navigator.of(context).pop();
                // Show file picker
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Clear All Connections'),
              subtitle: const Text('Disconnect all devices'),
              onTap: () {
                Navigator.of(context).pop();
                // Clear all connections
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper methods
  
  Color _getDeviceTypeColor(P2PDeviceType type) {
    switch (type) {
      case P2PDeviceType.webrtc:
        return Colors.blue;
      case P2PDeviceType.wifiDirect:
        return Colors.green;
      case P2PDeviceType.bluetooth:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getDeviceTypeIcon(P2PDeviceType type) {
    switch (type) {
      case P2PDeviceType.webrtc:
        return Icons.wifi;
      case P2PDeviceType.wifiDirect:
        return Icons.wifi_tethering;
      case P2PDeviceType.bluetooth:
        return Icons.bluetooth;
      default:
        return Icons.device_unknown;
    }
  }
  
  Color _getNetworkDeviceTypeColor(NetworkDeviceType type) {
    switch (type) {
      case NetworkDeviceType.http:
        return Colors.blue;
      case NetworkDeviceType.websocket:
        return Colors.green;
      case NetworkDeviceType.ftp:
        return Colors.orange;
      case NetworkDeviceType.smb:
        return Colors.purple;
      case NetworkDeviceType.webdav:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getNetworkDeviceTypeIcon(NetworkDeviceType type) {
    switch (type) {
      case NetworkDeviceType.http:
        return Icons.http;
      case NetworkDeviceType.websocket:
        return Icons.wifi;
      case NetworkDeviceType.ftp:
        return Icons.ftp;
      case NetworkDeviceType.smb:
        return Icons.folder_shared;
      case NetworkDeviceType.webdav:
        return Icons.cloud;
      default:
        return Icons.device_unknown;
    }
  }
  
  Color _getTransferStatusColor(TransferStatus status) {
    switch (status) {
      case TransferStatus.preparing:
        return Colors.orange;
      case TransferStatus.transferring:
      case TransferStatus.receiving:
        return Colors.blue;
      case TransferStatus.completed:
        return Colors.green;
      case TransferStatus.failed:
        return Colors.red;
      case TransferStatus.cancelled:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getTransferStatusIcon(TransferStatus status) {
    switch (status) {
      case TransferStatus.preparing:
        return Icons.hourglass_empty;
      case TransferStatus.transferring:
      case TransferStatus.receiving:
        return Icons.swap_horiz;
      case TransferStatus.completed:
        return Icons.check_circle;
      case TransferStatus.failed:
        return Icons.error;
      case TransferStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
