import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/presentation/bloc/games/games_event.dart';
import 'package:nookly/presentation/bloc/games/games_state.dart';
import 'package:nookly/core/services/games_service.dart';
import 'package:nookly/domain/entities/game_session.dart';
import 'package:nookly/domain/entities/game_prompt.dart';
import 'package:nookly/core/utils/logger.dart';

class GamesBloc extends Bloc<GamesEvent, GamesState> {
  final GamesService _gamesService;
  final GameTimeoutManager _timeoutManager;

  GamesBloc({
    required GamesService gamesService,
    required GameTimeoutManager timeoutManager,
  }) : _gamesService = gamesService,
       _timeoutManager = timeoutManager,
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
    AppLogger.info('🎮 - gameProgress: ${event.gameProgress.toJson()}');
    
    if (state is GameActive) {
      final currentState = state as GameActive;
      AppLogger.info('🎮 Current state is GameActive, updating session...');
      final updatedSession = currentState.gameSession.copyWith(
        currentTurn: event.newTurn,
        currentPrompt: event.nextPrompt,
        selectedChoice: null, // Reset for new turn
        gameProgress: event.gameProgress,
        lastActivityAt: DateTime.now(),
      );
      AppLogger.info('🎮 Emitting updated GameActive state');
      emit(GameActive(gameSession: updatedSession));
    } else {
      AppLogger.warning('🎮 Current state is not GameActive: ${state.runtimeType}');
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
    
    if (state is GameActive) {
      final currentState = state as GameActive;
      AppLogger.info('🎮 Current state is GameActive, updating session with choice...');
      
      // Update the game session with the selected choice
      // Keep the original truthOrThrill prompt structure, just update the selected choice
      final updatedSession = currentState.gameSession.copyWith(
        selectedChoice: event.choice,
        lastActivityAt: DateTime.now(),
      );
      
      AppLogger.info('🎮 Emitting updated GameActive state with choice');
      emit(GameActive(gameSession: updatedSession));
    } else {
      AppLogger.warning('🎮 Current state is not GameActive: ${state.runtimeType}');
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
    add(EndGame(sessionId: event.sessionId, reason: 'timeout'));
  }

  void _onGameSessionTimeout(
    GameSessionTimeout event,
    Emitter<GamesState> emit,
  ) {
    AppLogger.warning('⏰ Game session timeout: ${event.sessionId}');
    add(EndGame(sessionId: event.sessionId, reason: 'timeout'));
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

  @override
  Future<void> close() {
    _timeoutManager.dispose();
    return super.close();
  }
}
