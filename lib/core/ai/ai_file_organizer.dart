import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import '../backend/enhanced_pocketbase_service.dart';
import '../config/enhanced_config_manager.dart';
import '../logging/enhanced_logger.dart';
import '../performance/enhanced_performance_manager.dart';

/// AI-Powered File Organization Service
/// Features: Smart categorization, duplicate detection, content analysis
/// Performance: Batch processing, caching, parallel analysis
/// Security: Privacy-first, local processing, secure metadata
class AIFileOrganizer {
  static AIFileOrganizer? _instance;
  static AIFileOrganizer get instance => _instance ??= AIFileOrganizer._internal();
  AIFileOrganizer._internal();

  // Configuration
  late final bool _enableAIAnalysis;
  late final bool _enableDuplicateDetection;
  late final bool _enableSmartCategorization;
  late final bool _enableContentAnalysis;
  late final bool _enableRecommendations;
  late final int _maxBatchSize;
  late final Duration _analysisTimeout;
  
  // AI Models and Analysis
  final Map<String, FileCategory> _categories = {};
  final Map<String, FileMetadata> _fileMetadata = {};
  final Map<String, List<String>> _duplicates = {};
  final Map<String, List<FileRecommendation>> _recommendations = {};
  
  // Processing queues and caches
  final Queue<FileAnalysisTask> _analysisQueue = Queue();
  final Map<String, FileAnalysisResult> _analysisCache = {};
  Timer? _processingTimer;
  bool _isProcessing = false;
  
  // Event streams
  final StreamController<AnalysisEvent> _eventController = 
      StreamController<AnalysisEvent>.broadcast();
  final StreamController<OrganizationProgress> _progressController = 
      StreamController<OrganizationProgress>.broadcast();
  
  Stream<AnalysisEvent> get analysisEvents => _eventController.stream;
  Stream<OrganizationProgress> get progressEvents => _progressController.stream;

  /// Initialize AI File Organizer
  Future<void> initialize() async {
    try {
      // Load configuration
      await _loadConfiguration();
      
      // Initialize AI models
      await _initializeAIModels();
      
      // Setup file categories
      _setupCategories();
      
      // Start processing timer
      _setupProcessingTimer();
      
      EnhancedLogger.instance.info('AI File Organizer initialized');
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to initialize AI File Organizer', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Load configuration
  Future<void> _loadConfiguration() async {
    final config = EnhancedConfigManager.instance;
    
    _enableAIAnalysis = config.getParameter('ai_file_organizer.enable_analysis') ?? true;
    _enableDuplicateDetection = config.getParameter('ai_file_organizer.enable_duplicate_detection') ?? true;
    _enableSmartCategorization = config.getParameter('ai_file_organizer.enable_smart_categorization') ?? true;
    _enableContentAnalysis = config.getParameter('ai_file_organizer.enable_content_analysis') ?? true;
    _enableRecommendations = config.getParameter('ai_file_organizer.enable_recommendations') ?? true;
    _maxBatchSize = config.getParameter('ai_file_organizer.max_batch_size') ?? 50;
    _analysisTimeout = Duration(seconds: config.getParameter('ai_file_organizer.analysis_timeout_seconds') ?? 30);
  }

  /// Initialize AI models
  Future<void> _initializeAIModels() async {
    // Initialize local AI models for file analysis
    // This is a placeholder for actual AI model initialization
    EnhancedLogger.instance.info('AI models initialized');
  }

  /// Setup file categories
  void _setupCategories() {
    _categories.clear();
    
    // Document categories
    _categories['documents'] = FileCategory(
      name: 'Documents',
      description: 'Text documents and PDFs',
      extensions: ['.pdf', '.doc', '.docx', '.txt', '.rtf', '.odt'],
      icon: 'document',
      color: 0xFF2196F3,
      priority: 1,
    );
    
    // Image categories
    _categories['images'] = FileCategory(
      name: 'Images',
      description: 'Photos and graphics',
      extensions: ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg', '.webp'],
      icon: 'image',
      color: 0xFF4CAF50,
      priority: 2,
    );
    
    // Video categories
    _categories['videos'] = FileCategory(
      name: 'Videos',
      description: 'Video files',
      extensions: ['.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm', '.mkv'],
      icon: 'video',
      color: 0xFFFF9800,
      priority: 3,
    );
    
    // Audio categories
    _categories['audio'] = FileCategory(
      name: 'Audio',
      description: 'Music and audio files',
      extensions: ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a'],
      icon: 'audio',
      color: 0xFF9C27B0,
      priority: 4,
    );
    
    // Archive categories
    _categories['archives'] = FileCategory(
      name: 'Archives',
      description: 'Compressed files',
      extensions: ['.zip', '.rar', '.7z', '.tar', '.gz', '.bz2'],
      icon: 'archive',
      color: 0xFF607D8B,
      priority: 5,
    );
    
    // Code categories
    _categories['code'] = FileCategory(
      name: 'Code',
      description: 'Source code files',
      extensions: ['.dart', '.js', '.ts', '.py', '.java', '.cpp', '.html', '.css'],
      icon: 'code',
      color: 0xFF795548,
      priority: 6,
    );
    
    // Spreadsheet categories
    _categories['spreadsheets'] = FileCategory(
      name: 'Spreadsheets',
      description: 'Excel and spreadsheet files',
      extensions: ['.xls', '.xlsx', '.csv', '.ods'],
      icon: 'spreadsheet',
      color: 0xFF4CAF50,
      priority: 7,
    );
    
    // Presentation categories
    _categories['presentations'] = FileCategory(
      name: 'Presentations',
      description: 'PowerPoint and presentation files',
      extensions: ['.ppt', '.pptx', '.odp'],
      icon: 'presentation',
      color: 0xFFE91E63,
      priority: 8,
    );
    
    // Other categories
    _categories['other'] = FileCategory(
      name: 'Other',
      description: 'Other file types',
      extensions: [],
      icon: 'file',
      color: 0xFF9E9E9E,
      priority: 99,
    );
  }

  /// Setup processing timer
  void _setupProcessingTimer() {
    _processingTimer = Timer.periodic(Duration(milliseconds: 100), (_) {
      _processAnalysisQueue();
    });
  }

  /// Analyze file or directory
  Future<FileAnalysisResult> analyzeFile(String filePath) async {
    final timer = EnhancedPerformanceManager.instance.startTimer('ai_file_analysis');
    
    try {
      // Check cache first
      final cacheKey = _generateCacheKey(filePath);
      final cached = _analysisCache[cacheKey];
      if (cached != null && !cached.isExpired) {
        timer.stop();
        return cached;
      }
      
      // Create analysis task
      final task = FileAnalysisTask(
        filePath: filePath,
        timestamp: DateTime.now(),
        priority: AnalysisPriority.normal,
      );
      
      // Add to queue
      _analysisQueue.add(task);
      
      // Wait for completion (with timeout)
      final result = await _waitForAnalysisResult(cacheKey);
      
      timer.stop();
      return result;
    } catch (e, stackTrace) {
      timer.stop();
      EnhancedLogger.instance.error('Failed to analyze file: $filePath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Analyze directory recursively
  Future<DirectoryAnalysisResult> analyzeDirectory(String dirPath) async {
    final timer = EnhancedPerformanceManager.instance.startTimer('ai_directory_analysis');
    
    try {
      final directory = Directory(dirPath);
      if (!await directory.exists()) {
        throw Exception('Directory does not exist: $dirPath');
      }
      
      final result = DirectoryAnalysisResult(
        directoryPath: dirPath,
        timestamp: DateTime.now(),
        files: [],
        categories: {},
        duplicates: {},
        recommendations: [],
      );
      
      // Get all files
      final files = await directory
          .list(recursive: true)
          .where((entity) => entity is File)
          .cast<File>()
          .toList();
      
      // Process in batches
      for (int i = 0; i < files.length; i += _maxBatchSize) {
        final batch = files.skip(i).take(_maxBatchSize).toList();
        
        // Update progress
        _progressController.add(OrganizationProgress(
          totalFiles: files.length,
          processedFiles: i + batch.length,
          currentFile: batch.first.path,
          stage: AnalysisStage.analyzing,
        ));
        
        // Analyze batch
        final batchResults = await Future.wait(
          batch.map((file) => analyzeFile(file.path)),
        );
        
        result.files.addAll(batchResults);
        
        // Update categories
        for (final fileResult in batchResults) {
          final category = fileResult.category;
          result.categories[category] = (result.categories[category] ?? 0) + 1;
        }
      }
      
      // Find duplicates
      if (_enableDuplicateDetection) {
        result.duplicates = await _findDuplicatesInResults(result.files);
      }
      
      // Generate recommendations
      if (_enableRecommendations) {
        result.recommendations = await _generateRecommendations(result);
      }
      
      timer.stop();
      
      // Emit completion event
      _eventController.add(AnalysisEvent(
        type: AnalysisEventType.directoryAnalysisComplete,
        filePath: dirPath,
        result: result,
      ));
      
      return result;
    } catch (e, stackTrace) {
      timer.stop();
      EnhancedLogger.instance.error('Failed to analyze directory: $dirPath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Process analysis queue
  void _processAnalysisQueue() {
    if (_isProcessing || _analysisQueue.isEmpty) return;
    
    _isProcessing = true;
    
    while (_analysisQueue.isNotEmpty) {
      final task = _analysisQueue.removeFirst();
      
      try {
        _processTask(task);
      } catch (e) {
        EnhancedLogger.instance.error('Failed to process analysis task: ${task.filePath}', error: e);
      }
    }
    
    _isProcessing = false;
  }

  /// Process individual analysis task
  Future<void> _processTask(FileAnalysisTask task) async {
    final filePath = task.filePath;
    final file = File(filePath);
    
    if (!await file.exists()) return;
    
    final result = await _performFileAnalysis(file);
    final cacheKey = _generateCacheKey(filePath);
    
    // Cache result
    _analysisCache[cacheKey] = result;
    
    // Store metadata
    _fileMetadata[filePath] = FileMetadata(
      filePath: filePath,
      category: result.category,
      size: result.size,
      createdAt: result.createdAt,
      modifiedAt: result.modifiedAt,
      contentHash: result.contentHash,
      tags: result.tags,
      confidence: result.confidence,
    );
    
    // Emit event
    _eventController.add(AnalysisEvent(
      type: AnalysisEventType.fileAnalysisComplete,
      filePath: filePath,
      result: result,
    ));
  }

  /// Perform actual file analysis
  Future<FileAnalysisResult> _performFileAnalysis(File file) async {
    final timer = EnhancedPerformanceManager.instance.startTimer('file_analysis_core');
    
    try {
      final filePath = file.path;
      final stat = await file.stat();
      final extension = path.extension(filePath).toLowerCase();
      
      // Basic file info
      final size = stat.size;
      final createdAt = stat.modified;
      final modifiedAt = stat.modified;
      
      // Determine category
      final category = _determineCategory(extension);
      
      // Content analysis
      String contentHash = '';
      List<String> tags = [];
      double confidence = 0.0;
      Map<String, dynamic> contentAnalysis = {};
      
      if (_enableContentAnalysis && size < 10 * 1024 * 1024) { // 10MB limit
        final contentBytes = await file.readAsBytes();
        contentHash = sha256.convert(contentBytes).toString();
        
        // Analyze content based on file type
        contentAnalysis = await _analyzeContent(contentBytes, extension);
        tags = contentAnalysis['tags'] ?? [];
        confidence = contentAnalysis['confidence'] ?? 0.0;
      } else {
        // Hash based on metadata only for large files
        final metadata = '$filePath$size$modifiedAt';
        contentHash = sha256.convert(utf8.encode(metadata)).toString();
        confidence = 0.5;
      }
      
      timer.stop();
      
      return FileAnalysisResult(
        filePath: filePath,
        category: category,
        size: size,
        createdAt: createdAt,
        modifiedAt: modifiedAt,
        contentHash: contentHash,
        tags: tags,
        confidence: confidence,
        contentAnalysis: contentAnalysis,
        timestamp: DateTime.now(),
      );
    } catch (e, stackTrace) {
      timer.stop();
      EnhancedLogger.instance.error('Failed to perform file analysis: ${file.path}', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Determine file category
  String _determineCategory(String extension) {
    for (final category in _categories.values) {
      if (category.extensions.contains(extension)) {
        return category.name;
      }
    }
    return 'other';
  }

  /// Analyze file content
  Future<Map<String, dynamic>> _analyzeContent(Uint8List content, String extension) async {
    final result = <String, dynamic>{
      'tags': <String>[],
      'confidence': 0.0,
      'metadata': <String, dynamic>{},
    };
    
    try {
      // Text content analysis
      if (_isTextFile(extension)) {
        final textContent = utf8.decode(content, allowMalformed: true);
        final textAnalysis = await _analyzeTextContent(textContent);
        result.addAll(textAnalysis);
      }
      
      // Image content analysis
      else if (_isImageFile(extension)) {
        final imageAnalysis = await _analyzeImageContent(content);
        result.addAll(imageAnalysis);
      }
      
      // Document content analysis
      else if (_isDocumentFile(extension)) {
        final documentAnalysis = await _analyzeDocumentContent(content);
        result.addAll(documentAnalysis);
      }
      
      // Code content analysis
      else if (_isCodeFile(extension)) {
        final codeAnalysis = await _analyzeCodeContent(content);
        result.addAll(codeAnalysis);
      }
      
      // Generic analysis
      else {
        result['tags'] = ['unknown'];
        result['confidence'] = 0.3;
      }
    } catch (e) {
      EnhancedLogger.instance.warning('Content analysis failed: $e');
      result['tags'] = ['analysis_failed'];
      result['confidence'] = 0.0;
    }
    
    return result;
  }

  /// Analyze text content
  Future<Map<String, dynamic>> _analyzeTextContent(String content) async {
    final result = <String, dynamic>{
      'tags': <String>[],
      'confidence': 0.0,
      'metadata': <String, dynamic>{},
    };
    
    final words = content.toLowerCase().split(RegExp(r'\s+'));
    final wordCount = words.length;
    final charCount = content.length;
    
    result['metadata']['word_count'] = wordCount;
    result['metadata']['char_count'] = charCount;
    result['metadata']['line_count'] = content.split('\n').length;
    
    // Language detection (simplified)
    final language = _detectLanguage(content);
    result['metadata']['language'] = language;
    result['tags'].add('text');
    result['tags'].add(language);
    
    // Content type detection
    if (_isCodeContent(content)) {
      result['tags'].add('code');
      result['confidence'] = 0.8;
    } else if (_isLogContent(content)) {
      result['tags'].add('log');
      result['confidence'] = 0.7;
    } else if (_isConfigContent(content)) {
      result['tags'].add('config');
      result['confidence'] = 0.6;
    } else {
      result['tags'].add('document');
      result['confidence'] = 0.5;
    }
    
    return result;
  }

  /// Analyze image content
  Future<Map<String, dynamic>> _analyzeImageContent(Uint8List content) async {
    final result = <String, dynamic>{
      'tags': <String>[],
      'confidence': 0.0,
      'metadata': <String, dynamic>{},
    };
    
    // Basic image metadata (placeholder)
    result['metadata']['size'] = content.length;
    result['tags'].add('image');
    
    // Image type detection based on content
    if (_isJPEGImage(content)) {
      result['tags'].add('jpeg');
      result['confidence'] = 0.9;
    } else if (_isPNGImage(content)) {
      result['tags'].add('png');
      result['confidence'] = 0.9;
    } else if (_isGIFImage(content)) {
      result['tags'].add('gif');
      result['tags'].add('animated');
      result['confidence'] = 0.8;
    } else {
      result['tags'].add('unknown_image');
      result['confidence'] = 0.5;
    }
    
    return result;
  }

  /// Analyze document content
  Future<Map<String, dynamic>> _analyzeDocumentContent(Uint8List content) async {
    final result = <String, dynamic>{
      'tags': <String>[],
      'confidence': 0.0,
      'metadata': <String, dynamic>{},
    };
    
    result['metadata']['size'] = content.length;
    result['tags'].add('document');
    
    // PDF detection
    if (_isPDFDocument(content)) {
      result['tags'].add('pdf');
      result['confidence'] = 0.9;
    } else {
      result['tags'].add('unknown_document');
      result['confidence'] = 0.5;
    }
    
    return result;
  }

  /// Analyze code content
  Future<Map<String, dynamic>> _analyzeCodeContent(Uint8List content) async {
    final result = <String, dynamic>{
      'tags': <String>[],
      'confidence': 0.0,
      'metadata': <String, dynamic>{},
    };
    
    try {
      final codeContent = utf8.decode(content, allowMalformed: true);
      final language = _detectCodeLanguage(codeContent);
      
      result['metadata']['language'] = language;
      result['metadata']['size'] = content.length;
      result['metadata']['lines'] = codeContent.split('\n').length;
      
      result['tags'].add('code');
      result['tags'].add(language);
      result['confidence'] = 0.8;
    } catch (e) {
      result['tags'].add('code');
      result['tags'].add('unknown');
      result['confidence'] = 0.5;
    }
    
    return result;
  }

  /// Find duplicates in analysis results
  Future<Map<String, List<String>>> _findDuplicatesInResults(List<FileAnalysisResult> results) async {
    final duplicates = <String, List<String>>{};
    final hashGroups = <String, List<String>>{};
    
    // Group by content hash
    for (final result in results) {
      final hash = result.contentHash;
      if (!hashGroups.containsKey(hash)) {
        hashGroups[hash] = [];
      }
      hashGroups[hash]!.add(result.filePath);
    }
    
    // Find duplicates (groups with more than 1 file)
    for (final entry in hashGroups.entries) {
      if (entry.value.length > 1) {
        duplicates[entry.key] = entry.value;
      }
    }
    
    return duplicates;
  }

  /// Generate recommendations
  Future<List<FileRecommendation>> _generateRecommendations(DirectoryAnalysisResult analysis) async {
    final recommendations = <FileRecommendation>[];
    
    // Large files recommendation
    final largeFiles = analysis.files.where((f) => f.size > 100 * 1024 * 1024).toList(); // > 100MB
    if (largeFiles.isNotEmpty) {
      recommendations.add(FileRecommendation(
        type: RecommendationType.largeFiles,
        title: 'Large Files Found',
        description: 'Found ${largeFiles.length} files larger than 100MB',
        action: 'Consider compressing or archiving these files',
        priority: RecommendationPriority.medium,
        files: largeFiles.map((f) => f.filePath).toList(),
      ));
    }
    
    // Duplicate files recommendation
    if (analysis.duplicates.isNotEmpty) {
      recommendations.add(FileRecommendation(
        type: RecommendationType.duplicates,
        title: 'Duplicate Files Found',
        description: 'Found ${analysis.duplicates.length} sets of duplicate files',
        action: 'Review and remove unnecessary duplicates',
        priority: RecommendationPriority.high,
        files: analysis.duplicates.values.expand((files) => files).toList(),
      ));
    }
    
    // Uncategorized files recommendation
    final uncategorizedFiles = analysis.files.where((f) => f.category == 'other').toList();
    if (uncategorizedFiles.isNotEmpty) {
      recommendations.add(FileRecommendation(
        type: RecommendationType.categorization,
        title: 'Uncategorized Files',
        description: 'Found ${uncategorizedFiles.length} files in "other" category',
        action: 'Consider creating custom categories for these files',
        priority: RecommendationPriority.low,
        files: uncategorizedFiles.map((f) => f.filePath).toList(),
      ));
    }
    
    return recommendations;
  }

  /// Wait for analysis result
  Future<FileAnalysisResult> _waitForAnalysisResult(String cacheKey) async {
    final timeout = _analysisTimeout;
    final startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime) < timeout) {
      final result = _analysisCache[cacheKey];
      if (result != null) {
        return result;
      }
      
      await Future.delayed(Duration(milliseconds: 100));
    }
    
    throw TimeoutException('Analysis timeout for: $cacheKey', timeout);
  }

  /// Generate cache key
  String _generateCacheKey(String filePath) {
    final file = File(filePath);
    final stat = file.statSync();
    return '$filePath:${stat.modified}';
  }

  /// Helper methods for content analysis
  bool _isTextFile(String extension) {
    return ['.txt', '.md', '.json', '.yaml', '.xml', '.csv', '.log', '.conf', '.ini'].contains(extension);
  }

  bool _isImageFile(String extension) {
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg', '.webp'].contains(extension);
  }

  bool _isDocumentFile(String extension) {
    return ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx'].contains(extension);
  }

  bool _isCodeFile(String extension) {
    return ['.dart', '.js', '.ts', '.py', '.java', '.cpp', '.c', '.h', '.html', '.css', '.php', '.rb', '.go'].contains(extension);
  }

  bool _isJPEGImage(Uint8List content) {
    return content.length >= 3 && content[0] == 0xFF && content[1] == 0xD8 && content[2] == 0xFF;
  }

  bool _isPNGImage(Uint8List content) {
    return content.length >= 8 && 
           content[0] == 0x89 && content[1] == 0x50 && content[2] == 0x4E && content[3] == 0x47 &&
           content[4] == 0x0D && content[5] == 0x0A && content[6] == 0x1A && content[7] == 0x0A;
  }

  bool _isGIFImage(Uint8List content) {
    return content.length >= 6 && 
           content[0] == 0x47 && content[1] == 0x49 && content[2] == 0x46 &&
           content[3] == 0x38 && (content[4] == 0x37 || content[4] == 0x39) && content[5] == 0x61;
  }

  bool _isPDFDocument(Uint8List content) {
    return content.length >= 4 && 
           content[0] == 0x25 && content[1] == 0x50 && content[2] == 0x44 && content[3] == 0x46;
  }

  String _detectLanguage(String content) {
    // Simplified language detection
    final englishWords = ['the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for'];
    final spanishWords = ['el', 'la', 'y', 'o', 'pero', 'en', 'con', 'de', 'para', 'por'];
    final frenchWords = ['le', 'la', 'et', 'ou', 'mais', 'dans', 'avec', 'de', 'pour', 'par'];
    
    final words = content.toLowerCase().split(RegExp(r'\s+'));
    
    int englishCount = 0;
    int spanishCount = 0;
    int frenchCount = 0;
    
    for (final word in words) {
      if (englishWords.contains(word)) englishCount++;
      if (spanishWords.contains(word)) spanishCount++;
      if (frenchWords.contains(word)) frenchCount++;
    }
    
    if (englishCount > spanishCount && englishCount > frenchCount) {
      return 'english';
    } else if (spanishCount > englishCount && spanishCount > frenchCount) {
      return 'spanish';
    } else if (frenchCount > englishCount && frenchCount > spanishCount) {
      return 'french';
    } else {
      return 'unknown';
    }
  }

  bool _isCodeContent(String content) {
    final codePatterns = [
      RegExp(r'\bfunction\b'),
      RegExp(r'\bclass\b'),
      RegExp(r'\bimport\b'),
      RegExp(r'\bdef\b'),
      RegExp(r'\bpublic\b'),
      RegExp(r'\bprivate\b'),
      RegExp(r'\bvar\b'),
      RegExp(r'\blet\b'),
      RegExp(r'\bconst\b'),
    ];
    
    return codePatterns.any((pattern) => pattern.hasMatch(content));
  }

  bool _isLogContent(String content) {
    final logPatterns = [
      RegExp(r'\d{4}-\d{2}-\d{2}'), // Date
      RegExp(r'\d{2}:\d{2}:\d{2}'), // Time
      RegExp(r'\[ERROR\]'),
      RegExp(r'\[INFO\]'),
      RegExp(r'\[DEBUG\]'),
      RegExp(r'\[WARN\]'),
    ];
    
    return logPatterns.any((pattern) => pattern.hasMatch(content));
  }

  bool _isConfigContent(String content) {
    final configPatterns = [
      RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*\s*='),
      RegExp(r'^\s*[a-zA-Z_][a-zA-Z0-9_]*\s*:'),
      RegExp(r'^\s*#'),
      RegExp(r'^\s*;'),
    ];
    
    return configPatterns.any((pattern) => pattern.hasMatch(content));
  }

  String _detectCodeLanguage(String content) {
    final extensions = {
      'dart': RegExp(r'\bimport\b.*\bpackage\b'),
      'javascript': RegExp(r'\bfunction\b|\bvar\b|\blet\b|\bconst\b'),
      'python': RegExp(r'\bdef\b|\bimport\b|\bclass\b|\bif __name__\b'),
      'java': RegExp(r'\bpublic\s+class\b|\bimport\s+java\b'),
      'cpp': RegExp(r'#include\b|int\s+main\b'),
      'html': RegExp(r'<html|<body|<div|<span'),
      'css': RegExp(r'\.[a-zA-Z-]+\s*\{'),
      'php': RegExp(r'<\?php|\$\w+\s*='),
    };
    
    for (final entry in extensions.entries) {
      if (entry.value.hasMatch(content)) {
        return entry.key;
      }
    }
    
    return 'unknown';
  }

  /// Get file category
  FileCategory? getCategory(String categoryName) {
    return _categories[categoryName];
  }

  /// Get all categories
  Map<String, FileCategory> getAllCategories() {
    return Map.unmodifiable(_categories);
  }

  /// Get file metadata
  FileMetadata? getFileMetadata(String filePath) {
    return _fileMetadata[filePath];
  }

  /// Get duplicates
  Map<String, List<String>> getDuplicates() {
    return Map.unmodifiable(_duplicates);
  }

  /// Get recommendations
  List<FileRecommendation> getRecommendations(String? filePath) {
    if (filePath != null) {
      return _recommendations[filePath] ?? [];
    }
    return _recommendations.values.expand((recs) => recs).toList();
  }

  /// Clear cache
  void clearCache() {
    _analysisCache.clear();
    _fileMetadata.clear();
    _duplicates.clear();
    _recommendations.clear();
    
    EnhancedLogger.instance.info('AI File Organizer cache cleared');
  }

  /// Dispose
  void dispose() {
    _processingTimer?.cancel();
    _analysisQueue.clear();
    _analysisCache.clear();
    _fileMetadata.clear();
    _duplicates.clear();
    _recommendations.clear();
    
    _eventController.close();
    _progressController.close();
    
    EnhancedLogger.instance.info('AI File Organizer disposed');
  }
}

/// File category definition
class FileCategory {
  final String name;
  final String description;
  final List<String> extensions;
  final String icon;
  final int color;
  final int priority;

  FileCategory({
    required this.name,
    required this.description,
    required this.extensions,
    required this.icon,
    required this.color,
    required this.priority,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'extensions': extensions,
      'icon': icon,
      'color': color,
      'priority': priority,
    };
  }
}

/// File metadata
class FileMetadata {
  final String filePath;
  final String category;
  final int size;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String contentHash;
  final List<String> tags;
  final double confidence;

  FileMetadata({
    required this.filePath,
    required this.category,
    required this.size,
    required this.createdAt,
    required this.modifiedAt,
    required this.contentHash,
    required this.tags,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'file_path': filePath,
      'category': category,
      'size': size,
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt.toIso8601String(),
      'content_hash': contentHash,
      'tags': tags,
      'confidence': confidence,
    };
  }
}

/// File analysis result
class FileAnalysisResult {
  final String filePath;
  final String category;
  final int size;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String contentHash;
  final List<String> tags;
  final double confidence;
  final Map<String, dynamic> contentAnalysis;
  final DateTime timestamp;

  FileAnalysisResult({
    required this.filePath,
    required this.category,
    required this.size,
    required this.createdAt,
    required this.modifiedAt,
    required this.contentHash,
    required this.tags,
    required this.confidence,
    required this.contentAnalysis,
    required this.timestamp,
  });

  bool get isExpired => DateTime.now().difference(timestamp).inHours > 24;

  Map<String, dynamic> toJson() {
    return {
      'file_path': filePath,
      'category': category,
      'size': size,
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt.toIso8601String(),
      'content_hash': contentHash,
      'tags': tags,
      'confidence': confidence,
      'content_analysis': contentAnalysis,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Directory analysis result
class DirectoryAnalysisResult {
  final String directoryPath;
  final DateTime timestamp;
  final List<FileAnalysisResult> files;
  final Map<String, int> categories;
  final Map<String, List<String>> duplicates;
  final List<FileRecommendation> recommendations;

  DirectoryAnalysisResult({
    required this.directoryPath,
    required this.timestamp,
    required this.files,
    required this.categories,
    required this.duplicates,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() {
    return {
      'directory_path': directoryPath,
      'timestamp': timestamp.toIso8601String(),
      'files': files.map((f) => f.toJson()).toList(),
      'categories': categories,
      'duplicates': duplicates,
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
    };
  }
}

/// File analysis task
class FileAnalysisTask {
  final String filePath;
  final DateTime timestamp;
  final AnalysisPriority priority;

  FileAnalysisTask({
    required this.filePath,
    required this.timestamp,
    required this.priority,
  });
}

/// File recommendation
class FileRecommendation {
  final RecommendationType type;
  final String title;
  final String description;
  final String action;
  final RecommendationPriority priority;
  final List<String> files;

  FileRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.action,
    required this.priority,
    required this.files,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'title': title,
      'description': description,
      'action': action,
      'priority': priority.toString(),
      'files': files,
    };
  }
}

/// Analysis event
class AnalysisEvent {
  final AnalysisEventType type;
  final String filePath;
  final dynamic result;
  final DateTime timestamp;

  AnalysisEvent({
    required this.type,
    required this.filePath,
    this.result,
  }) : timestamp = DateTime.now();
}

/// Organization progress
class OrganizationProgress {
  final int totalFiles;
  final int processedFiles;
  final String currentFile;
  final AnalysisStage stage;

  OrganizationProgress({
    required this.totalFiles,
    required this.processedFiles,
    required this.currentFile,
    required this.stage,
  });

  double get progress => totalFiles > 0 ? processedFiles / totalFiles : 0.0;
}

/// Enums
enum AnalysisPriority { low, normal, high }
enum AnalysisStage { scanning, analyzing, categorizing, completing }
enum AnalysisEventType { fileAnalysisComplete, directoryAnalysisComplete, error }
enum RecommendationType { duplicates, largeFiles, categorization, organization }
enum RecommendationPriority { low, medium, high, critical }
