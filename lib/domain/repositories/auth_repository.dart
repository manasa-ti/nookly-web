import 'package:hushmate/domain/entities/user.dart';
import 'package:hushmate/data/models/auth/auth_response_model.dart';
import 'package:hushmate/data/models/auth/login_request_model.dart';
import 'package:hushmate/data/models/auth/register_request_model.dart';

abstract class AuthRepository {
  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<User> signUpWithEmailAndPassword(String email, String password);
  Future<User> signInWithGoogle();
  Future<void> resetPassword(String email);
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
} 