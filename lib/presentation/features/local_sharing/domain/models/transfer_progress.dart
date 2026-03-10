/// Transfer Progress Model for file sharing operations
class TransferProgress {
  final String fileName;
  final int fileSize;
  final int bytesTransferred;
  final double progress; // 0.0 to 1.0
  final TransferStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final String? errorMessage;

  TransferProgress({
    required this.fileName,
    required this.fileSize,
    required this.bytesTransferred,
    required this.progress,
    required this.status,
    required this.startTime,
    this.endTime,
    this.errorMessage,
  });

  double get percentage => progress * 100;

  Duration get elapsedTime => DateTime.now().difference(startTime);

  bool get isCompleted => status == TransferStatus.completed;
  bool get isFailed => status == TransferStatus.failed;
  bool get isInProgress => status == TransferStatus.inProgress;

  TransferProgress copyWith({
    String? fileName,
    int? fileSize,
    int? bytesTransferred,
    double? progress,
    TransferStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    String? errorMessage,
  }) {
    return TransferProgress(
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'TransferProgress(fileName: $fileName, progress: ${(progress * 100).toStringAsFixed(1)}%, status: $status)';
  }
}

enum TransferStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled,
}
