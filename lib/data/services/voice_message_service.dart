import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:nookly/core/network/network_service.dart';
import 'package:nookly/core/utils/logger.dart';

class VoiceMessageService {
  /// Upload voice file to server
  /// Returns voice metadata including URL, key, size, type, duration, and expiration
  Future<Map<String, dynamic>> uploadVoice(String filePath) async {
    try {
      AppLogger.info('🎤 Uploading voice file: $filePath');
      
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Voice file does not exist: $filePath');
      }

      final fileName = filePath.split('/').last;
      
      // Determine content type based on file extension
      final extension = fileName.split('.').last.toLowerCase();
      final contentType = switch (extension) {
        'm4a' => 'audio/m4a',
        'mp3' => 'audio/mpeg',
        'wav' => 'audio/wav',
        'ogg' => 'audio/ogg',
        'webm' => 'audio/webm',
        _ => 'audio/m4a', // Default to m4a
      };

      final formData = FormData.fromMap({
        'voice': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
      });

      final response = await NetworkService.dio.post(
        '/messages/upload-voice',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        AppLogger.info('✅ Voice file uploaded successfully');
        AppLogger.info('🎤 Voice URL: ${data['voiceUrl']}');
        AppLogger.info('🎤 Voice key: ${data['key']}');
        AppLogger.info('🎤 Voice size: ${data['size']} bytes');
        AppLogger.info('🎤 Voice duration: ${data['duration']} seconds');
        
        return {
          'voiceUrl': data['voiceUrl'] as String,
          'voiceKey': data['key'] as String,
          'voiceSize': data['size'] as int,
          'voiceType': data['type'] as String,
          'voiceDuration': data['duration'] as int,
          'expiresAt': data['expiresAt'] as String,
        };
      } else {
        throw Exception('Failed to upload voice file: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      AppLogger.error('❌ Error uploading voice file: $e');
      rethrow;
    }
  }

  /// Refresh expired voice URL
  /// Returns new voice URL and expiration time
  Future<Map<String, dynamic>> refreshVoiceUrl(String voiceKey) async {
    try {
      AppLogger.info('🔄 Refreshing voice URL for key: $voiceKey');
      
      final response = await NetworkService.dio.get(
        '/messages/refresh-voice-url/$voiceKey',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        AppLogger.info('✅ Voice URL refreshed successfully');
        
        return {
          'voiceUrl': data['voiceUrl'] as String,
          'expiresAt': data['expiresAt'] as String,
        };
      } else {
        throw Exception('Failed to refresh voice URL: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      AppLogger.error('❌ Error refreshing voice URL: $e');
      rethrow;
    }
  }

  /// Mark voice message as played (for view-once messages)
  /// This will trigger deletion of the voice file on the server
  Future<void> markVoicePlayed(String messageId) async {
    try {
      AppLogger.info('👁️ Marking voice message as played: $messageId');
      
      final response = await NetworkService.dio.put(
        '/messages/play-voice/$messageId',
      );

      if (response.statusCode == 200) {
        AppLogger.info('✅ Voice message marked as played successfully');
      } else {
        throw Exception('Failed to mark voice as played: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      AppLogger.error('❌ Error marking voice as played: $e');
      rethrow;
    }
  }

  /// Check if voice URL is expired
  bool isVoiceUrlExpired(String expiresAt) {
    try {
      final expirationTime = DateTime.parse(expiresAt);
      return DateTime.now().isAfter(expirationTime);
    } catch (e) {
      AppLogger.error('❌ Error parsing expiration time: $e');
      return true; // Assume expired if we can't parse
    }
  }

  /// Get remaining time until voice URL expires
  Duration? getRemainingTime(String expiresAt) {
    try {
      final expirationTime = DateTime.parse(expiresAt);
      final now = DateTime.now();
      
      if (now.isAfter(expirationTime)) {
        return Duration.zero; // Already expired
      }
      
      return expirationTime.difference(now);
    } catch (e) {
      AppLogger.error('❌ Error calculating remaining time: $e');
      return null;
    }
  }
}
