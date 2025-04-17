import 'package:hushmate/domain/entities/received_like.dart';

abstract class ReceivedLikesRepository {
  Future<List<ReceivedLike>> getReceivedLikes();
  Future<void> acceptLike(String likeId);
  Future<void> rejectLike(String likeId);
} 