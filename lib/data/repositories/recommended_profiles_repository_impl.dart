import 'package:nookly/core/network/network_service.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/data/models/recommended_profile_model.dart';
import 'package:nookly/domain/entities/recommended_profile.dart';
import 'package:nookly/domain/repositories/recommended_profiles_repository.dart';

class RecommendedProfilesRepositoryImpl implements RecommendedProfilesRepository {
  @override
  Future<List<RecommendedProfile>> getRecommendedProfiles({
    double? radius,
    int? limit,
    int? skip,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (radius != null) queryParams['radius'] = radius;
      if (limit != null) queryParams['limit'] = limit;
      if (skip != null) queryParams['skip'] = skip;

      final response = await NetworkService.dio.get(
        '/users/recommendations',
        queryParameters: queryParams,
      );

      final List<dynamic> profilesJson = response.data;
      final profiles = profilesJson
          .map((json) => RecommendedProfile.fromJson(json))
          .toList();

      AppLogger.info('Successfully fetched ${profiles.length} recommended profiles');
      return profiles;
    } catch (e) {
      AppLogger.error('Failed to fetch recommended profiles: $e');
      throw Exception('Failed to fetch recommended profiles: $e');
    }
  }

  @override
  Future<void> likeProfile(String profileId) async {
    try {
      await NetworkService.dio.post('/users/like/$profileId');
      AppLogger.info('Successfully liked profile: $profileId');
    } catch (e) {
      AppLogger.error('Failed to like profile: $e');
      throw Exception('Failed to like profile: $e');
    }
  }

  @override
  Future<void> dislikeProfile(String profileId) async {
    try {
      await NetworkService.dio.post('/users/dislikes/$profileId');
      AppLogger.info('Successfully disliked profile: $profileId');
    } catch (e) {
      AppLogger.error('Failed to dislike profile: $e');
      throw Exception('Failed to dislike profile: $e');
    }
  }

  @override
  Future<List<RecommendedProfile>> getLikedProfiles() async {
    try {
      final response = await NetworkService.dio.get('/users/likes');
      
      final List<dynamic> profilesJson = response.data;
      final profiles = profilesJson
          .map((json) => RecommendedProfile.fromJson(json))
          .toList();

      AppLogger.info('Successfully fetched ${profiles.length} liked profiles');
      return profiles;
    } catch (e) {
      AppLogger.error('Failed to fetch liked profiles: $e');
      throw Exception('Failed to fetch liked profiles: $e');
    }
  }

  @override
  Future<List<RecommendedProfile>> getProfilesThatLikedMe() async {
    try {
      final response = await NetworkService.dio.get('/users/liked-by');
      
      final List<dynamic> profilesJson = response.data;
      final profiles = profilesJson
          .map((json) => RecommendedProfile.fromJson(json))
          .toList();

      AppLogger.info('Successfully fetched ${profiles.length} profiles that liked me');
      return profiles;
    } catch (e) {
      AppLogger.error('Failed to fetch profiles that liked me: $e');
      throw Exception('Failed to fetch profiles that liked me: $e');
    }
  }
} 