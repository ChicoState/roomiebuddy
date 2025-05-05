import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';
import 'package:roomiebuddy/services/api_service.dart';
import 'package:roomiebuddy/services/auth_storage.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  // Text editing controllers
  final _userIdController = TextEditingController();
  final _createGroupNameController = TextEditingController();

  // User data variables
  String? _selectedGroupId;
  String _userId = "";
  String _password = "";
  String _errorMessage = "";
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _userGroups = [];
  List<Map<String, dynamic>> _pendingInvites = [];
  final Map<String, bool> _loadingInvites = {};

  // Services
  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _createGroupNameController.dispose();
    super.dispose();
  }

  // ------- Backend Communication Methods ------- //

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      // Get user credentials
      final userId = await _authStorage.getUserId();
      final password = await _authStorage.getPassword();

      // Ensure credentials exist
      if (userId == null || password == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "User not logged in";
        });
        return;
      }
      _userId = userId;
      _password = password;

      // Get user groups
      final groupsResponse = await _apiService.getGroupList(userId, password);
      if (!groupsResponse['success']) {
        setState(() {
          _errorMessage = "Failed to load groups: ${groupsResponse['message']}";
        });
      } else {
        final groups = groupsResponse['data']?['groups'] as Map<String, dynamic>? ?? {};
        _userGroups = groups.values.map((group) => group as Map<String, dynamic>).toList();
        _selectedGroupId = null;
      }

      // Get pending invites
      final invitesResponse = await _apiService.getPendingInvites(userId, password);
      if (!invitesResponse['success']) {
        setState(() {
          _errorMessage = _errorMessage.isNotEmpty
              ? "$_errorMessage\nFailed to load invites: ${invitesResponse['message']}"
              : "Failed to load invites: ${invitesResponse['message']}";
        });
      } else {
        final invites = invitesResponse['data']?['invites'] as Map<String, dynamic>? ?? {};
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
        '',
      );
      
      if (response['success']) {

        // Clear the form
        _createGroupNameController.clear();

        // Let the user know group was created successfully
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Group created successfully')),
        );

        // Refresh the group list
        try {
          final groupsResponse = await _apiService.getGroupList(_userId, _password);
          if (groupsResponse['success']) {
            final groups = groupsResponse['data']?['groups'] as Map<String, dynamic>? ?? {};
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
        final groups = groupsResponse['data']?['groups'] as Map<String, dynamic>? ?? {};
        setState(() {
          _userGroups = groups.values.map((group) => group as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      // Silently handle error
    }
  }

  // ------- Main Build Method ------- //

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
              // -------------------- Create Group -------------------- //
              Text(
                'Create Group',
                style: TextStyle(
                  color: themeProvider.currentTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              
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
                  SizedBox(
                    width: 80,
                    child: ElevatedButton(
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
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // -------------------- Invite Roommate -------------------- //
              Text(
                'Invite Roommate',
                style: TextStyle(
                  color: themeProvider.currentTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              
              if (_userGroups.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: themeProvider.currentInputFill,
                        ),
                        dropdownColor: themeProvider.currentInputFill,
                        borderRadius: BorderRadius.circular(8),
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
                              hintText: 'Enter user ID',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: ElevatedButton(
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
                        ),
                      ],
                    ),
                  ],
                )
              else
                const Text('You must be in a group to invite a roommate.'),
              
              const SizedBox(height: 16),

              // -------------------- Pending Invites -------------------- //
              Text(
                'Pending Invites',
                style: TextStyle(
                  color: themeProvider.currentTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              Container(
                height: 420,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeProvider.currentInputFill,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _pendingInvites.isNotEmpty
                  ? ListView.builder(
                      itemCount: _pendingInvites.length,
                      itemBuilder: (context, index) {
                        final invite = _pendingInvites[index];
                        final isLoadingInvite = _loadingInvites[invite['invite_id']] == true;
                        
                        return Card(
                          color: themeProvider.currentBackground,
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            // Group Name
                            title: Text(
                              invite['group_name'],
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: themeProvider.currentTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Inviter Name
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Invited by ${invite['inviter_name']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: themeProvider.currentSecondaryTextColor,
                                ),
                              ),
                            ),
                            trailing: isLoadingInvite
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: themeProvider.themeColor,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.check_circle,
                                          color: themeProvider.successColor,
                                          size: 26,
                                      ),
                                      onPressed: () => _respondToInvite(invite['invite_id'], 'accepted'),
                                      tooltip: 'Accept',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: Icon(Icons.highlight_off,
                                          color: themeProvider.errorColor,
                                          size: 26,
                                      ),
                                      onPressed: () => _respondToInvite(invite['invite_id'], 'rejected'),
                                      tooltip: 'Decline',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        'No pending invites at this time',
                        style: TextStyle(
                          color: themeProvider.currentSecondaryTextColor,
                        ),
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}