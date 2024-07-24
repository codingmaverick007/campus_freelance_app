class Freelancer {
  final String id;
  final String name;
  final String? title;
  final String? imageUrl;
  final String? studentId;
  final String? programme;
  final String? bio;
  final String? portfolio;
  final List<String>? skills;
  final List<String>? hobbiesAndInterests;

  Freelancer({
    required this.id,
    required this.name,
    this.title,
    this.imageUrl,
    this.studentId,
    this.programme,
    this.bio,
    this.portfolio,
    this.skills,
    this.hobbiesAndInterests,
  });

  factory Freelancer.fromMap(Map<String, dynamic> data, String id) {
    return Freelancer(
      id: id,
      name: data['fullName'] ?? '',
      title: data['title'],
      imageUrl: data['profileImageUrl'],
      studentId: data['studentId'],
      programme: data['programme'],
      bio: data['bio'],
      portfolio: data['portfolio'],
      skills: List<String>.from(data['skills'] ?? []),
      hobbiesAndInterests: List<String>.from(data['hobbiesAndInterests'] ?? []),
    );
  }
}
