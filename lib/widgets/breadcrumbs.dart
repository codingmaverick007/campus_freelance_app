import 'package:flutter/material.dart';

class Breadcrumb extends StatelessWidget {
  final int total;
  final int current;
  final ValueChanged<int> onBreadcrumbTapped;

  const Breadcrumb({
    required this.total,
    required this.current,
    required this.onBreadcrumbTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        return GestureDetector(
          onTap: () => onBreadcrumbTapped(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Container(
              width: 12.0,
              height: 12.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == current ? Colors.blue : Colors.grey,
              ),
            ),
          ),
        );
      }),
    );
  }
}
