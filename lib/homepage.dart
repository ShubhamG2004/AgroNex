import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final user = FirebaseAuth.instance.currentUser;

  signout() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut(); // Ensure you have a named route for the login page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo.png', height: 40),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              // Add navigation to profile page or any other action
            },
          ),
        ],
      ),
      body: Center(
        child: Text('${user!.email}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => signout(),
        child: Icon(Icons.logout),
      ),
    );
  }
}
