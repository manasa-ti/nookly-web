import 'package:equatable/equatable.dart';

abstract class ConversationStarterEvent extends Equatable {
  const ConversationStarterEvent();

  @override
  List<Object?> get props => [];
}

class GenerateConversationStarters extends ConversationStarterEvent {
  final String matchUserId;
  final int? numberOfSuggestions;
  final String? locale;
  final List<String>? priorMessages;

  const GenerateConversationStarters({
    required this.matchUserId,
    this.numberOfSuggestions,
    this.locale,
    this.priorMessages,
  });

  @override
  List<Object?> get props => [matchUserId, numberOfSuggestions, locale, priorMessages];
}

class LoadConversationStarterUsage extends ConversationStarterEvent {
  const LoadConversationStarterUsage();
}

class ClearConversationStarters extends ConversationStarterEvent {
  const ClearConversationStarters();
}

class RefreshConversationStarters extends ConversationStarterEvent {
  final String matchUserId;
  final int? numberOfSuggestions;
  final String? locale;
  final List<String>? priorMessages;

  const RefreshConversationStarters({
    required this.matchUserId,
    this.numberOfSuggestions,
    this.locale,
    this.priorMessages,
  });

  @override
  List<Object?> get props => [matchUserId, numberOfSuggestions, locale, priorMessages];
}
