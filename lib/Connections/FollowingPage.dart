import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';
import '../Message/MessagePage.dart'; // Adjust the path if necessary

class FollowingPage extends StatefulWidget {
  final List<UserModel> following;

  const FollowingPage({Key? key, required this.following}) : super(key: key);

  @override
  _FollowingPageState createState() => _FollowingPageState();
}

class _FollowingPageState extends State<FollowingPage> {
  List<UserModel> _filteredFollowing = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredFollowing = widget.following;
  }

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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagesPage(
              receiverId: receiver.uid,
              senderId: currentUser.uid,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are not following this user.'),
            backgroundColor: Colors.red, // Adjust color as needed
          ),
        );
      }
    }
  }

  void _filterFollowing(String query) {
    List<UserModel> filteredList = widget.following.where((followingUser) {
      String fullName = '${followingUser.firstName} ${followingUser.lastName}'.toLowerCase();
      return fullName.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredFollowing = filteredList;
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Following'),
        backgroundColor: Colors.green, // Adjust color as needed
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Container(
              height: 45,
              child: TextField(
                onChanged: _filterFollowing,
                decoration: InputDecoration(
                  labelText: 'Search Following',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: _filteredFollowing.isNotEmpty
                  ? ListView.builder(
                itemCount: _filteredFollowing.length,
                itemBuilder: (context, index) {
                  UserModel user = _filteredFollowing[index];
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
                        icon: Icon(Icons.message, color: Colors.green),
                      ),
                    ),
                  );
                },
              )
                  : Center(
                child: Text(
                  'No following users yet',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
