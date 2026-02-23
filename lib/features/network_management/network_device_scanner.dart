import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ping_discover_network_forked/ping_discover_network_forked.dart';
import '../../core/central_config.dart';
import '../../core/logging/logging_service.dart';

/// Enhanced Network Device Scanner for WiFi and Local Network Discovery
/// Provides comprehensive device scanning and network management capabilities
class NetworkDeviceScanner {
  static final NetworkDeviceScanner _instance = NetworkDeviceScanner._internal();
  factory NetworkDeviceScanner() => _instance;
  NetworkDeviceScanner._internal();

  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();

  bool _isScanning = false;
  final StreamController<NetworkScanEvent> _scanEventController = StreamController.broadcast();

  Stream<NetworkScanEvent> get scanEvents => _scanEventController.stream;

  /// Enhanced network scan with performance optimizations
  Future<List<NetworkDevice>> startEnhancedNetworkScan({
    String? subnet,
    int port = 80,
    Duration timeout = const Duration(seconds: 2),
    int maxConcurrent = 10,
    int maxRetries = 2,
    bool includeOfflineDevices = false,
    bool useCache = true,
    Duration cacheValidity = const Duration(minutes: 5),
  }) async {
    if (_isScanning) {
      throw Exception('Scan already in progress');
    }

    _isScanning = true;
    final devices = <NetworkDevice>[];
    final failedIPs = <String>[];

    try {
      _logger.info('Starting enhanced network scan with performance optimizations', 'NetworkDeviceScanner');

      // Determine subnet if not provided
      final targetSubnet = subnet ?? await _getLocalSubnet();

      _emitScanEvent(NetworkScanEventType.started, message: 'Enhanced scanning subnet: $targetSubnet');

      // Check cache first if enabled
      if (useCache) {
        final cachedDevices = await _getCachedDevices(targetSubnet, cacheValidity);
        if (cachedDevices.isNotEmpty) {
          devices.addAll(cachedDevices);
          _emitScanEvent(NetworkScanEventType.cacheHit, devices: cachedDevices);
          
          // Still perform fresh scan in background for cache refresh
          unawaited(_performFreshScan(targetSubnet, port, timeout, maxConcurrent, maxRetries, includeOfflineDevices, devices, failedIPs));
          
          return devices;
        }
      }

      // Perform fresh scan
      await _performFreshScan(targetSubnet, port, timeout, maxConcurrent, maxRetries, includeOfflineDevices, devices, failedIPs);

      // Cache results if enabled
      if (useCache && devices.isNotEmpty) {
        await _cacheDevices(targetSubnet, devices);
      }

      _emitScanEvent(NetworkScanEventType.completed, devices: devices);

      _logger.info('Enhanced network scan completed. Found ${devices.length} devices, ${failedIPs.length} failed IPs', 'NetworkDeviceScanner');

    } catch (e, stackTrace) {
      _emitScanEvent(NetworkScanEventType.error, error: e.toString());
      _logger.error('Enhanced network scan failed', 'NetworkDeviceScanner', error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      _isScanning = false;
    }

    return devices;
  }

  /// Perform fresh network scan
  Future<void> _performFreshScan(
    String targetSubnet,
    int port,
    Duration timeout,
    int maxConcurrent,
    int maxRetries,
    bool includeOfflineDevices,
    List<NetworkDevice> devices,
    List<String> failedIPs,
  ) async {
    // Use ping_discover_network for device discovery with enhanced options
    final stream = NetworkAnalyzer.discover(
      targetSubnet,
      port,
      timeout: timeout,
    );

    final futures = <Future<void>>[];
    int concurrentCount = 0;
    final semaphore = _Semaphore(maxConcurrent); // Custom semaphore for concurrency control

    await for (final addr in stream) {
      await semaphore.acquire();
      
      final future = _scanDeviceWithRetry(addr.ip, maxRetries, includeOfflineDevices)
          .then((device) {
            if (device != null) {
              devices.add(device);
              _emitScanEvent(NetworkScanEventType.deviceFound, device: device);
            } else if (includeOfflineDevices) {
              final offlineDevice = NetworkDevice(
                ip: addr.ip,
                hostname: null,
                macAddress: null,
                deviceType: DeviceType.unknown,
                isReachable: false,
                lastSeen: DateTime.now(),
                services: [],
                metadata: {'status': 'offline'},
              );
              devices.add(offlineDevice);
              _emitScanEvent(NetworkScanEventType.deviceFound, device: offlineDevice);
            }
          })
          .catchError((error) {
            failedIPs.add(addr.ip);
            _logger.warning('Failed to scan device ${addr.ip}: $error', 'NetworkDeviceScanner');
          })
          .whenComplete(() => semaphore.release());

      futures.add(future);
      concurrentCount++;
    }

    // Wait for all remaining scans to complete
    await Future.wait(futures);

    // Additional discovery methods with performance optimizations
    final additionalDevices = await _performEnhancedDiscoveryOptimized(targetSubnet, includeOfflineDevices);
    devices.addAll(additionalDevices);
  }

  /// Perform enhanced discovery with optimizations
  Future<List<NetworkDevice>> _performEnhancedDiscoveryOptimized(String subnet, bool includeOffline) async {
    final devices = <NetworkDevice>[];

    // Parallel execution of discovery methods
    final futures = <Future<List<NetworkDevice>>>[];

    // ARP table scanning
    futures.add(_scanArpTableOptimized(includeOffline));

    // Neighbor discovery (if available)
    futures.add(_scanNeighborTableOptimized(includeOffline));

    // Additional optimized discovery methods can be added here

    final results = await Future.wait(futures);
    for (final deviceList in results) {
      devices.addAll(deviceList);
    }

    return devices;
  }

  /// Optimized ARP table scanning
  Future<List<NetworkDevice>> _scanArpTableOptimized(bool includeOffline) async {
    final devices = <NetworkDevice>[];

    try {
      final arpResult = await Process.run('arp', ['-a']).timeout(const Duration(seconds: 5));
      if (arpResult.exitCode == 0) {
        final arpOutput = arpResult.stdout as String;
        final arpDevices = _parseEnhancedArpTable(arpOutput, includeOffline);
        devices.addAll(arpDevices);
      }
    } catch (e) {
      // ARP scanning not available or timed out
    }

    return devices;
  }

  /// Optimized neighbor table scanning
  Future<List<NetworkDevice>> _scanNeighborTableOptimized(bool includeOffline) async {
    final devices = <NetworkDevice>[];

    try {
      final neighborResult = await Process.run('ip', ['neigh']).timeout(const Duration(seconds: 5));
      if (neighborResult.exitCode == 0) {
        final neighborOutput = neighborResult.stdout as String;
        final neighborDevices = _parseNeighborTable(neighborOutput, includeOffline);
        devices.addAll(neighborDevices);
      }
    } catch (e) {
      // Neighbor discovery not available or timed out
    }

    return devices;
  }

  /// Get cached devices
  Future<List<NetworkDevice>> _getCachedDevices(String subnet, Duration validity) async {
    // In a real implementation, this would check a persistent cache
    // For now, return empty list (no caching implemented)
    return [];
  }

  /// Cache devices
  Future<void> _cacheDevices(String subnet, List<NetworkDevice> devices) async {
    // In a real implementation, this would save to persistent storage
    // For now, this is a placeholder
  }

  /// Clear device cache
  Future<void> clearDeviceCache() async {
    // Clear any cached device information
    _logger.info('Device cache cleared', 'NetworkDeviceScanner');
  }

  /// Get scan statistics
  Map<String, dynamic> getScanStatistics() {
    return {
      'is_scanning': _isScanning,
      'scan_duration': _lastScanDuration?.inMilliseconds,
      'devices_found': _devicesFoundCount,
      'cache_hit_rate': _cacheHitRate,
    };
  }

  /// Custom semaphore for concurrency control
  class _Semaphore {
    final int _maxPermits;
    int _availablePermits;
    final List<Completer<void>> _waitQueue = [];

    _Semaphore(this._maxPermits) : _availablePermits = _maxPermits;

    Future<void> acquire() async {
      if (_availablePermits > 0) {
        _availablePermits--;
        return;
      }

      final completer = Completer<void>();
      _waitQueue.add(completer);
      await completer.future;
    }

    void release() {
      if (_waitQueue.isNotEmpty) {
        final completer = _waitQueue.removeAt(0);
        completer.complete();
      } else {
        _availablePermits++;
      }
    }
  }

  /// Scan device with retry logic
  Future<NetworkDevice?> _scanDeviceWithRetry(String ip, int maxRetries, bool includeOffline) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final device = await _createDeviceInfo(ip);
        if (device.isReachable) {
          return device;
        }
      } catch (e) {
        if (attempt == maxRetries) {
          if (includeOffline) {
            return NetworkDevice(
              ip: ip,
              hostname: null,
              macAddress: null,
              deviceType: DeviceType.unknown,
              isReachable: false,
              lastSeen: DateTime.now(),
              services: [],
              metadata: {'status': 'unreachable', 'error': e.toString()},
            );
          }
          rethrow;
        }
        // Wait before retry
        await Future.delayed(Duration(milliseconds: 100 * (attempt + 1)));
      }
    }
    return null;
  }

  /// Perform enhanced additional discovery
  Future<List<NetworkDevice>> _performEnhancedDiscovery(String subnet, bool includeOffline) async {
    final devices = <NetworkDevice>[];

    // Enhanced ARP table scanning
    try {
      final arpResult = await Process.run('arp', ['-a']);
      if (arpResult.exitCode == 0) {
        final arpOutput = arpResult.stdout as String;
        final arpDevices = _parseEnhancedArpTable(arpOutput, includeOffline);
        devices.addAll(arpDevices);
      }
    } catch (e) {
      // ARP scanning not available on this platform
    }

    // Network neighbor discovery (if available)
    try {
      final neighborResult = await Process.run('ip', ['neigh']);
      if (neighborResult.exitCode == 0) {
        final neighborOutput = neighborResult.stdout as String;
        final neighborDevices = _parseNeighborTable(neighborOutput, includeOffline);
        devices.addAll(neighborDevices);
      }
    } catch (e) {
      // Neighbor discovery not available
    }

    return devices;
  }

  /// Parse enhanced ARP table
  List<NetworkDevice> _parseEnhancedArpTable(String arpOutput, bool includeOffline) {
    final devices = <NetworkDevice>[];
    final lines = arpOutput.split('\n');

    for (final line in lines) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length >= 3) {
        final ip = parts[1].replaceAll('(', '').replaceAll(')', '');
        final mac = parts[2];

        if (_isValidIp(ip) && _isValidMac(mac)) {
          final device = NetworkDevice(
            ip: ip,
            hostname: null,
            macAddress: mac,
            deviceType: DeviceType.unknown,
            isReachable: true,
            lastSeen: DateTime.now(),
            services: [],
            metadata: {'source': 'arp', 'manufacturer': _getManufacturerFromMac(mac)},
          );
          devices.add(device);
        }
      }
    }

    return devices;
  }

  /// Parse neighbor table
  List<NetworkDevice> _parseNeighborTable(String neighborOutput, bool includeOffline) {
    final devices = <NetworkDevice>[];
    final lines = neighborOutput.split('\n');

    for (final line in lines) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length >= 5) {
        final ip = parts[0];
        final mac = parts[4];
        final status = parts[5];

        if (_isValidIp(ip) && _isValidMac(mac)) {
          final isReachable = status.toLowerCase() == 'reachable' || status.toLowerCase() == 'stale';
          
          if (isReachable || includeOffline) {
            final device = NetworkDevice(
              ip: ip,
              hostname: null,
              macAddress: mac,
              deviceType: DeviceType.unknown,
              isReachable: isReachable,
              lastSeen: DateTime.now(),
              services: [],
              metadata: {'source': 'neighbor', 'status': status, 'manufacturer': _getManufacturerFromMac(mac)},
            );
            devices.add(device);
          }
        }
      }
    }

    return devices;
  }

  /// Get local subnet for scanning
  Future<String> _getLocalSubnet() async {
    try {
      // Get network interfaces
      final interfaces = await NetworkInterface.list();

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            final ipParts = addr.address.split('.');
            return '${ipParts[0]}.${ipParts[1]}.${ipParts[2]}.0/24';
          }
        }
      }
    } catch (e) {
      _logger.warning('Failed to get local subnet: $e', 'NetworkDeviceScanner');
    }

    // Fallback to common subnet
    return '192.168.1.0/24';
  }

  /// Create device information from IP address
  Future<NetworkDevice> _createDeviceInfo(String ip) async {
    final device = NetworkDevice(
      ip: ip,
      hostname: await _resolveHostname(ip),
      macAddress: await _getMacAddress(ip),
      deviceType: await _identifyDeviceType(ip),
      isReachable: true,
      lastSeen: DateTime.now(),
      services: await _scanServices(ip),
      metadata: await _gatherDeviceMetadata(ip),
    );

    return device;
  }

  /// Resolve hostname from IP
  Future<String?> _resolveHostname(String ip) async {
    try {
      final addresses = await InternetAddress.lookup(ip);
      return addresses.isNotEmpty ? addresses.first.host : null;
    } catch (e) {
      return null;
    }
  }

  /// Get MAC address (platform dependent)
  Future<String?> _getMacAddress(String ip) async {
    // This is a simplified implementation
    // In a real app, you'd use platform-specific APIs
    return null; // Placeholder
  }

  /// Identify device type based on services and characteristics
  Future<DeviceType> _identifyDeviceType(String ip) async {
    final services = await _scanServices(ip);

    if (services.contains('http') || services.contains('https')) {
      return DeviceType.webServer;
    }
    if (services.contains('smb') || services.contains('netbios')) {
      return DeviceType.fileServer;
    }
    if (services.contains('ftp')) {
      return DeviceType.ftpServer;
    }
    if (services.contains('ssh')) {
      return DeviceType.linuxDevice;
    }

    return DeviceType.unknown;
  }

  /// Scan for open services on device
  Future<List<String>> _scanServices(String ip) async {
    final services = <String>[];

    // Common ports to check
    final ports = [21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 443, 445, 993, 995];

    for (final port in ports) {
      try {
        final socket = await Socket.connect(ip, port, timeout: Duration(milliseconds: 500));
        await socket.close();

        switch (port) {
          case 21: services.add('ftp'); break;
          case 22: services.add('ssh'); break;
          case 23: services.add('telnet'); break;
          case 25: services.add('smtp'); break;
          case 53: services.add('dns'); break;
          case 80: services.add('http'); break;
          case 110: services.add('pop3'); break;
          case 135: services.add('rpc'); break;
          case 139: services.add('netbios'); break;
          case 143: services.add('imap'); break;
          case 443: services.add('https'); break;
          case 445: services.add('smb'); break;
          case 993: services.add('imaps'); break;
          case 995: services.add('pop3s'); break;
        }
      } catch (e) {
        // Port not open
      }
    }

    return services;
  }

  /// Gather additional device metadata
  Future<Map<String, dynamic>> _gatherDeviceMetadata(String ip) async {
    final metadata = <String, dynamic>{};

    // Try to get device manufacturer from MAC address
    final mac = await _getMacAddress(ip);
    if (mac != null) {
      metadata['manufacturer'] = _getManufacturerFromMac(mac);
    }

    // Try to identify device model/name
    final hostname = await _resolveHostname(ip);
    if (hostname != null) {
      metadata['hostname'] = hostname;
    }

    return metadata;
  }

  /// Get manufacturer from MAC address
  String _getManufacturerFromMac(String mac) {
    // This is a simplified implementation
    // In a real app, you'd have a comprehensive MAC address database
    final oui = mac.substring(0, 8).toUpperCase();

    final manufacturers = {
      '00:50:56': 'VMware',
      '08:00:27': 'Oracle VirtualBox',
      '00:0C:29': 'VMware',
      '00:05:69': 'Apple',
      '00:17:F2': 'Apple',
      '00:0F:20': 'Hewlett-Packard',
      '00:50:F1': 'Microsoft',
      '00:0C:76': 'Cisco Systems',
      '00:0F:B0': 'Compal Electronics',
      '00:13:49': 'Dell',
    };

    return manufacturers[oui] ?? 'Unknown';
  }

  /// Perform additional discovery methods
  Future<List<NetworkDevice>> _performAdditionalDiscovery(String subnet) async {
    final devices = <NetworkDevice>[];

    // ARP table scanning (if available)
    try {
      final arpResult = await Process.run('arp', ['-a']);
      if (arpResult.exitCode == 0) {
        final arpOutput = arpResult.stdout as String;
        final arpDevices = _parseArpTable(arpOutput);
        devices.addAll(arpDevices);
      }
    } catch (e) {
      // ARP scanning not available on this platform
    }

    return devices;
  }

  /// Parse ARP table output
  List<NetworkDevice> _parseArpTable(String arpOutput) {
    final devices = <NetworkDevice>[];
    final lines = arpOutput.split('\n');

    for (final line in lines) {
      // Parse ARP table format (varies by platform)
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length >= 3) {
        final ip = parts[1];
        final mac = parts[2];

        if (_isValidIp(ip) && _isValidMac(mac)) {
          devices.add(NetworkDevice(
            ip: ip,
            hostname: null,
            macAddress: mac,
            deviceType: DeviceType.unknown,
            isReachable: true,
            lastSeen: DateTime.now(),
            services: [],
            metadata: {'source': 'arp'},
          ));
        }
      }
    }

    return devices;
  }

  /// Validate IP address
  bool _isValidIp(String ip) {
    final ipRegex = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
    return ipRegex.hasMatch(ip);
  }

  /// Validate MAC address
  bool _isValidMac(String mac) {
    final macRegex = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
    return macRegex.hasMatch(mac);
  }

  /// Emit scan event
  void _emitScanEvent(NetworkScanEventType type, {
    NetworkDevice? device,
    List<NetworkDevice>? devices,
    String? message,
    String? error,
  }) {
    final event = NetworkScanEvent(
      type: type,
      timestamp: DateTime.now(),
      device: device,
      devices: devices,
      message: message,
      error: error,
    );
    _scanEventController.add(event);
  }

  void dispose() {
    _scanEventController.close();
  }
}

/// Network Device Model
class NetworkDevice {
  final String ip;
  final String? hostname;
  final String? macAddress;
  final DeviceType deviceType;
  final bool isReachable;
  final DateTime lastSeen;
  final List<String> services;
  final Map<String, dynamic> metadata;

  const NetworkDevice({
    required this.ip,
    this.hostname,
    this.macAddress,
    required this.deviceType,
    required this.isReachable,
    required this.lastSeen,
    required this.services,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'ip': ip,
    'hostname': hostname,
    'macAddress': macAddress,
    'deviceType': deviceType.name,
    'isReachable': isReachable,
    'lastSeen': lastSeen.toIso8601String(),
    'services': services,
    'metadata': metadata,
  };

  factory NetworkDevice.fromJson(Map<String, dynamic> json) => NetworkDevice(
    ip: json['ip'],
    hostname: json['hostname'],
    macAddress: json['macAddress'],
    deviceType: DeviceType.values.firstWhere(
      (e) => e.name == json['deviceType'],
      orElse: () => DeviceType.unknown,
    ),
    isReachable: json['isReachable'] ?? false,
    lastSeen: DateTime.parse(json['lastSeen']),
    services: List<String>.from(json['services'] ?? []),
    metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
  );
}

/// Device Type Enum
enum DeviceType {
  unknown,
  computer,
  mobile,
  tablet,
  router,
  switch,
  printer,
  server,
  webServer,
  fileServer,
  ftpServer,
  linuxDevice,
  windowsDevice,
  macDevice,
  iotDevice,
  networkDevice,
}

/// Network Scan Event Types
enum NetworkScanEventType {
  started,
  deviceFound,
  progress,
  completed,
  error,
}

/// Network Scan Event
class NetworkScanEvent {
  final NetworkScanEventType type;
  final DateTime timestamp;
  final NetworkDevice? device;
  final List<NetworkDevice>? devices;
  final String? message;
  final String? error;

  NetworkScanEvent({
    required this.type,
    required this.timestamp,
    this.device,
    this.devices,
    this.message,
    this.error,
  });
}
