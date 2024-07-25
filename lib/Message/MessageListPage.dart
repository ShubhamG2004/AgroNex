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

  Future<int> _getUnreadCount(String userId) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      QuerySnapshot unreadMessages = await FirebaseFirestore.instance
          .collection('messages')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('senderId', isEqualTo: userId)
          .where('seen', isEqualTo: false)
          .get();

      return unreadMessages.docs.length;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _getMessageUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          List<UserModel> users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              UserModel user = users[index];
              return FutureBuilder<int>(
                future: _getUnreadCount(user.uid),
                builder: (context, unreadSnapshot) {
                  int unreadCount = unreadSnapshot.data ?? 0;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user.photoURL),
                    ),
                    title: Text('${user.firstName} ${user.lastName}'),
                    trailing: unreadCount > 0
                        ? Chip(label: Text('$unreadCount'))
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessagesPage(
                            receiverId: user.uid,
                            senderId: FirebaseAuth.instance.currentUser!.uid,
                          ),
                        ),
                      ).then((_) {
                        // Refresh the unread count after navigating back
                        (context as Element).reassemble();
                      });
                    },
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
