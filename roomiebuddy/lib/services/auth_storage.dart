import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show debugPrint;
class AuthStorage {
  // Keys for SharedPreferences
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'email';
  static const String _passwordKey = 'password';
  static const String _usernameKey = 'username';
  
  // Singleton pattern implementation
  static final AuthStorage _instance = AuthStorage._internal();
  
  factory AuthStorage() {
    return _instance;
  }
  
  AuthStorage._internal();
  
  // Store user credentials
  Future<bool> storeUserCredentials(String userId, String email, String password, String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_emailKey, email);
      await prefs.setString(_passwordKey, password);
      await prefs.setString(_usernameKey, username);
      return true;
    } catch (e) {
      debugPrint('Error storing user credentials: $e');
      return false;
    }
  }
  
  // Get user ID
  Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      return null;
    }
  }
  
  // Get email
  Future<String?> getEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_emailKey);
    } catch (e) {
      debugPrint('Error getting email: $e');
      return null;
    }
  }
  
  // Get password
  Future<String?> getPassword() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_passwordKey);
    } catch (e) {
      debugPrint('Error getting password: $e');
      return null;
    }
  }
  
  // Get username
  Future<String?> getUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_usernameKey);
    } catch (e) {
      debugPrint('Error getting username: $e');
      return null;
    }
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if all required credentials are present
      final userId = prefs.getString(_userIdKey);
      final email = prefs.getString(_emailKey);
      final password = prefs.getString(_passwordKey);
      final username = prefs.getString(_usernameKey);
      
      // For development/debugging - REMEMBER: remove or set to false in production (proabably wont happen)
      debugPrint("Auth check: UserId=$userId, Email=$email, Username=$username");
      
      // Ensure all values exist and aren't empty
      return userId != null && userId.isNotEmpty && 
             email != null && email.isNotEmpty && 
             password != null && password.isNotEmpty &&
             username != null && username.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }
  
  // Clear user credentials (logout)
  Future<bool> clearUserCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      await prefs.remove(_emailKey);
      await prefs.remove(_passwordKey);
      await prefs.remove(_usernameKey);
      return true;
    } catch (e) {
      debugPrint('Error clearing user credentials: $e');
      return false;
    }
  }
} 