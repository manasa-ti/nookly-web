import 'package:hushmate/domain/entities/received_like.dart';

class ReceivedLikeModel extends ReceivedLike {
  const ReceivedLikeModel({
    required super.id,
    required super.name,
    required super.age,
    required super.gender,
    required super.distance,
    required super.bio,
    required super.interests,
    required super.profilePicture,
    required super.likedAt,
  });

  factory ReceivedLikeModel.fromJson(Map<String, dynamic> json) {
    return ReceivedLikeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      distance: json['distance'] as int,
      bio: json['bio'] as String,
      interests: List<String>.from(json['interests'] as List),
      profilePicture: json['profilePicture'] as String,
      likedAt: DateTime.parse(json['likedAt'] as String),
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
      'likedAt': likedAt.toIso8601String(),
    };
  }
} 