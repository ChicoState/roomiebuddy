import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:roomiebuddy/providers/theme_provider.dart';

class AddRoomatePage extends StatefulWidget {
  const AddRoomatePage({super.key});

  @override
  State<AddRoomatePage> createState() => _AddRoomatePageState();
}

class _AddRoomatePageState extends State<AddRoomatePage> {

  String nickName = "Naruto";
  String userID = "235454";
  String groupName = "House of Buddies";
  String groupID = "103958";

  bool hasRequests = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final TextEditingController invitedUser = TextEditingController(); //send to back end at somepoint

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Roommate'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // -------------------- Profile Name & acc# -------------------- //
            const Text(
              'About You',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 30),
            //Username
            Row(
              children: [
                const Text(
                  'My Nickname: ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  nickName,
                  style: const TextStyle(
                    fontSize: 24,
                    //fontWeight: FontWeight.bold,
                  ),
                ),
              ]
            ),
            //User ID
            Row(
              children: [
                const Text(
                  'User ID: ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userID,
                  style: const TextStyle(
                    fontSize: 24,
                  ),
                ),
                const SizedBox(width: 10),
                
                //Copy to clipboard button (user ID)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.themeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: userID));
                  },
                  child: Icon(
                    Icons.copy,
                    color: themeProvider.lightTextColor,
                  ),
                ),
              ]
            ),
            const SizedBox(height: 20,),

            // -------------------- Group Specs -------------------- //
            const Text(
              'Current Group',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 30),
            //Group Name
            Row(
              children: [
                const Text(
                  'Group Name: ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  groupName,
                  style: const TextStyle(
                    fontSize: 24,
                    //fontWeight: FontWeight.bold,
                  ),
                ),
              ]
            ),
            Row(
              children: [
                const Text(
                  'Group ID: ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  groupID,
                  style: const TextStyle(
                    fontSize: 24,
                    //fontWeight: FontWeight.bold,
                  ),
                ),

                //Copy to Clipboard (group ID)
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.themeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: groupID));
                  },
                  child: Icon(
                    Icons.copy,
                    color: themeProvider.lightTextColor,
                  ),
                ),
              ]
            ),
            const SizedBox(height: 20),

            // -------------------- Add Roomate -------------------- //
            const Text(
              'Add Roommate',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextField(
                    controller: invitedUser,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Rommie Buddy User ID',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.themeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {},
                  child: Text('Invite', style: TextStyle(color: themeProvider.lightTextColor, fontSize: 20)),
                ),
              ]
            ),
            const SizedBox(height: 20),

            // -------------------- Pending Requests -------------------- //
            const Text(
              'Pending Requests',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SingleChildScrollView(

                child:
                  Card(
                    child: ListTile(
                      title: Text('William wants to join House of Buddies'),
                        
                    ),
                  ),
            ),

            //No task display
            const SizedBox(height: 50),
            Text(
              hasRequests? '':'No pending join requests or invites at this time.',
            ),

          ] //Children

        )
      )
    );
  }
}