import 'package:flutter/material.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';

class InterestChips extends StatefulWidget {
  final List<String> selectedInterests;
  final Function(List<String>) onInterestsChanged;
  final AuthRepository authRepository;

  const InterestChips({
    super.key,
    required this.selectedInterests,
    required this.onInterestsChanged,
    required this.authRepository,
  });

  @override
  State<InterestChips> createState() => _InterestChipsState();
}

class _InterestChipsState extends State<InterestChips> {
  List<String> _availableInterests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInterests();
  }

  Future<void> _loadInterests() async {
    try {
      final interests = await widget.authRepository.getPredefinedInterests();
      setState(() {
        _availableInterests = interests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // You might want to show an error message to the user here
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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