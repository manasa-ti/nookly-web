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
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableInterests.map((interest) {
        final isSelected = widget.selectedInterests.contains(interest);
        return FilterChip(
          label: Text(
            interest,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFFD6D9E6),
              fontFamily: 'Nunito',
              fontSize: (MediaQuery.of(context).size.width * 0.04).clamp(13.0, 16.0),
              fontWeight: FontWeight.w500,
            ),
          ),
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
          selectedColor: const Color(0xFF4C5C8A),
          backgroundColor: const Color(0xFF35548b),
          checkmarkColor: Colors.white,
          side: BorderSide(
            color: isSelected ? const Color(0xFF4C5C8A) : const Color(0xFF8FA3C8),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }
} 