import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/presentation/bloc/games/games_bloc.dart';
import 'package:nookly/presentation/bloc/games/games_event.dart';
import 'package:nookly/presentation/bloc/games/games_state.dart';
import 'package:nookly/presentation/widgets/conversation_starter_widget.dart';
import 'package:nookly/presentation/widgets/game_board_widget.dart';
import 'package:nookly/domain/entities/game_session.dart';

class GameInterfaceBar extends StatelessWidget {
  final String matchUserId;
  final List<String>? priorMessages;
  final Function(String) onSuggestionSelected;
  final String currentUserId;
  final bool isOtherUserOnline;

  const GameInterfaceBar({
    Key? key,
    required this.matchUserId,
    this.priorMessages,
    required this.onSuggestionSelected,
    required this.currentUserId,
    required this.isOtherUserOnline,
  }) : super(key: key);

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
    AppLogger.info('🎮 GameInterfaceBar: Other user online: $isOtherUserOnline');
    
    // Show game board if game is active (regardless of online status)
    if (state is GameActive) {
      AppLogger.info('🎮 GameInterfaceBar: Showing GameBoardWidget');
      AppLogger.info('🎮 GameInterfaceBar: GameSession details: sessionId=${state.gameSession.sessionId}, gameType=${state.gameSession.gameType.displayName}, currentTurn=${state.gameSession.currentTurn.userId}');
      return GameBoardWidget(
        gameSession: state.gameSession,
        currentUserId: currentUserId,
        onGameAction: (action) => _handleGameAction(context, action, state.gameSession),
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
    if (isOtherUserOnline) {
      return _buildNormalInterface(context);
    } else {
      return _buildOfflineInterface(context);
    }
  }

  Widget _buildNormalInterface(BuildContext context) {
    return Row(
      children: [
        // Conversation Starters
        ConversationStarterWidget(
          matchUserId: matchUserId,
          priorMessages: priorMessages,
          onSuggestionSelected: onSuggestionSelected,
        ),
        
        const SizedBox(width: 16),
        
        // Play to Bond - always show when other user is online
        GestureDetector(
          onTap: () {
            // Handle authentication at action level
            if (currentUserId.isEmpty) {
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.games,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Play to Bond',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
              'Game invite from ${state.gameInvite.fromUserName ?? 'Unknown'}',
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
            childAspectRatio: 2.8,
            children: [
              _buildGameCard(context, GameType.truthOrThrill, 'Truth or Thrill', 'Choose your adventure'),
              _buildGameCard(context, GameType.memorySparks, 'Memory Sparks', 'Share your memories'),
              _buildGameCard(context, GameType.wouldYouRather, 'Would You Rather', 'Make tough choices'),
              _buildGameCard(context, GameType.guessMe, 'Guess Me', 'Test your knowledge'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, GameType gameType, String title, String description) {
    return GestureDetector(
      onTap: () {
        context.read<GamesBloc>().add(SelectGame(gameType: gameType));
        // Don't immediately send invite - show game board first
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
                fontFamily: 'Nunito',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
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
          currentUserId: currentUserId,
        ));
        break;
      case 'select_thrill':
        context.read<GamesBloc>().add(SelectGameChoice(
          choice: 'thrill',
          currentUserId: currentUserId,
        ));
        break;
      case 'send_invite':
        // matchUserId should be the other user's ID, but let's verify
        AppLogger.info('🎮 Sending game invite to: $matchUserId');
        AppLogger.info('🎮 Game type: ${gameSession.gameType.apiValue}');
        AppLogger.info('🎮 Current user ID: $currentUserId');
        context.read<GamesBloc>().add(SendGameInvite(
          gameType: gameSession.gameType.apiValue,
          otherUserId: matchUserId,
        ));
        break;
      case 'next_turn':
        _completeGameTurn(context, gameSession);
        break;
      case 'end_game':
        context.read<GamesBloc>().add(EndGame(
          sessionId: gameSession.sessionId,
          reason: 'user_ended',
        ));
        break;
    }
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
    ));
  }
}
