import 'package:flutter/material.dart';
import 'package:nookly/domain/entities/game_invite.dart';

class GameInviteIndicator extends StatelessWidget {
  final GameInvite gameInvite;
  final VoidCallback? onTap;

  const GameInviteIndicator({
    Key? key,
    required this.gameInvite,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.green.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.games,
              color: Colors.green,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              'Game invite',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }
}





