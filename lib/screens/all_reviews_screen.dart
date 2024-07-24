import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AllReviewsScreen extends StatelessWidget {
  final String freelancerId;

  const AllReviewsScreen({required this.freelancerId, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Reviews'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchReviews(freelancerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            final reviews = snapshot.data ?? [];
            return reviews.isEmpty
                ? const Center(
                    child: Text('No reviews or testimonials available.'))
                : ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return _buildReviewTile(review['userId'], review);
                    },
                  );
          }
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchReviews(String freelancerId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ratings')
          .where('freelancerId', isEqualTo: freelancerId)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching reviews: $e');
      return [];
    }
  }

  Widget _buildReviewTile(String userId, Map<String, dynamic> review) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: CircularProgressIndicator(),
            title: Text('Loading...'),
          );
        } else if (snapshot.hasError) {
          return ListTile(
            title: Text('Error: ${snapshot.error}'),
          );
        } else {
          final userData = snapshot.data?.data() as Map<String, dynamic>?;

          return ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  userData != null && userData['profileImageUrl'] != null
                      ? NetworkImage(userData['profileImageUrl'])
                      : const AssetImage('assets/avatar.jpg') as ImageProvider,
            ),
            title: Text(userData != null ? userData['fullName'] : 'User'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.yellow),
                    Text(review['rating'] != null
                        ? ' ${review['rating']} Stars'
                        : ' No Rating'),
                  ],
                ),
                Text(review['feedback'] ?? 'No review text provided.'),
              ],
            ),
          );
        }
      },
    );
  }
}
