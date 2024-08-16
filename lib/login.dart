import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup.dart';
import 'forgot.dart';
import 'AdditionalInfoScreen.dart';
import 'wrapper.dart';

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
    setState(() {
      isLoading = true;
    });
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // Save the user data to Firestore
      await saveUserData(userCredential.user!, googleUser);

      await checkAdditionalInfo(userCredential.user!);
    } catch (e) {
      if (mounted) {
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
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> signIn() async {
    setState(() {
      isLoading = true;
    });
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text,
        password: password.text,
      );

      await checkAdditionalInfo(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Get.snackbar(
          "Error",
          e.message ?? "An error occurred",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: Duration(seconds: 3),
          margin: EdgeInsets.all(10),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> checkAdditionalInfo(User user) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      Get.offAll(() => Wrapper());
    } else {
      Get.to(() => AdditionalInfoScreen(user: user));
    }
  }

  Future<void> saveUserData(User user, GoogleSignInAccount googleUser) async {
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    DocumentSnapshot doc = await userRef.get();
    if (!doc.exists) {
      String displayName = googleUser.displayName ?? '';
      List<String> nameParts = displayName.split(' ');
      String firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Create a new user document
      await userRef.set({
        'uid': user.uid,
        'firstName': firstName,
        'lastName': lastName,
        'Pronouns': '',
        'Position': '',
        'photoURL': googleUser.photoUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'email': user.email,
        'number': '',
        'address': '',
      });

      // Initialize collections for the new user
      await initializeUserCollections(user.uid);
    }
  }

  Future<void> initializeUserCollections(String uid) async {

    await FirebaseFirestore.instance.collection('followers').doc(uid).set({
      'followers': [],
    });

    await FirebaseFirestore.instance.collection('following').doc(uid).set({
      'following': [],
    });

    await FirebaseFirestore.instance.collection('research').doc(uid).set({
      'research': [],
    });

    await FirebaseFirestore.instance.collection('blog').doc(uid).set({
      'blog': [],
    });

    // Initialize product collection
    await FirebaseFirestore.instance.collection('product').doc(uid).set({
      'product': [],
    });
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
      backgroundColor: Colors.white,
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
                    backgroundColor: Color(0xFFC4EAFA), // Light sky blue background
                    padding: EdgeInsets.symmetric(horizontal: 120, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5, // Add elevation for shadow
                    shadowColor: Colors.black.withOpacity(0.9), // Shadow color
                  ),
                  child: Text('Sign In', style: TextStyle(fontSize: 18, color: Colors.black)),
                ),
                SizedBox(height: 20),
                Text('Or continue with'),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () => loginWithGoogle(),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white, // White background color
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: Offset(0, 2), // changes position of shadow
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/google.png',
                          height: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Sign in with Google',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
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
