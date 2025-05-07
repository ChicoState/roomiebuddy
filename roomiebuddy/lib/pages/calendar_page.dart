import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';
import 'package:roomiebuddy/services/auth_storage.dart';
import 'package:roomiebuddy/services/api_service.dart';
import 'package:roomiebuddy/common/widget/task/task_list_widget.dart';
import 'package:roomiebuddy/utils/data_transformer.dart';
import 'dart:async';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now(); // Tracks day user has selected
  DateTime _focusedDay = DateTime.now(); // Tracks month period in view
  final DateTime _firstDay = DateTime.utc(2020, 1, 1);
  final DateTime _lastDay = DateTime.utc(2030, 12, 31);

  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  bool _showOnlyMyTasks = true;

  static const double _cellMargin = 2.0;
  static const double _cellPadding = 4.0;
  static const double _borderRadius = 8.0;
  static const double _fontSize = 14.0;
  
  bool _isTaskLoading = true;
  List<Map<String, dynamic>> _roommateGroups = [];
  String? _userId;
  String? _password;

  final AuthStorage _authStorage = AuthStorage();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadUserDataAndGroups();
  }

  // ------------ Main Build Method ------------  //
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Task Calendar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeProvider.currentTextColor,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCalendar(),
            const SizedBox(height: 20),
            Row( 
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected Day: ${_formatSelectedDate()}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeProvider.currentTextColor),
                ),
                Tooltip(
                   message: _showOnlyMyTasks ? 'Show all tasks' : 'Show only my tasks',
                   child: IconButton(
                     icon: Icon(
                       _showOnlyMyTasks ? Icons.person : Icons.group,
                       color: themeProvider.currentTextColor,
                     ),
                     onPressed: () {
                       setState(() {
                         _showOnlyMyTasks = !_showOnlyMyTasks;
                       });
                     },
                   ),
                 ),
              ],
            ),
            _buildEventsList(themeProvider),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ------------ Backend Communication Methods ------------ //
  Future<void> _loadUserDataAndGroups() async {
    _userId = await _authStorage.getUserId();
    _password = await _authStorage.getPassword();

    if (_userId != null && _password != null) {
      try {
        final response = await _apiService.getGroupList(_userId!, _password!);
        if (mounted) {
          if (response['success']) {
            final groupsMap = response['data']?['groups'] as Map<String, dynamic>? ?? {};
            setState(() {
              _roommateGroups = groupsMap.values.map((rawGroup) {
                 final group = Map<String, dynamic>.from(rawGroup as Map);
                  final List<dynamic> membersData = group['members'] ?? [];
                  final List<Map<String, dynamic>> processedMembers = membersData.map((member) {
                    if (member is Map<String, dynamic>) {
                      return member;
                    } else if (member is Map) {
                      return Map<String, dynamic>.from(member);
                    } else {
                      return {'user_id': 'unknown', 'username': 'Invalid Member Data'};
                    }
                  }).toList();
                  return {
                    ...group,
                    'members': processedMembers,
                    'group_name': group['name'] ?? 'Unnamed Group'
                  };
              }).toList();
            });
            // After loading groups, load all tasks
            await _loadAllTasks();
          } else {
            setState(() => _isTaskLoading = false); // Stop loading if group fetch fails
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load groups: ${response['message']}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isTaskLoading = false); // Stop loading on error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading groups: $e')),
          );
        }
      }
    } else {
       if (mounted) {
         setState(() => _isTaskLoading = false); // Stop loading if not logged in
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to view tasks.')),
          );
       }
    }
  }

  Future<void> _loadAllTasks() async {
    if (!mounted || _userId == null || _password == null || _roommateGroups.isEmpty) {
      setState(() => _isTaskLoading = false); // Stop loading if prerequisites aren't met
      return;
    }

    setState(() {
      _isTaskLoading = true; // Start loading tasks
      _events = {}; // Clear previous events
    });

    try {
      List<Future<Map<String, dynamic>>> taskFutures = [];
      for (var group in _roommateGroups) {
        final groupId = group['group_id'];
        if (groupId != null) {
          taskFutures.add(_apiService.getGroupTasks(_userId!, groupId, _password!));
        }
      }

      final List<Map<String, dynamic>> responses = await Future.wait(taskFutures);
      final List<Map<String, dynamic>> allTasks = [];
      final Set<String> addedTaskIds = {}; // To handle potential duplicates if API returns same task for multiple group calls

      for (var response in responses) {
        if (response['success']) {
          final Map<String, dynamic>? tasksData = response['data'] as Map<String, dynamic>?;
          if (tasksData != null && tasksData.containsKey('tasks')) {
            final tasksMap = tasksData['tasks'] as Map<String, dynamic>;
            tasksMap.forEach((taskId, taskDataRaw) {
              if (!addedTaskIds.contains(taskId)) {
                 final taskData = taskDataRaw as Map<String, dynamic>;
                 // Process task data
                 final double? dueTimestamp = taskData['due_timestamp'] as double?;
                 DateTime? dueDateObject;
                 String? dueDateStr;
                 String? dueTimeStr;
                 if (dueTimestamp != null) {
                   final dateTime = DateTime.fromMillisecondsSinceEpoch((dueTimestamp * 1000).toInt());
                   dueDateObject = dateTime;
                   const monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
                   dueDateStr = "${monthNames[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}";
                   int hour = dateTime.hour;
                   final int minute = dateTime.minute;
                   final String period = hour < 12 ? 'AM' : 'PM';
                   if (hour == 0) { hour = 12; } else if (hour > 12) { hour -= 12; }
                   dueTimeStr = "$hour:${minute.toString().padLeft(2, '0')} $period";
                   final defaultDateCheck = "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
                   final defaultTimeCheck = "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
                   if (defaultDateCheck == '2000-01-01' && defaultTimeCheck == '00:00') {
                     dueDateStr = null; dueTimeStr = null;
                   }
                 }
                 final int priorityInt = taskData['priority'] as int? ?? 0;
                 final String priorityStr = priorityToString(priorityInt);
                 final int estDay = taskData['est_day'] as int? ?? 0;
                 final int estHour = taskData['est_hour'] as int? ?? 0;
                 final int estMin = taskData['est_min'] as int? ?? 0;
                 List<String> durationParts = [];
                 if (estDay > 0) durationParts.add('$estDay day${estDay > 1 ? 's' : ''}');
                 if (estHour > 0) durationParts.add('$estHour hour${estHour > 1 ? 's' : ''}');
                 if (estMin > 0) durationParts.add('$estMin min${estMin > 1 ? 's' : ''}');
                 String estimatedDuration = durationParts.join(' ');
                 if (estimatedDuration.isEmpty) estimatedDuration = 'Not specified';
                 final int recurrenceInt = taskData['recursive'] as int? ?? 0;
                 String recurrence = 'Does not repeat';
                 switch (recurrenceInt) {
                   case 1: recurrence = 'Repeats Daily'; break;
                   case 7: recurrence = 'Repeats Weekly'; break;
                   case 30: recurrence = 'Repeats Monthly'; break;
                 }

                 allTasks.add({
                   "id": taskId,
                   "taskName": taskData["name"] ?? "No Task Name",
                   "assignedBy": taskData["assigner_username"] ?? taskData["assigner_id"] ?? "Unknown",
                   "assignedTo": taskData["assignee_username"] ?? taskData["assign_id"] ?? "Unknown",
                   "priority": priorityStr,
                   "description": taskData["description"] ?? "",
                   "dueDate": dueDateStr,
                   "dueTime": dueTimeStr,
                   "dueDateObject": dueDateObject,
                   "estimatedDuration": estimatedDuration,
                   "recurrence": recurrence,
                   "photo": taskData["image_path"],
                   "assignee_id": taskData["assign_id"],
                   "group_id": taskData["group_id"],
                   "completed": taskData["completed"] as bool? ?? false,
                 });
                addedTaskIds.add(taskId);
              }
            });
          }
        } else {
          // Handle individual task fetch failure (optional: show a message)
           debugPrint('Failed to load tasks for a group: ${response['message']}');
        }
      }
       if (mounted) {
          setState(() {
            // Populate the events map
            _events = {};
            for (var task in allTasks) {
              if (task['dueDateObject'] != null) {
                final date = task['dueDateObject'] as DateTime;
                final dayOnly = DateTime.utc(date.year, date.month, date.day);
                if (_events[dayOnly] == null) {
                  _events[dayOnly] = [];
                }
                _events[dayOnly]!.add(task);
              }
            }
          });
       }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching tasks: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTaskLoading = false; // Loading finished
        });
      }
    }
  }

  // ------------ Calendar Builder Methods ------------  //
  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: _firstDay,
      lastDay: _lastDay,
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      eventLoader: _getEventsForDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: _onDaySelected,
      onFormatChanged: _onFormatChanged,
      onPageChanged: (focusedDay) => _focusedDay = focusedDay,
      headerStyle: _buildHeaderStyle(),
      calendarStyle: _buildCalendarStyle(),
      calendarBuilders: _buildCalendarBuilders(),
    );
  }
  
  // ------------ Calendar Event Handlers ------------  //
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

  // ------------ Calendar Style Config ------------  //
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
      markersAlignment: Alignment.bottomRight,
      markerDecoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
        shape: BoxShape.circle,
      ),
      markersMaxCount: 1,
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

  // ------------ Day Cell Builders ------------  //
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
        border: Border.all(color: themeProvider.currentBorderColor.withAlpha(77), width: 0.5),
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

  // ------------ Helper Methods ------------  //
  String _formatSelectedDate() {
    return '${_selectedDay.month}-${_selectedDay.day}-${_selectedDay.year}'; // "MM-DD-YYYY" formatting
  }
  
  // Helper to get events for a specific day (normalized)
  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    final dayEvents = _events[normalizedDay] ?? [];

    // Filter events based on _showOnlyMyTasks
    if (_showOnlyMyTasks && _userId != null) {
      return dayEvents.where((task) => task['assignee_id'] == _userId).toList();
    } else {
      return dayEvents;
    }
  }

  // ------------ Event List Widgets ------------  //
  Widget _buildEventsList(ThemeProvider themeProvider) {
    final Set<String> userGroupIds = _roommateGroups
        .map((group) => group['group_id'])
        .where((id) => id != null)
        .cast<String>()
        .toSet();

    final tasksForSelectedDay = _getEventsForDay(_selectedDay);

    return Expanded(
      child: _isTaskLoading
          ? const Center(child: CircularProgressIndicator())
          : TaskListWidget(
              allTasks: tasksForSelectedDay,
              focusedGroupId: null,
              userGroupIds: userGroupIds,
              roommateGroups: _roommateGroups,
              onTaskActionCompleted: _loadAllTasks,
              showOnlyMyTasks: _showOnlyMyTasks,
              currentUserId: _userId,
            ),
    );
  }
}
