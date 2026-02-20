import '../../core/utils.dart';
import '../../domain/models/search.dart';
import 'calendar_repository.dart';
import 'file_repository.dart';
import 'note_repository.dart';
import 'task_repository.dart';

class SearchRepository {
  static Future<List<SearchResult>> search({
    required String query,
    SearchFilter filter = const SearchFilter(),
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final results = <SearchResult>[];
    final queryLower = query.toLowerCase().trim();

    try {
      AppUtils.logInfo('Performing global search: "$query"',
          tag: 'SearchRepository');

      // Search tasks
      if (filter.types.contains(SearchResultType.task)) {
        final tasks = await TaskRepository.getAllTasks();
        for (final task in tasks) {
          final score = _calculateSearchScore(
              query: queryLower, title: task.title, description: task.description, tags: task.tags);
          if (score > 0) {
            results.add(SearchResult(
              id: task.id,
              type: SearchResultType.task,
              title: task.title,
              subtitle: task.description ?? 'No description',
              date: task.createdAt ?? DateTime.now(),
              relevanceScore: score,
              metadata: {
                'status': task.status.name,
                'priority': task.priority.name,
                'category': task.category,
              },
            ));
          }
        }
      }

      // Search notes
      if (filter.types.contains(SearchResultType.note)) {
        final notes = await NoteRepository.getAllNotes();
        for (final note in notes) {
          final score = _calculateSearchScore(
              query: queryLower, title: note.title, description: note.content, tags: note.tags);
          if (score > 0) {
            results.add(SearchResult(
              id: note.id,
              type: SearchResultType.note,
              title: note.title,
              subtitle:
                  note.content?.substring(0, min(100.0, note.content!.length.toDouble()).toInt()) ??
                      'No content',
              date: note.createdAt ?? DateTime.now(),
              relevanceScore: score,
              metadata: {
                'type': note.type.name,
                'status': note.status.name,
                'wordCount': note.wordCount,
              },
            ));
          }
        }
      }

      // Search files
      if (filter.types.contains(SearchResultType.file)) {
        final files = await FileRepository.getAllFiles();
        for (final file in files) {
          final score = _calculateRelevanceScore(
              queryLower, file.name, file.description, file.tags);
          if (score > 0) {
            results.add(SearchResult(
              id: file.id,
              type: SearchResultType.file,
              title: file.name,
              subtitle: file.description ?? 'No description',
              date: file.updatedAt,
              relevanceScore: score,
              metadata: {
                'size': file.formattedSize,
                'type': file.type.name,
                'status': file.status.name,
              },
            ));
          }
        }
      }

      // Search events
      if (filter.types.contains(SearchResultType.event)) {
        final events = await CalendarRepository.getAllEvents();
        for (final event in events) {
          final score = _calculateSearchScore(
              query: queryLower, title: event.title, description: event.description, tags: event.tags);
          if (score > 0) {
            results.add(SearchResult(
              id: event.id,
              type: SearchResultType.event,
              title: event.title,
              subtitle: event.description ?? 'No description',
              date: event.createdAt,
              relevanceScore: score,
              metadata: {
                'type': event.eventType,
                'status': event.status.name,
                'startDate': event.startTime.toIso8601String(),
                'endDate': event.endTime?.toIso8601String() ?? '',
              },
            ));
          }
        }
      }

      // Apply date filters
      if (filter.startDate != null || filter.endDate != null) {
        results.retainWhere((result) {
          if (filter.startDate != null &&
              result.date.isBefore(filter.startDate!)) {
            return false;
          }
          if (filter.endDate != null && result.date.isAfter(filter.endDate!)) {
            return false;
          }
          return true;
        });
      }

      // Sort results
      results.sort((a, b) {
        switch (filter.sortBy) {
          case SearchSortBy.relevance:
            return filter.sortAscending
                ? a.relevanceScore.compareTo(b.relevanceScore)
                : b.relevanceScore.compareTo(a.relevanceScore);
          case SearchSortBy.date:
            return filter.sortAscending
                ? a.date.compareTo(b.date)
                : b.date.compareTo(a.date);
          case SearchSortBy.type:
            return filter.sortAscending
                ? a.type.name.compareTo(b.type.name)
                : b.type.name.compareTo(a.type.name);
        }
      });

      AppUtils.logInfo('Search completed: ${results.length} results found',
          tag: 'SearchRepository');

      return results;
    } catch (e) {
      AppUtils.logError('Search failed', tag: 'SearchRepository', error: e);
      rethrow;
    }
  }

  static Future<List<SearchResult>> searchRecent({
    required String query,
    int limit = 10,
  }) async {
    final allResults = await search(query: query);
    return allResults.take(limit).toList();
  }

  static Future<Map<SearchResultType, List<SearchResult>>> searchByType({
    required String query,
  }) async {
    final allResults = await search(query: query);
    final grouped = <SearchResultType, List<SearchResult>>{};

    for (final result in allResults) {
      grouped[result.type] = (grouped[result.type] ?? [])..add(result);
    }

    return grouped;
  }

  static double _calculateSearchScore({
    String query,
    String? title,
    String? description,
    List<String>? tags,
  }) {
    double score = 0.0;
    final queryWords =
        query.split(' ').where((word) => word.isNotEmpty).toList();

    // Title matches (highest weight)
    if (title != null) {
      final titleLower = title.toLowerCase();
      for (final word in queryWords) {
        if (titleLower.contains(word)) {
          score += 10.0;
          if (titleLower.startsWith(word)) {
            score += 5.0; // Bonus for starting matches
          }
        }
      }
    }

    // Description matches (medium weight)
    if (description != null) {
      final descLower = description.toLowerCase();
      for (final word in queryWords) {
        if (descLower.contains(word)) {
          score += 3.0;
        }
      }
    }

    // Tag matches (high weight)
    if (tags != null) {
      for (final tag in tags) {
        final tagLower = tag.toLowerCase();
        for (final word in queryWords) {
          if (tagLower.contains(word)) {
            score += 7.0;
          }
        }
      }
    }

    // Exact phrase match bonus
    if (title != null && title.toLowerCase().contains(query)) {
      score += 15.0;
    }
    if (description != null && description.toLowerCase().contains(query)) {
      score += 8.0;
    }

    return score;
  }

  static double min(double a, double b) => a < b ? a : b;
}
