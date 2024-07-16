import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String firstName;
  final String lastName;
  final String email;
  final String photoURL;
  final String position;
  final int mutualFollowers;

  UserModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.photoURL,
    this.position = 'Unknown Position',
    this.mutualFollowers = 0,
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserModel(
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      photoURL: data['photoURL'] ?? '',
      position: data['Position'] ?? 'Unknown Position',  // Provide default value
      mutualFollowers: data['mutualFollowers'] ?? 0,    // Provide default value if needed
    );
  }
}
