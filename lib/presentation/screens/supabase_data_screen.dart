import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/supabase_providers.dart';
import '../widgets/common/parameterized_app_bar.dart';

/// Supabase Data Management Screen
/// 
/// Screen for managing Supabase data operations
/// Features: Data CRUD, real-time updates, statistics
/// Performance: Optimized data operations, efficient state management
/// Architecture: Consumer widget, provider pattern, responsive design
class SupabaseDataManagementScreen extends ConsumerStatefulWidget {
  const SupabaseDataManagementScreen({super.key});

  @override
  ConsumerState<SupabaseDataManagementScreen> createState() => _SupabaseDataManagementScreenState();
}

class _SupabaseDataManagementScreenState extends ConsumerState<SupabaseDataManagementScreen> {
  String _currentView = 'files'; // files, devices, transfers, users
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dataProvider = ref.watch(supabaseDataProvider);
    
    return Scaffold(
      appBar: ParameterizedAppBar(
        title: 'Supabase Data Management',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => dataProvider.loadAllData(),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Column(
        children: [
          // View selector
          _buildViewSelector(context, l10n),
          
          // Content
          Expanded(
            child: _buildContent(context, l10n, dataProvider),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context, l10n, dataProvider),
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
          _buildViewChip('files', 'Files', Icons.folder),
          _buildViewChip('devices', 'Devices', Icons.devices),
          _buildViewChip('transfers', 'Transfers', Icons.swap_horiz),
          _buildViewChip('users', 'Users', Icons.people),
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

  Widget _buildContent(BuildContext context, AppLocalizations l10n, dataProvider) {
    if (dataProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dataProvider.dataError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${dataProvider.dataError}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => dataProvider.clearError(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    switch (_currentView) {
      case 'files':
        return _buildFilesView(context, l10n, dataProvider);
      case 'devices':
        return _buildDevicesView(context, l10n, dataProvider);
      case 'transfers':
        return _buildTransfersView(context, l10n, dataProvider);
      case 'users':
        return _buildUsersView(context, l10n, dataProvider);
      default:
        return _buildFilesView(context, l10n, dataProvider);
    }
  }

  Widget _buildFilesView(BuildContext context, AppLocalizations l10n, dataProvider) {
    return Column(
      children: [
        // Statistics
        _buildFilesStatistics(context, l10n, dataProvider),
        
        // Files list
        Expanded(
          child: dataProvider.files.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No files found'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showCreateFileDialog,
                        child: const Text('Create File'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: dataProvider.files.length,
                  itemBuilder: (context, index) {
                    final file = dataProvider.files[index];
                    return _buildFileItem(context, l10n, file, dataProvider);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilesStatistics(BuildContext context, AppLocalizations l10n, dataProvider) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem('Total Files', dataProvider.files.length.toString(), Icons.folder),
            ),
            Expanded(
              child: _buildStatItem('Active', dataProvider.files.where((f) => f['status'] == 'active').length.toString(), Icons.check_circle),
            ),
            Expanded(
              child: _buildStatItem('Size', _formatTotalSize(dataProvider.files), Icons.storage),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesView(BuildContext context, AppLocalizations l10n, dataProvider) {
    return Column(
      children: [
        // Statistics
        _buildDevicesStatistics(context, l10n, dataProvider),
        
        // Devices list
        Expanded(
          child: dataProvider.networkDevices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.devices, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No devices found'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showCreateDeviceDialog,
                        child: const Text('Add Device'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: dataProvider.networkDevices.length,
                  itemBuilder: (context, index) {
                    final device = dataProvider.networkDevices[index];
                    return _buildDeviceItem(context, l10n, device, dataProvider);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDevicesStatistics(BuildContext context, AppLocalizations l10n, dataProvider) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem('Total Devices', dataProvider.networkDevices.length.toString(), Icons.devices),
            ),
            Expanded(
              child: _buildStatItem('Online', dataProvider.networkDevices.where((d) => d['status'] == 'online').length.toString(), Icons.wifi),
            ),
            Expanded(
              child: _buildStatItem('Types', _getDeviceTypes(dataProvider.networkDevices).length.toString(), Icons.category),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransfersView(BuildContext context, AppLocalizations l10n, dataProvider) {
    return Column(
      children: [
        // Statistics
        _buildTransfersStatistics(context, l10n, dataProvider),
        
        // Transfers list
        Expanded(
          child: dataProvider.fileTransfers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No transfers found'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showCreateTransferDialog,
                        child: const Text('Create Transfer'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: dataProvider.fileTransfers.length,
                  itemBuilder: (context, index) {
                    final transfer = dataProvider.fileTransfers[index];
                    return _buildTransferItem(context, l10n, transfer, dataProvider);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTransfersStatistics(BuildContext context, AppLocalizations l10n, dataProvider) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem('Total Transfers', dataProvider.fileTransfers.length.toString(), Icons.swap_horiz),
            ),
            Expanded(
              child: _buildStatItem('Active', dataProvider.fileTransfers.where((t) => t['status'] == 'active').length.toString(), Icons.play_arrow),
            ),
            Expanded(
              child: _buildStatItem('Completed', dataProvider.fileTransfers.where((t) => t['status'] == 'completed').length.toString(), Icons.check_circle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersView(BuildContext context, AppLocalizations l10n, dataProvider) {
    return Column(
      children: [
        // Statistics
        _buildUsersStatistics(context, l10n, dataProvider),
        
        // Users list
        Expanded(
          child: dataProvider.users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No users found'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showCreateUserDialog,
                        child: const Text('Create User'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: dataProvider.users.length,
                  itemBuilder: (context, index) {
                    final user = dataProvider.users[index];
                    return _buildUserItem(context, l10n, user, dataProvider);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUsersStatistics(BuildContext context, AppLocalizations l10n, dataProvider) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem('Total Users', dataProvider.users.length.toString(), Icons.people),
            ),
            Expanded(
              child: _buildStatItem('Active', dataProvider.users.where((u) => u['status'] == 'active').length.toString(), Icons.check_circle),
            ),
            Expanded(
              child: _buildStatItem('New Today', _getUsersCreatedToday(dataProvider.users).length.toString(), Icons.today),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildFileItem(BuildContext context, AppLocalizations l10n, Map<String, dynamic> file, dataProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getFileColor(file['type']),
          child: Icon(
            _getFileIcon(file['type']),
            color: Colors.white,
          ),
        ),
        title: Text(file['name'] ?? 'Unknown File'),
        subtitle: Text('${file['type'] ?? 'Unknown'} • ${_formatFileSize(file['size'] ?? 0)}'),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleFileAction(action, file, dataProvider),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceItem(BuildContext context, AppLocalizations l10n, Map<String, dynamic> device, dataProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getDeviceColor(device['status']),
          child: Icon(
            _getDeviceIcon(device['connection_type']),
            color: Colors.white,
          ),
        ),
        title: Text(device['name'] ?? 'Unknown Device'),
        subtitle: Text('${device['connection_type'] ?? 'Unknown'} • ${device['address'] ?? 'No address'}'),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleDeviceAction(action, device, dataProvider),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'connect', child: Text('Connect')),
            const PopupMenuItem(value: 'disconnect', child: Text('Disconnect')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferItem(BuildContext context, AppLocalizations l10n, Map<String, dynamic> transfer, dataProvider) {
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
        title: Text(transfer['file_name'] ?? 'Unknown File'),
        subtitle: Text('${transfer['device_name'] ?? 'Unknown Device'} • $status'),
        trailing: Text('${(progress * 100).toInt()}%'),
      ),
    );
  }

  Widget _buildUserItem(BuildContext context, AppLocalizations l10n, Map<String, dynamic> user, dataProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            (user['email'] as String? ?? 'U').substring(0, 2).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(user['email'] ?? 'Unknown User'),
        subtitle: Text('ID: ${user['id'] ?? 'Unknown'}'),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleUserAction(action, user, dataProvider),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, AppLocalizations l10n, dataProvider) {
    switch (_currentView) {
      case 'files':
        return FloatingActionButton.extended(
          onPressed: _showCreateFileDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add File'),
        );
      case 'devices':
        return FloatingActionButton.extended(
          onPressed: _showCreateDeviceDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Device'),
        );
      case 'transfers':
        return FloatingActionButton.extended(
          onPressed: _showCreateTransferDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Transfer'),
        );
      case 'users':
        return FloatingActionButton.extended(
          onPressed: _showCreateUserDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add User'),
        );
      default:
        return Container();
    }
  }

  // Action handlers
  void _handleFileAction(String action, Map<String, dynamic> file, dataProvider) {
    switch (action) {
      case 'view':
        _showFileDetails(file);
        break;
      case 'edit':
        _showEditFileDialog(file);
        break;
      case 'delete':
        _deleteFile(file, dataProvider);
        break;
    }
  }

  void _handleDeviceAction(String action, Map<String, dynamic> device, dataProvider) {
    switch (action) {
      case 'connect':
        _connectDevice(device, dataProvider);
        break;
      case 'disconnect':
        _disconnectDevice(device, dataProvider);
        break;
      case 'edit':
        _showEditDeviceDialog(device);
        break;
      case 'delete':
        _deleteDevice(device, dataProvider);
        break;
    }
  }

  void _handleTransferAction(String action, Map<String, dynamic> transfer, dataProvider) {
    switch (action) {
      case 'view':
        _showTransferDetails(transfer);
        break;
      case 'cancel':
        _cancelTransfer(transfer, dataProvider);
        break;
      case 'retry':
        _retryTransfer(transfer, dataProvider);
        break;
    }
  }

  void _handleUserAction(String action, Map<String, dynamic> user, dataProvider) {
    switch (action) {
      case 'view':
        _showUserDetails(user);
        break;
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'delete':
        _deleteUser(user, dataProvider);
        break;
    }
  }

  // Dialog methods
  void _showCreateFileDialog() {
    // Show create file dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create file dialog coming soon')),
    );
  }

  void _showCreateDeviceDialog() {
    // Show create device dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create device dialog coming soon')),
    );
  }

  void _showCreateTransferDialog() {
    // Show create transfer dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create transfer dialog coming soon')),
    );
  }

  void _showCreateUserDialog() {
    // Show create user dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create user dialog coming soon')),
    );
  }

  void _showFileDetails(Map<String, dynamic> file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${file['name'] ?? 'Unknown'}'),
            Text('Type: ${file['type'] ?? 'Unknown'}'),
            Text('Size: ${_formatFileSize(file['size'] ?? 0)}'),
            Text('Status: ${file['status'] ?? 'Unknown'}'),
            Text('Created: ${file['created_at'] ?? 'Unknown'}'),
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

  void _showEditFileDialog(Map<String, dynamic> file) {
    // Show edit file dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit file dialog coming soon')),
    );
  }

  void _showEditDeviceDialog(Map<String, dynamic> device) {
    // Show edit device dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit device dialog coming soon')),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    // Show edit user dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit user dialog coming soon')),
    );
  }

  // Action methods
  void _deleteFile(Map<String, dynamic> file, dataProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete ${file['name'] ?? 'this file'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              dataProvider.deleteFile(file['id']);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteDevice(Map<String, dynamic> device, dataProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: Text('Are you sure you want to delete ${device['name'] ?? 'this device'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              dataProvider.deleteNetworkDevice(device['id']);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteUser(Map<String, dynamic> user, dataProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user['email'] ?? 'this user'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // User deletion would be handled differently
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User deletion not implemented yet')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _connectDevice(Map<String, dynamic> device, dataProvider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connecting to ${device['name'] ?? 'device'}')),
    );
  }

  void _disconnectDevice(Map<String, dynamic> device, dataProvider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Disconnecting from ${device['name'] ?? 'device'}')),
    );
  }

  void _showTransferDetails(Map<String, dynamic> transfer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: ${transfer['file_name'] ?? 'Unknown'}'),
            Text('Device: ${transfer['device_name'] ?? 'Unknown'}'),
            Text('Status: ${transfer['status'] ?? 'Unknown'}'),
            Text('Progress: ${((transfer['progress'] ?? 0.0) * 100).toInt()}%'),
            Text('Created: ${transfer['created_at'] ?? 'Unknown'}'),
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

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user['email'] ?? 'Unknown'}'),
            Text('ID: ${user['id'] ?? 'Unknown'}'),
            Text('Status: ${user['status'] ?? 'Unknown'}'),
            Text('Created: ${user['created_at'] ?? 'Unknown'}'),
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

  void _cancelTransfer(Map<String, dynamic> transfer, dataProvider) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cancel transfer not implemented yet')),
    );
  }

  void _retryTransfer(Map<String, dynamic> transfer, dataProvider) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Retry transfer not implemented yet')),
    );
  }

  // Helper methods
  Color _getFileColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'image':
        return Colors.blue;
      case 'document':
        return Colors.green;
      case 'video':
        return Colors.red;
      case 'audio':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getFileIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'image':
        return Icons.image;
      case 'document':
        return Icons.description;
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.audiotrack;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getDeviceColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'online':
        return Colors.green;
      case 'offline':
        return Colors.red;
      case 'connecting':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getDeviceIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'bluetooth':
        return Icons.bluetooth;
      case 'usb':
        return Icons.usb;
      case 'network':
        return Icons.network_check;
      default:
        return Icons.device_unknown;
    }
  }

  Color _getTransferColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'paused':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTransferIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.play_arrow;
      case 'completed':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      case 'paused':
        return Icons.pause;
      default:
        return Icons.help;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatTotalSize(List<Map<String, dynamic>> files) {
    int totalSize = 0;
    for (final file in files) {
      totalSize += (file['size'] ?? 0) as int;
    }
    return _formatFileSize(totalSize);
  }

  Set<String> _getDeviceTypes(List<Map<String, dynamic>> devices) {
    return devices.map((d) => d['connection_type'] as String? ?? 'unknown').toSet();
  }

  List<Map<String, dynamic>> _getUsersCreatedToday(List<Map<String, dynamic>> users) {
    final today = DateTime.now();
    return users.where((user) {
      final createdAt = DateTime.tryParse(user['created_at'] as String? ?? '');
      return createdAt != null && 
             createdAt.day == today.day && 
             createdAt.month == today.month && 
             createdAt.year == today.year;
    }).toList();
  }
}
