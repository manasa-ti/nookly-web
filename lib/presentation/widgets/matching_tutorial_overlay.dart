import 'package:flutter/material.dart';
import 'package:nookly/core/services/onboarding_service.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/core/theme/app_text_styles.dart';

class MatchingTutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const MatchingTutorialOverlay({
    Key? key,
    required this.onComplete,
    required this.onSkip,
  }) : super(key: key);

  @override
  State<MatchingTutorialOverlay> createState() => _MatchingTutorialOverlayState();
}

class _MatchingTutorialOverlayState extends State<MatchingTutorialOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _completeTutorial() async {
    try {
      await OnboardingService.markMatchingTutorialCompleted();
      AppLogger.info('Matching tutorial completed');
      widget.onComplete();
    } catch (e) {
      AppLogger.error('Error completing matching tutorial: $e');
      widget.onComplete(); // Still proceed even if marking fails
    }
  }

  void _skipTutorial() async {
    try {
      await OnboardingService.markMatchingTutorialCompleted();
      AppLogger.info('Matching tutorial skipped');
      widget.onSkip();
    } catch (e) {
      AppLogger.error('Error skipping matching tutorial: $e');
      widget.onSkip(); // Still proceed even if marking fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Material(
              color: Colors.black.withOpacity(0.7),
              child: Stack(
                children: [
                  // Semi-transparent background
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _skipTutorial,
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                  
                  // Tutorial content
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5A4B7A), // Purple shade from profile card
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Heart icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.pink.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite_outline,
                              color: Colors.pink,
                              size: 40,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Title
                          Text(
                            'Find Your Match',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppTextStyles.getTitleFontSize(context),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Nunito',
                              color: Colors.white,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Description with single icons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.favorite_border,
                                color: Colors.pink,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Click on heart to like a profile',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: AppTextStyles.getBodyFontSize(context),
                                    fontFamily: 'Nunito',
                                    color: Colors.white70,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Likes received from others appear in Likes',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: AppTextStyles.getBodyFontSize(context),
                                    fontFamily: 'Nunito',
                                    color: Colors.white70,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.chat,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Matched profiles appear in Chat',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: AppTextStyles.getBodyFontSize(context),
                                    fontFamily: 'Nunito',
                                    color: Colors.white70,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Got it button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _completeTutorial,
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
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}