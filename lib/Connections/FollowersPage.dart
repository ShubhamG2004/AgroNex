import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';
import '../Message/MessagePage.dart'; // Adjust the path if necessary

class FollowersPage extends StatelessWidget {
  final List<UserModel> followers;

  const FollowersPage({Key? key, required this.followers}) : super(key: key);

  Future<bool> _isUserFollowed(UserModel user) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot followingDoc = await FirebaseFirestore.instance
          .collection('following')
          .doc(currentUser.uid)
          .get();
      Map<String, dynamic>? data = followingDoc.data() as Map<String, dynamic>?;
      List<String> followingUserIds = List<String>.from(data?['following'] ?? []);
      return followingUserIds.contains(user.uid);
    }
    return false;
  }

  Future<void> _openChat(UserModel receiver, BuildContext context) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      bool isFollowed = await _isUserFollowed(receiver);
      if (isFollowed) {
        // Navigate to the chat page without sending a message
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagesPage(
              receiverId: receiver.uid,
              senderId: currentUser.uid, // Pass sender ID to MessagesPage
            ),
          ),
        );
      } else {
        // Show a message that the user is not followed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are not following this user.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Followers'),
        backgroundColor: Colors.green, // Adjust color as needed
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: followers.isNotEmpty
            ? ListView.builder(
          itemCount: followers.length,
          itemBuilder: (context, index) {
            UserModel user = followers[index];
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                leading: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    backgroundImage: user.photoURL.isNotEmpty
                        ? NetworkImage(user.photoURL)
                        : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                    radius: 22,
                  ),
                ),
                title: Text('${user.firstName} ${user.lastName}'),
                subtitle: Text(user.position),
                trailing: IconButton(
                  onPressed: () => _openChat(user, context),
                  icon: Transform.scale(
                    scale: 1.3,
                    child: Icon(Icons.message, color: Colors.green),
                  ),
                ),
              ),
            );
          },
        )
            : Center(
          child: Text('No followers yet', style: TextStyle(color: Colors.black)),
        ),
      ),
    );
  }
}
