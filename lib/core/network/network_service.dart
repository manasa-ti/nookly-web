import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

class NetworkService {
  static Dio? _dio;
  static SharedPreferences? _prefs;

  static String get _baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api'; // Android emulator
    }
    return 'http://localhost:3000/api'; // iOS simulator and others
  }

  static Dio get dio {
    _dio ??= Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ))
      ..interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ))
      ..interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Get token from SharedPreferences
          _prefs ??= await SharedPreferences.getInstance();
          final token = _prefs?.getString('token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ));

    return _dio!;
  }

  static void setAuthToken(String token) {
    _dio?.options.headers['Authorization'] = 'Bearer $token';
  }

  static void clearAuthToken() {
    _dio?.options.headers.remove('Authorization');
  }
} 