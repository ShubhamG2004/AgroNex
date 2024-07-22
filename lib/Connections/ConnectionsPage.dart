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
        await FirebaseFirestore.instance.collection('follow_requests').add({
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
        await FirebaseFirestore.instance.collection('follow_requests').where('toUserId', isEqualTo: currentUser.uid).where('fromUserId', isEqualTo: user.uid).get().then((snapshot) {
          for (DocumentSnapshot doc in snapshot.docs) {
            doc.reference.delete();
          }
        });

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
        await FirebaseFirestore.instance.collection('follow_requests').where('toUserId', isEqualTo: currentUser.uid).where('fromUserId', isEqualTo: user.uid).get().then((snapshot) {
          for (DocumentSnapshot doc in snapshot.docs) {
            doc.reference.delete();
          }
        });

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
              SizedBox(height: 8), // Space between the border and follow requests title
              _buildFollowRequestsSection(),
              SizedBox(height: 8), // Space between sections
              _buildDiscoverPeopleSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, {bool isNavigable = false, List<UserModel>? followers, List<UserModel>? following}) {
    return InkWell(
      onTap: isNavigable
          ? () {
        if (label == 'Followers' && followers != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FollowersPage(followers: followers)),
          );
        } else if (label == 'Following' && following != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FollowingPage(followingUsers: following)),
          );
        }
      }
          : null,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: Colors.blue,
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4.0),
            Text(
              label,
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowRequestsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (followRequests.isNotEmpty) ...[
            Text(
              'Follow Requests',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Container(
              height: 100.0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: followRequests.length,
                itemBuilder: (context, index) {
                  UserModel user = followRequests[index];
                  return _buildFollowRequestCard(user);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFollowRequestCard(UserModel user) {
    return Container(
      width: 250.0, // Adjusted width for better display
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.grey[200],
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            blurRadius: 5.0,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(user.photoURL),
            radius: 30.0,
          ),
          SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${user.firstName} ${user.lastName}',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user.position,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey[600],
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => acceptFollowRequest(user),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        backgroundColor: Colors.blue,
                        textStyle: TextStyle(color: Colors.white),
                      ),
                      child: Text('Accept'),
                    ),
                    SizedBox(width: 8.0),
                    ElevatedButton(
                      onPressed: () => ignoreFollowRequest(user),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        backgroundColor: Colors.red,
                        textStyle: TextStyle(color: Colors.white),
                      ),
                      child: Text('Ignore'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverPeopleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover People',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.0),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (context, index) {
              UserModel user = users[index];
              return _buildDiscoverPeopleCard(user);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverPeopleCard(UserModel user) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(user.photoURL),
          radius: 30.0,
        ),
        title: Text('${user.firstName} ${user.lastName}'),
        subtitle: Text(user.position),
        trailing: ElevatedButton(
          onPressed: () => sendFollowRequest(user),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            textStyle: TextStyle(color: Colors.white),
          ),
          child: Text('Follow'),
        ),
      ),
    );
  }
}
