import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import '../common/widget/appbar/appbar.dart';
import '../providers/theme_provider.dart';
import 'package:roomiebuddy/services/auth_storage.dart';
import 'package:roomiebuddy/services/api_service.dart';
import 'subpages/home/group_detail_page.dart';
import '../common/widget/search/task_search_delegate.dart';
import '../common/widget/task/task_list_widget.dart';
import '../utils/data_transformer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  bool _isTaskLoading = false;
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _roommateGroups = [];
  int _currentGroupIndex = 0;
  bool _showOnlyMyTasks = true;

  final AuthStorage _authStorage = AuthStorage();
  final ApiService _apiService = ApiService();

  String? _userId;
  String? _password;
  String _userName = "Unknown";

  @override
  void initState() {
    super.initState();
    _loadUserDataAndGroups();
  }

  // --- Backend Communication Functions --- //

  Future<void> _loadUserDataAndGroups() async {

    _userId = await _authStorage.getUserId();
    _password = await _authStorage.getPassword();
    _userName = await _authStorage.getUsername() ?? "User";

    if (_userId != null && _password != null) {
      try {
        // Load groups first
        await _loadGroups(_userId!, _password!);
        // After loading groups, load tasks for the initial group (if any)
        if (_roommateGroups.isNotEmpty) {
          final initialGroupId = _roommateGroups[_currentGroupIndex]['group_id'] ?? _roommateGroups[_currentGroupIndex]['uuid'] ?? _roommateGroups[_currentGroupIndex]['id'];
          if (initialGroupId != null) {
            await _loadTasksForGroup(initialGroupId); // Load tasks for the first group
          } else {
            // Handle case where the initial group has no ID? Set tasks empty?
            if (mounted) setState(() => _tasks = []);
          }
        } else {
          // No groups, so no group tasks to load
          if (mounted) setState(() => _tasks = []);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading initial data: $e')),
          );
          setState(() => _tasks = []); // Clear tasks on error
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to view tasks.')),
        );
        setState(() {
          _tasks = []; // Clear tasks if not logged in
        });
      }
    }
  }

  Future<void> _loadGroups(String userId, String password) async {
    try {
      final response = await _apiService.getGroupList(userId, password);
      if (response['success']) {
        final groupsMap = response['data']?['groups'] as Map<String, dynamic>? ?? {};
        if (mounted) {
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
            // Reset index if it's out of bounds after refresh
            if (_currentGroupIndex >= _roommateGroups.length) {
              _currentGroupIndex = _roommateGroups.isEmpty ? 0 : _roommateGroups.length - 1;
            }
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load groups: ${response['message']}')),
          );
          setState(() => _roommateGroups = []); // Clear groups on failure
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading groups: $e')),
        );
        setState(() => _roommateGroups = []); // Clear groups on error
      }
    }
  }

  Future<void> _loadTasksForGroup(String groupId) async {
    if (!mounted || _userId == null || _password == null) return;

    setState(() {
      _isTaskLoading = true; // Use the task-specific loading flag
    });

    try {
      // Use ApiService to get tasks for the specified group
      final response = await _apiService.getGroupTasks(_userId!, groupId, _password!);

      if (response['success']) {
        final Map<String, dynamic>? tasksData = response['data'] as Map<String, dynamic>?;

        if (tasksData != null && tasksData.containsKey('tasks')) {
          final tasksMap = tasksData['tasks'] as Map<String, dynamic>;

          if (mounted) {
            setState(() {
              _tasks = tasksMap.entries.map((entry) {
                final taskId = entry.key;
                final taskData = entry.value as Map<String, dynamic>;

                final double? dueTimestamp = taskData['due_timestamp'] as double?;
                String? dueDateStr;
                String? dueTimeStr;
                if (dueTimestamp != null) {
                  final dateTime = DateTime.fromMillisecondsSinceEpoch((dueTimestamp * 1000).toInt());
                  
                  // Format Date: Month DD, YYYY
                  const monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
                  dueDateStr = "${monthNames[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}";
                  
                  // Format Time: H:MM AM/PM
                  int hour = dateTime.hour;
                  final int minute = dateTime.minute;
                  final String period = hour < 12 ? 'AM' : 'PM';
                  if (hour == 0) {
                    hour = 12; // Midnight
                  } else if (hour > 12) {
                    hour -= 12; // Convert to 12-hour format
                  }
                  dueTimeStr = "$hour:${minute.toString().padLeft(2, '0')} $period";

                  // Check for default date/time from backend (using original YYYY-MM-DD format for check)
                  final defaultDateCheck = "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
                  final defaultTimeCheck = "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
                  if (defaultDateCheck == '2000-01-01' && defaultTimeCheck == '00:00') {
                    dueDateStr = null; // Treat as unspecified
                    dueTimeStr = null;
                  }
                }

                final int priorityInt = taskData['priority'] as int? ?? 0;
                final String priorityStr = priorityToString(priorityInt);

                // Process estimated duration
                final int estDay = taskData['est_day'] as int? ?? 0;
                final int estHour = taskData['est_hour'] as int? ?? 0;
                final int estMin = taskData['est_min'] as int? ?? 0;
                List<String> durationParts = [];
                if (estDay > 0) durationParts.add('$estDay day${estDay > 1 ? 's' : ''}');
                if (estHour > 0) durationParts.add('$estHour hour${estHour > 1 ? 's' : ''}');
                if (estMin > 0) durationParts.add('$estMin min${estMin > 1 ? 's' : ''}');
                String estimatedDuration = durationParts.join(' ');
                if (estimatedDuration.isEmpty) {
                  estimatedDuration = 'Not specified';
                }

                // Process recurrence
                final int recurrenceInt = taskData['recursive'] as int? ?? 0;
                String recurrence = 'Does not repeat';
                switch (recurrenceInt) {
                  case 1: recurrence = 'Repeats Daily'; break;
                  case 7: recurrence = 'Repeats Weekly'; break;
                  case 30: recurrence = 'Repeats Monthly'; break;
                  // Add other cases if needed
                }

                return {
                  "id": taskId,
                  "taskName": taskData["name"] ?? "No Task Name",
                  "assignedBy": taskData["assigner_username"] ?? taskData["assigner_id"] ?? "Unknown",
                  "assignedTo": taskData["assignee_username"] ?? taskData["assign_id"] ?? "Unknown",
                  "priority": priorityStr,
                  "description": taskData["description"] ?? "",
                  "dueDate": dueDateStr,
                  "dueTime": dueTimeStr,
                  "estimatedDuration": estimatedDuration,
                  "recurrence": recurrence,
                  "photo": taskData["image_path"],
                  "assignee_id": taskData["assign_id"],
                  "group_id": taskData["group_id"],
                  "completed": taskData["completed"] as bool? ?? false,
                };
              }).toList();
            });
          }
        } else {
          if (mounted) {
            setState(() => _tasks = []); // Clear tasks if format is invalid
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to load tasks for group: Invalid data format.')),
            );
          }
        }
      } else {
        if (mounted) {
          setState(() => _tasks = []); // Clear tasks on failure
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load tasks for group: ${response['message']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _tasks = []); // Clear tasks on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching tasks for group: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTaskLoading = false; // Loading finished for this group's tasks
        });
      }
    }
  }

  // --- Helper Functions --- //

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 18) return "Good Afternoon";
    return "Good Evening";
  }

  // --- Build Widgets --- //

  @override
  Widget build(BuildContext context) {
    String userName = _userName;
    // String? profileImagePath;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      // -------------------- AppBar -------------------- //
      appBar: TAppBar(
        title: Row(
          // Profile Image
          children: [
            // COMMENTED OUT UNTIL WE GET PROFILE PIC WORKING (The warning was bothering me)
            // if (profileImagePath != null)
            //   Container(
            //     width: 40,
            //     height: 40,
            //     decoration: BoxDecoration(
            //       shape: BoxShape.circle,
            //       border: Border.all(color: Colors.grey, width: 2),
            //     ),
            //     child: ClipOval(
            //       child: Image.asset(
            //         profileImagePath,
            //         fit: BoxFit.cover,
            //         errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 30, color: Colors.grey),
            //       ),
            //     ),
            //   )
            // else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey, width: 2),
                ),
                child: const Icon(Icons.person, size: 30, color: Colors.grey),
              ),
            const SizedBox(width: 10),
            // Greeting
            Text(
              "${_getGreeting()}, $userName",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          // Search Button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: TaskSearchDelegate(tasks: _tasks),
              );
            },
          ),
        ],
      ),
      // -------------------- Body -------------------- //
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Roommate Groups title
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 12.0),
              child: Text(
                'Groups',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.currentTextColor,
                ),
              ),
            ),
            // Roommate Groups carousel
            Container(
              color: themeProvider.themeColor,
              height: 180,
              child: _roommateGroups.isEmpty
                  ? Center(
                      child: Text(
                        'No groups found.',
                        style: TextStyle(color: themeProvider.currentSecondaryTextColor),
                      ),
                    )
                  : _buildGroupCarousel(),
            ),

            // -------------------- Leaderboard Section -------------------- //
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Text(
                'Leaderboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.currentTextColor,
                ),
              ),
            ),
            const SizedBox(height: 50),
            
            // -------------------- Task Section -------------------- //
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dynamic title
                  Text(
                    _showOnlyMyTasks ? 'My Tasks' : 'All Tasks',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.currentTextColor,
                    ),
                  ),
                  // Dynamic icon
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
            ),
            
            // Tasks List (in task_list_widget.dart)
            _isTaskLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildTaskList(),
                  ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    // Get the ID of the group currently in focus
    String? currentFocusedGroupId;
    if (_roommateGroups.isNotEmpty && _currentGroupIndex < _roommateGroups.length) {
      currentFocusedGroupId = _roommateGroups[_currentGroupIndex]['group_id'];
    }

    // Get all group IDs the user is in
    final Set<String> userGroupIds = _roommateGroups
        .map((group) => group['group_id']) // iterate through all groups
        .where((id) => id != null) // filter out null IDs
        .cast<String>() // cast to String
        .toSet(); // convert to a set

    // --- Task List Widget --- //
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 300, // min height (CHANGE THIS TO MAKE DYNAMIC)
        maxHeight: 300, // max height
      ),
      child: TaskListWidget(
        allTasks: _tasks,
        focusedGroupId: currentFocusedGroupId,
        userGroupIds: userGroupIds,
        roommateGroups: _roommateGroups,
        onTaskActionCompleted: () {
          if (currentFocusedGroupId != null) {
            _loadTasksForGroup(currentFocusedGroupId);
          } else {
            // Reload groups and then tasks if group ID is missing
            _loadUserDataAndGroups();
          }
        },
        showOnlyMyTasks: _showOnlyMyTasks,
        currentUserId: _userId,
      ),
    );
  }

  Widget _buildGroupCarousel() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // No groups to display
    if (_roommateGroups.isEmpty) {
      return const Center(child: Text('No groups to display.'));
    }

    // --- Group Carousel --- //
    return SizedBox(
      height: 140,
      child: CarouselSlider(
        options: CarouselOptions(
          height: 140.0,
          enlargeCenterPage: true,
          autoPlay: false,
          viewportFraction: 0.85,
          initialPage: _currentGroupIndex,
          onPageChanged: (index, reason) {
            setState(() {
              _currentGroupIndex = index;
            });
            // Load tasks for the newly focused group
            if (_roommateGroups.isNotEmpty && index < _roommateGroups.length) {
              final newGroupId = _roommateGroups[index]['group_id'];
              if (newGroupId != null) {
                _loadTasksForGroup(newGroupId);
              }
            }
          },
        ),
        items: _roommateGroups.map((group) {
          return Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () async {
                  // Determine if this is the last group before navigating
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupDetailScreen(
                        group: group,
                      ),
                    ),
                  );
                  
                  // If left group (result is true), refresh the groups list and initial tasks
                  if (result == true && mounted) {
                    _loadUserDataAndGroups(); // Reload groups and tasks for index 0
                  }
                  // If a task within the group was updated, refresh tasks for the *current* group
                  else if (result == 'task_updated' && mounted) {
                     final currentGroupId = _roommateGroups[_currentGroupIndex]['group_id'];
                     if (currentGroupId != null) {
                       _loadTasksForGroup(currentGroupId);
                     }
                  }
                },
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.currentCardBackground,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: themeProvider.themeColor),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        group['group_name'] ?? 'Unnamed Group',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.currentTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
