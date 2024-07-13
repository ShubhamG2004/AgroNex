import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img; // Import image package

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
        File imageFile = File(pickedFile.path);

        // Resize the image using the image package
        final bytes = await imageFile.readAsBytes();
        img.Image? image = img.decodeImage(bytes);
        img.Image resizedImage = img.copyResize(image!, width: 300); // Resize width to 300 pixels
        File resizedFile = File(imageFile.path)
          ..writeAsBytesSync(img.encodeJpg(resizedImage)); // Convert to jpg and save as file

        String fileName = '${user!.uid}.jpg';
        try {
          // Upload resized image to Firebase Storage
          await FirebaseStorage.instance.ref('profile_images/$fileName').putFile(resizedFile);
          String photoURL = await FirebaseStorage.instance.ref('profile_images/$fileName').getDownloadURL();

          // Update Firestore with resized image URL
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

  void showProfileImageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: userData!['photoURL'] != null
                    ? NetworkImage(userData!['photoURL'])
                    : AssetImage('assets/images/default_avatar.png') as ImageProvider,
              ),
            ),
          ),
        );
      },
    );
  }

  void showEditOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.image),
                title: Text('View Image'),
                onTap: () {
                  Navigator.pop(context);
                  showProfileImageDialog();
                },
              ),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit Image'),
                onTap: () async {
                  Navigator.pop(context);
                  await pickImage();
                  showImageEditOptions();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void showImageEditOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => resizeImage(),
                child: Text('Resize Image'),
              ),
              TextButton(
                onPressed: () => changeImageColor(),
                child: Text('Change Color'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await saveImageEdits();
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> resizeImage() async {
    // Implement image resizing logic here
    // ...
  }

  Future<void> changeImageColor() async {
    // Implement image color changing logic here
    // ...
  }

  Future<void> saveImageEdits() async {
    // Implement logic to save the edited image to Firebase Storage and Firestore
    // ...
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
              GestureDetector(
                onTap: showEditOptions, // Show options to view or edit image
                child: Stack(
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
                  ],
                ),
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
