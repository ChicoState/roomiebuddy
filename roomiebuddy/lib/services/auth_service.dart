import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _baseUrl = 'http://10.0.2.2:5000';
  
  // Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'email': email,
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
            'message': 'Login successful',
            'user_id': decodedResponse[0]['user_id'],
          };
        } else {
          // Backend returned 200 but with an error
          String errorMessage = 'Login failed';
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
      debugPrint('AuthService login error: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Sign up user
  static Future<Map<String, dynamic>> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/signup'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
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
            'message': 'Signup successful',
            'user_id': decodedResponse[0]['user_id'],
          };
        } else {
          // Backend returned 200 but with an error
          String errorMessage = 'Signup failed';
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
      debugPrint('AuthService signup error: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
} 