import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    if (user != null) {
      DocumentSnapshot doc =
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
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
        img.Image resizedImage = img.copyResize(image!, width: 300);
        File resizedFile = File(imageFile.path)
          ..writeAsBytesSync(img.encodeJpg(resizedImage));

        String fileName = '${user!.uid}.jpg';
        try {
          // Upload resized image to Firebase Storage
          await FirebaseStorage.instance.ref('profile_images/$fileName').putFile(resizedFile);
          String photoURL =
          await FirebaseStorage.instance.ref('profile_images/$fileName').getDownloadURL();

          // Update Firestore with resized image URL
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .update({'photoURL': photoURL});

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

  Future<void> deleteImage() async {
    if (userData!['photoURL'] != null) {
      try {
        await FirebaseStorage.instance.refFromURL(userData!['photoURL']).delete();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({'photoURL': FieldValue.delete()});
        setState(() {
          userData!.remove('photoURL');
        });
      } catch (e) {
        print('Error deleting image: $e');
      }
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
        return AlertDialog(
          content: Container(
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
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                showEditOptions();
              },
              child: Text('Edit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                deleteImage();
              },
              child: Text('Delete'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
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
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete Image'),
                onTap: () {
                  Navigator.pop(context);
                  deleteImage();
                },
              ),
            ],
          ),
        );
      },
    );
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
                onTap: showEditOptions,
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
                  userData: userData ?? {},
                  onUpdate: (updatedData) {
                    setState(() {
                      userData?.addAll(updatedData);
                    });
                  },
                  user: user, // Pass user object here
                ),
              ),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                child: CustomCard(
                  title: 'Contact Details',
                  userData: userData ?? {},
                  onUpdate: (updatedData) {
                    setState(() {
                      userData?.addAll(updatedData);
                    });
                  },
                  user: user, // Pass user object here
                ),
              ),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                child: CustomCard(
                  title: 'Resources',
                  userData: userData ?? {},
                  onUpdate: (updatedData) {
                    setState(() {
                      userData?.addAll(updatedData);
                    });
                  },
                  user: user, // Pass user object here
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
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onUpdate;
  final User? user;

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
        margin: EdgeInsets.symmetric(vertical: 8),
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  decoration: InputDecoration(labelText: 'About'),
                  onChanged: (value) => about = value,
                ),
              ],
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
                    .doc(user!.uid)
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
