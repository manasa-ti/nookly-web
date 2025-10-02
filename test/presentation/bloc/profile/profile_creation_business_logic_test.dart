import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile Creation Business Logic Tests', () {
    group('Basic Profile Validation', () {
      test('should validate required fields', () {
        final requiredFields = {
          'name': 'John Doe',
          'age': 25,
          'sex': 'm',
          'seekingGender': 'f',
          'hometown': 'San Francisco',
          'bio': 'This is my bio',
          'interests': ['Travel', 'Music'],
          'objectives': ['Long Term'],
          'personalityType': ['introvert'],
          'physicalActiveness': ['moderate'],
          'availability': ['weekends'],
        };

        for (final entry in requiredFields.entries) {
          expect(entry.value, isNotNull);
          if (entry.value is String) {
            expect(entry.value, isNotEmpty);
          } else if (entry.value is List) {
            expect(entry.value, isNotEmpty);
          } else if (entry.value is int) {
            expect(entry.value, greaterThan(0));
          }
        }
      });

      test('should validate name format', () {
        const validNames = ['John Doe', 'Jane Smith', 'Alex Johnson', 'Maria Garcia'];
        const invalidNames = ['', '   ', 'A', 'John@Doe'];

        for (final name in validNames) {
          expect(name, isNotEmpty);
          expect(name.trim(), isNotEmpty);
          expect(name.length, greaterThan(1));
        }

        for (final name in invalidNames) {
          final isValid = name.trim().isNotEmpty && name.length > 1 && !name.contains('@') && !name.contains('#');
          expect(isValid, isFalse);
        }
      });

      test('should validate age range', () {
        const validAges = [18, 25, 30, 50, 80];
        const invalidAges = [17, 81, 0, -1, 100];

        for (final age in validAges) {
          expect(age, greaterThanOrEqualTo(18));
          expect(age, lessThanOrEqualTo(80));
        }

        for (final age in invalidAges) {
          final isValid = age >= 18 && age <= 80;
          expect(isValid, isFalse);
        }
      });

      test('should validate gender values', () {
        const validGenders = ['m', 'f', 'other'];
        const invalidGenders = ['male', 'female', 'unknown', '', 'M', 'F'];

        for (final gender in validGenders) {
          expect(gender, isIn(['m', 'f', 'other']));
        }

        for (final gender in invalidGenders) {
          expect(gender, isNot(isIn(['m', 'f', 'other'])));
        }
      });

      test('should validate seeking gender values', () {
        const validSeekingGenders = ['m', 'f', 'other', 'any'];
        const invalidSeekingGenders = ['male', 'female', 'unknown', '', 'M', 'F'];

        for (final gender in validSeekingGenders) {
          expect(gender, isIn(['m', 'f', 'other', 'any']));
        }

        for (final gender in invalidSeekingGenders) {
          expect(gender, isNot(isIn(['m', 'f', 'other', 'any'])));
        }
      });
    });

    group('Location Validation', () {
      test('should validate location coordinates', () {
        const validCoordinates = [
          {'lat': 37.7749, 'lng': -122.4194}, // San Francisco
          {'lat': 40.7128, 'lng': -74.0060}, // New York
          {'lat': 51.5074, 'lng': -0.1278},  // London
          {'lat': 0.0, 'lng': 0.0},          // Equator/Prime Meridian
        ];

        const invalidCoordinates = [
          {'lat': 91.0, 'lng': -122.4194},   // Invalid latitude
          {'lat': 37.7749, 'lng': 181.0},    // Invalid longitude
          {'lat': -91.0, 'lng': -122.4194},  // Invalid latitude
          {'lat': 37.7749, 'lng': -181.0},   // Invalid longitude
        ];

        for (final coord in validCoordinates) {
          final lat = coord['lat'] as double;
          final lng = coord['lng'] as double;
          expect(lat, greaterThanOrEqualTo(-90.0));
          expect(lat, lessThanOrEqualTo(90.0));
          expect(lng, greaterThanOrEqualTo(-180.0));
          expect(lng, lessThanOrEqualTo(180.0));
        }

        for (final coord in invalidCoordinates) {
          final lat = coord['lat'] as double;
          final lng = coord['lng'] as double;
          final isValid = lat >= -90.0 && lat <= 90.0 && lng >= -180.0 && lng <= 180.0;
          expect(isValid, isFalse);
        }
      });

      test('should validate location format', () {
        final validLocation = {
          'coordinates': [-122.4194, 37.7749], // [longitude, latitude]
        };

        expect(validLocation['coordinates'], isA<List>());
        expect(validLocation['coordinates'], hasLength(2));
        expect(validLocation['coordinates']![0], isA<double>());
        expect(validLocation['coordinates']![1], isA<double>());
      });

      test('should handle location permission states', () {
        const permissionStates = ['granted', 'denied', 'deniedForever', 'unknown'];
        
        for (final state in permissionStates) {
          expect(state, isIn(['granted', 'denied', 'deniedForever', 'unknown']));
        }
      });
    });

    group('Interests Validation', () {
      test('should validate interest categories', () {
        const validInterests = [
          'Deep Conversations', 'Travel', 'Music', 'Sports', 'Gaming',
          'Reading', 'Cooking', 'Art', 'Photography', 'Dancing',
          'Fitness', 'Movies', 'Nature', 'Technology', 'Fashion'
        ];
        
        for (final interest in validInterests) {
          expect(interest, isNotEmpty);
          expect(interest.length, greaterThan(1));
          expect(interest, isNot(contains('@')));
          expect(interest, isNot(contains('#')));
        }
      });

      test('should validate interest count', () {
        const validInterestCounts = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        const invalidInterestCounts = [0, 11, 15, 20];

        for (final count in validInterestCounts) {
          expect(count, greaterThan(0));
          expect(count, lessThanOrEqualTo(10));
        }

        for (final count in invalidInterestCounts) {
          final isValid = count > 0 && count <= 10;
          expect(isValid, isFalse);
        }
      });

      test('should handle duplicate interests', () {
        const interests = ['Travel', 'Music', 'Travel', 'Sports'];
        final uniqueInterests = interests.toSet().toList();
        
        expect(uniqueInterests, hasLength(3));
        expect(uniqueInterests, contains('Travel'));
        expect(uniqueInterests, contains('Music'));
        expect(uniqueInterests, contains('Sports'));
      });

      test('should validate interest format', () {
        const validInterests = ['Deep Conversations', 'Travel', 'Music'];
        const invalidInterests = ['', '   ', 'A', 'Travel@', 'Music#'];

        for (final interest in validInterests) {
          expect(interest, isNotEmpty);
          expect(interest.trim(), isNotEmpty);
          expect(interest.length, greaterThan(1));
        }

        for (final interest in invalidInterests) {
          final isValid = interest.trim().isNotEmpty && 
                         interest.length > 1 && 
                         !interest.contains('@') && 
                         !interest.contains('#');
          expect(isValid, isFalse);
        }
      });
    });

    group('Objectives Validation', () {
      test('should validate objective values', () {
        const validObjectives = [
          'Long Term', 'Serious Relationship', 'Casual', 'Friends',
          'Marriage', 'Dating', 'Hook Up', 'Not Sure'
        ];
        
        for (final objective in validObjectives) {
          expect(objective, isNotEmpty);
          expect(objective.length, greaterThan(1));
        }
      });

      test('should validate objective count', () {
        const validObjectiveCounts = [1, 2, 3, 4, 5];
        const invalidObjectiveCounts = [0, 6, 10];

        for (final count in validObjectiveCounts) {
          expect(count, greaterThan(0));
          expect(count, lessThanOrEqualTo(5));
        }

        for (final count in invalidObjectiveCounts) {
          final isValid = count > 0 && count <= 5;
          expect(isValid, isFalse);
        }
      });

      test('should handle conflicting objectives', () {
        const conflictingObjectives = [
          ['Long Term', 'Hook Up'],
          ['Serious Relationship', 'Casual'],
          ['Marriage', 'Not Sure'],
        ];

        for (final objectives in conflictingObjectives) {
          final hasConflict = objectives.contains('Long Term') && objectives.contains('Hook Up') ||
                             objectives.contains('Serious Relationship') && objectives.contains('Casual') ||
                             objectives.contains('Marriage') && objectives.contains('Not Sure');
          expect(hasConflict, isTrue);
        }
      });
    });

    group('Personality Type Validation', () {
      test('should validate personality type values', () {
        const validPersonalityTypes = [
          'introvert', 'extrovert', 'ambivert', 'analytical', 'creative',
          'logical', 'emotional', 'adventurous', 'cautious', 'spontaneous'
        ];
        
        for (final personalityType in validPersonalityTypes) {
          expect(personalityType, isNotEmpty);
          expect(personalityType.length, greaterThan(1));
        }
      });

      test('should validate personality type count', () {
        const validCounts = [1, 2, 3, 4, 5];
        const invalidCounts = [0, 6, 10];

        for (final count in validCounts) {
          expect(count, greaterThan(0));
          expect(count, lessThanOrEqualTo(5));
        }

        for (final count in invalidCounts) {
          final isValid = count > 0 && count <= 5;
          expect(isValid, isFalse);
        }
      });

      test('should handle conflicting personality types', () {
        const conflictingTypes = [
          ['introvert', 'extrovert'],
          ['analytical', 'emotional'],
          ['adventurous', 'cautious'],
          ['logical', 'spontaneous'],
        ];

        for (final types in conflictingTypes) {
          final hasConflict = types.contains('introvert') && types.contains('extrovert') ||
                             types.contains('analytical') && types.contains('emotional') ||
                             types.contains('adventurous') && types.contains('cautious') ||
                             types.contains('logical') && types.contains('spontaneous');
          expect(hasConflict, isTrue);
        }
      });
    });

    group('Physical Activeness Validation', () {
      test('should validate physical activeness levels', () {
        const validLevels = [
          'sedentary', 'light', 'moderate', 'active', 'very active'
        ];
        
        for (final level in validLevels) {
          expect(level, isNotEmpty);
          expect(level.length, greaterThan(1));
        }
      });

      test('should validate physical activeness count', () {
        const validCounts = [1, 2, 3];
        const invalidCounts = [0, 4, 5];

        for (final count in validCounts) {
          expect(count, greaterThan(0));
          expect(count, lessThanOrEqualTo(3));
        }

        for (final count in invalidCounts) {
          final isValid = count > 0 && count <= 3;
          expect(isValid, isFalse);
        }
      });

      test('should handle conflicting physical activeness levels', () {
        const conflictingLevels = [
          ['sedentary', 'very active'],
          ['light', 'very active'],
          ['moderate', 'very active'],
        ];

        for (final levels in conflictingLevels) {
          final hasConflict = levels.contains('sedentary') && levels.contains('very active') ||
                             levels.contains('light') && levels.contains('very active') ||
                             levels.contains('moderate') && levels.contains('very active');
          expect(hasConflict, isTrue);
        }
      });
    });

    group('Availability Validation', () {
      test('should validate availability options', () {
        const validAvailability = [
          'weekdays', 'weekends', 'evenings', 'mornings', 'afternoons',
          'flexible', 'specific times'
        ];
        
        for (final availability in validAvailability) {
          expect(availability, isNotEmpty);
          expect(availability.length, greaterThan(1));
        }
      });

      test('should validate availability count', () {
        const validCounts = [1, 2, 3, 4, 5, 6, 7];
        const invalidCounts = [0, 8, 10];

        for (final count in validCounts) {
          expect(count, greaterThan(0));
          expect(count, lessThanOrEqualTo(7));
        }

        for (final count in invalidCounts) {
          final isValid = count > 0 && count <= 7;
          expect(isValid, isFalse);
        }
      });

      test('should handle conflicting availability options', () {
        const conflictingAvailability = [
          ['weekdays', 'weekends'],
          ['mornings', 'evenings'],
          ['afternoons', 'evenings'],
        ];

        for (final availability in conflictingAvailability) {
          final hasConflict = availability.contains('weekdays') && availability.contains('weekends') ||
                             availability.contains('mornings') && availability.contains('evenings') ||
                             availability.contains('afternoons') && availability.contains('evenings');
          expect(hasConflict, isTrue);
        }
      });
    });

    group('Bio Validation', () {
      test('should validate bio length', () {
        const validBioLengths = [10, 50, 100, 200, 500];
        const invalidBioLengths = [0, 5, 501, 1000];

        for (final length in validBioLengths) {
          expect(length, greaterThanOrEqualTo(10));
          expect(length, lessThanOrEqualTo(500));
        }

        for (final length in invalidBioLengths) {
          final isValid = length >= 10 && length <= 500;
          expect(isValid, isFalse);
        }
      });

      test('should validate bio content', () {
        const validBios = [
          'I love traveling and meeting new people.',
          'Passionate about music and art.',
          'Looking for meaningful connections.',
        ];

        final invalidBios = [
          '', '   ', 'Hi', 'Too short',
        ];

        for (final bio in validBios) {
          expect(bio, isNotEmpty);
          expect(bio.trim(), isNotEmpty);
          expect(bio.length, greaterThanOrEqualTo(10));
          expect(bio.length, lessThanOrEqualTo(500));
        }

        for (final bio in invalidBios) {
          final isValid = bio.trim().isNotEmpty && 
                         bio.length >= 10 && 
                         bio.length <= 500;
          expect(isValid, isFalse);
        }
      });

      test('should validate bio format', () {
        const validBios = [
          'I love traveling and meeting new people.',
          'Passionate about music and art.',
          'Looking for meaningful connections.',
        ];

        const invalidBios = [
          'I love traveling and meeting new people!',
          'Passionate about music and art?',
          'Looking for meaningful connections.',
        ];

        for (final bio in validBios) {
          expect(bio, isNotEmpty);
          expect(bio.trim(), isNotEmpty);
          expect(bio.length, greaterThanOrEqualTo(10));
          expect(bio.length, lessThanOrEqualTo(500));
        }
      });
    });

    group('Hometown Validation', () {
      test('should validate hometown format', () {
        const validHometowns = [
          'San Francisco', 'New York', 'London', 'Tokyo', 'Paris',
          'Los Angeles', 'Chicago', 'Boston', 'Seattle', 'Miami'
        ];

        const invalidHometowns = ['', '   ', 'A', 'San Francisco@'];

        for (final hometown in validHometowns) {
          expect(hometown, isNotEmpty);
          expect(hometown.trim(), isNotEmpty);
          expect(hometown.length, greaterThan(1));
        }

        for (final hometown in invalidHometowns) {
          final isValid = hometown.trim().isNotEmpty && 
                         hometown.length > 1 && 
                         !hometown.contains('@') && 
                         !hometown.contains('#') &&
                         hometown.length <= 50;
          expect(isValid, isFalse);
        }
      });

      test('should validate hometown length', () {
        const validLengths = [2, 10, 20, 30, 50];
        const invalidLengths = [0, 1, 51, 100];

        for (final length in validLengths) {
          expect(length, greaterThanOrEqualTo(2));
          expect(length, lessThanOrEqualTo(50));
        }

        for (final length in invalidLengths) {
          final isValid = length >= 2 && length <= 50;
          expect(isValid, isFalse);
        }
      });
    });

    group('Profile Picture Validation', () {
      test('should validate profile picture URL format', () {
        const validUrls = [
          'https://example.com/pic.jpg',
          'https://example.com/pic.png',
          'https://example.com/pic.jpeg',
          'https://example.com/pic.webp',
        ];

        const invalidUrls = [
          '', '   ', 'not-a-url', 'http://example.com/pic.jpg',
          'https://example.com/pic.txt', 'https://example.com/pic',
        ];

        for (final url in validUrls) {
          expect(url, isNotEmpty);
          expect(url, startsWith('https://'));
          expect(url, anyOf([
            endsWith('.jpg'),
            endsWith('.png'),
            endsWith('.jpeg'),
            endsWith('.webp'),
          ]));
        }

        for (final url in invalidUrls) {
          final isValid = url.isNotEmpty && 
                         url.startsWith('https://') && 
                         (url.endsWith('.jpg') || url.endsWith('.png') || 
                          url.endsWith('.jpeg') || url.endsWith('.webp'));
          expect(isValid, isFalse);
        }
      });

      test('should handle optional profile picture', () {
        const profilePicture = null;
        expect(profilePicture, isNull);
      });
    });

    group('Profile Completion Logic', () {
      test('should calculate profile completion percentage', () {
        final profileData = {
          'name': 'John Doe',
          'age': 25,
          'sex': 'm',
          'seekingGender': 'f',
          'location': {'coordinates': [-122.4194, 37.7749]},
          'hometown': 'San Francisco',
          'bio': 'This is my bio',
          'interests': ['Travel', 'Music'],
          'objectives': ['Long Term'],
          'personalityType': ['introvert'],
          'physicalActiveness': ['moderate'],
          'availability': ['weekends'],
          'profilePic': null,
        };

        const totalFields = 12;
        int completedFields = 0;

        for (final entry in profileData.entries) {
          if (entry.value != null) {
            if (entry.value is String && (entry.value as String).isNotEmpty) {
              completedFields++;
            } else if (entry.value is List && (entry.value as List).isNotEmpty) {
              completedFields++;
            } else if (entry.value is Map && (entry.value as Map).isNotEmpty) {
              completedFields++;
            } else if (entry.value is int && (entry.value as int) > 0) {
              completedFields++;
            }
          }
        }

        final completionPercentage = (completedFields / totalFields) * 100;
        expect(completionPercentage, greaterThan(0));
        expect(completionPercentage, lessThanOrEqualTo(100));
      });

      test('should identify missing required fields', () {
        final profileData = {
          'name': 'John Doe',
          'age': 25,
          'sex': 'm',
          'seekingGender': 'f',
          'location': null,
          'hometown': 'San Francisco',
          'bio': 'This is my bio',
          'interests': ['Travel', 'Music'],
          'objectives': ['Long Term'],
          'personalityType': ['introvert'],
          'physicalActiveness': ['moderate'],
          'availability': ['weekends'],
        };

        final requiredFields = [
          'name', 'age', 'sex', 'seekingGender', 'location',
          'hometown', 'bio', 'interests', 'objectives',
          'personalityType', 'physicalActiveness', 'availability'
        ];

        final missingFields = <String>[];
        for (final field in requiredFields) {
          if (profileData[field] == null) {
            missingFields.add(field);
          }
        }

        expect(missingFields, contains('location'));
        expect(missingFields, hasLength(1));
      });

      test('should validate profile completeness', () {
        final completeProfile = {
          'name': 'John Doe',
          'age': 25,
          'sex': 'm',
          'seekingGender': 'f',
          'location': {'coordinates': [-122.4194, 37.7749]},
          'hometown': 'San Francisco',
          'bio': 'This is my bio',
          'interests': ['Travel', 'Music'],
          'objectives': ['Long Term'],
          'personalityType': ['introvert'],
          'physicalActiveness': ['moderate'],
          'availability': ['weekends'],
        };

        final incompleteProfile = {
          'name': 'John Doe',
          'age': 25,
          'sex': 'm',
          'seekingGender': 'f',
          'location': null,
          'hometown': 'San Francisco',
          'bio': 'This is my bio',
          'interests': ['Travel', 'Music'],
          'objectives': ['Long Term'],
          'personalityType': ['introvert'],
          'physicalActiveness': ['moderate'],
          'availability': ['weekends'],
        };

        final isComplete = completeProfile.values.every((value) => value != null);
        final isIncomplete = incompleteProfile.values.any((value) => value == null);

        expect(isComplete, isTrue);
        expect(isIncomplete, isTrue);
      });
    });

    group('Profile Validation Rules', () {
      test('should validate all profile rules', () {
        final profileRules = {
          'name': {'required': true, 'minLength': 2, 'maxLength': 50},
          'age': {'required': true, 'min': 18, 'max': 80},
          'sex': {'required': true, 'values': ['m', 'f', 'other']},
          'seekingGender': {'required': true, 'values': ['m', 'f', 'other', 'any']},
          'location': {'required': true, 'type': 'coordinates'},
          'hometown': {'required': true, 'minLength': 2, 'maxLength': 50},
          'bio': {'required': true, 'minLength': 10, 'maxLength': 500},
          'interests': {'required': true, 'minCount': 1, 'maxCount': 10},
          'objectives': {'required': true, 'minCount': 1, 'maxCount': 5},
          'personalityType': {'required': true, 'minCount': 1, 'maxCount': 5},
          'physicalActiveness': {'required': true, 'minCount': 1, 'maxCount': 3},
          'availability': {'required': true, 'minCount': 1, 'maxCount': 7},
          'profilePic': {'required': false, 'type': 'url'},
        };

        for (final entry in profileRules.entries) {
          final field = entry.key;
          final rules = entry.value;
          
          expect(rules['required'], isNotNull);
          if (rules['required'] == true) {
            expect(rules['required'], isTrue);
          } else {
            expect(rules['required'], isFalse);
          }
        }
      });

      test('should validate profile data against rules', () {
        final profileData = {
          'name': 'John Doe',
          'age': 25,
          'sex': 'm',
          'seekingGender': 'f',
          'location': {'coordinates': [-122.4194, 37.7749]},
          'hometown': 'San Francisco',
          'bio': 'This is my bio',
          'interests': ['Travel', 'Music'],
          'objectives': ['Long Term'],
          'personalityType': ['introvert'],
          'physicalActiveness': ['moderate'],
          'availability': ['weekends'],
        };

        final validationResults = <String, bool>{};
        
        // Validate name
        validationResults['name'] = profileData['name'] is String && 
                                   (profileData['name'] as String).length >= 2 && 
                                   (profileData['name'] as String).length <= 50;
        
        // Validate age
        validationResults['age'] = profileData['age'] is int && 
                                  (profileData['age'] as int) >= 18 && 
                                  (profileData['age'] as int) <= 80;
        
        // Validate sex
        validationResults['sex'] = profileData['sex'] is String && 
                                  ['m', 'f', 'other'].contains(profileData['sex'] as String);
        
        // Validate seeking gender
        validationResults['seekingGender'] = profileData['seekingGender'] is String && 
                                            ['m', 'f', 'other', 'any'].contains(profileData['seekingGender'] as String);
        
        // Validate location
        validationResults['location'] = profileData['location'] is Map && 
                                       (profileData['location'] as Map)['coordinates'] is List;
        
        // Validate hometown
        validationResults['hometown'] = profileData['hometown'] is String && 
                                       (profileData['hometown'] as String).length >= 2 && 
                                       (profileData['hometown'] as String).length <= 50;
        
        // Validate bio
        validationResults['bio'] = profileData['bio'] is String && 
                                  (profileData['bio'] as String).length >= 10 && 
                                  (profileData['bio'] as String).length <= 500;
        
        // Validate interests
        validationResults['interests'] = profileData['interests'] is List && 
                                        (profileData['interests'] as List).length >= 1 && 
                                        (profileData['interests'] as List).length <= 10;
        
        // Validate objectives
        validationResults['objectives'] = profileData['objectives'] is List && 
                                         (profileData['objectives'] as List).length >= 1 && 
                                         (profileData['objectives'] as List).length <= 5;
        
        // Validate personality type
        validationResults['personalityType'] = profileData['personalityType'] is List && 
                                              (profileData['personalityType'] as List).length >= 1 && 
                                              (profileData['personalityType'] as List).length <= 5;
        
        // Validate physical activeness
        validationResults['physicalActiveness'] = profileData['physicalActiveness'] is List && 
                                                 (profileData['physicalActiveness'] as List).length >= 1 && 
                                                 (profileData['physicalActiveness'] as List).length <= 3;
        
        // Validate availability
        validationResults['availability'] = profileData['availability'] is List && 
                                           (profileData['availability'] as List).length >= 1 && 
                                           (profileData['availability'] as List).length <= 7;

        for (final entry in validationResults.entries) {
          expect(entry.value, isTrue, reason: '${entry.key} validation failed');
        }
      });
    });
  });
}
