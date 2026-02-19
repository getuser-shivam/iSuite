import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/file_sharing_provider.dart';
import '../../domain/models/file_sharing_model.dart';
import '../../domain/models/network_model.dart';
import '../../core/utils.dart';
import '../../core/constants.dart';

class FileSharingScreen extends StatefulWidget {
  const FileSharingScreen({super.key});

  @override
  State<FileSharingScreen> createState() => _FileSharingScreenState();
}

class _FileSharingScreenState extends State<FileSharingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '21');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _remotePathController = TextEditingController();
  final _localPathController = TextEditingController();

  FileSharingProtocol _selectedProtocol = FileSharingProtocol.ftp;
  bool _isSecure = false;

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _remotePathController.dispose();
    _localPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Sharing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Connection',
            onPressed: _showAddConnectionDialog,
          ),
        ],
      ),
      body: Consumer<FileSharingProvider>(
        builder: (context, provider, child) {
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${provider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.clearError,
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Refresh connections if needed
            },
            child: ListView(
              padding: EdgeInsets.all(AppConstants.defaultPadding),
              children: [
                // Active Transfers Section
                if (provider.activeTransfers.isNotEmpty) ...[
                  _buildActiveTransfersSection(provider),
                  const SizedBox(height: 24),
                ],

                // Connections Section
                Text(
                  'Connections (${provider.connections.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                if (provider.connections.isEmpty) ...[
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No connections configured'),
                        SizedBox(height: 8),
                        Text('Tap the + button to add a connection'),
                      ],
                    ),
                  ),
                ] else ...[
                  ...provider.connections.map((connection) =>
                    _buildConnectionCard(context, connection, provider)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveTransfersSection(FileSharingProvider provider) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_upload, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Active Transfers (${provider.totalActiveTransfers})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...provider.activeTransfers.take(3).map((transfer) =>
              _buildTransferItem(transfer, provider)),
            if (provider.activeTransfers.length > 3) ...[
              const SizedBox(height: 8),
              Text(
                '+${provider.activeTransfers.length - 3} more transfers',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransferItem(FileTransferModel transfer, FileSharingProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            transfer.type == TransferType.upload ? Icons.upload : Icons.download,
            size: 20,
            color: transfer.isCompleted ? Colors.green : Colors.blue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transfer.fileName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${transfer.progressText} • ${transfer.speedText}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!transfer.isCompleted && !transfer.isFailed) ...[
            SizedBox(
              width: 80,
              child: LinearProgressIndicator(
                value: transfer.progress,
                backgroundColor: Colors.grey.shade300,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.cancel, size: 20),
              onPressed: () => provider.cancelTransfer(transfer.id),
              tooltip: 'Cancel Transfer',
            ),
          ] else if (transfer.isFailed) ...[
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => _retryTransfer(transfer, provider),
              tooltip: 'Retry',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionCard(BuildContext context, FileSharingModel connection, FileSharingProvider provider) {
    final isActive = connection.isActive;
    final hasActiveTransfers = connection.activeTransfers.isNotEmpty;

    return Semantics(
      label: 'Connection: ${connection.name}',
      hint: 'Status: ${isActive ? 'Active' : 'Inactive'}. Protocol: ${connection.protocolText}. Tap to manage.',
      child: Card(
        margin: EdgeInsets.only(bottom: AppConstants.defaultPadding / 2),
        color: isActive ? Colors.green.shade50 : null,
        child: InkWell(
          onTap: () => _showConnectionDetails(context, connection, provider),
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          child: Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getProtocolIcon(connection.protocol),
                      color: isActive ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            connection.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isActive ? Colors.green : null,
                            ),
                          ),
                          Text(
                            '${connection.protocolText} • ${connection.fullAddress}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (action) => _handleConnectionAction(action, connection, provider),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'connect',
                          child: Row(
                            children: [
                              Icon(isActive ? Icons.link_off : Icons.link),
                              const SizedBox(width: 8),
                              Text(isActive ? 'Disconnect' : 'Connect'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'upload',
                          child: Row(
                            children: [
                              Icon(Icons.upload_file),
                              SizedBox(width: 8),
                              Text('Upload File'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'download',
                          child: Row(
                            children: [
                              Icon(Icons.download),
                              SizedBox(width: 8),
                              Text('Download File'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (hasActiveTransfers) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${connection.totalTransfers} active transfers',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getProtocolIcon(FileSharingProtocol protocol) {
    switch (protocol) {
      case FileSharingProtocol.ftp:
        return Icons.cloud_upload;
      case FileSharingProtocol.sftp:
        return Icons.security;
      case FileSharingProtocol.http:
        return Icons.http;
      case FileSharingProtocol.https:
        return Icons.https;
      case FileSharingProtocol.smb:
        return Icons.folder_shared;
      case FileSharingProtocol.webdav:
        return Icons.web;
      case FileSharingProtocol.bluetooth:
        return Icons.bluetooth;
      case FileSharingProtocol.wifiDirect:
        return Icons.wifi_tethering;
    }
  }

  void _handleConnectionAction(String action, FileSharingModel connection, FileSharingProvider provider) {
    switch (action) {
      case 'connect':
        if (connection.isActive) {
          // Disconnect logic would go here
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Disconnecting from ${connection.name}')),
          );
        } else {
          // Connect logic
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connecting to ${connection.name}')),
          );
        }
        break;
      case 'upload':
        _pickFileForUpload(connection, provider);
        break;
      case 'download':
        _showDownloadDialog(connection, provider);
        break;
      case 'edit':
        _showEditConnectionDialog(connection);
        break;
      case 'delete':
        _showDeleteConnectionDialog(connection, provider);
        break;
    }
  }

  void _showAddConnectionDialog() {
    // Reset form
    _nameController.clear();
    _hostController.clear();
    _portController.text = '21';
    _usernameController.clear();
    _passwordController.clear();
    _remotePathController.clear();
    _localPathController.clear();
    _selectedProtocol = FileSharingProtocol.ftp;
    _isSecure = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Connection'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Connection Name'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                DropdownButtonFormField<FileSharingProtocol>(
                  value: _selectedProtocol,
                  decoration: const InputDecoration(labelText: 'Protocol'),
                  items: FileSharingProtocol.values.map((protocol) {
                    return DropdownMenuItem(
                      value: protocol,
                      child: Text(protocol.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedProtocol = value!),
                ),
                TextFormField(
                  controller: _hostController,
                  decoration: const InputDecoration(labelText: 'Host'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: _portController,
                  decoration: const InputDecoration(labelText: 'Port'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                TextFormField(
                  controller: _remotePathController,
                  decoration: const InputDecoration(labelText: 'Remote Path (optional)'),
                ),
                TextFormField(
                  controller: _localPathController,
                  decoration: const InputDecoration(labelText: 'Local Path (optional)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                final connection = FileSharingModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: _nameController.text,
                  protocol: _selectedProtocol,
                  host: _hostController.text,
                  port: int.tryParse(_portController.text) ?? 21,
                  username: _usernameController.text,
                  password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
                  remotePath: _remotePathController.text.isNotEmpty ? _remotePathController.text : null,
                  localPath: _localPathController.text.isNotEmpty ? _localPathController.text : null,
                  isSecure: _isSecure,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                await context.read<FileSharingProvider>().addConnection(connection);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showConnectionDetails(BuildContext context, FileSharingModel connection, FileSharingProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${connection.name} Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', connection.name),
              _buildDetailRow('Protocol', connection.protocolText),
              _buildDetailRow('Host', connection.host),
              _buildDetailRow('Port', connection.port.toString()),
              _buildDetailRow('Username', connection.username),
              _buildDetailRow('Remote Path', connection.remotePath ?? 'N/A'),
              _buildDetailRow('Local Path', connection.localPath ?? 'N/A'),
              _buildDetailRow('Status', connection.isActive ? 'Active' : 'Inactive'),
              _buildDetailRow('Secure', connection.isSecure ? 'Yes' : 'No'),
              if (connection.lastConnected != null)
                _buildDetailRow('Last Connected', connection.lastConnected!.toString()),
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

  void _pickFileForUpload(FileSharingModel connection, FileSharingProvider provider) async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      await provider.uploadFile(connection, filePath);
    }
  }

  void _showDownloadDialog(FileSharingModel connection, FileSharingProvider provider) {
    final remoteFileController = TextEditingController();
    final localPathController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download File'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: remoteFileController,
              decoration: const InputDecoration(labelText: 'Remote File Path'),
            ),
            TextFormField(
              controller: localPathController,
              decoration: const InputDecoration(labelText: 'Local Save Path'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (remoteFileController.text.isNotEmpty && localPathController.text.isNotEmpty) {
                await provider.downloadFile(connection, remoteFileController.text, localPathController.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _showEditConnectionDialog(FileSharingModel connection) {
    // Similar to add dialog but pre-filled
    // Implementation would be similar to _showAddConnectionDialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon')),
    );
  }

  void _showDeleteConnectionDialog(FileSharingModel connection, FileSharingProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Connection'),
        content: Text('Delete ${connection.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.removeConnection(connection.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${connection.name} deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _retryTransfer(FileTransferModel transfer, FileSharingProvider provider) {
    // Retry logic would depend on the original operation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Retry functionality coming soon')),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
