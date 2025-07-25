// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forgot_password_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ForgotPasswordResponseModel _$ForgotPasswordResponseModelFromJson(
        Map<String, dynamic> json) =>
    ForgotPasswordResponseModel(
      message: json['message'] as String,
      emailSent: json['emailSent'] as bool,
      expiresIn: (json['expiresIn'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ForgotPasswordResponseModelToJson(
        ForgotPasswordResponseModel instance) =>
    <String, dynamic>{
      'message': instance.message,
      'emailSent': instance.emailSent,
      if (instance.expiresIn case final value?) 'expiresIn': value,
    };
