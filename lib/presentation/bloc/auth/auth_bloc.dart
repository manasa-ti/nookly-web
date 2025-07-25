import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/presentation/bloc/auth/auth_event.dart';
import 'package:nookly/presentation/bloc/auth/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<SignInWithEmailAndPassword>(_onSignInWithEmailAndPassword);
    on<SignUpWithEmailAndPassword>(_onSignUpWithEmailAndPassword);
    on<SignInWithGoogle>(_onSignInWithGoogle);
    on<SignOut>(_onSignOut);
    on<ForceLogout>(_onForceLogout);
    on<ForgotPassword>(_onForgotPassword);
    on<ResetPassword>(_onResetPassword);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    
    // OTP Event Handlers
    on<SendOtp>(_onSendOtp);
    on<VerifyOtp>(_onVerifyOtp);
    on<ResendOtp>(_onResendOtp);
  }

  Future<void> _onSignInWithEmailAndPassword(
    SignInWithEmailAndPassword event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final authResponse = await _authRepository.signInWithEmailAndPassword(
        event.email,
        event.password,
      );
      
      // Check if email verification is required
      if (authResponse.emailVerificationRequired == true) {
        emit(EmailVerificationRequired(
          email: event.email,
          message: 'Please verify your email to continue.',
        ));
      } else {
        // User is authenticated
        final user = _mapUserModelToEntity(authResponse.user);
        emit(Authenticated(user));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignUpWithEmailAndPassword(
    SignUpWithEmailAndPassword event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final authResponse = await _authRepository.signUpWithEmailAndPassword(
        event.email,
        event.password,
      );
      
      // Check if email verification is required
      if (authResponse.emailVerificationRequired == true) {
        emit(EmailVerificationRequired(
          email: event.email,
          message: 'Please verify your email to complete registration.',
        ));
      } else {
        // User is already authenticated (email verification not required)
        final user = _mapUserModelToEntity(authResponse.user);
        emit(Authenticated(user));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithGoogle();
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignOut(
    SignOut event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onForceLogout(
    ForceLogout event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.signOut();
      emit(AuthError('Invalid Token: ${event.reason}'));
    } catch (e) {
      emit(AuthError('Failed to logout: ${e.toString()}'));
    }
  }

  Future<void> _onForgotPassword(
    ForgotPassword event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.forgotPassword(event.email);
      emit(ForgotPasswordSent(
        message: response.message,
        expiresIn: response.expiresIn,
      ));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onResetPassword(
    ResetPassword event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.resetPassword(event.token, event.newPassword);
      emit(PasswordResetSuccess(message: response.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // OTP Event Handlers
  Future<void> _onSendOtp(
    SendOtp event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final otpResponse = await _authRepository.sendOtp(event.email);
      emit(OtpSent(
        email: otpResponse.email,
        expiresIn: otpResponse.expiresIn,
        retryAfter: otpResponse.retryAfter,
      ));
    } catch (e) {
      emit(OtpError(e.toString()));
    }
  }

  Future<void> _onVerifyOtp(
    VerifyOtp event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final verifyResponse = await _authRepository.verifyOtp(event.email, event.otp);
      final user = _mapUserModelToEntity(verifyResponse.user);
      emit(OtpVerified(user));
    } catch (e) {
      emit(OtpError(e.toString()));
    }
  }

  Future<void> _onResendOtp(
    ResendOtp event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final otpResponse = await _authRepository.resendOtp(event.email);
      emit(OtpSent(
        email: otpResponse.email,
        expiresIn: otpResponse.expiresIn,
        retryAfter: otpResponse.retryAfter,
      ));
    } catch (e) {
      emit(OtpError(e.toString()));
    }
  }

  // Helper method to map UserModel to User entity
  User _mapUserModelToEntity(dynamic userModel) {
    // This is a simplified mapping - you may need to adjust based on your UserModel structure
    
    // Handle location - avoid sending [0, 0] coordinates which might cause geospatial query issues
    Map<String, dynamic>? locationMap;
    if (userModel.location != null && 
        userModel.location.coordinates.isNotEmpty && 
        (userModel.location.coordinates[0] != 0.0 || userModel.location.coordinates[1] != 0.0)) {
      locationMap = {
        'latitude': userModel.location.coordinates[0],
        'longitude': userModel.location.coordinates.length > 1 ? userModel.location.coordinates[1] : 0.0,
      };
    }
    
    return User(
      id: userModel.id,
      email: userModel.email,
      name: userModel.email.split('@')[0],
      age: userModel.age ?? 0,
      sex: userModel.sex ?? '',
      bio: userModel.bio ?? '',
      interests: userModel.interests ?? [],
      profilePic: userModel.profilePic ?? '',
      location: locationMap,
      preferredAgeRange: userModel.preferredAgeRange != null ? {
        'lower_limit': userModel.preferredAgeRange.lowerLimit,
        'upper_limit': userModel.preferredAgeRange.upperLimit,
      } : null,
      hometown: userModel.hometown ?? '',
      seekingGender: userModel.seekingGender ?? '',
      objectives: userModel.objectives ?? [],
    );
  }
} 