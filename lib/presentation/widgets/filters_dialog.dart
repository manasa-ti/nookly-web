import 'package:flutter/material.dart';
import 'package:hushmate/core/config/app_config.dart';

class FiltersDialog extends StatefulWidget {
  final Map<String, dynamic> currentFilters;

  const FiltersDialog({
    super.key,
    required this.currentFilters,
  });

  @override
  State<FiltersDialog> createState() => _FiltersDialogState();
}

class _FiltersDialogState extends State<FiltersDialog> {
  late RangeValues _ageRange;
  late String _selectedGender;
  late double _maxDistance;
  late List<String> _selectedInterests;
  late TextEditingController _hometownController;
  late List<String> _selectedObjectives;

  @override
  void initState() {
    super.initState();
    _ageRange = RangeValues(
      widget.currentFilters['minAge']?.toDouble() ?? 18,
      widget.currentFilters['maxAge']?.toDouble() ?? 100,
    );
    _selectedGender = widget.currentFilters['gender'] ?? 'All';
    _maxDistance = widget.currentFilters['maxDistance']?.toDouble() ?? 100;
    _selectedInterests = List<String>.from(widget.currentFilters['interests'] ?? []);
    _hometownController = TextEditingController(text: widget.currentFilters['hometown'] ?? '');
    _selectedObjectives = List<String>.from(widget.currentFilters['objectives'] ?? []);
  }

  @override
  void dispose() {
    _hometownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _ageRange = const RangeValues(18, 100);
                      _selectedGender = 'All';
                      _maxDistance = 100;
                      _selectedInterests = [];
                      _hometownController.clear();
                      _selectedObjectives = [];
                    });
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Age Range',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            RangeSlider(
              values: _ageRange,
              min: 18,
              max: 100,
              divisions: 82,
              labels: RangeLabels(
                _ageRange.start.round().toString(),
                _ageRange.end.round().toString(),
              ),
              onChanged: (RangeValues values) {
                setState(() {
                  _ageRange = values;
                });
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Gender',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['All', 'Male', 'Female'].map((gender) {
                return ChoiceChip(
                  label: Text(gender),
                  selected: _selectedGender == gender,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedGender = gender;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Maximum Distance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: _maxDistance,
              min: 1,
              max: 100,
              divisions: 99,
              label: '${_maxDistance.round()} miles',
              onChanged: (value) {
                setState(() {
                  _maxDistance = value;
                });
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Hometown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _hometownController,
              decoration: const InputDecoration(
                hintText: 'Enter hometown',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Interests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Music',
                'Movies',
                'Sports',
                'Travel',
                'Food',
                'Art',
                'Books',
                'Fitness',
                'Photography',
                'Technology',
              ].map((interest) {
                return FilterChip(
                  label: Text(interest),
                  selected: _selectedInterests.contains(interest),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedInterests.add(interest);
                      } else {
                        _selectedInterests.remove(interest);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Objectives',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Short Term',
                'Long Term',
                'Serious Committed Relationship',
                'Casual',
                'ONS',
                'FWB',
                'Friends to Hang Out',
                'Emotional Connection',
              ].map((objective) {
                return FilterChip(
                  label: Text(objective),
                  selected: _selectedObjectives.contains(objective),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedObjectives.add(objective);
                      } else {
                        _selectedObjectives.remove(objective);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'minAge': _ageRange.start.round(),
                      'maxAge': _ageRange.end.round(),
                      'gender': _selectedGender,
                      'maxDistance': _maxDistance.round(),
                      'interests': _selectedInterests,
                      'hometown': _hometownController.text.trim(),
                      'objectives': _selectedObjectives,
                    });
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 