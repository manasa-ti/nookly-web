import 'package:flutter/material.dart';

class DisappearingTimeSelector extends StatelessWidget {
  final int selectedTime;
  final Function(int) onTimeSelected;

  const DisappearingTimeSelector({
    Key? key,
    required this.selectedTime,
    required this.onTimeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final times = [3, 5, 10, 30]; // Available times in seconds

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Message will disappear after:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: times.map((time) {
              final isSelected = time == selectedTime;
              return ChoiceChip(
                label: Text('$time seconds'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    onTimeSelected(time);
                  }
                },
                backgroundColor: Colors.grey[200],
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
} 