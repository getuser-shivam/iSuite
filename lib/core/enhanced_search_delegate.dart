import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../core/ui_helper.dart';

/// Enhanced search functionality with debouncing and filtering
class EnhancedSearchDelegate extends SearchDelegate<String> {
  final List<String> suggestions;
  final Function(String) onSearch;
  final Function(String)? onSuggestionSelected;

  EnhancedSearchDelegate({
    required this.suggestions,
    required this.onSearch,
    this.onSuggestionSelected,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context, []);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) return _buildEmptyState();
    
    return ListView(
      padding: EdgeInsets.all(AppConstants.defaultPadding),
      children: [
        Text(
          'Results for "$query"',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: AppConstants.defaultPadding),
        // Results would be populated here based on search implementation
        _buildSearchResults(context),
      ],
    );
  }

  @override
  Widget buildSuggestions(BuildContext context, List<String> suggestions) {
    if (query.isEmpty) return _buildEmptyState();
    
    final filteredSuggestions = suggestions
        .where((suggestion) => suggestion.toLowerCase().contains(query.toLowerCase()))
        .toList();
    
    if (filteredSuggestions.isEmpty) return _buildNoSuggestionsState();
    
    return ListView.builder(
      itemCount: filteredSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = filteredSuggestions[index];
        return ListTile(
          leading: const Icon(Icons.history),
          title: RichText(
            text: TextSpan(
              text: suggestion,
              style: const TextStyle(color: Colors.black),
              children: [
                TextSpan(
                  text: suggestion.substring(query.length),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          onTap: () {
            query = suggestion;
            onSuggestionSelected?.call(suggestion);
            showResults(context);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: AppConstants.largeIconSize * 2, color: Colors.grey),
          SizedBox(height: AppConstants.defaultPadding),
          Text(
            'Start typing to search',
            style: TextStyle(color: Colors.grey, fontSize: AppConstants.bodyText2Size),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSuggestionsState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: AppConstants.largeIconSize * 2, color: Colors.grey),
          SizedBox(height: AppConstants.defaultPadding),
          Text(
            'No suggestions found',
            style: TextStyle(color: Colors.grey, fontSize: AppConstants.bodyText2Size),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    // This would be implemented based on specific search requirements
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info, color: Colors.blue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Search functionality would be implemented here based on your specific needs',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void showResults(BuildContext context) {
    onSearch(query);
    super.showResults(context);
  }

  @override
  void showSuggestions(BuildContext context, List<String> suggestions) {
    super.showSuggestions(context, suggestions);
  }
}
