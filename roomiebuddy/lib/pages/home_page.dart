import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/widget/appbar/appbar.dart';
import '../providers/theme_provider.dart';
import '../common/widget/roommate_carousel.dart';
import '../common/widget/task_list.dart';
import '../common/widget/task_search.dart';
import '../services/user_service.dart';
import '../common/utils/data_operations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final String _selectedCategory = 'All';
  bool _isLoading = false;
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _filteredTasks = [];
  String _searchText = '';
  String? profileImagePath;
  List<Map<String, dynamic>> roommateGroups = []; // gets populated from API
  Map<String, dynamic>? _selectedGroup;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app is resumed
      _initializeData();
    }
  }
  
  // This method will be called when the widget becomes visible again
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when returning to this page
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    // Initialize UserService first
    await UserService.initialize();
    
    // Then load groups
    await _loadGroups();
    
    // Finally load tasks
    fetchTasks();
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await DataOperations.loadUserGroups();
      
      // Transform the group data to the format expected by the carousel
      List<Map<String, dynamic>> formattedGroups = groups.map((group) {
        return {
          'groupId': group['groupId'],
          'groupName': group['groupName'],
          'description': group['description'],
          'members': ['You', '+ ${(group['memberCount'] ?? 1) - 1} more'],
          'memberCount': group['memberCount'] ?? 1,
        };
      }).toList();
      
      setState(() {
        roommateGroups = formattedGroups;
        
        // Select the first group by default
        if (formattedGroups.isNotEmpty && _selectedGroup == null) {
          _selectedGroup = formattedGroups[0];
        }
      });
      
      // Fetch tasks with the selected group filter
      fetchTasks();
    } catch (e) {
      debugPrint('Error loading groups: $e');
      setState(() {
        roommateGroups = [];
        _selectedGroup = null;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 18) return "Good Afternoon";
    return "Good Evening";
  }

  Future<void> fetchTasks() async {
    if (!mounted) return;
    
    final selectedGroupId = _selectedGroup?['groupId'];
    debugPrint('HomePage: Fetching tasks with groupId: $selectedGroupId (type: ${selectedGroupId?.runtimeType})');
    
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await DataOperations.fetchTasks(
        category: _selectedCategory,
        organizeByDate: false,
        groupId: selectedGroupId,
      );

      if (result['success']) {
        // Get the tasks
        List<Map<String, dynamic>> taskList = List<Map<String, dynamic>>.from(result['data'] ?? []);
        
        // Add group names from our known groups
        for (var task in taskList) {
          final groupId = task['groupId'];
          if (groupId != null && groupId.isNotEmpty && groupId != "0") {
            // Find matching group in our roommateGroups
            final matchingGroup = roommateGroups.firstWhere(
              (group) => group['groupId'] == groupId,
              orElse: () => {'groupName': ''},
            );
            
            // Set the group name
            task['groupName'] = matchingGroup['groupName'] ?? '';
          }
        }
        
        setState(() {
          _tasks = taskList;
          _filterTasks(_searchText);
        });
      } else {
        debugPrint('Error fetching tasks: ${result['message']}');
      }
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterTasks(String query) {
    setState(() {
      _searchText = query;
      if (query.isEmpty) {
        _filteredTasks = [];
      } else {
        _filteredTasks = _tasks.where((task) {
          final taskName = task['taskName'].toString().toLowerCase();
          final description = task['description'].toString().toLowerCase();
          final searchLower = query.toLowerCase();
          
          return taskName.contains(searchLower) || 
                 description.contains(searchLower);
        }).toList();
      }
    });
  }

  // Deletes a task from the backend using DataOperations
  Future<void> deleteTask(String taskId) async {
    try {
      final result = await DataOperations.deleteTask(taskId);
      
      if (result['success']) {
        setState(() {
          _tasks.removeWhere((task) => task['id'] == taskId);
          _filterTasks(_searchText);
        });
        
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

  // Handle group selection from carousel
  void _onGroupSelected(Map<String, dynamic> group) {
    debugPrint('HomePage: Group selected: ${group['groupName']}, id: ${group['groupId']} (type: ${group['groupId'].runtimeType})');
    
    setState(() {
      _selectedGroup = group;
    });
    
    // Reload tasks with the new group filter
    fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SafeArea(
      child: Scaffold(
        appBar: TAppBar(
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: themeProvider.currentBorderColor, width: 2),
                ),
                child: ClipOval(
                  child: profileImagePath != null
                    ? Image.asset(
                        profileImagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.person, size: 30, color: themeProvider.currentSecondaryTextColor),
                      )
                    : Icon(Icons.person, size: 30, color: themeProvider.currentSecondaryTextColor),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "${_getGreeting()}, ${UserService.userName}",
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w500,
                  color: themeProvider.currentTextColor,
                ),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: themeProvider.themeColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      color: themeProvider.currentBackground,
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Roommate Groups',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.isDarkMode ? themeProvider.darkTextColor : themeProvider.lightTextColor,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 180,
                      child: Center(
                        child: roommateGroups.isEmpty 
                        ? Text(
                            'No roommate groups yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: themeProvider.isDarkMode ? themeProvider.darkTextColor : themeProvider.lightTextColor,
                            ),
                          )
                        : RoommateGroupCarousel(
                            roommateGroups: roommateGroups,
                            onGroupSelected: _onGroupSelected,
                          ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Tasks',
                      style: TextStyle(
                        fontSize: 25, 
                        fontWeight: FontWeight.bold,
                        color: themeProvider.currentTextColor,
                      ),
                    ),
                    TaskSearchBar(
                      onSearch: _filterTasks,
                      searchText: _searchText,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.4, // 40% of screen height
                  child: TaskList(
                    tasks: _filteredTasks.isEmpty && _searchText.isEmpty ? _tasks : _filteredTasks,
                    onDeleteTask: deleteTask,
                    onRefresh: fetchTasks,
                    isLoading: _isLoading,
                    emptyMessage: _searchText.isNotEmpty ? 'No tasks found' : 'No tasks here',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
