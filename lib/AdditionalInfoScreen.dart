import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:agronex/wrapper.dart';

class AdditionalInfoScreen extends StatefulWidget {
  final User user;

  const AdditionalInfoScreen({Key? key, required this.user}) : super(key: key);

  @override
  _AdditionalInfoScreenState createState() => _AdditionalInfoScreenState();
}

class _AdditionalInfoScreenState extends State<AdditionalInfoScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();

  Future<void> saveAdditionalInfo() async {
    try {
      String firstName = nameController.text;
      String lastName = surnameController.text;
      String photoUrl = widget.user.photoURL ?? '';

      if (photoUrl.isEmpty) {
        photoUrl = 'https://via.placeholder.com/150?text=${firstName[0]}';
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': widget.user.email,
        'uid': widget.user.uid,
        'photoURL': photoUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Get.offAll(() => Wrapper()); // Navigate to Wrapper screen
    } catch (e) {
      Get.snackbar('Error', 'Failed to save information: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Additional Info')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: surnameController,
              decoration: InputDecoration(labelText: 'Surname'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveAdditionalInfo,
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
