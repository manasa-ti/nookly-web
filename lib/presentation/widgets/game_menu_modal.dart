import 'package:flutter/material.dart';
import 'package:nookly/domain/entities/game_session.dart';

class GameMenuModal extends StatelessWidget {
  final String matchUserId;
  final Function(String) onGameSelected;

  const GameMenuModal({
    Key? key,
    required this.matchUserId,
    required this.onGameSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.games,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Play to Bond',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Game options
          _buildGameOption(
            context,
            GameType.truthOrThrill,
            Icons.psychology,
            'Truth or Thrill',
            'Choose between revealing truths or taking thrilling challenges',
          ),
          const SizedBox(height: 16),
          
          _buildGameOption(
            context,
            GameType.memorySparks,
            Icons.auto_awesome,
            'Memory Sparks',
            'Share your favorite memories and create new ones together',
          ),
          const SizedBox(height: 16),
          
          _buildGameOption(
            context,
            GameType.wouldYouRather,
            Icons.help_outline,
            'Would You Rather',
            'Make tough choices and discover each other\'s preferences',
          ),
          const SizedBox(height: 16),
          
          _buildGameOption(
            context,
            GameType.guessMe,
            Icons.quiz,
            'Guess Me',
            'Test how well you know each other with fun guessing games',
          ),
        ],
      ),
    );
  }

  Widget _buildGameOption(
    BuildContext context,
    GameType gameType,
    IconData icon,
    String title,
    String description, {
    bool isComingSoon = false,
  }) {
    return GestureDetector(
      onTap: isComingSoon ? null : () => onGameSelected(gameType.apiValue),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isComingSoon 
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isComingSoon 
                    ? Colors.white.withOpacity(0.5)
                    : Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: isComingSoon 
                                ? Colors.white.withOpacity(0.5)
                                : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                      if (isComingSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            'Coming Soon',
                            style: TextStyle(
                              color: Colors.orange.withOpacity(0.8),
                              fontSize: 10,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: isComingSoon 
                          ? Colors.white.withOpacity(0.4)
                          : Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
            if (!isComingSoon)
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.5),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}





