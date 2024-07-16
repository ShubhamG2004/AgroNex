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

    if (currentUser!= null) {
      try {
        // Retrieve users from the 'users' collection
        QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').get();

        // Create a list of user models from the snapshot
        List<UserModel> fetchedUsers = snapshot.docs
            .map((doc) => UserModel.fromDocument(doc))
            .toList();

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
      appBar: AppBar(
        title: const Text('Connections'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : users.isNotEmpty
          ? GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 0.8, // Adjust the aspect ratio to increase the height of the cards
        ),
        itemCount: users.length,
        itemBuilder: (context, index) {
          UserModel user = users[index];
          return GestureDetector(
            onTap: () {
              // Handle card tap
              debugPrint('Card tapped for ${user.firstName} ${user.lastName}');
            },
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0), // Increased radius for a more rounded corner
              ),
              child: Container(
                padding: EdgeInsets.all(16.0), // Increased padding for a more spacious design
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity, // Set the width to the maximum available
                      height: 60,
                      alignment: Alignment.center, // Center the child horizontally
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: user.photoURL.isNotEmpty
                                ? NetworkImage(user.photoURL)
                                : AssetImage('assets/images/default_avatar.png'),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '${user.firstName} ${user.lastName}',
                      textAlign: TextAlign.center, // Move this line
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${user.position}', // Display position
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${user.mutualFollowers} mutual connections',
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
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: TextStyle(
                          inherit: false, // Set inherit to false
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ).copyWith(
                          elevation: MaterialStateProperty.all<double>(2)),
                      child: Text('Connect'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      )
          : Center(
        child: Text('No users found.'),
      ),
    );
  }
}