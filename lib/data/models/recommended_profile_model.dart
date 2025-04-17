import 'package:hushmate/domain/entities/recommended_profile.dart';

class RecommendedProfileModel extends RecommendedProfile {
  const RecommendedProfileModel({
    required super.id,
    required super.name,
    required super.age,
    required super.gender,
    required super.distance,
    required super.bio,
    required super.interests,
    required super.profilePicture,
  });

  factory RecommendedProfileModel.fromJson(Map<String, dynamic> json) {
    return RecommendedProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      distance: json['distance'] as int,
      bio: json['bio'] as String,
      interests: List<String>.from(json['interests'] as List),
      profilePicture: json['profilePicture'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'distance': distance,
      'bio': bio,
      'interests': interests,
      'profilePicture': profilePicture,
    };
  }
} 