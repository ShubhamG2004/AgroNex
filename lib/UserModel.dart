class UserModel {
  String id;
  String name;
  String surname;
  String email;
  String about;
  DateTime timestamp;

  UserModel({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    required this.about,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'email': email,
      'about': about,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      surname: map['surname'],
      email: map['email'],
      about: map['about'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
