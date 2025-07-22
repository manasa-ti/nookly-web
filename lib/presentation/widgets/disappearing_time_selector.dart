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
          Text(
            'Message will disappear after:',
            style: TextStyle(
              fontSize: (MediaQuery.of(context).size.width * 0.04).clamp(14.0, 16.0),
              fontWeight: FontWeight.w500,
              fontFamily: 'Nunito',
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: times.map((time) {
              final isSelected = time == selectedTime;
              return FilterChip(
                label: Text(
                  '$time seconds',
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFFD6D9E6),
                    fontFamily: 'Nunito',
                    fontSize: (MediaQuery.of(context).size.width * 0.04).clamp(13.0, 16.0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    onTimeSelected(time);
                  }
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
          ),
        ],
      ),
    );
  }
} 