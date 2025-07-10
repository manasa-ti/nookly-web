import 'package:nookly/domain/entities/recommended_profile.dart';

class RecommendedProfileModel extends RecommendedProfile {
  RecommendedProfileModel({
    required super.id,
    required super.name,
    required super.age,
    required super.sex,
    required super.location,
    required super.hometown,
    required super.bio,
    required super.interests,
    required super.objectives,
    super.profilePic,
    required super.distance,
    required super.commonInterests,
    required super.commonObjectives,
  });

  factory RecommendedProfileModel.fromJson(Map<String, dynamic> json) {
    return RecommendedProfileModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      sex: json['sex'] as String,
      location: json['location'] as Map<String, dynamic>,
      hometown: json['hometown'] as String,
      bio: json['bio'] as String,
      interests: List<String>.from(json['interests'] as List),
      objectives: List<String>.from(json['objectives'] as List),
      profilePic: json['profile_pic'] as String?,
      distance: (json['distance'] as num).toDouble(),
      commonInterests: List<String>.from(json['common_interests'] as List),
      commonObjectives: List<String>.from(json['common_objectives'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'age': age,
      'sex': sex,
      'location': location,
      'hometown': hometown,
      'bio': bio,
      'interests': interests,
      'objectives': objectives,
      'profile_pic': profilePic,
      'distance': distance,
      'common_interests': commonInterests,
      'common_objectives': commonObjectives,
    };
  }
} 