import 'dart:convert';

import 'package:nookly/core/network/network_service.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/domain/entities/recommended_profile.dart';
import 'package:nookly/domain/entities/recommended_profiles_page.dart';
import 'package:nookly/domain/repositories/recommended_profiles_repository.dart';

class RecommendedProfilesRepositoryImpl implements RecommendedProfilesRepository {
  static const bool _enableMockRecommendations =
      bool.fromEnvironment('USE_MOCK_RECOMMENDATIONS', defaultValue: false);
  static const int _mockTotalCandidates = 500;
  static const int _mockDefaultLimit = 20;

  @override
  Future<RecommendedProfilesPage> getRecommendedProfiles({
    double? radius,
    int? limit,
    String? cursor,
    List<String>? physicalActiveness,
    List<String>? availability,
  }) async {
    try {
      if (_enableMockRecommendations) {
        AppLogger.info(
          '🔶 MOCK PAGINATION: Returning mock recommendations (cursor: $cursor, limit: ${limit ?? _mockDefaultLimit})',
        );
        return _getMockRecommendedProfiles(
          cursor: cursor,
          limit: limit ?? _mockDefaultLimit,
        );
      }

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

  RecommendedProfilesPage _getMockRecommendedProfiles({
    required int limit,
    String? cursor,
  }) {
    final int startIndex = _decodeCursor(cursor);
    final int remaining =
        (_mockTotalCandidates - startIndex).clamp(0, _mockTotalCandidates);
    final int pageSize = remaining < limit ? remaining : limit;

    final hasMore = (startIndex + pageSize) < _mockTotalCandidates;
    final String? nextCursor =
        hasMore ? _encodeCursor(startIndex + pageSize) : null;

    final profiles = List<RecommendedProfile>.generate(pageSize, (index) {
      final globalIndex = startIndex + index;
      return _buildMockProfile(globalIndex);
    });

    return RecommendedProfilesPage(
      profiles: profiles,
      cursor: _encodeCursor(startIndex),
      nextCursor: nextCursor,
      hasMore: hasMore,
      limit: limit,
      totalCandidates: _mockTotalCandidates,
    );
  }

  int _decodeCursor(String? cursor) {
    if (cursor == null || cursor.isEmpty) {
      return 0;
    }
    try {
      final decoded = utf8.decode(base64Url.decode(cursor));
      return int.parse(decoded);
    } catch (e) {
      AppLogger.warning(
          '🔶 MOCK PAGINATION: Failed to decode cursor "$cursor": $e');
      return 0;
    }
  }

  String _encodeCursor(int offset) {
    return base64Url.encode(utf8.encode(offset.toString()));
  }

  RecommendedProfile _buildMockProfile(int index) {
    final template = _mockTemplates[index % _mockTemplates.length];
    final interests = List<String>.from(template.interests);
    final objectives = List<String>.from(template.objectives);
    final commonInterests = interests.take(2).toList();
    final commonObjectives = objectives.take(1).toList();

    final distance = 1.5 + (index % 18) * 1.2;
    final latitude = 12.90 + (index % 10) * 0.01;
    final longitude = 77.50 + (index % 10) * 0.015;

    return RecommendedProfile(
      id: 'mock-$index',
      name: template.name,
      age: 22 + (index % 15),
      sex: template.sex,
      location: {
        'coordinates': [latitude, longitude],
      },
      hometown: template.hometown,
      bio: template.bio,
      interests: interests,
      objectives: objectives,
      profilePic: template.profilePic,
      distance: double.parse(distance.toStringAsFixed(1)),
      commonInterests: commonInterests,
      commonObjectives: commonObjectives,
    );
  }

  static const List<_MockProfileTemplate> _mockTemplates = [
    _MockProfileTemplate(
      name: 'Avery',
      sex: 'f',
      hometown: 'Bengaluru',
      bio: 'Coffee, hikes, and meaningful conversations.',
      interests: ['coffee dates', 'nature walks', 'live music'],
      objectives: ['Long term', 'Companionship'],
      profilePic: 'https://cdn.nookly.app/mock/avery.jpg',
    ),
    _MockProfileTemplate(
      name: 'Maya',
      sex: 'f',
      hometown: 'Chennai',
      bio: 'Early morning runs and seaside sunsets.',
      interests: ['running buddies', 'cooking', 'podcasts'],
      objectives: ['Friendship', 'Study partner'],
      profilePic: 'https://cdn.nookly.app/mock/maya.jpg',
    ),
    _MockProfileTemplate(
      name: 'Noah',
      sex: 'm',
      hometown: 'Hyderabad',
      bio: 'Product designer who loves indie films.',
      interests: ['design meetups', 'board games', 'film clubs'],
      objectives: ['Creative projects', 'Companionship'],
      profilePic: 'https://cdn.nookly.app/mock/noah.jpg',
    ),
    _MockProfileTemplate(
      name: 'Liam',
      sex: 'm',
      hometown: 'Pune',
      bio: 'Weekend cyclist & amateur chef.',
      interests: ['long rides', 'farmers markets', 'tech events'],
      objectives: ['Workout partner', 'Travel buddy'],
      profilePic: 'https://cdn.nookly.app/mock/liam.jpg',
    ),
    _MockProfileTemplate(
      name: 'Zara',
      sex: 'f',
      hometown: 'New Delhi',
      bio: 'Bookstores, theatre, and street photography.',
      interests: ['open mic nights', 'art shows', 'coffee tasting'],
      objectives: ['Creative projects', 'Friendship'],
      profilePic: 'https://cdn.nookly.app/mock/zara.jpg',
    ),
  ];

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

class _MockProfileTemplate {
  final String name;
  final String sex;
  final String hometown;
  final String bio;
  final List<String> interests;
  final List<String> objectives;
  final String? profilePic;

  const _MockProfileTemplate({
    required this.name,
    required this.sex,
    required this.hometown,
    required this.bio,
    required this.interests,
    required this.objectives,
    this.profilePic,
  });
}