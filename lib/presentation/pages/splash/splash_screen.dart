import 'package:nookly/core/theme/app_colors.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/presentation/bloc/auth/auth_bloc.dart';
import 'package:nookly/presentation/bloc/auth/auth_event.dart';
import 'package:nookly/presentation/bloc/auth/auth_state.dart';
import 'package:nookly/presentation/pages/auth/login_page.dart';
import 'package:nookly/presentation/pages/home/home_page.dart';
import 'package:nookly/presentation/pages/profile/profile_creation_page.dart';
import 'package:nookly/presentation/pages/onboarding/welcome_tour_page.dart';
import 'package:nookly/core/services/deep_link_service.dart';
import 'package:nookly/core/services/onboarding_service.dart';
import 'package:nookly/core/services/force_update_service.dart';
import 'package:nookly/core/di/injection_container.dart' as di;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();
    _progressController.forward();

    // Check authentication status after animation, but only if no deep link is being processed
    Future.delayed(const Duration(seconds: 3), () {
      final deepLinkService = DeepLinkService();
      if (!deepLinkService.isProcessingDeepLink && deepLinkService.pendingResetToken == null) {
        context.read<AuthBloc>().add(CheckAuthStatus());
      } else {
        // If deep link is being processed or there's a pending reset token, wait a bit more and check again
        Future.delayed(const Duration(seconds: 2), () {
          if (!deepLinkService.isProcessingDeepLink && deepLinkService.pendingResetToken == null) {
            context.read<AuthBloc>().add(CheckAuthStatus());
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is Authenticated) {
          // Check force update first before any navigation
          final forceUpdateService = di.sl<ForceUpdateService>();
          final forceUpdateRequired = await forceUpdateService.checkAndShowForceUpdateIfNeeded(
            context,
            state.user,
          );
          
          if (forceUpdateRequired) {
            AppLogger.info('🔵 SPLASH: Force update required, blocking navigation');
            return; // Don't proceed with navigation if force update is required
          }
          
          // Check if welcome tour should be shown
          final shouldShowWelcomeTour = await OnboardingService.shouldShowWelcomeTour();
          AppLogger.info('🔵 SPLASH: shouldShowWelcomeTour = $shouldShowWelcomeTour');
          
          if (shouldShowWelcomeTour) {
            AppLogger.info('🔵 SPLASH: Showing welcome tour');
            // Show welcome tour first
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => WelcomeTourPage(
                  onComplete: () {
                    // After welcome tour, navigate based on profile completion
                    if (state.user.isProfileComplete) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                      );
                    } else {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const ProfileCreationPage(),
                        ),
                      );
                    }
                  },
                ),
              ),
              (route) => false, // Remove all previous routes
            );
          } else {
            AppLogger.info('🔵 SPLASH: Welcome tour already completed, navigating directly');
            // Welcome tour already completed, navigate directly
            if (state.user.isProfileComplete) {
              // Navigate to home page if profile is complete and clear navigation stack
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const HomePage(),
                ),
                (route) => false, // Remove all previous routes
              );
            } else {
              // Navigate to profile creation if profile is incomplete and clear navigation stack
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const ProfileCreationPage(),
                ),
                (route) => false, // Remove all previous routes
              );
            }
          }
        } else if (state is Unauthenticated) {
          // Check if welcome tour should be shown BEFORE login/signup
          final shouldShowWelcomeTour = await OnboardingService.shouldShowWelcomeTour();
          AppLogger.info('🔵 SPLASH: Unauthenticated - shouldShowWelcomeTour = $shouldShowWelcomeTour');
          
          if (shouldShowWelcomeTour) {
            AppLogger.info('🔵 SPLASH: Showing welcome tour before login');
            // Show welcome tour first, then navigate to login
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => WelcomeTourPage(
                  onComplete: () {
                    // After welcome tour, navigate to login page
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                ),
              ),
              (route) => false, // Remove all previous routes
            );
          } else {
            AppLogger.info('🔵 SPLASH: Welcome tour already completed, navigating directly to login');
            // Welcome tour already completed, navigate directly to login
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const LoginPage(),
              ),
              (route) => false, // Remove all previous routes
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1d335f), // #1d335f - blue
                    Color(0xFF413b62), // #514a7b - purple
                  ],
                ),
              ),
            ),
            
            // Floating elements
            _buildFloatingElements(),
            
            // Main content
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          _buildLogo(),
                          const SizedBox(height: 30),
                          
                          // Title
                          Text(
                            'nookly',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: (MediaQuery.of(context).size.width * 0.09).clamp(24.0, 36.0), // smaller
                              fontWeight: FontWeight.w600,
                              color: AppColors.white85,
                              letterSpacing: 3,
                              shadows: const [
                                Shadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.3),
                                  blurRadius: 15,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: (MediaQuery.of(context).size.height * 0.01).clamp(8.0, 16.0)),
                          // Tagline
                          Opacity(
                            opacity: 0.9,
                            child: Text(
                              'No more lonely',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: (MediaQuery.of(context).size.width * 0.032).clamp(11.0, 15.0), // smaller
                                fontWeight: FontWeight.w500,
                                color: AppColors.white85
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          
                          // Horizontal progress bar
                          _buildProgressBar(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final size = MediaQuery.of(context).size;
    final logoSize = (size.width * 0.35).clamp(100.0, 160.0);
    
    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1d335f).withOpacity(0.5),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Center(
        child: ClipOval(
          child: Image.asset(
            'assets/icons/app_icon.png',
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final progressBarWidth = screenWidth * 0.6;
    
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return SizedBox(
          width: progressBarWidth,
          child: Stack(
            children: [
              // Background track
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Animated progress fill
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: progressBarWidth * _progressAnimation.value,
                    height: 3,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1d335f), // #1d335f - blue
                          Color(0xFF413b62), // #413b62 - purple
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingElements() {
    return Stack(
      children: [
        // Floating element 1
        Positioned(
          top: 100,
          left: 50,
          child: _buildFloatingElement(24, 0),
        ),
        
        // Floating element 2
        Positioned(
          top: 400,
          right: 80,
          child: _buildFloatingElement(18, 3),
        ),
        
        // Floating element 3
        Positioned(
          bottom: 200,
          left: 100,
          child: _buildFloatingElement(20, 6),
        ),
        
        // Floating element 4
        Positioned(
          top: 300,
          right: 60,
          child: _buildFloatingElement(16, 2),
        ),
      ],
    );
  }

  Widget _buildFloatingElement(double size, int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 8),
      builder: (context, value, child) {
        final progress = (value + delay / 8.0) % 1.0;
        final translateY = (progress - 0.5) * 30; // -15 to 15
        final opacity = 0.08 + (progress - 0.5).abs() * 0.14; // 0.08 to 0.15
        
        return Transform.translate(
          offset: Offset(0, translateY),
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.08),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                ),
              ),
              transform: Matrix4.rotationZ(0.785398), // 45 degrees
            ),
          ),
        );
      },
    );
  }

} 