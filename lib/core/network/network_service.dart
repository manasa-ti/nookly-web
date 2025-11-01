import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:nookly/core/services/auth_handler.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/core/config/environment_manager.dart';

class NetworkService {
  static Dio? _dio;
  static SharedPreferences? _prefs;
  static String? _customBaseUrl;
  static AuthHandler? _authHandler;

  static String get baseUrl {
    final url = _customBaseUrl ?? EnvironmentManager.baseUrl;
    AppLogger.info('debug disappearing: NetworkService baseUrl getter called, returning: $url');
    return url;
  }

  static void setBaseUrl(String url) {
    AppLogger.info('debug disappearing: Setting NetworkService baseUrl to: $url');
    _customBaseUrl = url;
    _dio = null; // Force recreation of Dio instance with new baseUrl
  }

  static void setAuthHandler(AuthHandler authHandler) {
    _authHandler = authHandler;
  }

  static Dio get dio {
    AppLogger.info('debug disappearing: Getting Dio instance');
    AppLogger.info('debug disappearing: Current baseUrl: $baseUrl');
    
    _dio ??= Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
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
            AppLogger.info('🌐 HTTP_REQUEST: $obj');
          } else if (obj.toString().contains('RESPONSE')) {
            AppLogger.info('✅ HTTP_RESPONSE: $obj');
          } else if (obj.toString().contains('ERROR')) {
            AppLogger.info('❌ HTTP_ERROR: $obj');
          } else {
            AppLogger.info('📡 HTTP_LOG: $obj');
          }
        },
      ))
      ..interceptors.add(_createPerformanceInterceptor())
      ..interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            AppLogger.info('debug disappearing: Interceptor onRequest - URL: ${options.uri}');
            // Get token from SharedPreferences
            _prefs ??= await SharedPreferences.getInstance();
            final token = _prefs?.getString('token');
            
            // TEMP LOG: Print auth token before API call
            if (token != null) {
              AppLogger.info('🔑 NetworkService: Auth token for ${options.uri}: $token');
              options.headers['Authorization'] = 'Bearer $token';
            } else {
              AppLogger.info('🔑 NetworkService: No auth token found for ${options.uri}');
            }
            
            return handler.next(options);
          } catch (e) {
            AppLogger.info('debug disappearing: Interceptor onRequest error: $e');
            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'Failed to process request: $e',
              ),
            );
          }
        },
        onResponse: (response, handler) {
          AppLogger.info('debug disappearing: Interceptor onResponse - Status: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          AppLogger.info('debug disappearing: Interceptor onError - Error: ${e.message}');
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

  /// Create performance monitoring interceptor for Firebase Performance
  static Interceptor _createPerformanceInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // Only track performance in staging/production
        if (EnvironmentManager.currentEnvironment != Environment.development) {
          final httpMethod = _getHttpMethod(options.method);
          final trace = FirebasePerformance.instance.newHttpMetric(
            options.uri.toString(),
            httpMethod,
          );
          options.extra['firebase_performance_trace'] = trace;
          trace.start();
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final trace = response.requestOptions.extra['firebase_performance_trace'] as HttpMetric?;
        if (trace != null) {
          trace.httpResponseCode = response.statusCode ?? 0;
          if (response.headers.value('content-length') != null) {
            trace.responsePayloadSize =
              int.tryParse(response.headers.value('content-length')!) ?? 0;
          }
          trace.stop();
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        final trace = error.requestOptions.extra['firebase_performance_trace'] as HttpMetric?;
        if (trace != null) {
          trace.httpResponseCode = error.response?.statusCode ?? 0;
          trace.stop();
        }
        return handler.next(error);
      },
    );
  }

  /// Convert Dio HTTP method string to Firebase HttpMethod enum
  static HttpMethod _getHttpMethod(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return HttpMethod.Get;
      case 'POST':
        return HttpMethod.Post;
      case 'PUT':
        return HttpMethod.Put;
      case 'DELETE':
        return HttpMethod.Delete;
      case 'PATCH':
        return HttpMethod.Patch;
      case 'HEAD':
        return HttpMethod.Head;
      case 'OPTIONS':
        return HttpMethod.Options;
      default:
        return HttpMethod.Get;
    }
  }
} 