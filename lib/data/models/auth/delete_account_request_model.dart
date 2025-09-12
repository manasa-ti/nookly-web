import 'package:json_annotation/json_annotation.dart';

part 'delete_account_request_model.g.dart';

@JsonSerializable()
class DeleteAccountRequestModel {
  final String confirmation;
  final String? password;

  const DeleteAccountRequestModel({
    required this.confirmation,
    this.password,
  });

  factory DeleteAccountRequestModel.fromJson(Map<String, dynamic> json) =>
      _$DeleteAccountRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteAccountRequestModelToJson(this);
}
