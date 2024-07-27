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
  late List<UserModel> _followRequests;

  @override
  void initState() {
    super.initState();
    _followRequests = widget.followRequests;
  }

  void _handleAccept(UserModel user) async {
    await widget.onAccept(user);
    setState(() {
      _followRequests.remove(user);
    });
  }

  void _handleIgnore(UserModel user) async {
    await widget.onIgnore(user);
    setState(() {
      _followRequests.remove(user);
    });

    // Remove the follow request from Firestore
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String currentUserId = currentUser.uid;
      String followRequestId = user.uid;

      try {
        await FirebaseFirestore.instance
            .collection('followRequests')
            .doc(currentUserId)
            .collection('requests')
            .doc(followRequestId)
            .delete()
            .then((_) {
          print('Follow request deleted from Firestore.');
        });
      } catch (e) {
        print('Failed to delete follow request: $e');
      }
    } else {
      print('No current user found.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Follow Requests'),
      ),
      body: _followRequests.isEmpty
          ? Center(
        child: Text('No follow requests'),
      )
          : ListView.builder(
        itemCount: _followRequests.length,
        itemBuilder: (context, index) {
          UserModel user = _followRequests[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundImage: user.photoURL.isNotEmpty
                    ? NetworkImage(user.photoURL)
                    : AssetImage('assets/images/default_avatar.png')
                as ImageProvider,
              ),
              title: Text('${user.firstName} ${user.lastName}'),
              subtitle: Text('wants to follow you'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () => _handleAccept(user),
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
                    onPressed: () => _handleIgnore(user),
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
