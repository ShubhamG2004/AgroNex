import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Connections/user_model.dart'; // Import your UserModel class

class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  Map<int, bool> _isExpanded = {};
  Map<int, PageController> _pageControllers = {};

  // Function to format time difference
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

  // Function to fetch posts and user data
  Future<List<Map<String, dynamic>>> _fetchPosts() async {
    final userCollection = await FirebaseFirestore.instance.collection('users').get();
    final List<Map<String, dynamic>> postList = [];

    for (var userDoc in userCollection.docs) {
      final userData = UserModel.fromDocument(userDoc);

      final posts = await FirebaseFirestore.instance
          .collection('blog')
          .doc(userData.uid) // Access each user's posts
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .get();

      for (var post in posts.docs) {
        final postData = post.data();
        postList.add({
          'post': postData,
          'user': userData,
        });
      }
    }

    postList.sort((a, b) => (b['post']['timestamp'] as Timestamp).compareTo(a['post']['timestamp'] as Timestamp));

    return postList;
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
                          IconButton(
                            icon: Icon(Icons.more_horiz),
                            onPressed: () {
                              // Handle more options action
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
                                    post['thought'],
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
                                icon: Icon(Icons.arrow_back),
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
                                icon: Icon(Icons.arrow_forward),
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
