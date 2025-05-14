import 'package:hushmate/core/network/network_service.dart';
import 'package:hushmate/core/utils/logger.dart';
import 'package:hushmate/domain/entities/received_like.dart';
import 'package:hushmate/domain/repositories/received_likes_repository.dart';
import 'package:hushmate/domain/repositories/recommended_profiles_repository.dart';

class ReceivedLikesRepositoryImpl implements ReceivedLikesRepository {
  final RecommendedProfilesRepository recommendedProfilesRepository;

  ReceivedLikesRepositoryImpl({required this.recommendedProfilesRepository});

  @override
  Future<List<ReceivedLike>> getReceivedLikes() async {
    try {
      // Get profiles that liked the current user
      final profiles = await recommendedProfilesRepository.getProfilesThatLikedMe();
      
      // Convert profiles to received likes
      final likes = profiles.map((profile) => ReceivedLike(
        id: profile.id,
        name: profile.name,
        age: profile.age,
        gender: profile.sex,
        distance: (profile.distance ?? 0.0).toInt(),
        bio: profile.bio,
        interests: profile.interests,
        profilePicture: profile.profilePic ?? '',
        likedAt: DateTime.now(), // TODO: Get actual timestamp from API
      )).toList();

      AppLogger.info('Successfully fetched ${likes.length} received likes');
      return likes;
    } catch (e) {
      AppLogger.error('Failed to fetch received likes: $e');
      throw Exception('Failed to fetch received likes: $e');
    }
  }

  @override
  Future<void> acceptLike(String likeId) async {
    try {
      await NetworkService.dio.post('/users/like/$likeId');
      AppLogger.info('Successfully accepted like: $likeId');
    } catch (e) {
      AppLogger.error('Failed to accept like: $e');
      throw Exception('Failed to accept like: $e');
    }
  }

  @override
  Future<void> rejectLike(String likeId) async {
    try {
      await NetworkService.dio.post('/users/dislikes/$likeId');
      AppLogger.info('Successfully rejected like: $likeId');
    } catch (e) {
      AppLogger.error('Failed to reject like: $e');
      throw Exception('Failed to reject like: $e');
    }
  }
} 