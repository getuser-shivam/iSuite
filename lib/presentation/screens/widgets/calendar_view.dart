import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../domain/models/calendar_event.dart';

class CalendarView extends StatefulWidget {

  const CalendarView({
    required this.viewType, required this.selectedDate, required this.events, required this.onEventTap, required this.onDateTap, super.key,
  });
  final CalendarViewType viewType;
  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final Function(CalendarEvent) onEventTap;
  final Function(DateTime) onDateTap;

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      keepAlive: true,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.viewType) {
      case CalendarViewType.monthly:
        return _buildMonthlyView(context);
      case CalendarViewType.weekly:
        return _buildWeeklyView(context);
      case CalendarViewType.daily:
        return _buildDailyView(context);
      case CalendarViewType.list:
        return _buildListView(context);
    }
  }

  Widget _buildMonthlyView(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: TableCalendar(
            firstDay: DateTime(widget.selectedDate.year, widget.selectedDate.month),
            focusedDay: widget.selectedDate,
            calendarFormat: CalendarFormat.month,
            eventLoader: (day, events) => _getEventsForDay(day, events),
            calendarStyle: CalendarStyle(
              markers: _buildEventMarkers(events),
              defaultTextStyle: Theme.of(context).textTheme.bodySmall,
              weekendTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              holidayTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              outsideDaysVisible: true,
              canSelectOutside: true,
              outsideDaysVisibleRange: 1,
              rowHeight: 60,
              headerStyle: const HeaderStyle(
                titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                formatButtonDecoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                leftChevronIcon: Icon(Icons.chevron_left),
                rightChevronIcon: Icon(Icons.chevron_right),
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              // Handle day selection
            },
            onEventSelected: (event, _) {
              widget.onEventTap(event);
            },
          ),
        ),
      ),
    ]
  }

  Widget _buildWeeklyView(BuildContext context) => Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: _buildWeekGrid(context),
        ),
      ],
    );

  Widget _buildDailyView(BuildContext context) => Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: _buildDayTimeline(context),
        ),
      ],
    );

  Widget _buildListView(BuildContext context) => Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: ListView.builder(
            itemCount: widget.events.length,
            itemBuilder: (context, index) {
              final event = widget.events[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: event.priority.color,
                    child: Text(
                      event.startTime.day.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    event.formattedTimeRange,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => _handleEventAction(context, event, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Delete'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: ListTile(
                          leading: Icon(Icons.copy),
                          title: Text('Duplicate'),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => widget.onEventTap(event),
                ),
              ),
            )
            },
          ),
        ),
      ],
    );

  Widget _buildHeader(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatMonth(widget.selectedDate),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _navigateMonth(context, -1),
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: () => _navigateMonth(context, 1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ],
        ],
      ),
    );

  Widget _buildWeekGrid(BuildContext context) {
    final now = DateTime.now();
    final startOfWeek = widget.selectedDate.subtract(Duration(days: widget.selectedDate.weekday - 1));
    final days = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemCount: 7,
      itemBuilder: (context, index) {
        final day = days[index];
        final dayEvents = widget.events.where((event) {
          final eventDate = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
          return eventDate.isSameDay(day);
        }).toList();
        
        return Card(
          margin: const EdgeInsets.all(4),
          child: Column(
            children: [
              Text(
                _formatDay(day),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: dayEvents.length,
                  itemBuilder: (context, index) {
                    final event = dayEvents[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        event.title,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        event.formattedTime,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      onTap: () => widget.onEventTap(event),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayTimeline(BuildContext context) {
    final dayEvents = widget.events.where((event) {
      final eventDate = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
      return eventDate.isSameDay(widget.selectedDate);
    }).toList();

    return ListView.builder(
      itemCount: dayEvents.length,
      itemBuilder: (context, index) {
        final event = dayEvents[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.formattedTime,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: event.priority.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                event.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (event.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  event.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (event.location != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location!,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ],
            ],
            ],
          ),
        );
      },
    );
  }

  String _formatMonth(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}';

  String _formatDay(DateTime date) => '${date.day}';

  List<CalendarEvent> _getEventsForDay(DateTime day, List<CalendarEvent> events) => events.where((event) {
      final eventDate = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
      return eventDate.isSameDay(day);
    }).toList();

  List<CalendarEventMarker> _buildEventMarkers(List<CalendarEvent> events) => events.map((event) => CalendarEventMarker(
        date: event.startTime,
        event: event,
      )).toList();

  void _navigateMonth(BuildContext context, int offset) {
    final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
    final newDate = DateTime(widget.selectedDate.year, widget.selectedDate.month);
    calendarProvider.setDateFilter(newDate);
  }

  void _handleEventAction(BuildContext context, CalendarEvent event, String action) {
    switch (action) {
      case 'edit':
        // TODO: Show edit dialog
        break;
      case 'delete':
        // TODO: Show delete confirmation
        break;
      case 'duplicate':
        // TODO: Duplicate event
        break;
    }
  }
}

class CalendarEventMarker extends CalendarEvent {

  const CalendarEventMarker({
    required super.event,
    required this.color,
  });
  final Color color;
}
