import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/presentation/bloc/profile/profile_bloc.dart';
import 'package:nookly/presentation/bloc/profile/profile_event.dart';
import 'package:nookly/presentation/bloc/profile/profile_state.dart';
import 'package:nookly/presentation/widgets/interest_chips.dart';
import 'package:nookly/presentation/widgets/objective_chips.dart';
import 'package:nookly/presentation/widgets/distance_radius_slider.dart';
import 'package:nookly/presentation/pages/home/home_page.dart';
import 'package:intl/intl.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:nookly/presentation/widgets/custom_avatar.dart';
import 'package:nookly/core/services/content_moderation_service.dart';

class ProfileCreationPage extends StatefulWidget {
  const ProfileCreationPage({super.key});

  @override
  State<ProfileCreationPage> createState() => _ProfileCreationPageState();
}

class _ProfileCreationPageState extends State<ProfileCreationPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  final _bioController = TextEditingController();
  final _hometownController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedSex;
  String? _selectedWishToFind;
  RangeValues _ageRange = const RangeValues(18, 80);
  double _distanceRadius = 40.0; // Default value of 40 km
  List<String> _selectedInterests = [];
  List<String> _selectedObjectives = [];
  List<String> _availableObjectives = [];
  bool _usedFallbackObjectives = false;

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

  @override
  void initState() {
    super.initState();
    _loadObjectives();
  }

  Future<void> _loadObjectives() async {
    try {
      final authRepository = context.read<AuthRepository>();
      _availableObjectives = await authRepository.getPredefinedObjectives();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _availableObjectives = _fallbackObjectives;
      _usedFallbackObjectives = true;
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading objectives. Using default list. Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
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
              surface: Color(0xFF35548b),
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

  void _onNextStep() {
    if (_currentStep < 3) {
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
          isValid = _bioController.text.isNotEmpty && _selectedInterests.isNotEmpty;
          break;
        case 3: // Objective
          isValid = _selectedObjectives.isNotEmpty;
          break;
      }

      if (isValid) {
        setState(() {
          _currentStep++;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_currentStep == 3 ? 'Please select at least one objective' : 'Please fill in all required fields'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      _onSaveProfile();
    }
  }

  void _onPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _onSaveProfile() {
    if (_formKey.currentState!.validate()) {
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
      
      final user = User(
        id: '', // This will be set by the backend
        email: '', // This will be set by the backend
        age: DateTime.now().difference(_selectedDate!).inDays ~/ 365,
        sex: _selectedSex == 'Man' ? 'm' : _selectedSex == 'Woman' ? 'f' : 'other',
        seekingGender: _selectedWishToFind == 'Man' ? 'm' : _selectedWishToFind == 'Woman' ? 'f' : 'any',
        location: const {
          'coordinates': [0.0, 0.0], // [longitude, latitude]
        },
        preferredAgeRange: {
          'lower_limit': _ageRange.start.round(),
          'upper_limit': _ageRange.end.round(),
        },
        hometown: _hometownController.text,
        bio: bioModerationResult.filteredText, // Use filtered bio
        interests: _selectedInterests,
        objectives: _selectedObjectives,
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
      backgroundColor: const Color(0xFF234481),
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
        backgroundColor: const Color(0xFF234481),
        elevation: 0,
      ),
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileSaved) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const HomePage(),
              ),
              (route) => false, // Remove all previous routes
            );
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
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
                    surface: Color(0xFF35548b),
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
                                  backgroundColor: const Color(0xFF35548b),
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
                              child: isLoading && _currentStep == 3
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      _currentStep == 3 ? 'Save Profile' : 'Next',
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
                            color: const Color(0xFF35548b),
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
                            color: const Color(0xFF35548b),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduce vertical padding
                              child: DropdownButtonFormField<String>(
                                value: _selectedSex,
                                style: const TextStyle(color: Colors.white, fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w500),
                                dropdownColor: const Color(0xFF35548b),
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
                            color: const Color(0xFF35548b),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduce vertical padding
                              child: DropdownButtonFormField<String>(
                                value: _selectedWishToFind,
                                style: const TextStyle(color: Colors.white, fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w500),
                                dropdownColor: const Color(0xFF35548b),
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
                                return 'Please enter your bio';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              context.read<ProfileBloc>().add(UpdateBio(value));
                            },
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
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 