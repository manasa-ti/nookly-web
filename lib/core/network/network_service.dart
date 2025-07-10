import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:nookly/core/services/auth_handler.dart';
import 'package:nookly/core/utils/logger.dart';

class NetworkService {
  static Dio? _dio;
  static SharedPreferences? _prefs;
  static String? _customBaseUrl;
  static AuthHandler? _authHandler;

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

  static void setAuthHandler(AuthHandler authHandler) {
    _authHandler = authHandler;
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
        logPrint: (obj) {
          // Add custom logging with emojis for better filtering
          if (obj.toString().contains('REQUEST')) {
            print('🌐 HTTP_REQUEST: $obj');
          } else if (obj.toString().contains('RESPONSE')) {
            print('✅ HTTP_RESPONSE: $obj');
          } else if (obj.toString().contains('ERROR')) {
            print('❌ HTTP_ERROR: $obj');
          } else {
            print('📡 HTTP_LOG: $obj');
          }
        },
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
            AppLogger.warning('🔐 NetworkService: Received 401 Unauthorized error');
            
            // Get the error message from response
            String errorMessage = '';
            try {
              if (e.response?.data != null) {
                if (e.response!.data is Map) {
                  errorMessage = e.response!.data['message'] ?? '';
                } else if (e.response!.data is String) {
                  errorMessage = e.response!.data;
                }
              }
            } catch (ex) {
              AppLogger.warning('🔐 NetworkService: Could not parse error message: $ex');
            }
            
            AppLogger.info('🔐 NetworkService: 401 error message: "$errorMessage"');
            
            // Clear token on authentication error
            clearAuthToken();
            
            // Only trigger logout for "Invalid token" message on critical endpoints
            if (_authHandler != null && 
                _authHandler!.isCriticalEndpoint(e.requestOptions.path) &&
                errorMessage.toLowerCase().contains('invalid token')) {
              AppLogger.warning('🔐 NetworkService: Invalid token on critical endpoint, triggering logout');
              AppLogger.warning('🔐 NetworkService: Failed endpoint: ${e.requestOptions.path}');
              
              // Trigger logout through auth handler
              _authHandler!.triggerLogout();
            } else {
              AppLogger.info('🔐 NetworkService: 401 error not triggering logout (non-critical endpoint or different error message)');
            }
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