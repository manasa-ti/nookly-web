import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final int age;
  final String gender;
  final String bio;
  final List<String> interests;
  final String profilePicture;
  final Map<String, double> location;
  final Map<String, dynamic> preferences;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.age,
    required this.gender,
    required this.bio,
    required this.interests,
    required this.profilePicture,
    required this.location,
    required this.preferences,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      bio: json['bio'] as String,
      interests: (json['interests'] as List<dynamic>).cast<String>(),
      profilePicture: json['profilePicture'] as String,
      location: {
        'latitude': json['location']['latitude'] as double,
        'longitude': json['location']['longitude'] as double,
      },
      preferences: json['preferences'] as Map<String, dynamic>,
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
      ];
} 