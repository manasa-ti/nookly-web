// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_account_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeleteAccountRequestModel _$DeleteAccountRequestModelFromJson(
        Map<String, dynamic> json) =>
    DeleteAccountRequestModel(
      confirmation: json['confirmation'] as String,
      password: json['password'] as String?,
    );

Map<String, dynamic> _$DeleteAccountRequestModelToJson(
        DeleteAccountRequestModel instance) =>
    <String, dynamic>{
      'confirmation': instance.confirmation,
      'password': instance.password,
    };
