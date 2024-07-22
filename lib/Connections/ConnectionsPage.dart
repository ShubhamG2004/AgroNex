import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_model.dart';
import 'FollowRequestsPage.dart';
import 'FollowersPage.dart';
import 'FollowingPage.dart';

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({Key? key}) : super(key: key);

  @override
  _ConnectionsPageState createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  List<UserModel> users = [];
  List<UserModel> followRequests = [];
  List<UserModel> followers = [];
  List<UserModel> followingUsers = [];
  List<String> followingUserIds = [];
  bool isLoading = true;
  int followersCount = 0;
  int followingCount = 0;

  @override
  void initState() {
    super.initState();
    fetchUsers();
    fetchFollowRequests();
    fetchFollowers();
    fetchFollowingUsers();
  }

  Future<void> fetchUsers() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        // Fetch current user's data for counts
        DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        Map<String, dynamic>? currentUserData = currentUserDoc.data() as Map<String, dynamic>?;

        if (currentUserData != null) {
          setState(() {
            followersCount = currentUserData['followers_count'] ?? 0;
            followingCount = currentUserData['following_count'] ?? 0;
          });
        }

        // Fetch all users excluding the current user
        QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').where('uid', isNotEqualTo: currentUser.uid).get();
        List<UserModel> fetchedUsers = snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();

        // Fetch the list of user IDs that the current user is following
        await fetchFollowingUserIds();
        List<UserModel> filteredUsers = fetchedUsers.where((user) => !followingUserIds.contains(user.uid)).toList();

        setState(() {
          users = filteredUsers;
          isLoading = false;
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

          // Check if the user is already a follower or following
          if (!followers.any((follower) => follower.uid == user.uid) && !followingUserIds.contains(user.uid)) {
            requests.add(user);
          }
        }

        setState(() {
          followRequests = requests;
        });
      } catch (e) {
        print('Error fetching follow requests: $e');
      }
    } else {
      print('User is not authenticated');
    }
  }

  Future<void> fetchFollowers() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        DocumentSnapshot followersDoc = await FirebaseFirestore.instance.collection('followers').doc(currentUser.uid).get();
        Map<String, dynamic>? data = followersDoc.data() as Map<String, dynamic>?;

        List<String> followerIds = List<String>.from(data?['followers'] ?? []);
        List<UserModel> fetchedFollowers = [];

        for (String uid in followerIds) {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (userDoc.exists) {
            fetchedFollowers.add(UserModel.fromDocument(userDoc));
          }
        }

        setState(() {
          followers = fetchedFollowers;
          followersCount = fetchedFollowers.length; // Update followers count
        });
      } catch (e) {
        print('Error fetching followers: $e');
      }
    } else {
      print('User is not authenticated');
    }
  }

  Future<void> fetchFollowingUserIds() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        DocumentSnapshot followingDoc = await FirebaseFirestore.instance.collection('following').doc(currentUser.uid).get();
        Map<String, dynamic>? data = followingDoc.data() as Map<String, dynamic>?;
        followingUserIds = List<String>.from(data?['following'] ?? []);
      } catch (e) {
        print('Error fetching following users: $e');
      }
    }
  }

  Future<void> fetchFollowingUsers() async {
    await fetchFollowingUserIds();
    List<UserModel> fetchedFollowingUsers = [];

    for (String uid in followingUserIds) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        fetchedFollowingUsers.add(UserModel.fromDocument(userDoc));
      }
    }

    setState(() {
      followingUsers = fetchedFollowingUsers;
      followingCount = fetchedFollowingUsers.length; // Update following count
    });
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
        // Update followers count for the user
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'followers_count': FieldValue.increment(1),
        });

        // Update following count for the current user
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'following_count': FieldValue.increment(1),
        });

        // Add user to the following list
        await FirebaseFirestore.instance.collection('following').doc(currentUser.uid).update({
          'following': FieldValue.arrayUnion([user.uid]),
        });

        // Add current user to the follower list
        await FirebaseFirestore.instance.collection('followers').doc(user.uid).update({
          'followers': FieldValue.arrayUnion([currentUser.uid]),
        });

        // Remove follow request
        await FirebaseFirestore.instance.collection('follow_requests').doc(user.uid).delete();

        // Update UI
        setState(() {
          followRequests.removeWhere((request) => request.uid == user.uid);
          followersCount += 1; // Increment followers count
          followingCount += 1; // Increment following count
          followingUsers.add(user); // Add user to followingUsers
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
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.0), // Reduced height
              Padding(
                padding: const EdgeInsets.fromLTRB(35.0, 0.0, 35.0, 0.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('Followers', followersCount, isNavigable: true, followers: followers),
                    ),
                    SizedBox(width: 5), // Space between the cards
                    Expanded(
                      child: _buildStatCard('Following', followingCount, isNavigable: true, following: followingUsers),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Container(
                color: Colors.grey,
                height: 0.5, // Reduced height
                width: double.infinity,
              ),
              SizedBox(height: 8), // Space between the border and follow requests
              if (followRequests.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
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
                      SizedBox(height: 8),
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(color: Colors.grey, width: 0.5),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(8.0),
                          child: Column(
                            children: followRequests.map((request) {
                              return ListTile(
                                contentPadding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundImage: request.photoURL.isNotEmpty
                                      ? NetworkImage(request.photoURL)
                                      : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                                ),
                                title: Text('${request.firstName} ${request.lastName}'),
                                subtitle: Text('${request.firstName} wants to follow you'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => acceptFollowRequest(request),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                      child: Text('Accept'),
                                    ),
                                    SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => ignoreFollowRequest(request),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                      child: Text('Ignore'),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (users.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Container(
                        color: Colors.grey,
                        height: 0.5, // Border above the user profile cards
                        width: double.infinity,
                      ),
                      SizedBox(height: 8), // Space between the border and user profile cards
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Users You might Be Follow',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                      ),
                      GridView.builder(
                        shrinkWrap: true, // Allows GridView to take only the space it needs
                        physics: NeverScrollableScrollPhysics(), // Disables GridView scrolling
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                          childAspectRatio: 0.74,
                        ),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          UserModel user = users[index];
                          return GestureDetector(
                            onTap: () {
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
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundImage: user.photoURL.isNotEmpty
                                          ? NetworkImage(user.photoURL)
                                          : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '${user.firstName} ${user.lastName}',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${user.position}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () => sendFollowRequest(user),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.green,
                                        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 35),
                                        side: BorderSide(color: Colors.green, width: 1),
                                      ),
                                      child: Text('Follow'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, {bool isNavigable = false, List<UserModel> followers = const [], List<UserModel> following = const []}) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: Colors.grey, width: 0.5),
      ),
      child: InkWell(
        onTap: () {
          if (isNavigable) {
            if (title == 'Followers') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FollowersPage(followers: followers),
                ),
              );
            } else if (title == 'Following') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FollowingPage(following: following),
                ),
              );
            }
          }
        },
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4), // Reduced gap between text and count
              Text(
                count.toString(),
                style: TextStyle(fontSize: 24, color: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
