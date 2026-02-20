import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../domain/models/network_model.dart';
import '../providers/network_provider.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  @override
  void initState() {
    super.initState();
    // Auto scan networks on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NetworkProvider>().scanNetworks();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Network Management'),
          actions: [
            Consumer<NetworkProvider>(
              builder: (context, provider, child) => IconButton(
                onPressed:
                    provider.isScanning ? null : provider.refreshNetworks,
                icon: provider.isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Scan Networks',
              ),
            ),
          ],
        ),
        body: Consumer<NetworkProvider>(
          builder: (context, provider, child) {
            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${provider.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        provider.clearError();
                        provider.scanNetworks();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: provider.scanNetworks,
              child: ListView(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                children: [
                  // Current Network Status
                  if (provider.currentNetwork != null) ...[
                    _buildCurrentNetworkSection(
                        provider.currentNetwork!, provider),
                    const SizedBox(height: 24),
                  ],

                  // Scan Button
                  ElevatedButton.icon(
                    onPressed:
                        provider.isScanning ? null : provider.scanNetworks,
                    icon: provider.isScanning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.wifi_find),
                    label: Text(
                        provider.isScanning ? 'Scanning...' : 'Scan Networks'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Available Networks
                  if (provider.availableNetworks.isNotEmpty) ...[
                    Text(
                      'Available Networks (${provider.availableNetworks.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...provider.availableNetworks.map((network) =>
                        _buildNetworkCard(context, network, provider)),
                  ] else if (!provider.isScanning) ...[
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No networks found'),
                        ],
                      ),
                    ),
                  ],

                  // Saved Networks
                  if (provider.savedNetworks.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Saved Networks (${provider.savedNetworks.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...provider.savedNetworks.map((network) =>
                        _buildNetworkCard(context, network, provider,
                            isSaved: true)),
                  ],
                ],
              ),
            );
          },
        ),
      );

  Widget _buildCurrentNetworkSection(
          NetworkModel currentNetwork, NetworkProvider provider) =>
      Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.wifi, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Connected to ${currentNetwork.ssid}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Signal Strength: ${currentNetwork.signalStrengthText}'),
              Text('Security: ${currentNetwork.securityText}'),
              Text('IP Address: ${currentNetwork.ipAddress ?? 'N/A'}'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: provider.isConnecting
                        ? null
                        : () => _showNetworkDetails(currentNetwork),
                    child: const Text('Details'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: provider.isConnecting
                        ? null
                        : provider.disconnectFromNetwork,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: provider.isConnecting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Disconnect'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildNetworkCard(
      BuildContext context, NetworkModel network, NetworkProvider provider,
      {bool isSaved = false}) {
    final isConnected = provider.currentNetwork?.id == network.id;
    final isConnecting =
        provider.isConnecting && provider.currentNetwork?.id == network.id;

    return Semantics(
      label: 'Network: ${network.ssid}',
      hint:
          'Signal strength ${network.signalStrengthText}. ${network.securityText}. ${isConnected ? 'Connected' : 'Tap to connect'}.',
      child: Card(
        margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding / 2),
        color: isConnected ? Colors.blue.shade50 : null,
        child: InkWell(
          onTap: isConnected || isConnecting
              ? null
              : () => _showConnectDialog(context, network, provider),
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              children: [
                // Network Icon
                Icon(
                  isConnected ? Icons.wifi : Icons.wifi_lock,
                  color: isConnected ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 12),

                // Network Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            network.ssid,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isConnected ? Colors.blue : null,
                            ),
                          ),
                          if (isConnected) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.check_circle,
                                color: Colors.blue, size: 16),
                          ],
                          if (isSaved) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.bookmark,
                                color: Colors.orange, size: 16),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${network.signalStrengthText} • ${network.securityText}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),

                // Actions
                if (isConnecting) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ] else if (isConnected) ...[
                  IconButton(
                    onPressed: () => _showNetworkDetails(network),
                    icon: const Icon(Icons.info_outline),
                    tooltip: 'Network Details',
                  ),
                ] else ...[
                  PopupMenuButton<String>(
                    onSelected: (action) => _handleNetworkAction(
                        action, network, provider, context),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'connect',
                        child: Row(
                          children: [
                            Icon(Icons.wifi),
                            SizedBox(width: 8),
                            Text('Connect'),
                          ],
                        ),
                      ),
                      if (isSaved) ...[
                        const PopupMenuItem(
                          value: 'forget',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline),
                              SizedBox(width: 8),
                              Text('Forget'),
                            ],
                          ),
                        ),
                      ],
                      const PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline),
                            SizedBox(width: 8),
                            Text('Details'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNetworkAction(String action, NetworkModel network,
      NetworkProvider provider, BuildContext context) {
    switch (action) {
      case 'connect':
        _showConnectDialog(context, network, provider);
        break;
      case 'forget':
        _showForgetDialog(context, network, provider);
        break;
      case 'details':
        _showNetworkDetails(network);
        break;
    }
  }

  void _showConnectDialog(
      BuildContext context, NetworkModel network, NetworkProvider provider) {
    final passwordController = TextEditingController();
    var rememberNetwork = true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Connect to ${network.ssid}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Network: ${network.ssid}'),
            Text('Security: ${network.securityText}'),
            if (network.securityType != SecurityType.open) ...[
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: rememberNetwork,
                  onChanged: (value) =>
                      setState(() => rememberNetwork = value ?? true),
                ),
                const Text('Remember this network'),
              ],
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
              Navigator.of(context).pop();
              final success = await provider.connectToNetwork(network,
                  password: passwordController.text);
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Failed to connect to ${network.ssid}')),
                );
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showForgetDialog(
      BuildContext context, NetworkModel network, NetworkProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forget Network'),
        content: Text('Remove ${network.ssid} from saved networks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.forgetNetwork(network);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${network.ssid} forgotten')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Forget'),
          ),
        ],
      ),
    );
  }

  void _showNetworkDetails(NetworkModel network) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${network.ssid} Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('SSID', network.ssid),
              _buildDetailRow('Signal Strength', network.signalStrengthText),
              _buildDetailRow('Security', network.securityText),
              _buildDetailRow('Network Type', network.type.name),
              if (network.ipAddress != null)
                _buildDetailRow('IP Address', network.ipAddress!),
              if (network.gateway != null)
                _buildDetailRow('Gateway', network.gateway!),
              if (network.subnet != null)
                _buildDetailRow('Subnet', network.subnet!),
              if (network.dns != null) _buildDetailRow('DNS', network.dns!),
              if (network.lastConnected != null)
                _buildDetailRow(
                    'Last Connected', network.lastConnected!.toString()),
              _buildDetailRow('Saved', network.isSaved ? 'Yes' : 'No'),
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

  Widget _buildDetailRow(String label, String value) => Padding(
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
