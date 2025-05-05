import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true; // Dark mode set to default
  Color _themeColor = Colors.blueGrey; // Global theme color

  // Utility colors (Theme independent)
  Color get errorColor => Colors.red;
  Color get warningColor => Colors.orange;
  Color get successColor => Colors.green;
  
  // Global colors (Light Mode)
  Color get lightBackground => Colors.grey[300]!;
  Color get lightCardBackground => Colors.grey[50]!;
  Color get lightTextColor => Colors.black;
  Color get lightTextSecondary => Colors.grey[700]!;
  Color get lightBorder => Colors.grey[300]!;
  Color get lightInputFill => Colors.grey[100]!;
  
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
  Color get primaryHeaderColor => _themeColor.withAlpha(204);
  Color get primaryHeaderOverlayColor => Colors.white.withAlpha(26);
  
  // Calendar colors
  Color get calendarSelectedDayColor => _themeColor;
  Color get calendarTodayColor => _themeColor.withAlpha(128);
  Color get calendarWeekendTextColor => _isDarkMode ? darkTextColor : lightTextColor;
  Color get calendarDefaultTextColor => _isDarkMode ? darkTextColor : lightTextColor;
  Color get calendarSelectedDayTextColor => _isDarkMode ? darkBackground : Colors.white;
  
  // Getters
  bool get isDarkMode => _isDarkMode;
  Color get themeColor => _themeColor;
  Color get currentBackground => _isDarkMode ? darkBackground : lightBackground;
  Color get currentCardBackground => _isDarkMode ? darkCardBackground : lightBackground;
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
    final appBarBgColor = isDark ? _themeColor.withAlpha(204) : _themeColor;
    
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primarySwatch: Colors.blue,
      primaryColor: _themeColor,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBgColor,
        titleTextStyle: TextStyle(color: textColor, fontSize: 20),
        iconTheme: IconThemeData(color: textColor),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: _themeColor,
        unselectedItemColor: textColor,
        selectedLabelStyle: TextStyle(color: textColor),
        unselectedLabelStyle: TextStyle(color: textColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _themeColor,
          foregroundColor: textColor,
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