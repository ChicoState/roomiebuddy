import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roomiebuddy/NavScreen.dart';
import 'package:roomiebuddy/login_screen.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';
import 'package:roomiebuddy/services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool isValidEmail = false;
  bool isLoading = false;
  String? errorMessage;
  bool _passwordsMatch = true;
  
  // Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
        : SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              Text(
                'Sign Up',
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
                      // Username field
                      TextFormField(
                        controller: _usernameController,
                        keyboardType: TextInputType.name,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          hintText: 'Enter username',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          return value!.isEmpty ? 'Please Enter Username' : null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Email field
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
                
                      const SizedBox(height: 20),
                
                      // Password field
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
                        onChanged: (value) {
                          if (_confirmPasswordController.text.isNotEmpty) {
                            _checkPasswordsMatch();
                          }
                        },
                        validator: (value){
                          return value!.isEmpty ? 'Please Enter Password' : null;
                        },
                      ),

                      const SizedBox(height: 20),
                
                      // Confirm Password field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        keyboardType: TextInputType.visiblePassword,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          hintText: 'Confirm your password',
                          prefixIcon: Icon(Icons.password),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _checkPasswordsMatch();
                        },
                        validator: (value){
                          return value!.isEmpty ? 'Please Confirm Password' : null;
                        },
                      ),

                      if (!_passwordsMatch) ...[
                        const SizedBox(height: 5),
                        Text(
                          'Passwords do not match',
                          style: TextStyle(
                            color: themeProvider.errorColor,
                          ),
                        ),
                      ],

                      if (errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          errorMessage!,
                          style: TextStyle(
                            color: themeProvider.errorColor,
                          ),
                        ),
                      ],

                      const SizedBox(height: 30),

                      // SIGNUP BUTTON
                      MaterialButton(
                        minWidth: double.infinity,
                        onPressed: _handleSignup,
                        color: themeProvider.themeColor,
                        textColor: themeProvider.currentTextColor,
                        child: const Text('Sign Up'),
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // LOGIN LINK
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginScreen())
                          );
                        },
                        child: Text(
                          'Already have an account? Login',
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
          ),
        )
    );
  }

  void _checkEmail(String value) {
    setState(() {
      isValidEmail = EmailValidator.validate(value.trim());
    });
  }

  void _checkPasswordsMatch() {
    setState(() {
      _passwordsMatch = _passwordController.text == _confirmPasswordController.text;
    });
  }
  
  Future<void> _saveUserData(String userId, String username, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('username', username);
    await prefs.setString('email', email);
    await prefs.setString('password', password);
  }
  
  Future<void> _handleSignup() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    
    // Basic validations
    if (username.isEmpty) {
      setState(() => errorMessage = 'Username is required');
      return;
    }
    
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

    if (confirmPassword.isEmpty) {
      setState(() => errorMessage = 'Please confirm your password');
      return;
    }
    
    if (password != confirmPassword) {
      setState(() => errorMessage = 'Passwords do not match');
      return;
    }
    
    // Show loading indicator
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    // Call signup API
    final result = await AuthService.signup(
      username: username,
      email: email,
      password: password,
    );
    
    setState(() => isLoading = false);
    
    if (result['success']) {
      // Save user data to SharedPreferences
      await _saveUserData(result['user_id'], username, email, password);
      
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