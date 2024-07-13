import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (mounted) {
        setState(() {
          userData = doc.data() as Map<String, dynamic>?;
        });
      }
    }
  }

  Future<void> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        File image = File(pickedFile.path);
        String fileName = '${user!.uid}.jpg';
        try {
          await FirebaseStorage.instance.ref('profile_images/$fileName').putFile(image);
          String photoURL = await FirebaseStorage.instance.ref('profile_images/$fileName').getDownloadURL();
          await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'photoURL': photoURL});
          setState(() {
            userData!['photoURL'] = photoURL;
          });
        } catch (e) {
          print('Error uploading image: $e');
        }
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> signout() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => signout(),
          ),
        ],
      ),
      body: userData != null
          ? SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: userData!['photoURL'] != null
                        ? NetworkImage(userData!['photoURL'])
                        : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 10,
                    child: GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                child: CustomCard(
                  title: 'Personal Details',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${userData!['firstName']} ',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${userData!['lastName']}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text('Position: ${userData!['Position'] ?? ''}'),
                      Text('About: ${userData!['About'] ?? ''}'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                child: CustomCard(
                  title: 'Contact Details',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${userData!['email']}'),
                      Text('Mobile: ${userData!['Mobile'] ?? ''}'),
                      Text('Address: ${userData!['Address'] ?? ''}'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                child: CustomCard(
                  title: 'Resources',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Blog: ${userData!['Blog'] ?? ''}'),
                      Text('Product: ${userData!['Product'] ?? ''}'),
                      Text('Research: ${userData!['Research'] ?? ''}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : Center(child: CircularProgressIndicator()),
    );
  }
}

class CustomCard extends StatelessWidget {
  final String title;
  final Widget child;

  const CustomCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  child,
                ],
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.edit_outlined,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
