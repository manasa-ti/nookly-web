import 'package:dio/dio.dart';
import 'package:nookly/core/network/network_service.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/data/models/conversation_starter/conversation_starter_request.dart';
import 'package:nookly/data/models/conversation_starter/conversation_starter_response.dart' as models;
import 'package:nookly/domain/entities/conversation_starter.dart';
import 'package:nookly/domain/repositories/conversation_starter_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConversationStarterRepositoryImpl implements ConversationStarterRepository {
  final Dio _dio = NetworkService.dio;
  final SharedPreferences _prefs;

  ConversationStarterRepositoryImpl(this._prefs);

  @override
  Future<List<ConversationStarter>> generateConversationStarters({
    required String matchUserId,
    int? numberOfSuggestions,
    String? locale,
    List<String>? priorMessages,
  }) async {
    try {
      print('DEBUGGING STARTERS: REPOSITORY - generateConversationStarters called');
      print('DEBUGGING STARTERS: REPOSITORY - matchUserId: $matchUserId');
      print('DEBUGGING STARTERS: REPOSITORY - numberOfSuggestions: $numberOfSuggestions');
      print('DEBUGGING STARTERS: REPOSITORY - locale: $locale');
      print('DEBUGGING STARTERS: REPOSITORY - priorMessages: $priorMessages');
      AppLogger.info('🔵 Generating conversation starters for user: $matchUserId');
      AppLogger.info('🔵 Request details: n=${numberOfSuggestions ?? 4}, locale=${locale ?? 'en-IN'}');
      AppLogger.info('🔵 Prior messages count: ${priorMessages?.length ?? 0}');

      final request = ConversationStarterRequest(
        matchUserId: matchUserId,
        context: ConversationStarterContext(
          n: numberOfSuggestions ?? 4,
          locale: locale ?? 'en-IN',
          priorMessages: priorMessages,
        ),
      );

      print('DEBUGGING STARTERS: REPOSITORY - Request object created');
      print('DEBUGGING STARTERS: REPOSITORY - Request JSON: ${request.toJson()}');
      AppLogger.info('🔵 Making API call to: /conversation-starters/generate');
      AppLogger.info('🔵 Request data: ${request.toJson()}');

      print('DEBUGGING STARTERS: REPOSITORY - Making HTTP POST request');
      final response = await _dio.post(
        '/conversation-starters/generate',
        data: request.toJson(),
      );

      print('DEBUGGING STARTERS: REPOSITORY - HTTP response received');
      print('DEBUGGING STARTERS: REPOSITORY - Status code: ${response.statusCode}');
      print('DEBUGGING STARTERS: REPOSITORY - Response data: ${response.data}');
      AppLogger.info('🔵 API response status: ${response.statusCode}');
      AppLogger.info('🔵 API response data: ${response.data}');

      if (response.statusCode == 200) {
        print('DEBUGGING STARTERS: REPOSITORY - Parsing response data');
        final responseData = models.ConversationStarterResponse.fromJson(response.data);
        
        print('DEBUGGING STARTERS: REPOSITORY - Response parsed successfully');
        print('DEBUGGING STARTERS: REPOSITORY - Suggestions count: ${responseData.suggestions.length}');
        print('DEBUGGING STARTERS: REPOSITORY - Is fallback: ${responseData.isFallback}');
        print('DEBUGGING STARTERS: REPOSITORY - Usage remaining: ${responseData.usage.remaining}');
        AppLogger.info('✅ Conversation starters generated successfully');
        AppLogger.info('🔵 Suggestions count: ${responseData.suggestions.length}');
        AppLogger.info('🔵 Is fallback: ${responseData.isFallback}');
        AppLogger.info('🔵 Usage remaining: ${responseData.usage.remaining}');

        print('DEBUGGING STARTERS: REPOSITORY - Updating local usage tracking');
        // Update local usage tracking
        await _updateLocalUsage(ConversationStarterUsage(
          remaining: responseData.usage.remaining,
          resetDate: DateTime.parse(responseData.usage.resetDate),
          totalRequests: responseData.usage.totalRequests,
          isDailyLimitReached: responseData.usage.remaining <= 0,
        ));

        print('DEBUGGING STARTERS: REPOSITORY - Converting to domain entities');
        // Convert to domain entities
        final suggestions = responseData.suggestions.asMap().entries.map((entry) {
          return ConversationStarter(
            id: '${matchUserId}_${DateTime.now().millisecondsSinceEpoch}_${entry.key}',
            text: entry.value,
            isFallback: responseData.isFallback,
            createdAt: DateTime.now(),
          );
        }).toList();

        print('DEBUGGING STARTERS: REPOSITORY - Returning ${suggestions.length} suggestions');
        return suggestions;
      } else {
        throw Exception('Failed to generate conversation starters: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DEBUGGING STARTERS: REPOSITORY - DioException caught: ${e.message}');
      print('DEBUGGING STARTERS: REPOSITORY - DioException type: ${e.type}');
      print('DEBUGGING STARTERS: REPOSITORY - DioException response: ${e.response?.data}');
      AppLogger.error('❌ DioException in generateConversationStarters: ${e.message}');
      
      if (e.response?.statusCode == 429) {
        // Rate limit exceeded
        final errorData = e.response?.data;
        if (errorData != null && errorData is Map<String, dynamic>) {
          final usageData = models.ConversationStarterUsage.fromJson(errorData['usage']);
          await _updateLocalUsage(ConversationStarterUsage(
            remaining: usageData.remaining,
            resetDate: DateTime.parse(usageData.resetDate),
            totalRequests: usageData.totalRequests,
            isDailyLimitReached: usageData.remaining <= 0,
          ));
        }
        throw ConversationStarterRateLimitException(
          message: errorData?['message'] ?? 'Daily limit exceeded',
          usage: await getUsage(),
        );
      } else if (e.response?.statusCode == 400) {
        throw ConversationStarterValidationException(
          message: e.response?.data?['message'] ?? 'Invalid request',
        );
      } else if (e.response?.statusCode == 404) {
        throw ConversationStarterNotFoundException(
          message: e.response?.data?['message'] ?? 'User not found',
        );
      } else if (e.response?.statusCode == 500) {
        throw ConversationStarterServiceException(
          message: e.response?.data?['message'] ?? 'Service temporarily unavailable',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      AppLogger.error('❌ Unexpected error in generateConversationStarters: $e');
      throw Exception('Failed to generate conversation starters: $e');
    }
  }

  @override
  Future<ConversationStarterUsage> getUsage() async {
    try {
      final remaining = _prefs.getInt('conversation_starter_remaining') ?? 3;
      final resetDateStr = _prefs.getString('conversation_starter_reset_date');
      final totalRequests = _prefs.getInt('conversation_starter_total') ?? 0;
      
      DateTime resetDate;
      if (resetDateStr != null) {
        resetDate = DateTime.parse(resetDateStr);
      } else {
        // Set reset date to next midnight
        final now = DateTime.now();
        resetDate = DateTime(now.year, now.month, now.day + 1);
      }

      // Check if we need to reset usage (new day)
      if (DateTime.now().isAfter(resetDate)) {
        await _resetDailyUsage();
        final now = DateTime.now();
        final nextMidnight = DateTime(now.year, now.month, now.day + 1);
        return ConversationStarterUsage(
          remaining: 3,
          resetDate: nextMidnight,
          totalRequests: 0,
          isDailyLimitReached: false,
        );
      }

      return ConversationStarterUsage(
        remaining: remaining,
        resetDate: resetDate,
        totalRequests: totalRequests,
        isDailyLimitReached: remaining <= 0,
      );
    } catch (e) {
      AppLogger.error('❌ Error getting usage: $e');
      // Return default usage on error
      final now = DateTime.now();
      final nextMidnight = DateTime(now.year, now.month, now.day + 1);
      return ConversationStarterUsage(
        remaining: 3,
        resetDate: nextMidnight,
        totalRequests: 0,
        isDailyLimitReached: false,
      );
    }
  }

  @override
  Future<void> updateUsage(ConversationStarterUsage usage) async {
    await _updateLocalUsage(usage);
  }

  Future<void> _updateLocalUsage(ConversationStarterUsage usage) async {
    await _prefs.setInt('conversation_starter_remaining', usage.remaining);
    await _prefs.setString('conversation_starter_reset_date', usage.resetDate.toIso8601String());
    await _prefs.setInt('conversation_starter_total', usage.totalRequests);
  }

  Future<void> _resetDailyUsage() async {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    
    await _prefs.setInt('conversation_starter_remaining', 3);
    await _prefs.setString('conversation_starter_reset_date', nextMidnight.toIso8601String());
    
    AppLogger.info('🔄 Reset daily conversation starter usage');
  }
}

// Custom exceptions for better error handling
class ConversationStarterRateLimitException implements Exception {
  final String message;
  final ConversationStarterUsage usage;

  ConversationStarterRateLimitException({
    required this.message,
    required this.usage,
  });

  @override
  String toString() => message;
}

class ConversationStarterValidationException implements Exception {
  final String message;

  ConversationStarterValidationException({required this.message});

  @override
  String toString() => message;
}

class ConversationStarterNotFoundException implements Exception {
  final String message;

  ConversationStarterNotFoundException({required this.message});

  @override
  String toString() => message;
}

class ConversationStarterServiceException implements Exception {
  final String message;

  ConversationStarterServiceException({required this.message});

  @override
  String toString() => message;
}
