import 'package:nookly/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/flutter_svg.dart'; // Temporarily unused
import 'package:nookly/core/config/app_config.dart';
import 'package:nookly/presentation/bloc/auth/auth_bloc.dart';
import 'package:nookly/presentation/bloc/auth/auth_event.dart';
import 'package:nookly/presentation/bloc/auth/auth_state.dart';
import 'package:nookly/presentation/pages/auth/forgot_password_page.dart';
import 'package:nookly/presentation/pages/profile/profile_creation_page.dart';
import 'package:nookly/presentation/pages/auth/sign_up_page.dart';
import 'package:nookly/presentation/pages/home/home_page.dart';
import 'package:nookly/presentation/pages/auth/email_verification_page.dart';
import 'package:nookly/presentation/pages/onboarding/welcome_tour_page.dart';
import 'package:nookly/core/services/onboarding_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isEmailLoading = false; // Track email sign in loading

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignInPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isEmailLoading = true;
      });
      context.read<AuthBloc>().add(
            SignInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  void _onForgotPasswordPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordPage(),
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF234481),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is Authenticated) {
            setState(() {
              _isEmailLoading = false;
            });
            
            // Check if welcome tour should be shown
            final shouldShowWelcomeTour = await OnboardingService.shouldShowWelcomeTour();
            AppLogger.info('🔵 LOGIN: shouldShowWelcomeTour = $shouldShowWelcomeTour');
            
            if (shouldShowWelcomeTour) {
              AppLogger.info('🔵 LOGIN: Showing welcome tour');
              // Show welcome tour first
              Navigator.pushAndRemoveUntil(
                context,
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
              AppLogger.info('🔵 LOGIN: Welcome tour already completed, navigating directly');
              // Welcome tour already completed, navigate directly
              if (state.user.isProfileComplete) {
                // Navigate to home page and clear navigation stack
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomePage(),
                  ),
                  (route) => false, // Remove all previous routes
                );
              } else {
                // Navigate to profile creation and clear navigation stack
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileCreationPage(),
                  ),
                  (route) => false, // Remove all previous routes
                );
              }
            }
          } else if (state is EmailVerificationRequired) {
            setState(() {
              _isEmailLoading = false;
            });
            // Navigate to email verification page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmailVerificationPage(
                  email: state.email,
                  fromRegistration: false,
                ),
              ),
            );
          } else if (state is AuthError) {
            setState(() {
              _isEmailLoading = false;
            });
            
            // Provide user-friendly error messages for common issues
            String userMessage = state.message;
            if (state.message.contains('timed out') || state.message.contains('buffering')) {
              userMessage = 'Server is temporarily unavailable. Please try again in a moment.';
            } else if (state.message.contains('network') || state.message.contains('connection')) {
              userMessage = 'Network connection issue. Please check your internet connection.';
            } else if (state.message.contains('Invalid credentials') || state.message.contains('401')) {
              userMessage = 'Invalid email or password. Please try again.';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(userMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConfig.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40), // Add top margin for app bar space
                  Text(
                    'Welcome to nookly',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: (size.width * 0.05).clamp(16.0, 20.0),
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32), // Match sign up page spacing
                  Card(
                    color: const Color(0xFF35548b),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: Colors.white, fontFamily: 'Nunito', fontSize: (size.width * 0.035).clamp(12.0, 15.0)),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Color(0xFFD6D9E6), fontFamily: 'Nunito', fontSize: (size.width * 0.032).clamp(11.0, 13.0)),
                          prefixIcon: Icon(Icons.email, color: Color(0xFFD6D9E6), size: 20),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: const Color(0xFF35548b),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: TextStyle(color: Colors.white, fontFamily: 'Nunito', fontSize: (size.width * 0.035).clamp(12.0, 15.0)),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: Color(0xFFD6D9E6), fontFamily: 'Nunito', fontSize: (size.width * 0.032).clamp(11.0, 13.0)),
                          prefixIcon: const Icon(Icons.lock, color: Color(0xFFD6D9E6), size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                              color: const Color(0xFFD6D9E6),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _onForgotPasswordPressed,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Color(0xFFD6D9E6), fontFamily: 'Nunito'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isEmailLoading ? null : _onSignInPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFf4656f),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isEmailLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Sign In',
                            style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: (size.width * 0.035).clamp(12.0, 15.0), fontWeight: FontWeight.w500),
                          ),
                  ),
                  // Temporarily hidden Google Sign-In Button
                  // const SizedBox(height: 14),
                  // // Divider with "or" text
                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: Container(
                  //         height: 1,
                  //         color: const Color(0xFFD6D9E6).withOpacity(0.3),
                  //       ),
                  //     ),
                  //     Padding(
                  //       padding: const EdgeInsets.symmetric(horizontal: 12),
                  //       child: Text(
                  //         'or',
                  //         style: TextStyle(
                  //           color: const Color(0xFFD6D9E6),
                  //           fontFamily: 'Nunito',
                  //           fontSize: (size.width * 0.03).clamp(10.0, 12.0), // smaller
                  //         ),
                  //       ),
                  //     ),
                  //     Expanded(
                  //       child: Container(
                  //         height: 1,
                  //         color: const Color(0xFFD6D9E6).withOpacity(0.3),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // const SizedBox(height: 14),
                  // // Google Sign-In Button
                  // ElevatedButton.icon(
                  //   onPressed: _isGoogleLoading ? null : _onGoogleSignInPressed,
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.white,
                  //     foregroundColor: Colors.black87,
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(20),
                  //       side: BorderSide(
                  //         color: const Color(0xFFD6D9E6).withOpacity(0.3),
                  //         width: 1,
                  //       ),
                  //     ),
                  //     padding: const EdgeInsets.symmetric(vertical: 12), // less padding
                  //     elevation: 2,
                  //   ),
                  //   icon: _isGoogleLoading
                  //       ? const SizedBox(
                  //           height: 18,
                  //           width: 18,
                  //           child: CircularProgressIndicator(
                  //             strokeWidth: 2,
                  //             valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                  //           ),
                  //         )
                  //       : Container(
                  //           width: 18,
                  //           height: 18,
                  //           child: SvgPicture.asset(
                  //             'assets/icons/google_icon.svg',
                  //             fit: BoxFit.contain,
                  //           ),
                  //         ),
                  //   label: Text(
                  //     _isGoogleLoading ? 'Signing in...' : 'Continue with Google',
                  //     style: TextStyle(
                  //       fontFamily: 'Nunito',
                  //       fontSize: (size.width * 0.035).clamp(12.0, 15.0),
                  //       fontWeight: FontWeight.w500,
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Don\'t have an account?',
                        style: TextStyle(color: Color(0xFFD6D9E6), fontFamily: 'Nunito'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: TextStyle(color: Colors.white, fontFamily: 'Nunito', fontSize: (size.width * 0.035).clamp(12.0, 15.0), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 