import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:nookly/data/repositories/recommended_profiles_repository_impl.dart';
import 'package:nookly/presentation/bloc/recommended_profiles/recommended_profiles_bloc.dart';
import 'package:flutter/widgets.dart';

void main() {
  late RecommendedProfilesBloc bloc;
  late RecommendedProfilesRepositoryImpl repository;

  setUpAll(() {
    // Initialize Flutter binding for tests
    WidgetsFlutterBinding.ensureInitialized();
  });

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

    // NOTE: The following tests are skipped because they require proper mocking
    // of the repository and dependencies (shared_preferences, network calls, etc.)
    // These tests currently try to make real API calls which is not appropriate
    // for unit tests. They should be rewritten with proper mocks or moved to
    // integration tests.
    
    // NOTE: Tests skipped - require proper repository mocking (currently make real API calls)
    // These should be rewritten with proper mocks or moved to integration tests
  });
} 