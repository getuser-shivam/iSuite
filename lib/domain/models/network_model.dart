import 'package:equatable/equatable.dart';

enum NetworkType {
  wifi,
  ethernet,
  cellular,
  bluetooth,
  vpn,
}

enum NetworkStatus {
  disconnected,
  connecting,
  connected,
  authenticating,
  error,
}

enum SecurityType {
  open,
  wep,
  wpa,
  wpa2,
  wpa3,
  enterprise,
}

enum ConnectionProtocol {
  ftp,
  sftp,
  http,
  https,
  smb,
  webdav,
}

class NetworkModel extends Equatable {
  final String id;
  final String ssid;
  final NetworkType type;
  final NetworkStatus status;
  final int signalStrength;
  final SecurityType securityType;
  final String? ipAddress;
  final String? gateway;
  final String? subnet;
  final String? dns;
  final DateTime? lastConnected;
  final bool isSaved;
  final Map<String, dynamic> metadata;
  final ConnectionProtocol? preferredProtocol;

  const NetworkModel({
    required this.id,
    required this.ssid,
    this.type = NetworkType.wifi,
    this.status = NetworkStatus.disconnected,
    this.signalStrength = 0,
    this.securityType = SecurityType.open,
    this.ipAddress,
    this.gateway,
    this.subnet,
    this.dns,
    this.lastConnected,
    this.isSaved = false,
    this.metadata = const {},
    this.preferredProtocol,
  });

  NetworkModel copyWith({
    String? id,
    String? ssid,
    NetworkType? type,
    NetworkStatus? status,
    int? signalStrength,
    SecurityType? securityType,
    String? ipAddress,
    String? gateway,
    String? subnet,
    String? dns,
    DateTime? lastConnected,
    bool? isSaved,
    Map<String, dynamic>? metadata,
    ConnectionProtocol? preferredProtocol,
  }) {
    return NetworkModel(
      id: id ?? this.id,
      ssid: ssid ?? this.ssid,
      type: type ?? this.type,
      status: status ?? this.status,
      signalStrength: signalStrength ?? this.signalStrength,
      securityType: securityType ?? this.securityType,
      ipAddress: ipAddress ?? this.ipAddress,
      gateway: gateway ?? this.gateway,
      subnet: subnet ?? this.subnet,
      dns: dns ?? this.dns,
      lastConnected: lastConnected ?? this.lastConnected,
      isSaved: isSaved ?? this.isSaved,
      metadata: metadata ?? this.metadata,
      preferredProtocol: preferredProtocol ?? this.preferredProtocol,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ssid': ssid,
      'type': type.name,
      'status': status.name,
      'signalStrength': signalStrength,
      'securityType': securityType.name,
      'ipAddress': ipAddress,
      'gateway': gateway,
      'subnet': subnet,
      'dns': dns,
      'lastConnected': lastConnected?.toIso8601String(),
      'isSaved': isSaved,
      'metadata': metadata,
      'preferredProtocol': preferredProtocol?.name,
    };
  }

  factory NetworkModel.fromJson(Map<String, dynamic> json) {
    return NetworkModel(
      id: json['id'] as String,
      ssid: json['ssid'] as String,
      type: NetworkType.values.firstWhere((t) => t.name == json['type']),
      status: NetworkStatus.values.firstWhere((s) => s.name == json['status']),
      signalStrength: json['signalStrength'] as int? ?? 0,
      securityType: SecurityType.values.firstWhere((s) => s.name == json['securityType']),
      ipAddress: json['ipAddress'] as String?,
      gateway: json['gateway'] as String?,
      subnet: json['subnet'] as String?,
      dns: json['dns'] as String?,
      lastConnected: json['lastConnected'] != null 
          ? DateTime.parse(json['lastConnected'] as String)
          : null,
      isSaved: json['isSaved'] as bool? ?? false,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      preferredProtocol: json['preferredProtocol'] != null 
          ? ConnectionProtocol.values.firstWhere((p) => p.name == json['preferredProtocol'])
          : null,
    );
  }

  // Computed properties
  bool get isConnected => status == NetworkStatus.connected;
  bool get canConnect => status != NetworkStatus.connecting && status != NetworkStatus.authenticating;
  bool get isSecure => securityType != SecurityType.open;
  String get signalStrengthText {
    if (signalStrength >= 80) return 'Excellent';
    if (signalStrength >= 60) return 'Good';
    if (signalStrength >= 40) return 'Fair';
    if (signalStrength >= 20) return 'Weak';
    return 'Very Weak';
  }
  String get securityText {
    switch (securityType) {
      case SecurityType.open:
        return 'Open';
      case SecurityType.wep:
        return 'WEP';
      case SecurityType.wpa:
        return 'WPA';
      case SecurityType.wpa2:
        return 'WPA2';
      case SecurityType.wpa3:
        return 'WPA3';
      case SecurityType.enterprise:
        return 'Enterprise';
    }
  }
  String get protocolText {
    switch (preferredProtocol) {
      case ConnectionProtocol.ftp:
        return 'FTP';
      case ConnectionProtocol.sftp:
        return 'SFTP';
      case ConnectionProtocol.http:
        return 'HTTP';
      case ConnectionProtocol.https:
        return 'HTTPS';
      case ConnectionProtocol.smb:
        return 'SMB';
      case ConnectionProtocol.webdav:
        return 'WebDAV';
      case null:
        return 'Auto';
    }
  }

  @override
  List<Object?> get props => [
        id,
        ssid,
        type,
        status,
        signalStrength,
        securityType,
        ipAddress,
        gateway,
        subnet,
        dns,
        lastConnected,
        isSaved,
        metadata,
        preferredProtocol,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NetworkModel &&
        other.id == id &&
        other.ssid == ssid &&
        other.type == type &&
        other.status == status &&
        other.signalStrength == signalStrength &&
        other.securityType == securityType &&
        other.ipAddress == ipAddress &&
        other.gateway == gateway &&
        other.subnet == subnet &&
        other.dns == dns &&
        other.lastConnected == lastConnected &&
        other.isSaved == isSaved &&
        other.metadata == metadata &&
        other.preferredProtocol == preferredProtocol;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      ssid,
      type,
      status,
      signalStrength,
      securityType,
      ipAddress,
      gateway,
      subnet,
      dns,
      lastConnected,
      isSaved,
      metadata,
      preferredProtocol,
    );
  }
}
