import 'package:flutter/material.dart';
import 'package:nookly/presentation/widgets/interest_chips.dart';
import 'package:nookly/presentation/widgets/objective_chips.dart';
import 'package:nookly/presentation/widgets/distance_radius_slider.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:get_it/get_it.dart';

class ProfileFiltersPage extends StatefulWidget {
  const ProfileFiltersPage({super.key});

  @override
  State<ProfileFiltersPage> createState() => _ProfileFiltersPageState();
}

class _ProfileFiltersPageState extends State<ProfileFiltersPage> {
  final _formKey = GlobalKey<FormState>();
  late User _currentUser;
  bool _isLoading = true;
  bool _hasChanges = false;
  String? _errorMessage;

  // Form controllers
  late RangeValues _ageRange;
  late double _distanceRadius;
  late List<String> _selectedInterests;
  late List<String> _selectedObjectives;

  // Available options
  List<String> _availableObjectives = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndOptions();
  }

  Future<void> _loadCurrentUserAndOptions() async {
    try {
      final authRepository = GetIt.instance<AuthRepository>();
      final user = await authRepository.getCurrentUser();
      
      if (user != null) {
        _currentUser = user;
        
        // Load available options
        _availableObjectives = await authRepository.getPredefinedObjectives();
        
        // Initialize form with current user data
        _ageRange = RangeValues(
          (_currentUser.preferredAgeRange?['lower_limit']?.toDouble() ?? 18.0),
          (_currentUser.preferredAgeRange?['upper_limit']?.toDouble() ?? 80.0),
        );
        _distanceRadius = (_currentUser.preferredDistanceRadius ?? 40).toDouble();
        _selectedInterests = _currentUser.interests ?? [];
        _selectedObjectives = _currentUser.objectives ?? [];
        
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load user data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _onAgeRangeChanged(RangeValues values) {
    setState(() {
      _ageRange = values;
      _hasChanges = true;
    });
  }

  void _onDistanceRadiusChanged(double value) {
    setState(() {
      _distanceRadius = value;
      _hasChanges = true;
    });
  }

  void _onInterestsChanged(List<String> interests) {
    setState(() {
      _selectedInterests = interests;
      _hasChanges = true;
    });
  }

  void _onObjectivesChanged(List<String> objectives) {
    setState(() {
      _selectedObjectives = objectives;
      _hasChanges = true;
    });
  }

  Future<void> _updateFilters() async {
    if (!_hasChanges) {
      Navigator.pop(context, true); // Return with refresh flag
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Create updated user with new filter values
      final updatedUser = User(
        id: _currentUser.id,
        email: _currentUser.email,
        name: _currentUser.name,
        age: _currentUser.age,
        sex: _currentUser.sex,
        seekingGender: _currentUser.seekingGender,
        location: _currentUser.location,
        preferredAgeRange: {
          'lower_limit': _ageRange.start.round(),
          'upper_limit': _ageRange.end.round(),
        },
        hometown: _currentUser.hometown,
        bio: _currentUser.bio,
        interests: _selectedInterests,
        objectives: _selectedObjectives,
        profilePic: _currentUser.profilePic,
        preferredDistanceRadius: _distanceRadius.round(),
      );

      // Update profile
      final authRepository = GetIt.instance<AuthRepository>();
      await authRepository.updateUserProfile(updatedUser);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Filters updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back with refresh flag
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to update filters: ${e.toString()}';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating filters: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Filters', style: TextStyle(fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Adjust your preferences to find better matches',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Age Range
                        Text(
                          'Age Range',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
                            rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 6.0), // Smaller range thumb
                            rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
                            valueIndicatorColor: const Color(0xFF4C5C8A), // Blue color for tooltip
                            valueIndicatorShape: const PaddleSliderValueIndicatorShape(), // Same shape as age range slider
                          ),
                          child: RangeSlider(
                            values: _ageRange,
                            min: 18,
                            max: 80,
                            divisions: 62,
                            labels: RangeLabels(
                              '${_ageRange.start.round()} years',
                              '${_ageRange.end.round()} years',
                            ),
                            onChanged: _onAgeRangeChanged,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_ageRange.start.round()} years'),
                            Text('${_ageRange.end.round()} years'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Distance Radius
                        DistanceRadiusSlider(
                          value: _distanceRadius,
                          onChanged: _onDistanceRadiusChanged,
                        ),
                        const SizedBox(height: 16),

                        // Interests
                        Text(
                          'Interests',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InterestChips(
                          selectedInterests: _selectedInterests,
                          onInterestsChanged: _onInterestsChanged,
                          authRepository: GetIt.instance<AuthRepository>(),
                        ),
                        const SizedBox(height: 16),

                        // Objectives
                        const Text(
                          'Objectives',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ObjectiveChips(
                          availableObjectives: _availableObjectives,
                          selectedObjectives: _selectedObjectives,
                          onObjectivesChanged: _onObjectivesChanged,
                        ),
                        const SizedBox(height: 20),

                        // Update Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateFilters,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: const Color(0xFFf4656f),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Update Filters',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
} 