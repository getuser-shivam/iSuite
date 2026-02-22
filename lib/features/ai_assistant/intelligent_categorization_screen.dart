import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/central_config.dart';
import '../../../services/ai/document_ai_service.dart';
import '../../../services/ai/intelligent_categorization_service.dart';
import '../../../services/notifications/notification_service.dart';
import '../../../core/accessibility_manager.dart';

/// Intelligent Document Categorization Screen
class IntelligentCategorizationScreen extends StatefulWidget {
  const IntelligentCategorizationScreen({super.key});

  @override
  State<IntelligentCategorizationScreen> createState() => _IntelligentCategorizationScreenState();
}

class _IntelligentCategorizationScreenState extends State<IntelligentCategorizationScreen> {
  final DocumentAIService _documentAIService = DocumentAIService();
  final IntelligentCategorizationService _categorizationService = IntelligentCategorizationService();
  final AccessibilityManager _accessibility = AccessibilityManager();

  final List<CategorizationResult> _results = [];
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _announceScreenEntry();
  }

  void _announceScreenEntry() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _accessibility.announceToScreenReader(
        'Intelligent categorization screen opened. Select documents to automatically organize them.',
        assertion: 'screen opened',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = CentralConfig.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Organization'),
        backgroundColor: config.primaryColor,
        foregroundColor: config.surfaceColor,
        elevation: config.getParameter('ui.app_bar.elevation', defaultValue: 4.0),
        actions: [
          if (_results.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearResults,
              tooltip: 'Clear all results',
            ),
        ],
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
            if (_results.isNotEmpty) _buildResultsList(),
            if (_results.isEmpty && !_isProcessing) _buildEmptyState(),
          ],
        ),
      ),
      floatingActionButton: _results.isNotEmpty ? FloatingActionButton.extended(
        onPressed: _applyOrganization,
        icon: const Icon(Icons.auto_fix_high),
        label: const Text('Apply Organization'),
        backgroundColor: config.primaryColor,
      ) : null,
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
                  Icons.auto_awesome,
                  color: CentralConfig.instance.primaryColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'AI-Powered Smart Organization',
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
              'Let AI analyze your documents and automatically categorize them into logical folders. Machine learning identifies content patterns, keywords, and document types for intelligent organization.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            _buildCapabilitiesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilitiesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCapabilityItem('🎯 Smart Categorization', 'ML-based document classification'),
        _buildCapabilityItem('📁 Auto Organization', 'Automatic folder structure suggestions'),
        _buildCapabilityItem('🔍 Content Analysis', 'Keyword and pattern recognition'),
        _buildCapabilityItem('📊 Confidence Scoring', 'Quality assessment for categorizations'),
        _buildCapabilityItem('🔄 Learning System', 'Improves from user corrections'),
      ],
    );
  }

  Widget _buildCapabilityItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
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
              'Select Documents to Organize',
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
                  'Select Files',
                  Icons.file_open,
                  _selectFiles,
                  'Choose multiple files for batch categorization',
                ),
                _buildActionButton(
                  'Select Folder',
                  Icons.folder_open,
                  _selectFolder,
                  'Choose an entire folder to organize',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed, String hint) {
    return Semantics(
      button: true,
      enabled: !_isProcessing,
      label: label,
      hint: hint,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: CentralConfig.instance.primaryColor,
          foregroundColor: CentralConfig.instance.surfaceColor,
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
                'AI analyzing documents and generating smart organization...',
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
                    'Organization Error',
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

  Widget _buildResultsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Organization Results (${_results.length} documents)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${_calculateAverageConfidence().toStringAsFixed(1)}% avg confidence',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _results.length,
          itemBuilder: (context, index) => _buildResultCard(_results[index]),
        ),
      ],
    );
  }

  Widget _buildResultCard(CategorizationResult result) {
    final categories = _categorizationService.getCategories();
    final category = categories[result.primaryCategory];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: CentralConfig.instance.getParameter('ui.shadow.elevation.low', defaultValue: 2.0),
      child: Padding(
        padding: EdgeInsets.all(CentralConfig.instance.getParameter('ui.spacing.medium', defaultValue: 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  category?.icon ?? Icons.description,
                  color: category?.color ?? Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.documentName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(result.confidence),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(result.confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Category: ${result.primaryCategory}',
                  style: TextStyle(
                    color: category?.color ?? Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (result.alternativeCategories.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Text(
                    '+${result.alternativeCategories.length} alternatives',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: result.suggestedFolders.map((folder) => Chip(
                label: Text(
                  folder,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.blue[50],
                side: const BorderSide(color: Colors.blue, width: 0.5),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Ready for Smart Organization',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select documents above to let AI analyze and organize them automatically',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'jpg', 'jpeg', 'png', 'docx'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      await _processFiles(result.files.map((f) => File(f.path!)).toList());
    }
  }

  Future<void> _selectFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();

    if (result != null) {
      final directory = Directory(result);
      final files = await _getOrganizableFiles(directory);
      if (files.isNotEmpty) {
        await _processFiles(files);
      } else {
        setState(() => _errorMessage = 'No organizable files found in the selected folder');
      }
    }
  }

  Future<List<File>> _getOrganizableFiles(Directory directory) async {
    final files = <File>[];
    final allowedExtensions = ['pdf', 'txt', 'jpg', 'jpeg', 'png', 'docx'];

    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final extension = entity.path.split('.').last.toLowerCase();
        if (allowedExtensions.contains(extension)) {
          files.add(entity);
        }
      }
    }

    return files.take(50).toList(); // Limit for performance
  }

  Future<void> _processFiles(List<File> files) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _results.clear();
    });

    try {
      final documentResults = <DocumentAIResult>[];

      // Process each file with Document AI
      for (final file in files) {
        try {
          final docResult = await _documentAIService.processDocument(file);
          documentResults.add(docResult);
        } catch (e) {
          // Continue with other files if one fails
          continue;
        }
      }

      // Categorize documents intelligently
      final categorizationResults = await _categorizationService.categorizeDocuments(documentResults);

      setState(() {
        _results.addAll(categorizationResults);
        _isProcessing = false;
      });

      NotificationService().showFileOperationNotification(
        title: 'Smart Organization Complete',
        body: 'Categorized ${categorizationResults.length} documents with AI',
      );

      _accessibility.announceToScreenReader(
        'Organization complete. Categorized ${categorizationResults.length} documents.',
        assertion: 'task completed',
      );

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to organize documents: $e';
        _isProcessing = false;
      });
    }
  }

  void _clearResults() {
    setState(() => _results.clear());
    _accessibility.announceToScreenReader('Results cleared');
  }

  void _applyOrganization() {
    // Implementation for applying the organization
    // This would move files to suggested folders
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Organization application coming soon!')),
    );
  }

  double _calculateAverageConfidence() {
    if (_results.isEmpty) return 0.0;
    final total = _results.fold<double>(0, (sum, result) => sum + result.confidence);
    return total / _results.length;
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
