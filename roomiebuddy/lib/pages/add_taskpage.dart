import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import '../providers/navigation_provider.dart';
import '../common/utils/data_operations.dart';

// Inline implementation of SectionTitle widget
class SectionTitle extends StatelessWidget {
  final String title;
  final ThemeProvider themeProvider;

  const SectionTitle({
    super.key,
    required this.title,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title, 
        style: TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.bold,
          color: themeProvider.currentTextColor,
        )
      ),
    );
  }
}

// Inline implementation of TaskFormField widget
class TaskFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ThemeProvider themeProvider;
  final int maxLines;
  final TextInputType keyboardType;

  const TaskFormField({
    super.key,
    required this.controller,
    required this.hint,
    required this.themeProvider,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.currentInputFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: themeProvider.currentBorderColor),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(color: themeProvider.currentTextColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: themeProvider.currentSecondaryTextColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}

// Inline implementation of TaskDropdown widget
class TaskDropdown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final ThemeProvider themeProvider;
  final String hint;

  const TaskDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.themeProvider,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: themeProvider.currentInputFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: themeProvider.currentBorderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: themeProvider.currentTextColor),
          dropdownColor: themeProvider.currentCardBackground,
          hint: Text(
            hint, 
            style: TextStyle(
              color: themeProvider.currentSecondaryTextColor,
              fontSize: 16,
            )
          ),
          style: TextStyle(
            color: themeProvider.currentTextColor,
            fontSize: 16,
          ),
          items: items.map((String item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class AddTaskpage extends StatefulWidget {
  const AddTaskpage({super.key});

  @override
  State<AddTaskpage> createState() => _AddTaskpageState();
}

class _AddTaskpageState extends State<AddTaskpage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  // State variables
  String? _selectedPriority;
  String? _selectedAssignee;
  bool _isLoading = false;
  bool _isLoadingGroups = true; // Added loading state for groups
  List<String> _assigneeOptions = ['Everyone']; // TODO: Add logic to actually assign tasks to specific people
  final List<String> _priorityOptions = ['Low', 'Medium', 'High'];
  List<Map<String, dynamic>> _userGroups = [];
  String? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Initialize UserService first
    await UserService.initialize();
    
    // Then load groups
    await _loadUserGroups();
    
    // Set up assignee options
    setState(() {
      _assigneeOptions = ['Everyone'];
    });
  }

  Future<void> _loadUserGroups() async {
    try {
      final userGroups = await DataOperations.loadUserGroups();
      
      setState(() {
        _userGroups = userGroups;
        
        // Set default selected group to the first group if available
        if (userGroups.isNotEmpty) {
          _selectedGroupId = userGroups[0]['groupId'];
        } else {
          _selectedGroupId = null;
        }
        _isLoadingGroups = false; // Set loading state to false
      });
    } catch (e) {
      debugPrint('Error loading groups: $e');
      setState(() {
        _userGroups = [];
        _selectedGroupId = null;
        _isLoadingGroups = false; // Set loading state to false even on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isLightMode = !themeProvider.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Task', 
          style: TextStyle(
            color: themeProvider.isDarkMode ? themeProvider.darkTextColor : themeProvider.lightTextColor
          )
        ),
      ),
      body: _isLoadingGroups
        ? Center(child: CircularProgressIndicator(color: themeProvider.themeColor))
        : _userGroups.isEmpty 
          ? _buildNoGroupsMessage(themeProvider)
          : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                SectionTitle(title: 'Title', themeProvider: themeProvider),
                TaskFormField(
                  controller: _titleController,
                  hint: 'Enter title',
                  themeProvider: themeProvider,
                ),
                const SizedBox(height: 16),
                
                // Description
                SectionTitle(title: 'Description', themeProvider: themeProvider),
                TaskFormField(
                  controller: _descriptionController,
                  hint: 'Enter description',
                  themeProvider: themeProvider,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                
                // Due Date & Time
                SectionTitle(title: 'Due Date & Time', themeProvider: themeProvider),
                Row(
                  children: [
                    Expanded(
                      child: TaskFormField(
                        controller: _dateController,
                        hint: '(MM-DD-YYYY)',
                        themeProvider: themeProvider,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TaskFormField(
                        controller: _timeController,
                        hint: '(HH:MM)',
                        themeProvider: themeProvider,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Estimated Time
                SectionTitle(title: 'Estimated Time', themeProvider: themeProvider),
                Row(
                  children: [
                    Expanded(
                      child: TaskFormField(
                        controller: _daysController,
                        hint: 'Days',
                        themeProvider: themeProvider,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: TaskFormField(
                        controller: _hoursController,
                        hint: 'Hours',
                        themeProvider: themeProvider,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: TaskFormField(
                        controller: _minutesController,
                        hint: 'Minutes',
                        themeProvider: themeProvider,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Group',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isLightMode 
                      ? themeProvider.lightTextColor
                      : themeProvider.darkTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isLightMode 
                      ? themeProvider.lightInputFill
                      : themeProvider.currentInputFill,
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isLightMode 
                            ? themeProvider.currentBorderColor
                            : Colors.transparent,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeProvider.themeColor,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    value: _selectedGroupId,
                    dropdownColor: isLightMode 
                      ? themeProvider.lightInputFill
                      : themeProvider.currentInputFill,
                    style: TextStyle(
                      color: isLightMode 
                        ? themeProvider.lightTextColor
                        : themeProvider.darkTextColor,
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: isLightMode 
                        ? themeProvider.lightTextColor
                        : themeProvider.darkTextColor,
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedGroupId = newValue;
                      });
                    },
                    items: _userGroups.isEmpty 
                      ? [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(
                              'No groups available',
                              style: TextStyle(
                                color: themeProvider.errorColor,
                              ),
                            ),
                          ),
                        ]
                      : _userGroups.map((group) {
                          return DropdownMenuItem<String>(
                            value: group['groupId'],
                            child: Text(
                              group['groupName'] ?? 'Unknown Group',
                              style: TextStyle(
                                color: isLightMode 
                                  ? themeProvider.lightTextColor
                                  : themeProvider.darkTextColor,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                // Priority and Assign To
                Row(
                  children: [
                    // Priority column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionTitle(title: 'Priority', themeProvider: themeProvider),
                          TaskDropdown(
                            value: _selectedPriority,
                            items: _priorityOptions,
                            hint: 'Select Priority',
                            onChanged: (value) {
                              setState(() {
                                _selectedPriority = value;
                              });
                            },
                            themeProvider: themeProvider,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Assign To column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionTitle(title: 'Assign To', themeProvider: themeProvider),
                          TaskDropdown(
                            value: _selectedAssignee,
                            items: _assigneeOptions,
                            hint: 'Select Assignee',
                            onChanged: (value) {
                              setState(() {
                                _selectedAssignee = value;
                              });
                            },
                            themeProvider: themeProvider,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Save button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.themeColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        ),
                        onPressed: _saveTask,
                        child: Text(
                          'Save', 
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? themeProvider.darkTextColor : themeProvider.lightTextColor
                          )
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildNoGroupsMessage(ThemeProvider themeProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_off,
              size: 70,
              color: themeProvider.themeColor,
            ),
            const SizedBox(height: 24),
            Text(
              'No Groups Available',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: themeProvider.currentTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'You need to be a member of at least one group to add tasks.',
              style: TextStyle(
                fontSize: 16,
                color: themeProvider.currentSecondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create or join a group on the Add Roommate page.',
              style: TextStyle(
                fontSize: 16,
                color: themeProvider.currentSecondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Use NavigationProvider to change the tab
                final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
                navigationProvider.changeTab(3); // Index 3 is the Add Roommate page
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.themeColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.group_add,
                    color: themeProvider.isDarkMode ? themeProvider.darkTextColor : themeProvider.lightTextColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Go to Add Roommate',
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? themeProvider.darkTextColor : themeProvider.lightTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetForm() {
    if (!mounted) return;
    
    try {
      setState(() {
        _titleController.clear();
        _descriptionController.clear();
        _daysController.clear();
        _hoursController.clear();
        _minutesController.clear();
        _dateController.clear();
        _timeController.clear();
        _selectedPriority = null;
        _selectedAssignee = null;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error resetting form: $e");
    }
  }

  void _saveTask() async {
    try {
      // Ensure date and time are entered
      if (_dateController.text.isEmpty || _timeController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter both date and time.')),
        );
        return; 
      }
      // Ensure date is in format MM-DD-YYYY
      final datePattern = RegExp(r'^\d{2}-\d{2}-\d{4}$');
      if (!datePattern.hasMatch(_dateController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter date in format MM-DD-YYYY')),
        );
        return;
      }
      // Ensure time is in format HH:MM
      final timePattern = RegExp(r'^\d{2}:\d{2}$');
      if (!timePattern.hasMatch(_timeController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter time in format HH:MM')),
        );
        return;
      }
      // Ensure priority is selected
      if (_selectedPriority == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a priority.')),
        );
        return;
      }
      // Ensure assignee is selected
      if (_selectedAssignee == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an assignee.')),
        );
        return;
      }
      // Ensure group is selected
      if (_selectedGroupId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a group.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Use UserService instead of SharedPreferences
      if (!UserService.isLoggedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You need to be logged in to create tasks')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Parse date and time from the input
      final dateParts = _dateController.text.split('-');
      final timeParts = _timeController.text.split(':');
      
      try {
        final month = int.parse(dateParts[0]);
        final day = int.parse(dateParts[1]);
        final year = int.parse(dateParts[2]);
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        
        final dueDateTime = DateTime(year, month, day, hour, minute);
        
        // Convert priority string to integer value
        final priorityValue = TaskService.getPriorityValue(_selectedPriority);

        // Parse estimated time fields (with defaults)
        final estDays = int.tryParse(_daysController.text) ?? 0;
        final estHours = int.tryParse(_hoursController.text) ?? 0;
        final estMinutes = int.tryParse(_minutesController.text) ?? 0;

        // Prepare task data with actual user ID
        final taskData = TaskService.prepareTaskData(
          title: _titleController.text,
          description: _descriptionController.text,
          dueDateTime: dueDateTime,
          priorityValue: priorityValue,
          estDays: estDays,
          estHours: estHours,
          estMinutes: estMinutes,
          assignee: _selectedAssignee!,
          userId: UserService.userId ?? '',
          password: UserService.password ?? '',
          groupId: _selectedGroupId ?? "",
          assignerName: UserService.userName,
        );

        // Send task to backend using DataOperations
        final result = await DataOperations.addTask(taskData);
        
        if (!mounted) return;

        // Show feedback to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );

        // Reset form if successful
        if (result['success']) {
          Future.delayed(const Duration(seconds: 1), _resetForm);
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid date or time format.')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
}

