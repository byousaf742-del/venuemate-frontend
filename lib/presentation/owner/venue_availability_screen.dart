import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:venuemate/core/services/api_client.dart';
import 'package:venuemate/theme/app_theme.dart';

class VenueAvailabilityScreen extends StatefulWidget {
  final String venueId;
  final String venueName;

  const VenueAvailabilityScreen({
    super.key,
    required this.venueId,
    required this.venueName,
  });

  @override
  State<VenueAvailabilityScreen> createState() =>
      _VenueAvailabilityScreenState();
}

class _VenueAvailabilityScreenState extends State<VenueAvailabilityScreen> {
  Set<DateTime> _blockedDates = {};
  bool _loading = true;
  bool _saving = false;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadBlockedDates();
  }

  Future<void> _loadBlockedDates() async {
    try {
      final res =
          await ApiClient.get('/venues/${widget.venueId}/blocked-dates');
      final list = (res['blocked_dates'] as List?) ?? [];
      setState(() {
        _blockedDates = list
            .map((d) => DateTime.parse(d.toString()).toLocal())
            .map((d) => DateTime(d.year, d.month, d.day))
            .toSet();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final dates = _blockedDates
          .map((d) =>
              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}')
          .toList();
      await ApiClient.put('/venues/${widget.venueId}/block-dates', {
        'blocked_dates': dates,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability saved!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final day = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    // Don't allow blocking past dates
    if (day.isBefore(DateTime(DateTime.now().year, DateTime.now().month,
        DateTime.now().day))) return;
    setState(() {
      if (_blockedDates.contains(day)) {
        _blockedDates.remove(day);
      } else {
        _blockedDates.add(day);
      }
      _focusedDay = focusedDay;
    });
  }

  bool _isBlocked(DateTime day) {
    return _blockedDates
        .contains(DateTime(day.year, day.month, day.day));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manage Availability',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            Text(widget.venueName,
                style: TextStyle(
                    fontSize: 12, color: AppTheme.onSurfaceMuted)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Legend
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      _legendDot(AppTheme.primary, 'Selected/Blocked'),
                      const SizedBox(width: 20),
                      _legendDot(Colors.grey.shade300, 'Available'),
                      const SizedBox(width: 20),
                      _legendDot(
                          Colors.grey.shade400, 'Past dates'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Calendar
                TableCalendar(
                  firstDay: DateTime.now()
                      .subtract(const Duration(days: 1)),
                  lastDay: DateTime.now()
                      .add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                  },
                  selectedDayPredicate: (day) => _isBlocked(day),
                  onDaySelected: _onDaySelected,
                  onPageChanged: (focusedDay) =>
                      setState(() => _focusedDay = focusedDay),
                  enabledDayPredicate: (day) => !day.isBefore(DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day)),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle:
                        const TextStyle(color: Colors.white),
                    todayDecoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(50),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle:
                        TextStyle(color: AppTheme.primary),
                    disabledTextStyle:
                        TextStyle(color: Colors.grey.shade400),
                    weekendTextStyle:
                        TextStyle(color: AppTheme.onSurface),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.onSurface),
                    leftChevronIcon: Icon(
                        Icons.chevron_left_rounded,
                        color: AppTheme.primary),
                    rightChevronIcon: Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.primary),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                        color: AppTheme.onSurfaceMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                    weekendStyle: TextStyle(
                        color: AppTheme.onSurfaceMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                // Blocked dates list
                if (_blockedDates.isNotEmpty) ...[
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                            'Blocked Dates (${_blockedDates.length})',
                            style: theme.textTheme.titleSmall),
                        const Spacer(),
                        TextButton(
                          onPressed: () =>
                              setState(() => _blockedDates.clear()),
                          child: const Text('Clear All',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20),
                      children: (_blockedDates.toList()
                            ..sort())
                          .map((d) => Container(
                                margin: const EdgeInsets.only(
                                    bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary
                                      .withAlpha(15),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppTheme.primary
                                          .withAlpha(60)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                        Icons
                                            .block_rounded,
                                        size: 16,
                                        color: AppTheme.primary),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${d.day} ${_monthName(d.month)} ${d.year}',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.onSurface,
                                          fontWeight:
                                              FontWeight.w500),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => setState(() =>
                                          _blockedDates.remove(d)),
                                      child: Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                          color:
                                              AppTheme.onSurfaceMuted),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ] else
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 48,
                              color: AppTheme.outlineVariant),
                          const SizedBox(height: 12),
                          Text('No dates blocked',
                              style: TextStyle(
                                  color: AppTheme.onSurfaceMuted,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('Tap dates on the calendar to block them',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.onSurfaceMuted)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: AppTheme.onSurfaceMuted)),
      ],
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
