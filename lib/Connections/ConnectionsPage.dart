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
        QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').get();

        // Create a list of user models from the snapshot
        List<UserModel> fetchedUsers =
        snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();

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
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : users.isNotEmpty
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
              padding: EdgeInsets.only(
                left: index % 2 == 0 ? 1.50 : 1.50,
                right: index % 2 == 0 ? 1.50 : 1.50,
                top: 1.50,
                bottom: 1.50,
              ),
              child: GestureDetector(
                onTap: () {
                  // Handle card tap
                  debugPrint(
                      'Card tapped for ${user.firstName} ${user.lastName}');
                },
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(16.0), // Increased padding for a more spacious design
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center, // Center the content
                      children: [
                        Container(
                          width: double.infinity, // Set the width to the maximum available
                          height: 100,
                          alignment: Alignment.center, // Center the child horizontally
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.green, width: 0.8),
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: user.photoURL.isNotEmpty
                                    ? NetworkImage(user.photoURL)
                                    : AssetImage('assets/images/default_avatar.png'),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 11),
                        Text(
                          '${user.firstName} ${user.lastName}',
                          textAlign: TextAlign.center, // Center the text
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${user.position}', // Display position
                          textAlign: TextAlign.center, // Center the text
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '${user.mutualFollowers} Mutual Follower',
                          textAlign: TextAlign.center, // Center the text
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Spacer(),
                        // Follow button with a rounded rectangle shape
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
        )
            : Center(
          child: Text('No connections found'),
        ),
      ),
    );
  }
}
