import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../../domain/models/search.dart';
import '../../core/utils.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilters(),
          Expanded(
            child: Consumer<SearchProvider>(
              builder: (context, searchProvider, child) {
                if (searchProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (searchProvider.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchProvider.error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => searchProvider.clearError(),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }

                if (searchProvider.isEmpty) {
                  return _buildEmptyState(searchProvider);
                }

                return _buildResultsList(searchProvider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search tasks, notes, files, events...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchProvider.query.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        searchProvider.clearSearch();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            onSubmitted: (query) {
              if (query.trim().isNotEmpty) {
                searchProvider.performSearch(query);
                searchProvider.addRecentSearch(query);
              }
            },
            onChanged: (query) {
              searchProvider.setQuery(query);
            },
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        final filter = searchProvider.filter;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Type filters
                ...SearchResultType.values.map((type) {
                  final isSelected = filter.types.contains(type);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_getTypeLabel(type)),
                      selected: isSelected,
                      onSelected: (selected) {
                        final newTypes = List<SearchResultType>.from(filter.types);
                        if (selected) {
                          newTypes.add(type);
                        } else {
                          newTypes.remove(type);
                        }
                        searchProvider.updateFilter(filter.copyWith(types: newTypes));
                      },
                    ),
                  );
                }),

                const SizedBox(width: 16),

                // Sort options
                DropdownButton<SearchSortBy>(
                  value: filter.sortBy,
                  underline: const SizedBox(),
                  items: SearchSortBy.values.map((sort) {
                    return DropdownMenuItem(
                      value: sort,
                      child: Text('Sort by ${_getSortLabel(sort)}'),
                    );
                  }).toList(),
                  onChanged: (sortBy) {
                    if (sortBy != null) {
                      searchProvider.updateFilter(filter.copyWith(sortBy: sortBy));
                    }
                  },
                ),

                const SizedBox(width: 8),

                // Sort direction
                IconButton(
                  onPressed: () {
                    searchProvider.updateFilter(filter.copyWith(sortAscending: !filter.sortAscending));
                  },
                  icon: Icon(
                    filter.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                  tooltip: filter.sortAscending ? 'Sort ascending' : 'Sort descending',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(SearchProvider searchProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchProvider.query.isEmpty ? Icons.search : Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            searchProvider.query.isEmpty
                ? 'Start searching...'
                : 'No results found for "${searchProvider.query}"',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          if (searchProvider.recentSearches.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Recent searches',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: searchProvider.recentSearches.take(5).map((search) {
                return Chip(
                  label: Text(search),
                  onDeleted: () {
                    // Could implement remove recent search
                  },
                  deleteIcon: const Icon(Icons.history),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsList(SearchProvider searchProvider) {
    final results = searchProvider.results;
    final counts = searchProvider.resultCounts;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildResultsHeader(counts, results.length);
        }

        final result = results[index - 1];
        return _buildResultItem(result, searchProvider);
      },
    );
  }

  Widget _buildResultsHeader(Map<SearchResultType, int> counts, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$total results found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: counts.entries.map((entry) {
              return Text(
                '${_getTypeLabel(entry.key)}: ${entry.value}',
                style: const TextStyle(color: Colors.grey),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(SearchResult result, SearchProvider searchProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(result.type),
          child: Icon(
            _getTypeIcon(result.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          result.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  result.formattedDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTypeColor(result.type).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    result.type.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getTypeColor(result.type),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
        onTap: () => searchProvider.navigateToResult(context, result),
      ),
    );
  }

  String _getTypeLabel(SearchResultType type) {
    switch (type) {
      case SearchResultType.task:
        return 'Tasks';
      case SearchResultType.note:
        return 'Notes';
      case SearchResultType.file:
        return 'Files';
      case SearchResultType.event:
        return 'Events';
    }
  }

  String _getSortLabel(SearchSortBy sort) {
    switch (sort) {
      case SearchSortBy.relevance:
        return 'Relevance';
      case SearchSortBy.date:
        return 'Date';
      case SearchSortBy.type:
        return 'Type';
    }
  }

  IconData _getTypeIcon(SearchResultType type) {
    switch (type) {
      case SearchResultType.task:
        return Icons.task;
      case SearchResultType.note:
        return Icons.note;
      case SearchResultType.file:
        return Icons.folder;
      case SearchResultType.event:
        return Icons.event;
    }
  }

  Color _getTypeColor(SearchResultType type) {
    switch (type) {
      case SearchResultType.task:
        return Colors.blue;
      case SearchResultType.note:
        return Colors.green;
      case SearchResultType.file:
        return Colors.orange;
      case SearchResultType.event:
        return Colors.purple;
    }
  }
}
