class Rating {
  final String userId;
  final String freelancerId;
  final double rating;
  final String? feedback; // Optional feedback/comments
  final String? reviewerName;

  Rating({
    required this.userId,
    required this.freelancerId,
    required this.rating,
    this.feedback,
    required this.reviewerName,
  });
}
