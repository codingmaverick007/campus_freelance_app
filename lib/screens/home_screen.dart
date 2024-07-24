import 'package:campus_freelance_app/models/freelancer.dart';
import 'package:campus_freelance_app/screens/job_detail_screen.dart';
import 'package:campus_freelance_app/screens/profile_screen.dart';
import 'package:campus_freelance_app/screens/search_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/freelancer_provider.dart';
import 'job_upload_screen.dart';
import 'filter_screen.dart'; // Import the filter screen
import '../widgets/freelancer_card.dart';
import '../widgets/job_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late User _user;
  Map<String, dynamic>? _userData;
  List<String> _selectedCategories = [];

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

      if (userData.exists) {
        setState(() {
          _userData = userData.data();
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  void _applyFilters(List<String> selectedCategories) {
    setState(() {
      _selectedCategories = selectedCategories;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCategories.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final freelancerProvider = Provider.of<FreelancerProvider>(context);
    final freelancers = freelancerProvider.freelancers;

    return Scaffold(
      body: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                toolbarHeight: 80,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 8),
                    Text(
                        'Hello ${_userData != null && _userData!['fullName'] != null ? _userData!['fullName'].split(' ')[0] : 'User'}'),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: ((context) => const SearchScreen()),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) {
                          return DraggableScrollableSheet(
                            expand: false,
                            builder: (context, scrollController) {
                              return FilterScreen(
                                applyFilters: _applyFilters,
                                clearFilters: _clearFilters,
                                initialSelectedCategories: _selectedCategories,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
                pinned: true,
                floating: true,
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Jobs'),
                    Tab(text: 'Freelancers'),
                  ],
                ),
              ),
            ],
            body: Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 10.0),
              child: TabBarView(
                children: [
                  // Jobs Tab
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('jobs')
                        .snapshots(),
                    builder: (ctx, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final jobsDocs = snapshot.data!.docs;
                      final filteredJobs = _selectedCategories.isEmpty
                          ? jobsDocs
                          : jobsDocs.where((doc) {
                              var jobData = doc.data() as Map<String, dynamic>;
                              return _selectedCategories
                                  .contains(jobData['jobCategory']);
                            }).toList();

                      return ListView.builder(
                        itemCount: filteredJobs.length,
                        itemBuilder: (ctx, i) {
                          final job = filteredJobs[i];
                          final jobData = job.data() as Map<String, dynamic>;
                          return JobCard(
                            jobTitle: jobData['jobTitle'] ?? 'No Title',
                            location: jobData['location'] ?? 'No Location',
                            tags: jobData['tags'] != null
                                ? List<String>.from(jobData['tags'])
                                : [],
                            timestamp:
                                jobData['timestamp']?.toDate().toString() ??
                                    'No Timestamp',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => JobDetailScreen(
                                    job: job,
                                    status: '',
                                    jobId: job.id,
                                  ),
                                ),
                              );
                            },
                            uploadedBy: '',
                            jobCategory: '',
                            jobDescription: '',
                            jobId: '',
                          );
                        },
                      );
                    },
                  ),
                  // Freelancers Tab
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('isFreelancer', isEqualTo: true)
                        .snapshots(),
                    builder: (ctx, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final freelancerDocs = snapshot.data!.docs;
                      final freelancers = freelancerDocs
                          .map((doc) => Freelancer(
                                name: doc['fullName'] ?? 'No Name',
                                imageUrl: doc['profileImageUrl'] ?? '',
                                title: doc['title'],
                                id: doc.id,
                              ))
                          .toList();
                      return ListView.builder(
                        itemCount: freelancers.length,
                        itemBuilder: (ctx, i) {
                          final freelancer = freelancers[i];
                          return FreelancerCard(freelancer);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColorLight,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => JobUploadScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
