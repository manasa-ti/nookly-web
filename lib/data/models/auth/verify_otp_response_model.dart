import 'package:nookly/data/models/auth/auth_response_model.dart';

class VerifyOtpResponseModel {
  final String message;
  final String token;
  final UserModel user;
  final bool emailVerified;

  VerifyOtpResponseModel({
    required this.message,
    required this.token,
    required this.user,
    required this.emailVerified,
  });

  factory VerifyOtpResponseModel.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponseModel(
      message: json['message'] as String? ?? '',
      token: json['token'] as String? ?? '',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      emailVerified: json['emailVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'token': token,
      'user': user.toJson(),
      'emailVerified': emailVerified,
    };
  }
} 