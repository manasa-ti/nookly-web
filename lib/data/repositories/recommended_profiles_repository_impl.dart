import 'dart:convert';

import 'package:nookly/core/network/network_service.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/domain/entities/recommended_profile.dart';
import 'package:nookly/domain/entities/recommended_profiles_page.dart';
import 'package:nookly/domain/repositories/recommended_profiles_repository.dart';

class RecommendedProfilesRepositoryImpl implements RecommendedProfilesRepository {
  // Temporarily enable mock recommendations for testing
  static const bool _enableMockRecommendations = true; // Changed to true for temporary mock data
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
      name: 'Candlelight Vibes',
      sex: 'f',
      hometown: 'Bengaluru',
      bio: 'Exploring life. Looking to find like minded souls and see where this goes. Deep, Trust worthy, friendly one. No agenda, just exploring.',
      interests: ['engaging chats', 'drink and dine', 'deep conversations'],
      objectives: ['Companionship', 'Friendship'],
      profilePic: null,
    ),
    _MockProfileTemplate(
      name: 'Sunny Side Sam',
      sex: 'm',
      hometown: 'Mumbai',
      bio: 'I am a sports enthusiast. Ambivert in nature. I like talking about psychology and human behaviour. looking for like minded people.',
      interests: ['deep conversations', 'experiences together', 'engaging chats'],
      objectives: ['Friendship', 'Companionship'],
      profilePic: null,
    ),
    _MockProfileTemplate(
      name: 'Warmhearted Traveler',
      sex: 'f',
      hometown: 'Pune',
      bio: 'would love to have cherishable moments, experiences together, create memories. I like adventures and at some time like to relax in leisure',
      interests: ['experiences together', 'travel buddy', 'adventures'],
      objectives: ['Travel buddy', 'Companionship'],
      profilePic: null,
    ),
    _MockProfileTemplate(
      name: 'Midnight Philosopher',
      sex: 'm',
      hometown: 'Hyderabad',
      bio: 'Night owl who loves deep conversations over coffee. Passionate about books, music, and meaningful connections. Looking for someone to share thoughts and experiences with.',
      interests: ['deep conversations', 'coffee dates', 'book clubs'],
      objectives: ['Companionship', 'Friendship'],
      profilePic: null,
    ),
    _MockProfileTemplate(
      name: 'Ocean Breeze',
      sex: 'f',
      hometown: 'Chennai',
      bio: 'Beach lover and yoga enthusiast. I enjoy morning walks, meditation, and connecting with nature. Seeking someone who values peace and mindfulness.',
      interests: ['nature walks', 'yoga sessions', 'beach outings'],
      objectives: ['Companionship', 'Wellness partner'],
      profilePic: null,
    ),
    _MockProfileTemplate(
      name: 'Urban Explorer',
      sex: 'm',
      hometown: 'New Delhi',
      bio: 'City wanderer who loves discovering hidden gems. Foodie at heart, always up for trying new cuisines and exploring local markets. Let\'s create memories together.',
      interests: ['drink and dine', 'city exploration', 'food adventures'],
      objectives: ['Companionship', 'Travel buddy'],
      profilePic: null,
    ),
    _MockProfileTemplate(
      name: 'Starry Night Dreamer',
      sex: 'f',
      hometown: 'Kolkata',
      bio: 'Creative soul who finds inspiration in art, music, and stargazing. Love deep conversations about life, dreams, and everything in between. Looking for genuine connections.',
      interests: ['deep conversations', 'art shows', 'stargazing'],
      objectives: ['Creative projects', 'Companionship'],
      profilePic: null,
    ),
    _MockProfileTemplate(
      name: 'Mountain Soul',
      sex: 'm',
      hometown: 'Dehradun',
      bio: 'Adventure seeker and nature enthusiast. Love hiking, camping, and outdoor activities. Looking for someone to share adventures and create lasting memories with.',
      interests: ['adventures', 'hiking', 'outdoor activities'],
      objectives: ['Adventure partner', 'Companionship'],
      profilePic: null,
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