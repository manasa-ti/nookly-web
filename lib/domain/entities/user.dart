import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String? name;
  final int? age;
  final String? sex;
  final String? seekingGender;
  final Map<String, dynamic>? location;
  final Map<String, dynamic>? preferredAgeRange;
  final String? hometown;
  final String? bio;
  final List<String>? interests;
  final List<String>? objectives;
  final List<String>? personalityType;
  final List<String>? physicalActiveness;
  final List<String>? availability;
  final String? profilePic;
  final int? preferredDistanceRadius;
  final bool? isOnline;
  final String? lastSeen;
  final String? connectionStatus;
  final String? lastActive;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.age,
    this.sex,
    this.seekingGender,
    this.location,
    this.preferredAgeRange,
    this.hometown,
    this.bio,
    this.interests,
    this.objectives,
    this.personalityType,
    this.physicalActiveness,
    this.availability,
    this.profilePic,
    this.preferredDistanceRadius,
    this.isOnline,
    this.lastSeen,
    this.connectionStatus,
    this.lastActive,
  });

  bool get isProfileComplete {
    // Age check: complete if age is not null and not 0
    final isAgeSet = age != null && age != 0;
    
    // Name check: complete if not null and not empty
    final isNameSet = name != null && name!.isNotEmpty;

    // Bio check: complete if not null and not empty
    final isBioSet = bio != null && bio!.isNotEmpty;

    // Hometown check: complete if not null and not empty
    final isHometownSet = hometown != null && hometown!.isNotEmpty;

    // Profile Pic check: complete if not null and not empty
    final isProfilePicSet = profilePic != null && profilePic!.isNotEmpty;

    // Interests check: complete if not null and not empty list
    final isInterestsSet = interests != null && interests!.isNotEmpty;

    // Objectives check: complete if not null and not empty list
    final isObjectivesSet = objectives != null && objectives!.isNotEmpty;

    return isAgeSet &&
        isNameSet &&
        isBioSet &&
        isHometownSet &&
        isProfilePicSet &&
        isInterestsSet &&
        isObjectivesSet;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      age: json['age'] as int?,
      sex: json['sex'] as String?,
      seekingGender: json['seekingGender'] as String?,
      location: json['location'] != null ? {
        'latitude': (json['location']['coordinates'][0] as num?)?.toDouble() ?? 0.0,
        'longitude': (json['location']['coordinates'][1] as num?)?.toDouble() ?? 0.0,
      } : null,
      preferredAgeRange: json['preferredAgeRange'] != null ? {
        'lower_limit': json['preferredAgeRange']['lower_limit'] as int? ?? 18,
        'upper_limit': json['preferredAgeRange']['upper_limit'] as int? ?? 80,
      } : null,
      hometown: json['hometown'] as String?,
      bio: json['bio'] as String?,
      interests: (json['interests'] as List<dynamic>?)?.cast<String>(),
      objectives: (json['objectives'] as List<dynamic>?)?.cast<String>(),
      personalityType: (json['personality_type'] as List<dynamic>?)?.cast<String>(),
      physicalActiveness: (json['physical_activeness'] as List<dynamic>?)?.cast<String>(),
      availability: (json['availability'] as List<dynamic>?)?.cast<String>(),
      profilePic: json['profilePic'] as String?,
      preferredDistanceRadius: json['preferred_distance_radius'] as int? ?? 40,
      isOnline: json['isOnline'] as bool?,
      lastSeen: json['lastSeen'] as String?,
      connectionStatus: json['connectionStatus'] as String?,
      lastActive: json['last_active'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'name': name,
      'age': age,
      'sex': sex,
      'seeking_gender': seekingGender,
      'location': location,
      'preferred_age_range': preferredAgeRange,
      'hometown': hometown,
      'bio': bio,
      'interests': interests,
      'objectives': objectives,
      'personality_type': personalityType,
      'physical_activeness': physicalActiveness,
      'availability': availability,
      'profile_pic': profilePic,
      'preferred_distance_radius': preferredDistanceRadius,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'connectionStatus': connectionStatus,
      'last_active': lastActive,
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
        personalityType,
        physicalActiveness,
        availability,
        profilePic,
        preferredDistanceRadius,
        isOnline,
        lastSeen,
        connectionStatus,
        lastActive,
      ];
} 