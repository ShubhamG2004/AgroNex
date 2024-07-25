import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String senderId;
  final String receiverId;

  ChatPage({required this.senderId, required this.receiverId});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  late final CollectionReference _messagesRef;
  final List<DocumentSnapshot> _messages = [];
  bool _hasMoreMessages = true;
  bool _isLoading = false;
  final int _messagesPerPage = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messagesRef = FirebaseFirestore.instance.collection('user_messages');
    _fetchMessages();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _fetchMessages();
      }
    });
  }

  Future<void> _fetchMessages() async {
    if (_isLoading || !_hasMoreMessages) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Query query = _messagesRef
          .doc(widget.senderId)
          .collection('sent')
          .doc(widget.receiverId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(_messagesPerPage);

      if (_messages.isNotEmpty) {
        query = query.startAfterDocument(_messages.last);
      }

      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _hasMoreMessages = false;
        });
      } else {
        setState(() {
          _messages.addAll(querySnapshot.docs);
        });
      }
    } catch (e) {
      print('Error fetching messages: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      String messageText = _messageController.text.trim();
      var currentUser = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('messages').add({
        'senderId': widget.senderId,
        'receiverId': widget.receiverId,
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Store the message in both sender and receiver subcollections
      await _messagesRef
          .doc(widget.senderId)
          .collection('sent')
          .doc(widget.receiverId)
          .collection('messages')
          .add({
        'senderId': widget.senderId,
        'receiverId': widget.receiverId,
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _messagesRef
          .doc(widget.receiverId)
          .collection('received')
          .doc(widget.senderId)
          .collection('messages')
          .add({
        'senderId': widget.senderId,
        'receiverId': widget.receiverId,
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index].data() as Map<String, dynamic>;
                final timestamp = (message['timestamp'] as Timestamp).toDate();
                return ListTile(
                  title: Text(message['text'] ?? ''),
                  subtitle: Text(timestamp.toString()),
                );
              },
              controller: _scrollController,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message',
                      border: OutlineInputBorder(),
                    ),
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
}
