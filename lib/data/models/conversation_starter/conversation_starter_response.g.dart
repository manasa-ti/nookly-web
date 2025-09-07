// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_starter_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConversationStarterResponse _$ConversationStarterResponseFromJson(
        Map<String, dynamic> json) =>
    ConversationStarterResponse(
      suggestions: (json['suggestions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      usage: ConversationStarterUsage.fromJson(
          json['usage'] as Map<String, dynamic>),
      isFallback: json['isFallback'] as bool,
    );

Map<String, dynamic> _$ConversationStarterResponseToJson(
        ConversationStarterResponse instance) =>
    <String, dynamic>{
      'suggestions': instance.suggestions,
      'usage': instance.usage,
      'isFallback': instance.isFallback,
    };

ConversationStarterUsage _$ConversationStarterUsageFromJson(
        Map<String, dynamic> json) =>
    ConversationStarterUsage(
      remaining: (json['remaining'] as num).toInt(),
      resetDate: json['resetDate'] as String,
      totalRequests: (json['totalRequests'] as num).toInt(),
    );

Map<String, dynamic> _$ConversationStarterUsageToJson(
        ConversationStarterUsage instance) =>
    <String, dynamic>{
      'remaining': instance.remaining,
      'resetDate': instance.resetDate,
      'totalRequests': instance.totalRequests,
    };
