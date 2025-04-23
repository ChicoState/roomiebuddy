import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class CalendarWidget extends StatelessWidget {
  // Calendar properties passed from parent
  final DateTime firstDay;
  final DateTime lastDay;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final CalendarFormat calendarFormat;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(CalendarFormat) onFormatChanged;
  final Function(DateTime) onPageChanged;
  final List<Map<String, dynamic>> Function(DateTime) eventLoader;

  // Style constants
  static const double _cellMargin = 2.0;
  static const double _cellPadding = 4.0;
  static const double _borderRadius = 8.0;
  static const double _fontSize = 14.0;

  const CalendarWidget({
    super.key,
    required this.firstDay,
    required this.lastDay,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
    required this.eventLoader,
  });

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: firstDay,
      lastDay: lastDay,
      focusedDay: focusedDay,
      calendarFormat: calendarFormat,
      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
      onDaySelected: onDaySelected,
      onFormatChanged: onFormatChanged,
      onPageChanged: onPageChanged,
      headerStyle: _buildHeaderStyle(),
      calendarStyle: _buildCalendarStyle(context),
      calendarBuilders: _buildCalendarBuilders(context),
      eventLoader: eventLoader,
    );
  }

  // CALENDAR STYLE CONFIG
  HeaderStyle _buildHeaderStyle() {
    return const HeaderStyle(
      formatButtonVisible: true,
      titleCentered: true,
      formatButtonShowsNext: false,
    );
  }

  CalendarStyle _buildCalendarStyle(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return CalendarStyle(
      outsideDaysVisible: false,
      weekendTextStyle: TextStyle(color: themeProvider.calendarWeekendTextColor),
      selectedDecoration: BoxDecoration(
        color: themeProvider.calendarSelectedDayColor,
        shape: BoxShape.rectangle,
        borderRadius: const BorderRadius.all(Radius.circular(_borderRadius)),
      ),
      todayDecoration: BoxDecoration(
        color: themeProvider.calendarTodayColor,
        shape: BoxShape.rectangle,
        borderRadius: const BorderRadius.all(Radius.circular(_borderRadius)),
      ),
      defaultDecoration: const BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.all(Radius.circular(_borderRadius)),
      ),
      cellMargin: const EdgeInsets.all(_cellMargin),
      cellAlignment: Alignment.topLeft,
      markersMaxCount: 3,
      markersAnchor: 0.7,
    );
  }

  CalendarBuilders _buildCalendarBuilders(BuildContext context) {
    return CalendarBuilders(
      defaultBuilder: (context, day, focusedDay) => _defaultDayBuilder(context, day, focusedDay),
      selectedBuilder: (context, day, focusedDay) => _selectedDayBuilder(context, day, focusedDay),
      todayBuilder: (context, day, focusedDay) => _todayBuilder(context, day, focusedDay),
      outsideBuilder: (context, day, focusedDay) => _outsideDayBuilder(context, day, focusedDay),
      markerBuilder: (context, day, events) => _eventMarkerBuilder(context, day, events),
    );
  }

  // EVENT MARKER BUILDER
  Widget? _eventMarkerBuilder(BuildContext context, DateTime day, List<dynamic> events) {
    if (events.isNotEmpty) {
      final themeProvider = Provider.of<ThemeProvider>(context);
      return Positioned(
        bottom: 1,
        right: 1,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: themeProvider.themeColor,
          ),
        ),
      );
    }
    return null;
  }

  // DAY CELL BUILDERS
  Widget _defaultDayBuilder(BuildContext context, DateTime day, DateTime focusedDay) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final events = eventLoader(day);
    final hasEvents = events.isNotEmpty;
    
    return _buildBaseDayContainer(
      day,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(_borderRadius)),
        border: Border.all(
          color: hasEvents 
            ? themeProvider.themeColor.withOpacity(0.5) 
            : themeProvider.currentBorderColor, 
          width: hasEvents ? 1.0 : 0.5
        ),
      ),
      textStyle: TextStyle(
        fontSize: _fontSize, 
        color: themeProvider.calendarDefaultTextColor,
        fontWeight: hasEvents ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _selectedDayBuilder(BuildContext context, DateTime day, DateTime focusedDay) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return _buildBaseDayContainer(
      day,
      decoration: BoxDecoration(
        color: themeProvider.calendarSelectedDayColor,
        shape: BoxShape.rectangle,
        borderRadius: const BorderRadius.all(Radius.circular(_borderRadius)),
      ),
      textStyle: TextStyle(
        fontSize: _fontSize,
        color: themeProvider.calendarSelectedDayTextColor,
      ),
    );
  }

  Widget _todayBuilder(BuildContext context, DateTime day, DateTime focusedDay) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return _buildBaseDayContainer(
      day,
      decoration: BoxDecoration(
        color: themeProvider.calendarTodayColor,
        shape: BoxShape.rectangle,
        borderRadius: const BorderRadius.all(Radius.circular(_borderRadius)),
      ),
      textStyle: TextStyle(
        fontSize: _fontSize,
        color: themeProvider.calendarSelectedDayTextColor,
      ),
    );
  }

  Widget _outsideDayBuilder(BuildContext context, DateTime day, DateTime focusedDay) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return _buildBaseDayContainer(
      day,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(_borderRadius)),
        border: Border.all(color: themeProvider.currentBorderColor.withOpacity(0.3), width: 0.5),
      ),
      textStyle: TextStyle(
        fontSize: _fontSize,
        color: themeProvider.currentSecondaryTextColor,
      ),
    );
  }

  Widget _buildBaseDayContainer(DateTime day, {
    required BoxDecoration decoration,
    required TextStyle textStyle,
  }) {
    return Container(
      margin: const EdgeInsets.all(_cellMargin),
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.only(left: _cellPadding, top: _cellPadding),
      decoration: decoration,
      child: Text(
        '${day.day}',
        style: textStyle,
      ),
    );
  }
} 