import 'package:campus_freelance_app/screens/bookmarks_screen.dart';
import 'package:campus_freelance_app/screens/edit_profile_screen.dart';
import 'package:campus_freelance_app/screens/freelancer_list_screen.dart';
import 'package:campus_freelance_app/screens/job_list_screen.dart';
import 'package:campus_freelance_app/screens/job_management_screen.dart';
import 'package:campus_freelance_app/screens/messaging%20screens/messages_screen.dart';
import 'package:flutter/material.dart';

class ScreenScaffold extends StatefulWidget {
  const ScreenScaffold({super.key});

  @override
  State<ScreenScaffold> createState() => _ScreenScaffoldState();
}

class _ScreenScaffoldState extends State<ScreenScaffold> {
  int _currentPage = 0;
  bool _showProfileNotification = true;

  final List<Widget> _pages = [
    const JobsScreen(),
    const FreelancersScreen(),
    BookmarksScreen(),
    const ConversationsScreen(),
    const JobManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _pages[_currentPage],
          if (_showProfileNotification && _currentPage == 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildNotificationBar(),
            ),
        ],
      ),
      bottomNavigationBar: _bottomNavigationBar(),
    );
  }

  Widget _buildNotificationBar() {
    return Container(
      color: Colors.blueAccent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'Complete your profile for a better experience!',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: ((context) => EditProfileScreen()),
                  ),
                );
                _showProfileNotification = false;
              });
            },
            child: const Text(
              'Complete Now',
              style: TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              setState(() {
                _showProfileNotification = false;
              });
            },
          ),
        ],
      ),
    );
  }

  BottomNavigationBar _bottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentPage,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: const Color(0xFF6C757D), // Grey
      showUnselectedLabels: true,
      onTap: (index) {
        setState(() {
          _currentPage = index;
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Jobs'),
        BottomNavigationBarItem(icon: Icon(Icons.laptop), label: 'Freelancers'),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Bookmarks'),
        BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
        BottomNavigationBarItem(
            icon: Icon(Icons.maps_home_work_outlined), label: 'Contracts'),
      ],
    );
  }
}
