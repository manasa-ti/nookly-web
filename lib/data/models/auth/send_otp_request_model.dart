class SendOtpRequestModel {
  final String email;

  SendOtpRequestModel({
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
} 