import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

class WirelessSharingScreen extends ConsumerStatefulWidget {
  const WirelessSharingScreen({super.key});

  @override
  State<WirelessSharingScreen> createState() => _WirelessSharingScreenState();
}

class _WirelessSharingScreenState extends ConsumerState<WirelessSharingScreen> {
  final FlutterP2pConnection _flutterP2pConnectionPlugin = FlutterP2pConnection();
  List<DiscoveredPeers> _peers = [];
  WifiP2PInfo? _wifiP2PInfo;
  List<String> _selectedFiles = [];
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    _initializeP2P();
  }

  Future<void> _initializeP2P() async {
    await _flutterP2pConnectionPlugin.initialize();
    await _flutterP2pConnectionPlugin.register();

    _flutterP2pConnectionPlugin.streamWifiP2PInfo().listen((event) {
      setState(() {
        _wifiP2PInfo = event;
      });
    });

    _flutterP2pConnectionPlugin.streamPeers().listen((event) {
      setState(() {
        _peers = event;
      });
    });
  }

  Future<void> _discoverPeers() async {
    setState(() {
      _isDiscovering = true;
    });

    await _flutterP2pConnectionPlugin.discover();

    // Stop discovery after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      _flutterP2pConnectionPlugin.stopDiscovery();
      setState(() {
        _isDiscovering = false;
      });
    });
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        _selectedFiles = result.files.map((file) => file.path!).where((path) => path.isNotEmpty).toList();
      });
    }
  }

  Future<void> _sendFile(String peerAddress) async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No files selected')),
      );
      return;
    }

    for (final filePath in _selectedFiles) {
      try {
        await _flutterP2pConnectionPlugin.sendFile(filePath, peerAddress);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sending ${filePath.split('/').last}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wireless File Sharing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // P2P Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wi-Fi Direct Status: ${_wifiP2PInfo?.isConnected == true ? 'Connected' : 'Disconnected'}'),
                    if (_wifiP2PInfo?.groupOwnerAddress != null)
                      Text('Group Owner: ${_wifiP2PInfo!.groupOwnerAddress!}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Discover Devices
            ElevatedButton(
              onPressed: _isDiscovering ? null : _discoverPeers,
              child: Text(_isDiscovering ? 'Discovering...' : 'Discover Devices'),
            ),
            const SizedBox(height: 16),

            // Device List
            Expanded(
              child: _peers.isEmpty
                  ? const Center(child: Text('No devices found. Tap "Discover Devices" to search.'))
                  : ListView.builder(
                      itemCount: _peers.length,
                      itemBuilder: (context, index) {
                        final peer = _peers[index];
                        return Card(
                          child: ListTile(
                            title: Text(peer.deviceName ?? 'Unknown Device'),
                            subtitle: Text(peer.deviceAddress ?? ''),
                            trailing: ElevatedButton(
                              onPressed: () => _sendFile(peer.deviceAddress!),
                              child: const Text('Send Files'),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // File Selection
            ElevatedButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.attach_file),
              label: const Text('Select Files to Share'),
            ),
            const SizedBox(height: 8),
            Text('Selected files: ${_selectedFiles.length}'),
            if (_selectedFiles.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _selectedFiles.length,
                  itemBuilder: (context, index) {
                    return Text(_selectedFiles[index].split('/').last);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
