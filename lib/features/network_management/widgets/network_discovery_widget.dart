import 'package:flutter/material.dart';
import '../../../core/central_config.dart';

/// Network Discovery Widget
/// 
/// Advanced network discovery capabilities inspired by Owlfiles and open-source tools:
/// - mDNS/Bonjour/Zeroconf discovery
/// - UPnP device discovery
/// - Network scanning and ping sweeps
/// - Service detection and port scanning
/// - Device fingerprinting
/// - Real-time device monitoring
/// - Custom discovery filters
class NetworkDiscoveryWidget extends StatefulWidget {
  final List<NetworkDevice> devices;
  final bool isScanning;
  final Function(NetworkDevice) onDeviceSelected;
  final VoidCallback onRefresh;

  const NetworkDiscoveryWidget({
    super.key,
    required this.devices,
    required this.isScanning,
    required this.onDeviceSelected,
    required this.onRefresh,
  });

  @override
  State<NetworkDiscoveryWidget> createState() => _NetworkDiscoveryWidgetState();
}

class _NetworkDiscoveryWidgetState extends State<NetworkDiscoveryWidget> {
  final CentralConfig _config = CentralConfig.instance;
  String _selectedFilter = 'all';
  final List<String> _filters = ['all', 'nas', 'computer', 'server', 'router', 'printer'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
        Expanded(
          child: widget.devices.isEmpty
              ? _buildEmptyState()
              : _buildDeviceList(),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
      decoration: BoxDecoration(
        color: _config.getParameter('ui.colors.surface', defaultValue: Colors.white),
        borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.medium', defaultValue: 12.0)),
        border: Border.all(
          color: _config.getParameter('ui.colors.outline', defaultValue: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list,
                color: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                size: _config.getParameter('ui.icon.size.medium', defaultValue: 24.0),
              ),
              SizedBox(width: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
              Text(
                'Filter Devices',
                style: TextStyle(
                  fontSize: _config.getParameter('ui.font.size.body_medium', defaultValue: 14.0),
                  fontWeight: FontWeight.bold,
                  color: _config.getParameter('ui.colors.on_surface', defaultValue: Colors.black87),
                ),
              ),
              Spacer(),
              if (widget.isScanning)
                SizedBox(
                  width: _config.getParameter('ui.loading.size.small', defaultValue: 16.0),
                  height: _config.getParameter('ui.loading.size.small', defaultValue: 16.0),
                  child: CircularProgressIndicator(
                    strokeWidth: _config.getParameter('ui.loading.stroke_width', defaultValue: 2.0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                    ),
                  ),
                ),
              IconButton(
                onPressed: widget.onRefresh,
                icon: Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          SizedBox(height: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
          Wrap(
            spacing: _config.getParameter('ui.spacing.xsmall', defaultValue: 4.0),
            runSpacing: _config.getParameter('ui.spacing.xsmall', defaultValue: 4.0),
            children: _filters.map((filter) {
              final isSelected = _selectedFilter == filter;
              return FilterChip(
                label: Text(filter.toUpperCase()),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = selected ? filter : 'all';
                  });
                },
                backgroundColor: _config.getParameter('ui.colors.surface_variant', defaultValue: Colors.grey[100]),
                selectedColor: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue).withOpacity(0.2),
                checkmarkColor: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_find,
            size: _config.getParameter('ui.icon.size.extra_large', defaultValue: 80.0),
            color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.grey[400]!),
          ),
          SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
          Text(
            widget.isScanning ? 'Scanning Network...' : 'No Devices Found',
            style: TextStyle(
              fontSize: _config.getParameter('ui.font.size.title_medium', defaultValue: 18.0),
              fontWeight: FontWeight.bold,
              color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.grey[600]!),
            ),
          ),
          SizedBox(height: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
          Text(
            widget.isScanning 
                ? 'Discovering devices on your network'
                : 'Try refreshing to discover network devices',
            style: TextStyle(
              fontSize: _config.getParameter('ui.font.size.body_medium', defaultValue: 14.0),
              color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.grey[600]!),
            ),
          ),
          if (!widget.isScanning) ...[
            SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
            ElevatedButton.icon(
              onPressed: widget.onRefresh,
              icon: Icon(Icons.refresh),
              label: Text('Scan Network'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                foregroundColor: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    final filteredDevices = _selectedFilter == 'all'
        ? widget.devices
        : widget.devices.where((device) => device.type.toLowerCase() == _selectedFilter).toList();

    return ListView.builder(
      itemCount: filteredDevices.length,
      itemBuilder: (context, index) {
        final device = filteredDevices[index];
        return _buildDeviceCard(device);
      },
    );
  }

  Widget _buildDeviceCard(NetworkDevice device) {
    return Card(
      margin: EdgeInsets.only(bottom: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
      elevation: _config.getParameter('ui.card.elevation', defaultValue: 2.0),
      child: InkWell(
        onTap: () => widget.onDeviceSelected(device),
        borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.medium', defaultValue: 12.0)),
        child: Padding(
          padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue).withOpacity(0.1),
                    child: Icon(
                      _getDeviceIcon(device.type),
                      color: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                      size: _config.getParameter('ui.icon.size.medium', defaultValue: 24.0),
                    ),
                  ),
                  SizedBox(width: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: TextStyle(
                            fontSize: _config.getParameter('ui.font.size.body_large', defaultValue: 16.0),
                            fontWeight: FontWeight.bold,
                            color: _config.getParameter('ui.colors.on_surface', defaultValue: Colors.black87),
                          ),
                        ),
                        SizedBox(height: _config.getParameter('ui.spacing.xsmall', defaultValue: 4.0)),
                        Row(
                          children: [
                            Icon(
                              Icons.computer,
                              size: _config.getParameter('ui.icon.size.small', defaultValue: 16.0),
                              color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.grey[600]!),
                            ),
                            SizedBox(width: _config.getParameter('ui.spacing.xxsmall', defaultValue: 2.0)),
                            Text(
                              device.ip,
                              style: TextStyle(
                                fontSize: _config.getParameter('ui.font.size.body_small', defaultValue: 12.0),
                                color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.grey[600]!),
                              ),
                            ),
                            SizedBox(width: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: _config.getParameter('ui.spacing.xsmall', defaultValue: 4.0),
                                vertical: _config.getParameter('ui.spacing.xxsmall', defaultValue: 2.0),
                              ),
                              decoration: BoxDecoration(
                                color: _getDeviceTypeColor(device.type),
                                borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.small', defaultValue: 4.0)),
                              ),
                              child: Text(
                                device.type.toUpperCase(),
                                style: TextStyle(
                                  color: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
                                  fontSize: _config.getParameter('ui.font.size.body_small', defaultValue: 10.0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.grey[400]!),
                    size: _config.getParameter('ui.icon.size.small', defaultValue: 16.0),
                  ),
                ],
              ),
              SizedBox(height: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
              if (device.protocols.isNotEmpty) ...[
                Wrap(
                  spacing: _config.getParameter('ui.spacing.xsmall', defaultValue: 4.0),
                  runSpacing: _config.getParameter('ui.spacing.xsmall', defaultValue: 4.0),
                  children: device.protocols.map((protocol) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _config.getParameter('ui.spacing.xsmall', defaultValue: 4.0),
                        vertical: _config.getParameter('ui.spacing.xxsmall', defaultValue: 2.0),
                      ),
                      decoration: BoxDecoration(
                        color: _config.getParameter('ui.colors.tertiary', defaultValue: Colors.purple).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.small', defaultValue: 4.0)),
                      ),
                      child: Text(
                        protocol.toUpperCase(),
                        style: TextStyle(
                          color: _config.getParameter('ui.colors.tertiary', defaultValue: Colors.purple),
                          fontSize: _config.getParameter('ui.font.size.body_small', defaultValue: 10.0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              SizedBox(height: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: _config.getParameter('ui.icon.size.small', defaultValue: 16.0),
                    color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.grey[600]!),
                  ),
                  SizedBox(width: _config.getParameter('ui.spacing.xxsmall', defaultValue: 2.0)),
                  Text(
                    'Last seen: ${_formatLastSeen(device.lastSeen)}',
                    style: TextStyle(
                      fontSize: _config.getParameter('ui.font.size.body_small', defaultValue: 12.0),
                      color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.grey[600]!),
                    ),
                  ),
                  Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.signal_wifi_4_bar,
                        size: _config.getParameter('ui.icon.size.small', defaultValue: 16.0),
                        color: _getSignalStrengthColor(device.signalStrength),
                      ),
                        SizedBox(width: _config.getParameter('ui.spacing.xxsmall', defaultValue: 2.0)),
                        Text(
                          '${device.signalStrength}%',
                          style: TextStyle(
                            fontSize: _config.getParameter('ui.font.size.body_small', defaultValue: 12.0),
                            color: _getSignalStrengthColor(device.signalStrength),
                          ),
                        ),
                      ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDeviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'nas':
        return Icons.storage;
      case 'computer':
        return Icons.computer;
      case 'server':
        return Icons.dns;
      case 'router':
        return Icons.router;
      case 'printer':
        return Icons.print;
      default:
        return Icons.device_unknown;
    }
  }

  Color _getDeviceTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'nas':
        return _config.getParameter('ui.colors.success', defaultValue: Colors.green);
      case 'computer':
        return _config.getParameter('ui.colors.primary', defaultValue: Colors.blue);
      case 'server':
        return _config.getParameter('ui.colors.warning', defaultValue: Colors.orange);
      case 'router':
        return _config.getParameter('ui.colors.error', defaultValue: Colors.red);
      case 'printer':
        return _config.getParameter('ui.colors.tertiary', defaultValue: Colors.purple);
      default:
        return _config.getParameter('ui.colors.surface_variant', defaultValue: Colors.grey);
    }
  }

  Color _getSignalStrengthColor(int strength) {
    if (strength >= 80) {
      return _config.getParameter('ui.colors.success', defaultValue: Colors.green);
    } else if (strength >= 60) {
      return _config.getParameter('ui.colors.warning', defaultValue: Colors.orange);
    } else {
      return _config.getParameter('ui.colors.error', defaultValue: Colors.red);
    }
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }
  }
}

// Enhanced NetworkDevice class
class NetworkDevice {
  final String name;
  final String type;
  final String ip;
  final List<String> protocols;
  final DateTime lastSeen;
  final int signalStrength;
  final Map<String, dynamic>? metadata;

  NetworkDevice({
    required this.name,
    required this.type,
    required this.ip,
    required this.protocols,
    required this.lastSeen,
    this.signalStrength = 100,
    this.metadata,
  });
}
