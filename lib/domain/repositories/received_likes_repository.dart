import 'package:hushmate/domain/entities/received_like.dart';
import 'package:hushmate/domain/entities/recommended_profile.dart';
import 'package:hushmate/domain/repositories/recommended_profiles_repository.dart';

abstract class ReceivedLikesRepository {
  final RecommendedProfilesRepository recommendedProfilesRepository;

  ReceivedLikesRepository({required this.recommendedProfilesRepository});

  Future<List<ReceivedLike>> getReceivedLikes();
  Future<void> acceptLike(String likeId);
  Future<void> rejectLike(String likeId);
} 