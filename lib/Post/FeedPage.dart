import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:translator/translator.dart'; // Import a translation package if you want to use it
import '../Connections/user_model.dart'; // Import your UserModel class

class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  Map<int, bool> _isExpanded = {};
  Map<int, PageController> _pageControllers = {};
  Map<int, String> _translatedText = {}; // Store translated text for each post

  final translator = GoogleTranslator(); // Initialize the translator

  // Function to translate text
  Future<void> _translateText(int index, String text, String languageCode) async {
    final translation = await translator.translate(text, to: languageCode);
    setState(() {
      _translatedText[index] = translation.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No posts available'));
          }

          final posts = snapshot.data!;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index]['post'];
              final user = posts[index]['user'] as UserModel;

              _isExpanded[index] = _isExpanded[index] ?? false;
              _pageControllers[index] = _pageControllers[index] ?? PageController();

              return Card(
                color: Colors.white, // Set the background color of the card to white
                margin: EdgeInsets.all(6),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: user.photoURL.isNotEmpty
                                ? NetworkImage(user.photoURL)
                                : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${user.firstName} ${user.lastName}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  user.position,
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  _formatTimeDifference(post['timestamp'] as Timestamp),
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_horiz),
                            onSelected: (value) async {
                              if (value == 'hindi') {
                                await _translateText(index, post['thought'], 'hi');
                              } else if (value == 'tamil') {
                                await _translateText(index, post['thought'], 'ta');
                              } else if (value == 'telugu') {
                                await _translateText(index, post['thought'], 'te');
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              return [
                                PopupMenuItem(
                                  value: 'hindi',
                                  child: Text('Convert to Hindi'),
                                ),
                                PopupMenuItem(
                                  value: 'tamil',
                                  child: Text('Convert to Tamil'),
                                ),
                                PopupMenuItem(
                                  value: 'telugu',
                                  child: Text('Convert to Telugu'),
                                ),
                              ];
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 1), // Super fast duration
                        curve: Curves.easeInOut,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _translatedText[index] ?? post['thought'], // Display translated text if available
                                    maxLines: _isExpanded[index]! ? null : 1,
                                    overflow: _isExpanded[index]! ? null : TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                                if ((post['thought'] as String).length > 100 && !_isExpanded[index]!)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10.0),
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _isExpanded[index] = !_isExpanded[index]!;
                                        });
                                      },
                                      child: Text(_isExpanded[index]! ? 'See Less' : 'See More'),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (post['photos'] != null && (post['photos'] as List).isNotEmpty)
                        Stack(
                          children: [
                            Container(
                              height: 300,
                              child: PageView.builder(
                                controller: _pageControllers[index],
                                itemCount: (post['photos'] as List).length,
                                itemBuilder: (context, photoIndex) {
                                  return Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Image.network(post['photos'][photoIndex]),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_back_ios,
                                  size: 15, // Set the size of the icon
                                  color: Colors.black, // Set the color of the icon
                                ),
                                onPressed: () {
                                  _pageControllers[index]!.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                                },
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: IconButton(
                                icon: Icon( Icons.arrow_forward_ios,size: 15,
                                  color: Colors.black, ),
                                onPressed: () {
                                  _pageControllers[index]!.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                                },
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.thumb_up),
                                  onPressed: () {
                                    // Handle like action
                                  },
                                ),
                                Text('${post['likes']}'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.comment),
                                  onPressed: () {
                                    // Navigate to comments page or open comments section
                                  },
                                ),
                                Text('${post['comments'].length}'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.share),
                                  onPressed: () {
                                    // Handle share action
                                  },
                                ),
                                Text('Share'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
