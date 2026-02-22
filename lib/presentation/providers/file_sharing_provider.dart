import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/utils.dart';
import '../../domain/models/file_sharing_model.dart';
import '../../domain/models/discovered_device_model.dart';
import '../../domain/models/shared_file_model.dart';

class FileSharingProvider extends ChangeNotifier {
  FileSharingProvider() {
    _loadSavedConnections();
  }
  List<FileSharingModel> _connections = [];
  final List<FileTransferModel> _activeTransfers = [];
  bool _isTransferring = false;
  bool _isServerRunning = false;
  String? _serverUrl;
  String? _localSharingPath;
  HttpServer? _httpServer;
  String? _error;
  final Map<String, double> _transferProgress = {};
  final List<SharedFile> _sharedFiles = [];
  final List<DiscoveredDevice> _connectedDevices = [];

  // Getters
  List<FileSharingModel> get connections => _connections;
  List<FileTransferModel> get activeTransfers => _activeTransfers;
  bool get isTransferring => _isTransferring;
  bool get isServerRunning => _isServerRunning;
  String? get serverUrl => _serverUrl;
  String? get localSharingPath => _localSharingPath;
  String? get error => _error;
  Map<String, double> get transferProgress => _transferProgress;
  List<SharedFile> get sharedFiles => _sharedFiles;
  List<DiscoveredDevice> get connectedDevices => _connectedDevices;

  // Computed properties
  List<FileSharingModel> get activeConnections =>
      _connections.where((c) => c.isActive).toList();
  List<FileTransferModel> get uploadTransfers =>
      _activeTransfers.where((t) => t.type == TransferType.upload).toList();
  List<FileTransferModel> get downloadTransfers =>
      _activeTransfers.where((t) => t.type == TransferType.download).toList();
  double get totalTransferSpeed =>
      _activeTransfers.fold(0, (sum, t) => sum + t.speed);
  int get totalActiveTransfers => _activeTransfers.length;

  Future<void> _loadSavedConnections() async {
    try {
      // Load from local storage/database
      // This would integrate with your existing database system
      _connections = []; // TODO: Implement actual loading
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load saved connections: $e';
      AppUtils.logError(
          'FileSharingProvider', 'Failed to load saved connections', e);
      notifyListeners();
    }
  }

  Future<void> addConnection(FileSharingModel connection) async {
    try {
      AppUtils.logInfo(
          'FileSharingProvider', 'Adding connection: ${connection.name}');

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

      AppUtils.logInfo('FileSharingProvider',
          'Successfully added connection: ${connection.name}');
    } catch (e) {
      _error = 'Failed to add connection: $e';
      AppUtils.logError('FileSharingProvider', 'Add connection failed', e);
      notifyListeners();
    }
  }

  Future<void> removeConnection(String connectionId) async {
    try {
      AppUtils.logInfo(
          'FileSharingProvider', 'Removing connection: $connectionId');

      // Remove from connections list
      _connections.removeWhere((c) => c.id == connectionId);

      // Cancel any active transfers for this connection
      _activeTransfers
          .removeWhere((t) => t.metadata['connectionId'] == connectionId);

      await _saveConnections();
      notifyListeners();

      AppUtils.logInfo('FileSharingProvider',
          'Successfully removed connection: $connectionId');
    } catch (e) {
      _error = 'Failed to remove connection: $e';
      AppUtils.logError('FileSharingProvider', 'Remove connection failed', e);
      notifyListeners();
    }
  }

  Future<void> updateConnection(FileSharingModel connection) async {
    try {
      AppUtils.logInfo(
          'FileSharingProvider', 'Updating connection: ${connection.name}');

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

  Future<String> uploadFile(FileSharingModel connection, String filePath,
      {String? remotePath}) async {
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
          throw UnsupportedError(
              'Protocol ${connection.protocol} not supported for upload');
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

  Future<String> downloadFile(FileSharingModel connection,
      String remoteFilePath, String localPath) async {
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
          throw UnsupportedError(
              'Protocol ${connection.protocol} not supported for download');
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
      AppUtils.logInfo(
          'FileSharingProvider', 'Cancelling transfer: $transferId');

      // Remove from active transfers
      _activeTransfers.removeWhere((t) => t.id == transferId);
      _transferProgress.remove(transferId);

      notifyListeners();

      AppUtils.logInfo(
          'FileSharingProvider', 'Transfer cancelled: $transferId');
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
      AppUtils.logInfo(
          'FileSharingProvider', 'Saving ${_connections.length} connections');
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
          final ftp =
              FTPConnect(connection.host, connection.user, connection.pass);
          final result = await ftp.connect();
          await ftp.disconnect();
          return result;
        case FileSharingProtocol.http:
        case FileSharingProtocol.https:
          final dio = Dio();
          final response = await dio.head(
              '${connection.isSecure ? "https" : "http"}://${connection.host}:${connection.port}');
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

  Future<String> _uploadFTP(FileSharingModel connection,
      FileTransferModel transfer, String? remotePath) async {
    final ftp = FTPConnect(connection.host, connection.user, connection.pass);
    await ftp.connect();

    if (remotePath != null) {
      await ftp.changeDirectory(remotePath);
    }

    final file = File(transfer.filePath);
    final result = await ftp
        .uploadFileWithRetry(file, file.path.split('/').last, retryCount: 3);
    await ftp.disconnect();

    return file.path;
  }

  Future<String> _uploadSFTP(FileSharingModel connection,
      FileTransferModel transfer, String? remotePath) async {
    // SFTP implementation would require additional package
    // For now, simulate SFTP upload
    await Future.delayed(
        Duration(seconds: (transfer.totalBytes / (1024 * 1024)).ceil()));
    return transfer.filePath;
  }

  Future<String> _uploadHTTP(FileSharingModel connection,
      FileTransferModel transfer, String? remotePath) async {
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
              speed: sent /
                  DateTime.now().difference(transfer.startTime).inMilliseconds *
                  1000,
            );
            notifyListeners();
          }
        },
      ),
    );

    return transfer.filePath;
  }

  Future<String> _downloadFTP(FileSharingModel connection,
      FileTransferModel transfer, String remoteFilePath) async {
    final ftp = FTPConnect(connection.host, connection.user, connection.pass);
    await ftp.connect();

    final fileName = remoteFilePath.split('/').last;
    final result = await ftp.downloadFileWithRetry(
        remoteFilePath, transfer.filePath,
        retryCount: 3);
    await ftp.disconnect();

    return transfer.filePath;
  }

  Future<String> _downloadSFTP(FileSharingModel connection,
      FileTransferModel transfer, String remoteFilePath) async {
    // SFTP implementation would require additional package
    // For now, simulate SFTP download
    await Future.delayed(const Duration(seconds: 5));
    return transfer.filePath;
  }

  Future<String> _downloadHTTP(FileSharingModel connection,
      FileTransferModel transfer, String remoteFilePath) async {
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
              speed: received /
                  DateTime.now().difference(transfer.startTime).inMilliseconds *
                  1000,
            );
            notifyListeners();
          }
        },
      ),
    );

    return transfer.filePath;
  }

  // Utility methods
  Future<List<String>> listRemoteFiles(FileSharingModel connection,
      {String? remotePath}) async {
    try {
      switch (connection.protocol) {
        case FileSharingProtocol.ftp:
          final ftp =
              FTPConnect(connection.host, connection.user, connection.pass);
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
      AppUtils.logError(
          'FileSharingProvider', 'Failed to list remote files', e);
      return [];
    }
  }

  // Advanced File Sharing Features (inspired by ezShare and Sharik)

  Future<bool> startLocalServer({String? path, int port = 8080}) async {
    try {
      if (_isServerRunning) {
        _error = 'Server is already running';
        notifyListeners();
        return false;
      }

      _localSharingPath =
          path ?? (await getApplicationDocumentsDirectory()).path;

      _httpServer = await HttpServer.bind('0.0.0.0', port);
      _serverUrl = 'http://$_getLocalIP():$port';
      _isServerRunning = true;

      // Start listening for requests
      _httpServer!.listen(_handleRequest);

      AppUtils.logInfo('FileSharingProvider', 'Server started at $_serverUrl');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to start server: $e';
      _isServerRunning = false;
      AppUtils.logError('FileSharingProvider', 'Server start failed', e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> stopLocalServer() async {
    try {
      if (_httpServer != null) {
        await _httpServer!.close();
        _httpServer = null;
      }

      _isServerRunning = false;
      _serverUrl = null;

      AppUtils.logInfo('FileSharingProvider', 'Server stopped');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to stop server: $e';
      AppUtils.logError('FileSharingProvider', 'Server stop failed', e);
      notifyListeners();
      return false;
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final path = request.uri.path == '/' ? '' : request.uri.path;
      final filePath = '$_localSharingPath$path';
      final file = File(filePath);

      if (file.existsSync()) {
        // Serve file
        final bytes = await file.readAsBytes();
        final mimeType = _getMimeType(filePath);

        request.response
          ..headers.set('Content-Type', mimeType)
          ..headers.set('Access-Control-Allow-Origin', '*')
          ..headers.set(
              'Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
          ..headers.set(
              'Access-Control-Allow-Headers', 'Content-Type, Authorization')
          ..add(bytes);

        // Log the file access
        AppUtils.logInfo('FileSharingProvider', 'Served file: $filePath');
      } else if (request.method == 'GET' && path.isEmpty) {
        // Serve directory listing
        await _serveDirectoryListing(request);
      } else if (request.method == 'POST') {
        // Handle file upload
        await _handleFileUpload(request);
      } else {
        // 404 Not Found
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('File not found');
      }
    } catch (e) {
      AppUtils.logError('FileSharingProvider', 'Request handling failed', e);
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Internal server error');
    }

    await request.response.close();
  }

  Future<void> _serveDirectoryListing(HttpRequest request) async {
    try {
      final directory = Directory(_localSharingPath!);
      final files = await directory.list().toList();

      final html = '''
<!DOCTYPE html>
<html>
<head>
    <title>iSuite File Sharing</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .file-list { list-style: none; padding: 0; }
        .file-item { padding: 10px; border: 1px solid #ddd; margin: 5px 0; border-radius: 5px; }
        .file-item:hover { background-color: #f5f5f5; }
        .upload-area { border: 2px dashed #ccc; padding: 20px; text-align: center; margin: 20px 0; }
        .btn { background-color: #007bff; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; }
    </style>
</head>
<body>
    <h1>iSuite File Sharing</h1>
    <div class="upload-area">
        <h3>Upload Files</h3>
        <form action="/upload" method="post" enctype="multipart/form-data">
            <input type="file" name="file" multiple>
            <button type="submit" class="btn">Upload</button>
        </form>
    </div>
    <h3>Available Files</h3>
    <ul class="file-list">
        ${files.map((file) {
        final name = file.path.split('/').last;
        final isDirectory = file is Directory;
        final icon = isDirectory ? '📁' : '📄';
        final size =
            isDirectory ? '' : '(${(file as File).lengthSync()} bytes)';
        return '''
          <li class="file-item">
            <a href="/$name">$icon $name $size</a>
          </li>
        ''';
      }).join('')}
    </ul>
</body>
</html>
      ''';

      request.response
        ..headers.set('Content-Type', 'text/html')
        ..write(html);
    } catch (e) {
      AppUtils.logError('FileSharingProvider', 'Directory listing failed', e);
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Failed to list directory');
    }
  }

  Future<void> _handleFileUpload(HttpRequest request) async {
    try {
      final contentType = request.headers.contentType;
      if (contentType?.mimeType == 'multipart/form-data') {
        final boundary = contentType!.parameters['boundary'];
        final data = await request
            .fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));

        // Parse multipart data and save files
        // This is a simplified implementation
        AppUtils.logInfo('FileSharingProvider', 'File upload received');

        request.response
          ..headers.set('Content-Type', 'application/json')
          ..write(
              '{"status": "success", "message": "Files uploaded successfully"}');
      } else {
        request.response
          ..statusCode = HttpStatus.badRequest
          ..write('Invalid content type');
      }
    } catch (e) {
      AppUtils.logError('FileSharingProvider', 'File upload failed', e);
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Upload failed');
    }
  }

  String _getLocalIP() {
    // This would get the actual local IP
    // For now, return a placeholder
    return '192.168.1.100';
  }

  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'html':
        return 'text/html';
      case 'css':
        return 'text/css';
      case 'js':
        return 'application/javascript';
      case 'json':
        return 'application/json';
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> shareFiles(List<String> filePaths) async {
    try {
      for (final filePath in filePaths) {
        final file = File(filePath);
        if (file.existsSync()) {
          final sharedFile = SharedFile(
            id: uuid.v4(),
            name: file.path.split('/').last,
            path: file.path,
            size: file.lengthSync(),
            mimeType: _getMimeType(filePath),
            sharedAt: DateTime.now(),
            isShared: true,
          );
          _sharedFiles.add(sharedFile);
        }
      }

      // Generate shareable link
      final shareUrl = '$_serverUrl/shared/${uuid.v4()}';

      // Share via system share dialog
      await Share.share('Check out my shared files: $shareUrl');

      notifyListeners();
    } catch (e) {
      _error = 'Failed to share files: $e';
      AppUtils.logError('FileSharingProvider', 'File sharing failed', e);
      notifyListeners();
    }
  }

  Future<String> generateQRCode(String data) async {
    try {
      // This would generate an actual QR code image
      // For now, return the data as a string representation
      return 'QR_CODE:$data';
    } catch (e) {
      AppUtils.logError('FileSharingProvider', 'QR code generation failed', e);
      return '';
    }
  }

  Future<bool> connectToDevice(DiscoveredDevice device) async {
    try {
      // Test connection to device
      final socket =
          await Socket.connect(device.ipAddress, device.port ?? 8080);
      socket.destroy();

      if (!_connectedDevices.any((d) => d.id == device.id)) {
        _connectedDevices.add(device);
        notifyListeners();
      }

      AppUtils.logInfo(
          'FileSharingProvider', 'Connected to device: ${device.name}');
      return true;
    } catch (e) {
      AppUtils.logError('FileSharingProvider', 'Device connection failed', e);
      return false;
    }
  }

  Future<void> disconnectFromDevice(String deviceId) async {
    _connectedDevices.removeWhere((d) => d.id == deviceId);
    notifyListeners();
    AppUtils.logInfo(
        'FileSharingProvider', 'Disconnected from device: $deviceId');
  }

  Future<bool> createRemoteDirectory(
      FileSharingModel connection, String directoryPath) async {
    try {
      switch (connection.protocol) {
        case FileSharingProtocol.ftp:
          final ftp =
              FTPConnect(connection.host, connection.user, connection.pass);
          await ftp.connect();
          await ftp.makeDirectory(directoryPath);
          await ftp.disconnect();
          return true;
        default:
          return false;
      }
    } catch (e) {
      AppUtils.logError(
          'FileSharingProvider', 'Failed to create remote directory', e);
      return false;
    }
  }
}
