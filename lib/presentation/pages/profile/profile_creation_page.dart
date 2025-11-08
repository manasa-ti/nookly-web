import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/presentation/bloc/profile/profile_bloc.dart';
import 'package:nookly/presentation/bloc/profile/profile_event.dart';
import 'package:nookly/presentation/bloc/profile/profile_state.dart';
import 'package:nookly/presentation/widgets/interest_chips.dart';
import 'package:nookly/presentation/widgets/objective_chips.dart';
import 'package:nookly/presentation/widgets/personality_type_chips.dart';
import 'package:nookly/presentation/widgets/physical_activeness_chips.dart';
import 'package:nookly/presentation/widgets/availability_chips.dart';
import 'package:nookly/presentation/widgets/distance_radius_slider.dart';
import 'package:nookly/presentation/pages/home/home_page.dart';
import 'package:intl/intl.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:nookly/core/services/content_moderation_service.dart';
import 'package:nookly/core/services/screen_protection_service.dart';
import 'package:nookly/core/services/location_service.dart';
import 'package:nookly/core/di/injection_container.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/main.dart';
import 'package:nookly/presentation/widgets/safety_tips_banner.dart';
import 'package:geolocator/geolocator.dart';

class ProfileCreationPage extends StatefulWidget {
  const ProfileCreationPage({super.key});

  @override
  State<ProfileCreationPage> createState() => _ProfileCreationPageState();
}

class _ProfileCreationPageState extends State<ProfileCreationPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _showSafetyTips = true; // Control safety tips visibility
  late ScreenProtectionService _screenProtectionService;
  final _bioController = TextEditingController();
  final _hometownController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedSex;
  String? _selectedWishToFind;
  RangeValues _ageRange = const RangeValues(18, 80);
  double _distanceRadius = 40.0; // Default value of 40 km
  List<String> _selectedInterests = [];
  List<String> _selectedObjectives = [];
  List<String> _selectedPersonalityTypes = [];
  List<String> _selectedPhysicalActiveness = [];
  List<String> _selectedAvailability = [];
  List<String> _availableObjectives = [];
  List<String> _availablePersonalityTypes = [];
  List<String> _availablePhysicalActiveness = [];
  List<String> _availableAvailability = [];
  bool _usedFallbackObjectives = false;

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

  final List<String> _sexOptions = ['Man', 'Woman', 'Other'];
  final List<String> _wishToFindOptions = ['Man', 'Woman', 'Any'];

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
    _loadProfileOptions();
  }

  /// Enable screenshot and screen recording protection for profile pages
  Future<void> _enableScreenProtection() async {
    if (!mounted) return;
    
    try {
      await _screenProtectionService.enableProtection(
        screenType: 'profile',
        context: context,
      );
      AppLogger.info('🔒 Screen protection enabled for profile creation');
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

  Future<void> _loadProfileOptions() async {
    try {
      final authRepository = context.read<AuthRepository>();
      final profileOptions = await authRepository.getProfileOptions();
      
      if (mounted) {
        setState(() {
          _availableObjectives = profileOptions['objectives'] ?? [];
          _availablePersonalityTypes = profileOptions['personality_types'] ?? [];
          _availablePhysicalActiveness = profileOptions['physical_activeness'] ?? [];
          _availableAvailability = profileOptions['availability'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _availableObjectives = _fallbackObjectives;
          _availablePersonalityTypes = _fallbackPersonalityTypes;
          _availablePhysicalActiveness = _fallbackPhysicalActiveness;
          _availableAvailability = _fallbackAvailability;
          _usedFallbackObjectives = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile options. Using default lists. Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _disableScreenProtection();
    _bioController.dispose();
    _hometownController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime.now().subtract(const Duration(days: 36500)), // 100 years ago
      lastDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white, // Selection circle is white
              onPrimary: Color(0xFF4C5C8A), // Selected day number is accent blue
              surface: Color(0xFF384E85),
              onSurface: Colors.white,
              secondary: Color(0xFF4C5C8A),
              onSecondary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white, // OK/Cancel button text is white
                textStyle: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      // Age verification - ensure user is 18 or older
      final age = DateTime.now().difference(picked).inDays ~/ 365;
      if (age < 18) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be 18 or older to use Nookly. Please select a different date of birth.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return; // Don't set the date if underage
      }
      
      setState(() {
        _selectedDate = picked;
      });
      context.read<ProfileBloc>().add(UpdateBirthdate(picked));
    }
  }

  void _onNextStep() async {
    if (_currentStep < 6) {
      bool isValid = false;
      
      // Validate based on current step
      switch (_currentStep) {
        case 0: // Basic Info
          // Additional age verification for step 0
          if (_selectedDate != null) {
            final age = DateTime.now().difference(_selectedDate!).inDays ~/ 365;
            if (age < 18) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You must be 18 or older to use Nookly. Please select a different date of birth.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                ),
              );
              return;
            }
          }
          isValid = _selectedDate != null && _selectedSex != null && _selectedWishToFind != null;
          break;
        case 1: // Location & Age
          isValid = _hometownController.text.isNotEmpty;
          break;
        case 2: // Profile Details
          isValid = _isBioValid(_bioController.text) && _selectedInterests.isNotEmpty;
          break;
        case 3: // Objective
          isValid = _selectedObjectives.isNotEmpty;
          break;
        case 4: // Personality Type
          isValid = _selectedPersonalityTypes.isNotEmpty;
          break;
        case 5: // Physical Activeness
          isValid = _selectedPhysicalActiveness.isNotEmpty;
          break;
        case 6: // Availability
          isValid = _selectedAvailability.isNotEmpty;
          break;
      }

      if (isValid) {
        setState(() {
          _currentStep++;
        });
      } else {
        print('ProfileCreationPage: Validation failed for step $_currentStep');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getValidationErrorMessage()),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      await _onSaveProfile();
    }
  }

  void _onPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  String _getValidationErrorMessage() {
    switch (_currentStep) {
      case 0:
        return 'Please fill in all required fields';
      case 1:
        return 'Please enter your hometown';
      case 2:
        return 'Please write a bio of at least 100 characters and select an interest';
      case 3:
        return 'Please select at least one objective';
      case 4:
        return 'Please select at least one personality type';
      case 5:
        return 'Please select at least one physical activeness option';
      case 6:
        return 'Please select at least one availability option';
      default:
        return 'Please fill in all required fields';
    }
  }

  Future<void> _onSaveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Ensure bio minimum length before moderation
      if (!_isBioValid(_bioController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please write at least 100 characters about yourself'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      // Final age verification before saving profile
      if (_selectedDate != null) {
        final age = DateTime.now().difference(_selectedDate!).inDays ~/ 365;
        if (age < 18) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be 18 or older to use Nookly. Please select a different date of birth.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }
      }
      
      // Content moderation for bio
      final moderationService = ContentModerationService();
      final bioModerationResult = moderationService.moderateContent(_bioController.text, ContentType.bio);
      
      if (!bioModerationResult.isAppropriate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bio contains inappropriate content. Please revise your bio.',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Nunito',
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      
      final locationService = sl<LocationService>();
      Position? position;
      Map<String, dynamic> profileLocation = const {
        'coordinates': [0.0, 0.0],
      };

      try {
        position = await locationService.getLocationForProfileCreation();
        if (position != null) {
          profileLocation = {
            'coordinates': [position.longitude, position.latitude],
          };
          AppLogger.info(
            '📍 Profile creation captured location: ${position.latitude}, ${position.longitude}',
          );
        } else {
          AppLogger.warning('📍 Profile creation could not retrieve location; using fallback coordinates.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to access location. Using default coordinates. You can enable location permissions later.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        AppLogger.error('📍 Error fetching location during profile creation: $e');
      }

      final user = User(
        id: '', // This will be set by the backend
        email: '', // This will be set by the backend
        age: DateTime.now().difference(_selectedDate!).inDays ~/ 365,
        sex: _selectedSex == 'Man' ? 'm' : _selectedSex == 'Woman' ? 'f' : 'other',
        seekingGender: _selectedWishToFind == 'Man' ? 'm' : _selectedWishToFind == 'Woman' ? 'f' : 'any',
        location: profileLocation,
        preferredAgeRange: {
          'lower_limit': _ageRange.start.round(),
          'upper_limit': _ageRange.end.round(),
        },
        hometown: _hometownController.text,
        bio: bioModerationResult.filteredText, // Use filtered bio
        interests: _selectedInterests,
        objectives: _selectedObjectives,
        personalityType: _selectedPersonalityTypes,
        physicalActiveness: _selectedPhysicalActiveness,
        availability: _selectedAvailability,
        preferredDistanceRadius: _distanceRadius.round(),
      );
      context.read<ProfileBloc>().add(SaveProfile(user));
    }
  }

  @override
  Widget build(BuildContext context) {
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
    return Scaffold(
      backgroundColor: const Color(0xFF2d457f),
      appBar: AppBar(
        title: Text(
          'Create Profile',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: (MediaQuery.of(context).size.width * 0.055).clamp(18.0, 24.0),
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2d457f),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Safety Tips Banner
          if (_showSafetyTips)
            SafetyTipsBanner(
              onSkip: () {
                setState(() {
                  _showSafetyTips = false;
                });
              },
              onComplete: () {
                setState(() {
                  _showSafetyTips = false;
                });
              },
            ),
          Expanded(
            child: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          print('ProfileCreationPage: Received state: ${state.runtimeType}');
          
          if (state is ProfileSaved) {
            print('ProfileCreationPage: Profile saved successfully');
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const HomePage(),
              ),
              (route) => false, // Remove all previous routes
            );
          } else if (state is ProfileError) {
            print('ProfileCreationPage: Profile error: ${state.message}');
            // Use a more explicit approach to ensure the SnackBar shows
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                print('ProfileCreationPage: Showing error SnackBar');
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                } catch (e) {
                  print('ProfileCreationPage: Error showing SnackBar with context: $e');
                  // Fallback to global ScaffoldMessenger
                  MyApp.scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              } else {
                print('ProfileCreationPage: Widget not mounted, cannot show SnackBar');
                // Fallback to global ScaffoldMessenger
                MyApp.scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            });
          }
        },
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, profileState) {
            final isLoading = profileState is ProfileLoading;
            
            return Form(
              key: _formKey,
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF4C5C8A), // Accent color for completed steps
                    onPrimary: Colors.white,
                    surface: Color(0xFF384E85),
                    onSurface: Colors.white,
                    secondary: Colors.white, // Incomplete steps and lines are white
                    onSecondary: Color(0xFF4C5C8A),
                  ),
                ),
                child: Stepper(
                  currentStep: _currentStep,
                  onStepContinue: isLoading ? null : _onNextStep,
                  onStepCancel: isLoading ? null : _onPreviousStep,
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          if (_currentStep > 0)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isLoading ? null : details.onStepCancel,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF384E85),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: Text(
                                  'Previous',
                                  style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: (MediaQuery.of(context).size.width * 0.045).clamp(16.0, 20.0), fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          if (_currentStep > 0) const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoading ? null : details.onStepContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFf4656f),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: isLoading && _currentStep == 6
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      _currentStep == 6 ? 'Save Profile' : 'Next',
                                      style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: (MediaQuery.of(context).size.width * 0.045).clamp(16.0, 20.0), fontWeight: FontWeight.w700),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: Text('Basic Info', style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: (MediaQuery.of(context).size.width * 0.04).clamp(14.0, 18.0), fontWeight: FontWeight.w600)),
                      content: Column(
                        children: [
                          Card(
                            color: const Color(0xFF384E85),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              title: const Text('Birthdate', style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedDate != null
                                        ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                                        : 'Tap to select',
                                    style: const TextStyle(fontFamily: 'Nunito', color: Color(0xFFD6D9E6), fontSize: 15, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.calendar_today, color: Color(0xFFD6D9E6)),
                                ],
                              ),
                              onTap: () => _selectDate(context),
                              dense: true, // More compact
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduce vertical padding
                            ),
                          ),
                          const SizedBox(height: 4), // Reduce space after birthdate
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Must be 18+',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  color: Color(0xFFB0B3C7), // subtle, lighter color
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            color: const Color(0xFF384E85),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduce vertical padding
                              child: DropdownButtonFormField<String>(
                                value: _selectedSex,
                                style: const TextStyle(color: Colors.white, fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w500),
                                dropdownColor: const Color(0xFF384E85),
                                decoration: const InputDecoration(
                                  labelText: 'I am',
                                  labelStyle: TextStyle(color: Color(0xFFD6D9E6), fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w500),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 4), // Reduce vertical padding
                                ),
                                items: _sexOptions.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value, style: const TextStyle(color: Colors.white, fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w500)),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedSex = newValue;
                                  });
                                  if (newValue != null) {
                                    context.read<ProfileBloc>().add(UpdateSex(newValue));
                                  }
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select your sex';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 4), // Reduce space after gender
                          Card(
                            color: const Color(0xFF384E85),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduce vertical padding
                              child: DropdownButtonFormField<String>(
                                value: _selectedWishToFind,
                                style: const TextStyle(color: Colors.white, fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w500),
                                dropdownColor: const Color(0xFF384E85),
                                decoration: const InputDecoration(
                                  labelText: 'I want to find',
                                  labelStyle: TextStyle(color: Color(0xFFD6D9E6), fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w500),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 4), // Reduce vertical padding
                                ),
                                items: _wishToFindOptions.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value, style: const TextStyle(color: Colors.white, fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w500)),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedWishToFind = newValue;
                                  });
                                  if (newValue != null) {
                                    context
                                        .read<ProfileBloc>()
                                        .add(UpdateWishToFind(newValue));
                                  }
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select who you want to find';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 4), // Reduce space after seeking gender
                        ],
                      ),
                      isActive: _currentStep >= 0,
                    ),
                    Step(
                      title: Text('Location & Age', style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: (MediaQuery.of(context).size.width * 0.04).clamp(14.0, 18.0), fontWeight: FontWeight.w600)),
                      content: Column(
                        children: [
                          TextFormField(
                            controller: _hometownController,
                            style: const TextStyle(color: Colors.white, fontFamily: 'Nunito', fontSize: 16),
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              labelText: 'Hometown',
                              prefixIcon: const Icon(Icons.location_city, color: Color(0xFFD6D9E6)),
                              labelStyle: const TextStyle(color: Color(0xFFD6D9E6), fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w500),
                              border: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFFD6D9E6)),
                              ),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFFD6D9E6)),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF4C5C8A)),
                              ),
                              errorBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your hometown';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              context.read<ProfileBloc>().add(UpdateHometown(value));
                            },
                          ),
                          const SizedBox(height: 24),
                          const Text('Preferred Age Range', style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
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
                                context.read<ProfileBloc>().add(
                                      UpdateAgePreferences(
                                        minAge: values.start.round(),
                                        maxAge: values.end.round(),
                                      ),
                                    );
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${_ageRange.start.round()} years', style: const TextStyle(fontFamily: 'Nunito', color: Color(0xFFD6D9E6), fontSize: 16, fontWeight: FontWeight.w500)),
                              Text('${_ageRange.end.round()} years', style: const TextStyle(fontFamily: 'Nunito', color: Color(0xFFD6D9E6), fontSize: 16, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          DistanceRadiusSlider(
                            value: _distanceRadius,
                            onChanged: (value) {
                              setState(() {
                                _distanceRadius = value;
                              });
                            },
                          ),
                        ],
                      ),
                      isActive: _currentStep >= 1,
                    ),
                    Step(
                      title: Text('Profile Details', style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: (MediaQuery.of(context).size.width * 0.04).clamp(14.0, 18.0), fontWeight: FontWeight.w600)),
                      content: Column(
                        children: [
                          TextFormField(
                            controller: _bioController,
                            maxLines: null,
                            minLines: 3,
                            style: const TextStyle(color: Colors.white, fontFamily: 'Nunito', fontSize: 16),
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              labelText: 'Bio',
                              hintText: 'Tell us about yourself',
                              hintStyle: const TextStyle(color: Color(0xFFD6D9E6), fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w500),
                              labelStyle: const TextStyle(color: Color(0xFFD6D9E6), fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w500),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(color: _bioProgressColor(_bioController.text)),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: _bioProgressColor(_bioController.text)),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: _bioProgressColor(_bioController.text)),
                              ),
                              errorBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              ),
                            ),
                            validator: (value) {
                              return _isBioValid(value)
                                  ? null
                                  : 'Please write at least 100 characters about yourself';
                            },
                            onChanged: (value) {
                              setState(() {}); // Trigger rebuild for dynamic border colors
                              context.read<ProfileBloc>().add(UpdateBio(value));
                            },
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
                          const SizedBox(height: 24),
                          const Text('Interests', style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          InterestChips(
                            selectedInterests: _selectedInterests,
                            onInterestsChanged: (interests) {
                              setState(() {
                                _selectedInterests = interests;
                              });
                              context
                                  .read<ProfileBloc>()
                                  .add(UpdateInterests(interests));
                            },
                            authRepository: context.read<AuthRepository>(),
                          ),
                        ],
                      ),
                      isActive: _currentStep >= 2,
                    ),
                    Step(
                      title: const Text('Objective', style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('What are you looking for?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Nunito', color: Colors.white)),
                          const SizedBox(height: 8),
                          if (_availableObjectives.isEmpty)
                            const Center(child: CircularProgressIndicator(color: Colors.white))
                          else
                            ObjectiveChips(
                              availableObjectives: _availableObjectives,
                              selectedObjectives: _selectedObjectives,
                              onObjectivesChanged: (objectives) {
                                setState(() {
                                  _selectedObjectives = objectives;
                                });
                                context
                                    .read<ProfileBloc>()
                                    .add(UpdateObjective(objectives));
                              },
                            ),
                        ],
                      ),
                      isActive: _currentStep >= 3,
                    ),
                    Step(
                      title: const Text('Personality Type', style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('What describes your personality?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Nunito', color: Colors.white)),
                          const SizedBox(height: 8),
                          if (_availablePersonalityTypes.isEmpty)
                            const Center(child: CircularProgressIndicator(color: Colors.white))
                          else
                            PersonalityTypeChips(
                              availablePersonalityTypes: _availablePersonalityTypes,
                              selectedPersonalityTypes: _selectedPersonalityTypes,
                              onPersonalityTypesChanged: (personalityTypes) {
                                setState(() {
                                  _selectedPersonalityTypes = personalityTypes;
                                });
                              },
                            ),
                        ],
                      ),
                      isActive: _currentStep >= 4,
                    ),
                    Step(
                      title: const Text('Physical Activeness', style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('How would you describe your physical activity level?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Nunito', color: Colors.white)),
                          const SizedBox(height: 8),
                          if (_availablePhysicalActiveness.isEmpty)
                            const Center(child: CircularProgressIndicator(color: Colors.white))
                          else
                            PhysicalActivenessChips(
                              availablePhysicalActiveness: _availablePhysicalActiveness,
                              selectedPhysicalActiveness: _selectedPhysicalActiveness,
                              onPhysicalActivenessChanged: (physicalActiveness) {
                                setState(() {
                                  _selectedPhysicalActiveness = physicalActiveness;
                                });
                              },
                            ),
                        ],
                      ),
                      isActive: _currentStep >= 5,
                    ),
                    Step(
                      title: const Text('Availability', style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('When are you typically available?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Nunito', color: Colors.white)),
                          const SizedBox(height: 8),
                          if (_availableAvailability.isEmpty)
                            const Center(child: CircularProgressIndicator(color: Colors.white))
                          else
                            AvailabilityChips(
                              availableAvailability: _availableAvailability,
                              selectedAvailability: _selectedAvailability,
                              onAvailabilityChanged: (availability) {
                                setState(() {
                                  _selectedAvailability = availability;
                                });
                              },
                            ),
                        ],
                      ),
                      isActive: _currentStep >= 6,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
            ),
          ),
        ],
      ),
    );
  }
} 