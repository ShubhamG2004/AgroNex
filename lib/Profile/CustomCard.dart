import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onUpdate;
  final User user; // Ensure user object is passed from parent

  const CustomCard({
    required this.title,
    required this.userData,
    required this.onUpdate,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => showEditPersonalDetailsDialog(context),
                    child: Icon(Icons.edit_outlined, color: Colors.black),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '${userData['firstName']} ${userData['lastName']}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text('Position: ${userData['Position'] ?? ''}'),
              Text('About: ${userData['About'] ?? ''}'),
            ],
          ),
        ),
      ),
    );
  }

  void showEditPersonalDetailsDialog(BuildContext context) {
    String firstName = userData['firstName'];
    String lastName = userData['lastName'];
    String position = userData['Position'] ?? '';
    String about = userData['About'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Personal Details'),
          contentPadding: EdgeInsets.zero, // Remove default padding
          content: Container(
            width: MediaQuery.of(context).size.width * 0.9, // 90% of screen width
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
                    initialValue: firstName,
                    decoration: InputDecoration(labelText: 'First Name'),
                    onChanged: (value) => firstName = value,
                  ),
                  TextFormField(
                    initialValue: lastName,
                    decoration: InputDecoration(labelText: 'Last Name'),
                    onChanged: (value) => lastName = value,
                  ),
                  TextFormField(
                    initialValue: position,
                    decoration: InputDecoration(labelText: 'Position'),
                    onChanged: (value) => position = value,
                  ),
                  TextFormField(
                    initialValue: about,
                    maxLines: null, // Allows for multiple lines of input
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(labelText: 'About'),
                    onChanged: (value) => about = value,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Update Firestore with new data
                Map<String, dynamic> updatedData = {
                  'firstName': firstName,
                  'lastName': lastName,
                  'Position': position,
                  'About': about,
                };
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid) // Access user's uid from passed user object
                    .update(updatedData);

                // Update UI
                onUpdate(updatedData);

                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
