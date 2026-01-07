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

/// Stub Blob for mobile platforms
class Blob {
  final String type;
  Blob(this.type);
}

/// Stub FileReader for mobile platforms
class FileReader {
  Stream<dynamic> get onLoadEnd => throw UnimplementedError('FileReader is only available on web');
  Stream<dynamic> get onError => throw UnimplementedError('FileReader is only available on web');
  dynamic get result => throw UnimplementedError('FileReader is only available on web');
  void readAsArrayBuffer(dynamic blob) {
    throw UnimplementedError('FileReader is only available on web');
  }
}

