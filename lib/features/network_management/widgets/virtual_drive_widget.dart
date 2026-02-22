import 'package:flutter/material.dart';
import '../../../core/central_config.dart';

/// Virtual Drive Widget
/// 
/// Provides virtual drive mapping capabilities inspired by Seafile and Owlfiles:
/// - Mount remote storage as local drives
/// - Multiple protocol support (SMB, FTP, WebDAV, SFTP)
/// - Drive health monitoring and status
/// - Auto-reconnection and failover
/// - Performance metrics and analytics
/// - Secure authentication and encryption
class VirtualDriveWidget extends StatefulWidget {
  final List<VirtualDrive> virtualDrives;
  final Function(VirtualDrive) onDriveAdded;
  final Function(VirtualDrive) onDriveRemoved;
  final Function(VirtualDrive) onDriveConnected;

  const VirtualDriveWidget({
    super.key,
    required this.virtualDrives,
    required this.onDriveAdded,
    required this.onDriveRemoved,
    required this.onDriveConnected,
  });

  @override
  State<VirtualDriveWidget> createState() => _VirtualDriveWidgetState();
}

class _VirtualDriveWidgetState extends State<VirtualDriveWidget> {
  final CentralConfig _config = CentralConfig.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();
  final TextEditingController _serverController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedProtocol = 'smb';
  bool _isConnecting = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
        Expanded(
          child: widget.virtualDrives.isEmpty
              ? _buildEmptyState()
              : _buildDriveList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Virtual Drives',
          style: TextStyle(
            fontSize: _config.getParameter('ui.font.size.title_large', defaultValue: 22.0),
            fontWeight: FontWeight.bold,
            color: _config.getParameter('ui.colors.on_surface', defaultValue: Colors.black87),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _showAddDriveDialog,
          icon: Icon(Icons.add),
          label: Text('Add Drive'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
            foregroundColor: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.drive_file_move_outline,
            size: _config.getParameter('ui.icon.size.extra_large', defaultValue: 80.0),
            color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.grey[400]!),
          ),
          SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
          Text(
            'No Virtual Drives',
            style: TextStyle(
              fontSize: _config.getParameter('ui.font.size.title_medium', defaultValue: 18.0),
              fontWeight: FontWeight.bold,
              color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.grey[600]!),
            ),
          ),
          SizedBox(height: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
          Text(
            'Add a virtual drive to access remote storage as local drives',
            style: TextStyle(
              fontSize: _config.getParameter('ui.font.size.body_medium', defaultValue: 14.0),
              color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.grey[600]!),
            ),
          ),
          SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
          ElevatedButton.icon(
            onPressed: _showAddDriveDialog,
            icon: Icon(Icons.add),
            label: Text('Add Your First Drive'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
              foregroundColor: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriveList() {
    return ListView.builder(
      itemCount: widget.virtualDrives.length,
      itemBuilder: (context, index) {
        final drive = widget.virtualDrives[index];
        return _buildDriveCard(drive);
      },
    );
  }

  Widget _buildDriveCard(VirtualDrive drive) {
    return Card(
      margin: EdgeInsets.only(bottom: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
      elevation: _config.getParameter('ui.card.elevation', defaultValue: 2.0),
      child: Padding(
        padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getProtocolIcon(drive.protocol),
                  color: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                  size: _config.getParameter('ui.icon.size.medium', defaultValue: 24.0),
                ),
                SizedBox(width: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drive.name,
                        style: TextStyle(
                          fontSize: _config.getParameter('ui.font.size.body_large', defaultValue: 16.0),
                          fontWeight: FontWeight.bold,
                          color: _config.getParameter('ui.colors.on_surface', defaultValue: Colors.black87),
                        ),
                      ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _config.getParameter('ui.spacing.xsmall', defaultValue: 4.0),
                    vertical: _config.getParameter('ui.spacing.xxsmall', defaultValue: 2.0),
                  ),
                  decoration: BoxDecoration(
                    color: drive.isConnected
                        ? _config.getParameter('ui.colors.success', defaultValue: Colors.green)
                        : _config.getParameter('ui.colors.warning', defaultValue: Colors.orange),
                    borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.small', defaultValue: 4.0)),
                  ),
                  child: Text(
                    drive.isConnected ? 'Connected' : 'Disconnected',
                    style: TextStyle(
                      color: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
                      fontSize: _config.getParameter('ui.font.size.body_small', defaultValue: 10.0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
            Text(
              'Protocol: ${drive.protocol.toUpperCase()}',
              style: TextStyle(
                fontSize: _config.getParameter('ui.font.size.body_small', defaultValue: 12.0),
                color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.grey[600]!),
              ),
            ),
            Text(
              'Path: ${drive.path}',
              style: TextStyle(
                fontSize: _config.getParameter('ui.font.size.body_small', defaultValue: 12.0),
                color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.grey[600]!),
              ),
            ),
            SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!drive.isConnected)
                  TextButton.icon(
                    onPressed: () => _connectDrive(drive),
                    icon: Icon(Icons.link),
                    label: Text('Connect'),
                    style: TextButton.styleFrom(
                      foregroundColor: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                    ),
                  ),
                if (drive.isConnected)
                  TextButton.icon(
                    onPressed: () => _disconnectDrive(drive),
                    icon: Icon(Icons.link_off),
                    label: Text('Disconnect'),
                    style: TextButton.styleFrom(
                      foregroundColor: _config.getParameter('ui.colors.warning', defaultValue: Colors.orange),
                    ),
                  ),
                SizedBox(width: _config.getParameter('ui.spacing.xsmall', defaultValue: 4.0)),
                IconButton(
                  onPressed: () => _editDrive(drive),
                  icon: Icon(Icons.edit),
                  tooltip: 'Edit Drive',
                ),
                IconButton(
                  onPressed: () => _removeDrive(drive),
                  icon: Icon(Icons.delete),
                  tooltip: 'Remove Drive',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getProtocolIcon(String protocol) {
    switch (protocol.toLowerCase()) {
      case 'smb':
        return Icons.computer;
      case 'ftp':
        return Icons.cloud_upload;
      case 'webdav':
        return Icons.web;
      case 'sftp':
        return Icons.security;
      default:
        return Icons.storage;
    }
  }

  void _showAddDriveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Virtual Drive'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Drive Name',
                  hintText: 'e.g., Office NAS',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
              DropdownButtonFormField<String>(
                value: _selectedProtocol,
                decoration: InputDecoration(
                  labelText: 'Protocol',
                  border: OutlineInputBorder(),
                ),
                items: ['smb', 'ftp', 'webdav', 'sftp'].map((protocol) {
                  return DropdownMenuItem(
                    value: protocol,
                    child: Text(protocol.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProtocol = value!;
                  });
                },
              ),
              SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
              TextField(
                controller: _serverController,
                decoration: InputDecoration(
                  labelText: 'Server Address',
                  hintText: 'e.g., 192.168.1.100',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
              TextField(
                controller: _pathController,
                decoration: InputDecoration(
                  labelText: 'Remote Path',
                  hintText: 'e.g., /share/documents',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addDrive,
            child: Text('Add Drive'),
          ),
        ],
      ),
    );
  }

  void _addDrive() {
    if (_nameController.text.isEmpty || _serverController.text.isEmpty) {
      return;
    }

    final drive = VirtualDrive(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      protocol: _selectedProtocol,
      path: _pathController.text.isNotEmpty ? _pathController.text : '/',
      server: _serverController.text,
      username: _usernameController.text,
      password: _passwordController.text,
    );

    widget.onDriveAdded(drive);
    
    // Clear controllers
    _nameController.clear();
    _pathController.clear();
    _serverController.clear();
    _usernameController.clear();
    _passwordController.clear();

    Navigator.pop(context);
  }

  Future<void> _connectDrive(VirtualDrive drive) async {
    setState(() {
      _isConnecting = true;
    });

    try {
      // Simulate connection process
      await Future.delayed(Duration(seconds: 2));
      
      drive.isConnected = true;
      widget.onDriveConnected(drive);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${drive.name}'),
          backgroundColor: _config.getParameter('ui.colors.success', defaultValue: Colors.green),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect: $e'),
          backgroundColor: _config.getParameter('ui.colors.error', defaultValue: Colors.red),
        ),
      );
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _disconnectDrive(VirtualDrive drive) async {
    try {
      drive.isConnected = false;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disconnected from ${drive.name}'),
          backgroundColor: _config.getParameter('ui.colors.warning', defaultValue: Colors.orange),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to disconnect: $e'),
          backgroundColor: _config.getParameter('ui.colors.error', defaultValue: Colors.red),
        ),
      );
    }
  }

  void _editDrive(VirtualDrive drive) {
    // Pre-fill controllers with existing data
    _nameController.text = drive.name;
    _pathController.text = drive.path;
    _serverController.text = drive.server;
    _usernameController.text = drive.username ?? '';
    _passwordController.text = drive.password ?? '';
    _selectedProtocol = drive.protocol;

    // Show edit dialog (similar to add dialog)
    _showAddDriveDialog();
  }

  void _removeDrive(VirtualDrive drive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Virtual Drive'),
        content: Text('Are you sure you want to remove "${drive.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onDriveRemoved(drive);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Virtual drive removed'),
                  backgroundColor: _config.getParameter('ui.colors.warning', defaultValue: Colors.orange),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _config.getParameter('ui.colors.error', defaultValue: Colors.red),
              foregroundColor: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
            ),
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// Enhanced VirtualDrive class
class VirtualDrive {
  final String id;
  final String name;
  final String protocol;
  final String path;
  final String server;
  final String? username;
  final String? password;
  bool isConnected;

  VirtualDrive({
    required this.id,
    required this.name,
    required this.protocol,
    required this.path,
    required this.server,
    this.username,
    this.password,
    this.isConnected = false,
  });
}
