import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/presentation/bloc/auth/auth_bloc.dart';
import 'package:nookly/presentation/bloc/auth/auth_event.dart';
import 'package:nookly/presentation/bloc/auth/auth_state.dart';
import 'package:nookly/presentation/widgets/otp_input_widget.dart';
import 'package:nookly/presentation/widgets/resend_timer_widget.dart';
import 'package:nookly/presentation/pages/home/home_page.dart';
import 'package:nookly/presentation/pages/profile/profile_creation_page.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;
  final bool fromRegistration;

  const EmailVerificationPage({
    super.key,
    required this.email,
    this.fromRegistration = false,
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isOtpLoading = false;
  bool _isResendLoading = false;
  int _retryAfterSeconds = 0;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _onOtpCompleted(String otp) {
    setState(() {
      _isOtpLoading = true;
    });
    context.read<AuthBloc>().add(VerifyOtp(email: widget.email, otp: otp));
  }

  void _onResendOtp() {
    setState(() {
      _isResendLoading = true;
    });
    context.read<AuthBloc>().add(ResendOtp(email: widget.email));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF234481),
      appBar: AppBar(
        backgroundColor: const Color(0xFF234481),
        elevation: 0,
        title: const Text('Verify Your Email', style: TextStyle(color: Colors.white, fontFamily: 'Nunito')),
        centerTitle: true,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is OtpVerified) {
            setState(() {
              _isOtpLoading = false;
            });
            // Navigate to home or profile creation
            if (state.user.isProfileComplete) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const ProfileCreationPage()),
                (route) => false,
              );
            }
          } else if (state is OtpSent) {
            setState(() {
              _isOtpLoading = false;
              _isResendLoading = false;
              _retryAfterSeconds = state.retryAfter;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('OTP sent successfully! Please check your email.')),
            );
          } else if (state is OtpError) {
            setState(() {
              _isOtpLoading = false;
              _isResendLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Enter the 6-digit code sent to',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Nunito',
                    fontSize: (size.width * 0.04).clamp(14.0, 18.0),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.email,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: (size.width * 0.045).clamp(15.0, 20.0),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                OtpInputWidget(
                  controller: _otpController,
                  onCompleted: _onOtpCompleted,
                  onChanged: (_) {},
                  enabled: !_isOtpLoading,
                ),
                const SizedBox(height: 16),
                ResendTimerWidget(
                  retryAfterSeconds: _retryAfterSeconds,
                  onResend: _onResendOtp,
                  isLoading: _isResendLoading,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isOtpLoading
                      ? null
                      : () => _onOtpCompleted(_otpController.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFf4656f),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isOtpLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 