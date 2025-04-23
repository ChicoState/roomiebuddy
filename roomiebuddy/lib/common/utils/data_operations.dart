import 'package:flutter/material.dart';
import '../../services/group_service.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';

/// Standardized data operations across the app
class DataOperations {

  static Future<List<Map<String, dynamic>>> loadUserGroups() async {
    try {
      // Skip if not logged in
      if (!UserService.isLoggedIn) {
        return [];
      }
      
      final result = await GroupService.getGroupList(
        userId: UserService.userId ?? '',
        password: UserService.password ?? '',
      );
      
      if (result['success'] && result['groups'] != null) {
        final groups = result['groups'] as Map<String, dynamic>;
        if (groups.isNotEmpty) {
          List<Map<String, dynamic>> formattedGroups = [];
          
          for (var entry in groups.entries) {
            final groupId = entry.key;
            final groupData = entry.value as Map<String, dynamic>;
            
            formattedGroups.add({
              'groupId': groupId,
              'groupName': groupData['group_name'] ?? 'Unnamed Group',
              'description': groupData['description'] ?? 'No description',
              'memberCount': groupData['member_count'] ?? 1,
              'role': groupData['role_id'] ?? 'member',
            });
          }
          
          return formattedGroups;
        }
      }
      
      // If we get here, either the request failed or there are no groups
      return [];
    } catch (e) {
      debugPrint('Error loading groups: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> fetchTasks({
    required String category,
    required bool organizeByDate,
    String? groupId,
  }) async {
    try {
      // Skip if not logged in
      if (!UserService.isLoggedIn) {
        return {
          'success': false,
          'message': 'User not logged in',
          'data': organizeByDate ? {} : [],
        };
      }
      
      final result = await TaskService.fetchTasks(
        category: category,
        organizeByDate: organizeByDate,
        userId: UserService.userId ?? '',
        password: UserService.password ?? '',
        groupId: groupId,
      );

      return result;
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'data': organizeByDate ? {} : [],
      };
    }
  }

  static Future<Map<String, dynamic>> deleteTask(String taskId) async {
    try {
      // Skip if not logged in
      if (!UserService.isLoggedIn) {
        return {
          'success': false,
          'message': 'User not logged in',
        };
      }
      
      final result = await TaskService.deleteTask(
        taskId, 
        userId: UserService.userId ?? '',
        password: UserService.password ?? '',
      );
      
      return result;
    } catch (e) {
      debugPrint('Error deleting task: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> createGroup({
    required String groupName,
    String description = '',
  }) async {
    try {
      // Skip if not logged in
      if (!UserService.isLoggedIn) {
        return {
          'success': false,
          'message': 'User not logged in',
        };
      }
      
      final result = await GroupService.createGroup(
        userId: UserService.userId ?? '',
        groupName: groupName,
        description: description,
        password: UserService.password ?? '',
      );
      
      return result;
    } catch (e) {
      debugPrint('Error creating group: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> leaveGroup(String groupId) async {
    try {
      // Skip if not logged in
      if (!UserService.isLoggedIn) {
        return {
          'success': false,
          'message': 'User not logged in',
        };
      }
      
      final result = await GroupService.leaveGroup(
        userId: UserService.userId ?? '',
        groupId: groupId,
        password: UserService.password ?? '',
      );
      
      return result;
    } catch (e) {
      debugPrint('Error leaving group: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  static Future<Map<String, dynamic>> addTask(Map<String, String> taskData) async {
    try {
      // Skip if not logged in
      if (!UserService.isLoggedIn) {
        return {
          'success': false,
          'message': 'User not logged in',
        };
      }
      
      final result = await TaskService.addTask(taskData);
      return result;
    } catch (e) {
      debugPrint('Error adding task: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
} 