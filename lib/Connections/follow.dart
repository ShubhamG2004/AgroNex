import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_model.dart';

class FollowPage extends StatefulWidget {
  const FollowPage({Key? key}) : super(key: key);

  @override
  _FollowPageState createState() => _FollowPageState();
}

class _FollowPageState extends State<FollowPage> {
  List<UserModel> followRequests = [];

  @override
  void initState() {
    super.initState();
    fetchFollowRequests();
  }

  Future<void> fetchFollowRequests() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('follow_requests')
            .where('toUserId', isEqualTo: currentUser.uid)
            .get();

        List<UserModel> requests = [];
        for (var doc in snapshot.docs) {
          var fromUserId = doc['fromUserId'];
          var userDoc = await FirebaseFirestore.instance.collection('users').doc(fromUserId).get();
          var user = UserModel.fromDocument(userDoc);
          requests.add(user);
        }

        setState(() {
          followRequests = requests;
        });
      } catch (e) {
        print('Error fetching follow requests: $e');
      }
    }
  }

  Future<void> acceptFollowRequest(UserModel user) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance.collection('followers').doc(user.uid).update({
          'followers': FieldValue.arrayUnion([currentUser.uid]),
        });

        await FirebaseFirestore.instance.collection('following').doc(currentUser.uid).update({
          'following': FieldValue.arrayUnion([user.uid]),
        });

        await FirebaseFirestore.instance.collection('follow_requests').doc(user.uid).delete();

        // Remove the accepted request from the list
        setState(() {
          followRequests.removeWhere((request) => request.uid == user.uid);
        });
      } catch (e) {
        print('Error accepting follow request: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView.builder(
        itemCount: followRequests.length,
        itemBuilder: (context, index) {
          UserModel user = followRequests[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: user.photoURL.isNotEmpty
                  ? NetworkImage(user.photoURL)
                  : AssetImage('assets/images/default_avatar.png') as ImageProvider,
            ),
            title: Text('${user.firstName} ${user.lastName}'),
            subtitle: Text(user.position),
            trailing: ElevatedButton(
              onPressed: () => acceptFollowRequest(user),
              child: Text('Accept'),
            ),
          );
        },
      ),
    );
  }
}
