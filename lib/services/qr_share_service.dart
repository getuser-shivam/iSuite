import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class QRShareService {
  static Future<String> generateShareableLink(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      final fileName = path.basename(filePath);
      final fileSize = await file.length();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Create share data
      final shareData = {
        'type': 'file_share',
        'fileName': fileName,
        'filePath': filePath,
        'fileSize': fileSize,
        'timestamp': timestamp,
        'deviceId': await _getDeviceId(),
      };

      // Generate shareable link (in production, this would be a real URL)
      final shareId = _generateShareId();
      final shareUrl = 'https://share.isuite.app/file/$shareId';

      // Store share data locally
      await _storeShareData(shareId, shareData);

      return shareUrl;
    } catch (e) {
      throw Exception('Failed to generate shareable link: $e');
    }
  }

  static Future<String> generateQRCode(String data) async {
    try {
      final qrCode = await QrPainter.createQRCode(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      // Convert QR code to image
      final qrImage = await qrCode.toImage(320);

      // Save QR code image temporarily
      final tempDir = Directory.systemTemp;
      final qrFile = File(
          '${tempDir.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png');
      await qrFile.writeAsBytes(
          await qrImage.toByteData(quality: 100).buffer.asUint8List());

      return qrFile.path;
    } catch (e) {
      throw Exception('Failed to generate QR code: $e');
    }
  }

  static Future<void> shareFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      final fileName = path.basename(filePath);

      // Share via system share dialog
      await Share.shareXFiles([XFile(filePath)],
          text: 'Sharing file: $fileName');

      // Also generate QR code for easy sharing
      final shareUrl = await generateShareableLink(filePath);
      final qrPath = await generateQRCode(shareUrl);

      // Show QR code dialog
      await _showShareDialog(fileName, shareUrl, qrPath);
    } catch (e) {
      throw Exception('Failed to share file: $e');
    }
  }

  static Future<void> shareMultipleFiles(List<String> filePaths) async {
    try {
      final files = filePaths.map((path) => XFile(path)).toList();
      final fileNames = filePaths.map(path.basename).toList();

      // Share via system share dialog
      await Share.shareXFiles(files, text: 'Sharing ${fileNames.length} files');

      // Generate QR code for file list
      final shareData = {
        'type': 'multi_file_share',
        'files': filePaths,
        'fileNames': fileNames,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'deviceId': await _getDeviceId(),
      };

      final shareId = _generateShareId();
      final shareUrl = 'https://share.isuite.app/files/$shareId';
      await _storeShareData(shareId, shareData);

      final qrPath = await generateQRCode(shareUrl);
      await _showMultiShareDialog(fileNames, shareUrl, qrPath);
    } catch (e) {
      throw Exception('Failed to share files: $e');
    }
  }

  static Future<String> _getDeviceId() async {
    // Generate unique device identifier
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _generateShareId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().millisecond;
    return '${timestamp}_$random';
  }

  static Future<void> _storeShareData(
      String shareId, Map<String, dynamic> shareData) async {
    try {
      final shareDir = Directory('${await _getAppDocumentsPath()}/shares');
      await shareDir.create(recursive: true);

      final shareFile = File('${shareDir.path}/$shareId.json');
      await shareFile.writeAsString(jsonEncode(shareData));
    } catch (e) {
      debugPrint('Failed to store share data: $e');
    }
  }

  static Future<String> _getAppDocumentsPath() async {
    // In a real app, you'd use path_provider
    // For now, return a temporary path
    return Directory.systemTemp.path;
  }

  static Future<void> _showShareDialog(
      String fileName, String shareUrl, String qrPath) async {
    // This would show a dialog in the actual app
    // For now, just print the information
    debugPrint('Share Dialog - File: $fileName');
    debugPrint('Share URL: $shareUrl');
    debugPrint('QR Code Path: $qrPath');
  }

  static Future<void> _showMultiShareDialog(
      List<String> fileNames, String shareUrl, String qrPath) async {
    // This would show a dialog in the actual app
    debugPrint('Multi-Share Dialog - Files: ${fileNames.join(', ')}');
    debugPrint('Share URL: $shareUrl');
    debugPrint('QR Code Path: $qrPath');
  }

  static Future<Map<String, dynamic>> getShareInfo(String shareId) async {
    try {
      final shareDir = Directory('${await _getAppDocumentsPath()}/shares');
      final shareFile = File('${shareDir.path}/$shareId.json');

      if (!await shareFile.exists()) {
        throw Exception('Share not found: $shareId');
      }

      final content = await shareFile.readAsString();
      final shareData = jsonDecode(content);

      // Check if share is expired (24 hours)
      final shareTime =
          DateTime.fromMillisecondsSinceEpoch(shareData['timestamp']);
      final now = DateTime.now();
      final isExpired = now.difference(shareTime).inHours > 24;

      return {
        ...shareData,
        'isExpired': isExpired,
        'timeRemaining': isExpired ? 0 : 24 - now.difference(shareTime).inHours,
      };
    } catch (e) {
      throw Exception('Failed to get share info: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getActiveShares() async {
    try {
      final shareDir = Directory('${await _getAppDocumentsPath()}/shares');
      if (!await shareDir.exists()) {
        return [];
      }

      final shareFiles = await shareDir.list().toList();
      final activeShares = <Map<String, dynamic>>[];

      for (final file in shareFiles) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final shareData = jsonDecode(content);

            // Check if share is not expired
            final shareTime =
                DateTime.fromMillisecondsSinceEpoch(shareData['timestamp']);
            final now = DateTime.now();
            final isExpired = now.difference(shareTime).inHours <= 24;

            if (isExpired) {
              await file.delete();
            } else {
              activeShares.add({
                ...shareData,
                'shareId': file.path.split('/').last.replaceAll('.json', ''),
                'qrCode': await generateQRCode(shareData['shareUrl'] ?? ''),
              });
            }
          } catch (e) {
            debugPrint('Error reading share file: $e');
          }
        }
      }

      return activeShares;
    } catch (e) {
      throw Exception('Failed to get active shares: $e');
    }
  }

  static Future<void> cleanupExpiredShares() async {
    try {
      final shares = await getActiveShares();

      for (final share in shares) {
        if (share['isExpired'] == true) {
          final shareId = share['shareId'];
          final shareDir = Directory('${await _getAppDocumentsPath()}/shares');
          final shareFile = File('${shareDir.path}/$shareId.json');

          if (await shareFile.exists()) {
            await shareFile.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up expired shares: $e');
    }
  }

  static Future<void> downloadSharedFile(
      String shareId, String localPath) async {
    try {
      final shareInfo = await getShareInfo(shareId);

      if (shareInfo['isExpired'] == true) {
        throw Exception('Share link has expired');
      }

      final filePath = shareInfo['filePath'];
      if (filePath == null) {
        throw Exception('File path not found in share data');
      }

      final sourceFile = File(filePath);
      if (!await sourceFile.exists()) {
        throw Exception('Original file not found');
      }

      final destinationFile = File(localPath);
      await destinationFile.parent.create(recursive: true);
      await sourceFile.copy(localPath);

      // Update download count
      shareInfo['downloadCount'] = (shareInfo['downloadCount'] ?? 0) + 1;

      // Save updated share info
      final shareDir = Directory('${await _getAppDocumentsPath()}/shares');
      final shareFile = File('${shareDir.path}/$shareId.json');
      await shareFile.writeAsString(jsonEncode(shareInfo));
    } catch (e) {
      throw Exception('Failed to download shared file: $e');
    }
  }
}

class QRShareWidget extends StatefulWidget {
  final String filePath;
  final VoidCallback? onClose;

  const QRShareWidget({
    Key? key,
    required this.filePath,
    this.onClose,
  }) : super(key: key);

  @override
  State<QRShareWidget> createState() => _QRShareWidgetState();
}

class _QRShareWidgetState extends State<QRShareWidget> {
  bool _isGenerating = false;
  String? _shareUrl;
  String? _qrPath;

  @override
  void initState() {
    super.initState();
    _generateShareContent();
  }

  Future<void> _generateShareContent() async {
    setState(() => _isGenerating = true);

    try {
      _shareUrl = await QRShareService.generateShareableLink(widget.filePath);
      _qrPath = await QRShareService.generateQRCode(_shareUrl!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating share content: $e')),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: const Text('Share File'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => widget.onClose?.call(),
          ),
        ],
      ),
      body: _isGenerating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'Generating shareable link...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_qrPath != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'QR Code',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Image.file(File(_qrPath!)),
                          const SizedBox(height: 16),
                          Text(
                            'Scan to download',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (_shareUrl != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Share Link',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            _shareUrl!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _copyShareUrl,
                                icon: const Icon(Icons.copy),
                                label: const Text('Copy Link'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _shareViaSystem,
                                icon: const Icon(Icons.share),
                                label: const Text('Share'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  void _copyShareUrl() {
    if (_shareUrl != null) {
      // In a real app, you'd copy to clipboard
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard')),
      );
    }
  }

  void _shareViaSystem() async {
    if (_shareUrl != null) {
      await Share.share(_shareUrl!);
    }
  }
}
