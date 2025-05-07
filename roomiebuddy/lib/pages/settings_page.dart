import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:roomiebuddy/pages/subpages/auth/login_screen.dart';
import 'package:roomiebuddy/services/auth_storage.dart';
import 'package:flutter/services.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthStorage _authStorage = AuthStorage();
  String _username = "";
  String _userId = "";
  String _errorMessage = "";
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ------- Backend Communication Methods ------- //

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final userId = await _authStorage.getUserId();
      final username = await _authStorage.getUsername();

      if (userId == null || username == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "User data not found";
        });
        return;
      }
      
      if (mounted) {
        setState(() {
          _userId = userId;
          _username = username;
          _isLoading = false;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error loading user data: $e";
          _isLoading = false;
        });
      }
    }
  }

  // ------- Color Picker Method ------- //

  void _openColorPicker(BuildContext context, ThemeProvider themeProvider) {
    Color pickerColor = themeProvider.themeColor;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeProvider.currentBackground,
          contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.5,
              enableAlpha: false,
              displayThumbColor: true,
              labelTypes: const [],
              paletteType: PaletteType.hsv,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: themeProvider.currentTextColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(width: 4),
            TextButton(
              child: Text(
                'Apply',
                style: TextStyle(color: themeProvider.themeColor),
              ),
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

  // ------- Main Build Method ------- //

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    

    if (!_isLoading && _errorMessage.isNotEmpty) {
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
        body: Center(child: Text(_errorMessage)),
      );
    }

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
            // -------------------- Profile Section -------------------- //
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.currentTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Card(
              color: themeProvider.currentInputFill,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: themeProvider.currentBorderColor, width: 1.0),
              ),
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 4.0, 0.0, 4.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        'Username: ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.currentTextColor,
                        ),
                      ),
                      title: Text(
                        _isLoading ? "Loading..." : _username,
                        style: TextStyle(
                          fontSize: 15,
                          overflow: TextOverflow.ellipsis,
                          color: themeProvider.currentTextColor,
                        ),
                      ),
                    ),
                    ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        'User ID: ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.currentTextColor,
                        ),
                      ),
                      title: Text(
                        _isLoading ? "Loading..." : (_userId.length > 12 ? "${_userId.substring(0, 11)}..." : _userId),
                        style: TextStyle(
                          fontSize: 15,
                          overflow: TextOverflow.ellipsis,
                          color: themeProvider.currentTextColor,
                        ),
                      ),
                      trailing: IconButton(
                        padding: EdgeInsets.zero, 
                        constraints: const BoxConstraints(), 
                        icon: Icon(
                          Icons.copy,
                          color: _isLoading ? Colors.grey : themeProvider.currentTextColor,
                          size: 20,
                        ),
                        tooltip: 'Copy User ID', 
                        onPressed: _isLoading ? null : () {
                          Clipboard.setData(ClipboardData(text: _userId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User ID copied to clipboard')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // -------------------- Appearance Section -------------------- //
            Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.currentTextColor,
              ),
            ),
            const SizedBox(height: 4),
            
            // Dark Mode Toggle
            Card(
              color: themeProvider.currentInputFill,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: themeProvider.currentBorderColor, width: 1.0),
              ),
              margin: const EdgeInsets.only(bottom: 8.0),
              child: ListTile(
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.only(left: 16.0, right: 6.0),
                title: Text(
                  'Dark Mode',
                  style: TextStyle(color: themeProvider.currentTextColor, fontSize: 15),
                ),
                trailing: Switch(
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
            
            const SizedBox(height: 8),
            
            // Theme Color
            Card(
              color: themeProvider.currentInputFill,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: themeProvider.currentBorderColor, width: 1.0),
              ),
              margin: const EdgeInsets.only(bottom: 8.0),
              child: ListTile(
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.only(left: 16.0, right: 12.0),
                title: Text(
                  'Theme Color',
                  style: TextStyle(color: themeProvider.currentTextColor, fontSize: 15),
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
            
            // -------------------- Account Section -------------------- //
            const SizedBox(height: 8),
            Text(
              'Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.currentTextColor,
              ),
            ),
            const SizedBox(height: 4),
            
            // Logout
            Card(
              color: themeProvider.currentInputFill,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: themeProvider.currentBorderColor, width: 1.0),
              ),
              margin: const EdgeInsets.only(bottom: 8.0),
              child: ListTile(
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.only(left: 16.0, right: 12.0),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    color: themeProvider.currentTextColor,
                    fontSize: 15,
                  ),
                ),
                trailing: const Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirm Logout'),
                        content: const Text('Are you sure you want to log out?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
          
                              // Navigate to login screen
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const LoginScreen(clearCredentials: true)),
                                (route) => false,
                              );
                            },
                            child: const Text(
                              'Logout',
                              style: TextStyle(color: Colors.red),
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