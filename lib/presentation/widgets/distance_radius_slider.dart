import 'package:flutter/material.dart';

class DistanceRadiusSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int divisions;

  const DistanceRadiusSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1.0,
    this.max = 150.0,
    this.divisions = 149,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preferred Distance Radius',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2.0, // Thinner track for more subtle appearance
            activeTrackColor: Colors.white,
            inactiveTrackColor: const Color(0xFF4C5C8A),
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0), // Smaller thumb to match thinner track
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0), // Smaller overlay
            valueIndicatorColor: const Color(0xFF4C5C8A), // Blue color for tooltip
            valueIndicatorShape: const PaddleSliderValueIndicatorShape(), // Same shape as age range slider
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: '${value.round()} km',
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${min.round()} km',
              style: const TextStyle(fontFamily: 'Nunito', color: Color(0xFFD6D9E6), fontSize: 16),
            ),
            Text(
              '${value.round()} km',
              style: const TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: 16),
            ),
            Text(
              '${max.round()} km',
              style: const TextStyle(fontFamily: 'Nunito', color: Color(0xFFD6D9E6), fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }
} 