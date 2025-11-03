import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:nookly/presentation/widgets/distance_radius_slider.dart';
import 'package:nookly/presentation/widgets/custom_avatar.dart';
import 'package:nookly/presentation/widgets/personality_type_chips.dart';
import 'package:nookly/presentation/widgets/physical_activeness_chips.dart';
import 'package:nookly/presentation/widgets/availability_chips.dart';
import 'package:nookly/core/services/content_moderation_service.dart';
import 'package:nookly/core/services/screen_protection_service.dart';
import 'package:nookly/core/di/injection_container.dart';

class EditProfilePage extends StatefulWidget {
  final User user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _authRepository = GetIt.instance<AuthRepository>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isLoading = false;
  late ScreenProtectionService _screenProtectionService;
  String? _selectedImagePath;
  List<String> _selectedInterests = [];
  List<String> _selectedObjectives = [];
  List<String> _selectedPersonalityTypes = [];
  List<String> _selectedPhysicalActiveness = [];
  List<String> _selectedAvailability = [];
  List<String> _availableInterests = [];
  List<String> _availableObjectives = [];
  List<String> _availablePersonalityTypes = [];
  List<String> _availablePhysicalActiveness = [];
  List<String> _availableAvailability = [];
  RangeValues _ageRange = const RangeValues(18, 80);
  double _distanceRadius = 40.0; // Default value of 40 km
  bool _usedFallbackInterests = false;
  bool _usedFallbackObjectives = false;
  late User _currentUser;

  // Bio validation and helper text
  static const List<String> _bioTips = [
    'One cool thing about you',
    'What you truly seek',
    'One limitation of yours',
  ];

  bool _isBioValid(String? bio) {
    if (bio == null) return false;
    final normalized = bio.trim();
    final nonWhitespaceLen = normalized.replaceAll(RegExp(r"\s"), '').length;
    return normalized.length >= 100 && nonWhitespaceLen >= 80;
  }

  int _getBioLength(String? bio) {
    return bio?.trim().length ?? 0;
  }

  Color _bioProgressColor(String? bio) {
    final length = _getBioLength(bio);
    if (length >= 100) return Colors.green; // valid - green
    if (length >= 75) return const Color(0xFFE6C65B); // warning - yellow
    if (length >= 50) return const Color(0xFFFFA84A); // heads-up - orange
    return Colors.red; // too short - red
  }

  // Fallback static lists
  static const List<String> _fallbackObjectives = [
    'Short Term',
    'Long Term',
    'Serious Committed Relationship',
    'Casual',
    'ONS',
    'FWB',
    'Friends to Hang Out',
    'Emotional Connection',
  ];

  static const List<String> _fallbackInterests = [
    'Deep Conversations',
    'Friendly Warmth',
    'Shared Dreams',
    'Experiences Together',
    'Engaging Chats',
    'Netflix and Chill',
    'Intimate Talks',
    'Long Drives',
    'Coffee Dates',
    'Drink and Dine',
    'Cook at Home',
    'Game Night',
    'Cafe Hopping',
    'Late Night Walks',
    'Nature Walks / Hikes Together',
    'Travel Together',
  ];

  static const List<String> _fallbackPersonalityTypes = [
    'introvert',
    'extrovert',
    'ambivert',
    'foody',
    'chatty',
    'book worm',
    'party animal',
    'tech enthusiast',
    'explorative',
    'conventional',
    'easy going',
    'fussy',
    'spontaneous',
    'organised',
    'competitive',
    'loyalist',
    'peacemaker',
  ];

  static const List<String> _fallbackPhysicalActiveness = [
    'Weight lifter',
    'Runner',
    'Dancer',
    'Sporty',
    'walker',
    'couch potato',
  ];

  static const List<String> _fallbackAvailability = [
    'Majorly Texts sometimes calls',
    'calls only',
    'weekends only',
    'weekdays only',
    'all 7 days',
    'day time only',
    'nights only',
    'anytime',
  ];

  @override
  void initState() {
    super.initState();
    _screenProtectionService = sl<ScreenProtectionService>();
    // Enable screenshot protection for profile pages
    _enableScreenProtection();
    _currentUser = widget.user;
    // Initialize age range from user's preferred age range
    AppLogger.debug("preferredAgeRange initState:$_currentUser.preferredAgeRange.toString()");
    if (_currentUser.preferredAgeRange != null) {
      _ageRange = RangeValues(
        (_currentUser.preferredAgeRange!['lower_limit']?.toDouble() ?? 18.0).clamp(18.0, 80.0),
        (_currentUser.preferredAgeRange!['upper_limit']?.toDouble() ?? 80.0).clamp(18.0, 80.0),
      );
    }
    _initializeData();
  }

  /// Enable screenshot and screen recording protection for profile pages
  Future<void> _enableScreenProtection() async {
    if (!mounted) return;
    
    try {
      await _screenProtectionService.enableProtection(
        screenType: 'profile',
        context: context,
      );
      AppLogger.info('🔒 Screen protection enabled for edit profile');
    } catch (e) {
      AppLogger.error('Failed to enable screen protection', e);
    }
  }

  /// Disable screenshot protection
  Future<void> _disableScreenProtection() async {
    try {
      await _screenProtectionService.disableProtection();
      AppLogger.info('🔓 Screen protection disabled');
    } catch (e) {
      AppLogger.error('Failed to disable screen protection', e);
    }
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Fetch latest user profile
      final fetchedUser = await _authRepository.getCurrentUser();
      if (fetchedUser == null) {
        throw Exception('Failed to fetch user profile');
      }
      if (!mounted) return;
      setState(() {
        _currentUser = fetchedUser;
      });

      // Load all profile options with fallback
      try {
        final profileOptions = await _authRepository.getProfileOptions();
        _availableInterests = profileOptions['interests'] ?? [];
        _availableObjectives = profileOptions['objectives'] ?? [];
        _availablePersonalityTypes = profileOptions['personality_types'] ?? [];
        _availablePhysicalActiveness = profileOptions['physical_activeness'] ?? [];
        _availableAvailability = profileOptions['availability'] ?? [];
      } catch (e) {
        _availableInterests = _fallbackInterests;
        _availableObjectives = _fallbackObjectives;
        _availablePersonalityTypes = _fallbackPersonalityTypes;
        _availablePhysicalActiveness = _fallbackPhysicalActiveness;
        _availableAvailability = _fallbackAvailability;
        _usedFallbackInterests = true;
        _usedFallbackObjectives = true;
      }
      
      // Initialize form with current user data
      _nameController.text = _currentUser.name ?? '';
      _bioController.text = _currentUser.bio ?? '';
      _selectedInterests = List<String>.from(_currentUser.interests ?? []);
      _selectedObjectives = List<String>.from(_currentUser.objectives ?? []);
      _selectedPersonalityTypes = List<String>.from(_currentUser.personalityType ?? []);
      _selectedPhysicalActiveness = List<String>.from(_currentUser.physicalActiveness ?? []);
      _selectedAvailability = List<String>.from(_currentUser.availability ?? []);
      
      // Set distance radius from user's preferred distance radius
      _distanceRadius = (_currentUser.preferredDistanceRadius ?? 40).toDouble();
      
      // Set age range from user's preferred age range
      AppLogger.debug("preferredAgeRange initialized:$_currentUser.preferredAgeRange.toString()");
      if (_currentUser.preferredAgeRange != null) {
        final lowerLimit = _currentUser.preferredAgeRange!['lower_limit']?.toDouble() ?? 18.0;
        final upperLimit = _currentUser.preferredAgeRange!['upper_limit']?.toDouble() ?? 80.0;
        if (!mounted) return;
        setState(() {
          _ageRange = RangeValues(
            lowerLimit.clamp(18.0, 80.0),
            upperLimit.clamp(18.0, 80.0),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading data: $e')),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }



  bool _isFormValid() {
    // Check if any field has been modified
    final hasNameChanged = _nameController.text != _currentUser.name;
    final hasBioChanged = _bioController.text != (_currentUser.bio ?? '');
    // Note: Bio validation (100 chars minimum) is handled separately in _updateProfile
    final hasInterestsChanged = !listEquals(_selectedInterests, _currentUser.interests ?? []);
    
    // Use set comparison for objectives since order doesn't matter
    final currentObjectivesSet = Set<String>.from(_currentUser.objectives ?? []);
    final selectedObjectivesSet = Set<String>.from(_selectedObjectives);
    final hasObjectivesChanged = !currentObjectivesSet.difference(selectedObjectivesSet).isEmpty || 
                                !selectedObjectivesSet.difference(currentObjectivesSet).isEmpty;
    
    // Check personality types changes
    final currentPersonalityTypesSet = Set<String>.from(_currentUser.personalityType ?? []);
    final selectedPersonalityTypesSet = Set<String>.from(_selectedPersonalityTypes);
    final hasPersonalityTypesChanged = !currentPersonalityTypesSet.difference(selectedPersonalityTypesSet).isEmpty || 
                                      !selectedPersonalityTypesSet.difference(currentPersonalityTypesSet).isEmpty;
    
    // Check physical activeness changes
    final currentPhysicalActivenessSet = Set<String>.from(_currentUser.physicalActiveness ?? []);
    final selectedPhysicalActivenessSet = Set<String>.from(_selectedPhysicalActiveness);
    final hasPhysicalActivenessChanged = !currentPhysicalActivenessSet.difference(selectedPhysicalActivenessSet).isEmpty || 
                                        !selectedPhysicalActivenessSet.difference(currentPhysicalActivenessSet).isEmpty;
    
    // Check availability changes
    final currentAvailabilitySet = Set<String>.from(_currentUser.availability ?? []);
    final selectedAvailabilitySet = Set<String>.from(_selectedAvailability);
    final hasAvailabilityChanged = !currentAvailabilitySet.difference(selectedAvailabilitySet).isEmpty || 
                                  !selectedAvailabilitySet.difference(currentAvailabilitySet).isEmpty;
    
    // Debug logging
    AppLogger.debug('EditProfile: Current objectives: ${_currentUser.objectives}');
    AppLogger.debug('EditProfile: Selected objectives: $_selectedObjectives');
    AppLogger.debug('EditProfile: Current objectives set: $currentObjectivesSet');
    AppLogger.debug('EditProfile: Selected objectives set: $selectedObjectivesSet');
    AppLogger.debug('EditProfile: hasObjectivesChanged: $hasObjectivesChanged');
    
    final hasAgeRangeChanged = _ageRange.start != (_currentUser.preferredAgeRange?['lower_limit']?.toDouble() ?? 18) ||
                              _ageRange.end != (_currentUser.preferredAgeRange?['upper_limit']?.toDouble() ?? 80);
    final hasDistanceRadiusChanged = _distanceRadius.round() != (_currentUser.preferredDistanceRadius ?? 40);
    final hasImageChanged = _selectedImagePath != null;

    final isValid = hasNameChanged || 
           hasBioChanged || 
           hasInterestsChanged || 
           hasObjectivesChanged || 
           hasPersonalityTypesChanged ||
           hasPhysicalActivenessChanged ||
           hasAvailabilityChanged ||
           hasAgeRangeChanged || 
           hasDistanceRadiusChanged ||
           hasImageChanged;
    
    AppLogger.debug('EditProfile: Form valid: $isValid');
    return isValid;
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Ensure bio minimum length before moderation
    if (!_isBioValid(_bioController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please write at least 100 characters about yourself',
            style: TextStyle(
              color: Colors.black,
              fontSize: (MediaQuery.of(context).size.width * 0.04).clamp(14.0, 16.0),
              fontWeight: FontWeight.w500,
              fontFamily: 'Nunito',
            ),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Content moderation for bio
    final moderationService = ContentModerationService();
    final bioModerationResult = moderationService.moderateContent(_bioController.text, ContentType.bio);
    
    if (!bioModerationResult.isAppropriate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bio contains inappropriate content. Please revise your bio.',
            style: TextStyle(
              color: Colors.black,
              fontSize: (MediaQuery.of(context).size.width * 0.04).clamp(14.0, 16.0),
              fontWeight: FontWeight.w500,
              fontFamily: 'Nunito',
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Create updated user with all existing data and new values for changed fields
      final updatedUser = User(
        id: _currentUser.id,
        email: _currentUser.email,
        // Update only if changed
        name: _nameController.text != _currentUser.name ? _nameController.text : _currentUser.name,
        bio: _bioController.text != (_currentUser.bio ?? '') ? bioModerationResult.filteredText : _currentUser.bio,
        interests: !listEquals(_selectedInterests, _currentUser.interests ?? []) 
            ? _selectedInterests 
            : _currentUser.interests,
        objectives: (() {
          final currentObjectivesSet = Set<String>.from(_currentUser.objectives ?? []);
          final selectedObjectivesSet = Set<String>.from(_selectedObjectives);
          final hasObjectivesChanged = !currentObjectivesSet.difference(selectedObjectivesSet).isEmpty || 
                                      !selectedObjectivesSet.difference(currentObjectivesSet).isEmpty;
          return hasObjectivesChanged ? _selectedObjectives : _currentUser.objectives;
        })(),
        personalityType: (() {
          final currentPersonalityTypesSet = Set<String>.from(_currentUser.personalityType ?? []);
          final selectedPersonalityTypesSet = Set<String>.from(_selectedPersonalityTypes);
          final hasPersonalityTypesChanged = !currentPersonalityTypesSet.difference(selectedPersonalityTypesSet).isEmpty || 
                                            !selectedPersonalityTypesSet.difference(currentPersonalityTypesSet).isEmpty;
          return hasPersonalityTypesChanged ? _selectedPersonalityTypes : _currentUser.personalityType;
        })(),
        physicalActiveness: (() {
          final currentPhysicalActivenessSet = Set<String>.from(_currentUser.physicalActiveness ?? []);
          final selectedPhysicalActivenessSet = Set<String>.from(_selectedPhysicalActiveness);
          final hasPhysicalActivenessChanged = !currentPhysicalActivenessSet.difference(selectedPhysicalActivenessSet).isEmpty || 
                                              !selectedPhysicalActivenessSet.difference(currentPhysicalActivenessSet).isEmpty;
          return hasPhysicalActivenessChanged ? _selectedPhysicalActiveness : _currentUser.physicalActiveness;
        })(),
        availability: (() {
          final currentAvailabilitySet = Set<String>.from(_currentUser.availability ?? []);
          final selectedAvailabilitySet = Set<String>.from(_selectedAvailability);
          final hasAvailabilityChanged = !currentAvailabilitySet.difference(selectedAvailabilitySet).isEmpty || 
                                        !selectedAvailabilitySet.difference(currentAvailabilitySet).isEmpty;
          return hasAvailabilityChanged ? _selectedAvailability : _currentUser.availability;
        })(),
        preferredAgeRange: (_ageRange.start != (_currentUser.preferredAgeRange?['lower_limit']?.toDouble() ?? 18) ||
                           _ageRange.end != (_currentUser.preferredAgeRange?['upper_limit']?.toDouble() ?? 80))
            ? {
                'lower_limit': _ageRange.start.round(),
                'upper_limit': _ageRange.end.round(),
              }
            : _currentUser.preferredAgeRange,
        preferredDistanceRadius: _distanceRadius.round() != (_currentUser.preferredDistanceRadius ?? 40)
            ? _distanceRadius.round()
            : _currentUser.preferredDistanceRadius,
        profilePic: _selectedImagePath != null ? _selectedImagePath : _currentUser.profilePic,
        // Keep existing values for other fields
        age: _currentUser.age,
        sex: _currentUser.sex,
        location: _currentUser.location,
        seekingGender: _currentUser.seekingGender,
        hometown: _currentUser.hometown,
      );

      await _authRepository.updateUserProfile(updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }




  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Show fallback snackbars if needed
    if (_usedFallbackInterests) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_usedFallbackInterests) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Using default interests list'),
              duration: Duration(seconds: 2),
            ),
          );
          _usedFallbackInterests = false;
        }
      });
    }
    if (_usedFallbackObjectives) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_usedFallbackObjectives) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Using default objectives list'),
              duration: Duration(seconds: 2),
            ),
          );
          _usedFallbackObjectives = false;
        }
      });
    }
    AppLogger.debug("Profile pic : ${_currentUser.profilePic.toString()}");
    return Scaffold(
      backgroundColor: const Color(0xFF2e4781),
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: (size.width * 0.045).clamp(14.0, 18.0), fontWeight: FontWeight.w500)),
        backgroundColor: const Color(0xFF2e4781),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture
                    Center(
                      child: Stack(
                        children: [
                          CustomAvatar(
                            name: _nameController.text.isNotEmpty ? _nameController.text : _currentUser.name,
                            size: 80,
                          ),
                          // Profile picture upload disabled for now
                          // Positioned(
                          //   bottom: 0,
                          //   right: 0,
                          //   child: Container(
                          //     decoration: const BoxDecoration(
                          //       color: Color(0xFF4C5C8A),
                          //       shape: BoxShape.circle,
                          //     ),
                          //     child: IconButton(
                          //       icon: const Icon(Icons.camera_alt, color: Colors.white),
                          //       onPressed: () => _showImagePicker(),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: const Color(0xFF35548b),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white, fontFamily: 'Nunito'),
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            labelStyle: TextStyle(color: Color(0xFFD6D9E6), fontFamily: 'Nunito'),
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: const Color(0xFF35548b),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: TextFormField(
                          controller: _bioController,
                          maxLines: null,
                          minLines: 3,
                          style: const TextStyle(color: Colors.white, fontFamily: 'Nunito'),
                          decoration: InputDecoration(
                            labelText: 'Bio',
                            hintText: 'Tell us about yourself',
                            labelStyle: const TextStyle(color: Color(0xFFD6D9E6), fontFamily: 'Nunito'),
                            hintStyle: const TextStyle(color: Color(0xFFD6D9E6), fontFamily: 'Nunito'),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                          ),
                          validator: (value) {
                            return _isBioValid(value)
                                ? null
                                : 'Please write at least 100 characters about yourself';
                          },
                          onChanged: (value) {
                            setState(() {}); // Trigger rebuild for dynamic colors
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Character counter
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'min 100 required',
                        style: TextStyle(
                          color: _bioProgressColor(_bioController.text),
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF4C5C8A),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF2A3A5F).withOpacity(0.3),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.lightbulb_outline,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Bio Tips',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Nunito',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._bioTips.map((tip) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.only(top: 6, right: 8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4C5C8A),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: const TextStyle(
                                      color: Color(0xFFB0B3C7),
                                      fontFamily: 'Nunito',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Interests',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: (size.width * 0.04).clamp(14.0, 16.0), fontWeight: FontWeight.w500, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableInterests.map((interest) {
                        final isSelected = _selectedInterests.contains(interest);
                        return FilterChip(
                          label: Text(
                            interest,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFFD6D9E6),
                              fontFamily: 'Nunito',
                              fontSize: (size.width * 0.035).clamp(12.0, 15.0),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
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
                    const SizedBox(height: 16),
                    Text(
                      'Objectives',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: (size.width * 0.04).clamp(14.0, 16.0), fontWeight: FontWeight.w500, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableObjectives.map((objective) {
                        final isSelected = _selectedObjectives.contains(objective);
                        return FilterChip(
                          label: Text(
                            objective,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFFD6D9E6),
                              fontFamily: 'Nunito',
                              fontSize: (size.width * 0.035).clamp(12.0, 15.0),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
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
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedObjectives.add(objective);
                                AppLogger.debug('EditProfile: Added objective: $objective');
                                AppLogger.debug('EditProfile: Selected objectives after add: $_selectedObjectives');
                              } else {
                                _selectedObjectives.remove(objective);
                                AppLogger.debug('EditProfile: Removed objective: $objective');
                                AppLogger.debug('EditProfile: Selected objectives after remove: $_selectedObjectives');
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    PersonalityTypeChips(
                      availablePersonalityTypes: _availablePersonalityTypes,
                      selectedPersonalityTypes: _selectedPersonalityTypes,
                      onPersonalityTypesChanged: (personalityTypes) {
                        setState(() {
                          _selectedPersonalityTypes = personalityTypes;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    PhysicalActivenessChips(
                      availablePhysicalActiveness: _availablePhysicalActiveness,
                      selectedPhysicalActiveness: _selectedPhysicalActiveness,
                      onPhysicalActivenessChanged: (physicalActiveness) {
                        setState(() {
                          _selectedPhysicalActiveness = physicalActiveness;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    AvailabilityChips(
                      availableAvailability: _availableAvailability,
                      selectedAvailability: _selectedAvailability,
                      onAvailabilityChanged: (availability) {
                        setState(() {
                          _selectedAvailability = availability;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Preferred Age Range',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: (size.width * 0.04).clamp(14.0, 16.0), fontWeight: FontWeight.w500, color: Colors.white),
                    ),
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
                          _ageRange.start.round().toString(),
                          _ageRange.end.round().toString(),
                        ),
                        onChanged: (RangeValues values) {
                          setState(() {
                            _ageRange = values;
                          });
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_ageRange.start.round()} years', style: TextStyle(fontFamily: 'Nunito', color: Color(0xFFD6D9E6), fontSize: (size.width * 0.032).clamp(11.0, 14.0))),
                        Text('${_ageRange.end.round()} years', style: TextStyle(fontFamily: 'Nunito', color: Color(0xFFD6D9E6), fontSize: (size.width * 0.032).clamp(11.0, 14.0))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Preferred Distance Radius',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: (size.width * 0.04).clamp(14.0, 16.0), fontWeight: FontWeight.w500, color: Colors.white),
                    ),
                    DistanceRadiusSlider(
                      value: _distanceRadius,
                      onChanged: (value) {
                        setState(() {
                          _distanceRadius = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: Builder(
                        builder: (context) {
                          final isValid = _isFormValid();
                          AppLogger.debug('EditProfile: Save button - isValid: $isValid');
                          return ElevatedButton(
                            onPressed: isValid ? _updateProfile : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFf4656f),
                              disabledBackgroundColor: const Color(0xFFf4656f).withOpacity(0.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 1,
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white.withOpacity(0.7),
                            ),
                            child: Text(
                              'Save Changes',
                              style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: (size.width * 0.04).clamp(14.0, 16.0), fontWeight: FontWeight.w500),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _disableScreenProtection();
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
} 