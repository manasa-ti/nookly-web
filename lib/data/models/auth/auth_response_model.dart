import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/data/models/auth/location_age_range_models.dart';

class AuthResponseModel {
  final String? token; // Optional for registration when email verification is required
  final UserModel user;
  final bool? emailVerificationRequired;
  final bool? emailSent;

  const AuthResponseModel({
    this.token,
    required this.user,
    this.emailVerificationRequired,
    this.emailSent,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: json['token'] as String?,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      emailVerificationRequired: json['emailVerificationRequired'] as bool?,
      emailSent: json['emailSent'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
      'emailVerificationRequired': emailVerificationRequired,
      'emailSent': emailSent,
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
  final Map<String, dynamic>? subscription;

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
    this.subscription,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      AppLogger.info('UserModel.fromJson - Starting parsing with JSON: $json');
      
      // Parse each field individually with logging
      final id = json['id'] as String? ?? '';
      AppLogger.info('UserModel.fromJson - Parsed id: $id');
      
      final email = json['email'] as String? ?? '';
      AppLogger.info('UserModel.fromJson - Parsed email: $email');
      
      final age = json['age'] as int? ?? 0;
      AppLogger.info('UserModel.fromJson - Parsed age: $age');
      
      final sex = json['sex'] as String? ?? '';
      AppLogger.info('UserModel.fromJson - Parsed sex: $sex');
      
      final location = json['location'] != null 
          ? LocationModel.fromJson(json['location'] as Map<String, dynamic>)
          : LocationModel(coordinates: [0.0, 0.0]);
      AppLogger.info('UserModel.fromJson - Parsed location: ${location.coordinates}');
      
      final seekingGender = json['seeking_gender'] as String? ?? '';
      AppLogger.info('UserModel.fromJson - Parsed seekingGender: $seekingGender');
      
      final hometown = json['hometown'] as String?;
      AppLogger.info('UserModel.fromJson - Parsed hometown: $hometown');
      
      final preferredAgeRange = json['preferred_age_range'] != null
          ? AgeRangeModel.fromJson(json['preferred_age_range'] as Map<String, dynamic>)
          : AgeRangeModel(lowerLimit: 18, upperLimit: 80);
      AppLogger.info('UserModel.fromJson - Parsed preferredAgeRange: ${preferredAgeRange.lowerLimit}-${preferredAgeRange.upperLimit}');
      
      final bio = json['bio'] as String?;
      AppLogger.info('UserModel.fromJson - Parsed bio: $bio');
      
      // Handle interests with detailed logging
      List<String>? interests;
      try {
        final interestsRaw = json['interests'];
        AppLogger.info('UserModel.fromJson - Raw interests: $interestsRaw (type: ${interestsRaw.runtimeType})');
        
        if (interestsRaw != null) {
          if (interestsRaw is List) {
            interests = interestsRaw.map((item) {
              AppLogger.info('UserModel.fromJson - Processing interest item: $item (type: ${item.runtimeType})');
              return item.toString();
            }).toList();
          } else {
            AppLogger.error('UserModel.fromJson - Interests is not a List, it is: ${interestsRaw.runtimeType}');
            interests = null;
          }
        } else {
          interests = null;
        }
      } catch (e) {
        AppLogger.error('UserModel.fromJson - Error parsing interests: $e');
        interests = null;
      }
      AppLogger.info('UserModel.fromJson - Parsed interests: $interests');
      
      // Handle objectives with detailed logging
      List<String>? objectives;
      try {
        final objectivesRaw = json['objectives'];
        AppLogger.info('UserModel.fromJson - Raw objectives: $objectivesRaw (type: ${objectivesRaw.runtimeType})');
        
        if (objectivesRaw != null) {
          if (objectivesRaw is List) {
            objectives = objectivesRaw.map((item) {
              AppLogger.info('UserModel.fromJson - Processing objective item: $item (type: ${item.runtimeType})');
              return item.toString();
            }).toList();
          } else {
            AppLogger.error('UserModel.fromJson - Objectives is not a List, it is: ${objectivesRaw.runtimeType}');
            objectives = null;
          }
        } else {
          objectives = null;
        }
      } catch (e) {
        AppLogger.error('UserModel.fromJson - Error parsing objectives: $e');
        objectives = null;
      }
      AppLogger.info('UserModel.fromJson - Parsed objectives: $objectives');
      
      final profilePic = json['profile_pic'] as String?;
      AppLogger.info('UserModel.fromJson - Parsed profilePic: $profilePic');
      
      // Handle subscription details
      Map<String, dynamic>? subscription;
      if (json['subscription'] != null) {
        if (json['subscription'] is Map<String, dynamic>) {
          subscription = json['subscription'] as Map<String, dynamic>;
          AppLogger.info('UserModel.fromJson - Parsed subscription: $subscription');
        } else {
          AppLogger.warning('UserModel.fromJson - Subscription is not a Map, type: ${json['subscription'].runtimeType}');
        }
      }
      
      AppLogger.info('UserModel.fromJson - All fields parsed successfully, creating UserModel');
      
      return UserModel(
        id: id,
        email: email,
        age: age,
        sex: sex,
        location: location,
        seekingGender: seekingGender,
        hometown: hometown,
        preferredAgeRange: preferredAgeRange,
        bio: bio,
        interests: interests,
        objectives: objectives,
        profilePic: profilePic,
        subscription: subscription,
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('UserModel.fromJson - Error parsing UserModel: $e', e, stackTrace);
      rethrow;
    }
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
      'subscription': subscription,
    };
  }
} 