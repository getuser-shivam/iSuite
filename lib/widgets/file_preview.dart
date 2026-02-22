import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class FilePreviewWidget extends StatefulWidget {
  final String filePath;
  final VoidCallback? onClose;
  
  const FilePreviewWidget({
    Key? key,
    required this.filePath,
    this.onClose,
  }) : super(key: key);

  @override
  State<FilePreviewWidget> createState() => _FilePreviewWidgetState();
}

class _FilePreviewWidgetState extends State<FilePreviewWidget> {
  bool _isLoading = true;
  String? _error;
  dynamic _content;

  @override
  void initState() {
    super.initState();
    _loadFileContent();
  }

  Future<void> _loadFileContent() async {
    try {
      final file = File(widget.filePath);
      final extension = path.extension(widget.filePath).toLowerCase();
      
      if (!_file.exists) {
        setState(() {
          _error = 'File not found';
          _isLoading = false;
        });
        return;
      }

      switch (extension) {
        case '.jpg':
        case '.jpeg':
        case '.png':
        case '.gif':
        case '.bmp':
          await _loadImage(file);
          break;
        case '.mp4':
        case '.avi':
        case '.mov':
        case '.wmv':
          await _loadVideoInfo(file);
          break;
        case '.mp3':
        case '.wav':
        case '.flac':
          await _loadAudioInfo(file);
          break;
        case '.pdf':
          await _loadPdfInfo(file);
          break;
        case '.txt':
        case '.md':
          await _loadTextFile(file);
          break;
        case '.json':
        case '.xml':
          await _loadJsonFile(file);
          break;
        default:
          await _loadFileInfo(file);
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading file: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadImage(File file) async {
    final bytes = await file.readAsBytes();
    setState(() {
      _content = bytes;
      _isLoading = false;
    });
  }

  Future<void> _loadVideoInfo(File file) async {
    final stat = await file.stat();
    setState(() {
      _content = {
        'type': 'video',
        'size': stat.size,
        'modified': stat.modified,
        'duration': '00:00', // Would need video processing library
      };
      _isLoading = false;
    });
  }

  Future<void> _loadAudioInfo(File file) async {
    final stat = await file.stat();
    setState(() {
      _content = {
        'type': 'audio',
        'size': stat.size,
        'modified': stat.modified,
        'duration': '00:00', // Would need audio processing library
      };
      _isLoading = false;
    });
  }

  Future<void> _loadPdfInfo(File file) async {
    final stat = await file.stat();
    setState(() {
      _content = {
        'type': 'pdf',
        'size': stat.size,
        'modified': stat.modified,
        'pages': 'Unknown', // Would need PDF library
      };
      _isLoading = false;
    });
  }

  Future<void> _loadTextFile(File file) async {
    final content = await file.readAsString();
    setState(() {
      _content = content;
      _isLoading = false;
    });
  }

  Future<void> _loadJsonFile(File file) async {
    final content = await file.readAsString();
    try {
      final jsonData = jsonDecode(content);
      setState(() {
        _content = {
          'type': 'json',
          'data': jsonData,
          'formatted': const JsonEncoder.withIndent('  ').convert(jsonData),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Invalid JSON file: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFileInfo(File file) async {
    final stat = await file.stat();
    setState(() {
      _content = {
        'type': 'unknown',
        'size': stat.size,
        'modified': stat.modified,
      };
      _isLoading = false;
    });
  }

  Widget _buildPreview() {
    if (_content is Map && _content['type'] == 'image') {
      return _buildImagePreview();
    } else if (_content is Map && _content['type'] == 'video') {
      return _buildVideoPreview();
    } else if (_content is Map && _content['type'] == 'audio') {
      return _buildAudioPreview();
    } else if (_content is Map && _content['type'] == 'pdf') {
      return _buildPdfPreview();
    } else if (_content is String) {
      return _buildTextPreview();
    } else if (_content is Map && _content['type'] == 'json') {
      return _buildJsonPreview();
    } else if (_content is Map) {
      return _buildFileInfo();
    }
    
    return const Center(child: Text('No preview available'));
  }

  Widget _buildImagePreview() {
    return InteractiveViewer(
      panEnabled: true,
      boundaryMargin: const EdgeInsets.all(20),
      minScale: 0.5,
      maxScale: 4.0,
      child: Image.memory(
        _content,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.play_circle_outline,
          size: 100,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 16),
        Text(
          'Video File',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text('Size: ${_formatFileSize(_content['size'])}'),
        Text('Duration: ${_content['duration']}'),
        Text('Modified: ${_formatDate(_content['modified'])}'),
      ],
    );
  }

  Widget _buildAudioPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.audiotrack,
          size: 100,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 16),
        Text(
          'Audio File',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text('Size: ${_formatFileSize(_content['size'])}'),
        Text('Duration: ${_content['duration']}'),
        Text('Modified: ${_formatDate(_content['modified'])}'),
      ],
    );
  }

  Widget _buildPdfPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.picture_as_pdf,
          size: 100,
          color: Colors.red[600],
        ),
        const SizedBox(height: 16),
        Text(
          'PDF Document',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text('Size: ${_formatFileSize(_content['size'])}'),
        Text('Pages: ${_content['pages']}'),
        Text('Modified: ${_formatDate(_content['modified'])}'),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _openWithExternalApp(),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open with PDF Viewer'),
        ),
      ],
    );
  }

  Widget _buildTextPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        _content,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
      ),
    );
  }

  Widget _buildJsonPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        _content['formatted'],
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }

  Widget _buildFileInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.insert_drive_file,
          size: 100,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 16),
        Text(
          'File Information',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text('Size: ${_formatFileSize(_content['size'])}'),
        Text('Modified: ${_formatDate(_content['modified'])}'),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _openWithExternalApp(),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open with Default App'),
        ),
      ],
    );
  }

  void _openWithExternalApp() async {
    try {
      await OpenFilex.open(widget.filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file: $e')),
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text(path.basename(widget.filePath)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareFile,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showFileInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                )
              : _buildPreview(),
    );
  }

  void _shareFile() async {
    // Implement file sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  void _showFileInfo() {
    final file = File(widget.filePath);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Information'),
        content: FutureBuilder<FileStat>(
          future: file.stat(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            final stat = snapshot.data!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${path.basename(widget.filePath)}'),
                Text('Path: ${widget.filePath}'),
                Text('Size: ${_formatFileSize(stat.size)}'),
                Text('Modified: ${stat.modified}'),
                Text('Type: ${path.extension(widget.filePath)}'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Add open_filex package to pubspec.yaml for this to work
// For now, we'll create a mock implementation
class OpenFilex {
  static Future<void> open(String filePath) async {
    // Mock implementation - would use url_launcher or open_file package
    debugPrint('Opening file: $filePath');
  }
}
