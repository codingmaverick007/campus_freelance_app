import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/freelancer.dart';

class FreelancerProvider with ChangeNotifier {
  List<Freelancer> _freelancers = [];

  List<Freelancer> get freelancers => _freelancers;

  FreelancerProvider() {
    _fetchFreelancers();
  }

  Future<void> _fetchFreelancers() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isFreelancer', isEqualTo: true)
          .get();

      _freelancers = snapshot.docs.map((doc) {
        return Freelancer.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      notifyListeners();
    } catch (e) {
      print("Error fetching freelancers: $e");
    }
  }
}
