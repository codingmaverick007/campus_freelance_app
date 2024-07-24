import 'package:flutter/material.dart';

class GradientWaveBackground extends StatelessWidget {
  final double height;

  GradientWaveBackground({required this.height});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: BackgroundWaveClipper(),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: height, // Use the provided height
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 76, 174, 255),
        ),
      ),
    );
  }
}

class BackgroundWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0.0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
