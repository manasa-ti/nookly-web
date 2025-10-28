// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CallSessionModel _$CallSessionModelFromJson(Map<String, dynamic> json) =>
    CallSessionModel(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      hmsRoomId: json['hmsRoomId'] as String,
      callerId: json['callerId'] as String,
      receiverId: json['receiverId'] as String,
      callType: json['callType'] as String,
      status: json['status'] as String,
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      duration: (json['duration'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$CallSessionModelToJson(CallSessionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'roomId': instance.roomId,
      'hmsRoomId': instance.hmsRoomId,
      'callerId': instance.callerId,
      'receiverId': instance.receiverId,
      'callType': instance.callType,
      'status': instance.status,
      'startedAt': instance.startedAt?.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
      'duration': instance.duration,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

CallUserModel _$CallUserModelFromJson(Map<String, dynamic> json) =>
    CallUserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      profilePicture: json['profilePicture'] as String?,
    );

Map<String, dynamic> _$CallUserModelToJson(CallUserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'profilePicture': instance.profilePicture,
    };

CallTokensModel _$CallTokensModelFromJson(Map<String, dynamic> json) =>
    CallTokensModel(
      caller: json['caller'] as String,
      receiver: json['receiver'] as String,
    );

Map<String, dynamic> _$CallTokensModelToJson(CallTokensModel instance) =>
    <String, dynamic>{
      'caller': instance.caller,
      'receiver': instance.receiver,
    };

CallHistoryResponseModel _$CallHistoryResponseModelFromJson(
        Map<String, dynamic> json) =>
    CallHistoryResponseModel(
      calls: (json['calls'] as List<dynamic>)
          .map((e) => CallSessionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          PaginationModel.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CallHistoryResponseModelToJson(
        CallHistoryResponseModel instance) =>
    <String, dynamic>{
      'calls': instance.calls,
      'pagination': instance.pagination,
    };

PaginationModel _$PaginationModelFromJson(Map<String, dynamic> json) =>
    PaginationModel(
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      pages: (json['pages'] as num).toInt(),
    );

Map<String, dynamic> _$PaginationModelToJson(PaginationModel instance) =>
    <String, dynamic>{
      'page': instance.page,
      'limit': instance.limit,
      'total': instance.total,
      'pages': instance.pages,
    };
