import 'package:flutter/material.dart';

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
          label: Text(objective),
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