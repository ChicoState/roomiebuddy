import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:roomiebuddy/NavScreen.dart';
import 'package:roomiebuddy/pages/login_screen.dart';
// import 'package:myapp/main.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:provider/provider.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin{
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    Future.delayed(const Duration(seconds: 3), () {
      screenJump();
    });
  }

  void screenJump(){
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen())); //GO TO LOGIN
  }

  @override
  Widget build(BuildContext context){
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [themeProvider.currentBackground, themeProvider.themeColor], 
            begin: Alignment.topRight,
            end: Alignment.bottomLeft)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //Text(
            //'Roomie Buddy',
            //style: TextStyle(color: Colors.black, fontSize: 42, fontWeight: FontWeight.bold),
          //)

          AnimatedTextKit(
            animatedTexts: [
              FadeAnimatedText(
                'Roomie Buddy',
                textStyle: TextStyle(
                  fontSize: 32.0, 
                  fontWeight: FontWeight.bold,
                  color: themeProvider.currentTextColor
                ),
                duration: const Duration(milliseconds: 2000),
              ),
            ],
          ),

        ]),
      ),
    );
  }
}