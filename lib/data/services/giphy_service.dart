import 'package:nookly/core/network/network_service.dart';
import 'package:nookly/core/utils/logger.dart';

class GiphyService {
  static const String _baseUrl = '/messages/giphy';

  /// Search for GIFs
  Future<Map<String, dynamic>> searchGifs({
    required String query,
    int offset = 0,
    int limit = 25,
  }) async {
    try {
      final response = await NetworkService.dio.get(
        '$_baseUrl/gifs/search',
        queryParameters: {
          'q': query,
          'offset': offset,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to search GIFs: ${response.data}');
      }
    } catch (e) {
      AppLogger.error('❌ Error searching GIFs: $e');
      rethrow;
    }
  }

  /// Get trending GIFs
  Future<Map<String, dynamic>> getTrendingGifs({
    int offset = 0,
    int limit = 25,
  }) async {
    try {
      final response = await NetworkService.dio.get(
        '$_baseUrl/gifs/trending',
        queryParameters: {
          'offset': offset,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get trending GIFs: ${response.data}');
      }
    } catch (e) {
      AppLogger.error('❌ Error getting trending GIFs: $e');
      rethrow;
    }
  }

  /// Search for stickers
  Future<Map<String, dynamic>> searchStickers({
    required String query,
    int offset = 0,
    int limit = 25,
  }) async {
    try {
      final response = await NetworkService.dio.get(
        '$_baseUrl/stickers/search',
        queryParameters: {
          'q': query,
          'offset': offset,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to search stickers: ${response.data}');
      }
    } catch (e) {
      AppLogger.error('❌ Error searching stickers: $e');
      rethrow;
    }
  }

  /// Get trending stickers
  Future<Map<String, dynamic>> getTrendingStickers({
    int offset = 0,
    int limit = 25,
  }) async {
    try {
      final response = await NetworkService.dio.get(
        '$_baseUrl/stickers/trending',
        queryParameters: {
          'offset': offset,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get trending stickers: ${response.data}');
      }
    } catch (e) {
      AppLogger.error('❌ Error getting trending stickers: $e');
      rethrow;
    }
  }

  /// Get GIF/sticker by ID
  Future<Map<String, dynamic>> getGiphyById(String id) async {
    try {
      final response = await NetworkService.dio.get('$_baseUrl/$id');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get Giphy by ID: ${response.data}');
      }
    } catch (e) {
      AppLogger.error('❌ Error getting Giphy by ID: $e');
      rethrow;
    }
  }
}

/// Giphy data models
class GiphyGif {
  final String id;
  final String title;
  final String url;
  final String previewUrl;
  final int width;
  final int height;
  final int size;
  final String? webpUrl;
  final String? mp4Url;

  const GiphyGif({
    required this.id,
    required this.title,
    required this.url,
    required this.previewUrl,
    required this.width,
    required this.height,
    required this.size,
    this.webpUrl,
    this.mp4Url,
  });

  factory GiphyGif.fromJson(Map<String, dynamic> json) {
    return GiphyGif(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      url: json['url'] as String,
      previewUrl: json['previewUrl'] as String? ?? json['url'] as String,
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
      webpUrl: json['webpUrl'] as String?,
      mp4Url: json['mp4Url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'previewUrl': previewUrl,
      'width': width,
      'height': height,
      'size': size,
      'webpUrl': webpUrl,
      'mp4Url': mp4Url,
    };
  }
}

class GiphySticker {
  final String id;
  final String title;
  final String url;
  final String previewUrl;
  final int width;
  final int height;
  final int size;
  final String? webpUrl;

  const GiphySticker({
    required this.id,
    required this.title,
    required this.url,
    required this.previewUrl,
    required this.width,
    required this.height,
    required this.size,
    this.webpUrl,
  });

  factory GiphySticker.fromJson(Map<String, dynamic> json) {
    return GiphySticker(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      url: json['url'] as String,
      previewUrl: json['previewUrl'] as String? ?? json['url'] as String,
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
      webpUrl: json['webpUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'previewUrl': previewUrl,
      'width': width,
      'height': height,
      'size': size,
      'webpUrl': webpUrl,
    };
  }
}
