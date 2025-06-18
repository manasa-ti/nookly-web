import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

class NetworkService {
  static Dio? _dio;
  static SharedPreferences? _prefs;
  static String? _customBaseUrl;

  static String get baseUrl {
    final url = _customBaseUrl ?? (Platform.isAndroid ? 'http://10.0.2.2:3000/api/' : 'http://localhost:3000/api/');
    print('debug disappearing: NetworkService baseUrl getter called, returning: $url');
    return url;
  }

  static void setBaseUrl(String url) {
    print('debug disappearing: Setting NetworkService baseUrl to: $url');
    _customBaseUrl = url;
    _dio = null; // Force recreation of Dio instance with new baseUrl
  }

  static Dio get dio {
    print('debug disappearing: Getting Dio instance');
    print('debug disappearing: Current baseUrl: $baseUrl');
    
    _dio ??= Dio(BaseOptions(
      baseUrl: baseUrl,
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
          try {
            print('debug disappearing: Interceptor onRequest - URL: ${options.uri}');
            // Get token from SharedPreferences
            _prefs ??= await SharedPreferences.getInstance();
            final token = _prefs?.getString('token');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            return handler.next(options);
          } catch (e) {
            print('debug disappearing: Interceptor onRequest error: $e');
            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'Failed to process request: $e',
              ),
            );
          }
        },
        onResponse: (response, handler) {
          print('debug disappearing: Interceptor onResponse - Status: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print('debug disappearing: Interceptor onError - Error: ${e.message}');
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                error: 'Connection timed out. Please check your internet connection and try again.',
              ),
            );
          }
          if (e.response?.statusCode == 401) {
            // Clear token on authentication error
            clearAuthToken();
          }
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
    _prefs?.remove('token');
  }
} 