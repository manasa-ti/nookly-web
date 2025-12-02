import 'package:flutter/material.dart';
import 'package:nookly/core/theme/app_text_styles.dart';

class ObjectiveChips extends StatelessWidget {
  final List<String> availableObjectives;
  final List<String> selectedObjectives;
  final Function(List<String>) onObjectivesChanged;

  const ObjectiveChips({
    super.key,
    required this.availableObjectives,
    required this.selectedObjectives,
    required this.onObjectivesChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (availableObjectives.isEmpty) {
      return const Center(child: Text('No objectives available.'));
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: availableObjectives.map((objective) {
        final isSelected = selectedObjectives.contains(objective);
        return FilterChip(
          label: Text(
            objective,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFFD6D9E6),
              fontFamily: 'Nunito',
              fontSize: AppTextStyles.getChipFontSize(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          selected: isSelected,
          onSelected: (bool selected) {
            final List<String> updatedObjectives =
                List<String>.from(selectedObjectives);
            if (selected) {
              if (!updatedObjectives.contains(objective)) {
                updatedObjectives.add(objective);
              }
            } else {
              updatedObjectives.remove(objective);
            }
            onObjectivesChanged(updatedObjectives);
          },
          selectedColor: const Color(0xFF35548b),
          backgroundColor: const Color(0xFF283d67),
          checkmarkColor: Colors.white,
          side: BorderSide(
            color: isSelected ? const Color(0xFF35548b) : const Color(0xFF8FA3C8),
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