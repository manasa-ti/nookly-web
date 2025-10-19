import 'package:nookly/domain/entities/conversation_starter.dart';
import 'package:nookly/domain/repositories/conversation_starter_repository.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/data/repositories/conversation_starter_repository_impl.dart';

class ConversationStarterService {
  final ConversationStarterRepository _repository;

  ConversationStarterService(this._repository);

  Future<List<ConversationStarter>> generateConversationStarters({
    required String matchUserId,
    int? numberOfSuggestions,
    String? locale,
    List<String>? priorMessages,
  }) async {
    try {
      AppLogger.info('DEBUGGING STARTERS: SERVICE - generateConversationStarters called');
      AppLogger.info('DEBUGGING STARTERS: SERVICE - matchUserId: $matchUserId');
      AppLogger.info('DEBUGGING STARTERS: SERVICE - numberOfSuggestions: $numberOfSuggestions');
      AppLogger.info('DEBUGGING STARTERS: SERVICE - locale: $locale');
      AppLogger.info('DEBUGGING STARTERS: SERVICE - priorMessages: $priorMessages');
      AppLogger.info('🔵 ConversationStarterService: Generating starters for $matchUserId');
      AppLogger.info('🔵 ConversationStarterService: Calling repository...');
      
      AppLogger.info('DEBUGGING STARTERS: SERVICE - Checking usage before API call');
      // Check usage before making API call
      final usage = await _repository.getUsage();
      AppLogger.info('DEBUGGING STARTERS: SERVICE - Usage remaining: ${usage.remaining}');
      if (usage.isDailyLimitReached) {
        AppLogger.info('DEBUGGING STARTERS: SERVICE - Daily limit reached, throwing exception');
        AppLogger.info('🔵 ConversationStarterService: Daily limit reached');
        throw ConversationStarterRateLimitException(
          message: 'You have reached your daily limit of 3 conversation starters. Try again tomorrow.',
          usage: usage,
        );
      }

      AppLogger.info('DEBUGGING STARTERS: SERVICE - Calling repository.generateConversationStarters');
      final suggestions = await _repository.generateConversationStarters(
        matchUserId: matchUserId,
        numberOfSuggestions: numberOfSuggestions,
        locale: locale,
        priorMessages: priorMessages,
      );

      AppLogger.info('DEBUGGING STARTERS: SERVICE - Repository returned ${suggestions.length} suggestions');
      AppLogger.info('✅ ConversationStarterService: Generated ${suggestions.length} suggestions');
      return suggestions;
    } catch (e) {
      AppLogger.error('❌ ConversationStarterService: Error generating starters: $e');
      rethrow;
    }
  }

  Future<ConversationStarterUsage> getUsage() async {
    return await _repository.getUsage();
  }

  Future<void> updateUsage(ConversationStarterUsage usage) async {
    await _repository.updateUsage(usage);
  }
}
