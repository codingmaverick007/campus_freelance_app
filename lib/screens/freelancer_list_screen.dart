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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            delegate: SliverSearchAppBar(
              maxHeight: 200,
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
                    suffixIcon: const Icon(Icons.filter_alt_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              onSuffixIconTap: () {},
            ),
            pinned: true,
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('isFreelancer', isEqualTo: true)
                .snapshots(),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(child: Text('No freelancers available.')),
                );
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
