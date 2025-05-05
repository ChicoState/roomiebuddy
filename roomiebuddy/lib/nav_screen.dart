import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';

import 'pages/home_page.dart';
import 'pages/calendar_page.dart';
import 'pages/add_task_page.dart';
import 'pages/group_page.dart';
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
    const GroupPage(),
    const SettingsPage(),
  ];
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
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
        onTap: (value){
          setState(() {
            selectedIndex = value;
          });
        },
        backgroundColor: Colors.transparent,
        color: themeProvider.themeColor,
        buttonBackgroundColor: themeProvider.themeColor,
        animationDuration: const Duration(milliseconds: 300),
      ),
      body: pages[selectedIndex]
    );
  }
}

