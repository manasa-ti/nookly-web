import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/core/utils/logger.dart';

/// Singleton service for caching user data to reduce API calls
class UserCacheService {
  static final UserCacheService _instance = UserCacheService._internal();
  factory UserCacheService() => _instance;
  UserCacheService._internal();

  User? _cachedUser;
  DateTime? _cacheTimestamp;
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  /// Get cached user data if available and not expired
  User? getCachedUser() {
    if (_cachedUser == null) {
      AppLogger.info('🔵 UserCache: No cached user data available');
      return null;
    }

    if (_cacheTimestamp == null) {
      AppLogger.info('🔵 UserCache: Cache timestamp is null, invalidating cache');
      _invalidateCache();
      return null;
    }

    final now = DateTime.now();
    final cacheAge = now.difference(_cacheTimestamp!);
    
    if (cacheAge > _cacheValidityDuration) {
      AppLogger.info('🔵 UserCache: Cache expired (age: ${cacheAge.inMinutes} minutes), invalidating');
      _invalidateCache();
      return null;
    }

    AppLogger.info('🔵 UserCache: Returning cached user data (age: ${cacheAge.inSeconds} seconds)');
    return _cachedUser;
  }

  /// Cache user data with current timestamp
  void cacheUser(User user) {
    _cachedUser = user;
    _cacheTimestamp = DateTime.now();
    AppLogger.info('🔵 UserCache: User data cached successfully for user: ${user.id}');
  }

  /// Invalidate the cache (clear cached data)
  void _invalidateCache() {
    _cachedUser = null;
    _cacheTimestamp = null;
    AppLogger.info('🔵 UserCache: Cache invalidated');
  }

  /// Force invalidate the cache (public method for external use)
  void invalidateCache() {
    _invalidateCache();
  }


  /// Check if cache is valid and not expired
  bool isCacheValid() {
    if (_cachedUser == null || _cacheTimestamp == null) {
      return false;
    }

    final now = DateTime.now();
    final cacheAge = now.difference(_cacheTimestamp!);
    return cacheAge <= _cacheValidityDuration;
  }

  /// Get cache age in seconds
  int? getCacheAgeInSeconds() {
    if (_cacheTimestamp == null) {
      return null;
    }
    return DateTime.now().difference(_cacheTimestamp!).inSeconds;
  }

  /// Get cache info for debugging
  Map<String, dynamic> getCacheInfo() {
    return {
      'hasCachedUser': _cachedUser != null,
      'cacheTimestamp': _cacheTimestamp?.toIso8601String(),
      'isValid': isCacheValid(),
      'ageInSeconds': getCacheAgeInSeconds(),
      'userId': _cachedUser?.id,
      'userName': _cachedUser?.name,
    };
  }
}
