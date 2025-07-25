// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reset_password_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResetPasswordResponseModel _$ResetPasswordResponseModelFromJson(
        Map<String, dynamic> json) =>
    ResetPasswordResponseModel(
      message: json['message'] as String,
      success: json['success'] as bool,
    );

Map<String, dynamic> _$ResetPasswordResponseModelToJson(
        ResetPasswordResponseModel instance) =>
    <String, dynamic>{
      'message': instance.message,
      'success': instance.success,
    };
