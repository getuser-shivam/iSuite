import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/central_config.dart';

/// QR Code File Sharing Screen
class QrShareScreen extends StatefulWidget {
  final Map<String, dynamic> fileData;

  const QrShareScreen({Key? key, required this.fileData}) : super(key: key);

  @override
  State<QrShareScreen> createState() => _QrShareScreenState();
}

class _QrShareScreenState extends State<QrShareScreen> {
  final CentralConfig _config = CentralConfig.instance;
  late String _shareData;

  @override
  void initState() {
    super.initState();
    _generateShareData();
  }

  void _generateShareData() {
    // Create shareable data with file information
    final fileInfo = {
      'type': 'iSuite_file_share',
      'fileName': widget.fileData['name'],
      'fileType': widget.fileData['type'],
      'fileSize': widget.fileData['size'],
      'timestamp': DateTime.now().toIso8601String(),
      'deviceId': 'current_device', // In real app, use unique device ID
      'checksum': 'mock_checksum_${widget.fileData['name']}', // In real app, calculate file hash
    };

    // Convert to JSON string for QR code
    _shareData = fileInfo.toString();
  }

  void _shareViaOtherApps() {
    final text = '''
Check out this file shared via iSuite:
📄 ${widget.fileData['name']}
📏 Size: ${widget.fileData['size']}
📋 Type: ${widget.fileData['type']}

Download iSuite for seamless file management: https://github.com/your-repo/iSuite
''';

    Share.share(text, subject: 'File shared via iSuite');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share File'),
        backgroundColor: _config.primaryColor,
        foregroundColor: _config.surfaceColor,
        elevation: _config.cardElevation,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareViaOtherApps,
            tooltip: 'Share via other apps',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(_config.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // File info header
            Card(
              elevation: _config.cardElevation,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_config.borderRadius),
              ),
              child: Padding(
                padding: EdgeInsets.all(_config.defaultPadding),
                child: Column(
                  children: [
                    Icon(
                      _getFileIcon(widget.fileData['name']),
                      size: 48,
                      color: _config.primaryColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.fileData['name'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _config.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.fileData['type']} • ${widget.fileData['size']}',
                      style: TextStyle(
                        color: _config.primaryColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Instructions
            Text(
              'Scan this QR code with another device to receive the file',
              style: TextStyle(
                fontSize: 16,
                color: _config.primaryColor.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_config.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: _config.primaryColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: QrImageView(
                data: _shareData,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),

            const SizedBox(height: 24),

            // Share options
            Text(
              'Share Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: _config.primaryColor,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildShareOption(
                  icon: Icons.qr_code_scanner,
                  label: 'QR Code',
                  description: 'Scan to receive',
                  isActive: true,
                ),
                const SizedBox(width: 16),
                _buildShareOption(
                  icon: Icons.wifi,
                  label: 'WiFi Direct',
                  description: 'Coming soon',
                  isActive: false,
                ),
                const SizedBox(width: 16),
                _buildShareOption(
                  icon: Icons.bluetooth,
                  label: 'Bluetooth',
                  description: 'Coming soon',
                  isActive: false,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _config.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(_config.borderRadius),
                border: Border.all(
                  color: _config.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _config.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For security, QR code sharing includes file metadata only. '
                    'Actual file transfer requires network connection or direct device communication.',
                    style: TextStyle(
                      fontSize: 14,
                      color: _config.primaryColor.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required String description,
    required bool isActive,
  }) {
    return Expanded(
      child: Card(
        elevation: isActive ? _config.cardElevation : 0,
        color: isActive ? _config.surfaceColor : _config.surfaceColor.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_config.borderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(
                icon,
                color: isActive ? _config.primaryColor : _config.primaryColor.withOpacity(0.3),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive ? _config.primaryColor : _config.primaryColor.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? _config.primaryColor.withOpacity(0.7) : _config.primaryColor.withOpacity(0.4),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'mp4':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }
}
