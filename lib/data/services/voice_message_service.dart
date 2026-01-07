import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:nookly/core/utils/file_io_helper.dart';
import 'package:http_parser/http_parser.dart';
import 'package:nookly/core/network/network_service.dart';
import 'package:nookly/core/utils/logger.dart';
import 'dart:html' as html if (dart.library.io) 'voice_message_service_stub.dart';

class VoiceMessageService {
  /// Upload voice file to server
  /// Returns voice metadata including URL, key, size, type, duration, and expiration
  Future<Map<String, dynamic>> uploadVoice(String filePath) async {
    try {
      AppLogger.info('🎤 Uploading voice file: $filePath');
      
      MultipartFile voiceFile;
      String fileName;
      String contentType;
      
      if (kIsWeb) {
        // On web, filePath is a blob URL
        // We need to fetch the blob and convert to bytes
        voiceFile = await _createMultipartFileFromBlobUrl(filePath);
        fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        contentType = 'audio/mp4'; // Web MediaRecorder typically uses mp4
      } else {
        // On mobile, filePath is a file path
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('Voice file does not exist: $filePath');
        }
        
        fileName = filePath.split('/').last;
        
        // Determine content type based on file extension
        final extension = fileName.split('.').last.toLowerCase();
        contentType = switch (extension) {
          'm4a' => 'audio/m4a',
          'mp3' => 'audio/mpeg',
          'wav' => 'audio/wav',
          'ogg' => 'audio/ogg',
          'webm' => 'audio/webm',
          _ => 'audio/m4a', // Default to m4a
        };
        
        voiceFile = await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        );
      }

      final formData = FormData.fromMap({
        'voice': voiceFile,
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
  
  /// Create MultipartFile from blob URL (web only)
  Future<MultipartFile> _createMultipartFileFromBlobUrl(String blobUrl) async {
    if (!kIsWeb) {
      throw UnsupportedError('_createMultipartFileFromBlobUrl is only available on web');
    }
    
    try {
      // Fetch the blob from the URL
      final request = await html.HttpRequest.request(
        blobUrl,
        responseType: 'blob',
      );
      
      final blob = request.response as html.Blob;
      
      // Convert blob to bytes using FileReader
      final fileReader = html.FileReader();
      final completer = Completer<Uint8List>();
      
      fileReader.onLoadEnd.listen((_) {
        final result = fileReader.result;
        // On web, result can be either ArrayBuffer or Uint8List depending on browser
        // Use dynamic type check to avoid compilation issues
        try {
          // Handle both ArrayBuffer and Uint8List cases
          Uint8List bytes;
          if (result is Uint8List) {
            // Already a Uint8List (some browsers return this directly)
            bytes = result;
          } else {
            // It's an ArrayBuffer, create a view
            final arrayBuffer = result as dynamic;
            bytes = Uint8List.view(arrayBuffer);
          }
          completer.complete(bytes);
        } catch (e) {
          completer.completeError(StateError('Failed to read blob as ArrayBuffer: $e'));
        }
      });
      
      fileReader.onError.listen((_) {
        completer.completeError(StateError('Failed to read blob'));
      });
      
      fileReader.readAsArrayBuffer(blob);
      final bytes = await completer.future;
      
      // Determine filename and MIME type from blob type
      // Server accepts: M4A, MP3, OGG, Opus, WebM
      final blobMimeType = blob.type.isNotEmpty ? blob.type.toLowerCase() : '';
      String extension = 'm4a';
      String contentType = 'audio/m4a'; // Default to m4a
      
      if (blobMimeType.contains('mp4') || blobMimeType.contains('m4a') || blobMimeType.contains('aac')) {
        // Map audio/mp4 and audio/aac to audio/m4a (server expects m4a)
        extension = 'm4a';
        contentType = 'audio/m4a';
      } else if (blobMimeType.contains('webm')) {
        extension = 'webm';
        contentType = 'audio/webm';
      } else if (blobMimeType.contains('ogg') || blobMimeType.contains('opus')) {
        // Map opus to ogg format (server accepts both)
        extension = 'ogg';
        contentType = 'audio/ogg';
      } else if (blobMimeType.contains('mp3') || blobMimeType.contains('mpeg')) {
        extension = 'mp3';
        contentType = 'audio/mpeg';
      } else {
        // Default to m4a if unknown
        extension = 'm4a';
        contentType = 'audio/m4a';
      }
      
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      AppLogger.info('🎤 Voice file details:');
      AppLogger.info('🎤 Original blob MIME type: $blobMimeType');
      AppLogger.info('🎤 Mapped content type: $contentType');
      AppLogger.info('🎤 File extension: $extension');
      AppLogger.info('🎤 File name: $fileName');
      
      return MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      );
    } catch (e) {
      AppLogger.error('❌ Error creating MultipartFile from blob URL: $e');
      rethrow;
    }
  }
}
