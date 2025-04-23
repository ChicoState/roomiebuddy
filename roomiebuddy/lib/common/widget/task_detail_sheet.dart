import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';

class TaskDetailSheet extends StatelessWidget {
  final Map<String, dynamic> task;
  final Function(String)? onDeleteTask;
  final Function(String)? onCompleteTask;

  const TaskDetailSheet({
    super.key, 
    required this.task,
    this.onDeleteTask,
    this.onCompleteTask,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sheet handle
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: themeProvider.currentBorderColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          // Task details content
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    task['taskName'],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.currentTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Divider(color: themeProvider.currentBorderColor),
                  if (task['description'] != null && task['description'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        task['description'],
                        style: TextStyle(
                          fontSize: 16,
                          color: themeProvider.currentTextColor,
                        ),
                      ),
                    ),
                  ListTile(
                    leading: Icon(Icons.person, color: themeProvider.themeColor),
                    title: Text('Assigned by', style: TextStyle(color: themeProvider.currentTextColor)),
                    subtitle: Text(task['assignerName'] ?? 'Not Specified', style: TextStyle(color: themeProvider.currentSecondaryTextColor)),
                  ),
                  ListTile(
                    leading: Icon(Icons.group, color: themeProvider.themeColor),
                    title: Text('Group', style: TextStyle(color: themeProvider.currentTextColor)),
                    subtitle: Text(task['groupName'] ?? 'Not Specified', style: TextStyle(color: themeProvider.currentSecondaryTextColor)),
                  ),
                  ListTile(
                    leading: Icon(Icons.calendar_today, color: themeProvider.themeColor),
                    title: Text('Due Date', style: TextStyle(color: themeProvider.currentTextColor)),
                    subtitle: Text(task['dueDate'] ?? 'Not specified', style: TextStyle(color: themeProvider.currentSecondaryTextColor)),
                  ),
                  ListTile(
                    leading: Icon(Icons.access_time, color: themeProvider.themeColor),
                    title: Text('Due Time', style: TextStyle(color: themeProvider.currentTextColor)),
                    subtitle: Text(task['dueTime'] ?? 'Not specified', style: TextStyle(color: themeProvider.currentSecondaryTextColor)),
                  ),
                  ListTile(
                    leading: Icon(Icons.flag, color: themeProvider.themeColor),
                    title: Text('Priority', style: TextStyle(color: themeProvider.currentTextColor)),
                    subtitle: () {
                      final normalizedPriority = _normalizePriority(task['priority']);
                      final priorityColor = _getPriorityColor(normalizedPriority);
                      return Text(
                        normalizedPriority, 
                        style: TextStyle(
                          color: priorityColor,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }(),
                  ),
                  ListTile(
                    leading: Icon(Icons.timer, color: themeProvider.themeColor),
                    title: Text('Estimated Time', style: TextStyle(color: themeProvider.currentTextColor)),
                    subtitle: Text(
                      _formatEstimatedTime(
                        task['estDay'] ?? 0,
                        task['estHour'] ?? 0,
                        task['estMin'] ?? 0,
                      ),
                      style: TextStyle(color: themeProvider.currentSecondaryTextColor),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Complete Task'),
                        onPressed: onCompleteTask != null ? () {
                          Navigator.pop(context);
                          onCompleteTask!(task['id']);
                        } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete Task'),
                        onPressed: onDeleteTask != null ? () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: themeProvider.currentBackground,
                              title: Text('Delete Task', style: TextStyle(color: themeProvider.currentTextColor)),
                              content: Text(
                                'Are you sure you want to delete "${task['taskName']}"?',
                                style: TextStyle(color: themeProvider.currentTextColor),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: Text('Cancel', style: TextStyle(color: themeProvider.themeColor)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: Text('Delete', style: TextStyle(color: themeProvider.errorColor)),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirm == true) {
                            Navigator.pop(context);
                            onDeleteTask!(task['id']);
                          }
                        } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.errorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to show the bottom sheet
  static void show({
    required BuildContext context, 
    required Map<String, dynamic> task,
    Function(String)? onDeleteTask,
    Function(String)? onCompleteTask,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeProvider.currentBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: TaskDetailSheet(
          task: task,
          onDeleteTask: onDeleteTask,
          onCompleteTask: onCompleteTask,
        ),
      ),
    );
  }

  // Convert numeric priority to string if needed
  String _normalizePriority(dynamic priority) {
    // Handle null values
    if (priority == null) {
      return 'Low';
    }
    
    // Handle numeric values
    if (priority is int) {
      switch (priority) {
        case 3:
          return 'High';
        case 2:
          return 'Medium';
        case 1:
        case 0:
          return 'Low';
        default:
          return 'Low';
      }
    }
    
    // Handle string values that might be numeric
    if (priority is String) {
      // Try parsing as integer first
      int? numPriority = int.tryParse(priority);
      if (numPriority != null) {
        switch (numPriority) {
          case 3:
            return 'High';
          case 2:
            return 'Medium';
          case 1:
          case 0:
            return 'Low';
          default:
            return 'Low';
        }
      }
      
      // Check if the string matches priority names
      String lowercasePriority = priority.toLowerCase();
      
      if (lowercasePriority.contains('high') || lowercasePriority == '3') {
        return 'High';
      } else if (lowercasePriority.contains('medium') || lowercasePriority.contains('med') || lowercasePriority == '2') {
        return 'Medium';
      } else if (lowercasePriority.contains('low') || lowercasePriority == '1' || lowercasePriority == '0') {
        return 'Low';
      }
      
      // Return as is if it doesn't match anything else
      return priority;
    }
    
    // Handle double values (just in case)
    if (priority is double) {
      if (priority >= 3) {
        return 'High';
      } else if (priority >= 2) {
        return 'Medium';
      } else {
        return 'Low';
      }
    }
    
    // Default to Low for any other case
    return 'Low';
  }

  Color _getPriorityColor(String priority) {
    switch(priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.green;
    }
  }
  
  // Format estimated time for display
  String _formatEstimatedTime(dynamic days, dynamic hours, dynamic minutes) {
    // Convert to integers in case they're strings
    int estDays = days is int ? days : int.tryParse(days.toString()) ?? 0;
    int estHours = hours is int ? hours : int.tryParse(hours.toString()) ?? 0;
    int estMinutes = minutes is int ? minutes : int.tryParse(minutes.toString()) ?? 0;
    
    // Create formatted string
    List<String> parts = [];
    
    if (estDays > 0) {
      parts.add('${estDays} ${estDays == 1 ? 'day' : 'days'}');
    }
    
    if (estHours > 0) {
      parts.add('${estHours} ${estHours == 1 ? 'hour' : 'hours'}');
    }
    
    if (estMinutes > 0) {
      parts.add('${estMinutes} ${estMinutes == 1 ? 'minute' : 'minutes'}');
    }
    
    return parts.isEmpty ? 'Not specified' : parts.join(', ');
  }
} 