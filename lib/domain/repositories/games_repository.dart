import 'dart:async';
import 'package:nookly/domain/entities/game_session.dart';
import 'package:nookly/domain/entities/game_invite.dart';

abstract class GamesRepository {
  // Game invite methods
  Future<void> sendGameInvite({
    required String gameType,
    required String otherUserId,
  });

  Future<void> acceptGameInvite({
    required String gameType,
    required String otherUserId,
  });

  Future<void> rejectGameInvite({
    required String gameType,
    required String fromUserId,
    String? reason,
  });

  // Game session methods
  Future<void> sendGameChoice({
    required String sessionId,
    required String choice,
    required Map<String, dynamic> selectedPrompt,
    required String madeBy,
  });

  Future<void> completeGameTurn({
    required String sessionId,
    String? selectedChoice,
    required Map<String, dynamic> selectedPrompt,
  });

  Future<void> endGame({
    required String sessionId,
    required String reason,
  });

  // Game state management
  Future<void> updateGameState(GameSession gameSession);
  Future<GameSession?> getCurrentGameSession();
  Future<void> clearGameSession();

  // Game invite management
  Future<void> updateGameInvite(GameInvite gameInvite);
  Future<GameInvite?> getPendingGameInvite();
  Future<void> clearGameInvite();

  // Stream getters for real-time events
  Stream<GameInvite> get onGameInviteReceived;
  Stream<GameInvite> get onGameInviteSent;
  Stream<GameInvite> get onGameInviteRejected;
  Stream<GameSession> get onGameStarted;
  Stream<Map<String, dynamic>> get onGameTurnSwitched;
  Stream<Map<String, dynamic>> get onGameEnded;
}
