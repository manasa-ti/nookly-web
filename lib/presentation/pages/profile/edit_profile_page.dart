import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nookly/core/config/app_config.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:logger/logger.dart';
import 'package:nookly/presentation/widgets/distance_radius_slider.dart';
import 'package:nookly/presentation/widgets/custom_avatar.dart';

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
  final _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _selectedImagePath;
  List<String> _selectedInterests = [];
  List<String> _selectedObjectives = [];
  List<String> _availableInterests = [];
  List<String> _availableObjectives = [];
  RangeValues _ageRange = const RangeValues(18, 80);
  double _distanceRadius = 40.0; // Default value of 40 km
  bool _usedFallbackInterests = false;
  bool _usedFallbackObjectives = false;
  late User _currentUser;

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

  @override
  void initState() {
    super.initState();
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

      // Load interests with fallback
      try {
        _availableInterests = await _authRepository.getPredefinedInterests();
      } catch (e) {
        _availableInterests = _fallbackInterests;
        _usedFallbackInterests = true;
      }

      // Load objectives with fallback
      try {
        _availableObjectives = await _authRepository.getPredefinedObjectives();
      } catch (e) {
        _availableObjectives = _fallbackObjectives;
        _usedFallbackObjectives = true;
      }
      
      // Initialize form with current user data
      _nameController.text = _currentUser.name ?? '';
      _bioController.text = _currentUser.bio ?? '';
      _selectedInterests = _currentUser.interests ?? [];
      _selectedObjectives = _currentUser.objectives ?? [];
      
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
          _isUploading = true;
          _uploadProgress = 0.0;
        });

        // Mock S3 upload with progress
        await _mockUploadImage(pickedFile.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _mockUploadImage(String imagePath) async {
    // Simulate upload progress
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _uploadProgress = i / 100;
      });
    }
    setState(() {
      _isUploading = false;
    });
  }

  bool _isFormValid() {
    // Check if any field has been modified
    final hasNameChanged = _nameController.text != _currentUser.name;
    final hasBioChanged = _bioController.text != (_currentUser.bio ?? '');
    final hasInterestsChanged = !listEquals(_selectedInterests, _currentUser.interests ?? []);
    final hasObjectivesChanged = !listEquals(_selectedObjectives, _currentUser.objectives ?? []);
    final hasAgeRangeChanged = _ageRange.start != (_currentUser.preferredAgeRange?['lower_limit']?.toDouble() ?? 18) ||
                              _ageRange.end != (_currentUser.preferredAgeRange?['upper_limit']?.toDouble() ?? 80);
    final hasDistanceRadiusChanged = _distanceRadius.round() != (_currentUser.preferredDistanceRadius ?? 40);
    final hasImageChanged = _selectedImagePath != null;

    // At least one field should be modified
    return hasNameChanged || 
           hasBioChanged || 
           hasInterestsChanged || 
           hasObjectivesChanged || 
           hasAgeRangeChanged || 
           hasDistanceRadiusChanged ||
           hasImageChanged;
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Create updated user with all existing data and new values for changed fields
      final updatedUser = User(
        id: _currentUser.id,
        email: _currentUser.email,
        // Update only if changed
        name: _nameController.text != _currentUser.name ? _nameController.text : _currentUser.name,
        bio: _bioController.text != (_currentUser.bio ?? '') ? _bioController.text : _currentUser.bio,
        interests: !listEquals(_selectedInterests, _currentUser.interests ?? []) 
            ? _selectedInterests 
            : _currentUser.interests,
        objectives: !listEquals(_selectedObjectives, _currentUser.objectives ?? []) 
            ? _selectedObjectives 
            : _currentUser.objectives,
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



  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a Photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: const Color(0xFF234481),
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontFamily: 'Nunito', color: Colors.white)),
        backgroundColor: const Color(0xFF234481),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConfig.defaultPadding),
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
                            size: 120,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF4C5C8A),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white),
                                onPressed: () => _showImagePicker(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      color: const Color(0xFF35548b),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    const SizedBox(height: 16),
                    Card(
                      color: const Color(0xFF35548b),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: TextFormField(
                          controller: _bioController,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white, fontFamily: 'Nunito'),
                          decoration: const InputDecoration(
                            labelText: 'Bio',
                            labelStyle: TextStyle(color: Color(0xFFD6D9E6), fontFamily: 'Nunito'),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Interests',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
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
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
                    const SizedBox(height: 24),
                    const Text(
                      'Objectives',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
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
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
                              } else {
                                _selectedObjectives.remove(objective);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Preferred Age Range',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3.0, // Reduced from default 4.0
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: const Color(0xFF4C5C8A),
                        thumbColor: Colors.white,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0), // Reduced from default 10.0
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0), // Reduced from default 24.0
                        rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8.0), // Reduced from default 10.0
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
                        Text('${_ageRange.start.round()} years', style: const TextStyle(fontFamily: 'Nunito', color: Color(0xFFD6D9E6))),
                        Text('${_ageRange.end.round()} years', style: const TextStyle(fontFamily: 'Nunito', color: Color(0xFFD6D9E6))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Distance Radius',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    DistanceRadiusSlider(
                      value: _distanceRadius,
                      onChanged: (value) {
                        setState(() {
                          _distanceRadius = value;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isFormValid() ? _updateProfile : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFf4656f),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: 16),
                        ),
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
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
} 