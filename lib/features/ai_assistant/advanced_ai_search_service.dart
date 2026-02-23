import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../core/config/central_config.dart';
import '../../core/advanced_performance_service.dart';
import '../../core/logging/logging_service.dart';
import 'ai_file_analysis_service.dart';

/// Advanced AI-Powered Search Service with LLM Integration
/// Provides intelligent file discovery and semantic search using Large Language Models
class AdvancedAISearchService {
  static final AdvancedAISearchService _instance = AdvancedAISearchService._internal();
  factory AdvancedAISearchService() => _instance;
  AdvancedAISearchService._internal();

  final CentralConfig _config = CentralConfig.instance;
  final AdvancedPerformanceService _performanceService = AdvancedPerformanceService();
  final LoggingService _logger = LoggingService();
  final AIFileAnalysisService _aiAnalysisService = AIFileAnalysisService();

  StreamController<SearchEvent> _searchEventController = StreamController.broadcast();
  StreamController<LLMEvent> _llmEventController = StreamController.broadcast();

  Stream<SearchEvent> get searchEvents => _searchEventController.stream;
  Stream<LLMEvent> get llmEvents => _llmEventController.stream;

  // LLM Configuration
  String? _llmApiKey;
  String? _llmEndpoint;
  String? _llmModel;
  Map<String, dynamic> _llmConfig = {};

  // Search indexes and caches
  final Map<String, SemanticIndex> _semanticIndexes = {};
  final Map<String, SearchCache> _searchCache = {};
  final Map<String, QueryHistory> _queryHistory = {};

  // AI models for different search types
  final Map<String, AIModel> _searchModels = {};
  final Map<String, VectorDatabase> _vectorDatabases = {};

  bool _isInitialized = false;
  bool _llmEnabled = true;
  bool _offlineMode = false;

  /// Initialize advanced AI search service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing advanced AI search service', 'AdvancedAISearchService');

      // Register with CentralConfig
      await _config.registerComponent(
        'AdvancedAISearchService',
        '2.0.0',
        'Advanced AI-powered search with LLM integration for intelligent file discovery',
        dependencies: ['CentralConfig', 'AdvancedPerformanceService', 'AIFileAnalysisService'],
        parameters: {
          // LLM Configuration
          'ai.search.llm_enabled': true,
          'ai.search.llm_provider': 'openai', // openai, anthropic, local, custom
          'ai.search.llm_model': 'gpt-4',
          'ai.search.llm_api_key': '',
          'ai.search.llm_endpoint': 'https://api.openai.com/v1',
          'ai.search.llm_temperature': 0.7,
          'ai.search.llm_max_tokens': 2000,
          'ai.search.llm_timeout': 30000,

          // Search Configuration
          'ai.search.semantic_enabled': true,
          'ai.search.vector_search_enabled': true,
          'ai.search.fuzzy_search_enabled': true,
          'ai.search.context_search_enabled': true,
          'ai.search.multi_modal_search': true,

          // Performance Configuration
          'ai.search.cache_enabled': true,
          'ai.search.cache_ttl': 3600000, // 1 hour
          'ai.search.max_results': 100,
          'ai.search.batch_size': 50,
          'ai.search.parallel_queries': 3,

          // Index Configuration
          'ai.search.index_update_interval': 3600000, // 1 hour
          'ai.search.index_chunk_size': 1000,
          'ai.search.embedding_dimensions': 1536, // OpenAI ada-002 dimensions

          // Offline Configuration
          'ai.search.offline_enabled': true,
          'ai.search.local_model_path': 'models/',
          'ai.search.offline_fallback': true,

          // Privacy & Security
          'ai.search.privacy_mode': false,
          'ai.search.content_filtering': true,
          'ai.search.audit_logging': true,

          // Advanced Features
          'ai.search.conversation_memory': true,
          'ai.search.context_awareness': true,
          'ai.search.personalization': true,
          'ai.search.collaborative_search': false,

          // Integration Settings
          'ai.search.integrate_file_analysis': true,
          'ai.search.integrate_network_scan': true,
          'ai.search.integrate_cloud_storage': true,
        }
      );

      // Initialize LLM configuration
      await _initializeLLMConfig();

      // Initialize search models
      await _initializeSearchModels();

      // Initialize vector databases
      await _initializeVectorDatabases();

      // Initialize semantic indexes
      await _initializeSemanticIndexes();

      // Initialize search cache
      await _initializeSearchCache();

      // Start background indexing
      _startBackgroundIndexing();

      _isInitialized = true;
      _logger.info('Advanced AI search service initialized successfully', 'AdvancedAISearchService');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize advanced AI search service', 'AdvancedAISearchService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Perform advanced AI-powered search
  Future<SearchResults> advancedSearch(String query, {
    SearchContext? context,
    SearchOptions? options,
  }) async {
    try {
      _logger.info('Performing advanced AI search: "$query"', 'AdvancedAISearchService');

      final startTime = DateTime.now();

      // Check cache first
      if (options?.useCache ?? true) {
        final cachedResult = await _checkSearchCache(query, context);
        if (cachedResult != null) {
          _emitSearchEvent(SearchEventType.cacheHit, data: {'query': query});
          return cachedResult;
        }
      }

      // Process query with AI
      final processedQuery = await _processQueryWithAI(query, context);

      // Perform multi-modal search
      final results = await _performMultiModalSearch(processedQuery, options);

      // Apply AI ranking and filtering
      final rankedResults = await _applyAIRanking(results, processedQuery);

      // Generate AI insights
      final insights = await _generateSearchInsights(query, rankedResults);

      final searchResults = SearchResults(
        query: query,
        processedQuery: processedQuery.query,
        results: rankedResults,
        insights: insights,
        searchTime: DateTime.now().difference(startTime),
        totalResults: rankedResults.length,
        searchContext: context,
        aiConfidence: processedQuery.confidence,
      );

      // Cache results
      if (options?.useCache ?? true) {
        await _cacheSearchResults(query, searchResults, context);
      }

      // Add to query history
      await _addToQueryHistory(query, searchResults);

      _emitSearchEvent(SearchEventType.searchCompleted, data: {
        'query': query,
        'results_count': rankedResults.length,
        'search_time': searchResults.searchTime.inMilliseconds,
        'ai_confidence': processedQuery.confidence,
      });

      return searchResults;

    } catch (e, stackTrace) {
      _logger.error('Advanced AI search failed: $query', 'AdvancedAISearchService',
          error: e, stackTrace: stackTrace);

      _emitSearchEvent(SearchEventType.searchFailed, data: {
        'query': query,
        'error': e.toString(),
      });

      // Return empty results on failure
      return SearchResults(
        query: query,
        processedQuery: query,
        results: [],
        insights: [],
        searchTime: Duration.zero,
        totalResults: 0,
      );
    }
  }

  /// Process query with AI for better understanding
  Future<ProcessedQuery> _processQueryWithAI(String query, SearchContext? context) async {
    try {
      if (!_llmEnabled || _offlineMode) {
        return ProcessedQuery(
          originalQuery: query,
          query: query,
          intent: SearchIntent.general,
          entities: [],
          confidence: 0.5,
        );
      }

      // Use LLM to understand query intent and extract entities
      final llmResponse = await _callLLM(_buildQueryUnderstandingPrompt(query, context));

      // Parse LLM response
      final processedQuery = _parseQueryUnderstandingResponse(llmResponse, query);

      _emitLLMEvent(LLMEventType.queryProcessed, data: {
        'original_query': query,
        'processed_query': processedQuery.query,
        'intent': processedQuery.intent.toString(),
        'confidence': processedQuery.confidence,
      });

      return processedQuery;

    } catch (e) {
      _logger.warning('LLM query processing failed, using fallback', 'AdvancedAISearchService', error: e);

      // Fallback to basic query processing
      return ProcessedQuery(
        originalQuery: query,
        query: query,
        intent: SearchIntent.general,
        entities: _extractBasicEntities(query),
        confidence: 0.3,
      );
    }
  }

  /// Perform multi-modal search across different data sources
  Future<List<SearchResult>> _performMultiModalSearch(ProcessedQuery query, SearchOptions? options) async {
    final results = <SearchResult>[];

    // Parallel search across different sources
    final searchFutures = <Future<List<SearchResult>>>[];

    // File system search
    searchFutures.add(_searchFileSystem(query, options));

    // Network search (FTP, SMB, etc.)
    if (_config.getParameter('ai.search.integrate_network_scan', defaultValue: true)) {
      searchFutures.add(_searchNetwork(query, options));
    }

    // Cloud storage search
    if (_config.getParameter('ai.search.integrate_cloud_storage', defaultValue: true)) {
      searchFutures.add(_searchCloudStorage(query, options));
    }

    // Semantic search
    if (_config.getParameter('ai.search.semantic_enabled', defaultValue: true)) {
      searchFutures.add(_semanticSearch(query, options));
    }

    // Execute all searches in parallel
    final searchResults = await Future.wait(searchFutures);

    // Merge and deduplicate results
    final seenPaths = <String>{};
    for (final resultList in searchResults) {
      for (final result in resultList) {
        if (!seenPaths.contains(result.filePath)) {
          results.add(result);
          seenPaths.add(result.filePath);
        }
      }
    }

    return results;
  }

  /// Apply AI ranking and filtering to search results
  Future<List<SearchResult>> _applyAIRanking(List<SearchResult> results, ProcessedQuery query) async {
    if (results.isEmpty) return results;

    try {
      // Use AI to rank results based on relevance
      final rankingPrompt = _buildRankingPrompt(query, results.take(20).toList());
      final llmResponse = await _callLLM(rankingPrompt);

      // Parse ranking response and reorder results
      final rankedResults = _parseRankingResponse(llmResponse, results);

      return rankedResults;

    } catch (e) {
      _logger.warning('AI ranking failed, using basic ranking', 'AdvancedAISearchService', error: e);

      // Fallback to basic scoring
      return _applyBasicRanking(results, query);
    }
  }

  /// Generate AI-powered search insights
  Future<List<SearchInsight>> _generateSearchInsights(String query, List<SearchResult> results) async {
    final insights = <SearchInsight>[];

    try {
      // Analyze result patterns
      if (results.isEmpty) {
        insights.add(SearchInsight(
          type: InsightType.noResults,
          message: 'No files found matching your search. Try broadening your search terms.',
          confidence: 1.0,
        ));
      } else if (results.length > 50) {
        insights.add(SearchInsight(
          type: InsightType.manyResults,
          message: 'Found ${results.length} results. Consider making your search more specific.',
          confidence: 0.8,
        ));
      }

      // Analyze file type distribution
      final typeDistribution = _analyzeFileTypeDistribution(results);
      if (typeDistribution.isNotEmpty) {
        insights.add(SearchInsight(
          type: InsightType.fileTypeDistribution,
          message: 'Results include: ${typeDistribution.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
          confidence: 0.9,
          data: typeDistribution,
        ));
      }

      // Generate AI-powered insights
      if (_llmEnabled) {
        final insightPrompt = _buildInsightPrompt(query, results);
        final llmResponse = await _callLLM(insightPrompt);
        final aiInsights = _parseInsightResponse(llmResponse);

        insights.addAll(aiInsights);
      }

    } catch (e) {
      _logger.warning('Insight generation failed', 'AdvancedAISearchService', error: e);
    }

    return insights;
  }

  /// Conversational search with context awareness
  Future<ConversationalSearchResult> conversationalSearch({
    required String query,
    String? conversationId,
    List<PreviousMessage>? conversationHistory,
  }) async {
    try {
      // Get or create conversation context
      final context = await _getConversationContext(conversationId);

      // Build conversational prompt
      final conversationalPrompt = _buildConversationalPrompt(
        query,
        context,
        conversationHistory
      );

      // Get LLM response
      final llmResponse = await _callLLM(conversationalPrompt);

      // Parse conversational response
      final parsedResponse = _parseConversationalResponse(llmResponse);

      // Update conversation context
      await _updateConversationContext(context, query, parsedResponse.response);

      // Perform search based on AI understanding
      final searchQuery = parsedResponse.extractedSearchQuery ?? query;
      final searchResults = await advancedSearch(searchQuery);

      return ConversationalSearchResult(
        conversationId: context.id,
        query: query,
        response: parsedResponse.response,
        searchResults: searchResults,
        suggestedFollowUps: parsedResponse.suggestedFollowUps,
        context: context,
      );

    } catch (e) {
      _logger.error('Conversational search failed', 'AdvancedAISearchService', error: e);

      // Fallback to regular search
      final searchResults = await advancedSearch(query);
      return ConversationalSearchResult(
        query: query,
        response: 'I encountered an error, but here are the search results for your query.',
        searchResults: searchResults,
        suggestedFollowUps: [],
      );
    }
  }

  /// Build and maintain semantic index
  Future<void> buildSemanticIndex(List<String> filePaths) async {
    try {
      _logger.info('Building semantic index for ${filePaths.length} files', 'AdvancedAISearchService');

      final batchSize = _config.getParameter('ai.search.batch_size', defaultValue: 50);
      final batches = _createBatches(filePaths, batchSize);

      for (final batch in batches) {
        await _processSemanticIndexBatch(batch);
      }

      _logger.info('Semantic index built successfully', 'AdvancedAISearchService');

    } catch (e) {
      _logger.error('Semantic index building failed', 'AdvancedAISearchService', error: e);
    }
  }

  /// Get search analytics and insights
  Future<SearchAnalytics> getSearchAnalytics({DateTime? startDate, DateTime? endDate}) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    // Analyze query patterns
    final queryPatterns = await _analyzeQueryPatterns(start, end);

    // Analyze search effectiveness
    final searchEffectiveness = await _analyzeSearchEffectiveness(start, end);

    // Analyze user behavior
    final userBehavior = await _analyzeUserBehavior(start, end);

    return SearchAnalytics(
      period: DateRange(start: start, end: end),
      totalQueries: queryPatterns.totalQueries,
      uniqueQueries: queryPatterns.uniqueQueries,
      averageQueryLength: queryPatterns.averageQueryLength,
      popularSearchTerms: queryPatterns.popularTerms,
      searchSuccessRate: searchEffectiveness.successRate,
      averageResultsPerQuery: searchEffectiveness.averageResults,
      noResultQueries: searchEffectiveness.noResultQueries,
      userEngagementMetrics: userBehavior,
    );
  }

  // LLM Integration Methods

  /// Call LLM with prompt
  Future<String> _callLLM(String prompt, {Map<String, dynamic>? parameters}) async {
    if (!_llmEnabled || _llmApiKey == null) {
      throw Exception('LLM not available');
    }

    try {
      final requestBody = {
        'model': _llmModel ?? 'gpt-4',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'temperature': parameters?['temperature'] ?? _llmConfig['temperature'] ?? 0.7,
        'max_tokens': parameters?['max_tokens'] ?? _llmConfig['max_tokens'] ?? 2000,
      };

      final response = await http.post(
        Uri.parse('${_llmEndpoint}/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_llmApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(Duration(milliseconds: _llmConfig['timeout'] ?? 30000));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('LLM API error: ${response.statusCode}');
      }

    } catch (e) {
      _logger.error('LLM call failed', 'AdvancedAISearchService', error: e);
      _emitLLMEvent(LLMEventType.callFailed, data: {'error': e.toString()});
      throw;
    }
  }

  /// Build query understanding prompt
  String _buildQueryUnderstandingPrompt(String query, SearchContext? context) {
    return '''
Analyze this search query and provide a detailed understanding:

Query: "$query"
${context != null ? 'Context: ${context.toString()}' : ''}

Please provide:
1. The intent of the search (find_files, organize_files, analyze_content, etc.)
2. Key entities and concepts mentioned
3. Any specific file types, dates, or locations mentioned
4. The confidence level of your understanding (0.0-1.0)

Format your response as JSON:
{
  "intent": "intent_type",
  "entities": ["entity1", "entity2"],
  "specifications": {
    "file_types": ["pdf", "docx"],
    "date_range": "last_week",
    "location": "/documents"
  },
  "confidence": 0.85,
  "clarification_needed": false
}
''';
  }

  /// Initialize LLM configuration
  Future<void> _initializeLLMConfig() async {
    _llmEnabled = _config.getParameter('ai.search.llm_enabled', defaultValue: true);
    _llmApiKey = _config.getParameter('ai.search.llm_api_key', defaultValue: '');
    _llmEndpoint = _config.getParameter('ai.search.llm_endpoint', defaultValue: 'https://api.openai.com/v1');
    _llmModel = _config.getParameter('ai.search.llm_model', defaultValue: 'gpt-4');

    _llmConfig = {
      'temperature': _config.getParameter('ai.search.llm_temperature', defaultValue: 0.7),
      'max_tokens': _config.getParameter('ai.search.llm_max_tokens', defaultValue: 2000),
      'timeout': _config.getParameter('ai.search.llm_timeout', defaultValue: 30000),
    };

    // Check if offline mode should be enabled
    _offlineMode = _llmApiKey?.isEmpty ?? true;
    if (_offlineMode) {
      _logger.info('LLM offline mode enabled - using local processing only', 'AdvancedAISearchService');
    }
  }

  /// Initialize search models
  Future<void> _initializeSearchModels() async {
    _searchModels['text_search'] = AIModel(
      name: 'Text Search Model',
      type: AIModelType.nlp,
      capabilities: ['text_matching', 'keyword_extraction', 'sentiment_analysis'],
      confidenceThreshold: 0.7,
    );

    _searchModels['semantic_search'] = AIModel(
      name: 'Semantic Search Model',
      type: AIModelType.nlp,
      capabilities: ['semantic_similarity', 'context_understanding', 'intent_recognition'],
      confidenceThreshold: 0.8,
    );

    _searchModels['multimodal_search'] = AIModel(
      name: 'Multimodal Search Model',
      type: AIModelType.multimodal,
      capabilities: ['image_search', 'content_analysis', 'cross_modal_retrieval'],
      confidenceThreshold: 0.75,
    );
  }

  /// Initialize vector databases
  Future<void> _initializeVectorDatabases() async {
    // Initialize vector database for embeddings
    // This would typically connect to services like Pinecone, Weaviate, etc.
    _logger.info('Vector databases initialized', 'AdvancedAISearchService');
  }

  /// Initialize semantic indexes
  Future<void> _initializeSemanticIndexes() async {
    // Initialize semantic search indexes
    _logger.info('Semantic indexes initialized', 'AdvancedAISearchService');
  }

  /// Initialize search cache
  Future<void> _initializeSearchCache() async {
    // Initialize search result caching
    _logger.info('Search cache initialized', 'AdvancedAISearchService');
  }

  /// Start background indexing
  void _startBackgroundIndexing() {
    final updateInterval = _config.getParameter('ai.search.index_update_interval', defaultValue: 3600000);
    Timer.periodic(Duration(milliseconds: updateInterval), (timer) {
      _performBackgroundIndexing();
    });
  }

  /// Perform background indexing
  Future<void> _performBackgroundIndexing() async {
    try {
      // Update semantic indexes with new/changed files
      // This would scan for file changes and update indexes
      _logger.debug('Background indexing completed', 'AdvancedAISearchService');
    } catch (e) {
      _logger.error('Background indexing failed', 'AdvancedAISearchService', error: e);
    }
  }

  // Helper methods (simplified implementations)

  Future<SearchResults?> _checkSearchCache(String query, SearchContext? context) async => null;
  Future<void> _cacheSearchResults(String query, SearchResults results, SearchContext? context) async {}
  Future<void> _addToQueryHistory(String query, SearchResults results) async {}
  Future<List<SearchResult>> _searchFileSystem(ProcessedQuery query, SearchOptions? options) async => [];
  Future<List<SearchResult>> _searchNetwork(ProcessedQuery query, SearchOptions? options) async => [];
  Future<List<SearchResult>> _searchCloudStorage(ProcessedQuery query, SearchOptions? options) async => [];
  Future<List<SearchResult>> _semanticSearch(ProcessedQuery query, SearchOptions? options) async => [];
  List<SearchResult> _applyBasicRanking(List<SearchResult> results, ProcessedQuery query) => results;
  String _buildRankingPrompt(ProcessedQuery query, List<SearchResult> results) => '';
  List<SearchResult> _parseRankingResponse(String response, List<SearchResult> results) => results;
  String _buildInsightPrompt(String query, List<SearchResult> results) => '';
  List<SearchInsight> _parseInsightResponse(String response) => [];
  Future<ConversationContext> _getConversationContext(String? conversationId) async => ConversationContext(id: conversationId ?? 'default');
  String _buildConversationalPrompt(String query, ConversationContext context, List<PreviousMessage>? history) => '';
  ConversationalResponse _parseConversationalResponse(String response) => ConversationalResponse(response: response);
  Future<void> _updateConversationContext(ConversationContext context, String query, String response) async {}
  List<String> _createBatches(List<String> items, int batchSize) => [];
  Future<void> _processSemanticIndexBatch(List<String> batch) async {}
  Future<QueryPatterns> _analyzeQueryPatterns(DateTime start, DateTime end) async => QueryPatterns();
  Future<SearchEffectiveness> _analyzeSearchEffectiveness(DateTime start, DateTime end) async => SearchEffectiveness();
  Future<UserBehaviorMetrics> _analyzeUserBehavior(DateTime start, DateTime end) async => UserBehaviorMetrics();
  Map<String, int> _analyzeFileTypeDistribution(List<SearchResult> results) => {};
  ProcessedQuery _parseQueryUnderstandingResponse(String response, String originalQuery) => ProcessedQuery(
    originalQuery: originalQuery,
    query: originalQuery,
    intent: SearchIntent.general,
    entities: [],
    confidence: 0.5,
  );
  List<String> _extractBasicEntities(String query) => [];

  // Event emission methods
  void _emitSearchEvent(SearchEventType type, {Map<String, dynamic>? data}) {
    final event = SearchEvent(type: type, timestamp: DateTime.now(), data: data ?? {});
    _searchEventController.add(event);
  }

  void _emitLLMEvent(LLMEventType type, {Map<String, dynamic>? data}) {
    final event = LLMEvent(type: type, timestamp: DateTime.now(), data: data ?? {});
    _llmEventController.add(event);
  }

  /// Dispose resources
  void dispose() {
    _searchEventController.close();
    _llmEventController.close();
  }
}

/// Supporting data classes and enums

enum SearchIntent {
  general,
  findFiles,
  organizeFiles,
  analyzeContent,
  locateDuplicates,
  findByContent,
  searchByDate,
  searchByType,
  networkSearch,
  cloudSearch,
}

enum InsightType {
  noResults,
  manyResults,
  fileTypeDistribution,
  timeDistribution,
  locationDistribution,
  contentInsights,
  usagePatterns,
  recommendations,
}

enum SearchEventType {
  searchStarted,
  searchCompleted,
  searchFailed,
  cacheHit,
  indexUpdated,
  modelUpdated,
}

enum LLMEventType {
  queryProcessed,
  callFailed,
  modelLoaded,
  contextUpdated,
}

class SearchContext {
  final String? userId;
  final String? currentDirectory;
  final List<String>? recentSearches;
  final Map<String, dynamic>? preferences;

  SearchContext({
    this.userId,
    this.currentDirectory,
    this.recentSearches,
    this.preferences,
  });
}

class SearchOptions {
  final bool useCache;
  final int maxResults;
  final bool includeNetwork;
  final bool includeCloud;
  final bool semanticSearch;
  final Duration timeout;

  SearchOptions({
    this.useCache = true,
    this.maxResults = 100,
    this.includeNetwork = true,
    this.includeCloud = true,
    this.semanticSearch = true,
    this.timeout = const Duration(seconds: 30),
  });
}

class ProcessedQuery {
  final String originalQuery;
  final String query;
  final SearchIntent intent;
  final List<String> entities;
  final double confidence;

  ProcessedQuery({
    required this.originalQuery,
    required this.query,
    required this.intent,
    required this.entities,
    required this.confidence,
  });
}

class SearchResult {
  final String filePath;
  final String fileName;
  final double relevanceScore;
  final String matchedContent;
  final Map<String, dynamic> metadata;
  final DateTime foundAt;

  SearchResult({
    required this.filePath,
    required this.fileName,
    required this.relevanceScore,
    required this.matchedContent,
    this.metadata = const {},
    DateTime? foundAt,
  }) : foundAt = foundAt ?? DateTime.now();
}

class SearchResults {
  final String query;
  final String processedQuery;
  final List<SearchResult> results;
  final List<SearchInsight> insights;
  final Duration searchTime;
  final int totalResults;
  final SearchContext? searchContext;
  final double aiConfidence;

  SearchResults({
    required this.query,
    required this.processedQuery,
    required this.results,
    this.insights = const [],
    required this.searchTime,
    required this.totalResults,
    this.searchContext,
    this.aiConfidence = 0.0,
  });
}

class SearchInsight {
  final InsightType type;
  final String message;
  final double confidence;
  final Map<String, dynamic>? data;

  SearchInsight({
    required this.type,
    required this.message,
    required this.confidence,
    this.data,
  });
}

class ConversationContext {
  final String id;
  final List<PreviousMessage> history;
  final Map<String, dynamic> metadata;

  ConversationContext({
    required this.id,
    this.history = const [],
    this.metadata = const {},
  });
}

class PreviousMessage {
  final String query;
  final String response;
  final DateTime timestamp;

  PreviousMessage({
    required this.query,
    required this.response,
    required this.timestamp,
  });
}

class ConversationalResponse {
  final String response;
  final String? extractedSearchQuery;
  final List<String> suggestedFollowUps;

  ConversationalResponse({
    required this.response,
    this.extractedSearchQuery,
    this.suggestedFollowUps = const [],
  });
}

class ConversationalSearchResult {
  final String? conversationId;
  final String query;
  final String response;
  final SearchResults searchResults;
  final List<String> suggestedFollowUps;
  final ConversationContext context;

  ConversationalSearchResult({
    this.conversationId,
    required this.query,
    required this.response,
    required this.searchResults,
    this.suggestedFollowUps = const [],
    required this.context,
  });
}

class SemanticIndex {
  final String id;
  final String content;
  final List<double> embedding;
  final DateTime indexedAt;
  final Map<String, dynamic> metadata;

  SemanticIndex({
    required this.id,
    required this.content,
    required this.embedding,
    DateTime? indexedAt,
    this.metadata = const {},
  }) : indexedAt = indexedAt ?? DateTime.now();
}

class SearchCache {
  final String query;
  final SearchResults results;
  final DateTime cachedAt;
  final Duration ttl;

  SearchCache({
    required this.query,
    required this.results,
    required this.cachedAt,
    required this.ttl,
  });
}

class QueryHistory {
  final String query;
  final int frequency;
  final DateTime lastUsed;
  final double averageResults;

  QueryHistory({
    required this.query,
    required this.frequency,
    required this.lastUsed,
    required this.averageResults,
  });
}

class AIModel {
  final String name;
  final AIModelType type;
  final List<String> capabilities;
  final double confidenceThreshold;

  AIModel({
    required this.name,
    required this.type,
    required this.capabilities,
    required this.confidenceThreshold,
  });
}

class VectorDatabase {
  final String name;
  final String type;
  final int dimensions;
  final int maxVectors;

  VectorDatabase({
    required this.name,
    required this.type,
    required this.dimensions,
    required this.maxVectors,
  });
}

class SearchAnalytics {
  final DateRange period;
  final int totalQueries;
  final int uniqueQueries;
  final double averageQueryLength;
  final List<String> popularSearchTerms;
  final double searchSuccessRate;
  final double averageResultsPerQuery;
  final int noResultQueries;
  final UserBehaviorMetrics userBehaviorMetrics;

  SearchAnalytics({
    required this.period,
    required this.totalQueries,
    required this.uniqueQueries,
    required this.averageQueryLength,
    required this.popularSearchTerms,
    required this.searchSuccessRate,
    required this.averageResultsPerQuery,
    required this.noResultQueries,
    required this.userBehaviorMetrics,
  });
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({
    required this.start,
    required this.end,
  });
}

class QueryPatterns {
  final int totalQueries = 0;
  final int uniqueQueries = 0;
  final double averageQueryLength = 0.0;
  final List<String> popularTerms = [];
}

class SearchEffectiveness {
  final double successRate = 0.0;
  final double averageResults = 0.0;
  final int noResultQueries = 0;
}

class UserBehaviorMetrics {
  final double averageSessionDuration = 0.0;
  final int averageQueriesPerSession = 0;
  final List<String> preferredSearchTypes = [];
}

class SearchEvent {
  final SearchEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  SearchEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });
}

class LLMEvent {
  final LLMEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  LLMEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });
}
