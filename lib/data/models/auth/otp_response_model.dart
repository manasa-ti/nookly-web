class OtpResponseModel {
  final String message;
  final String email;
  final int expiresIn;
  final int retryAfter;

  OtpResponseModel({
    required this.message,
    required this.email,
    required this.expiresIn,
    required this.retryAfter,
  });

  factory OtpResponseModel.fromJson(Map<String, dynamic> json) {
    return OtpResponseModel(
      message: json['message'] as String,
      email: json['email'] as String,
      expiresIn: json['expiresIn'] as int,
      retryAfter: json['retryAfter'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'email': email,
      'expiresIn': expiresIn,
      'retryAfter': retryAfter,
    };
  }
} 