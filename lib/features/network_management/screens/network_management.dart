import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'dart:io';
import '../../../core/central_config.dart';

class NetworkManagementScreen extends StatefulWidget {
  const NetworkManagementScreen({super.key});

  @override
  State<NetworkManagementScreen> createState() => _NetworkManagementScreenState();
}

class _NetworkManagementScreenState extends State<NetworkManagementScreen>
    with TickerProviderStateMixin {
  List<WiFiAccessPoint> accessPoints = [];
  bool isScanning = false;
  String currentConnection = 'Unknown';
  String? ipAddress;
  String? wifiName;

  // Network tools state
  final TextEditingController _pingController = TextEditingController(text: '8.8.8.8');
  final TextEditingController _tracerouteController = TextEditingController(text: 'google.com');
  final TextEditingController _portScanHostController = TextEditingController(text: '127.0.0.1');
  final TextEditingController _portScanRangeController = TextEditingController(text: '20-100');
  
  String _pingResult = '';
  List<String> _tracerouteResult = [];
  List<int> _openPorts = [];
  bool _isToolRunning = false;

  final Connectivity _connectivity = Connectivity();
  final NetworkInfo _networkInfo = NetworkInfo();
  final CentralConfig _config = CentralConfig.instance;

  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  // Keys for performance optimization
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _initNetworkInfo();
    _checkPermissions();

    // Setup scan animation
    _scanAnimationController = AnimationController(
      duration: _config.scanAnimationDuration,
      vsync: this,
    )..repeat(reverse: true);
    _scanAnimation = Tween<double>(
      begin: _config.scanAnimationMinScale, 
      end: _config.scanAnimationMaxScale
    ).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _pingController.dispose();
    _tracerouteController.dispose();
    _portScanHostController.dispose();
    _portScanRangeController.dispose();
    super.dispose();
  }

  Future<void> _initNetworkInfo() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      currentConnection = connectivityResult.toString();

      ipAddress = await _networkInfo.getWifiIP();
      wifiName = await _networkInfo.getWifiName();

      setState(() {});
    } catch (e) {
      // Error boundary: Handle network info retrieval failures gracefully
      print('Error getting network info: $e');
      currentConnection = 'Error retrieving connection';
      setState(() {});
    }
  }

  Future<void> _checkPermissions() async {
    try {
      // Check WiFi scan permissions with error boundary
      final can = await WiFiScan.instance.canGetScannedResults();
      if (can == CanGetScannedResults.yes) {
        _startScan();
      } else {
        print('WiFi scan permissions not granted');
      }
    } catch (e) {
      print('Error checking WiFi permissions: $e');
    }
  }

  Future<void> _startScan() async {
    if (isScanning) return; // Prevent multiple simultaneous scans

    setState(() => isScanning = true);

    try {
      final can = await WiFiScan.instance.canStartScan();
      if (can == CanStartScan.yes) {
        await WiFiScan.instance.startScan();
        await Future.delayed(_config.wifiScanDelay);
        final results = await WiFiScan.instance.getScannedResults();
        setState(() {
          accessPoints = results;
          isScanning = false;
        });
      } else {
        print('Cannot start WiFi scan');
        setState(() => isScanning = false);
      }
    } catch (e) {
      // Error boundary: Handle scan failures
      print('Error scanning WiFi: $e');
      setState(() => isScanning = false);
    }
  }

  String _getSignalStrengthIcon(int level) {
    if (level >= _config.excellentSignalThreshold) return '📶'; // Excellent
    if (level >= _config.goodSignalThreshold) return '📶'; // Good
    if (level >= _config.fairSignalThreshold) return '📶'; // Fair
    return '📶'; // Weak
  }

  Color _getSignalColor(int level) {
    if (level >= _config.excellentSignalThreshold) return _config.wifiSignalExcellent;
    if (level >= _config.goodSignalThreshold) return _config.wifiSignalGood;
    if (level >= _config.fairSignalThreshold) return _config.wifiSignalFair;
    return _config.wifiSignalWeak;
  }

  Widget _buildToolSection(String title, IconData icon, TextEditingController controller, 
                           String buttonText, VoidCallback onPressed, String? result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _config.primaryColor,
          ),
        ),
        SizedBox(height: _config.defaultPadding / 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Host/IP',
                  labelStyle: TextStyle(color: _config.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_config.borderRadius),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: _config.defaultPadding,
                    vertical: _config.defaultPadding / 2,
                  ),
                ),
                style: TextStyle(color: _config.primaryColor),
              ),
            ),
            SizedBox(width: _config.defaultPadding),
            ElevatedButton.icon(
              onPressed: _isToolRunning ? null : onPressed,
              icon: Icon(icon, size: _config.smallIconSize),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: _config.primaryColor,
                foregroundColor: _config.surfaceColor,
                padding: EdgeInsets.symmetric(
                  horizontal: _config.defaultPadding,
                  vertical: _config.defaultPadding / 2,
                ),
              ),
            ),
          ],
        ),
        if (result != null)
          Padding(
            padding: EdgeInsets.only(top: _config.defaultPadding / 2),
            child: Container(
              padding: EdgeInsets.all(_config.defaultPadding / 2),
              decoration: BoxDecoration(
                color: _config.secondaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(_config.borderRadius),
              ),
              child: Text(
                result,
                style: TextStyle(
                  fontSize: 12,
                  color: _config.primaryColor,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _ping() async {
    if (_isToolRunning) return;
    setState(() => _isToolRunning = true);

    try {
      final host = _pingController.text.trim();
      if (host.isEmpty) return;

      setState(() => _pingResult = 'Pinging $host...');

      // Use Process to run ping command
      final result = await Process.run('ping', ['-n', '4', host]);

      setState(() {
        _pingResult = result.stdout.toString().trim();
        if (result.stderr.toString().isNotEmpty) {
          _pingResult += '\nError: ${result.stderr}';
        }
      });
    } catch (e) {
      setState(() => _pingResult = 'Error: $e');
    } finally {
      setState(() => _isToolRunning = false);
    }
  }

  Future<void> _traceroute() async {
    if (_isToolRunning) return;
    setState(() => _isToolRunning = true);

    try {
      final host = _tracerouteController.text.trim();
      if (host.isEmpty) return;

      setState(() => _tracerouteResult = ['Tracing route to $host...']);

      // Use tracert on Windows
      final result = await Process.run('tracert', ['-d', '-h', '10', host]);

      final lines = result.stdout.toString().split('\n');
      setState(() => _tracerouteResult = lines.where((line) => line.trim().isNotEmpty).toList());

      if (result.stderr.toString().isNotEmpty) {
        setState(() => _tracerouteResult.add('Error: ${result.stderr}'));
      }
    } catch (e) {
      setState(() => _tracerouteResult = ['Error: $e']);
    } finally {
      setState(() => _isToolRunning = false);
    }
  }

  Future<void> _portScan() async {
    if (_isToolRunning) return; // Prevent concurrent tool execution
    setState(() => _isToolRunning = true);

    try {
      final host = _portScanHostController.text.trim();
      final rangeText = _portScanRangeController.text.trim();

      // Input validation
      if (host.isEmpty || rangeText.isEmpty) {
        print('Host or range is empty');
        return;
      }

      // Parse port range (e.g., "20-100")
      final rangeParts = rangeText.split('-');
      if (rangeParts.length != 2) {
        print('Invalid range format');
        return;
      }

      final startPort = int.tryParse(rangeParts[0]);
      final endPort = int.tryParse(rangeParts[1]);

      if (startPort == null || endPort == null || startPort >= endPort || startPort < 1 || endPort > 65535) {
        print('Invalid port range');
        return;
      }

      setState(() => _openPorts = []);

      final openPorts = <int>[];
      final batchSize = _config.portScanBatchSize; // Scan ports in batches to avoid overwhelming the system

      // Scan ports in range with progress updates
      for (int port = startPort; port <= endPort; port++) {
        try {
          // Attempt to connect to the port with timeout
          final socket = await Socket.connect(host, port, timeout: _config.portScanTimeout);
          await socket.close();
          openPorts.add(port);
          // Update UI with found open ports
          setState(() => _openPorts = List.from(openPorts));
        } catch (e) {
          // Port is closed or connection failed - this is expected behavior
        }

        // Yield control to prevent blocking UI
        if (port % batchSize == 0) {
          await Future.delayed(Duration(milliseconds: _config.portScanBatchDelayMs));
        }
      }

      setState(() => _openPorts = openPorts);
      print('Port scan completed. Found ${openPorts.length} open ports on $host');
    } catch (e) {
      // Error boundary: Handle port scan failures
      print('Error during port scan: $e');
      setState(() => _openPorts = []);
    } finally {
      setState(() => _isToolRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_config.wifiScreenTitle),
        elevation: _config.cardElevation,
      ),
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: () async {
          await _startScan();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(_config.defaultPadding),
          child: Column(
            children: [
              // Current Connection Info - Enhanced with accessibility
              Semantics(
                header: true,
                label: 'Current network connection information',
                child: Card(
                  elevation: _config.cardElevation,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_config.borderRadius),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(_config.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          key: const ValueKey('connection_header'),
                          children: [
                            Semantics(
                              label: 'WiFi connection icon',
                              child: Icon(Icons.wifi, color: _config.primaryColor),
                            ),
                            SizedBox(width: _config.defaultPadding / 2),
                            Expanded(
                              child: Text(
                                _config.currentConnectionLabel,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _config.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: _config.defaultPadding / 2),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: _config.defaultPadding,
                            vertical: _config.defaultPadding / 2,
                          ),
                          decoration: BoxDecoration(
                            color: _config.secondaryColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(_config.borderRadius),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                label: 'Connection type: $currentConnection',
                                child: Text('Type: $currentConnection'),
                              ),
                              if (wifiName != null)
                                Semantics(
                                  label: 'Connected WiFi network: $wifiName',
                                  child: Text('WiFi: $wifiName'),
                                ),
                              if (ipAddress != null)
                                Semantics(
                                  label: 'IP address: $ipAddress',
                                  child: Text('IP: $ipAddress'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: _config.defaultPadding),

              // WiFi Scan Results
              Card(
                elevation: _config.cardElevation,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_config.borderRadius),
                ),
                child: Padding(
                  padding: EdgeInsets.all(_config.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        key: const ValueKey('wifi_header'),
                        children: [
                          Icon(Icons.wifi_find, color: _config.primaryColor),
                          SizedBox(width: _config.defaultPadding / 2),
                          Text(
                            _config.wifiNetworksLabel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _config.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: _config.defaultPadding),
                      SizedBox(
                        height: _config.wifiListHeight, // Fixed height for performance
                        child: isScanning
                            ? Center(
                                child: AnimatedBuilder(
                                  animation: _scanAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _scanAnimation.value,
                                      child: Icon(
                                        Icons.wifi_find,
                                        size: _config.animationIconSize,
                                        color: _config.primaryColor,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : accessPoints.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.wifi_off,
                                          size: _config.emptyStateIconSize,
                                          color: _config.primaryColor.withOpacity(0.5),
                                        ),
                                        SizedBox(height: _config.defaultPadding),
                                        Text(
                                          'No networks found',
                                          style: TextStyle(
                                            color: _config.primaryColor.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    key: const PageStorageKey('wifi_list'),
                                    itemCount: accessPoints.length,
                                    itemBuilder: (context, index) {
                                      final ap = accessPoints[index];
                                      return Container(
                                        key: ValueKey('wifi_${ap.ssid}_${index}'),
                                        margin: EdgeInsets.only(bottom: _config.defaultPadding / 2),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: _config.primaryColor.withOpacity(0.2),
                                          ),
                                          borderRadius: BorderRadius.circular(_config.borderRadius),
                                        ),
                                        child: ListTile(
                                          leading: Text(
                                            _getSignalStrengthIcon(ap.level),
                                            style: const TextStyle(fontSize: 24),
                                          ),
                                          title: Text(
                                            ap.ssid.isNotEmpty ? ap.ssid : 'Hidden Network',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: _config.primaryColor,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Signal: ${ap.level}dBm | Freq: ${ap.frequency}MHz\nCapabilities: ${ap.capabilities}',
                                            style: TextStyle(fontSize: _config.subtitleFontSize),
                                          ),
                                          trailing: Icon(
                                            ap.capabilities.contains('WPA') ? Icons.lock : Icons.lock_open,
                                            color: ap.capabilities.contains('WPA')
                                                ? _config.accentColor
                                                : _config.successColor,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: _config.defaultPadding),

              // Network Tools Section
              Card(
                elevation: _config.cardElevation,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_config.borderRadius),
                ),
                child: ExpansionTile(
                  key: const PageStorageKey('network_tools'),
                  title: Row(
                    children: [
                      Icon(Icons.build, color: _config.primaryColor),
                      SizedBox(width: _config.defaultPadding / 2),
                      Text(
                        'Network Tools',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _config.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(_config.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ping Tool
                          _buildToolSection(
                            'Ping',
                            Icons.network_ping,
                            _pingController,
                            'Ping Host',
                            _ping,
                            _pingResult.isNotEmpty ? _pingResult : null,
                          ),
                          SizedBox(height: _config.defaultPadding),

                          // Traceroute Tool
                          _buildToolSection(
                            'Traceroute',
                            Icons.route,
                            _tracerouteController,
                            'Traceroute Host',
                            _traceroute,
                            _tracerouteResult.isNotEmpty ? _tracerouteResult.join('\n') : null,
                          ),
                          SizedBox(height: _config.defaultPadding),

                          // Port Scan Tool
                          Row(
                            key: const ValueKey('port_scan_row'),
                            children: [
                              Expanded(
                                child: TextField(
                                  key: const ValueKey('port_scan_host'),
                                  controller: _portScanHostController,
                                  decoration: InputDecoration(
                                    labelText: 'Host',
                                    labelStyle: TextStyle(color: _config.primaryColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(_config.borderRadius),
                                    ),
                                  ),
                                  style: TextStyle(color: _config.primaryColor),
                                ),
                              ),
                              SizedBox(width: _config.defaultPadding),
                              Expanded(
                                child: TextField(
                                  key: const ValueKey('port_scan_range'),
                                  controller: _portScanRangeController,
                                  decoration: InputDecoration(
                                    labelText: 'Port Range (e.g., 20-100)',
                                    labelStyle: TextStyle(color: _config.primaryColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(_config.borderRadius),
                                    ),
                                  ),
                                  style: TextStyle(color: _config.primaryColor),
                                ),
                              ),
                              SizedBox(width: _config.defaultPadding),
                              ElevatedButton.icon(
                                key: const ValueKey('port_scan_button'),
                                onPressed: _isToolRunning ? null : _portScan,
                                icon: Icon(_isToolRunning ? Icons.hourglass_empty : Icons.search),
                                label: Text('Scan'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _config.primaryColor,
                                  foregroundColor: _config.surfaceColor,
                                ),
                              ),
                            ],
                          ),
                          if (_openPorts.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: _config.defaultPadding / 2),
                              child: Text(
                                'Open Ports: ${_openPorts.join(', ')}',
                                style: TextStyle(
                                  color: _config.successColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('scan_fab'),
        onPressed: isScanning ? null : _startScan,
        backgroundColor: _config.primaryColor,
        foregroundColor: _config.surfaceColor,
        icon: Icon(isScanning ? Icons.wifi_find : Icons.refresh),
        label: Text(_config.scanButtonLabel),
      ),
    );
  }
}
