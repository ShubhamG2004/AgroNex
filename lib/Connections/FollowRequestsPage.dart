import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_model.dart';

class FollowRequestsPage extends StatefulWidget {
  final List<UserModel> followRequests;
  final Function(UserModel) onAccept;
  final Function(UserModel) onIgnore;

  const FollowRequestsPage({
    Key? key,
    required this.followRequests,
    required this.onAccept,
    required this.onIgnore,
  }) : super(key: key);

  @override
  _FollowRequestsPageState createState() => _FollowRequestsPageState();
}

class _FollowRequestsPageState extends State<FollowRequestsPage> {
  @override
  void initState() {
    super.initState();
    // Fetch follow requests if needed, or use the provided followRequests
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Follow Requests'),
      ),
      body: widget.followRequests.isEmpty
          ? Center(
        child: Text('No follow requests'),
      )
          : ListView.builder(
        itemCount: widget.followRequests.length,
        itemBuilder: (context, index) {
          UserModel user = widget.followRequests[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundImage: user.photoURL.isNotEmpty
                    ? NetworkImage(user.photoURL)
                    : AssetImage('assets/images/default_avatar.png') as ImageProvider,
              ),
              title: Text('${user.firstName} ${user.lastName}'),
              subtitle: Text('wants to follow you'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () => widget.onAccept(user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      side: BorderSide(color: Colors.green, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    child: Text('Accept', style: TextStyle(fontSize: 12)),
                  ),
                  SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () => widget.onIgnore(user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      side: BorderSide(color: Colors.red, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    child: Text('Ignore', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
