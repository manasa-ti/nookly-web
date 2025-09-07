import 'package:equatable/equatable.dart';

class ConversationStarter extends Equatable {
  final String id;
  final String text;
  final bool isFallback;
  final DateTime createdAt;

  const ConversationStarter({
    required this.id,
    required this.text,
    required this.isFallback,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, text, isFallback, createdAt];

  ConversationStarter copyWith({
    String? id,
    String? text,
    bool? isFallback,
    DateTime? createdAt,
  }) {
    return ConversationStarter(
      id: id ?? this.id,
      text: text ?? this.text,
      isFallback: isFallback ?? this.isFallback,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ConversationStarterUsage extends Equatable {
  final int remaining;
  final DateTime resetDate;
  final int totalRequests;
  final bool isDailyLimitReached;

  const ConversationStarterUsage({
    required this.remaining,
    required this.resetDate,
    required this.totalRequests,
    required this.isDailyLimitReached,
  });

  @override
  List<Object?> get props => [remaining, resetDate, totalRequests, isDailyLimitReached];

  ConversationStarterUsage copyWith({
    int? remaining,
    DateTime? resetDate,
    int? totalRequests,
    bool? isDailyLimitReached,
  }) {
    return ConversationStarterUsage(
      remaining: remaining ?? this.remaining,
      resetDate: resetDate ?? this.resetDate,
      totalRequests: totalRequests ?? this.totalRequests,
      isDailyLimitReached: isDailyLimitReached ?? this.isDailyLimitReached,
    );
  }
}
