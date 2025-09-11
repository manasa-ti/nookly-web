import 'package:dio/dio.dart';
import 'package:nookly/core/network/network_service.dart'; // Use NetworkService
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/core/services/api_cache_service.dart';
import 'package:nookly/domain/entities/matched_profile.dart';
import 'package:nookly/domain/repositories/matches_repository.dart';

class MatchesRepositoryImpl implements MatchesRepository {
  // No need for _dio, _authRepository, or _baseUrl here

  MatchesRepositoryImpl(); // Constructor can be empty or take NetworkService if preferred for testing

  @override
  Future<List<MatchedProfile>> getMatchedProfiles() async {
    try {
      AppLogger.info('🔵 MatchesRepository: Starting getMatchedProfiles API call');
      final apiStopwatch = Stopwatch()..start();
      
      // Check cache first
      const cacheKey = 'matched_profiles';
      final apiCacheService = ApiCacheService();
      final cachedProfiles = apiCacheService.getCachedResponse<List<MatchedProfile>>(cacheKey);
      if (cachedProfiles != null) {
        AppLogger.info('🔵 MatchesRepository: Returning cached matches (${cachedProfiles.length} items)');
        return cachedProfiles;
      }
      
      AppLogger.info('🔵 MatchesRepository: Making HTTP GET to /users/matches');
      final httpStopwatch = Stopwatch()..start();
      
      // NetworkService interceptor handles token and base URL
      final response = await NetworkService.dio.get('/users/matches'); // Endpoint path
      
      httpStopwatch.stop();
      AppLogger.info('🔵 MatchesRepository: HTTP response received in ${httpStopwatch.elapsedMilliseconds}ms');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> jsonData = response.data as List<dynamic>;
        final profiles = jsonData.map((json) => MatchedProfile.fromJson(json as Map<String, dynamic>)).toList();
        
        apiStopwatch.stop();
        AppLogger.info('🔵 MatchesRepository: getMatchedProfiles completed in ${apiStopwatch.elapsedMilliseconds}ms, found ${profiles.length} matches');
        
        // Cache the result
        apiCacheService.cacheResponse(cacheKey, profiles, duration: const Duration(minutes: 5));
        
        return profiles;
      } else {
        throw Exception('Failed to load matched profiles: Status ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioError fetching matched profiles: ${e.response?.data ?? e.message}');
      throw Exception('Failed to load matched profiles: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('Error fetching matched profiles: $e');
      throw Exception('Failed to load matched profiles: An unexpected error occurred.');
    }
  }
} 