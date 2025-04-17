import 'package:flutter_test/flutter_test.dart';
import 'package:hushmate/data/repositories/received_likes_repository_impl.dart';
import 'package:hushmate/presentation/bloc/received_likes/received_likes_bloc.dart';
import 'package:hushmate/presentation/bloc/received_likes/received_likes_event.dart';
import 'package:hushmate/presentation/bloc/received_likes/received_likes_state.dart';

void main() {
  late ReceivedLikesBloc bloc;
  late ReceivedLikesRepositoryImpl repository;

  setUp(() {
    repository = ReceivedLikesRepositoryImpl();
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
      act: (bloc) => bloc.add(LoadReceivedLikes()),
      expect: () => [
        isA<ReceivedLikesLoading>(),
        isA<ReceivedLikesLoaded>(),
      ],
    );

    blocTest<ReceivedLikesBloc, ReceivedLikesState>(
      'emits [ReceivedLikesLoading, ReceivedLikesLoaded] when AcceptLike is successful',
      build: () => bloc,
      act: (bloc) async {
        await bloc.add(LoadReceivedLikes());
        final likes = (bloc.state as ReceivedLikesLoaded).likes;
        bloc.add(AcceptLike(likes.first.id));
      },
      expect: () => [
        isA<ReceivedLikesLoading>(),
        isA<ReceivedLikesLoaded>(),
        isA<ReceivedLikesLoading>(),
        isA<ReceivedLikesLoaded>(),
      ],
    );

    blocTest<ReceivedLikesBloc, ReceivedLikesState>(
      'emits [ReceivedLikesLoading, ReceivedLikesLoaded] when RejectLike is successful',
      build: () => bloc,
      act: (bloc) async {
        await bloc.add(LoadReceivedLikes());
        final likes = (bloc.state as ReceivedLikesLoaded).likes;
        bloc.add(RejectLike(likes.first.id));
      },
      expect: () => [
        isA<ReceivedLikesLoading>(),
        isA<ReceivedLikesLoaded>(),
        isA<ReceivedLikesLoading>(),
        isA<ReceivedLikesLoaded>(),
      ],
    );

    test('loaded state should contain non-empty likes list', () async {
      bloc.add(LoadReceivedLikes());
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(bloc.state, isA<ReceivedLikesLoaded>());
      final likes = (bloc.state as ReceivedLikesLoaded).likes;
      expect(likes.isNotEmpty, true);
    });

    test('likes should have valid timestamps', () async {
      bloc.add(LoadReceivedLikes());
      await Future.delayed(const Duration(milliseconds: 100));
      
      final likes = (bloc.state as ReceivedLikesLoaded).likes;
      for (final like in likes) {
        expect(like.likedAt, isA<DateTime>());
        expect(like.likedAt.isBefore(DateTime.now()), true);
      }
    });
  });
} 