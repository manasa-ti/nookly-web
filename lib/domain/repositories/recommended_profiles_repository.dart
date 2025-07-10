import 'package:nookly/domain/entities/recommended_profile.dart';

abstract class RecommendedProfilesRepository {
  Future<List<RecommendedProfile>> getRecommendedProfiles({
    double? radius,
    int? limit,
    int? skip,
  });
  Future<void> likeProfile(String profileId);
  Future<void> dislikeProfile(String profileId);
  
  /// Get list of profiles that the current user has liked
  Future<List<RecommendedProfile>> getLikedProfiles();
  
  /// Get list of profiles that have liked the current user
  Future<List<RecommendedProfile>> getProfilesThatLikedMe();
} 