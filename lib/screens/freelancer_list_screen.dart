import 'package:campus_freelance_app/widgets/sliver_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/freelancer_card.dart';
import '../models/freelancer.dart';

class FreelancersScreen extends StatefulWidget {
  const FreelancersScreen({Key? key}) : super(key: key);

  @override
  State<FreelancersScreen> createState() => _FreelancersScreenState();
}

class _FreelancersScreenState extends State<FreelancersScreen> {
  late User _user;
  Map<String, dynamic>? _userData;
  String _searchTerm = '';
  bool _isSearching = false;
  List<QueryDocumentSnapshot> _searchResults = [];
  bool _isSortedByRating = false;

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
      if (mounted) {
        print("Error fetching user data: $e");
      }
    }
  }

  void _searchFreelancers(String searchTerm) async {
    setState(() {
      _isSearching = true;
      _searchTerm = searchTerm.toLowerCase();
    });

    final freelancerQuery = FirebaseFirestore.instance
        .collection('users')
        .where('isFreelancer', isEqualTo: true)
        .get();

    final freelancerResults = await freelancerQuery;

    if (mounted) {
      setState(() {
        _isSearching = false;
        _searchResults = freelancerResults.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['fullName']
                  .toString()
                  .toLowerCase()
                  .contains(_searchTerm) ||
              data['title'].toString().toLowerCase().contains(_searchTerm);
        }).toList();

        // Sort results by rating
        _searchResults.sort((a, b) {
          final ratingA = (a['rating'] ?? 0.0) as double;
          final ratingB = (b['rating'] ?? 0.0) as double;
          return ratingB.compareTo(ratingA); // Descending order
        });
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
                              setState(() {
                                _searchTerm = '';
                                _searchResults.clear();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    _searchFreelancers(value);
                  },
                ),
              ),
              onSuffixIconTap: () {},
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
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('isFreelancer', isEqualTo: true)
                  .snapshots(),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No freelancers available.')),
                  );
                }

                final freelancerDocs = displayResults ?? snapshot.data!.docs;

                // Sort freelancers by rating if needed
                if (_isSortedByRating) {
                  freelancerDocs.sort((a, b) {
                    final ratingA = (a['rating'] ?? 0.0) as double;
                    final ratingB = (b['rating'] ?? 0.0) as double;
                    return ratingB.compareTo(ratingA); // Descending order
                  });
                }

                final freelancers = freelancerDocs
                    .map((doc) => Freelancer(
                          name: doc['fullName'] ?? 'No Name',
                          imageUrl: doc['profileImageUrl'] ?? '',
                          title: doc['title'],
                          id: doc.id,
                        ))
                    .toList();

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final freelancer = freelancers[i];
                      return FreelancerCard(freelancer);
                    },
                    childCount: freelancers.length,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
