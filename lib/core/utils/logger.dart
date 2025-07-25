import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  static void debug(dynamic message) {
    if (kDebugMode) {
      _logger.d(message);
    }
  }

  static void info(dynamic message) {
    if (kDebugMode) {
      _logger.i(message);
    }
  }

  static void warning(dynamic message) {
    if (kDebugMode) {
      _logger.w(message);
    }
  }

  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.e(message, error: error, stackTrace: stackTrace);
    }
  }

  static void verbose(dynamic message) {
    if (kDebugMode) {
      _logger.v(message);
    }
  }

  static void wtf(dynamic message) {
    if (kDebugMode) {
      _logger.wtf(message);
    }
  }
} 