import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessagesPage extends StatefulWidget {
  final String receiverId;
  final String senderId;

  const MessagesPage({Key? key, required this.receiverId, required this.senderId}) : super(key: key);

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _hasUnreadMessages = false;

  @override
  void initState() {
    super.initState();
    _checkForUnreadMessages();
  }

  @override
  void dispose() {
    _markMessagesAsRead();
    super.dispose();
  }

  Future<void> _checkForUnreadMessages() async {
    QuerySnapshot unreadMessages = await FirebaseFirestore.instance
        .collection('messages')
        .where('receiverId', isEqualTo: widget.senderId)
        .where('senderId', isEqualTo: widget.receiverId)
        .where('seen', isEqualTo: false)
        .get();

    if (unreadMessages.docs.isNotEmpty) {
      setState(() {
        _hasUnreadMessages = true;
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('messages')
        .where('receiverId', isEqualTo: widget.senderId)
        .where('senderId', isEqualTo: widget.receiverId)
        .where('seen', isEqualTo: false)
        .get();

    for (var doc in querySnapshot.docs) {
      doc.reference.update({'seen': true});
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection('messages').add({
      'senderId': widget.senderId,
      'receiverId': widget.receiverId,
      'message': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,
    });

    _messageController.clear();
  }

  Future<Map<String, String>> _getUserProfile(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return {
      'photoURL': userDoc['photoURL'] ?? '',
      'fullName': '${userDoc['firstName'] ?? ''} ${userDoc['lastName'] ?? ''}',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: FutureBuilder<Map<String, String>>(
          future: _getUserProfile(widget.receiverId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            var userProfile = snapshot.data!;
            return Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(userProfile['photoURL']!),
                  radius: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    userProfile['fullName']!,
                    style: TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('senderId', isEqualTo: widget.senderId)
                  .where('receiverId', isEqualTo: widget.receiverId)
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot1) {
                if (!snapshot1.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('messages')
                      .where('senderId', isEqualTo: widget.receiverId)
                      .where('receiverId', isEqualTo: widget.senderId)
                      .orderBy('timestamp')
                      .snapshots(),
                  builder: (context, snapshot2) {
                    if (!snapshot2.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    List<DocumentSnapshot> messages = [...snapshot1.data!.docs, ...snapshot2.data!.docs];
                    messages.sort((a, b) => (a['timestamp'] as Timestamp).compareTo(b['timestamp'] as Timestamp));

                    bool showUnreadText = _hasUnreadMessages;

                    return ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        var message = messages[index];
                        var time = (message['timestamp'] as Timestamp).toDate();
                        var timeString = "${time.hour}:${time.minute}";

                        bool isSender = message['senderId'] == widget.senderId;
                        Map<String, dynamic> messageData = message.data() as Map<String, dynamic>;
                        bool isSeen = messageData.containsKey('seen') ? messageData['seen'] : false;

                        if (_hasUnreadMessages && showUnreadText && !isSeen && !isSender) {
                          showUnreadText = false; // Show "Unread Messages" text only once
                          return Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                margin: EdgeInsets.symmetric(vertical: 10),
                                // color: Colors.yellow,
                                child: Text(
                                  "Unread Messages",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                              _buildMessageBubble(messageData, isSender, timeString, isSeen),
                            ],
                          );
                        }

                        return _buildMessageBubble(messageData, isSender, timeString, isSeen);
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 8.0, top: 8.0, bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      contentPadding: EdgeInsets.all(8.0),
                    ),
                    style: TextStyle(fontSize: 14.0),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> messageData, bool isSender, String timeString, bool isSeen) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: isSender ? Colors.green[100] : Colors.blue[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                messageData['message'],
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(width: 8),
            Text(
              timeString,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            if (!isSeen && !isSender) ...[
              SizedBox(width: 8),
              Icon(Icons.mark_email_unread, color: Colors.red, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
