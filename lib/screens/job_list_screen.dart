import 'package:campus_freelance_app/screens/job_upload_screen.dart';
import 'package:campus_freelance_app/widgets/sliver_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/job_card.dart';
import 'job_detail_screen.dart';
import 'filter_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class JobsScreen extends StatefulWidget {
  const JobsScreen({Key? key}) : super(key: key);

  @override
  _JobsScreenState createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  late User _user;
  Map<String, dynamic>? _userData;
  List<String> _selectedCategories = [];
  String _searchTerm = '';
  bool _isSearching = false;
  List<QueryDocumentSnapshot> _searchResults = [];
  bool _isDisposed = false; // Add this flag

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    _fetchUserData();
  }

  @override
  void dispose() {
    _isDisposed = true; // Update the flag in dispose
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .get();

      if (userData.exists && !_isDisposed) {
        // Check if disposed
        setState(() {
          _userData = userData.data();
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  void _applyFilters(List<String> selectedCategories) {
    if (!_isDisposed) {
      // Check if disposed
      setState(() {
        _selectedCategories = selectedCategories;
      });
    }
  }

  void _clearFilters() {
    if (!_isDisposed) {
      // Check if disposed
      setState(() {
        _selectedCategories.clear();
      });
    }
  }

  void _onSuffixIconTap() {
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
  }

  void _searchJobs(String searchTerm) async {
    if (!_isDisposed) {
      // Check if disposed
      setState(() {
        _isSearching = true;
        _searchTerm = searchTerm.toLowerCase();
      });
    }

    final jobQuery = FirebaseFirestore.instance.collection('jobs').get();
    final jobResults = await jobQuery;

    if (!_isDisposed) {
      // Check if disposed
      setState(() {
        _isSearching = false;
        _searchResults = jobResults.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['jobTitle']
              .toString()
              .toLowerCase()
              .contains(_searchTerm);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayResults = _searchTerm.isNotEmpty ? _searchResults : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            delegate: SliverSearchAppBar(
              maxHeight: 180,
              minHeight: 100,
              profileImageUrl: _userData?['profileImageUrl'],
              searchBar: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchTerm.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              if (!_isDisposed) {
                                // Check if disposed
                                setState(() {
                                  _searchTerm = '';
                                  _searchResults.clear();
                                });
                              }
                            },
                          )
                        : IconButton(
                            icon:
                                const Icon(CupertinoIcons.slider_horizontal_3),
                            onPressed: _onSuffixIconTap,
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    _searchJobs(value);
                  },
                ),
              ),
              onSuffixIconTap: _onSuffixIconTap,
            ),
            pinned: true,
          ),
          if (_isSearching)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (displayResults != null && displayResults.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No results found')),
            )
          else
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No jobs available.')),
                  );
                }

                final jobsDocs = displayResults ?? snapshot.data!.docs;
                final filteredJobs = _selectedCategories.isEmpty
                    ? jobsDocs
                    : jobsDocs.where((doc) {
                        var jobData = doc.data() as Map<String, dynamic>;
                        return _selectedCategories
                            .contains(jobData['jobCategory']);
                      }).toList();

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final job = filteredJobs[i];
                      final jobData = job.data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: JobCard(
                          jobTitle: jobData['jobTitle'] ?? 'No Title',
                          uploadedBy:
                              jobData['uploadedBy'] ?? 'Unknown Company',
                          location: jobData['location'] ?? 'No Location',
                          jobCategory: jobData['jobCategory'],
                          tags: jobData['jobTags'] != null
                              ? List<String>.from(jobData['jobTags'])
                              : [],
                          jobDescription: jobData['jobDescription'],
                          timestamp: _formatTimestamp(
                              jobData['createdAt'] ?? 'No Timestamp'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JobDetailScreen(
                                  job: job,
                                  status: jobData['status'],
                                  jobId: jobData['jobId'],
                                ),
                              ),
                            );
                          },
                          jobId: jobData['jobId'],
                        ),
                      );
                    },
                    childCount: filteredJobs.length,
                  ),
                );
              },
            ),
        ],
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

  String _formatTimestamp(dynamic timestamp) {
    DateTime createdAt = (timestamp as Timestamp).toDate();
    return timeago.format(createdAt, locale: 'en_short');
  }
}
