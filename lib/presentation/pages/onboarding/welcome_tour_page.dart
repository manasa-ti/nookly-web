import 'package:flutter/material.dart';
import 'package:nookly/core/services/onboarding_service.dart';
import 'package:nookly/core/utils/logger.dart';

class WelcomeTourPage extends StatefulWidget {
  final VoidCallback onComplete;

  const WelcomeTourPage({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<WelcomeTourPage> createState() => _WelcomeTourPageState();
}

class _WelcomeTourPageState extends State<WelcomeTourPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<WelcomeSlide> _slides = [
    WelcomeSlide(
      title: 'Welcome to Nookly',
      description: 'Your journey to meaningful connections starts here',
      icon: '👋',
      color: const Color(0xFF6C5CE7),
    ),
    WelcomeSlide(
      title: 'Ditch loneliness',
      description: 'Find genuine connections with people who share your interests',
      icon: '💝',
      color: const Color(0xFFE84393),
    ),
    WelcomeSlide(
      title: 'Find your discreet companion',
      description: 'Connect with like-minded individuals in a safe, private environment',
      icon: '🔒',
      color: const Color(0xFF00B894),
    ),
    WelcomeSlide(
      title: 'Chat and play games together',
      description: 'Break the ice with fun games and meaningful conversations',
      icon: '🎮',
      color: const Color(0xFFFDCB6E),
    ),
    WelcomeSlide(
      title: 'Start your journey',
      description: 'Ready to find your like minded companion? Let\'s begin!',
      icon: '🚀',
      color: const Color(0xFFE17055),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeTour();
    }
  }

  void _skipTour() {
    _completeTour();
  }

  void _completeTour() async {
    try {
      await OnboardingService.markWelcomeTourCompleted();
      AppLogger.info('Welcome tour completed');
      widget.onComplete();
    } catch (e) {
      AppLogger.error('Error completing welcome tour: $e');
      widget.onComplete(); // Still proceed even if marking fails
    }
  }

  @override
  Widget build(BuildContext context) {
        return Scaffold(
          backgroundColor: const Color(0xFF352D49), // Darker purple color
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _skipTour,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _buildSlide(_slides[index]);
                },
              ),
            ),
            
            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index 
                          ? Colors.white 
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            
            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _slides[_currentPage].color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(WelcomeSlide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: slide.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                slide.icon,
                style: const TextStyle(fontSize: 60),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Nunito',
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Description
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontFamily: 'Nunito',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomeSlide {
  final String title;
  final String description;
  final String icon;
  final Color color;

  WelcomeSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
