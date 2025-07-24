import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class SignInWithEmailAndPassword extends AuthEvent {
  final String email;
  final String password;

  const SignInWithEmailAndPassword({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class SignUpWithEmailAndPassword extends AuthEvent {
  final String email;
  final String password;

  const SignUpWithEmailAndPassword({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class SignInWithGoogle extends AuthEvent {}

class SignOut extends AuthEvent {}

class ForceLogout extends AuthEvent {
  final String reason;

  const ForceLogout({required this.reason});

  @override
  List<Object?> get props => [reason];
}

class ResetPassword extends AuthEvent {
  final String email;

  const ResetPassword({required this.email});

  @override
  List<Object?> get props => [email];
}

class CheckAuthStatus extends AuthEvent {}

// OTP Events
class SendOtp extends AuthEvent {
  final String email;

  const SendOtp({required this.email});

  @override
  List<Object?> get props => [email];
}

class VerifyOtp extends AuthEvent {
  final String email;
  final String otp;

  const VerifyOtp({
    required this.email,
    required this.otp,
  });

  @override
  List<Object?> get props => [email, otp];
}

class ResendOtp extends AuthEvent {
  final String email;

  const ResendOtp({required this.email});

  @override
  List<Object?> get props => [email];
} 