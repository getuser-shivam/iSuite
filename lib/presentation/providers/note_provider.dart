import 'package:flutter/material.dart';
import '../../domain/models/note.dart';
import '../../core/utils.dart';
import '../../data/repositories/note_repository.dart';

class NoteProvider extends ChangeNotifier {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  NoteType _selectedType = NoteType.text;
  NoteStatus _selectedStatus = NoteStatus.draft;
  NotePriority _selectedPriority = NotePriority.medium;
  NoteCategory _selectedCategory = NoteCategory.personal;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;
  bool _isGridView = true;
  SortOption _sortBy = SortOption.updatedAt;
  bool _sortAscending = false;
  bool _showFavorites = false;
  bool _showPinned = false;
  bool _showArchived = false;

  // Getters
  List<Note> get notes => _notes;
  List<Note> get filteredNotes => _filteredNotes;
  NoteType get selectedType => _selectedType;
  NoteStatus get selectedStatus => _selectedStatus;
  NotePriority get selectedPriority => _selectedPriority;
  NoteCategory get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isGridView => _isGridView;
  SortOption get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;
  bool get showFavorites => _showFavorites;
  bool get showPinned => _showPinned;
  bool get showArchived => _showArchived;

  // Computed properties
  int get totalNotes => _notes.length;
  int get draftNotes => _notes.where((note) => note.status == NoteStatus.draft).length;
  int get publishedNotes => _notes.where((note) => note.status == NoteStatus.published).length;
  int get archivedNotes => _notes.where((note) => note.isArchived).length;
  int get favoriteNotes => _notes.where((note) => note.isFavorite).length;
  int get pinnedNotes => _notes.where((note) => note.isPinned).length;
  int get overdueNotes => _notes.where((note) => note.isOverdue).length;
  int get dueTodayNotes => _notes.where((note) => note.isDueToday).length;
  int get dueSoonNotes => _notes.where((note) => note.isDueSoon).length;

  NoteProvider() {
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppUtils.logInfo('Loading notes...', tag: 'NoteProvider');
      // TODO: Get user ID from user provider
      _notes = await NoteRepository.getAllNotes();
      _applyFiltersAndSort();
      AppUtils.logInfo('Notes loaded successfully: ${_notes.length} notes', tag: 'NoteProvider');
    } catch (e) {
      _error = 'Failed to load notes: ${e.toString()}';
      AppUtils.logError('Failed to load notes', tag: 'NoteProvider', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createNote({
    required String title,
    String? content,
    NoteType type = NoteType.text,
    NotePriority priority = NotePriority.medium,
    NoteCategory category = NoteCategory.personal,
    List<String> tags = const [],
    DateTime? dueDate,
    bool isPinned = false,
    bool isFavorite = false,
    String? color,
    bool isEncrypted = false,
    String? password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppUtils.logInfo('Creating note: $title', tag: 'NoteProvider');
      // Validate note data
      if (title.trim().isEmpty) {
        throw Exception('Note title is required');
      }

      final note = Note(
        id: AppUtils.generateRandomId(),
        title: title.trim(),
        content: content?.trim(),
        type: type,
        status: NoteStatus.draft,
        priority: priority,
        category: category,
        tags: tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: dueDate,
        isPinned: isPinned,
        isArchived: false,
        isFavorite: isFavorite,
        color: color,
        isEncrypted: isEncrypted,
        password: password,
      );

      await NoteRepository.createNote(note);
      AppUtils.logInfo('Note created successfully: ${note.id}', tag: 'NoteProvider');
      _notes.insert(0, note);
      _applyFiltersAndSort();
      
      _error = null;
    } catch (e) {
      _error = 'Failed to create note: ${e.toString()}';
      AppUtils.logError('Failed to create note', tag: 'NoteProvider', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateNote(Note note) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (note.title.trim().isEmpty) {
        throw Exception('Note title is required');
      }

      final updatedNote = note.copyWith(
        updatedAt: DateTime.now(),
        wordCount: note.content?.split(' ').length ?? 0,
        readingTime: note.content?.split(' ').length ?? 0,
      );

      await NoteRepository.updateNote(updatedNote);
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = updatedNote;
      }
      _applyFiltersAndSort();
      
      _error = null;
    } catch (e) {
      _error = 'Failed to update note: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteNote(String noteId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await NoteRepository.deleteNote(noteId);
      _notes.removeWhere((note) => note.id == noteId);
      _applyFiltersAndSort();
      
      _error = null;
    } catch (e) {
      _error = 'Failed to delete note: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleNoteFavorite(Note note) async {
    try {
      await NoteRepository.toggleNoteFavorite(note.id);
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note.copyWith(isFavorite: !note.isFavorite);
      }
      _applyFiltersAndSort();
    } catch (e) {
      _error = 'Failed to toggle favorite: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> toggleNotePin(Note note) async {
    try {
      await NoteRepository.toggleNotePin(note.id);
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note.copyWith(isPinned: !note.isPinned);
      }
      _applyFiltersAndSort();
    } catch (e) {
      _error = 'Failed to toggle pin: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> archiveNote(Note note) async {
    try {
      await NoteRepository.archiveNote(note.id);
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note.copyWith(isArchived: true, status: NoteStatus.archived);
      }
      _applyFiltersAndSort();
    } catch (e) {
      _error = 'Failed to archive note: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> unarchiveNote(Note note) async {
    try {
      await NoteRepository.unarchiveNote(note.id);
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note.copyWith(isArchived: false, status: NoteStatus.draft);
      }
      _applyFiltersAndSort();
    } catch (e) {
      _error = 'Failed to unarchive note: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> publishNote(Note note) async {
    try {
      final updatedNote = note.copyWith(status: NoteStatus.published);
      await NoteRepository.updateNote(updatedNote);
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = updatedNote;
      }
      _applyFiltersAndSort();
    } catch (e) {
      _error = 'Failed to publish note: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> deleteAllNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await NoteRepository.deleteAllNotes();
      _notes.clear();
      _filteredNotes.clear();
      
      _error = null;
    } catch (e) {
      _error = 'Failed to delete all notes: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setTypeFilter(NoteType type) {
    _selectedType = type;
    _applyFiltersAndSort();
  }

  void setStatusFilter(NoteStatus status) {
    _selectedStatus = status;
    _applyFiltersAndSort();
  }

  void setPriorityFilter(NotePriority priority) {
    _selectedPriority = priority;
    _applyFiltersAndSort();
  }

  void setCategoryFilter(NoteCategory category) {
    _selectedCategory = category;
    _applyFiltersAndSort();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFiltersAndSort();
  }

  void toggleFavorites() {
    _showFavorites = !_showFavorites;
    _applyFiltersAndSort();
  }

  void togglePinned() {
    _showPinned = !_showPinned;
    _applyFiltersAndSort();
  }

  void toggleArchived() {
    _showArchived = !_showArchived;
    _applyFiltersAndSort();
  }

  void clearFilters() {
    _selectedType = NoteType.text;
    _selectedStatus = NoteStatus.draft;
    _selectedPriority = NotePriority.medium;
    _selectedCategory = NoteCategory.personal;
    _searchQuery = '';
    _showFavorites = false;
    _showPinned = false;
    _showArchived = false;
    _applyFiltersAndSort();
  }

  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  void setSortOption(SortOption sortBy, {bool ascending = true}) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    _filteredNotes = _notes.where((note) {
      // Type filter
      if (_selectedType != NoteType.text && note.type != _selectedType) {
        return false;
      }

      // Status filter
      if (_selectedStatus != NoteStatus.draft && note.status != _selectedStatus) {
        return false;
      }

      // Priority filter
      if (_selectedPriority != NotePriority.medium && note.priority != _selectedPriority) {
        return false;
      }

      // Category filter
      if (_selectedCategory != NoteCategory.personal && note.category != _selectedCategory) {
        return false;
      }

      // Special filters
      if (_showFavorites && !note.isFavorite) {
        return false;
      }

      if (_showPinned && !note.isPinned) {
        return false;
      }

      if (_showArchived && !note.isArchived) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final titleMatch = note.title.toLowerCase().contains(query);
        final contentMatch = note.content?.toLowerCase().contains(query) ?? false;
        final tagsMatch = note.tags.any((tag) => tag.toLowerCase().contains(query));
        
        if (!titleMatch && !contentMatch && !tagsMatch) {
          return false;
        }
      }

      return true;
    }).toList();

    // Apply sorting
    _filteredNotes.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case SortOption.title:
          comparison = a.title.compareTo(b.title);
          break;
        case SortOption.createdAt:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case SortOption.updatedAt:
          comparison = a.updatedAt?.compareTo(b.updatedAt ?? b.createdAt) ?? 0;
          break;
        case SortOption.dueDate:
          comparison = _compareDueDates(a, b);
          break;
        case SortOption.priority:
          comparison = b.priority.value.compareTo(a.priority.value);
          break;
        case SortOption.category:
          comparison = a.category.name.compareTo(b.category.name);
          break;
        case SortOption.type:
          comparison = a.type.name.compareTo(b.type.name);
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });

    notifyListeners();
  }

  int _compareDueDates(Note a, Note b) {
    if (a.dueDate == null && b.dueDate == null) {
      return 0;
    } else if (a.dueDate == null) {
      return 1;
    } else if (b.dueDate == null) {
      return -1;
    } else {
      return a.dueDate!.compareTo(b.dueDate!);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void refresh() {
    _loadNotes();
  }

  Future<Map<String, int>> getStatistics() async {
    try {
      return await NoteRepository.getNoteStatistics();
    } catch (e) {
      _error = 'Failed to get statistics: ${e.toString()}';
      notifyListeners();
      return {};
    }
  }
}

enum SortOption {
  title('Title'),
  createdAt('Created'),
  updatedAt('Updated'),
  dueDate('Due Date'),
  priority('Priority'),
  category('Category'),
  type('Type');
}
