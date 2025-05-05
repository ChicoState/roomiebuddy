import 'package:flutter/material.dart';
import 'package:roomiebuddy/services/api_service.dart';
import 'package:roomiebuddy/services/auth_storage.dart';

class GroupDetailScreen extends StatelessWidget {
  final Map<String, dynamic> group;

  const GroupDetailScreen({
    super.key,
    required this.group,
  });

  @override
  // ----- Group Detail Page ----- //
  Widget build(BuildContext context) {
    final List<dynamic> membersData = group['members'] ?? [];
    final List<String> memberNames = membersData
        .map((member) => member['username'] as String? ?? 'Unknown')
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(group['group_name'] ?? 'Group Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Group Name: ${group['group_name'] ?? 'Unnamed Group'}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 20),
            const Text("Members:", style: TextStyle(fontSize: 20)),
            ...memberNames.map((name) => Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  child: Text("- $name"),
                )),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () => _showLeaveGroupConfirmation(context),
                child: const Text('Leave Group'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----- Leave Group Confirmation ----- //
  void _showLeaveGroupConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Leave Group'),
          content: Text('Are you sure you want to leave "${group['group_name'] ?? 'this group'}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _leaveGroup(context);
              },
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
  }

  // ----- Leave Group (Backend Communication) ----- //
  Future<void> _leaveGroup(BuildContext context) async {
    final AuthStorage authStorage = AuthStorage();
    final ApiService apiService = ApiService();

    try {
      final userId = await authStorage.getUserId();
      final password = await authStorage.getPassword();

      if (!context.mounted) return;

      if (userId == null || password == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to leave the group.')),
        );
        return;
      }

      // Try to find group ID from various possible fields
      final String? groupId = group['group_id'] ?? group['uuid'] ?? group['id'];
      if (groupId == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group ID not found.')),
        );
        return;
      }

      final response = await apiService.leaveGroup(userId, password, groupId);

      if (!context.mounted) return;

      // Check for success directly from the Map response
      final bool isSuccess = response['success'] == true;

      if (isSuccess) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully left the group.')),
        );

        // Pop to home page and signal success (true)
        Navigator.pop(context, true);
      } else {
        // Get error message directly from the Map response
        final String errorMsg = response['message'] as String? ?? 'Unknown error leaving group';

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave group: $errorMsg')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error leaving group: $e')),
      );
    }
  }
} 