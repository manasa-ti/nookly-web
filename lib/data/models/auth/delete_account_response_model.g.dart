// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_account_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeleteAccountResponseModel _$DeleteAccountResponseModelFromJson(
        Map<String, dynamic> json) =>
    DeleteAccountResponseModel(
      message: json['message'] as String,
      success: json['success'] as bool,
      deletedAt: json['deletedAt'] as String,
    );

Map<String, dynamic> _$DeleteAccountResponseModelToJson(
        DeleteAccountResponseModel instance) =>
    <String, dynamic>{
      'message': instance.message,
      'success': instance.success,
      'deletedAt': instance.deletedAt,
    };
