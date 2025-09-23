import 'package:nookly/domain/entities/game_invite.dart';

class GameInviteModel extends GameInvite {
  const GameInviteModel({
    required super.gameType,
    required super.fromUserId,
    super.fromUserName,
    super.toUserId,
    required super.status,
    required super.createdAt,
    super.respondedAt,
    super.reason,
  });

  factory GameInviteModel.fromJson(Map<String, dynamic> json) {
    return GameInviteModel(
      gameType: json['gameType'] as String,
      fromUserId: json['fromUserId'] as String,
      fromUserName: json['fromUserName'] as String?,
      toUserId: json['toUserId'] as String?,
      status: GameInviteStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => GameInviteStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      respondedAt: json['respondedAt'] != null 
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameType': gameType,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'reason': reason,
    };
  }

  factory GameInviteModel.fromEntity(GameInvite entity) {
    return GameInviteModel(
      gameType: entity.gameType,
      fromUserId: entity.fromUserId,
      fromUserName: entity.fromUserName,
      toUserId: entity.toUserId,
      status: entity.status,
      createdAt: entity.createdAt,
      respondedAt: entity.respondedAt,
      reason: entity.reason,
    );
  }
}

