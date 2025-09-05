import 'package:flutter/material.dart';
import 'package:nookly/presentation/widgets/selection_chips.dart';

class AvailabilityChips extends StatelessWidget {
  final List<String> availableAvailability;
  final List<String> selectedAvailability;
  final Function(List<String>) onAvailabilityChanged;

  const AvailabilityChips({
    super.key,
    required this.availableAvailability,
    required this.selectedAvailability,
    required this.onAvailabilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SelectionChips(
      availableOptions: availableAvailability,
      selectedOptions: selectedAvailability,
      onSelectionChanged: onAvailabilityChanged,
      title: 'Availability',
    );
  }
}
