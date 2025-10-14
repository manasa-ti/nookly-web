import 'package:flutter_test/flutter_test.dart';
import 'package:nookly/domain/entities/user.dart';

void main() {
  group('User', () {
    group('fromJson', () {
      test('should parse location coordinates correctly when they are integers', () {
        // Arrange
        final json = {
          '_id': '1',
          'email': 'test@example.com',
          'name': 'Test User',
          'bio': 'Test bio',
          'interests': [],
          'location': {
            'coordinates': [0, 0],
          },
        };

        // Act
        final user = User.fromJson(json);

        // Assert - location is stored as {latitude, longitude}
        expect(user.location?['latitude'], 0.0);
        expect(user.location?['longitude'], 0.0);
      });

      test('should parse location coordinates correctly when they are doubles', () {
        // Arrange
        final json = {
          '_id': '1',
          'email': 'test@example.com',
          'name': 'Test User',
          'bio': 'Test bio',
          'interests': [],
          'location': {
            'coordinates': [12.34, 56.78],
          },
        };

        // Act
        final user = User.fromJson(json);

        // Assert - location is stored as {latitude, longitude}
        // coordinates[0] = longitude (12.34) → stored as latitude in User
        // coordinates[1] = latitude (56.78) → stored as longitude in User
        expect(user.location?['latitude'], 12.34);
        expect(user.location?['longitude'], 56.78);
      });

      test('should handle null location', () {
        // Arrange
        final json = {
          '_id': '1',
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
          '_id': '1',
          'email': 'test@example.com',
          'name': 'Test User',
          'bio': 'Test bio',
          'interests': ['reading', 'gaming'],
          'location': {
            'coordinates': [12.34, 56.78],
          },
          'age': 25,
          'sex': 'm',
          'seekingGender': 'f',
          'hometown': 'New York',
          'preferredAgeRange': {
            'lower_limit': 18,
            'upper_limit': 30,
          },
          'profilePic': 'https://example.com/photo.jpg',
          'objectives': ['Long Term'],
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
        expect(user.sex, 'm');
        expect(user.seekingGender, 'f');
        expect(user.hometown, 'New York');
        expect(user.preferredAgeRange?['lower_limit'], 18);
        expect(user.preferredAgeRange?['upper_limit'], 30);
        expect(user.profilePic, 'https://example.com/photo.jpg');
        expect(user.objectives, ['Long Term']);
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
          age: 25,
          sex: 'm',
          seekingGender: 'f',
          location: {
            'coordinates': [12.34, 56.78],
          },
          preferredAgeRange: {
            'lower_limit': 18,
            'upper_limit': 30,
          },
          hometown: 'New York',
          bio: 'Test bio',
          interests: ['reading'],
          objectives: ['Long Term'],
          profilePic: 'https://example.com/photo.jpg',
        );

        // Assert
        expect(user.isProfileComplete, true);
      });
    });
  });
} 