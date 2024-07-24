class Bookmark {
  final String id;
  final String name;
  final String imageUrl;
  // Add other fields as needed

  Bookmark({
    required this.id,
    required this.name,
    required this.imageUrl,
    // Add other fields as needed
  });

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'],
      name: map['name'],
      imageUrl: map['imageUrl'],
      // Initialize other fields
    );
  }
}
