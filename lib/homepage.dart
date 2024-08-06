import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile/ProfilePage.dart';
import 'Connections/ConnectionsPage.dart';
import 'Message/MessageListPage.dart';
import './Post/PostPage.dart';
import './Post/FeedPage.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;
  PageController _pageController = PageController();
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  List<String> searchResults = ['Result 1', 'Result 2', 'Result 3'];
  bool _hasUnreadMessages = false;

  @override
  void initState() {
    super.initState();
    _checkForUnreadMessages();
  }

  Future<void> _checkForUnreadMessages() async {
    if (user != null) {
      QuerySnapshot unreadMessages = await FirebaseFirestore.instance
          .collection('messages')
          .where('receiverId', isEqualTo: user!.uid)
          .where('seen', isEqualTo: false)
          .get();

      setState(() {
        _hasUnreadMessages = unreadMessages.docs.isNotEmpty;
      });
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login'); // Navigate to login page
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      // Navigate to PostPage on 'Post' tab click
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PostPage()),
      );
    } else {
      // Update the selected index and page view controller
      setState(() {
        _selectedIndex = index;
      });
      _pageController.jumpToPage(index);
    }
  }

  void _performSearch(String query) {
    // Simulate search logic here
    setState(() {
      searchResults = ['Result 1', 'Result 2', 'Result 3']
          .where((result) => result.contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0), // Adjusted height
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, // Set background color of the AppBar to white
            border: Border(
              bottom: BorderSide(color: Colors.grey, width: 0.5), // Bottom border
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: _isSearching
                ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search...',
                border: InputBorder.none,
              ),
              style: TextStyle(color: Colors.black, fontSize: 16.0),
              onChanged: _performSearch,
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset('assets/images/logo.png', height: 30),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.search, color: Colors.black),
                      onPressed: () {
                        setState(() {
                          _isSearching = true;
                        });
                      },
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: Icon(Icons.message, color: Colors.black),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => MessageListPage()),
                            );
                          },
                        ),
                        if (_hasUnreadMessages)
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.account_circle, color: Colors.black),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProfilePage()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            leading: _isSearching
                ? IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                });
                _searchController.clear();
                searchResults = ['Result 1', 'Result 2', 'Result 3'];
              },
            )
                : null,
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          FeedPage(), // Integrate FeedPage here
          ConnectionsPage(),
          Center(child: Text('Placeholder for Post Page')), // Placeholder for Post page
          Center(child: Text('Blog Page')), // Placeholder for Blog page
          Center(child: Text('Notifications Page')), // Placeholder for Notifications page
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _signOut,
        child: Icon(Icons.logout),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey, width: 0.5), // Top border
          ),
        ),
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.0),
                child: Icon(Icons.home, size: 22),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.0),
                child: Icon(Icons.search, size: 22),
              ),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.0),
                child: Icon(Icons.add_circle, size: 30),
              ),
              label: 'Post',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.0),
                child: Icon(Icons.library_books, size: 22),
              ),
              label: 'Blog',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Icon(Icons.notifications, size: 22),
              ),
              label: 'Notification',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.black54,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed, // To keep all items visible
          selectedFontSize: 12,
          unselectedFontSize: 10,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold), // bold
        ),
      ),
    );
  }
}
