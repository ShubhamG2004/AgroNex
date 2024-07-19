import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_model.dart'; // Import your user model

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({Key? key}) : super(key: key);

  @override
  _ConnectionsPageState createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  List<UserModel> users = [];
  bool isLoading = true; // Track loading state
  int followersCount = 0; // Followers count
  int followingCount = 0; // Following count

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        // Retrieve users from the 'users' collection
        QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();

        // Retrieve the current user data
        DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        Map<String, dynamic>? currentUserData = currentUserDoc.data() as Map<String, dynamic>?;

        if (currentUserData != null) {
          // Update follower and following count
          followersCount = currentUserData['followers_count'] ?? 10000000;
          followingCount = currentUserData['following_count'] ?? 230;
        }

        // Create a list of user models from the snapshot
        List<UserModel> fetchedUsers = snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();

        // Update the user list in the UI
        setState(() {
          users = fetchedUsers;
          isLoading = false; // Update loading state
        });
      } catch (e) {
        print('Error fetching users: $e');
        // Handle error gracefully, show message to user
        setState(() {
          isLoading = false; // Update loading state
        });
      }
    } else {
      print('User is not authenticated');
      // Handle case where user is not authenticated
      setState(() {
        isLoading = false; // Update loading state
      });
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
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('Followers', followersCount, isNavigable: true),
                  _buildStatCard('Following', followingCount, isNavigable: true),
                ],
              ),
            ),
            Expanded(
              child: users.isNotEmpty
                  ? Container(
                color: Colors.white,
                child: GridView.builder(
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
                                    // Follow button functionality
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
                ),
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
    String formattedCount = _formatCount(count); // Format the count
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: Colors.grey, width: 0.5), // Thin border
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Reduced height
        width: MediaQuery.of(context).size.width / 2 - 32, // Adjust width as needed
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display the count and arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  formattedCount,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isNavigable? Colors.black : Colors.black,
                  ),
                ),
                if (isNavigable)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0), // Reduced padding
                    child: Image.asset(
                      'assets/images/arrow.png',
                      width: 18,
                      height: 18,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 1), // Reduced height
            // Display the title
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
  // Helper function to format the count with K and M
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M'; // Millions
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K'; // Thousands
    }
    return count.toString(); // Less than a thousand
  }
}
