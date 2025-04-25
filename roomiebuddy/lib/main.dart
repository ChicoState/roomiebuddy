import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomiebuddy/pages/login_screen.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Roomie Buddy',
      theme: themeProvider.themeData,
      home: const LoginScreen(clearCredentials: false), // Set to false to enable "remember me" functionality
    );
  }
}
      