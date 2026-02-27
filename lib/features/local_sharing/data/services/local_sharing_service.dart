import 'dart:async';
import 'dart:io';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:flutter/foundation.dart';
import '../../../core/config/central_config.dart';
import '../../domain/models/p2p_device.dart';
import '../../domain/models/transfer_progress.dart';

/// Local Sharing Service using Flutter P2P Connection
/// Provides device discovery, connection, and file transfer over local network
class LocalSharingService {
  static final LocalSharingService _instance = LocalSharingService._internal();
  factory LocalSharingService() => _instance;
  LocalSharingService._internal();

  final FlutterP2pConnection _p2pConnection = FlutterP2pConnection();
  final StreamController<List<P2pDevice>> _devicesController = StreamController<List<P2pDevice>>.broadcast();
  final StreamController<TransferProgress> _progressController = StreamController<TransferProgress>.broadcast();

  List<P2pDevice> _discoveredDevices = [];
  P2pDevice? _connectedDevice;

  // Parameterized settings from CentralConfig
  late int _discoveryTimeout;
  late int _connectionTimeout;
  late int _transferBufferSize;
  late bool _enableEncryption;

  Stream<List<P2pDevice>> get discoveredDevices => _devicesController.stream;
  Stream<TransferProgress> get transferProgress => _progressController.stream;
  P2pDevice? get connectedDevice => _connectedDevice;

  /// Initialize P2P connection
  Future<void> initialize() async {
    try {
      // Load parameterized settings from CentralConfig
      _discoveryTimeout = CentralConfig.instance.getParameter('sharing.discovery_timeout', defaultValue: 30000); // 30 seconds
      _connectionTimeout = CentralConfig.instance.getParameter('sharing.connection_timeout', defaultValue: 15000); // 15 seconds
      _transferBufferSize = CentralConfig.instance.getParameter('sharing.buffer_size', defaultValue: 8192); // 8KB
      _enableEncryption = CentralConfig.instance.getParameter('sharing.enable_encryption', defaultValue: true);

      await _p2pConnection.initialize();
      await _p2pConnection.registerWifiDirectModel(
        wifiDirectModel: WifiDirectModel(),
      );
      debugPrint('Local Sharing Service initialized with parameterized settings');
    } catch (e) {
      debugPrint('Failed to initialize P2P connection: $e');
      rethrow;
    }
  }

  /// Start device discovery
  Future<void> startDiscovery() async {
    try {
      _discoveredDevices.clear();
      _devicesController.add([]);

      await _p2pConnection.discoverDevices();
      debugPrint('Device discovery started');
    } catch (e) {
      debugPrint('Failed to start discovery: $e');
      rethrow;
    }
  }

  /// Stop device discovery
  Future<void> stopDiscovery() async {
    try {
      await _p2pConnection.stopDiscovery();
      debugPrint('Device discovery stopped');
    } catch (e) {
      debugPrint('Failed to stop discovery: $e');
    }
  }

  /// Connect to a device
  Future<void> connectToDevice(P2pDevice device) async {
    try {
      await _p2pConnection.connectToDevice(device);
      _connectedDevice = device;
      debugPrint('Connected to device: ${device.deviceName}');
    } catch (e) {
      debugPrint('Failed to connect to device: $e');
      rethrow;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    try {
      await _p2pConnection.disconnectFromDevice();
      _connectedDevice = null;
      debugPrint('Disconnected from device');
    } catch (e) {
      debugPrint('Failed to disconnect: $e');
    }
  }

  /// Send file to connected device
  Future<void> sendFile(String filePath) async {
    if (_connectedDevice == null) {
      throw Exception('No device connected');
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      await _p2pConnection.sendFile(file);
      debugPrint('File sent: $filePath');
    } catch (e) {
      debugPrint('Failed to send file: $e');
      rethrow;
    }
  }

  /// Receive file from connected device
  Future<void> receiveFile(String savePath) async {
    try {
      await _p2pConnection.receiveFile(savePath);
      debugPrint('File received and saved to: $savePath');
    } catch (e) {
      debugPrint('Failed to receive file: $e');
      rethrow;
    }
  }

  /// Get transfer progress
  Stream<double> getTransferProgress() {
    return _p2pConnection.getTransferProgress();
  }

  /// Dispose resources
  void dispose() {
    _devicesController.close();
    _progressController.close();
    _p2pConnection.unregisterWifiDirectModel();
  }
}
