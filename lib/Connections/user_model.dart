import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String photoURL;
  final String position;
  final int mutualFollowers;
  bool isRequested;  // New field to track follow request status

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.photoURL,
    required this.position,
    required this.mutualFollowers,
    this.isRequested = false,  // Default value
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    return UserModel(
      uid: doc.id,
      firstName: doc['firstName'],
      lastName: doc['lastName'],
      photoURL: doc['photoURL'] ?? '',
      position: doc['position'] ?? '',
      mutualFollowers: doc['mutualFollowers'] ?? 0,
      isRequested: doc['isRequested'] ?? false,  // Set field from document
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'photoURL': photoURL,
      'position': position,
      'mutualFollowers': mutualFollowers,
      'isRequested': isRequested,  // Include field in map
    };
  }
}
