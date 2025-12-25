import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/presentation/bloc/games/games_event.dart';
import 'package:nookly/presentation/bloc/games/games_state.dart';
import 'package:nookly/core/services/games_service.dart';
import 'package:nookly/core/services/analytics_service.dart';
import 'package:nookly/core/services/demo_game_data_service.dart';
import 'package:nookly/core/services/remote_config_service.dart';
import 'package:nookly/domain/entities/game_session.dart';
import 'package:nookly/domain/entities/game_prompt.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/core/di/injection_container.dart' as di;

class GamesBloc extends Bloc<GamesEvent, GamesState> {
  final GamesService _gamesService;
  final GameTimeoutManager _timeoutManager;
  final AnalyticsService? _analyticsService;
  final DemoGameDataService _demoGameDataService = DemoGameDataService();
  final RemoteConfigService _remoteConfigService = di.sl<RemoteConfigService>();
  Timer? _demoGameTimer;

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
    
    // Demo game events
    on<StartDemoGame>(_onStartDemoGame);
    on<DemoGameTurnSwitch>(_onDemoGameTurnSwitch);
    on<DemoGamePartnerChoice>(_onDemoGamePartnerChoice);
    
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
      
      // Check if this is a demo game - skip server call for demo games
      if (currentState.gameSession.sessionId.startsWith('demo_')) {
        AppLogger.info('🎮 Demo game detected - skipping server call for choice selection');
        return; // For demo games, just update the state locally
      }
      
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
    
    // Check if this is a demo game
    if (event.sessionId.startsWith('demo_')) {
      AppLogger.info('🎮 Demo game detected, handling turn switch locally');
      _handleDemoGameTurnSwitch(emit, event.sessionId);
      return;
    }
    
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
    // Check if this is a demo game - handle locally without server call
    if (event.sessionId.startsWith('demo_')) {
      AppLogger.info('🎮 Ending demo game locally: ${event.sessionId}');
      
      // Cancel any running demo game timer
      _demoGameTimer?.cancel();
      _demoGameTimer = null;
      
      // Clear game state
      _gamesService.clearGameSession();
      
      // Extract game type and reset the demo game data service
      final gameType = _extractGameTypeFromSessionId(event.sessionId);
      _demoGameDataService.reset(gameType);
      
      AppLogger.info('🎮 Demo game ended successfully');
      emit(const GamesInitial());
      return;
    }
    
    // For real games, call the server
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

  // Demo game handlers
  void _onStartDemoGame(
    StartDemoGame event,
    Emitter<GamesState> emit,
  ) {
    AppLogger.info('🎮 GamesBloc: Received StartDemoGame event');
    AppLogger.info('🎮 - gameType: ${event.gameType}');
    AppLogger.info('🎮 - currentUserId: ${event.currentUserId}');
    AppLogger.info('🎮 - otherUserId: ${event.otherUserId}');
    
    // Check if it's a reviewer build
    if (!_remoteConfigService.isReviewerBuild()) {
      AppLogger.warning('⚠️ StartDemoGame called but not in reviewer build mode');
      emit(GamesError(message: 'Demo game is only available in reviewer builds'));
      return;
    }
    
    try {
      // Reset demo game data service for this game type
      _demoGameDataService.reset(event.gameType);
      
      // Get first prompt
      final promptData = _demoGameDataService.getNextPrompt(event.gameType);
      if (promptData == null) {
        AppLogger.error('❌ No prompts available for game type: ${event.gameType}');
        emit(GamesError(message: 'No prompts available for this game type'));
        return;
      }
      
      // Create demo game session
      final gameSession = _createDemoGameSession(
        gameType: event.gameType,
        currentUserId: event.currentUserId,
        otherUserId: event.otherUserId,
        promptData: promptData,
        turnNumber: 1,
      );
      
      AppLogger.info('🎮 Demo game session created: ${gameSession.sessionId}');
      emit(GameActive(gameSession: gameSession));
    } catch (e) {
      AppLogger.error('❌ Failed to start demo game: $e');
      emit(GamesError(message: 'Failed to start demo game: $e'));
    }
  }

  GameSession _createDemoGameSession({
    required String gameType,
    required String currentUserId,
    required String otherUserId,
    required Map<String, dynamic> promptData,
    required int turnNumber,
  }) {
    final gameTypeEnum = GameType.fromApiValue(gameType);
    final sessionId = 'demo_${gameType}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Parse prompt data - extract the correct structure based on game type
    Map<String, dynamic> promptJson;
    if (gameType == 'truth_or_thrill') {
      // For truth_or_thrill, extract the truthOrThrill object
      promptJson = promptData['truthOrThrill'] as Map<String, dynamic>;
    } else {
      // For other games, extract the singlePrompt object
      promptJson = promptData['singlePrompt'] as Map<String, dynamic>;
    }
    final gamePrompt = GamePrompt.fromJson(promptJson, gameType);
    
    // Create players
    final players = [
      Player(userId: currentUserId, isActive: true),
      Player(userId: otherUserId, isActive: true),
    ];
    
    // Create current turn (current user's turn)
    final currentTurn = Turn(
      userId: currentUserId,
      turnNumber: turnNumber,
    );
    
    return GameSession(
      sessionId: sessionId,
      gameType: gameTypeEnum,
      currentTurn: currentTurn,
      currentPrompt: gamePrompt,
      players: players,
      startedAt: DateTime.now(),
      lastActivityAt: DateTime.now(),
    );
  }

  /// Extract game type from demo session ID
  /// Format: demo_gameType_timestamp
  /// Game types can have underscores: truth_or_thrill, memory_sparks, would_you_rather, guess_me
  String _extractGameTypeFromSessionId(String sessionId) {
    // Remove "demo_" prefix
    if (!sessionId.startsWith('demo_')) {
      AppLogger.error('❌ Invalid demo session ID format: $sessionId');
      return 'truth_or_thrill'; // Default fallback
    }
    
    final withoutPrefix = sessionId.substring(5); // Remove "demo_"
    final parts = withoutPrefix.split('_');
    
    if (parts.length < 2) {
      AppLogger.error('❌ Invalid demo session ID format: $sessionId');
      return 'truth_or_thrill'; // Default fallback
    }
    
    // The last part is always the timestamp (numeric), everything before is the game type
    // Remove the last part (timestamp) and join the rest
    final gameTypeParts = parts.sublist(0, parts.length - 1);
    final gameType = gameTypeParts.join('_');
    
    AppLogger.info('🎮 Extracted game type from session ID: $gameType');
    return gameType;
  }

  void _handleDemoGameTurnSwitch(Emitter<GamesState> emit, String sessionId) {
    AppLogger.info('🎮 Handling demo game turn switch for session: $sessionId');
    
    // Cancel any existing timer
    _demoGameTimer?.cancel();
    
    if (state is! GameActive && state is! GameTurnCompleted) {
      AppLogger.warning('⚠️ Invalid state for demo game turn switch: ${state.runtimeType}');
      return;
    }
    
    final currentState = state is GameActive 
        ? (state as GameActive).gameSession 
        : (state as GameTurnCompleted).gameSession;
    
    // Extract game type from session ID
    final gameType = _extractGameTypeFromSessionId(sessionId);
    
    // Get next prompt
    final nextPromptData = _demoGameDataService.getNextPrompt(gameType);
    
    if (nextPromptData == null) {
      // No more prompts - game over
      AppLogger.info('🎮 Demo game completed - no more prompts');
      emit(const DemoGameEnded());
      // Clear state after a brief delay to allow toast to show
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!isClosed) {
          emit(const GamesInitial());
        }
      });
      return;
    }
    
    // Switch to partner's turn (no Done button)
    // Find the partner (the other player)
    final currentTurnUserId = currentState.currentTurn.userId;
    final partner = currentState.players.firstWhere(
      (p) => p.userId != currentTurnUserId,
      orElse: () => currentState.players.last,
    );
    
    final partnerTurn = Turn(
      userId: partner.userId,
      turnNumber: currentState.currentTurn.turnNumber + 1,
    );
    
    // Parse prompt data - extract the correct structure based on game type
    Map<String, dynamic> partnerPromptJson;
    if (gameType == 'truth_or_thrill') {
      partnerPromptJson = nextPromptData['truthOrThrill'] as Map<String, dynamic>;
    } else {
      partnerPromptJson = nextPromptData['singlePrompt'] as Map<String, dynamic>;
    }
    final partnerPrompt = GamePrompt.fromJson(partnerPromptJson, gameType);
    
    final partnerSession = currentState.copyWith(
      currentTurn: partnerTurn,
      currentPrompt: partnerPrompt,
      clearSelectedChoice: true,
      lastActivityAt: DateTime.now(),
    );
    
    AppLogger.info('🎮 Emitting GameTurnCompleted (partner\'s turn)');
    emit(GameTurnCompleted(gameSession: partnerSession));
    
    // For Truth or Thrill games, we need two phases:
    // 1. Show prompt for 5 seconds
    // 2. Simulate partner choosing Truth/Thrill for 3 seconds
    // 3. Then switch back to current user
    if (gameType == 'truth_or_thrill') {
      // Phase 1: Show prompt for 5 seconds (already emitted above)
      _demoGameTimer = Timer(const Duration(seconds: 3), () {
        if (isClosed) return;
        // Phase 2: Simulate partner choosing Truth or Thrill
        add(DemoGamePartnerChoice(sessionId: sessionId));
      });
    } else {
      // For other games, just wait 5 seconds then switch back
      _demoGameTimer = Timer(const Duration(seconds: 5), () {
        if (isClosed) return;
        add(DemoGameTurnSwitch(sessionId: sessionId));
      });
    }
  }

  void _onDemoGameTurnSwitch(
    DemoGameTurnSwitch event,
    Emitter<GamesState> emit,
  ) {
    AppLogger.info('🎮 Handling demo game turn switch after 5 seconds');
    
    if (state is! GameTurnCompleted) {
      AppLogger.warning('⚠️ Invalid state for demo game turn switch: ${state.runtimeType}');
      return;
    }
    
    final currentState = (state as GameTurnCompleted).gameSession;
    
    // Extract game type from session ID
    final gameType = _extractGameTypeFromSessionId(event.sessionId);
    
    // Get next prompt
    final nextPromptData = _demoGameDataService.getNextPrompt(gameType);
    
    if (nextPromptData == null) {
      // No more prompts - game over
      AppLogger.info('🎮 Demo game completed - no more prompts');
      emit(const DemoGameEnded());
      // Clear state after a brief delay to allow toast to show
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!isClosed) {
          emit(const GamesInitial());
        }
      });
      return;
    }
    
    // Switch back to current user's turn
    // The current user is the one who started the game (first player)
    // We need to find the user who is NOT the current turn user (the partner)
    // and switch back to the original current user
    final partnerUserId = currentState.currentTurn.userId; // Currently partner's turn
    final originalCurrentUser = currentState.players.firstWhere(
      (p) => p.userId != partnerUserId,
      orElse: () => currentState.players.first,
    );
    
      final currentUserTurn = Turn(
        userId: originalCurrentUser.userId,
        turnNumber: currentState.currentTurn.turnNumber + 1,
      );
      
      // Parse prompt data - extract the correct structure based on game type
      Map<String, dynamic> currentUserPromptJson;
      if (gameType == 'truth_or_thrill') {
        currentUserPromptJson = nextPromptData['truthOrThrill'] as Map<String, dynamic>;
      } else {
        currentUserPromptJson = nextPromptData['singlePrompt'] as Map<String, dynamic>;
      }
      final currentUserPrompt = GamePrompt.fromJson(currentUserPromptJson, gameType);
    
    final currentUserSession = currentState.copyWith(
      currentTurn: currentUserTurn,
      currentPrompt: currentUserPrompt,
      clearSelectedChoice: true,
      lastActivityAt: DateTime.now(),
    );
    
    AppLogger.info('🎮 Emitting GameActive (current user\'s turn)');
    emit(GameActive(gameSession: currentUserSession));
  }

  void _onDemoGamePartnerChoice(
    DemoGamePartnerChoice event,
    Emitter<GamesState> emit,
  ) {
    AppLogger.info('🎮 Simulating partner choice for Truth or Thrill');
    
    if (state is! GameTurnCompleted) {
      AppLogger.warning('⚠️ Invalid state for demo game partner choice: ${state.runtimeType}');
      return;
    }
    
    final currentState = (state as GameTurnCompleted).gameSession;
    
    // Randomly choose Truth or Thrill for the partner (alternate for consistency)
    final partnerChoice = (currentState.currentTurn.turnNumber % 2 == 0) ? 'truth' : 'thrill';
    AppLogger.info('🎮 Partner chose: $partnerChoice');
    AppLogger.info('🎮 Current turn user: ${currentState.currentTurn.userId}');
    AppLogger.info('🎮 Current turn number: ${currentState.currentTurn.turnNumber}');
    
    // Update the session with partner's choice
    final sessionWithChoice = currentState.copyWith(
      selectedChoice: partnerChoice,
      lastActivityAt: DateTime.now(),
    );
    
    AppLogger.info('🎮 Emitting GameTurnCompleted with partner choice: $partnerChoice');
    AppLogger.info('🎮 Session selectedChoice: ${sessionWithChoice.selectedChoice}');
    AppLogger.info('🎮 Current turn user: ${sessionWithChoice.currentTurn.userId}');
    
    // Emit GameTurnCompleted with the choice (this will show the selected choice)
    // The UI will display the partner's choice (Truth or Thrill badge)
    emit(GameTurnCompleted(gameSession: sessionWithChoice));
    
    // After 3 seconds, switch back to current user with next prompt
    _demoGameTimer = Timer(const Duration(seconds: 5), () {
      if (isClosed) return;
      add(DemoGameTurnSwitch(sessionId: event.sessionId));
    });
  }

  @override
  Future<void> close() {
    _demoGameTimer?.cancel();
    _timeoutManager.dispose();
    return super.close();
  }
}
