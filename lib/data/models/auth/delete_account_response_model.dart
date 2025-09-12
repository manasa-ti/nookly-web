import 'package:json_annotation/json_annotation.dart';

part 'delete_account_response_model.g.dart';

@JsonSerializable()
class DeleteAccountResponseModel {
  final String message;
  final bool success;
  final String deletedAt;

  const DeleteAccountResponseModel({
    required this.message,
    required this.success,
    required this.deletedAt,
  });

  factory DeleteAccountResponseModel.fromJson(Map<String, dynamic> json) =>
      _$DeleteAccountResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteAccountResponseModelToJson(this);
}
