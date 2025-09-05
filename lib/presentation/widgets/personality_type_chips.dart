import 'package:flutter/material.dart';
import 'package:nookly/presentation/widgets/selection_chips.dart';

class PersonalityTypeChips extends StatelessWidget {
  final List<String> availablePersonalityTypes;
  final List<String> selectedPersonalityTypes;
  final Function(List<String>) onPersonalityTypesChanged;

  const PersonalityTypeChips({
    super.key,
    required this.availablePersonalityTypes,
    required this.selectedPersonalityTypes,
    required this.onPersonalityTypesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SelectionChips(
      availableOptions: availablePersonalityTypes,
      selectedOptions: selectedPersonalityTypes,
      onSelectionChanged: onPersonalityTypesChanged,
      title: 'Personality Type',
    );
  }
}
