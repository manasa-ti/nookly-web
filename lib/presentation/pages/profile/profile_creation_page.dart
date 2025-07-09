import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hushmate/presentation/bloc/profile/profile_bloc.dart';
import 'package:hushmate/presentation/bloc/profile/profile_event.dart';
import 'package:hushmate/presentation/bloc/profile/profile_state.dart';
import 'package:hushmate/presentation/widgets/interest_chips.dart';
import 'package:hushmate/presentation/widgets/objective_chips.dart';
import 'package:hushmate/presentation/widgets/distance_radius_slider.dart';
import 'package:hushmate/presentation/pages/home/home_page.dart';
import 'package:intl/intl.dart';
import 'package:hushmate/domain/entities/user.dart';
import 'package:hushmate/domain/repositories/auth_repository.dart';

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

  final List<String> _sexOptions = ['Male', 'Female', 'Other'];
  final List<String> _wishToFindOptions = ['Male', 'Female', 'Any'];

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
    );
    if (picked != null && picked != _selectedDate && mounted) {
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
      final user = User(
        id: '', // This will be set by the backend
        email: '', // This will be set by the backend
        age: DateTime.now().difference(_selectedDate!).inDays ~/ 365,
        sex: _selectedSex == 'Male' ? 'm' : _selectedSex == 'Female' ? 'f' : 'other',
        seekingGender: _selectedWishToFind == 'Male' ? 'm' : _selectedWishToFind == 'Female' ? 'f' : 'any',
        location: const {
          'coordinates': [0.0, 0.0], // [longitude, latitude]
        },
        preferredAgeRange: {
          'lower_limit': _ageRange.start.round(),
          'upper_limit': _ageRange.end.round(),
        },
        hometown: _hometownController.text,
        bio: _bioController.text,
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
      appBar: AppBar(
        title: const Text('Create Profile'),
      ),
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Saving your profile...'),
                duration: Duration(seconds: 1),
              ),
            );
          } else if (state is ProfileSaved) {
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
              child: Stepper(
                currentStep: _currentStep,
                onStepContinue: isLoading ? null : _onNextStep,
                onStepCancel: isLoading ? null : _onPreviousStep,
                steps: [
                  Step(
                    title: const Text('Basic Info'),
                    content: Column(
                      children: [
                        ListTile(
                          title: const Text('Birthdate'),
                          subtitle: Text(
                            _selectedDate != null
                                ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                                : 'Select your birthdate',
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () => _selectDate(context),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedSex,
                          decoration: const InputDecoration(
                            labelText: 'Sex',
                          ),
                          items: _sexOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
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
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedWishToFind,
                          decoration: const InputDecoration(
                            labelText: 'Wish to Find',
                          ),
                          items: _wishToFindOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
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
                      ],
                    ),
                    isActive: _currentStep >= 0,
                  ),
                  Step(
                    title: const Text('Location & Age'),
                    content: Column(
                      children: [
                        TextFormField(
                          controller: _hometownController,
                          decoration: const InputDecoration(
                            labelText: 'Hometown',
                            prefixIcon: Icon(Icons.location_city),
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
                        const Text('Preferred Age Range'),
                        RangeSlider(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_ageRange.start.round()} years'),
                            Text('${_ageRange.end.round()} years'),
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
                    title: const Text('Profile Details'),
                    content: Column(
                      children: [
                        TextFormField(
                          controller: _bioController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Bio',
                            hintText: 'Tell us about yourself',
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
                        const Text('Interests'),
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
                    title: const Text('Objective'),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('What are you looking for?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (_availableObjectives.isEmpty)
                          const Center(child: CircularProgressIndicator())
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
            );
          },
        ),
      ),
    );
  }
} 