import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';
import '../common/widget/task_list.dart';
import '../common/widget/calendar_widget.dart';
import '../common/utils/date_parser.dart';
import '../services/user_service.dart';
import '../common/utils/data_operations.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  // Calendar properties
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  final DateTime _firstDay = DateTime.utc(2020, 1, 1);
  final DateTime _lastDay = DateTime.utc(2030, 12, 31);

  // Task data
  bool _isLoading = false;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  List<Map<String, dynamic>> _selectedEvents = [];
  
  // Group data
  List<Map<String, dynamic>> _roomateGroups = [];
  
  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    // Initialize UserService first
    await UserService.initialize();
    
    // Load groups first
    await _loadGroups();
    
    // Then fetch tasks
    await fetchTasks();
  }
  
  // Load roommate groups for providing group names to tasks
  Future<void> _loadGroups() async {
    try {
      final groups = await DataOperations.loadUserGroups();
      setState(() => _roomateGroups = groups);
    } catch (e) {
      debugPrint('Calendar: Error loading groups: $e');
      setState(() => _roomateGroups = []);
    }
  }

  // Fetches tasks from the backend using DataOperations
  Future<void> fetchTasks() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint("Calendar: Fetching tasks...");
      
      // Skip if not logged in
      if (!UserService.isLoggedIn) {
        setState(() {
          _events = {};
          _selectedEvents = [];
          _isLoading = false;
        });
        return;
      }
      
      final result = await DataOperations.fetchTasks(
        category: 'All',
        organizeByDate: true,
      );

      if (result['success']) {
        debugPrint("Calendar: Tasks fetched successfully with ${(result['data'] as Map?)?.length ?? 0} date entries");
        
        // Get the events map
        final rawEvents = Map<DateTime, List<Map<String, dynamic>>>.from(result['data'] ?? {});
        final processedEvents = <DateTime, List<Map<String, dynamic>>>{};
        
        // Process each date's tasks to include group names
        rawEvents.forEach((date, tasks) {
          final processdTasks = tasks.map((task) {
            // Add group name from our known groups
            final groupId = task['groupId'];
            if (groupId != null && groupId.isNotEmpty && groupId != "0") {
              // Find matching group in our _roomateGroups
              final matchingGroup = _roomateGroups.firstWhere(
                (group) => group['groupId'] == groupId,
                orElse: () => {'groupName': ''},
              );
              
              // Set the group name
              task['groupName'] = matchingGroup['groupName'] ?? '';
            }
            return task;
          }).toList();
          
          processedEvents[date] = processdTasks;
        });
        
        setState(() {
          _events = processedEvents;
          _selectedEvents = _getEventsForDay(_selectedDay);
        });
      } else {
        debugPrint("Calendar: Error fetching tasks: ${result['message']}");
      }
    } catch (e) {
      debugPrint('Calendar: Error fetching tasks: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final normalizedDay = DateParser.normalizeDate(day);
    return _events[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedEvents = _getEventsForDay(selectedDay);
    });
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }
  
  // Deletes a task from the backend and refreshes the calendar
  Future<void> deleteTask(String taskId) async {
    try {
      final result = await DataOperations.deleteTask(taskId);
      
      if (result['success']) {
        // Refresh the tasks data
        await fetchTasks();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task deleted successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint('Error deleting task: ${result['message']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting task: ${result['message']}'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting task: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Main build method
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Task Calendar',
          style: TextStyle(
            color: themeProvider.isDarkMode ? themeProvider.darkTextColor : themeProvider.lightTextColor
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CalendarWidget(
              firstDay: _firstDay,
              lastDay: _lastDay,
              focusedDay: _focusedDay,
              selectedDay: _selectedDay,
              calendarFormat: _calendarFormat,
              onDaySelected: _onDaySelected,
              onFormatChanged: _onFormatChanged,
              onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
              eventLoader: _getEventsForDay,
            ),
            const SizedBox(height: 20),
            Text(
              'Tasks for ${DateParser.formatDate(_selectedDay)}',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                color: themeProvider.currentTextColor,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _selectedEvents.isEmpty 
                ? Center(
                    child: Text(
                      'No tasks for this day',
                      style: TextStyle(
                        fontSize: 16,
                        color: themeProvider.currentSecondaryTextColor,
                      ),
                    ),
                  )
                : TaskList(
                    tasks: _selectedEvents,
                    isLoading: false,
                    enableDelete: true, // Enable delete functionality on calendar
                    onDeleteTask: deleteTask, // Pass the delete function
                    onRefresh: () => fetchTasks(), // Add refresh functionality
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
