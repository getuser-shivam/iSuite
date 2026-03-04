import 'package:flutter/material.dart';
import 'dart:async';
import '../config/central_config.dart';

/// Network Device model with enhanced features
class NetworkDevice {
  final String id;
  final String name;
  final String ip;
  final String mac;
  final String type;
  final String status;
  final DateTime lastSeen;
  final int? port;
  final List<String>? services;
  final Map<String, dynamic>? metadata;

  const NetworkDevice({
    required this.id,
    required this.name,
    required this.ip,
    required this.mac,
    required this.type,
    required this.status,
    required this.lastSeen,
    this.port,
    this.services,
    this.metadata,
  });

  NetworkDevice copyWith({
    String? id,
    String? name,
    String? ip,
    String? mac,
    String? type,
    String? status,
    DateTime? lastSeen,
    int? port,
    List<String>? services,
    Map<String, dynamic>? metadata,
  }) {
    return NetworkDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      ip: ip ?? this.ip,
      mac: mac ?? this.mac,
      type: type ?? this.type,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      port: port ?? this.port,
      services: services ?? this.services,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ip': ip,
      'mac': mac,
      'type': type,
      'status': status,
      'lastSeen': lastSeen.toIso8601String(),
      'port': port,
      'services': services,
      'metadata': metadata,
    };
  }

  factory NetworkDevice.fromJson(Map<String, dynamic> json) {
    return NetworkDevice(
      id: json['id'],
      name: json['name'],
      ip: json['ip'],
      mac: json['mac'],
      type: json['type'],
      status: json['status'],
      lastSeen: DateTime.parse(json['lastSeen']),
      port: json['port'],
      services: json['services']?.cast<String>(),
      metadata: json['metadata'],
    );
  }
}

/// Network Connection Info
class NetworkConnection {
  final String ssid;
  final String bssid;
  final int signalStrength;
  final String security;
  final String frequency;
  final DateTime lastConnected;

  const NetworkConnection({
    required this.ssid,
    required this.bssid,
    required this.signalStrength,
    required this.security,
    required this.frequency,
    required this.lastConnected,
  });
}

/// Network Provider - Manages network-related state and operations with central configuration
class NetworkProvider extends ChangeNotifier {
  final CentralConfig _config = CentralConfig.instance;

  // Centralized network parameters
  late bool _autoScanEnabled;
  late int _scanIntervalSeconds;
  late int _deviceTimeoutMinutes;
  late bool _enableDevicePersistence;
  late int _maxStoredDevices;
  late bool _enableServiceDiscovery;
  late List<String> _enabledProtocols;
  late Duration _connectionTimeout;
  late int _maxConcurrentScans;
  late bool _enableNetworkMonitoring;

  bool _isScanning = false;
  bool _isOnline = true;
  final List<NetworkDevice> _devices = [];
  final List<NetworkConnection> _connections = [];
  Timer? _scanTimer;
  Timer? _connectivityTimer;
  Timer? _monitoringTimer;

  bool _isInitialized = false;

  // Getters
  bool get isScanning => _isScanning;
  bool get isOnline => _isOnline;
  List<NetworkDevice> get devices => List.unmodifiable(_devices);
  List<NetworkConnection> get connections => List.unmodifiable(_connections);
  bool get isInitialized => _isInitialized;

  int get deviceCount => _devices.length;
  int get onlineDeviceCount =>
      _devices.where((d) => d.status == 'online').length;
  int get offlineDeviceCount =>
      _devices.where((d) => d.status == 'offline').length;

  NetworkProvider() {
    _initializeProvider();
  }

  /// Initialize provider with central configuration
  Future<void> _initializeProvider() async {
    try {
      // Initialize central config
      await _config.initialize();

      // Load all network parameters from central config
      await _loadNetworkParameters();

      _isInitialized = true;
      notifyListeners();

      // Set up parameter change listeners for hot reload
      _setupParameterListeners();

      // Start network monitoring if enabled
      if (_enableNetworkMonitoring) {
        _startConnectivityMonitoring();
      }

      // Load persisted devices if enabled
      if (_enableDevicePersistence) {
        await _loadPersistedDevices();
      }
    } catch (e) {
      debugPrint('NetworkProvider initialization error: $e');
      // Use fallback defaults
      _setFallbackDefaults();
    }
  }

  Future<void> _loadNetworkParameters() async {
    // Network scanning settings
    _autoScanEnabled =
        await _config.getParameter<bool>('network.auto_scan') ?? true;
    _scanIntervalSeconds =
        await _config.getParameter<int>('network.scan_interval_seconds') ??
            300; // 5 minutes
    _deviceTimeoutMinutes =
        await _config.getParameter<int>('network.device_timeout_minutes') ?? 30;
    _maxConcurrentScans =
        await _config.getParameter<int>('network.max_concurrent_scans') ?? 3;

    // Device management
    _enableDevicePersistence =
        await _config.getParameter<bool>('network.device_persistence') ?? true;
    _maxStoredDevices =
        await _config.getParameter<int>('network.max_stored_devices') ?? 100;

    // Service discovery
    _enableServiceDiscovery =
        await _config.getParameter<bool>('network.service_discovery') ?? true;
    final protocols =
        await _config.getParameter<List<dynamic>>('network.enabled_protocols');
    _enabledProtocols = protocols?.cast<String>() ?? ['SMB', 'FTP', 'WebDAV'];

    // Connection settings
    final timeoutMs =
        await _config.getParameter<int>('network.connection_timeout_ms') ??
            10000;
    _connectionTimeout = Duration(milliseconds: timeoutMs);

    // Monitoring
    _enableNetworkMonitoring =
        await _config.getParameter<bool>('network.monitoring_enabled') ?? true;
  }

  void _setFallbackDefaults() {
    _autoScanEnabled = true;
    _scanIntervalSeconds = 300;
    _deviceTimeoutMinutes = 30;
    _enableDevicePersistence = true;
    _maxStoredDevices = 100;
    _enableServiceDiscovery = true;
    _enabledProtocols = ['SMB', 'FTP', 'WebDAV'];
    _connectionTimeout = const Duration(seconds: 10);
    _maxConcurrentScans = 3;
    _enableNetworkMonitoring = true;
    _isInitialized = true;
  }

  /// Set up listeners for parameter changes
  void _setupParameterListeners() {
    _config.events.listen((event) {
      if (event.type == ConfigEventType.parameterChanged &&
          event.parameterKey?.startsWith('network.') == true) {
        _handleParameterChange(event.parameterKey!, event.newValue);
      }
    });
  }

  void _handleParameterChange(String key, dynamic value) {
    bool shouldNotify = true;

    switch (key) {
      case 'network.auto_scan':
        if (value is bool) {
          _autoScanEnabled = value;
          if (value && !_isScanning) {
            _startAutoScanIfEnabled();
          }
        }
        break;
      case 'network.scan_interval_seconds':
        if (value is int) {
          _scanIntervalSeconds = value;
        }
        break;
      case 'network.device_timeout_minutes':
        if (value is int) {
          _deviceTimeoutMinutes = value;
        }
        break;
      case 'network.device_persistence':
        if (value is bool) {
          _enableDevicePersistence = value;
        }
        break;
      case 'network.max_stored_devices':
        if (value is int) {
          _maxStoredDevices = value;
          _enforceMaxDevices();
        }
        break;
      case 'network.service_discovery':
        if (value is bool) {
          _enableServiceDiscovery = value;
        }
        break;
      case 'network.enabled_protocols':
        if (value is List) {
          _enabledProtocols = value.cast<String>();
        }
        break;
      case 'network.monitoring_enabled':
        if (value is bool) {
          _enableNetworkMonitoring = value;
          if (value) {
            _startConnectivityMonitoring();
          } else {
            _connectivityTimer?.cancel();
          }
        }
        break;
      default:
        shouldNotify = false;
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }

  void _enforceMaxDevices() {
    if (_devices.length > _maxStoredDevices) {
      final excess = _devices.length - _maxStoredDevices;
      _devices.removeRange(0, excess);
    }
  }

  void _startAutoScanIfEnabled() {
    if (_autoScanEnabled && !_isScanning) {
      // Start periodic scanning
      Timer.periodic(Duration(seconds: _scanIntervalSeconds), (timer) {
        if (_autoScanEnabled && !_isScanning) {
          startNetworkScan();
        }
      });
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _connectivityTimer?.cancel();
    _monitoringTimer?.cancel();
    _config.dispose();
    super.dispose();
  }

  /// Public methods for network operations
  void startNetworkScan() {
    if (_isScanning || !_isInitialized) return;

    _isScanning = true;
    notifyListeners();

    // Simulate network scanning with progress updates
    int progress = 0;
    _scanTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      progress += 10;
      if (progress >= 100) {
        _completeNetworkScan();
        timer.cancel();
      }
    });
  }

  void stopNetworkScan() {
    _scanTimer?.cancel();
    _isScanning = false;
    notifyListeners();
  }

  void _completeNetworkScan() {
    _isScanning = false;

    // Add some mock discovered devices (inspired by Owlfiles discovery)
    final mockDevices = [
      NetworkDevice(
        id: 'nas_001',
        name: 'Home NAS Server',
        ip: '192.168.1.10',
        mac: '00:11:22:33:44:55',
        type: 'nas',
        status: 'online',
        lastSeen: DateTime.now(),
        services: ['SMB', 'FTP', 'WebDAV'],
        metadata: {'storage': '4TB', 'free_space': '2.8TB'},
      ),
      NetworkDevice(
        id: 'laptop_001',
        name: 'Work Laptop',
        ip: '192.168.1.101',
        mac: 'AA:BB:CC:DD:EE:FF',
        type: 'computer',
        status: 'online',
        lastSeen: DateTime.now(),
        services: ['SMB', 'FTP'],
        metadata: {'os': 'Windows 11', 'hostname': 'DESKTOP-ABC123'},
      ),
      NetworkDevice(
        id: 'phone_001',
        name: 'Mobile Phone',
        ip: '192.168.1.102',
        mac: '11:22:33:44:55:66',
        type: 'mobile',
        status: 'online',
        lastSeen: DateTime.now(),
        services: ['FTP'],
        metadata: {'os': 'Android', 'version': '13'},
      ),
      NetworkDevice(
        id: 'printer_001',
        name: 'Network Printer',
        ip: '192.168.1.103',
        mac: 'DD:EE:FF:11:22:33',
        type: 'printer',
        status: 'offline',
        lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
        services: ['IPP', 'SMB'],
        metadata: {'model': 'HP LaserJet', 'status': 'paper_jam'},
      ),
    ];

    // Add new devices, update existing ones
    for (final device in mockDevices) {
      final existingIndex = _devices.indexWhere((d) => d.id == device.id);
      if (existingIndex >= 0) {
        _devices[existingIndex] = device;
      } else {
        _devices.add(device);
      }
    }

    // Enforce max devices limit
    _enforceMaxDevices();

    // Persist devices if enabled
    if (_enableDevicePersistence) {
      _persistDevices();
    }

    notifyListeners();
  }

  void refreshDeviceStatus() {
    for (int i = 0; i < _devices.length; i++) {
      // Simulate random status changes
      final isOnline = DateTime.now().millisecondsSinceEpoch % 2 == 0;
      _devices[i] = _devices[i].copyWith(
        status: isOnline ? 'online' : 'offline',
        lastSeen: DateTime.now(),
      );
    }

    // Clean up old offline devices
    _cleanupOldDevices();

    notifyListeners();
  }

  void _cleanupOldDevices() {
    final cutoffTime =
        DateTime.now().subtract(Duration(minutes: _deviceTimeoutMinutes));
    _devices.removeWhere((device) =>
        device.status == 'offline' && device.lastSeen.isBefore(cutoffTime));
  }

  void removeDevice(String deviceId) {
    _devices.removeWhere((device) => device.id == deviceId);
    if (_enableDevicePersistence) {
      _persistDevices();
    }
    notifyListeners();
  }

  void addDevice(NetworkDevice device) {
    _devices.add(device);
    _enforceMaxDevices();
    if (_enableDevicePersistence) {
      _persistDevices();
    }
    notifyListeners();
  }

  NetworkDevice? getDeviceById(String id) {
    try {
      return _devices.firstWhere((device) => device.id == id);
    } catch (e) {
      return null;
    }
  }

  List<NetworkDevice> getDevicesByType(String type) {
    return _devices.where((device) => device.type == type).toList();
  }

  List<NetworkDevice> getOnlineDevices() {
    return _devices.where((device) => device.status == 'online').toList();
  }

  List<NetworkDevice> getDevicesByService(String service) {
    return _devices
        .where((device) => device.services?.contains(service) ?? false)
        .toList();
  }

  void _startConnectivityMonitoring() {
    _connectivityTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      // Simulate connectivity checking
      _isOnline = true; // Assume always online for demo
      _checkDeviceConnectivity();
      notifyListeners();
    });
  }

  void _checkDeviceConnectivity() {
    // Simulate checking device connectivity
    for (int i = 0; i < _devices.length; i++) {
      // Randomly update some device statuses
      if (DateTime.now().millisecondsSinceEpoch % 5 == 0) {
        final isOnline = DateTime.now().millisecondsSinceEpoch % 2 == 0;
        _devices[i] = _devices[i].copyWith(
          status: isOnline ? 'online' : 'offline',
          lastSeen: DateTime.now(),
        );
      }
    }
  }

  void _loadMockDevices() {
    // Load some initial mock devices
    _devices.addAll([
      NetworkDevice(
        id: 'router',
        name: 'Home Router',
        ip: '192.168.1.1',
        mac: '00:11:22:33:44:55',
        type: 'router',
        status: 'online',
        lastSeen: DateTime.now(),
        services: ['DHCP', 'DNS', 'NAT'],
        metadata: {'model': 'AC1200', 'firmware': '1.2.3'},
      ),
    ]);
  }

  /// Persistence methods
  Future<void> _loadPersistedDevices() async {
    try {
      // In a real app, this would load from secure storage
      // For now, just initialize with mock data
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('Error loading persisted devices: $e');
    }
  }

  Future<void> _persistDevices() async {
    try {
      // In a real app, this would save to secure storage
      // For now, just simulate persistence
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (e) {
      debugPrint('Error persisting devices: $e');
    }
  }

  /// Network utility methods with central config
  Future<bool> pingDevice(String ip) async {
    // Use configured timeout
    await Future.delayed(_connectionTimeout ~/ 2);
    return true; // Mock success
  }

  Future<Map<String, dynamic>> getNetworkInfo() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'ip': '192.168.1.100',
      'subnet': '255.255.255.0',
      'gateway': '192.168.1.1',
      'dns': ['8.8.8.8', '8.8.4.4'],
      'mac': 'AA:BB:CC:DD:EE:FF',
    };
  }

  Future<List<String>> scanPorts(String ip,
      {int startPort = 1, int endPort = 1024}) async {
    // Use configured timeout
    await Future.delayed(_connectionTimeout);
    return ['22', '80', '443']; // Mock open ports
  }

  /// Update network settings via central config
  Future<void> updateNetworkSettings({
    bool? autoScan,
    int? scanInterval,
    bool? devicePersistence,
    int? maxDevices,
    bool? serviceDiscovery,
    List<String>? enabledProtocols,
  }) async {
    if (autoScan != null) {
      await _config.setParameter('network.auto_scan', autoScan);
    }
    if (scanInterval != null) {
      await _config.setParameter('network.scan_interval_seconds', scanInterval);
    }
    if (devicePersistence != null) {
      await _config.setParameter(
          'network.device_persistence', devicePersistence);
    }
    if (maxDevices != null) {
      await _config.setParameter('network.max_stored_devices', maxDevices);
    }
    if (serviceDiscovery != null) {
      await _config.setParameter('network.service_discovery', serviceDiscovery);
    }
    if (enabledProtocols != null) {
      await _config.setParameter('network.enabled_protocols', enabledProtocols);
    }
  }

  void clearDevices() {
    _devices.clear();
    if (_enableDevicePersistence) {
      _persistDevices();
    }
    notifyListeners();
  }

  void setOnlineStatus(bool online) {
    _isOnline = online;
    notifyListeners();
  }

  void updateDeviceStatus(String deviceId, String status) {
    final index = _devices.indexWhere((device) => device.id == deviceId);
    if (index >= 0) {
      _devices[index] = _devices[index].copyWith(
        status: status,
        lastSeen: DateTime.now(),
      );
      if (_enableDevicePersistence) {
        _persistDevices();
      }
      notifyListeners();
    }
  }

  void renameDevice(String deviceId, String newName) {
    final index = _devices.indexWhere((device) => device.id == deviceId);
    if (index >= 0) {
      _devices[index] = _devices[index].copyWith(name: newName);
      if (_enableDevicePersistence) {
        _persistDevices();
      }
      notifyListeners();
    }
  }

  /// Get network health status
  Map<String, dynamic> getNetworkHealthStatus() {
    return {
      'isInitialized': _isInitialized,
      'isOnline': _isOnline,
      'isScanning': _isScanning,
      'deviceCount': deviceCount,
      'onlineDevices': onlineDeviceCount,
      'offlineDevices': offlineDeviceCount,
      'autoScanEnabled': _autoScanEnabled,
      'serviceDiscoveryEnabled': _enableServiceDiscovery,
      'protocolsEnabled': _enabledProtocols,
      'monitoringEnabled': _enableNetworkMonitoring,
      'lastScanTime': DateTime.now().toIso8601String(), // Mock
    };
  }

  /// Export network configuration
  Map<String, dynamic> exportNetworkConfig() {
    return {
      'version': '2.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': {
        'autoScan': _autoScanEnabled,
        'scanInterval': _scanIntervalSeconds,
        'deviceTimeout': _deviceTimeoutMinutes,
        'devicePersistence': _enableDevicePersistence,
        'maxDevices': _maxStoredDevices,
        'serviceDiscovery': _enableServiceDiscovery,
        'enabledProtocols': _enabledProtocols,
        'connectionTimeoutMs': _connectionTimeout.inMilliseconds,
        'monitoringEnabled': _enableNetworkMonitoring,
      },
      'devices': _devices.map((d) => d.toJson()).toList(),
    };
  }

  /// Import network configuration
  Future<void> importNetworkConfig(Map<String, dynamic> config) async {
    try {
      final settings = config['settings'];
      if (settings != null) {
        await updateNetworkSettings(
          autoScan: settings['autoScan'],
          scanInterval: settings['scanInterval'],
          devicePersistence: settings['devicePersistence'],
          maxDevices: settings['maxDevices'],
          serviceDiscovery: settings['serviceDiscovery'],
          enabledProtocols: settings['enabledProtocols']?.cast<String>(),
        );
      }

      final devices = config['devices'] as List?;
      if (devices != null) {
        _devices.clear();
        for (final deviceData in devices) {
          final device = NetworkDevice.fromJson(deviceData);
          _devices.add(device);
        }
        _enforceMaxDevices();
        if (_enableDevicePersistence) {
          _persistDevices();
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error importing network config: $e');
    }
  }
}
