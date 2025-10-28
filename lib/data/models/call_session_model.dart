import 'package:json_annotation/json_annotation.dart';

part 'call_session_model.g.dart';

@JsonSerializable()
class CallSessionModel {
  final String id;
  final String roomId;
  final String hmsRoomId;
  final String callerId;
  final String receiverId;
  final String callType;
  final String status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? duration;
  final DateTime createdAt;
  final DateTime updatedAt;

  CallSessionModel({
    required this.id,
    required this.roomId,
    required this.hmsRoomId,
    required this.callerId,
    required this.receiverId,
    required this.callType,
    required this.status,
    this.startedAt,
    this.endedAt,
    this.duration,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CallSessionModel.fromJson(Map<String, dynamic> json) =>
      _$CallSessionModelFromJson(json);

  Map<String, dynamic> toJson() => _$CallSessionModelToJson(this);
}

@JsonSerializable()
class CallUserModel {
  final String id;
  final String name;
  final String? profilePicture;

  CallUserModel({
    required this.id,
    required this.name,
    this.profilePicture,
  });

  factory CallUserModel.fromJson(Map<String, dynamic> json) =>
      _$CallUserModelFromJson(json);

  Map<String, dynamic> toJson() => _$CallUserModelToJson(this);
}

@JsonSerializable()
class CallTokensModel {
  final String caller;
  final String receiver;

  CallTokensModel({
    required this.caller,
    required this.receiver,
  });

  factory CallTokensModel.fromJson(Map<String, dynamic> json) =>
      _$CallTokensModelFromJson(json);

  Map<String, dynamic> toJson() => _$CallTokensModelToJson(this);
}

@JsonSerializable()
class CallHistoryResponseModel {
  final List<CallSessionModel> calls;
  final PaginationModel pagination;

  CallHistoryResponseModel({
    required this.calls,
    required this.pagination,
  });

  factory CallHistoryResponseModel.fromJson(Map<String, dynamic> json) =>
      _$CallHistoryResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$CallHistoryResponseModelToJson(this);
}

@JsonSerializable()
class PaginationModel {
  final int page;
  final int limit;
  final int total;
  final int pages;

  PaginationModel({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) =>
      _$PaginationModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationModelToJson(this);
}

