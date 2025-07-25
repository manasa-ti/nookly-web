import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/core/config/app_config.dart';
import 'package:nookly/presentation/bloc/auth/auth_bloc.dart';
import 'package:nookly/presentation/bloc/auth/auth_event.dart';
import 'package:nookly/presentation/bloc/auth/auth_state.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onForgotPasswordPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            ForgotPassword(email: _emailController.text.trim()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF234481),
      appBar: AppBar(
        title: const Text('Forgot Password', style: TextStyle(fontFamily: 'Nunito', color: Colors.white)),
        backgroundColor: const Color(0xFF234481),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is ForgotPasswordSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enter your email address to reset your password.',
                    style: TextStyle(
                      fontSize: (size.width * 0.04).clamp(14.0, 16.0),
                      fontFamily: 'Nunito',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _onForgotPasswordPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFf4656f),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Send Reset Email',
                      style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: (size.width * 0.035).clamp(12.0, 15.0), fontWeight: FontWeight.w500),
                    ),
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