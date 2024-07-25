import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'MessagePage.dart';
import '../Connections/user_model.dart';

class MessageListPage extends StatelessWidget {
  const MessageListPage({Key? key}) : super(key: key);

  Future<List<UserModel>> _getMessageUsers() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      QuerySnapshot sentMessagesSnapshot = await FirebaseFirestore.instance
          .collection('messages')
          .where('senderId', isEqualTo: currentUser.uid)
          .get();

      QuerySnapshot receivedMessagesSnapshot = await FirebaseFirestore.instance
          .collection('messages')
          .where('receiverId', isEqualTo: currentUser.uid)
          .get();

      Set<String> userIds = {};

      for (var doc in sentMessagesSnapshot.docs) {
        userIds.add(doc['receiverId']);
      }
      for (var doc in receivedMessagesSnapshot.docs) {
        userIds.add(doc['senderId']);
      }

      List<UserModel> users = [];
      for (String userId in userIds) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (userDoc.exists) {
          users.add(UserModel.fromDocument(userDoc));
        }
      }

      return users;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _getMessageUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          List<UserModel>? users = snapshot.data;
          if (users == null || users.isEmpty) {
            return Center(
              child: Text('No messages yet'),
            );
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              UserModel user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.photoURL.isNotEmpty
                      ? NetworkImage(user.photoURL)
                      : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                ),
                title: Text('${user.firstName} ${user.lastName}'),
                subtitle: Text(user.position),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessagesPage(
                        senderId: FirebaseAuth.instance.currentUser!.uid,
                        receiverId: user.uid,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
