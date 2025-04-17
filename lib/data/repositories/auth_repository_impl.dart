import 'package:hushmate/domain/entities/user.dart';
import 'package:hushmate/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  // Mock user data
  final Map<String, dynamic> _mockUser = {
    'id': 'mock-user-id',
    'email': 'user@example.com',
    'name': 'John Doe',
    'age': 25,
    'gender': 'Male',
    'bio': 'Love traveling and trying new cuisines',
    'interests': ['Travel', 'Food', 'Photography'],
    'profilePicture': 'https://example.com/profile.jpg',
    'location': {
      'latitude': 37.7749,
      'longitude': -122.4194,
    },
    'preferences': {
      'ageRange': {'min': 21, 'max': 30},
      'distance': 50,
      'gender': ['Female'],
    },
  };

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock validation
    if (email != _mockUser['email'] || password != 'password123') {
      throw Exception('Invalid email or password');
    }
    
    return User.fromJson(_mockUser);
  }

  @override
  Future<User> signUpWithEmailAndPassword(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock validation
    if (email == _mockUser['email']) {
      throw Exception('Email already exists');
    }
    
    return User.fromJson(_mockUser);
  }

  @override
  Future<User> signInWithGoogle() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock Google sign in
    return User.fromJson(_mockUser);
  }

  @override
  Future<void> resetPassword(String email) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock validation
    if (email != _mockUser['email']) {
      throw Exception('Email not found');
    }
  }

  @override
  Future<void> signOut() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<User?> getCurrentUser() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Always return the mock user for testing
    return User.fromJson(_mockUser);
  }

  @override
  Future<void> updateUserProfile(User user) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Update mock user data
    _mockUser.addAll(user.toJson());
  }

  @override
  Future<void> deleteAccount() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
  }
} 