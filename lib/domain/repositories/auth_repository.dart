import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/data/models/auth/auth_response_model.dart';
import 'package:nookly/data/models/auth/login_request_model.dart';
import 'package:nookly/data/models/auth/register_request_model.dart';
import 'package:nookly/data/models/auth/otp_response_model.dart';
import 'package:nookly/data/models/auth/verify_otp_response_model.dart';
import 'package:nookly/data/models/auth/forgot_password_response_model.dart';
import 'package:nookly/data/models/auth/reset_password_response_model.dart';

abstract class AuthRepository {
  Future<AuthResponseModel> signInWithEmailAndPassword(String email, String password);
  Future<AuthResponseModel> signUpWithEmailAndPassword(String email, String password);
  Future<User> signInWithGoogle();
  Future<ForgotPasswordResponseModel> forgotPassword(String email);
  Future<ResetPasswordResponseModel> resetPassword(String token, String newPassword);
  Future<void> signOut();
  Future<User?> getCurrentUser();
  Future<void> updateUserProfile(User user);
  Future<void> deleteAccount();
  Future<AuthResponseModel> login(LoginRequestModel request);
  Future<AuthResponseModel> register(RegisterRequestModel request);
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<String?> getToken();
  Future<List<String>> getPredefinedInterests();
  Future<List<String>> getPredefinedObjectives();
  
  // OTP Methods
  Future<OtpResponseModel> sendOtp(String email);
  Future<VerifyOtpResponseModel> verifyOtp(String email, String otp);
  Future<OtpResponseModel> resendOtp(String email);
} 