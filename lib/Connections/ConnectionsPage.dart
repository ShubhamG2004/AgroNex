import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_model.dart';

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({Key? key}) : super(key: key);

  @override
  _ConnectionsPageState createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  List<UserModel> users = [];
  List<UserModel> followRequests = [];
  bool isLoading = true;
  int followersCount = 0;
  int followingCount = 0;

  @override
  void initState() {
    super.initState();
    fetchUsers();
    fetchFollowRequests();
  }

  Future<void> fetchUsers() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();
        DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        Map<String, dynamic>? currentUserData = currentUserDoc.data() as Map<String, dynamic>?;

        if (currentUserData != null) {
          followersCount = currentUserData['followers_count'] ?? 0;
          followingCount = currentUserData['following_count'] ?? 0;
        }

        List<UserModel> fetchedUsers = snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();

        setState(() {
          users = fetchedUsers;
        });
      } catch (e) {
        print('Error fetching users: $e');
      }
    } else {
      print('User is not authenticated');
    }
  }

  Future<void> fetchFollowRequests() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('follow_requests').where('toUserId', isEqualTo: currentUser.uid).get();

        List<UserModel> requests = [];
        for (var doc in snapshot.docs) {
          var fromUserId = doc['fromUserId'];
          var userDoc = await FirebaseFirestore.instance.collection('users').doc(fromUserId).get();
          var user = UserModel.fromDocument(userDoc);
          requests.add(user);
        }

        setState(() {
          followRequests = requests;
          isLoading = false;
        });
      } catch (e) {
        print('Error fetching follow requests: $e');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      print('User is not authenticated');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> sendFollowRequest(UserModel user) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance.collection('follow_requests').doc(user.uid).set({
          'fromUserId': currentUser.uid,
          'toUserId': user.uid,
        });
        print('Follow request sent to ${user.uid}');
      } catch (e) {
        print('Error sending follow request: $e');
      }
    }
  }

  Future<void> acceptFollowRequest(UserModel user) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance.collection('followers').doc(user.uid).update({
          'followers': FieldValue.arrayUnion([currentUser.uid]),
        });

        await FirebaseFirestore.instance.collection('following').doc(currentUser.uid).update({
          'following': FieldValue.arrayUnion([user.uid]),
        });

        await FirebaseFirestore.instance.collection('follow_requests').doc(user.uid).delete();

        setState(() {
          followRequests.removeWhere((request) => request.uid == user.uid);
        });
      } catch (e) {
        print('Error accepting follow request: $e');
      }
    }
  }

  Future<void> ignoreFollowRequest(UserModel user) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance.collection('follow_requests').doc(user.uid).delete();

        setState(() {
          followRequests.removeWhere((request) => request.uid == user.uid);
        });
      } catch (e) {
        print('Error ignoring follow request: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 5, right: 5, bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('Followers', followersCount, isNavigable: true),
                  _buildStatCard('Following', followingCount, isNavigable: true),
                ],
              ),
            ),
            if (followRequests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 0, left: 8, right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Follow Requests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_forward),
                          color: Colors.black,
                          onPressed: () {
                            // Navigate to Follow Requests page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FollowRequestsPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    ...followRequests.map((user) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(color: Colors.grey, width: 0.5),
                        ),
                        child: Container(
                          width: MediaQuery.of(context).size.width - 15,
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                            leading: CircleAvatar(
                              radius: 18, // Smaller profile photo
                              backgroundImage: user.photoURL.isNotEmpty
                                  ? NetworkImage(user.photoURL)
                                  : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                            ),
                            title: Text(
                              '${user.firstName} ${user.lastName}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Smaller username font size
                            ),
                            subtitle: Text('${user.position} wants to follow you',
                              style: TextStyle(fontSize: 14),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () => acceptFollowRequest(user),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.green,
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    side: BorderSide(color: Colors.green, width: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.0),
                                    ),
                                  ),
                                  child: Text('Accept', style: TextStyle(fontSize: 12)),
                                ),
                                SizedBox(width: 4),
                                ElevatedButton(
                                  onPressed: () => ignoreFollowRequest(user),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.red,
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    side: BorderSide(color: Colors.red, width: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.0),
                                    ),
                                  ),
                                  child: Text('Ignore', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            Expanded(
              child: users.isNotEmpty
                  ? GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 2.0,
                  mainAxisSpacing: 1.0,
                  childAspectRatio: 0.74,
                ),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  UserModel user = users[index];
                  return Padding(
                    padding: EdgeInsets.all(1.50),
                    child: GestureDetector(
                      onTap: () {
                        // Handle card tap
                        debugPrint('Card tapped for ${user.firstName} ${user.lastName}');
                      },
                      child: Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          side: BorderSide(color: Colors.grey, width: 0.5),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 100,
                                alignment: Alignment.center,
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.green,
                                  backgroundImage: user.photoURL.isNotEmpty
                                      ? NetworkImage(user.photoURL)
                                      : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                                ),
                              ),
                              SizedBox(height: 11),
                              Text(
                                '${user.firstName} ${user.lastName}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${user.position}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                '${user.mutualFollowers} Mutual Follower${user.mutualFollowers != 1 ? 's' : ''}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Spacer(),
                              ElevatedButton(
                                onPressed: () {
                                  sendFollowRequest(user);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(horizontal: 35, vertical: 5),
                                  side: BorderSide(color: Colors.green, width: 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                ),
                                child: Text('Follow'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
                  : Center(
                child: Text('No connections found'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, {bool isNavigable = false}) {
    String formattedCount = _formatCount(count);
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: Colors.grey, width: 0.5),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        width: MediaQuery.of(context).size.width / 2 - 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  formattedCount,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isNavigable ? Colors.black : Colors.black,
                  ),
                ),
                if (isNavigable)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Image.asset(
                      'assets/images/arrow.png',
                      width: 18,
                      height: 18,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 1),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

// Create a new page for Follow Requests
class FollowRequestsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Follow Requests'),
      ),
      body: Center(
        child: Text('Follow Requests Page'),
      ),
    );
  }
}
