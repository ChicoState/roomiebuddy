import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';
import 'package:roomiebuddy/services/api_service.dart';
import 'package:roomiebuddy/services/auth_storage.dart';
import 'dart:math' as math;

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  final _groupIdController = TextEditingController();
  final _userIdController = TextEditingController();
  final _createGroupNameController = TextEditingController();
  final _createGroupDescController = TextEditingController();
  
  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  final Map<String, bool> _loadingInvites = {};

  String _username = "";
  String _userId = "";
  String _password = "";
  List<Map<String, dynamic>> _userGroups = [];
  String? _selectedGroupId;
  List<Map<String, dynamic>> _pendingInvites = [];
  String _errorMessage = "";
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _groupIdController.dispose();
    _userIdController.dispose();
    _createGroupNameController.dispose();
    _createGroupDescController.dispose();
    super.dispose();
  }

  // Loads user groups and pending invites
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {

      // Get user credentials
      final userId = await _authStorage.getUserId();
      final password = await _authStorage.getPassword();
      final username = await _authStorage.getUsername();

      // Ensure all credentials exist
      if (userId == null || password == null || username == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "User not logged in";
        });
        return;
      }
      _userId = userId;
      _password = password;
      _username = username;

      // Get user groups
      final groupsResponse = await _apiService.getGroupList(userId, password);
      if (!groupsResponse['success']) {
        setState(() {
          _errorMessage = "Failed to load groups: ${groupsResponse['message']}";
        });
      } else {
        final groups = groupsResponse['message'] as Map<String, dynamic>;
        _userGroups = groups.values.map((group) => group as Map<String, dynamic>).toList();
        _selectedGroupId = null;
      }

      // Get pending invites
      final invitesResponse = await _apiService.getPendingInvites(userId, password);
      if (!invitesResponse['success']) {
        setState(() {
          _errorMessage = "Failed to load invites: ${invitesResponse['message']}";
        });
      } else {
        final invites = invitesResponse['message'] as Map<String, dynamic>;
        _pendingInvites = invites.values.map((invite) => invite as Map<String, dynamic>).toList();
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createGroup() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Ensure group name is entered
    if (_createGroupNameController.text.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    try {
      final response = await _apiService.createGroup(
        _userId,
        _password,
        _createGroupNameController.text.trim(),
        _createGroupDescController.text.trim(),
      );
      
      if (response['success']) {

        // Clear the form
        _createGroupNameController.clear();
        _createGroupDescController.clear();

        // Let the user know group was created successfully
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Group created successfully')),
        );

        // Refresh the group list
        try {
          final groupsResponse = await _apiService.getGroupList(_userId, _password);
          if (groupsResponse['success']) {
            final groups = groupsResponse['message'] as Map<String, dynamic>;
            if(mounted){
              setState(() {
                _userGroups = groups.values.map((group) => group as Map<String, dynamic>).toList();
              });
            }
          }
        } catch (e) {
          // Silently handle error
        }
      } else {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to create group: ${response['message']}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if(mounted){
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _inviteUser() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Ensure user ID and group are entered
    if (_userIdController.text.isEmpty || _selectedGroupId == null) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please enter a user ID and select a group')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await _apiService.inviteToGroup(
        _userId,
        _userIdController.text.trim(),
        _selectedGroupId!,
        _password,
      );

      if (response['success']) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Invitation sent successfully')),
        );
        _userIdController.clear();
      } else {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to send invitation: ${response['message']}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if(mounted){
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _respondToInvite(String inviteId, String status) async {
    setState(() {
      _loadingInvites[inviteId] = true;
    });

    try {
      final response = await _apiService.respondToInvite(
        _userId,
        inviteId,
        status,
        _password,
      );

      if (response['success']) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully $status invitation')),
        );
        
        // Update local state
        setState(() {
          // Remove the invite locally
          _pendingInvites.removeWhere((invite) => invite['invite_id'] == inviteId);
          
          // If accepted, refresh the groups list
          if (status == 'accepted') {
            // Get updated groups
            _refreshGroupsList();
          }
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to $status invitation: ${response['message']}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      // Clear loading state for this invite
      setState(() {
        _loadingInvites.remove(inviteId);
      });
    }
  }

  Future<void> _refreshGroupsList() async {
    try {
      final groupsResponse = await _apiService.getGroupList(_userId, _password);
      if (groupsResponse['success']) {
        final groups = groupsResponse['message'] as Map<String, dynamic>;
        setState(() {
          _userGroups = groups.values.map((group) => group as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      // Silently handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Management')),
        body: Center(child: Text(_errorMessage)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Group Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeProvider.currentTextColor,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------------------- Profile Info -------------------- //
              Text(
                'Profile Info',
                style: TextStyle(
                  color: themeProvider.currentTextColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Username
              Row(
                children: [
                  Text(
                    'Username: ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.currentTextColor,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _username,
                      style: TextStyle(
                        fontSize: 16,
                        overflow: TextOverflow.ellipsis,
                        color: themeProvider.currentTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              
              // User ID
              Row(
                children: [
                  Text(
                    'User ID: ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.currentTextColor,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _userId.length > 12 ? "${_userId.substring(0, 11)}..." : _userId,
                      style: TextStyle(
                        fontSize: 16,
                        overflow: TextOverflow.ellipsis,
                        color: themeProvider.currentTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Copy to clipboard button (user ID)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeProvider.themeColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.all(8),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _userId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User ID copied to clipboard')),
                      );
                    },
                    child: Icon(
                      Icons.copy,
                      color: themeProvider.currentTextColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // -------------------- Create Group -------------------- //
              Text(
                'Create Group',
                style: TextStyle(
                  color: themeProvider.currentTextColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _createGroupNameController,
                      decoration: InputDecoration(
                        hintText: 'Enter group name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeProvider.themeColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onPressed: _isSubmitting ? null : _createGroup,
                    child: _isSubmitting 
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: themeProvider.currentTextColor,
                          ),
                        )
                      : Text(
                          'Create',
                          style: TextStyle(color: themeProvider.currentTextColor),
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // -------------------- Invite Roommate -------------------- //
              Text(
                'Invite Roommate',
                style: TextStyle(
                  color: themeProvider.currentTextColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              if (_userGroups.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        value: _selectedGroupId,
                        hint: const Text('Select Group'),
                        items: _userGroups.map((group) => 
                          DropdownMenuItem<String>(
                            value: group['group_id'],
                            child: Text(group['name'], overflow: TextOverflow.ellipsis),
                          )
                        ).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGroupId = value;
                          });
                        },
                      ),
                    ),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _userIdController,
                            decoration: InputDecoration(
                              hintText: 'Enter user ID to invite',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeProvider.themeColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onPressed: _isSubmitting ? null : _inviteUser,
                          child: _isSubmitting 
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: themeProvider.currentTextColor,
                                ),
                              )
                            : Text(
                                'Invite',
                                style: TextStyle(color: themeProvider.currentTextColor),
                              ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                const Text('You must be in a group to invite a roommate.'),
              
              const SizedBox(height: 32),

              // -------------------- Pending Invites -------------------- //
              Text(
                'Pending Invites',
                style: TextStyle(
                  color: themeProvider.currentTextColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              if (_pendingInvites.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pendingInvites.length,
                  itemBuilder: (context, index) {
                    final invite = _pendingInvites[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Stack(
                        children: [
                          // Main content
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Group Name
                                Text(
                                  invite['group_name'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: themeProvider.currentTextColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                
                                // Inviter name
                                Text(
                                  '${invite['inviter_name']} invited you',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    color: themeProvider.currentSecondaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                          
                          // Action buttons for accepting/declining
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: _loadingInvites[invite['invite_id']] == true
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: themeProvider.themeColor,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.check_circle_outline, color: themeProvider.successColor),
                                      onPressed: () => _respondToInvite(invite['invite_id'], 'accepted'),
                                      tooltip: 'Accept',
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.cancel_outlined, color: themeProvider.errorColor),
                                      onPressed: () => _respondToInvite(invite['invite_id'], 'rejected'),
                                      tooltip: 'Decline',
                                    ),
                                  ],
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              else
                const Text('No pending invites at this time'),
              
              const SizedBox(height: 32),

              // -------------------- Current Groups -------------------- //
              Text(
                'Current Groups',
                style: TextStyle(
                  color: themeProvider.currentTextColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              if (_userGroups.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _userGroups.length,
                  itemBuilder: (context, index) {
                    final group = _userGroups[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Stack(
                        children: [
                          // Main content
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Group Name
                                Text(
                                  group['name'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: themeProvider.currentTextColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                
                                // Members Section
                                Text(
                                  'Members (${group['members'].length})',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    color: themeProvider.currentSecondaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Member list
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (var i = 0; i < math.min(5, group['members'].length); i++)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: themeProvider.themeColor,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          group['members'][i]['username'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: themeProvider.currentTextColor,
                                          ),
                                        ),
                                      ),
                                    
                                    if (group['members'].length > 5)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: themeProvider.currentSecondaryTextColor,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '+${group['members'].length - 5} more',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                            color: themeProvider.currentTextColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                          
                          // Leave group button
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: IconButton(
                              icon: Icon(
                                Icons.exit_to_app,
                                color: themeProvider.errorColor,
                                size: 24,
                              ),
                              tooltip: 'Leave Group',
                              onPressed: _isSubmitting ? null : () async {
                                final scaffoldMessenger = ScaffoldMessenger.of(context);
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Leave Group'),
                                    content: const Text('Are you sure you want to leave this group?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Leave'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirm == true) {
                                  setState(() => _isSubmitting = true);
                                  try {
                                    final response = await _apiService.leaveGroup(
                                      _userId,
                                      _password,
                                      group['group_id'],
                                    );
                                    
                                    if (response['success']) {
                                      if (!mounted) return;
                                      scaffoldMessenger.showSnackBar(
                                        const SnackBar(content: Text('Left group successfully')),
                                      );
                                      setState(() {
                                        _userGroups.removeWhere((g) => g['group_id'] == group['group_id']);
                                        if (_selectedGroupId == group['group_id']) {
                                          _selectedGroupId = null;
                                        }
                                      });
                                    } else {
                                      if (!mounted) return;
                                      scaffoldMessenger.showSnackBar(
                                        SnackBar(content: Text('Failed to leave group: ${response['message']}')),
                                      );
                                    }
                                  } catch (e) {
                                    if (!mounted) return;
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  } finally {
                                    if(mounted){
                                      setState(() => _isSubmitting = false);
                                    }
                                  }
                                }
                              },
                            ),
                          ),
                          
                          if (_isSubmitting)
                            Positioned.fill(
                              child: Container(
                                color: themeProvider.currentCardBackground.withAlpha(191),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: themeProvider.themeColor,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                )
              else
                const Text('You are not currently in any groups'),
            ],
          ),
        ),
      ),
    );
  }
}