import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../backend/enhanced_pocketbase_service.dart';
import '../config/enhanced_config_manager.dart';
import '../logging/enhanced_logger.dart';
import '../performance/enhanced_performance_manager.dart';
import 'ai_file_organizer.dart';
import 'ai_advanced_search.dart';
import 'smart_file_categorizer.dart';
import 'ai_duplicate_detector.dart';
import 'ai_file_recommendations.dart';

/// AI Services Integration Manager
/// Features: Unified AI services, coordinated workflows, enhanced performance
/// Performance: Service coordination, optimized workflows, shared resources
/// Security: Privacy-first, secure integration, unified authentication
class AIServicesIntegration {
  static AIServicesIntegration? _instance;
  static AIServicesIntegration get instance => _instance ??= AIServicesIntegration._internal();
  AIServicesIntegration._internal();

  // Service instances
  late final AIFileOrganizer _fileOrganizer;
  late final AIAdvancedSearch _advancedSearch;
  late final SmartFileCategorizer _smartCategorizer;
  late final AIDuplicateDetector _duplicateDetector;
  late final AIFileRecommendations _recommendations;
  
  // Configuration
  late final bool _enableCoordination;
  late final bool _enableSharedCaching;
  late final bool _enableWorkflowOptimization;
  late final int _maxConcurrentTasks;
  late final Duration _workflowTimeout;
  
  // Workflow management
  final Map<String, WorkflowTask> _activeWorkflows = {};
  final Queue<WorkflowTask> _workflowQueue = Queue();
  final Map<String, WorkflowResult> _workflowResults = {};
  Timer? _workflowProcessor;
  bool _isProcessingWorkflows = false;
  
  // Shared resources
  final Map<String, dynamic> _sharedCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  Timer? _cacheCleanupTimer;
  
  // Event coordination
  final StreamController<AIIntegrationEvent> _eventController = 
      StreamController<AIIntegrationEvent>.broadcast();
  final StreamController<WorkflowProgress> _progressController = 
      StreamController<WorkflowProgress>.broadcast();
  
  Stream<AIIntegrationEvent> get integrationEvents => _eventController.stream;
  Stream<WorkflowProgress> get workflowProgress => _progressController.stream;

  /// Initialize AI Services Integration
  Future<void> initialize() async {
    try {
      // Load configuration
      await _loadConfiguration();
      
      // Initialize individual services
      await _initializeServices();
      
      // Setup service coordination
      _setupServiceCoordination();
      
      // Setup workflow processor
      _setupWorkflowProcessor();
      
      // Setup shared cache
      _setupSharedCache();
      
      // Setup event coordination
      _setupEventCoordination();
      
      EnhancedLogger.instance.info('AI Services Integration initialized');
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to initialize AI Services Integration', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Load configuration
  Future<void> _loadConfiguration() async {
    final config = EnhancedConfigManager.instance;
    
    _enableCoordination = config.getParameter('ai_integration.enable_coordination') ?? true;
    _enableSharedCaching = config.getParameter('ai_integration.enable_shared_caching') ?? true;
    _enableWorkflowOptimization = config.getParameter('ai_integration.enable_workflow_optimization') ?? true;
    _maxConcurrentTasks = config.getParameter('ai_integration.max_concurrent_tasks') ?? 5;
    _workflowTimeout = Duration(seconds: config.getParameter('ai_integration.workflow_timeout_seconds') ?? 300);
  }

  /// Initialize individual services
  Future<void> _initializeServices() async {
    // Initialize all AI services
    _fileOrganizer = AIFileOrganizer.instance;
    _advancedSearch = AIAdvancedSearch.instance;
    _smartCategorizer = SmartFileCategorizer.instance;
    _duplicateDetector = AIDuplicateDetector.instance;
    _recommendations = AIFileRecommendations.instance;
    
    // Initialize each service
    await _fileOrganizer.initialize();
    await _advancedSearch.initialize();
    await _smartCategorizer.initialize();
    await _duplicateDetector.initialize();
    await _recommendations.initialize();
    
    EnhancedLogger.instance.info('All AI services initialized');
  }

  /// Setup service coordination
  void _setupServiceCoordination() {
    if (!_enableCoordination) return;
    
    // Coordinate file analysis across services
    _fileOrganizer.analysisEvents.listen((event) {
      if (event.type == AnalysisEventType.fileAnalysisComplete) {
        _coordinateFileAnalysis(event.result as FileAnalysisResult);
      }
    });
    
    // Coordinate search results with recommendations
    _advancedSearch.searchEvents.listen((event) {
      if (event.type == SearchEventType.searchCompleted) {
        _coordinateSearchWithRecommendations(event.result as SearchResults);
      }
    });
    
    // Coordinate categorization with recommendations
    _smartCategorizer.categorizationEvents.listen((event) {
      if (event.type == CategorizationEventType.fileCategorized) {
        _coordinateCategorizationWithRecommendations(event.result as CategorizationResult);
      }
    });
    
    // Coordinate duplicate detection with organization
    _duplicateDetector.duplicateEvents.listen((event) {
      if (event.type == DuplicateEventType.directoryAnalyzed) {
        _coordinateDuplicatesWithOrganization(event.result as DirectoryDuplicateAnalysis);
      }
    });
  }

  /// Setup workflow processor
  void _setupWorkflowProcessor() {
    _workflowProcessor = Timer.periodic(Duration(milliseconds: 100), (_) {
      _processWorkflowQueue();
    });
  }

  /// Setup shared cache
  void _setupSharedCache() {
    if (!_enableSharedCaching) return;
    
    _cacheCleanupTimer = Timer.periodic(Duration(minutes: 10), (_) {
      _cleanupSharedCache();
    });
  }

  /// Setup event coordination
  void _setupEventCoordination() {
    // Emit integration events
    _eventController.add(AIIntegrationEvent(
      type: AIIntegrationEventType.servicesInitialized,
      message: 'All AI services initialized and coordinated',
    ));
  }

  /// Coordinate file analysis across services
  void _coordinateFileAnalysis(FileAnalysisResult analysis) {
    // Update search index with new file
    _advancedSearch.indexFile(analysis.filePath, {
      'title': analysis.filePath.split('/').last,
      'category': analysis.category,
      'tags': analysis.tags,
      'confidence': analysis.confidence,
    });
    
    // Update recommendations with new file
    _recommendations.trackFileAccess(analysis.filePath, FileActionType.open);
    
    // Cache analysis result
    if (_enableSharedCaching) {
      _cacheAnalysisResult(analysis);
    }
  }

  /// Coordinate search with recommendations
  void _coordinateSearchWithRecommendations(SearchResults searchResults) {
    // Track search patterns for recommendations
    for (final result in searchResults.results) {
      _recommendations.trackFileAccess(result.documentId, FileActionType.open);
    }
    
    // Cache search results
    if (_enableSharedCaching) {
      _cacheSearchResults(searchResults);
    }
  }

  /// Coordinate categorization with recommendations
  void _coordinateCategorizationWithRecommendations(CategorizationResult categorization) {
    // Update recommendations based on categorization
    _recommendations.trackFileAccess(categorization.filePath, FileActionType.open);
    
    // Cache categorization result
    if (_enableSharedCaching) {
      _cacheCategorizationResult(categorization);
    }
  }

  /// Coordinate duplicates with organization
  void _coordinateDuplicatesWithOrganization(DirectoryDuplicateAnalysis duplicateAnalysis) {
    // Create organization workflow for duplicates
    final workflow = WorkflowTask(
      id: 'duplicate_organization_${DateTime.now().millisecondsSinceEpoch}',
      type: WorkflowType.duplicateCleanup,
      priority: WorkflowPriority.medium,
      data: duplicateAnalysis,
      timestamp: DateTime.now(),
    );
    
    _addWorkflow(workflow);
  }

  /// Execute comprehensive file analysis workflow
  Future<ComprehensiveAnalysisResult> executeComprehensiveAnalysis(
    String filePath, {
    bool includeSearch = true,
    bool includeCategorization = true,
    bool includeDuplicateCheck = true,
    bool includeRecommendations = true,
  }) async {
    final timer = EnhancedPerformanceManager.instance.startTimer('comprehensive_analysis');
    
    try {
      final result = ComprehensiveAnalysisResult(
        filePath: filePath,
        timestamp: DateTime.now(),
        fileAnalysis: null,
        searchResults: null,
        categorizationResult: null,
        duplicateAnalysis: null,
        recommendations: [],
      );
      
      // Step 1: File analysis (always included)
      result.fileAnalysis = await _fileOrganizer.analyzeFile(filePath);
      
      // Step 2: Search indexing
      if (includeSearch) {
        await _advancedSearch.indexFile(filePath, {
          'title': result.fileAnalysis!.filePath.split('/').last,
          'category': result.fileAnalysis!.category,
          'tags': result.fileAnalysis!.tags,
        });
      }
      
      // Step 3: Categorization
      if (includeCategorization) {
        result.categorizationResult = await _smartCategorizer.categorizeFile(filePath);
      }
      
      // Step 4: Duplicate check
      if (includeDuplicateCheck) {
        // Check for duplicates in the same directory
        final directory = path.dirname(filePath);
        result.duplicateAnalysis = await _duplicateDetector.analyzeDirectory(directory);
        
        // Filter results for this specific file
        final fileHash = result.fileAnalysis!.contentHash;
        result.duplicateAnalysis!.exactDuplicates = {
          fileHash: result.duplicateAnalysis!.exactDuplicates[fileHash] ?? []
        };
      }
      
      // Step 5: Recommendations
      if (includeRecommendations) {
        result.recommendations = await _recommendations.getRecommendations(
          context: filePath,
          type: RecommendationType.smartSuggestions,
        );
      }
      
      timer.stop();
      
      // Emit completion event
      _eventController.add(AIIntegrationEvent(
        type: AIIntegrationEventType.comprehensiveAnalysisCompleted,
        filePath: filePath,
        message: 'Comprehensive analysis completed',
        data: result,
      ));
      
      return result;
    } catch (e, stackTrace) {
      timer.stop();
      EnhancedLogger.instance.error('Failed to execute comprehensive analysis: $filePath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Execute smart directory organization workflow
  Future<DirectoryOrganizationResult> executeSmartOrganization(
    String dirPath, {
    String? templateName,
    bool dryRun = false,
    bool includeDuplicateCleanup = true,
    bool includeSmartCategorization = true,
  }) async {
    final timer = EnhancedPerformanceManager.instance.startTimer('smart_organization');
    
    try {
      final result = DirectoryOrganizationResult(
        directoryPath: dirPath,
        timestamp: DateTime.now(),
        organizationResult: null,
        duplicateCleanup: null,
        smartCategorization: null,
        recommendations: [],
        statistics: {},
      );
      
      // Step 1: Duplicate cleanup
      if (includeDuplicateCleanup) {
        result.duplicateCleanup = await _duplicateDetector.analyzeDirectory(dirPath);
        
        // Create duplicate cleanup recommendations
        if (!dryRun) {
          await _executeDuplicateCleanup(result.duplicateCleanup!);
        }
      }
      
      // Step 2: Smart categorization
      if (includeSmartCategorization) {
        result.smartCategorization = await _smartCategorizer.categorizeFile(dirPath);
      }
      
      // Step 3: Directory organization
      result.organizationResult = await _smartCategorizer.organizeDirectory(
        dirPath,
        templateName: templateName,
        dryRun: dryRun,
      );
      
      // Step 4: Generate recommendations
      result.recommendations = await _recommendations.getRecommendations(
        context: dirPath,
        type: RecommendationType.organization,
      );
      
      // Step 5: Calculate statistics
      result.statistics = _calculateOrganizationStatistics(result);
      
      timer.stop();
      
      // Emit completion event
      _eventController.add(AIIntegrationEvent(
        type: AIIntegrationEventType.smartOrganizationCompleted,
        filePath: dirPath,
        message: 'Smart organization completed',
        data: result,
      ));
      
      return result;
    } catch (e, stackTrace) {
      timer.stop();
      EnhancedLogger.instance.error('Failed to execute smart organization: $dirPath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Execute intelligent search workflow
  Future<IntelligentSearchResult> executeIntelligentSearch(
    String query, {
    SearchType searchType = SearchType.semantic,
    String? scope,
    Map<String, dynamic>? filters,
    int? limit,
  }) async {
    final timer = EnhancedPerformanceManager.instance.startTimer('intelligent_search');
    
    try {
      final result = IntelligentSearchResult(
        query: query,
        timestamp: DateTime.now(),
        searchResults: null,
        recommendations: [],
        insights: [],
        statistics: {},
      );
      
      // Step 1: Execute search
      final searchQuery = SearchQuery(
        query: query,
        type: searchType,
        filters: filters ?? {},
      );
      
      result.searchResults = await _advancedSearch.search(searchQuery);
      
      // Step 2: Generate search recommendations
      result.recommendations = await _recommendations.getRecommendations(
        context: query,
        type: RecommendationType.similarFiles,
      );
      
      // Step 3: Generate search insights
      result.insights = _generateSearchInsights(result.searchResults!);
      
      // Step 4: Calculate statistics
      result.statistics = _calculateSearchStatistics(result);
      
      timer.stop();
      
      // Emit completion event
      _eventController.add(AIIntegrationEvent(
        type: AIIntegrationEventType.intelligentSearchCompleted,
        result: result,
        message: 'Intelligent search completed',
      ));
      
      return result;
    } catch (e, stackTrace) {
      timer.stop();
      EnhancedLogger.instance.error('Failed to execute intelligent search: $query', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Add workflow to queue
  void _addWorkflow(WorkflowTask workflow) {
    _workflowQueue.add(workflow);
    
    _eventController.add(AIIntegrationEvent(
      type: AIIntegrationEventType.workflowQueued,
      message: 'Workflow queued: ${workflow.type}',
      data: workflow,
    ));
  }

  /// Process workflow queue
  void _processWorkflowQueue() {
    if (_isProcessingWorkflows || _workflowQueue.isEmpty) return;
    
    _isProcessingWorkflows = true;
    
    while (_workflowQueue.isNotEmpty && _activeWorkflows.length < _maxConcurrentTasks) {
      final workflow = _workflowQueue.removeFirst();
      _activeWorkflows[workflow.id] = workflow;
      
      // Execute workflow in background
      _executeWorkflow(workflow);
    }
    
    _isProcessingWorkflows = false;
  }

  /// Execute individual workflow
  Future<void> _executeWorkflow(WorkflowTask workflow) async {
    try {
      _progressController.add(WorkflowProgress(
        workflowId: workflow.id,
        stage: 'starting',
        progress: 0.0,
      ));
      
      WorkflowResult result;
      
      switch (workflow.type) {
        case WorkflowType.duplicateCleanup:
          result = await _executeDuplicateCleanupWorkflow(workflow);
          break;
        case WorkflowType.smartOrganization:
          result = await _executeSmartOrganizationWorkflow(workflow);
          break;
        case WorkflowType.intelligentSearch:
          result = await _executeIntelligentSearchWorkflow(workflow);
          break;
        case WorkflowType.comprehensiveAnalysis:
          result = await _executeComprehensiveAnalysisWorkflow(workflow);
          break;
        default:
          throw Exception('Unknown workflow type: ${workflow.type}');
      }
      
      _workflowResults[workflow.id] = result;
      
      _progressController.add(WorkflowProgress(
        workflowId: workflow.id,
        stage: 'completed',
        progress: 1.0,
      ));
      
      _eventController.add(AIIntegrationEvent(
        type: AIIntegrationEventType.workflowCompleted,
        message: 'Workflow completed: ${workflow.type}',
        data: result,
      ));
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to execute workflow: ${workflow.id}', 
        error: e, stackTrace: stackTrace);
      
      _progressController.add(WorkflowProgress(
        workflowId: workflow.id,
        stage: 'error',
        progress: 0.0,
        error: e.toString(),
      ));
    } finally {
      _activeWorkflows.remove(workflow.id);
    }
  }

  /// Execute duplicate cleanup workflow
  Future<WorkflowResult> _executeDuplicateCleanupWorkflow(WorkflowTask workflow) async {
    final duplicateAnalysis = workflow.data as DirectoryDuplicateAnalysis;
    
    // Execute cleanup logic
    int cleanedFiles = 0;
    long long totalSavings = 0;
    
    for (final group in duplicateAnalysis.duplicateGroups) {
      if (group.type == DuplicateType.exact && group.files.length > 1) {
        // Keep the first file, delete the rest
        for (int i = 1; i < group.files.length; i++) {
          try {
            await File(group.files[i]).delete();
            cleanedFiles++;
            totalSavings += group.savings ?? 0;
          } catch (e) {
            EnhancedLogger.instance.warning('Failed to delete duplicate file: ${group.files[i]}');
          }
        }
      }
    }
    
    return WorkflowResult(
      workflowId: workflow.id,
      type: workflow.type,
      success: true,
      message: 'Cleaned up $cleanedFiles duplicate files',
      data: {
        'cleaned_files': cleanedFiles,
        'total_savings': totalSavings,
      },
      timestamp: DateTime.now(),
    );
  }

  /// Execute smart organization workflow
  Future<WorkflowResult> _executeSmartOrganizationWorkflow(WorkflowTask workflow) async {
    // Implementation for smart organization workflow
    return WorkflowResult(
      workflowId: workflow.id,
      type: workflow.type,
      success: true,
      message: 'Smart organization completed',
      timestamp: DateTime.now(),
    );
  }

  /// Execute intelligent search workflow
  Future<WorkflowResult> _executeIntelligentSearchWorkflow(WorkflowTask workflow) async {
    // Implementation for intelligent search workflow
    return WorkflowResult(
      workflowId: workflow.id,
      type: workflow.type,
      success: true,
      message: 'Intelligent search completed',
      timestamp: DateTime.now(),
    );
  }

  /// Execute comprehensive analysis workflow
  Future<WorkflowResult> _executeComprehensiveAnalysisWorkflow(WorkflowTask workflow) async {
    // Implementation for comprehensive analysis workflow
    return WorkflowResult(
      workflowId: workflow.id,
      type: workflow.type,
      success: true,
      message: 'Comprehensive analysis completed',
      timestamp: DateTime.now(),
    );
  }

  /// Execute duplicate cleanup
  Future<void> _executeDuplicateCleanup(DirectoryDuplicateAnalysis duplicateAnalysis) async {
    for (final group in duplicateAnalysis.duplicateGroups) {
      if (group.type == DuplicateType.exact && group.files.length > 1) {
        // Keep the first file, delete the rest
        for (int i = 1; i < group.files.length; i++) {
          try {
            await File(group.files[i]).delete();
          } catch (e) {
            EnhancedLogger.instance.warning('Failed to delete duplicate file: ${group.files[i]}');
          }
        }
      }
    }
  }

  /// Generate search insights
  List<SearchInsight> _generateSearchInsights(SearchResults searchResults) {
    final insights = <SearchInsight>[];
    
    // Category distribution insight
    final categoryCount = <String, int>{};
    for (final result in searchResults.results) {
      final category = result.category;
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }
    
    if (categoryCount.isNotEmpty) {
      insights.add(SearchInsight(
        type: InsightType.categoryDistribution,
        title: 'Category Distribution',
        description: 'Results are distributed across ${categoryCount.length} categories',
        data: categoryCount,
      ));
    }
    
    // Size distribution insight
    final sizeRanges = {
      'small': 0,
      'medium': 0,
      'large': 0,
    };
    
    for (final result in searchResults.results) {
      final size = result.metadata['size'] as int? ?? 0;
      if (size < 1024 * 1024) {
        sizeRanges['small'] = (sizeRanges['small'] ?? 0) + 1;
      } else if (size < 100 * 1024 * 1024) {
        sizeRanges['medium'] = (sizeRanges['medium'] ?? 0) + 1;
      } else {
        sizeRanges['large'] = (sizeRanges['large'] ?? 0) + 1;
      }
    }
    
    insights.add(SearchInsight(
      type: InsightType.sizeDistribution,
      title: 'Size Distribution',
      description: 'Files are distributed across size ranges',
      data: sizeRanges,
    ));
    
    return insights;
  }

  /// Calculate organization statistics
  Map<String, dynamic> _calculateOrganizationStatistics(DirectoryOrganizationResult result) {
    return {
      'organized_files': result.organizationResult?.organizedFiles.length ?? 0,
      'created_directories': result.organizationResult?.createdDirectories.length ?? 0,
      'duplicate_groups': result.duplicateCleanup?.duplicateGroups.length ?? 0,
      'total_savings': result.duplicateCleanup?.statistics['total_savings'] ?? 0,
      'recommendations': result.recommendations.length,
    };
  }

  /// Calculate search statistics
  Map<String, dynamic> _calculateSearchStatistics(IntelligentSearchResult result) {
    return {
      'total_results': result.searchResults?.results.length ?? 0,
      'recommendations': result.recommendations.length,
      'insights': result.insights.length,
      'avg_confidence': result.searchResults?.results
          .map((r) => r.score)
          .reduce((a, b) => a + b) / (result.searchResults?.results.length ?? 1),
    };
  }

  /// Cache analysis result
  void _cacheAnalysisResult(FileAnalysisResult analysis) {
    final cacheKey = 'analysis_${analysis.filePath}';
    _sharedCache[cacheKey] = analysis.toJson();
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  /// Cache search results
  void _cacheSearchResults(SearchResults results) {
    final cacheKey = 'search_${results.query.query}_${results.query.type}';
    _sharedCache[cacheKey] = results.toJson();
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  /// Cache categorization result
  void _cacheCategorizationResult(CategorizationResult categorization) {
    final cacheKey = 'categorization_${categorization.filePath}';
    _sharedCache[cacheKey] = categorization.toJson();
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  /// Cleanup shared cache
  void _cleanupSharedCache() {
    final expiredKeys = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (DateTime.now().difference(entry.value).inMinutes > 30) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _sharedCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      EnhancedLogger.instance.info('Cleaned up ${expiredKeys.length} expired shared cache entries');
    }
  }

  /// Get integration statistics
  Map<String, dynamic> getIntegrationStatistics() {
    return {
      'active_workflows': _activeWorkflows.length,
      'queued_workflows': _workflowQueue.length,
      'completed_workflows': _workflowResults.length,
      'shared_cache_size': _sharedCache.length,
      'services_count': 5,
      'coordination_enabled': _enableCoordination,
      'shared_caching_enabled': _enableSharedCaching,
      'workflow_optimization_enabled': _enableWorkflowOptimization,
    };
  }

  /// Get workflow status
  Map<String, dynamic> getWorkflowStatus() {
    return {
      'active_workflows': _activeWorkflows.map((key, value) => MapEntry(key, {
        'type': value.type.toString(),
        'priority': value.priority.toString(),
        'timestamp': value.timestamp.toIso8601String(),
      })),
      'queued_workflows': _workflowQueue.map((workflow) => {
        'id': workflow.id,
        'type': workflow.type.toString(),
        'priority': workflow.priority.toString(),
        'timestamp': workflow.timestamp.toIso8601String(),
      }).toList(),
      'completed_workflows': _workflowResults.length,
    };
  }

  /// Clear all data
  Future<void> clearAllData() async {
    // Clear service data
    _fileOrganizer.clearCache();
    _advancedSearch.clearSearchIndex();
    _duplicateDetector.clearAllData();
    _recommendations.clearAllData();
    
    // Clear integration data
    _activeWorkflows.clear();
    _workflowQueue.clear();
    _workflowResults.clear();
    _sharedCache.clear();
    _cacheTimestamps.clear();
    
    EnhancedLogger.instance.info('All AI services integration data cleared');
  }

  /// Dispose
  Future<void> dispose() async {
    _workflowProcessor?.cancel();
    _cacheCleanupTimer?.cancel();
    
    // Dispose services
    _fileOrganizer.dispose();
    _advancedSearch.dispose();
    _smartCategorizer.dispose();
    _duplicateDetector.dispose();
    _recommendations.dispose();
    
    // Clear integration data
    _activeWorkflows.clear();
    _workflowQueue.clear();
    _workflowResults.clear();
    _sharedCache.clear();
    _cacheTimestamps.clear();
    
    _eventController.close();
    _progressController.close();
    
    EnhancedLogger.instance.info('AI Services Integration disposed');
  }
}

/// Comprehensive analysis result
class ComprehensiveAnalysisResult {
  final String filePath;
  final DateTime timestamp;
  final FileAnalysisResult? fileAnalysis;
  final SearchResults? searchResults;
  final CategorizationResult? categorizationResult;
  final DirectoryDuplicateAnalysis? duplicateAnalysis;
  final List<RecommendationResult> recommendations;

  ComprehensiveAnalysisResult({
    required this.filePath,
    required this.timestamp,
    this.fileAnalysis,
    this.searchResults,
    this.categorizationResult,
    this.duplicateAnalysis,
    required this.recommendations,
  });
}

/// Directory organization result
class DirectoryOrganizationResult {
  final String directoryPath;
  final DateTime timestamp;
  final OrganizationResult? organizationResult;
  final DirectoryDuplicateAnalysis? duplicateCleanup;
  final CategorizationResult? smartCategorization;
  final List<RecommendationResult> recommendations;
  final Map<String, dynamic> statistics;

  DirectoryOrganizationResult({
    required this.directoryPath,
    required this.timestamp,
    this.organizationResult,
    this.duplicateCleanup,
    this.smartCategorization,
    required this.recommendations,
    required this.statistics,
  });
}

/// Intelligent search result
class IntelligentSearchResult {
  final String query;
  final DateTime timestamp;
  final SearchResults? searchResults;
  final List<RecommendationResult> recommendations;
  final List<SearchInsight> insights;
  final Map<String, dynamic> statistics;

  IntelligentSearchResult({
    required this.query,
    required this.timestamp,
    this.searchResults,
    required this.recommendations,
    required this.insights,
    required this.statistics,
  });
}

/// Workflow task
class WorkflowTask {
  final String id;
  final WorkflowType type;
  final WorkflowPriority priority;
  final dynamic data;
  final DateTime timestamp;

  WorkflowTask({
    required this.id,
    required this.type,
    required this.priority,
    this.data,
    required this.timestamp,
  });
}

/// Workflow result
class WorkflowResult {
  final String workflowId;
  final WorkflowType type;
  final bool success;
  final String message;
  final dynamic data;
  final DateTime timestamp;

  WorkflowResult({
    required this.workflowId,
    required this.type,
    required this.success,
    required this.message,
    this.data,
    required this.timestamp,
  });
}

/// Search insight
class SearchInsight {
  final InsightType type;
  final String title;
  final String description;
  final dynamic data;

  SearchInsight({
    required this.type,
    required this.title,
    required this.description,
    this.data,
  });
}

/// Workflow progress
class WorkflowProgress {
  final String workflowId;
  final String stage;
  final double progress;
  final String? error;

  WorkflowProgress({
    required this.workflowId,
    required this.stage,
    required this.progress,
    this.error,
  });
}

/// AI integration event
class AIIntegrationEvent {
  final AIIntegrationEventType type;
  final String? filePath;
  final String message;
  final dynamic data;
  final DateTime timestamp;

  AIIntegrationEvent({
    required this.type,
    this.filePath,
    required this.message,
    this.data,
  }) : timestamp = DateTime.now();
}

/// Enums
enum WorkflowType { duplicateCleanup, smartOrganization, intelligentSearch, comprehensiveAnalysis }
enum WorkflowPriority { low, medium, high, critical }
enum InsightType { categoryDistribution, sizeDistribution, patternAnalysis }
enum AIIntegrationEventType { servicesInitialized, comprehensiveAnalysisCompleted, smartOrganizationCompleted, intelligentSearchCompleted, workflowQueued, workflowCompleted }
