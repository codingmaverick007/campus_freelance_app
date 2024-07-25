import 'package:campus_freelance_app/services/fetch_user_details_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobCard extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final String uploadedBy;
  final String location;
  final String jobCategory;
  final List<String> tags;
  final String timestamp;
  final VoidCallback onTap;
  final String jobDescription;

  const JobCard({
    Key? key,
    required this.jobId,
    required this.jobTitle,
    required this.uploadedBy,
    required this.location,
    required this.jobCategory,
    required this.tags,
    required this.timestamp,
    required this.onTap,
    required this.jobDescription,
  }) : super(key: key);

  @override
  _JobCardState createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  Map<String, dynamic>? _uploaderData;
  bool isBookmarked = false;
  bool hasApplied = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  bool isPoster = false;

  @override
  void initState() {
    super.initState();
    _fetchUploaderData();
    _checkApplicationStatus();
    _checkBookmarkStatus();
    _checkIfCurrentUserIsUploader();
  }

  Future<void> _fetchUploaderData() async {
    _uploaderData = await FetchUploaderDetail.fetchUserData(widget.uploadedBy);
    if (_uploaderData != null) {
      setState(() {});
    }
  }

  Future<void> _checkApplicationStatus() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final applicantSnapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .collection('applicants')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      setState(() {
        hasApplied = applicantSnapshot.docs.isNotEmpty;
      });
    }
  }

  Future<void> _checkBookmarkStatus() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final bookmarkSnapshot = await usersCollection
          .doc(currentUser.uid)
          .collection('bookmarks')
          .doc(widget.jobId)
          .get();

      setState(() {
        isBookmarked = bookmarkSnapshot.exists;
      });
    }
  }

  Future<void> _checkIfCurrentUserIsUploader() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      setState(() {
        isPoster = currentUser.uid == widget.uploadedBy;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final bookmarkRef = usersCollection
          .doc(currentUser.uid)
          .collection('bookmarks')
          .doc(widget.jobId);

      if (isBookmarked) {
        await bookmarkRef.delete();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from bookmarks')));
      } else {
        await bookmarkRef.set({'jobTitle': widget.jobTitle});
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Added to bookmarks')));
      }

      setState(() {
        isBookmarked = !isBookmarked;
      });
    }
  }

  Future<void> _applyForJob() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final userDoc = await usersCollection.doc(currentUser.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;

        final jobRef =
            FirebaseFirestore.instance.collection('jobs').doc(widget.jobId);

        if (hasApplied) {
          // Unapply for the job
          final applicantSnapshot = await jobRef
              .collection('applicants')
              .where('userId', isEqualTo: currentUser.uid)
              .get();

          for (var doc in applicantSnapshot.docs) {
            await jobRef.collection('applicants').doc(doc.id).delete();
          }

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('You have successfully unapplied from the job.')));

          setState(() {
            hasApplied = false;
          });
        } else {
          // Apply for the job
          await jobRef.collection('applicants').add({
            'userId': currentUser.uid,
            'userName': userData['fullName'],
            'profileImageUrl': userData['profileImageUrl'],
          });

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('You have successfully applied for the job.')));

          setState(() {
            hasApplied = true;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.jobTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.jobCategory,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isPoster)
                    IconButton(
                      icon: Icon(isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border),
                      onPressed: _toggleBookmark,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _uploaderData != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time,
                                    size: 12, color: Colors.grey),
                                Text(
                                  '${widget.timestamp} ago',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  widget.location,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    )
                  : Container(),
              const SizedBox(height: 8),
              Text(
                widget.jobDescription,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: widget.tags.map((tag) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8.0),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 6.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.009),
                      _uploaderData != null
                          ? Text(
                              'Posted by ${_uploaderData!['fullName'] ?? 'Unknown User'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            )
                          : Container(),
                    ],
                  ),
                  if (!isPoster)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                        onPressed: _applyForJob,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).primaryColor, // Button color
                          foregroundColor: Colors.white, // Text color
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          hasApplied ? 'Unapply' : 'Apply',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
