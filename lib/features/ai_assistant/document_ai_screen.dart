import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/central_config.dart';
import '../../../services/ai/document_ai_service.dart';
import '../../../services/notifications/notification_service.dart';
import '../../../core/accessibility_manager.dart';

/// Advanced Document AI Processing Screen with Accessibility Support
class DocumentAIScreen extends StatefulWidget {
  const DocumentAIScreen({super.key});

  @override
  State<DocumentAIScreen> createState() => _DocumentAIScreenState();
}

class _DocumentAIScreenState extends State<DocumentAIScreen> {
  final DocumentAIService _documentAIService = DocumentAIService();
  final ImagePicker _imagePicker = ImagePicker();
  final AccessibilityManager _accessibility = AccessibilityManager();

  DocumentAIResult? _currentResult;
  bool _isProcessing = false;
  String? _errorMessage;

  // Focus nodes for keyboard navigation
  final FocusNode _filePickerFocus = FocusNode();
  final FocusNode _cameraFocus = FocusNode();
  final FocusNode _galleryFocus = FocusNode();
  final FocusNode _exportFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _announceScreenEntry();
  }

  @override
  void dispose() {
    _documentAIService.dispose();
    _filePickerFocus.dispose();
    _cameraFocus.dispose();
    _galleryFocus.dispose();
    _exportFocus.dispose();
    super.dispose();
  }

  void _announceScreenEntry() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _accessibility.announceToScreenReader(
        'Document AI screen opened. Use tab to navigate between options.',
        assertion: 'screen opened',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = CentralConfig.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document AI'),
        backgroundColor: config.primaryColor,
        foregroundColor: config.surfaceColor,
        elevation: config.getParameter('ui.app_bar.elevation', defaultValue: 4.0),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(config.getParameter('ui.spacing.medium', defaultValue: 20.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 24),
            if (_isProcessing) _buildProcessingIndicator(),
            if (_errorMessage != null) _buildErrorMessage(),
            if (_currentResult != null) _buildResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: CentralConfig.instance.getParameter('ui.shadow.elevation.medium', defaultValue: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          CentralConfig.instance.getParameter('ui.border_radius.medium', defaultValue: 8.0),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(CentralConfig.instance.getParameter('ui.spacing.medium', defaultValue: 20.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.document_scanner,
                  color: CentralConfig.instance.primaryColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'AI-Powered Document Processing',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Extract text, analyze content, and gain insights from your documents using advanced AI and machine learning.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFeatureItem('OCR & Text Extraction', 'Extract text from images and scanned documents'),
        _buildFeatureItem('Content Analysis', 'Analyze document content and categorize automatically'),
        _buildFeatureItem('Metadata Generation', 'Generate intelligent metadata and tags'),
        _buildFeatureItem('Multi-format Support', 'Process PDFs, images, and text documents'),
      ],
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      elevation: CentralConfig.instance.getParameter('ui.shadow.elevation.low', defaultValue: 2.0),
      child: Padding(
        padding: EdgeInsets.all(CentralConfig.instance.getParameter('ui.spacing.medium', defaultValue: 20.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Document',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton(
                  'Choose File',
                  Icons.file_open,
                  _pickDocument,
                  focusNode: _filePickerFocus,
                  hint: 'Select a document file from your device storage',
                ),
                _buildActionButton(
                  'Take Photo',
                  Icons.camera_alt,
                  _takePhoto,
                  focusNode: _cameraFocus,
                  hint: 'Capture a photo with your camera for processing',
                ),
                _buildActionButton(
                  'From Gallery',
                  Icons.photo_library,
                  _pickFromGallery,
                  focusNode: _galleryFocus,
                  hint: 'Select an image from your photo gallery',
                ),
                if (_currentResult != null)
                  _buildActionButton(
                    'Export Results',
                    Icons.download,
                    _exportResults,
                    focusNode: _exportFocus,
                    hint: 'Save the processing results to a file',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed,
      {FocusNode? focusNode, String? hint}) {
    final accessibleColors = _accessibility.getAccessibleColors(context);
    final fontSizes = _accessibility.getAccessibleFontSizes(context);

    return Focus(
      focusNode: focusNode,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          _accessibility.announceToScreenReader('$label button focused');
        }
      },
      child: _accessibility.createAccessibleButton(
        child: ElevatedButton.icon(
          focusNode: focusNode,
          onPressed: _isProcessing ? null : onPressed,
          icon: Icon(icon, size: 18),
          label: Text(
            label,
            style: TextStyle(fontSize: fontSizes.medium),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: accessibleColors.primary,
            foregroundColor: accessibleColors.onPrimary,
            padding: EdgeInsets.symmetric(
              horizontal: CentralConfig.instance.getParameter('ui.spacing.medium', defaultValue: 20.0),
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                CentralConfig.instance.getParameter('ui.border_radius.medium', defaultValue: 8.0),
              ),
            ),
          ),
        ),
        onPressed: onPressed,
        label: label,
        hint: hint ?? 'Tap to $label',
        enabled: !_isProcessing,
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(CentralConfig.instance.getParameter('ui.spacing.medium', defaultValue: 20.0)),
        child: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Processing document with AI...',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: EdgeInsets.all(CentralConfig.instance.getParameter('ui.spacing.medium', defaultValue: 20.0)),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Processing Error',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _errorMessage = null),
              icon: const Icon(Icons.close, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_currentResult == null) return const SizedBox();

    return Card(
      elevation: CentralConfig.instance.getParameter('ui.shadow.elevation.medium', defaultValue: 4.0),
      child: Padding(
        padding: EdgeInsets.all(CentralConfig.instance.getParameter('ui.spacing.medium', defaultValue: 20.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Processing Complete',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildResultSummary(),
            const SizedBox(height: 16),
            _buildExtractedText(),
            if (_currentResult!.contentLabels.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildContentLabels(),
            ],
            const SizedBox(height: 16),
            _buildMetadata(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSummary() {
    return Container(
      padding: EdgeInsets.all(CentralConfig.instance.getParameter('ui.spacing.small', defaultValue: 12.0)),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(
          CentralConfig.instance.getParameter('ui.border_radius.small', defaultValue: 4.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'File: ${_currentResult!.fileName}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            'Type: ${_currentResult!.fileType.toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            'Confidence: ${(_currentResult!.confidence * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              color: _getConfidenceColor(_currentResult!.confidence),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Extracted Text',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          padding: EdgeInsets.all(CentralConfig.instance.getParameter('ui.spacing.small', defaultValue: 12.0)),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(
              CentralConfig.instance.getParameter('ui.border_radius.small', defaultValue: 4.0),
            ),
          ),
          child: SingleChildScrollView(
            child: Text(
              _currentResult!.extractedText.isNotEmpty
                  ? _currentResult!.extractedText
                  : 'No text extracted',
              style: TextStyle(
                color: _currentResult!.extractedText.isNotEmpty ? Colors.black : Colors.grey,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentLabels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Content Labels',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _currentResult!.contentLabels.map((label) => Chip(
            label: Text(
              '${label.label} ${(label.confidence * 100).toStringAsFixed(0)}%',
            ),
            backgroundColor: CentralConfig.instance.primaryColor.withOpacity(0.1),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildMetadata() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metadata',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ..._currentResult!.metadata.entries.map((entry) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(
                '${entry.key}: ',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Expanded(
                child: Text(
                  entry.value.toString(),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      await _processFile(File(result.files.single.path!));
    }
  }

  Future<void> _takePhoto() async {
    final image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image != null) {
      await _processFile(File(image.path));
    }
  }

  Future<void> _pickFromGallery() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _processFile(File(image.path));
    }
  }

  Future<void> _processFile(File file) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _currentResult = null;
    });

    try {
      final result = await _documentAIService.processDocument(file);

      setState(() {
        _currentResult = result;
        _isProcessing = false;
      });

      NotificationService().showFileOperationNotification(
        title: 'Document Processed',
        body: 'AI analysis completed for ${result.fileName}',
      );

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isProcessing = false;
      });

      NotificationService().showFileOperationNotification(
        title: 'Processing Failed',
        body: 'Failed to process document: $e',
      );
    }
  }

  void _exportResults() {
    if (_currentResult == null) return;

    // Implementation for exporting results
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon!')),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
