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

  Future<Map<String, dynamic>> getValidImageUrlWithExpiration(String imageKey) async {
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

        return {
          'imageUrl': imageUrl,
          'expiresAt': expiresAt,
        };
      } else {
        AppLogger.error('❌ Failed to get image URL: ${response.statusMessage}');
        throw Exception('Failed to get image URL: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      AppLogger.error('❌ Dio error getting image URL: ${e.message}');
      if (e.response != null) {
        AppLogger.error('❌ Response data: ${e.response?.data}');
        AppLogger.error('❌ Response status: ${e.response?.statusCode}');
      }
      throw Exception('Failed to get image URL: ${e.message}');
    } catch (e) {
      AppLogger.error('❌ Failed to get image URL: $e');
      throw Exception('Failed to get image URL: $e');
    }
  }

  // Backward-compatible method that returns just the URL
  Future<String> getValidImageUrl(String imageKey) async {
    final result = await getValidImageUrlWithExpiration(imageKey);
    return result['imageUrl'] as String;
  }

  void clearCache() {
    _urlCache.clear();
    _expirationCache.clear();
  }
} 