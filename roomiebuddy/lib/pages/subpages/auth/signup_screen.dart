import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:provider/provider.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';
import 'package:roomiebuddy/pages/subpages/auth/login_screen.dart';
import 'package:roomiebuddy/services/api_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool isValidEmail = false;
  bool passwordsMatch = true;
  bool _isLoading = false;
  String _errorMessage = '';

  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Roomie Buddy',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeProvider.currentTextColor,
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
              key: _formKey,
              child: Column(
                children: [
                  // Username field
                  TextFormField(
                    controller: usernameController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
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
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Enter email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (String value) {
                      _checkEmail(value);
                    },
                    validator: (value) {
                      return value!.isEmpty ? 'Please Enter Email' : null;
                    },
                  ),
                  
                  Text(
                    (emailController.text.trim().isNotEmpty && !isValidEmail) ? 'Email is not valid' : '',
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Password field
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: const InputDecoration(
                      hintText: 'Enter Password',
                      prefixIcon: Icon(Icons.password),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (String value) {
                      _checkPasswords();
                    },
                    validator: (value) {
                      return value!.isEmpty ? 'Please Enter Password' : null;
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Confirm Password field
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: const InputDecoration(
                      hintText: 'Confirm Password',
                      prefixIcon: Icon(Icons.password),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (String value) {
                      _checkPasswords();
                    },
                    validator: (value) {
                      return value!.isEmpty ? 'Please Confirm Password' : null;
                    },
                  ),
                  
                  Text(
                    passwordsMatch ? '' : 'Passwords do not match',
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Display error message if there is one
                  if (_errorMessage.isNotEmpty)
                    Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                  
                  // Signup Button
                  _isLoading
                      ? const CircularProgressIndicator()
                      : MaterialButton(
                          minWidth: double.infinity,
                          onPressed: _registerUser,
                          color: themeProvider.themeColor,
                          textColor: themeProvider.currentTextColor,
                          child: const Text('Sign Up'),
                        ),
                  
                  const SizedBox(height: 15),
                  
                  // Link to login screen
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: TextStyle(
                          color: themeProvider.currentSecondaryTextColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginScreen())
                          );
                        },
                        child: Text(
                          'Login',
                          style: TextStyle(
                            color: themeProvider.themeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _checkEmail(String value) {
    setState(() {
      isValidEmail = EmailValidator.validate(value.trim());
    });
  }

  void _checkPasswords() {
    setState(() {
      passwordsMatch = passwordController.text == confirmPasswordController.text;
    });
  }
  
  Future<void> _registerUser() async {
    setState(() {
      _errorMessage = '';
    });
    
    if (!_formKey.currentState!.validate() || !isValidEmail || !passwordsMatch) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Call signup API
      final result = await _apiService.signup(
        usernameController.text.trim(),
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      
      if (!mounted) return;
      
      // Handle result
      if (result['success']) {
        // Show success message and navigate to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
          ),
        );
        
        // Navigate to login screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        // Show error message
        setState(() {
          _errorMessage = result['message'] ?? 'Registration failed. Please try again.';
        });
      }
    } catch (e) {
      // Handle exceptions
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
      debugPrint('Registration error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 