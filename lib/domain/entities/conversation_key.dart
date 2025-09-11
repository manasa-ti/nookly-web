import 'package:equatable/equatable.dart';

class ConversationKey extends Equatable {
  final String conversationId;
  final String encryptionKey;
  final DateTime createdAt;
  final DateTime lastUsed;

  const ConversationKey({
    required this.conversationId,
    required this.encryptionKey,
    required this.createdAt,
    required this.lastUsed,
  });

  @override
  List<Object?> get props => [
        conversationId,
        encryptionKey,
        createdAt,
        lastUsed,
      ];

  factory ConversationKey.fromJson(Map<String, dynamic> json) {
    return ConversationKey(
      conversationId: json['conversationId'] as String,
      encryptionKey: json['encryptionKey'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsed: DateTime.parse(json['lastUsed'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'encryptionKey': encryptionKey,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  ConversationKey copyWith({
    String? conversationId,
    String? encryptionKey,
    DateTime? createdAt,
    DateTime? lastUsed,
  }) {
    return ConversationKey(
      conversationId: conversationId ?? this.conversationId,
      encryptionKey: encryptionKey ?? this.encryptionKey,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
}
