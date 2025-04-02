import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance Section
            const Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Dark Mode Toggle
            Card(
              child: ListTile(
                title: const Text('Dark Mode'),
                trailing: Container(
                  padding: const EdgeInsets.only(right: 0),
                  width: 50,
                  child: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleDarkMode();
                    },
                    activeColor: themeProvider.switchActiveThumb,
                    activeTrackColor: themeProvider.switchActiveTrack,
                    inactiveThumbColor: themeProvider.switchInactiveThumb,
                    inactiveTrackColor: themeProvider.switchInactiveTrack,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Theme Color
            Card(
              child: ListTile(
                title: const Text('Theme Color'),
                trailing: Container(
                  width: 50,
                  height: 30,
                  decoration: BoxDecoration(
                    color: themeProvider.themeColor,
                    border: Border.all(color: themeProvider.currentBorderColor),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onTap: () {
                  // Color selection will be implemented later
                },
              ),
            ),
            
            // Account Section - with more spacing for separation
            const SizedBox(height: 32),
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Logout
            Card(
              child: ListTile(
                title: Text(
                  'Logout',
                  style: TextStyle(
                    color: themeProvider.errorColor,
                  ),
                ),
                trailing: Icon(
                  Icons.logout,
                  color: themeProvider.errorColor,
                ),
                onTap: () {
                  // Non-functional
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}