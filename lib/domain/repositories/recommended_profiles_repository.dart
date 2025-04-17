import 'package:hushmate/domain/entities/recommended_profile.dart';

abstract class RecommendedProfilesRepository {
  Future<List<RecommendedProfile>> getRecommendedProfiles();
  Future<void> likeProfile(String profileId);
  Future<void> dislikeProfile(String profileId);
} 