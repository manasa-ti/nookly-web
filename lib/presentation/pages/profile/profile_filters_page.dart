import 'package:flutter/material.dart';
import 'package:nookly/presentation/widgets/interest_chips.dart';
import 'package:nookly/presentation/widgets/objective_chips.dart';
import 'package:nookly/presentation/widgets/physical_activeness_chips.dart';
import 'package:nookly/presentation/widgets/availability_chips.dart';
import 'package:nookly/presentation/widgets/distance_radius_slider.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  late List<String> _selectedPhysicalActiveness;
  late List<String> _selectedAvailability;

  // Available options
  List<String> _availableObjectives = [];
  List<String> _availablePhysicalActiveness = [];
  List<String> _availableAvailability = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndOptions();
  }

  Future<void> _saveFilterPreferences() async {
    print('🔵 FILTER DEBUG: Saving filter preferences');
    print('🔵 FILTER DEBUG: Physical Activeness: $_selectedPhysicalActiveness');
    print('🔵 FILTER DEBUG: Availability: $_selectedAvailability');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('filter_physical_activeness', jsonEncode(_selectedPhysicalActiveness));
    await prefs.setString('filter_availability', jsonEncode(_selectedAvailability));
    print('🔵 FILTER DEBUG: Filter preferences saved successfully');
  }

  Future<void> _loadFilterPreferences() async {
    print('🔵 FILTER DEBUG: Loading filter preferences');
    final prefs = await SharedPreferences.getInstance();
    final physicalActivenessJson = prefs.getString('filter_physical_activeness');
    final availabilityJson = prefs.getString('filter_availability');
    
    if (physicalActivenessJson != null) {
      _selectedPhysicalActiveness = List<String>.from(jsonDecode(physicalActivenessJson));
      print('🔵 FILTER DEBUG: Loaded Physical Activeness: $_selectedPhysicalActiveness');
    } else {
      print('🔵 FILTER DEBUG: No Physical Activeness preferences found');
    }
    if (availabilityJson != null) {
      _selectedAvailability = List<String>.from(jsonDecode(availabilityJson));
      print('🔵 FILTER DEBUG: Loaded Availability: $_selectedAvailability');
    } else {
      print('🔵 FILTER DEBUG: No Availability preferences found');
    }
  }

  Future<void> _loadCurrentUserAndOptions() async {
    try {
      final authRepository = GetIt.instance<AuthRepository>();
      final user = await authRepository.getCurrentUser();
      
      if (user != null) {
        _currentUser = user;
        
        // Load available options using consolidated API
        final profileOptions = await authRepository.getProfileOptions();
        _availableObjectives = profileOptions['objectives'] ?? [];
        _availablePhysicalActiveness = profileOptions['physical_activeness'] ?? [];
        _availableAvailability = profileOptions['availability'] ?? [];
        
        // Initialize form with current user data
        _ageRange = RangeValues(
          (_currentUser.preferredAgeRange?['lower_limit']?.toDouble() ?? 18.0),
          (_currentUser.preferredAgeRange?['upper_limit']?.toDouble() ?? 80.0),
        );
        _distanceRadius = (_currentUser.preferredDistanceRadius ?? 40).toDouble();
        _selectedInterests = _currentUser.interests ?? [];
        _selectedObjectives = _currentUser.objectives ?? [];
        // Initialize new fields as empty (not pre-selected from user's own profile)
        _selectedPhysicalActiveness = [];
        _selectedAvailability = [];
        
        // Load saved filter preferences
        await _loadFilterPreferences();
        
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

  void _onPhysicalActivenessChanged(List<String> physicalActiveness) {
    setState(() {
      _selectedPhysicalActiveness = physicalActiveness;
      _hasChanges = true;
    });
  }

  void _onAvailabilityChanged(List<String> availability) {
    setState(() {
      _selectedAvailability = availability;
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
        personalityType: _currentUser.personalityType,
        physicalActiveness: _currentUser.physicalActiveness,
        availability: _currentUser.availability,
        profilePic: _currentUser.profilePic,
        preferredDistanceRadius: _distanceRadius.round(),
      );

      // Update profile (for interests, objectives, age range, distance)
      final authRepository = GetIt.instance<AuthRepository>();
      await authRepository.updateUserProfile(updatedUser);

      // Save filter preferences (for physical activeness and availability)
      await _saveFilterPreferences();

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
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF2d457f),
      appBar: AppBar(
        title: Text('Profile Filters', style: TextStyle(fontSize: (size.width * 0.045).clamp(16.0, 18.0), fontWeight: FontWeight.w500, fontFamily: 'Nunito', color: Colors.white)),
        backgroundColor: const Color(0xFF2d457f),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
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
                            fontSize: (size.width * 0.035).clamp(12.0, 14.0),
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Age Range
                        Text(
                          'Age Range',
                          style: TextStyle(
                            fontSize: (size.width * 0.04).clamp(14.0, 16.0),
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            fontFamily: 'Nunito',
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
                            Text('${_ageRange.start.round()} years', style: const TextStyle(color: Colors.white70, fontFamily: 'Nunito')),
                            Text('${_ageRange.end.round()} years', style: const TextStyle(color: Colors.white70, fontFamily: 'Nunito')),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Distance Radius
                        Text(
                          'Preferred Distance Radius',
                          style: TextStyle(fontFamily: 'Nunito', fontSize: (size.width * 0.04).clamp(14.0, 16.0), fontWeight: FontWeight.w500, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        DistanceRadiusSlider(
                          value: _distanceRadius,
                          onChanged: _onDistanceRadiusChanged,
                        ),
                        const SizedBox(height: 16),

                        // Interests
                        Text(
                          'Interests',
                          style: TextStyle(
                            fontSize: (size.width * 0.04).clamp(14.0, 16.0),
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            fontFamily: 'Nunito',
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
                        Text(
                          'Objectives',
                          style: TextStyle(
                            fontSize: (size.width * 0.04).clamp(14.0, 16.0),
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        const SizedBox(height: 6),
                        ObjectiveChips(
                          availableObjectives: _availableObjectives,
                          selectedObjectives: _selectedObjectives,
                          onObjectivesChanged: _onObjectivesChanged,
                        ),
                        const SizedBox(height: 16),

                        // Physical Activeness
                        PhysicalActivenessChips(
                          availablePhysicalActiveness: _availablePhysicalActiveness,
                          selectedPhysicalActiveness: _selectedPhysicalActiveness,
                          onPhysicalActivenessChanged: _onPhysicalActivenessChanged,
                        ),
                        const SizedBox(height: 16),

                        // Availability
                        AvailabilityChips(
                          availableAvailability: _availableAvailability,
                          selectedAvailability: _selectedAvailability,
                          onAvailabilityChanged: _onAvailabilityChanged,
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
                                : Text(
                                    'Update Filters',
                                    style: TextStyle(
                                      fontSize: (size.width * 0.04).clamp(13.0, 15.0),
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Nunito',
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