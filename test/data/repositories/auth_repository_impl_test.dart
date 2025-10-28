import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:nookly/data/repositories/auth_repository_impl.dart';
import 'package:nookly/data/models/auth/auth_response_model.dart';
import 'package:nookly/domain/entities/user.dart';

import 'auth_repository_impl_test.mocks.dart';

@GenerateMocks([SharedPreferences])
void main() {
  group('AuthRepositoryImpl Tests', () {
    late MockSharedPreferences mockSharedPreferences;
    late AuthRepositoryImpl authRepository;

    setUp(() {
      mockSharedPreferences = MockSharedPreferences();
      authRepository = AuthRepositoryImpl(mockSharedPreferences);
    });

    group('isLoggedIn', () {
      test('should return true when token exists', () async {
        // Arrange
        when(mockSharedPreferences.getString('token'))
            .thenReturn('test_token');

        // Act
        final result = await authRepository.isLoggedIn();

        // Assert
        expect(result, true);
        verify(mockSharedPreferences.getString('token')).called(1);
      });

      test('should return false when token is null', () async {
        // Arrange
        when(mockSharedPreferences.getString('token'))
            .thenReturn(null);

        // Act
        final result = await authRepository.isLoggedIn();

        // Assert
        expect(result, false);
        verify(mockSharedPreferences.getString('token')).called(1);
      });
    });

    group('getToken', () {
      test('should return token when it exists', () async {
        // Arrange
        const token = 'test_token';
        when(mockSharedPreferences.getString('token'))
            .thenReturn(token);

        // Act
        final result = await authRepository.getToken();

        // Assert
        expect(result, token);
        verify(mockSharedPreferences.getString('token')).called(1);
      });

      test('should return null when token does not exist', () async {
        // Arrange
        when(mockSharedPreferences.getString('token'))
            .thenReturn(null);

        // Act
        final result = await authRepository.getToken();

        // Assert
        expect(result, null);
        verify(mockSharedPreferences.getString('token')).called(1);
      });
    });

    group('logout', () {
      test('should clear token and userId from SharedPreferences', () async {
        // Arrange
        when(mockSharedPreferences.remove('token'))
            .thenAnswer((_) async => true);
        when(mockSharedPreferences.remove('userId'))
            .thenAnswer((_) async => true);

        // Act
        await authRepository.logout();

        // Assert
        verify(mockSharedPreferences.remove('token')).called(1);
        verify(mockSharedPreferences.remove('userId')).called(1);
      });
    });
  });
}