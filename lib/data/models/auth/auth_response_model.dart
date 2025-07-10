import 'package:nookly/data/models/auth/location_age_range_models.dart';

class AuthResponseModel {
  final String token;
  final UserModel user;

  const AuthResponseModel({
    required this.token,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
    };
  }
}

class UserModel {
  final String id;
  final String email;
  final int age;
  final String sex;
  final LocationModel location;
  final String seekingGender;
  final String? hometown;
  final AgeRangeModel preferredAgeRange;
  final String? bio;
  final List<String>? interests;
  final List<String>? objectives;
  final String? profilePic;

  const UserModel({
    required this.id,
    required this.email,
    required this.age,
    required this.sex,
    required this.location,
    required this.seekingGender,
    required this.preferredAgeRange,
    this.hometown,
    this.bio,
    this.interests,
    this.objectives,
    this.profilePic,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      age: json['age'] as int,
      sex: json['sex'] as String,
      location: LocationModel.fromJson(json['location'] as Map<String, dynamic>),
      seekingGender: json['seeking_gender'] as String,
      hometown: json['hometown'] as String?,
      preferredAgeRange: AgeRangeModel.fromJson(json['preferred_age_range'] as Map<String, dynamic>),
      bio: json['bio'] as String?,
      interests: json['interests'] != null ? List<String>.from(json['interests'] as List) : null,
      objectives: json['objectives'] != null ? List<String>.from(json['objectives'] as List) : null,
      profilePic: json['profile_pic'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'age': age,
      'sex': sex,
      'location': location.toJson(),
      'seeking_gender': seekingGender,
      'hometown': hometown,
      'preferred_age_range': preferredAgeRange.toJson(),
      'bio': bio,
      'interests': interests,
      'objectives': objectives,
      'profile_pic': profilePic,
    };
  }
} 