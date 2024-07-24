import 'package:campus_freelance_app/models/job';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobService {
  final CollectionReference jobCollection =
      FirebaseFirestore.instance.collection('jobs');

  Future<Job> fetchJob(String jobId) async {
    DocumentSnapshot doc = await jobCollection.doc(jobId).get();
    return Job.fromFirestore(doc);
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    await jobCollection.doc(jobId).update({'status': status});
  }
}
