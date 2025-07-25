import 'package:json_annotation/json_annotation.dart';

part 'forgot_password_response_model.g.dart';

@JsonSerializable()
class ForgotPasswordResponseModel {
  final String message;
  final bool emailSent;
  @JsonKey(includeIfNull: false)
  final int? expiresIn;

  const ForgotPasswordResponseModel({
    required this.message,
    required this.emailSent,
    this.expiresIn,
  });

  factory ForgotPasswordResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ForgotPasswordResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ForgotPasswordResponseModelToJson(this);
} 