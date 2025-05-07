
class RegisterRequestModel {
  final String email;
  final String password;
  final int age;
  final String sex;
  final String seekingGender;
  final LocationModel location;
  final AgeRangeModel preferredAgeRange;
  final String? hometown;
  final String? bio;
  final List<String>? interests;
  final List<String>? objectives;
  final String? profilePic;

  RegisterRequestModel({
    required this.email,
    required this.password,
    required this.age,
    required this.sex,
    required this.seekingGender,
    required this.location,
    required this.preferredAgeRange,
    this.hometown,
    this.bio,
    this.interests,
    this.objectives,
    this.profilePic,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'age': age,
      'sex': sex,
      'seeking_gender': seekingGender,
      'location': location.toJson(),
      'preferred_age_range': preferredAgeRange.toJson(),
      'hometown': hometown,
      'bio': bio,
      'interests': interests,
      'objectives': objectives,
      'profile_pic': profilePic,
    };
  }
}

class LocationModel {
  final List<double> coordinates;

  LocationModel({required this.coordinates});

  Map<String, dynamic> toJson() {
    return {
      'coordinates': coordinates,
    };
  }
}

class AgeRangeModel {
  final int lowerLimit;
  final int upperLimit;

  AgeRangeModel({
    required this.lowerLimit,
    required this.upperLimit,
  });

  Map<String, dynamic> toJson() {
    return {
      'lower_limit': lowerLimit,
      'upper_limit': upperLimit,
    };
  }
} 