import 'package:nookly/domain/entities/received_like.dart';
import 'package:nookly/domain/entities/recommended_profile.dart';
import 'package:nookly/domain/repositories/recommended_profiles_repository.dart';

abstract class ReceivedLikesRepository {
  final RecommendedProfilesRepository recommendedProfilesRepository;

  ReceivedLikesRepository({required this.recommendedProfilesRepository});

  Future<List<ReceivedLike>> getReceivedLikes();
  Future<void> acceptLike(String likeId);
  Future<void> rejectLike(String likeId);
} 