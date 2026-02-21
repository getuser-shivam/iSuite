import 'package:flutter/material.dart';

import '../../core/utils.dart';
import '../../data/repositories/calendar_repository.dart';
import '../../domain/models/calendar_event.dart';

class CalendarProvider extends ChangeNotifier {

  CalendarProvider() {
    _loadEvents();
  }
  List<CalendarEvent> _events = [];
  List<CalendarEvent> _filteredEvents = [];
  DateTime _selectedDate = DateTime.now();
  EventType? _selectedType;
  EventStatus? _selectedStatus;
  EventPriority? _selectedPriority;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;
  bool _isGridView = true;
  SortOption _sortBy = SortOption.startTime;
  bool _sortAscending = true;

  // Getters
  List<CalendarEvent> get events => _events;
  List<CalendarEvent> get filteredEvents => _filteredEvents;
  DateTime get selectedDate => _selectedDate;
  EventType? get selectedType => _selectedType;
  EventStatus? get selectedStatus => _selectedStatus;
  EventPriority? get selectedPriority => _selectedPriority;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isGridView => _isGridView;
  SortOption get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  // Computed properties
  int get totalEvents => _events.length;
  int get todayEvents => _events.where((event) => event.isToday).length;
  int get upcomingEvents => _events.where((event) => event.isFuture).length;
  int get pastEvents => _events.where((event) => event.isPast).length;
  int get completedEvents => _events.where((event) => event.status == EventStatus.completed).length;

  Future<void> _loadEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Get user ID from user provider
      _events = await CalendarRepository.getAllEvents();
      _applyFiltersAndSort();
    } catch (e) {
      _error = 'Failed to load events: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createEvent(CalendarEvent event) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate event data
      if (event.title.trim().isEmpty) {
        throw Exception('Event title is required');
      }

      final newEvent = event.copyWith(
        id: AppUtils.generateRandomId(),
        createdAt: DateTime.now(),
      );

      await CalendarRepository.createEvent(newEvent);
      _events.insert(0, newEvent);
      _applyFiltersAndSort();
      
      _error = null;
    } catch (e) {
      _error = 'Failed to create event: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateEvent(CalendarEvent event) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (event.title.trim().isEmpty) {
        throw Exception('Event title is required');
      }

      final updatedEvent = event.copyWith(
        updatedAt: DateTime.now(),
      );

      await CalendarRepository.updateEvent(updatedEvent);
      final index = _events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _events[index] = updatedEvent;
      }
      _applyFiltersAndSort();
      
      _error = null;
    } catch (e) {
      _error = 'Failed to update event: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteEvent(String eventId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await CalendarRepository.deleteEvent(eventId);
      _events.removeWhere((event) => event.id == eventId);
      _applyFiltersAndSort();
      
      _error = null;
    } catch (e) {
      _error = 'Failed to delete event: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleEventStatus(CalendarEvent event) async {
    EventStatus newStatus;
    switch (event.status) {
      case EventStatus.tentative:
        newStatus = EventStatus.confirmed;
        break;
      case EventStatus.confirmed:
        newStatus = EventStatus.completed;
        break;
      case EventStatus.completed:
        newStatus = EventStatus.tentative;
        break;
      case EventStatus.cancelled:
        newStatus = EventStatus.confirmed;
        break;
    }

    await updateEvent(event.copyWith(status: newStatus));
  }

  void setDateFilter(DateTime date) {
    _selectedDate = date;
    _applyFiltersAndSort();
  }

  void setTypeFilter(EventType? type) {
    _selectedType = type;
    _applyFiltersAndSort();
  }

  void setStatusFilter(EventStatus? status) {
    _selectedStatus = status;
    _applyFiltersAndSort();
  }

  void setPriorityFilter(EventPriority? priority) {
    _selectedPriority = priority;
    _applyFiltersAndSort();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFiltersAndSort();
  }

  void clearFilters() {
    _selectedDate = DateTime.now();
    _selectedType = null;
    _selectedStatus = null;
    _selectedPriority = null;
    _searchQuery = '';
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
    _filteredEvents = _events.where((event) {
      // Date filter
      if (_selectedDate != DateTime.now()) {
        final eventDate = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
        if (!eventDate.isSameDay(_selectedDate)) {
          return false;
        }
      }

      // Type filter
      if (_selectedType != null && event.type != _selectedType) {
        return false;
      }

      // Status filter
      if (_selectedStatus != null && event.status != _selectedStatus) {
        return false;
      }

      // Priority filter
      if (_selectedPriority != null && event.priority != _selectedPriority) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final titleMatch = event.title.toLowerCase().contains(query);
        final descriptionMatch = event.description?.toLowerCase().contains(query) ?? false;
        final locationMatch = event.location?.toLowerCase().contains(query) ?? false;
        final tagsMatch = event.tags.any((tag) => tag.toLowerCase().contains(query));
        
        if (!titleMatch && !descriptionMatch && !locationMatch && !tagsMatch) {
          return false;
        }
      }

      return true;
    }).toList();

    // Apply sorting
    _filteredEvents.sort((a, b) {
      var comparison = 0;
      
      switch (_sortBy) {
        case SortOption.title:
          comparison = a.title.compareTo(b.title);
          break;
        case SortOption.startTime:
          comparison = a.startTime.compareTo(b.startTime);
          break;
        case SortOption.priority:
          comparison = b.priority.value.compareTo(a.priority.value);
          break;
        case SortOption.status:
          comparison = a.status.name.compareTo(b.status.name);
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });

    notifyListeners();
  }
}
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void refresh() {
    _loadEvents();
  }
}

enum SortOption {
  title('Title'),
  startTime('Start Time'),
  priority('Priority'),
  status('Status');
}
