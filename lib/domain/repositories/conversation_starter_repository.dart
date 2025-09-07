import 'package:nookly/domain/entities/conversation_starter.dart';

abstract class ConversationStarterRepository {
  Future<List<ConversationStarter>> generateConversationStarters({
    required String matchUserId,
    int? numberOfSuggestions,
    String? locale,
    List<String>? priorMessages,
  });

  Future<ConversationStarterUsage> getUsage();

  Future<void> updateUsage(ConversationStarterUsage usage);
}
