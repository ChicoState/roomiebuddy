import 'package:flutter/material.dart';
import 'package:roomiebuddy/services/api_service.dart';
import 'package:roomiebuddy/services/auth_storage.dart';

class TaskDetailScreen extends StatelessWidget {
  final Map<String, dynamic> task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  // ----- Task Detail Page ----- //
  Widget build(BuildContext context) {
    final String? photoPath = task['photo'];
    final String imageUrl = _getImageUrl(photoPath ?? '');
    return Scaffold(
      appBar: AppBar(title: Text(task['taskName'])),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 12),
                Text("Description: ${task['description']?.isNotEmpty == true ? task['description'] : 'Not specified'}"),
                const SizedBox(height: 12),
                Text("Priority: ${task['priority']}",),
                const SizedBox(height: 12),
                Text("Assigned by: ${task['assignedBy']}",),
                Text("Assigned to: ${task['assignedTo']}",),
                const SizedBox(height: 12),
                Text("Due Date: ${task['dueDate'] ?? 'Not specified'}"),
                Text("Time Due: ${task['dueTime'] ?? 'Not specified'}"),
                const SizedBox(height: 12),
                Text("Estimated Duration: ${task['estimatedDuration'] ?? 'Not specified'}"),
                const SizedBox(height: 12),
                Text("Recurrence: ${task['recurrence'] ?? 'Not specified'}"),
              ],
            ),
            if (imageUrl !=  ' ') ...[
              const SizedBox(height: 30),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: 250,
                    height: 250,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.red.withAlpha(40),
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () => _showDeleteConfirmation(context),
                child: const Text('Delete Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getImageUrl(String imagePath) {
    // The backend stores filenames like "data/images/file.jpg"
    // Extract just the filename
    final filename = imagePath.split('/').last;
    
    // Construct the full URL to the image
    return '${ApiService.baseUrl}/data/images/$filename';
  }

  // ----- Delete Task Confirmation ----- //
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: Text('Are you sure you want to delete "${task['taskName']}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteTask(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // ----- Delete Task (Backend Communication) ----- //
  Future<void> _deleteTask(BuildContext context) async {
    final AuthStorage authStorage = AuthStorage();
    final ApiService apiService = ApiService();

    try {
      final userId = await authStorage.getUserId();
      final password = await authStorage.getPassword();
      final taskId = task['id'] as String?;

      if ((userId == null || password == null)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to delete the task.')),
        );
        return;
      }
      if (taskId == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task ID not found.')),
        );
        return;
      }

      final response = await apiService.deleteTask(userId, password, taskId);

      if (!context.mounted) return;

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted successfully.')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete task: ${response['message']}')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting task: $e')),
      );
    }
  }
} 