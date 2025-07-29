class RecommendedProfile {
  final String id;
  final String name;
  final int age;
  final String sex;
  final Map<String, dynamic> location;
  final String hometown;
  final String bio;
  final List<String> interests;
  final List<String> objectives;
  final String? profilePic;
  final double distance;
  final List<String> commonInterests;
  final List<String> commonObjectives;
  final DateTime? likedAt; // Add timestamp for when this profile liked the current user

  RecommendedProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.sex,
    required this.location,
    required this.hometown,
    required this.bio,
    required this.interests,
    required this.objectives,
    this.profilePic,
    required this.distance,
    required this.commonInterests,
    required this.commonObjectives,
    this.likedAt, // Add to constructor
  });

  factory RecommendedProfile.fromJson(Map<String, dynamic> json) {
    return RecommendedProfile(
      id: json['_id'],
      name: json['name'],
      age: json['age'],
      sex: json['sex'],
      location: json['location'],
      hometown: json['hometown'],
      bio: json['bio'],
      interests: List<String>.from(json['interests']),
      objectives: List<String>.from(json['objectives']),
      profilePic: json['profile_pic'],
      distance: json['distance'].toDouble(),
      commonInterests: List<String>.from(json['common_interests']),
      commonObjectives: List<String>.from(json['common_objectives']),
      likedAt: json['liked_at'] != null ? DateTime.parse(json['liked_at']) : null, // Parse liked_at timestamp
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
      'liked_at': likedAt?.toIso8601String(), // Include liked_at in JSON
    };
  }
} 