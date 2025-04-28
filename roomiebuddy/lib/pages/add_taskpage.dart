import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // Import dart:io for File
import 'package:provider/provider.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';
import 'package:roomiebuddy/utils/data_transformer.dart';
import 'package:roomiebuddy/services/api_service.dart';
import 'package:roomiebuddy/services/auth_storage.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker

class AddTaskpage extends StatefulWidget {
  const AddTaskpage({super.key});

  @override
  State<AddTaskpage> createState() => _AddTaskpageState();
}

class _AddTaskpageState extends State<AddTaskpage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedGroupId;
  String? _selectedMemberId;
  String? _selectedPriority;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _estDaysController = TextEditingController();
  final TextEditingController _estHoursController = TextEditingController();
  final TextEditingController _estMinsController = TextEditingController();
  String? _selectedRecurrence = 'Once';

  // Add state variable for selected image
  File? _selectedImage;

  List<Map<String, dynamic>> _userGroups = [];
  List<Map<String, dynamic>> _groupMembers = [];
  bool _isLoadingGroups = false;
  bool _isLoadingMembers = false;
  bool _isSaving = false;

  String _userId = "";
  String _password = "";

  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final userId = await _authStorage.getUserId();
    final password = await _authStorage.getPassword();
    if (userId != null && password != null) {
      setState(() {
        _userId = userId;
        _password = password;
      });
      _loadUserGroups();
    } else {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: User not logged in.')),
          );
          Navigator.of(context).pop();
       }
    }
  }

  Future<void> _loadUserGroups() async {
    setState(() => _isLoadingGroups = true);
    try {
      final response = await _apiService.getGroupList(_userId, _password);
      if (response['success'] && mounted) {
        final groupsMap = response['data']?['message'] as Map<String, dynamic>? ?? {};
        setState(() {
          _userGroups = groupsMap.values.map((group) => group as Map<String, dynamic>).toList();
        });
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
    } finally {
      if (mounted) {
         setState(() => _isLoadingGroups = false);
      }
    }
  }

  Future<void> _loadGroupMembers(String groupId) async {
    setState(() => _isLoadingMembers = true);
    try {
      final response = await _apiService.getGroupMembers(_userId, groupId, _password);
      if (response['success'] && mounted) {
        setState(() {
          _groupMembers = List<Map<String, dynamic>>.from(response['members']);
        });
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load members: ${response['message']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading members: $e')),
        );
      }
    } finally {
       if (mounted) {
          setState(() => _isLoadingMembers = false);
       }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: themeProvider.isDarkMode
              ? ColorScheme.dark(
                  primary: themeProvider.themeColor,
                  onPrimary: themeProvider.currentTextColor,
                  surface: themeProvider.currentInputFill,
                  onSurface: themeProvider.currentTextColor,
                )
              : ColorScheme.light(
                  primary: themeProvider.themeColor,
                  onPrimary: themeProvider.currentTextColor,
                  surface: themeProvider.currentInputFill,
                  onSurface: themeProvider.currentTextColor,
                ),
            dialogTheme: DialogTheme(
              backgroundColor: themeProvider.currentInputFill,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: themeProvider.themeColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: themeProvider.isDarkMode
              ? ColorScheme.dark(
                  primary: themeProvider.themeColor,
                  onPrimary: themeProvider.currentTextColor,
                  surface: themeProvider.currentInputFill,
                  onSurface: themeProvider.currentTextColor,
                )
              : ColorScheme.light(
                  primary: themeProvider.themeColor,
                  onPrimary: themeProvider.currentTextColor,
                  surface: themeProvider.currentInputFill,
                  onSurface: themeProvider.currentTextColor,
                ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: themeProvider.currentInputFill,
              dialHandColor: themeProvider.themeColor,
              dayPeriodColor: themeProvider.themeColor,
              dayPeriodTextColor: themeProvider.currentTextColor,
            ),
            dialogTheme: DialogTheme(
              backgroundColor: themeProvider.currentInputFill,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: themeProvider.themeColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Function to pick an image
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Pick an image from the gallery
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveTask() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // --- Show SnackBar if image selected but upload not implemented ---
    if (_selectedImage != null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Image selected, but backend upload is not yet implemented.')),
      );
      // Optionally, you might want to return here if upload is mandatory
      // return;
    }

    if (_titleController.text.isEmpty) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Please enter a task title.')));
      return;
    }
     if (_selectedGroupId == null) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Please select a group.')));
      return;
    }
    if (_selectedMemberId == null) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Please select a member to assign the task to.')));
      return;
    }
     if (_selectedPriority == null) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Please select a priority.')));
      return;
    }
    if (_selectedDate == null) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Please select a due date.')));
      return;
    }
    if (_selectedTime == null) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Please select a due time.')));
      return;
    }

    final int estDays = int.tryParse(_estDaysController.text) ?? 0;
    final int estHours = int.tryParse(_estHoursController.text) ?? 0;
    final int estMins = int.tryParse(_estMinsController.text) ?? 0;

    final Map<String, int> recurrenceMap = {
      'Once': 0,
      'Daily': 1,
      'Weekly': 2,
      'Monthly': 3,
    };
    final int recurrenceInt = recurrenceMap[_selectedRecurrence ?? 'Once'] ?? 0;

    final double? dueTimestamp = dateTimeToTimestamp(_selectedDate, _selectedTime);
    final int priorityInt = priorityToInt(_selectedPriority);

    if (dueTimestamp == null) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Invalid date/time selected.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await _apiService.post('/add_task', {
        'task_name': _titleController.text,
        'task_description': _descriptionController.text,
        'task_due': dueTimestamp,
        'assigner_id': _userId,
        'assign_id': _selectedMemberId!,
        'group_id': _selectedGroupId!,
        'password': _password,
        'priority': priorityInt,
        'task_est_day': estDays,
        'task_est_hour': estHours,
        'task_est_min': estMins,
        'recursive': recurrenceInt,
        'image_path': '' 
      });

      if (response['success'] && mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Task added successfully!'), duration: Duration(seconds: 2)),
        );
        setState(() {
          _titleController.clear();
          _descriptionController.clear();
          _selectedGroupId = null;
          _selectedMemberId = null;
          _groupMembers = [];
          _selectedPriority = null;
          _selectedDate = null;
          _selectedTime = null;
          _estDaysController.clear();
          _estHoursController.clear();
          _estMinsController.clear();
          _selectedRecurrence = 'Once';
          // Clear selected image
          _selectedImage = null;
        });
      } else {
         if (mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text('Failed to add task: ${response['message']}')),
            );
         }
      }
    } catch (e) {
       if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error adding task: $e')),
          );
       }
    } finally {
       if (mounted) {
          setState(() => _isSaving = false);
       }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estDaysController.dispose();
    _estHoursController.dispose();
    _estMinsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      filled: true,
      fillColor: themeProvider.currentInputFill,
      hintStyle: TextStyle(color: themeProvider.currentSecondaryTextColor),
      labelStyle: TextStyle(color: themeProvider.currentSecondaryTextColor),
    );
    final dropdownDecoration = inputDecoration.copyWith(
      labelStyle: null, 
    );
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Task',
          style: TextStyle(
            color: themeProvider.currentTextColor,
            fontWeight: FontWeight.bold
          ),
        ),
        iconTheme: IconThemeData(color: themeProvider.currentTextColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Details',
              style: TextStyle(
                color: themeProvider.currentTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _titleController,
              decoration: inputDecoration.copyWith(hintText: 'Enter task title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: inputDecoration.copyWith(hintText: 'Enter task description'),
              maxLines: 4,
            ),
            const SizedBox(height: 12),

            Text(
              'Assign To',
              style: TextStyle(
                color: themeProvider.currentTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: dropdownDecoration,
                    dropdownColor: themeProvider.currentInputFill,
                    borderRadius: BorderRadius.circular(8),
                    value: _selectedGroupId,
                    hint: _isLoadingGroups
                        ? const Row(children: [SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 8), Text('Loading...')])
                        : const Text('Select Group'),
                    items: _userGroups.map((group) =>
                      DropdownMenuItem<String>(
                        value: group['group_id']?.toString(), 
                        child: Text(group['name'] ?? 'Unknown Group', overflow: TextOverflow.ellipsis), 
                      )
                    ).toList(),
                    onChanged: _isLoadingGroups ? null : (value) {
                      if (value != null && value != _selectedGroupId) {
                          setState(() {
                          _selectedGroupId = value;
                          _selectedMemberId = null;
                          _groupMembers = [];
                           _loadGroupMembers(value);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                   child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: dropdownDecoration,
                    dropdownColor: themeProvider.currentInputFill,
                    borderRadius: BorderRadius.circular(8),
                    value: _selectedMemberId,
                    hint: _isLoadingMembers
                        ? const Row(children: [SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 8), Text('Loading...')])
                        : (_selectedGroupId == null
                            ? const Text('Select group first')
                            : (_groupMembers.isEmpty ? const Text('No members found') : const Text('Select Member'))),
                    items: _groupMembers.map((member) =>
                      DropdownMenuItem<String>(
                        value: member['user_id']?.toString(), 
                        child: Text(member['username'] ?? 'Unknown Member', overflow: TextOverflow.ellipsis), 
                      )
                    ).toList(),
                    onChanged: (_selectedGroupId == null || _isLoadingMembers || _groupMembers.isEmpty) ? null : (value) {
                       setState(() {
                         _selectedMemberId = value;
                       });
                    },
                    disabledHint: _selectedGroupId == null ? const Text('Select group first') : (_isLoadingMembers ? null : const Text('No members found')), 
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              'Priority',
              style: TextStyle(
                color: themeProvider.currentTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
             DropdownButtonFormField<String>(
               isExpanded: true,
               decoration: dropdownDecoration,
               dropdownColor: themeProvider.currentInputFill,
               borderRadius: BorderRadius.circular(8),
               value: _selectedPriority,
               hint: const Text('Select Priority'),
               items: ['Low', 'Medium', 'High'].map((String priority) {
                 return DropdownMenuItem<String>(
                   value: priority,
                   child: Text(priority),
                 );
               }).toList(),
               onChanged: (value) {
                 setState(() {
                   _selectedPriority = value;
                 });
               },
             ),
            const SizedBox(height: 12),

            Text(
              'Due Date & Time',
              style: TextStyle(
                color: themeProvider.currentTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeProvider.currentInputFill,
                      foregroundColor: themeProvider.currentTextColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_selectedDate == null ? 'Select Date' : '${_selectedDate!.toLocal()}'.split(' ')[0]),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                     style: ElevatedButton.styleFrom(
                      backgroundColor: themeProvider.currentInputFill,
                      foregroundColor: themeProvider.currentTextColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: () => _selectTime(context),
                     icon: const Icon(Icons.access_time, size: 18),
                    label: Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              'Estimated Duration',
              style: TextStyle(
                color: themeProvider.currentTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _estDaysController,
                    decoration: inputDecoration.copyWith(hintText: 'Days'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _estHoursController,
                    decoration: inputDecoration.copyWith(hintText: 'Hours'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _estMinsController,
                    decoration: inputDecoration.copyWith(hintText: 'Mins'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              'Recurrence',
              style: TextStyle(
                color: themeProvider.currentTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: dropdownDecoration,
              dropdownColor: themeProvider.currentInputFill,
              borderRadius: BorderRadius.circular(8),
              value: _selectedRecurrence,
              hint: const Text('Select Recurrence'),
              items: ['Once', 'Daily', 'Weekly', 'Monthly']
                  .map((String recurrence) {
                return DropdownMenuItem<String>(
                  value: recurrence,
                  child: Text(recurrence),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRecurrence = value;
                });
              },
            ),
            const SizedBox(height: 16), // Adjusted spacing slightly

            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.themeColor.withOpacity(0.8),
                    foregroundColor: themeProvider.currentTextColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onPressed: _pickImage, // Call _pickImage on press
                  // Change icon based on whether an image is selected
                  icon: Icon(
                    _selectedImage == null ? Icons.add_a_photo : Icons.check_circle_outline,
                    size: 18,
                    color: _selectedImage == null
                        ? themeProvider.currentTextColor
                        : Colors.green, // Indicate success with green check
                  ),
                  label: const Text('Add Photo'),
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.themeColor,
                    foregroundColor: themeProvider.currentTextColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: _isSaving ? null : _saveTask,
                  child: _isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: themeProvider.currentTextColor,
                          ),
                        )
                      : Text('Save Task', style: TextStyle(color: themeProvider.currentTextColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

