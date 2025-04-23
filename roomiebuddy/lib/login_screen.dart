import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roomiebuddy/NavScreen.dart';
import 'package:roomiebuddy/signup_screen.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';
import 'package:roomiebuddy/services/auth_service.dart';
import 'package:roomiebuddy/services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isValidEmail = false;
  bool isLoading = false;
  String? errorMessage;
  
  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roomie Buddy'),
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator(color: themeProvider.themeColor))
        : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            Text(
              'Login',
              style: TextStyle(
                fontSize: 35,
                color: themeProvider.currentSecondaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Form(
                child: Column(
                  children: [
                    
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      
                      onChanged: (String value){
                        _checkEmail(value);
                      },
                      validator: (value){
                        return value!.isEmpty ? 'Please Enter Email' : null;
                      },
                    ),

                    Text(
                      (_emailController.text.trim().isEmpty || isValidEmail) ? '' : 'Email is not valid',
                      style: TextStyle(
                        color: themeProvider.errorColor,
                      ),
                    ),
              
                    const SizedBox(height: 20,),
              
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter Password',
                        prefixIcon: Icon(Icons.password),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value){
                        return value!.isEmpty ? 'Please Enter Password' : null;
                      },
                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: themeProvider.errorColor,
                        ),
                      ),
                    ],

                    const SizedBox(height: 30,),

                    //LOGIN BUTTON
                    MaterialButton(
                      minWidth: double.infinity,
                      onPressed: _handleLogin,
                      color: themeProvider.themeColor,
                      textColor: themeProvider.currentTextColor,
                      child: const Text('Login'),
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // SIGNUP LINK
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const SignupScreen())
                        );
                      },
                      child: Text(
                        'Don\'t have an account? Sign Up',
                        style: TextStyle(
                          color: themeProvider.themeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
    );
  }

  void _checkEmail(String value) {
    setState(() {
      isValidEmail = EmailValidator.validate(value.trim());
    });
  }
  
  Future<void> _saveUserData(String userId, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('email', email);
    await prefs.setString('password', password);
    
    // Try to fetch the username if available, or fallback to email username part
    try {
      final username = email.split('@')[0];
      await prefs.setString('username', username);
    } catch (e) {
      debugPrint('Error extracting username from email: $e');
    }
  }
  
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    // Basic validations
    if (email.isEmpty) {
      setState(() => errorMessage = 'Email is required');
      return;
    }
    
    if (!isValidEmail) {
      setState(() => errorMessage = 'Please enter a valid email');
      return;
    }
    
    if (password.isEmpty) {
      setState(() => errorMessage = 'Password is required');
      return;
    }
    
    // Show loading indicator
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    // Call login API
    final result = await AuthService.login(
      email: email,
      password: password,
    );
    
    setState(() => isLoading = false);
    
    if (result['success']) {
      // Save user data to SharedPreferences
      await _saveUserData(result['user_id'], email, password);
      
      // Now also update UserService with the extracted username
      final username = email.split('@')[0];
      await UserService.updateUserData(
        userId: result['user_id'],
        password: password,
        userName: username,
      );
      
      // Navigate to main app on success
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const Navscreen())
        );
      }
    } else {
      // Show error message
      setState(() => errorMessage = result['message']);
    }
  }
}