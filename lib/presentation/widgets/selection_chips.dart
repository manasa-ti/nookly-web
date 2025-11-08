import 'package:flutter/material.dart';

class SelectionChips extends StatelessWidget {
  final List<String> availableOptions;
  final List<String> selectedOptions;
  final Function(List<String>) onSelectionChanged;
  final String? title;

  const SelectionChips({
    super.key,
    required this.availableOptions,
    required this.selectedOptions,
    required this.onSelectionChanged,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (availableOptions.isEmpty) {
      return const Center(child: Text('No options available.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: (MediaQuery.of(context).size.width * 0.04).clamp(14.0, 16.0),
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableOptions.map((option) {
            final isSelected = selectedOptions.contains(option);
            return FilterChip(
              label: Text(
                option,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFD6D9E6),
                  fontFamily: 'Nunito',
                  fontSize: (MediaQuery.of(context).size.width * 0.035).clamp(12.0, 15.0),
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (bool selected) {
                final List<String> updatedOptions = List<String>.from(selectedOptions);
                if (selected) {
                  if (!updatedOptions.contains(option)) {
                    updatedOptions.add(option);
                  }
                } else {
                  updatedOptions.remove(option);
                }
                onSelectionChanged(updatedOptions);
              },
              selectedColor: const Color(0xFF4C5C8A),
              backgroundColor: const Color(0xFF384E85),
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
        ),
      ],
    );
  }
}
