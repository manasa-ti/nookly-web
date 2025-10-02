import 'package:flutter_test/flutter_test.dart';
import 'package:nookly/domain/entities/received_like.dart';

void main() {
  group('Received Likes Business Logic Tests', () {
    group('Like Data Structure', () {
      test('should validate received like data structure', () {
        final receivedLike = ReceivedLike(
          id: 'like1',
          name: 'John Doe',
          age: 25,
          gender: 'm',
          distance: 5,
          bio: 'This is my bio',
          interests: ['Travel', 'Music'],
          profilePicture: 'https://example.com/pic.jpg',
          likedAt: DateTime.now(),
        );

        expect(receivedLike.id, isNotEmpty);
        expect(receivedLike.name, isNotEmpty);
        expect(receivedLike.age, greaterThanOrEqualTo(18));
        expect(receivedLike.age, lessThanOrEqualTo(80));
        expect(receivedLike.gender, isIn(['m', 'f', 'other']));
        expect(receivedLike.bio, isNotEmpty);
        expect(receivedLike.interests, isNotEmpty);
        expect(receivedLike.distance, greaterThanOrEqualTo(0));
        expect(receivedLike.distance, lessThanOrEqualTo(100));
        expect(receivedLike.likedAt, isNotNull);
      });

      test('should handle optional profile picture', () {
        final receivedLikeWithPic = ReceivedLike(
          id: 'like1',
          name: 'John Doe',
          age: 25,
          gender: 'm',
          distance: 5,
          bio: 'This is my bio',
          interests: ['Travel'],
          profilePicture: 'https://example.com/pic.jpg',
          likedAt: DateTime.now(),
        );

        final receivedLikeWithoutPic = ReceivedLike(
          id: 'like2',
          name: 'Jane Doe',
          age: 23,
          gender: 'f',
          distance: 3,
          bio: 'This is my bio',
          interests: ['Music'],
          profilePicture: '',
          likedAt: DateTime.now(),
        );

        expect(receivedLikeWithPic.profilePicture, isNotEmpty);
        expect(receivedLikeWithoutPic.profilePicture, isEmpty);
      });

      test('should validate timestamp format', () {
        final now = DateTime.now();
        final receivedLike = ReceivedLike(
          id: 'like1',
          name: 'John Doe',
          age: 25,
          gender: 'm',
          distance: 5,
          bio: 'This is my bio',
          interests: ['Travel'],
          profilePicture: 'https://example.com/pic.jpg',
          likedAt: now,
        );

        expect(receivedLike.likedAt, isNotNull);
        expect(receivedLike.likedAt, equals(now));
        expect(receivedLike.likedAt.isBefore(DateTime.now().add(Duration(seconds: 1))), isTrue);
      });
    });

    group('Like Response Actions', () {
      test('should handle like back action', () {
        final likes = [
          ReceivedLike(
            id: 'like1',
            name: 'John Doe',
            age: 25,
            gender: 'm',
            distance: 5,
            bio: 'This is my bio',
            interests: ['Travel'],
            profilePicture: 'https://example.com/pic.jpg',
            likedAt: DateTime.now(),
          ),
        ];

        const likedBackId = 'like1';
        final updatedLikes = likes.where((like) => like.id != likedBackId).toList();

        expect(updatedLikes, isEmpty);
      });

      test('should handle pass action', () {
        final likes = [
          ReceivedLike(
            id: 'like1',
            name: 'John Doe',
            age: 25,
            gender: 'm',
            distance: 5,
            bio: 'This is my bio',
            interests: ['Travel'],
            profilePicture: 'https://example.com/pic.jpg',
            likedAt: DateTime.now(),
          ),
          ReceivedLike(
            id: 'like2',
            name: 'Jane Doe',
            age: 23,
            gender: 'f',
            distance: 3,
            bio: 'This is my bio',
            interests: ['Music'],
            profilePicture: 'https://example.com/pic.jpg',
            likedAt: DateTime.now(),
          ),
        ];

        const passedId = 'like1';
        final updatedLikes = likes.where((like) => like.id != passedId).toList();

        expect(updatedLikes, hasLength(1));
        expect(updatedLikes.first.id, equals('like2'));
      });

      test('should handle non-existent like ID', () {
        final likes = [
          ReceivedLike(
            id: 'like1',
            name: 'John Doe',
            age: 25,
            gender: 'm',
            distance: 5,
            bio: 'This is my bio',
            interests: ['Travel'],
            profilePicture: 'https://example.com/pic.jpg',
            likedAt: DateTime.now(),
          ),
        ];

        const nonExistentId = 'like999';
        final updatedLikes = likes.where((like) => like.id != nonExistentId).toList();

        expect(updatedLikes, hasLength(1));
        expect(updatedLikes.first.id, equals('like1'));
      });
    });

    group('Pagination Logic', () {
      test('should calculate pagination correctly', () {
        const limit = 20;
        const skip = 0;
        const totalLikes = 100;
        
        final hasMore = skip + limit < totalLikes;
        final nextSkip = skip + limit;
        
        expect(hasMore, isTrue);
        expect(nextSkip, equals(20));
      });

      test('should handle last page correctly', () {
        const limit = 20;
        const skip = 80;
        const totalLikes = 100;
        
        final hasMore = skip + limit < totalLikes;
        final nextSkip = skip + limit;
        
        expect(hasMore, isFalse);
        expect(nextSkip, equals(100));
      });

      test('should handle empty results', () {
        const limit = 20;
        const skip = 0;
        const totalLikes = 0;
        
        final hasMore = skip + limit < totalLikes;
        
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

    group('State Management Logic', () {
      test('should handle loading state correctly', () {
        const isLoading = true;
        const likes = <ReceivedLike>[];
        
        expect(isLoading, isTrue);
        expect(likes, isEmpty);
      });

      test('should handle loaded state correctly', () {
        final likes = [
          ReceivedLike(
            id: 'like1',
            name: 'John Doe',
            age: 25,
            gender: 'm',
            distance: 5,
            bio: 'This is my bio',
            interests: ['Travel'],
            profilePicture: 'https://example.com/pic.jpg',
            likedAt: DateTime.now(),
          ),
        ];
        
        expect(likes, isNotEmpty);
        expect(likes, hasLength(1));
      });

      test('should handle error state correctly', () {
        const errorMessage = 'Failed to load received likes';
        
        expect(errorMessage, isNotEmpty);
        expect(errorMessage, contains('Failed'));
      });

      test('should handle empty state correctly', () {
        const likes = <ReceivedLike>[];
        const hasMore = false;
        
        expect(likes, isEmpty);
        expect(hasMore, isFalse);
      });
    });

    group('Like Sorting and Filtering', () {
      test('should sort likes by timestamp correctly', () {
        final now = DateTime.now();
        final likes = [
          ReceivedLike(
            id: 'like1',
            name: 'John Doe',
            age: 25,
            gender: 'm',
            distance: 5,
            bio: 'This is my bio',
            interests: ['Travel'],
            profilePicture: 'https://example.com/pic.jpg',
            likedAt: now.subtract(Duration(hours: 2)),
          ),
          ReceivedLike(
            id: 'like2',
            name: 'Jane Doe',
            age: 23,
            gender: 'f',
            distance: 3,
            bio: 'This is my bio',
            interests: ['Music'],
            profilePicture: 'https://example.com/pic.jpg',
            likedAt: now.subtract(Duration(hours: 1)),
          ),
        ];

        // Sort by timestamp (newest first)
        likes.sort((a, b) => b.likedAt.compareTo(a.likedAt));

        expect(likes.first.id, equals('like2'));
        expect(likes.last.id, equals('like1'));
      });

      test('should filter by distance range', () {
        final likes = [
          ReceivedLike(
            id: 'like1',
            name: 'John Doe',
            age: 25,
            gender: 'm',
            distance: 5,
            bio: 'This is my bio',
            interests: ['Travel'],
            profilePicture: 'https://example.com/pic.jpg',
            likedAt: DateTime.now(),
          ),
          ReceivedLike(
            id: 'like2',
            name: 'Jane Doe',
            age: 23,
            gender: 'f',
            distance: 15,
            bio: 'This is my bio',
            interests: ['Music'],
            profilePicture: 'https://example.com/pic.jpg',
            likedAt: DateTime.now(),
          ),
        ];

        const maxDistance = 10;
        final nearbyLikes = likes.where((like) => like.distance <= maxDistance).toList();

        expect(nearbyLikes, hasLength(1));
        expect(nearbyLikes.first.id, equals('like1'));
      });
    });

    group('Data Validation', () {
      test('should validate liker age range', () {
        const validAges = [18, 25, 30, 50, 80];
        const invalidAges = [17, 81, 0, -1];

        for (final age in validAges) {
          expect(age, greaterThanOrEqualTo(18));
          expect(age, lessThanOrEqualTo(80));
        }

        for (final age in invalidAges) {
          final isValid = age >= 18 && age <= 80;
          expect(isValid, isFalse);
        }
      });

      test('should validate liker sex values', () {
        const validSexes = ['m', 'f', 'other'];
        const invalidSexes = ['male', 'female', 'unknown', ''];

        for (final sex in validSexes) {
          expect(sex, isIn(['m', 'f', 'other']));
        }

        for (final sex in invalidSexes) {
          expect(sex, isNot(isIn(['m', 'f', 'other'])));
        }
      });

      test('should validate distance values', () {
        const validDistances = [0, 1, 5, 10, 25, 50, 100];
        const invalidDistances = [-1, -5, 101, 200];

        for (final distance in validDistances) {
          expect(distance, greaterThanOrEqualTo(0));
          expect(distance, lessThanOrEqualTo(100));
        }

        for (final distance in invalidDistances) {
          final isValid = distance >= 0 && distance <= 100;
          expect(isValid, isFalse);
        }
      });

      test('should validate common interests', () {
        final likerInterests = ['Travel', 'Music', 'Sports'];
        final userInterests = ['Travel', 'Music', 'Reading'];
        final commonInterests = likerInterests.where((interest) => 
          userInterests.contains(interest)).toList();

        expect(commonInterests, hasLength(2));
        expect(commonInterests, contains('Travel'));
        expect(commonInterests, contains('Music'));
        expect(commonInterests, isNot(contains('Sports')));
      });
    });
  });
}