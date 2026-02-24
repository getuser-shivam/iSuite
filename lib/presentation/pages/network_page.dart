import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/network_provider.dart';
import '../../core/widgets/animated_counter.dart';
import '../../core/widgets/gradient_card.dart';
import '../../core/widgets/slide_in_animation.dart';
import '../../core/widgets/scale_animation.dart';
import '../../core/widgets/pulse_animation.dart';

/// Enhanced Network Page with Advanced Features (Inspired by Owlfiles & Open Source Solutions)
class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isScanning = false;
  bool _isStreaming = false;
  Map<String, dynamic> _networkInfo = {};
  List<Map<String, dynamic>> _discoveredDevices = [];
  List<Map<String, dynamic>> _sharedFolders = [];
  List<Map<String, dynamic>> _activeStreams = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Increased to 5 tabs
    _initializeNetworkFeatures();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeNetworkFeatures() {
    // Initialize network data (inspired by Owlfiles features)
    _networkInfo = {
      'wifi_ssid': 'Home Network',
      'ip_address': '192.168.1.100',
      'subnet_mask': '255.255.255.0',
      'gateway': '192.168.1.1',
      'dns_servers': ['8.8.8.8', '8.8.4.4'],
      'mac_address': 'AA:BB:CC:DD:EE:FF',
      'connection_type': 'WiFi',
      'signal_strength': 85,
      'connection_speed': '100 Mbps',
    };

    // Mock discovered devices (inspired by FileGator and OpenFTP)
    _discoveredDevices = [
      {
        'name': 'Home NAS Server',
        'ip': '192.168.1.10',
        'type': 'nas',
        'services': ['SMB', 'FTP', 'WebDAV'],
        'status': 'online',
        'shared_folders': 12,
        'total_space': '4TB',
        'available_space': '2.8TB',
      },
      {
        'name': 'Work Laptop',
        'ip': '192.168.1.101',
        'type': 'computer',
        'services': ['SMB', 'FTP'],
        'status': 'online',
        'shared_folders': 3,
        'os': 'Windows 11',
      },
      {
        'name': 'Mobile Phone',
        'ip': '192.168.1.102',
        'type': 'mobile',
        'services': ['FTP'],
        'status': 'online',
        'shared_folders': 1,
        'os': 'Android',
      },
      {
        'name': 'Network Printer',
        'ip': '192.168.1.103',
        'type': 'printer',
        'services': ['IPP', 'SMB'],
        'status': 'offline',
        'last_seen': '2 hours ago',
      },
    ];

    // Mock shared folders (inspired by Owlfiles streaming)
    _sharedFolders = [
      {
        'name': 'Movies',
        'server': 'Home NAS',
        'path': '/shared/movies',
        'size': '500GB',
        'files': 245,
        'streaming_enabled': true,
        'access_level': 'Read-Only',
      },
      {
        'name': 'Music',
        'server': 'Home NAS',
        'path': '/shared/music',
        'size': '120GB',
        'files': 1200,
        'streaming_enabled': true,
        'access_level': 'Read-Write',
      },
      {
        'name': 'Documents',
        'server': 'Work Laptop',
        'path': '/Users/Documents',
        'size': '25GB',
        'files': 1500,
        'streaming_enabled': false,
        'access_level': 'Read-Only',
      },
    ];

    // Mock active streams (inspired by Owlfiles streaming capabilities)
    _activeStreams = [
      {
        'file': 'movie.mp4',
        'client': 'Living Room TV',
        'progress': 0.75,
        'speed': '8.5 MB/s',
        'time_remaining': '15m 32s',
      },
      {
        'file': 'song.mp3',
        'client': 'Mobile Phone',
        'progress': 0.45,
        'speed': '320 KB/s',
        'time_remaining': '2m 18s',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Management'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Discovery', icon: Icon(Icons.search)),
            Tab(text: 'Devices', icon: Icon(Icons.devices)),
            Tab(text: 'Sharing', icon: Icon(Icons.share)),
            Tab(text: 'Streaming', icon: Icon(Icons.play_circle)),
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscoveryTab(),
          _buildDevicesTab(),
          _buildSharingTab(),
          _buildStreamingTab(),
          _buildNetworkSettingsTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildDiscoveryTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Network Discovery',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan and discover devices on your network (Inspired by Owlfiles & FileGator)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Network Info Card
          GradientCard(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.primary.withOpacity(0.05),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.wifi,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _networkInfo['wifi_ssid'] ?? 'Unknown Network',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_networkInfo['ip_address']} • ${_networkInfo['connection_speed']}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.signal_wifi_4_bar, size: 16, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              '${_networkInfo['signal_strength'] ?? 0}%',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Scan Controls
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? null : _startNetworkScan,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(_isScanning ? 'Scanning...' : 'Scan Network'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: _refreshNetworkInfo,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Network Info',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildQuickStat(
                  context,
                  'Devices Found',
                  _discoveredDevices.length.toString(),
                  Icons.devices,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStat(
                  context,
                  'Shared Folders',
                  _sharedFolders.length.toString(),
                  Icons.folder_shared,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStat(
                  context,
                  'Active Streams',
                  _activeStreams.length.toString(),
                  Icons.stream,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Network Devices',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discovered devices and services (Inspired by OpenFTP & Sigma File Manager)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: ListView.builder(
              itemCount: _discoveredDevices.length,
              itemBuilder: (context, index) {
                final device = _discoveredDevices[index];
                return SlideInAnimation(
                  direction: index % 2 == 0 ? SlideDirection.fromLeft : SlideDirection.fromRight,
                  delay: Duration(milliseconds: 100 + (index * 50)),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: _getDeviceColor(device['type']).withOpacity(0.2),
                        child: Icon(
                          _getDeviceIcon(device['type']),
                          color: _getDeviceColor(device['type']),
                        ),
                      ),
                      title: Text(device['name']),
                      subtitle: Text('${device['ip']} • ${device['status']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: device['status'] == 'online'
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: device['status'] == 'online'
                                    ? Colors.green
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              device['status'].toUpperCase(),
                              style: TextStyle(
                                color: device['status'] == 'online'
                                    ? Colors.green
                                    : Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            onSelected: (action) => _handleDeviceAction(action, device),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'connect',
                                child: ListTile(
                                  leading: Icon(Icons.link, size: 20),
                                  title: Text('Connect'),
                                  dense: true,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'browse',
                                child: ListTile(
                                  leading: Icon(Icons.folder_open, size: 20),
                                  title: Text('Browse Files'),
                                  dense: true,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'ping',
                                child: ListTile(
                                  leading: Icon(Icons.network_ping, size: 20),
                                  title: Text('Ping Test'),
                                  dense: true,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'info',
                                child: ListTile(
                                  leading: Icon(Icons.info, size: 20),
                                  title: Text('Device Info'),
                                  dense: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: (device['services'] as List<dynamic>).map((service) {
                                  return Chip(
                                    label: Text(service, style: const TextStyle(fontSize: 12)),
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    side: BorderSide(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              if (device['shared_folders'] != null) ...[
                                Text(
                                  'Shared Folders: ${device['shared_folders']}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                              if (device['total_space'] != null) ...[
                                Text(
                                  'Storage: ${device['available_space']} / ${device['total_space']} available',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                              if (device['os'] != null) ...[
                                Text(
                                  'OS: ${device['os']}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharingTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'File Sharing',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Shared folders and network resources (Inspired by Owlfiles & Tiny File Manager)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Protocol Support
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildProtocolChip(context, 'SMB/CIFS', Colors.blue),
              _buildProtocolChip(context, 'FTP', Colors.green),
              _buildProtocolChip(context, 'WebDAV', Colors.orange),
              _buildProtocolChip(context, 'NFS', Colors.purple),
              _buildProtocolChip(context, 'AFP', Colors.red),
            ],
          ),

          const SizedBox(height: 24),

          Expanded(
            child: ListView.builder(
              itemCount: _sharedFolders.length,
              itemBuilder: (context, index) {
                final folder = _sharedFolders[index];
                return SlideInAnimation(
                  direction: SlideDirection.fromBottom,
                  delay: Duration(milliseconds: 100 + (index * 100)),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 3,
                    child: ListTile(
                      leading: Stack(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.folder_shared,
                              color: Colors.white,
                            ),
                          ),
                          if (folder['streaming_enabled'])
                            Positioned(
                              top: 0,
                              right: 0,
                              child: PulseAnimation(
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.surface,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    size: 8,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(folder['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${folder['server']} • ${folder['files']} files'),
                          Text(
                            '${folder['size']} • ${folder['access_level']}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () => _openSharedFolder(folder),
                            tooltip: 'Open Folder',
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _showFolderOptions(context, folder),
                          ),
                        ],
                      ),
                      onTap: () => _browseSharedFolder(folder),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Media Streaming',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Stream media files across your network (Inspired by Owlfiles streaming)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Streaming Stats
          Row(
            children: [
              Expanded(
                child: _buildStreamingStat(
                  context,
                  'Active Streams',
                  _activeStreams.length.toString(),
                  Icons.stream,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStreamingStat(
                  context,
                  'Bandwidth',
                  '12.3 MB/s',
                  Icons.speed,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Active Streams
          if (_activeStreams.isNotEmpty) ...[
            Text(
              'Active Streams',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _activeStreams.length,
                itemBuilder: (context, index) {
                  final stream = _activeStreams[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircularProgressIndicator(
                        value: stream['progress'],
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(stream['file']),
                      subtitle: Text('${stream['client']} • ${stream['speed']}'),
                      trailing: Text(
                        stream['time_remaining'],
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.stream,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active streams',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start streaming media files from shared folders',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNetworkSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Network Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure network protocols and sharing options',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: ListView(
              children: [
                // FTP Settings
                _buildProtocolSettingsCard(
                  context,
                  'FTP Server',
                  'File Transfer Protocol',
                  Icons.cloud_upload,
                  Colors.blue,
                  [
                    _buildSettingSwitch('Enable FTP Server', true),
                    _buildSettingText('Port', '21'),
                    _buildSettingText('Max Connections', '10'),
                    _buildSettingSwitch('Anonymous Access', false),
                  ],
                ),

                const SizedBox(height: 16),

                // SMB Settings
                _buildProtocolSettingsCard(
                  context,
                  'SMB/CIFS',
                  'Windows File Sharing',
                  Icons.computer,
                  Colors.green,
                  [
                    _buildSettingSwitch('Enable SMB Sharing', true),
                    _buildSettingText('Workgroup', 'WORKGROUP'),
                    _buildSettingSwitch('Guest Access', false),
                  ],
                ),

                const SizedBox(height: 16),

                // WebDAV Settings
                _buildProtocolSettingsCard(
                  context,
                  'WebDAV',
                  'Web-based File Access',
                  Icons.web,
                  Colors.orange,
                  [
                    _buildSettingSwitch('Enable WebDAV', false),
                    _buildSettingText('Port', '8080'),
                    _buildSettingSwitch('SSL/TLS', true),
                  ],
                ),

                const SizedBox(height: 16),

                // Network Discovery
                _buildProtocolSettingsCard(
                  context,
                  'Network Discovery',
                  'Device and Service Discovery',
                  Icons.search,
                  Colors.purple,
                  [
                    _buildSettingSwitch('Enable Discovery', true),
                    _buildSettingText('Scan Interval', '30s'),
                    _buildSettingSwitch('Auto-connect', false),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, String title, String value, IconData icon, Color color) {
    return GradientCard(
      gradient: LinearGradient(
        colors: [
          color.withOpacity(0.15),
          color.withOpacity(0.05),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            AnimatedCounter(
              value: int.tryParse(value) ?? 0,
              duration: const Duration(milliseconds: 1000),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamingStat(BuildContext context, String title, String value, IconData icon, Color color) {
    return GradientCard(
      gradient: LinearGradient(
        colors: [
          color.withOpacity(0.1),
          color.withOpacity(0.05),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolChip(BuildContext context, String protocol, Color color) {
    return Chip(
      label: Text(
        protocol,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      avatar: Icon(
        _getProtocolIcon(protocol),
        size: 16,
        color: color,
      ),
    );
  }

  Widget _buildProtocolSettingsCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    List<Widget> settings,
  ) {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: settings,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSwitch(String title, bool initialValue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Switch(
          value: initialValue,
          onChanged: (value) {
            // Handle setting change
          },
        ),
      ],
    );
  }

  Widget _buildSettingText(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<NetworkProvider>(
      builder: (context, networkProvider, child) {
        return ScaleTransition(
          scale: _isScanning ? const AlwaysStoppedAnimation<double>(0.8) : const AlwaysStoppedAnimation<double>(1.0),
          child: FloatingActionButton.extended(
            onPressed: _isScanning ? _stopNetworkScan : _startNetworkScan,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _isScanning ? Icons.stop : Icons.search,
                key: ValueKey<bool>(_isScanning),
              ),
            ),
            label: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _isScanning ? 'Stop Scan' : 'Scan Network',
                key: ValueKey<bool>(_isScanning),
              ),
            ),
            backgroundColor: _isScanning
                ? Colors.red
                : Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }

  IconData _getDeviceIcon(String? type) {
    switch (type) {
      case 'nas':
        return Icons.storage;
      case 'computer':
        return Icons.computer;
      case 'mobile':
        return Icons.phone_android;
      case 'printer':
        return Icons.print;
      case 'router':
        return Icons.router;
      default:
        return Icons.device_unknown;
    }
  }

  Color _getDeviceColor(String? type) {
    switch (type) {
      case 'nas':
        return Colors.blue;
      case 'computer':
        return Colors.green;
      case 'mobile':
        return Colors.orange;
      case 'printer':
        return Colors.purple;
      case 'router':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getProtocolIcon(String protocol) {
    switch (protocol.toLowerCase()) {
      case 'smb/cifs':
        return Icons.computer;
      case 'ftp':
        return Icons.cloud_upload;
      case 'webdav':
        return Icons.web;
      case 'nfs':
        return Icons.storage;
      case 'afp':
        return Icons.apple;
      default:
        return Icons.settings_ethernet;
    }
  }

  void _startNetworkScan() {
    if (_isScanning) return;

    setState(() => _isScanning = true);

    // Simulate network scanning with progress
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network scan completed!')),
        );
      }
    });
  }

  void _stopNetworkScan() {
    setState(() => _isScanning = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Network scan stopped')),
    );
  }

  void _refreshNetworkInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Network information refreshed')),
    );
  }

  void _handleDeviceAction(String action, Map<String, dynamic> device) {
    switch (action) {
      case 'connect':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connecting to ${device['name']}...')),
        );
        break;
      case 'browse':
        _browseDevice(device);
        break;
      case 'ping':
        _pingDevice(device);
        break;
      case 'info':
        _showDeviceInfo(device);
        break;
    }
  }

  void _browseDevice(Map<String, dynamic> device) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Browsing ${device['name']}...')),
    );
  }

  void _pingDevice(Map<String, dynamic> device) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pinging ${device['name']}...')),
    );
  }

  void _showDeviceInfo(Map<String, dynamic> device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${device['name']} - Device Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IP Address: ${device['ip']}'),
            Text('Type: ${device['type']?.toString().toUpperCase()}'),
            Text('Status: ${device['status']?.toString().toUpperCase()}'),
            if (device['services'] != null)
              Text('Services: ${(device['services'] as List).join(', ')}'),
            if (device['os'] != null)
              Text('Operating System: ${device['os']}'),
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

  void _openSharedFolder(Map<String, dynamic> folder) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${folder['name']}...')),
    );
  }

  void _browseSharedFolder(Map<String, dynamic> folder) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Browsing ${folder['name']}...')),
    );
  }

  void _showFolderOptions(BuildContext context, Map<String, dynamic> folder) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open Folder'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Folder'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Folder Settings'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
