import 'package:flutter/material.dart';

class AddRoomatePage extends StatefulWidget {
  const AddRoomatePage({super.key});

  @override
  State<AddRoomatePage> createState() => _AddRoomatePageState();
}

class _AddRoomatePageState extends State<AddRoomatePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("AddRoomatePage"),
      )
    );
  }
}