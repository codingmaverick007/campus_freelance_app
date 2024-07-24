import 'package:campus_freelance_app/models/rating.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RatingService {
  final CollectionReference ratingsCollection =
      FirebaseFirestore.instance.collection('ratings');

  Future<void> submitRating(Rating rating) async {
    await ratingsCollection.add({
      'userId': rating.userId,
      'reviewerName': rating.reviewerName,
      'freelancerId': rating.freelancerId,
      'rating': rating.rating,
      'feedback': rating.feedback,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<double> calculateAverageRating(String freelancerId) async {
    final QuerySnapshot<Object?> snapshot = await ratingsCollection
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
  }
}
