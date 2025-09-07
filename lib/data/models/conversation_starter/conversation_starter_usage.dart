import 'package:json_annotation/json_annotation.dart';

part 'conversation_starter_usage.g.dart';

@JsonSerializable()
class ConversationStarterUsageModel {
  final int remaining;
  final DateTime resetDate;
  final int totalRequests;
  final DateTime lastUsed;

  const ConversationStarterUsageModel({
    required this.remaining,
    required this.resetDate,
    required this.totalRequests,
    required this.lastUsed,
  });

  factory ConversationStarterUsageModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationStarterUsageModelFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationStarterUsageModelToJson(this);

  ConversationStarterUsageModel copyWith({
    int? remaining,
    DateTime? resetDate,
    int? totalRequests,
    DateTime? lastUsed,
  }) {
    return ConversationStarterUsageModel(
      remaining: remaining ?? this.remaining,
      resetDate: resetDate ?? this.resetDate,
      totalRequests: totalRequests ?? this.totalRequests,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  bool get isDailyLimitReached => remaining <= 0;
  
  bool get shouldResetUsage {
    final now = DateTime.now();
    return now.isAfter(resetDate);
  }
}
