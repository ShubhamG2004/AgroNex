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
  Map<String, String> followRequestStatus = {};
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
            followRequestStatus[user.uid] = 'requested';
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
          followersCount = fetchedFollowers.length;
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
      followingCount = fetchedFollowingUsers.length;
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
        setState(() {
          followRequestStatus[user.uid] = 'requested';
        });
      } catch (e) {
        print('Error sending follow request: $e');
      }
    }
  }

  Future<void> cancelFollowRequest(UserModel user) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance.collection('follow_requests').doc(user.uid).delete();

        setState(() {
          followRequestStatus[user.uid] = 'not_requested';
        });
      } catch (e) {
        print('Error canceling follow request: $e');
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
          followersCount += 1;
          followingCount += 1;
          followingUsers.add(user);
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
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Connections'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Connections'),
      ),
      body: RefreshIndicator(
        onRefresh: fetchUsers,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                        child: _buildStatCard('Followers', followersCount, isNavigable: true, followers: followers),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                        child: _buildStatCard('Following', followingCount, isNavigable: true, followingUsers: followingUsers),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                        child: _buildStatCard('Requests', followRequests.length, isNavigable: true, followRequests: followRequests),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.0, 0, 0.0, 0.0),
                child: Text(
                  'Suggestions',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              ),
              GridView.builder(
                padding: EdgeInsets.all(16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.75,
                ),
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  UserModel user = users[index];
                  return _buildUserCard(user);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, {bool isNavigable = false, List<UserModel>? followers, List<UserModel>? followingUsers, List<UserModel>? followRequests}) {
    return GestureDetector(
      onTap: () {
        if (isNavigable) {
          if (title == 'Followers') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FollowersPage(followers: followers!),
              ),
            );
          } else if (title == 'Following') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FollowingPage(following: followingUsers!),
              ),
            );
          } else if (title == 'Requests') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FollowRequestsPage(followRequests: followRequests!, onAccept: acceptFollowRequest, onIgnore: ignoreFollowRequest),
              ),
            );
          }
        }
      },
      child: Container(
        padding: EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 10.0),
            Text(
              count.toString(),
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    bool isRequested = followRequestStatus[user.uid] == 'requested';
    bool isFollowing = followingUserIds.contains(user.uid);

    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(user.photoURL),
            radius: 45.0,
            backgroundColor: Colors.white, // Add this line
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.green, // Change this to the color you want
                  width: 1.0, // Change this to the width you want
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(height: 10.0),
          Text(
            '${user.firstName} ${user.lastName}',
            style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 5.0),
          Text(
            user.position,
            style: TextStyle(fontSize: 12.0, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.0),
          ElevatedButton(
            onPressed: isRequested ? () => cancelFollowRequest(user) : () => sendFollowRequest(user),
            style: ElevatedButton.styleFrom(
              backgroundColor: isRequested ? Colors.white : Colors.white,
              foregroundColor: isRequested ? Colors.red : Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(
                  color: isRequested ? Colors.red : Colors.green,
                  width: 1.0,
                ),
              ),
            ),
            child: Text(isRequested ? 'Cancel' : 'Connect'),
          ),
        ],
      ),
    );
  }
}
