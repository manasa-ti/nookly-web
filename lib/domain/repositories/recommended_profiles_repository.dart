import 'package:nookly/domain/entities/recommended_profile.dart';
import 'package:nookly/domain/entities/recommended_profiles_page.dart';

abstract class RecommendedProfilesRepository {
  Future<RecommendedProfilesPage> getRecommendedProfiles({
    double? radius,
    int? limit,
    String? cursor,
    List<String>? physicalActiveness,
    List<String>? availability,
  });
  Future<void> likeProfile(String profileId);
  Future<void> dislikeProfile(String profileId);
  
  /// Get list of profiles that the current user has liked
  Future<List<RecommendedProfile>> getLikedProfiles();
  
  /// Get list of profiles that have liked the current user
  Future<List<RecommendedProfile>> getProfilesThatLikedMe();
} 