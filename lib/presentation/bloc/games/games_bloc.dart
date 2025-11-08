import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/presentation/bloc/games/games_event.dart';
import 'package:nookly/presentation/bloc/games/games_state.dart';
import 'package:nookly/core/services/games_service.dart';
import 'package:nookly/core/services/analytics_service.dart';
import 'package:nookly/domain/entities/game_session.dart';
import 'package:nookly/domain/entities/game_prompt.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/core/di/injection_container.dart' as di;

class GamesBloc extends Bloc<GamesEvent, GamesState> {
  final GamesService _gamesService;
  final GameTimeoutManager _timeoutManager;
  final AnalyticsService? _analyticsService;

  GamesBloc({
    required GamesService gamesService,
    required GameTimeoutManager timeoutManager,
    AnalyticsService? analyticsService,
  }) : _gamesService = gamesService,
       _timeoutManager = timeoutManager,
       _analyticsService = analyticsService ?? di.sl<AnalyticsService>(),
       super(const GamesInitial()) {
    AppLogger.info('🎮 GamesBloc instance created: ${hashCode}');
    
    // Game events are now handled directly in the chat page socket listeners
    
    // Game invite events
    on<SendGameInvite>(_onSendGameInvite);
    on<AcceptGameInvite>(_onAcceptGameInvite);
    on<RejectGameInvite>(_onRejectGameInvite);
    on<GameInviteReceived>(_onGameInviteReceived);
    on<GameInviteSent>(_onGameInviteSent);
    on<GameInviteAccepted>(_onGameInviteAccepted);
    on<GameInviteRejected>(_onGameInviteRejected);
    
    // Game session events
    on<SelectGame>(_onSelectGame);
    on<GameStarted>(_onGameStarted);
    on<SelectGameChoice>(_onSelectGameChoice);
    on<CompleteGameTurn>(_onCompleteGameTurn);
    on<GameTurnSwitched>(_onGameTurnSwitched);
    on<GameChoiceMade>(_onGameChoiceMade);
    on<EndGame>(_onEndGame);
    on<GameEnded>(_onGameEnded);
    
    // Timeout events
    // on<GameInviteTimeout>(_onGameInviteTimeout);
    on<GameTurnTimeout>(_onGameTurnTimeout);
    on<GameSessionTimeout>(_onGameSessionTimeout);
    
    // UI events
    on<ShowGameMenu>(_onShowGameMenu);
    on<HideGameMenu>(_onHideGameMenu);
    on<ShowGameInviteModal>(_onShowGameInviteModal);
    on<HideGameInviteModal>(_onHideGameInviteModal);
    
    // Cleanup events
    on<ClearGameState>(_onClearGameState);
    on<ClearGameInvite>(_onClearGameInvite);
  }

  // Game invite event handlers
  Future<void> _onSendGameInvite(
    SendGameInvite event,
    Emitter<GamesState> emit,
  ) async {
    try {
      emit(const GamesLoading(message: 'Sending game invite...'));
      
      await _gamesService.sendGameInvite(
        gameType: event.gameType,
        otherUserId: event.otherUserId,
        conversationId: event.conversationId,
      );
      
      // Track game invite sent
      // Convert gameType string to display name
      final gameName = _getGameDisplayName(event.gameType);
      _analyticsService?.logGameInviteSent(
        gameName: gameName,
        recipientUserId: event.otherUserId,
      );
      
      emit(GameInviteSentState(
        gameType: event.gameType,
        toUserId: event.otherUserId,
      ));
    } catch (e) {
      AppLogger.error('❌ Failed to send game invite: $e');
      emit(GamesError(message: 'Failed to send game invite: $e'));
    }
  }

  Future<void> _onAcceptGameInvite(
    AcceptGameInvite event,
    Emitter<GamesState> emit,
  ) async {
    try {
      emit(const GamesLoading(message: 'Accepting game invite...'));
      
      await _gamesService.acceptGameInvite(
        gameType: event.gameType,
        otherUserId: event.otherUserId,
      );
      
      // State will be updated when game_started event is received
    } catch (e) {
      AppLogger.error('❌ Failed to accept game invite: $e');
      emit(GamesError(message: 'Failed to accept game invite: $e'));
    }
  }

  Future<void> _onRejectGameInvite(
    RejectGameInvite event,
    Emitter<GamesState> emit,
  ) async {
    try {
      await _gamesService.rejectGameInvite(
        gameType: event.gameType,
        fromUserId: event.fromUserId,
        reason: event.reason,
      );
      
      emit(const GamesInitial());
    } catch (e) {
      AppLogger.error('❌ Failed to reject game invite: $e');
      emit(GamesError(message: 'Failed to reject game invite: $e'));
    }
  }

  void _onGameInviteReceived(
    GameInviteReceived event,
    Emitter<GamesState> emit,
  ) {
    AppLogger.info('🎮 Game invite received: ${event.gameInvite.gameType}');
    emit(GameInviteReceivedState(gameInvite: event.gameInvite));
  }

  void _onGameInviteSent(
    GameInviteSent event,
    Emitter<GamesState> emit,
  ) {
    AppLogger.info('🎮 Game invite sent: ${event.gameType}');
    emit(GameInviteSentState(
      gameType: event.gameType,
      toUserId: event.toUserId,
    ));
  }

  void _onGameInviteAccepted(
    GameInviteAccepted event,
    Emitter<GamesState> emit,
  ) {
    AppLogger.info('🎮 Game invite accepted: ${event.gameType}');
    AppLogger.info('🎮 Session ID: ${event.sessionId}');
    // The game will start automatically, so we don't need to emit a specific state
    // The GameStarted event will handle the transition to GameActive state
  }

  void _onGameInviteRejected(
    GameInviteRejected event,
    Emitter<GamesState> emit,
  ) {
    AppLogger.info('🎮 Game invite rejected: ${event.gameType} - ${event.reason}');
    emit(GameInviteRejectedState(
      gameType: event.gameType,
      fromUserId: event.fromUserId,
      reason: event.reason,
    ));
  }

  // Game session event handlers
  void _onGameStarted(
    GameStarted event,
    Emitter<GamesState> emit,
  ) {
    AppLogger.info('🎮 GamesBloc: Received GameStarted event');
    AppLogger.info('🎮 - Current state before processing: ${state.runtimeType}');
    AppLogger.info('🎮 - sessionId: ${event.gameSession.sessionId}');
    AppLogger.info('🎮 - gameType: ${event.gameSession.gameType.displayName}');
    AppLogger.info('🎮 - currentTurn: ${event.gameSession.currentTurn.userId}');
    AppLogger.info('🎮 - selectedChoice: ${event.gameSession.selectedChoice}');
    
    // Track game started
    final players = event.gameSession.players;
    if (players.length >= 2) {
      _analyticsService?.logGameStarted(
        gameName: event.gameSession.gameType.displayName,
        user1Id: players[0].userId,
        user2Id: players[1].userId,
      );
    }
    
    // Clear the invite timeout since the game has started
    // _gamesService.clearInviteTimeout();
    // AppLogger.info('🎮 Game invite timeout cleared');
    
    AppLogger.info('🎮 Emitting GameActive state');
    emit(GameActive(gameSession: event.gameSession));
    AppLogger.info('✅ GameActive state emitted successfully');
    AppLogger.info('🎮 - New state after emitting: ${state.runtimeType}');
  }

  void _onSelectGameChoice(
    SelectGameChoice event,
    Emitter<GamesState> emit,
  ) {
    AppLogger.info('🎮 GamesBloc: Received SelectGameChoice event');
    AppLogger.info('🎮 - choice: ${event.choice}');
    AppLogger.info('🎮 - currentUserId: ${event.currentUserId}');
    
    if (state is GameActive) {
      final currentState = state as GameActive;
      AppLogger.info('🎮 Current state is GameActive, updating session with choice...');
      
      final updatedSession = currentState.gameSession.copyWith(
        selectedChoice: event.choice,
        lastActivityAt: DateTime.now(),
      );
      
      AppLogger.info('🎮 Emitting updated GameActive state with choice');
      emit(GameActive(gameSession: updatedSession));
      
      // Emit the choice to the server so other players can see it
      AppLogger.info('🎮 Emitting game choice to server...');
      
      // Get the selected prompt based on the choice
      Map<String, dynamic> selectedPrompt;
      if (event.choice == 'truth') {
        selectedPrompt = currentState.gameSession.currentPrompt.truthOrThrill!.truth.toJson();
      } else {
        selectedPrompt = currentState.gameSession.currentPrompt.truthOrThrill!.thrill.toJson();
      }
      
      AppLogger.info('🎮 About to send game choice with:');
      AppLogger.info('🎮 - sessionId: ${currentState.gameSession.sessionId}');
      AppLogger.info('🎮 - choice: ${event.choice}');
      AppLogger.info('🎮 - madeBy: ${event.currentUserId}');
      AppLogger.info('🎮 - currentTurn.userId: ${currentState.gameSession.currentTurn.userId}');
      AppLogger.info('🎮 - isCurrentUserTurn: ${currentState.gameSession.isCurrentUserTurn(event.currentUserId)}');
      
      _gamesService.gamesRepository.sendGameChoice(
        sessionId: currentState.gameSession.sessionId,
        choice: event.choice,
        selectedPrompt: selectedPrompt,
        madeBy: event.currentUserId,
        conversationId: event.conversationId,
      );
    } else {
      AppLogger.warning('🎮 Current state is not GameActive: ${state.runtimeType}');
    }
  }

  Future<void> _onCompleteGameTurn(
    CompleteGameTurn event,
    Emitter<GamesState> emit,
  ) async {
    AppLogger.info('🎮 GamesBloc: Received CompleteGameTurn event');
    AppLogger.info('🎮 - sessionId: ${event.sessionId}');
    AppLogger.info('🎮 - selectedChoice: ${event.selectedChoice}');
    AppLogger.info('🎮 - selectedPrompt: ${event.selectedPrompt}');
    AppLogger.info('🎮 - Current state: ${state.runtimeType}');
    AppLogger.info('🎮 - GamesService instance: ${_gamesService.hashCode}');
    
    try {
      AppLogger.info('🎮 Calling gamesService.completeGameTurn...');
      await _gamesService.completeGameTurn(
        sessionId: event.sessionId,
        selectedChoice: event.selectedChoice,
        selectedPrompt: event.selectedPrompt,
        conversationId: event.conversationId,
      );
      AppLogger.info('🎮 Successfully called gamesService.completeGameTurn');
      
      if (state is GameActive) {
        final currentState = state as GameActive;
        AppLogger.info('🎮 Emitting GameTurnCompleted state');
        emit(GameTurnCompleted(gameSession: currentState.gameSession));
        AppLogger.info('✅ GameTurnCompleted state emitted successfully');
      } else {
        AppLogger.warning('🎮 Current state is not GameActive: ${state.runtimeType}');
        AppLogger.warning('🎮 Cannot emit GameTurnCompleted state');
      }
    } catch (e) {
      AppLogger.error('❌ Failed to complete game turn: $e');
      AppLogger.error('❌ Error stack trace: ${StackTrace.current}');
      emit(GamesError(message: 'Failed to complete game turn: $e'));
    }
  }

  void _onGameTurnSwitched(
    GameTurnSwitched event,
    Emitter<GamesState> emit,
  ) {
    AppLogger.info('🎮 GamesBloc: Received GameTurnSwitched event');
    AppLogger.info('🎮 - sessionId: ${event.sessionId}');
    AppLogger.info('🎮 - newTurn: ${event.newTurn.toJson()}');
    AppLogger.info('🎮 - nextPrompt: ${event.nextPrompt.toJson()}');
    AppLogger.info('🎮 - gameProgress: ${event.gameProgress?.toJson()}');
    
    if (state is GameActive) {
      final currentState = state as GameActive;
      AppLogger.info('🎮 Current state is GameActive, updating session...');
      final updatedSession = currentState.gameSession.copyWith(
        currentTurn: event.newTurn,
        currentPrompt: event.nextPrompt,
        clearSelectedChoice: true, // Reset for new turn
        gameProgress: event.gameProgress,
        lastActivityAt: DateTime.now(),
      );
      AppLogger.info('🎮 Emitting updated GameActive state');
      AppLogger.info('🎮 - selectedChoice reset to: ${updatedSession.selectedChoice}');
      AppLogger.info('🎮 - currentTurn: ${updatedSession.currentTurn.userId}');
      AppLogger.info('🎮 - This should show Truth/Thrill buttons for the new turn user');
      emit(GameActive(gameSession: updatedSession));
    } else if (state is GameTurnCompleted) {
      final currentState = state as GameTurnCompleted;
      AppLogger.info('🎮 Current state is GameTurnCompleted, transitioning to GameActive...');
      final updatedSession = currentState.gameSession.copyWith(
        currentTurn: event.newTurn,
        currentPrompt: event.nextPrompt,
        clearSelectedChoice: true, // Reset for new turn
        gameProgress: event.gameProgress,
        lastActivityAt: DateTime.now(),
      );
      AppLogger.info('🎮 Emitting GameActive state from GameTurnCompleted');
      AppLogger.info('🎮 - selectedChoice reset to: ${updatedSession.selectedChoice}');
      AppLogger.info('🎮 - currentTurn: ${updatedSession.currentTurn.userId}');
      AppLogger.info('🎮 - This should show Truth/Thrill buttons for the new turn user');
      emit(GameActive(gameSession: updatedSession));
    } else {
      AppLogger.warning('🎮 Current state is not GameActive or GameTurnCompleted: ${state.runtimeType}');
    }
  }

  void _onGameChoiceMade(
    GameChoiceMade event,
    Emitter<GamesState> emit,
  ) {
    AppLogger.info('🎮 GamesBloc: Received GameChoiceMade event');
    AppLogger.info('🎮 - sessionId: ${event.sessionId}');
    AppLogger.info('🎮 - choice: ${event.choice}');
    AppLogger.info('🎮 - selectedPrompt: ${event.selectedPrompt.toJson()}');
    AppLogger.info('🎮 - madeBy: ${event.madeBy}');
    AppLogger.info('🎮 - Current state: ${state.runtimeType}');
    
    if (state is GameActive) {
      final currentState = state as GameActive;
      AppLogger.info('🎮 Current state is GameActive');
      AppLogger.info('🎮 Choice made by: ${event.madeBy}');
      AppLogger.info('🎮 Current turn user: ${currentState.gameSession.currentTurn.userId}');
      
      // Guard against late/out-of-order events: only accept choice from the current turn user
      if (currentState.gameSession.currentTurn.userId == event.madeBy) {
        AppLogger.info('🎮 Accepting choice for current turn user; updating selectedChoice');
        final updatedSession = currentState.gameSession.copyWith(
          selectedChoice: event.choice,
          lastActivityAt: DateTime.now(),
        );
        AppLogger.info('🎮 Emitting updated GameActive state with choice');
        emit(GameActive(gameSession: updatedSession));
      } else {
        AppLogger.info("⚠️ Ignoring GameChoiceMade: madeBy doesn't match current turn user (likely late event)");
      }
    } else if (state is GameTurnCompleted) {
      final currentState = state as GameTurnCompleted;
      AppLogger.info('🎮 Current state is GameTurnCompleted');
      AppLogger.info('🎮 Choice made by: ${event.madeBy}');
      AppLogger.info('🎮 Current turn user: ${currentState.gameSession.currentTurn.userId}');
      
      // Same guard during completed state to avoid re-setting after switch
      if (currentState.gameSession.currentTurn.userId == event.madeBy) {
        AppLogger.info('🎮 Accepting choice for current turn user in GameTurnCompleted; updating selectedChoice');
        final updatedSession = currentState.gameSession.copyWith(
          selectedChoice: event.choice,
          lastActivityAt: DateTime.now(),
        );
        AppLogger.info('🎮 Emitting updated GameTurnCompleted state with choice');
        emit(GameTurnCompleted(gameSession: updatedSession));
      } else {
        AppLogger.info("⚠️ Ignoring GameChoiceMade in GameTurnCompleted: madeBy doesn't match current turn user (likely late event)");
      }
    } else {
      AppLogger.warning('🎮 Current state is not GameActive or GameTurnCompleted: ${state.runtimeType}');
      AppLogger.warning('🎮 Cannot process GameChoiceMade event in this state');
    }
  }

  Future<void> _onEndGame(
    EndGame event,
    Emitter<GamesState> emit,
  ) async {
    try {
      await _gamesService.endGame(
        sessionId: event.sessionId,
        reason: event.reason,
        conversationId: event.conversationId,
      );
      
      emit(const GamesInitial());
    } catch (e) {
      AppLogger.error('❌ Failed to end game: $e');
      emit(GamesError(message: 'Failed to end game: $e'));
    }
  }

  void _onGameEnded(
    GameEnded event,
    Emitter<GamesState> emit,
  ) {
    AppLogger.info('🎮 Game ended: ${event.sessionId} - ${event.reason}');
    
    // Track game ended
    if (state is GameActive) {
      final currentState = state as GameActive;
      final gameSession = currentState.gameSession;
      
      // Calculate game duration
      int gameDuration = 0;
      if (gameSession.startedAt != null) {
        gameDuration = DateTime.now().difference(gameSession.startedAt!).inSeconds;
      }
      
      // Get turns played from game progress or estimate
      int turnsPlayed = gameSession.gameProgress?.completedTurns ?? 
                       gameSession.gameProgress?.totalTurns ?? 0;
      
      _analyticsService?.logGameEnded(
        gameName: gameSession.gameType.displayName,
        turnsPlayed: turnsPlayed,
        gameDuration: gameDuration,
      );
    }
    
    emit(GameEndedState(
      sessionId: event.sessionId,
      reason: event.reason,
      finalStats: event.finalStats,
    ));
  }

  // Timeout event handlers
  // void _onGameInviteTimeout(
  //   GameInviteTimeout event,
  //   Emitter<GamesState> emit,
  // ) {
  //   AppLogger.warning('⏰ Game invite timeout: ${event.sessionId}');
  //   emit(const GamesInitial());
  // }

  void _onGameTurnTimeout(
    GameTurnTimeout event,
    Emitter<GamesState> emit,
  ) {
    AppLogger.warning('⏰ Game turn timeout: ${event.sessionId}');
    add(EndGame(sessionId: event.sessionId, reason: 'timeout', conversationId: event.sessionId));
  }

  void _onGameSessionTimeout(
    GameSessionTimeout event,
    Emitter<GamesState> emit,
  ) {
    AppLogger.warning('⏰ Game session timeout: ${event.sessionId}');
    add(EndGame(sessionId: event.sessionId, reason: 'timeout', conversationId: event.sessionId));
  }

  // UI event handlers
  void _onShowGameMenu(
    ShowGameMenu event,
    Emitter<GamesState> emit,
  ) {
    emit(const GameMenuVisible());
  }

  void _onHideGameMenu(
    HideGameMenu event,
    Emitter<GamesState> emit,
  ) {
    emit(const GamesInitial());
  }

  void _onSelectGame(
    SelectGame event,
    Emitter<GamesState> emit,
  ) {
    // Track game selected
    _analyticsService?.logGameSelected(gameName: event.gameType.displayName);
    
    // Create a mock game session for the selected game
    final mockGameSession = GameSession(
      sessionId: 'pending_${event.gameType.apiValue}',
      gameType: event.gameType,
      currentTurn: const Turn(userId: '', turnNumber: 0),
      currentPrompt: const GamePrompt(),
      players: const [],
    );
    
    emit(GameActive(gameSession: mockGameSession));
  }

  void _onShowGameInviteModal(
    ShowGameInviteModal event,
    Emitter<GamesState> emit,
  ) {
    emit(GameInviteModalVisible(gameInvite: event.gameInvite));
  }

  void _onHideGameInviteModal(
    HideGameInviteModal event,
    Emitter<GamesState> emit,
  ) {
    emit(const GamesInitial());
  }

  // Cleanup event handlers
  void _onClearGameState(
    ClearGameState event,
    Emitter<GamesState> emit,
  ) {
    _gamesService.clearGameSession();
    emit(const GamesInitial());
  }

  void _onClearGameInvite(
    ClearGameInvite event,
    Emitter<GamesState> emit,
  ) {
    _gamesService.clearGameInvite();
    emit(const GamesInitial());
  }

  /// Helper method to convert game type string to display name
  String _getGameDisplayName(String gameType) {
    switch (gameType) {
      case 'truth_or_thrill':
        return 'Truth or Thrill';
      case 'memory_sparks':
        return 'Memory Sparks';
      case 'would_you_rather':
        return 'Would You Rather';
      case 'guess_me':
        return 'Guess Me';
      default:
        return gameType; // Return as-is if unknown
    }
  }

  @override
  Future<void> close() {
    _timeoutManager.dispose();
    return super.close();
  }
}
