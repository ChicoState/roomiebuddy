import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false; // GLOBAL DARK MODE FLAG
  Color _themeColor = Colors.greenAccent; // GLOBAL THEME COLOR

  // Utility colors (Theme independent)
  Color get errorColor => Colors.red;
  Color get warningColor => Colors.orange;
  Color get successColor => Colors.green;
  
  // Global colors (Light Mode)
  Color get lightBackground => Colors.white;
  Color get lightCardBackground => Colors.white;
  Color get lightTextColor => Colors.black;
  Color get lightTextSecondary => Colors.grey[700]!;
  Color get lightBorder => Colors.grey[300]!;
  Color get lightInputFill => Colors.white;
  
  // Global colors (Dark Mode)
  Color get darkBackground => Colors.grey[850]!;
  Color get darkCardBackground => Colors.grey[800]!;
  Color get darkWidgetBackground => Colors.grey[700]!;
  Color get darkTextColor => Colors.white;
  Color get darkTextSecondary => Colors.grey[300]!;
  Color get darkBorder => Colors.grey[600]!;
  
  // Toggle button colors (Dark/Light mode in settings page)
  Color get switchActiveThumb => Colors.grey[800]!;
  Color get switchActiveTrack => Colors.grey[600]!;
  Color get switchInactiveThumb => Colors.white;
  Color get switchInactiveTrack => Colors.grey[300]!;

    // Circle colors (Main background)
  Color get primaryHeaderColor => _themeColor.withOpacity(0.8);
  Color get primaryHeaderOverlayColor => Colors.white.withOpacity(0.1);
  
  // Calendar colors
  Color get calendarSelectedDayColor => _themeColor;
  Color get calendarTodayColor => _themeColor.withOpacity(0.5);
  Color get calendarWeekendTextColor => _isDarkMode ? darkTextColor : lightTextColor;
  Color get calendarDefaultTextColor => _isDarkMode ? darkTextColor : lightTextColor;
  Color get calendarSelectedDayTextColor => _isDarkMode ? darkBackground : Colors.white;
  
  // Getters
  bool get isDarkMode => _isDarkMode;
  Color get themeColor => _themeColor;
  Color get currentBackground => _isDarkMode ? darkBackground : lightBackground;
  Color get currentCardBackground => _isDarkMode ? darkCardBackground : lightCardBackground;
  Color get currentTextColor => _isDarkMode ? darkTextColor : lightTextColor;
  Color get currentSecondaryTextColor => _isDarkMode ? darkTextSecondary : lightTextSecondary;
  Color get currentBorderColor => _isDarkMode ? darkBorder : lightBorder;
  Color get currentInputFill => _isDarkMode ? darkWidgetBackground : lightInputFill;

  ThemeData get themeData {
    return _isDarkMode ? _createTheme(true) : _createTheme(false);
  }

  ThemeData _createTheme(bool isDark) {
    final backgroundColor = isDark ? darkBackground : lightBackground;
    final cardBackground = isDark ? darkCardBackground : lightCardBackground;
    final textColor = isDark ? darkTextColor : lightTextColor;
    final secondaryTextColor = isDark ? darkTextSecondary : lightTextSecondary;
    final borderColor = isDark ? darkBorder : lightBorder;
    final inputFillColor = isDark ? darkWidgetBackground : lightInputFill;
    final appBarBgColor = isDark ? _themeColor.withOpacity(0.8) : _themeColor;
    
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primarySwatch: Colors.blue,
      primaryColor: _themeColor,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBgColor,
        titleTextStyle: TextStyle(color: lightTextColor, fontSize: 20),
        iconTheme: IconThemeData(color: lightTextColor),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: _themeColor,
        unselectedItemColor: lightTextColor,
        selectedLabelStyle: TextStyle(color: lightTextColor),
        unselectedLabelStyle: TextStyle(color: lightTextColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _themeColor,
          foregroundColor: lightTextColor,
        ),
      ),
      cardTheme: CardTheme(
        color: cardBackground,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor,
        hintStyle: TextStyle(color: secondaryTextColor),
        labelStyle: TextStyle(color: secondaryTextColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _themeColor),
        ),
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: textColor),
        bodyLarge: TextStyle(color: textColor),
      ),
    );
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setThemeColor(Color color) {
    _themeColor = color;
    notifyListeners();
  }
} 