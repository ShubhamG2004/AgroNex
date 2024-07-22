import 'package:flutter/material.dart';
import 'user_model.dart';

class FollowersPage extends StatelessWidget {
  final List<UserModel> followers;

  const FollowersPage({Key? key, required this.followers}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Followers'),
        backgroundColor: Colors.white, // Set app bar background color to white
      ),
      body: Container(
        color: Colors.white, // Set page background color to white
        child: followers.isNotEmpty
            ? ListView.builder(
          itemCount: followers.length,
          itemBuilder: (context, index) {
            UserModel user = followers[index];
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white, // Set background color to white
              ),
              margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                leading: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 0.8), // Set border color to green and width to 2
                    shape: BoxShape.circle, // Make the border a circle
                  ),
                  child: CircleAvatar(
                    backgroundImage: user.photoURL.isNotEmpty
                        ? NetworkImage(user.photoURL)
                        : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                    radius: 22, // Adjust the radius to fit inside the border
                  ),
                ),
                title: Text('${user.firstName} ${user.lastName}'),
                subtitle: Text(user.position),
                trailing: IconButton(
                  onPressed: () {
                    // Define what happens when the button is pressed
                    print('Message ${user.firstName}');
                  },
                  icon: Transform.scale(
                    scale: 1.3, // Increase the size of the icon by 1.5 times
                    child: Icon(Icons.message, color: Colors.green), // Set message icon with green color
                  ),
                ),
              ),
            );
          },
        )
            : Center(
          child: Text('No followers yet', style: TextStyle(color: Colors.black)), // Set text color to black
        ),
      ),
    );
  }
}