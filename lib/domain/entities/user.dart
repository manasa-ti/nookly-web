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

  // Helper method to parse int from dynamic value (handles Decimal128 from backend)
  static int? _parseIntFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    if (value is Map<String, dynamic>) {
      // Handle Decimal128 serialized as Map
      if (value.containsKey('\$numberDecimal')) {
        final decimalStr = value['\$numberDecimal'] as String?;
        return int.tryParse(decimalStr ?? '');
      }
    }
    return null;
  }

  // Helper method to parse double from dynamic value (handles Decimal128 from backend)
  static double? _parseDoubleFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    if (value is Map<String, dynamic>) {
      // Handle Decimal128 serialized as Map
      if (value.containsKey('\$numberDecimal')) {
        final decimalStr = value['\$numberDecimal'] as String?;
        return double.tryParse(decimalStr ?? '');
      }
    }
    return null;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      age: _parseIntFromDynamic(json['age']),
      sex: json['sex'] as String?,
      seekingGender: json['seekingGender'] as String?,
      location: json['location'] != null ? {
        'latitude': _parseDoubleFromDynamic(json['location']['coordinates'][0]) ?? 0.0,
        'longitude': _parseDoubleFromDynamic(json['location']['coordinates'][1]) ?? 0.0,
      } : null,
      preferredAgeRange: json['preferredAgeRange'] != null ? {
        'lower_limit': _parseIntFromDynamic(json['preferredAgeRange']['lower_limit']) ?? 18,
        'upper_limit': _parseIntFromDynamic(json['preferredAgeRange']['upper_limit']) ?? 80,
      } : null,
      hometown: json['hometown'] as String?,
      bio: json['bio'] as String?,
      interests: (json['interests'] as List<dynamic>?)?.cast<String>(),
      objectives: (json['objectives'] as List<dynamic>?)?.cast<String>(),
      personalityType: (json['personality_type'] as List<dynamic>?)?.cast<String>(),
      physicalActiveness: (json['physical_activeness'] as List<dynamic>?)?.cast<String>(),
      availability: (json['availability'] as List<dynamic>?)?.cast<String>(),
      profilePic: json['profilePic'] as String?,
      preferredDistanceRadius: _parseIntFromDynamic(json['preferred_distance_radius']) ?? 40,
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