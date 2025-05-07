import 'package:hushmate/data/models/recommended_profile_model.dart';
import 'package:hushmate/domain/entities/recommended_profile.dart';
import 'package:hushmate/domain/repositories/recommended_profiles_repository.dart';

class RecommendedProfilesRepositoryImpl implements RecommendedProfilesRepository {
  @override
  Future<List<RecommendedProfile>> getRecommendedProfiles() async {
    // Mock data for now
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    return [
      const RecommendedProfileModel(
        id: '1',
        name: 'Sarah',
        age: 25,
        gender: 'Female',
        distance: 3,
        bio: 'Love traveling and trying new cuisines. Looking for someone who shares my passion for adventure.',
        interests: ['Travel', 'Food', 'Photography', 'Yoga'],
        profilePicture: 'https://example.com/profile1.jpg',
      ),
      const RecommendedProfileModel(
        id: '2',
        name: 'Michael',
        age: 28,
        gender: 'Male',
        distance: 5,
        bio: 'Tech enthusiast and coffee lover. Always up for a good conversation about the latest gadgets.',
        interests: ['Technology', 'Coffee', 'Gaming', 'Music'],
        profilePicture: 'https://example.com/profile2.jpg',
      ),
      // Add more mock profiles as needed
    ];
  }

  @override
  Future<void> likeProfile(String profileId) async {
    // Mock implementation for now
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Implement actual API call
  }

  @override
  Future<void> dislikeProfile(String profileId) async {
    // Mock implementation for now
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Implement actual API call
  }
} 