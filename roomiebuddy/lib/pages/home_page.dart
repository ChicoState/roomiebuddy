import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import '../common/widget/appbar/appbar.dart';
import '../containers/primary_header_container.dart';
import '../providers/theme_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final String _selectedCategory = 'Today';
  bool _isLoading = false;
  List<Map<String, dynamic>> _tasks = [];
  TextEditingController _searchController = TextEditingController();

  //  Carousel Feature Start
  final List<Map<String, dynamic>> roommateGroups = [
    {
      "groupName": "Room 101",
      "members": ["Alice", "Bob", "Charlie"]
    },
    {
      "groupName": "Kitchen Crew",
      "members": ["Dana", "Eli"]
    },
    {
      "groupName": "Laundry Legends",
      "members": ["Fred", "Gina", "Harry"]
    },
  ];

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 18) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  Future<void> fetchTasks() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/get_user_task'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'category': _selectedCategory,
          'user_id': "dummy_id",
          "password": "dummy_password"
        }),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey("message") && data["message"] == "success") {
          data.remove("message");
          if (mounted) {
            setState(() {
              _tasks = data.entries.map((e) {
                return {
                  "id": e.key,
                  "taskName": e.value["name"] ?? "No Task Name",
                  "assignedBy": e.value["assignedBy"] ?? "Unknown",
                  "priority": e.value["priority"] ?? "No Priority",
                };
              }).toList();
            });
          }
        } else {
          throw Exception('Unexpected data format');
        }
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      print('Error fetching tasks: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String userName = "Naruto";
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
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: 30, color: Colors.grey),
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
              Text("${_getGreeting()}, $userName", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(context: context, delegate: TaskSearchDelegate(tasks: _tasks));
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
              color: themeProvider.themeColor,
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Text(
                        'Roommate Groups',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.lightTextColor,
                        ),
                      ),
                    ),
                    Container(
  color: Colors.white.withOpacity(0.05),
  height: 180,
  child: _buildGroupCarousel(),
),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'My Tasks',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),
              _isLoading ? const Center(child: CircularProgressIndicator()) : displayTasks(),
            ],
          ),
        ),
      ),
    );
  }

  // Carousel Widget
  Widget _buildGroupCarousel() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return SizedBox(
      height: 140,
      child: CarouselSlider(
        options: CarouselOptions(
          height: 140.0,
          enlargeCenterPage: true,
          autoPlay: false,
          viewportFraction: 0.85,
        ),
        items: roommateGroups.map((group) {
          return Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  print('Tapped group: ${group['groupName']}');
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.currentCardBackground,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: themeProvider.themeColor),
                    boxShadow: [
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
                        group['groupName'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.currentTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Members: ${group['members'].join(', ')}",
                        style: TextStyle(
                          fontSize: 16,
                          color: themeProvider.currentSecondaryTextColor,
                        ),
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

  Widget displayTasks() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Text(task['taskName']),
            subtitle: Text('Assigned by: ${task['assignedBy']}'),
            trailing: Text(
              task['priority'],
              style: TextStyle(color: themeProvider.errorColor),
            ),
          ),
        );
      },
    );
  }
}

class TaskSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> tasks;
  TaskSearchDelegate({required this.tasks});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    List<Map<String, dynamic>> filteredTasks = tasks.where((task) {
      return task['taskName'].toLowerCase().contains(query.toLowerCase());
    }).toList();
    return ListView.builder(
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return ListTile(
          title: Text(task['taskName']),
          subtitle: Text('Assigned by: ${task['assignedBy']}'),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}

