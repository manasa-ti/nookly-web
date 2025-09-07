import 'package:equatable/equatable.dart';
import 'package:nookly/domain/entities/conversation_starter.dart';

abstract class ConversationStarterState extends Equatable {
  const ConversationStarterState();

  @override
  List<Object?> get props => [];
}

class ConversationStarterInitial extends ConversationStarterState {
  const ConversationStarterInitial();
}

class ConversationStarterLoading extends ConversationStarterState {
  const ConversationStarterLoading();
}

class ConversationStarterLoaded extends ConversationStarterState {
  final List<ConversationStarter> suggestions;
  final ConversationStarterUsage usage;
  final bool isFallback;

  const ConversationStarterLoaded({
    required this.suggestions,
    required this.usage,
    required this.isFallback,
  });

  @override
  List<Object?> get props => [suggestions, usage, isFallback];

  ConversationStarterLoaded copyWith({
    List<ConversationStarter>? suggestions,
    ConversationStarterUsage? usage,
    bool? isFallback,
  }) {
    return ConversationStarterLoaded(
      suggestions: suggestions ?? this.suggestions,
      usage: usage ?? this.usage,
      isFallback: isFallback ?? this.isFallback,
    );
  }
}

class ConversationStarterError extends ConversationStarterState {
  final String message;
  final ConversationStarterUsage? usage;

  const ConversationStarterError({
    required this.message,
    this.usage,
  });

  @override
  List<Object?> get props => [message, usage];
}

class ConversationStarterRateLimited extends ConversationStarterState {
  final String message;
  final ConversationStarterUsage usage;

  const ConversationStarterRateLimited({
    required this.message,
    required this.usage,
  });

  @override
  List<Object?> get props => [message, usage];
}
