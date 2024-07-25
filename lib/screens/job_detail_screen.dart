import 'package:campus_freelance_app/screens/edit_job_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'freelancer_detail_screen.dart';
import '../models/freelancer.dart';

class JobDetailScreen extends StatefulWidget {
  final QueryDocumentSnapshot<Object?> job;
  late String status;

  JobDetailScreen(
      {super.key,
      required this.job,
      required this.status,
      required String jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  late bool isBookmarked = false;
  late bool isJobPoster = false;
  late bool isFreelancer = false;
  late bool hasApplied = false;

  @override
  void initState() {
    super.initState();
    checkBookmarkStatus();
    checkJobPosterStatus();
    checkFreelancerStatus();
    checkIfApplied();
  }

  Future<void> checkBookmarkStatus() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final userDoc = usersCollection.doc(currentUser.uid);
      final bookmarksCollection = userDoc.collection('bookmarks');
      final snapshot = await bookmarksCollection.doc(widget.job.id).get();

      setState(() {
        isBookmarked = snapshot.exists;
      });
    } else {
      setState(() {
        isBookmarked = false;
      });
    }
  }

  Future<void> checkJobPosterStatus() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      setState(() {
        isJobPoster = currentUser.uid == widget.job['uploadedBy'];
      });
    }
  }

  Future<void> checkFreelancerStatus() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final userDoc = await usersCollection.doc(currentUser.uid).get();
      setState(() {
        isFreelancer = userDoc['isFreelancer'] ?? false;
      });
    }
  }

  Future<void> checkIfApplied() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final applicantSnapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.job.id)
          .collection('applicants')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      setState(() {
        hasApplied = applicantSnapshot.docs.isNotEmpty;
      });
    }
  }

  void toggleBookmark(BuildContext context) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final userDoc = usersCollection.doc(currentUser.uid);
      final bookmarksCollection = userDoc.collection('bookmarks');

      if (isBookmarked) {
        await bookmarksCollection.doc(widget.job.id).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from bookmarks')),
        );
      } else {
        await bookmarksCollection.doc(widget.job.id).set({
          'jobTitle': widget.job['jobTitle'],
          // Add other fields as needed
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to bookmarks')),
        );
      }

      setState(() {
        isBookmarked = !isBookmarked;
      });
    }
  }

  Future<void> _applyForJob(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackBar(context, 'Please log in to apply for this job.');
      return;
    }

    if (widget.status == 'closed') {
      _showErrorSnackBar(context, 'This job is closed.');
      return;
    }

    if (!isFreelancer) {
      _showErrorSnackBar(context, 'Only freelancers can apply for this job.');
      return;
    }

    if (isJobPoster) {
      _showErrorSnackBar(context, 'You cannot apply for your own job.');
      return;
    }

    try {
      hasApplied
          ? await _unapplyFromJob(user.uid, context)
          : await _applyToJob(user.uid, context);
    } catch (e) {
      _showErrorSnackBar(context, 'An error occurred. Please try again later.');
    }
  }

  Future<void> _applyToJob(String userId, BuildContext context) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      print('User does not exist in Firestore.');
      return;
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    await FirebaseFirestore.instance
        .collection('jobs')
        .doc(widget.job.id)
        .collection('applicants')
        .add({
      'userId': userId,
      'userName': userData['fullName'],
      'profileImageUrl': userData['profileImageUrl'],
    });

    setState(() {
      hasApplied = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('You have successfully applied for the job.')),
    );
  }

  Future<void> _unapplyFromJob(String userId, BuildContext context) async {
    final applicantSnapshot = await FirebaseFirestore.instance
        .collection('jobs')
        .doc(widget.job.id)
        .collection('applicants')
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in applicantSnapshot.docs) {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.job.id)
          .collection('applicants')
          .doc(doc.id)
          .delete();
    }

    setState(() {
      hasApplied = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('You have successfully unapplied from the job.')),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _acceptApplicant(
      BuildContext context, String applicantId) async {
    try {
      // Fetch the current job data
      DocumentSnapshot jobDoc = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.job.id)
          .get();

      if (!jobDoc.exists) {
        print('Job does not exist in Firestore.');
        return;
      }

      final jobData = jobDoc.data() as Map<String, dynamic>;

      // Check if there is already an accepted applicant
      if (jobData['acceptedApplicantId'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('An applicant has already been accepted.')),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.job.id)
          .update({
        'status': 'closed',
        'acceptedApplicantId': applicantId,
      });

      setState(() {
        // Update the local status to reflect the change
        widget.status = 'closed';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Applicant accepted and job closed.')),
      );
    } catch (e) {
      print('Error accepting applicant: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  Future<void> _showAcceptConfirmationDialog(
      BuildContext context, String applicantId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Accept Applicant"),
          content:
              const Text("Are you sure you want to accept this applicant?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Accept"),
              onPressed: () {
                Navigator.of(context).pop();
                _acceptApplicant(context, applicantId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _reopenJob(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.job.id)
          .update({'status': 'open', 'acceptedApplicantId': null});

      setState(() {
        // Update the local status to reflect the change
        widget.status = 'open';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job has been reopened.')),
      );
    } catch (e) {
      print('Error reopening job: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  Future<void> _closeJob(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.job.id)
          .update({'status': 'closed'});

      setState(() {
        widget.status = 'closed';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job has been closed.')),
      );
    } catch (e) {
      print('Error closing job: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  Future<void> _deleteJob(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.job.id)
          .delete();

      Navigator.of(context).pop(); // Go back to the previous screen

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job has been deleted.')),
      );
    } catch (e) {
      print('Error deleting job: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  Future<void> _markAsCompleted(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.job.id)
          .update({'status': 'completed'});

      setState(() {
        widget.status = 'completed';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job has been marked as completed.')),
      );
    } catch (e) {
      print('Error marking job as completed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> jobData = widget.job.data() as Map<String, dynamic>;
    List<dynamic> jobTags = jobData['jobTags'] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Job Details',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        backgroundColor: Colors.blue,
        actions: <Widget>[
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? Colors.amber : Colors.white,
            ),
            onPressed: () => toggleBookmark(context),
          ),
          if (isJobPoster)
            PopupMenuButton<String>(
              onSelected: (String value) {
                switch (value) {
                  case 'reopen':
                    _reopenJob(context);
                    break;
                  case 'close':
                    _closeJob(context);
                    break;
                  case 'delete':
                    _deleteJob(context);
                    break;
                  case 'complete':
                    _markAsCompleted(context);
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(
                    value: 'reopen',
                    child: Text('Reopen'),
                    enabled: widget.status == 'closed',
                  ),
                  PopupMenuItem(
                    value: 'close',
                    child: Text('Close'),
                    enabled: widget.status == 'open',
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                  PopupMenuItem(
                    value: 'complete',
                    child: Text('Mark as Completed'),
                    enabled: widget.status == 'closed',
                  ),
                ];
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  jobData['jobTitle'] as String,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  jobData['jobCategory'] as String,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Posted ${_formatTimestamp(jobData['createdAt'])}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      jobData['location'] as String,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(jobData['uploadedBy'] as String)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container();
                    }
                    if (!snapshot.hasData) {
                      return const Text('User not found');
                    }
                    Map<String, dynamic> userData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    return Row(
                      children: [
                        const Icon(Icons.person, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Posted by ${userData['fullName'] as String}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Job Description',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  jobData['jobDescription'] as String,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Requirements',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: (jobData['requirements'] as List<dynamic>)
                      .map<Widget>((item) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: const Icon(Icons.circle,
                              size: 8, color: Colors.black),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item as String,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Applicants',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                if (isJobPoster)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('jobs')
                        .doc(widget.job.id)
                        .collection('applicants')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final applicantsDocs = snapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: applicantsDocs.length,
                        itemBuilder: (ctx, i) {
                          final applicant = applicantsDocs[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                  applicant['profileImageUrl'] as String),
                            ),
                            title: Text(applicant['userName'] as String),
                            trailing: IconButton(
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                              onPressed: () {
                                _showAcceptConfirmationDialog(
                                    context, applicant['userId']);
                              },
                            ),
                            onTap: () async {
                              try {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        FreelancerDetailScreen(
                                      applicant['userId'],
                                    ),
                                  ),
                                );
                              } catch (e) {
                                print('Error fetching freelancer data: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Error fetching freelancer data.'),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                  )
                else
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('jobs')
                        .doc(widget.job.id)
                        .collection('applicants')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final applicantCount = snapshot.data!.docs.length;
                      return Text('Number of applicants: $applicantCount');
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isJobPoster
            ? Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        backgroundColor: Colors.white,
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditJobScreen(jobId: widget.job.id),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 24.0),
                        child: Text(
                          'Edit',
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: () {
                  if (widget.status == 'closed') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('This job is closed.'),
                      ),
                    );
                  } else {
                    _applyForJob(context);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 24.0),
                  child: Text(
                    widget.status == 'closed'
                        ? 'Job Closed'
                        : hasApplied
                            ? 'Unapply'
                            : 'Apply',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
              ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    DateTime createdAt = (timestamp as Timestamp).toDate();
    return timeago.format(createdAt, locale: 'en_short');
  }
}
