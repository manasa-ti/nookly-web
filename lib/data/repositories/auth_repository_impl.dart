import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:nookly/core/network/network_service.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/core/services/google_sign_in_service.dart';
import 'package:nookly/data/models/auth/auth_response_model.dart';
import 'package:nookly/data/models/auth/login_request_model.dart';
import 'package:nookly/data/models/auth/register_request_model.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SharedPreferences _prefs;

  AuthRepositoryImpl(this._prefs);

  @override
  Future<AuthResponseModel> login(LoginRequestModel request) async {
    try {
      AppLogger.info('Attempting login for user: ${request.email}');
      final response = await NetworkService.dio.post(
        '/users/login',
        data: request.toJson(),
      );

      final authResponse = AuthResponseModel.fromJson(response.data);
      await _saveToken(authResponse.token);
      await _saveUserId(authResponse.user.id);
      NetworkService.setAuthToken(authResponse.token);
      AppLogger.info('Login successful for user: ${request.email}');
      return authResponse;
    } on DioException catch (e) {
      AppLogger.error(
        'Login failed',
        e,
        StackTrace.current,
      );
      throw Exception('Failed to login: ${e.response?.data ?? e.message}');
    }
  }

  @override
  Future<AuthResponseModel> register(RegisterRequestModel request) async {
    try {
      AppLogger.info('Attempting registration for user: ${request.email}');
      final response = await NetworkService.dio.post(
        '/users/register',
        data: request.toJson(),
      );

      final authResponse = AuthResponseModel.fromJson(response.data);
      await _saveToken(authResponse.token);
      await _saveUserId(authResponse.user.id);
      NetworkService.setAuthToken(authResponse.token);
      AppLogger.info('Registration successful for user: ${request.email}');
      return authResponse;
    } on DioException catch (e) {
      AppLogger.error(
        'Registration failed',
        e,
        StackTrace.current,
      );
      throw Exception('Failed to register: ${e.response?.data ?? e.message}');
    }
  }

  @override
  Future<void> logout() async {
    await _prefs.remove('token');
    await _prefs.remove('userId');
    NetworkService.clearAuthToken();
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  @override
  Future<String?> getToken() async {
    return _prefs.getString('token');
  }

  Future<void> _saveToken(String token) async {
    await _prefs.setString('token', token);
  }

  Future<void> _saveUserId(String userId) async {
    await _prefs.setString('userId', userId);
  }

  Future<String?> _getUserId() async {
    return _prefs.getString('userId');
  }

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    final request = LoginRequestModel(email: email, password: password);
    final response = await login(request);
    return _mapUserModelToEntity(response.user);
  }

  @override
  Future<User> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final response = await NetworkService.dio.post(
        '/users/register',
        data: {
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponseModel.fromJson(response.data);
      await _saveToken(authResponse.token);
      await _saveUserId(authResponse.user.id);
      NetworkService.setAuthToken(authResponse.token);
      return _mapUserModelToEntity(authResponse.user);
    } on DioException catch (e) {
      throw Exception('Failed to register: ${e.response?.data ?? e.message}');
    }
  }

  @override
  Future<User> signInWithGoogle() async {
    try {
      AppLogger.info('Starting Google Sign-In process');
      
      // Get the Google Sign-In service instance
      final googleSignInService = GoogleSignInService.instance;
      try {
        googleSignInService.initialize();
        AppLogger.info('GoogleSignInService initialized in repository');
      } catch (error) {
        AppLogger.error('Failed to initialize GoogleSignInService in repository', error, StackTrace.current);
        throw Exception('Failed to initialize Google Sign-In: $error');
      }
      
      // Get Google auth data
      final authData = await googleSignInService.getAuthData();
      
      if (authData == null) {
        throw Exception('Google Sign-In was cancelled or failed');
      }

      AppLogger.info('Google auth data received, sending to backend');
      AppLogger.info('=== SENDING TO BACKEND ===');
      AppLogger.info('Email: ${authData['email']}');
      AppLogger.info('Display Name: ${authData['displayName']}');
      AppLogger.info('Photo URL: ${authData['photoUrl']}');
      AppLogger.info('ID Token length: ${authData['idToken']?.length ?? 0}');
      AppLogger.info('ID Token content: ${authData['idToken']}');
      AppLogger.info('Access Token length: ${authData['accessToken']?.length ?? 0}');
      AppLogger.info('Server Auth Code length: ${authData['serverAuthCode']?.length ?? 0}');
      AppLogger.info('==========================');
      
      // Send Google auth data to backend
      final response = await NetworkService.dio.post(
        '/users/google-signin',
        data: {
          'idToken': authData['idToken'],
          'accessToken': authData['accessToken'],
          'serverAuthCode': authData['serverAuthCode'],
          'email': authData['email'],
          'displayName': authData['displayName'],
          'photoUrl': authData['photoUrl'],
        },
      );

      AppLogger.info('=== BACKEND RESPONSE ===');
      AppLogger.info('Response status: ${response.statusCode}');
      AppLogger.info('Response data: ${response.data}');
      AppLogger.info('=======================');
      
      final authResponse = AuthResponseModel.fromJson(response.data);
      await _saveToken(authResponse.token);
      await _saveUserId(authResponse.user.id);
      NetworkService.setAuthToken(authResponse.token);
      
      AppLogger.info('Google Sign-In successful for user: ${authData['email']}');
      AppLogger.info('JWT Token received: ${authResponse.token.substring(0, 20)}...');
      AppLogger.info('User ID: ${authResponse.user.id}');
      return _mapUserModelToEntity(authResponse.user);
    } on DioException catch (e) {
      AppLogger.error(
        'Google Sign-In failed',
        e,
        StackTrace.current,
      );
      AppLogger.error('DioException details:');
      AppLogger.error('Status code: ${e.response?.statusCode}');
      AppLogger.error('Response data: ${e.response?.data}');
      AppLogger.error('Error message: ${e.message}');
      throw Exception('Failed to sign in with Google: ${e.response?.data ?? e.message}');
    } catch (e) {
      AppLogger.error(
        'Unexpected error in Google Sign-In',
        e,
        StackTrace.current,
      );
      throw Exception('Google Sign-In failed: $e');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await NetworkService.dio.post(
        '/users/reset-password',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw Exception('Failed to reset password: ${e.response?.data ?? e.message}');
    }
  }

  @override
  Future<void> signOut() async {
    await logout();
  }

  @override
  Future<User?> getCurrentUser() async {
    final token = await getToken();
    final userId = await _getUserId();
    
    if (token == null || userId == null) {
      AppLogger.warning('getCurrentUser called but no token or userId found');
      return null;
    }

    try {
      AppLogger.info('Fetching current user profile for userId: $userId');
      final response = await NetworkService.dio.get('/users/profile/$userId');
      final userData = response.data;
      AppLogger.info('Raw API response: $userData');
      
      // Validate user data
      if (userData == null) {
        AppLogger.error('API response is null');
        return null;
      }

      // Log each field to check what's missing
      AppLogger.info('User data fields:');
      AppLogger.info('_id: ${userData['_id']}');
      AppLogger.info('email: ${userData['email']}');
      AppLogger.info('name: ${userData['name']}');
      AppLogger.info('age: ${userData['age']}');
      AppLogger.info('sex: ${userData['sex']}');
      AppLogger.info('seekingGender: ${userData['seekingGender']}');
      AppLogger.info('location: ${userData['location']}');
      AppLogger.info('preferredAgeRange: ${userData['preferredAgeRange']}');
      AppLogger.info('hometown: ${userData['hometown']}');
      AppLogger.info('bio: ${userData['bio']}');
      AppLogger.info('interests: ${userData['interests']}');
      AppLogger.info('objectives: ${userData['objectives']}');
      AppLogger.info('profilePic: ${userData['profilePic']}');

      // Create a map with default values for missing fields
      final Map<String, dynamic> safeUserData = {
        '_id': userData['_id'] ?? userId,
        'email': userData['email'] ?? '',
        'name': userData['name'] ?? '',
        'age': userData['age'],
        'sex': userData['sex'],
        'seekingGender': userData['seeking_gender'],
        'location': userData['location'],
        'preferredAgeRange': userData['preferred_age_range'],
        'hometown': userData['hometown'] ?? '',
        'bio': userData['bio'] ?? '',
        'interests': userData['interests'] ?? [],
        'objectives': userData['objectives'] ?? [],
        'profilePic': userData['profile_pic'] ?? '',
        'preferred_distance_radius': userData['preferred_distance_radius'] ?? 40,
      };

      AppLogger.info('Processed user data: $safeUserData');
      
      final user = User.fromJson(safeUserData);
      AppLogger.info('Created User object with isProfileComplete: ${user.isProfileComplete}');
      
      // Log each field's completion status
      AppLogger.info('Profile completion check:');
      AppLogger.info('Age set: ${user.age != null && user.age != 0}');
      AppLogger.info('Name set: ${user.name != null && user.name!.isNotEmpty}');
      AppLogger.info('Bio set: ${user.bio != null && user.bio!.isNotEmpty}');
      AppLogger.info('Hometown set: ${user.hometown != null && user.hometown!.isNotEmpty}');
      AppLogger.info('Profile pic set: ${user.profilePic != null && user.profilePic!.isNotEmpty}');
      AppLogger.info('Interests set: ${user.interests != null && user.interests!.isNotEmpty}');
      AppLogger.info('Objectives set: ${user.objectives != null && user.objectives!.isNotEmpty}');
      
      return user;
    } on DioException catch (e) {
      AppLogger.error(
        'Failed to get current user',
        e,
        StackTrace.current,
      );
      return null;
    } catch (e) {
      AppLogger.error(
        'Unexpected error in getCurrentUser',
        e,
        StackTrace.current,
      );
      return null;
    }
  }

  @override
  Future<void> updateUserProfile(User user) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    try {
      await NetworkService.dio.put(
        '/users/profile',
        data: user.toJson(),
      );
    } on DioException catch (e) {
      throw Exception('Failed to update profile: ${e.response?.data ?? e.message}');
    }
  }

  @override
  Future<void> deleteAccount() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    try {
      await NetworkService.dio.delete('/users/account');
      await logout();
    } on DioException catch (e) {
      throw Exception('Failed to delete account: ${e.response?.data ?? e.message}');
    }
  }

  @override
  Future<List<String>> getPredefinedInterests() async {
    try {
      final response = await NetworkService.dio.get('/users/interests');
      final data = response.data as Map<String, dynamic>;
      final interests = List<String>.from(data['interests'] as List);
      AppLogger.info('Successfully fetched ${interests.length} predefined interests');
      return interests;
    } on DioException catch (e) {
      AppLogger.error(
        'Failed to fetch predefined interests: ${e.message}',
      );
      throw Exception('Failed to fetch predefined interests: ${e.message}');
    }
  }

  @override
  Future<List<String>> getPredefinedObjectives() async {
    try {
      final response = await NetworkService.dio.get('/users/objectives');
      final data = response.data as Map<String, dynamic>;
      final objectives = List<String>.from(data['objectives'] as List);
      AppLogger.info('Successfully fetched ${objectives.length} predefined objectives');
      return objectives;
    } on DioException catch (e) {
      AppLogger.error(
        'Failed to fetch predefined objectives: ${e.message}',
      );
      throw Exception('Failed to fetch predefined objectives: ${e.message}');
    }
  }

  User _mapUserModelToEntity(UserModel model) {
    return User(
      id: model.id,
      email: model.email,
      name: model.email.split('@')[0], // Using email username as name for now
      age: model.age,
      sex: model.sex,
      bio: model.bio,
      interests: model.interests,
      profilePic: model.profilePic,
      location: {
        'coordinates': [model.location.coordinates[0], model.location.coordinates[1]],
      },
      preferredAgeRange: {
        'lower_limit': model.preferredAgeRange.lowerLimit,
        'upper_limit': model.preferredAgeRange.upperLimit,
      },
      hometown: model.hometown,
      seekingGender: model.seekingGender,
      objectives: model.objectives,
    );
  }
} 