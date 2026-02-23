import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../core/central_config.dart';
import '../../core/logging/logging_service.dart';

/// Enhanced File Sharing Service for Network Transfer
/// Provides secure file transfer capabilities across network devices
class FileSharingService {
  static final FileSharingService _instance = FileSharingService._internal();
  factory FileSharingService() => _instance;
  FileSharingService._internal();

  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();

  bool _isInitialized = false;
  final Map<String, TransferSession> _activeTransfers = {};
  final StreamController<FileTransferEvent> _transferEventController = StreamController.broadcast();

  Stream<FileTransferEvent> get transferEvents => _transferEventController.stream;

  /// Initialize file sharing service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing File Sharing Service', 'FileSharingService');

      // Register with CentralConfig
      await _config.registerComponent(
        'FileSharingService',
        '1.0.0',
        'Enhanced file sharing service for network transfers',
        parameters: {
          'transfer_chunk_size': 1024 * 1024, // 1MB
          'max_concurrent_transfers': 3,
          'transfer_timeout': 300, // 5 minutes
          'enable_compression': true,
          'enable_encryption': true,
        }
      );

      _isInitialized = true;
      _logger.info('File Sharing Service initialized successfully', 'FileSharingService');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize File Sharing Service', 'FileSharingService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Send file to network device
  Future<String> sendFile({
    required String filePath,
    required String targetIP,
    required int targetPort,
    String? targetPath,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) await initialize();

    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Source file does not exist: $filePath');
    }

    final fileSize = await file.length();
    final transferId = _generateTransferId();

    final session = TransferSession(
      id: transferId,
      filePath: filePath,
      fileName: file.basename,
      fileSize: fileSize,
      targetIP: targetIP,
      targetPort: targetPort,
      targetPath: targetPath,
      direction: TransferDirection.send,
      status: TransferStatus.preparing,
      metadata: metadata,
    );

    _activeTransfers[transferId] = session;
    _emitTransferEvent(TransferEventType.started, session: session);

    try {
      // Start transfer in background
      unawaited(_performFileTransfer(session));
      
      return transferId;
    } catch (e) {
      session.status = TransferStatus.failed;
      session.error = e.toString();
      _emitTransferEvent(TransferEventType.failed, session: session);
      throw e;
    }
  }

  /// Receive file from network device
  Future<String> receiveFile({
    required String savePath,
    required int listenPort,
    String? expectedFileName,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) await initialize();

    final transferId = _generateTransferId();

    final session = TransferSession(
      id: transferId,
      filePath: savePath,
      fileName: expectedFileName ?? 'received_file',
      targetPort: listenPort,
      direction: TransferDirection.receive,
      status: TransferStatus.preparing,
      metadata: metadata,
    );

    _activeTransfers[transferId] = session;
    _emitTransferEvent(TransferEventType.started, session: session);

    try {
      // Start receiver in background
      unawaited(_performFileReceive(session));
      
      return transferId;
    } catch (e) {
      session.status = TransferStatus.failed;
      session.error = e.toString();
      _emitTransferEvent(TransferEventType.failed, session: session);
      throw e;
    }
  }

  /// Perform file transfer
  Future<void> _performFileTransfer(TransferSession session) async {
    try {
      session.status = TransferStatus.connecting;
      _emitTransferEvent(TransferEventType.progress, session: session);

      final socket = await Socket.connect(session.targetIP!, session.targetPort!);
      
      session.status = TransferStatus.transferring;
      _emitTransferEvent(TransferEventType.progress, session: session);

      final file = File(session.filePath);
      final stream = file.openRead();
      final totalBytes = session.fileSize;
      int sentBytes = 0;

      // Send file metadata first
      final metadata = {
        'filename': session.fileName,
        'size': totalBytes,
        'targetPath': session.targetPath,
        'metadata': session.metadata,
      };
      
      final metadataJson = json.encode(metadata);
      socket.write('${metadataJson.length}\n$metadataJson');

      await for (final chunk in stream) {
        socket.add(chunk);
        sentBytes += chunk.length;
        
        session.progress = sentBytes / totalBytes;
        _emitTransferEvent(TransferEventType.progress, session: session);

        // Check for transfer cancellation
        if (session.status == TransferStatus.cancelled) {
          socket.close();
          return;
        }
      }

      await socket.flush();
      await socket.close();

      session.status = TransferStatus.completed;
      _emitTransferEvent(TransferEventType.completed, session: session);

    } catch (e) {
      session.status = TransferStatus.failed;
      session.error = e.toString();
      _emitTransferEvent(TransferEventType.failed, session: session);
    } finally {
      _activeTransfers.remove(session.id);
    }
  }

  /// Perform file receive
  Future<void> _performFileReceive(TransferSession session) async {
    try {
      session.status = TransferStatus.connecting;
      _emitTransferEvent(TransferEventType.progress, session: session);

      final server = await ServerSocket.bind(InternetAddress.anyIPv4, session.targetPort!);
      
      session.status = TransferStatus.transferring;
      _emitTransferEvent(TransferEventType.progress, session: session);

      final socket = await server.first;
      server.close();

      // Read metadata
      final metadataLength = int.parse(await _readLine(socket));
      final metadataJson = await _readBytes(socket, metadataLength);
      final metadata = json.decode(utf8.decode(metadataJson));

      final filename = metadata['filename'] as String;
      final fileSize = metadata['size'] as int;
      final targetPath = metadata['targetPath'] as String?;

      final savePath = targetPath != null 
          ? '$session.filePath/$filename'
          : '${session.filePath}/$filename';

      final file = File(savePath);
      final sink = file.openWrite();
      
      int receivedBytes = 0;
      final buffer = Uint8List(64 * 1024); // 64KB buffer

      while (receivedBytes < fileSize) {
        final bytesRead = await socket.read(buffer);
        if (bytesRead == 0) break;

        sink.add(buffer.sublist(0, bytesRead));
        receivedBytes += bytesRead;
        
        session.progress = receivedBytes / fileSize;
        _emitTransferEvent(TransferEventType.progress, session: session);

        // Check for transfer cancellation
        if (session.status == TransferStatus.cancelled) {
          await sink.close();
          await file.delete();
          socket.close();
          return;
        }
      }

      await sink.close();
      await socket.close();

      session.status = TransferStatus.completed;
      session.filePath = savePath;
      session.fileSize = fileSize;
      _emitTransferEvent(TransferEventType.completed, session: session);

    } catch (e) {
      session.status = TransferStatus.failed;
      session.error = e.toString();
      _emitTransferEvent(TransferEventType.failed, session: session);
    } finally {
      _activeTransfers.remove(session.id);
    }
  }

  /// Cancel transfer
  Future<void> cancelTransfer(String transferId) async {
    final session = _activeTransfers[transferId];
    if (session != null) {
      session.status = TransferStatus.cancelled;
      _emitTransferEvent(TransferEventType.cancelled, session: session);
      _activeTransfers.remove(transferId);
    }
  }

  /// Get transfer status
  TransferSession? getTransferStatus(String transferId) {
    return _activeTransfers[transferId];
  }

  /// Get all active transfers
  List<TransferSession> getActiveTransfers() {
    return _activeTransfers.values.toList();
  }

  /// Generate unique transfer ID
  String _generateTransferId() {
    return 'transfer_${DateTime.now().millisecondsSinceEpoch}_${_activeTransfers.length}';
  }

  /// Read line from socket
  Future<String> _readLine(Socket socket) async {
    final buffer = StringBuffer();
    while (true) {
      final byte = await socket.first;
      if (byte == 10) break; // \n
      buffer.writeCharCode(byte);
    }
    return buffer.toString();
  }

  /// Read specific number of bytes from socket
  Future<Uint8List> _readBytes(Socket socket, int count) async {
    final buffer = Uint8List(count);
    int offset = 0;
    
    while (offset < count) {
      final chunk = await socket.read(count - offset);
      buffer.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    
    return buffer;
  }

  /// Emit transfer event
  void _emitTransferEvent(FileTransferEventType type, {TransferSession? session}) {
    final event = FileTransferEvent(
      type: type,
      timestamp: DateTime.now(),
      session: session,
    );
    _transferEventController.add(event);
  }

  void dispose() {
    _transferEventController.close();
    // Cancel all active transfers
    for (final session in _activeTransfers.values) {
      session.status = TransferStatus.cancelled;
    }
    _activeTransfers.clear();
  }
}

/// Transfer Session Model
class TransferSession {
  final String id;
  String filePath;
  String fileName;
  int fileSize;
  String? targetIP;
  int targetPort;
  String? targetPath;
  TransferDirection direction;
  TransferStatus status;
  double progress;
  String? error;
  Map<String, dynamic>? metadata;

  TransferSession({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    this.targetIP,
    required this.targetPort,
    this.targetPath,
    required this.direction,
    required this.status,
    this.progress = 0.0,
    this.error,
    this.metadata,
  });
}

/// Transfer Direction Enum
enum TransferDirection {
  send,
  receive,
}

/// Transfer Status Enum
enum TransferStatus {
  preparing,
  connecting,
  transferring,
  completed,
  failed,
  cancelled,
}

/// File Transfer Event Types
enum FileTransferEventType {
  started,
  progress,
  completed,
  failed,
  cancelled,
}

/// File Transfer Event
class FileTransferEvent {
  final FileTransferEventType type;
  final DateTime timestamp;
  final TransferSession? session;

  FileTransferEvent({
    required this.type,
    required this.timestamp,
    this.session,
  });
}
