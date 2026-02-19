import 'package:flutter/material.dart';
import '../../domain/models/search.dart';
import '../../data/repositories/search_repository.dart';
import '../../core/utils.dart';

class SearchProvider extends ChangeNotifier {
  SearchModel _searchModel = const SearchModel();

  SearchModel get searchModel => _searchModel;

  // Getters for convenience
  String get query => _searchModel.query;
  List<SearchResult> get results => _searchModel.sortedResults;
  bool get isLoading => _searchModel.isLoading;
  String? get error => _searchModel.error;
  SearchFilter get filter => _searchModel.filter;
  bool get hasResults => _searchModel.hasResults;
  bool get isEmpty => _searchModel.isEmpty;
  bool get hasError => _searchModel.hasError;
  Map<SearchResultType, int> get resultCounts => _searchModel.resultCounts;

  Future<void> performSearch(String searchQuery) async {
    if (searchQuery.trim().isEmpty) {
      clearSearch();
      return;
    }

    _searchModel = _searchModel.copyWith(
      query: searchQuery,
      isLoading: true,
      error: null,
    );
    notifyListeners();

    try {
      AppUtils.logInfo('Performing search: "$searchQuery"', tag: 'SearchProvider');
      final results = await SearchRepository.search(
        query: searchQuery,
        filter: _searchModel.filter,
      );

      _searchModel = _searchModel.copyWith(
        results: results,
        isLoading: false,
        lastSearched: DateTime.now(),
      );

      AppUtils.logInfo('Search completed: ${results.length} results', tag: 'SearchProvider');
    } catch (e) {
      _searchModel = _searchModel.copyWith(
        isLoading: false,
        error: 'Search failed: ${e.toString()}',
      );
      AppUtils.logError('Search failed', tag: 'SearchProvider', error: e);
    }

    notifyListeners();
  }

  Future<void> performSearchByType(String searchQuery) async {
    if (searchQuery.trim().isEmpty) {
      clearSearch();
      return;
    }

    _searchModel = _searchModel.copyWith(
      query: searchQuery,
      isLoading: true,
      error: null,
    );
    notifyListeners();

    try {
      AppUtils.logInfo('Performing search by type: "$searchQuery"', tag: 'SearchProvider');
      final resultsByType = await SearchRepository.searchByType(query: searchQuery);

      final allResults = <SearchResult>[];
      resultsByType.forEach((type, results) => allResults.addAll(results));

      _searchModel = _searchModel.copyWith(
        results: allResults,
        isLoading: false,
        lastSearched: DateTime.now(),
      );

      AppUtils.logInfo('Search by type completed: ${allResults.length} results', tag: 'SearchProvider');
    } catch (e) {
      _searchModel = _searchModel.copyWith(
        isLoading: false,
        error: 'Search failed: ${e.toString()}',
      );
      AppUtils.logError('Search by type failed', tag: 'SearchProvider', error: e);
    }

    notifyListeners();
  }

  Future<void> performRecentSearch(String searchQuery, {int limit = 10}) async {
    if (searchQuery.trim().isEmpty) {
      clearSearch();
      return;
    }

    _searchModel = _searchModel.copyWith(
      query: searchQuery,
      isLoading: true,
      error: null,
    );
    notifyListeners();

    try {
      AppUtils.logInfo('Performing recent search: "$searchQuery"', tag: 'SearchProvider');
      final results = await SearchRepository.searchRecent(query: searchQuery, limit: limit);

      _searchModel = _searchModel.copyWith(
        results: results,
        isLoading: false,
        lastSearched: DateTime.now(),
      );

      AppUtils.logInfo('Recent search completed: ${results.length} results', tag: 'SearchProvider');
    } catch (e) {
      _searchModel = _searchModel.copyWith(
        isLoading: false,
        error: 'Search failed: ${e.toString()}',
      );
      AppUtils.logError('Recent search failed', tag: 'SearchProvider', error: e);
    }

    notifyListeners();
  }

  void updateFilter(SearchFilter newFilter) {
    _searchModel = _searchModel.copyWith(filter: newFilter);
    if (_searchModel.query.isNotEmpty) {
      performSearch(_searchModel.query);
    }
    notifyListeners();
  }

  void setQuery(String newQuery) {
    _searchModel = _searchModel.copyWith(query: newQuery);
    notifyListeners();
  }

  void clearSearch() {
    _searchModel = const SearchModel();
    notifyListeners();
  }

  void clearError() {
    _searchModel = _searchModel.copyWith(error: null);
    notifyListeners();
  }

  // Navigation helpers
  void navigateToResult(BuildContext context, SearchResult result) {
    String route;
    switch (result.type) {
      case SearchResultType.task:
        route = '/tasks';
        break;
      case SearchResultType.note:
        route = '/notes';
        break;
      case SearchResultType.file:
        route = '/files';
        break;
      case SearchResultType.event:
        route = '/calendar';
        break;
    }

    Navigator.of(context).pushNamed(route);
    AppUtils.logInfo('Navigated to ${result.type.name}: ${result.id}', tag: 'SearchProvider');
  }

  // Recent searches (could be persisted in the future)
  final List<String> _recentSearches = [];

  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  void addRecentSearch(String query) {
    if (query.trim().isNotEmpty) {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 10) {
        _recentSearches.removeLast();
      }
    }
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    notifyListeners();
  }

  // Search suggestions (basic implementation)
  List<String> getSearchSuggestions(String input) {
    if (input.isEmpty) return [];
    return _recentSearches.where((search) => search.toLowerCase().contains(input.toLowerCase())).toList();
  }
}
