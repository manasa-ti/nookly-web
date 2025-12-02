import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/core/config/app_config.dart';
import 'package:nookly/presentation/bloc/auth/auth_bloc.dart';
import 'package:nookly/presentation/bloc/auth/auth_event.dart';
import 'package:nookly/presentation/bloc/auth/auth_state.dart';
import 'package:nookly/presentation/pages/auth/login_page.dart';
import 'package:nookly/core/theme/app_text_styles.dart';

class ResetPasswordPage extends StatefulWidget {
  final String token;

  const ResetPasswordPage({
    super.key,
    required this.token,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isTokenValid = true;

  @override
  void initState() {
    super.initState();
    _validateToken();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateToken() {
    // Basic token validation - check if token is not empty and has reasonable length
    if (widget.token.isEmpty || widget.token.length < 10) {
      setState(() {
        _isTokenValid = false;
      });
    }
  }

  void _onResetPasswordPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            ResetPassword(
              token: widget.token,
              newPassword: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF1d335f),
      appBar: AppBar(
        title: const Text('Reset Password', style: TextStyle(fontFamily: 'Nunito', color: Colors.white)),
        backgroundColor: const Color(0xFF1d335f),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is PasswordResetSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Navigate to login page and clear navigation stack
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginPage(),
              ),
              (route) => false,
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConfig.defaultPadding),
            child: _isTokenValid ? Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enter your new password below.',
                    style: TextStyle(
                      fontSize: AppTextStyles.getSectionHeaderFontSize(context),
                      fontFamily: 'Nunito',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: const Color(0xFF1d335f),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: TextStyle(color: Colors.white, fontFamily: 'Nunito', fontSize: AppTextStyles.getBodyFontSize(context)),
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          labelStyle: TextStyle(color: Color(0xFFD6D9E6), fontFamily: 'Nunito', fontSize: AppTextStyles.getLabelFontSize(context)),
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
                            return 'Please enter a new password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: const Color(0xFF1d335f),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        style: TextStyle(color: Colors.white, fontFamily: 'Nunito', fontSize: AppTextStyles.getBodyFontSize(context)),
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          labelStyle: TextStyle(color: Color(0xFFD6D9E6), fontFamily: 'Nunito', fontSize: AppTextStyles.getLabelFontSize(context)),
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
                            return 'Please confirm your new password';
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
                    onPressed: _onResetPasswordPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFf4656f),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Reset Password',
                      style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: AppTextStyles.getBodyFontSize(context), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ) : _buildInvalidTokenError(size),
          ),
        ),
      ),
    );
  }

  Widget _buildInvalidTokenError(Size size) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 64,
        ),
        const SizedBox(height: 24),
        Text(
          'Invalid Reset Link',
          style: TextStyle(
            fontSize: AppTextStyles.getLargeTitleFontSize(context),
            fontFamily: 'Nunito',
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'This password reset link is invalid or has expired. Please request a new password reset.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppTextStyles.getSectionHeaderFontSize(context),
            fontFamily: 'Nunito',
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginPage(),
              ),
              (route) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFf4656f),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
          child: Text(
            'Back to Login',
            style: TextStyle(
              fontFamily: 'Nunito',
              color: Colors.white,
              fontSize: AppTextStyles.getBodyFontSize(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
} 