import 'package:flutter_test/flutter_test.dart';
import 'package:hushmate/domain/entities/user.dart';

void main() {
  group('User', () {
    group('fromJson', () {
      test('should parse location coordinates correctly when they are integers', () {
        // Arrange
        final json = {
          'id': '1',
          'email': 'test@example.com',
          'name': 'Test User',
          'bio': 'Test bio',
          'interests': [],
          'location': {
            'latitude': 0,
            'longitude': 0,
          },
        };

        // Act
        final user = User.fromJson(json);

        // Assert
        expect(user.location?['latitude'], 0.0);
        expect(user.location?['longitude'], 0.0);
      });

      test('should parse location coordinates correctly when they are doubles', () {
        // Arrange
        final json = {
          'id': '1',
          'email': 'test@example.com',
          'name': 'Test User',
          'bio': 'Test bio',
          'interests': [],
          'location': {
            'latitude': 12.34,
            'longitude': 56.78,
          },
        };

        // Act
        final user = User.fromJson(json);

        // Assert
        expect(user.location?['latitude'], 12.34);
        expect(user.location?['longitude'], 56.78);
      });

      test('should handle null location', () {
        // Arrange
        final json = {
          'id': '1',
          'email': 'test@example.com',
          'name': 'Test User',
          'bio': 'Test bio',
          'interests': [],
        };

        // Act
        final user = User.fromJson(json);

        // Assert
        expect(user.location, null);
      });

      test('should parse all required fields correctly', () {
        // Arrange
        final json = {
          'id': '1',
          'email': 'test@example.com',
          'name': 'Test User',
          'bio': 'Test bio',
          'interests': ['reading', 'gaming'],
          'location': {
            'latitude': 12.34,
            'longitude': 56.78,
          },
          'age': 25,
          'gender': 'Male',
          'sex': 'Male',
          'wishToFind': 'Female',
          'hometown': 'New York',
          'minAgePreference': 18,
          'maxAgePreference': 30,
          'profilePictureUrl': 'https://example.com/photo.jpg',
          'objective': 'Long Term',
          'birthdate': '1998-01-01T00:00:00.000Z',
        };

        // Act
        final user = User.fromJson(json);

        // Assert
        expect(user.id, '1');
        expect(user.email, 'test@example.com');
        expect(user.name, 'Test User');
        expect(user.bio, 'Test bio');
        expect(user.interests, ['reading', 'gaming']);
        expect(user.location?['latitude'], 12.34);
        expect(user.location?['longitude'], 56.78);
        expect(user.age, 25);
        expect(user.gender, 'Male');
        expect(user.sex, 'Male');
        expect(user.wishToFind, 'Female');
        expect(user.hometown, 'New York');
        expect(user.minAgePreference, 18);
        expect(user.maxAgePreference, 30);
        expect(user.profilePictureUrl, 'https://example.com/photo.jpg');
        expect(user.objective, 'Long Term');
        expect(user.birthdate?.year, 1998);
      });
    });

    group('isProfileComplete', () {
      test('should return false when required fields are missing', () {
        // Arrange
        final user = User(
          id: '1',
          email: 'test@example.com',
          name: 'Test User',
          bio: 'Test bio',
          interests: [],
        );

        // Assert
        expect(user.isProfileComplete, false);
      });

      test('should return true when all required fields are present', () {
        // Arrange
        final user = User(
          id: '1',
          email: 'test@example.com',
          name: 'Test User',
          bio: 'Test bio',
          interests: ['reading'],
          birthdate: DateTime.now(),
          sex: 'Male',
          wishToFind: 'Female',
          hometown: 'New York',
          minAgePreference: 18,
          maxAgePreference: 30,
          profilePictureUrl: 'https://example.com/photo.jpg',
          objective: 'Long Term',
        );

        // Assert
        expect(user.isProfileComplete, true);
      });
    });
  });
} 