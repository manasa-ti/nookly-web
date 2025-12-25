import 'package:nookly/core/theme/app_colors.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:nookly/core/theme/app_text_styles.dart';
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
    // Determine if Done button will be shown to adjust bottom padding
    final showDoneButton = !_isGamePending() && _isCurrentUserTurn() && _hasSelectedChoice();
    
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: showDoneButton ? 4 : 8, // Less bottom padding when Done button is shown
      ),
      decoration: BoxDecoration(
        // Remove background color and border - outer container provides it
        // Keep only for visual consistency, but make it transparent
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game title, turn indicator badge, and close button in one row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Game title
              Text(
                gameSession.gameType.displayName,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: AppTextStyles.getSectionHeaderFontSize(context),
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Turn indicator badge (small chip style)
              _buildTurnIndicatorBadge(context),
              // Close button
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
          
          const SizedBox(height: 8),
          
          // Game content based on type and state
          if (gameSession.gameType == GameType.truthOrThrill) ...[
            if (_isGamePending()) ...[
              // Show game description when pending
              _buildGameDescription(context),
            ] else ...[
              // Show Truth/Thrill buttons only after game starts and only for current turn user
              _buildTruthOrThrillContent(context),
            ],
          ] else ...[
            if (_isGamePending()) ...[
              // Show game description when pending
              _buildGameDescription(context),
            ] else ...[
              // Show prompt content after game starts
              _buildDirectPromptContent(context),
            ],
          ],
          
          // Truth/Thrill button and Done button on same line (only shown when it's user's turn and they've selected a choice)
          if (!_isGamePending() && _isCurrentUserTurn() && _hasSelectedChoice() && gameSession.gameType == GameType.truthOrThrill && gameSession.selectedChoice != null) ...[
            const SizedBox(height: 4),
            // Row with Truth/Thrill button on left and Done button on right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Truth/Thrill button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: gameSession.selectedChoice == 'truth' 
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.purple.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: gameSession.selectedChoice == 'truth' 
                          ? Colors.blue.withOpacity(0.6)
                          : Colors.purple.withOpacity(0.6),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    gameSession.selectedChoice == 'truth' ? 'Truth' : 'Thrill',
                    style: TextStyle(
                      color: AppColors.white85,
                      fontSize: AppTextStyles.getCaptionFontSize(context),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
                // Done button
                ElevatedButton(
                  onPressed: () => onGameAction('next_turn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.8),
                    foregroundColor: AppColors.white85,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    minimumSize: const Size(0, 0), // Allow button to be as small as content
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontSize: AppTextStyles.getCaptionFontSize(context),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ],
            ),
          ] else if (!_isGamePending() && _isCurrentUserTurn() && _hasSelectedChoice()) ...[
            // Done button only (for non-truth-or-thrill games)
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => onGameAction('next_turn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.withOpacity(0.8),
                  foregroundColor: AppColors.white85,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  minimumSize: const Size(0, 0), // Allow button to be as small as content
                ),
                child: Text(
                  'Done',
                  style: TextStyle(
                    fontSize: AppTextStyles.getCaptionFontSize(context),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ),
          ],
          
          // Show Send Invite button if game is pending (not started yet)
          if (_isGamePending()) ...[
            const SizedBox(height: 6),
            _buildSendInviteButton(context),
          ],
        ],
      ),
    );
  }

  Widget _buildTruthOrThrillContent(BuildContext context) {
    // If turn is completed and partner hasn't made a choice yet, show waiting message
    // (This user is no longer the current turn user)
    // But if partner has made a choice, we'll show it below
    if (isTurnCompleted && !_isCurrentUserTurn() && gameSession.selectedChoice == null) {
      AppLogger.info('🎮 Showing turn completed message for user who completed turn: $currentUserId');
      AppLogger.info('🎮 Current turn user: ${gameSession.currentTurn.userId}');
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
            fontSize: AppTextStyles.getBodyFontSize(context),
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
        AppLogger.info('🎮 Showing Truth/Thrill buttons for current user: $currentUserId');
        AppLogger.info('🎮 Current turn user: ${gameSession.currentTurn.userId}');
        AppLogger.info('🎮 Game session ID: ${gameSession.sessionId}');
        AppLogger.info('🎮 Game type: ${gameSession.gameType.displayName}');
        AppLogger.info('🎮 Selected choice: ${gameSession.selectedChoice}');
        AppLogger.info('🎮 isTurnCompleted: $isTurnCompleted');
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
                  child: Text(
                    'Truth',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.white85,
                      fontSize: AppTextStyles.getBodyFontSize(context),
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
                  child: Text(
                    'Thrill',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.white85,
                      fontSize: AppTextStyles.getBodyFontSize(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      } else {
        AppLogger.info('🎮 Showing partner turn message for user: $currentUserId');
        AppLogger.info('🎮 Current turn user: ${gameSession.currentTurn.userId}');
        AppLogger.info('🎮 isTurnCompleted: $isTurnCompleted');
        AppLogger.info('🎮 selectedChoice: ${gameSession.selectedChoice}');
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
              fontSize: AppTextStyles.getBodyFontSize(context),
              fontWeight: FontWeight.w500,
              fontFamily: 'Nunito',
            ),
          ),
        );
      }
    }
    
    // If a choice has been made (by any player), show the selected choice and prompt
    // Note: If it's the user's turn, the Truth/Thrill button will be shown with Done button in main build method
    return Column(
      children: [
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
              fontSize: AppTextStyles.getBodyFontSize(context),
              fontFamily: 'Nunito',
            ),
          ),
        ),
        // Only show Truth/Thrill button here if it's NOT the user's turn (partner's turn or waiting)
        if (!_isCurrentUserTurn()) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: gameSession.selectedChoice == 'truth' 
                    ? Colors.blue.withOpacity(0.3)
                    : Colors.purple.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: gameSession.selectedChoice == 'truth' 
                      ? Colors.blue.withOpacity(0.6)
                      : Colors.purple.withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: Text(
                gameSession.selectedChoice == 'truth' ? 'Truth' : 'Thrill',
                style: TextStyle(
                  color: AppColors.white85,
                  fontSize: AppTextStyles.getCaptionFontSize(context),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDirectPromptContent(BuildContext context) {
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

  // Build turn indicator as a small badge/chip
  Widget _buildTurnIndicatorBadge(BuildContext context) {
    String turnText;
    Color badgeColor;
    Color textColor;
    IconData icon;
    
    if (_isGamePending()) {
      turnText = 'Pending';
      badgeColor = Colors.orange.withOpacity(0.2);
      textColor = Colors.orange.withOpacity(0.9);
      icon = Icons.schedule;
    } else if (_isCurrentUserTurn()) {
      turnText = 'Your turn';
      badgeColor = Colors.green.withOpacity(0.2);
      textColor = Colors.green.withOpacity(0.9);
      icon = Icons.access_time;
    } else {
      turnText = 'Partner\'s turn';
      badgeColor = Colors.orange.withOpacity(0.2);
      textColor = Colors.orange.withOpacity(0.9);
      icon = Icons.person_outline;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withOpacity(0.4),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            turnText,
            style: TextStyle(
              color: textColor,
              fontSize: AppTextStyles.getLabelFontSize(context),
              fontWeight: FontWeight.w500,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  bool _isCurrentUserTurn() {
    final isCurrentTurn = gameSession.isCurrentUserTurn(currentUserId);
    AppLogger.info('🎮 _isCurrentUserTurn() check:');
    AppLogger.info('🎮 - currentUserId: $currentUserId');
    AppLogger.info('🎮 - gameSession.currentTurn.userId: ${gameSession.currentTurn.userId}');
    AppLogger.info('🎮 - isCurrentTurn: $isCurrentTurn');
    return isCurrentTurn;
  }

  bool _isGamePending() {
    // Game is pending if sessionId starts with 'pending_'
    final isPending = gameSession.sessionId.startsWith('pending_');
    AppLogger.info('🎮 _isGamePending() check:');
    AppLogger.info('🎮 - sessionId: ${gameSession.sessionId}');
    AppLogger.info('🎮 - isPending: $isPending');
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

  Widget _buildGameDescription(BuildContext context) {
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
          fontSize: AppTextStyles.getBodyFontSize(context),
          fontFamily: 'Nunito',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSendInviteButton(BuildContext context) {
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
        child: Text(
          'Send Invite',
          style: TextStyle(
            fontSize: AppTextStyles.getBodyFontSize(context),
            fontWeight: FontWeight.w600,
            fontFamily: 'Nunito',
            color: AppColors.white85,
          ),
        ),
      ),
    );
  }
}
