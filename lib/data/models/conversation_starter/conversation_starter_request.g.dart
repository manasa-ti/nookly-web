// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_starter_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConversationStarterRequest _$ConversationStarterRequestFromJson(
        Map<String, dynamic> json) =>
    ConversationStarterRequest(
      matchUserId: json['matchUserId'] as String,
      context: json['context'] == null
          ? null
          : ConversationStarterContext.fromJson(
              json['context'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ConversationStarterRequestToJson(
        ConversationStarterRequest instance) =>
    <String, dynamic>{
      'matchUserId': instance.matchUserId,
      'context': instance.context,
    };

ConversationStarterContext _$ConversationStarterContextFromJson(
        Map<String, dynamic> json) =>
    ConversationStarterContext(
      n: (json['n'] as num?)?.toInt(),
      locale: json['locale'] as String?,
      priorMessages: (json['priorMessages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ConversationStarterContextToJson(
        ConversationStarterContext instance) =>
    <String, dynamic>{
      'n': instance.n,
      'locale': instance.locale,
      'priorMessages': instance.priorMessages,
    };
