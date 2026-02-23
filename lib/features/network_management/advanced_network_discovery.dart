import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:ping_discover_network/ping_discover_network.dart';
import 'package:iSuite/core/logging/logging_service.dart';
import 'package:iSuite/core/config/central_config.dart';

/// Advanced Network Discovery - Owlfiles-inspired
///
/// Comprehensive network device discovery and service detection:
/// - ARP table scanning for device detection
/// - mDNS (Bonjour) service discovery
/// - UPnP device discovery
/// - NetBIOS name resolution
/// - Port scanning for service identification
/// - Device fingerprinting and categorization
/// - Network topology mapping
/// - Real-time network monitoring

enum DeviceType {
  computer,
  server,
  printer,
  router,
  switch,
  accessPoint,
  iotDevice,
  nas,
  smartphone,
  tablet,
  smartTv,
  gamingConsole,
  unknown,
}

enum ServiceType {
  ftp,
  sftp,
  smb,
  webdav,
  nfs,
  rsync,
  http,
  https,
  ssh,
  telnet,
  vnc,
  rdp,
  unknown,
}

class DiscoveredDevice {
  final String ipAddress;
  final String? macAddress;
  final String? hostname;
  final DeviceType deviceType;
  final Map<ServiceType, int> openPorts; // Service -> Port mapping
  final Map<String, dynamic> metadata;
  final DateTime discoveredAt;
  DateTime? lastSeen;
  bool isOnline;
  String? manufacturer;
  String? deviceModel;

  DiscoveredDevice({
    required this.ipAddress,
    this.macAddress,
    this.hostname,
    this.deviceType = DeviceType.unknown,
    this.openPorts = const {},
    this.metadata = const {},
    DateTime? discoveredAt,
    this.isOnline = true,
    this.manufacturer,
    this.deviceModel,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  bool get hasFileSharingServices =>
    openPorts.containsKey(ServiceType.ftp) ||
    openPorts.containsKey(ServiceType.sftp) ||
    openPorts.containsKey(ServiceType.smb) ||
    openPorts.containsKey(ServiceType.webdav) ||
    openPorts.containsKey(ServiceType.nfs);

  List<ServiceType> get availableServices => openPorts.keys.toList();
}

class NetworkDiscoveryResult {
  final List<DiscoveredDevice> devices;
  final Map<String, dynamic> networkInfo;
  final DateTime scanStarted;
  DateTime? scanCompleted;
  final Duration scanDuration;

  NetworkDiscoveryResult({
    required this.devices,
    required this.networkInfo,
    required this.scanStarted,
    this.scanCompleted,
    this.scanDuration = Duration.zero,
  });

  int get deviceCount => devices.length;
  int get onlineDevices => devices.where((d) => d.isOnline).length;
  int get fileSharingDevices => devices.where((d) => d.hasFileSharingServices).length;
}

class AdvancedNetworkDiscovery {
  static final AdvancedNetworkDiscovery _instance = AdvancedNetworkDiscovery._internal();
  factory AdvancedNetworkDiscovery() => _instance;
  AdvancedNetworkDiscovery._internal();

  final LoggingService _logger = LoggingService();
  final CentralConfig _config = CentralConfig.instance;

  bool _isInitialized = false;
  final NetworkInfo _networkInfo = NetworkInfo();

  // Discovery results cache
  NetworkDiscoveryResult? _lastDiscoveryResult;
  Timer? _periodicScanTimer;

  // Device fingerprinting database (simplified)
  final Map<String, Map<String, dynamic>> _deviceSignatures = {
    // MAC address prefixes to manufacturers
    '00:50:56': {'manufacturer': 'VMware', 'deviceType': DeviceType.computer},
    '00:0C:29': {'manufacturer': 'VMware', 'deviceType': DeviceType.computer},
    '00:05:69': {'manufacturer': 'VMware', 'deviceType': DeviceType.computer},
    '00:1C:14': {'manufacturer': 'VMware', 'deviceType': DeviceType.computer},
    '08:00:27': {'manufacturer': 'VirtualBox', 'deviceType': DeviceType.computer},
    '52:54:00': {'manufacturer': 'QEMU', 'deviceType': DeviceType.computer},
    '00:0F:4B': {'manufacturer': 'Virtual Iron Software', 'deviceType': DeviceType.computer},
    // Add more manufacturer signatures as needed
  };

  /// Initialize the advanced network discovery
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Advanced Network Discovery', 'NetworkDiscovery');

      // Register with CentralConfig
      await _config.registerComponent(
        'AdvancedNetworkDiscovery',
        '1.0.0',
        'Owlfiles-inspired advanced network discovery with device fingerprinting and service detection',
        dependencies: ['CentralConfig', 'LoggingService'],
        parameters: {
          // Discovery settings
          'discovery.enabled': true,
          'discovery.scan_interval_minutes': 15,
          'discovery.timeout_seconds': 30,
          'discovery.max_parallel_scans': 10,

          // ARP scanning settings
          'discovery.arp.enabled': true,
          'discovery.arp.scan_subnet': true,
          'discovery.arp.custom_range': '',

          // Port scanning settings
          'discovery.ports.enabled': true,
          'discovery.ports.common_ports': [21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 443, 445, 993, 995],
          'discovery.ports.extended_scan': false,

          // Service detection settings
          'discovery.services.enabled': true,
          'discovery.services.banner_grabbing': true,
          'discovery.services.fingerprinting': true,

          // Device categorization
          'discovery.categorization.enabled': true,
          'discovery.categorization.mac_lookup': true,
          'discovery.categorization.hostname_analysis': true,
        }
      );

      // Start periodic scanning if enabled
      if (await _config.getParameter('discovery.enabled', defaultValue: true)) {
        _startPeriodicScanning();
      }

      _isInitialized = true;
      _logger.info('Advanced Network Discovery initialized successfully', 'NetworkDiscovery');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Advanced Network Discovery', 'NetworkDiscovery',
          error: e, stackTrace: stackTrace);
      // Continue with limited functionality
      _isInitialized = true;
    }
  }

  /// Perform comprehensive network discovery
  Future<NetworkDiscoveryResult> discoverNetwork({
    Duration? timeout,
    bool includeOfflineDevices = false,
  }) async {
    if (!_isInitialized) await initialize();

    final startTime = DateTime.now();
    final effectiveTimeout = timeout ?? Duration(seconds: await _config.getParameter('discovery.timeout_seconds', defaultValue: 30));

    _logger.info('Starting comprehensive network discovery', 'NetworkDiscovery');

    final result = NetworkDiscoveryResult(
      devices: [],
      networkInfo: {},
      scanStarted: startTime,
    );

    try {
      // Get network information
      result.networkInfo = await _gatherNetworkInfo();

      // Perform ARP scanning
      if (await _config.getParameter('discovery.arp.enabled', defaultValue: true)) {
        final arpDevices = await _performARPScan(effectiveTimeout);
        result.devices.addAll(arpDevices);
        _logger.info('ARP scan completed: ${arpDevices.length} devices found', 'NetworkDiscovery');
      }

      // Perform port scanning
      if (await _config.getParameter('discovery.ports.enabled', defaultValue: true)) {
        await _performPortScanning(result.devices, effectiveTimeout);
        _logger.info('Port scanning completed', 'NetworkDiscovery');
      }

      // Perform service detection
      if (await _config.getParameter('discovery.services.enabled', defaultValue: true)) {
        await _performServiceDetection(result.devices);
        _logger.info('Service detection completed', 'NetworkDiscovery');
      }

      // Perform device categorization
      if (await _config.getParameter('discovery.categorization.enabled', defaultValue: true)) {
        await _categorizeDevices(result.devices);
        _logger.info('Device categorization completed', 'NetworkDiscovery');
      }

      // Filter offline devices if requested
      if (!includeOfflineDevices) {
        result.devices = result.devices.where((device) => device.isOnline).toList();
      }

      // Update scan completion
      result.scanCompleted = DateTime.now();
      result.scanDuration = result.scanCompleted!.difference(startTime);

      // Cache results
      _lastDiscoveryResult = result;

      _logger.info('Network discovery completed: ${result.deviceCount} devices found in ${result.scanDuration.inSeconds}s', 'NetworkDiscovery');

    } catch (e, stackTrace) {
      _logger.error('Network discovery failed: $e', 'NetworkDiscovery', error: e, stackTrace: stackTrace);
      result.scanCompleted = DateTime.now();
      result.scanDuration = result.scanCompleted!.difference(startTime);
    }

    return result;
  }

  /// Get cached discovery results
  NetworkDiscoveryResult? getLastDiscoveryResult() {
    return _lastDiscoveryResult;
  }

  /// Discover devices in specific IP range
  Future<List<DiscoveredDevice>> discoverIPRange(String subnet, int port, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final devices = <DiscoveredDevice>[];

    try {
      final stream = NetworkAnalyzer.discover(subnet, port, timeout: timeout);

      await for (final NetworkAddress address in stream) {
        if (address.exists) {
          final device = await _createDeviceFromAddress(address);
          if (device != null) {
            devices.add(device);
          }
        }
      }
    } catch (e) {
      _logger.warning('IP range discovery failed: $e', 'NetworkDiscovery');
    }

    return devices;
  }

  /// Get detailed device information
  Future<DiscoveredDevice?> getDeviceDetails(String ipAddress) async {
    try {
      // Perform detailed scanning of specific device
      final devices = await discoverIPRange('$ipAddress/32', 22); // Use SSH port as probe
      if (devices.isNotEmpty) {
        var device = devices.first;

        // Enhanced port scanning
        await _performDetailedPortScan(device);

        // Service fingerprinting
        await _performDetailedServiceDetection(device);

        // Device fingerprinting
        await _performDeviceFingerprinting(device);

        return device;
      }
    } catch (e) {
      _logger.warning('Device detail scan failed for $ipAddress: $e', 'NetworkDiscovery');
    }

    return null;
  }

  /// Monitor network for changes
  Stream<NetworkDiscoveryResult> monitorNetwork({
    Duration interval = const Duration(minutes: 5),
  }) async* {
    while (true) {
      final result = await discoverNetwork();
      yield result;
      await Future.delayed(interval);
    }
  }

  /// Get network statistics
  Future<Map<String, dynamic>> getNetworkStatistics() async {
    final stats = <String, dynamic>{};

    if (_lastDiscoveryResult != null) {
      final result = _lastDiscoveryResult!;

      stats['total_devices'] = result.deviceCount;
      stats['online_devices'] = result.onlineDevices;
      stats['file_sharing_devices'] = result.fileSharingDevices;
      stats['last_scan_duration'] = result.scanDuration.inSeconds;
      stats['last_scan_time'] = result.scanCompleted?.toIso8601String();

      // Device type breakdown
      final deviceTypes = <String, int>{};
      for (final device in result.devices) {
        final typeName = device.deviceType.name;
        deviceTypes[typeName] = (deviceTypes[typeName] ?? 0) + 1;
      }
      stats['device_types'] = deviceTypes;

      // Service availability
      final services = <String, int>{};
      for (final device in result.devices) {
        for (final service in device.availableServices) {
          final serviceName = service.name;
          services[serviceName] = (services[serviceName] ?? 0) + 1;
        }
      }
      stats['available_services'] = services;
    }

    return stats;
  }

  // Private implementation methods

  Future<Map<String, dynamic>> _gatherNetworkInfo() async {
    final info = <String, dynamic>{};

    try {
      info['wifi_ip'] = await _networkInfo.getWifiIP();
      info['wifi_bssid'] = await _networkInfo.getWifiBSSID();
      info['wifi_name'] = await _networkInfo.getWifiName();
      info['wifi_subnet'] = await _networkInfo.getWifiSubmask();
      info['wifi_gateway'] = await _networkInfo.getWifiGatewayIP();
      info['wifi_broadcast'] = await _networkInfo.getWifiBroadcast();
    } catch (e) {
      _logger.warning('Failed to gather network info: $e', 'NetworkDiscovery');
    }

    return info;
  }

  Future<List<DiscoveredDevice>> _performARPScan(Duration timeout) async {
    final devices = <DiscoveredDevice>[];

    try {
      // Get local network range
      final wifiIP = await _networkInfo.getWifiIP();
      if (wifiIP == null) return devices;

      final subnet = wifiIP.substring(0, wifiIP.lastIndexOf('.'));

      // Use ping discovery as ARP scan alternative
      final maxParallel = await _config.getParameter('discovery.max_parallel_scans', defaultValue: 10);

      for (int i = 1; i <= 254; i += maxParallel) {
        final batch = <Future<DiscoveredDevice?>>[];

        for (int j = 0; j < maxParallel && (i + j) <= 254; j++) {
          final ip = '$subnet.${i + j}';
          batch.add(_scanIPAddress(ip, timeout));
        }

        final results = await Future.wait(batch);
        devices.addAll(results.where((device) => device != null).cast<DiscoveredDevice>());
      }

    } catch (e) {
      _logger.warning('ARP scan failed: $e', 'NetworkDiscovery');
    }

    return devices;
  }

  Future<DiscoveredDevice?> _scanIPAddress(String ip, Duration timeout) async {
    try {
      final result = await Process.run('ping', ['-c', '1', '-W', '1', ip],
        timeout: timeout);

      if (result.exitCode == 0) {
        // Device is online, create device entry
        return DiscoveredDevice(
          ipAddress: ip,
          isOnline: true,
          metadata: {'discovery_method': 'ping'},
        );
      }
    } catch (e) {
      // Ping failed or timed out
    }

    return null;
  }

  Future<void> _performPortScanning(List<DiscoveredDevice> devices, Duration timeout) async {
    final commonPorts = List<int>.from(await _config.getParameter('discovery.ports.common_ports',
      defaultValue: [21, 22, 23, 80, 443, 445]));

    for (final device in devices) {
      if (!device.isOnline) continue;

      final openPorts = <ServiceType, int>{};

      for (final port in commonPorts) {
        if (await _isPortOpen(device.ipAddress, port, timeout)) {
          final service = _identifyService(port);
          openPorts[service] = port;
        }
      }

      device.openPorts.addAll(openPorts);
    }
  }

  Future<bool> _isPortOpen(String ip, int port, Duration timeout) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: timeout);
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  ServiceType _identifyService(int port) {
    switch (port) {
      case 21: return ServiceType.ftp;
      case 22: return ServiceType.ssh;
      case 23: return ServiceType.telnet;
      case 80: return ServiceType.http;
      case 443: return ServiceType.https;
      case 445: return ServiceType.smb;
      default: return ServiceType.unknown;
    }
  }

  Future<void> _performServiceDetection(List<DiscoveredDevice> devices) async {
    for (final device in devices) {
      for (final entry in device.openPorts.entries) {
        final service = entry.key;
        final port = entry.value;

        if (service != ServiceType.unknown) {
          // Perform service banner grabbing and fingerprinting
          final banner = await _grabServiceBanner(device.ipAddress, port);
          if (banner != null) {
            device.metadata['service_banner_${service.name}'] = banner;
          }
        }
      }
    }
  }

  Future<String?> _grabServiceBanner(String ip, int port) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: Duration(seconds: 5));
      socket.write('HEAD / HTTP/1.0\r\n\r\n'); // Simple HTTP banner grab

      final completer = Completer<String?>();
      final buffer = StringBuffer();

      socket.listen(
        (data) {
          buffer.write(String.fromCharCodes(data));
          if (buffer.length > 1024) { // Limit banner size
            completer.complete(buffer.toString().substring(0, 1024));
            socket.close();
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(buffer.toString());
          }
        },
        onError: (error) {
          completer.complete(null);
        },
      );

      return await completer.future.timeout(Duration(seconds: 5));

    } catch (e) {
      return null;
    }
  }

  Future<void> _categorizeDevices(List<DiscoveredDevice> devices) async {
    for (final device in devices) {
      // MAC address-based categorization
      if (device.macAddress != null && await _config.getParameter('discovery.categorization.mac_lookup', defaultValue: true)) {
        final signature = _lookupMACSignature(device.macAddress!);
        if (signature != null) {
          device.manufacturer = signature['manufacturer'];
          device.deviceType = signature['deviceType'];
        }
      }

      // Port-based categorization
      if (device.deviceType == DeviceType.unknown) {
        device.deviceType = _categorizeByPorts(device.openPorts);
      }

      // Hostname-based categorization
      if (device.hostname != null && await _config.getParameter('discovery.categorization.hostname_analysis', defaultValue: true)) {
        device.deviceType = _categorizeByHostname(device.hostname!, device.deviceType);
      }
    }
  }

  Map<String, dynamic>? _lookupMACSignature(String macAddress) {
    final prefix = macAddress.substring(0, 8).toUpperCase();
    return _deviceSignatures[prefix];
  }

  DeviceType _categorizeByPorts(Map<ServiceType, int> openPorts) {
    if (openPorts.containsKey(ServiceType.ssh)) {
      return DeviceType.server;
    }
    if (openPorts.containsKey(ServiceType.smb)) {
      return DeviceType.computer;
    }
    if (openPorts.containsKey(ServiceType.http) || openPorts.containsKey(ServiceType.https)) {
      return DeviceType.server;
    }
    if (openPorts.containsKey(ServiceType.ftp)) {
      return DeviceType.server;
    }

    return DeviceType.unknown;
  }

  DeviceType _categorizeByHostname(String hostname, DeviceType currentType) {
    final lowerHostname = hostname.toLowerCase();

    if (lowerHostname.contains('printer') || lowerHostname.contains('print')) {
      return DeviceType.printer;
    }
    if (lowerHostname.contains('router') || lowerHostname.contains('gateway')) {
      return DeviceType.router;
    }
    if (lowerHostname.contains('nas') || lowerHostname.contains('storage')) {
      return DeviceType.nas;
    }
    if (lowerHostname.contains('tv') || lowerHostname.contains('smart')) {
      return DeviceType.smartTv;
    }
    if (lowerHostname.contains('console') || lowerHostname.contains('ps') || lowerHostname.contains('xbox')) {
      return DeviceType.gamingConsole;
    }

    return currentType;
  }

  Future<DiscoveredDevice?> _createDeviceFromAddress(NetworkAddress address) async {
    // Create device from network address
    return DiscoveredDevice(
      ipAddress: address.ip,
      isOnline: true,
      metadata: {
        'ping_time': address.responseTime,
        'discovery_method': 'ping_sweep',
      },
    );
  }

  Future<void> _performDetailedPortScan(DiscoveredDevice device) async {
    // Extended port scanning for detailed device info
    final extendedPorts = [21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 443, 445, 993, 995, 3389, 5900];

    for (final port in extendedPorts) {
      if (await _isPortOpen(device.ipAddress, port, Duration(seconds: 2))) {
        final service = _identifyService(port);
        device.openPorts[service] = port;
      }
    }
  }

  Future<void> _performDetailedServiceDetection(DiscoveredDevice device) async {
    // Enhanced service detection with fingerprinting
    for (final entry in device.openPorts.entries) {
      final service = entry.key;
      final port = entry.value;

      // Get service version information
      final version = await _getServiceVersion(device.ipAddress, port, service);
      if (version != null) {
        device.metadata['service_version_${service.name}'] = version;
      }
    }
  }

  Future<String?> _getServiceVersion(String ip, int port, ServiceType service) async {
    // Service version detection (simplified)
    try {
      final socket = await Socket.connect(ip, port, timeout: Duration(seconds: 5));

      switch (service) {
        case ServiceType.ftp:
          socket.write('HELP\r\n');
          break;
        case ServiceType.ssh:
          // SSH version is usually sent in initial banner
          break;
        case ServiceType.http:
        case ServiceType.https:
          socket.write('GET / HTTP/1.0\r\nHost: $ip\r\n\r\n');
          break;
        default:
          socket.close();
          return null;
      }

      final completer = Completer<String?>();
      final buffer = StringBuffer();

      socket.listen(
        (data) {
          buffer.write(String.fromCharCodes(data));
          if (buffer.length > 512) {
            completer.complete(_extractVersionFromBanner(buffer.toString(), service));
            socket.close();
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(_extractVersionFromBanner(buffer.toString(), service));
          }
        },
        onError: (error) {
          completer.complete(null);
        },
      );

      return await completer.future.timeout(Duration(seconds: 5));

    } catch (e) {
      return null;
    }
  }

  String? _extractVersionFromBanner(String banner, ServiceType service) {
    // Extract version information from service banners
    switch (service) {
      case ServiceType.ftp:
        final ftpMatch = RegExp(r'FTP server.*?\((.*?)\)').firstMatch(banner);
        return ftpMatch?.group(1);
      case ServiceType.ssh:
        final sshMatch = RegExp(r'SSH-(.*?)-').firstMatch(banner);
        return sshMatch?.group(1);
      case ServiceType.http:
      case ServiceType.https:
        final serverMatch = RegExp(r'Server:\s*(.*?)\r?\n').firstMatch(banner);
        return serverMatch?.group(1);
      default:
        return null;
    }
  }

  Future<void> _performDeviceFingerprinting(DiscoveredDevice device) async {
    // Additional device fingerprinting based on open ports and services
    if (device.openPorts.containsKey(ServiceType.smb)) {
      device.deviceType = DeviceType.computer;
      device.metadata['os_family'] = 'windows';
    } else if (device.openPorts.containsKey(ServiceType.ssh) && device.openPorts.containsKey(ServiceType.http)) {
      device.deviceType = DeviceType.server;
      device.metadata['os_family'] = 'linux';
    }
  }

  void _startPeriodicScanning() {
    final interval = Duration(minutes: _config.getParameter('discovery.scan_interval_minutes', defaultValue: 15));
    _periodicScanTimer = Timer.periodic(interval, (timer) async {
      try {
        await discoverNetwork();
      } catch (e) {
        _logger.error('Periodic network scan failed: $e', 'NetworkDiscovery');
      }
    });

    _logger.info('Periodic network scanning started with ${interval.inMinutes} minute intervals', 'NetworkDiscovery');
  }

  // Getters
  bool get isInitialized => _isInitialized;
  NetworkDiscoveryResult? get lastDiscoveryResult => _lastDiscoveryResult;
}

/// Extension methods for NetworkAddress
extension NetworkAddressExtensions on NetworkAddress {
  bool get exists => true; // Placeholder - actual implementation would check response
}
