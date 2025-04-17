import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hushmate/core/config/app_config.dart';
import 'package:hushmate/presentation/bloc/profile/profile_bloc.dart';
import 'package:hushmate/presentation/bloc/profile/profile_event.dart';
import 'package:hushmate/presentation/bloc/profile/profile_state.dart';
import 'package:hushmate/presentation/widgets/interest_chips.dart';
import 'package:intl/intl.dart';

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
  List<String> _selectedInterests = [];
  String? _selectedObjective;

  final List<String> _sexOptions = ['Male', 'Female', 'Other'];
  final List<String> _wishToFindOptions = ['Male', 'Female', 'Any'];
  final List<String> _objectiveOptions = [
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      context.read<ProfileBloc>().add(UpdateBirthdate(picked));
    }
  }

  void _onNextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
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
    if (_formKey.currentState?.validate() ?? false) {
      context.read<ProfileBloc>().add(SaveProfile());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Profile'),
      ),
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileSaved) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: _onNextStep,
            onStepCancel: _onPreviousStep,
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
                    ),
                  ],
                ),
                isActive: _currentStep >= 2,
              ),
              Step(
                title: const Text('Objective'),
                content: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedObjective,
                      decoration: const InputDecoration(
                        labelText: 'What are you looking for?',
                      ),
                      items: _objectiveOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedObjective = newValue;
                        });
                        if (newValue != null) {
                          context
                              .read<ProfileBloc>()
                              .add(UpdateObjective(newValue));
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your objective';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                isActive: _currentStep >= 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 