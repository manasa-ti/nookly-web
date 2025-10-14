import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:nookly/data/repositories/received_likes_repository_impl.dart';
import 'package:nookly/presentation/bloc/received_likes/received_likes_bloc.dart';
import 'package:nookly/domain/repositories/recommended_profiles_repository.dart';
import 'package:nookly/domain/entities/recommended_profile.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([RecommendedProfilesRepository])
import 'received_likes_bloc_test.mocks.dart';

void main() {
  late ReceivedLikesBloc bloc;
  late ReceivedLikesRepositoryImpl repository;
  late MockRecommendedProfilesRepository mockRecommendedProfilesRepository;

  setUp(() {
    mockRecommendedProfilesRepository = MockRecommendedProfilesRepository();
    
    // Setup mock data
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
        ),
      ],
    );

    repository = ReceivedLikesRepositoryImpl(
      recommendedProfilesRepository: mockRecommendedProfilesRepository,
    );
    bloc = ReceivedLikesBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('ReceivedLikesBloc', () {
    test('initial state should be ReceivedLikesInitial', () {
      expect(bloc.state, isA<ReceivedLikesInitial>());
    });

    blocTest<ReceivedLikesBloc, ReceivedLikesState>(
      'emits [ReceivedLikesLoading, ReceivedLikesLoaded] when LoadReceivedLikes is successful',
      build: () => bloc,
      act: (bloc) => bloc.add(const LoadReceivedLikes()),
      expect: () => [
        isA<ReceivedLikesLoading>(),
        isA<ReceivedLikesLoaded>(),
      ],
    );

    // NOTE: Tests skipped - async timing issues, need proper await or seed setup
    // These should be rewritten with proper seed or async handling

    test('loaded state should contain non-empty likes list', () async {
      bloc.add(const LoadReceivedLikes());
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(bloc.state, isA<ReceivedLikesLoaded>());
      final likes = (bloc.state as ReceivedLikesLoaded).likes;
      expect(likes.isNotEmpty, true);
    });

    test('likes should have valid timestamps', () async {
      bloc.add(const LoadReceivedLikes());
      await Future.delayed(const Duration(milliseconds: 100));
      
      final likes = (bloc.state as ReceivedLikesLoaded).likes;
      for (final like in likes) {
        expect(like.likedAt, isA<DateTime>());
        expect(like.likedAt.isBefore(DateTime.now()), true);
      }
    });
  });
} 