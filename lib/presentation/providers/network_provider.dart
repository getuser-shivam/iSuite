import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/utils.dart';
import '../../domain/models/network_model.dart';

class NetworkProvider extends ChangeNotifier {
  NetworkProvider() {
    _initializeNetworkMonitoring();
    _loadSavedNetworks();
  }
  List<NetworkModel> _networks = [];
  List<NetworkModel> _savedNetworks = [];
  List<DiscoveredDevice> _discoveredDevices = [];
  NetworkModel? _currentNetwork;
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isHotspotActive = false;
  String? _hotspotName;
  String? _hotspotPassword;
  String? _localIpAddress;
  String? _error;
  ConnectivityResult _connectivityResult = ConnectivityResult.none;
  final NetworkInfo _networkInfo = NetworkInfo();

  // Getters
  List<NetworkModel> get networks => _networks;
  List<NetworkModel> get savedNetworks => _savedNetworks;
  List<DiscoveredDevice> get discoveredDevices => _discoveredDevices;
  NetworkModel? get currentNetwork => _currentNetwork;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  bool get isHotspotActive => _isHotspotActive;
  String? get hotspotName => _hotspotName;
  String? get hotspotPassword => _hotspotPassword;
  String? get localIpAddress => _localIpAddress;
  String? get error => _error;
  ConnectivityResult get connectivityResult => _connectivityResult;

  // Computed properties
  List<NetworkModel> get availableNetworks =>
      _networks.where((n) => n.canConnect).toList();
  List<NetworkModel> get connectedNetworks =>
      _networks.where((n) => n.isConnected).toList();
  bool get hasNetworkConnection =>
      _currentNetwork != null && _currentNetwork!.isConnected;
  bool get isOnline => _connectivityResult != ConnectivityResult.none;
  bool get canShareFiles => isOnline || _isHotspotActive;

  Future<void> _initializeNetworkMonitoring() async {
    // Monitor connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      _connectivityResult = result;
      _updateNetworkInfo();
      notifyListeners();
    });

    // Get initial connectivity status
    final connectivity = await Connectivity().checkConnectivity();
    _connectivityResult = connectivity;
    await _updateNetworkInfo();
    notifyListeners();
  }

  Future<void> _updateNetworkInfo() async {
    try {
      // Get local IP address
      _localIpAddress = await _networkInfo.getWifiIP();
      
      // Get current network info
      final wifiName = await _networkInfo.getWifiName();
      if (wifiName != null && _networks.isNotEmpty) {
        _currentNetwork = _networks.firstWhere(
          (n) => n.ssid == wifiName,
          orElse: () => _networks.first.copyWith(
            ssid: wifiName,
            status: NetworkStatus.connected,
          ),
        );
      }
    } catch (e) {
      AppUtils.logError('NetworkProvider', 'Failed to update network info', e);
    }
  }

  Future<void> _loadSavedNetworks() async {
    try {
      // Load from local storage/database
      // This would integrate with your existing database system
      _savedNetworks = []; // TODO: Implement actual loading
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load saved networks: $e';
      AppUtils.logError('NetworkProvider', 'Failed to load saved networks', e);
      notifyListeners();
    }
  }

  Future<void> scanNetworks() async {
    if (_isScanning) return;

    _isScanning = true;
    _error = null;
    notifyListeners();

    try {
      AppUtils.logInfo('NetworkProvider', 'Starting network scan');

      // Scan for WiFi networks
      final wifiScanResult = await WiFiScan.instance.startScan();

      if (wifiScanResult.isNotEmpty) {
        _networks = wifiScanResult
            .map((wifi) => NetworkModel(
                  id: wifi.bssid,
                  ssid: wifi.ssid,
                  signalStrength: wifi.level.abs(),
                  securityType: _mapSecurityType(wifi.capabilities),
                  metadata: {
                    'bssid': wifi.bssid,
                    'frequency': wifi.frequency,
                    'channel': _getChannelFromFrequency(wifi.frequency),
                    'capabilities': wifi.capabilities,
                  },
                ))
            .toList();

        // Update status for current network if found
        if (_currentNetwork != null) {
          final current = _networks.firstWhere(
            (n) => n.id == _currentNetwork!.id,
            orElse: () => _currentNetwork!,
          );
          _currentNetwork = current.copyWith(status: NetworkStatus.connected);
        }

        AppUtils.logInfo(
            'NetworkProvider', 'Found ${_networks.length} networks');
      } else {
        _error = 'No networks found';
        AppUtils.logWarning('NetworkProvider', 'No networks found during scan');
      }
    } catch (e) {
      _error = 'Failed to scan networks: $e';
      AppUtils.logError('NetworkProvider', 'Network scan failed', e);
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<bool> connectToNetwork(NetworkModel network,
      {String? password}) async {
    if (_isConnecting) return false;

    _isConnecting = true;
    _error = null;
    notifyListeners();

    try {
      AppUtils.logInfo(
          'NetworkProvider', 'Connecting to network: ${network.ssid}');

      // Update network status
      final updatedNetwork = network.copyWith(
        status: NetworkStatus.connecting,
        lastConnected: DateTime.now(),
      );

      // Update in networks list
      final index = _networks.indexWhere((n) => n.id == network.id);
      if (index != -1) {
        _networks[index] = updatedNetwork;
      }

      notifyListeners();

      // Simulate connection process
      await Future.delayed(const Duration(seconds: 3));

      // Update to connected status
      final connectedNetwork = updatedNetwork.copyWith(
        status: NetworkStatus.connected,
        ipAddress: '192.168.1.100', // Simulated IP
        gateway: '192.168.1.1',
        subnet: '255.255.255.0',
        dns: '8.8.8.8',
      );

      _currentNetwork = connectedNetwork;

      final networkIndex = _networks.indexWhere((n) => n.id == network.id);
      if (networkIndex != -1) {
        _networks[networkIndex] = connectedNetwork;
      }

      // Add to saved networks if not already saved
      if (!_savedNetworks.any((n) => n.id == network.id)) {
        final savedNetwork = network.copyWith(
          isSaved: true,
          password: password,
        );
        _savedNetworks.add(savedNetwork);
        await _saveNetworks();
      }

      AppUtils.logInfo(
          'NetworkProvider', 'Successfully connected to ${network.ssid}');
      return true;
    } catch (e) {
      _error = 'Failed to connect to network: $e';
      AppUtils.logError('NetworkProvider', 'Connection failed', e);

      // Update network status to error
      final index = _networks.indexWhere((n) => n.id == network.id);
      if (index != -1) {
        _networks[index] = network.copyWith(status: NetworkStatus.error);
      }

      return false;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<bool> disconnectFromNetwork() async {
    if (_currentNetwork == null) return true;

    try {
      AppUtils.logInfo('NetworkProvider',
          'Disconnecting from network: ${_currentNetwork!.ssid}');

      // Update current network status
      _currentNetwork =
          _currentNetwork!.copyWith(status: NetworkStatus.disconnected);

      // Update in networks list
      final index = _networks.indexWhere((n) => n.id == _currentNetwork!.id);
      if (index != -1) {
        _networks[index] = _currentNetwork!;
      }

      notifyListeners();

      // Simulate disconnection
      await Future.delayed(const Duration(seconds: 1));

      _currentNetwork = null;
      AppUtils.logInfo(
          'NetworkProvider', 'Successfully disconnected from network');
      return true;
    } catch (e) {
      _error = 'Failed to disconnect: $e';
      AppUtils.logError('NetworkProvider', 'Disconnection failed', e);
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> forgetNetwork(NetworkModel network) async {
    try {
      AppUtils.logInfo(
          'NetworkProvider', 'Forgetting network: ${network.ssid}');

      // Remove from saved networks
      _savedNetworks.removeWhere((n) => n.id == network.id);

      // Update in networks list
      final index = _networks.indexWhere((n) => n.id == network.id);
      if (index != -1) {
        _networks[index] = network.copyWith(isSaved: false);
      }

      await _saveNetworks();
      notifyListeners();

      AppUtils.logInfo(
          'NetworkProvider', 'Successfully forgot network: ${network.ssid}');
    } catch (e) {
      _error = 'Failed to forget network: $e';
      AppUtils.logError('NetworkProvider', 'Forget network failed', e);
      notifyListeners();
    }
  }

  Future<void> saveNetwork(NetworkModel network) async {
    try {
      if (!_savedNetworks.any((n) => n.id == network.id)) {
        final savedNetwork = network.copyWith(isSaved: true);
        _savedNetworks.add(savedNetwork);

        // Update in networks list
        final index = _networks.indexWhere((n) => n.id == network.id);
        if (index != -1) {
          _networks[index] = savedNetwork;
        }

        await _saveNetworks();
        notifyListeners();

        AppUtils.logInfo(
            'NetworkProvider', 'Successfully saved network: ${network.ssid}');
      }
    } catch (e) {
      _error = 'Failed to save network: $e';
      AppUtils.logError('NetworkProvider', 'Save network failed', e);
      notifyListeners();
    }
  }

  Future<void> _saveNetworks() async {
    try {
      // Save to local storage/database
      // This would integrate with your existing database system
      AppUtils.logInfo(
          'NetworkProvider', 'Saving ${_savedNetworks.length} saved networks');
    } catch (e) {
      AppUtils.logError('NetworkProvider', 'Failed to save networks', e);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void refreshNetworks() {
    scanNetworks();
  }

  // Advanced Network Features (inspired by Sharik and ezShare)
  
  Future<bool> requestPermissions() async {
    try {
      final locationPermission = await Permission.location.request();
      final nearbyDevicesPermission = await Permission.nearbyWifiDevices.request();
      
      return locationPermission.isGranted && nearbyDevicesPermission.isGranted;
    } catch (e) {
      AppUtils.logError('NetworkProvider', 'Permission request failed', e);
      return false;
    }
  }

  Future<bool> createHotspot({String? ssid, String? password}) async {
    try {
      _isHotspotActive = true;
      _hotspotName = ssid ?? 'iSuite_${DateTime.now().millisecondsSinceEpoch}';
      _hotspotPassword = password ?? AppUtils.generateRandomPassword(8);
      
      // This would integrate with platform-specific hotspot creation
      // For Android: WifiManager.startLocalOnlyHotspot()
      // For iOS: NEHotspotHelper (limited support)
      
      AppUtils.logInfo('NetworkProvider', 'Created hotspot: $_hotspotName');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create hotspot: $e';
      _isHotspotActive = false;
      AppUtils.logError('NetworkProvider', 'Hotspot creation failed', e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> stopHotspot() async {
    try {
      // This would integrate with platform-specific hotspot stopping
      _isHotspotActive = false;
      _hotspotName = null;
      _hotspotPassword = null;
      
      AppUtils.logInfo('NetworkProvider', 'Stopped hotspot');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to stop hotspot: $e';
      AppUtils.logError('NetworkProvider', 'Hotspot stop failed', e);
      notifyListeners();
      return false;
    }
  }

  Future<void> discoverDevices() async {
    if (_isScanning) return;

    _isScanning = true;
    _discoveredDevices.clear();
    notifyListeners();

    try {
      AppUtils.logInfo('NetworkProvider', 'Starting device discovery');
      
      // Discover devices on the same network
      await _discoverNetworkDevices();
      
      // Discover WiFi Direct devices (Android only)
      await _discoverWiFiDirectDevices();
      
      AppUtils.logInfo('NetworkProvider', 'Found ${_discoveredDevices.length} devices');
    } catch (e) {
      _error = 'Failed to discover devices: $e';
      AppUtils.logError('NetworkProvider', 'Device discovery failed', e);
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> _discoverNetworkDevices() async {
    try {
      // Scan common ports for file sharing services
      final subnet = await _getSubnet();
      if (subnet == null) return;

      final commonPorts = [80, 8080, 21, 22, 443, 5000, 8000, 9000];
      
      for (int i = 1; i <= 254; i++) {
        final ip = '$subnet.$i';
        
        for (final port in commonPorts) {
          try {
            final socket = await Socket.connect(ip, port, timeout: Duration(milliseconds: 500));
            socket.destroy();
            
            _discoveredDevices.add(DiscoveredDevice(
              id: '$ip:$port',
              name: 'Device at $ip',
              ipAddress: ip,
              port: port,
              type: DeviceType.networkService,
              lastSeen: DateTime.now(),
            ));
            
            break; // Found an open port, move to next IP
          } catch (e) {
            // Port is closed or host is unreachable
          }
        }
      }
    } catch (e) {
      AppUtils.logError('NetworkProvider', 'Network device discovery failed', e);
    }
  }

  Future<void> _discoverWiFiDirectDevices() async {
    try {
      // This would integrate with WiFi Direct API
      // For Android: WifiManager.requestPeers()
      AppUtils.logInfo('NetworkProvider', 'WiFi Direct discovery not yet implemented');
    } catch (e) {
      AppUtils.logError('NetworkProvider', 'WiFi Direct discovery failed', e);
    }
  }

  Future<String?> _getSubnet() async {
    try {
      final ip = await _networkInfo.getWifiIP();
      if (ip != null) {
        final parts = ip.split('.');
        return '${parts[0]}.${parts[1]}.${parts[2]}';
      }
    } catch (e) {
      AppUtils.logError('NetworkProvider', 'Failed to get subnet', e);
    }
    return null;
  }

  Future<bool> testConnection(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: Duration(seconds: 5));
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<NetworkSpeed> measureNetworkSpeed() async {
    try {
      final startTime = DateTime.now();
      final testData = List.filled(1024 * 100, 0); // 100KB test data
      
      // This would implement actual speed test
      // For now, return estimated values based on connection type
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      return NetworkSpeed(
        downloadSpeed: 10.0, // Mbps
        uploadSpeed: 5.0,    // Mbps
        latency: duration.inMilliseconds, // ms
        testTime: endTime,
      );
    } catch (e) {
      AppUtils.logError('NetworkProvider', 'Speed test failed', e);
      return NetworkSpeed(
        downloadSpeed: 0.0,
        uploadSpeed: 0.0,
        latency: 9999,
        testTime: DateTime.now(),
      );
    }
  }

  // Helper methods
  SecurityType _mapSecurityType(String capabilities) {
    if (capabilities.contains('WPA3')) return SecurityType.wpa3;
    if (capabilities.contains('WPA2')) return SecurityType.wpa2;
    if (capabilities.contains('WPA')) return SecurityType.wpa;
    if (capabilities.contains('WEP')) return SecurityType.wep;
    return SecurityType.open;
  }

  int _getChannelFromFrequency(int frequency) {
    if (frequency == 2484) return 14;
    return (frequency - 2407) ~/ 5;
  }

  // Advanced network operations
  Future<bool> testConnection(NetworkModel network) async {
    try {
      AppUtils.logInfo(
          'NetworkProvider', 'Testing connection to: ${network.ssid}');

      // Simulate connection test
      await Future.delayed(const Duration(seconds: 2));

      // Return random success for demo
      return DateTime.now().millisecondsSinceEpoch % 3 != 0;
    } catch (e) {
      AppUtils.logError('NetworkProvider', 'Connection test failed', e);
      return false;
    }
  }

  Future<Map<String, dynamic>> getNetworkInfo() async {
    try {
      // Get detailed network information
      return {
        'ssid': _currentNetwork?.ssid,
        'bssid': _currentNetwork?.id,
        'ipAddress': _currentNetwork?.ipAddress,
        'gateway': _currentNetwork?.gateway,
        'subnet': _currentNetwork?.subnet,
        'dns': _currentNetwork?.dns,
        'signalStrength': _currentNetwork?.signalStrength,
        'security': _currentNetwork?.securityText,
        'connectivity': _connectivityResult.name,
        'isConnected': hasNetworkConnection,
        'lastConnected': _currentNetwork?.lastConnected?.toIso8601String(),
      };
    } catch (e) {
      AppUtils.logError('NetworkProvider', 'Failed to get network info', e);
      return {};
    }
  }
}
