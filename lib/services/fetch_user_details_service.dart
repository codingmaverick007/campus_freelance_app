import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FetchDetail {
  static Future<Map<String, dynamic>?> fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userData.exists) {
          return userData.data() as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
    return null;
  }
}

class FetchUploaderDetail {
  static Future<Map<String, dynamic>?> fetchUserData(String userId) async {
    try {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userData.exists) {
        return userData.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
    return null;
  }
}
