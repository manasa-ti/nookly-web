import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nookly/core/config/app_config.dart';
import 'package:nookly/presentation/bloc/auth/auth_bloc.dart';
import 'package:nookly/presentation/bloc/auth/auth_event.dart';
import 'package:nookly/presentation/bloc/auth/auth_state.dart';
import 'package:nookly/presentation/pages/profile/profile_creation_page.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSignUpPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            SignUpWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  void _onGoogleSignInPressed() {
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
            // Navigate to profile creation and clear navigation stack
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileCreationPage(),
              ),
              (route) => false, // Remove all previous routes
            );
          } else if (state is AuthError) {
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
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  const SizedBox(height: 24),
                  Card(
                    color: const Color(0xFF35548b),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // less padding
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: Colors.white, fontFamily: 'Nunito', fontSize: (size.width * 0.035).clamp(12.0, 15.0)), // smaller
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Color(0xFFD6D9E6), fontFamily: 'Nunito', fontSize: (size.width * 0.032).clamp(11.0, 13.0)),
                          prefixIcon: Icon(Icons.email, color: Color(0xFFD6D9E6), size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8), // less height
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // less padding
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: TextStyle(color: Colors.white, fontFamily: 'Nunito', fontSize: (size.width * 0.035).clamp(12.0, 15.0)), // smaller
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
                          contentPadding: const EdgeInsets.symmetric(vertical: 8), // less height
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // less padding
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        style: TextStyle(color: Colors.white, fontFamily: 'Nunito', fontSize: (size.width * 0.035).clamp(12.0, 15.0)), // smaller
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
                          contentPadding: const EdgeInsets.symmetric(vertical: 8), // less height
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
                  ElevatedButton(
                    onPressed: _onSignUpPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFf4656f),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: (size.width * 0.04).clamp(14.0, 16.0), fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: TextStyle(
                            color: const Color(0xFFD6D9E6),
                            fontFamily: 'Nunito',
                            fontSize: (size.width * 0.035).clamp(12.0, 15.0),
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
                  const SizedBox(height: 16),
                  // Google Sign-In Button
                  ElevatedButton.icon(
                    onPressed: _onGoogleSignInPressed,
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                    ),
                    icon: Container(
                      width: 20,
                      height: 20,
                      child: SvgPicture.asset(
                        'assets/icons/google_icon.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                    label: Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: (size.width * 0.04).clamp(14.0, 16.0),
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