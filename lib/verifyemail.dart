import 'package:agronex/homepage.dart';
import 'package:agronex/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';


class Verify extends StatefulWidget {
  const Verify({super.key});

  @override
  State<Verify> createState() => _VerifyState();
}

class _VerifyState extends State<Verify> {

  @override
  void initState(){
    super.initState();
    sendVerifyLink();
  }

  sendVerifyLink() async {
    final user = FirebaseAuth.instance.currentUser!;
    try {
      await user.sendEmailVerification();
      Get.snackbar('Link Sent', 'A verification link has been sent to your email.', margin: EdgeInsets.all(30), snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'too-many-requests') {
        Get.snackbar('Error', 'Too many requests. Please try again later.', margin: EdgeInsets.all(30), snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Error', e.toString(), margin: EdgeInsets.all(30), snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  reload() async {
    await FirebaseAuth.instance.currentUser!.reload();
    Get.offAll(Wrapper());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Please verify your email address'),
            ElevatedButton(
              onPressed: sendVerifyLink,
              child: Text('Resend Verification Email'),
            ),
            ElevatedButton(
              onPressed: reload,
              child: Text('I have verified'),
            ),
          ],
        ),
      ),
    );
  }
}
