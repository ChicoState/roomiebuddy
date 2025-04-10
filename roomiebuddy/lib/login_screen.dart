//import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:provider/provider.dart';
import 'package:roomiebuddy/NavScreen.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  bool isValidEmail = false;
  TextEditingController controller = TextEditingController();//EMAIL VALIDATOR

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roomie Buddy'),
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
              child: Column(
                children: [
                  
                  TextFormField(
                    controller: controller, //EMAIL VALIDATOR
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'email',
                      hintText: 'Enter email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    
                    onChanged: (String value){
                      _checkEmail(value);
                      //MIGHT NEED LATER
                    },
                    validator: (value){
                      return value!.isEmpty ? 'Please Enter Email' : null;
                    },
                  ),

                  Text(
                    isValidEmail? '':'Email is not valid',
                    style: TextStyle(
                      color: themeProvider.errorColor,
                    ),
                  ),
            
                  const SizedBox(height: 20,),
            
                  TextFormField(
                    keyboardType: TextInputType.visiblePassword,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter Password',
                      prefixIcon: Icon(Icons.password),
                      border: OutlineInputBorder(),
                    ),
                    
                    onChanged: (String value){
                      //MIGHT NEED LATER
                    },
                    validator: (value){
                      return value!.isEmpty ? 'Please Enter Password' : null;
                    },
                  ),

                  const SizedBox(height: 30,),

                  //LOGIN BUTTON
                  MaterialButton(
                    minWidth: double.infinity,
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const Navscreen()));
                    },
                    color: themeProvider.themeColor,
                    textColor: themeProvider.currentTextColor,
                    child: const Text('Login'),
                  )

                ],
              ),
            ),
          ),

        ],
      )
    );
  }

//WIP
  void _checkEmail(String value) {
    setState(() {
      //controller.text.trim()
      isValidEmail = EmailValidator.validate(value.trim());
    });
  }
}