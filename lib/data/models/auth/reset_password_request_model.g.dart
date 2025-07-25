// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reset_password_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResetPasswordRequestModel _$ResetPasswordRequestModelFromJson(
        Map<String, dynamic> json) =>
    ResetPasswordRequestModel(
      token: json['token'] as String,
      newPassword: json['newPassword'] as String,
    );

Map<String, dynamic> _$ResetPasswordRequestModelToJson(
        ResetPasswordRequestModel instance) =>
    <String, dynamic>{
      'token': instance.token,
      'newPassword': instance.newPassword,
    };
