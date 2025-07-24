import 'package:equatable/equatable.dart';
import 'package:nookly/domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// OTP States
class OtpSent extends AuthState {
  final String email;
  final int expiresIn;
  final int retryAfter;

  const OtpSent({
    required this.email,
    required this.expiresIn,
    required this.retryAfter,
  });

  @override
  List<Object?> get props => [email, expiresIn, retryAfter];
}

class OtpVerified extends AuthState {
  final User user;

  const OtpVerified(this.user);

  @override
  List<Object?> get props => [user];
}

class OtpError extends AuthState {
  final String message;

  const OtpError(this.message);

  @override
  List<Object?> get props => [message];
}

class ResendOtpAvailable extends AuthState {
  final String email;

  const ResendOtpAvailable({required this.email});

  @override
  List<Object?> get props => [email];
}

class EmailVerificationRequired extends AuthState {
  final String email;
  final String message;

  const EmailVerificationRequired({
    required this.email,
    required this.message,
  });

  @override
  List<Object?> get props => [email, message];
} 