import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/central_config.dart';
import '../providers/enhanced_network_provider.dart';
import '../../core/network_sharing_engine.dart';
import '../../domain/models/shared_file_model.dart';
import '../../domain/models/discovered_device_model.dart';

/// Enhanced Network Sharing Widget with Central Parameterization
/// Provides comprehensive WiFi and file sharing capabilities
/// Inspired by Sharik and ezshare open-source projects
class EnhancedNetworkSharingWidget extends StatefulWidget {
  const EnhancedNetworkSharingWidget({super.key});

  @override
  State<EnhancedNetworkSharingWidget> createState() => _EnhancedNetworkSharingWidgetState();
}

class _EnhancedNetworkSharingWidgetState extends State<EnhancedNetworkSharingWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late EnhancedNetworkProvider _networkProvider;
  late CentralConfig _config;
  
  // UI State
  bool _isScanning = false;
  bool _isSharing = false;
  String? _selectedShareId;
  List<String> _selectedFiles = [];
  
  // Animation Controllers
  late AnimationController _scanAnimationController;
  late AnimationController _shareAnimationController;
  
  // Form Controllers
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: 4, vsync: this);
    _networkProvider = Provider.of<EnhancedNetworkProvider>(context, listen: false);
    _config = CentralConfig.instance;
    
    // Animation controllers
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _shareAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    // Initialize with central config values
    _initializeFromConfig();
    
    // Listen to network events
    _networkProvider.events.listen(_handleNetworkEvent);
  }

  void _initializeFromConfig() {
    _ssidController.text = _config.getParameter<String>('default_wifi_ssid') ?? 'iSuite_Share';
    _passwordController.text = _config.getParameter<String>('default_wifi_password') ?? 'isuite123';
    _portController.text = _config.getParameter<int>('http_port')?.toString() ?? '8080';
  }

  void _handleNetworkEvent(NetworkEvent event) {
    if (mounted) {
      setState(() {
        switch (event.type) {
          case NetworkEventType.discoveryStarted:
            _isScanning = true;
            _scanAnimationController.repeat();
            break;
          case NetworkEventType.discoveryStopped:
            _isScanning = false;
            _scanAnimationController.stop();
            break;
          case NetworkEventType.sharingServerStarted:
            _isSharing = true;
            _shareAnimationController.forward();
            break;
          case NetworkEventType.sharingServerStopped:
            _isSharing = false;
            _shareAnimationController.reverse();
            break;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Network & File Sharing'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.wifi), text: 'WiFi'),
            Tab(icon: Icon(Icons.share), text: 'Share'),
            Tab(icon: Icon(Icons.devices), text: 'Devices'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshAll,
            tooltip: 'Refresh All',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWifiTab(),
          _buildShareTab(),
          _buildDevicesTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildWifiTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // WiFi Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wifi, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('WiFi Status', style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildWifiStatus(),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // WiFi Networks
          Expanded(
            child: Card(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Available Networks', style: Theme.of(context).textTheme.titleMedium),
                        AnimatedBuilder(
                          animation: _scanAnimationController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _scanAnimationController.value * 6.28,
                              child: Icon(Icons.refresh),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                  Expanded(child: _buildNetworksList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWifiStatus() {
    return Consumer<EnhancedNetworkProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            _buildStatusRow('Connected', provider.isConnected ? 'Yes' : 'No'),
            _buildStatusRow('Network Name', provider.currentWifiName ?? 'Not connected'),
            _buildStatusRow('Local IP', provider.localIpAddress ?? 'Not available'),
            _buildStatusRow('Signal Strength', '${provider.signalStrength} dBm'),
            _buildStatusRow('Connection Speed', '${provider.connectionSpeed.toStringAsFixed(1)} Mbps'),
          ],
        );
      },
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNetworksList() {
    return Consumer<EnhancedNetworkProvider>(
      builder: (context, provider, child) {
        if (provider.isScanning) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (provider.availableNetworks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No networks found'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _scanNetworks,
                  child: Text('Scan Networks'),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: provider.availableNetworks.length,
          itemBuilder: (context, index) {
            final network = provider.availableNetworks[index];
            return ListTile(
              leading: Icon(
                network.isSecure ? Icons.lock : Icons.wifi,
                color: network.isSecure ? Colors.orange : Colors.green,
              ),
              title: Text(network.ssid),
              subtitle: Text('Signal: ${network.signalStrength} dBm'),
              trailing: network.isSecure ? Icon(Icons.lock_outline) : null,
              onTap: () => _connectToNetwork(network),
            );
          },
        );
      },
    );
  }

  Widget _buildShareTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Share Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _shareAnimationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 0.8 + (_shareAnimationController.value * 0.2),
                            child: Icon(
                              _isSharing ? Icons.share : Icons.share_outlined,
                              color: _isSharing ? Colors.green : Colors.grey,
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 8),
                      Text('Sharing Status', style: Theme.of(context).textTheme.titleLarge),
                      Spacer(),
                      Switch(
                        value: _isSharing,
                        onChanged: _toggleSharing,
                      ),
                    ],
                  ),
                  if (_isSharing) ...[
                    SizedBox(height: 16),
                    _buildSharingInfo(),
                  ],
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // File Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Files to Share', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectFiles,
                          icon: Icon(Icons.file_upload),
                          label: Text('Choose Files'),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectFolder,
                          icon: Icon(Icons.folder_upload),
                          label: Text('Choose Folder'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildSelectedFilesList(),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // QR Code
          if (_selectedShareId != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Share via QR Code', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 16),
                    _buildQRCode(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSharingInfo() {
    return Consumer<EnhancedNetworkProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            _buildStatusRow('Server Running', provider.isSharingServerRunning ? 'Yes' : 'No'),
            _buildStatusRow('Local IP', provider.localIpAddress ?? 'Not available'),
            _buildStatusRow('Port', _portController.text),
            _buildStatusRow('Shared Files', '${provider.sharedFiles.length}'),
            _buildStatusRow('Active Transfers', '${provider.activeTransfers.length}'),
          ],
        );
      },
    );
  }

  Widget _buildSelectedFilesList() {
    if (_selectedFiles.isEmpty) {
      return Container(
        height: 100,
        child: Center(
          child: Text('No files selected', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    
    return Container(
      height: 150,
      child: ListView.builder(
        itemCount: _selectedFiles.length,
        itemBuilder: (context, index) {
          final filePath = _selectedFiles[index];
          final fileName = filePath.split('/').last;
          
          return ListTile(
            dense: true,
            leading: Icon(Icons.insert_drive_file),
            title: Text(fileName, style: TextStyle(fontSize: 14)),
            subtitle: Text(filePath, style: TextStyle(fontSize: 12, color: Colors.grey)),
            trailing: IconButton(
              icon: Icon(Icons.remove_circle),
              onPressed: () => _removeFile(index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQRCode() {
    if (_selectedShareId == null) return Container();
    
    return FutureBuilder<String>(
      future: _networkProvider.generateQRCode(_selectedShareId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error generating QR code');
        }
        
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        
        return Column(
          children: [
            QrImageView(
              data: snapshot.data!,
              version: QrVersions.auto,
              size: 200.0,
            ),
            SizedBox(height: 16),
            Text(
              'Scan to download files',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            SelectableText(
              snapshot.data!,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDevicesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Device Discovery Controls
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.devices),
                  SizedBox(width: 8),
                  Text('Device Discovery', style: Theme.of(context).textTheme.titleMedium),
                  Spacer(),
                  ElevatedButton.icon(
                    onPressed: _networkProvider.isDiscovering ? _stopDiscovery : _startDiscovery,
                    icon: Icon(_networkProvider.isDiscovering ? Icons.stop : Icons.search),
                    label: Text(_networkProvider.isDiscovering ? 'Stop' : 'Start'),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Discovered Devices
          Expanded(
            child: Card(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Discovered Devices (${_networkProvider.discoveredDevices.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Divider(),
                  Expanded(child: _buildDevicesList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesList() {
    return Consumer<EnhancedNetworkProvider>(
      builder: (context, provider, child) {
        if (provider.isDiscovering) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (provider.discoveredDevices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.devices_other, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No devices discovered'),
                SizedBox(height: 8),
                Text('Start device discovery to find nearby devices'),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: provider.discoveredDevices.length,
          itemBuilder: (context, index) {
            final device = provider.discoveredDevices[index];
            return ListTile(
              leading: CircleAvatar(
                child: Icon(_getDeviceIcon(device.type)),
              ),
              title: Text(device.name),
              subtitle: Text(device.ipAddress),
              trailing: device.isOnline 
                ? Icon(Icons.circle, color: Colors.green, size: 12)
                : Icon(Icons.circle, color: Colors.grey, size: 12),
              onTap: () => _connectToDevice(device),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Hotspot Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hotspot Settings', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 16),
                    TextField(
                      controller: _ssidController,
                      decoration: InputDecoration(
                        labelText: 'Hotspot SSID',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.wifi),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _toggleHotspot,
                            icon: Icon(_networkProvider.isHotspotEnabled ? Icons.wifi_off : Icons.wifi),
                            label: Text(_networkProvider.isHotspotEnabled ? 'Disable' : 'Enable'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Server Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Server Settings', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 16),
                    TextField(
                      controller: _portController,
                      decoration: InputDecoration(
                        labelText: 'Port',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.settings),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    SwitchListTile(
                      title: Text('Auto-discovery'),
                      subtitle: Text('Automatically discover nearby devices'),
                      value: _config.getParameter<bool>('network_auto_discovery') ?? true,
                      onChanged: (value) => _updateConfig('network_auto_discovery', value),
                    ),
                    SwitchListTile(
                      title: Text('Enable QR Codes'),
                      subtitle: Text('Generate QR codes for easy sharing'),
                      value: _config.getParameter<bool>('enable_qr_codes') ?? true,
                      onChanged: (value) => _updateConfig('enable_qr_codes', value),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // File Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('File Settings', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 16),
                    ListTile(
                      title: Text('Max File Size'),
                      subtitle: Text('${(_config.getParameter<int>('max_file_size') ?? (100 * 1024 * 1024)) / (1024 * 1024)} MB'),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: _showMaxFileSizeDialog,
                    ),
                    ListTile(
                      title: Text('Allowed File Types'),
                      subtitle: Text('Configure allowed file extensions'),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: _showAllowedTypesDialog,
                    ),
                    SwitchListTile(
                      title: Text('Enable Encryption'),
                      subtitle: Text('Encrypt shared files'),
                      value: _config.getParameter<bool>('enable_encryption') ?? false,
                      onChanged: (value) => _updateConfig('enable_encryption', value),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Action Methods
  Future<void> _scanNetworks() async {
    setState(() => _isScanning = true);
    
    try {
      await _networkProvider.scanNetworks();
    } catch (e) {
      _showErrorDialog('Scan Failed', 'Failed to scan networks: $e');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _connectToNetwork(dynamic network) async {
    try {
      // In a real implementation, this would connect to the network
      _showSuccessDialog('Connection Successful', 'Connected to ${network.ssid}');
    } catch (e) {
      _showErrorDialog('Connection Failed', 'Failed to connect: $e');
    }
  }

  Future<void> _toggleSharing(bool value) async {
    if (value) {
      try {
        final port = int.tryParse(_portController.text) ?? 8080;
        await _networkProvider.startSharingServer(port: port);
      } catch (e) {
        _showErrorDialog('Failed to Start Sharing', 'Could not start sharing server: $e');
      }
    } else {
      await _networkProvider.stopSharingServer();
    }
  }

  Future<void> _selectFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      
      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.files.map((file) => file.path ?? '').where((path) => path.isNotEmpty));
        });
        
        // Share selected files
        for (final filePath in _selectedFiles) {
          final shareId = await _networkProvider.shareFile(filePath);
          if (_selectedShareId == null) {
            _selectedShareId = shareId;
          }
        }
      }
    } catch (e) {
      _showErrorDialog('File Selection Failed', 'Could not select files: $e');
    }
  }

  Future<void> _selectFolder() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      
      if (result != null) {
        setState(() {
          _selectedFiles.add(result);
        });
        
        // Share selected folder
        final shareId = await _networkProvider.shareFile(result);
        if (_selectedShareId == null) {
          _selectedShareId = shareId;
        }
      }
    } catch (e) {
      _showErrorDialog('Folder Selection Failed', 'Could not select folder: $e');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _startDiscovery() async {
    try {
      await _networkProvider.startDeviceDiscovery();
    } catch (e) {
      _showErrorDialog('Discovery Failed', 'Could not start device discovery: $e');
    }
  }

  Future<void> _stopDiscovery() async {
    await _networkProvider.stopDeviceDiscovery();
  }

  Future<void> _connectToDevice(DiscoveredDeviceModel device) async {
    try {
      // In a real implementation, this would connect to the device
      _showSuccessDialog('Connected', 'Connected to ${device.name}');
    } catch (e) {
      _showErrorDialog('Connection Failed', 'Could not connect to device: $e');
    }
  }

  Future<void> _toggleHotspot() async {
    try {
      if (_networkProvider.isHotspotEnabled) {
        await _networkProvider.disableHotspot();
      } else {
        await _networkProvider.enableHotspot(
          ssid: _ssidController.text,
          password: _passwordController.text,
        );
      }
    } catch (e) {
      _showErrorDialog('Hotspot Error', 'Could not toggle hotspot: $e');
    }
  }

  Future<void> _updateConfig(String key, dynamic value) async {
    await _config.setParameter(key, value);
    setState(() {});
  }

  Future<void> _showMaxFileSizeDialog() async {
    // Implementation for max file size dialog
    _showInfoDialog('Max File Size', 'Current max file size: ${(_config.getParameter<int>('max_file_size') ?? (100 * 1024 * 1024)) / (1024 * 1024)} MB');
  }

  Future<void> _showAllowedTypesDialog() async {
    // Implementation for allowed types dialog
    final types = _config.getParameter<List<String>>('allowed_file_types') ?? ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png'];
    _showInfoDialog('Allowed File Types', types.join(', '));
  }

  Future<void> _refreshAll() async {
    await _scanNetworks();
    if (_networkProvider.isDiscovering) {
      await _stopDiscovery();
      await _startDiscovery();
    }
  }

  // Utility Methods
  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.mobile:
        return Icons.smartphone;
      case DeviceType.desktop:
        return Icons.computer;
      case DeviceType.tablet:
        return Icons.tablet;
      case DeviceType.server:
        return Icons.dns;
      default:
        return Icons.devices_other;
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scanAnimationController.dispose();
    _shareAnimationController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    _portController.dispose();
    super.dispose();
  }
}
