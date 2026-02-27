import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/local_sharing_provider.dart';
import '../../domain/models/p2p_device.dart';
import '../../domain/models/transfer_progress.dart';

class LocalSharingScreen extends ConsumerStatefulWidget {
  const LocalSharingScreen({super.key});

  @override
  ConsumerState<LocalSharingScreen> createState() => _LocalSharingScreenState();
}

class _LocalSharingScreenState extends ConsumerState<LocalSharingScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localSharingProvider);
    final notifier = ref.read(localSharingProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Sharing'),
        actions: [
          if (state.isDiscovering)
            const CircularProgressIndicator()
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => notifier.startDiscovery(),
              tooltip: 'Discover Devices',
            ),
          if (state.isDiscovering)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () => notifier.stopDiscovery(),
              tooltip: 'Stop Discovery',
            ),
        ],
      ),
      body: Column(
        children: [
          // Status section
          if (state.errorMessage != null)
            Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => notifier.clearError(),
                  ),
                ],
              ),
            ),

          // Connected device info
          if (state.isConnected && state.connectedDevice != null)
            Container(
              color: Colors.green.shade100,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.wifi, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Connected to ${state.connectedDevice!.deviceName}',
                    style: const TextStyle(color: Colors.green),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => notifier.disconnect(),
                    child: const Text('Disconnect'),
                  ),
                ],
              ),
            ),

          // Discovered devices list
          Expanded(
            child: state.discoveredDevices.isEmpty
                ? const Center(
                    child: Text('No devices discovered. Tap search to find devices.'),
                  )
                : ListView.builder(
                    itemCount: state.discoveredDevices.length,
                    itemBuilder: (context, index) {
                      final device = state.discoveredDevices[index];
                      return ListTile(
                        leading: const Icon(Icons.devices),
                        title: Text(device.deviceName),
                        subtitle: Text(device.deviceAddress),
                        trailing: device.isConnected
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : ElevatedButton(
                                onPressed: () => notifier.connectToDevice(device),
                                child: const Text('Connect'),
                              ),
                      );
                    },
                  ),
          ),

          // Transfer progress
          if (state.currentTransfer != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transferring: ${state.currentTransfer!.fileName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: state.currentTransfer!.progress,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(state.currentTransfer!.percentage).toStringAsFixed(1)}% - '
                    '${_formatBytes(state.currentTransfer!.bytesTransferred)} / '
                    '${_formatBytes(state.currentTransfer!.fileSize)}',
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFilePicker(context, notifier),
        tooltip: 'Send File',
        child: const Icon(Icons.send),
      ),
    );
  }

  void _showFilePicker(BuildContext context, LocalSharingNotifier notifier) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.single.path;
        if (filePath != null) {
          await notifier.sendFile(filePath);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('File selected: ${result.files.single.name}')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
