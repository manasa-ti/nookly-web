import 'package:json_annotation/json_annotation.dart';

part 'reset_password_response_model.g.dart';

@JsonSerializable()
class ResetPasswordResponseModel {
  final String message;
  final bool success;

  const ResetPasswordResponseModel({
    required this.message,
    required this.success,
  });

  factory ResetPasswordResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ResetPasswordResponseModelToJson(this);
} 