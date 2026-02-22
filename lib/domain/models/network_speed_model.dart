import 'package:equatable/equatable.dart';

class NetworkSpeed extends Equatable {
  final double downloadSpeed; // Mbps
  final double uploadSpeed; // Mbps
  final int latency; // milliseconds
  final DateTime testTime;
  final String? testServer;
  final Map<String, dynamic>? additionalMetrics;

  const NetworkSpeed({
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.latency,
    required this.testTime,
    this.testServer,
    this.additionalMetrics,
  });

  NetworkSpeed copyWith({
    double? downloadSpeed,
    double? uploadSpeed,
    int? latency,
    DateTime? testTime,
    String? testServer,
    Map<String, dynamic>? additionalMetrics,
  }) {
    return NetworkSpeed(
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      uploadSpeed: uploadSpeed ?? this.uploadSpeed,
      latency: latency ?? this.latency,
      testTime: testTime ?? this.testTime,
      testServer: testServer ?? this.testServer,
      additionalMetrics: additionalMetrics ?? this.additionalMetrics,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'downloadSpeed': downloadSpeed,
      'uploadSpeed': uploadSpeed,
      'latency': latency,
      'testTime': testTime.millisecondsSinceEpoch,
      'testServer': testServer,
      'additionalMetrics': additionalMetrics,
    };
  }

  factory NetworkSpeed.fromMap(Map<String, dynamic> map) {
    return NetworkSpeed(
      downloadSpeed: map['downloadSpeed']?.toDouble() ?? 0.0,
      uploadSpeed: map['uploadSpeed']?.toDouble() ?? 0.0,
      latency: map['latency'] ?? 0,
      testTime: DateTime.fromMillisecondsSinceEpoch(map['testTime']),
      testServer: map['testServer'],
      additionalMetrics: map['additionalMetrics'],
    );
  }

  // Computed properties
  bool get isExcellent =>
      downloadSpeed > 50 && uploadSpeed > 20 && latency < 20;
  bool get isGood => downloadSpeed > 25 && uploadSpeed > 10 && latency < 50;
  bool get isFair => downloadSpeed > 5 && uploadSpeed > 2 && latency < 100;
  bool get isPoor => !isFair;

  String get speedGrade {
    if (isExcellent) return 'Excellent';
    if (isGood) return 'Good';
    if (isFair) return 'Fair';
    return 'Poor';
  }

  String get downloadSpeedText => '${downloadSpeed.toStringAsFixed(1)} Mbps';
  String get uploadSpeedText => '${uploadSpeed.toStringAsFixed(1)} Mbps';
  String get latencyText => '${latency}ms';

  @override
  List<Object?> get props => [
        downloadSpeed,
        uploadSpeed,
        latency,
        testTime,
        testServer,
        additionalMetrics,
      ];

  @override
  String toString() {
    return 'NetworkSpeed(download: $downloadSpeedText, upload: $uploadSpeedText, latency: $latencyText)';
  }
}
