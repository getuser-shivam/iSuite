import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/network_sharing_engine.dart';
import '../../core/component_registry.dart';
import '../../domain/models/network_model.dart';
import '../../domain/models/discovered_device_model.dart';
import '../../domain/models/shared_file_model.dart';

/// Enhanced Network Provider with Central Parameterization
/// Provides comprehensive network management, WiFi operations, and file sharing capabilities
class EnhancedNetworkProvider extends ChangeNotifier {
  // Central Configuration
  NetworkConfig _config = NetworkConfig.defaultConfig();

  // Network State
  bool _isInitialized = false;
  ConnectivityResult _currentConnectivity = ConnectivityResult.none;
  String? _currentWifiName;
  String? _currentWifiBSSID;
  String? _localIpAddress;
  int _signalStrength = 0;
  double _connectionSpeed = 0.0;

  // WiFi Management
  List<WifiNetwork> _availableNetworks = [];
  List<NetworkModel> _savedNetworks = [];
  bool _isScanning = false;
  bool _isConnected = false;

  // Device Discovery
  List<DiscoveredDeviceModel> _discoveredDevices = [];
  bool _isDiscovering = false;
  Timer? _discoveryTimer;

  // File Sharing
  NetworkSharingEngine _sharingEngine = NetworkSharingEngine.instance;
  Map<String, SharedFileModel> _sharedFiles = {};
  Map<String, FileTransferSession> _activeTransfers = {};
  bool _isSharingServerRunning = false;

  // Hotspot Management
  bool _isHotspotEnabled = false;
  HotspotConfig _hotspotConfig = HotspotConfig.defaultConfig();

  // Event Streams
  final StreamController<NetworkEvent> _eventController =
      StreamController<NetworkEvent>.broadcast();

  // Performance Monitoring
  final Map<String, dynamic> _performanceMetrics = {};
  DateTime _lastMetricsUpdate = DateTime.now();

  // Getters with Central Parameterization
  NetworkConfig get config => _config;
  bool get isInitialized => _isInitialized;
  ConnectivityResult get currentConnectivity => _currentConnectivity;
  String? get currentWifiName => _currentWifiName;
  String? get currentWifiBSSID => _currentWifiBSSID;
  String? get localIpAddress => _localIpAddress;
  int get signalStrength => _signalStrength;
  double get connectionSpeed => _connectionSpeed;
  List<WifiNetwork> get availableNetworks => List.from(_availableNetworks);
  List<NetworkModel> get savedNetworks => List.from(_savedNetworks);
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  List<DiscoveredDeviceModel> get discoveredDevices =>
      List.from(_discoveredDevices);
  bool get isDiscovering => _isDiscovering;
  Map<String, SharedFileModel> get sharedFiles => Map.from(_sharedFiles);
  Map<String, FileTransferSession> get activeTransfers =>
      Map.from(_activeTransfers);
  bool get isSharingServerRunning => _isSharingServerRunning;
  bool get isHotspotEnabled => _isHotspotEnabled;
  HotspotConfig get hotspotConfig => _hotspotConfig;
  Stream<NetworkEvent> get events => _eventController.stream;
  Map<String, dynamic> get performanceMetrics => Map.from(_performanceMetrics);

  /// Initialize the enhanced network provider
  Future<bool> initialize({NetworkConfig? config}) async {
    if (_isInitialized) return true;

    try {
      // Set configuration from central registry if not provided
      _config = config ??
          ComponentRegistry.instance.getParameter('network_config') ??
          NetworkConfig.defaultConfig();

      // Request permissions
      await _requestPermissions();

      // Initialize sharing engine
      await _sharingEngine.initialize(
          config: NetworkSharingConfig(
        defaultPort: _config.defaultPort,
        enableAutoDiscovery: _config.enableAutoDiscovery,
        enableQRCode: _config.enableQRCode,
        enablePasswordProtection: _config.enablePasswordProtection,
        sessionTimeout: _config.sessionTimeout,
        maxConcurrentTransfers: _config.maxConcurrentTransfers,
        maxFileSize: _config.maxFileSize,
      ));

      // Start connectivity monitoring
      await _startConnectivityMonitoring();

      // Start performance monitoring
      _startPerformanceMonitoring();

      // Load saved networks
      await _loadSavedNetworks();

      _isInitialized = true;
      await _emitEvent(NetworkEvent.initialized);
      notifyListeners();

      return true;
    } catch (e) {
      await _emitEvent(NetworkEvent.error('Initialization failed: $e'));
      return false;
    }
  }

  /// Update configuration (central parameterization)
  Future<void> updateConfig(NetworkConfig config) async {
    _config = config;

    // Update central registry
    await ComponentRegistry.instance.setParameter('network_config', config);

    // Reinitialize sharing engine with new config
    await _sharingEngine.dispose();
    await _sharingEngine.initialize(
        config: NetworkSharingConfig(
      defaultPort: config.defaultPort,
      enableAutoDiscovery: config.enableAutoDiscovery,
      enableQRCode: config.enableQRCode,
      enablePasswordProtection: config.enablePasswordProtection,
      sessionTimeout: config.sessionTimeout,
      maxConcurrentTransfers: config.maxConcurrentTransfers,
      maxFileSize: config.maxFileSize,
    ));

    notifyListeners();
    await _emitEvent(NetworkEvent.configUpdated);
  }

  /// Scan for available WiFi networks
  Future<bool> scanNetworks() async {
    if (_isScanning) return false;

    try {
      _isScanning = true;
      notifyListeners();

      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        await _emitEvent(NetworkEvent.permissionDenied(
            'Location permission required for WiFi scanning'));
        return false;
      }

      // Start WiFi scan
      final result = await WiFiScan.instance.startScan();

      if (result) {
        // Wait a moment for scan to complete
        await Future.delayed(Duration(seconds: 3));

        // Get scanned networks
        final networks = await WiFiScan.instance.getScannedResults();

        _availableNetworks = networks
            .map((network) => WifiNetwork(
                  ssid: network.ssid,
                  bssid: network.bssid,
                  signalStrength: network.level ?? 0,
                  frequency: network.frequency ?? 0,
                  capabilities: network.capabilities ?? '',
                  isSecure: (network.capabilities ?? '').contains('WEP') ||
                      (network.capabilities ?? '').contains('WPA') ||
                      (network.capabilities ?? '').contains('WPA2'),
                ))
            .toList();

        // Sort by signal strength
        _availableNetworks
            .sort((a, b) => b.signalStrength.compareTo(a.signalStrength));

        await _emitEvent(
            NetworkEvent.networksScanned(_availableNetworks.length));
      }

      return result;
    } catch (e) {
      await _emitEvent(NetworkEvent.error('WiFi scan failed: $e'));
      return false;
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Connect to WiFi network
  Future<bool> connectToNetwork(WifiNetwork network, {String? password}) async {
    try {
      if (network.isSecure && (password == null || password.isEmpty)) {
        await _emitEvent(
            NetworkEvent.error('Password required for secure network'));
        return false;
      }

      await _emitEvent(NetworkEvent.connecting(network.ssid));

      // In a real implementation, this would use platform-specific APIs
      // For now, we'll simulate the connection
      await Future.delayed(Duration(seconds: 3));

      // Update connection state
      _isConnected = true;
      _currentWifiName = network.ssid;
      _currentWifiBSSID = network.bssid;
      _signalStrength = network.signalStrength;

      // Save network if not already saved
      if (!_savedNetworks.any((n) => n.bssid == network.bssid)) {
        final savedNetwork = NetworkModel(
          ssid: network.ssid,
          bssid: network.bssid,
          password: password,
          isSecure: network.isSecure,
          lastConnected: DateTime.now(),
          connectionCount: 1,
        );

        _savedNetworks.add(savedNetwork);
        await _saveNetworks();
      } else {
        // Update existing network
        final existingNetwork =
            _savedNetworks.firstWhere((n) => n.bssid == network.bssid);
        existingNetwork.lastConnected = DateTime.now();
        existingNetwork.connectionCount++;
        await _saveNetworks();
      }

      await _emitEvent(NetworkEvent.connected(network.ssid));
      notifyListeners();

      return true;
    } catch (e) {
      await _emitEvent(NetworkEvent.error('Connection failed: $e'));
      return false;
    }
  }

  /// Disconnect from current network
  Future<void> disconnect() async {
    try {
      if (!_isConnected) return;

      await _emitEvent(NetworkEvent.disconnecting(_currentWifiName));

      // In a real implementation, this would use platform-specific APIs
      await Future.delayed(Duration(seconds: 1));

      _isConnected = false;
      _currentWifiName = null;
      _currentWifiBSSID = null;
      _signalStrength = 0;

      await _emitEvent(NetworkEvent.disconnected);
      notifyListeners();
    } catch (e) {
      await _emitEvent(NetworkEvent.error('Disconnection failed: $e'));
    }
  }

  /// Start device discovery
  Future<void> startDeviceDiscovery() async {
    if (_isDiscovering) return;

    try {
      _isDiscovering = true;
      _discoveredDevices.clear();
      notifyListeners();

      // Start sharing engine discovery
      await _sharingEngine.startNetworkDiscovery();

      // Listen for discovery events
      _sharingEngine.events.listen((event) {
        if (event.type == NetworkSharingEventType.devicesDiscovered) {
          final devices = event.data as List<DiscoveredDevice>;
          _discoveredDevices = devices
              .map((device) => DiscoveredDeviceModel(
                    id: device.id,
                    name: device.name,
                    ipAddress: device.ipAddress,
                    type: _mapDeviceType(device.type),
                    lastSeen: device.lastSeen,
                    isOnline: device.isOnline,
                    metadata: device.metadata,
                  ))
              .toList();

          notifyListeners();
          _emitEvent(NetworkEvent.devicesDiscovered(_discoveredDevices.length));
        }
      });

      // Start periodic discovery
      _discoveryTimer = Timer.periodic(Duration(seconds: 10), (_) {
        _updateDeviceDiscovery();
      });

      await _emitEvent(NetworkEvent.discoveryStarted);
      notifyListeners();
    } catch (e) {
      await _emitEvent(NetworkEvent.error('Discovery failed: $e'));
    }
  }

  /// Stop device discovery
  Future<void> stopDeviceDiscovery() async {
    if (!_isDiscovering) return;

    try {
      _discoveryTimer?.cancel();
      _discoveryTimer = null;

      await _sharingEngine.stopNetworkDiscovery();

      _isDiscovering = false;
      notifyListeners();

      await _emitEvent(NetworkEvent.discoveryStopped);
    } catch (e) {
      await _emitEvent(NetworkEvent.error('Discovery stop failed: $e'));
    }
  }

  /// Start file sharing server
  Future<bool> startSharingServer({
    String? directoryPath,
    int? port,
    bool enableQRCode = true,
    bool enablePassword = false,
    String? password,
  }) async {
    try {
      final result = await _sharingEngine.startSharingServer(
        directoryPath: directoryPath,
        port: port,
        enableQRCode: enableQRCode,
        enablePassword: enablePassword,
        password: password,
      );

      if (result) {
        _isSharingServerRunning = true;
        notifyListeners();
        await _emitEvent(NetworkEvent.sharingServerStarted);

        // Listen to sharing events
        _sharingEngine.events.listen((event) {
          if (event.type == NetworkSharingEventType.fileShared) {
            final sharedFile = event.data as SharedFile;
            _sharedFiles[sharedFile.id] =
                SharedFileModel.fromSharedFile(sharedFile);
            notifyListeners();
          } else if (event.type == NetworkSharingEventType.error) {
            _emitEvent(
                NetworkEvent.error(event.message ?? 'Sharing engine error'));
          }
        });
      }

      return result;
    } catch (e) {
      await _emitEvent(
          NetworkEvent.error('Failed to start sharing server: $e'));
      return false;
    }
  }

  /// Stop file sharing server
  Future<void> stopSharingServer() async {
    try {
      await _sharingEngine.stopSharingServer();

      _isSharingServerRunning = false;
      _sharedFiles.clear();
      notifyListeners();

      await _emitEvent(NetworkEvent.sharingServerStopped);
    } catch (e) {
      await _emitEvent(NetworkEvent.error('Failed to stop sharing server: $e'));
    }
  }

  /// Share a file
  Future<String> shareFile(
    String filePath, {
    String? customName,
    bool generateQRCode = true,
    bool enablePassword = false,
    String? password,
    Duration? expiryTime,
  }) async {
    try {
      final shareId = await _sharingEngine.shareFile(
        filePath,
        customName: customName,
        generateQRCode: generateQRCode,
        enablePassword: enablePassword,
        password: password,
        expiryTime: expiryTime,
      );

      await _emitEvent(NetworkEvent.fileShared(filePath));
      return shareId;
    } catch (e) {
      await _emitEvent(NetworkEvent.error('Failed to share file: $e'));
      rethrow;
    }
  }

  /// Generate QR code for sharing
  Future<String> generateQRCode(String shareId) async {
    try {
      final url = await _sharingEngine.generateQRCode(shareId);
      await _emitEvent(NetworkEvent.qrCodeGenerated(shareId));
      return url;
    } catch (e) {
      await _emitEvent(NetworkEvent.error('Failed to generate QR code: $e'));
      rethrow;
    }
  }

  /// Enable WiFi hotspot
  Future<bool> enableHotspot({
    String? ssid,
    String? password,
    HotspotSecurity security = HotspotSecurity.wpa2,
  }) async {
    try {
      // In a real implementation, this would use platform-specific APIs
      await Future.delayed(Duration(seconds: 2));

      _isHotspotEnabled = true;
      _hotspotConfig = _hotspotConfig.copyWith(
        ssid: ssid ?? _hotspotConfig.ssid,
        password: password ?? _hotspotConfig.password,
        security: security,
      );

      notifyListeners();
      await _emitEvent(NetworkEvent.hotspotEnabled);
      return true;
    } catch (e) {
      await _emitEvent(NetworkEvent.error('Failed to enable hotspot: $e'));
      return false;
    }
  }

  /// Disable WiFi hotspot
  Future<void> disableHotspot() async {
    try {
      // In a real implementation, this would use platform-specific APIs
      await Future.delayed(Duration(seconds: 1));

      _isHotspotEnabled = false;
      notifyListeners();

      await _emitEvent(NetworkEvent.hotspotDisabled);
    } catch (e) {
      await _emitEvent(NetworkEvent.error('Failed to disable hotspot: $e'));
    }
  }

  /// Get network statistics
  Map<String, dynamic> getNetworkStatistics() {
    return {
      'config': _config.toMap(),
      'connectivity': {
        'type': _currentConnectivity.name,
        'wifiName': _currentWifiName,
        'wifiBSSID': _currentWifiBSSID,
        'localIp': _localIpAddress,
        'signalStrength': _signalStrength,
        'connectionSpeed': _connectionSpeed,
        'isConnected': _isConnected,
      },
      'wifi': {
        'availableNetworks': _availableNetworks.length,
        'savedNetworks': _savedNetworks.length,
        'isScanning': _isScanning,
      },
      'discovery': {
        'isDiscovering': _isDiscovering,
        'discoveredDevices': _discoveredDevices.length,
      },
      'sharing': {
        'isServerRunning': _isSharingServerRunning,
        'sharedFiles': _sharedFiles.length,
        'activeTransfers': _activeTransfers.length,
      },
      'hotspot': {
        'isEnabled': _isHotspotEnabled,
        'config': _hotspotConfig.toMap(),
      },
      'performance': _performanceMetrics,
    };
  }

  /// Private methods
  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.location,
      Permission.nearbyWifiDevices,
      Permission.accessWifiState,
      Permission.changeWifiState,
    ];

    for (final permission in permissions) {
      final status = await Permission.request(permission);
      if (!status.isGranted) {
        await _emitEvent(NetworkEvent.permissionDenied(permission.toString()));
      }
    }
  }

  Future<bool> _checkLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  Future<void> _startConnectivityMonitoring() async {
    Connectivity().onConnectivityChanged.listen((result) {
      _currentConnectivity = result;
      _updateConnectionInfo();
      notifyListeners();

      _emitEvent(NetworkEvent.connectivityChanged(result.name));
    });

    // Initial connectivity check
    _currentConnectivity = await Connectivity().checkConnectivity();
    await _updateConnectionInfo();
  }

  Future<void> _updateConnectionInfo() async {
    try {
      if (_currentConnectivity == ConnectivityResult.wifi) {
        _currentWifiName = await NetworkInfo().getWifiName();
        _currentWifiBSSID = await NetworkInfo().getWifiBSSID();
        _localIpAddress = await _getLocalIpAddress();

        // Simulate signal strength and speed
        _signalStrength = -50 + (DateTime.now().millisecond % 50);
        _connectionSpeed = 10.0 + (DateTime.now().millisecond % 90);

        _isConnected = _currentWifiName != null;
      } else {
        _isConnected = false;
        _currentWifiName = null;
        _currentWifiBSSID = null;
        _signalStrength = 0;
        _connectionSpeed = 0.0;
      }
    } catch (e) {
      await _emitEvent(
          NetworkEvent.error('Failed to update connection info: $e'));
    }
  }

  Future<String?> _getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
          includeLinkLocal: false, includeLoopback: false);

      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4) {
            return address.address;
          }
        }
      }
    } catch (e) {
      await _emitEvent(NetworkEvent.error('Failed to get local IP: $e'));
    }
    return null;
  }

  Future<void> _loadSavedNetworks() async {
    // In a real implementation, this would load from secure storage
    // For now, we'll use empty list
    _savedNetworks = [];
  }

  Future<void> _saveNetworks() async {
    // In a real implementation, this would save to secure storage
    // For now, we'll just emit an event
    await _emitEvent(NetworkEvent.networksSaved(_savedNetworks.length));
  }

  void _startPerformanceMonitoring() {
    Timer.periodic(Duration(seconds: 5), (_) {
      _updatePerformanceMetrics();
    });
  }

  void _updatePerformanceMetrics() {
    _performanceMetrics = {
      'lastUpdate': DateTime.now().toIso8601String(),
      'availableNetworks': _availableNetworks.length,
      'discoveredDevices': _discoveredDevices.length,
      'sharedFiles': _sharedFiles.length,
      'activeTransfers': _activeTransfers.length,
      'connectionSpeed': _connectionSpeed,
      'signalStrength': _signalStrength,
      'memoryUsage': _getMemoryUsage(),
      'cpuUsage': _getCpuUsage(),
    };

    _lastMetricsUpdate = DateTime.now();
  }

  double _getMemoryUsage() {
    // Simulate memory usage
    return 50.0 + (DateTime.now().millisecond % 30);
  }

  double _getCpuUsage() {
    // Simulate CPU usage
    return 20.0 + (DateTime.now().millisecond % 40);
  }

  void _updateDeviceDiscovery() {
    // Update device discovery status
    if (_discoveredDevices.isNotEmpty) {
      final now = DateTime.now();
      _discoveredDevices.removeWhere(
          (device) => now.difference(device.lastSeen).inMinutes > 5);

      if (_discoveredDevices.length != _discoveredDevices.length) {
        notifyListeners();
      }
    }
  }

  DeviceType _mapDeviceType(DeviceType type) {
    switch (type) {
      case DeviceType.mobile:
        return DeviceType.mobile;
      case DeviceType.desktop:
        return DeviceType.desktop;
      case DeviceType.tablet:
        return DeviceType.tablet;
      case DeviceType.server:
        return DeviceType.server;
      case DeviceType.unknown:
        return DeviceType.unknown;
    }
  }

  Future<void> _emitEvent(NetworkEvent event) async {
    _eventController.add(event);
  }

  @override
  void dispose() {
    _eventController.close();
    _discoveryTimer?.cancel();
    _sharingEngine.dispose();
    super.dispose();
  }
}

// Supporting Classes
class NetworkConfig {
  final int defaultPort;
  final bool enableAutoDiscovery;
  final bool enableQRCode;
  final bool enablePasswordProtection;
  final Duration sessionTimeout;
  final int maxConcurrentTransfers;
  final int maxFileSize;
  final Duration scanTimeout;
  final int maxSavedNetworks;

  const NetworkConfig({
    this.defaultPort = 8080,
    this.enableAutoDiscovery = true,
    this.enableQRCode = true,
    this.enablePasswordProtection = false,
    this.sessionTimeout = const Duration(hours: 1),
    this.maxConcurrentTransfers = 5,
    this.maxFileSize = 100 * 1024 * 1024, // 100MB
    this.scanTimeout = const Duration(seconds: 10),
    this.maxSavedNetworks = 20,
  });

  static const NetworkConfig defaultConfig = NetworkConfig();

  Map<String, dynamic> toMap() {
    return {
      'defaultPort': defaultPort,
      'enableAutoDiscovery': enableAutoDiscovery,
      'enableQRCode': enableQRCode,
      'enablePasswordProtection': enablePasswordProtection,
      'sessionTimeout': sessionTimeout.inMilliseconds,
      'maxConcurrentTransfers': maxConcurrentTransfers,
      'maxFileSize': maxFileSize,
      'scanTimeout': scanTimeout.inMilliseconds,
      'maxSavedNetworks': maxSavedNetworks,
    };
  }

  NetworkConfig copyWith({
    int? defaultPort,
    bool? enableAutoDiscovery,
    bool? enableQRCode,
    bool? enablePasswordProtection,
    Duration? sessionTimeout,
    int? maxConcurrentTransfers,
    int? maxFileSize,
    Duration? scanTimeout,
    int? maxSavedNetworks,
  }) {
    return NetworkConfig(
      defaultPort: defaultPort ?? this.defaultPort,
      enableAutoDiscovery: enableAutoDiscovery ?? this.enableAutoDiscovery,
      enableQRCode: enableQRCode ?? this.enableQRCode,
      enablePasswordProtection:
          enablePasswordProtection ?? this.enablePasswordProtection,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      maxConcurrentTransfers:
          maxConcurrentTransfers ?? this.maxConcurrentTransfers,
      maxFileSize: maxFileSize ?? this.maxFileSize,
      scanTimeout: scanTimeout ?? this.scanTimeout,
      maxSavedNetworks: maxSavedNetworks ?? this.maxSavedNetworks,
    );
  }
}

class HotspotConfig {
  final String ssid;
  final String password;
  final HotspotSecurity security;
  final int maxClients;
  final Duration timeout;

  const HotspotConfig({
    this.ssid = 'iSuite_Hotspot',
    this.password = 'isuite123',
    this.security = HotspotSecurity.wpa2,
    this.maxClients = 10,
    this.timeout = const Duration(hours: 2),
  });

  static const HotspotConfig defaultConfig = HotspotConfig();

  Map<String, dynamic> toMap() {
    return {
      'ssid': ssid,
      'password': password,
      'security': security.name,
      'maxClients': maxClients,
      'timeout': timeout.inMilliseconds,
    };
  }

  HotspotConfig copyWith({
    String? ssid,
    String? password,
    HotspotSecurity? security,
    int? maxClients,
    Duration? timeout,
  }) {
    return HotspotConfig(
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
      security: security ?? this.security,
      maxClients: maxClients ?? this.maxClients,
      timeout: timeout ?? this.timeout,
    );
  }
}

enum HotspotSecurity {
  open,
  wep,
  wpa,
  wpa2,
  wpa3,
}

enum NetworkEventType {
  initialized,
  configUpdated,
  connectivityChanged,
  networksScanned,
  connecting,
  connected,
  disconnecting,
  disconnected,
  permissionDenied,
  discoveryStarted,
  discoveryStopped,
  devicesDiscovered,
  sharingServerStarted,
  sharingServerStopped,
  fileShared,
  qrCodeGenerated,
  hotspotEnabled,
  hotspotDisabled,
  networksSaved,
  error,
}

class NetworkEvent {
  final NetworkEventType type;
  final String? message;
  final dynamic data;
  final DateTime timestamp;

  const NetworkEvent({
    required this.type,
    this.message,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  const NetworkEvent.initialized() : type = NetworkEventType.initialized;

  const NetworkEvent.configUpdated() : type = NetworkEventType.configUpdated;

  const NetworkEvent.connectivityChanged(String connectivity)
      : type = NetworkEventType.connectivityChanged,
        data = connectivity;

  const NetworkEvent.networksScanned(int count)
      : type = NetworkEventType.networksScanned,
        data = count;

  const NetworkEvent.connecting(String ssid)
      : type = NetworkEventType.connecting,
        data = ssid;

  const NetworkEvent.connected(String ssid)
      : type = NetworkEventType.connected,
        data = ssid;

  const NetworkEvent.disconnecting(String ssid)
      : type = NetworkEventType.disconnecting,
        data = ssid;

  const NetworkEvent.disconnected() : type = NetworkEventType.disconnected;

  const NetworkEvent.permissionDenied(String permission)
      : type = NetworkEventType.permissionDenied,
        data = permission;

  const NetworkEvent.discoveryStarted()
      : type = NetworkEventType.discoveryStarted;

  const NetworkEvent.discoveryStopped()
      : type = NetworkEventType.discoveryStopped;

  const NetworkEvent.devicesDiscovered(int count)
      : type = NetworkEventType.devicesDiscovered,
        data = count;

  const NetworkEvent.sharingServerStarted()
      : type = NetworkEventType.sharingServerStarted;

  const NetworkEvent.sharingServerStopped()
      : type = NetworkEventType.sharingServerStopped;

  const NetworkEvent.fileShared(String filePath)
      : type = NetworkEventType.fileShared,
        data = filePath;

  const NetworkEvent.qrCodeGenerated(String shareId)
      : type = NetworkEventType.qrCodeGenerated,
        data = shareId;

  const NetworkEvent.hotspotEnabled() : type = NetworkEventType.hotspotEnabled;

  const NetworkEvent.hotspotDisabled()
      : type = NetworkEventType.hotspotDisabled;

  const NetworkEvent.networksSaved(int count)
      : type = NetworkEventType.networksSaved,
        data = count;

  const NetworkEvent.error(String message)
      : type = NetworkEventType.error,
        message = message;
}
