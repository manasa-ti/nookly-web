import 'package:json_annotation/json_annotation.dart';

part 'conversation_starter_response.g.dart';

@JsonSerializable()
class ConversationStarterResponse {
  final List<String> suggestions;
  final ConversationStarterUsage usage;
  final bool isFallback;

  const ConversationStarterResponse({
    required this.suggestions,
    required this.usage,
    required this.isFallback,
  });

  factory ConversationStarterResponse.fromJson(Map<String, dynamic> json) =>
      _$ConversationStarterResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationStarterResponseToJson(this);
}

@JsonSerializable()
class ConversationStarterUsage {
  final int remaining;
  final String resetDate;
  final int totalRequests;

  const ConversationStarterUsage({
    required this.remaining,
    required this.resetDate,
    required this.totalRequests,
  });

  factory ConversationStarterUsage.fromJson(Map<String, dynamic> json) =>
      _$ConversationStarterUsageFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationStarterUsageToJson(this);
}
