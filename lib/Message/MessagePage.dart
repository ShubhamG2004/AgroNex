import 'dart:io'; // Ensure this import is present
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class MessagesPage extends StatefulWidget {
  final String receiverId;
  final String senderId;

  const MessagesPage({Key? key, required this.receiverId, required this.senderId}) : super(key: key);

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasUnreadMessages = false;
  String? _firstUnreadMessageId;
  bool _isEmojiPickerVisible = false;

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
      _firstUnreadMessageId = null;
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

    _scrollToBottom();
  }

  Future<void> _sendFile(String fileName, String url, String fileType) async {
    await FirebaseFirestore.instance.collection('messages').add({
      'senderId': widget.senderId,
      'receiverId': widget.receiverId,
      'fileName': fileName,
      'fileURL': url,
      'fileType': fileType,
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,
    });

    setState(() {
      _hasUnreadMessages = false;
      _firstUnreadMessageId = null;
    });

    _scrollToBottom();
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
      String fileName = result.files.single.name;
      String fileExtension = fileName.split('.').last;
      String fileType = fileExtension == 'pdf'
          ? 'pdf'
          : ['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension)
          ? 'image'
          : 'file';

      // Upload file to a cloud storage and get the download URL
      String url = await _uploadFileToStorage(filePath, fileName);

      _sendFile(fileName, url, fileType);
    }
  }

  Future<String> _uploadFileToStorage(String filePath, String fileName) async {
    // Implement file upload to cloud storage here
    // Return the download URL of the uploaded file
    return 'https://your_storage_url/$fileName';
  }

  Future<void> _downloadFile(String url) async {
    try {
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
                Set<String> displayedDates = {};

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
                    bool showUnreadText = _hasUnreadMessages && messagesOnDate.any((msg) => !(msg.data() as Map<String, dynamic>)['seen']);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          child: Text(
                            date,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                        ...messagesOnDate.map((message) {
                          bool isSender = message['senderId'] == widget.senderId;
                          var timestamp = message['timestamp'] as Timestamp?;
                          var time = timestamp != null ? DateFormat('HH:mm').format(timestamp.toDate()) : 'Unknown Time';
                          bool showUnread = _hasUnreadMessages && message.id == _firstUnreadMessageId;

                          var messageType = message['fileType'] ?? 'text';
                          var messageContent = messageType == 'text'
                              ? message['message']
                              : messageType == 'image'
                              ? message['fileURL']
                              : message['fileName'];

                          return Column(
                            children: [
                              if (showUnread) _buildUnreadMessagesIndicator(),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    if (messageType == 'text')
                                      Container(
                                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                        decoration: BoxDecoration(
                                          color: isSender ? Colors.green : Colors.grey[300],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          messageContent,
                                          style: TextStyle(color: isSender ? Colors.white : Colors.black),
                                        ),
                                      )
                                    else if (messageType == 'image')
                                      GestureDetector(
                                        onTap: () {
                                          // Implement full screen image view here
                                        },
                                        child: Container(
                                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                          child: Image.network(messageContent),
                                        ),
                                      )
                                    else
                                      GestureDetector(
                                        onTap: () async {
                                          Directory directory = await getApplicationDocumentsDirectory();
                                          String savePath = '${directory.path}/${messageContent}';
                                          await _downloadFile(message['fileURL']);
                                          await _openFile(savePath);
                                        },
                                        child: Container(
                                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                          decoration: BoxDecoration(
                                            color: isSender ? Colors.green : Colors.grey[300],
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.insert_drive_file, color: isSender ? Colors.white : Colors.black),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  messageContent,
                                                  style: TextStyle(color: isSender ? Colors.white : Colors.black),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    SizedBox(height: 5),
                                    Text(
                                      time,
                                      style: TextStyle(color: Colors.grey, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
          if (_isEmojiPickerVisible)
            EmojiPicker(
              onEmojiSelected: (category, emoji) {
                _messageController.text += emoji.emoji;
              },

            ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            color: Colors.grey[200],
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.emoji_emotions),
                  onPressed: () {
                    setState(() {
                      _isEmojiPickerVisible = !_isEmojiPickerVisible;
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.attach_file),
                  onPressed: _pickFile,
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

  Widget _buildUnreadMessagesIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: Colors.grey),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Unread messages',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Divider(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
