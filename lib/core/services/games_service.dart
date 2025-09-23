import 'dart:async';
import 'package:nookly/domain/entities/game_session.dart';
import 'package:nookly/domain/entities/game_invite.dart';
import 'package:nookly/domain/repositories/games_repository.dart';
import 'package:nookly/core/utils/logger.dart';

class GameConfig {
  static const Duration inviteTimeout = Duration(minutes: 2);
  static const Duration turnTimeout = Duration(minutes: 2);
  static const Duration sessionTimeout = Duration(minutes: 10);
  static const Duration reconnectTimeout = Duration(seconds: 5);
}

class GameTimeoutManager {
  Timer? _inviteTimeout;
  Timer? _turnTimeout;
  Timer? _sessionTimeout;
  final Function(String) onInviteTimeout;
  final Function(String) onTurnTimeout;
  final Function(String) onSessionTimeout;

  GameTimeoutManager({
    required this.onInviteTimeout,
    required this.onTurnTimeout,
    required this.onSessionTimeout,
  });

  void startInviteTimeout(String sessionId) {
    _cancelInviteTimeout();
    AppLogger.info('🎮 Starting invite timeout for session: $sessionId');
    
    _inviteTimeout = Timer(GameConfig.inviteTimeout, () {
      AppLogger.warning('⏰ Game invite timeout for session: $sessionId');
      onInviteTimeout(sessionId);
    });
  }

  void startTurnTimeout(String sessionId) {
    _cancelTurnTimeout();
    AppLogger.info('🎮 Starting turn timeout for session: $sessionId');
    
    _turnTimeout = Timer(GameConfig.turnTimeout, () {
      AppLogger.warning('⏰ Game turn timeout for session: $sessionId');
      onTurnTimeout(sessionId);
    });
  }

  void startSessionTimeout(String sessionId) {
    _cancelSessionTimeout();
    AppLogger.info('🎮 Starting session timeout for session: $sessionId');
    
    _sessionTimeout = Timer(GameConfig.sessionTimeout, () {
      AppLogger.warning('⏰ Game session timeout for session: $sessionId');
      onSessionTimeout(sessionId);
    });
  }

  void cancelTimeouts() {
    _cancelInviteTimeout();
    _cancelTurnTimeout();
    _cancelSessionTimeout();
    AppLogger.info('🎮 All game timeouts cancelled');
  }

  void clearInviteTimeout() {
    _cancelInviteTimeout();
    AppLogger.info('🎮 Game invite timeout cleared');
  }

  void _cancelInviteTimeout() {
    _inviteTimeout?.cancel();
    _inviteTimeout = null;
  }

  void _cancelTurnTimeout() {
    _turnTimeout?.cancel();
    _turnTimeout = null;
  }

  void _cancelSessionTimeout() {
    _sessionTimeout?.cancel();
    _sessionTimeout = null;
  }

  void dispose() {
    cancelTimeouts();
  }
}

class GamesService {
  final GamesRepository _gamesRepository;
  final GameTimeoutManager _timeoutManager;

  GamesService({
    required GamesRepository gamesRepository,
    required GameTimeoutManager timeoutManager,
  }) : _gamesRepository = gamesRepository,
       _timeoutManager = timeoutManager;

  GamesRepository get gamesRepository => _gamesRepository;

  // Game invite methods
  Future<void> sendGameInvite({
    required String gameType,
    required String otherUserId,
  }) async {
    try {
      await _gamesRepository.sendGameInvite(
        gameType: gameType,
        otherUserId: otherUserId,
      );
      
      // Start invite timeout - COMMENTED OUT
      // _timeoutManager.startInviteTimeout('${gameType}_${otherUserId}');
      
      AppLogger.info('🎮 Game invite sent successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to send game invite: $e');
      rethrow;
    }
  }

  Future<void> acceptGameInvite({
    required String gameType,
    required String otherUserId,
  }) async {
    try {
      await _gamesRepository.acceptGameInvite(
        gameType: gameType,
        otherUserId: otherUserId,
      );
      
      AppLogger.info('🎮 Game invite accepted successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to accept game invite: $e');
      rethrow;
    }
  }

  Future<void> rejectGameInvite({
    required String gameType,
    required String fromUserId,
    String? reason,
  }) async {
    try {
      await _gamesRepository.rejectGameInvite(
        gameType: gameType,
        fromUserId: fromUserId,
        reason: reason,
      );
      
      AppLogger.info('🎮 Game invite rejected successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to reject game invite: $e');
      rethrow;
    }
  }

  // Game session methods
  Future<void> completeGameTurn({
    required String sessionId,
    String? selectedChoice,
    required Map<String, dynamic> selectedPrompt,
  }) async {
    AppLogger.info('🎮 GamesService: completeGameTurn called');
    AppLogger.info('🎮 - sessionId: $sessionId');
    AppLogger.info('🎮 - selectedChoice: $selectedChoice');
    AppLogger.info('🎮 - selectedPrompt: $selectedPrompt');
    AppLogger.info('🎮 - GamesRepository instance: ${_gamesRepository.hashCode}');
    
    try {
      AppLogger.info('🎮 GamesService: Calling repository.completeGameTurn...');
      await _gamesRepository.completeGameTurn(
        sessionId: sessionId,
        selectedChoice: selectedChoice,
        selectedPrompt: selectedPrompt,
      );
      
      AppLogger.info('🎮 GamesService: completeGameTurn repository call completed');
      
      // Start turn timeout for the next turn
      _timeoutManager.startTurnTimeout(sessionId);
      
      AppLogger.info('🎮 Game turn completed successfully');
    } catch (e) {
      AppLogger.error('❌ GamesService: Failed to complete game turn: $e');
      AppLogger.error('❌ GamesService: Error stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<void> endGame({
    required String sessionId,
    required String reason,
  }) async {
    try {
      await _gamesRepository.endGame(
        sessionId: sessionId,
        reason: reason,
      );
      
      // Cancel all timeouts
      _timeoutManager.cancelTimeouts();
      
      AppLogger.info('🎮 Game ended successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to end game: $e');
      rethrow;
    }
  }

  // Game state management
  Future<void> updateGameState(GameSession gameSession) async {
    try {
      await _gamesRepository.updateGameState(gameSession);
      
      // Start session timeout if game is active
      if (gameSession.startedAt != null) {
        _timeoutManager.startSessionTimeout(gameSession.sessionId);
      }
      
      AppLogger.info('🎮 Game state updated successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to update game state: $e');
      rethrow;
    }
  }

  Future<GameSession?> getCurrentGameSession() async {
    try {
      return await _gamesRepository.getCurrentGameSession();
    } catch (e) {
      AppLogger.error('❌ Failed to get current game session: $e');
      return null;
    }
  }

  Future<void> clearGameSession() async {
    try {
      await _gamesRepository.clearGameSession();
      _timeoutManager.cancelTimeouts();
      AppLogger.info('🎮 Game session cleared successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to clear game session: $e');
      rethrow;
    }
  }

  // Game invite management
  Future<void> updateGameInvite(GameInvite gameInvite) async {
    try {
      await _gamesRepository.updateGameInvite(gameInvite);
      AppLogger.info('🎮 Game invite updated successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to update game invite: $e');
      rethrow;
    }
  }

  Future<GameInvite?> getPendingGameInvite() async {
    try {
      return await _gamesRepository.getPendingGameInvite();
    } catch (e) {
      AppLogger.error('❌ Failed to get pending game invite: $e');
      return null;
    }
  }

  Future<void> clearGameInvite() async {
    try {
      await _gamesRepository.clearGameInvite();
      AppLogger.info('🎮 Game invite cleared successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to clear game invite: $e');
      rethrow;
    }
  }

  void clearInviteTimeout() {
    _timeoutManager.clearInviteTimeout();
  }

  void dispose() {
    _timeoutManager.dispose();
  }
}
