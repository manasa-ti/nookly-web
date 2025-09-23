import 'package:equatable/equatable.dart';
import 'package:nookly/domain/entities/game_session.dart';
import 'package:nookly/domain/entities/game_invite.dart';

abstract class GamesState extends Equatable {
  const GamesState();

  @override
  List<Object?> get props => [];
}

// Initial state
class GamesInitial extends GamesState {
  const GamesInitial();
}

// Game invite states
class GameInvitePending extends GamesState {
  final String gameType;
  final String otherUserId;

  const GameInvitePending({
    required this.gameType,
    required this.otherUserId,
  });

  @override
  List<Object?> get props => [gameType, otherUserId];
}

class GameInviteReceivedState extends GamesState {
  final GameInvite gameInvite;

  const GameInviteReceivedState({required this.gameInvite});

  @override
  List<Object?> get props => [gameInvite];
}

class GameInviteSentState extends GamesState {
  final String gameType;
  final String toUserId;

  const GameInviteSentState({
    required this.gameType,
    required this.toUserId,
  });

  @override
  List<Object?> get props => [gameType, toUserId];
}

class GameInviteRejectedState extends GamesState {
  final String gameType;
  final String fromUserId;
  final String reason;

  const GameInviteRejectedState({
    required this.gameType,
    required this.fromUserId,
    required this.reason,
  });

  @override
  List<Object?> get props => [gameType, fromUserId, reason];
}

// Game session states
class GameActive extends GamesState {
  final GameSession gameSession;

  const GameActive({required this.gameSession});

  @override
  List<Object?> get props => [gameSession];
}

class GameTurnCompleted extends GamesState {
  final GameSession gameSession;

  const GameTurnCompleted({required this.gameSession});

  @override
  List<Object?> get props => [gameSession];
}

class GameEndedState extends GamesState {
  final String sessionId;
  final String reason;
  final Map<String, dynamic>? finalStats;

  const GameEndedState({
    required this.sessionId,
    required this.reason,
    this.finalStats,
  });

  @override
  List<Object?> get props => [sessionId, reason, finalStats];
}

// UI states
class GameMenuVisible extends GamesState {
  const GameMenuVisible();
}

class GameInviteModalVisible extends GamesState {
  final GameInvite gameInvite;

  const GameInviteModalVisible({required this.gameInvite});

  @override
  List<Object?> get props => [gameInvite];
}

// Error states
class GamesError extends GamesState {
  final String message;

  const GamesError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Loading states
class GamesLoading extends GamesState {
  final String message;

  const GamesLoading({required this.message});

  @override
  List<Object?> get props => [message];
}
