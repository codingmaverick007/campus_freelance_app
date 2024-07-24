import 'package:card_loading/card_loading.dart';
import 'package:campus_freelance_app/screens/freelancer_detail_screen.dart';
import 'package:flutter/material.dart';
import '../models/freelancer.dart';
import '../services/rating_service.dart';

class FreelancerCard extends StatelessWidget {
  final Freelancer freelancer;
  final RatingService ratingService =
      RatingService(); // Initialize the rating service

  FreelancerCard(this.freelancer, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FreelancerDetailScreen(freelancer.id),
          ),
        );
        print('Freelancer card tapped');
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: freelancer.imageUrl != null
                    ? NetworkImage(freelancer.imageUrl!)
                    : const AssetImage('assets/avatar.png') as ImageProvider,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      freelancer.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      freelancer.title ?? 'No job title provided',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<double>(
                      future:
                          ratingService.calculateAverageRating(freelancer.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CardLoading(
                            height: 20,
                            width: 100,
                            borderRadius: BorderRadius.circular(10),
                          ); // Replace with card_loading widget
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          final averageRating = snapshot.data ?? 0.0;
                          return Row(
                            children: [
                              Text(
                                averageRating.toStringAsFixed(
                                    1), // Display rating with one decimal place
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
