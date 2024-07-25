import 'package:campus_freelance_app/screens/auth%20screens/login_screen.dart';
import 'package:campus_freelance_app/screens/fullscreen_image.dart';
import 'package:campus_freelance_app/services/fetch_user_details_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User _user;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    _userData = await FetchDetail.fetchUserData();
    if (_userData != null) {
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load user data')),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _userData != null
          ? SafeArea(
              child: Column(
                children: [
                  customAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FullScreenImageView(
                                      imageUrl: _userData!['profileImageUrl']!,
                                    ),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 50,
                                backgroundImage:
                                    _userData!['profileImageUrl'] != null
                                        ? NetworkImage(
                                            _userData!['profileImageUrl'])
                                        : const AssetImage('assets/avatar.png')
                                            as ImageProvider,
                                onBackgroundImageError:
                                    (exception, stackTrace) {
                                  print(
                                      "Error loading network image: $exception");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Error loading profile image'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  _userData!['fullName'] ?? 'Full Name',
                                  style: GoogleFonts.roboto(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (_userData!['isFreelancer'] ?? false)
                                  Text(
                                    _userData!['title'] ?? 'Job Title',
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _userData!['isFreelancer'] ?? false
                                    ? null
                                    : Icons.person_outline,
                                color: _userData!['isFreelancer'] ?? false
                                    ? Colors.blue
                                    : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              _userData!['isFreelancer'] ?? false
                                  ? Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: (_userData!['services']
                                              as List<dynamic>)
                                          .map((service) => Chip(
                                                label: Text(service),
                                                labelStyle: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall,
                                              ))
                                          .toList(),
                                    )
                                  : Text('Client',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildUserInfoTile(Icons.description, 'Bio',
                              _userData!['bio'] ?? 'No bio provided'),
                          _buildUserInfoTile(
                              Icons.book,
                              'Programme',
                              _userData!['programme'] ??
                                  'No programme provided'),
                          _buildUserInfoTile(
                              Icons.school,
                              'Student ID',
                              _userData!['studentId'] ??
                                  'No student ID provided'),
                          if (_userData!.containsKey('studentIdImageUrl') &&
                              _userData!['studentIdImageUrl'] != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Image.network(
                                _userData!['studentIdImageUrl'],
                                height: 150,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Text('Error loading image');
                                },
                              ),
                            ),
                          _buildPortfolioTile(),
                          _buildUserInfoTile(
                              Icons.work,
                              'Work Experience',
                              _userData!['workExperience'] ??
                                  'No work experience provided'),
                          _buildUserInfoTile(
                              Icons.star,
                              'Reviews and Testimonials',
                              _userData!['reviews'] ??
                                  'No reviews and testimonials provided'),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: TextButton.icon(
                                onPressed: _logout,
                                icon:
                                    const Icon(Icons.logout, color: Colors.red),
                                label: Text(
                                  'Logout',
                                  style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.red),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildUserInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title,
          style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      tileColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    );
  }

  Widget _buildPortfolioTile() {
    return ListTile(
      leading: const Icon(Icons.portrait, color: Colors.blueAccent),
      title: const Text('Portfolio',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87)),
      subtitle: _userData!.containsKey('portfolioUrl')
          ? InkWell(
              onTap: () {
                // Navigate to portfolio URL
              },
              child: Text(
                _userData!['portfolioUrl'] ?? 'No portfolio provided',
                style: const TextStyle(color: Colors.blue),
              ),
            )
          : const Text('No portfolio provided'),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      tileColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    );
  }

  Widget customAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 0, 0, 0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withOpacity(0.2),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
          Text(
            'My Profile',
            style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: ((context) => EditProfileScreen()),
              ),
            ),
            icon: const Icon(Icons.edit, size: 30.0, color: Colors.blueAccent),
          ),
        ],
      ),
    );
  }
}
