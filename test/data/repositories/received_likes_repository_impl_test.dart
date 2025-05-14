import 'package:flutter_test/flutter_test.dart';
import 'package:hushmate/data/repositories/received_likes_repository_impl.dart';
import 'package:hushmate/domain/entities/received_like.dart';
import 'package:hushmate/domain/repositories/recommended_profiles_repository.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([RecommendedProfilesRepository])
import 'received_likes_repository_impl_test.mocks.dart';

void main() {
  late ReceivedLikesRepositoryImpl repository;
  late MockRecommendedProfilesRepository mockRecommendedProfilesRepository;

  setUp(() {
    mockRecommendedProfilesRepository = MockRecommendedProfilesRepository();
    repository = ReceivedLikesRepositoryImpl(
      recommendedProfilesRepository: mockRecommendedProfilesRepository,
    );
  });

  group('ReceivedLikesRepositoryImpl', () {
    test('getReceivedLikes should return list of likes', () async {
      final result = await repository.getReceivedLikes();

      expect(result, isA<List<ReceivedLike>>());
      expect(result.isNotEmpty, true);
      expect(result.first, isA<ReceivedLike>());
    });

    test('acceptLike should complete without error', () async {
      final likes = await repository.getReceivedLikes();
      final likeId = likes.first.id;

      expect(() => repository.acceptLike(likeId), returnsNormally);
    });

    test('rejectLike should complete without error', () async {
      final likes = await repository.getReceivedLikes();
      final likeId = likes.first.id;

      expect(() => repository.rejectLike(likeId), returnsNormally);
    });

    test('getReceivedLikes should return consistent data', () async {
      final firstCall = await repository.getReceivedLikes();
      final secondCall = await repository.getReceivedLikes();

      expect(firstCall.length, secondCall.length);
      expect(firstCall.first.id, secondCall.first.id);
      expect(firstCall.first.name, secondCall.first.name);
    });

    test('likes should have valid timestamps', () async {
      final likes = await repository.getReceivedLikes();
      
      for (final like in likes) {
        expect(like.likedAt, isA<DateTime>());
        expect(like.likedAt.isBefore(DateTime.now()), true);
      }
    });
  });
} 