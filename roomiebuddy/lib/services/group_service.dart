import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GroupService {
  static const String _baseUrl = 'http://10.0.2.2:5000';
  
  // Create a new group
  static Future<Map<String, dynamic>> createGroup({
    required String userId,
    required String groupName,
    String description = '',
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/create_group'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'user_id': userId,
          'group_name': groupName,
          'description': description,
          'password': password,
        }),
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
            'message': 'Group created successfully',
            'group_id': decodedResponse[0]['group_id'],
          };
        } else {
          // Backend returned 200 but with an error
          String errorMessage = 'Group creation failed';
          if (decodedResponse is List && decodedResponse.isNotEmpty && decodedResponse[0] is Map) {
            errorMessage = decodedResponse[0]['message'] ?? errorMessage;
          }
          return {
            'success': false,
            'message': errorMessage,
          };
        }
      } else {
        // HTTP error
        return {
          'success': false,
          'message': 'HTTP error ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      // Exception occurred
      debugPrint('GroupService createGroup error: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Get groups for a user
  static Future<Map<String, dynamic>> getGroupList({
    required String userId,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/get_group_list'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'user_id': userId,
          'password': password,
        }),
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
            'message': 'Groups retrieved successfully',
            'groups': decodedResponse[0]['message'],
          };
        } else {
          // Backend returned 200 but with an error
          String errorMessage = 'Failed to retrieve groups';
          if (decodedResponse is List && decodedResponse.isNotEmpty && decodedResponse[0] is Map) {
            errorMessage = decodedResponse[0]['message'] ?? errorMessage;
          }
          return {
            'success': false,
            'message': errorMessage,
          };
        }
      } else {
        // HTTP error
        return {
          'success': false,
          'message': 'HTTP error ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      // Exception occurred
      debugPrint('GroupService getGroupList error: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Leave a group
  static Future<Map<String, dynamic>> leaveGroup({
    required String userId,
    required String groupId,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/leave_group'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'user_id': userId,
          'group_id': groupId,
          'password': password,
        }),
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
            'message': 'Left group successfully',
          };
        } else {
          // Backend returned 200 but with an error
          String errorMessage = 'Failed to leave group';
          if (decodedResponse is List && decodedResponse.isNotEmpty && decodedResponse[0] is Map) {
            errorMessage = decodedResponse[0]['message'] ?? errorMessage;
          }
          return {
            'success': false,
            'message': errorMessage,
          };
        }
      } else {
        // HTTP error
        return {
          'success': false,
          'message': 'HTTP error ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      // Exception occurred
      debugPrint('GroupService leaveGroup error: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
} 