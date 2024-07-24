import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'job_detail_screen.dart';
import 'profile_screen.dart';

class JobManagementScreen extends StatefulWidget {
  const JobManagementScreen({super.key});

  @override
  State<JobManagementScreen> createState() => _JobManagementScreenState();
}

class _JobManagementScreenState extends State<JobManagementScreen> {
  late User _user;
  Map<String, dynamic>? _userData;
  bool isLoading = true;
  List<QueryDocumentSnapshot> postedJobs = [];
  List<QueryDocumentSnapshot> hiredJobs = [];
  String selectedTag = 'all';

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
        _fetchJobs();
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> _fetchJobs() async {
    try {
      if (_userData != null) {
        if (_userData!['isFreelancer'] == true) {
          final hiredJobsData = await FirebaseFirestore.instance
              .collection('jobs')
              .where('acceptedApplicantId', isEqualTo: _user.uid)
              .get();
          if (mounted) {
            setState(() {
              hiredJobs = hiredJobsData.docs;
            });
          }
        }
        final postedJobsData = await FirebaseFirestore.instance
            .collection('jobs')
            .where('uploadedBy', isEqualTo: _user.uid)
            .get();
        if (mounted) {
          setState(() {
            postedJobs = postedJobsData.docs;
          });
        }
      }
    } catch (e) {
      print("Error fetching jobs: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteJob(String jobId) async {
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).delete();
      _fetchJobs();
    } catch (e) {
      print("Error deleting job: $e");
    }
  }

  Future<void> _updateJobStatus(String jobId, String newStatus) async {
    try {
      if (newStatus == 'completed') {
        final jobData = await FirebaseFirestore.instance
            .collection('jobs')
            .doc(jobId)
            .get();
        final freelancerId = jobData['acceptedApplicantId'];

        if (freelancerId != null) {
          await _showRatingDialog(freelancerId);

          // After rating, delete the job
          await FirebaseFirestore.instance
              .collection('jobs')
              .doc(jobId)
              .delete();
        }
      } else {
        // If status is not 'completed', update status normally
        await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
          'status': newStatus,
        });
      }

      // Fetch updated jobs list
      _fetchJobs();
    } catch (e) {
      print("Error updating job status: $e");
    }
  }

  Future<void> _showDeleteConfirmationDialog(String jobId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this job?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteJob(jobId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRatingDialog(String freelancerId) async {
    final freelancerData = await FirebaseFirestore.instance
        .collection('users')
        .doc(freelancerId)
        .get();
    final freelancerName = freelancerData['fullName'];

    double _rating = 0.0;
    String _feedback = '';

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rate $freelancerName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                _rating = rating;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Feedback',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                _feedback = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('ratings') // Change to 'ratings' collection
                  .add({
                'freelancerId': freelancerId,
                'userId': _user.uid,
                'rating': _rating,
                'feedback': _feedback,
                'timestamp': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _handlePopupMenuSelection(String jobId, String jobStatus, String value) {
    switch (value) {
      case 'reopen':
        if (jobStatus != 'closed') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'You need to accept/hire an applicant first to reopen the job.')),
          );
        } else {
          _updateJobStatus(jobId, 'opened');
        }
        break;
      case 'close':
        _updateJobStatus(jobId, 'closed');
        break;
      case 'complete':
        if (jobStatus != 'closed') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'You need to accept/hire an applicant first to mark the job as completed.')),
          );
        } else {
          _updateJobStatus(jobId, 'completed');
        }
        break;
      case 'delete':
        _showDeleteConfirmationDialog(jobId);
        break;
    }
  }

  void _handleFilterPressed() {
    // Implement your filter logic here
  }

  void _handleTagSelection(String tag) {
    setState(() {
      selectedTag = tag;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 110, 0, 0),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ChoiceChip(
                                label: Text(
                                  'All',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                selected: selectedTag == 'all',
                                onSelected: (_) => _handleTagSelection('all'),
                              ),
                              ChoiceChip(
                                label: Text(
                                  'Posted Jobs',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                selected: selectedTag == 'posted',
                                onSelected: (_) =>
                                    _handleTagSelection('posted'),
                              ),
                              ChoiceChip(
                                label: Text(
                                  'Hired Jobs',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                selected: selectedTag == 'hired',
                                onSelected: (_) => _handleTagSelection('hired'),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _buildJobList(),
                        ),
                      ],
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
                      'Here are your contracts, ${_userData != null && _userData!['fullName'] != null ? _userData!['fullName'].split(' ')[0] : 'User'}',
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

  Widget _buildJobList() {
    List<QueryDocumentSnapshot> jobsToShow = [];
    if (selectedTag == 'all') {
      jobsToShow = [...postedJobs, ...hiredJobs];
    } else if (selectedTag == 'posted') {
      jobsToShow = postedJobs;
    } else if (selectedTag == 'hired') {
      jobsToShow = hiredJobs;
    }

    return ListView.separated(
      itemCount: jobsToShow.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final job = jobsToShow[index];
        final jobData = job.data() as Map<String, dynamic>;
        final jobTitle = jobData['jobTitle'] as String? ?? '';
        final jobDescription = jobData['jobDescription'] as String? ?? '';
        final jobStatus = jobData['status'] as String? ?? '';

        return ListTile(
          title: Text(jobTitle),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(jobDescription),
              const SizedBox(height: 4),
              Row(
                children: [
                  _getStatusIcon(jobStatus),
                  const SizedBox(width: 4),
                  Text(jobStatus, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          trailing: jobData['uploadedBy'] == _user.uid
              ? PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'reopen',
                      child: Text('Reopen'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'close',
                      child: Text('Close'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'complete',
                      child: Text('Mark as Completed'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                  onSelected: (value) {
                    _handlePopupMenuSelection(job.id, jobStatus, value);
                  },
                )
              : null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JobDetailScreen(
                  jobId: job.id,
                  job: job,
                  status: jobStatus,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Icon _getStatusIcon(String status) {
    switch (status) {
      case 'opened':
        return const Icon(Icons.lock_open, color: Colors.green, size: 16);
      case 'closed':
        return const Icon(Icons.lock, color: Colors.red, size: 16);
      case 'completed':
        return const Icon(Icons.check_circle, color: Colors.blue, size: 16);
      case 'accepted':
        return const Icon(Icons.check, color: Colors.orange, size: 16);
      default:
        return const Icon(Icons.info, color: Colors.grey, size: 16);
    }
  }
}
