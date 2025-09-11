import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:nookly/core/network/network_service.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/core/services/google_sign_in_service.dart';
import 'package:nookly/core/services/user_cache_service.dart';
import 'package:nookly/data/models/auth/auth_response_model.dart';
import 'package:nookly/data/models/auth/login_request_model.dart';
import 'package:nookly/data/models/auth/register_request_model.dart';
import 'package:nookly/data/models/auth/otp_response_model.dart';
import 'package:nookly/data/models/auth/verify_otp_response_model.dart';
import 'package:nookly/data/models/auth/forgot_password_request_model.dart';
import 'package:nookly/data/models/auth/forgot_password_response_model.dart';
import 'package:nookly/data/models/auth/reset_password_request_model.dart';
import 'package:nookly/data/models/auth/reset_password_response_model.dart';
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
      if (authResponse.token != null) {
        await _saveToken(authResponse.token!);
        await _saveUserId(authResponse.user.id);
        NetworkService.setAuthToken(authResponse.token!);
      }
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
      if (authResponse.token != null) {
        await _saveToken(authResponse.token!);
        await _saveUserId(authResponse.user.id);
        NetworkService.setAuthToken(authResponse.token!);
      }
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
    
    // Clear user cache on logout
    final userCacheService = UserCacheService();
    userCacheService.invalidateCache();
    AppLogger.info('🔵 logout: User cache cleared on logout');
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
  Future<AuthResponseModel> signInWithEmailAndPassword(String email, String password) async {
    final request = LoginRequestModel(email: email, password: password);
    return await login(request);
  }

  @override
  Future<AuthResponseModel> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final response = await NetworkService.dio.post(
        '/users/register',
        data: {
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponseModel.fromJson(response.data);
      
      // Only save token and set auth if email verification is not required
      if (authResponse.token != null && authResponse.emailVerificationRequired != true) {
        await _saveToken(authResponse.token!);
        await _saveUserId(authResponse.user.id);
        NetworkService.setAuthToken(authResponse.token!);
      }
      
      return authResponse;
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
      if (authResponse.token != null) {
        await _saveToken(authResponse.token!);
        await _saveUserId(authResponse.user.id);
        NetworkService.setAuthToken(authResponse.token!);
      }
      
      AppLogger.info('Google Sign-In successful for user: ${authData['email']}');
      AppLogger.info('JWT Token received: ${authResponse.token?.substring(0, 20) ?? 'null'}...');
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
  Future<ForgotPasswordResponseModel> forgotPassword(String email) async {
    try {
      AppLogger.info('Requesting password reset for email: $email');
      final request = ForgotPasswordRequestModel(email: email);
      final response = await NetworkService.dio.post(
        '/users/forgot-password',
        data: request.toJson(),
      );

      final forgotPasswordResponse = ForgotPasswordResponseModel.fromJson(response.data);
      AppLogger.info('Password reset email sent successfully to: $email');
      return forgotPasswordResponse;
    } on DioException catch (e) {
      AppLogger.error(
        'Failed to send password reset email',
        e,
        StackTrace.current,
      );
      throw Exception('Failed to send password reset email: ${e.response?.data ?? e.message}');
    }
  }

  @override
  Future<ResetPasswordResponseModel> resetPassword(String token, String newPassword) async {
    try {
      AppLogger.info('Resetting password with token');
      final request = ResetPasswordRequestModel(
        token: token,
        newPassword: newPassword,
      );
      final response = await NetworkService.dio.post(
        '/users/reset-password',
        data: request.toJson(),
      );

      final resetPasswordResponse = ResetPasswordResponseModel.fromJson(response.data);
      AppLogger.info('Password reset successful');
      return resetPasswordResponse;
    } on DioException catch (e) {
      AppLogger.error(
        'Failed to reset password',
        e,
        StackTrace.current,
      );
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

    // Check cache first
    final userCacheService = UserCacheService();
    final cachedUser = userCacheService.getCachedUser();
    if (cachedUser != null) {
      AppLogger.info('🔵 getCurrentUser: Returning cached user data for userId: $userId');
      return cachedUser;
    }

    try {
      AppLogger.info('🔵 getCurrentUser: Cache miss, fetching from API for userId: $userId');
      final response = await NetworkService.dio.get('/users/profile/$userId');
      final userData = response.data;
      AppLogger.info('Raw API response: $userData');
      
      // Validate user data
      if (userData == null) {
        AppLogger.error('API response is null');
        return null;
      }

      // Log each field to check what's missing

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
        'personality_type': userData['personality_type'] ?? [],
        'physical_activeness': userData['physical_activeness'] ?? [],
        'availability': userData['availability'] ?? [],
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
      
      // Cache the user data
      userCacheService.cacheUser(user);
      AppLogger.info('🔵 getCurrentUser: User data cached successfully');
      
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
      
      // Invalidate cache after successful profile update
      final userCacheService = UserCacheService();
      userCacheService.invalidateCache();
      AppLogger.info('🔵 updateUserProfile: Cache invalidated after profile update');
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

  @override
  Future<Map<String, List<String>>> getProfileOptions() async {
    try {
      final response = await NetworkService.dio.get('/users/profile-options');
      final data = response.data as Map<String, dynamic>;
      
      final profileOptions = {
        'interests': List<String>.from(data['interests'] as List),
        'objectives': List<String>.from(data['objectives'] as List),
        'personality_types': List<String>.from(data['personality_types'] as List),
        'physical_activeness': List<String>.from(data['physical_activeness'] as List),
        'availability': List<String>.from(data['availability'] as List),
      };
      
      AppLogger.info('Successfully fetched profile options: ${profileOptions.map((k, v) => MapEntry(k, v.length))}');
      return profileOptions;
    } on DioException catch (e) {
      AppLogger.error(
        'Failed to fetch profile options: ${e.message}',
      );
      throw Exception('Failed to fetch profile options: ${e.message}');
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

  // OTP Methods Implementation
  @override
  Future<OtpResponseModel> sendOtp(String email) async {
    try {
      AppLogger.info('Sending OTP to email: $email');
      final response = await NetworkService.dio.post(
        '/users/send-otp',
        data: {'email': email},
      );

      final otpResponse = OtpResponseModel.fromJson(response.data);
      AppLogger.info('OTP sent successfully to: $email');
      return otpResponse;
    } on DioException catch (e) {
      AppLogger.error(
        'Failed to send OTP',
        e,
        StackTrace.current,
      );
      throw Exception('Failed to send OTP: ${e.response?.data?['message'] ?? e.message}');
    }
  }

  @override
  Future<VerifyOtpResponseModel> verifyOtp(String email, String otp) async {
    try {
      AppLogger.info('Verifying OTP for email: $email');
      final response = await NetworkService.dio.post(
        '/users/verify-otp',
        data: {
          'email': email,
          'otp': otp,
        },
      );

      AppLogger.info('OTP verification response data: ${response.data}');
      
      try {
        final verifyResponse = VerifyOtpResponseModel.fromJson(response.data);
        
        // Save token and user ID after successful verification
        await _saveToken(verifyResponse.token);
        await _saveUserId(verifyResponse.user.id);
        NetworkService.setAuthToken(verifyResponse.token);
        
        AppLogger.info('OTP verified successfully for: $email');
        return verifyResponse;
      } catch (parseError) {
        AppLogger.error('Failed to parse OTP verification response: $parseError');
        AppLogger.error('Response data structure: ${response.data.runtimeType}');
        if (response.data is Map) {
          final responseMap = response.data as Map;
          AppLogger.error('Response data keys: ${responseMap.keys.toList()}');
          if (responseMap.containsKey('user')) {
            final userData = responseMap['user'];
            AppLogger.error('User data keys: ${userData is Map ? (userData as Map<String, dynamic>).keys.toList() : 'Not a Map'}');
          }
        }
        throw Exception('Failed to parse OTP verification response: $parseError');
      }
    } on DioException catch (e) {
      AppLogger.error(
        'Failed to verify OTP',
        e,
        StackTrace.current,
      );
      throw Exception('Failed to verify OTP: ${e.response?.data?['message'] ?? e.message}');
    }
  }

  @override
  Future<OtpResponseModel> resendOtp(String email) async {
    try {
      AppLogger.info('Resending OTP to email: $email');
      final response = await NetworkService.dio.post(
        '/users/resend-otp',
        data: {'email': email},
      );

      final otpResponse = OtpResponseModel.fromJson(response.data);
      AppLogger.info('OTP resent successfully to: $email');
      return otpResponse;
    } on DioException catch (e) {
      AppLogger.error(
        'Failed to resend OTP',
        e,
        StackTrace.current,
      );
      throw Exception('Failed to resend OTP: ${e.response?.data?['message'] ?? e.message}');
    }
  }
} 