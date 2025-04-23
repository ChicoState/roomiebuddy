import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  // Static properties to cache user data
  static String? _userId;
  static String? _userName;
  static String? _password;
  static bool _initialized = false;
  
  // Initialize by loading user data from SharedPreferences
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id');
      _userName = prefs.getString('username');
      _password = prefs.getString('password');
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing UserService: $e');
    }
  }
  
  // Getters for user data
  static String? get userId => _userId;
  static String? get userName => _userName ?? 'User';
  static String? get password => _password;
  
  // Check if user is logged in
  static bool get isLoggedIn => _userId != null && _userId!.isNotEmpty && _password != null && _password!.isNotEmpty;
  
  // Helper method for API authentication
  static Map<String, String> getAuthCredentials() {
    return {
      'user_id': _userId ?? '',
      'password': _password ?? '',
    };
  }
  
  // Update user data (e.g., after login)
  static Future<void> updateUserData({
    required String userId,
    required String password,
    String? userName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('user_id', userId);
      await prefs.setString('password', password);
      
      if (userName != null) {
        await prefs.setString('username', userName);
      }
      
      _userId = userId;
      _password = password;
      if (userName != null) {
        _userName = userName;
      }
    } catch (e) {
      debugPrint('Error updating user data: $e');
    }
  }
  
  // Clear user data (for logout)
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('password');
      await prefs.remove('username');
      
      _userId = null;
      _password = null;
      _userName = null;
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }
} 