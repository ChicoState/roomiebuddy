import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show debugPrint;
class AuthStorage {
  // 
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'email';
  static const String _passwordKey = 'password';
  static const String _usernameKey = 'username';
  static const String _profileImagePathKey = 'profile_image_path';
  
  static final AuthStorage _instance = AuthStorage._internal();
  
  factory AuthStorage() {
    return _instance;
  }
  
  AuthStorage._internal();
  
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
  
  // Generic method for getters
  Future<String?> _getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      debugPrint('Error getting $key: $e');
      return null;
    }
  }
  
  Future<String?> getUserId() async {
    return _getString(_userIdKey);
  }
  
  Future<String?> getEmail() async {
    return _getString(_emailKey);
  }
  
  Future<String?> getPassword() async {
    return _getString(_passwordKey);
  }
  
  Future<String?> getUsername() async {
    return _getString(_usernameKey);
  }
  
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if all required credentials are present
      final userId = prefs.getString(_userIdKey);
      final email = prefs.getString(_emailKey);
      final password = prefs.getString(_passwordKey);
      final username = prefs.getString(_usernameKey);
      
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
  
  Future<bool> saveProfileImagePath(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileImagePathKey, imagePath);
      return true;
    } catch (e) {
      debugPrint('Error storing profile image path: $e');
      return false;
    }
  }
  
  Future<String?> getProfileImagePath() async {
    return _getString(_profileImagePathKey);
  }
} 