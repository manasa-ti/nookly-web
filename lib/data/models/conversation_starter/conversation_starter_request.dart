import 'package:json_annotation/json_annotation.dart';

part 'conversation_starter_request.g.dart';

@JsonSerializable()
class ConversationStarterRequest {
  final String matchUserId;
  final ConversationStarterContext? context;

  const ConversationStarterRequest({
    required this.matchUserId,
    this.context,
  });

  factory ConversationStarterRequest.fromJson(Map<String, dynamic> json) =>
      _$ConversationStarterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationStarterRequestToJson(this);
}

@JsonSerializable()
class ConversationStarterContext {
  final int? n;
  final String? locale;
  final List<String>? priorMessages;

  const ConversationStarterContext({
    this.n,
    this.locale,
    this.priorMessages,
  });

  factory ConversationStarterContext.fromJson(Map<String, dynamic> json) =>
      _$ConversationStarterContextFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationStarterContextToJson(this);
}
