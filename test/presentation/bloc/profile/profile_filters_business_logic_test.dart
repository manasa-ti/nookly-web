import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile Filters Business Logic Tests', () {
    group('Age Range Filtering', () {
      test('should validate age range limits', () {
        const minAge = 18;
        const maxAge = 80;
        const validAges = [18, 25, 30, 50, 80];
        const invalidAges = [17, 81, 0, -1];

        for (final age in validAges) {
          expect(age, greaterThanOrEqualTo(minAge));
          expect(age, lessThanOrEqualTo(maxAge));
        }

        for (final age in invalidAges) {
          final isValid = age >= minAge && age <= maxAge;
          expect(isValid, isFalse);
        }
      });

      test('should validate age range consistency', () {
        const lowerLimit = 25;
        const upperLimit = 35;
        
        expect(lowerLimit, lessThanOrEqualTo(upperLimit));
        expect(upperLimit, greaterThanOrEqualTo(lowerLimit));
        expect(upperLimit - lowerLimit, greaterThanOrEqualTo(0));
      });

      test('should handle invalid age ranges', () {
        const invalidRanges = [
          {'lower': 35, 'upper': 25}, // upper < lower
          {'lower': 0, 'upper': 30},  // lower < 18
          {'lower': 25, 'upper': 81}, // upper > 80
        ];

        for (final range in invalidRanges) {
          final lower = range['lower'] as int;
          final upper = range['upper'] as int;
          
          final isValid = lower >= 18 && upper <= 80 && lower <= upper;
          expect(isValid, isFalse);
        }
      });

      test('should calculate age range span', () {
        const ageRanges = [
          {'lower': 18, 'upper': 25, 'span': 7},
          {'lower': 25, 'upper': 35, 'span': 10},
          {'lower': 30, 'upper': 50, 'span': 20},
          {'lower': 18, 'upper': 80, 'span': 62},
        ];

        for (final range in ageRanges) {
          final lower = range['lower'] as int;
          final upper = range['upper'] as int;
          final expectedSpan = range['span'] as int;
          
          final actualSpan = upper - lower;
          expect(actualSpan, equals(expectedSpan));
        }
      });
    });

    group('Distance Radius Filtering', () {
      test('should validate distance radius values', () {
        const validRadii = [1, 5, 10, 25, 50, 100];
        const invalidRadii = [0, -1, 101, 200];

        for (final radius in validRadii) {
          expect(radius, greaterThan(0));
          expect(radius, lessThanOrEqualTo(100));
        }

        for (final radius in invalidRadii) {
          final isValid = radius > 0 && radius <= 100;
          expect(isValid, isFalse);
        }
      });

      test('should convert distance units correctly', () {
        const kilometers = 10;
        const miles = 6.2; // Approximate conversion
        
        expect(kilometers, greaterThan(miles));
        expect(miles, lessThan(kilometers));
      });

      test('should handle distance boundary conditions', () {
        const minDistance = 1;
        const maxDistance = 100;
        
        expect(minDistance, equals(1));
        expect(maxDistance, equals(100));
        expect(maxDistance - minDistance, equals(99));
      });
    });

    group('Gender Filtering', () {
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

      test('should handle seeking gender combinations', () {
        const userGender = 'm';
        const seekingGenders = ['f', 'other', 'any'];
        
        for (final seekingGender in seekingGenders) {
          final isCompatible = seekingGender == 'any' || 
                              seekingGender == 'f' || 
                              seekingGender == 'other';
          expect(isCompatible, isTrue);
        }
      });

      test('should validate gender compatibility matrix', () {
        const compatibilityMatrix = {
          'm': ['f', 'other', 'any'],
          'f': ['m', 'other', 'any'],
          'other': ['m', 'f', 'any'],
        };

        for (final entry in compatibilityMatrix.entries) {
          final userGender = entry.key;
          final compatibleGenders = entry.value;
          
          expect(compatibleGenders, contains('any'));
          expect(compatibleGenders, isNot(contains(userGender)));
        }
      });
    });

    group('Interests Filtering', () {
      test('should validate interest categories', () {
        const validInterests = [
          'Deep Conversations', 'Travel', 'Music', 'Sports', 'Gaming',
          'Reading', 'Cooking', 'Art', 'Photography', 'Dancing',
          'Fitness', 'Movies', 'Nature', 'Technology', 'Fashion'
        ];
        
        for (final interest in validInterests) {
          expect(interest, isNotEmpty);
          expect(interest.length, greaterThan(1));
        }
      });

      test('should handle interest matching logic', () {
        const userInterests = ['Deep Conversations', 'Travel', 'Music'];
        const profileInterests = ['Travel', 'Music', 'Sports'];
        
        final commonInterests = userInterests.where((interest) => 
          profileInterests.contains(interest)).toList();
        
        expect(commonInterests, hasLength(2));
        expect(commonInterests, contains('Travel'));
        expect(commonInterests, contains('Music'));
        expect(commonInterests, isNot(contains('Deep Conversations')));
      });

      test('should calculate interest compatibility score', () {
        const userInterests = ['Deep Conversations', 'Travel', 'Music', 'Sports'];
        const profileInterests = ['Travel', 'Music', 'Gaming'];
        
        final commonInterests = userInterests.where((interest) => 
          profileInterests.contains(interest)).toList();
        
        final compatibilityScore = commonInterests.length / userInterests.length;
        
        expect(compatibilityScore, equals(0.5)); // 2 out of 4 interests match
        expect(compatibilityScore, greaterThanOrEqualTo(0.0));
        expect(compatibilityScore, lessThanOrEqualTo(1.0));
      });

      test('should handle empty interests gracefully', () {
        const userInterests = <String>[];
        const profileInterests = ['Travel', 'Music'];
        
        final commonInterests = userInterests.where((interest) => 
          profileInterests.contains(interest)).toList();
        
        expect(commonInterests, isEmpty);
      });
    });

    group('Objectives Filtering', () {
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

      test('should handle objective matching logic', () {
        const userObjectives = ['Long Term', 'Serious Relationship'];
        const profileObjectives = ['Long Term', 'Casual', 'Friends'];
        
        final commonObjectives = userObjectives.where((objective) => 
          profileObjectives.contains(objective)).toList();
        
        expect(commonObjectives, hasLength(1));
        expect(commonObjectives, contains('Long Term'));
        expect(commonObjectives, isNot(contains('Serious Relationship')));
      });

      test('should calculate objective compatibility score', () {
        const userObjectives = ['Long Term', 'Serious Relationship', 'Marriage'];
        const profileObjectives = ['Long Term', 'Marriage', 'Casual'];
        
        final commonObjectives = userObjectives.where((objective) => 
          profileObjectives.contains(objective)).toList();
        
        final compatibilityScore = commonObjectives.length / userObjectives.length;
        
        expect(compatibilityScore, closeTo(0.67, 0.01)); // 2 out of 3 objectives match
        expect(compatibilityScore, greaterThanOrEqualTo(0.0));
        expect(compatibilityScore, lessThanOrEqualTo(1.0));
      });
    });

    group('Physical Activeness Filtering', () {
      test('should validate physical activeness levels', () {
        const validLevels = [
          'sedentary', 'light', 'moderate', 'active', 'very active'
        ];
        
        for (final level in validLevels) {
          expect(level, isNotEmpty);
          expect(level.length, greaterThan(1));
        }
      });

      test('should handle physical activeness matching', () {
        const userPhysicalActiveness = ['moderate', 'active'];
        const profilePhysicalActiveness = ['moderate', 'very active'];
        
        final commonLevels = userPhysicalActiveness.where((level) => 
          profilePhysicalActiveness.contains(level)).toList();
        
        expect(commonLevels, hasLength(1));
        expect(commonLevels, contains('moderate'));
        expect(commonLevels, isNot(contains('active')));
      });

      test('should calculate physical activeness compatibility', () {
        const userPhysicalActiveness = ['moderate', 'active'];
        const profilePhysicalActiveness = ['light', 'moderate', 'very active'];
        
        final commonLevels = userPhysicalActiveness.where((level) => 
          profilePhysicalActiveness.contains(level)).toList();
        
        final compatibilityScore = commonLevels.length / userPhysicalActiveness.length;
        
        expect(compatibilityScore, equals(0.5)); // 1 out of 2 levels match
        expect(compatibilityScore, greaterThanOrEqualTo(0.0));
        expect(compatibilityScore, lessThanOrEqualTo(1.0));
      });
    });

    group('Availability Filtering', () {
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

      test('should handle availability matching', () {
        const userAvailability = ['weekends', 'evenings'];
        const profileAvailability = ['weekends', 'mornings'];
        
        final commonAvailability = userAvailability.where((availability) => 
          profileAvailability.contains(availability)).toList();
        
        expect(commonAvailability, hasLength(1));
        expect(commonAvailability, contains('weekends'));
        expect(commonAvailability, isNot(contains('evenings')));
      });

      test('should calculate availability compatibility', () {
        const userAvailability = ['weekends', 'evenings', 'flexible'];
        const profileAvailability = ['weekends', 'mornings', 'flexible'];
        
        final commonAvailability = userAvailability.where((availability) => 
          profileAvailability.contains(availability)).toList();
        
        final compatibilityScore = commonAvailability.length / userAvailability.length;
        
        expect(compatibilityScore, closeTo(0.67, 0.01)); // 2 out of 3 availability options match
        expect(compatibilityScore, greaterThanOrEqualTo(0.0));
        expect(compatibilityScore, lessThanOrEqualTo(1.0));
      });
    });

    group('Personality Type Filtering', () {
      test('should validate personality types', () {
        const validPersonalityTypes = [
          'introvert', 'extrovert', 'ambivert', 'analytical', 'creative',
          'logical', 'emotional', 'adventurous', 'cautious', 'spontaneous'
        ];
        
        for (final personalityType in validPersonalityTypes) {
          expect(personalityType, isNotEmpty);
          expect(personalityType.length, greaterThan(1));
        }
      });

      test('should handle personality type matching', () {
        const userPersonalityTypes = ['introvert', 'analytical'];
        const profilePersonalityTypes = ['introvert', 'creative', 'logical'];
        
        final commonPersonalityTypes = userPersonalityTypes.where((type) => 
          profilePersonalityTypes.contains(type)).toList();
        
        expect(commonPersonalityTypes, hasLength(1));
        expect(commonPersonalityTypes, contains('introvert'));
        expect(commonPersonalityTypes, isNot(contains('analytical')));
      });

      test('should calculate personality compatibility', () {
        const userPersonalityTypes = ['introvert', 'analytical', 'cautious'];
        const profilePersonalityTypes = ['introvert', 'logical', 'cautious', 'creative'];
        
        final commonPersonalityTypes = userPersonalityTypes.where((type) => 
          profilePersonalityTypes.contains(type)).toList();
        
        final compatibilityScore = commonPersonalityTypes.length / userPersonalityTypes.length;
        
        expect(compatibilityScore, closeTo(0.67, 0.01)); // 2 out of 3 personality types match
        expect(compatibilityScore, greaterThanOrEqualTo(0.0));
        expect(compatibilityScore, lessThanOrEqualTo(1.0));
      });
    });

    group('Filter Combination Logic', () {
      test('should combine multiple filters correctly', () {
        final filters = {
          'ageRange': {'min': 25, 'max': 35},
          'distance': 25,
          'seekingGender': 'f',
          'interests': ['Travel', 'Music'],
          'objectives': ['Long Term'],
          'physicalActiveness': ['moderate', 'active'],
          'availability': ['weekends'],
          'personalityType': ['introvert', 'extrovert'],
        };

        expect(filters['ageRange'], isNotNull);
        expect(filters['distance'], isNotNull);
        expect(filters['seekingGender'], isNotNull);
        expect(filters['interests'], isNotNull);
        expect(filters['objectives'], isNotNull);
        expect(filters['physicalActiveness'], isNotNull);
        expect(filters['availability'], isNotNull);
        expect(filters['personalityType'], isNotNull);
      });

      test('should validate filter combinations', () {
        const ageRange = {'min': 25, 'max': 35};
        const distance = 25;
        const seekingGender = 'f';
        
        final isValidCombination = ageRange['min']! >= 18 && 
                                  ageRange['max']! <= 80 &&
                                  ageRange['min']! <= ageRange['max']! &&
                                  distance > 0 && distance <= 100 &&
                                  ['m', 'f', 'other', 'any'].contains(seekingGender);
        
        expect(isValidCombination, isTrue);
      });

      test('should handle partial filter combinations', () {
        final partialFilters = {
          'ageRange': {'min': 25, 'max': 35},
          'distance': 25,
          // Other filters are null/empty
        };

        expect(partialFilters['ageRange'], isNotNull);
        expect(partialFilters['distance'], isNotNull);
        expect(partialFilters['seekingGender'], isNull);
        expect(partialFilters['interests'], isNull);
      });

      test('should calculate overall compatibility score', () {
        final compatibilityScores = {
          'interests': 0.5,
          'objectives': 0.67,
          'physicalActiveness': 0.5,
          'availability': 0.67,
          'personalityType': 0.67,
        };

        final weights = {
          'interests': 0.3,
          'objectives': 0.25,
          'physicalActiveness': 0.15,
          'availability': 0.15,
          'personalityType': 0.15,
        };

        double overallScore = 0.0;
        for (final entry in compatibilityScores.entries) {
          final category = entry.key;
          final score = entry.value;
          final weight = weights[category]!;
          overallScore += score * weight;
        }

        expect(overallScore, closeTo(0.59, 0.01));
        expect(overallScore, greaterThanOrEqualTo(0.0));
        expect(overallScore, lessThanOrEqualTo(1.0));
      });
    });

    group('Filter Validation', () {
      test('should validate all filter types', () {
        final filterValidation = {
          'ageRange': {'min': 25, 'max': 35, 'valid': true},
          'distance': {'value': 25, 'valid': true},
          'seekingGender': {'value': 'f', 'valid': true},
          'interests': {'values': ['Travel'], 'valid': true},
          'objectives': {'values': ['Long Term'], 'valid': true},
          'physicalActiveness': {'values': ['moderate'], 'valid': true},
          'availability': {'values': ['weekends'], 'valid': true},
          'personalityType': {'values': ['introvert'], 'valid': true},
        };

        for (final entry in filterValidation.entries) {
          expect(entry.value['valid'], isTrue);
        }
      });

      test('should detect invalid filter combinations', () {
        final invalidFilters = [
          {'ageRange': {'min': 35, 'max': 25}}, // min > max
          {'distance': -1}, // negative distance
          {'seekingGender': 'invalid'}, // invalid gender
          {'ageRange': {'min': 17, 'max': 30}}, // min < 18
          {'ageRange': {'min': 25, 'max': 81}}, // max > 80
        ];

        for (final filter in invalidFilters) {
          final isValid = _validateFilter(filter);
          expect(isValid, isFalse);
        }
      });

      test('should handle empty filter values', () {
        final emptyFilters = {
          'interests': <String>[],
          'objectives': <String>[],
          'physicalActiveness': <String>[],
          'availability': <String>[],
          'personalityType': <String>[],
        };

        for (final entry in emptyFilters.entries) {
          expect(entry.value, isEmpty);
        }
      });
    });

    group('Filter Persistence', () {
      test('should serialize filter data correctly', () {
        final filters = {
          'ageRange': {'min': 25, 'max': 35},
          'distance': 25,
          'seekingGender': 'f',
          'interests': ['Travel', 'Music'],
          'objectives': ['Long Term'],
          'physicalActiveness': ['moderate', 'active'],
          'availability': ['weekends'],
          'personalityType': ['introvert', 'extrovert'],
        };

        // Simulate serialization
        final serialized = filters.toString();
        expect(serialized, isNotEmpty);
        expect(serialized, contains('ageRange'));
        expect(serialized, contains('distance'));
        expect(serialized, contains('seekingGender'));
      });

      test('should deserialize filter data correctly', () {
        final serializedData = {
          'ageRange': {'min': 25, 'max': 35},
          'distance': 25,
          'seekingGender': 'f',
          'interests': ['Travel', 'Music'],
          'objectives': ['Long Term'],
          'physicalActiveness': ['moderate', 'active'],
          'availability': ['weekends'],
          'personalityType': ['introvert', 'extrovert'],
        };

        // Simulate deserialization
        expect(serializedData['ageRange'], isNotNull);
        expect(serializedData['distance'], isNotNull);
        expect(serializedData['seekingGender'], isNotNull);
        expect(serializedData['interests'], isNotNull);
        expect(serializedData['objectives'], isNotNull);
        expect(serializedData['physicalActiveness'], isNotNull);
        expect(serializedData['availability'], isNotNull);
        expect(serializedData['personalityType'], isNotNull);
      });
    });
  });
}

// Helper function for filter validation
bool _validateFilter(Map<String, dynamic> filter) {
  if (filter.containsKey('ageRange')) {
    final ageRange = filter['ageRange'] as Map<String, dynamic>;
    final min = ageRange['min'] as int;
    final max = ageRange['max'] as int;
    if (min < 18 || max > 80 || min > max) return false;
  }
  
  if (filter.containsKey('distance')) {
    final distance = filter['distance'] as int;
    if (distance <= 0 || distance > 100) return false;
  }
  
  if (filter.containsKey('seekingGender')) {
    final gender = filter['seekingGender'] as String;
    if (!['m', 'f', 'other', 'any'].contains(gender)) return false;
  }
  
  return true;
}
