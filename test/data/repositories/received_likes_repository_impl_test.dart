import 'package:flutter_test/flutter_test.dart';
import 'package:nookly/data/repositories/received_likes_repository_impl.dart';
import 'package:nookly/domain/entities/received_like.dart';
import 'package:nookly/domain/entities/recommended_profile.dart';
import 'package:nookly/domain/repositories/recommended_profiles_repository.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([RecommendedProfilesRepository])
import 'received_likes_repository_impl_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // Add Flutter binding initialization

  late ReceivedLikesRepositoryImpl repository;
  late MockRecommendedProfilesRepository mockRecommendedProfilesRepository;

  setUp(() {
    mockRecommendedProfilesRepository = MockRecommendedProfilesRepository();
    
    // Setup mock data with likedAt timestamp
    when(mockRecommendedProfilesRepository.getProfilesThatLikedMe()).thenAnswer(
      (_) async => [
        RecommendedProfile(
          id: '1',
          name: 'Test User',
          age: 25,
          sex: 'Female',
          location: {'lat': 0.0, 'lng': 0.0},
          hometown: 'Test City',
          bio: 'Test Bio',
          interests: ['Test'],
          objectives: ['Test'],
          distance: 5.0,
          commonInterests: ['Test'],
          commonObjectives: ['Test'],
          likedAt: DateTime.now().subtract(const Duration(hours: 2)), // Add actual timestamp
        ),
      ],
    );

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

    test('likes should use API timestamp when available', () async {
      final likes = await repository.getReceivedLikes();
      
      for (final like in likes) {
        expect(like.likedAt, isA<DateTime>());
        // The timestamp should be from the API (2 hours ago in our mock)
        expect(like.likedAt.isBefore(DateTime.now().subtract(const Duration(hours: 1))), true);
      }
    });

    test('likes should fallback to current time when API timestamp is null', () async {
      // Setup mock with null likedAt
      when(mockRecommendedProfilesRepository.getProfilesThatLikedMe()).thenAnswer(
        (_) async => [
          RecommendedProfile(
            id: '1',
            name: 'Test User',
            age: 25,
            sex: 'Female',
            location: {'lat': 0.0, 'lng': 0.0},
            hometown: 'Test City',
            bio: 'Test Bio',
            interests: ['Test'],
            objectives: ['Test'],
            distance: 5.0,
            commonInterests: ['Test'],
            commonObjectives: ['Test'],
            likedAt: null, // No API timestamp
          ),
        ],
      );

      final likes = await repository.getReceivedLikes();
      
      for (final like in likes) {
        expect(like.likedAt, isA<DateTime>());
        // Should be very recent (within last few seconds)
        expect(like.likedAt.isAfter(DateTime.now().subtract(const Duration(seconds: 5))), true);
      }
    });
  });
} 