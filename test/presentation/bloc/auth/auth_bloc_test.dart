import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nookly/data/repositories/auth_repository_impl.dart';
import 'package:nookly/presentation/bloc/auth/auth_bloc.dart';
import 'package:nookly/presentation/bloc/auth/auth_event.dart';
import 'package:nookly/presentation/bloc/auth/auth_state.dart';

void main() {
  late AuthBloc bloc;
  late AuthRepositoryImpl repository;
  late SharedPreferences prefs;

  setUp(() async {
    prefs = await SharedPreferences.getInstance();
    repository = AuthRepositoryImpl(prefs);
    bloc = AuthBloc(authRepository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('AuthBloc', () {
    test('initial state should be AuthInitial', () {
      expect(bloc.state, isA<AuthInitial>());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when SignInWithEmailAndPassword is successful',
      build: () => bloc,
      act: (bloc) => bloc.add(
        const SignInWithEmailAndPassword(
          email: 'user@example.com',
          password: 'password123',
        ),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<Authenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when SignInWithEmailAndPassword fails',
      build: () => bloc,
      act: (bloc) => bloc.add(
        const SignInWithEmailAndPassword(
          email: 'wrong@email.com',
          password: 'wrongpassword',
        ),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when SignUpWithEmailAndPassword is successful',
      build: () => bloc,
      act: (bloc) => bloc.add(
        SignUpWithEmailAndPassword(
          email: 'new@email.com',
          password: 'password123',
        ),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<Authenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when SignUpWithEmailAndPassword fails',
      build: () => bloc,
      act: (bloc) => bloc.add(
        SignUpWithEmailAndPassword(
          email: 'user@example.com',
          password: 'password123',
        ),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when SignOut is called',
      build: () => bloc,
      act: (bloc) => bloc.add(SignOut()),
      expect: () => [
        isA<AuthLoading>(),
        isA<Unauthenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when CheckAuthStatus is called and user is authenticated',
      build: () => bloc,
      act: (bloc) => bloc.add(CheckAuthStatus()),
      expect: () => [
        isA<AuthLoading>(),
        isA<Authenticated>(),
      ],
    );
  });
} 