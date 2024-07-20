import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:agronex/AdditionalInfoScreen.dart';
import 'package:agronex/wrapper.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  Future<void> signup() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text,
        password: password.text,
      );

      await initializeUserCollections(userCredential.user!.uid);

      Get.to(() => AdditionalInfoScreen(user: userCredential.user!));
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', e.message ?? 'An error occurred',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> initializeUserCollections(String uid) async {
    // Initialize followers collection
    await FirebaseFirestore.instance.collection('followers').doc(uid).set({
      'followers': [], // Empty list of followers
    });

    // Initialize following collection
    await FirebaseFirestore.instance.collection('following').doc(uid).set({
      'following': [], // Empty list of following
    });

    // Initialize research collection
    await FirebaseFirestore.instance.collection('research').doc(uid).set({
      'research': [], // Empty list of research
    });

    // Initialize blog collection
    await FirebaseFirestore.instance.collection('blog').doc(uid).set({
      'blog': [], // Empty list of blog
    });

    // Initialize product collection
    await FirebaseFirestore.instance.collection('product').doc(uid).set({
      'product': [], // Empty list of product
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // Navigate back to the previous screen
          },
        ),
        title: Text('Signup'), // Optional: Add a title to the app bar
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                ),
                SizedBox(height: 20),
                Text(
                  'Register Here!',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: email,
                  decoration: InputDecoration(
                    hintText: 'Enter your e-mail',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: password,
                  decoration: InputDecoration(
                    hintText: 'Enter password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => signup(),
                    child: Text('Sign Up'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
