import 'package:hushmate/domain/entities/user.dart';

abstract class AuthRepository {
  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<User> signUpWithEmailAndPassword(String email, String password);
  Future<User> signInWithGoogle();
  Future<void> resetPassword(String email);
  Future<void> signOut();
  Future<User?> getCurrentUser();
  Future<void> updateUserProfile(User user);
  Future<void> deleteAccount();
} 