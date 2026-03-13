import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import '../backend/enhanced_pocketbase_service.dart';
import '../config/enhanced_config_manager.dart';
import '../logging/enhanced_logger.dart';
import '../performance/enhanced_performance_manager.dart';
import 'ai_file_organizer.dart';

/// AI-Powered Advanced Search Service
/// Features: Semantic search, content analysis, smart filtering
/// Performance: Indexing, caching, parallel search
/// Security: Privacy-first, local processing, secure indexing
class AIAdvancedSearch {
  static AIAdvancedSearch? _instance;
  static AIAdvancedSearch get instance => _instance ??= AIAdvancedSearch._internal();
  AIAdvancedSearch._internal();

  // Configuration
  late final bool _enableSemanticSearch;
  late final bool _enableContentIndexing;
  late final bool _enableFuzzySearch;
  late final bool _enableAutoComplete;
  late final bool _enableSearchHistory;
  late final int _maxSearchResults;
  late final int _indexBatchSize;
  late final Duration _searchTimeout;
  
  // Search indexes
  final Map<String, SearchIndex> _searchIndexes = {};
  final Map<String, List<String>> _invertedIndex = {};
  final Map<String, DocumentVector> _documentVectors = {};
  
  // Search history and suggestions
  final List<SearchQuery> _searchHistory = [];
  final Map<String, List<String>> _autoCompleteSuggestions = {};
  
  // Performance optimization
  final Map<String, List<SearchResult>> _searchCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  Timer? _cacheCleanupTimer;
  
  // Event streams
  final StreamController<SearchEvent> _eventController = 
      StreamController<SearchEvent>.broadcast();
  final StreamController<SearchProgress> _progressController = 
      StreamController<SearchProgress>.broadcast();
  
  Stream<SearchEvent> get searchEvents => _eventController.stream;
  Stream<SearchProgress> get progressEvents => _progressController.stream;

  /// Initialize AI Advanced Search
  Future<void> initialize() async {
    try {
      // Load configuration
      await _loadConfiguration();
      
      // Initialize search indexes
      await _initializeSearchIndexes();
      
      // Setup cache cleanup
      _setupCacheCleanup();
      
      EnhancedLogger.instance.info('AI Advanced Search initialized');
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to initialize AI Advanced Search', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Load configuration
  Future<void> _loadConfiguration() async {
    final config = EnhancedConfigManager.instance;
    
    _enableSemanticSearch = config.getParameter('ai_search.enable_semantic') ?? true;
    _enableContentIndexing = config.getParameter('ai_search.enable_content_indexing') ?? true;
    _enableFuzzySearch = config.getParameter('ai_search.enable_fuzzy') ?? true;
    _enableAutoComplete = config.getParameter('ai_search.enable_autocomplete') ?? true;
    _enableSearchHistory = config.getParameter('ai_search.enable_history') ?? true;
    _maxSearchResults = config.getParameter('ai_search.max_results') ?? 50;
    _indexBatchSize = config.getParameter('ai_search.index_batch_size') ?? 100;
    _searchTimeout = Duration(seconds: config.getParameter('ai_search.timeout_seconds') ?? 10);
  }

  /// Initialize search indexes
  Future<void> _initializeSearchIndexes() async {
    // Create main search index
    _searchIndexes['files'] = SearchIndex(
      name: 'files',
      type: IndexType.file,
      fields: ['name', 'path', 'content', 'tags', 'category'],
      timestamp: DateTime.now(),
    );
    
    // Create content index
    _searchIndexes['content'] = SearchIndex(
      name: 'content',
      type: IndexType.content,
      fields: ['text', 'title', 'description', 'keywords'],
      timestamp: DateTime.now(),
    );
    
    // Create metadata index
    _searchIndexes['metadata'] = SearchIndex(
      name: 'metadata',
      type: IndexType.metadata,
      fields: ['category', 'size', 'date', 'author', 'tags'],
      timestamp: DateTime.now(),
    );
    
    EnhancedLogger.instance.info('Search indexes initialized');
  }

  /// Setup cache cleanup
  void _setupCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(Duration(minutes: 10), (_) {
      _cleanupSearchCache();
    });
  }

  /// Index file for search
  Future<void> indexFile(String filePath, Map<String, dynamic> metadata) async {
    final timer = EnhancedPerformanceManager.instance.startTimer('file_indexing');
    
    try {
      // Get file analysis from AI File Organizer
      final analysis = await AIFileOrganizer.instance.analyzeFile(filePath);
      
      // Create document
      final document = SearchDocument(
        id: filePath,
        title: metadata['title'] ?? filePath.split('/').last,
        content: analysis.contentAnalysis['text_content'] ?? '',
        path: filePath,
        category: analysis.category,
        tags: analysis.tags,
        metadata: {
          'size': analysis.size,
          'created_at': analysis.createdAt.toIso8601String(),
          'modified_at': analysis.modifiedAt.toIso8601String(),
          'confidence': analysis.confidence,
          ...metadata,
        },
        timestamp: DateTime.now(),
      );
      
      // Index document
      await _indexDocument(document);
      
      // Update auto-complete suggestions
      if (_enableAutoComplete) {
        _updateAutoCompleteSuggestions(document);
      }
      
      timer.stop();
      
      // Emit event
      _eventController.add(SearchEvent(
        type: SearchEventType.documentIndexed,
        query: filePath,
        result: document,
      ));
    } catch (e, stackTrace) {
      timer.stop();
      EnhancedLogger.instance.error('Failed to index file: $filePath', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// Index document
  Future<void> _indexDocument(SearchDocument document) async {
    // Add to inverted index
    for (final field in _searchIndexes['files']!.fields) {
      final value = _getFieldValue(document, field);
      if (value != null) {
        final terms = _extractTerms(value.toString());
        
        for (final term in terms) {
          if (!_invertedIndex.containsKey(term)) {
            _invertedIndex[term] = [];
          }
          if (!_invertedIndex[term]!.contains(document.id)) {
            _invertedIndex[term]!.add(document.id);
          }
        }
      }
    }
    
    // Create document vector for semantic search
    if (_enableSemanticSearch) {
      _documentVectors[document.id] = await _createDocumentVector(document);
    }
  }

  /// Search with AI capabilities
  Future<SearchResults> search(SearchQuery query) async {
    final timer = EnhancedPerformanceManager.instance.startTimer('ai_search');
    
    try {
      // Check cache first
      final cacheKey = _generateCacheKey(query);
      final cached = _searchCache[cacheKey];
      if (cached != null && !_isCacheExpired(cacheKey)) {
        timer.stop();
        return SearchResults(
          query: query,
          results: cached,
          totalCount: cached.length,
          timestamp: DateTime.now(),
          fromCache: true,
        );
      }
      
      // Add to search history
      if (_enableSearchHistory) {
        _addToSearchHistory(query);
      }
      
      // Perform search
      final results = await _performSearch(query);
      
      // Cache results
      _searchCache[cacheKey] = results;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      timer.stop();
      
      // Emit event
      _eventController.add(SearchEvent(
        type: SearchEventType.searchCompleted,
        query: query.query,
        result: results,
      ));
      
      return SearchResults(
        query: query,
        results: results,
        totalCount: results.length,
        timestamp: DateTime.now(),
        fromCache: false,
      );
    } catch (e, stackTrace) {
      timer.stop();
      EnhancedLogger.instance.error('Search failed: ${query.query}', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Perform actual search
  Future<List<SearchResult>> _performSearch(SearchQuery query) async {
    final results = <SearchResult>[];
    
    // Extract search terms
    final terms = _extractTerms(query.query);
    
    // Perform different search types based on query
    if (query.type == SearchType.semantic && _enableSemanticSearch) {
      results.addAll(await _performSemanticSearch(terms));
    } else if (query.type == SearchType.fuzzy && _enableFuzzySearch) {
      results.addAll(await _performFuzzySearch(terms));
    } else {
      results.addAll(await _performExactSearch(terms));
    }
    
    // Apply filters
    if (query.filters.isNotEmpty) {
      results.removeWhere((result) => !_matchesFilters(result, query.filters));
    }
    
    // Sort results
    results.sort((a, b) => b.score.compareTo(a.score));
    
    // Limit results
    if (results.length > _maxSearchResults) {
      results.removeRange(_maxSearchResults, results.length);
    }
    
    return results;
  }

  /// Perform exact search
  Future<List<SearchResult>> _performExactSearch(List<String> terms) async {
    final results = <SearchResult>[];
    final documentScores = <String, double>{};
    
    // Find documents containing all terms
    for (final term in terms) {
      final documents = _invertedIndex[term] ?? [];
      
      for (final documentId in documents) {
        documentScores[documentId] = (documentScores[documentId] ?? 0) + 1.0;
      }
    }
    
    // Filter documents that contain all terms
    final matchingDocuments = documentScores.entries
        .where((entry) => entry.value == terms.length)
        .map((entry) => entry.key)
        .toList();
    
    // Create search results
    for (final documentId in matchingDocuments) {
      final result = await _createSearchResult(documentId, terms, 1.0);
      if (result != null) {
        results.add(result);
      }
    }
    
    return results;
  }

  /// Perform fuzzy search
  Future<List<SearchResult>> _performFuzzySearch(List<String> terms) async {
    final results = <SearchResult>[];
    
    for (final term in terms) {
      // Find similar terms
      final similarTerms = _findSimilarTerms(term, 0.8);
      
      for (final similarTerm in similarTerms) {
        final documents = _invertedIndex[similarTerm] ?? [];
        
        for (final documentId in documents) {
          final similarity = _calculateSimilarity(term, similarTerm);
          final result = await _createSearchResult(documentId, [similarTerm], similarity);
          if (result != null) {
            results.add(result);
          }
        }
      }
    }
    
    // Remove duplicates and sort
    final uniqueResults = <String, SearchResult>{};
    for (final result in results) {
      final existing = uniqueResults[result.documentId];
      if (existing == null || result.score > existing.score) {
        uniqueResults[result.documentId] = result;
      }
    }
    
    return uniqueResults.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  /// Perform semantic search
  Future<List<SearchResult>> _performSemanticSearch(List<String> terms) async {
    final results = <SearchResult>[];
    
    // Create query vector
    final queryVector = await _createQueryVector(terms);
    
    // Calculate similarity with document vectors
    for (final entry in _documentVectors.entries) {
      final documentVector = entry.value;
      final similarity = _calculateCosineSimilarity(queryVector, documentVector);
      
      if (similarity > 0.3) { // Threshold for semantic similarity
        final result = await _createSearchResult(entry.key, terms, similarity);
        if (result != null) {
          results.add(result);
        }
      }
    }
    
    return results
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  /// Find similar terms
  List<String> _findSimilarTerms(String term, double threshold) {
    final similarTerms = <String>[];
    
    for (final indexedTerm in _invertedIndex.keys) {
      final similarity = _calculateSimilarity(term, indexedTerm);
      if (similarity >= threshold && indexedTerm != term) {
        similarTerms.add(indexedTerm);
      }
    }
    
    return similarTerms;
  }

  /// Calculate similarity between two strings
  double _calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;
    
    final longer = a.length > b.length ? a : b;
    final shorter = a.length > b.length ? b : a;
    
    if (longer.isEmpty) return 1.0;
    
    final editDistance = _levenshteinDistance(a, b);
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

  /// Create document vector
  Future<DocumentVector> _createDocumentVector(SearchDocument document) async {
    // This is a simplified vector creation
    // In production, use proper word embeddings or TF-IDF
    
    final allTerms = <String>[];
    final termFrequencies = <String, double>{};
    
    // Extract terms from all fields
    for (final field in _searchIndexes['files']!.fields) {
      final value = _getFieldValue(document, field);
      if (value != null) {
        final terms = _extractTerms(value.toString());
        allTerms.addAll(terms);
        
        for (final term in terms) {
          termFrequencies[term] = (termFrequencies[term] ?? 0) + 1;
        }
      }
    }
    
    // Create simplified vector (TF-IDF-like)
    final vector = <String, double>{};
    for (final term in allTerms) {
      vector[term] = termFrequencies[term]! / allTerms.length;
    }
    
    return DocumentVector(
      documentId: document.id,
      vector: vector,
      timestamp: DateTime.now(),
    );
  }

  /// Create query vector
  Future<DocumentVector> _createQueryVector(List<String> terms) async {
    final vector = <String, double>{};
    
    for (final term in terms) {
      vector[term] = 1.0 / terms.length;
    }
    
    return DocumentVector(
      documentId: 'query',
      vector: vector,
      timestamp: DateTime.now(),
    );
  }

  /// Calculate cosine similarity
  double _calculateCosineSimilarity(DocumentVector vec1, DocumentVector vec2) {
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;
    
    // Get all unique terms
    final allTerms = {...vec1.vector.keys, ...vec2.vector.keys};
    
    for (final term in allTerms) {
      final v1 = vec1.vector[term] ?? 0.0;
      final v2 = vec2.vector[term] ?? 0.0;
      
      dotProduct += v1 * v2;
      norm1 += v1 * v1;
      norm2 += v2 * v2;
    }
    
    if (norm1 == 0 || norm2 == 0) return 0.0;
    
    return dotProduct / (math.sqrt(norm1) * math.sqrt(norm2));
  }

  /// Create search result
  Future<SearchResult?> _createSearchResult(
    String documentId,
    List<String> matchedTerms,
    double score,
  ) async {
    try {
      // Get document from AI File Organizer
      final metadata = AIFileOrganizer.instance.getFileMetadata(documentId);
      if (metadata == null) return null;
      
      // Get file analysis
      final analysis = await AIFileOrganizer.instance.analyzeFile(documentId);
      
      return SearchResult(
        documentId: documentId,
        title: analysis.filePath.split('/').last,
        path: analysis.filePath,
        category: analysis.category,
        tags: analysis.tags,
        snippet: _createSnippet(analysis, matchedTerms),
        score: score,
        matchedTerms: matchedTerms,
        metadata: {
          'size': analysis.size,
          'modified_at': analysis.modifiedAt.toIso8601String(),
          'confidence': analysis.confidence,
        },
        timestamp: DateTime.now(),
      );
    } catch (e) {
      EnhancedLogger.instance.warning('Failed to create search result: $documentId', error: e);
      return null;
    }
  }

  /// Create search snippet
  String _createSnippet(FileAnalysisResult analysis, List<String> matchedTerms) {
    // This is a simplified snippet creation
    // In production, create proper context-aware snippets
    
    final content = analysis.contentAnalysis['text_content'] ?? '';
    if (content.isEmpty) {
      return 'No preview available';
    }
    
    // Find first matched term in content
    for (final term in matchedTerms) {
      final index = content.toLowerCase().indexOf(term.toLowerCase());
      if (index != -1) {
        final start = math.max(0, index - 50);
        final end = math.min(content.length, index + term.length + 50);
        final snippet = content.substring(start, end);
        return '...$snippet...';
      }
    }
    
    // Return first 100 characters if no match found
    return content.length > 100 ? '${content.substring(0, 100)}...' : content;
  }

  /// Extract terms from text
  List<String> _extractTerms(String text) {
    // Remove special characters and split
    final cleanText = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ');
    final terms = cleanText.split(RegExp(r'\s+')).where((term) => term.isNotEmpty).toList();
    
    // Remove common stop words
    final stopWords = {
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
      'of', 'with', 'by', 'from', 'up', 'about', 'into', 'through', 'during',
      'before', 'after', 'above', 'below', 'between', 'among', 'is', 'are',
      'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do',
      'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might',
      'must', 'can', 'this', 'that', 'these', 'those', 'i', 'you', 'he',
      'she', 'it', 'we', 'they', 'what', 'which', 'who', 'when', 'where',
      'why', 'how', 'all', 'any', 'both', 'each', 'few', 'more', 'most',
      'other', 'some', 'such', 'no', 'nor', 'not', 'only', 'own', 'same',
      'so', 'than', 'too', 'very', 'just', 'now',
    };
    
    return terms.where((term) => !stopWords.contains(term) && term.length > 2).toList();
  }

  /// Get field value from document
  String? _getFieldValue(SearchDocument document, String field) {
    switch (field) {
      case 'name':
        return document.title;
      case 'path':
        return document.path;
      case 'content':
        return document.content;
      case 'tags':
        return document.tags.join(' ');
      case 'category':
        return document.category;
      default:
        return document.metadata[field]?.toString();
    }
  }

  /// Update auto-complete suggestions
  void _updateAutoCompleteSuggestions(SearchDocument document) {
    // Add title terms
    final titleTerms = _extractTerms(document.title);
    for (final term in titleTerms) {
      if (!_autoCompleteSuggestions.containsKey(term)) {
        _autoCompleteSuggestions[term] = [];
      }
      if (!_autoCompleteSuggestions[term]!.contains(document.id)) {
        _autoCompleteSuggestions[term]!.add(document.id);
      }
    }
    
    // Add tag terms
    for (final tag in document.tags) {
      final tagTerms = _extractTerms(tag);
      for (final term in tagTerms) {
        if (!_autoCompleteSuggestions.containsKey(term)) {
          _autoCompleteSuggestions[term] = [];
        }
        if (!_autoCompleteSuggestions[term]!.contains(document.id)) {
          _autoCompleteSuggestions[term]!.add(document.id);
        }
      }
    }
  }

  /// Get auto-complete suggestions
  List<String> getAutoCompleteSuggestions(String query) {
    if (!_enableAutoComplete) return [];
    
    final suggestions = <String>[];
    final queryTerms = _extractTerms(query);
    
    for (final term in queryTerms) {
      // Find terms starting with query term
      for (final suggestion in _autoCompleteSuggestions.keys) {
        if (suggestion.startsWith(term) && !suggestions.contains(suggestion)) {
          suggestions.add(suggestion);
        }
      }
    }
    
    // Sort by relevance (number of documents)
    suggestions.sort((a, b) {
      final aCount = _autoCompleteSuggestions[a]?.length ?? 0;
      final bCount = _autoCompleteSuggestions[b]?.length ?? 0;
      return bCount.compareTo(aCount);
    });
    
    // Return top 10 suggestions
    return suggestions.take(10).toList();
  }

  /// Get search suggestions
  Future<List<SearchSuggestion>> getSearchSuggestions(String query) async {
    final suggestions = <SearchSuggestion>[];
    
    // Auto-complete suggestions
    final autoCompleteSuggestions = getAutoCompleteSuggestions(query);
    for (final suggestion in autoCompleteSuggestions) {
      suggestions.add(SearchSuggestion(
        type: SuggestionType.autocomplete,
        text: suggestion,
        description: 'Auto-complete suggestion',
        score: 1.0,
      ));
    }
    
    // History suggestions
    if (_enableSearchHistory) {
      final historySuggestions = _getHistorySuggestions(query);
      suggestions.addAll(historySuggestions);
    }
    
    // Sort and limit
    suggestions.sort((a, b) => b.score.compareTo(a.score));
    
    return suggestions.take(10).toList();
  }

  /// Get history suggestions
  List<SearchSuggestion> _getHistorySuggestions(String query) {
    final suggestions = <SearchSuggestion>[];
    
    for (final searchQuery in _searchHistory) {
      if (searchQuery.query.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(SearchSuggestion(
          type: SuggestionType.history,
          text: searchQuery.query,
          description: 'Recent search',
          score: 0.8,
        ));
      }
    }
    
    return suggestions;
  }

  /// Add to search history
  void _addToSearchHistory(SearchQuery query) {
    // Remove existing entry
    _searchHistory.removeWhere((sq) => sq.query == query.query);
    
    // Add to beginning
    _searchHistory.insert(0, query);
    
    // Keep only last 100 searches
    if (_searchHistory.length > 100) {
      _searchHistory.removeRange(100, _searchHistory.length);
    }
  }

  /// Check if cache entry is expired
  bool _isCacheExpired(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return true;
    
    return DateTime.now().difference(timestamp).inMinutes > 30;
  }

  /// Generate cache key
  String _generateCacheKey(SearchQuery query) {
    final parts = [
      query.query,
      query.type.toString(),
      query.filters.toString(),
      query.sortBy,
      query.sortOrder.toString(),
    ];
    
    return sha256.convert(utf8.encode(parts.join('|'))).toString();
  }

  /// Check if result matches filters
  bool _matchesFilters(SearchResult result, Map<String, dynamic> filters) {
    for (final entry in filters.entries) {
      final key = entry.key;
      final value = entry.value;
      
      switch (key) {
        case 'category':
          if (result.category != value) return false;
          break;
        case 'tags':
          final requiredTags = (value as List).cast<String>();
          for (final tag in requiredTags) {
            if (!result.tags.contains(tag)) return false;
          }
          break;
        case 'size_min':
          final size = result.metadata['size'] as int? ?? 0;
          if (size < value) return false;
          break;
        case 'size_max':
          final size = result.metadata['size'] as int? ?? 0;
          if (size > value) return false;
          break;
        case 'date_after':
          final date = DateTime.parse(result.metadata['modified_at'] as String);
          final afterDate = DateTime.parse(value as String);
          if (date.isBefore(afterDate)) return false;
          break;
        case 'date_before':
          final date = DateTime.parse(result.metadata['modified_at'] as String);
          final beforeDate = DateTime.parse(value as String);
          if (date.isAfter(beforeDate)) return false;
          break;
      }
    }
    
    return true;
  }

  /// Cleanup search cache
  void _cleanupSearchCache() {
    final expiredKeys = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (_isCacheExpired(entry.key)) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _searchCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      EnhancedLogger.instance.info('Cleaned up ${expiredKeys.length} expired search cache entries');
    }
  }

  /// Get search statistics
  Map<String, dynamic> getSearchStatistics() {
    return {
      'indexed_documents': _documentVectors.length,
      'indexed_terms': _invertedIndex.length,
      'search_cache_size': _searchCache.length,
      'auto_complete_suggestions': _autoCompleteSuggestions.length,
      'search_history_size': _searchHistory.length,
      'search_indexes': _searchIndexes.length,
    };
  }

  /// Clear search index
  void clearSearchIndex() {
    _searchIndexes.clear();
    _invertedIndex.clear();
    _documentVectors.clear();
    _autoCompleteSuggestions.clear();
    _searchCache.clear();
    _cacheTimestamps.clear();
    _searchHistory.clear();
    
    // Reinitialize indexes
    _initializeSearchIndexes();
    
    EnhancedLogger.instance.info('Search index cleared');
  }

  /// Dispose
  void dispose() {
    _cacheCleanupTimer?.cancel();
    
    _searchIndexes.clear();
    _invertedIndex.clear();
    _documentVectors.clear();
    _autoCompleteSuggestions.clear();
    _searchCache.clear();
    _cacheTimestamps.clear();
    _searchHistory.clear();
    
    _eventController.close();
    _progressController.close();
    
    EnhancedLogger.instance.info('AI Advanced Search disposed');
  }
}

/// Search index definition
class SearchIndex {
  final String name;
  final IndexType type;
  final List<String> fields;
  final DateTime timestamp;

  SearchIndex({
    required this.name,
    required this.type,
    required this.fields,
    required this.timestamp,
  });
}

/// Document vector for semantic search
class DocumentVector {
  final String documentId;
  final Map<String, double> vector;
  final DateTime timestamp;

  DocumentVector({
    required this.documentId,
    required this.vector,
    required this.timestamp,
  });
}

/// Search document
class SearchDocument {
  final String id;
  final String title;
  final String content;
  final String path;
  final String category;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  SearchDocument({
    required this.id,
    required this.title,
    required this.content,
    required this.path,
    required this.category,
    required this.tags,
    required this.metadata,
    required this.timestamp,
  });
}

/// Search query
class SearchQuery {
  final String query;
  final SearchType type;
  final Map<String, dynamic> filters;
  final String? sortBy;
  final SortOrder sortOrder;
  final DateTime timestamp;

  SearchQuery({
    required this.query,
    this.type = SearchType.exact,
    this.filters = const {},
    this.sortBy,
    this.sortOrder = SortOrder.relevance,
  }) : timestamp = DateTime.now();
}

/// Search results
class SearchResults {
  final SearchQuery query;
  final List<SearchResult> results;
  final int totalCount;
  final DateTime timestamp;
  final bool fromCache;

  SearchResults({
    required this.query,
    required this.results,
    required this.totalCount,
    required this.timestamp,
    required this.fromCache,
  });
}

/// Search result
class SearchResult {
  final String documentId;
  final String title;
  final String path;
  final String category;
  final List<String> tags;
  final String snippet;
  final double score;
  final List<String> matchedTerms;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  SearchResult({
    required this.documentId,
    required this.title,
    required this.path,
    required this.category,
    required this.tags,
    required this.snippet,
    required this.score,
    required this.matchedTerms,
    required this.metadata,
    required this.timestamp,
  });
}

/// Search suggestion
class SearchSuggestion {
  final SuggestionType type;
  final String text;
  final String description;
  final double score;

  SearchSuggestion({
    required this.type,
    required this.text,
    required this.description,
    required this.score,
  });
}

/// Search event
class SearchEvent {
  final SearchEventType type;
  final String query;
  final dynamic result;
  final DateTime timestamp;

  SearchEvent({
    required this.type,
    required this.query,
    this.result,
  }) : timestamp = DateTime.now();
}

/// Search progress
class SearchProgress {
  final String stage;
  final double progress;
  final String? currentFile;
  final DateTime timestamp;

  SearchProgress({
    required this.stage,
    required this.progress,
    this.currentFile,
  }) : timestamp = DateTime.now();
}

/// Enums
enum IndexType { file, content, metadata }
enum SearchType { exact, fuzzy, semantic }
enum SortOrder { relevance, date, size, name }
enum SuggestionType { autocomplete, history, popular }
enum SearchEventType { documentIndexed, searchCompleted, error }
