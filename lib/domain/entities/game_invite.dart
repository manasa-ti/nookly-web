import 'package:equatable/equatable.dart';
import 'package:nookly/domain/entities/game_session.dart';

enum GameInviteStatus {
  pending,
  accepted,
  rejected,
  timeout,
}

class GameInvite extends Equatable {
  final String gameType;
  final String fromUserId;
  final String? fromUserName;
  final String? toUserId;
  final GameInviteStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? reason; // For rejection/timeout

  const GameInvite({
    required this.gameType,
    required this.fromUserId,
    this.fromUserName,
    this.toUserId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.reason,
  });

  @override
  List<Object?> get props => [
        gameType,
        fromUserId,
        fromUserName,
        toUserId,
        status,
        createdAt,
        respondedAt,
        reason,
      ];

  GameInvite copyWith({
    String? gameType,
    String? fromUserId,
    String? fromUserName,
    String? toUserId,
    GameInviteStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? reason,
  }) {
    return GameInvite(
      gameType: gameType ?? this.gameType,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      toUserId: toUserId ?? this.toUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      reason: reason ?? this.reason,
    );
  }

  factory GameInvite.fromJson(Map<String, dynamic> json) {
    return GameInvite(
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

  String get gameTypeDisplayName {
    return GameType.fromApiValue(gameType).displayName;
  }
}





