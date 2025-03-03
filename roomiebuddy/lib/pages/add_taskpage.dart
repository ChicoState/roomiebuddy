import 'package:flutter/material.dart';

class AddTaskpage extends StatefulWidget {
  const AddTaskpage({super.key});

  @override
  State<AddTaskpage> createState() => _AddTaskpageState();
}

class _AddTaskpageState extends State<AddTaskpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("AddTaskPage"),
      )
    );
  }
}