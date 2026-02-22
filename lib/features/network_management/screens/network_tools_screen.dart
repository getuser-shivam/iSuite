import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/central_config.dart';
import '../../../core/accessibility_manager.dart';
import '../../../services/network/network_discovery_service.dart';
import '../../../services/network/virtual_drive_service.dart';
import '../../../services/notifications/notification_service.dart';

/// Advanced Network Tools Screen - Inspired by Owlfiles network capabilities
class NetworkToolsScreen extends StatefulWidget {
  const NetworkToolsScreen({super.key});

  @override
  State<NetworkToolsScreen> createState() => _NetworkToolsScreenState();
}

class _NetworkToolsScreenState extends State<NetworkToolsScreen> {
  final NetworkDiscoveryService _discoveryService = NetworkDiscoveryService();
  final VirtualDriveService _virtualDriveService = VirtualDriveService();
  final AccessibilityManager _accessibility = AccessibilityManager();

  List<NetworkDevice> _devices = [];
  Map<String, VirtualDrive> _drives = {};
  NetworkStatus _networkStatus = NetworkStatus(isConnected: false);
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _announceScreenEntry();
  }

  void _announceScreenEntry() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _accessibility.announceToScreenReader(
        'Network tools screen opened. Discover devices and manage virtual drives.',
        assertion: 'screen opened',
      );
    });
  }

  Future<void> _initializeServices() async {
    await _discoveryService.initialize();
    await _virtualDriveService.initialize();

    // Listen to device discoveries
    _discoveryService.devicesStream.listen((devices) {
      if (mounted) {
        setState(() => _devices = devices);
      }
    });

    // Listen to network status
    _discoveryService.networkStatusStream.listen((status) {
      if (mounted) {
        setState(() => _networkStatus = status);
      }
    });

    // Listen to virtual drive events
    _virtualDriveService.driveEvents.listen((event) {
      if (mounted) {
        setState(() => _drives = _virtualDriveService.mountedDrives);
      }

      // Show notification for drive events
      switch (event.type) {
        case DriveEventType.mounted:
          NotificationService().showFileOperationNotification(
            title: 'Drive Mounted',
            body: '${event.drive?.name} is now available',
          );
          break;
        case DriveEventType.unmounted:
          NotificationService().showFileOperationNotification(
            title: 'Drive Unmounted',
            body: '${event.drive?.name} has been disconnected',
          );
          break;
        case DriveEventType.synced:
          NotificationService().showFileOperationNotification(
            title: 'Drive Synced',
            body: '${event.drive?.name} synchronization completed',
          );
          break;
        default:
          break;
      }
    });

    // Get initial data
    setState(() {
      _devices = _discoveryService.discoveredDevices;
      _drives = _virtualDriveService.mountedDrives;
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = CentralConfig.instance;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Network Tools'),
          backgroundColor: config.primaryColor,
          foregroundColor: config.surfaceColor,
          elevation: config.getParameter('ui.app_bar.elevation', defaultValue: 4.0),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.wifi), text: 'Discovery'),
              Tab(icon: Icon(Icons.storage), text: 'Virtual Drives'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDiscoveryTab(),
            _buildVirtualDrivesTab(),
            _buildSettingsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _isScanning ? null : _performNetworkScan,
          backgroundColor: config.primaryColor,
          child: _isScanning
              ? const CircularProgressIndicator(color: Colors.white)
              : const Icon(Icons.refresh),
        ),
      ),
    );
  }

  Widget _buildDiscoveryTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(CentralConfig.instance.getParameter('ui.spacing.medium', defaultValue: 20.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNetworkStatus(),
          const SizedBox(height: 24),
          _buildDiscoveryActions(),
          const SizedBox(height: 24),
          _buildDeviceList(),
        ],
      ),
    );
  }

  Widget _buildNetworkStatus() {
    final accessibleColors = _accessibility.getAccessibleColors(context);

    return Card(
      elevation: CentralConfig.instance.getParameter('ui.shadow.elevation.medium', defaultValue: 4.0),
      child: Padding(
        padding: EdgeInsets.all(CentralConfig.instance.getParameter('ui.spacing.medium', defaultValue: 20.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _networkStatus.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: _networkStatus.isConnected ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Network Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accessibleColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusItem('Connected', _networkStatus.isConnected ? 'Yes' : 'No'),
            if (_networkStatus.wifiName != null)
              _buildStatusItem('WiFi Network', _networkStatus.wifiName!),
            if (_networkStatus.localIP != null)
              _buildStatusItem('Local IP', _networkStatus.localIP!),
            if (_networkStatus.gatewayIP != null)
              _buildStatusItem('Gateway', _networkStatus.gatewayIP!),
            _buildStatusItem('Devices Found', _devices.length.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryActions() {
    return Card(
      elevation: CentralConfig.instance.getParameter('ui.shadow.elevation.low', defaultValue: 2.0),
      child: Padding(
        padding: EdgeInsets.all(CentralConfig.instance.getParameter('ui.spacing.medium', defaultValue: 20.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Network Discovery',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _performNetworkScan,
                  icon: const Icon(Icons.search),
                  label: const Text('Scan Network'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CentralConfig.instance.primaryColor,
                    foregroundColor: CentralConfig.instance.surfaceColor,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _startContinuousMonitoring,
                  icon: const Icon(Icons.visibility),
                  label: const Text('Monitor Network'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _stopContinuousMonitoring,
                  icon: const Icon(Icons.visibility_off),
                  label: const Text('Stop Monitoring'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
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

  Widget _buildDeviceList() {
    if (_devices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.devices,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Devices Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the scan button to discover devices on your network',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discovered Devices (${_devices.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _devices.length,
          itemBuilder: (context, index) => _buildDeviceCard(_devices[index]),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(NetworkDevice device) {
    final deviceIcon = _getDeviceIcon(device.deviceType);
    final accessibleColors = _accessibility.getAccessibleColors(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: CentralConfig.instance.getParameter('ui.shadow.elevation.low', defaultValue: 2.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accessibleColors.primary.withOpacity(0.1),
          child: Icon(deviceIcon, color: accessibleColors.primary),
        ),
        title: Text(
          device.displayName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.ipAddress),
            if (device.services.isNotEmpty)
              Text(
                'Services: ${device.services.map((s) => s.name).join(', ')}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: device.isReachable
            ? const Icon(Icons.wifi, color: Colors.green)
            : const Icon(Icons.wifi_off, color: Colors.red),
        onTap: () => _showDeviceDetails(device),
      ),
    );
  }

  Widget _buildVirtualDrivesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(CentralConfig.instance.getParameter('ui.spacing.medium', defaultValue: 20.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDriveActions(),
          const SizedBox(height: 24),
          _buildDriveList(),
        ],
      ),
    );
  }

  Widget _buildDriveActions() {
    return Card(
      elevation: CentralConfig.instance.getParameter('ui.shadow.elevation.low', defaultValue: 2.0),
      child: Padding(
        padding: EdgeInsets.all(CentralConfig.instance.getParameter('ui.spacing.medium', defaultValue: 20.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Virtual Drives',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _addFTPDrive,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Add FTP Drive'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addSMBDrive,
                  icon: const Icon(Icons.storage),
                  label: const Text('Add SMB Drive'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addNASDrive,
                  icon: const Icon(Icons.dns),
                  label: const Text('Add NAS Drive'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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

  Widget _buildDriveList() {
    if (_drives.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.drive_file_move,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Virtual Drives',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add virtual drives to access remote files seamlessly',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mounted Drives (${_drives.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._drives.values.map((drive) => _buildDriveCard(drive)),
      ],
    );
  }

  Widget _buildDriveCard(VirtualDrive drive) {
    final accessibleColors = _accessibility.getAccessibleColors(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: CentralConfig.instance.getParameter('ui.shadow.elevation.low', defaultValue: 2.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accessibleColors.primary.withOpacity(0.1),
          child: Icon(_getDriveIcon(drive.type), color: accessibleColors.primary),
        ),
        title: Text(
          drive.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${drive.type.name.toUpperCase()} - ${drive.config.host}'),
            if (drive.lastSync != null)
              Text(
                'Last sync: ${drive.lastSync!.toString().split('.')[0]}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              drive.isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: drive.isOnline ? Colors.green : Colors.red,
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showDriveMenu(drive),
            ),
          ],
        ),
        onTap: () => _browseDrive(drive),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(CentralConfig.instance.getParameter('ui.spacing.medium', defaultValue: 20.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNetworkSettings(),
          const SizedBox(height: 24),
          _buildDriveSettings(),
        ],
      ),
    );
  }

  Widget _buildNetworkSettings() {
    return Card(
      elevation: CentralConfig.instance.getParameter('ui.shadow.elevation.medium', defaultValue: 4.0),
      child: Padding(
        padding: EdgeInsets.all(CentralConfig.instance.getParameter('ui.spacing.medium', defaultValue: 20.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Network Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto-discover devices'),
              subtitle: const Text('Automatically scan for network devices'),
              value: true, // Would be from config
              onChanged: (value) {
                // Implementation
              },
            ),
            SwitchListTile(
              title: const Text('Continuous monitoring'),
              subtitle: const Text('Monitor network changes in background'),
              value: false, // Would be from config
              onChanged: (value) {
                // Implementation
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriveSettings() {
    return Card(
      elevation: CentralConfig.instance.getParameter('ui.shadow.elevation.medium', defaultValue: 4.0),
      child: Padding(
        padding: EdgeInsets.all(CentralConfig.instance.getParameter('ui.spacing.medium', defaultValue: 20.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Virtual Drive Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto-mount drives'),
              subtitle: const Text('Automatically mount saved virtual drives'),
              value: true, // Would be from config
              onChanged: (value) {
                // Implementation
              },
            ),
            SwitchListTile(
              title: const Text('Background sync'),
              subtitle: const Text('Sync drives in background'),
              value: false, // Would be from config
              onChanged: (value) {
                // Implementation
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performNetworkScan() async {
    setState(() => _isScanning = true);

    await _discoveryService.performNetworkScan();

    setState(() => _isScanning = false);
  }

  void _startContinuousMonitoring() {
    _discoveryService.startContinuousMonitoring();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Network monitoring started')),
    );
  }

  void _stopContinuousMonitoring() {
    _discoveryService.stopContinuousMonitoring();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Network monitoring stopped')),
    );
  }

  void _showDeviceDetails(NetworkDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(device.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IP Address: ${device.ipAddress}'),
            if (device.hostname != null) Text('Hostname: ${device.hostname}'),
            Text('Type: ${device.deviceType.name}'),
            Text('Status: ${device.isReachable ? 'Online' : 'Offline'}'),
            if (device.services.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Services:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...device.services.map((service) => Text(
                '• ${service.name} (Port ${service.port})',
                style: TextStyle(
                  color: service.isSecure ? Colors.green : Colors.black,
                  fontStyle: service.isSecure ? FontStyle.italic : FontStyle.normal,
                ),
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (device.hasFileSharing)
            ElevatedButton(
              onPressed: () => _connectToDevice(device),
              child: const Text('Connect'),
            ),
        ],
      ),
    );
  }

  void _connectToDevice(NetworkDevice device) {
    Navigator.of(context).pop();
    // Implementation for connecting to device
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connecting to ${device.displayName}...')),
    );
  }

  void _addFTPDrive() {
    _showAddDriveDialog(DriveType.ftp);
  }

  void _addSMBDrive() {
    _showAddDriveDialog(DriveType.smb);
  }

  void _addNASDrive() {
    _showAddDriveDialog(DriveType.nas);
  }

  void _showAddDriveDialog(DriveType type) {
    // Implementation for adding drive dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add ${type.name.toUpperCase()} drive - Coming soon!')),
    );
  }

  void _showDriveMenu(VirtualDrive drive) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('Browse'),
            onTap: () {
              Navigator.of(context).pop();
              _browseDrive(drive);
            },
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync'),
            onTap: () {
              Navigator.of(context).pop();
              _syncDrive(drive);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.of(context).pop();
              _showDriveSettings(drive);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Unmount', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(context).pop();
              _unmountDrive(drive);
            },
          ),
        ],
      ),
    );
  }

  void _browseDrive(VirtualDrive drive) {
    // Implementation for browsing drive
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Browsing ${drive.name}...')),
    );
  }

  void _syncDrive(VirtualDrive drive) {
    _virtualDriveService.syncDrive(drive.id);
  }

  void _showDriveSettings(VirtualDrive drive) {
    // Implementation for drive settings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings for ${drive.name}')),
    );
  }

  void _unmountDrive(VirtualDrive drive) {
    _virtualDriveService.unmountDrive(drive.id);
  }

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.computer:
        return Icons.computer;
      case DeviceType.mobile:
        return Icons.smartphone;
      case DeviceType.router:
        return Icons.router;
      case DeviceType.nas:
        return Icons.storage;
      case DeviceType.printer:
        return Icons.print;
      case DeviceType.server:
        return Icons.dns;
      default:
        return Icons.device_unknown;
    }
  }

  IconData _getDriveIcon(DriveType type) {
    switch (type) {
      case DriveType.ftp:
        return Icons.cloud_upload;
      case DriveType.sftp:
        return Icons.security;
      case DriveType.smb:
        return Icons.folder_shared;
      case DriveType.webdav:
        return Icons.web;
      case DriveType.nas:
        return Icons.dns;
      case DriveType.cloud:
        return Icons.cloud;
    }
  }

  @override
  void dispose() {
    _discoveryService.dispose();
    _virtualDriveService.dispose();
    super.dispose();
  }
}
