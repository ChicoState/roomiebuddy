import 'package:flutter/material.dart';
import 'package:roomiebuddy/pages/subpages/home/task_detail_page.dart';

class TaskSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> tasks;
  TaskSearchDelegate({required this.tasks});

  @override
  List<Widget> buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) {
    final results = tasks
        .where((task) =>
            task['taskName'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(results[index]['taskName']),
        subtitle: Text('Assigned by: ${results[index]['assignedBy']}'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(task: results[index]),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
} 