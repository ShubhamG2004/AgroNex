import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class PostPage extends StatefulWidget {
  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  TextEditingController _thoughtController = TextEditingController();
  List<File> _selectedPhotos = []; // Store the selected photos
  List<String> _photoUrls = []; // Store the URLs of uploaded photos

  // Method to handle photo upload
  void _addPhotos() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      setState(() {
        _selectedPhotos = pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();
      });
    }
  }

  // Method to save the post to Firestore
  void _savePost() async {
    String thought = _thoughtController.text.trim();
    if (thought.isEmpty) {
      // Show an error message if thought is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please write something for the post')),
      );
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;

      // Upload selected photos to Firebase Storage
      for (File photo in _selectedPhotos) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        UploadTask uploadTask = FirebaseStorage.instance
            .ref()
            .child('post_photos')
            .child(fileName)
            .putFile(photo);

        TaskSnapshot taskSnapshot = await uploadTask;
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        _photoUrls.add(downloadUrl);
      }

      CollectionReference blogCollection = FirebaseFirestore.instance.collection('blog').doc(uid).collection('posts');

      await blogCollection.add({
        'thought': thought,
        'photos': _photoUrls,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': [],
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post saved successfully')),
      );

      // Clear the input
      _thoughtController.clear();
      setState(() {
        _selectedPhotos = [];
        _photoUrls = [];
      });

      // Navigate back
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Post'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _savePost,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _thoughtController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Write your thought...',
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_selectedPhotos.isNotEmpty)
              Container(
                height: 130,
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedPhotos.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 4.0,
                    crossAxisSpacing: 4.0,
                  ),
                  itemBuilder: (context, index) {
                    return Image.file(_selectedPhotos[index]);
                  },
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: IconButton(
                icon: Icon(Icons.add_photo_alternate, size: 35),
                onPressed: _addPhotos,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
