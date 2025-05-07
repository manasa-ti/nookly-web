import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final int? age;
  final String? gender;
  final String bio;
  final List<String> interests;
  final String? profilePicture;
  final Map<String, double>? location;
  final Map<String, dynamic>? preferences;
  final DateTime? birthdate;
  final String? sex;
  final String? wishToFind;
  final String? hometown;
  final int? minAgePreference;
  final int? maxAgePreference;
  final String? profilePictureUrl;
  final String? objective;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.age,
    this.gender,
    required this.bio,
    required this.interests,
    this.profilePicture,
    this.location,
    this.preferences,
    this.birthdate,
    this.sex,
    this.wishToFind,
    this.hometown,
    this.minAgePreference,
    this.maxAgePreference,
    this.profilePictureUrl,
    this.objective,
  });

  bool get isProfileComplete => 
    birthdate != null && 
    sex != null && 
    wishToFind != null && 
    hometown != null && 
    minAgePreference != null && 
    maxAgePreference != null && 
    profilePictureUrl != null && 
    objective != null &&
    interests.isNotEmpty;

  factory User.fromJson(Map<String, dynamic> json) {
    // Temporary handling until API includes name field
    String name;
    if (json['name'] != null) {
      name = json['name'] as String;
    } else {
      // TODO: Remove this temporary solution once API includes name field
      name = 'User ${json['_id'].toString().substring(0, 6)}';
    }
    
    return User(
      id: json['_id'] as String,
      email: json['email'] as String,
      name: name,
      age: json['age'] as int?,
      gender: json['sex'] as String?,
      bio: json['bio'] as String? ?? '',
      interests: (json['interests'] as List<dynamic>?)?.cast<String>() ?? [],
      profilePicture: json['profile_pic'] as String?,
      location: json['location'] != null ? {
        'latitude': (json['location']['coordinates'][0] as num?)?.toDouble() ?? 0.0,
        'longitude': (json['location']['coordinates'][1] as num?)?.toDouble() ?? 0.0,
      } : null,
      preferences: json['preferred_age_range'] != null ? {
        'ageRange': {
          'min': json['preferred_age_range']['lower_limit'] as int? ?? 18,
          'max': json['preferred_age_range']['upper_limit'] as int? ?? 99,
        },
        'seekingGender': json['seeking_gender'] as String? ?? 'any',
      } : null,
      birthdate: null, // Not provided in API
      sex: json['sex'] as String?,
      wishToFind: json['seeking_gender'] as String?,
      hometown: json['hometown'] as String?,
      minAgePreference: json['preferred_age_range']?['lower_limit'] as int?,
      maxAgePreference: json['preferred_age_range']?['upper_limit'] as int?,
      profilePictureUrl: json['profile_pic'] as String?,
      objective: (json['objectives'] as List<dynamic>?)?.firstOrNull as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'age': age,
      'gender': gender,
      'bio': bio,
      'interests': interests,
      'profilePicture': profilePicture,
      'location': location,
      'preferences': preferences,
      'birthdate': birthdate?.toIso8601String(),
      'sex': sex,
      'wishToFind': wishToFind,
      'hometown': hometown,
      'minAgePreference': minAgePreference,
      'maxAgePreference': maxAgePreference,
      'profilePictureUrl': profilePictureUrl,
      'objective': objective,
    };
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        age,
        gender,
        bio,
        interests,
        profilePicture,
        location,
        preferences,
        birthdate,
        sex,
        wishToFind,
        hometown,
        minAgePreference,
        maxAgePreference,
        profilePictureUrl,
        objective,
      ];
} 