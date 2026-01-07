// Conditional export of File from dart:io
// On web, this file will be empty (no File class available)
// On mobile/desktop, this exports File from dart:io

export 'dart:io' if (dart.library.html) 'file_io_stub.dart' show File;

