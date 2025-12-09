import 'package:flutter/material.dart';
import 'package:nookly/core/services/onboarding_service.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/core/theme/app_text_styles.dart';

class GamesTutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const GamesTutorialOverlay({
    Key? key,
    required this.onComplete,
    required this.onSkip,
  }) : super(key: key);

  @override
  State<GamesTutorialOverlay> createState() => _GamesTutorialOverlayState();
}

class _GamesTutorialOverlayState extends State<GamesTutorialOverlay>
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
      await OnboardingService.markGamesTutorialCompleted();
      AppLogger.info('Games tutorial completed');
      widget.onComplete();
    } catch (e) {
      AppLogger.error('Error completing games tutorial: $e');
      widget.onComplete(); // Still proceed even if marking fails
    }
  }

  void _skipTutorial() async {
    try {
      await OnboardingService.markGamesTutorialCompleted();
      AppLogger.info('Games tutorial skipped');
      widget.onSkip();
    } catch (e) {
      AppLogger.error('Error skipping games tutorial: $e');
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
                        color: Colors.white,
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
                          // Games icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.games,
                              color: Colors.purple,
                              size: 40,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Title
                          Text(
                            'Play 2 Bond',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppTextStyles.getTitleFontSize(context),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Nunito',
                              color: Colors.black87,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Description
                          Text(
                            'Choose a game to play together',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppTextStyles.getBodyFontSize(context),
                              fontFamily: 'Nunito',
                              color: Colors.black54,
                              height: 1.5,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            'Send invite to your connection',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppTextStyles.getBodyFontSize(context),
                              fontFamily: 'Nunito',
                              color: Colors.black54,
                              height: 1.5,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            'Take turns answering questions',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppTextStyles.getBodyFontSize(context),
                              fontFamily: 'Nunito',
                              color: Colors.black54,
                              height: 1.5,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            'Have fun getting to know each other!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppTextStyles.getBodyFontSize(context),
                              fontFamily: 'Nunito',
                              color: Colors.black54,
                              height: 1.5,
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: _skipTutorial,
                                  child: Text(
                                    'Skip',
                                    style: TextStyle(
                                      fontSize: AppTextStyles.getBodyFontSize(context),
                                      fontFamily: 'Nunito',
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _completeTutorial,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
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
