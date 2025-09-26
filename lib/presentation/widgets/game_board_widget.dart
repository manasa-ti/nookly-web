import 'package:flutter/material.dart';
import 'package:nookly/domain/entities/game_session.dart';

class GameBoardWidget extends StatelessWidget {
  final GameSession gameSession;
  final String currentUserId;
  final Function(String) onGameAction;
  final bool isTurnCompleted; // Flag to indicate if turn is completed

  const GameBoardWidget({
    Key? key,
    required this.gameSession,
    required this.currentUserId,
    required this.onGameAction,
    this.isTurnCompleted = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game title and close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                gameSession.gameType.displayName,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () => onGameAction('end_game'),
                child: Icon(
                  Icons.close,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Game content based on type and state
          if (gameSession.gameType == GameType.truthOrThrill) ...[
            if (_isGamePending()) ...[
              // Show game description when pending
              _buildGameDescription(),
            ] else ...[
              // Show Truth/Thrill buttons only after game starts and only for current turn user
              _buildTruthOrThrillContent(),
            ],
          ] else ...[
            if (_isGamePending()) ...[
              // Show game description when pending
              _buildGameDescription(),
            ] else ...[
              // Show prompt content after game starts
              _buildDirectPromptContent(),
            ],
          ],
          
          const SizedBox(height: 12),
          
          // Show Send Invite button if game is pending (not started yet)
          if (_isGamePending()) ...[
            _buildSendInviteButton(),
          ] else if (_isCurrentUserTurn() && _hasSelectedChoice()) ...[
            // Next Turn button (if it's current user's turn AND they have selected a choice)
            _buildNextTurnButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildTruthOrThrillContent() {
    // If turn is completed, show waiting message for the user who completed their turn
    // (This user is no longer the current turn user)
    if (isTurnCompleted && !_isCurrentUserTurn()) {
      print('🎮 Showing turn completed message for user who completed turn: $currentUserId');
      print('🎮 Current turn user: ${gameSession.currentTurn.userId}');
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.green.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Text(
          "Waiting for your partner to make their choice...",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.green.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Nunito',
          ),
        ),
      );
    }
    
    // If no choice has been made yet (by any player), show both options
    if (gameSession.selectedChoice == null) {
      // Only show buttons if it's the current user's turn
      if (_isCurrentUserTurn()) {
        print('🎮 Showing Truth/Thrill buttons for current user: $currentUserId');
        print('🎮 Current turn user: ${gameSession.currentTurn.userId}');
        print('🎮 Game session ID: ${gameSession.sessionId}');
        print('🎮 Game type: ${gameSession.gameType.displayName}');
        print('🎮 Selected choice: ${gameSession.selectedChoice}');
        print('🎮 isTurnCompleted: $isTurnCompleted');
        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onGameAction('select_truth'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.6),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Truth',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => onGameAction('select_thrill'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.purple.withOpacity(0.6),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Thrill',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      } else {
        print('🎮 Showing partner turn message for user: $currentUserId');
        print('🎮 Current turn user: ${gameSession.currentTurn.userId}');
        print('🎮 isTurnCompleted: $isTurnCompleted');
        print('🎮 selectedChoice: ${gameSession.selectedChoice}');
        // Show "partner's turn" message
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.orange.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Text(
            "It's your partner's turn now",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.orange.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Nunito',
            ),
          ),
        );
      }
    }
    
    // If a choice has been made (by any player), show the selected choice and prompt
    return Column(
      children: [
        // Selected choice button (centered)
        Container(
          width: 120,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: gameSession.selectedChoice == 'truth' 
                ? Colors.blue.withOpacity(0.3)
                : Colors.purple.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: gameSession.selectedChoice == 'truth' 
                  ? Colors.blue.withOpacity(0.6)
                  : Colors.purple.withOpacity(0.6),
              width: 1,
            ),
          ),
          child: Text(
            gameSession.selectedChoice == 'truth' ? 'Truth' : 'Thrill',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Display the selected prompt
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            gameSession.currentPrompt.getDisplayText(gameSession.selectedChoice) ?? '',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontFamily: 'Nunito',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectPromptContent() {
    // For non-truth-or-thrill games, always show the prompt to both players
    // The prompt is shared and both players can see it
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        gameSession.currentPrompt.getDisplayText(null) ?? '',
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 14,
          fontFamily: 'Nunito',
        ),
      ),
    );
  }

  Widget _buildNextTurnButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => onGameAction('next_turn'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.withOpacity(0.8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Your turn',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Nunito',
          ),
        ),
      ),
    );
  }

  bool _isCurrentUserTurn() {
    final isCurrentTurn = gameSession.isCurrentUserTurn(currentUserId);
    print('🎮 _isCurrentUserTurn() check:');
    print('🎮 - currentUserId: $currentUserId');
    print('🎮 - gameSession.currentTurn.userId: ${gameSession.currentTurn.userId}');
    print('🎮 - isCurrentTurn: $isCurrentTurn');
    return isCurrentTurn;
  }

  bool _isGamePending() {
    // Game is pending if sessionId starts with 'pending_'
    final isPending = gameSession.sessionId.startsWith('pending_');
    print('🎮 _isGamePending() check:');
    print('🎮 - sessionId: ${gameSession.sessionId}');
    print('🎮 - isPending: $isPending');
    return isPending;
  }

  bool _hasSelectedChoice() {
    // For Truth or Thrill games, check if user has selected a choice
    if (gameSession.gameType == GameType.truthOrThrill) {
      return gameSession.selectedChoice != null;
    }
    // For other games, assume choice is always made
    return true;
  }

  Widget _buildGameDescription() {
    String description;
    switch (gameSession.gameType) {
      case GameType.truthOrThrill:
        description = 'Choose between Truth or Thrill questions to get to know each other better!';
        break;
      case GameType.memorySparks:
        description = 'Share your favorite memories and create new ones together!';
        break;
      case GameType.wouldYouRather:
        description = 'Make tough choices and discover each other\'s preferences!';
        break;
      case GameType.guessMe:
        description = 'Test how well you know each other with fun guessing games!';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        description,
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 14,
          fontFamily: 'Nunito',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSendInviteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => onGameAction('send_invite'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: const Text(
          'Send Invite',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Nunito',
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
