import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/presentation/bloc/auth/auth_bloc.dart';
import 'package:nookly/presentation/bloc/auth/auth_event.dart';
import 'package:nookly/presentation/bloc/auth/auth_state.dart';
import 'package:nookly/presentation/pages/auth/login_page.dart';
import 'package:nookly/presentation/pages/home/home_page.dart';
import 'package:nookly/presentation/pages/profile/profile_creation_page.dart';
import 'package:nookly/core/config/app_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _loadingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _loadingController = AnimationController(
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

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();
    _loadingController.repeat();

    // Check authentication status after animation
    Future.delayed(const Duration(seconds: 3), () {
      context.read<AuthBloc>().add(CheckAuthStatus());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
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
        } else if (state is Unauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
            (route) => false, // Remove all previous routes
          );
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
                    Color(0xFF234481), // #234481
                    Color(0xFF2D4B8A), // #2D4B8A
                    Color(0xFF5A4B7A), // #5A4B7A
                  ],
                  stops: [0.0, 0.5, 1.0],
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
                              color: Colors.white,
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
                              'Never be lonely',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: (MediaQuery.of(context).size.width * 0.032).clamp(11.0, 15.0), // smaller
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          
                          // Loading bar
                          _buildLoadingBar(),
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
    final logoSize = (size.width * 0.25).clamp(80.0, 120.0);
    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF234481), // #234481
            Color(0xFF5A4B7A), // #5A4B7A
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.15),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF234481).withOpacity(0.5),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main "N" letter
          Center(
            child: Text(
              'N',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: (logoSize * 0.48).clamp(32.0, 48.0),
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 2,
                shadows: const [
                  Shadow(
                    color: Color.fromRGBO(0, 0, 0, 0.4),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          
          // Diamond accent
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.6),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                ),
              ),
              transform: Matrix4.rotationZ(0.785398), // 45 degrees
            ),
          ),
        ],
      ),
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

  Widget _buildLoadingBar() {
    return Container(
      width: 220,
      height: 4,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: AnimatedBuilder(
        animation: _loadingAnimation,
        builder: (context, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _loadingAnimation.value,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF234481), // #234481
                    Color(0xFF5A4B7A), // #5A4B7A
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        },
      ),
    );
  }
} 