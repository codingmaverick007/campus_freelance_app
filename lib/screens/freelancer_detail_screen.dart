import 'package:campus_freelance_app/screens/all_reviews_screen.dart';
import 'package:campus_freelance_app/screens/messaging%20screens/chat_screen.dart';
import 'package:campus_freelance_app/services/rating_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/freelancer.dart';

class FreelancerDetailScreen extends StatefulWidget {
  final String userId;

  const FreelancerDetailScreen(this.userId, {super.key});

  @override
  State<FreelancerDetailScreen> createState() => _FreelancerDetailScreenState();
}

class _FreelancerDetailScreenState extends State<FreelancerDetailScreen> {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late bool isBookmarked = false;
  final RatingService ratingService = RatingService();
  Freelancer? freelancer;

  @override
  void initState() {
    super.initState();
    fetchFreelancerDetails();
    checkBookmarkStatus();
  }

  Future<void> fetchFreelancerDetails() async {
    try {
      final snapshot = await usersCollection.doc(widget.userId).get();
      setState(() {
        freelancer = Freelancer.fromMap(
            snapshot.data() as Map<String, dynamic>, widget.userId);
      });
    } catch (e) {
      print('Error fetching freelancer details: $e');
    }
  }

  Future<void> checkBookmarkStatus() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final userDoc = usersCollection.doc(currentUser.uid);
      final bookmarksCollection = userDoc.collection('bookmarks');
      final bookmarkDocId = widget.userId;

      final snapshot = await bookmarksCollection.doc(bookmarkDocId).get();

      setState(() {
        isBookmarked = snapshot.exists;
      });
    } else {
      setState(() {
        isBookmarked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: freelancer == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context),
                      _buildFreelancerDetails(),
                    ],
                  ),
                ),
                _buildAppBar(context),
                _buildBookmarkButton(),
              ],
            ),
      floatingActionButton: freelancer == null ? null : _buildMessageButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0.0, 30.0, 0.0, 20.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundImage: freelancer!.imageUrl != null &&
                              freelancer!.imageUrl!.isNotEmpty
                          ? NetworkImage(freelancer!.imageUrl!)
                          : const AssetImage('assets/avatar.jpg')
                              as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: FutureBuilder<double>(
                        future: ratingService
                            .calculateAverageRating(freelancer!.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return const Icon(Icons.error, color: Colors.red);
                          } else {
                            final averageRating = snapshot.data ?? 0.0;
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  Text(
                                    averageRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      freelancer!.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Text(' - '),
                    if (freelancer!.title != null &&
                        freelancer!.title!.isNotEmpty)
                      Text(
                        freelancer!.title!,
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
                if (freelancer!.programme != null &&
                    freelancer!.programme!.isNotEmpty)
                  Text(
                    '${freelancer!.programme!} Student',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                if (freelancer!.studentId != null &&
                    freelancer!.studentId!.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.badge, color: Colors.black54),
                      const SizedBox(width: 8),
                      Text(
                        freelancer!.studentId!,
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFreelancerDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 6.0,
                    spreadRadius: 2.0,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Bio', Icons.person),
                  Text(
                    freelancer!.bio ?? 'No bio available.',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Portfolio', Icons.portrait),
                  Text(
                    freelancer!.portfolio ?? 'No portfolio available.',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Skills', Icons.build),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: freelancer!.skills != null &&
                            freelancer!.skills!.isNotEmpty
                        ? freelancer!.skills!
                            .map((skill) => Chip(
                                  label: Text(skill),
                                  labelStyle:
                                      const TextStyle(color: Colors.white),
                                  backgroundColor: Colors.blueAccent,
                                ))
                            .toList()
                        : [const Text('No skills provided.')],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Hobbies and Interests', Icons.favorite),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: freelancer!.hobbiesAndInterests != null &&
                            freelancer!.hobbiesAndInterests!.isNotEmpty
                        ? freelancer!.hobbiesAndInterests!
                            .map((hobby) => Chip(
                                  label: Text(hobby),
                                  labelStyle:
                                      const TextStyle(color: Colors.white),
                                  backgroundColor: Colors.green,
                                ))
                            .toList()
                        : [const Text('No hobbies or interests provided.')],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'User Reviews',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            _buildExpandableReviews(freelancer!.id),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: Colors.grey.withOpacity(0.7)),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarkButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 15,
      right: 16,
      child: CircleAvatar(
        backgroundColor: Colors.white,
        child: IconButton(
          icon: Icon(
            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: isBookmarked ? Colors.blueAccent : Colors.black,
          ),
          onPressed: () async {
            final currentUser = _auth.currentUser;
            if (currentUser != null) {
              final userDoc = usersCollection.doc(currentUser.uid);
              final bookmarksCollection = userDoc.collection('bookmarks');
              final bookmarkDocId = widget.userId;

              final bookmarkSnapshot =
                  await bookmarksCollection.doc(bookmarkDocId).get();
              final bookmarkExists = bookmarkSnapshot.exists;

              if (isBookmarked && bookmarkExists) {
                // Remove from bookmarks
                await bookmarksCollection.doc(bookmarkDocId).delete();
                showSnackbar(context, 'Removed from bookmarks');
              } else if (!isBookmarked && !bookmarkExists) {
                // Add to bookmarks if not already bookmarked
                await bookmarksCollection.doc(bookmarkDocId).set({
                  'name': freelancer!.name,
                  'imageUrl': freelancer!.imageUrl ?? '',
                });
              }
              setState(() {
                isBookmarked = !isBookmarked;
              });
              showSnackbar(
                  context,
                  isBookmarked
                      ? 'Added to bookmarks'
                      : 'Removed from bookmarks');
            } else {
              showSnackbar(context, 'Please sign in to bookmark');
            }
          },
        ),
      ),
    );
  }

  Widget _buildMessageButton() {
    return FloatingActionButton(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      onPressed: () async {
        final currentUser = _auth.currentUser;
        final receiverId = freelancer!.id;

        if (currentUser != null) {
          final conversationSnapshot =
              await getOrCreateConversation(currentUser.uid, receiverId);

          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChatScreen(
                      receiverId: receiverId,
                      receiverName: freelancer!.name,
                      receiverImage: freelancer!.imageUrl!,
                      conversationId: conversationSnapshot.id,
                    )),
          );
        } else {
          showSnackbar(context, 'Please sign in to start a conversation');
        }
      },
      child: const Icon(Icons.message),
    );
  }

  Widget _buildExpandableReviews(String freelancerId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchReviews(freelancerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final reviews = snapshot.data ?? [];
          final recentReviews =
              reviews.take(4).toList(); // Displaying 4 most recent reviews
          return Column(
            children: [
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentReviews.length,
                  itemBuilder: (context, index) {
                    final review = recentReviews[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _buildReviewTile(review['userId'], review),
                    );
                  },
                ),
              ),
              if (reviews.length > 4)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AllReviewsScreen(freelancerId: freelancerId),
                      ),
                    );
                  },
                  child: Text(
                    'Show more reviews',
                    style: GoogleFonts.roboto(fontSize: 12, color: Colors.blue),
                  ),
                ),
            ],
          );
        }
      },
    );
  }

  Widget _buildReviewTile(String userId, Map<String, dynamic> review) {
    return FutureBuilder<DocumentSnapshot>(
      future: usersCollection.doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 250,
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return SizedBox(
            width: 250,
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else {
          final userData = snapshot.data?.data() as Map<String, dynamic>?;

          return Container(
            width: 250,
            height: 100, // Set a fixed height
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    review['feedback'] ?? 'No review text provided.',
                    maxLines: 3, // Limit to 3 lines
                    overflow: TextOverflow.ellipsis, // Show ellipsis
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review['rating'] ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    );
                  }),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    userData != null ? userData['fullName'] : 'User',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  review['feedback'] ??
                                      'No review text provided.',
                                  style: GoogleFonts.roboto(
                                    fontSize: 20,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < review['rating']
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                    );
                                  }),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  userData != null
                                      ? userData['fullName']
                                      : 'User',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  review['date'] != null
                                      ? DateFormat.yMMMd()
                                          .format(review['date'].toDate())
                                      : 'No date provided',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: const Text(
                      'Show more',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
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

  Future<DocumentSnapshot<Object?>> getOrCreateConversation(
      String senderId, String receiverId) async {
    final conversationId = _generateConversationId(senderId, receiverId);
    final conversationRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId);

    try {
      final docSnapshot = await conversationRef.get();

      if (!docSnapshot.exists) {
        await conversationRef.set({
          'createdAt': FieldValue.serverTimestamp(),
          'members': [senderId, receiverId],
        });
      }

      return docSnapshot;
    } catch (e) {
      print('Error creating conversation: $e');
      rethrow; // Rethrow the exception
    }
  }

  String _generateConversationId(String senderId, String receiverId) {
    final ids = [senderId, receiverId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  void showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
