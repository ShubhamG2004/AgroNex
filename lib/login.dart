import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'signup.dart';
import 'forgot.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool isLoading = false;

  Future<void> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: Duration(seconds: 3),
        margin: EdgeInsets.all(10),
      );
    }
  }

  Future<void> signIn() async {
    setState(() {
      isLoading = true;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text,
        password: password.text,
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Error",
        e.message ?? "An error occurred",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: Duration(seconds: 3),
        margin: EdgeInsets.all(10),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: Duration(seconds: 3),
        margin: EdgeInsets.all(10),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 60),
                Image.asset('assets/images/logo.png', height: 130),
                SizedBox(height: 20),
                Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: email,
                  decoration: InputDecoration(
                    hintText: 'Enter Your E-mail',
                    prefixIcon: Icon(Icons.email, size: 25),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: password,
                  decoration: InputDecoration(
                    hintText: 'Enter Your Password',
                    prefixIcon: Icon(Icons.lock, size: 25),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  obscureText: true,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Get.to(Forgot()),
                    child: Text('Forgot Password?'),
                  ),
                ),
                SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () => signIn(),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 130, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Sign In'),
                ),
                SizedBox(height: 20),
                Text('Or continue with'),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Image.asset('assets/images/google.png', height: 40),
                      iconSize: 50,
                      onPressed: () => loginWithGoogle(),
                    ),
                    SizedBox(width: 20),
                    IconButton(
                      icon: Image.asset('assets/images/apple.png', height: 40),
                      iconSize: 50,
                      onPressed: () {
                        // Add Apple Sign-In functionality here
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () => Get.to(Signup()),
                  child: Text('Not a member? Register now'),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
