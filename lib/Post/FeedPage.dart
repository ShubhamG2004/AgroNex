import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:share_plus/share_plus.dart';
import '../Connections/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  Map<int, bool> _isExpanded = {};
  Map<int, PageController> _pageControllers = {};
  Map<int, String> _translatedText = {}; // Store translated text for each post

  late final OnDeviceTranslator _onDeviceTranslator = OnDeviceTranslator(
    sourceLanguage: TranslateLanguage.english,
    targetLanguage: TranslateLanguage.hindi, // Default language
  );

  // Method to fetch posts and user data
  // Method to fetch posts and user data
  Future<List<Map<String, dynamic>>> _fetchPosts() async {
    final userCollection = await FirebaseFirestore.instance.collection('users').get();
    final List<Map<String, dynamic>> postList = [];
    final currentUserUid = "yourCurrentUserUid"; // Replace with the actual current user UID

    for (var userDoc in userCollection.docs) {
      final userData = UserModel.fromDocument(userDoc);

      final posts = await FirebaseFirestore.instance
          .collection('blog')
          .doc(userData.uid)
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .get();

      for (var post in posts.docs) {
        final postData = post.data();
        postData['id'] = post.id; // Add the post ID to the post data
        postData['hasLiked'] = (postData['likedBy'] as List<dynamic>? ?? []).contains(currentUserUid);

        postList.add({
          'post': postData,
          'user': userData,
        });
      }
    }
    postList.sort((a, b) => (b['post']['timestamp'] as Timestamp).compareTo(a['post']['timestamp'] as Timestamp));
    return postList;
  }

  // Method to format the time difference
  String _formatTimeDifference(Timestamp timestamp) {
    final now = DateTime.now();
    final postTime = timestamp.toDate();
    final difference = now.difference(postTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  // Method to translate text
  Future<void> _translateText(int index, String text, TranslateLanguage targetLanguage) async {
    setState(() {
      _translatedText[index] = 'Translating...'; // Indicate the translation process
    });

    final translator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: targetLanguage,
    );

    final translation = await translator.translateText(text);
    setState(() {
      _translatedText[index] = translation;
    });

    // Dispose the translator instance after use to free resources
    translator.close();
  }

  Future<void> _toggleLike(String userId, String postId, bool hasLiked) async {
    // Fetch the current user's UID
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;

    final postRef = FirebaseFirestore.instance
        .collection('blog')
        .doc(userId)
        .collection('posts')
        .doc(postId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);

      if (!snapshot.exists) {
        throw Exception('Post does not exist!');
      }

      List<String> likedBy = List.from(snapshot.data()!['likedBy'] as List<dynamic>? ?? []);

      if (hasLiked) {
        // If currently liked by user, do nothing
        if (likedBy.contains(currentUserUid)) {
          return;
        }
        likedBy.add(currentUserUid);
      } else {
        // If not currently liked by user, do nothing
        if (!likedBy.contains(currentUserUid)) {
          return;
        }
        likedBy.remove(currentUserUid);
      }

      // Update the Firestore document with the updated likedBy list and likes count
      transaction.update(postRef, {
        'likedBy': likedBy,
        'likes': likedBy.length, // The number of UIDs in the likedBy list represents the likes count
      });
    });
  }


  // Method to share content
  void _shareContent(String content, String postId) {
    final String postLink = 'https://yourapp.com/posts/$postId'; // Replace with your app's post link format
    final String shareContent = '$content\n\nRead more at: $postLink';

    Share.share(shareContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.grey[200], // Set the background color of the page
        child: FutureBuilder<List<Map<String, dynamic>>>(
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // Remove border radius
                  ),
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
                              onSelected: (value) {
                                TranslateLanguage targetLanguage;

                                switch (value) {
                                  case 'hindi':
                                    targetLanguage = TranslateLanguage.hindi;
                                    break;
                                  case 'tamil':
                                    targetLanguage = TranslateLanguage.tamil;
                                    break;
                                  case 'telugu':
                                    targetLanguage = TranslateLanguage.telugu;
                                    break;
                                  case 'marathi':
                                    targetLanguage = TranslateLanguage.marathi;
                                    break;
                                  default:
                                    return;
                                }

                                _translateText(index, post['thought'], targetLanguage);
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
                                  PopupMenuItem(
                                    value: 'marathi',
                                    child: Text('Convert to Marathi'),
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
                                      _translatedText[index] ?? post['thought'],
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
                                    size: 15,
                                    color: Colors.black,
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
                                  icon: Icon(Icons.arrow_forward_ios, size: 15, color: Colors.black),
                                  onPressed: () {
                                    _pageControllers[index]!.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                                  },
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: 8),
                        Row(
                          children:
                          [
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: IconButton(
                                      icon: post['hasLiked']
                                          ? Icon(Icons.thumb_up, color: Colors.green)
                                          : Icon(Icons.thumb_up_alt_outlined, color: Colors.grey),
                                      onPressed: () async {
                                        setState(() {
                                          // Optimistically update the UI
                                          post['hasLiked'] = !post['hasLiked'];
                                          post['likes'] = post['hasLiked']
                                              ? (post['likes'] ?? 0) + 1
                                              : (post['likes'] ?? 0) - 1;
                                        });

                                        try {
                                          await _toggleLike(user.uid, post['id'], post['hasLiked']);
                                        } catch (e) {
                                          // If there's an error, revert the optimistic UI update
                                          setState(() {
                                            post['hasLiked'] = !post['hasLiked'];
                                            post['likes'] = post['hasLiked']
                                                ? (post['likes'] ?? 0) + 1
                                                : (post['likes'] ?? 0) - 1;
                                          });
                                          print('Error updating like status: $e');
                                        }
                                      },
                                    ),
                                  ),

                                  Text(
                                    '${post['likes']} likes', // Display the number of likes
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),

                                  Expanded(
                                    child: IconButton(
                                      icon: Icon(Icons.comment),
                                      onPressed: () {},
                                    ),
                                  ),
                                  Expanded(
                                    child: IconButton(
                                      icon: Icon(Icons.share),
                                      onPressed: () {
                                        final postId = post['id']; // Get the post ID
                                        _shareContent(post['thought'], postId);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
