import 'package:flutter/material.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/central_config.dart';
import '../../../core/logging/logging_service.dart';
import '../../../core/security/security_manager.dart';

/// Enhanced transfer status enum with additional states
enum TransferStatus { 
  queued, 
  inProgress, 
  completed, 
  failed, 
  paused, 
  cancelled, 
  retrying,
  verifying 
}

/// Transfer priority levels
enum TransferPriority { low, normal, high, critical }

/// Enhanced transfer item model with additional metadata
class TransferItem {
  final String id;
  final String fileName;
  final String localPath;
  final String remotePath;
  final bool isUpload;
  final int fileSize;
  final DateTime createdAt;
  final TransferPriority priority;
  TransferStatus status;
  double progress;
  String? errorMessage;
  int retryCount;
  final int maxRetries;
  DateTime? lastAttempt;
  String? checksum;
  Map<String, dynamic>? metadata;

  TransferItem({
    required this.id,
    required this.fileName,
    required this.localPath,
    required this.remotePath,
    required this.isUpload,
    required this.fileSize,
    this.priority = TransferPriority.normal,
    this.status = TransferStatus.queued,
    this.progress = 0.0,
    this.errorMessage,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.metadata,
  }) : createdAt = DateTime.now();

  /// Copy with updated status
  TransferItem copyWith({
    TransferStatus? status,
    double? progress,
    String? errorMessage,
    int? retryCount,
    DateTime? lastAttempt,
    String? checksum,
  }) {
    return TransferItem(
      id: id,
      fileName: fileName,
      localPath: localPath,
      remotePath: remotePath,
      isUpload: isUpload,
      fileSize: fileSize,
      priority: priority,
      createdAt: createdAt,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      checksum: checksum ?? this.checksum,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get formatted file size
  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Get transfer speed (bytes per second)
  double? get transferSpeed {
    if (lastAttempt == null || progress == 0.0) return null;
    final elapsed = DateTime.now().difference(lastAttempt!).inMilliseconds;
    if (elapsed == 0) return null;
    return (fileSize * progress) / (elapsed / 1000);
  }

  /// Get formatted transfer speed
  String? get formattedTransferSpeed {
    final speed = transferSpeed;
    if (speed == null) return null;
    
    if (speed < 1024) return '${speed.toStringAsFixed(1)} B/s';
    if (speed < 1024 * 1024) return '${(speed / 1024).toStringAsFixed(1)} KB/s';
    if (speed < 1024 * 1024 * 1024) return '${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    return '${(speed / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB/s';
  }

  /// Check if transfer can be retried
  bool get canRetry => retryCount < maxRetries && status == TransferStatus.failed;

  /// Get estimated time remaining
  Duration? get estimatedTimeRemaining {
    final speed = transferSpeed;
    if (speed == null || speed <= 0) return null;
    final remainingBytes = fileSize * (1.0 - progress);
    return Duration(milliseconds: (remainingBytes / speed * 1000).round());
  }

  /// Get formatted time remaining
  String? get formattedTimeRemaining {
    final remaining = estimatedTimeRemaining;
    if (remaining == null) return null;
    
    if (remaining.inSeconds < 60) return '${remaining.inSeconds}s';
    if (remaining.inMinutes < 60) return '${remaining.inMinutes}m ${remaining.inSeconds % 60}s';
    return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
  }
}

class FtpClientScreen extends StatefulWidget {
  const FtpClientScreen({super.key});

  @override
  State<FtpClientScreen> createState() => _FtpClientScreenState();
}

class _FtpClientScreenState extends State<FtpClientScreen> {
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  FTPConnect? _ftpConnect;
  bool _isConnected = false;
  List<FTPEntry> _files = [];
  bool _isLoading = false;

  // Transfer queue
  List<TransferItem> _transferQueue = [];
  bool _isProcessingQueue = false;

  final CentralConfig _config = CentralConfig.instance;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with centralized parameters
    _hostController = TextEditingController(
      text: _config.getParameter('ftp.defaultHost', defaultValue: 'ftp.example.com')
    );
    _portController = TextEditingController(
      text: _config.getParameter('ftp.defaultPort', defaultValue: '21').toString()
    );
    _usernameController = TextEditingController(
      text: _config.getParameter('ftp.defaultUsername', defaultValue: 'anonymous')
    );
    _passwordController = TextEditingController(
      text: _config.getParameter('ftp.defaultPassword', defaultValue: '')
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() => _isLoading = true);

    try {
      _ftpConnect = FTPConnect(
        _hostController.text,
        port: int.parse(_portController.text),
        user: _usernameController.text,
        pass: _passwordController.text,
        timeout: _config.ftpTimeout,
      );

      await _ftpConnect!.connect();
      setState(() => _isConnected = true);
      await _listFiles();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disconnect() async {
    try {
      await _ftpConnect?.disconnect();
      setState(() {
        _isConnected = false;
        _files = [];
      });
    } catch (e) {
      print('Disconnect error: $e');
    }
  }

  void _addToQueue(TransferItem item) {
    setState(() {
      _transferQueue.add(item);
    });

    if (!_isProcessingQueue) {
      _processQueue();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.isUpload ? 'Upload' : 'Download'} added to queue: ${item.fileName}')),
    );
  }

  void _processQueue() async {
    if (_transferQueue.isEmpty || _ftpConnect == null || !_isConnected) {
      setState(() => _isProcessingQueue = false);
      return;
    }

    setState(() => _isProcessingQueue = true);

    // Find next queued item
    final nextItem = _transferQueue.firstWhere(
      (item) => item.status == TransferStatus.queued,
      orElse: () => _transferQueue.first,
    );

    if (nextItem.status != TransferStatus.queued) {
      setState(() => _isProcessingQueue = false);
      return;
    }

    // Process the item
    setState(() {
      nextItem.status = TransferStatus.inProgress;
    });

    try {
      if (nextItem.isUpload) {
        await _uploadFile(nextItem);
      } else {
        await _downloadFile(nextItem);
      }

      setState(() {
        nextItem.status = TransferStatus.completed;
        nextItem.progress = 1.0;
      });
    } catch (e) {
      setState(() {
        nextItem.status = TransferStatus.failed;
        nextItem.errorMessage = e.toString();
      });
    }

    // Continue processing queue
    _processQueue();
  }

  Future<void> _uploadFile(TransferItem item) async {
    final file = File(item.localPath);

    await _ftpConnect!.uploadFileWithProgress(
      item.localPath,
      sRemoteName: item.remotePath,
      onProgress: (progress) {
        setState(() {
          item.progress = progress / 100.0;
        });
      },
    );
  }

  Future<void> _downloadFile(TransferItem item) async {
    await _ftpConnect!.downloadFileWithProgress(
      item.remotePath,
      item.localPath,
      onProgress: (progress) {
        setState(() {
          item.progress = progress / 100.0;
        });
      },
    );
  }

  void _removeFromQueue(TransferItem item) {
    setState(() {
      _transferQueue.remove(item);
    });
  }

  void _retryTransfer(TransferItem item) {
    setState(() {
      item.status = TransferStatus.queued;
      item.progress = 0.0;
      item.errorMessage = null;
    });

    if (!_isProcessingQueue) {
      _processQueue();
    }
  }

  Future<void> _pickFileToUpload() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      final fileName = file.name;
      final localPath = file.path!;
      final remotePath = '/$fileName'; // Default to root

      final transferItem = TransferItem(
        fileName: fileName,
        localPath: localPath,
        remotePath: remotePath,
        isUpload: true,
        fileSize: file.size,
      );

      _addToQueue(transferItem);
    }
  }

  void _downloadSelectedFile(FTPEntry file) {
    // For demo, download to temp directory
    final localPath = '/tmp/${file.name}'; // This would be handled differently in real app

    final transferItem = TransferItem(
      fileName: file.name,
      localPath: localPath,
      remotePath: file.name,
      isUpload: false,
      fileSize: file.size ?? 0,
    );

    _addToQueue(transferItem);
  }

  Future<void> _uploadFile() async {
    if (!_isConnected || _ftpConnect == null) return;

    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null) {
        final file = result.files.single;
        await _ftpConnect!.uploadFile(file);
        await _listFiles(); // Refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  Future<void> _downloadFile(FTPEntry file) async {
    if (!_isConnected || _ftpConnect == null) return;

    try {
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save ${file.name}',
        fileName: file.name,
      );

      if (savePath != null) {
        await _ftpConnect!.downloadFile(file.name, savePath);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded ${file.name}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  IconData _getFileIcon(FTPEntry file) {
    if (file.type == FTPEntryType.DIR) return Icons.folder;
    final ext = file.name.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mkv':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_config.ftpScreenTitle),
        elevation: _config.cardElevation,
        actions: [
          if (_isConnected)
            IconButton(
              icon: Icon(Icons.logout, color: _config.surfaceColor),
              onPressed: _disconnect,
              tooltip: _config.disconnectButtonLabel,
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(_config.defaultPadding),
        child: Column(
          children: [
            // Connection Form
            Card(
              elevation: _config.cardElevation,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_config.borderRadius),
              ),
              child: Padding(
                padding: EdgeInsets.all(_config.defaultPadding),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _hostController,
                            decoration: InputDecoration(
                              labelText: _config.ftpHostLabel,
                              labelStyle: TextStyle(color: _config.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(_config.borderRadius),
                              ),
                              focusedBorder: OutlineInputBorder(
                            ),
                          ),
                        ),
                        SizedBox(width: _config.getParameter('ui.spacing.medium', defaultValue: 20.0)),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _portController,
                            decoration: InputDecoration(
                              labelText: 'Port',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.small', defaultValue: 4.0)!),
                              ),
                itemBuilder: (context, index) {
                  final file = _files[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Icon(
                        file.type == FTPEntryType.FILE ? Icons.insert_drive_file : Icons.folder,
                        color: _config.primaryColor,
                      ),
                      title: Text(file.name),
                      subtitle: file.type == FTPEntryType.FILE
                          ? Text('Size: ${file.size ?? 0} bytes')
                          : const Text('Directory'),
                      trailing: file.type == FTPEntryType.FILE
                          ? IconButton(
                              icon: const Icon(Icons.download),
                              onPressed: () => _downloadSelectedFile(file),
                              tooltip: 'Download',
                            )
                          : null,
                      onTap: () {
                        if (file.type == FTPEntryType.DIR) {
                          // Navigate to directory (simplified)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Navigate to: ${file.name}')),
                          );
                        }
                      },
                    ),
                  );
                },
              )
            : const Center(
                child: Text('Not connected. Please connect to an FTP server.'),
              ),
      ),
    ],
  );
}

Widget _buildTransferQueueTab() {
  return Column(
    children: [
      // Queue stats
      Card(
        margin: EdgeInsets.all(_config.defaultPadding),
        child: Padding(
          padding: EdgeInsets.all(_config.defaultPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQueueStat('Queued', _transferQueue.where((t) => t.status == TransferStatus.queued).length),
              _buildQueueStat('Active', _transferQueue.where((t) => t.status == TransferStatus.inProgress).length),
              _buildQueueStat('Completed', _transferQueue.where((t) => t.status == TransferStatus.completed).length),
              _buildQueueStat('Failed', _transferQueue.where((t) => t.status == TransferStatus.failed).length),
            ],
          ),
        ),
      ),

      // Transfer list
      Expanded(
        child: _transferQueue.isEmpty
            ? const Center(
                child: Text('No transfers in queue'),
              )
            : ListView.builder(
                itemCount: _transferQueue.length,
                itemBuilder: (context, index) {
                  final transfer = _transferQueue[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Icon(
                        transfer.isUpload ? Icons.upload : Icons.download,
                        color: _getStatusColor(transfer.status),
                      ),
                      title: Text(transfer.fileName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${transfer.isUpload ? 'Upload' : 'Download'} • ${_formatFileSize(transfer.fileSize)}'),
                          if (transfer.status == TransferStatus.inProgress || transfer.progress > 0)
                            LinearProgressIndicator(value: transfer.progress),
                          if (transfer.errorMessage != null)
                            Text(
                              transfer.errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (transfer.status == TransferStatus.failed)
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () => _retryTransfer(transfer),
                              tooltip: 'Retry',
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeFromQueue(transfer),
                            tooltip: 'Remove',
                                          style: TextStyle(fontSize: 12),
                                        )
                                      : const Text('Directory'),
                                  trailing: file.type == FTPEntryType.FILE
                                      ? IconButton(
                                          icon: Icon(Icons.download, color: _config.successColor),
                                          onPressed: () => _downloadFile(file),
                                          tooltip: _config.downloadButtonLabel,
                                        )
                                      : null,
                                  onTap: file.type == FTPEntryType.DIR
                                      ? () async {
                                          await _ftpConnect?.changeDirectory(file.name);
                                          await _listFiles();
                                        }
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _isConnected
          ? FloatingActionButton.extended(
              onPressed: _uploadFile,
              backgroundColor: _config.primaryColor,
              foregroundColor: _config.surfaceColor,
              icon: Icon(Icons.upload_file),
              label: Text(_config.uploadButtonLabel),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _ftpConnect?.disconnect();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
