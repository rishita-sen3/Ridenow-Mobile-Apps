import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../core/providers.dart';
import '../models/booking.dart';
import '../core/constants.dart';
import '../widgets/app_drawer.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<Booking> _getEventsForDay(List<Booking> allBookings, DateTime day) {
    return allBookings.where((booking) {
      DateTime start = DateTime.parse(booking.startDatetime);
      DateTime end = booking.endDatetime != null ? DateTime.parse(booking.endDatetime!) : start;
      
      // Normalize dates to ignore time for comparison
      DateTime normDay = DateTime(day.year, day.month, day.day);
      DateTime normStart = DateTime(start.year, start.month, start.day);
      DateTime normEnd = DateTime(end.year, end.month, end.day);
      
      return (normDay.isAtSameMomentAs(normStart) || normDay.isAtSameMomentAs(normEnd)) ||
             (normDay.isAfter(normStart) && normDay.isBefore(normEnd));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider(const {}));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      drawer: const AppDrawer(),
      body: bookingsAsync.when(
        data: (bookings) {
          final selectedEvents = _getEventsForDay(bookings, _selectedDay!);

          return Column(
            children: [
              TableCalendar<Booking>(
                firstDay: DateTime.utc(2020, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                eventLoader: (day) => _getEventsForDay(bookings, day),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return const SizedBox();
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${events.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: selectedEvents.isEmpty
                    ? const Center(child: Text('No bookings for this day.'))
                    : ListView.builder(
                        itemCount: selectedEvents.length,
                        itemBuilder: (context, index) {
                          final booking = selectedEvents[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: const Icon(Icons.directions_car),
                              title: Text(booking.vehicleName ?? 'Unknown Vehicle'),
                              subtitle: Text('Customer: ${booking.customerName}'),
                              trailing: Text(booking.status, style: TextStyle(fontWeight: FontWeight.bold, color: booking.status == 'completed' ? Colors.green : Colors.orange)),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
