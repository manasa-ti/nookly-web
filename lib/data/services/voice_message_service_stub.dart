// Stub file for mobile platforms
// This file is only imported on non-web platforms to satisfy conditional import requirements

/// Stub HttpRequest for mobile platforms
/// This class is never actually used on mobile - it's only for type checking
class HttpRequest {
  static Future<dynamic> request(
    String url, {
    String? responseType,
  }) {
    throw UnimplementedError('HttpRequest is only available on web');
  }
}

