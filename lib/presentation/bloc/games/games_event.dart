import 'package:equatable/equatable.dart';
import 'package:nookly/domain/entities/game_session.dart';
import 'package:nookly/domain/entities/game_invite.dart';
import 'package:nookly/domain/entities/game_prompt.dart';

abstract class GamesEvent extends Equatable {
  const GamesEvent();

  @override
  List<Object?> get props => [];
}

// Game invite events
class SendGameInvite extends GamesEvent {
  final String gameType;
  final String otherUserId;

  const SendGameInvite({
    required this.gameType,
    required this.otherUserId,
  });

  @override
  List<Object?> get props => [gameType, otherUserId];
}

class AcceptGameInvite extends GamesEvent {
  final String gameType;
  final String otherUserId;

  const AcceptGameInvite({
    required this.gameType,
    required this.otherUserId,
  });

  @override
  List<Object?> get props => [gameType, otherUserId];
}

class RejectGameInvite extends GamesEvent {
  final String gameType;
  final String fromUserId;
  final String? reason;

  const RejectGameInvite({
    required this.gameType,
    required this.fromUserId,
    this.reason,
  });

  @override
  List<Object?> get props => [gameType, fromUserId, reason];
}

class GameInviteReceived extends GamesEvent {
  final GameInvite gameInvite;

  const GameInviteReceived({required this.gameInvite});

  @override
  List<Object?> get props => [gameInvite];
}

class GameInviteSent extends GamesEvent {
  final String gameType;
  final String toUserId;
  final String status;

  const GameInviteSent({
    required this.gameType,
    required this.toUserId,
    required this.status,
  });

  @override
  List<Object?> get props => [gameType, toUserId, status];
}

class GameInviteAccepted extends GamesEvent {
  final String gameType;
  final String fromUserId;
  final String sessionId;

  const GameInviteAccepted({
    required this.gameType,
    required this.fromUserId,
    required this.sessionId,
  });

  @override
  List<Object?> get props => [gameType, fromUserId, sessionId];
}

class GameInviteRejected extends GamesEvent {
  final String gameType;
  final String fromUserId;
  final String reason;

  const GameInviteRejected({
    required this.gameType,
    required this.fromUserId,
    required this.reason,
  });

  @override
  List<Object?> get props => [gameType, fromUserId, reason];
}

// Game session events
class GameStarted extends GamesEvent {
  final GameSession gameSession;

  const GameStarted({required this.gameSession});

  @override
  List<Object?> get props => [gameSession];
}

class SelectGameChoice extends GamesEvent {
  final String choice; // 'truth' or 'thrill'
  final String currentUserId;

  const SelectGameChoice({
    required this.choice,
    required this.currentUserId,
  });

  @override
  List<Object?> get props => [choice, currentUserId];
}

class CompleteGameTurn extends GamesEvent {
  final String sessionId;
  final String? selectedChoice;
  final Map<String, dynamic> selectedPrompt;

  const CompleteGameTurn({
    required this.sessionId,
    this.selectedChoice,
    required this.selectedPrompt,
  });

  @override
  List<Object?> get props => [sessionId, selectedChoice, selectedPrompt];
}

class GameTurnSwitched extends GamesEvent {
  final String sessionId;
  final Turn newTurn;
  final GamePrompt nextPrompt;
  final GameProgress gameProgress;

  const GameTurnSwitched({
    required this.sessionId,
    required this.newTurn,
    required this.nextPrompt,
    required this.gameProgress,
  });

  @override
  List<Object?> get props => [sessionId, newTurn, nextPrompt, gameProgress];
}

class GameChoiceMade extends GamesEvent {
  final String sessionId;
  final String choice;
  final Prompt selectedPrompt;
  final String madeBy;

  const GameChoiceMade({
    required this.sessionId,
    required this.choice,
    required this.selectedPrompt,
    required this.madeBy,
  });

  @override
  List<Object?> get props => [sessionId, choice, selectedPrompt, madeBy];
}

class EndGame extends GamesEvent {
  final String sessionId;
  final String reason;

  const EndGame({
    required this.sessionId,
    required this.reason,
  });

  @override
  List<Object?> get props => [sessionId, reason];
}

class GameEnded extends GamesEvent {
  final String sessionId;
  final String reason;
  final Map<String, dynamic>? finalStats;

  const GameEnded({
    required this.sessionId,
    required this.reason,
    this.finalStats,
  });

  @override
  List<Object?> get props => [sessionId, reason, finalStats];
}

// Timeout events
class GameInviteTimeout extends GamesEvent {
  final String sessionId;

  const GameInviteTimeout({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

class GameTurnTimeout extends GamesEvent {
  final String sessionId;

  const GameTurnTimeout({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

class GameSessionTimeout extends GamesEvent {
  final String sessionId;

  const GameSessionTimeout({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

// UI events
class ShowGameMenu extends GamesEvent {
  const ShowGameMenu();
}

class HideGameMenu extends GamesEvent {
  const HideGameMenu();
}

class SelectGame extends GamesEvent {
  final GameType gameType;
  
  const SelectGame({required this.gameType});
  
  @override
  List<Object?> get props => [gameType];
}

class ShowGameInviteModal extends GamesEvent {
  final GameInvite gameInvite;

  const ShowGameInviteModal({required this.gameInvite});

  @override
  List<Object?> get props => [gameInvite];
}

class HideGameInviteModal extends GamesEvent {
  const HideGameInviteModal();
}

// Cleanup events
class ClearGameState extends GamesEvent {
  const ClearGameState();
}

class ClearGameInvite extends GamesEvent {
  const ClearGameInvite();
}
