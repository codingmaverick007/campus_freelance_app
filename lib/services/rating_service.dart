import 'package:campus_freelance_app/models/rating.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RatingService {
  final CollectionReference ratingsCollection =
      FirebaseFirestore.instance.collection('ratings');
  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users'); // Assuming 'users' collection

  Future<void> submitRating(Rating rating) async {
    try {
      // Add rating to ratings collection
      await ratingsCollection.add({
        'userId': rating.userId,
        'reviewerName': rating.reviewerName,
        'freelancerId': rating.freelancerId,
        'rating': rating.rating,
        'feedback': rating.feedback,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update average rating in user document
      await _updateUserAverageRating(rating.userId);
    } catch (e) {
      print("Error submitting rating: $e");
    }
  }

  Future<void> _updateUserAverageRating(String userId) async {
    try {
      final QuerySnapshot snapshot =
          await ratingsCollection.where('userId', isEqualTo: userId).get();

      if (snapshot.docs.isEmpty) {
        // Set default rating if no ratings found
        await usersCollection.doc(userId).set({
          'averageRating': 0.0,
        }, SetOptions(merge: true));
        return;
      }

      double totalStars = 0;
      double totalRatings = snapshot.docs.length as double;

      for (final doc in snapshot.docs) {
        final rating = doc['rating'];
        if (rating is int) {
          totalStars += rating.toDouble();
        } else if (rating is double) {
          totalStars += rating;
        } else {
          // Handle unexpected types gracefully
          print('Unexpected rating type: ${rating.runtimeType}');
        }
      }

      double averageRating = totalStars / totalRatings;

      // Update or set the average rating in the user's document
      await usersCollection.doc(userId).set({
        'averageRating': averageRating, // Ensure correct field name
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error updating user average rating: $e");
    }
  }

  Future<double> calculateAverageRating(String freelancerId) async {
    try {
      final QuerySnapshot snapshot = await ratingsCollection
          .where('freelancerId', isEqualTo: freelancerId)
          .get();

      if (snapshot.docs.isEmpty) {
        return 0.0; // Default rating if no ratings found
      }

      double totalStars = 0;
      int totalRatings = snapshot.docs.length;

      for (final doc in snapshot.docs) {
        final rating = doc['rating'];
        if (rating is int) {
          totalStars += rating.toDouble();
        } else if (rating is double) {
          totalStars += rating;
        } else {
          // Handle unexpected types gracefully
          print('Unexpected rating type: ${rating.runtimeType}');
        }
      }

      return totalStars / totalRatings;
    } catch (e) {
      print("Error calculating average rating: $e");
      return 0.0;
    }
  }
}
