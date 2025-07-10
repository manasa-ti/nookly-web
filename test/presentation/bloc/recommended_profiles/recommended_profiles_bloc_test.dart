import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:nookly/data/repositories/recommended_profiles_repository_impl.dart';
import 'package:nookly/presentation/bloc/recommended_profiles/recommended_profiles_bloc.dart';

void main() {
  late RecommendedProfilesBloc bloc;
  late RecommendedProfilesRepositoryImpl repository;

  setUp(() {
    repository = RecommendedProfilesRepositoryImpl();
    bloc = RecommendedProfilesBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('RecommendedProfilesBloc', () {
    test('initial state should be RecommendedProfilesInitial', () {
      expect(bloc.state, isA<RecommendedProfilesInitial>());
    });

    blocTest<RecommendedProfilesBloc, RecommendedProfilesState>(
      'emits [RecommendedProfilesLoading, RecommendedProfilesLoaded] when LoadRecommendedProfiles is successful',
      build: () => bloc,
      act: (bloc) => bloc.add(LoadRecommendedProfiles()),
      expect: () => [
        isA<RecommendedProfilesLoading>(),
        isA<RecommendedProfilesLoaded>(),
      ],
    );

    blocTest<RecommendedProfilesBloc, RecommendedProfilesState>(
      'emits [RecommendedProfilesLoading, RecommendedProfilesLoaded] when LikeProfile is successful',
      build: () => bloc,
      act: (bloc) {
        bloc.add(LoadRecommendedProfiles());
        final profiles = (bloc.state as RecommendedProfilesLoaded).profiles;
        bloc.add(LikeProfile(profiles.first.id));
      },
      expect: () => [
        isA<RecommendedProfilesLoading>(),
        isA<RecommendedProfilesLoaded>(),
        isA<RecommendedProfilesLoading>(),
        isA<RecommendedProfilesLoaded>(),
      ],
    );

    blocTest<RecommendedProfilesBloc, RecommendedProfilesState>(
      'emits [RecommendedProfilesLoading, RecommendedProfilesLoaded] when DislikeProfile is successful',
      build: () => bloc,
      act: (bloc) {
        bloc.add(LoadRecommendedProfiles());
        final profiles = (bloc.state as RecommendedProfilesLoaded).profiles;
        bloc.add(DislikeProfile(profiles.first.id));
      },
      expect: () => [
        isA<RecommendedProfilesLoading>(),
        isA<RecommendedProfilesLoaded>(),
        isA<RecommendedProfilesLoading>(),
        isA<RecommendedProfilesLoaded>(),
      ],
    );

    test('loaded state should contain non-empty profiles list', () async {
      bloc.add(LoadRecommendedProfiles());
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(bloc.state, isA<RecommendedProfilesLoaded>());
      final profiles = (bloc.state as RecommendedProfilesLoaded).profiles;
      expect(profiles.isNotEmpty, true);
    });
  });
} 