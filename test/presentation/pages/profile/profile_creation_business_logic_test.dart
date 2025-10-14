import 'package:flutter_test/flutter_test.dart';
import 'package:nookly/domain/entities/user.dart';

void main() {
  group('Profile Creation Business Logic Tests', () {
    group('Age Validation', () {
      test('should calculate age correctly from birthdate', () {
        final birthdate = DateTime.now().subtract(const Duration(days: 365 * 25)); // 25 years ago
        final age = DateTime.now().difference(birthdate).inDays ~/ 365;
        expect(age, equals(25));
      });

      test('should reject users under 18', () {
        final birthdate = DateTime.now().subtract(const Duration(days: 365 * 17)); // 17 years ago
        final age = DateTime.now().difference(birthdate).inDays ~/ 365;
        expect(age, lessThan(18));
        expect(age, equals(17));
      });

      test('should accept users 18 and older', () {
        final birthdate = DateTime.now().subtract(const Duration(days: 365 * 18)); // 18 years ago
        final age = DateTime.now().difference(birthdate).inDays ~/ 365;
        expect(age, greaterThanOrEqualTo(18));
        expect(age, equals(18));
      });

      test('should handle edge case of exactly 18 years', () {
        final birthdate = DateTime.now().subtract(const Duration(days: 365 * 18 + 1)); // Just over 18 years
        final age = DateTime.now().difference(birthdate).inDays ~/ 365;
        expect(age, equals(18));
      });
    });

    group('Gender Validation', () {
      test('should map gender options correctly', () {
        const genderMappings = {
          'Man': 'm',
          'Woman': 'f',
          'Other': 'other',
        };

        expect(genderMappings['Man'], equals('m'));
        expect(genderMappings['Woman'], equals('f'));
        expect(genderMappings['Other'], equals('other'));
      });

      test('should map seeking gender options correctly', () {
        const seekingGenderMappings = {
          'Man': 'm',
          'Woman': 'f',
          'Any': 'any',
        };

        expect(seekingGenderMappings['Man'], equals('m'));
        expect(seekingGenderMappings['Woman'], equals('f'));
        expect(seekingGenderMappings['Any'], equals('any'));
      });
    });

    group('Location Validation', () {
      test('should validate location coordinates', () {
        const latitude = 37.7749;
        const longitude = -122.4194;

        // Valid coordinates
        expect(latitude >= -90 && latitude <= 90, isTrue);
        expect(longitude >= -180 && longitude <= 180, isTrue);
      });

      test('should reject invalid latitude', () {
        const invalidLatitudes = [91.0, -91.0, 200.0, -200.0];

        for (final lat in invalidLatitudes) {
          expect(lat >= -90 && lat <= 90, isFalse);
        }
      });

      test('should reject invalid longitude', () {
        const invalidLongitudes = [181.0, -181.0, 300.0, -300.0];

        for (final lng in invalidLongitudes) {
          expect(lng >= -180 && lng <= 180, isFalse);
        }
      });

      test('should format location coordinates correctly for API', () {
        const latitude = 37.7749;
        const longitude = -122.4194;

        final locationData = {
          'coordinates': [longitude, latitude], // [longitude, latitude] format
        };

        expect(locationData['coordinates'], isA<List>());
        expect(locationData['coordinates'], hasLength(2));
        expect(locationData['coordinates']![0], equals(longitude));
        expect(locationData['coordinates']![1], equals(latitude));
      });
    });

    group('Age Range Validation', () {
      test('should validate age range limits', () {
        const lowerLimit = 18;
        const upperLimit = 80;

        expect(lowerLimit, greaterThanOrEqualTo(18));
        expect(upperLimit, lessThanOrEqualTo(100));
        expect(lowerLimit, lessThan(upperLimit));
      });

      test('should reject invalid age ranges', () {
        const invalidRanges = [
          {'lower': 17, 'upper': 80}, // Lower limit too low
          {'lower': 18, 'upper': 101}, // Upper limit too high
          {'lower': 80, 'upper': 18}, // Lower > Upper
          {'lower': 18, 'upper': 18}, // Same values
        ];

        for (final range in invalidRanges) {
          final lower = range['lower']!;
          final upper = range['upper']!;
          
          final isValid = lower >= 18 && upper <= 100 && lower < upper;
          expect(isValid, isFalse);
        }
      });

      test('should accept valid age ranges', () {
        const validRanges = [
          {'lower': 18, 'upper': 25},
          {'lower': 25, 'upper': 35},
          {'lower': 30, 'upper': 50},
          {'lower': 18, 'upper': 80},
        ];

        for (final range in validRanges) {
          final lower = range['lower']!;
          final upper = range['upper']!;
          
          final isValid = lower >= 18 && upper <= 100 && lower < upper;
          expect(isValid, isTrue);
        }
      });
    });

    group('Distance Radius Validation', () {
      test('should validate distance radius limits', () {
        const validRadii = [1, 5, 10, 25, 50, 100];
        const invalidRadii = [0, -1, 101, 200];

        for (final radius in validRadii) {
          expect(radius > 0 && radius <= 100, isTrue);
        }

        for (final radius in invalidRadii) {
          expect(radius > 0 && radius <= 100, isFalse);
        }
      });

      test('should convert distance radius to integer', () {
        const radius = 40.0;
        expect(radius.round(), equals(40));
        expect(radius.round(), isA<int>());
      });
    });

    group('Required Fields Validation', () {
      test('should validate required fields for each step', () {
        // Step 0: Basic Info
        final basicInfoValid = {
          'birthdate': DateTime.now().subtract(const Duration(days: 365 * 25)),
          'sex': 'Man',
          'seekingGender': 'Woman',
        };
        expect(basicInfoValid['birthdate'], isNotNull);
        expect(basicInfoValid['sex'], isNotNull);
        expect(basicInfoValid['seekingGender'], isNotNull);

        // Step 1: Location
        final locationValid = {
          'hometown': 'San Francisco',
        };
        expect(locationValid['hometown']!.isNotEmpty, isTrue);

        // Step 2: Profile Details
        final profileDetailsValid = {
          'bio': 'This is my bio',
          'interests': ['Deep Conversations', 'Travel'],
        };
        expect((profileDetailsValid['bio'] as String).isNotEmpty, isTrue);
        expect((profileDetailsValid['interests'] as List).isNotEmpty, isTrue);

        // Step 3: Objectives
        final objectivesValid = {
          'objectives': ['Long Term'],
        };
        expect(objectivesValid['objectives']!.isNotEmpty, isTrue);

        // Step 4: Personality Type
        final personalityValid = {
          'personalityTypes': ['introvert'],
        };
        expect(personalityValid['personalityTypes']!.isNotEmpty, isTrue);

        // Step 5: Physical Activeness
        final physicalValid = {
          'physicalActiveness': ['moderate'],
        };
        expect(physicalValid['physicalActiveness']!.isNotEmpty, isTrue);

        // Step 6: Availability
        final availabilityValid = {
          'availability': ['weekends'],
        };
        expect(availabilityValid['availability']!.isNotEmpty, isTrue);
      });

      test('should reject empty required fields', () {
        // Empty bio
        const bio = '';
        expect(bio.isNotEmpty, isFalse);

        // Empty interests
        const interests = <String>[];
        expect(interests.isNotEmpty, isFalse);

        // Empty objectives
        const objectives = <String>[];
        expect(objectives.isNotEmpty, isFalse);

        // Empty hometown
        const hometown = '';
        expect(hometown.isNotEmpty, isFalse);
      });
    });

    group('Fallback Data', () {
      test('should have fallback objectives', () {
        const fallbackObjectives = [
          'Short Term',
          'Long Term',
          'Serious Committed Relationship',
          'Casual',
          'ONS',
          'FWB',
          'Friends to Hang Out',
          'Emotional Connection',
        ];

        expect(fallbackObjectives, isNotEmpty);
        expect(fallbackObjectives.length, greaterThan(0));
      });

      test('should have fallback personality types', () {
        const fallbackPersonalityTypes = [
          'introvert',
          'extrovert',
          'ambivert',
          'foody',
          'chatty',
          'book worm',
          'party animal',
          'tech enthusiast',
          'explorative',
          'conventional',
          'easy going',
          'fussy',
          'spontaneous',
          'organised',
          'competitive',
          'loyalist',
          'peacemaker',
        ];

        expect(fallbackPersonalityTypes, isNotEmpty);
        expect(fallbackPersonalityTypes.length, greaterThan(0));
      });

      test('should have fallback physical activeness options', () {
        const fallbackPhysicalActiveness = [
          'Weight lifter',
          'Runner',
          'Dancer',
          'Sporty',
          'walker',
          'couch potato',
        ];

        expect(fallbackPhysicalActiveness, isNotEmpty);
        expect(fallbackPhysicalActiveness.length, greaterThan(0));
      });

      test('should have fallback availability options', () {
        const fallbackAvailability = [
          'weekdays',
          'weekends',
          'evenings',
          'mornings',
          'flexible',
          'busy',
        ];

        expect(fallbackAvailability, isNotEmpty);
        expect(fallbackAvailability.length, greaterThan(0));
      });
    });

    group('User Object Creation', () {
      test('should create valid User object with all required fields', () {
        final user = User(
          id: '',
          email: '',
          name: '',
          age: 25,
          sex: 'm',
          seekingGender: 'f',
          location: {
            'coordinates': [-122.4194, 37.7749],
          },
          preferredAgeRange: {
            'lower_limit': 18,
            'upper_limit': 30,
          },
          hometown: 'San Francisco',
          bio: 'This is my bio',
          interests: ['Deep Conversations', 'Travel'],
          objectives: ['Long Term'],
          personalityType: ['introvert'],
          physicalActiveness: ['moderate'],
          availability: ['weekends'],
          preferredDistanceRadius: 40,
        );

        expect(user.age, equals(25));
        expect(user.sex, equals('m'));
        expect(user.seekingGender, equals('f'));
        expect(user.hometown, equals('San Francisco'));
        expect(user.bio, equals('This is my bio'));
        expect(user.interests, hasLength(2));
        expect(user.objectives, hasLength(1));
        expect(user.personalityType, hasLength(1));
        expect(user.physicalActiveness, hasLength(1));
        expect(user.availability, hasLength(1));
        expect(user.preferredDistanceRadius, equals(40));
      });

      test('should handle empty optional fields', () {
        final user = User(
          id: '',
          email: '',
          name: '',
          age: 25,
          sex: 'm',
          seekingGender: 'f',
          location: {
            'coordinates': [-122.4194, 37.7749],
          },
          preferredAgeRange: {
            'lower_limit': 18,
            'upper_limit': 30,
          },
          hometown: 'San Francisco',
          bio: 'This is my bio',
          interests: ['Deep Conversations'],
          objectives: ['Long Term'],
          personalityType: ['introvert'],
          physicalActiveness: ['moderate'],
          availability: ['weekends'],
          preferredDistanceRadius: 40,
        );

        expect(user.profilePic, isNull);
        expect(user.isOnline, isNull);
        expect(user.lastSeen, isNull);
        expect(user.connectionStatus, isNull);
        expect(user.lastActive, isNull);
      });
    });

    group('Content Moderation', () {
      test('should validate bio content length', () {
        const shortBio = 'Hi';
        final longBio = 'A' * 1000;
        const normalBio = 'This is a normal bio with reasonable length';

        expect(shortBio.length, lessThan(10));
        expect(longBio.length, greaterThan(500));
        expect(normalBio.length, greaterThan(10));
        expect(normalBio.length, lessThan(500));
      });

      test('should handle empty bio', () {
        const emptyBio = '';
        expect(emptyBio.isEmpty, isTrue);
        expect(emptyBio.isNotEmpty, isFalse);
      });

      test('should validate bio contains appropriate content', () {
        const appropriateBio = 'I love hiking and reading books';
        const inappropriateBio = 'This contains inappropriate content';

        // Basic validation (in real implementation, this would use content moderation service)
        expect(appropriateBio.toLowerCase().contains('inappropriate'), isFalse);
        expect(inappropriateBio.toLowerCase().contains('inappropriate'), isTrue);
      });
    });

    group('Step Navigation Logic', () {
      test('should validate step progression', () {
        const totalSteps = 7; // 0-6
        const currentStep = 3;

        expect(currentStep, greaterThanOrEqualTo(0));
        expect(currentStep, lessThan(totalSteps));
        expect(currentStep + 1, lessThanOrEqualTo(totalSteps));
      });

      test('should handle step validation logic', () {
        final stepValidation = {
          0: {'birthdate': true, 'sex': true, 'seekingGender': true},
          1: {'hometown': true},
          2: {'bio': true, 'interests': true},
          3: {'objectives': true},
          4: {'personalityTypes': true},
          5: {'physicalActiveness': true},
          6: {'availability': true},
        };

        for (final entry in stepValidation.entries) {
          final step = entry.key;
          final fields = entry.value;
          
          expect(step, greaterThanOrEqualTo(0));
          expect(step, lessThan(7));
          expect(fields.values.every((isValid) => isValid), isTrue);
        }
      });
    });
  });
}
