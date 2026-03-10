import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/local_sharing_service.dart';
import '../../domain/models/p2p_device.dart';
import '../../domain/models/transfer_progress.dart';

// Provider for Local Sharing Service
final localSharingServiceProvider = Provider<LocalSharingService>((ref) {
  return LocalSharingService();
});

// Provider for Local Sharing State
final localSharingProvider =
    StateNotifierProvider<LocalSharingNotifier, LocalSharingState>((ref) {
  final service = ref.watch(localSharingServiceProvider);
  return LocalSharingNotifier(service);
});

class LocalSharingState {
  final List<P2pDeviceInfo> discoveredDevices;
  final P2pDeviceInfo? connectedDevice;
  final TransferProgress? currentTransfer;
  final bool isDiscovering;
  final bool isConnected;
  final String? errorMessage;

  LocalSharingState({
    this.discoveredDevices = const [],
    this.connectedDevice,
    this.currentTransfer,
    this.isDiscovering = false,
    this.isConnected = false,
    this.errorMessage,
  });

  LocalSharingState copyWith({
    List<P2pDeviceInfo>? discoveredDevices,
    P2pDeviceInfo? connectedDevice,
    TransferProgress? currentTransfer,
    bool? isDiscovering,
    bool? isConnected,
    String? errorMessage,
  }) {
    return LocalSharingState(
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      currentTransfer: currentTransfer ?? this.currentTransfer,
      isDiscovering: isDiscovering ?? this.isDiscovering,
      isConnected: isConnected ?? this.isConnected,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LocalSharingNotifier extends StateNotifier<LocalSharingState> {
  final LocalSharingService _service;

  LocalSharingNotifier(this._service) : super(LocalSharingState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _service.initialize();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to initialize: $e');
    }
  }

  Future<void> startDiscovery() async {
    state = state.copyWith(isDiscovering: true, errorMessage: null);
    try {
      await _service.startDiscovery();
      // Listen to discovered devices stream
      _service.discoveredDevices.listen((devices) {
        final deviceInfos =
            devices.map((device) => P2pDeviceInfo(device: device)).toList();
        state = state.copyWith(discoveredDevices: deviceInfos);
      });
    } catch (e) {
      state = state.copyWith(
          isDiscovering: false, errorMessage: 'Failed to start discovery: $e');
    }
  }

  Future<void> stopDiscovery() async {
    state = state.copyWith(isDiscovering: false);
    try {
      await _service.stopDiscovery();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to stop discovery: $e');
    }
  }

  Future<void> connectToDevice(P2pDeviceInfo deviceInfo) async {
    try {
      await _service.connectToDevice(deviceInfo.device);
      final connectedDevice = deviceInfo.copyWith(isConnected: true);
      state = state.copyWith(
          connectedDevice: connectedDevice,
          isConnected: true,
          errorMessage: null);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to connect: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      await _service.disconnect();
      state = state.copyWith(connectedDevice: null, isConnected: false);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to disconnect: $e');
    }
  }

  Future<void> sendFile(String filePath) async {
    if (!state.isConnected) {
      state = state.copyWith(errorMessage: 'No device connected');
      return;
    }

    try {
      final fileName = filePath.split('/').last;
      final transfer = TransferProgress(
        fileName: fileName,
        fileSize: 0, // Will be updated
        bytesTransferred: 0,
        progress: 0.0,
        status: TransferStatus.inProgress,
        startTime: DateTime.now(),
      );

      state = state.copyWith(currentTransfer: transfer);

      await _service.sendFile(filePath);

      final completedTransfer = transfer.copyWith(
        progress: 1.0,
        status: TransferStatus.completed,
        endTime: DateTime.now(),
      );

      state = state.copyWith(currentTransfer: completedTransfer);
    } catch (e) {
      final failedTransfer = state.currentTransfer?.copyWith(
        status: TransferStatus.failed,
        errorMessage: e.toString(),
        endTime: DateTime.now(),
      );

      state = state.copyWith(
          currentTransfer: failedTransfer,
          errorMessage: 'Failed to send file: $e');
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
