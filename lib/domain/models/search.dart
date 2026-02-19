import 'package:equatable/equatable.dart';

enum SearchResultType {
  task,
  note,
  file,
  event,
}

enum SearchSortBy {
  relevance,
  date,
  type,
}

class SearchResult extends Equatable {
  final String id;
  final SearchResultType type;
  final String title;
  final String subtitle;
  final DateTime date;
  final double relevanceScore;
  final Map<String, dynamic> metadata;

  const SearchResult({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
    this.relevanceScore = 0.0,
    this.metadata = const {},
  });

  SearchResult copyWith({
    String? id,
    SearchResultType? type,
    String? title,
    String? subtitle,
    DateTime? date,
    double? relevanceScore,
    Map<String, dynamic>? metadata,
  }) {
    return SearchResult(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      date: date ?? this.date,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [id, type, title, subtitle, date, relevanceScore, metadata];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchResult &&
        other.id == id &&
        other.type == type &&
        other.title == title &&
        other.subtitle == subtitle &&
        other.date == date &&
        other.relevanceScore == relevanceScore &&
        other.metadata == metadata;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      type,
      title,
      subtitle,
      date,
      relevanceScore,
      metadata,
    );
  }
}

class SearchFilter extends Equatable {
  final List<SearchResultType> types;
  final DateTime? startDate;
  final DateTime? endDate;
  final SearchSortBy sortBy;
  final bool sortAscending;

  const SearchFilter({
    this.types = const [SearchResultType.task, SearchResultType.note, SearchResultType.file, SearchResultType.event],
    this.startDate,
    this.endDate,
    this.sortBy = SearchSortBy.relevance,
    this.sortAscending = false,
  });

  SearchFilter copyWith({
    List<SearchResultType>? types,
    DateTime? startDate,
    DateTime? endDate,
    SearchSortBy? sortBy,
    bool? sortAscending,
  }) {
    return SearchFilter(
      types: types ?? this.types,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  @override
  List<Object?> get props => [types, startDate, endDate, sortBy, sortAscending];
}

class SearchModel extends Equatable {
  final String query;
  final List<SearchResult> results;
  final SearchFilter filter;
  final bool isLoading;
  final String? error;
  final DateTime? lastSearched;

  const SearchModel({
    this.query = '',
    this.results = const [],
    this.filter = const SearchFilter(),
    this.isLoading = false,
    this.error,
    this.lastSearched,
  });

  SearchModel copyWith({
    String? query,
    List<SearchResult>? results,
    SearchFilter? filter,
    bool? isLoading,
    String? error,
    DateTime? lastSearched,
  }) {
    return SearchModel(
      query: query ?? this.query,
      results: results ?? this.results,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastSearched: lastSearched ?? this.lastSearched,
    );
  }

  // Computed properties
  bool get hasResults => results.isNotEmpty;
  bool get isEmpty => query.isNotEmpty && results.isEmpty && !isLoading;
  bool get hasError => error != null;

  Map<SearchResultType, int> get resultCounts {
    final counts = <SearchResultType, int>{};
    for (final result in results) {
      counts[result.type] = (counts[result.type] ?? 0) + 1;
    }
    return counts;
  }

  List<SearchResult> get sortedResults {
    final sorted = List<SearchResult>.from(results);

    switch (filter.sortBy) {
      case SearchSortBy.relevance:
        sorted.sort((a, b) => filter.sortAscending
            ? a.relevanceScore.compareTo(b.relevanceScore)
            : b.relevanceScore.compareTo(a.relevanceScore));
        break;
      case SearchSortBy.date:
        sorted.sort((a, b) => filter.sortAscending
            ? a.date.compareTo(b.date)
            : b.date.compareTo(a.date));
        break;
      case SearchSortBy.type:
        sorted.sort((a, b) => filter.sortAscending
            ? a.type.name.compareTo(b.type.name)
            : b.type.name.compareTo(a.type.name));
        break;
    }

    return sorted;
  }

  @override
  List<Object?> get props => [query, results, filter, isLoading, error, lastSearched];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchModel &&
        other.query == query &&
        other.results == results &&
        other.filter == filter &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.lastSearched == lastSearched;
  }

  @override
  int get hashCode {
    return Object.hash(
      query,
      results,
      filter,
      isLoading,
      error,
      lastSearched,
    );
  }
}
