// Stub file for web platform
// This file is used when compiling for web where dart:io is not available
// The File class is never actually used on web since we check kIsWeb before using it

/// Stub File class for web compilation
/// This class is never actually instantiated on web - it's only used for type checking
class File {
  File(String path) {
    throw UnimplementedError('File operations are not available on web');
  }
  
  Future<bool> exists() async {
    throw UnimplementedError('File operations are not available on web');
  }
  
  Future<int> length() async {
    throw UnimplementedError('File operations are not available on web');
  }
  
  Future<File> delete({bool recursive = false}) async {
    throw UnimplementedError('File operations are not available on web');
  }
}

