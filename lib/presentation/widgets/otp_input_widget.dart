import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onCompleted;
  final Function(String) onChanged;
  final bool enabled;
  final String? errorText;

  const OtpInputWidget({
    super.key,
    required this.controller,
    required this.onCompleted,
    required this.onChanged,
    this.enabled = true,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Column(
      children: [
        PinCodeTextField(
          appContext: context,
          length: 6,
          controller: controller,
          onChanged: onChanged,
          onCompleted: onCompleted,
          enabled: enabled,
          keyboardType: TextInputType.number,
          textStyle: TextStyle(
            color: Colors.white,
            fontFamily: 'Nunito',
            fontSize: (size.width * 0.04).clamp(14.0, 18.0),
            fontWeight: FontWeight.w600,
          ),
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(12),
            fieldHeight: (size.width * 0.12).clamp(45.0, 55.0),
            fieldWidth: (size.width * 0.12).clamp(45.0, 55.0),
            activeFillColor: const Color(0xFF35548b),
            inactiveFillColor: const Color(0xFF2a3f6b),
            selectedFillColor: const Color(0xFFf4656f),
            activeColor: const Color(0xFFf4656f),
            inactiveColor: const Color(0xFFD6D9E6),
            selectedColor: const Color(0xFFf4656f),
          ),
          animationType: AnimationType.fade,
          enableActiveFill: true,
          autoFocus: true,
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: const TextStyle(
              color: Colors.red,
              fontFamily: 'Nunito',
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
} 