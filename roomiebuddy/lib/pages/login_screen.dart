//import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:provider/provider.dart';
import 'package:roomiebuddy/NavScreen.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';
import 'package:roomiebuddy/pages/signup_screen.dart';
import 'package:roomiebuddy/services/api_service.dart';
import 'package:roomiebuddy/services/auth_storage.dart';

class LoginScreen extends StatefulWidget {
  final bool clearCredentials;
  
  const LoginScreen({
    super.key, 
    this.clearCredentials = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isValidEmail = false;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _checkingAuth = true;

  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  @override
  void initState() {
    super.initState();
    
    if (widget.clearCredentials) {
      _clearCredentialsAndReset();
    } else {
      _checkExistingLogin();
    }
  }
  

  Future<void> _clearCredentialsAndReset() async {
    setState(() {
      _checkingAuth = true;
    });
    
    await _authStorage.clearUserCredentials();
    
    setState(() {
      _checkingAuth = false;
    });
  }

  // When the app is opened, check if the user has credentials saved already
  // If so, it automatically navigates to the main screen
  Future<void> _checkExistingLogin() async {
    setState(() {
      _checkingAuth = true;
    });
    
    try {
      final isLoggedIn = await _authStorage.isLoggedIn();
      debugPrint("Is logged in check result: $isLoggedIn");
      
      if (isLoggedIn) {
        // Get stored credentials
        final userId = await _authStorage.getUserId();
        
        if (userId != null && userId.isNotEmpty) {
          _navigateToMainScreen();
        } else {
          await _authStorage.clearUserCredentials();
        }
      }
    } catch (e) {
      debugPrint("Error checking login: $e");
    } finally {
      setState(() {
        _checkingAuth = false;
      });
    }
  }
  
  // If not, it shows the login screen and the user can login
  Future<void> _loginUser() async {
    setState(() {
      _errorMessage = '';
    });
    
    if (!_formKey.currentState!.validate() || !isValidEmail) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Call login API
      final result = await _apiService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      
      // Handle result
      if (result['success']) {
        // Extract user ID from the response
        final String userId = result['data']['user_id'];
        final String username = result['data']['username'];
        
        // Store credentials for future use
        await _authStorage.storeUserCredentials(
          userId,
          emailController.text.trim(),
          passwordController.text.trim(),
          username,
        );
        
        // Navigate to main screen
        _navigateToMainScreen();
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'An unknown error occurred.'; 
        });
      }
    } catch (e) {
      // Handle exceptions
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
      debugPrint('Login error: $e');
    } finally {
      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Show loading indicator while checking authentication
    if (_checkingAuth) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: themeProvider.themeColor,
          ),
        ),
      );
    }
    
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
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
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
                    (emailController.text.trim().isNotEmpty && !isValidEmail) ? 'Email is not valid' : '',
                    style: TextStyle(
                      color: themeProvider.errorColor,
                    ),
                  ),
            
                  const SizedBox(height: 20,),
            
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: const InputDecoration(
                      hintText: 'Enter Password',
                      prefixIcon: Icon(Icons.password),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value){
                      return value!.isEmpty ? 'Please Enter Password' : null;
                    },
                  ),

                  const SizedBox(height: 10),
                  
                  // Display error message if there is one
                  if (_errorMessage.isNotEmpty)
                    Text(
                      _errorMessage,
                      style: TextStyle(
                        color: themeProvider.errorColor,
                      ),
                    ),

                  const SizedBox(height: 20),

                  // LOGIN BUTTON
                  _isLoading
                      ? const CircularProgressIndicator()
                      : MaterialButton(
                          minWidth: double.infinity,
                          onPressed: _loginUser,
                          color: themeProvider.themeColor,
                          textColor: themeProvider.currentTextColor,
                          child: const Text('Login'),
                        ),
                  
                  const SizedBox(height: 15,),
                  
                  // Link to signup screen
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account?',
                        style: TextStyle(
                          color: themeProvider.currentSecondaryTextColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const SignupScreen())
                          );
                        },
                        child: Text(
                          'Sign Up',
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
      )
    );
  }

  void _checkEmail(String value) {
    setState(() {
      isValidEmail = EmailValidator.validate(value.trim());
    });
  }

  void _navigateToMainScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const Navscreen()),
    );
  }
}