import 'package:flutter/material.dart';
import 'package:timer_builder/timer_builder.dart';

class ResendTimerWidget extends StatelessWidget {
  final int retryAfterSeconds;
  final VoidCallback onResend;
  final bool isLoading;

  const ResendTimerWidget({
    super.key,
    required this.retryAfterSeconds,
    required this.onResend,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return TimerBuilder.periodic(
      const Duration(seconds: 1),
      builder: (context) {
        final now = DateTime.now();
        final endTime = now.add(Duration(seconds: retryAfterSeconds));
        final remaining = endTime.difference(now).inSeconds;
        
        if (remaining <= 0) {
          return Column(
            children: [
              Text(
                "Didn't receive the code?",
                style: TextStyle(
                  color: const Color(0xFFD6D9E6),
                  fontFamily: 'Nunito',
                  fontSize: (size.width * 0.032).clamp(11.0, 13.0),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: isLoading ? null : onResend,
                child: isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Resend OTP',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Nunito',
                          fontSize: (size.width * 0.032).clamp(11.0, 13.0),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
              ),
            ],
          );
        }
        
        return Column(
          children: [
            Text(
              "Didn't receive the code?",
              style: TextStyle(
                color: const Color(0xFFD6D9E6),
                fontFamily: 'Nunito',
                fontSize: (size.width * 0.032).clamp(11.0, 13.0),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Resend available in ${remaining}s',
              style: TextStyle(
                color: const Color(0xFFD6D9E6),
                fontFamily: 'Nunito',
                fontSize: (size.width * 0.03).clamp(10.0, 12.0),
              ),
            ),
          ],
        );
      },
    );
  }
} 