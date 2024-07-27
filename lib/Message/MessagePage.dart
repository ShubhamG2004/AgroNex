import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

class MessagesPage extends StatefulWidget {
  final String senderId;
  final String receiverId;

  MessagesPage({required this.senderId, required this.receiverId});

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isEmojiPickerVisible = false;
  bool _hasUnreadMessages = false;

  @override
  void initState() {
    super.initState();
    _checkForUnreadMessages();
  }

  @override
  void dispose() {
    _markMessagesAsRead();
    _scrollController.dispose();
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

    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'seen': true});
    }

    await batch.commit();

    setState(() {
      _hasUnreadMessages = false;
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
    _scrollToBottom();

    // Mark all messages as read after sending a message
    await _markMessagesAsRead();
  }

  Future<void> _sendFile(String filePath) async {
    await FirebaseFirestore.instance.collection('messages').add({
      'senderId': widget.senderId,
      'receiverId': widget.receiverId,
      'file': filePath,
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,
    });

    _scrollToBottom();

    // Mark all messages as read after sending a file
    await _markMessagesAsRead();
  }

  Future<Map<String, String>> _getUserProfile(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return {
      'photoURL': userDoc['photoURL'] ?? '',
      'fullName': '${userDoc['firstName'] ?? ''} ${userDoc['lastName'] ?? ''}',
    };
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      String filePath = result.files.single.path!;
      _sendFile(filePath);
    }
  }

  Future<void> _downloadFile(String url) async {
    try {
      if (!url.startsWith('http')) {
        throw ArgumentError('Invalid URL format: $url');
      }

      Dio dio = Dio();
      String filename = url.split('/').last.split('?').first;
      Directory directory = await getApplicationDocumentsDirectory();
      String savePath = '${directory.path}/$filename';

      await dio.download(url, savePath);
    } catch (e) {
      print("Error downloading file: $e");
    }
  }

  Future<void> _openFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final result = await OpenFile.open(path);
        if (result.type != ResultType.done) {
          print("Failed to open file: ${result.message}");
        }
      } else {
        print("File does not exist at: $path");
      }
    } catch (e) {
      print("Error opening file: $e");
    }
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
                Map<String, List<DocumentSnapshot>> messagesByDate = {};

                for (var message in messages) {
                  var timestamp = message['timestamp'] as Timestamp?;
                  var date = timestamp != null ? DateFormat('dd MMMM yyyy').format(timestamp.toDate()) : 'Unknown Date';

                  if (!messagesByDate.containsKey(date)) {
                    messagesByDate[date] = [];
                  }
                  messagesByDate[date]!.add(message);
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients && _scrollController.position.pixels == 0) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView(
                  controller: _scrollController,
                  children: messagesByDate.entries.map((entry) {
                    var date = entry.key;
                    var messagesOnDate = entry.value;

                    // Separate seen and unseen messages
                    List<DocumentSnapshot> seenMessages = [];
                    List<DocumentSnapshot> unseenMessages = [];

                    for (var message in messagesOnDate) {
                      var messageData = message.data() as Map<String, dynamic>;
                      if (messageData['seen'] ?? false) {
                        seenMessages.add(message);
                      } else {
                        unseenMessages.add(message);
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Text(
                              date,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        ...seenMessages.map((message) {
                          var timestamp = message['timestamp'] as Timestamp?;
                          var time = timestamp != null ? timestamp.toDate() : DateTime.now();
                          var timeString = DateFormat('HH:mm').format(time);
                          var messageData = message.data() as Map<String, dynamic>;
                          bool isSender = message['senderId'] == widget.senderId;

                          return _buildMessageBubble(messageData, isSender, timeString, true);
                        }).toList(),
                        if (unseenMessages.isNotEmpty &&
                            unseenMessages.first['receiverId'] == widget.senderId)
                          Container(
                            padding: EdgeInsets.all(0),
                            margin: EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Text(
                                "Unread Messages",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ...unseenMessages.map((message) {
                          var timestamp = message['timestamp'] as Timestamp?;
                          var time = timestamp != null ? timestamp.toDate() : DateTime.now();
                          var timeString = DateFormat('HH:mm').format(time);
                          var messageData = message.data() as Map<String, dynamic>;
                          bool isSender = message['senderId'] == widget.senderId;

                          return _buildMessageBubble(messageData, isSender, timeString, false);
                        }).toList(),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
          if (_isEmojiPickerVisible)
            SizedBox(
              height: 256,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _messageController.text += emoji.emoji;
                },
                onBackspacePressed: () {
                  _messageController.text =
                      _messageController.text.characters.skipLast(1).toString();
                },
              ),
            ),
          Container(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.attach_file),
                  onPressed: _pickFile,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    onTap: () {
                      if (_isEmojiPickerVisible) {
                        setState(() {
                          _isEmojiPickerVisible = false;
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(
                      _isEmojiPickerVisible ? Icons.keyboard : Icons.emoji_emotions),
                  onPressed: () {
                    setState(() {
                      _isEmojiPickerVisible = !_isEmojiPickerVisible;
                    });
                  },
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

  Widget _buildMessageBubble(
      Map<String, dynamic> messageData, bool isSender, String timeString, bool isSeen) {
    bool isFile = messageData.containsKey('file');
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
            isFile
                ? _buildFilePreview(messageData['file'] ?? '')
                : Text(
              messageData['message'] ?? '',
              style: TextStyle(fontSize: 16),
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

  Widget _buildFilePreview(String filePath) {
    String fileName = filePath.split('/').last;
    String fileExtension = fileName.split('.').last.toLowerCase();
    fileName = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');

    if (fileExtension == 'pdf') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red),
              SizedBox(width: 8),
              Text(fileName, style: TextStyle(fontSize: 16)),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.download),
                onPressed: () => _openFile(filePath),
              ),
            ],
          ),
        ],
      );
    } else if (['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension)) {
      return Container(
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(filePath),
                width: 140,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.download),
                  onPressed: () => _openFile(filePath),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.insert_drive_file, color: Colors.grey),
              SizedBox(width: 0),
              Text(fileName, style: TextStyle(fontSize: 14)),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.download),
                onPressed: () => _openFile(filePath),
              ),
            ],
          ),
        ],
      );
    }
  }
}
