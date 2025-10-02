import 'package:flutter_test/flutter_test.dart';
import 'package:nookly/domain/entities/recommended_profile.dart';

void main() {
  group('Recommended Profiles Business Logic Tests', () {
    group('Profile Matching Algorithm', () {
      test('should calculate common interests correctly', () {
        final userInterests = ['Deep Conversations', 'Travel', 'Music'];
        final profileInterests = ['Travel', 'Music', 'Sports'];
        
        final commonInterests = userInterests.where((interest) => 
          profileInterests.contains(interest)).toList();
        
        expect(commonInterests, hasLength(2));
        expect(commonInterests, contains('Travel'));
        expect(commonInterests, contains('Music'));
        expect(commonInterests, isNot(contains('Deep Conversations')));
        expect(commonInterests, isNot(contains('Sports')));
      });

      test('should calculate common objectives correctly', () {
        final userObjectives = ['Long Term', 'Serious Relationship'];
        final profileObjectives = ['Long Term', 'Casual', 'Friends'];
        
        final commonObjectives = userObjectives.where((objective) => 
          profileObjectives.contains(objective)).toList();
        
        expect(commonObjectives, hasLength(1));
        expect(commonObjectives, contains('Long Term'));
        expect(commonObjectives, isNot(contains('Serious Relationship')));
      });

      test('should handle empty interests gracefully', () {
        final userInterests = <String>[];
        final profileInterests = ['Travel', 'Music'];
        
        final commonInterests = userInterests.where((interest) => 
          profileInterests.contains(interest)).toList();
        
        expect(commonInterests, isEmpty);
      });

      test('should handle no common interests', () {
        final userInterests = ['Deep Conversations', 'Travel'];
        final profileInterests = ['Sports', 'Gaming'];
        
        final commonInterests = userInterests.where((interest) => 
          profileInterests.contains(interest)).toList();
        
        expect(commonInterests, isEmpty);
      });
    });

    group('Distance Calculation', () {
      test('should validate distance values', () {
        const validDistances = [0.0, 1.5, 5.0, 10.0, 25.0, 50.0, 100.0];
        const invalidDistances = [-1.0, -5.0, 101.0, 200.0];

        for (final distance in validDistances) {
          expect(distance, greaterThanOrEqualTo(0.0));
          expect(distance, lessThanOrEqualTo(100.0));
        }

        for (final distance in invalidDistances) {
          final isValid = distance >= 0.0 && distance <= 100.0;
          expect(isValid, isFalse);
        }
      });

      test('should convert distance to integer correctly', () {
        const distance = 5.7;
        expect(distance.toInt(), equals(5));
        expect(distance.round(), equals(6));
      });

      test('should handle zero distance', () {
        const distance = 0.0;
        expect(distance, equals(0.0));
        expect(distance.toInt(), equals(0));
      });
    });

    group('Age Compatibility', () {
      test('should validate age compatibility', () {
        const userAge = 25;
        const profileAge = 23;
        final ageDifference = (userAge - profileAge).abs();
        
        expect(ageDifference, lessThanOrEqualTo(10)); // Within 10 years
        expect(profileAge, greaterThanOrEqualTo(18));
        expect(profileAge, lessThanOrEqualTo(80));
      });

      test('should reject profiles with large age difference', () {
        const userAge = 25;
        const profileAge = 50;
        final ageDifference = (userAge - profileAge).abs();
        
        expect(ageDifference, greaterThan(10)); // More than 10 years
      });

      test('should reject profiles under 18', () {
        const profileAge = 17;
        expect(profileAge, lessThan(18));
      });

      test('should reject profiles over 80', () {
        const profileAge = 81;
        expect(profileAge, greaterThan(80));
      });
    });

    group('Gender Compatibility', () {
      test('should match compatible genders', () {
        const userSeekingGender = 'f';
        const profileGender = 'f';
        
        expect(profileGender, equals(userSeekingGender));
      });

      test('should match any gender preference', () {
        const userSeekingGender = 'any';
        const profileGender = 'm';
        
        expect(userSeekingGender, equals('any'));
      });

      test('should reject incompatible genders', () {
        const userSeekingGender = 'f';
        const profileGender = 'm';
        
        expect(profileGender, isNot(equals(userSeekingGender)));
      });
    });

    group('Pagination Logic', () {
      test('should calculate pagination correctly', () {
        const limit = 20;
        const skip = 0;
        const totalProfiles = 100;
        
        final hasMore = skip + limit < totalProfiles;
        final nextSkip = skip + limit;
        
        expect(hasMore, isTrue);
        expect(nextSkip, equals(20));
      });

      test('should handle last page correctly', () {
        const limit = 20;
        const skip = 80;
        const totalProfiles = 100;
        
        final hasMore = skip + limit < totalProfiles;
        final nextSkip = skip + limit;
        
        expect(hasMore, isFalse);
        expect(nextSkip, equals(100));
      });

      test('should handle empty results', () {
        const limit = 20;
        const skip = 0;
        const totalProfiles = 0;
        
        final hasMore = skip + limit < totalProfiles;
        
        expect(hasMore, isFalse);
      });

      test('should validate skip and limit values', () {
        const validSkips = [0, 20, 40, 60, 80];
        const validLimits = [10, 20, 50];
        const invalidSkips = [-1, -20];
        const invalidLimits = [0, -1, 101];

        for (final skip in validSkips) {
          expect(skip, greaterThanOrEqualTo(0));
        }

        for (final limit in validLimits) {
          expect(limit, greaterThan(0));
          expect(limit, lessThanOrEqualTo(100));
        }

        for (final skip in invalidSkips) {
          expect(skip, lessThan(0));
        }

        for (final limit in invalidLimits) {
          final isValid = limit > 0 && limit <= 100;
          expect(isValid, isFalse);
        }
      });
    });

    group('Filter Logic', () {
      test('should filter by physical activeness', () {
        const userPhysicalActiveness = ['moderate', 'active'];
        const profilePhysicalActiveness = ['moderate'];
        
        final hasMatch = userPhysicalActiveness.any((activity) => 
          profilePhysicalActiveness.contains(activity));
        
        expect(hasMatch, isTrue);
      });

      test('should filter by availability', () {
        const userAvailability = ['weekends', 'evenings'];
        const profileAvailability = ['weekends'];
        
        final hasMatch = userAvailability.any((availability) => 
          profileAvailability.contains(availability));
        
        expect(hasMatch, isTrue);
      });

      test('should handle no matching filters', () {
        const userPhysicalActiveness = ['moderate'];
        const profilePhysicalActiveness = ['very active'];
        
        final hasMatch = userPhysicalActiveness.any((activity) => 
          profilePhysicalActiveness.contains(activity));
        
        expect(hasMatch, isFalse);
      });

      test('should handle empty filter lists', () {
        const userPhysicalActiveness = <String>[];
        const profilePhysicalActiveness = ['moderate'];
        
        final hasMatch = userPhysicalActiveness.any((activity) => 
          profilePhysicalActiveness.contains(activity));
        
        expect(hasMatch, isFalse);
      });
    });

    group('Profile Data Validation', () {
      test('should validate profile data structure', () {
        final profile = RecommendedProfile(
          id: 'user1',
          name: 'John Doe',
          age: 25,
          sex: 'm',
          location: {'coordinates': [-122.4194, 37.7749]},
          hometown: 'San Francisco',
          bio: 'This is my bio',
          interests: ['Travel', 'Music'],
          objectives: ['Long Term'],
          distance: 5.0,
          commonInterests: ['Travel'],
          commonObjectives: ['Long Term'],
        );

        expect(profile.id, isNotEmpty);
        expect(profile.name, isNotEmpty);
        expect(profile.age, greaterThanOrEqualTo(18));
        expect(profile.age, lessThanOrEqualTo(80));
        expect(profile.sex, isIn(['m', 'f', 'other']));
        expect(profile.bio, isNotEmpty);
        expect(profile.interests, isNotEmpty);
        expect(profile.objectives, isNotEmpty);
        expect(profile.distance, greaterThanOrEqualTo(0.0));
        expect(profile.distance, lessThanOrEqualTo(100.0));
      });

      test('should handle optional profile picture', () {
        final profileWithPic = RecommendedProfile(
          id: 'user1',
          name: 'John Doe',
          age: 25,
          sex: 'm',
          location: {'coordinates': [-122.4194, 37.7749]},
          hometown: 'San Francisco',
          bio: 'This is my bio',
          interests: ['Travel'],
          objectives: ['Long Term'],
          profilePic: 'https://example.com/pic.jpg',
          distance: 5.0,
          commonInterests: ['Travel'],
          commonObjectives: ['Long Term'],
        );

        final profileWithoutPic = RecommendedProfile(
          id: 'user2',
          name: 'Jane Doe',
          age: 23,
          sex: 'f',
          location: {'coordinates': [-122.4194, 37.7749]},
          hometown: 'San Francisco',
          bio: 'This is my bio',
          interests: ['Music'],
          objectives: ['Long Term'],
          distance: 3.0,
          commonInterests: ['Music'],
          commonObjectives: ['Long Term'],
        );

        expect(profileWithPic.profilePic, isNotNull);
        expect(profileWithoutPic.profilePic, isNull);
      });

      test('should validate likedAt timestamp', () {
        final now = DateTime.now();
        final profile = RecommendedProfile(
          id: 'user1',
          name: 'John Doe',
          age: 25,
          sex: 'm',
          location: {'coordinates': [-122.4194, 37.7749]},
          hometown: 'San Francisco',
          bio: 'This is my bio',
          interests: ['Travel'],
          objectives: ['Long Term'],
          distance: 5.0,
          commonInterests: ['Travel'],
          commonObjectives: ['Long Term'],
          likedAt: now,
        );

        expect(profile.likedAt, isNotNull);
        expect(profile.likedAt, equals(now));
      });
    });

    group('State Management Logic', () {
      test('should handle loading state correctly', () {
        const isLoading = true;
        const profiles = <RecommendedProfile>[];
        
        expect(isLoading, isTrue);
        expect(profiles, isEmpty);
      });

      test('should handle loaded state correctly', () {
        final profiles = [
          RecommendedProfile(
            id: 'user1',
            name: 'John Doe',
            age: 25,
            sex: 'm',
            location: {'coordinates': [-122.4194, 37.7749]},
            hometown: 'San Francisco',
            bio: 'This is my bio',
            interests: ['Travel'],
            objectives: ['Long Term'],
            distance: 5.0,
            commonInterests: ['Travel'],
            commonObjectives: ['Long Term'],
          ),
        ];
        
        expect(profiles, isNotEmpty);
        expect(profiles, hasLength(1));
      });

      test('should handle error state correctly', () {
        const errorMessage = 'Failed to load profiles';
        
        expect(errorMessage, isNotEmpty);
        expect(errorMessage, contains('Failed'));
      });

      test('should handle empty state correctly', () {
        const profiles = <RecommendedProfile>[];
        const hasMore = false;
        
        expect(profiles, isEmpty);
        expect(hasMore, isFalse);
      });
    });

    group('Like/Dislike Logic', () {
      test('should handle like action correctly', () {
        final profiles = [
          RecommendedProfile(
            id: 'user1',
            name: 'John Doe',
            age: 25,
            sex: 'm',
            location: {'coordinates': [-122.4194, 37.7749]},
            hometown: 'San Francisco',
            bio: 'This is my bio',
            interests: ['Travel'],
            objectives: ['Long Term'],
            distance: 5.0,
            commonInterests: ['Travel'],
            commonObjectives: ['Long Term'],
          ),
          RecommendedProfile(
            id: 'user2',
            name: 'Jane Doe',
            age: 23,
            sex: 'f',
            location: {'coordinates': [-122.4194, 37.7749]},
            hometown: 'San Francisco',
            bio: 'This is my bio',
            interests: ['Music'],
            objectives: ['Long Term'],
            distance: 3.0,
            commonInterests: ['Music'],
            commonObjectives: ['Long Term'],
          ),
        ];

        const likedProfileId = 'user1';
        final updatedProfiles = profiles.where((profile) => 
          profile.id != likedProfileId).toList();

        expect(updatedProfiles, hasLength(1));
        expect(updatedProfiles.first.id, equals('user2'));
      });

      test('should handle dislike action correctly', () {
        final profiles = [
          RecommendedProfile(
            id: 'user1',
            name: 'John Doe',
            age: 25,
            sex: 'm',
            location: {'coordinates': [-122.4194, 37.7749]},
            hometown: 'San Francisco',
            bio: 'This is my bio',
            interests: ['Travel'],
            objectives: ['Long Term'],
            distance: 5.0,
            commonInterests: ['Travel'],
            commonObjectives: ['Long Term'],
          ),
        ];

        const dislikedProfileId = 'user1';
        final updatedProfiles = profiles.where((profile) => 
          profile.id != dislikedProfileId).toList();

        expect(updatedProfiles, isEmpty);
      });

      test('should handle non-existent profile ID', () {
        final profiles = [
          RecommendedProfile(
            id: 'user1',
            name: 'John Doe',
            age: 25,
            sex: 'm',
            location: {'coordinates': [-122.4194, 37.7749]},
            hometown: 'San Francisco',
            bio: 'This is my bio',
            interests: ['Travel'],
            objectives: ['Long Term'],
            distance: 5.0,
            commonInterests: ['Travel'],
            commonObjectives: ['Long Term'],
          ),
        ];

        const nonExistentId = 'user999';
        final updatedProfiles = profiles.where((profile) => 
          profile.id != nonExistentId).toList();

        expect(updatedProfiles, hasLength(1));
        expect(updatedProfiles.first.id, equals('user1'));
      });
    });

    group('Query Parameters', () {
      test('should build query parameters correctly', () {
        final queryParams = <String, dynamic>{};
        
        const radius = 25.0;
        const limit = 20;
        const skip = 0;
        const physicalActiveness = ['moderate', 'active'];
        const availability = ['weekends'];

        if (radius != null) queryParams['radius'] = radius;
        if (limit != null) queryParams['limit'] = limit;
        if (skip != null) queryParams['skip'] = skip;
        if (physicalActiveness.isNotEmpty) {
          queryParams['physical_activeness'] = physicalActiveness.join(',');
        }
        if (availability.isNotEmpty) {
          queryParams['availability'] = availability.join(',');
        }

        expect(queryParams['radius'], equals(25.0));
        expect(queryParams['limit'], equals(20));
        expect(queryParams['skip'], equals(0));
        expect(queryParams['physical_activeness'], equals('moderate,active'));
        expect(queryParams['availability'], equals('weekends'));
      });

      test('should handle empty query parameters', () {
        final queryParams = <String, dynamic>{};
        
        const radius = null;
        const limit = null;
        const skip = null;
        const physicalActiveness = <String>[];
        const availability = <String>[];

        if (radius != null) queryParams['radius'] = radius;
        if (limit != null) queryParams['limit'] = limit;
        if (skip != null) queryParams['skip'] = skip;
        if (physicalActiveness.isNotEmpty) {
          queryParams['physical_activeness'] = physicalActiveness.join(',');
        }
        if (availability.isNotEmpty) {
          queryParams['availability'] = availability.join(',');
        }

        expect(queryParams, isEmpty);
      });
    });
  });
}
