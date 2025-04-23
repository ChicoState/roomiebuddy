import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'task_detail_sheet.dart';

class TaskList extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  final Function(String)? onDeleteTask;
  final Function()? onRefresh;
  final bool isLoading;
  final bool enableDelete;
  final String emptyMessage;

  const TaskList({
    super.key,
    required this.tasks,
    this.onDeleteTask,
    this.onRefresh,
    this.isLoading = false,
    this.enableDelete = true,
    this.emptyMessage = 'No tasks for this day',
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (tasks.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return onRefresh != null
        ? RefreshIndicator(
            onRefresh: () async => onRefresh!(),
            child: _buildTaskListView(),
          )
        : _buildTaskListView();
  }

  Widget _buildTaskListView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return _buildTaskItem(context, tasks[index]);
      },
    );
  }

  Widget _buildTaskItem(BuildContext context, Map<String, dynamic> task) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Debug: Print raw priority value to see what's coming in
    print('Raw priority value: ${task['priority']} (type: ${task['priority'].runtimeType})');
    
    // Normalize the priority once to avoid multiple calls
    final normalizedPriority = _normalizePriority(task['priority']);
    print('Normalized priority: $normalizedPriority');
    final priorityColor = _getPriorityColor(normalizedPriority);
    
    // Create the task card without Dismissible wrapper
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      color: themeProvider.currentCardBackground,
      child: ListTile(
        title: Text(
          task['taskName'],
          style: TextStyle(fontWeight: FontWeight.bold, color: themeProvider.currentTextColor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assigned by: ${task['assignerName'] ?? task['assignedBy']}', style: TextStyle(color: themeProvider.currentSecondaryTextColor)),
            Text('Group: ${task['groupName']}', style: TextStyle(color: themeProvider.currentSecondaryTextColor)),
            if (task['dueTime'] != null) 
              Text('Due: ${task['dueTime']}', style: TextStyle(color: themeProvider.currentSecondaryTextColor)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                normalizedPriority,
                style: TextStyle(
                  color: priorityColor,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          _showTaskDetails(context, task);
        },
      ),
    );
  }

  // Convert numeric priority to string if needed
  String _normalizePriority(dynamic priority) {
    print('Normalizing priority in task_list: $priority (${priority.runtimeType})');
    
    // Handle null values
    if (priority == null) {
      print('Priority is null, defaulting to Low');
      return 'Low';
    }
    
    // Handle numeric values
    if (priority is int) {
      print('Priority is int: $priority');
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
      print('Priority is String: $priority');
      
      // Try parsing as integer first
      int? numPriority = int.tryParse(priority);
      if (numPriority != null) {
        print('String parsed as int: $numPriority');
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
      print('Lowercase priority: $lowercasePriority');
      
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
      print('Priority is double: $priority');
      if (priority >= 3) {
        return 'High';
      } else if (priority >= 2) {
        return 'Medium';
      } else {
        return 'Low';
      }
    }
    
    // If it's some other type (Map, List, etc.)
    print('Priority is other type: ${priority.runtimeType}');
    
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

  void _showTaskDetails(BuildContext context, Map<String, dynamic> task) {
    TaskDetailSheet.show(
      context: context,
      task: task,
      onDeleteTask: onDeleteTask,
      onCompleteTask: (String taskId) {
        // Handle task completion
        // This would need to be implemented in the parent widget
        // For now, just show a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${task['taskName']}" marked as complete'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
} 