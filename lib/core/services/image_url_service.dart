import 'package:dio/dio.dart';
import 'package:hushmate/core/network/network_service.dart';
import 'package:hushmate/domain/repositories/auth_repository.dart';
import 'package:hushmate/core/di/injection_container.dart';
import 'package:hushmate/core/utils/logger.dart';
import 'dart:convert';

class ImageUrlService {
  static final ImageUrlService _instance = ImageUrlService._internal();
  factory ImageUrlService() => _instance;
  ImageUrlService._internal();

  final Map<String, String> _urlCache = {};
  final Map<String, DateTime> _expirationCache = {};
  final Map<String, int> _retryCount = {}; // Track retry attempts
  final Map<String, DateTime> _lastRetryTime = {}; // Track last retry time
  
  static const int maxRetries = 3;
  static const Duration retryCooldown = Duration(minutes: 5);

  Future<Map<String, dynamic>> getValidImageUrlWithExpiration(String imageKey) async {
    // Check retry limits
    final retryCount = _retryCount[imageKey] ?? 0;
    final lastRetry = _lastRetryTime[imageKey];
    
    if (retryCount >= maxRetries) {
      if (lastRetry != null && DateTime.now().difference(lastRetry) < retryCooldown) {
        AppLogger.warning('⚠️ Max retries exceeded for $imageKey, using fallback URL');
        return _getFallbackResponse(imageKey);
      } else {
        // Reset retry count after cooldown
        AppLogger.info('🔵 Resetting retry count for $imageKey after cooldown');
        _retryCount[imageKey] = 0;
      }
    }
    
    // Check if we have a cached URL that's still valid
    if (_urlCache.containsKey(imageKey)) {
      final expirationTime = _expirationCache[imageKey];
      if (expirationTime != null && expirationTime.isAfter(DateTime.now())) {
        AppLogger.info('🔵 Using cached URL for image key: $imageKey');
        return {
          'imageUrl': _urlCache[imageKey]!,
          'expiresAt': expirationTime.toIso8601String(),
        };
      }
    }

    // Get auth token
    final authRepository = sl<AuthRepository>();
    final token = await authRepository.getToken();
    if (token == null) {
      AppLogger.error('❌ No authentication token available');
      throw Exception('No authentication token available');
    }

    // If no valid cached URL, request a new one
    try {
      AppLogger.info('🌐 API_REQUEST: GET /messages/refresh-image-url/$imageKey');
      AppLogger.info('🔵 Requesting new URL for image key: $imageKey');
      final response = await NetworkService.dio.get(
        '/messages/refresh-image-url/$imageKey',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        AppLogger.info('✅ API_RESPONSE: Status ${response.statusCode} for $imageKey');
        AppLogger.info('📦 API_RESPONSE_DATA: $data');
        AppLogger.info('🔵 Received response: $data');
        
        if (data == null) {
          AppLogger.error('❌ Response data is null');
          throw Exception('Response data is null');
        }

        final imageUrl = data['imageUrl'] as String?;
        final expiresAt = data['expiresAt'] as String?;

        if (imageUrl == null || expiresAt == null) {
          AppLogger.error('❌ Missing required fields in response: imageUrl=$imageUrl, expiresAt=$expiresAt');
          throw Exception('Missing required fields in response');
        }

        AppLogger.info('🔵 Image details:');
        AppLogger.info('  - URL: $imageUrl');
        AppLogger.info('  - Expires at: $expiresAt');
        
        final expirationTime = DateTime.parse(expiresAt);
        
        // Cache the new URL and its expiration
        _urlCache[imageKey] = imageUrl;
        _expirationCache[imageKey] = expirationTime;
        
        // Reset retry count on success
        _retryCount[imageKey] = 0;
        AppLogger.info('🔵 Successfully refreshed URL for $imageKey, reset retry count');

        return {
          'imageUrl': imageUrl,
          'expiresAt': expiresAt,
        };
      } else {
        AppLogger.error('❌ API_ERROR: Status ${response.statusCode} for $imageKey');
        AppLogger.error('❌ API_ERROR_MESSAGE: ${response.statusMessage}');
        AppLogger.error('❌ Failed to get image URL: ${response.statusMessage}');
        throw Exception('Failed to get image URL: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      AppLogger.error('🌐 DIO_ERROR: ${e.message} for $imageKey');
      if (e.response != null) {
        AppLogger.error('📦 DIO_RESPONSE_DATA: ${e.response?.data}');
        AppLogger.error('❌ DIO_RESPONSE_STATUS: ${e.response?.statusCode}');
        AppLogger.error('❌ Response data: ${e.response?.data}');
        AppLogger.error('❌ Response status: ${e.response?.statusCode}');
        
        // Handle specific error cases
        if (e.response?.statusCode == 404) {
          AppLogger.error('❌ Image not found or endpoint does not exist: $imageKey');
          AppLogger.error('❌ Please verify the backend endpoint is implemented');
        }
      }
      _incrementRetryCount(imageKey);
      throw Exception('Failed to get image URL: ${e.message}');
    } catch (e) {
      AppLogger.error('❌ Failed to get image URL: $e');
      _incrementRetryCount(imageKey);
      throw Exception('Failed to get image URL: $e');
    }
  }

  Map<String, dynamic> _getFallbackResponse(String imageKey) {
    AppLogger.info('🔵 Returning fallback response for image key: $imageKey');
    return {
      'imageUrl': 'https://via.placeholder.com/200x200?text=Image+Unavailable',
      'expiresAt': DateTime.now().add(Duration(hours: 1)).toIso8601String(),
    };
  }

  void _incrementRetryCount(String imageKey) {
    final currentCount = _retryCount[imageKey] ?? 0;
    _retryCount[imageKey] = currentCount + 1;
    _lastRetryTime[imageKey] = DateTime.now();
    AppLogger.warning('⚠️ API call failed for $imageKey (attempt ${_retryCount[imageKey]}/$maxRetries)');
  }

  // Backward-compatible method that returns just the URL
  Future<String> getValidImageUrl(String imageKey) async {
    final result = await getValidImageUrlWithExpiration(imageKey);
    return result['imageUrl'] as String;
  }

  void clearCache() {
    _urlCache.clear();
    _expirationCache.clear();
    _retryCount.clear();
    _lastRetryTime.clear();
  }

  // Debug method to check retry status
  Map<String, dynamic> getRetryStatus(String imageKey) {
    return {
      'retryCount': _retryCount[imageKey] ?? 0,
      'lastRetryTime': _lastRetryTime[imageKey]?.toIso8601String(),
      'isBlocked': (_retryCount[imageKey] ?? 0) >= maxRetries,
    };
  }
} 