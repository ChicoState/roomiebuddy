import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  Color _themeColor = Colors.greenAccent;
  
  // Global color constants - Light Mode
  Color get lightBackground => Colors.white;
  Color get lightCardBackground => Colors.white;
  Color get lightTextColor => Colors.black;
  Color get lightTextSecondary => Colors.grey[700]!;
  Color get lightBorder => Colors.grey[300]!;
  Color get lightInputFill => Colors.white;
  
  // Global color constants - Dark Mode
  Color get darkBackground => Colors.grey[850]!;
  Color get darkCardBackground => Colors.grey[800]!;
  Color get darkWidgetBackground => Colors.grey[700]!;
  Color get darkTextColor => Colors.white;
  Color get darkTextSecondary => Colors.grey[300]!;
  Color get darkBorder => Colors.grey[600]!;
  
  // Utility colors that don't change with theme
  Color get errorColor => Colors.red;
  Color get warningColor => Colors.orange;
  Color get successColor => Colors.green;
  
  // Switch colors
  Color get switchActiveThumb => Colors.grey[800]!;
  Color get switchActiveTrack => Colors.grey[600]!;
  Color get switchInactiveThumb => Colors.white;
  Color get switchInactiveTrack => Colors.grey[300]!;
  
  // Getters for theme state
  bool get isDarkMode => _isDarkMode;
  Color get themeColor => _themeColor;
  
  // Current theme-dependent colors (for widgets to easily access)
  Color get currentBackground => _isDarkMode ? darkBackground : lightBackground;
  Color get currentCardBackground => _isDarkMode ? darkCardBackground : lightCardBackground;
  Color get currentTextColor => _isDarkMode ? darkTextColor : lightTextColor;
  Color get currentSecondaryTextColor => _isDarkMode ? darkTextSecondary : lightTextSecondary;
  Color get currentBorderColor => _isDarkMode ? darkBorder : lightBorder;
  Color get currentInputFill => _isDarkMode ? darkWidgetBackground : lightInputFill;

  ThemeData get themeData {
    return _isDarkMode ? _darkTheme : _lightTheme;
  }

  ThemeData get _lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      primaryColor: _themeColor,
      scaffoldBackgroundColor: lightBackground,
      canvasColor: lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: _themeColor,
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
        color: lightCardBackground,
      ),
      // Light mode input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightInputFill,
        hintStyle: TextStyle(color: lightTextSecondary),
        labelStyle: TextStyle(color: lightTextSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _themeColor),
        ),
      ),
    );
  }

  ThemeData get _darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      primaryColor: _themeColor,
      scaffoldBackgroundColor: darkBackground,
      canvasColor: darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: _themeColor.withOpacity(0.8),
        titleTextStyle: TextStyle(color: lightTextColor, fontSize: 20), // Using light text for contrast
        iconTheme: IconThemeData(color: lightTextColor),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: _themeColor,
        unselectedItemColor: lightTextColor, // Using light text for contrast
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
        color: darkCardBackground,
      ),
      // Dark mode input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkWidgetBackground, 
        hintStyle: TextStyle(color: darkTextSecondary), 
        labelStyle: TextStyle(color: darkTextSecondary), 
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _themeColor),
        ),
      ),
      // Ensure text is white in dark mode
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: darkTextColor),
        bodyLarge: TextStyle(color: darkTextColor),
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