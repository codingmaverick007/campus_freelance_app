import 'package:flutter/material.dart';

class FilterScreen extends StatefulWidget {
  final Function(List<String> selectedCategories) applyFilters;
  final Function() clearFilters;
  final List<String> initialSelectedCategories;

  FilterScreen({
    required this.applyFilters,
    required this.initialSelectedCategories,
    required this.clearFilters,
  });

  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final List<String> _categories = [
    'Tutoring',
    'Proofreading and Editing',
    'Graphic Design',
    'Photography and Videography',
    'Writing',
    'IT Support',
    'Web Development',
    'App Development',
    'Data Entry',
    'Virtual Assistance',
    'Event Planning',
    'Event Assistance',
    'Fitness Training',
    'Language Lessons',
    'Music Lessons',
    'Handyman Services',
    'Moving Assistance',
    'House Sitting / Pet Sitting',
    'Custom Requests',
  ];

  late List<String> _selectedCategories;

  @override
  void initState() {
    super.initState();
    _selectedCategories = List.from(widget.initialSelectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Categories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _selectedCategories.clear();
                    });
                    widget.clearFilters();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return ChoiceChip(
                  label: Text(
                    category,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      isSelected
                          ? _selectedCategories.remove(category)
                          : _selectedCategories.add(category);
                    });
                    widget.applyFilters(_selectedCategories);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
