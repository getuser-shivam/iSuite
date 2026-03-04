import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/calendar_event.dart';
import '../providers/calendar_provider.dart';
import '../widgets/calendar_view.dart';
import '../widgets/event_dialog.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final DateTime _currentMonth = DateTime.now();
  final CalendarViewType _viewType = CalendarViewType.monthly;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    _loadEvents();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
    await calendarProvider.refresh();
  }

  void _showAddEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EventDialog(
        onSave: (eventData) async {
          final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
          await calendarProvider.createEvent(CalendarEvent(
            id: eventData['id'],
            title: eventData['title'],
            description: eventData['description'],
            startTime: eventData['startTime'],
            endTime: eventData['endTime'],
            type: eventData['type'],
            priority: eventData['priority'],
            attendees: eventData['attendees']?.split(',').map((e) => e.trim()).toList(),
            location: eventData['location'],
            notes: eventData['notes'],
            tags: eventData['tags']?.split(',').map((e) => e.trim()).toList(),
          ));
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: 'Event created successfully',
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calendarProvider = Provider.of<CalendarProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () => _goToToday(context),
            tooltip: 'Go to Today',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'month',
                child: ListTile(
                  leading: Icon(Icons.calendar_view_month),
                  title: Text('Month View'),
                ),
              ),
              const PopupMenuItem(
                value: 'week',
                child: ListTile(
                  leading: Icon(Icons.calendar_view_week),
                  title: Text('Week View'),
                ),
              ),
              const PopupMenuItem(
                value: 'day',
                child: ListTile(
                  leading: Icon(Icons.calendar_view_day),
                  title: Text('Day View'),
                ),
              ),
              const PopupMenuItem(
                value: 'list',
                child: ListTile(
                  leading: Icon(Icons.list),
                  title: Text('List View'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Header with month navigation
              _buildHeader(context),
              
              // Calendar view
              Expanded(
                child: CalendarView(
                  viewType: _viewType,
                  selectedDate: calendarProvider.selectedDate,
                  events: calendarProvider.filteredEvents,
                  onEventTap: (event) => _showEventDetails(context, event),
                  onDateTap: (date) => _selectDate(context, date),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEventDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final calendarProvider = Provider.of<CalendarProvider>(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Month navigation
              Row(
                children: [
                  IconButton(
                    onPressed: () => _navigateMonth(context, -1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _formatMonth(calendarProvider.selectedDate),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _navigateMonth(context, 1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              
              // View type selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildViewTypeButton(context, CalendarViewType.monthly, Icons.calendar_view_month),
                  const SizedBox(width: 8),
                  _buildViewTypeButton(context, CalendarViewType.weekly, Icons.calendar_view_week),
                  const SizedBox(width: 8),
                  _buildViewTypeButton(context, CalendarViewType.daily, Icons.calendar_view_day),
                  const SizedBox(width: 8),
                  _buildViewTypeButton(context, CalendarViewType.list, Icons.list),
                ],
              ),
            ],
          ],
          const SizedBox(height: 16),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(context, 'All', calendarProvider.selectedType == null),
                _buildFilterChip(context, 'Meeting', EventType.meeting),
                _buildFilterChip(context, 'Appointment', EventType.appointment),
                _buildFilterChip(context, 'Deadline', EventType.deadline),
                _buildFilterChip(context, 'Personal', EventType.personal),
                _buildFilterChip(context, 'Work', EventType.work),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTypeButton(BuildContext context, CalendarViewType type, IconData icon) {
    final calendarProvider = Provider.of<CalendarProvider>(context);
    final isSelected = calendarProvider._viewType == type;
    
    return FilterChip(
      label: type.name,
      avatar: Icon(icon),
      selected: isSelected,
      onSelected: () {
        calendarProvider.setSortOption(SortOption.startTime);
        // TODO: Change view type
      },
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, EventType? type) {
    final calendarProvider = Provider.of<CalendarProvider>(context);
    final isSelected = calendarProvider.selectedType == type;
    
    return FilterChip(
      label: label,
      avatar: type != null ? Icon(_getEventTypeIcon(type)) : null,
      selected: isSelected,
      onSelected: () {
        calendarProvider.setTypeFilter(isSelected ? null : type);
      },
    );
  }

  IconData _getEventTypeIcon(EventType? type) {
    switch (type) {
      case EventType.meeting:
        return Icons.business_center;
      case EventType.appointment:
        return Icons.event_available;
      case EventType.deadline:
        return Icons.alarm;
      case EventType.reminder:
        return Icons.notifications;
      case EventType.birthday:
        return Icons.cake;
      case EventType.holiday:
        return Icons.celebration;
      case EventType.personal:
        return Icons.person;
      case EventType.work:
        return Icons.work;
      case EventType.other:
        return Icons.more_horiz;
      default:
        return Icons.event;
    }
  }

  String _formatMonth(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}';

  void _navigateMonth(BuildContext context, int offset) {
    final calendarProvider = Provider.of<CalendarProvider>(context);
    final newDate = DateTime(calendarProvider.selectedDate.year, calendarProvider.selectedDate.month + offset);
    calendarProvider.setDateFilter(newDate);
  }

  void _selectDate(BuildContext context, DateTime date) {
    final calendarProvider = Provider.of<CalendarProvider>(context);
    calendarProvider.setDateFilter(date);
  }

  void _goToToday(BuildContext context) {
    final calendarProvider = Provider.of<CalendarProvider>(context);
    calendarProvider.setDateFilter(DateTime.now());
  }

  void _showEventDetails(BuildContext context, CalendarEvent event) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController, _) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (event.description != null) ...[
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(event.description!),
                const SizedBox(height: 16),
              ],
              _buildDetailRow('Time', event.formattedTimeRange),
              if (event.location != null) ...[
                _buildDetailRow('Location', event.location!),
              ],
              if (event.attendees.isNotEmpty) ...[
                _buildDetailRow('Attendees', event.attendees.join(', ')),
              ],
              if (event.notes != null) ...[
                _buildDetailRow('Notes', event.notes!),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Edit event
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: event.priority.color,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );

  void _handleMenuAction(BuildContext context, String action) {
    final calendarProvider = Provider.of<CalendarProvider>(context);
    
    switch (action) {
      case 'month':
        calendarProvider._viewType = CalendarViewType.monthly;
        break;
      case 'week':
        calendarProvider._viewType = CalendarViewType.weekly;
        break;
      case 'day':
        calendarProvider._viewType = CalendarViewType.daily;
        break;
      case 'list':
        calendarProvider._viewType = CalendarViewType.list;
        break;
    }
  }
}

class EventDialog extends StatefulWidget {

  const EventDialog({
    required this.onSave, super.key,
    this.event,
  });
  final CalendarEvent? event;
  final Function(Map<String, dynamic>) onSave;

  @override
  State<EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _attendeesController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _dueDateController = TextEditingController();
  
  EventType _selectedType = EventType.meeting;
  EventPriority _selectedPriority = EventPriority.medium;
  DateTime? _selectedStartTime;
  DateTime? _selectedEndTime;
  DateTime? _selectedDueDate;
  bool _isAllDay = false;

  @override
  Widget build(BuildContext context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event == null ? 'Add Event' : 'Edit Event',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                
                // Type and Priority
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<EventType>(
                        initialValue: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        items: EventType.values.map((type) => DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Icon(_getEventTypeIcon(type)),
                                const SizedBox(width: 8),
                                Text(type.name),
                              ],
                            ),
                          )).toList(),
                        onChanged: (value) => setState(() => _selectedType = value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<EventPriority>(
                        initialValue: _selectedPriority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          prefixIcon: Icon(Icons.flag),
                          border: OutlineInputBorder(),
                        ),
                        items: EventPriority.values.map((priority) => DropdownMenuItem(
                            value: priority,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: priority.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(priority.label),
                              ],
                            ),
                          )).toList(),
                        onChanged: (value) => setState(() => _selectedPriority = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Date and Time
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Start Time',
                          prefixIcon: Icon(Icons.access_time),
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () => _selectDateTime(context, 'start'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _endTimeController,
                        decoration: const InputDecoration(
                          labelText: 'End Time',
                          prefixIcon: Icon(Icons.access_time),
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () => _selectDateTime(context, 'end'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dueDateController,
                        decoration: const InputDecoration(
                          labelText: 'Due Date',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context, 'due'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CheckboxListTile(
                      title: const Text('All Day Event'),
                      value: _isAllDay,
                      onChanged: (value) => setState(() => _isAllDay = value),
                    ),
                  ],
                ),
                ],
                
                // Location
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Attendees
                TextFormField(
                  controller: _attendeesController,
                  decoration: const InputDecoration(
                    labelText: 'Attendees (comma separated)',
                    prefixIcon: Icon(Icons.people),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.note),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(widget.event == null ? 'Add Event' : 'Update'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

  Future<void> _selectDateTime(BuildContext context, String field) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: field == 'start' ? _selectedStartTime : _selectedDueDate,
      firstDate: field == 'start' ? _selectedStartTime : DateTime.now(),
    );
    
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(field == 'start' ? _selectedStartTime ?? DateTime.now() : _selectedDueDate ?? DateTime.now()),
      );
      
      final dateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time,
      );
      
      setState(() {
        if (field == 'start') {
          _selectedStartTime = dateTime;
        } else {
          _selectedDueDate = dateTime;
        }
      });
    }
  }

  void _saveEvent() {
    if (_formKey.currentState?.validate() ?? false) {
      final eventData = {
        'id': widget.event?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'startTime': _selectedStartTime?.millisecondsSinceEpoch,
        'endTime': _endTimeController.text.trim().isNotEmpty 
            ? DateTime.parse(_endTimeController.text).millisecondsSinceEpoch
            : null,
        'dueDate': _selectedDueDate?.millisecondsSinceEpoch,
        'type': _selectedType.name,
        'priority': _selectedPriority.value,
        'attendees': _attendeesController.text.trim(),
        'location': _locationController.text.trim(),
        'notes': _notesController.text.trim(),
      };
      
      widget.onSave(eventData);
      Navigator.pop(context);
    }
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.meeting:
        return Icons.business_center;
      case EventType.appointment:
        return Icons.event_available;
      case EventType.deadline:
        return Icons.alarm;
      case EventType.reminder:
        return Icons.notifications;
      case EventType.birthday:
        return Icons.cake;
      case EventType.holiday:
        return Icons.celebration;
      case EventType.personal:
        return Icons.person;
      case EventType.work:
        return Icons.work;
      case EventType.other:
        return Icons.more_horiz;
      default:
        return Icons.event;
    }
  }
}

enum CalendarViewType {
  monthly,
  weekly,
  daily,
  list;
}
