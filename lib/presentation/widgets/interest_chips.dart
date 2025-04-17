import 'package:flutter/material.dart';

class InterestChips extends StatefulWidget {
  final List<String> selectedInterests;
  final Function(List<String>) onInterestsChanged;

  const InterestChips({
    super.key,
    required this.selectedInterests,
    required this.onInterestsChanged,
  });

  @override
  State<InterestChips> createState() => _InterestChipsState();
}

class _InterestChipsState extends State<InterestChips> {
  final List<String> _availableInterests = [
    'Travel',
    'Music',
    'Movies',
    'Books',
    'Sports',
    'Fitness',
    'Cooking',
    'Photography',
    'Art',
    'Gaming',
    'Technology',
    'Nature',
    'Fashion',
    'Food',
    'Dancing',
    'Writing',
    'Languages',
    'Science',
    'History',
    'Politics',
    'Business',
    'Fitness',
    'Yoga',
    'Meditation',
    'Fashion',
    'Beauty',
    'Pets',
    'Coffee',
    'Wine',
    'Craft Beer',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableInterests.map((interest) {
        final isSelected = widget.selectedInterests.contains(interest);
        return FilterChip(
          label: Text(interest),
          selected: isSelected,
          onSelected: (bool selected) {
            final List<String> updatedInterests =
                List<String>.from(widget.selectedInterests);
            if (selected) {
              updatedInterests.add(interest);
            } else {
              updatedInterests.remove(interest);
            }
            widget.onInterestsChanged(updatedInterests);
          },
          selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
          checkmarkColor: Theme.of(context).primaryColor,
          labelStyle: TextStyle(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
      }).toList(),
    );
  }
} 