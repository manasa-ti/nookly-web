// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_starter_usage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConversationStarterUsageModel _$ConversationStarterUsageModelFromJson(
        Map<String, dynamic> json) =>
    ConversationStarterUsageModel(
      remaining: (json['remaining'] as num).toInt(),
      resetDate: DateTime.parse(json['resetDate'] as String),
      totalRequests: (json['totalRequests'] as num).toInt(),
      lastUsed: DateTime.parse(json['lastUsed'] as String),
    );

Map<String, dynamic> _$ConversationStarterUsageModelToJson(
        ConversationStarterUsageModel instance) =>
    <String, dynamic>{
      'remaining': instance.remaining,
      'resetDate': instance.resetDate.toIso8601String(),
      'totalRequests': instance.totalRequests,
      'lastUsed': instance.lastUsed.toIso8601String(),
    };
