import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import '../common/widget/appbar/appbar.dart';
import '../providers/theme_provider.dart';
import 'package:roomiebuddy/services/auth_storage.dart';
import 'package:roomiebuddy/services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _roommateGroups = [];

  final AuthStorage _authStorage = AuthStorage();
  final ApiService _apiService = ApiService();
  String? _userId;
  String? _password;
  String _userName = "User";

  @override
  void initState() {
    super.initState();
    _loadUserDataAndTasks();
  }

  Future<void> _loadUserDataAndTasks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    _userId = await _authStorage.getUserId();
    _password = await _authStorage.getPassword();
    _userName = await _authStorage.getUsername() ?? "User";

    if (_userId != null && _password != null) {
      await Future.wait([
        _loadTasks(_userId!, _password!),
        _loadGroups(_userId!, _password!),
      ]);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to view tasks.')),
        );
      }
      if (mounted) setState(() => _isLoading = false);
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
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load groups: ${response['message']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading groups: $e')),
        );
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 18) return "Good Afternoon";
    return "Good Evening";
  }

  Future<void> _loadTasks(String userId, String password) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/get_user_task'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'password': password
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          final firstItem = decoded[0];
          if (firstItem['error_no'] == '0' && firstItem['message'] is Map<String, dynamic>) {
            final tasksMap = firstItem['message'] as Map<String, dynamic>;
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
                    dueDateStr = "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
                    dueTimeStr = "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
                  }

                  final int priorityInt = taskData['priority'] as int? ?? 0;
                  final String priorityStr = priorityToString(priorityInt);

                  return {
                    "id": taskId,
                    "taskName": taskData["name"] ?? "No Task Name",
                    "assignedBy": taskData["assigner_username"] ?? taskData["assigner_id"] ?? "Unknown",
                    "priority": priorityStr,
                    "description": taskData["description"] ?? "",
                    "dueDate": dueDateStr,
                    "dueTime": dueTimeStr,
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to load tasks: ${firstItem['message']}')),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to load tasks: Invalid server response.')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load tasks: Server error ${response.statusCode}')),
          );
        }
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
          _isLoading = false;
        });
      }
    }
  }

  String priorityToString(int priority) {
    switch (priority) {
      case 0: return 'Low';
      case 1: return 'Medium';
      case 2: return 'High';
      default: return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    String userName = _userName;
    String? profileImagePath;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SafeArea(
      child: Scaffold(
        appBar: TAppBar(
          title: Row(
            children: [
              if (profileImagePath != null)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      profileImagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.person, size: 30, color: Colors.grey),
                    ),
                  ),
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey, width: 2),
                  ),
                  child: Icon(Icons.person, size: 30, color: Colors.grey),
                ),
              const SizedBox(width: 10),
              Text(
                "${_getGreeting()}, $userName",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
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
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: Text(
                        'Roommate Groups',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.currentTextColor,
                        ),
                      ),
                    ),
                    Container(
                      color: themeProvider.themeColor,
                      height: 180,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _roommateGroups.isEmpty
                              ? Center(
                                  child: Text(
                                    'No groups found.',
                                    style: TextStyle(color: themeProvider.currentSecondaryTextColor),
                                  ),
                                )
                              : _buildGroupCarousel(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'My Tasks',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.currentTextColor,
                  ),
                ),
              ),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayTasks(),
            ],
          ),
        ),
      ),
    );
  }

  Widget displayTasks() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No tasks assigned to you yet!',
            style: TextStyle(color: themeProvider.currentSecondaryTextColor, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        Color priorityColor = themeProvider.currentSecondaryTextColor;
        if (task['priority'] == 'Medium') {
          priorityColor = themeProvider.warningColor;
        } else if (task['priority'] == 'High') {
          priorityColor = themeProvider.errorColor;
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: themeProvider.currentCardBackground,
          child: ListTile(
            title: Text(task['taskName'], style: TextStyle(color: themeProvider.currentTextColor)),
            subtitle: Text('Assigned by: ${task['assignedBy']}', style: TextStyle(color: themeProvider.currentSecondaryTextColor)),
            trailing: Text(task['priority'],
                style: TextStyle(color: priorityColor, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailScreen(task: task),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGroupCarousel() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    if (_roommateGroups.isEmpty) {
      return const Center(child: Text('No groups to display.'));
    }

    return SizedBox(
      height: 140,
      child: CarouselSlider(
        options: CarouselOptions(
          height: 140.0,
          enlargeCenterPage: true,
          autoPlay: false,
          viewportFraction: 0.6,
        ),
        items: _roommateGroups.map((group) {
          final List<dynamic> membersData = group['members'] ?? [];
          final List<String> memberNames = membersData
              .map((member) => member['username'] as String? ?? 'Unknown')
              .toList();

          return Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupDetailScreen(group: group),
                    ),
                  );
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group['group_name'] ?? 'Unnamed Group',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.currentTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Members: ${memberNames.join(', ')}",
                        style: TextStyle(
                          fontSize: 16,
                          color: themeProvider.currentSecondaryTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
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

// ==========================
// EXTRA SCREENS (Appended)
// ==========================

class TaskDetailScreen extends StatelessWidget {
  final Map<String, dynamic> task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(task['taskName'])),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text("Title: ${task['taskName']}",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("Description: ${task['description'] ?? "No description"}"),
            const SizedBox(height: 12),
            Text("Priority: ${task['priority']}"),
            const SizedBox(height: 12),
            if (task['photo'] != null)
              Image.network(task['photo'],
                  errorBuilder: (_, __, ___) => const Text("Image failed to load")),
            const SizedBox(height: 12),
            Text("Due Date: ${task['dueDate'] ?? 'Not specified'}"),
            Text("Time Due: ${task['dueTime'] ?? 'Not specified'}"),
          ],
        ),
      ),
    );
  }
}

class GroupDetailScreen extends StatelessWidget {
  final Map<String, dynamic> group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> membersData = group['members'] ?? [];
    final List<String> memberNames = membersData
        .map((member) => member['username'] as String? ?? 'Unknown')
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(group['group_name'] ?? 'Group Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Group Name: ${group['group_name'] ?? 'Unnamed Group'}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 20),
            const Text("Members:", style: TextStyle(fontSize: 20)),
            ...memberNames.map((name) => Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  child: Text("- $name"),
                )),
          ],
        ),
      ),
    );
  }
}

class TaskSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> tasks;
  TaskSearchDelegate({required this.tasks});

  @override
  List<Widget> buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) {
    final results = tasks
        .where((task) =>
            task['taskName'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(results[index]['taskName']),
        subtitle: Text('Assigned by: ${results[index]['assignedBy']}'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(task: results[index]),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}
