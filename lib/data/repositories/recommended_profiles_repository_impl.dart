import 'package:nookly/core/network/network_service.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/domain/entities/recommended_profile.dart';
import 'package:nookly/domain/entities/recommended_profiles_page.dart';
import 'package:nookly/domain/repositories/recommended_profiles_repository.dart';

class RecommendedProfilesRepositoryImpl implements RecommendedProfilesRepository {
  @override
  Future<RecommendedProfilesPage> getRecommendedProfiles({
    double? radius,
    int? limit,
    String? cursor,
    List<String>? physicalActiveness,
    List<String>? availability,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (radius != null) queryParams['radius'] = radius;
      if (limit != null) queryParams['limit'] = limit;
      if (cursor != null && cursor.isNotEmpty) queryParams['cursor'] = cursor;
      if (physicalActiveness != null && physicalActiveness.isNotEmpty) {
        queryParams['physical_activeness'] = physicalActiveness.join(',');
      }
      if (availability != null && availability.isNotEmpty) {
        queryParams['availability'] = availability.join(',');
      }

      final response = await NetworkService.dio.get(
        '/users/recommendations',
        queryParameters: queryParams,
      );

      final Map<String, dynamic> data = response.data as Map<String, dynamic>;
      final List<dynamic> profilesJson = data['profiles'] as List<dynamic>? ?? [];
      final profiles = profilesJson
          .map((json) => RecommendedProfile.fromJson(json))
          .toList();

      final Map<String, dynamic>? pagination =
          data['pagination'] as Map<String, dynamic>?;
      final hasMore = pagination?['has_more'] as bool? ?? false;
      final nextCursor = pagination?['next_cursor'] as String?;
      final currentCursor = pagination?['cursor'] as String?;
      final usedLimit = pagination?['limit'] as int?;
      final totalCandidates = pagination?['total_candidates'] as int?;

      AppLogger.info(
        'Successfully fetched ${profiles.length} recommended profiles | hasMore: $hasMore | nextCursor: $nextCursor',
      );

      return RecommendedProfilesPage(
        profiles: profiles,
        cursor: currentCursor,
        nextCursor: nextCursor,
        hasMore: hasMore,
        limit: usedLimit,
        totalCandidates: totalCandidates,
      );
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