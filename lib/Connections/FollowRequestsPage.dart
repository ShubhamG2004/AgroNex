import 'package:flutter/material.dart';
import 'user_model.dart';  // Import the UserModel if needed

class FollowRequestsPage extends StatelessWidget {
  const FollowRequestsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Follow Requests'),
      ),
      body: Center(
        child: Text('Follow requests will be displayed here.'),
      ),
    );
  }
}
