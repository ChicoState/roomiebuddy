import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // BASE URL
  static const String baseUrl = 'http://10.0.2.2:5000';
  
  // HTTP client
  final http.Client _client = http.Client();

  // Singleton pattern implC
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal();

  // Generic GET request method
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Generic POST request method
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // AUTH METHODS
  
  // User signup
  Future<Map<String, dynamic>> signup(String username, String email, String password) async {
    return await post('/signup', {
      'username': username,
      'email': email,
      'password': password,
    });
  }

  // User login
  Future<Map<String, dynamic>> login(String email, String password) async {
    return await post('/login', {
      'email': email,
      'password': password,
    });
  }

  // TASK METHODS
  
  // Get user tasks
  Future<Map<String, dynamic>> getUserTasks(String userId, String password) async {
    return await post('/get_user_task', {
      'user_id': userId,
      'password': password,
    });
  }

  // Add a new task
  Future<Map<String, dynamic>> addTask(
    String taskName,
    String taskDescription,
    int dueYear,
    int dueMonth,
    int dueDate,
    int dueHour,
    int dueMin,
    int estDay,
    int estHour,
    int estMin,
    String assignerId,
    String assignId,
    String groupId,
    int recursive,
    int priority,
    String password,
  ) async {
    return await post('/add_task', {
      'task_name': taskName,
      'task_description': taskDescription,
      'task_due_year': dueYear,
      'task_due_month': dueMonth,
      'task_due_date': dueDate,
      'task_due_hour': dueHour,
      'task_due_min': dueMin,
      'task_est_day': estDay,
      'task_est_hour': estHour,
      'task_est_min': estMin,
      'assigner_id': assignerId,
      'assign_id': assignId,
      'group_id': groupId,
      'recursive': recursive,
      'priority': priority,
      'password': password,
    });
  }

  // GROUP METHODS

  // Get all groups for a user
  Future<Map<String, dynamic>> getGroupList(String userId, String password) async {
    return await post('/get_group_list', {
      'user_id': userId,
      'password': password,
    });
  }

  // **** NEW METHOD: Get members of a specific group ****
  Future<Map<String, dynamic>> getGroupMembers(String userId, String groupId, String password) async {
    // Note: The backend returns { error_no: 0, message: success, members: [...] }
    // The _handleResponse expects a list as the top-level JSON object.
    // We need to adjust how we handle this specific response or generalize _handleResponse.
    // For now, we'll make a direct call and parse differently.
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/get_group_members'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'group_id': groupId,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
          Map<String, dynamic> responseData = jsonDecode(response.body);
          if (responseData['error_no'] == '0') {
            return {
              'success': true,
              'members': responseData['members'] ?? [], // Return members list
              'message': responseData['message'],
            };
          } else {
            return {
              'success': false,
              'message': responseData['message'] ?? 'Unknown backend error',
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Server returned status code ${response.statusCode}',
          };
        }
    } catch (e) {
      return _handleError(e);
    }
  }
  // **** END NEW METHOD ****

  // Helper to convert priority int to string
  String priorityToString(int priority) {
    switch (priority) {
      case 0: return 'Low';
      case 1: return 'Medium';
      case 2: return 'High';
      default: return 'Unknown';
    }
  }

  // Create a new group
  Future<Map<String, dynamic>> createGroup(
    String userId, 
    String password, 
    String groupName, 
    String description
  ) async {
    return await post('/create_group', {
      'user_id': userId,
      'password': password,
      'group_name': groupName,
      'description': description,
    });
  }

  // Leave a group
  Future<Map<String, dynamic>> leaveGroup(
    String userId, 
    String password, 
    String groupId
  ) async {
    return await post('/leave_group', {
      'user_id': userId,
      'password': password,
      'group_id': groupId,
    });
  }

  // Delete a group
  Future<Map<String, dynamic>> deleteGroup(
    String userId, 
    String password, 
    String groupId
  ) async {
    return await post('/delete_group', {
      'user_id': userId,
      'password': password,
      'group_id': groupId,
    });
  }

  // Invite a user to a group
  Future<Map<String, dynamic>> inviteToGroup(
    String inviterId, 
    String inviteeId, 
    String groupId, 
    String password
  ) async {
    return await post('/invite_to_group', {
      'inviter_id': inviterId,
      'invitee_id': inviteeId,
      'group_id': groupId,
      'password': password,
    });
  }

  // Get pending group invites for a user
  Future<Map<String, dynamic>> getPendingInvites(String userId, String password) async {
    return await post('/get_pending_invites', {
      'user_id': userId,
      'password': password,
    });
  }

  // Respond to a group invitation
  Future<Map<String, dynamic>> respondToInvite(
    String userId, 
    String inviteId, 
    String status, 
    String password
  ) async {
    return await post('/respond_to_invite', {
      'user_id': userId,
      'invite_id': inviteId,
      'status': status, // 'accepted' or 'rejected'
      'password': password,
    });
  }

  // Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success
      List<dynamic> responseData = jsonDecode(response.body);
      
      if (responseData.isNotEmpty) {
        Map<String, dynamic> firstItem = responseData[0];
        return {
          'success': firstItem['error_no'] == '0',
          'data': firstItem,
          'message': firstItem['message'],
        };
      } else {
        return {
          'success': false,
          'message': 'Empty response from server',
        };
      }
    } else {
      // Error
      return {
        'success': false,
        'message': 'Server returned status code ${response.statusCode}',
      };
    }
  }

  // Handle exceptions
  Map<String, dynamic> _handleError(dynamic error) {
    return {
      'success': false,
      'message': 'Network error: ${error.toString()}',
    };
  }
}
