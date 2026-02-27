import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

/// Wrapper for P2P Device with additional metadata
class P2pDeviceInfo {
  final P2pDevice device;
  final bool isConnected;
  final DateTime discoveredAt;

  P2pDeviceInfo({
    required this.device,
    this.isConnected = false,
    DateTime? discoveredAt,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  String get deviceName => device.deviceName ?? 'Unknown Device';
  String get deviceAddress => device.deviceAddress ?? '';

  P2pDeviceInfo copyWith({
    P2pDevice? device,
    bool? isConnected,
    DateTime? discoveredAt,
  }) {
    return P2pDeviceInfo(
      device: device ?? this.device,
      isConnected: isConnected ?? this.isConnected,
      discoveredAt: discoveredAt ?? this.discoveredAt,
    );
  }
}
