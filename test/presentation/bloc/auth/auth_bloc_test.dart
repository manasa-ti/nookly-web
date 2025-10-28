import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:nookly/presentation/bloc/auth/auth_bloc.dart';
import 'package:nookly/presentation/bloc/auth/auth_event.dart';
import 'package:nookly/presentation/bloc/auth/auth_state.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/data/repositories/notification_repository.dart';
import 'package:nookly/data/models/auth/auth_response_model.dart';
import 'package:nookly/data/models/auth/location_age_range_models.dart';

import 'auth_bloc_test.mocks.dart';

@GenerateMocks([AuthRepository, NotificationRepository])
void main() {
  group('AuthBloc Tests', () {
    late MockAuthRepository mockAuthRepository;
    late MockNotificationRepository mockNotificationRepository;
    late AuthBloc authBloc;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockNotificationRepository = MockNotificationRepository();
      authBloc = AuthBloc(
        authRepository: mockAuthRepository,
        notificationRepository: mockNotificationRepository,
      );
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state should be AuthInitial', () {
      expect(authBloc.state, equals(AuthInitial()));
    });

    group('SignInWithEmailAndPassword', () {
      const email = 'test@example.com';
      const password = 'password123';
      final user = User(
        id: '1',
        email: email,
        name: 'test',
        age: 25,
        sex: 'm',
        seekingGender: 'f',
        location: null, // The mapping sets location to null when coordinates are [0,0]
        preferredAgeRange: {'lower_limit': 18, 'upper_limit': 30},
        hometown: 'Test City',
        bio: 'Test bio',
        interests: ['Music'],
        objectives: ['Long Term'],
        personalityType: null, // Not mapped in _mapUserModelToEntity
        physicalActiveness: null, // Not mapped in _mapUserModelToEntity
        availability: null, // Not mapped in _mapUserModelToEntity
        profilePic: '', // Mapped in _mapUserModelToEntity but defaults to empty string
        preferredDistanceRadius: null, // Not mapped in _mapUserModelToEntity
      );
      
      final userModel = UserModel(
        id: '1',
        email: email,
        age: 25,
        sex: 'm',
        location: LocationModel(coordinates: [0.0, 0.0]),
        seekingGender: 'f',
        preferredAgeRange: AgeRangeModel(lowerLimit: 18, upperLimit: 30),
        hometown: 'Test City',
        bio: 'Test bio',
        interests: ['Music'],
        objectives: ['Long Term'],
        profilePic: null,
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Authenticated] when sign in is successful',
        build: () {
          when(mockAuthRepository.signInWithEmailAndPassword(email, password))
              .thenAnswer((_) async => AuthResponseModel(
                    user: userModel,
                    token: 'test_token',
                    emailVerificationRequired: false,
                  ));
          when(mockNotificationRepository.registerDevice())
              .thenAnswer((_) async => true);
          return authBloc;
        },
        act: (bloc) => bloc.add(SignInWithEmailAndPassword(email: email, password: password)),
        expect: () => [
          AuthLoading(),
          Authenticated(user),
        ],
        verify: (_) {
          verify(mockAuthRepository.signInWithEmailAndPassword(email, password)).called(1);
          verify(mockNotificationRepository.registerDevice()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, EmailVerificationRequired] when email verification is required',
        build: () {
          when(mockAuthRepository.signInWithEmailAndPassword(email, password))
              .thenAnswer((_) async => AuthResponseModel(
                    user: userModel,
                    token: null,
                    emailVerificationRequired: true,
                  ));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignInWithEmailAndPassword(email: email, password: password)),
        expect: () => [
          AuthLoading(),
          EmailVerificationRequired(
            email: email,
            message: 'Please verify your email to continue.',
          ),
        ],
        verify: (_) {
          verify(mockAuthRepository.signInWithEmailAndPassword(email, password)).called(1);
          verifyNever(mockNotificationRepository.registerDevice());
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when sign in fails',
        build: () {
          when(mockAuthRepository.signInWithEmailAndPassword(email, password))
              .thenThrow(Exception('Invalid credentials'));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignInWithEmailAndPassword(email: email, password: password)),
        expect: () => [
          AuthLoading(),
          AuthError('Exception: Invalid credentials'),
        ],
        verify: (_) {
          verify(mockAuthRepository.signInWithEmailAndPassword(email, password)).called(1);
          verifyNever(mockNotificationRepository.registerDevice());
        },
      );
    });

    group('SignOut', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Unauthenticated] when sign out is successful',
        build: () {
          when(mockAuthRepository.signOut())
              .thenAnswer((_) async => {});
          when(mockNotificationRepository.unregisterDevice())
              .thenAnswer((_) async => true);
          return authBloc;
        },
        act: (bloc) => bloc.add(SignOut()),
        expect: () => [
          AuthLoading(),
          Unauthenticated(),
        ],
        verify: (_) {
          verify(mockAuthRepository.signOut()).called(1);
          verify(mockNotificationRepository.unregisterDevice()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when sign out fails',
        build: () {
          when(mockAuthRepository.signOut())
              .thenThrow(Exception('Sign out failed'));
          when(mockNotificationRepository.unregisterDevice())
              .thenAnswer((_) async => true);
          return authBloc;
        },
        act: (bloc) => bloc.add(SignOut()),
        expect: () => [
          AuthLoading(),
          AuthError('Exception: Sign out failed'),
        ],
        verify: (_) {
          verify(mockAuthRepository.signOut()).called(1);
          verify(mockNotificationRepository.unregisterDevice()).called(1);
        },
      );
    });
  });
} 