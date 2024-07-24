import 'package:campus_freelance_app/models/bookmark.dart';
import 'package:campus_freelance_app/screens/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'freelancer_detail_screen.dart'; // Import the FreelancerDetailScreen

class BookmarksScreen extends StatefulWidget {
  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  late User _user;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .get();

      if (userData.exists && mounted) {
        setState(() {
          _userData = userData.data();
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 110, 0, 0),
              child: StreamBuilder(
                stream: getUsersBookmarksStream(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final bookmarks = snapshot.data?.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Bookmark.fromMap({
                      'id': doc.id,
                      'name': data['name'],
                      'imageUrl': data['imageUrl'],
                      // Map other fields as needed
                    });
                  }).toList();

                  if (bookmarks == null || bookmarks.isEmpty) {
                    return Center(child: Text('No bookmarks found.'));
                  }

                  return ListView.builder(
                    itemCount: bookmarks.length,
                    itemBuilder: (context, index) {
                      final bookmark = bookmarks[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(bookmark.imageUrl),
                        ),
                        title: Text(bookmark.name),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FreelancerDetailScreen(
                                bookmark.id, // Pass the user ID
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfileScreen()),
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage: _userData != null &&
                                _userData!['profileImageUrl'] != null
                            ? NetworkImage(_userData!['profileImageUrl']!)
                                as ImageProvider<Object>?
                            : const AssetImage('assets/avatar.png'),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Here are your bookmarks, ${_userData != null && _userData!['fullName'] != null ? _userData!['fullName'].split(' ')[0] : 'User'}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<QuerySnapshot> getUsersBookmarksStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return usersCollection
        .doc(currentUser?.uid)
        .collection('bookmarks')
        .snapshots();
  }
}
