import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import '../../../core/central_config.dart';

/// Advanced Document AI Service for OCR, content extraction, and intelligent processing
class DocumentAIService {
  final CentralConfig _config = CentralConfig.instance;

  // ML Kit text recognizer for OCR
  late TextRecognizer _textRecognizer;

  // Image labeler for content categorization
  late ImageLabeler _imageLabeler;

  DocumentAIService() {
    _initializeServices();
  }

  void _initializeServices() {
    _textRecognizer = GoogleMlKit.vision.textRecognizer();
    _imageLabeler = GoogleMlKit.vision.imageLabeler();
  }

  /// Process document with AI - main entry point
  Future<DocumentAIResult> processDocument(File file) async {
    final mimeType = lookupMimeType(file.path);

    if (mimeType == null) {
      throw Exception('Unsupported file type');
    }

    if (mimeType.startsWith('image/')) {
      return await _processImageDocument(file);
    } else if (mimeType == 'application/pdf') {
      return await _processPDFDocument(file);
    } else if (mimeType.startsWith('text/')) {
      return await _processTextDocument(file);
    } else {
      throw Exception('Unsupported document type: $mimeType');
    }
  }

  /// Process image documents with OCR and content analysis
  Future<DocumentAIResult> _processImageDocument(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);

    // OCR processing
    final recognizedText = await _textRecognizer.processImage(inputImage);

    // Content labeling for categorization
    final labels = await _imageLabeler.processImage(inputImage);

    // Extract metadata
    final metadata = await _extractImageMetadata(imageFile);

    return DocumentAIResult(
      fileName: imageFile.path.split('/').last,
      fileType: 'image',
      extractedText: recognizedText.text,
      confidence: _calculateTextConfidence(recognizedText),
      contentLabels: labels.map((label) => ContentLabel(
        label: label.label,
        confidence: label.confidence,
      )).toList(),
      metadata: metadata,
      processingTime: DateTime.now(),
    );
  }

  /// Process PDF documents with text extraction
  Future<DocumentAIResult> _processPDFDocument(File pdfFile) async {
    final pdfDoc = await PDFDoc.fromFile(pdfFile);
    final pageCount = pdfDoc.length;

    String extractedText = '';
    for (int i = 1; i <= pageCount; i++) {
      final page = await pdfDoc.pageAt(i);
      final pageText = await page.text;
      extractedText += pageText + '\n';
    }

    // Extract PDF metadata
    final metadata = await _extractPDFMetadata(pdfFile);

    return DocumentAIResult(
      fileName: pdfFile.path.split('/').last,
      fileType: 'pdf',
      extractedText: extractedText,
      confidence: 0.95, // PDF text extraction is generally reliable
      contentLabels: [], // Could add ML analysis for PDF content
      metadata: metadata,
      processingTime: DateTime.now(),
    );
  }

  /// Process text documents
  Future<DocumentAIResult> _processTextDocument(File textFile) async {
    final content = await textFile.readAsString();

    // Basic text analysis
    final analysis = await _analyzeTextContent(content);

    return DocumentAIResult(
      fileName: textFile.path.split('/').last,
      fileType: 'text',
      extractedText: content,
      confidence: 1.0, // Direct text reading is 100% accurate
      contentLabels: analysis.labels,
      metadata: {
        'wordCount': analysis.wordCount,
        'characterCount': analysis.characterCount,
        'lineCount': analysis.lineCount,
        'language': analysis.detectedLanguage,
      },
      processingTime: DateTime.now(),
    );
  }

  /// Extract image metadata
  Future<Map<String, dynamic>> _extractImageMetadata(File imageFile) async {
    // Note: Would use exif package for full EXIF data extraction
    final stat = await imageFile.stat();

    return {
      'fileSize': stat.size,
      'lastModified': stat.modified,
      'created': stat.changed,
    };
  }

  /// Extract PDF metadata
  Future<Map<String, dynamic>> _extractPDFMetadata(File pdfFile) async {
    final stat = await pdfFile.stat();

    return {
      'fileSize': stat.size,
      'lastModified': stat.modified,
      'created': stat.changed,
    };
  }

  /// Analyze text content for insights
  Future<TextAnalysis> _analyzeTextContent(String content) async {
    final words = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final lines = content.split('\n');

    // Simple language detection (could be enhanced with ML)
    final language = _detectLanguage(content);

    return TextAnalysis(
      wordCount: words.length,
      characterCount: content.length,
      lineCount: lines.length,
      detectedLanguage: language,
      labels: [], // Could add content categorization
    );
  }

  /// Calculate OCR confidence score
  double _calculateTextConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0.0;

    double totalConfidence = 0.0;
    int totalLines = 0;

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        totalConfidence += line.confidence;
        totalLines++;
      }
    }

    return totalLines > 0 ? totalConfidence / totalLines : 0.0;
  }

  /// Simple language detection
  String _detectLanguage(String text) {
    // Basic language detection - could be enhanced
    if (text.contains('the ') || text.contains(' and ') || text.contains(' is ')) {
      return 'en';
    }
    // Add more language detection logic
    return 'unknown';
  }

  /// Clean up resources
  void dispose() {
    _textRecognizer.close();
    _imageLabeler.close();
  }
}

/// Result of Document AI processing
class DocumentAIResult {
  final String fileName;
  final String fileType;
  final String extractedText;
  final double confidence;
  final List<ContentLabel> contentLabels;
  final Map<String, dynamic> metadata;
  final DateTime processingTime;

  DocumentAIResult({
    required this.fileName,
    required this.fileType,
    required this.extractedText,
    required this.confidence,
    required this.contentLabels,
    required this.metadata,
    required this.processingTime,
  });

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'fileType': fileType,
    'extractedText': extractedText,
    'confidence': confidence,
    'contentLabels': contentLabels.map((l) => l.toJson()).toList(),
    'metadata': metadata,
    'processingTime': processingTime.toIso8601String(),
  };
}

/// Content label for categorization
class ContentLabel {
  final String label;
  final double confidence;

  ContentLabel({
    required this.label,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'confidence': confidence,
  };
}

/// Text analysis result
class TextAnalysis {
  final int wordCount;
  final int characterCount;
  final int lineCount;
  final String detectedLanguage;
  final List<ContentLabel> labels;

  TextAnalysis({
    required this.wordCount,
    required this.characterCount,
    required this.lineCount,
    required this.detectedLanguage,
    required this.labels,
  });
}
