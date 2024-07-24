import 'package:campus_freelance_app/screens/profile_screen.dart';
import 'package:flutter/material.dart';

class SliverSearchAppBar extends SliverPersistentHeaderDelegate {
  final double maxHeight;
  final double minHeight;
  final Widget? searchBar;
  final String? profileImageUrl;
  final VoidCallback onSuffixIconTap;

  SliverSearchAppBar({
    required this.maxHeight,
    required this.minHeight,
    this.searchBar,
    this.profileImageUrl,
    required this.onSuffixIconTap,
  });

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bool isCollapsed = shrinkOffset > (maxHeight - minHeight) / 2;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: Colors.blue,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/logo.png',
                        height: 50,
                      ), // Replace with your logo
                    ),
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          radius: 25,
                          backgroundImage: profileImageUrl != null
                              ? NetworkImage(profileImageUrl!)
                              : const AssetImage('assets/avatar.png')
                                  as ImageProvider,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                if (!isCollapsed)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(child: searchBar!),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant SliverSearchAppBar oldDelegate) {
    return oldDelegate.maxHeight != maxHeight ||
        oldDelegate.minHeight != minHeight ||
        oldDelegate.searchBar != searchBar ||
        oldDelegate.profileImageUrl != profileImageUrl;
  }
}
