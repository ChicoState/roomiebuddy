import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:roomiebuddy/pages/login_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void _openColorPicker(BuildContext context, ThemeProvider themeProvider) {
    Color pickerColor = themeProvider.themeColor;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a theme color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
              labelTypes: const [
                ColorLabelType.hex,
                ColorLabelType.rgb,
                ColorLabelType.hsv,
              ],
              paletteType: PaletteType.hsv,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Apply'),
              onPressed: () {
                themeProvider.setThemeColor(pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeProvider.currentTextColor,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance Section
            Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.currentTextColor,
              ),
            ),
            const SizedBox(height: 12),
            
            // Dark Mode Toggle
            Card(
              child: ListTile(
                title: Text(
                  'Dark Mode',
                  style: TextStyle(color: themeProvider.currentTextColor),
                ),
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
                title: Text(
                  'Theme Color',
                  style: TextStyle(color: themeProvider.currentTextColor),
                ),
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
                  _openColorPicker(context, themeProvider);
                },
              ),
            ),
            
            // Account Section
            const SizedBox(height: 32),
            Text(
              'Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.currentTextColor,
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
                  // Show confirmation dialog
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirm Logout'),
                        content: const Text('Are you sure you want to log out?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close dialog
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              // Close dialog
                              Navigator.of(context).pop();
                              
                              // Navigate to login screen
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const LoginScreen(clearCredentials: true)),
                                (route) => false, // This removes all previous routes
                              );
                            },
                            child: Text(
                              'Logout',
                              style: TextStyle(color: themeProvider.errorColor),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}