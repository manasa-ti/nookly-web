import 'package:flutter_test/flutter_test.dart';
import 'package:nookly/core/services/user_cache_service.dart';
import 'package:nookly/domain/entities/user.dart';

void main() {
  group('UserCacheService', () {
    late UserCacheService cacheService;
    late User testUser;

    setUp(() {
      cacheService = UserCacheService();
      cacheService.invalidateCache(); // Clear any existing cache
      
      testUser = User(
        id: 'test_user_123',
        email: 'test@example.com',
        name: 'Test User',
        age: 25,
        sex: 'male',
        seekingGender: 'female',
        location: {'coordinates': [0.0, 0.0]},
        preferredAgeRange: {'lower_limit': 20, 'upper_limit': 30},
        hometown: 'Test City',
        bio: 'Test bio',
        interests: ['music', 'travel'],
        objectives: ['friendship'],
        profilePic: 'test_pic_url',
        preferredDistanceRadius: 25,
      );
    });

    test('should return null when no user is cached', () {
      final result = cacheService.getCachedUser();
      expect(result, isNull);
    });

    test('should cache and retrieve user data', () {
      // Cache the user
      cacheService.cacheUser(testUser);
      
      // Retrieve the user
      final result = cacheService.getCachedUser();
      
      expect(result, isNotNull);
      expect(result!.id, equals(testUser.id));
      expect(result.name, equals(testUser.name));
      expect(result.email, equals(testUser.email));
    });

    test('should invalidate cache correctly', () {
      // Cache the user
      cacheService.cacheUser(testUser);
      expect(cacheService.getCachedUser(), isNotNull);
      
      // Invalidate cache
      cacheService.invalidateCache();
      expect(cacheService.getCachedUser(), isNull);
    });

    test('should return valid cache info', () {
      // Initially no cache
      var cacheInfo = cacheService.getCacheInfo();
      expect(cacheInfo['hasCachedUser'], isFalse);
      expect(cacheInfo['isValid'], isFalse);
      
      // After caching
      cacheService.cacheUser(testUser);
      cacheInfo = cacheService.getCacheInfo();
      expect(cacheInfo['hasCachedUser'], isTrue);
      expect(cacheInfo['isValid'], isTrue);
      expect(cacheInfo['userId'], equals(testUser.id));
      expect(cacheInfo['userName'], equals(testUser.name));
    });

    test('should return cache age in seconds', () {
      cacheService.cacheUser(testUser);
      
      final age = cacheService.getCacheAgeInSeconds();
      expect(age, isNotNull);
      expect(age, greaterThanOrEqualTo(0));
    });

    test('should handle cache validity correctly', () {
      cacheService.cacheUser(testUser);
      expect(cacheService.isCacheValid(), isTrue);
      
      cacheService.invalidateCache();
      expect(cacheService.isCacheValid(), isFalse);
    });
  });
}
