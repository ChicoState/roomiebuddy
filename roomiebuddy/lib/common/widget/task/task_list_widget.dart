import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';
import 'package:roomiebuddy/pages/subpages/home/task_detail_page.dart';

class TaskListWidget extends StatelessWidget {
  // --- State Variables --- //
  final List<Map<String, dynamic>> allTasks;
  final String? focusedGroupId;
  final Set<String> userGroupIds;
  final List<Map<String, dynamic>> roommateGroups;
  final VoidCallback onTaskActionCompleted;
  final bool showOnlyMyTasks;
  final String? currentUserId;

  // --- Constructor --- //

  const TaskListWidget({
    super.key,
    required this.allTasks,
    required this.focusedGroupId,
    required this.userGroupIds,
    required this.roommateGroups,
    required this.onTaskActionCompleted,
    required this.showOnlyMyTasks,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Create the content to display inside the container
    Widget content;
    
    // If there are no tasks, show a message
    if (allTasks.isEmpty) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No tasks!',
            style: TextStyle(color: themeProvider.currentSecondaryTextColor, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      // Filter tasks based on the focused group ID
      List<Map<String, dynamic>> filteredTasks = allTasks.where((task) {
        final String? groupId = task["group_id"] as String?;

        // Show tasks for the focused group if one is selected
        if (focusedGroupId != null) {
          return groupId == focusedGroupId;
        }

        // If no group is focused, show tasks that either have no group ID
        // or belong to any of the user's groups.
        return groupId == null || groupId == "0" || userGroupIds.contains(groupId);
      }).toList();

      // Further filter by assigned user if the flag is set
      if (showOnlyMyTasks && currentUserId != null) {
        filteredTasks = filteredTasks.where((task) {
          // Keep tasks where assignee_id matches the current user ID
          return task['assignee_id'] == currentUserId;
        }).toList();
      }

      // If no tasks are found with the current filter display a message
      if (filteredTasks.isEmpty) {
        content = Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              showOnlyMyTasks
                  ? 'No tasks assigned specifically to you${focusedGroupId != null ? ' in this group' : ''}.'
                  : 'No tasks found${focusedGroupId != null ? ' for this group' : ''}.',
              style: TextStyle(color: themeProvider.currentSecondaryTextColor, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        );
      } else {
        // If there are tasks, display them
        content = ListView.builder(
          shrinkWrap: true,
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            final task = filteredTasks[index];
            String groupName = 'Unknown Group'; // Default group name

            // Find the group name if focusedGroupId is null (showing all groups)
            if (focusedGroupId == null && task['group_id'] != null) {
              final group = roommateGroups.firstWhere(
                (g) => g['group_id'] == task['group_id'],
                orElse: () => {'group_name': 'Unknown Group'}
              );
              groupName = group['group_name'] ?? 'Unknown Group';
            }

            // Return a card for each task
            return Card(
              margin: EdgeInsets.only(bottom: index < filteredTasks.length - 1 ? 12 : 0),
              color: themeProvider.currentBackground,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                title: Text(task['taskName'], 
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: themeProvider.currentTextColor
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Show group name when displaying tasks from multiple groups (like in calendar)
                          if (focusedGroupId == null && task['group_id'] != null) ...[
                            Text('Group: $groupName', style: TextStyle(color: themeProvider.currentSecondaryTextColor)),
                            const SizedBox(height: 2),
                          ],
                          // Always show assigned by
                          Text('Assigned by: ${task['assignedBy']}', style: TextStyle(color: themeProvider.currentSecondaryTextColor)),
                          
                          if (!showOnlyMyTasks) ...[
                            const SizedBox(height: 2),
                            Text('For: ${task['assignedTo']}', style: TextStyle(color: themeProvider.currentSecondaryTextColor)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: task['priority'] == 'High' 
                        ? themeProvider.errorColor.withAlpha(40)
                        : task['priority'] == 'Medium'
                            ? themeProvider.warningColor.withAlpha(40)
                            : themeProvider.successColor.withAlpha(40),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task['priority'],
                    style: TextStyle(
                      color: task['priority'] == 'High'
                          ? themeProvider.errorColor
                          : task['priority'] == 'Medium'
                              ? themeProvider.warningColor
                              : themeProvider.successColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskDetailScreen(task: task),
                    ),
                  );
                  if (result == true && context.mounted) {
                    onTaskActionCompleted();
                  }
                },
              ),
            );
          },
        );
      }
    }

    // Return the styled container with the content
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeProvider.currentInputFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: content,
    );
  }
} 