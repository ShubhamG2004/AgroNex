import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
  String? _firstUnreadMessageId;

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
        _firstUnreadMessageId = unreadMessages.docs.first.id;
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

    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'seen': true});
    }

    await batch.commit();

    setState(() {
      _hasUnreadMessages = false;
      _firstUnreadMessageId = null; // Reset the flag and ID after marking as read
    });
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

    setState(() {
      _hasUnreadMessages = false;
      _firstUnreadMessageId = null;
    });
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
            child: StreamBuilder<List<DocumentSnapshot>>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('senderId', isEqualTo: widget.senderId)
                  .where('receiverId', isEqualTo: widget.receiverId)
                  .orderBy('timestamp')
                  .snapshots()
                  .map((snapshot) => snapshot.docs)
                  .asyncMap((docs) async {
                QuerySnapshot receivedMessagesSnapshot = await FirebaseFirestore.instance
                    .collection('messages')
                    .where('senderId', isEqualTo: widget.receiverId)
                    .where('receiverId', isEqualTo: widget.senderId)
                    .orderBy('timestamp')
                    .get();

                List<DocumentSnapshot> allMessages = [...docs, ...receivedMessagesSnapshot.docs];
                allMessages.sort((a, b) => (a['timestamp'] as Timestamp).compareTo(b['timestamp'] as Timestamp));
                return allMessages;
              }),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                List<DocumentSnapshot> messages = snapshot.data!;
                bool showUnreadText = _hasUnreadMessages;
                List<int> unreadMessageIndexes = [];
                String? lastMessageDate;

                for (int i = 0; i < messages.length; i++) {
                  if (!(messages[i].data() as Map<String, dynamic>)['seen']) {
                    unreadMessageIndexes.add(i);
                  }
                }

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    var timestamp = message['timestamp'] as Timestamp;
                    var time = timestamp.toDate();
                    var timeString = DateFormat('HH:mm').format(time);
                    var messageDate = DateFormat('dd MMMM yyyy').format(time);

                    bool isSender = message['senderId'] == widget.senderId;
                    Map<String, dynamic> messageData = message.data() as Map<String, dynamic>;
                    bool isSeen = messageData['seen'] ?? false;

                    List<Widget> messageWidgets = [];

                    if (messageDate != lastMessageDate) {
                      lastMessageDate = messageDate;
                      messageWidgets.add(
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Text(
                              messageDate,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    }

                    if (showUnreadText && unreadMessageIndexes.contains(index)) {
                      showUnreadText = false;
                      messageWidgets.add(
                        Container(
                          padding: EdgeInsets.all(0),
                          margin: EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            "Unread Messages",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }

                    messageWidgets.add(_buildMessageBubble(messageData, isSender, timeString, isSeen));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: messageWidgets,
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
              style: TextStyle(fontSize: 12, color: Colors.black),
            ),
            if (!isSeen && !isSender) ...[
              SizedBox(width: 8),
              Icon(Icons.mark_email_unread, color: Colors.orange, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
