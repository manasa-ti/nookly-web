import 'package:equatable/equatable.dart';

class MatchedProfile extends Equatable {
  final String id; // from _id
  final String name; // API provides this
  final String profilePicUrl;
  final int age;
  final String sex;
  final String? bio;
  final List<String> interests;
  final List<String> objectives;
  // final Location? location; // Consider if needed, requires Location entity
  // final String? hometown;
  // final double? distance;
  // final List<String>? commonInterests;
  // final List<String>? commonObjectives;

  const MatchedProfile({
    required this.id,
    required this.name,
    required this.profilePicUrl,
    required this.age,
    required this.sex,
    this.bio,
    this.interests = const [],
    this.objectives = const [],
  });

  @override
  List<Object?> get props => [
        id,
        name,
        profilePicUrl,
        age,
        sex,
        bio,
        interests,
        objectives,
      ];

  // Factory constructor for creating a new MatchedProfile instance from a map (JSON).
  factory MatchedProfile.fromJson(Map<String, dynamic> json) {
    return MatchedProfile(
      id: json['_id'] as String,
      name: json['name'] as String, // Directly from API
      profilePicUrl: json['profile_pic'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      sex: json['sex'] as String? ?? '',
      bio: json['bio'] as String?,
      interests: List<String>.from(json['interests'] as List? ?? []),
      objectives: List<String>.from(json['objectives'] as List? ?? []),
    );
  }

  // Method for converting a MatchedProfile instance to a map (JSON).
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'profile_pic': profilePicUrl,
      'age': age,
      'sex': sex,
      'bio': bio,
      'interests': interests,
      'objectives': objectives,
    };
  }
} 