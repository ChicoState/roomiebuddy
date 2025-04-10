import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  // CALENDAR PROPERTIES
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now(); // Tracks day user has selected
  DateTime _focusedDay = DateTime.now(); // Tracks month period in view
  final DateTime _firstDay = DateTime.utc(2020, 1, 1);
  final DateTime _lastDay = DateTime.utc(2030, 12, 31);

  // STYLE CONSTANTS
  static const double _cellMargin = 2.0;
  static const double _cellPadding = 4.0;
  static const double _borderRadius = 8.0;
  static const double _fontSize = 14.0;
  
  // MAIN BUILD METHOD
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Calendar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCalendar(),
            const SizedBox(height: 20),
            Text(
              'Selected Day: ${_formatSelectedDate()}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildEventsList(themeProvider),
          ],
        ),
      ),
    );
  }

  // CALENDAR BUILDER METHODS
  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: _firstDay,
      lastDay: _lastDay,
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: _onDaySelected,
      onFormatChanged: _onFormatChanged,
      onPageChanged: (focusedDay) => _focusedDay = focusedDay,
      headerStyle: _buildHeaderStyle(),
      calendarStyle: _buildCalendarStyle(),
      calendarBuilders: _buildCalendarBuilders(),
    );
  }
  
  // CALENDAR EVENT HANDLERS
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  // CALENDAR STYLE CONFIG
  HeaderStyle _buildHeaderStyle() {
    return const HeaderStyle(
      formatButtonVisible: true,
      titleCentered: true,
      formatButtonShowsNext: false,
    );
  }

  CalendarStyle _buildCalendarStyle() {
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
    );
  }

  CalendarBuilders _buildCalendarBuilders() {
    return CalendarBuilders(
      defaultBuilder: _defaultDayBuilder,
      selectedBuilder: _selectedDayBuilder,
      todayBuilder: _todayBuilder,
      outsideBuilder: _outsideDayBuilder,
    );
  }

  // DAY CELL BUILDERS
  Widget _defaultDayBuilder(BuildContext context, DateTime day, DateTime focusedDay) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return _buildBaseDayContainer(
      day,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(_borderRadius)),
        border: Border.all(color: themeProvider.currentBorderColor, width: 0.5),
      ),
      textStyle: TextStyle(fontSize: _fontSize, color: themeProvider.calendarDefaultTextColor),
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

  // HELPER METHODS
  String _formatSelectedDate() {
    return '${_selectedDay.month}-${_selectedDay.day}-${_selectedDay.year}'; // "MM-DD-YYYY" formatting
  }
  
  // EVENT LIST WIDGETS
  Widget _buildEventsList(ThemeProvider themeProvider) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: themeProvider.currentInputFill,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Text(
            'No events for this day',
            style: TextStyle(
              color: themeProvider.currentSecondaryTextColor,
            ),
          ),
        ),
      ),
    );
  }
}
