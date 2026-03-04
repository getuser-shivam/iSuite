import 'package:equatable/equatable.dart';

enum DeviceType {
  networkService,
  wifiDirect,
  bluetooth,
  hotspot,
  unknown,
}

class DiscoveredDevice extends Equatable {
  final String id;
  final String name;
  final String ipAddress;
  final int? port;
  final DeviceType type;
  final DateTime lastSeen;
  final Map<String, dynamic>? metadata;
  final bool? isOnline;
  final String? serviceName;
  final String? manufacturer;

  const DiscoveredDevice({
    required this.id,
    required this.name,
    required this.ipAddress,
    this.port,
    required this.type,
    required this.lastSeen,
    this.metadata,
    this.isOnline,
    this.serviceName,
    this.manufacturer,
  });

  DiscoveredDevice copyWith({
    String? id,
    String? name,
    String? ipAddress,
    int? port,
    DeviceType? type,
    DateTime? lastSeen,
    Map<String, dynamic>? metadata,
    bool? isOnline,
    String? serviceName,
    String? manufacturer,
  }) {
    return DiscoveredDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      type: type ?? this.type,
      lastSeen: lastSeen ?? this.lastSeen,
      metadata: metadata ?? this.metadata,
      isOnline: isOnline ?? this.isOnline,
      serviceName: serviceName ?? this.serviceName,
      manufacturer: manufacturer ?? this.manufacturer,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ipAddress': ipAddress,
      'port': port,
      'type': type.name,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'metadata': metadata,
      'isOnline': isOnline,
      'serviceName': serviceName,
      'manufacturer': manufacturer,
    };
  }

  factory DiscoveredDevice.fromMap(Map<String, dynamic> map) {
    return DiscoveredDevice(
      id: map['id'],
      name: map['name'],
      ipAddress: map['ipAddress'],
      port: map['port'],
      type: DeviceType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DeviceType.unknown,
      ),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(map['lastSeen']),
      metadata: map['metadata'],
      isOnline: map['isOnline'],
      serviceName: map['serviceName'],
      manufacturer: map['manufacturer'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        ipAddress,
        port,
        type,
        lastSeen,
        metadata,
        isOnline,
        serviceName,
        manufacturer,
      ];

  @override
  String toString() {
    return 'DiscoveredDevice(id: $id, name: $name, ipAddress: $ipAddress, type: $type)';
  }
}
