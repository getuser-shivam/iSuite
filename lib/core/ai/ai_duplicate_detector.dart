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
import 'ai_file_organizer.dart';

/// AI-Powered File Duplicate Detection Service
/// Features: Content-based detection, similarity analysis, smart grouping
/// Performance: Parallel processing, caching, optimized algorithms
/// Security: Privacy-first, local processing, secure hashing
class AIDuplicateDetector {
  static AIDuplicateDetector? _instance;
  static AIDuplicateDetector get instance => _instance ??= AIDuplicateDetector._internal();
  AIDuplicateDetector._internal();

  // Configuration
  late final bool _enableContentAnalysis;
  late final bool _enableSimilarityDetection;
  late final bool _enableSmartGrouping;
  late final bool _enableAutoCleanup;
  late final double _similarityThreshold;
  late final int _maxFileSizeForAnalysis;
  late final int _batchSize;
  
  // Detection algorithms
  final Map<String, FileHash> _fileHashes = {};
  final Map<String, List<String>> _exactDuplicates = {};
  final Map<String, List<SimilarFile>> _similarFiles = {};
  final Map<String, DuplicateGroup> _duplicateGroups = {};
  
  // Caching and performance
  final Map<String, DuplicateAnalysis> _analysisCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  Timer? _cacheCleanupTimer;
  
  // Processing queues
  final Queue<AnalysisTask> _analysisQueue = Queue();
  final Map<String, AnalysisTask> _activeTasks = {};
  Timer? _processingTimer;
  bool _isProcessing = false;
  
  // Event streams
  final StreamController<DuplicateEvent> _eventController = 
      StreamController<DuplicateEvent>.broadcast();
  final StreamController<DetectionProgress> _progressController = 
      StreamController<DetectionProgress>.broadcast();
  
  Stream<DuplicateEvent> get duplicateEvents => _eventController.stream;
  Stream<DetectionProgress> get progressEvents => _progressController.stream;

  /// Initialize AI Duplicate Detector
  Future<void> initialize() async {
    try {
      // Load configuration
      await _loadConfiguration();
      
      // Setup cache cleanup
      _setupCacheCleanup();
      
      // Setup processing timer
      _setupProcessingTimer();
      
      EnhancedLogger.instance.info('AI Duplicate Detector initialized');
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to initialize AI Duplicate Detector', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Load configuration
  Future<void> _loadConfiguration() async {
    final config = EnhancedConfigManager.instance;
    
    _enableContentAnalysis = config.getParameter('duplicate_detector.enable_content_analysis') ?? true;
    _enableSimilarityDetection = config.getParameter('duplicate_detector.enable_similarity') ?? true;
    _enableSmartGrouping = config.getParameter('duplicate_detector.enable_smart_grouping') ?? true;
    _enableAutoCleanup = config.getParameter('duplicate_detector.enable_auto_cleanup') ?? false;
    _similarityThreshold = config.getParameter('duplicate_detector.similarity_threshold') ?? 0.85;
    _maxFileSizeForAnalysis = config.getParameter('duplicate_detector.max_file_size_mb') ?? 50 * 1024 * 1024; // 50MB
    _batchSize = config.getParameter('duplicate_detector.batch_size') ?? 100;
  }

  /// Setup cache cleanup
  void _setupCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(Duration(minutes: 15), (_) {
      _cleanupCache();
    });
  }

  /// Setup processing timer
  void _setupProcessingTimer() {
    _processingTimer = Timer.periodic(Duration(milliseconds: 100), (_) {
      _processAnalysisQueue();
    });
  }

  /// Analyze file for duplicates
  Future<DuplicateAnalysis> analyzeFile(String filePath) async {
    final timer = EnhancedPerformanceManager.instance.startTimer('duplicate_analysis');
    
    try {
      // Check cache first
      final cacheKey = _generateCacheKey(filePath);
      final cached = _analysisCache[cacheKey];
      if (cached != null && !_isCacheExpired(cacheKey)) {
        timer.stop();
        return cached;
      }
      
      // Create analysis task
      final task = AnalysisTask(
        filePath: filePath,
        timestamp: DateTime.now(),
        priority: AnalysisPriority.normal,
      );
      
      // Add to queue
      _analysisQueue.add(task);
      _activeTasks[filePath] = task;
      
      // Wait for completion
      final result = await _waitForAnalysisCompletion(filePath);
      
      // Cache result
      _analysisCache[cacheKey] = result;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      timer.stop();
      
      // Emit event
      _eventController.add(DuplicateEvent(
        type: DuplicateEventType.fileAnalyzed,
        filePath: filePath,
        result: result,
      ));
      
      return result;
    } catch (e, stackTrace) {
      timer.stop();
      EnhancedLogger.instance.error('Failed to analyze file for duplicates: $filePath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Analyze directory for duplicates
  Future<DirectoryDuplicateAnalysis> analyzeDirectory(String dirPath) async {
    final timer = EnhancedPerformanceManager.instance.startTimer('directory_duplicate_analysis');
    
    try {
      final directory = Directory(dirPath);
      if (!await directory.exists()) {
        throw Exception('Directory does not exist: $dirPath');
      }
      
      final result = DirectoryDuplicateAnalysis(
        directoryPath: dirPath,
        timestamp: DateTime.now(),
        exactDuplicates: {},
        similarFiles: {},
        duplicateGroups: [],
        statistics: {},
      );
      
      // Get all files
      final files = await directory
          .list(recursive: true)
          .where((entity) => entity is File)
          .cast<File>()
          .toList();
      
      // Process in batches
      for (int i = 0; i < files.length; i += _batchSize) {
        final batch = files.skip(i).take(_batchSize).toList();
        
        // Update progress
        _progressController.add(DetectionProgress(
          totalFiles: files.length,
          processedFiles: i + batch.length,
          currentFile: batch.first.path,
          stage: DetectionStage.analyzing,
        ));
        
        // Analyze batch
        final batchResults = await Future.wait(
          batch.map((file) => analyzeFile(file.path)),
        );
        
        // Process results
        for (final analysis in batchResults) {
          _processAnalysisResult(analysis, result);
        }
      }
      
      // Find duplicate groups
      if (_enableSmartGrouping) {
        result.duplicateGroups = await _findDuplicateGroups(result);
      }
      
      // Calculate statistics
      result.statistics = _calculateStatistics(result);
      
      timer.stop();
      
      // Emit event
      _eventController.add(DuplicateEvent(
        type: DuplicateEventType.directoryAnalyzed,
        filePath: dirPath,
        result: result,
      ));
      
      return result;
    } catch (e, stackTrace) {
      timer.stop();
      EnhancedLogger.instance.error('Failed to analyze directory for duplicates: $dirPath', 
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
      } finally {
        _activeTasks.remove(task.filePath);
      }
    }
    
    _isProcessing = false;
  }

  /// Process individual analysis task
  Future<void> _processTask(AnalysisTask task) async {
    final filePath = task.filePath;
    final file = File(filePath);
    
    if (!await file.exists()) return;
    
    final analysis = await _performFileAnalysis(file);
    final cacheKey = _generateCacheKey(filePath);
    
    // Cache result
    _analysisCache[cacheKey] = analysis;
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    // Store file hash
    _fileHashes[filePath] = analysis.fileHash;
    
    // Check for exact duplicates
    await _checkExactDuplicates(analysis);
    
    // Check for similar files
    if (_enableSimilarityDetection) {
      await _checkSimilarFiles(analysis);
    }
    
    // Emit completion event
    _eventController.add(DuplicateEvent(
      type: DuplicateEventType.fileAnalyzed,
      filePath: filePath,
      result: analysis,
    ));
  }

  /// Perform file analysis
  Future<DuplicateAnalysis> _performFileAnalysis(File file) async {
    final filePath = file.path;
    final stat = await file.stat();
    final size = stat.size;
    
    // Generate file hash
    FileHash fileHash;
    
    if (size <= _maxFileSizeForAnalysis) {
      // Full content hash for small files
      fileHash = await _generateContentHash(file);
    } else {
      // Partial hash for large files
      fileHash = await _generatePartialHash(file);
    }
    
    // Generate metadata hash
    final metadataHash = await _generateMetadataHash(file, stat);
    
    // Calculate similarity features
    Map<String, dynamic> similarityFeatures = {};
    if (_enableContentAnalysis && size <= _maxFileSizeForAnalysis) {
      similarityFeatures = await _extractSimilarityFeatures(file);
    }
    
    return DuplicateAnalysis(
      filePath: filePath,
      fileHash: fileHash,
      metadataHash: metadataHash,
      size: size,
      modifiedAt: stat.modified,
      similarityFeatures: similarityFeatures,
      exactDuplicates: [],
      similarFiles: [],
      timestamp: DateTime.now(),
    );
  }

  /// Generate content hash
  Future<FileHash> _generateContentHash(File file) async {
    final bytes = await file.readAsBytes();
    final hash = sha256.convert(bytes);
    
    return FileHash(
      type: HashType.content,
      algorithm: 'SHA-256',
      value: hash.toString(),
      size: bytes.length,
      timestamp: DateTime.now(),
    );
  }

  /// Generate partial hash
  Future<FileHash> _generatePartialHash(File file) async {
    final randomAccessFile = await file.open();
    final fileSize = await randomAccessFile.length();
    
    // Sample different parts of the file
    final samples = <Uint8List>[];
    final sampleSize = math.min(4096, fileSize ~/ 10);
    
    // Sample from beginning, middle, and end
    final positions = [0, fileSize ~/ 2, fileSize - sampleSize];
    
    for (final position in positions) {
      await randomAccessFile.setPosition(position);
      final sample = Uint8List(sampleSize);
      await randomAccessFile.readInto(sample);
      samples.add(sample);
    }
    
    await randomAccessFile.close();
    
    // Combine samples and hash
    final combined = Uint8List(samples.fold(0, (sum, sample) => sum + sample.length));
    int offset = 0;
    
    for (final sample in samples) {
      combined.setRange(offset, offset + sample.length, sample);
      offset += sample.length;
    }
    
    final hash = sha256.convert(combined);
    
    return FileHash(
      type: HashType.partial,
      algorithm: 'SHA-256',
      value: hash.toString(),
      size: fileSize,
      timestamp: DateTime.now(),
    );
  }

  /// Generate metadata hash
  Future<FileHash> _generateMetadataHash(File file, FileStat stat) async {
    final metadata = {
      'name': path.basename(file.path),
      'size': stat.size,
      'modified': stat.modified.toIso8601String(),
      'extension': path.extension(file.path),
    };
    
    final metadataString = jsonEncode(metadata);
    final hash = sha256.convert(utf8.encode(metadataString));
    
    return FileHash(
      type: HashType.metadata,
      algorithm: 'SHA-256',
      value: hash.toString(),
      size: stat.size,
      timestamp: DateTime.now(),
    );
  }

  /// Extract similarity features
  Future<Map<String, dynamic>> _extractSimilarityFeatures(File file) async {
    final features = <String, dynamic>{};
    
    try {
      final bytes = await file.readAsBytes();
      final extension = path.extension(file.path).toLowerCase();
      
      // File size features
      features['size_category'] = _categorizeSize(bytes.length);
      features['size_log'] = math.log(bytes.length + 1);
      
      // Content features
      if (_isTextFile(extension)) {
        final content = utf8.decode(bytes, allowMalformed: true);
        features['content_type'] = 'text';
        features['word_count'] = content.split(RegExp(r'\s+')).length;
        features['char_count'] = content.length;
        features['line_count'] = content.split('\n').length;
        features['language'] = _detectLanguage(content);
        features['has_code'] = _containsCode(content);
      } else if (_isImageFile(extension)) {
        features['content_type'] = 'image';
        features['image_type'] = _detectImageType(bytes);
        features['dimensions'] = _detectImageDimensions(bytes);
      } else if (_isAudioFile(extension)) {
        features['content_type'] = 'audio';
        features['duration'] = _detectAudioDuration(bytes);
        features['bitrate'] = _detectAudioBitrate(bytes);
      } else if (_isVideoFile(extension)) {
        features['content_type'] = 'video';
        features['duration'] = _detectVideoDuration(bytes);
        features['resolution'] = _detectVideoResolution(bytes);
      } else {
        features['content_type'] = 'binary';
      }
      
      // Name features
      final fileName = path.basename(file.path);
      features['name_length'] = fileName.length;
      features['name_words'] = fileName.split(RegExp(r'[^\w]')).length;
      features['name_has_date'] = _containsDate(fileName);
      features['name_has_numbers'] = _containsNumbers(fileName);
      
    } catch (e) {
      EnhancedLogger.instance.warning('Failed to extract similarity features: $e');
      features['error'] = e.toString();
    }
    
    return features;
  }

  /// Check for exact duplicates
  Future<void> _checkExactDuplicates(DuplicateAnalysis analysis) async {
    final hash = analysis.fileHash.value;
    
    // Find existing files with same hash
    final existingFiles = _exactDuplicates[hash] ?? [];
    
    if (existingFiles.isNotEmpty) {
      // Add to exact duplicates list
      analysis.exactDuplicates = List.from(existingFiles);
      
      // Add current file to the list
      existingFiles.add(analysis.filePath);
      
      // Update all existing analyses
      for (final existingFile in existingFiles) {
        if (existingFile != analysis.filePath) {
          final existingAnalysis = _getCachedAnalysis(existingFile);
          if (existingAnalysis != null) {
            existingAnalysis.exactDuplicates.add(analysis.filePath);
          }
        }
      }
    } else {
      // Create new entry
      _exactDuplicates[hash] = [analysis.filePath];
    }
  }

  /// Check for similar files
  Future<void> _checkSimilarFiles(DuplicateAnalysis analysis) async {
    final similarFiles = <SimilarFile>[];
    
    // Compare with all existing files
    for (final existingAnalysis in _analysisCache.values) {
      if (existingAnalysis.filePath == analysis.filePath) continue;
      
      final similarity = await _calculateSimilarity(analysis, existingAnalysis);
      
      if (similarity >= _similarityThreshold) {
        similarFiles.add(SimilarFile(
          filePath: existingAnalysis.filePath,
          similarity: similarity,
          reasons: _getSimilarityReasons(analysis, existingAnalysis),
        ));
        
        // Add to existing analysis
        existingAnalysis.similarFiles.add(SimilarFile(
          filePath: analysis.filePath,
          similarity: similarity,
          reasons: _getSimilarityReasons(existingAnalysis, analysis),
        ));
      }
    }
    
    // Sort by similarity
    similarFiles.sort((a, b) => b.similarity.compareTo(a.similarity));
    
    analysis.similarFiles = similarFiles;
    
    // Store in similar files index
    for (final similarFile in similarFiles) {
      final key = similarFile.filePath;
      if (!_similarFiles.containsKey(key)) {
        _similarFiles[key] = [];
      }
      _similarFiles[key]!.add(analysis.filePath);
    }
  }

  /// Calculate similarity between two files
  Future<double> _calculateSimilarity(DuplicateAnalysis a1, DuplicateAnalysis a2) async {
    double totalSimilarity = 0.0;
    int featureCount = 0;
    
    // Hash similarity (exact match)
    if (a1.fileHash.value == a2.fileHash.value) {
      return 1.0;
    }
    
    // Size similarity
    final sizeRatio = math.min(a1.size, a2.size) / math.max(a1.size, a2.size);
    totalSimilarity += sizeRatio * 0.2;
    featureCount++;
    
    // Metadata similarity
    final metadataSimilarity = _calculateMetadataSimilarity(a1, a2);
    totalSimilarity += metadataSimilarity * 0.3;
    featureCount++;
    
    // Content similarity
    if (a1.similarityFeatures.isNotEmpty && a2.similarityFeatures.isNotEmpty) {
      final contentSimilarity = _calculateContentSimilarity(a1.similarityFeatures, a2.similarityFeatures);
      totalSimilarity += contentSimilarity * 0.5;
      featureCount++;
    }
    
    return featureCount > 0 ? totalSimilarity / featureCount : 0.0;
  }

  /// Calculate metadata similarity
  double _calculateMetadataSimilarity(DuplicateAnalysis a1, DuplicateAnalysis a2) {
    double similarity = 0.0;
    int features = 0;
    
    // Name similarity
    final name1 = path.basename(a1.filePath);
    final name2 = path.basename(a2.filePath);
    final nameSimilarity = _calculateStringSimilarity(name1, name2);
    similarity += nameSimilarity;
    features++;
    
    // Extension similarity
    final ext1 = path.extension(a1.filePath);
    final ext2 = path.extension(a2.filePath);
    if (ext1 == ext2) {
      similarity += 1.0;
    } else {
      similarity += 0.0;
    }
    features++;
    
    // Size similarity
    final sizeRatio = math.min(a1.size, a2.size) / math.max(a1.size, a2.size);
    similarity += sizeRatio;
    features++;
    
    return features > 0 ? similarity / features : 0.0;
  }

  /// Calculate content similarity
  double _calculateContentSimilarity(Map<String, dynamic> f1, Map<String, dynamic> f2) {
    double similarity = 0.0;
    int features = 0;
    
    // Content type similarity
    if (f1['content_type'] == f2['content_type']) {
      similarity += 1.0;
    } else {
      similarity += 0.0;
    }
    features++;
    
    // Size category similarity
    if (f1['size_category'] == f2['size_category']) {
      similarity += 1.0;
    } else {
      similarity += 0.0;
    }
    features++;
    
    // Text-specific features
    if (f1['content_type'] == 'text' && f2['content_type'] == 'text') {
      // Word count similarity
      final wc1 = f1['word_count'] as int? ?? 0;
      final wc2 = f2['word_count'] as int? ?? 0;
      final wcRatio = wc1 > 0 && wc2 > 0 ? math.min(wc1, wc2) / math.max(wc1, wc2) : 0.0;
      similarity += wcRatio;
      features++;
      
      // Language similarity
      if (f1['language'] == f2['language']) {
        similarity += 1.0;
      } else {
        similarity += 0.0;
      }
      features++;
    }
    
    // Image-specific features
    if (f1['content_type'] == 'image' && f2['content_type'] == 'image') {
      // Image type similarity
      if (f1['image_type'] == f2['image_type']) {
        similarity += 1.0;
      } else {
        similarity += 0.0;
      }
      features++;
    }
    
    return features > 0 ? similarity / features : 0.0;
  }

  /// Calculate string similarity (Levenshtein distance)
  double _calculateStringSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    
    final longer = s1.length > s2.length ? s1 : s2;
    final shorter = s1.length > s2.length ? s2 : s1;
    
    if (longer.isEmpty) return 1.0;
    
    final editDistance = _levenshteinDistance(s1, s2);
    return (longer.length - editDistance) / longer.length;
  }

  /// Calculate Levenshtein distance
  int _levenshteinDistance(String a, String b) {
    final matrix = List.generate(
      a.length + 1,
      (i) => List.generate(b.length + 1, (j) => i == 0 ? j : j == 0 ? i : 0),
    );
    
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = math.min(
          matrix[i - 1][j] + 1,      // deletion
          math.min(
            matrix[i][j - 1] + 1,  // insertion
            matrix[i - 1][j - 1] + cost, // substitution
          ),
        );
      }
    }
    
    return matrix[a.length][b.length];
  }

  /// Get similarity reasons
  List<String> _getSimilarityReasons(DuplicateAnalysis a1, DuplicateAnalysis a2) {
    final reasons = <String>[];
    
    if (a1.size == a2.size) {
      reasons.add('Same size');
    }
    
    if (path.extension(a1.filePath) == path.extension(a2.filePath)) {
      reasons.add('Same extension');
    }
    
    if (a1.similarityFeatures['content_type'] == a2.similarityFeatures['content_type']) {
      reasons.add('Same content type');
    }
    
    return reasons;
  }

  /// Find duplicate groups
  Future<List<DuplicateGroup>> _findDuplicateGroups(DirectoryDuplicateAnalysis analysis) async {
    final groups = <DuplicateGroup>[];
    
    // Group exact duplicates
    for (final entry in analysis.exactDuplicates.entries) {
      if (entry.value.length > 1) {
        groups.add(DuplicateGroup(
          type: DuplicateType.exact,
          files: entry.value,
          hash: entry.key,
          totalSize: entry.value.fold(0, (sum, file) => sum + (File(file).lengthSync())),
          savings: (entry.value.length - 1) * (File(entry.value.first).lengthSync()),
          timestamp: DateTime.now(),
        ));
      }
    }
    
    // Group similar files
    for (final entry in analysis.similarFiles.entries) {
      if (entry.value.length > 1) {
        groups.add(DuplicateGroup(
          type: DuplicateType.similar,
          files: entry.value.map((sf) => sf.filePath).toList(),
          similarity: entry.value.map((sf) => sf.similarity).reduce(math.max),
          timestamp: DateTime.now(),
        ));
      }
    }
    
    return groups;
  }

  /// Calculate statistics
  Map<String, dynamic> _calculateStatistics(DirectoryDuplicateAnalysis analysis) {
    final totalFiles = analysis.exactDuplicates.values.fold(0, (sum, files) => sum + files.length);
    final totalDuplicates = analysis.exactDuplicates.values.where((files) => files.length > 1).fold(0, (sum, files) => sum + (files.length - 1));
    final totalSize = analysis.duplicateGroups.fold(0, (sum, group) => sum + group.totalSize);
    final totalSavings = analysis.duplicateGroups.fold(0, (sum, group) => sum + (group.savings ?? 0));
    
    return {
      'total_files': totalFiles,
      'total_duplicates': totalDuplicates,
      'duplicate_ratio': totalFiles > 0 ? totalDuplicates / totalFiles : 0.0,
      'total_size': totalSize,
      'total_savings': totalSavings,
      'savings_ratio': totalSize > 0 ? totalSavings / totalSize : 0.0,
      'exact_duplicate_groups': analysis.exactDuplicates.values.where((files) => files.length > 1).length,
      'similar_file_groups': analysis.similarFiles.values.where((files) => files.length > 1).length,
    };
  }

  /// Wait for analysis completion
  Future<DuplicateAnalysis> _waitForAnalysisCompletion(String filePath) async {
    final timeout = Duration(seconds: 30);
    final startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime) < timeout) {
      final task = _activeTasks[filePath];
      if (task == null) {
        final analysis = _getCachedAnalysis(filePath);
        if (analysis != null) {
          return analysis;
        }
      }
      
      await Future.delayed(Duration(milliseconds: 100));
    }
    
    throw TimeoutException('Analysis timeout for: $filePath', timeout);
  }

  /// Get cached analysis
  DuplicateAnalysis? _getCachedAnalysis(String filePath) {
    final cacheKey = _generateCacheKey(filePath);
    return _analysisCache[cacheKey];
  }

  /// Process analysis result
  void _processAnalysisResult(DuplicateAnalysis analysis, DirectoryDuplicateAnalysis result) {
    // Add exact duplicates
    if (analysis.exactDuplicates.isNotEmpty) {
      final hash = analysis.fileHash.value;
      if (!result.exactDuplicates.containsKey(hash)) {
        result.exactDuplicates[hash] = [];
      }
      result.exactDuplicates[hash]!.addAll(analysis.exactDuplicates);
      result.exactDuplicates[hash]!.add(analysis.filePath);
    }
    
    // Add similar files
    if (analysis.similarFiles.isNotEmpty) {
      for (final similarFile in analysis.similarFiles) {
        final key = similarFile.filePath;
        if (!result.similarFiles.containsKey(key)) {
          result.similarFiles[key] = [];
        }
        result.similarFiles[key]!.add(analysis.filePath);
      }
    }
  }

  /// Generate cache key
  String _generateCacheKey(String filePath) {
    final file = File(filePath);
    final stat = file.statSync();
    return '$filePath:${stat.modified}';
  }

  /// Check if cache entry is expired
  bool _isCacheExpired(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return true;
    
    return DateTime.now().difference(timestamp).inHours > 24;
  }

  /// Cleanup cache
  void _cleanupCache() {
    final expiredKeys = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (_isCacheExpired(entry.key)) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _analysisCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      EnhancedLogger.instance.info('Cleaned up ${expiredKeys.length} expired cache entries');
    }
  }

  /// Helper methods for feature extraction
  String _categorizeSize(int size) {
    if (size < 1024) return 'tiny';
    if (size < 10 * 1024) return 'small';
    if (size < 1024 * 1024) return 'medium';
    if (size < 100 * 1024 * 1024) return 'large';
    return 'huge';
  }

  bool _isTextFile(String extension) {
    return ['.txt', '.md', '.json', '.yaml', '.xml', '.csv', '.log', '.conf', '.ini', '.dart', '.js', '.ts', '.py', '.java', '.cpp', '.c', '.h', '.html', '.css', '.php', '.rb', '.go'].contains(extension);
  }

  bool _isImageFile(String extension) {
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg', '.webp', '.tiff'].contains(extension);
  }

  bool _isAudioFile(String extension) {
    return ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a', '.wma'].contains(extension);
  }

  bool _isVideoFile(String extension) {
    return ['.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm', '.mkv', '.m4v'].contains(extension);
  }

  String _detectLanguage(String content) {
    // Simplified language detection
    final englishWords = ['the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for'];
    final spanishWords = ['el', 'la', 'y', 'o', 'pero', 'en', 'con', 'de', 'para'];
    final frenchWords = ['le', 'la', 'et', 'ou', 'mais', 'dans', 'avec', 'de', 'pour'];
    
    final words = content.toLowerCase().split(RegExp(r'\s+'));
    
    int englishCount = 0;
    int spanishCount = 0;
    int frenchCount = 0;
    
    for (final word in words) {
      if (englishWords.contains(word)) englishCount++;
      if (spanishWords.contains(word)) spanishCount++;
      if (frenchWords.contains(word)) frenchCount++;
    }
    
    if (englishCount > spanishCount && englishCount > frenchCount) return 'english';
    if (spanishCount > englishCount && spanishCount > frenchCount) return 'spanish';
    if (frenchCount > englishCount && frenchCount > spanishCount) return 'french';
    
    return 'unknown';
  }

  bool _containsCode(String content) {
    final codePatterns = [
      RegExp(r'\bfunction\b'),
      RegExp(r'\bclass\b'),
      RegExp(r'\bimport\b'),
      RegExp(r'\bdef\b'),
      RegExp(r'\bpublic\b'),
      RegExp(r'\bprivate\b'),
    ];
    
    return codePatterns.any((pattern) => pattern.hasMatch(content));
  }

  String _detectImageType(Uint8List bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'jpeg';
    }
    if (bytes.length >= 8 && 
        bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 &&
        bytes[4] == 0x0D && bytes[5] == 0x0A && bytes[6] == 0x1A && bytes[7] == 0x0A) {
      return 'png';
    }
    if (bytes.length >= 6 && 
        bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 &&
        bytes[3] == 0x38 && (bytes[4] == 0x37 || bytes[4] == 0x39) && bytes[5] == 0x61) {
      return 'gif';
    }
    
    return 'unknown';
  }

  String _detectImageDimensions(Uint8List bytes) {
    // Simplified dimension detection
    return 'unknown';
  }

  String _detectAudioDuration(Uint8List bytes) {
    // Simplified duration detection
    return 'unknown';
  }

  String _detectAudioBitrate(Uint8List bytes) {
    // Simplified bitrate detection
    return 'unknown';
  }

  String _detectVideoDuration(Uint8List bytes) {
    // Simplified duration detection
    return 'unknown';
  }

  String _detectVideoResolution(Uint8List bytes) {
    // Simplified resolution detection
    return 'unknown';
  }

  bool _containsDate(String fileName) {
    final datePattern = RegExp(r'\d{4}[-_]\d{2}[-_]\d{2}');
    return datePattern.hasMatch(fileName);
  }

  bool _containsNumbers(String fileName) {
    return RegExp(r'\d').hasMatch(fileName);
  }

  /// Get duplicate statistics
  Map<String, dynamic> getDuplicateStatistics() {
    return {
      'analyzed_files': _analysisCache.length,
      'exact_duplicates': _exactDuplicates.length,
      'similar_files': _similarFiles.length,
      'duplicate_groups': _duplicateGroups.length,
      'cache_size': _analysisCache.length,
      'active_tasks': _activeTasks.length,
    };
  }

  /// Clear all data
  void clearAllData() {
    _fileHashes.clear();
    _exactDuplicates.clear();
    _similarFiles.clear();
    _duplicateGroups.clear();
    _analysisCache.clear();
    _cacheTimestamps.clear();
    _analysisQueue.clear();
    _activeTasks.clear();
    
    EnhancedLogger.instance.info('All duplicate detection data cleared');
  }

  /// Dispose
  void dispose() {
    _cacheCleanupTimer?.cancel();
    _processingTimer?.cancel();
    
    _fileHashes.clear();
    _exactDuplicates.clear();
    _similarFiles.clear();
    _duplicateGroups.clear();
    _analysisCache.clear();
    _cacheTimestamps.clear();
    _analysisQueue.clear();
    _activeTasks.clear();
    
    _eventController.close();
    _progressController.close();
    
    EnhancedLogger.instance.info('AI Duplicate Detector disposed');
  }
}

/// File hash
class FileHash {
  final HashType type;
  final String algorithm;
  final String value;
  final int size;
  final DateTime timestamp;

  FileHash({
    required this.type,
    required this.algorithm,
    required this.value,
    required this.size,
    required this.timestamp,
  });
}

/// Duplicate analysis
class DuplicateAnalysis {
  final String filePath;
  final FileHash fileHash;
  final FileHash metadataHash;
  final int size;
  final DateTime modifiedAt;
  final Map<String, dynamic> similarityFeatures;
  final List<String> exactDuplicates;
  final List<SimilarFile> similarFiles;
  final DateTime timestamp;

  DuplicateAnalysis({
    required this.filePath,
    required this.fileHash,
    required this.metadataHash,
    required this.size,
    required this.modifiedAt,
    required this.similarityFeatures,
    required this.exactDuplicates,
    required this.similarFiles,
    required this.timestamp,
  });
}

/// Similar file
class SimilarFile {
  final String filePath;
  final double similarity;
  final List<String> reasons;

  SimilarFile({
    required this.filePath,
    required this.similarity,
    required this.reasons,
  });
}

/// Directory duplicate analysis
class DirectoryDuplicateAnalysis {
  final String directoryPath;
  final DateTime timestamp;
  final Map<String, List<String>> exactDuplicates;
  final Map<String, List<String>> similarFiles;
  final List<DuplicateGroup> duplicateGroups;
  final Map<String, dynamic> statistics;

  DirectoryDuplicateAnalysis({
    required this.directoryPath,
    required this.timestamp,
    required this.exactDuplicates,
    required this.similarFiles,
    required this.duplicateGroups,
    required this.statistics,
  });
}

/// Duplicate group
class DuplicateGroup {
  final DuplicateType type;
  final List<String> files;
  final String? hash;
  final double? similarity;
  final int? totalSize;
  final int? savings;
  final DateTime timestamp;

  DuplicateGroup({
    required this.type,
    required this.files,
    this.hash,
    this.similarity,
    this.totalSize,
    this.savings,
    required this.timestamp,
  });
}

/// Analysis task
class AnalysisTask {
  final String filePath;
  final DateTime timestamp;
  final AnalysisPriority priority;

  AnalysisTask({
    required this.filePath,
    required this.timestamp,
    required this.priority,
  });
}

/// Duplicate event
class DuplicateEvent {
  final DuplicateEventType type;
  final String? filePath;
  final dynamic result;
  final DateTime timestamp;

  DuplicateEvent({
    required this.type,
    this.filePath,
    this.result,
  }) : timestamp = DateTime.now();
}

/// Detection progress
class DetectionProgress {
  final int totalFiles;
  final int processedFiles;
  final String currentFile;
  final DetectionStage stage;
  final DateTime timestamp;

  DetectionProgress({
    required this.totalFiles,
    required this.processedFiles,
    required this.currentFile,
    required this.stage,
  }) : timestamp = DateTime.now();

  double get progress => totalFiles > 0 ? processedFiles / totalFiles : 0.0;
}

/// Enums
enum HashType { content, partial, metadata }
enum DuplicateType { exact, similar }
enum AnalysisPriority { low, normal, high }
enum DuplicateEventType { fileAnalyzed, directoryAnalyzed, duplicateFound }
enum DetectionStage { scanning, analyzing, grouping, completing }
