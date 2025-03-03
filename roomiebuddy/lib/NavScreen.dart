import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/calender_page.dart';
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
    HomePage(),
    CalenderPage(),
    AddTaskpage(),
    AddRoomatePage(),
    SettingsPage(),
  ];
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        items: [
        Icon(Icons.home,
        size: 30,
        ),
        Icon(Icons.calendar_month,
        size: 30,
        ),
        Icon(Icons.add, 
        size: 50,
        ),
        Icon(Icons.people,
        size: 30,
        ),
        Icon(Icons.settings,
        size: 30,
        ),
        ],
        onTap: (value){
          setState(() {
            selectedIndex = value;
          });
        },
        backgroundColor:Colors.transparent,
        color: Colors.greenAccent,
      ),
      body: pages[selectedIndex]
    );
  }
}

