import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nookly/core/config/app_config.dart';
import 'package:nookly/presentation/bloc/auth/auth_bloc.dart';
import 'package:nookly/presentation/bloc/auth/auth_event.dart';
import 'package:nookly/presentation/bloc/auth/auth_state.dart';
import 'package:nookly/presentation/pages/profile/profile_creation_page.dart';
import 'package:nookly/presentation/pages/auth/email_verification_page.dart';
import 'package:nookly/presentation/widgets/safety_tips_banner.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isEmailLoading = false; // Add loading state for email sign up
  bool _isGoogleLoading = false; // Add loading state for Google sign up
  bool _showSafetyTips = true; // Control safety tips visibility

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSignUpPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isEmailLoading = true;
        _isGoogleLoading = false;
      });
      context.read<AuthBloc>().add(
            SignUpWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  void _onGoogleSignInPressed() {
    setState(() {
      _isGoogleLoading = true;
      _isEmailLoading = false;
    });
    context.read<AuthBloc>().add(SignInWithGoogle());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF234481),
      appBar: AppBar(
        title: const Text('Sign Up', style: TextStyle(fontFamily: 'Nunito', color: Colors.white)),
        backgroundColor: const Color(0xFF234481),
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            setState(() {
              _isEmailLoading = false;
              _isGoogleLoading = false;
            });
            // Navigate to profile creation and clear navigation stack
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileCreationPage(),
              ),
              (route) => false, // Remove all previous routes
            );
          } else if (state is EmailVerificationRequired) {
            setState(() {
              _isEmailLoading = false;
              _isGoogleLoading = false;
            });
            // Navigate to email verification page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmailVerificationPage(
                  email: state.email,
                  fromRegistration: true,
                ),
              ),
            );
          } else if (state is AuthError) {
            setState(() {
              _isEmailLoading = false;
              _isGoogleLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
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
                  const SizedBox(height: 40), // Match login page top margin
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: (size.width * 0.05).clamp(16.0, 20.0),
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32), // Match login page spacing
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
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
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
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
                  const SizedBox(height: 12),
                  Card(
                    color: const Color(0xFF35548b),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        style: TextStyle(color: Colors.white, fontFamily: 'Nunito', fontSize: (size.width * 0.035).clamp(12.0, 15.0)),
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: TextStyle(color: Color(0xFFD6D9E6), fontFamily: 'Nunito', fontSize: (size.width * 0.032).clamp(11.0, 13.0)),
                          prefixIcon: const Icon(Icons.lock, color: Color(0xFFD6D9E6), size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                              color: const Color(0xFFD6D9E6),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Safety Tips Banner
                  if (_showSafetyTips)
                    SafetyTipsBanner(
                      onSkip: () {
                        setState(() {
                          _showSafetyTips = false;
                        });
                      },
                      onComplete: () {
                        setState(() {
                          _showSafetyTips = false;
                        });
                      },
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isEmailLoading ? null : _onSignUpPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFf4656f),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 12), // Match login page
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
                            'Sign Up',
                            style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: (size.width * 0.035).clamp(12.0, 15.0), fontWeight: FontWeight.w500),
                          ),
                  ),
                  const SizedBox(height: 14),
                  // Divider with "or" text
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFD6D9E6).withOpacity(0.3),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12), // Match login page
                        child: Text(
                          'or',
                          style: TextStyle(
                            color: const Color(0xFFD6D9E6),
                            fontFamily: 'Nunito',
                            fontSize: (size.width * 0.03).clamp(10.0, 12.0), // Match login page
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFD6D9E6).withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Google Sign-In Button
                  ElevatedButton.icon(
                    onPressed: _isGoogleLoading ? null : _onGoogleSignInPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: const Color(0xFFD6D9E6).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12), // Match login page
                      elevation: 2,
                    ),
                    icon: _isGoogleLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                            ),
                          )
                        : Container(
                            width: 18,
                            height: 18,
                            child: SvgPicture.asset(
                              'assets/icons/google_icon.svg',
                              fit: BoxFit.contain,
                            ),
                          ),
                    label: Text(
                      _isGoogleLoading ? 'Signing up...' : 'Continue with Google',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: (size.width * 0.035).clamp(12.0, 15.0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account?',
                        style: TextStyle(color: Color(0xFFD6D9E6), fontFamily: 'Nunito'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Sign In',
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