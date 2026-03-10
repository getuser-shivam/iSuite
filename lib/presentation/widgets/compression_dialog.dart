import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/compression_service.dart';

/// Compression Dialog Widget
/// Provides UI for file compression operations
class CompressionDialog extends ConsumerStatefulWidget {
  final List<String> filePaths;

  const CompressionDialog({
    super.key,
    required this.filePaths,
  });

  @override
  ConsumerState<CompressionDialog> createState() => _CompressionDialogState();
}

class _CompressionDialogState extends ConsumerState<CompressionDialog> {
  final TextEditingController _fileNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isCompressing = false;
  double _progress = 0.0;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    // Default filename based on first file
    if (widget.filePaths.isNotEmpty) {
      final firstFileName = widget.filePaths.first.split('/').last;
      final baseName = firstFileName.split('.').first;
      _fileNameController.text = '${baseName}_compressed.zip';
    }
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _compressFiles() async {
    if (_fileNameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a filename';
      });
      return;
    }

    setState(() {
      _isCompressing = true;
      _progress = 0.0;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final compressionService = CompressionService();

      // Convert file paths to File objects
      final files = widget.filePaths.map((path) => File(path)).toList();

      // Determine output path (same directory as first file)
      final firstFileDir = File(widget.filePaths.first).parent.path;
      final outputPath = '$firstFileDir/${_fileNameController.text}';

      // Compress files
      final resultPath = await compressionService.compressToZip(
        files,
        outputPath,
        password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
        onProgress: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );

      setState(() {
        _isCompressing = false;
        _successMessage = 'Files compressed successfully!\nSaved to: ${File(resultPath).path.split('/').last}';
      });

    } catch (e) {
      setState(() {
        _isCompressing = false;
        _errorMessage = 'Compression failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Compress Files'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Compressing ${widget.filePaths.length} file(s)'),
            const SizedBox(height: 16),

            // Filename input
            TextField(
              controller: _fileNameController,
              decoration: const InputDecoration(
                labelText: 'Archive Name',
                hintText: 'Enter archive filename',
                border: OutlineInputBorder(),
              ),
              enabled: !_isCompressing,
            ),
            const SizedBox(height: 16),

            // Password input (optional)
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password (Optional)',
                hintText: 'Leave empty for no password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              enabled: !_isCompressing,
            ),
            const SizedBox(height: 16),

            // Progress indicator
            if (_isCompressing) ...[
              const Text('Compressing...'),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text('${(_progress * 100).round()}% complete'),
            ],

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Success message
            if (_successMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.green.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCompressing ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isCompressing ? null : _compressFiles,
          child: _isCompressing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Compress'),
        ),
      ],
    );
  }
}
