import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';
import 'package:roomiebuddy/providers/navigation_provider.dart';
import 'package:roomiebuddy/common/utils/data_operations.dart';
import 'package:roomiebuddy/services/user_service.dart';

import 'pages/home_page.dart';
import 'pages/calendar_page.dart';
import 'pages/add_taskpage.dart';
import 'pages/add_roomate_page.dart';
import 'pages/settings_page.dart';

class Navscreen extends StatefulWidget {
  const Navscreen({super.key});

  @override
  State<Navscreen> createState() => _NavscreenState();
}

class _NavscreenState extends State<Navscreen> {
  final pages = [
    const HomePage(),
    const CalendarPage(),
    const AddTaskpage(),
    const AddRoomatePage(),
    const SettingsPage(),
  ];
  
  @override
  void initState() {
    super.initState();
    // Initialize UserService to ensure user data is loaded
    _initUserService();
  }
  
  Future<void> _initUserService() async {
    await UserService.initialize();
    // Verify that we have user data after initialization
    if (!UserService.isLoggedIn) {
      debugPrint('Warning: UserService initialized but user is not logged in');
    } else {
      debugPrint('UserService initialized, user is logged in as: ${UserService.userName}');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final navigationProvider = Provider.of<NavigationProvider>(context);
    final iconColor = themeProvider.isDarkMode ? themeProvider.darkTextColor : themeProvider.lightTextColor;
    
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        items: [
          Icon(Icons.home,
            size: 30,
            color: iconColor,
          ),
          Icon(Icons.calendar_month,
            size: 30,
            color: iconColor,
          ),
          Icon(Icons.add, 
            size: 50,
            color: iconColor,
          ),
          Icon(Icons.people,
            size: 30,
            color: iconColor,
          ),
          Icon(Icons.settings,
            size: 30,
            color: iconColor,
          ),
        ],
        onTap: (value) async {
          // If selecting the Add Task page (index 2), check if user has groups
          if (value == 2) {
            final hasGroups = await _checkUserHasGroups();
            if (!hasGroups) {
              // Show dialog telling user to create a group first
              if (context.mounted) {
                _showNoGroupsDialog(context, themeProvider);
                // No longer redirect to Add Roommate page
              }
            }
          }
          
          // Use the navigation provider to change tabs
          navigationProvider.changeTab(value);
        },
        index: navigationProvider.selectedIndex,
        backgroundColor: Colors.transparent,
        color: themeProvider.themeColor,
        buttonBackgroundColor: themeProvider.themeColor,
        animationDuration: const Duration(milliseconds: 300),
      ),
      body: pages[navigationProvider.selectedIndex]
    );
  }
  
  // Check if user has any groups
  Future<bool> _checkUserHasGroups() async {
    try {
      final groups = await DataOperations.loadUserGroups();
      return groups.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if user has groups: $e');
      return false;
    }
  }
  
  // Show dialog when user has no groups
  void _showNoGroupsDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'No Groups Available',
          style: TextStyle(
            color: themeProvider.currentTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'You need to be a member of at least one group to add tasks. Create or join a group first.',
          style: TextStyle(
            color: themeProvider.currentTextColor,
          ),
        ),
        backgroundColor: themeProvider.currentCardBackground,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                color: themeProvider.themeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

