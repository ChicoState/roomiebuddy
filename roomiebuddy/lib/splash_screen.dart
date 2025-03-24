import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roomiebuddy/login_screen.dart';
// import 'package:myapp/main.dart';

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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()));
    });
  }


  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(179, 221, 249, 230), Colors.greenAccent], 
            begin: Alignment.topRight,
            end: Alignment.bottomLeft)),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Roomie Buddy',
            style: TextStyle(color: Colors.black, fontSize: 42),
          )
        ]),
      ),
    );
  }
}