import 'package:flutter/material.dart';
import '../containers/primary_header_container.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedCategory = 'Today'; // Tracks selected category

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TPrimaryHeaderContainer(
              child: Container(),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'My Tasks',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
            ),
            _buildTaskCategories(),
            _buildGroupSection(),
          ],
        ),
      ),
    );
  }

  // Task category selector with oval design
  Widget _buildTaskCategories() {
    final categories = ['Today', 'Upcoming', 'Completed'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: categories.map((title) {
          bool isSelected = _selectedCategory == title;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = title;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.green,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Placeholder for Group Section (will be filled in later)
  Widget _buildGroupSection() {
    return Container(); // Empty for now
  }

  Widget displayTasks(){
    return Container();
  }
}

