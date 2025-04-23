import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../common/utils/date_parser.dart';
import '../services/user_service.dart';

class TaskService {
  static const String _baseUrl = 'http://10.0.2.2:5000';
  
  // Adds a task to the backend
  static Future<Map<String, dynamic>> addTask(Map<String, String> taskData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/add_task'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(taskData),
      );
      
      final decodedResponse = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        if (decodedResponse is List && 
            decodedResponse.isNotEmpty && 
            decodedResponse[0] is Map && 
            decodedResponse[0]['error_no'] == '0') {
          // Success
          return {
            'success': true,
            'message': 'Task added successfully!',
            'data': decodedResponse
          };
        } else {
          // Backend returned 200 but with an error
          return {
            'success': false,
            'message': 'Backend error: ${response.body}',
            'data': decodedResponse
          };
        }
      } else {
        // HTTP error
        return {
          'success': false,
          'message': 'HTTP error ${response.statusCode}: ${response.body}',
          'data': decodedResponse
        };
      }
    } catch (e) {
      // Exception occurred
      return {
        'success': false,
        'message': 'Error: $e',
        'data': null
      };
    }
  }
  
  // Fetch tasks for either homepage or calendar
  static Future<Map<String, dynamic>> fetchTasks({
    required String category, 
    bool organizeByDate = false,
    String userId = "dummy_id",
    String password = "dummy_password",
    String? groupId,
  }) async {
    try {
      debugPrint("TaskService: Fetching tasks for category: $category, groupId: $groupId");
      final response = await http.post(
        Uri.parse('$_baseUrl/get_user_task'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'category': category,
          'user_id': userId,
          'password': password,
          'group_id': groupId,
        }),
      );

      debugPrint("TaskService: Response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        
        if (decoded is List && decoded.isNotEmpty) {
          final firstItem = decoded[0];
          
          // Check for error message first
          if (firstItem.containsKey("error_no") && firstItem["error_no"] != "0") {
            debugPrint("TaskService: Backend returned error: ${firstItem["message"]}");
            return {
              'success': false,
              'message': firstItem["message"],
              'data': null
            };
          }
          
          final message = firstItem["message"];
          
          if (message is Map<String, dynamic>) {
            debugPrint("TaskService: Processing ${message.length} tasks");
            
            List<Map<String, dynamic>> allTasks = [];
            
            message.entries.forEach((e) {
              final task = e.value;
              allTasks.add(_processTaskData(e.key, task));
            });
            
            // Add back group filtering
            if (groupId != null && groupId.isNotEmpty && groupId != "0") {
              debugPrint("TaskService: Filtering tasks for groupId: $groupId, tasks before: ${allTasks.length}");
              
              allTasks = allTasks.where((task) {
                final taskGroupId = task['groupId'];
                final match = taskGroupId == groupId;
                debugPrint("TaskService: Task ${task['id']} has groupId: $taskGroupId, matches filter: $match");
                return match;
              }).toList();
              
              debugPrint("TaskService: Tasks after filtering: ${allTasks.length}");
            }
            
            if (organizeByDate) {
              // Calendar view - organize tasks by date
              final Map<DateTime, List<Map<String, dynamic>>> eventMap = {};
              
              for (var task in allTasks) {
                // Parse the due date if it exists
                if (task["dueDate"] != null) {
                  try {
                    final dateStr = task["dueDate"].toString();
                    final eventDateTime = DateParser.parseTaskDate(dateStr);
                    
                    if (eventDateTime != null) {
                      final eventDate = DateParser.normalizeDate(eventDateTime);
                      
                      if (eventMap[eventDate] == null) {
                        eventMap[eventDate] = [];
                      }
                      
                      eventMap[eventDate]!.add(task);
                    }
                  } catch (e) {
                    debugPrint('TaskService: Error processing date: $e');
                  }
                }
              }
              
              return {
                'success': true,
                'message': 'Tasks fetched successfully',
                'data': eventMap,
              };
            } else {
              // Home page view - flat list of tasks
              return {
                'success': true,
                'message': 'Tasks fetched successfully',
                'data': allTasks,
              };
            }
          } else if (message is String && message == "success") {
            // Backend might return success but no tasks
            debugPrint("TaskService: Backend returned success but no tasks");
            return {
              'success': true,
              'message': 'No tasks found',
              'data': organizeByDate ? {} : [],
            };
          }
        }
      }
      
      return {
        'success': false,
        'message': 'Failed to fetch tasks',
        'data': null
      };
    } catch (e) {
      debugPrint('TaskService: Error fetching tasks: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'data': null
      };
    }
  }
  
  // Helper method to process task data consistently
  static Map<String, dynamic> _processTaskData(String id, Map<String, dynamic> task) {
    // If we have the assigner's ID, we should try to get their actual name
    String assignerId = task["assigner_id"] ?? "";
    
    // For now, the backend doesn't include assigner_name, so we can check if we have UserService available
    // This won't work for tasks created by other users, but will work for tasks the current user created
    String assignerName;
    
    if (assignerId == UserService.userId) {
      // If the current user created the task, use their name
      assignerName = UserService.userName ?? "User";
    } else {
      // Otherwise use a placeholder or try to fetch from group members in the future
      assignerName = task["assigner_name"] ?? "User";
    }
    
    // Get the actual group name from the task data
    String groupName = task["group_name"] ?? "";
    
    // Get group ID with logging
    String groupId = task["group_id"] ?? "0";
    debugPrint("TaskService: Processing task $id with group_id: ${task["group_id"]}, parsed as: $groupId");
    
    return {
      "id": id,
      "taskName": task["name"] ?? "No Task Name",
      "assignedBy": task["assigner_id"] ?? "Unknown",
      "assignerName": assignerName,
      "assignedTo": task["assign_id"] ?? "Unknown",
      "groupId": groupId,
      "groupName": groupName,
      "priority": task["priority"],
      "description": task["description"] ?? "",
      "dueDate": task["due"],
      "dueTime": task["due"],
      "photo": task["photo_url"],
      "estDay": task["est_day"] ?? 0,
      "estHour": task["est_hour"] ?? 0,
      "estMin": task["est_min"] ?? 0,
    };
  }
  
  // Prepare task data from form inputs
  static Map<String, String> prepareTaskData({
    required String title,
    required String description,
    required DateTime dueDateTime,
    required int priorityValue,
    required int estDays,
    required int estHours,
    required int estMinutes,
    required String assignee,
    String userId = "dummy_id",
    String password = "dummy_password",
    String groupId = "0", // Default to 0 (no group)
    String? assignerName,
  }) {
    // If groupId is empty or null, default to "0"
    final validGroupId = (groupId.isEmpty) ? "0" : groupId;
    
    return {
      'task_name': title,
      'task_description': description,
      'assigner_id': userId,
      'assigner_name': assignerName ?? UserService.userName ?? 'User',
      'assign_id': userId, // For now, assigning to self
      'group_id': validGroupId,
      'password': password,
      'task_due_year': dueDateTime.year.toString(),
      'task_due_month': dueDateTime.month.toString(),
      'task_due_date': dueDateTime.day.toString(),
      'task_due_hour': dueDateTime.hour.toString(),
      'task_due_min': dueDateTime.minute.toString(),
      'task_est_day': estDays.toString(),
      'task_est_hour': estHours.toString(),
      'task_est_min': estMinutes.toString(),
      'priority': priorityValue.toString(),
      'assignee': assignee,
    };
  }
  
  // Converts priority string to int value
  static int getPriorityValue(String? priority) {
    switch (priority) {
      case 'High':
        return 3;
      case 'Medium':
        return 2;
      case 'Low':
      default:
        return 1;
    }
  }
  
  // Delete a task
  static Future<Map<String, dynamic>> deleteTask(
    String taskId, {
    String userId = "dummy_id",
    String password = "dummy_password",
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/delete_task'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'task_id': taskId,
          'user_id': userId,
          'password': password
        }),
      );
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && 
            decoded.isNotEmpty && 
            decoded[0] is Map && 
            decoded[0]['error_no'] == '0') {
          return {
            'success': true,
            'message': 'Task deleted successfully',
          };
        } else {
          return {
            'success': false,
            'message': 'Backend error: ${response.body}',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP error ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
} 