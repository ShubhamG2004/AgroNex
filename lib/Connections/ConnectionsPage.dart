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
  Map<String, bool> followRequestSent = {};

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

        // Fetch follow request state for each user
        for (var user in users) {
          bool requestSent = await checkIfFollowRequestSent(user.uid);
          setState(() {
            followRequestSent[user.uid] = requestSent;
          });
        }
      } catch (e) {
        print('Error fetching users: $e');
      }
    } else {
      print('User is not authenticated');
    }
  }

  Future<bool> checkIfFollowRequestSent(String userId) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('follow_requests').doc(userId).get();
      return doc.exists;
    }
    return false;
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
        setState(() {
          followRequestSent[user.uid] = true;
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
        print('Follow request cancelled for ${user.uid}');
        setState(() {
          followRequestSent[user.uid] = false;
        });
      } catch (e) {
        print('Error cancelling follow request: $e');
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
      appBar: AppBar(
        title: const Text('Connections'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Followers: $followersCount, Following: $followingCount'),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              itemBuilder: (context, index) {
                UserModel user = users[index];
                bool isRequestSent = followRequestSent[user.uid] ?? false;
                return Card(
                  child: ListTile(
                    title: Text(user.username ?? 'No Username'),
                    subtitle: Text(user.email ?? 'No Email'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        if (isRequestSent) {
                          cancelFollowRequest(user);
                        } else {
                          sendFollowRequest(user);
                        }
                      },
                      child: Text(isRequestSent ? 'Request Sent' : 'Follow'),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16.0),
            const Text('Follow Requests', style: TextStyle(fontSize: 20.0)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: followRequests.length,
              itemBuilder: (context, index) {
                UserModel user = followRequests[index];
                return Card(
                  child: ListTile(
                    title: Text(user.username ?? 'No Username'),
                    subtitle: Text(user.email ?? 'No Email'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () => acceptFollowRequest(user),
                          child: const Text('Accept'),
                        ),
                        const SizedBox(width: 8.0),
                        ElevatedButton(
                          onPressed: () => ignoreFollowRequest(user),
                          child: const Text('Ignore'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16.0),
            const Text('Followers', style: TextStyle(fontSize: 20.0)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: followers.length,
              itemBuilder: (context, index) {
                UserModel user = followers[index];
                return Card(
                  child: ListTile(
                    title: Text(user.username ?? 'No Username'),
                    subtitle: Text(user.email ?? 'No Email'),
                  ),
                );
              },
            ),
            const SizedBox(height: 16.0),
            const Text('Following', style: TextStyle(fontSize: 20.0)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: followingUsers.length,
              itemBuilder: (context, index) {
                UserModel user = followingUsers[index];
                return Card(
                  child: ListTile(
                    title: Text(user.username ?? 'No Username'),
                    subtitle: Text(user.email ?? 'No Email'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
