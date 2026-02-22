import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:ping_discover_network_forked/ping_discover_network_forked.dart';
import '../../../core/central_config.dart';
import '../../../core/logging/logging_service.dart';
import '../../../services/notifications/notification_service.dart';

/// Advanced Network Discovery Service - Inspired by Owlfiles and Seafile
class NetworkDiscoveryService {
  static final NetworkDiscoveryService _instance = NetworkDiscoveryService._internal();
  factory NetworkDiscoveryService() => _instance;
  NetworkDiscoveryService._internal();

  final LoggingService _logger = LoggingService();
  final Connectivity _connectivity = Connectivity();
  final NetworkInfo _networkInfo = NetworkInfo();

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  final StreamController<List<NetworkDevice>> _devicesController = StreamController<List<NetworkDevice>>.broadcast();
  final StreamController<NetworkStatus> _networkStatusController = StreamController<NetworkStatus>.broadcast();

  List<NetworkDevice> _discoveredDevices = [];
  bool _isScanning = false;
  Timer? _scanTimer;

  /// Initialize network discovery service
  Future<void> initialize() async {
    try {
      _logger.info('Initializing Network Discovery Service', 'NetworkDiscoveryService');

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
      );

      // Start initial network scan
      await _performNetworkScan();

      _logger.info('Network Discovery Service initialized successfully', 'NetworkDiscoveryService');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Network Discovery Service', 'NetworkDiscoveryService',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Get discovered devices stream
  Stream<List<NetworkDevice>> get devicesStream => _devicesController.stream;

  /// Get network status stream
  Stream<NetworkStatus> get networkStatusStream => _networkStatusController.stream;

  /// Get current discovered devices
  List<NetworkDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);

  /// Get current network status
  Future<NetworkStatus> getCurrentNetworkStatus() async {
    try {
      final wifiName = await _networkInfo.getWifiName();
      final wifiIP = await _networkInfo.getWifiIP();
      final wifiGateway = await _networkInfo.getWifiGatewayIP();

      return NetworkStatus(
        isConnected: wifiIP != null,
        wifiName: wifiName,
        localIP: wifiIP,
        gatewayIP: wifiGateway,
        subnet: _calculateSubnet(wifiIP),
      );
    } catch (e) {
      _logger.error('Failed to get network status', 'NetworkDiscoveryService', error: e);
      return NetworkStatus(isConnected: false);
    }
  }

  /// Perform network scan for devices
  Future<void> performNetworkScan() async {
    if (_isScanning) return;

    _isScanning = true;
    _logger.info('Starting network scan', 'NetworkDiscoveryService');

    try {
      await _performNetworkScan();
      _devicesController.add(_discoveredDevices);

      NotificationService().showFileOperationNotification(
        title: 'Network Scan Complete',
        body: 'Found ${_discoveredDevices.length} devices on network',
      );

    } catch (e, stackTrace) {
      _logger.error('Network scan failed', 'NetworkDiscoveryService', error: e, stackTrace: stackTrace);

      NotificationService().showFileOperationNotification(
        title: 'Network Scan Failed',
        body: 'Failed to scan network: $e',
      );
    } finally {
      _isScanning = false;
    }
  }

  /// Start continuous network monitoring
  void startContinuousMonitoring({Duration interval = const Duration(seconds: 30)}) {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(interval, (_) {
      if (!_isScanning) {
        performNetworkScan();
      }
    });
    _logger.info('Started continuous network monitoring', 'NetworkDiscoveryService');
  }

  /// Stop continuous network monitoring
  void stopContinuousMonitoring() {
    _scanTimer?.cancel();
    _scanTimer = null;
    _logger.info('Stopped continuous network monitoring', 'NetworkDiscoveryService');
  }

  /// Perform the actual network scan
  Future<void> _performNetworkScan() async {
    final status = await getCurrentNetworkStatus();
    _networkStatusController.add(status);

    if (!status.isConnected || status.subnet == null) {
      _logger.warning('No network connection or invalid subnet', 'NetworkDiscoveryService');
      return;
    }

    final discoveredDevices = <NetworkDevice>[];

    try {
      // Scan for devices using ping discovery
      final stream = NetworkAnalyzer.discover2(
        status.subnet!,
        80, // Default port to check
        timeout: const Duration(milliseconds: 500),
      );

      await for (final device in stream) {
        if (device.exists) {
          final networkDevice = await _createNetworkDevice(device.ip, status);
          if (networkDevice != null) {
            discoveredDevices.add(networkDevice);
          }
        }
      }

      // Sort devices by IP address for consistent ordering
      discoveredDevices.sort((a, b) => a.ipAddress.compareTo(b.ipAddress));

      _discoveredDevices = discoveredDevices;
      _logger.info('Network scan completed, found ${discoveredDevices.length} devices', 'NetworkDiscoveryService');

    } catch (e, stackTrace) {
      _logger.error('Error during network scan', 'NetworkDiscoveryService', error: e, stackTrace: stackTrace);
    }
  }

  /// Create network device from IP address
  Future<NetworkDevice?> _createNetworkDevice(String ip, NetworkStatus status) async {
    try {
      // Try to get hostname (reverse DNS lookup)
      String? hostname;
      try {
        final addresses = await InternetAddress.lookup(ip);
        if (addresses.isNotEmpty && addresses[0].host != ip) {
          hostname = addresses[0].host;
        }
      } catch (_) {
        // Hostname lookup failed, continue without hostname
      }

      // Determine device type based on IP and hostname
      final deviceType = _determineDeviceType(ip, hostname);

      // Check for common services
      final services = await _detectServices(ip);

      return NetworkDevice(
        ipAddress: ip,
        hostname: hostname,
        deviceType: deviceType,
        isReachable: true,
        lastSeen: DateTime.now(),
        services: services,
        macAddress: null, // Would need additional permissions/libraries
      );

    } catch (e) {
      _logger.debug('Failed to create network device for $ip: $e', 'NetworkDiscoveryService');
      return null;
    }
  }

  /// Determine device type based on IP and hostname
  DeviceType _determineDeviceType(String ip, String? hostname) {
    if (hostname != null) {
      final lowerHostname = hostname.toLowerCase();

      if (lowerHostname.contains('router') || lowerHostname.contains('gateway')) {
        return DeviceType.router;
      }
      if (lowerHostname.contains('nas') || lowerHostname.contains('storage')) {
        return DeviceType.nas;
      }
      if (lowerHostname.contains('printer') || lowerHostname.contains('print')) {
        return DeviceType.printer;
      }
      if (lowerHostname.contains('iphone') || lowerHostname.contains('ipad') ||
          lowerHostname.contains('android') || lowerHostname.contains('mobile')) {
        return DeviceType.mobile;
      }
      if (lowerHostname.contains('laptop') || lowerHostname.contains('desktop') ||
          lowerHostname.contains('pc') || lowerHostname.contains('mac')) {
        return DeviceType.computer;
      }
    }

    // Check IP ranges for common device types
    if (ip.startsWith('192.168.') || ip.startsWith('10.') || ip.startsWith('172.')) {
      return DeviceType.unknown; // Local network device
    }

    return DeviceType.unknown;
  }

  /// Detect common services running on the device
  Future<List<NetworkService>> _detectServices(String ip) async {
    final services = <NetworkService>[];

    // Common ports to check
    final ports = {
      21: 'FTP',
      22: 'SSH',
      23: 'Telnet',
      25: 'SMTP',
      53: 'DNS',
      80: 'HTTP',
      443: 'HTTPS',
      445: 'SMB',
      548: 'AFP',
      631: 'IPP',
      3689: 'DAAP',
      5353: 'mDNS',
      8000: 'HTTP Alt',
      8080: 'HTTP Proxy',
      8443: 'HTTPS Alt',
    };

    for (final entry in ports.entries) {
      try {
        final socket = await Socket.connect(ip, entry.key, timeout: const Duration(milliseconds: 200));
        await socket.close();

        services.add(NetworkService(
          name: entry.value,
          port: entry.key,
          type: _getServiceType(entry.key),
          isSecure: _isSecurePort(entry.key),
        ));
      } catch (_) {
        // Port not open, continue
      }
    }

    return services;
  }

  /// Get service type from port
  ServiceType _getServiceType(int port) {
    switch (port) {
      case 21:
      case 22:
        return ServiceType.fileSharing;
      case 80:
      case 443:
      case 8000:
      case 8080:
      case 8443:
        return ServiceType.web;
      case 25:
      case 53:
        return ServiceType.network;
      case 631:
        return ServiceType.printing;
      case 3689:
        return ServiceType.media;
      default:
        return ServiceType.other;
    }
  }

  /// Check if port uses secure connection
  bool _isSecurePort(int port) {
    return [22, 443, 8443].contains(port);
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(ConnectivityResult result) async {
    _logger.info('Connectivity changed: $result', 'NetworkDiscoveryService');

    if (result != ConnectivityResult.none) {
      // Network connected, perform scan
      await Future.delayed(const Duration(seconds: 2)); // Wait for connection to stabilize
      performNetworkScan();
    } else {
      // Network disconnected
      _discoveredDevices.clear();
      _devicesController.add([]);
    }
  }

  /// Calculate subnet from IP address
  String? _calculateSubnet(String? ip) {
    if (ip == null) return null;

    try {
      final parts = ip.split('.');
      if (parts.length == 4) {
        // Assume /24 subnet for local networks
        return '${parts[0]}.${parts[1]}.${parts[2]}.0/24';
      }
    } catch (_) {}

    return null;
  }

  /// Clean up resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _scanTimer?.cancel();
    _devicesController.close();
    _networkStatusController.close();
  }
}

/// Network device information
class NetworkDevice {
  final String ipAddress;
  final String? hostname;
  final DeviceType deviceType;
  final bool isReachable;
  final DateTime lastSeen;
  final List<NetworkService> services;
  final String? macAddress;

  NetworkDevice({
    required this.ipAddress,
    required this.hostname,
    required this.deviceType,
    required this.isReachable,
    required this.lastSeen,
    required this.services,
    this.macAddress,
  });

  String get displayName => hostname ?? ipAddress;
  bool get hasFileSharing => services.any((s) => s.type == ServiceType.fileSharing);
  bool get hasWebAccess => services.any((s) => s.type == ServiceType.web);
}

/// Device types
enum DeviceType {
  computer,
  mobile,
  router,
  nas,
  printer,
  server,
  unknown,
}

/// Network service information
class NetworkService {
  final String name;
  final int port;
  final ServiceType type;
  final bool isSecure;

  NetworkService({
    required this.name,
    required this.port,
    required this.type,
    required this.isSecure,
  });
}

/// Service types
enum ServiceType {
  fileSharing,
  web,
  network,
  printing,
  media,
  other,
}

/// Network status information
class NetworkStatus {
  final bool isConnected;
  final String? wifiName;
  final String? localIP;
  final String? gatewayIP;
  final String? subnet;

  NetworkStatus({
    required this.isConnected,
    this.wifiName,
    this.localIP,
    this.gatewayIP,
    this.subnet,
  });
}
