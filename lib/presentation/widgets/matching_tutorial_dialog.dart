import 'package:flutter/material.dart';
import 'package:nookly/core/services/onboarding_service.dart';
import 'package:nookly/core/theme/app_text_styles.dart';

class MatchingTutorialDialog extends StatelessWidget {
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;

  const MatchingTutorialDialog({
    Key? key,
    this.onComplete,
    this.onSkip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF5A4B7A), // Purple background matching app theme
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Find Your Match',
              style: TextStyle(
                fontSize: AppTextStyles.getTitleFontSize(context),
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 24),
            
            // Instructions
            _buildInstruction(
              context: context,
              icon: Icons.favorite_border,
              text: 'Click on heart to like a profile',
            ),
            const SizedBox(height: 16),
            
            _buildInstruction(
              context: context,
              icon: Icons.favorite,
              text: 'Likes received from others appear in Likes',
            ),
            const SizedBox(height: 16),
            
            _buildInstruction(
              context: context,
              icon: Icons.chat_bubble_outline,
              text: 'Matched profiles appear in Chat',
            ),
            const SizedBox(height: 24),
            
            // Got it button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  OnboardingService.markMatchingTutorialCompleted();
                  onComplete?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF5A4B7A),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Got it!',
                  style: TextStyle(
                    fontSize: AppTextStyles.getBodyFontSize(context),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Nunito',
                    decoration: TextDecoration.none, // Remove underline
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction({
    required BuildContext context,
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: AppTextStyles.getBodyFontSize(context),
              color: Colors.white,
              fontFamily: 'Nunito',
            ),
          ),
        ),
      ],
    );
  }
}
