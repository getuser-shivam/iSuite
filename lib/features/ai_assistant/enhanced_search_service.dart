import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'advanced_document_intelligence_service.dart';
import '../../core/logging/logging_service.dart';
import '../../core/config/central_config.dart';

/// Enhanced AI-Powered Search Service
///
/// Provides intelligent search capabilities beyond traditional keyword matching:
/// - Semantic search understanding context and intent
/// - Natural language query processing
/// - Personalized search results based on user behavior
/// - Query expansion and suggestion generation
/// - Multi-modal search (text, metadata, content analysis)
/// - Learning from user interactions to improve results
class EnhancedSearchService {
  static final EnhancedSearchService _instance = EnhancedSearchService._internal();
  factory EnhancedSearchService() => _instance;
  EnhancedSearchService._internal();

  final LoggingService _logger = LoggingService();
  final CentralConfig _config = CentralConfig.instance;
  final AdvancedDocumentIntelligenceService _documentIntelligence = AdvancedDocumentIntelligenceService();

  GenerativeModel? _model;
  bool _isInitialized = false;

  // Search history and learning
  final List<SearchQuery> _searchHistory = [];
  final Map<String, UserSearchProfile> _userProfiles = {};
  final Map<String, SearchAnalytics> _searchAnalytics = {};

  // Caching and performance
  final Map<String, SearchResults> _searchCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Initialize the enhanced search service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Enhanced Search Service', 'SearchService');

      // Check if AI search is enabled
      final searchEnabled = _config.getParameter('ai.search.enabled', defaultValue: true);
      if (!searchEnabled) {
        _logger.info('AI search disabled, using basic search capabilities', 'SearchService');
        _isInitialized = true;
        return;
      }

      // Initialize AI model for search enhancement
      await _initializeAIModel();

      // Initialize document intelligence
      await _documentIntelligence.initialize();

      _isInitialized = true;
      _logger.info('Enhanced Search Service initialized successfully', 'SearchService');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Enhanced Search Service', 'SearchService',
          error: e, stackTrace: stackTrace);
      // Continue with basic functionality
      _isInitialized = true;
    }
  }

  Future<void> _initializeAIModel() async {
    try {
      final provider = _config.getParameter('ai.llm_provider', defaultValue: 'google');
      final apiKey = _config.getParameter('ai.api_key', defaultValue: '');
      final modelName = _config.getParameter('ai.model_name', defaultValue: 'gemini-1.5-flash');

      if (provider == 'google' && apiKey.isNotEmpty) {
        _model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: _config.getParameter('ai.temperature', defaultValue: 0.3), // Lower temperature for search
            maxOutputTokens: _config.getParameter('ai.max_tokens', defaultValue: 1024),
          ),
        );
        _logger.info('AI model initialized for search enhancement', 'SearchService');
      }
    } catch (e) {
      _logger.error('Failed to initialize AI model for search', 'SearchService', error: e);
    }
  }

  /// Perform enhanced search with AI capabilities
  Future<SearchResults> search({
    required String query,
    required List<DocumentAnalysis> availableDocuments,
    String? userId,
    Map<String, dynamic>? filters,
    SearchOptions? options,
  }) async {
    if (!_isInitialized) await initialize();

    final startTime = DateTime.now();
    final searchId = _generateSearchId();

    try {
      _logger.info('Performing enhanced search: "$query"', 'SearchService');

      // Create search query record
      final searchQuery = SearchQuery(
        id: searchId,
        query: query,
        userId: userId,
        timestamp: startTime,
        filters: filters,
        options: options,
      );

      // Check cache first
      if (_config.getParameter('ai.cache.enabled', defaultValue: true)) {
        final cachedResult = _getCachedResult(query, filters);
        if (cachedResult != null) {
          _logger.info('Returning cached search results', 'SearchService');
          return cachedResult;
        }
      }

      // Analyze query intent and expand
      final queryAnalysis = await _analyzeQueryIntent(query);

      // Perform multi-stage search
      final results = SearchResults(
        searchId: searchId,
        originalQuery: query,
        analyzedQuery: queryAnalysis,
        timestamp: startTime,
      );

      // Stage 1: Basic keyword matching
      final basicResults = await _performBasicSearch(query, availableDocuments, filters);
      results.basicMatches = basicResults;

      // Stage 2: Semantic search if AI available
      if (_model != null && _config.getParameter('ai.search.semantic_search', defaultValue: true)) {
        final semanticResults = await _performSemanticSearch(queryAnalysis, availableDocuments, filters);
        results.semanticMatches = semanticResults;
      }

      // Stage 3: Personalized results if user profile available
      if (userId != null && _config.getParameter('ai.search.personalization', defaultValue: true)) {
        final personalizedResults = await _personalizeResults(userId, results, availableDocuments);
        results.personalizedMatches = personalizedResults;
      }

      // Stage 4: Generate suggestions and related queries
      if (_config.getParameter('ai.search.context_understanding', defaultValue: true)) {
        results.suggestions = await _generateSearchSuggestions(query, availableDocuments);
        results.relatedQueries = await _generateRelatedQueries(query);
      }

      // Combine and rank results
      results.combinedResults = await _combineAndRankResults(results, queryAnalysis);

      // Apply result limits
      final maxResults = _config.getParameter('ai.search.max_results', defaultValue: 50);
      results.combinedResults = results.combinedResults.take(maxResults).toList();

      // Record search analytics
      await _recordSearchAnalytics(searchQuery, results);

      // Cache results
      if (_config.getParameter('ai.cache.enabled', defaultValue: true)) {
        _cacheSearchResult(query, filters, results);
      }

      final duration = DateTime.now().difference(startTime);
      results.searchDuration = duration;

      _logger.info('Enhanced search completed in ${duration.inMilliseconds}ms, found ${results.combinedResults.length} results', 'SearchService');

      return results;

    } catch (e, stackTrace) {
      _logger.error('Enhanced search failed for query: "$query"', 'SearchService',
          error: e, stackTrace: stackTrace);

      // Return basic results on failure
      return SearchResults(
        searchId: searchId,
        originalQuery: query,
        timestamp: startTime,
        error: e.toString(),
        combinedResults: await _performBasicSearch(query, availableDocuments, filters),
      );
    }
  }

  Future<QueryAnalysis> _analyzeQueryIntent(String query) async {
    final analysis = QueryAnalysis(query: query);

    // Basic analysis
    analysis.queryType = _classifyQueryType(query);
    analysis.keywords = _extractKeywords(query);
    analysis.entities = _extractEntities(query);
    analysis.intent = _determineIntent(query);

    // AI-powered analysis if available
    if (_model != null && _config.getParameter('ai.search.context_understanding', defaultValue: true)) {
      await _performAIQueryAnalysis(analysis);
    }

    return analysis;
  }

  String _classifyQueryType(String query) {
    final lowerQuery = query.toLowerCase();

    if (lowerQuery.contains('find') || lowerQuery.contains('search') || lowerQuery.contains('locate')) {
      return 'search';
    } else if (lowerQuery.contains('show') || lowerQuery.contains('display') || lowerQuery.contains('list')) {
      return 'browse';
    } else if (lowerQuery.contains('create') || lowerQuery.contains('make') || lowerQuery.contains('generate')) {
      return 'create';
    } else if (lowerQuery.contains('delete') || lowerQuery.contains('remove') || lowerQuery.contains('erase')) {
      return 'delete';
    } else if (lowerQuery.contains('edit') || lowerQuery.contains('modify') || lowerQuery.contains('change')) {
      return 'edit';
    }

    return 'search'; // Default
  }

  List<String> _extractKeywords(String query) {
    // Simple keyword extraction - remove stop words and split
    final stopWords = {'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by'};
    final words = query.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2 && !stopWords.contains(word))
        .toList();

    return words;
  }

  List<String> _extractEntities(String query) {
    // Basic entity extraction - look for file extensions, dates, etc.
    final entities = <String>[];

    // File extensions
    final extensionMatches = RegExp(r'\.(\w+)').allMatches(query);
    for (final match in extensionMatches) {
      entities.add(match.group(1)!);
    }

    // Dates (basic patterns)
    final dateMatches = RegExp(r'\d{4}[/-]\d{2}[/-]\d{2}').allMatches(query);
    for (final match in dateMatches) {
      entities.add(match.group(0)!);
    }

    return entities;
  }

  String _determineIntent(String query) {
    final lowerQuery = query.toLowerCase();

    if (lowerQuery.contains('recent') || lowerQuery.contains('latest') || lowerQuery.contains('new')) {
      return 'temporal';
    } else if (lowerQuery.contains('large') || lowerQuery.contains('big') || lowerQuery.contains('size')) {
      return 'size-based';
    } else if (lowerQuery.contains('type') || lowerQuery.contains('kind') || lowerQuery.contains('format')) {
      return 'type-based';
    } else if (lowerQuery.contains('author') || lowerQuery.contains('creator') || lowerQuery.contains('owner')) {
      return 'author-based';
    }

    return 'general';
  }

  Future<void> _performAIQueryAnalysis(QueryAnalysis analysis) async {
    if (_model == null) return;

    try {
      final prompt = '''
Analyze this search query and provide detailed insights:

QUERY: "${analysis.query}"

Please provide:
1. QUERY_INTENT: What is the user trying to accomplish?
2. QUERY_TYPE: Type of query (factual, exploratory, transactional, etc.)
3. KEY_CONCEPTS: Main concepts or topics in the query
4. EXPECTED_RESULTS: What type of results should be returned
5. SEARCH_STRATEGY: Best approach to find relevant results
6. RELATED_CONCEPTS: Related terms or concepts to consider
7. CONFIDENCE: How confident are you in this analysis (0.0-1.0)

Format as JSON with these keys.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final result = response.text;

      if (result != null) {
        final aiAnalysis = _parseAIResponse(result);
        analysis.aiInsights = aiAnalysis;
        analysis.confidence = aiAnalysis['confidence'] ?? 0.5;
      }
    } catch (e) {
      _logger.warning('AI query analysis failed, using basic analysis', 'SearchService', error: e);
    }
  }

  Future<List<SearchMatch>> _performBasicSearch(
    String query,
    List<DocumentAnalysis> documents,
    Map<String, dynamic>? filters,
  ) async {
    final matches = <SearchMatch>[];
    final lowerQuery = query.toLowerCase();

    for (final doc in documents) {
      final score = _calculateBasicScore(doc, lowerQuery);
      if (score > 0) {
        // Apply filters
        if (_matchesFilters(doc, filters)) {
          matches.add(SearchMatch(
            document: doc,
            score: score,
            matchType: 'basic',
            matchedTerms: _findMatchedTerms(doc, lowerQuery),
          ));
        }
      }
    }

    // Sort by score
    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches;
  }

  double _calculateBasicScore(DocumentAnalysis doc, String lowerQuery) {
    double score = 0.0;

    // File name matching (highest weight)
    final fileNameLower = doc.fileName.toLowerCase();
    if (fileNameLower.contains(lowerQuery)) {
      score += 10.0;
      if (fileNameLower.startsWith(lowerQuery)) {
        score += 5.0; // Bonus for prefix match
      }
    }

    // Content matching
    final summary = doc.aiInsights?['summary']?.toString().toLowerCase() ?? '';
    if (summary.contains(lowerQuery)) {
      score += 3.0;
    }

    // Metadata matching
    final categories = doc.aiInsights?['categories'] as List?;
    if (categories != null) {
      for (final category in categories) {
        if (category.toString().toLowerCase().contains(lowerQuery)) {
          score += 2.0;
          break;
        }
      }
    }

    return score;
  }

  Future<List<SearchMatch>> _performSemanticSearch(
    QueryAnalysis queryAnalysis,
    List<DocumentAnalysis> documents,
    Map<String, dynamic>? filters,
  ) async {
    if (_model == null) return [];

    final matches = <SearchMatch>[];

    try {
      // Use AI to find semantic matches
      for (final doc in documents) {
        final semanticScore = await _calculateSemanticScore(queryAnalysis, doc);
        if (semanticScore > 0.3) { // Minimum threshold
          if (_matchesFilters(doc, filters)) {
            matches.add(SearchMatch(
              document: doc,
              score: semanticScore,
              matchType: 'semantic',
              matchedTerms: queryAnalysis.keywords,
            ));
          }
        }
      }

      matches.sort((a, b) => b.score.compareTo(a.score));
      return matches;

    } catch (e) {
      _logger.warning('Semantic search failed, falling back to basic search', 'SearchService', error: e);
      return [];
    }
  }

  Future<double> _calculateSemanticScore(QueryAnalysis queryAnalysis, DocumentAnalysis doc) async {
    if (_model == null) return 0.0;

    try {
      final prompt = '''
Rate how relevant this document is to the search query on a scale of 0.0 to 1.0.

QUERY: "${queryAnalysis.query}"
DOCUMENT: ${doc.fileName}
SUMMARY: ${doc.aiInsights?['summary'] ?? 'No summary'}
TYPE: ${doc.aiInsights?['document_type'] ?? 'Unknown'}
CATEGORIES: ${doc.aiInsights?['categories']?.join(', ') ?? 'None'}

Consider semantic meaning, context, and conceptual relevance.
Return only a number between 0.0 and 1.0.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final scoreText = response.text?.trim() ?? '0.0';
      final score = double.tryParse(scoreText) ?? 0.0;

      return score.clamp(0.0, 1.0);

    } catch (e) {
      return 0.0;
    }
  }

  Future<List<SearchMatch>> _personalizeResults(
    String userId,
    SearchResults results,
    List<DocumentAnalysis> allDocuments,
  ) async {
    final userProfile = _userProfiles[userId];
    if (userProfile == null) return [];

    final personalized = <SearchMatch>[];

    // Boost results based on user preferences and history
    for (final match in results.combinedResults) {
      double boost = 1.0;

      // Boost based on frequently accessed document types
      final docType = match.document.aiInsights?['document_type'];
      if (docType != null && userProfile.preferredDocumentTypes.contains(docType)) {
        boost *= 1.2;
      }

      // Boost based on recently accessed files
      if (userProfile.recentlyAccessed.contains(match.document.filePath)) {
        boost *= 1.1;
      }

      // Boost based on user feedback
      final feedback = userProfile.feedbackHistory[match.document.filePath];
      if (feedback != null) {
        boost *= (1.0 + feedback * 0.1); // Small boost for positive feedback
      }

      if (boost > 1.0) {
        personalized.add(SearchMatch(
          document: match.document,
          score: match.score * boost,
          matchType: 'personalized',
          matchedTerms: match.matchedTerms,
          personalizationReason: _getPersonalizationReason(boost, userProfile),
        ));
      }
    }

    return personalized.take(5).toList(); // Top 5 personalized results
  }

  Future<List<String>> _generateSearchSuggestions(String query, List<DocumentAnalysis> documents) async {
    return await _documentIntelligence.generateSearchSuggestions(query, documents);
  }

  Future<List<String>> _generateRelatedQueries(String query) async {
    if (_model == null) return [];

    try {
      final prompt = '''
Generate 3-5 related search queries for: "$query"

Consider:
- Synonyms and related terms
- Different ways to phrase the same search
- Related concepts or topics
- Common variations

Return only the queries, one per line, no numbering.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final suggestions = response.text?.split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .take(5)
          .toList() ?? [];

      return suggestions;

    } catch (e) {
      _logger.warning('Failed to generate related queries', 'SearchService', error: e);
      return [];
    }
  }

  Future<List<SearchMatch>> _combineAndRankResults(SearchResults results, QueryAnalysis queryAnalysis) async {
    final allMatches = <SearchMatch>[];

    // Add all types of matches
    allMatches.addAll(results.basicMatches);
    allMatches.addAll(results.semanticMatches);
    allMatches.addAll(results.personalizedMatches);

    // Remove duplicates and combine scores
    final uniqueMatches = <String, SearchMatch>{};
    for (final match in allMatches) {
      final key = match.document.filePath;
      if (uniqueMatches.containsKey(key)) {
        // Combine scores (weighted average)
        final existing = uniqueMatches[key]!;
        final combinedScore = (existing.score * 0.7) + (match.score * 0.3);
        uniqueMatches[key] = SearchMatch(
          document: match.document,
          score: combinedScore,
          matchType: 'combined',
          matchedTerms: {...existing.matchedTerms, ...match.matchedTerms}.toList(),
        );
      } else {
        uniqueMatches[key] = match;
      }
    }

    // Sort by combined score
    final sortedMatches = uniqueMatches.values.toList();
    sortedMatches.sort((a, b) => b.score.compareTo(a.score));

    return sortedMatches;
  }

  // Utility methods
  bool _matchesFilters(DocumentAnalysis doc, Map<String, dynamic>? filters) {
    if (filters == null || filters.isEmpty) return true;

    for (final entry in filters.entries) {
      final key = entry.key;
      final value = entry.value;

      switch (key) {
        case 'fileType':
          if (doc.mimeType != value) return false;
          break;
        case 'documentType':
          final docType = doc.aiInsights?['document_type'];
          if (docType != value) return false;
          break;
        case 'minSize':
          if (doc.fileSize < (value as num)) return false;
          break;
        case 'maxSize':
          if (doc.fileSize > (value as num)) return false;
          break;
        case 'category':
          final categories = doc.aiInsights?['categories'] as List?;
          if (categories == null || !categories.contains(value)) return false;
          break;
      }
    }

    return true;
  }

  List<String> _findMatchedTerms(DocumentAnalysis doc, String query) {
    final matched = <String>[];
    final queryWords = query.split(RegExp(r'\s+'));

    for (final word in queryWords) {
      if (doc.fileName.toLowerCase().contains(word.toLowerCase())) {
        matched.add(word);
      }
    }

    return matched;
  }

  String _getPersonalizationReason(double boost, UserSearchProfile profile) {
    if (boost >= 1.3) return 'Highly preferred document type';
    if (boost >= 1.2) return 'Frequently accessed';
    if (boost >= 1.1) return 'Recent activity';
    return 'User preference';
  }

  void _recordSearchAnalytics(SearchQuery query, SearchResults results) {
    _searchHistory.add(query);

    // Keep only last 1000 searches
    if (_searchHistory.length > 1000) {
      _searchHistory.removeRange(0, _searchHistory.length - 1000);
    }

    // Update analytics
    final analytics = _searchAnalytics.putIfAbsent(query.query, () => SearchAnalytics(query.query));
    analytics.totalSearches++;
    analytics.averageResults = ((analytics.averageResults * (analytics.totalSearches - 1)) + results.combinedResults.length) / analytics.totalSearches;
    analytics.lastSearched = query.timestamp;

    // Update user profile if user ID provided
    if (query.userId != null) {
      final profile = _userProfiles.putIfAbsent(query.userId!, () => UserSearchProfile(query.userId!));
      profile.recordSearch(query, results);
    }
  }

  SearchResults? _getCachedResult(String query, Map<String, dynamic>? filters) {
    final cacheKey = _generateCacheKey(query, filters);
    final cached = _searchCache[cacheKey];
    final timestamp = _cacheTimestamps[cacheKey];

    if (cached != null && timestamp != null) {
      final cacheTTL = Duration(seconds: _config.getParameter('ai.cache.ttl', defaultValue: 3600));
      if (DateTime.now().difference(timestamp) < cacheTTL) {
        return cached;
      } else {
        // Expired, remove from cache
        _searchCache.remove(cacheKey);
        _cacheTimestamps.remove(cacheKey);
      }
    }

    return null;
  }

  void _cacheSearchResult(String query, Map<String, dynamic>? filters, SearchResults results) {
    final cacheKey = _generateCacheKey(query, filters);
    _searchCache[cacheKey] = results;
    _cacheTimestamps[cacheKey] = DateTime.now();

    // Cleanup old cache entries
    _cleanupSearchCache();
  }

  void _cleanupSearchCache() {
    final maxSize = _config.getParameter('ai.cache.max_size', defaultValue: 100);
    if (_searchCache.length > maxSize) {
      // Remove oldest entries
      final entriesToRemove = _searchCache.length - maxSize;
      final keysToRemove = _searchCache.keys.take(entriesToRemove).toList();
      for (final key in keysToRemove) {
        _searchCache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }
  }

  String _generateSearchId() => 'search_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

  String _generateCacheKey(String query, Map<String, dynamic>? filters) {
    final filterStr = filters?.toString() ?? '';
    return '${query.hashCode}_${filterStr.hashCode}';
  }

  Map<String, dynamic> _parseAIResponse(String response) {
    try {
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd);
        return json.decode(jsonStr);
      }
    } catch (e) {
      _logger.warning('Failed to parse AI response as JSON', 'SearchService', error: e);
    }

    return {};
  }

  // Getters
  bool get isInitialized => _isInitialized;
  List<SearchQuery> get searchHistory => List.from(_searchHistory);
  Map<String, UserSearchProfile> get userProfiles => Map.from(_userProfiles);
  Map<String, SearchAnalytics> get searchAnalytics => Map.from(_searchAnalytics);
}

/// Search Query Record
class SearchQuery {
  final String id;
  final String query;
  final String? userId;
  final DateTime timestamp;
  final Map<String, dynamic>? filters;
  final SearchOptions? options;

  SearchQuery({
    required this.id,
    required this.query,
    this.userId,
    required this.timestamp,
    this.filters,
    this.options,
  });
}

/// Search Options
class SearchOptions {
  final bool includeContent;
  final bool includeMetadata;
  final bool fuzzyMatching;
  final int maxResults;
  final Duration timeout;

  SearchOptions({
    this.includeContent = true,
    this.includeMetadata = true,
    this.fuzzyMatching = true,
    this.maxResults = 50,
    this.timeout = const Duration(seconds: 30),
  });
}

/// Search Results
class SearchResults {
  final String searchId;
  final String originalQuery;
  final QueryAnalysis analyzedQuery;
  final DateTime timestamp;
  Duration searchDuration = Duration.zero;

  List<SearchMatch> basicMatches = [];
  List<SearchMatch> semanticMatches = [];
  List<SearchMatch> personalizedMatches = [];
  List<SearchMatch> combinedResults = [];

  List<String> suggestions = [];
  List<String> relatedQueries = [];

  String? error;

  SearchResults({
    required this.searchId,
    required this.originalQuery,
    required this.analyzedQuery,
    required this.timestamp,
    this.error,
  });
}

/// Search Match
class SearchMatch {
  final DocumentAnalysis document;
  final double score;
  final String matchType;
  final List<String> matchedTerms;
  final String? personalizationReason;

  SearchMatch({
    required this.document,
    required this.score,
    required this.matchType,
    required this.matchedTerms,
    this.personalizationReason,
  });
}

/// Query Analysis
class QueryAnalysis {
  final String query;
  String queryType = 'unknown';
  List<String> keywords = [];
  List<String> entities = [];
  String intent = 'general';
  Map<String, dynamic>? aiInsights;
  double confidence = 0.0;

  QueryAnalysis({required this.query});
}

/// User Search Profile
class UserSearchProfile {
  final String userId;
  final List<String> preferredDocumentTypes = [];
  final List<String> recentlyAccessed = [];
  final Map<String, double> feedbackHistory = {};
  final Map<String, int> searchPatterns = {};

  UserSearchProfile(this.userId);

  void recordSearch(SearchQuery query, SearchResults results) {
    // Update search patterns
    final patternKey = query.analyzedQuery.queryType;
    searchPatterns[patternKey] = (searchPatterns[patternKey] ?? 0) + 1;

    // Update preferred document types
    for (final match in results.combinedResults.take(3)) {
      final docType = match.document.aiInsights?['document_type'];
      if (docType != null && !preferredDocumentTypes.contains(docType)) {
        preferredDocumentTypes.add(docType);
      }
    }

    // Keep lists manageable
    if (preferredDocumentTypes.length > 10) {
      preferredDocumentTypes.removeRange(0, preferredDocumentTypes.length - 10);
    }
  }

  void recordFeedback(String filePath, double feedback) {
    feedbackHistory[filePath] = feedback;
  }
}

/// Search Analytics
class SearchAnalytics {
  final String query;
  int totalSearches = 0;
  double averageResults = 0.0;
  DateTime? lastSearched;
  final Map<String, int> resultTypes = {};

  SearchAnalytics(this.query);
}
