import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../containers/primary_header_container.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedCategory = 'Today'; // Tracks selected category
  bool _isLoading = false; // Loading state to show a loading spinner
  List<Map<String, dynamic>> _tasks = []; // Store tasks as a list of maps

  @override
  void initState() {
    super.initState();
    fetchTasks(); // Fetch tasks when the page loads
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-fetch tasks when the screen is resumed
    fetchTasks();
  }

  // Fetch tasks from the API
  Future<void> fetchTasks() async {
    if (!mounted) return; // Ensure the widget is still mounted before updating the state
    setState(() {
      _isLoading = true; // Show loading spinner while fetching
    });

    print("Fetching Tasks.....");

    try {

      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/get_task'),
        headers: {'Content-Type': 'application/json'}, // Ensure correct headers
        body: jsonEncode({'category': _selectedCategory}), // Convert map to JSON string
      );

      print("Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body); // Decode response body
        print("Response Data: $data");

        if (data.containsKey("message") && data["message"] == "success") {
          data.remove("message"); // Remove success message

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
            print("Tasks Loaded: $_tasks");
          }
        } else {
          throw Exception('Unexpected data format');
        }
      } else {
        print('Server Error: ${response.statusCode}');
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      print('Error fetching tasks: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Hide loading spinner
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchTasks, // Reload tasks when pressed
            tooltip: 'Reload Tasks',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TPrimaryHeaderContainer(child: Container()),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'My Tasks',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
            ),
            _buildTaskCategories(),
            _buildGroupSection(),
            _isLoading
                ? const Center(child: CircularProgressIndicator()) // Show loading spinner
                : displayTasks(), // Display the tasks
          ],
        ),
      ),
    );
  }

  // Task category selector with oval design
  Widget _buildTaskCategories() {
    final categories = ['Today', 'Upcoming', 'Completed'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: categories.map((title) {
          bool isSelected = _selectedCategory == title;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = title;
              });
              fetchTasks(); // Fetch tasks when the category is changed
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.green,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Placeholder for Group Section (can be filled later)
  Widget _buildGroupSection() {
    return Container(); // Empty for now
  }

  // Display tasks fetched from the API
  Widget displayTasks() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Prevent scrolling conflicts
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
              style: const TextStyle(color: Colors.red),
            ),
          ),
        );
      },
    );
  }
}
