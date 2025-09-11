import 'package:nookly/core/utils/logger.dart';

/// Service for caching API responses to reduce slow API calls
class ApiCacheService {
  static final ApiCacheService _instance = ApiCacheService._internal();
  factory ApiCacheService() => _instance;
  ApiCacheService._internal();

  final Map<String, CacheEntry> _cache = {};
  static const Duration _defaultCacheDuration = Duration(minutes: 2);

  /// Cache an API response
  void cacheResponse(String key, dynamic data, {Duration? duration}) {
    final cacheDuration = duration ?? _defaultCacheDuration;
    _cache[key] = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      duration: cacheDuration,
    );
    AppLogger.info('🔵 ApiCache: Cached response for key: $key (expires in ${cacheDuration.inMinutes} minutes)');
  }

  /// Get cached API response if available and not expired
  T? getCachedResponse<T>(String key) {
    final entry = _cache[key];
    if (entry == null) {
      AppLogger.info('🔵 ApiCache: No cached response for key: $key');
      return null;
    }

    final now = DateTime.now();
    final age = now.difference(entry.timestamp);
    
    if (age > entry.duration) {
      AppLogger.info('🔵 ApiCache: Cached response expired for key: $key (age: ${age.inMinutes} minutes)');
      _cache.remove(key);
      return null;
    }

    AppLogger.info('🔵 ApiCache: Returning cached response for key: $key (age: ${age.inSeconds} seconds)');
    return entry.data as T?;
  }

  /// Check if a cached response exists and is valid
  bool hasValidCache(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    
    final now = DateTime.now();
    final age = now.difference(entry.timestamp);
    return age <= entry.duration;
  }

  /// Invalidate cache for a specific key
  void invalidateCache(String key) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
      AppLogger.info('🔵 ApiCache: Invalidated cache for key: $key');
    }
  }

  /// Clear all cache
  void clearAllCache() {
    _cache.clear();
    AppLogger.info('🔵 ApiCache: Cleared all cache');
  }

  /// Get cache info for debugging
  Map<String, dynamic> getCacheInfo() {
    final now = DateTime.now();
    return {
      'totalEntries': _cache.length,
      'entries': _cache.map((key, entry) {
        final age = now.difference(entry.timestamp);
        return MapEntry(key, {
          'ageInSeconds': age.inSeconds,
          'isValid': age <= entry.duration,
          'expiresInSeconds': entry.duration.inSeconds - age.inSeconds,
        });
      }),
    };
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration duration;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.duration,
  });
}
