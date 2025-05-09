import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final int? age;
  final String? sex;
  final String? seekingGender;
  final Map<String, dynamic>? location;
  final Map<String, dynamic>? preferredAgeRange;
  final String? hometown;
  final String? bio;
  final List<String>? interests;
  final List<String>? objectives;
  final String? profilePic;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.age,
    this.sex,
    this.seekingGender,
    this.location,
    this.preferredAgeRange,
    this.hometown,
    this.bio,
    this.interests,
    this.objectives,
    this.profilePic,
  });

  bool get isProfileComplete => 
    age != null && 
    sex != null && 
    seekingGender != null && 
    location != null && 
    preferredAgeRange != null && 
    hometown != null && 
    bio != null && 
    interests != null && 
    objectives != null && 
    profilePic != null;

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
      sex: json['sex'] as String?,
      seekingGender: json['seeking_gender'] as String?,
      location: json['location'] != null ? {
        'latitude': (json['location']['coordinates'][0] as num?)?.toDouble() ?? 0.0,
        'longitude': (json['location']['coordinates'][1] as num?)?.toDouble() ?? 0.0,
      } : null,
      preferredAgeRange: json['preferred_age_range'] != null ? {
        'lower_limit': json['preferred_age_range']['min'] as int? ?? 18,
        'upper_limit': json['preferred_age_range']['max'] as int? ?? 99,
      } : null,
      hometown: json['hometown'] as String?,
      bio: json['bio'] as String?,
      interests: (json['interests'] as List<dynamic>?)?.cast<String>(),
      objectives: (json['objectives'] as List<dynamic>?)?.cast<String>(),
      profilePic: json['profile_pic'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'age': age,
      'sex': sex,
      'seeking_gender': seekingGender,
      'location': location,
      'preferred_age_range': preferredAgeRange,
      'hometown': hometown,
      'bio': bio,
      'interests': interests,
      'objectives': objectives,
      'profile_pic': profilePic,
    };
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        age,
        sex,
        seekingGender,
        location,
        preferredAgeRange,
        hometown,
        bio,
        interests,
        objectives,
        profilePic,
      ];
} 