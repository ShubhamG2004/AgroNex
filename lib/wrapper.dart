import 'package:agronex/homepage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agronex/verifyemail.dart';


import 'login.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              if (snapshot.data!.emailVerified) {
                return Homepage();
              } else {
                return Verify();
              }
            } else {
              return Login();
            }
          } else {
            // You can show a loading spinner while waiting for the connection
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
