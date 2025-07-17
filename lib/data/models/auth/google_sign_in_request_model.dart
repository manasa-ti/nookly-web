class GoogleSignInRequestModel {
  final String idToken;
  final String? accessToken;
  final String? serverAuthCode;
  final String email;
  final String? displayName;
  final String? photoUrl;

  GoogleSignInRequestModel({
    required this.idToken,
    this.accessToken,
    this.serverAuthCode,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'idToken': idToken,
      'accessToken': accessToken,
      'serverAuthCode': serverAuthCode,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }

  factory GoogleSignInRequestModel.fromMap(Map<String, dynamic> map) {
    return GoogleSignInRequestModel(
      idToken: map['idToken'] as String,
      accessToken: map['accessToken'] as String?,
      serverAuthCode: map['serverAuthCode'] as String?,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
    );
  }
} 