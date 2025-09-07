import 'package:flutter/material.dart';
import 'package:nookly/presentation/widgets/selection_chips.dart';

class PhysicalActivenessChips extends StatelessWidget {
  final List<String> availablePhysicalActiveness;
  final List<String> selectedPhysicalActiveness;
  final Function(List<String>) onPhysicalActivenessChanged;

  const PhysicalActivenessChips({
    super.key,
    required this.availablePhysicalActiveness,
    required this.selectedPhysicalActiveness,
    required this.onPhysicalActivenessChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SelectionChips(
      availableOptions: availablePhysicalActiveness,
      selectedOptions: selectedPhysicalActiveness,
      onSelectionChanged: onPhysicalActivenessChanged,
      title: 'Physical Activeness',
    );
  }
}
