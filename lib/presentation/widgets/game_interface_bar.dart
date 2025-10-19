import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/presentation/bloc/games/games_bloc.dart';
import 'package:nookly/presentation/bloc/games/games_event.dart';
import 'package:nookly/presentation/bloc/games/games_state.dart';
import 'package:nookly/presentation/widgets/conversation_starter_widget.dart';
import 'package:nookly/presentation/widgets/game_board_widget.dart';
import 'package:nookly/presentation/widgets/contextual_tooltip.dart';
import 'package:nookly/domain/entities/game_session.dart';
import 'package:nookly/core/services/onboarding_service.dart';

class GameInterfaceBar extends StatefulWidget {
  final String matchUserId;
  final List<String>? priorMessages;
  final Function(String) onSuggestionSelected;
  final String currentUserId;
  final bool isOtherUserOnline;
  final String? serverConversationId; // Server-provided conversation ID

  const GameInterfaceBar({
    Key? key,
    required this.matchUserId,
    this.priorMessages,
    required this.onSuggestionSelected,
    required this.currentUserId,
    required this.isOtherUserOnline,
    this.serverConversationId,
  }) : super(key: key);

  @override
  State<GameInterfaceBar> createState() => _GameInterfaceBarState();
}

class _GameInterfaceBarState extends State<GameInterfaceBar> {
  bool _showGamesTooltip = false;
  bool _conversationStarterCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkGamesTutorial();
    _checkConversationStarterCompletion();
  }

  void _checkConversationStarterCompletion() async {
    final isCompleted = await OnboardingService.isConversationStarterTutorialCompleted();
    setState(() {
      _conversationStarterCompleted = isCompleted;
    });
    
    // If conversation starter is completed, check if we should show games tooltip
    if (isCompleted) {
      _checkGamesTutorial();
    }
  }

  void _checkGamesTutorial() async {
    final shouldShow = await OnboardingService.shouldShowGamesTutorial();
    AppLogger.info('🔵 GAMES TOOLTIP: shouldShowGamesTutorial returned: $shouldShow');
    AppLogger.info('🔵 GAMES TOOLTIP: mounted: $mounted');
    AppLogger.info('🔵 GAMES TOOLTIP: conversation starter completed: $_conversationStarterCompleted');
    
    // Only show games tooltip if conversation starter tutorial is completed
    if (shouldShow && mounted && _conversationStarterCompleted) {
      AppLogger.info('🔵 GAMES TOOLTIP: Setting _showGamesTooltip to true');
      setState(() {
        _showGamesTooltip = true;
      });
    } else {
      AppLogger.info('🔵 GAMES TOOLTIP: Not showing tooltip - shouldShow: $shouldShow, mounted: $mounted, conversationStarterCompleted: $_conversationStarterCompleted');
    }
  }

  void _onConversationStarterCompleted() {
    AppLogger.info('🔵 GAMES TOOLTIP: Conversation starter tutorial completed, checking games tutorial');
    setState(() {
      _conversationStarterCompleted = true;
    });
    // Check if we should show games tooltip now
    _checkGamesTutorial();
  }

  Widget _buildPlayToBondButton() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.games,
          color: Colors.white.withOpacity(0.8),
          size: 20,
        ),
        const SizedBox(width: 6),
        Text(
          'Play 2 Bond',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final gamesBloc = context.read<GamesBloc>();
    AppLogger.info('🎮 GameInterfaceBar: Using GamesBloc instance: ${gamesBloc.hashCode}');
    
    return BlocConsumer<GamesBloc, GamesState>(
      listener: (context, state) {
        if (state is GamesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      builder: (context, state) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 0.5,
              ),
            ),
          ),
          child: _buildContent(context, state),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, GamesState state) {
    AppLogger.info('🎮 GameInterfaceBar: Building content with state: ${state.runtimeType}');
    AppLogger.info('🎮 GameInterfaceBar: State details: $state');
    AppLogger.info('🎮 GameInterfaceBar: Other user online: ${widget.isOtherUserOnline}');
    
    // Show game board if game is active (regardless of online status)
    if (state is GameActive) {
      AppLogger.info('🎮 GameInterfaceBar: Showing GameBoardWidget');
      AppLogger.info('🎮 GameInterfaceBar: GameSession details: sessionId=${state.gameSession.sessionId}, gameType=${state.gameSession.gameType.displayName}, currentTurn=${state.gameSession.currentTurn.userId}');
      return GameBoardWidget(
        gameSession: state.gameSession,
        currentUserId: widget.currentUserId,
        onGameAction: (action) => _handleGameAction(context, action, state.gameSession),
      );
    }

    // Show game board if turn is completed (waiting for partner's turn)
    if (state is GameTurnCompleted) {
      AppLogger.info('🎮 GameInterfaceBar: Showing GameBoardWidget for completed turn');
      AppLogger.info('🎮 GameInterfaceBar: GameSession details: sessionId=${state.gameSession.sessionId}, gameType=${state.gameSession.gameType.displayName}, currentTurn=${state.gameSession.currentTurn.userId}');
      return GameBoardWidget(
        gameSession: state.gameSession,
        currentUserId: widget.currentUserId,
        onGameAction: (action) => _handleGameAction(context, action, state.gameSession),
        isTurnCompleted: true, // Pass flag to indicate turn is completed
      );
    }

    // Show game menu grid if menu is visible (regardless of online status)
    if (state is GameMenuVisible) {
      return _buildGameMenuGrid(context);
    }

    // Show game invite modal if invite is received (regardless of online status)
    if (state is GameInviteReceivedState) {
      return _buildGameInviteReceived(context, state);
    }

    // Show invite pending if invite is sent (regardless of online status)
    if (state is GameInviteSentState) {
      AppLogger.info('🎮 GameInterfaceBar: Showing GameInviteSentState');
      return _buildInvitePending(context, state);
    }

    // Only show conversation starters and games if other user is online
    if (widget.isOtherUserOnline) {
      return _buildNormalInterface(context);
    } else {
      return _buildOfflineInterface(context);
    }
  }

  Widget _buildNormalInterface(BuildContext context) {
    AppLogger.info('🔵 GAMES TOOLTIP: _buildNormalInterface called, _showGamesTooltip: $_showGamesTooltip');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Conversation Starters
          Flexible(
            flex: 2,
            child: ConversationStarterWidget(
              matchUserId: widget.matchUserId,
              priorMessages: widget.priorMessages,
              onSuggestionSelected: widget.onSuggestionSelected,
              onTutorialCompleted: _onConversationStarterCompleted,
            ),
          ),
          
          const SizedBox(width: 8), // Reduced from 16
          
          // Play to Bond - always show when other user is online
          Flexible(
            flex: 1,
            child: _showGamesTooltip
                ? ContextualTooltip(
                    message: 'Choose a game to play together and have fun getting to know each other!',
                    position: TooltipPosition.bottom,
                    onDismiss: () {
                      AppLogger.info('🔵 GAMES TOOLTIP: Tooltip dismissed');
                      setState(() {
                        _showGamesTooltip = false;
                      });
                      OnboardingService.markGamesTutorialCompleted();
                    },
                    child: GestureDetector(
                      onTap: () {
                        if (widget.currentUserId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please wait while we connect...'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        context.read<GamesBloc>().add(const ShowGameMenu());
                      },
                      child: _buildPlayToBondButton(),
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      if (widget.currentUserId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please wait while we connect...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      context.read<GamesBloc>().add(const ShowGameMenu());
                    },
                    child: _buildPlayToBondButton(),
                  ),
          ),
          
          const SizedBox(width: 8), // Reduced from 20
          
          // Spice it Up - coming soon (compact version)
          Flexible(
            flex: 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: Colors.white.withOpacity(0.5),
                      size: 16, // Reduced from 20
                    ),
                    const SizedBox(width: 4), // Reduced from 6
                    Flexible(
                      child: Text(
                        'Spice it Up',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12, // Reduced from 14
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20), // Reduced from 26 (16 + 4)
                  child: Text(
                    'Coming soon',
                    style: TextStyle(
                      color: Colors.orange.withOpacity(0.8),
                      fontSize: 9, // Reduced from 10
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineInterface(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.offline_bolt,
            color: Colors.grey.withOpacity(0.8),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'User is offline - Only messaging available',
            style: TextStyle(
              color: Colors.grey.withOpacity(0.9),
              fontSize: 14,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameInviteReceived(BuildContext context, GameInviteReceivedState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.games,
            color: Colors.green.withOpacity(0.8),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Game invite from this chat',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _acceptGameInvite(context, state.gameInvite),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _rejectGameInvite(context, state.gameInvite),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Decline',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvitePending(BuildContext context, GameInviteSentState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.games,
            color: Colors.orange.withOpacity(0.8),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Invite sent for ${state.gameType.replaceAll('_', ' ')}...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _cancelGameInvite(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameMenuGrid(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Choose a Game',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  context.read<GamesBloc>().add(const HideGameMenu());
                },
                child: Icon(
                  Icons.close,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.8, // Reduced from 2.8 to give more height
            children: [
              _buildGameCard(context, GameType.truthOrThrill, 'Truth or Thrill', 'Choose adventure'),
              _buildGameCard(context, GameType.memorySparks, 'Memory Sparks', 'Share memories'),
              _buildGameCard(context, GameType.wouldYouRather, 'Would You Rather', 'Make choices'),
              _buildGameCard(context, GameType.guessMe, 'Guess Me', 'Test knowledge'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, GameType gameType, String title, String description, {bool isComingSoon = false}) {
    return GestureDetector(
      onTap: isComingSoon ? null : () {
        context.read<GamesBloc>().add(SelectGame(gameType: gameType));
        // Don't immediately send invite - show game board first
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isComingSoon 
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isComingSoon 
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Prevent overflow
          children: [
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: isComingSoon 
                      ? Colors.white.withOpacity(0.5)
                      : Colors.white,
                  fontSize: 13,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                description,
                style: TextStyle(
                  color: isComingSoon 
                      ? Colors.white.withOpacity(0.4)
                      : Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  fontFamily: 'Nunito',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            if (isComingSoon) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: Colors.orange.withOpacity(0.8),
                    fontSize: 9,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _acceptGameInvite(BuildContext context, gameInvite) {
    context.read<GamesBloc>().add(AcceptGameInvite(
      gameType: gameInvite.gameType,
      otherUserId: gameInvite.fromUserId,
    ));
  }

  void _rejectGameInvite(BuildContext context, gameInvite) {
    context.read<GamesBloc>().add(RejectGameInvite(
      gameType: gameInvite.gameType,
      fromUserId: gameInvite.fromUserId,
      reason: 'declined',
    ));
  }

  void _cancelGameInvite(BuildContext context) {
    context.read<GamesBloc>().add(ClearGameInvite());
  }

  void _handleGameAction(BuildContext context, String action, gameSession) {
    switch (action) {
      case 'select_truth':
        context.read<GamesBloc>().add(SelectGameChoice(
          choice: 'truth',
          currentUserId: widget.currentUserId,
          conversationId: _getActualConversationId(), // Pass actual conversation ID for room-based broadcasting
        ));
        break;
      case 'select_thrill':
        context.read<GamesBloc>().add(SelectGameChoice(
          choice: 'thrill',
          currentUserId: widget.currentUserId,
          conversationId: _getActualConversationId(), // Pass actual conversation ID for room-based broadcasting
        ));
        break;
      case 'send_invite':
        // matchUserId should be the other user's ID, but let's verify
        AppLogger.info('🎮 Sending game invite to: ${widget.matchUserId}');
        AppLogger.info('🎮 Game type: ${gameSession.gameType.apiValue}');
        AppLogger.info('🎮 Current user ID: ${widget.currentUserId}');
        context.read<GamesBloc>().add(SendGameInvite(
          gameType: gameSession.gameType.apiValue,
          otherUserId: widget.matchUserId,
          conversationId: _getActualConversationId(),
        ));
        break;
      case 'next_turn':
        _completeGameTurn(context, gameSession);
        break;
      case 'end_game':
        context.read<GamesBloc>().add(EndGame(
          sessionId: gameSession.sessionId,
          reason: 'user_ended',
          conversationId: _getActualConversationId(), // Pass actual conversation ID for room-based broadcasting
        ));
        break;
    }
  }

  String _getActualConversationId() {
    // Use server-provided conversation ID if available
    if (widget.serverConversationId != null && widget.serverConversationId!.isNotEmpty) {
      AppLogger.info('🔵 GameInterfaceBar: Using server-provided conversation ID: ${widget.serverConversationId}');
      return widget.serverConversationId!;
    }
    
    // Fallback: Generate the actual conversation ID in the format: user1_user2 (sorted alphabetically)
    if (widget.currentUserId.isEmpty || widget.matchUserId.isEmpty) {
      AppLogger.error('❌ Cannot generate conversation ID: user IDs are empty');
      return widget.matchUserId; // Fallback to other user's ID
    }
    
    final userIds = [widget.currentUserId, widget.matchUserId];
    userIds.sort(); // Sort alphabetically to ensure consistent format
    
    final actualConversationId = '${userIds[0]}_${userIds[1]}';
    AppLogger.info('🔵 GameInterfaceBar: Generated fallback conversation ID: $actualConversationId');
    AppLogger.info('🔵 From user IDs: ${widget.currentUserId} and ${widget.matchUserId}');
    
    return actualConversationId;
  }

  void _completeGameTurn(BuildContext context, gameSession) {
    AppLogger.info('🎮 Completing game turn for session: ${gameSession.sessionId}');
    AppLogger.info('🎮 Game type: ${gameSession.gameType.displayName}');
    AppLogger.info('🎮 Selected choice: ${gameSession.selectedChoice}');
    
    // For Truth or Thrill games, user must select a choice first
    if (gameSession.gameType == GameType.truthOrThrill && gameSession.selectedChoice == null) {
      AppLogger.warning('🎮 Cannot complete turn: User must select Truth or Thrill first');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Truth or Thrill first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Get the selected prompt based on the game type and choice
    Map<String, dynamic> selectedPrompt;
    String? selectedChoice;

    if (gameSession.gameType == GameType.truthOrThrill && gameSession.selectedChoice != null) {
      selectedChoice = gameSession.selectedChoice;
      if (gameSession.selectedChoice == 'truth') {
        selectedPrompt = gameSession.currentPrompt.truthOrThrill!.truth.toJson();
      } else {
        selectedPrompt = gameSession.currentPrompt.truthOrThrill!.thrill.toJson();
      }
    } else {
      selectedPrompt = gameSession.currentPrompt.singlePrompt!.toJson();
    }

    AppLogger.info('🎮 Sending CompleteGameTurn event with:');
    AppLogger.info('🎮 - sessionId: ${gameSession.sessionId}');
    AppLogger.info('🎮 - selectedChoice: $selectedChoice');
    AppLogger.info('🎮 - selectedPrompt: $selectedPrompt');

    context.read<GamesBloc>().add(CompleteGameTurn(
      sessionId: gameSession.sessionId,
      selectedChoice: selectedChoice,
      selectedPrompt: selectedPrompt,
      conversationId: _getActualConversationId(), // Pass actual conversation ID for room-based broadcasting
    ));
  }
}
