import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';
import 'package:roomiebuddy/common/widget/group_detail_sheet.dart';
import 'package:roomiebuddy/services/user_service.dart';
import 'package:roomiebuddy/common/utils/data_operations.dart';

class AddRoomatePage extends StatefulWidget {
  const AddRoomatePage({super.key});

  @override
  State<AddRoomatePage> createState() => _AddRoomatePageState();
}

class _AddRoomatePageState extends State<AddRoomatePage> {
  bool _isLoading = true;
  
  // List of groups the user is in
  List<Map<String, dynamic>> _userGroups = [];
  
  // Create separate controllers for each text field
  final TextEditingController _inviteUserController = TextEditingController();
  final TextEditingController _joinGroupController = TextEditingController();
  final TextEditingController _createGroupNameController = TextEditingController();
  final TextEditingController _createGroupDescController = TextEditingController();

  // Placeholder for when API is implemented
  bool hasRequests = false;
  List<Map<String, String>> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    
    try {
      // Initialize UserService
      await UserService.initialize();
      
      // Load group data if user is logged in
      if (UserService.isLoggedIn) {
        await _loadGroupData();
      } else {
        setState(() => _isLoading = false);
      }
      
      // Request data would be loaded from an API in a real implementation
      setState(() {
        _pendingRequests = [];
        hasRequests = _pendingRequests.isNotEmpty;
      });
    } catch (e) {
      debugPrint('Error initializing data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGroupData() async {
    try {
      final userGroups = await DataOperations.loadUserGroups();
      
      setState(() {
        _userGroups = userGroups;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading group data: $e');
      setState(() {
        _userGroups = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _createGroup() async {
    if (_createGroupNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name'))
      );
      return;
    }

    // Check if user is logged in first
    if (!UserService.isLoggedIn) {
      // Try to reinitialize the UserService
      await UserService.initialize();
      
      // Check again after initialization
      if (!UserService.isLoggedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to create a group. Please logout and login again.'))
        );
        return;
      }
    }

    try {
      setState(() => _isLoading = true);
      
      final result = await DataOperations.createGroup(
        groupName: _createGroupNameController.text,
        description: _createGroupDescController.text,
      );
      
      setState(() => _isLoading = false);
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group "${_createGroupNameController.text}" created successfully!'))
        );
        
        // Clear the form
        _createGroupNameController.clear();
        _createGroupDescController.clear();
        
        // Refresh group data
        await _loadGroupData();
      } else {
        String errorMessage = result['message'] ?? 'Unknown error';
        
        // Provide more specific feedback for common errors
        if (errorMessage.contains('User not logged in')) {
          errorMessage = 'You need to be logged in to create a group. Please logout and login again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: $errorMessage'))
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating group: $e'))
      );
    }
  }

  Future<void> _leaveGroup(String groupId, String groupName) async {
    // Confirm with the user
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave "$groupName"?'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!shouldLeave) return;
    
    try {
      final result = await DataOperations.leaveGroup(groupId);
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Left group "$groupName" successfully')),
        );
        
        // Refresh group data
        await _loadGroupData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave group: ${result['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error leaving group: $e')),
      );
    }
  }

  // Helper method to shorten user ID for display
  String _getShortenedID(String id) {
    if (id.length <= 20) return id;
    return "${id.substring(0, 20)}...";
  }

  @override
  void dispose() {
    // Clean up controllers when the widget is disposed
    _inviteUserController.dispose();
    _joinGroupController.dispose();
    _createGroupNameController.dispose();
    _createGroupDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Add Roommate',
            style: TextStyle(
              color: themeProvider.isDarkMode ? themeProvider.darkTextColor : themeProvider.lightTextColor
            ),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(color: themeProvider.themeColor),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Roommate',
          style: TextStyle(
            color: themeProvider.isDarkMode ? themeProvider.darkTextColor : themeProvider.lightTextColor
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------------------- Profile Name & acc# -------------------- //
              _buildSectionTitle('About You', themeProvider),
              const SizedBox(height: 12),
              
              // Username
              _buildInfoRow('Username:', UserService.userName ?? "User", null, themeProvider),
              const SizedBox(height: 8),
              
              // User ID with copy button - showing shortened version
              _buildInfoRow(
                'User ID:', 
                _getShortenedID(UserService.userId ?? ""), 
                UserService.userId?.isNotEmpty == true ? () {
                  Clipboard.setData(ClipboardData(text: UserService.userId ?? ""));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User ID copied to clipboard')),
                  );
                } : null,
                themeProvider
              ),

              const SizedBox(height: 24),

                            // -------------------- Join Group -------------------- //
              _buildSectionTitle('Join Group', themeProvider),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _joinGroupController,
                      'Roomie Buddy Group ID',
                      TextInputType.number,
                      themeProvider,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildActionButton('Request Join', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Request Join button pressed, not implemented yet'))
                    );
                  }, themeProvider),
                ],
              ),
              const SizedBox(height: 24),

              // -------------------- Create Group -------------------- //
              _buildSectionTitle('Create Group', themeProvider),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _createGroupNameController,
                      'Group Name',
                      TextInputType.text,
                      themeProvider,
              ),
                  ),
                  const SizedBox(width: 10),
                  _buildActionButton('Create Group', () {
                    _createGroup();
                  }, themeProvider),
                ],
              ),
              const SizedBox(height: 24),

              // -------------------- Add Roomate -------------------- //
              _buildSectionTitle('Add Roommate', themeProvider),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _inviteUserController,
                      'Roomie Buddy User ID',
                      TextInputType.number,
                      themeProvider,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildActionButton('Invite', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite button pressed, not implemented yet'))
                    );
                  }, themeProvider),
                ],
              ),
              const SizedBox(height: 24),


              // -------------------- Pending Requests -------------------- //
              _buildSectionTitle('Pending Requests', themeProvider),
              const SizedBox(height: 12),
              
              if (hasRequests) ...[
                for (final request in _pendingRequests) ...[
                  _buildRequestCard(request['text'] ?? '', themeProvider),
                  const SizedBox(height: 8),
                ]
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No pending join requests or invites at this time.',
                    style: TextStyle(
                      color: themeProvider.currentSecondaryTextColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
                            // -------------------- Group Specs -------------------- //
              _buildSectionTitle('Current Groups', themeProvider),
              const SizedBox(height: 12),
              
              if (_userGroups.isEmpty) 
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'You are not in any groups. Create or join a group below.',
                    style: TextStyle(
                      color: themeProvider.currentSecondaryTextColor,
                      fontSize: 16,
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _userGroups.length,
                  itemBuilder: (context, index) {
                    final group = _userGroups[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: themeProvider.currentBorderColor, width: 1),
                      ),
                      elevation: 0,
                      color: themeProvider.currentCardBackground,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    group['groupName'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: themeProvider.currentTextColor,
                                    ),
                                  ),
                                ),
                                // Leave group button
                                TextButton.icon(
                                  onPressed: () => _leaveGroup(group['groupId'], group['groupName']),
                                  icon: Icon(Icons.exit_to_app, size: 18, color: themeProvider.errorColor),
                                  label: Text(
                                    'Leave',
                                    style: TextStyle(color: themeProvider.errorColor),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                ),
                              ],
                            ),
                            if (group['description'] != null && group['description'].isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                group['description'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: themeProvider.currentSecondaryTextColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),
                            // Group ID with copy button
                            Row(
                              children: [
                                Text(
                                  'Group ID: ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: themeProvider.currentTextColor,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    _getShortenedID(group['groupId']),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: themeProvider.currentTextColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.copy,
                                    color: themeProvider.themeColor,
                                    size: 18,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: themeProvider.themeColor.withOpacity(0.1),
                                    padding: const EdgeInsets.all(6),
                                  ),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: group['groupId']));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Group ID copied to clipboard')),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 16,
                                  color: themeProvider.themeColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${group['memberCount']} ${group['memberCount'] == 1 ? 'member' : 'members'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: themeProvider.currentTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeProvider themeProvider) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: themeProvider.currentSecondaryTextColor,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, VoidCallback? onCopyPressed, ThemeProvider themeProvider) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: themeProvider.currentTextColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: themeProvider.currentTextColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onCopyPressed != null) ...[
          const SizedBox(width: 10),
          IconButton(
            icon: Icon(
              Icons.copy,
              color: themeProvider.themeColor,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: themeProvider.themeColor.withOpacity(0.1),
              padding: const EdgeInsets.all(8),
            ),
            onPressed: onCopyPressed,
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    TextInputType keyboardType,
    ThemeProvider themeProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.currentInputFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: themeProvider.currentBorderColor),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: themeProvider.currentTextColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: themeProvider.currentSecondaryTextColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed, ThemeProvider themeProvider) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: themeProvider.themeColor,
        foregroundColor: themeProvider.isDarkMode ? themeProvider.darkTextColor : themeProvider.lightTextColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  Widget _buildRequestCard(String requestText, ThemeProvider themeProvider) {
    return InkWell(
      onTap: () {
        // Show group detail sheet when card is tapped
        GroupDetailSheet.show(
          context: context,
          request: {
            'requestText': requestText,
            'type': requestText.contains('wants to join') ? 'join_request' : 'invitation',
          },
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Card(
        color: themeProvider.currentCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: themeProvider.currentBorderColor, width: 1),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  requestText,
                  style: TextStyle(
                    color: themeProvider.currentTextColor,
                    fontSize: 16,
                  ),
                ),
              ),
              // Removed arrow icon
            ],
          ),
        ),
      ),
    );
  }
}