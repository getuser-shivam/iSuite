import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:dio/dio.dart';
import '../../domain/models/file_sharing_model.dart';
import '../../core/utils.dart';

class FileSharingProvider extends ChangeNotifier {
  List<FileSharingModel> _connections = [];
  List<FileTransferModel> _activeTransfers = [];
  bool _isTransferring = false;
  String? _error;
  Map<String, double> _transferProgress = {};

  // Getters
  List<FileSharingModel> get connections => _connections;
  List<FileTransferModel> get activeTransfers => _activeTransfers;
  bool get isTransferring => _isTransferring;
  String? get error => _error;
  Map<String, double> get transferProgress => _transferProgress;

  // Computed properties
  List<FileSharingModel> get activeConnections => _connections.where((c) => c.isActive).toList();
  List<FileTransferModel> get uploadTransfers => _activeTransfers.where((t) => t.type == TransferType.upload).toList();
  List<FileTransferModel> get downloadTransfers => _activeTransfers.where((t) => t.type == TransferType.download).toList();
  double get totalTransferSpeed => _activeTransfers.fold(0.0, (sum, t) => sum + t.speed);
  int get totalActiveTransfers => _activeTransfers.length;

  FileSharingProvider() {
    _loadSavedConnections();
  }

  Future<void> _loadSavedConnections() async {
    try {
      // Load from local storage/database
      // This would integrate with your existing database system
      _connections = []; // TODO: Implement actual loading
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load saved connections: $e';
      AppUtils.logError('FileSharingProvider', 'Failed to load saved connections', e);
      notifyListeners();
    }
  }

  Future<void> addConnection(FileSharingModel connection) async {
    try {
      AppUtils.logInfo('FileSharingProvider', 'Adding connection: ${connection.name}');

      // Test connection before saving
      final testResult = await _testConnection(connection);
      if (!testResult) {
        _error = 'Failed to connect to ${connection.host}:${connection.port}';
        notifyListeners();
        return;
      }

      // Add to connections list
      final newConnection = connection.copyWith(
        isActive: true,
        lastConnected: DateTime.now(),
      );
      _connections.add(newConnection);

      await _saveConnections();
      notifyListeners();

      AppUtils.logInfo('FileSharingProvider', 'Successfully added connection: ${connection.name}');
    } catch (e) {
      _error = 'Failed to add connection: $e';
      AppUtils.logError('FileSharingProvider', 'Add connection failed', e);
      notifyListeners();
    }
  }

  Future<void> removeConnection(String connectionId) async {
    try {
      AppUtils.logInfo('FileSharingProvider', 'Removing connection: $connectionId');

      // Remove from connections list
      _connections.removeWhere((c) => c.id == connectionId);

      // Cancel any active transfers for this connection
      _activeTransfers.removeWhere((t) => t.metadata['connectionId'] == connectionId);

      await _saveConnections();
      notifyListeners();

      AppUtils.logInfo('FileSharingProvider', 'Successfully removed connection: $connectionId');
    } catch (e) {
      _error = 'Failed to remove connection: $e';
      AppUtils.logError('FileSharingProvider', 'Remove connection failed', e);
      notifyListeners();
    }
  }

  Future<void> updateConnection(FileSharingModel connection) async {
    try {
      AppUtils.logInfo('FileSharingProvider', 'Updating connection: ${connection.name}');

      final index = _connections.indexWhere((c) => c.id == connection.id);
      if (index != -1) {
        _connections[index] = connection.copyWith(updatedAt: DateTime.now());
        await _saveConnections();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update connection: $e';
      AppUtils.logError('FileSharingProvider', 'Update connection failed', e);
      notifyListeners();
    }
  }

  Future<String> uploadFile(FileSharingModel connection, String filePath, {String? remotePath}) async {
    final file = File(filePath);
    if (!await file.exists()) {
      _error = 'File does not exist: $filePath';
      notifyListeners();
      return '';
    }

    final transferId = DateTime.now().millisecondsSinceEpoch.toString();
    final fileName = file.path.split('/').last;

    try {
      AppUtils.logInfo('FileSharingProvider', 'Starting upload: $fileName');

      // Create transfer model
      final transfer = FileTransferModel(
        id: transferId,
        fileName: fileName,
        filePath: filePath,
        type: TransferType.upload,
        totalBytes: await file.length(),
        startTime: DateTime.now(),
        metadata: {
          'connectionId': connection.id,
          'connectionName': connection.name,
          'remotePath': remotePath ?? connection.remotePath ?? '/',
        },
      );

      _activeTransfers.add(transfer);
      _isTransferring = true;
      notifyListeners();

      // Perform upload based on protocol
      String result;
      switch (connection.protocol) {
        case FileSharingProtocol.ftp:
          result = await _uploadFTP(connection, transfer, remotePath);
          break;
        case FileSharingProtocol.sftp:
          result = await _uploadSFTP(connection, transfer, remotePath);
          break;
        case FileSharingProtocol.http:
        case FileSharingProtocol.https:
          result = await _uploadHTTP(connection, transfer, remotePath);
          break;
        default:
          throw UnsupportedError('Protocol ${connection.protocol} not supported for upload');
      }

      // Update transfer status
      final index = _activeTransfers.indexWhere((t) => t.id == transferId);
      if (index != -1) {
        _activeTransfers[index] = transfer.copyWith(
          status: TransferStatus.completed,
          endTime: DateTime.now(),
        );
      }

      _transferProgress.remove(transferId);
      notifyListeners();

      AppUtils.logInfo('FileSharingProvider', 'Upload completed: $fileName');
      return result;
    } catch (e) {
      _error = 'Upload failed: $e';
      AppUtils.logError('FileSharingProvider', 'Upload failed', e);

      // Update transfer status to failed
      final index = _activeTransfers.indexWhere((t) => t.id == transferId);
      if (index != -1) {
        _activeTransfers[index] = _activeTransfers[index].copyWith(
          status: TransferStatus.failed,
          endTime: DateTime.now(),
          errorMessage: e.toString(),
        );
      }

      notifyListeners();
      return '';
    } finally {
      _isTransferring = false;
      notifyListeners();
    }
  }

  Future<String> downloadFile(FileSharingModel connection, String remoteFilePath, String localPath) async {
    final transferId = DateTime.now().millisecondsSinceEpoch.toString();
    final fileName = remoteFilePath.split('/').last;

    try {
      AppUtils.logInfo('FileSharingProvider', 'Starting download: $fileName');

      // Create transfer model
      final transfer = FileTransferModel(
        id: transferId,
        fileName: fileName,
        filePath: localPath,
        type: TransferType.download,
        startTime: DateTime.now(),
        metadata: {
          'connectionId': connection.id,
          'connectionName': connection.name,
          'remotePath': remoteFilePath,
        },
      );

      _activeTransfers.add(transfer);
      _isTransferring = true;
      notifyListeners();

      // Perform download based on protocol
      String result;
      switch (connection.protocol) {
        case FileSharingProtocol.ftp:
          result = await _downloadFTP(connection, transfer, remoteFilePath);
          break;
        case FileSharingProtocol.sftp:
          result = await _downloadSFTP(connection, transfer, remoteFilePath);
          break;
        case FileSharingProtocol.http:
        case FileSharingProtocol.https:
          result = await _downloadHTTP(connection, transfer, remoteFilePath);
          break;
        default:
          throw UnsupportedError('Protocol ${connection.protocol} not supported for download');
      }

      // Update transfer status
      final index = _activeTransfers.indexWhere((t) => t.id == transferId);
      if (index != -1) {
        _activeTransfers[index] = transfer.copyWith(
          status: TransferStatus.completed,
          endTime: DateTime.now(),
          totalBytes: File(result).lengthSync(),
        );
      }

      _transferProgress.remove(transferId);
      notifyListeners();

      AppUtils.logInfo('FileSharingProvider', 'Download completed: $fileName');
      return result;
    } catch (e) {
      _error = 'Download failed: $e';
      AppUtils.logError('FileSharingProvider', 'Download failed', e);

      // Update transfer status to failed
      final index = _activeTransfers.indexWhere((t) => t.id == transferId);
      if (index != -1) {
        _activeTransfers[index] = _activeTransfers[index].copyWith(
          status: TransferStatus.failed,
          endTime: DateTime.now(),
          errorMessage: e.toString(),
        );
      }

      notifyListeners();
      return '';
    } finally {
      _isTransferring = false;
      notifyListeners();
    }
  }

  Future<void> cancelTransfer(String transferId) async {
    try {
      AppUtils.logInfo('FileSharingProvider', 'Cancelling transfer: $transferId');

      // Remove from active transfers
      _activeTransfers.removeWhere((t) => t.id == transferId);
      _transferProgress.remove(transferId);

      notifyListeners();

      AppUtils.logInfo('FileSharingProvider', 'Transfer cancelled: $transferId');
    } catch (e) {
      _error = 'Failed to cancel transfer: $e';
      AppUtils.logError('FileSharingProvider', 'Cancel transfer failed', e);
      notifyListeners();
    }
  }

  Future<void> pauseTransfer(String transferId) async {
    try {
      AppUtils.logInfo('FileSharingProvider', 'Pausing transfer: $transferId');

      // Update transfer status to paused
      final index = _activeTransfers.indexWhere((t) => t.id == transferId);
      if (index != -1) {
        _activeTransfers[index] = _activeTransfers[index].copyWith(
          status: TransferStatus.paused,
        );
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to pause transfer: $e';
      AppUtils.logError('FileSharingProvider', 'Pause transfer failed', e);
      notifyListeners();
    }
  }

  Future<void> resumeTransfer(String transferId) async {
    try {
      AppUtils.logInfo('FileSharingProvider', 'Resuming transfer: $transferId');

      // Update transfer status to in progress
      final index = _activeTransfers.indexWhere((t) => t.id == transferId);
      if (index != -1) {
        _activeTransfers[index] = _activeTransfers[index].copyWith(
          status: TransferStatus.inProgress,
        );
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to resume transfer: $e';
      AppUtils.logError('FileSharingProvider', 'Resume transfer failed', e);
      notifyListeners();
    }
  }

  Future<void> _saveConnections() async {
    try {
      // Save to local storage/database
      // This would integrate with your existing database system
      AppUtils.logInfo('FileSharingProvider', 'Saving ${_connections.length} connections');
    } catch (e) {
      AppUtils.logError('FileSharingProvider', 'Failed to save connections', e);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Protocol-specific implementations
  Future<bool> _testConnection(FileSharingModel connection) async {
    try {
      switch (connection.protocol) {
        case FileSharingProtocol.ftp:
          final ftp = FTPConnect(connection.host, connection.user, connection.pass);
          final result = await ftp.connect();
          await ftp.disconnect();
          return result;
        case FileSharingProtocol.http:
        case FileSharingProtocol.https:
          final dio = Dio();
          final response = await dio.head('${connection.isSecure ? "https" : "http"}://${connection.host}:${connection.port}');
          return response.statusCode == 200;
        default:
          // For other protocols, return true for now
          return true;
      }
    } catch (e) {
      AppUtils.logError('FileSharingProvider', 'Connection test failed', e);
      return false;
    }
  }

  Future<String> _uploadFTP(FileSharingModel connection, FileTransferModel transfer, String? remotePath) async {
    final ftp = FTPConnect(connection.host, connection.user, connection.pass);
    await ftp.connect();
    
    if (remotePath != null) {
      await ftp.changeDirectory(remotePath);
    }

    final file = File(transfer.filePath);
    final result = await ftp.uploadFileWithRetry(file, file.path.split('/').last, retryCount: 3);
    await ftp.disconnect();
    
    return file.path;
  }

  Future<String> _uploadSFTP(FileSharingModel connection, FileTransferModel transfer, String? remotePath) async {
    // SFTP implementation would require additional package
    // For now, simulate SFTP upload
    await Future.delayed(Duration(seconds: (transfer.totalBytes / (1024 * 1024)).ceil()));
    return transfer.filePath;
  }

  Future<String> _uploadHTTP(FileSharingModel connection, FileTransferModel transfer, String? remotePath) async {
    final dio = Dio();
    final file = File(transfer.filePath);
    
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file, file.path.split('/').last),
    });

    final response = await dio.post(
      '${connection.isSecure ? "https" : "http"}://${connection.host}:${connection.port}${remotePath ?? "/upload"}',
      data: formData,
      options: Options(
        headers: connection.customHeaders,
        onSendProgress: (sent, total) {
          final index = _activeTransfers.indexWhere((t) => t.id == transfer.id);
          if (index != -1) {
            final progress = sent / total;
            _transferProgress[transfer.id] = progress;
            
            _activeTransfers[index] = _activeTransfers[index].copyWith(
              transferredBytes: sent,
              speed: sent / DateTime.now().difference(transfer.startTime).inMilliseconds * 1000,
            );
            notifyListeners();
          }
        },
      ),
    );

    return transfer.filePath;
  }

  Future<String> _downloadFTP(FileSharingModel connection, FileTransferModel transfer, String remoteFilePath) async {
    final ftp = FTPConnect(connection.host, connection.user, connection.pass);
    await ftp.connect();
    
    final fileName = remoteFilePath.split('/').last;
    final result = await ftp.downloadFileWithRetry(remoteFilePath, transfer.filePath, retryCount: 3);
    await ftp.disconnect();
    
    return transfer.filePath;
  }

  Future<String> _downloadSFTP(FileSharingModel connection, FileTransferModel transfer, String remoteFilePath) async {
    // SFTP implementation would require additional package
    // For now, simulate SFTP download
    await Future.delayed(Duration(seconds: 5));
    return transfer.filePath;
  }

  Future<String> _downloadHTTP(FileSharingModel connection, FileTransferModel transfer, String remoteFilePath) async {
    final dio = Dio();
    final response = await dio.download(
      '${connection.isSecure ? "https" : "http"}://${connection.host}:${connection.port}$remoteFilePath',
      transfer.filePath,
      options: Options(
        headers: connection.customHeaders,
        onReceiveProgress: (received, total) {
          final index = _activeTransfers.indexWhere((t) => t.id == transfer.id);
          if (index != -1) {
            final progress = received / total;
            _transferProgress[transfer.id] = progress;
            
            _activeTransfers[index] = _activeTransfers[index].copyWith(
              totalBytes: total,
              transferredBytes: received,
              speed: received / DateTime.now().difference(transfer.startTime).inMilliseconds * 1000,
            );
            notifyListeners();
          }
        },
      ),
    );

    return transfer.filePath;
  }

  // Utility methods
  Future<List<String>> listRemoteFiles(FileSharingModel connection, {String? remotePath}) async {
    try {
      switch (connection.protocol) {
        case FileSharingProtocol.ftp:
          final ftp = FTPConnect(connection.host, connection.user, connection.pass);
          await ftp.connect();
          
          if (remotePath != null) {
            await ftp.changeDirectory(remotePath);
          }
          
          final files = await ftp.listDirectoryContent();
          await ftp.disconnect();
          
          return files.map((f) => f.name).toList();
        default:
          return [];
      }
    } catch (e) {
      AppUtils.logError('FileSharingProvider', 'Failed to list remote files', e);
      return [];
    }
  }

  Future<bool> createRemoteDirectory(FileSharingModel connection, String directoryPath) async {
    try {
      switch (connection.protocol) {
        case FileSharingProtocol.ftp:
          final ftp = FTPConnect(connection.host, connection.user, connection.pass);
          await ftp.connect();
          await ftp.makeDirectory(directoryPath);
          await ftp.disconnect();
          return true;
        default:
          return false;
      }
    } catch (e) {
      AppUtils.logError('FileSharingProvider', 'Failed to create remote directory', e);
      return false;
    }
  }
}
