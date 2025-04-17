import 'package:hushmate/data/models/received_like_model.dart';
import 'package:hushmate/domain/entities/received_like.dart';
import 'package:hushmate/domain/repositories/received_likes_repository.dart';

class ReceivedLikesRepositoryImpl implements ReceivedLikesRepository {
  @override
  Future<List<ReceivedLike>> getReceivedLikes() async {
    // Mock data for now
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    return [
      ReceivedLikeModel(
        id: '1',
        name: 'Sarah',
        age: 25,
        gender: 'Female',
        distance: 3,
        bio: 'Love traveling and trying new cuisines. Looking for someone who shares my passion for adventure.',
        interests: ['Travel', 'Food', 'Photography', 'Yoga'],
        profilePicture: 'https://example.com/profile1.jpg',
        likedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ReceivedLikeModel(
        id: '2',
        name: 'Michael',
        age: 28,
        gender: 'Male',
        distance: 5,
        bio: 'Tech enthusiast and coffee lover. Always up for a good conversation about the latest gadgets.',
        interests: ['Technology', 'Coffee', 'Gaming', 'Music'],
        profilePicture: 'https://example.com/profile2.jpg',
        likedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      // Add more mock likes as needed
    ];
  }

  @override
  Future<void> acceptLike(String likeId) async {
    // Mock implementation for now
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Implement actual API call
  }

  @override
  Future<void> rejectLike(String likeId) async {
    // Mock implementation for now
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Implement actual API call
  }
} 