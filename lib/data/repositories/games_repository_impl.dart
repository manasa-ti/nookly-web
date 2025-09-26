import 'dart:async';

import 'package:nookly/domain/repositories/games_repository.dart';
import 'package:nookly/domain/entities/game_session.dart';
import 'package:nookly/domain/entities/game_invite.dart';
import 'package:nookly/core/network/socket_service.dart';
import 'package:nookly/core/utils/logger.dart';

class GamesRepositoryImpl implements GamesRepository {
  final SocketService _socketService;

  GamesRepositoryImpl({required SocketService socketService})
      : _socketService = socketService;

  final _gameInviteReceivedController = StreamController<GameInvite>.broadcast();
  final _gameInviteSentController = StreamController<GameInvite>.broadcast();
  final _gameInviteRejectedController = StreamController<GameInvite>.broadcast();
  final _gameStartedController = StreamController<GameSession>.broadcast();
  final _gameTurnSwitchedController = StreamController<Map<String, dynamic>>.broadcast();
  final _gameEndedController = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<GameInvite> get onGameInviteReceived => _gameInviteReceivedController.stream;
  @override
  Stream<GameInvite> get onGameInviteSent => _gameInviteSentController.stream;
  @override
  Stream<GameInvite> get onGameInviteRejected => _gameInviteRejectedController.stream;
  @override
  Stream<GameSession> get onGameStarted => _gameStartedController.stream;
  @override
  Stream<Map<String, dynamic>> get onGameTurnSwitched => _gameTurnSwitchedController.stream;
  @override
  Stream<Map<String, dynamic>> get onGameEnded => _gameEndedController.stream;


  @override
  Future<void> sendGameInvite({
    required String gameType,
    required String otherUserId,
    required String conversationId,
  }) async {
    try {
      AppLogger.info('🎮 GamesRepository: sendGameInvite called');
      AppLogger.info('🎮 - gameType: $gameType');
      AppLogger.info('🎮 - otherUserId: $otherUserId');
      AppLogger.info('🎮 - conversationId: $conversationId');
      AppLogger.info('🎮 - socketService available: ${_socketService != null}');
      AppLogger.info('🎮 - socket connected: ${_socketService.isConnected}');
      
      final eventData = {
        'gameType': gameType,
        'otherUserId': otherUserId,
        'conversationId': conversationId, // NEW: Use actual conversation ID for room-based broadcasting
      };
      
      AppLogger.info('🎮 Emitting game_invite event with data: $eventData');
      _socketService.emit('game_invite', eventData);
      AppLogger.info('✅ GamesRepository: game_invite event emitted successfully');
    } catch (e) {
      AppLogger.error('❌ GamesRepository: Failed to send game invite: $e');
      rethrow;
    }
  }

  @override
  Future<void> acceptGameInvite({
    required String gameType,
    required String otherUserId,
  }) async {
    try {
      AppLogger.info('🎮 GamesRepository: acceptGameInvite called');
      AppLogger.info('🎮 - gameType: $gameType');
      AppLogger.info('🎮 - otherUserId: $otherUserId');
      AppLogger.info('🎮 - socketService available: ${_socketService != null}');
      AppLogger.info('🎮 - socket connected: ${_socketService.isConnected}');
      
      final eventData = {
        'gameType': gameType,
        'otherUserId': otherUserId,
        'conversationId': otherUserId, // NEW: Required for room-based broadcasting
      };
      
      AppLogger.info('🎮 Emitting game_invite_accepted event with data: $eventData');
      _socketService.emit('game_invite_accepted', eventData);
      AppLogger.info('✅ GamesRepository: game_invite_accepted event emitted successfully');
    } catch (e) {
      AppLogger.error('❌ GamesRepository: Failed to accept game invite: $e');
      rethrow;
    }
  }

  @override
  Future<void> rejectGameInvite({
    required String gameType,
    required String fromUserId,
    String? reason,
  }) async {
    try {
      AppLogger.info('🎮 GamesRepository: rejectGameInvite called');
      AppLogger.info('🎮 - gameType: $gameType');
      AppLogger.info('🎮 - fromUserId: $fromUserId');
      AppLogger.info('🎮 - reason: $reason');
      AppLogger.info('🎮 - socketService available: ${_socketService != null}');
      AppLogger.info('🎮 - socket connected: ${_socketService.isConnected}');
      
      final eventData = {
        'gameType': gameType,
        'fromUserId': fromUserId,
        'reason': reason ?? 'declined',
        'conversationId': fromUserId, // NEW: Required for room-based broadcasting
      };
      
      AppLogger.info('🎮 Emitting game_invite_rejected event with data: $eventData');
      _socketService.emit('game_invite_rejected', eventData);
      AppLogger.info('✅ GamesRepository: game_invite_rejected event emitted successfully');
    } catch (e) {
      AppLogger.error('❌ GamesRepository: Failed to reject game invite: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendGameChoice({
    required String sessionId,
    required String choice,
    required Map<String, dynamic> selectedPrompt,
    required String madeBy,
    required String conversationId,
  }) async {
    try {
      AppLogger.info('🎮 GamesRepository: Sending game choice for session: $sessionId');
      AppLogger.info('🎮 - choice: $choice');
      AppLogger.info('🎮 - selectedPrompt: $selectedPrompt');
      AppLogger.info('🎮 - madeBy: $madeBy');
      
      final eventData = {
        'sessionId': sessionId,
        'choice': choice,
        'selectedPrompt': selectedPrompt,
        'madeBy': madeBy,
        'conversationId': conversationId, // NEW: Required for room-based broadcasting
      };
      
      AppLogger.info('🎮 ===== EMITTING GAME_CHOICE_MADE EVENT =====');
      AppLogger.info('🎮 Emitting game_choice_made event with data: $eventData');
      _socketService.emit('game_choice_made', eventData);
      AppLogger.info('🎮 ===== GAME_CHOICE_MADE EVENT EMITTED SUCCESSFULLY =====');
    } catch (e) {
      AppLogger.error('❌ Failed to send game choice: $e');
      rethrow;
    }
  }

  @override
  Future<void> completeGameTurn({
    required String sessionId,
    String? selectedChoice,
    required Map<String, dynamic> selectedPrompt,
    required String conversationId,
  }) async {
    try {
      AppLogger.info('🎮 GamesRepository: completeGameTurn called');
      AppLogger.info('🎮 - sessionId: $sessionId');
      AppLogger.info('🎮 - selectedChoice: $selectedChoice');
      AppLogger.info('🎮 - selectedPrompt: $selectedPrompt');
      AppLogger.info('🎮 - socketService available: ${_socketService != null}');
      AppLogger.info('🎮 - socket connected: ${_socketService.isConnected}');
      
      final eventData = {
        'sessionId': sessionId,
        'selectedChoice': selectedChoice,
        'selectedPrompt': selectedPrompt,
        'conversationId': conversationId, // NEW: Required for room-based broadcasting
      };
      
      AppLogger.info('🎮 Emitting game_turn_completed event with data: $eventData');
      _socketService.emit('game_turn_completed', eventData);
      AppLogger.info('✅ GamesRepository: game_turn_completed event emitted successfully');
    } catch (e) {
      AppLogger.error('❌ GamesRepository: Failed to complete game turn: $e');
      rethrow;
    }
  }

  @override
  Future<void> endGame({
    required String sessionId,
    required String reason,
    required String conversationId,
  }) async {
    try {
      AppLogger.info('🎮 GamesRepository: endGame called');
      AppLogger.info('🎮 - sessionId: $sessionId');
      AppLogger.info('🎮 - reason: $reason');
      AppLogger.info('🎮 - socketService available: ${_socketService != null}');
      AppLogger.info('🎮 - socket connected: ${_socketService.isConnected}');
      
      final eventData = {
        'sessionId': sessionId,
        'reason': reason,
        'conversationId': conversationId, // NEW: Required for room-based broadcasting
      };
      
      AppLogger.info('🎮 Emitting game_ended event with data: $eventData');
      _socketService.emit('game_ended', eventData);
      AppLogger.info('✅ GamesRepository: game_ended event emitted successfully');
    } catch (e) {
      AppLogger.error('❌ GamesRepository: Failed to end game: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateGameState(GameSession gameSession) async {
    // This would typically update local storage or cache
    // For now, we'll just log the update
    AppLogger.info('🎮 Updating game state: ${gameSession.sessionId}');
  }

  @override
  Future<GameSession?> getCurrentGameSession() async {
    // This would typically retrieve from local storage or cache
    // For now, return null as game state is managed by the bloc
    return null;
  }

  @override
  Future<void> clearGameSession() async {
    // This would typically clear local storage or cache
    AppLogger.info('🎮 Clearing game session');
  }

  @override
  Future<void> updateGameInvite(GameInvite gameInvite) async {
    // This would typically update local storage or cache
    AppLogger.info('🎮 Updating game invite: ${gameInvite.gameType}');
  }

  @override
  Future<GameInvite?> getPendingGameInvite() async {
    // This would typically retrieve from local storage or cache
    // For now, return null as invite state is managed by the bloc
    return null;
  }

  @override
  Future<void> clearGameInvite() async {
    // This would typically clear local storage or cache
    AppLogger.info('🎮 Clearing game invite');
  }
}
