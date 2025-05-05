import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';
import 'package:roomiebuddy/utils/data_transformer.dart';
import 'package:roomiebuddy/services/api_service.dart';
import 'package:roomiebuddy/services/auth_storage.dart';
import 'package:image_picker/image_picker.dart';

class AddTaskpage extends StatefulWidget {
  const AddTaskpage({super.key});

  @override
  State<AddTaskpage> createState() => _AddTaskpageState();
}

class _AddTaskpageState extends State<AddTaskpage> {
  // TextEditingControllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _estDaysController = TextEditingController();
  final TextEditingController _estHoursController = TextEditingController();
  final TextEditingController _estMinsController = TextEditingController();

  // Task variables
  String? _selectedGroupId;
  String? _selectedMemberId;
  String? _selectedPriority;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedRecurrence = 'Once';
  File? _selectedImage;

  // For storing users groups and members in selected group
  List<Map<String, dynamic>> _userGroups = [];
  List<Map<String, dynamic>> _groupMembers = [];
  bool _isLoadingGroups = false;
  bool _isLoadingMembers = false;
  bool _isSaving = false;
  bool _initialDataLoaded = false;

  String _userId = "";
  String _password = "";

  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialDataLoaded) {
      _loadInitialData();
      _initialDataLoaded = true;
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

  // ------- Backend Communication Methods ------- //

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingGroups = true);
    final userId = await _authStorage.getUserId();
    final password = await _authStorage.getPassword();
    if (userId != null && password != null) {
      setState(() {
        _userId = userId;
        _password = password;
      });
      await _loadUserGroups();
      setState(() => _isLoadingGroups = false);
    } else {
      setState(() => _isLoadingGroups = false);
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
      if (response['success']) {
        final groupsMap = response['data']?['groups'] as Map<String, dynamic>? ?? {};
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
      setState(() => _isLoadingGroups = false);
    }
  }

  Future<void> _loadGroupMembers(String groupId) async {
    setState(() => _isLoadingMembers = true);
    
    try {
      final response = await _apiService.getGroupMembers(_userId, groupId, _password);
      if (response['success']) {
        final members = response['members'];
        if (members is List) {
          setState(() {
            _groupMembers = List<Map<String, dynamic>>.from(members.map((member) {
              if (member is Map<String, dynamic>) {
                return member;
              } else {
                return Map<String, dynamic>.from(member as Map);
              }
            }));
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to load members: Invalid response format')),
            );
          }
        }
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
      setState(() => _isLoadingMembers = false);
    }
  }

  Future<void> _saveTask() async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // TODO: Implement image upload
    if (_selectedImage != null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Image selected, but backend upload is not yet implemented.')),
      );
    }

    // Ensure we have all the required fields
    // If the user has not entered certain fields, show a snackbar telling them to enter the next missing field

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
    
    // Validate that est time inputs contain valid integers
    if (_estDaysController.text.isNotEmpty && int.tryParse(_estDaysController.text) == null) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Days must be an integer value.')));
      return;
    }
    if (_estHoursController.text.isNotEmpty && int.tryParse(_estHoursController.text) == null) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Hours must be an integer value.')));
      return;
    }
    if (_estMinsController.text.isNotEmpty && int.tryParse(_estMinsController.text) == null) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Minutes must be an integer value.')));
      return;
    }

    // Convert est time inputs from objects to ints
    final int estDays = int.tryParse(_estDaysController.text) ?? 0;
    final int estHours = int.tryParse(_estHoursController.text) ?? 0;
    final int estMins = int.tryParse(_estMinsController.text) ?? 0;

    // Map the recurrence value to an int for backend
    final Map<String, int> recurrenceMap = {
      'Once': 0,
      'Daily': 1,
      'Weekly': 2,
      'Monthly': 3,
    };

    final int recurrenceInt = recurrenceMap[_selectedRecurrence ?? 'Once'] ?? 0;
    final int priorityInt = priorityToInt(_selectedPriority);

    // If the date/time is invalid (shouldn't happen with current checks, but good practice)
    if (_selectedDate == null || _selectedTime == null) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Invalid date/time selected.')));
      return;
    }

    setState(() => _isSaving = true); // Set saving state to true, shows a loading indicator

    try {
      final response = await _apiService.addTask(
        _titleController.text,                           // taskName
        _descriptionController.text,                   // taskDescription
        _selectedDate!.year,                           // dueYear
        _selectedDate!.month,                          // dueMonth
        _selectedDate!.day,                            // dueDate
        _selectedTime!.hour,                           // dueHour
        _selectedTime!.minute,                         // dueMin
        estDays,                                       // estDay
        estHours,                                      // estHour
        estMins,                                       // estMin
        _userId,                                       // assignerId
        _selectedMemberId!,                            // assignId
        _selectedGroupId!,                             // groupId
        recurrenceInt,                                 // recursive
        priorityInt,                                   // priority
        _password,                                     // password
      );

      if (!mounted) return;

      if (response['success']) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Task added successfully!'), duration: Duration(seconds: 2)),
        );
        // Clear all the fields if save was successful
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
          _selectedImage = null;
        });
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to add task: ${response['message']}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error adding task: $e')),
      );
    } finally {
       setState(() => _isSaving = false);
    }
  }


  // ------- Date/Time/Image Picker Methods ------- //

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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // ------- Main Build Method ------- //

  @override
  Widget build(BuildContext context) {
    // Theme and general input styling setup
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
            // ------------ Task Details Section ------------  //
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

            // ------------ Assignment Section ------------  //
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

            // ------------ Priority Section ------------  //
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

            // ------------ Due Date & Time Section ------------  //
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

            // ------------ Estimated Duration Section ------------  //
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

            // ------------ Recurrence Section ------------  //
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
            const SizedBox(height: 16),

            // ------------ Action Buttons ------------  //
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.themeColor,
                    foregroundColor: themeProvider.currentTextColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onPressed: _pickImage,
                  // Change icon based on whether an image is selected
                  icon: Icon(
                    _selectedImage == null ? Icons.add_a_photo : Icons.check_circle_outline,
                    size: 18,
                    color: _selectedImage == null
                        ? themeProvider.currentTextColor
                        : Colors.green, // Indicate image uploaded with green check
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

