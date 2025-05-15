import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hushmate/core/utils/logger.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hushmate/core/config/app_config.dart';
import 'package:hushmate/domain/entities/user.dart';
import 'package:hushmate/domain/repositories/auth_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:logger/logger.dart';

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
    final hasImageChanged = _selectedImagePath != null;

    // At least one field should be modified
    return hasNameChanged || 
           hasBioChanged || 
           hasInterestsChanged || 
           hasObjectivesChanged || 
           hasAgeRangeChanged || 
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
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.pink[100],
                            child: ClipOval(
                              child: Builder(
                                builder: (context) {
                                  if (_selectedImagePath != null) {
                                    // Display newly picked image from local file
                                    AppLogger.debug("Displaying selected image: $_selectedImagePath");
                                    return Image.file(
                                      File(_selectedImagePath!),
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        AppLogger.error("Error loading selected file image: $error", error, stackTrace);
                                        return const Icon(Icons.broken_image, size: 60);
                                      },
                                    );
                                  } else if (_currentUser.profilePic != null && _currentUser.profilePic!.isNotEmpty) {
                                    // Display existing profile picture from URL
                                    final imageUrl = _currentUser.profilePic!;
                                    AppLogger.debug("Displaying network image: $imageUrl");

                                    // Logic adapted from profile_page.dart
                                    if (imageUrl.toLowerCase().contains('dicebear') || imageUrl.toLowerCase().endsWith('.svg')) {
                                      AppLogger.debug("Attempting to load as SVG: $imageUrl");
                                      return SvgPicture.network(
                                        imageUrl,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        placeholderBuilder: (context) => const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
                                          ),
                                        ),
                                        errorBuilder: (context, error, stackTrace) {
                                          AppLogger.error("Error loading SVG network image: $imageUrl, Error: $error", error, stackTrace);
                                          return const Icon(Icons.person, size: 60); // Fallback for SVG load error
                                        },
                                      );
                                    } else {
                                      AppLogger.debug("Attempting to load as standard image: $imageUrl");
                                      return Image.network(
                                        imageUrl,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          AppLogger.error("Error loading standard network image: $imageUrl, Error: $error", error, stackTrace);
                                          return const Icon(Icons.person, size: 60); // Fallback for standard image load error
                                        },
                                      );
                                    }
                                  } else {
                                    // Fallback if no selected image and no profile picture URL
                                    AppLogger.debug("No image selected and no profilePic URL. Displaying default icon.");
                                    return const Icon(Icons.person, size: 60);
                                  }
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white),
                                onPressed: () {
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
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isUploading) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(value: _uploadProgress),
                      const SizedBox(height: 8),
                      Text(
                        'Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    // Bio
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your bio';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),

                    // Age Range
                    const Text(
                      'Age Preferences',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    RangeSlider(
                      values: _ageRange,
                      min: 18.0,
                      max: 80.0,
                      divisions: 62,
                      labels: RangeLabels(
                        _ageRange.start.round().toString(),
                        _ageRange.end.round().toString(),
                      ),
                      onChanged: (RangeValues values) {
                        if (mounted) {
                          setState(() {
                            _ageRange = values;
                          });
                        }
                      },
                    ),
                    Text(
                      '${_ageRange.start.round()} - ${_ageRange.end.round()} years',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Interests
                    const Text(
                      'Interests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableInterests.map((interest) {
                        final isSelected = _selectedInterests.contains(interest);
                        return FilterChip(
                          label: Text(interest),
                          selected: isSelected,
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

                    // Objectives
                    const Text(
                      'Objectives',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableObjectives.map((objective) {
                        final isSelected = _selectedObjectives.contains(objective);
                        return FilterChip(
                          label: Text(objective),
                          selected: isSelected,
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
                    const SizedBox(height: 32),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isFormValid() ? _updateProfile : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Update Profile'),
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